const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const projectRoot = path.resolve(__dirname, '..');
const cliPath = path.join(projectRoot, 'scripts', 'check-design-baseline.cjs');

function baselineManifest() {
  return {
    version: 1,
    artifacts: {
      sourceHtml: 'final.html',
      packagedHtml: 'copy.html',
      viewer: 'viewer.js',
      layers: 'layers.json',
      snapshot: 'snapshot.json',
      pen: 'design.pen',
      requiredFiles: ['asset.png'],
      copies: [{ source: 'asset.png', target: 'copy-asset.png' }],
    },
    productScenes: ['main', 'boarding', 'intro'],
    internalScenes: ['main', 'boarding', 'intro'],
    states: [
      { viewerKey: 'main', scene: 'main', penNode: 'n1' },
      { viewerKey: 'boarding-success', scene: 'boarding', penNode: 'n2' },
    ],
    reviews: {
      browser: {
        status: 'pending',
        reason: 'Latest boarding rendering not verified',
      },
      productScreenCoverage: {
        status: 'passed',
      },
    },
  };
}

function writeJson(filePath, value) {
  fs.writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`);
}

function makeFixture(mutate = () => {}) {
  const fixtureDir = fs.mkdtempSync(path.join(os.tmpdir(), 'design-baseline-'));
  const root = path.join(fixtureDir, 'root');
  const docs = path.join(root, 'docs');
  fs.mkdirSync(docs, { recursive: true });

  const html = [
    "const sceneIds=['main','boarding','intro'];",
    "const productSceneIds=['main','boarding','intro'];",
    "const requiredBaselineReviews=['browser','productScreenCoverage'];",
    '',
  ].join('\n');
  const asset = Buffer.from('same asset bytes');
  fs.writeFileSync(path.join(root, 'final.html'), html);
  fs.writeFileSync(path.join(root, 'copy.html'), html);
  fs.writeFileSync(
    path.join(root, 'viewer.js'),
    "const cases=[['main','Main'],['boarding-success','Recognized']];\n",
  );
  writeJson(path.join(root, 'layers.json'), [
    { scene: 'main' },
    { scene: 'boarding-success' },
  ]);
  writeJson(path.join(root, 'snapshot.json'), {
    nodes: [
      { id: 'n1', name: 'Main' },
      {
        id: 'container',
        name: 'Container',
        children: [{ id: 'n2', name: 'Recognized' }],
      },
    ],
  });
  fs.writeFileSync(path.join(root, 'design.pen'), Buffer.from([0x50, 0x45, 0x4e]));
  fs.writeFileSync(path.join(root, 'asset.png'), asset);
  fs.writeFileSync(path.join(root, 'copy-asset.png'), asset);

  const manifest = baselineManifest();
  mutate({ root, manifest });
  writeJson(path.join(docs, 'design-baseline.json'), manifest);
  return root;
}

function runCli(root, args = ['--root', root]) {
  const result = spawnSync(process.execPath, [cliPath, ...args], {
    cwd: projectRoot,
    encoding: 'utf8',
    timeout: 5_000,
  });

  assert.equal(result.error, undefined, `CLI process failed to start: ${result.error}`);
  assert.notEqual(
    result.stdout.trim(),
    '',
    `CLI implementation is missing or emitted no JSON stdout. stderr: ${result.stderr.trim()}`,
  );

  let output;
  assert.doesNotThrow(() => {
    output = JSON.parse(result.stdout);
  }, `CLI stdout must be one JSON object. stdout: ${result.stdout}`);

  assert.equal(typeof output.automationPassed, 'boolean');
  assert.equal(typeof output.phase0Complete, 'boolean');
  assert.ok(Array.isArray(output.errors));
  assert.ok(Array.isArray(output.pendingReviews));
  assert.deepEqual(Object.keys(output.counts).sort(), ['design', 'internal', 'product']);
  for (const error of output.errors) {
    assert.equal(typeof error.code, 'string');
    assert.equal(typeof error.path, 'string');
    assert.equal(typeof error.detail, 'string');
  }

  return { result, output };
}

function assertErrorMentions(output, expected) {
  assert.ok(
    output.errors.some(({ path: errorPath, detail }) =>
      `${errorPath}\n${detail}`.includes(expected),
    ),
    `expected an error naming ${expected}; got ${JSON.stringify(output.errors)}`,
  );
}

test('AC-1 실행 자료 불일치 감지', async (t) => {
  const cases = [
    {
      name: '동일한 실행 자료와 복제본은 통과한다',
      expectedStatus: 0,
      expectedPassed: true,
    },
    {
      name: 'HTML 복제본이 다르면 copy.html을 표시하며 실패한다',
      expectedStatus: 1,
      expectedPassed: false,
      expectedError: 'copy.html',
      mutate: ({ root }) => fs.writeFileSync(path.join(root, 'copy.html'), 'different'),
    },
    {
      name: '필수 자산이 없으면 asset.png를 표시하며 실패한다',
      expectedStatus: 1,
      expectedPassed: false,
      expectedError: 'asset.png',
      mutate: ({ root }) => fs.unlinkSync(path.join(root, 'asset.png')),
    },
    {
      name: '자산 복제본이 다르면 copy-asset.png를 표시하며 실패한다',
      expectedStatus: 1,
      expectedPassed: false,
      expectedError: 'copy-asset.png',
      mutate: ({ root }) => fs.writeFileSync(path.join(root, 'copy-asset.png'), 'different'),
    },
    {
      name: '루트 밖의 기존 파일을 가리키는 경로도 거부한다',
      expectedStatus: 1,
      expectedPassed: false,
      expectedError: '../outside.html',
      mutate: ({ root, manifest }) => {
        fs.writeFileSync(path.join(root, '..', 'outside.html'), fs.readFileSync(path.join(root, 'copy.html')));
        manifest.artifacts.sourceHtml = '../outside.html';
      },
    },
    {
      name: '기준선 manifest가 없으면 계약 JSON으로 실패한다',
      expectedStatus: 1,
      expectedPassed: false,
      expectedComplete: false,
      expectedError: 'docs/design-baseline.json',
      expectedHandledFailure: true,
      afterCreate: ({ root }) => {
        fs.unlinkSync(path.join(root, 'docs', 'design-baseline.json'));
      },
    },
    {
      name: '기준선 manifest JSON이 잘못되면 계약 JSON으로 실패한다',
      expectedStatus: 1,
      expectedPassed: false,
      expectedComplete: false,
      expectedError: 'docs/design-baseline.json',
      expectedHandledFailure: true,
      afterCreate: ({ root }) => {
        fs.writeFileSync(path.join(root, 'docs', 'design-baseline.json'), '{malformed');
      },
    },
  ];

  for (const scenario of cases) {
    await t.test(scenario.name, () => {
      const root = makeFixture(scenario.mutate);
      try {
        scenario.afterCreate?.({ root });
        const { result, output } = runCli(root);
        assert.equal(result.status, scenario.expectedStatus);
        assert.equal(output.automationPassed, scenario.expectedPassed);
        if (scenario.expectedComplete !== undefined) {
          assert.equal(output.phase0Complete, scenario.expectedComplete);
        }
        if (scenario.expectedHandledFailure) {
          assert.doesNotMatch(
            result.stderr,
            /^\s*(?:SyntaxError|Error:)|\n\s+at /m,
            `CLI must report manifest failure as JSON, not an uncaught stack: ${result.stderr}`,
          );
        }
        if (scenario.expectedError) assertErrorMentions(output, scenario.expectedError);
      } finally {
        fs.rmSync(path.dirname(root), { recursive: true, force: true });
      }
    });
  }
});

test('AC-2 화면 연결 누락 감지', async (t) => {
  const cases = [
    {
      name: 'HTML의 승인 제품 장면이 productScenes에서 누락되면 보고한다',
      expectedError: 'intro',
      mutate: ({ manifest }) => { manifest.productScenes.pop(); },
    },
    {
      name: 'HTML에서 추출한 장면과 internalScenes가 다르면 보고한다',
      expectedError: 'ghost',
      mutate: ({ manifest }) => { manifest.internalScenes[2] = 'ghost'; },
    },
    {
      name: 'internalScenes에 없는 제품 장면을 보고한다',
      expectedError: 'ghost',
      mutate: ({ manifest }) => { manifest.productScenes.push('ghost'); },
    },
    {
      name: '중복된 제품 장면을 보고한다',
      expectedError: 'main',
      mutate: ({ manifest }) => { manifest.productScenes.push('main'); },
    },
    {
      name: '내부 장면에 없는 상태 장면을 보고한다',
      expectedError: 'ghost',
      mutate: ({ manifest }) => { manifest.states[0].scene = 'ghost'; },
    },
    {
      name: 'viewerKey에 대응하는 상태가 없으면 보고한다',
      expectedError: 'boarding-success',
      mutate: ({ manifest }) => { manifest.states.pop(); },
    },
    {
      name: '같은 viewerKey가 두 번 연결되면 보고한다',
      expectedError: 'main',
      mutate: ({ manifest }) => {
        manifest.states[1].viewerKey = 'main';
      },
    },
    {
      name: '스냅샷에 없는 Pen 노드를 보고한다',
      expectedError: 'n404',
      mutate: ({ manifest }) => { manifest.states[1].penNode = 'n404'; },
    },
    {
      name: 'layer와 viewer 키 집합이 다르면 누락 키를 보고한다',
      expectedError: 'layer-only',
      mutate: ({ root }) => {
        writeJson(path.join(root, 'layers.json'), [
          { scene: 'main' },
          { scene: 'layer-only' },
        ]);
      },
    },
  ];

  for (const scenario of cases) {
    await t.test(scenario.name, () => {
      const root = makeFixture(scenario.mutate);
      try {
        const { result, output } = runCli(root);
        assert.equal(result.status, 1);
        assert.equal(output.automationPassed, false);
        assert.equal(output.phase0Complete, false);
        assertErrorMentions(output, scenario.expectedError);
      } finally {
        fs.rmSync(path.dirname(root), { recursive: true, force: true });
      }
    });
  }
});

test('AC-3 자동 검사와 브라우저 검토 상태 구분', async (t) => {
  const cases = [
    {
      name: '자동 검사가 통과해도 브라우저 검토가 pending이면 완료하지 않는다',
      expectedStatus: 0,
      expectedAutomation: true,
      expectedComplete: false,
      expectedPending: ['browser'],
    },
    {
      name: '자동 검사와 브라우저 검토가 모두 통과하면 완료한다',
      expectedStatus: 0,
      expectedAutomation: true,
      expectedComplete: true,
      expectedPending: [],
      mutate: ({ manifest }) => { manifest.reviews.browser.status = 'passed'; },
    },
    {
      name: '브라우저 검토가 passed여도 자료 오류가 있으면 완료하지 않는다',
      expectedStatus: 1,
      expectedAutomation: false,
      expectedComplete: false,
      expectedPending: [],
      mutate: ({ root, manifest }) => {
        manifest.reviews.browser.status = 'passed';
        fs.writeFileSync(path.join(root, 'copy.html'), 'different');
      },
    },
    {
      name: '알 수 없는 브라우저 검토 상태는 완료로 처리하지 않는다',
      expectedStatus: 1,
      expectedAutomation: false,
      expectedComplete: false,
      mutate: ({ manifest }) => { manifest.reviews.browser.status = 'unknown'; },
    },
    {
      name: '브라우저 검토 상태가 없으면 완료로 처리하지 않는다',
      expectedStatus: 1,
      expectedAutomation: false,
      expectedComplete: false,
      mutate: ({ manifest }) => { delete manifest.reviews.browser.status; },
    },
  ];

  for (const scenario of cases) {
    await t.test(scenario.name, () => {
      const root = makeFixture(scenario.mutate);
      try {
        const { result, output } = runCli(root);
        assert.equal(result.status, scenario.expectedStatus);
        assert.equal(output.automationPassed, scenario.expectedAutomation);
        assert.equal(output.phase0Complete, scenario.expectedComplete);
        if (scenario.expectedPending) {
          assert.deepEqual(output.pendingReviews, scenario.expectedPending);
        } else {
          assert.ok(
            output.pendingReviews.includes('browser') || output.errors.length > 0,
            'invalid review status must remain pending or produce an error',
          );
        }
        assert.deepEqual(output.counts, { product: 3, internal: 3, design: 2 });
      } finally {
        fs.rmSync(path.dirname(root), { recursive: true, force: true });
      }
    });
  }
});

test('R3 필수 검토 및 CLI 입력 계약', async (t) => {
  const cases = [
    {
      name: '독립 목록의 필수 제품 화면 검토가 manifest에서 누락되면 실패한다',
      expectedError: 'productScreenCoverage',
      mutate: ({ manifest }) => {
        manifest.reviews.browser.status = 'passed';
        delete manifest.reviews.productScreenCoverage;
      },
    },
    {
      name: 'HTML에 필수 검토 목록 선언이 없으면 실패한다',
      expectedError: 'requiredBaselineReviews',
      afterCreate: ({ root }) => {
        const htmlWithoutReviewContract = [
          "const sceneIds=['main','boarding','intro'];",
          "const productSceneIds=['main','boarding','intro'];",
          '',
        ].join('\n');
        fs.writeFileSync(path.join(root, 'final.html'), htmlWithoutReviewContract);
        fs.writeFileSync(path.join(root, 'copy.html'), htmlWithoutReviewContract);
      },
    },
    {
      name: '알 수 없는 --rooot 옵션을 거부한다',
      expectedError: '--rooot',
      args: ({ root }) => ['--rooot', root],
    },
    {
      name: '--root 값이 없으면 거부한다',
      expectedError: '--root',
      args: () => ['--root'],
    },
    {
      name: '--root 뒤의 추가 인자를 거부한다',
      expectedError: 'extra',
      args: ({ root }) => ['--root', root, 'extra'],
    },
    {
      name: '존재하지 않는 --root 경로를 거부한다',
      expectedError: 'missing-root',
      args: ({ root }) => ['--root', path.join(root, 'missing-root')],
    },
  ];

  for (const scenario of cases) {
    await t.test(scenario.name, () => {
      const root = makeFixture(scenario.mutate);
      try {
        scenario.afterCreate?.({ root });
        const args = scenario.args?.({ root });
        const { result, output } = runCli(root, args);
        assert.equal(result.status, 1);
        assert.equal(output.automationPassed, false);
        assert.equal(output.phase0Complete, false);
        assertErrorMentions(output, scenario.expectedError);
      } finally {
        fs.rmSync(path.dirname(root), { recursive: true, force: true });
      }
    });
  }
});
