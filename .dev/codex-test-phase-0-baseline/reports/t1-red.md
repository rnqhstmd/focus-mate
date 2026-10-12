# T1 RED 보고서 — Phase 0 디자인 기준선 CLI

## 깨짐 명명

- 실행 자료 비교를 생략하거나 루트 밖 manifest 경로를 허용하면 AC-1 테스트가 실패해야 한다.
- HTML 장면과 internal 목록의 불일치, product 부분집합/고유성 위반, viewerKey/layer/Pen 노드의 누락·중복을 허용하면 AC-2 테스트가 실패해야 한다.
- 제품 장면을 독립 viewer/Pen 상태와 강제로 1:1 대응시키면 상태가 없는 합법적 제품 장면 fixture가 실패한다.
- 자동 검사와 브라우저 검토 상태를 합치거나 잘못된/누락 상태를 완료로 간주하면 AC-3 테스트가 실패해야 한다.

## 테스트 코드 전문

```js
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

  const html = "const sceneIds=['main','boarding','intro'];\n";
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

function runCli(root) {
  const result = spawnSync(process.execPath, [cliPath, '--root', root], {
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
  ];

  for (const scenario of cases) {
    await t.test(scenario.name, () => {
      const root = makeFixture(scenario.mutate);
      try {
        const { result, output } = runCli(root);
        assert.equal(result.status, scenario.expectedStatus);
        assert.equal(output.automationPassed, scenario.expectedPassed);
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
```

## 실패 확인

- 명령: `node --test scripts/design-baseline.test.cjs`
- 결과: 종료 코드 1, 사례 18개 모두 실패. Node 집계는 상위 그룹 3개를 포함해 `tests 21 / pass 0 / fail 21`.
- 대표 실패:

```text
AssertionError [ERR_ASSERTION]: CLI implementation is missing or emitted no JSON stdout.
Error: Cannot find module '/Users/bonseung/Documents/ChatGPT/new/scripts/check-design-baseline.cjs'
code: 'MODULE_NOT_FOUND'
ℹ tests 21
ℹ pass 0
ℹ fail 21
```

- 실패 분류: 정상 RED — 테스트 러너와 실제 fs fixture 생성은 실행됐고, 각 하위 테스트가 미구현 CLI 명령(NoSuchMethod 상당)을 spawn한 뒤 계약 assertion에서 실패했다.
- 구현/manifest/HTML/Pen 파일은 읽지 않았다. fixture의 HTML/viewer 소스 문자열도 실행하지 않는다.
- 제품 장면 집합은 internal의 고유 부분집합으로 검증하되 viewer/Pen 상태와의 1:1 대응 대상은 아니다. 상태 연결 완전성은 viewer cases와 layers 사이의 계약이다.

## 참조한 파일

- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-dev/references/codex-roles/red-writer.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/testing-anti-patterns.md`
- `/Users/bonseung/Documents/ChatGPT/new/.dev/codex-test-phase-0-baseline/ac.md`
- `/Users/bonseung/Documents/ChatGPT/new/scripts/design-baseline.test.cjs`

## 재현 RED R1

### 추가 사례

- `docs/design-baseline.json`이 없으면 exit 1과 계약 JSON을 반환하고, `automationPassed:false`, `phase0Complete:false`, 해당 경로를 담은 오류를 보고한다.
- `docs/design-baseline.json`이 malformed JSON이면 exit 1과 같은 실패 계약을 반환하며 uncaught stack trace로 종료하지 않는다.

### 집중 실행 결과

- 명령: `node --test scripts/design-baseline.test.cjs`
- leaf 결과: 기존 18건 통과, 신규 2건 실패.
- Node 집계: `tests 23 / pass 20 / fail 3` (실패 leaf 2건과 상위 AC-1 그룹 1건).
- manifest 부재: CLI가 JSON stdout 없이 uncaught `ENOENT` stack trace를 출력해 `CLI implementation is missing or emitted no JSON stdout` assertion에서 실패했다.
- malformed JSON: CLI가 JSON stdout 없이 uncaught `SyntaxError` stack trace를 출력해 같은 assertion에서 실패했다.
- 실패 분류: 정상 RED. 테스트 러너/fixture/CLI spawn은 정상이며 필요한 오류 경계 처리만 미구현이다.

### R1 참조 파일

- `/Users/bonseung/Documents/ChatGPT/new/scripts/design-baseline.test.cjs`
- `/Users/bonseung/Documents/ChatGPT/new/.dev/codex-test-phase-0-baseline/reports/t1-red.md`

## 재현 RED R2

### 추가 사례

- fixture HTML의 독립 승인 목록 `productSceneIds=['main','boarding','intro']`는 그대로 두고 manifest의 `productScenes`에서 `intro`를 제거한다.
- CLI는 exit 1, `automationPassed:false`, `intro`를 명시한 오류를 반환해야 한다.

### 집중 실행 결과

- 명령: `node --test scripts/design-baseline.test.cjs`
- leaf 결과: 기존 20건 통과, 신규 1건 실패.
- Node 집계: `tests 24 / pass 22 / fail 2` (실패 leaf 1건과 상위 AC-2 그룹 1건).
- 실제 실패: CLI가 누락된 승인 제품 장면을 감지하지 않고 exit 0을 반환해 `0 !== 1` assertion에서 실패했다.
- 실패 분류: 정상 RED. 현재 검사는 productScenes의 부분집합 조건만 확인하며 독립 승인 목록 대비 누락은 확인하지 않는다.

### R2 참조 파일

- `/Users/bonseung/Documents/ChatGPT/new/scripts/design-baseline.test.cjs`
- `/Users/bonseung/Documents/ChatGPT/new/.dev/codex-test-phase-0-baseline/reports/t1-red.md`

## 재현 RED R3

### 깨짐 명명

- 필수 검토 이름을 독립 HTML 계약이 아니라 현재 manifest 키에서만 추론하면 누락된 `productScreenCoverage`를 놓친다.
- `requiredBaselineReviews` 선언 자체의 부재를 허용하면 검토 완전성의 기준이 사라진다.
- CLI가 오타 옵션, 값 없는 `--root`, 초과 인자, 존재하지 않는 root를 정상 형식으로 수용하면 잘못된 대상 또는 기본 프로젝트를 감사할 수 있다.

### 추가 사례

- `productScreenCoverage` 필수 검토 누락 1건, `requiredBaselineReviews` HTML 리터럴 누락 1건.
- `--rooot <root>`, 값 없는 `--root`, `--root <root> extra`, 존재하지 않는 `--root` 경로 4건.

### 집중 실행 결과

- 명령: `node --test scripts/design-baseline.test.cjs`
- leaf 결과: 기존 21건 통과, 신규 6건 실패.
- Node 집계: `tests 31 / pass 24 / fail 7` (실패 leaf 6건과 상위 R3 그룹 1건).
- 필수 검토/선언 누락, `--rooot`, 초과 인자: CLI가 exit 0을 반환해 `0 !== 1`로 실패했다.
- 값 없는 `--root`: JSON stdout 없이 uncaught `ERR_INVALID_ARG_TYPE` stack trace로 실패했다.
- 존재하지 않는 root: JSON stdout 없이 uncaught `ENOENT` stack trace로 실패했다.
- 실패 분류: 정상 RED. 기존 동작은 유지되며 필수 검토 완전성과 CLI 입력 경계만 미구현이다.

### R3 참조 파일

- `/Users/bonseung/Documents/ChatGPT/new/scripts/design-baseline.test.cjs`
- `/Users/bonseung/Documents/ChatGPT/new/.dev/codex-test-phase-0-baseline/reports/t1-red.md`
