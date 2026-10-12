const fs = require('node:fs');
const path = require('node:path');

let root;
const report = {
  automationPassed: true,
  phase0Complete: false,
  errors: [],
  pendingReviews: ['browser'],
  counts: { product: 0, internal: 0, design: 0 },
};
function error(file, detail) {
  report.errors.push({ code: 'BASELINE_MISMATCH', path: String(file), detail });
}
function locate(file) {
  if (typeof file !== 'string' || !file || path.isAbsolute(file)) throw new Error('Expected a relative file path');
  const candidate = path.resolve(root, file);
  const outside = resolved => { const relative = path.relative(fs.realpathSync(root), resolved); return relative === '..' || relative.startsWith(`..${path.sep}`) || path.isAbsolute(relative); };
  if (outside(candidate)) throw new Error('Path is outside the project root');
  const resolved = fs.realpathSync(candidate);
  if (outside(resolved)) throw new Error('Symlink is outside the project root');
  if (!fs.statSync(resolved).isFile()) throw new Error('Expected a file');
  return resolved;
}
function read(file) {
  try {
    const resolved = locate(file);
    if (path.extname(resolved) === '.pen') throw new Error('Pen content requires Pencil MCP; existence checks only');
    return fs.readFileSync(resolved);
  } catch (cause) { error(file, cause.message); return null; }
}
function compare(source, target) {
  const a = read(source), b = read(target);
  if (a && b && !a.equals(b)) error(target, `Copy differs from ${source}`);
}
function audit() {
  const manifest = json('docs/design-baseline.json');
  if (!manifest) return;
  report.counts = { product: manifest.productScenes.length, internal: manifest.internalScenes.length, design: manifest.states.length };
  compare(manifest.artifacts.sourceHtml, manifest.artifacts.packagedHtml);
  for (const file of manifest.artifacts.requiredFiles) {
    try { locate(file); } catch (cause) { error(file, cause.message); }
  }
  try { locate(manifest.artifacts.pen); } catch (cause) { error(manifest.artifacts.pen, cause.message); }
  for (const pair of manifest.artifacts.copies) compare(pair.source, pair.target);
  function stringsLiteral(file, name, pairs = false) {
    const bytes = read(file);
    if (!bytes) return [];
    const literal = bytes.toString('utf8').match(new RegExp(`const\\s+${name}\\s*=\\s*\\[([\\s\\S]*?)\\];`));
    if (!literal) { error(file, `Missing literal ${name} array`); return []; }
    const expression = pairs ? /\[\s*['"]([^'"]+)['"]\s*,/g : /['"]([^'"]+)['"]/g;
    return [...literal[1].matchAll(expression)].map(match => match[1]);
  }
  function unique(values, file) {
    const seen = new Set();
    for (const value of values) {
      if (seen.has(value)) error(file, `Duplicate ${value}`);
      seen.add(value);
    }
    return seen;
  }
  function equalMembers(a, b, file) {
    for (const value of a) if (!b.has(value)) error(file, `Unmatched ${value}`);
    for (const value of b) if (!a.has(value)) error(file, `Unmatched ${value}`);
  }
  function json(file) {
    const bytes = read(file);
    try { return bytes ? JSON.parse(bytes.toString('utf8')) : null; }
    catch (cause) { error(file, cause.message); return null; }
  }
  const internal = unique(manifest.internalScenes, 'internalScenes');
  const product = unique(manifest.productScenes, 'productScenes');
  equalMembers(product, unique(stringsLiteral(manifest.artifacts.sourceHtml, 'productSceneIds'), manifest.artifacts.sourceHtml), 'productScenes');
  equalMembers(internal, unique(stringsLiteral(manifest.artifacts.sourceHtml, 'sceneIds'), manifest.artifacts.sourceHtml), 'internalScenes');
  for (const scene of product) if (!internal.has(scene)) error('productScenes', `Unknown ${scene}`);
  const viewer = unique(stringsLiteral(manifest.artifacts.viewer, 'cases', true), manifest.artifacts.viewer);
  const layers = json(manifest.artifacts.layers);
  if (layers) equalMembers(viewer, unique(layers.map(layer => layer.scene), manifest.artifacts.layers), manifest.artifacts.layers);
  const snapshot = json(manifest.artifacts.snapshot);
  const nodeIds = new Set();
  function collect(nodes) {
    for (const node of nodes) { if (node.id) nodeIds.add(node.id); if (node.children) collect(node.children); }
  }
  if (snapshot) collect(snapshot.nodes);
  const states = unique(manifest.states.map(state => state.viewerKey), 'states');
  equalMembers(viewer, states, 'states');
  unique(manifest.states.map(state => state.penNode), 'states.penNode');
  for (const state of manifest.states) {
    if (!internal.has(state.scene)) error(state.viewerKey, `Unknown scene ${state.scene}`);
    if (!nodeIds.has(state.penNode)) error(state.viewerKey, `Unknown Pen node ${state.penNode}`);
  }
  report.pendingReviews = [];
  if (!manifest.reviews || !manifest.reviews.browser) error('reviews.browser', 'Browser review is required');
  const requiredReviews = unique(stringsLiteral(manifest.artifacts.sourceHtml, 'requiredBaselineReviews'), manifest.artifacts.sourceHtml);
  for (const name of requiredReviews) {
    if (!manifest.reviews || !Object.hasOwn(manifest.reviews, name)) {
      report.pendingReviews.push(name);
      error(`reviews.${name}`, 'Required review is missing');
    }
  }
  for (const [name, review] of Object.entries(manifest.reviews || {})) {
    if (review.status !== 'passed') report.pendingReviews.push(name);
    if (!['pending', 'passed'].includes(review.status)) error(`reviews.${name}`, 'Review status must be pending or passed');
  }
}
const args = process.argv.slice(2);
try {
  if (args.length !== 0 && !(args.length === 2 && args[0] === '--root' && args[1])) {
    throw new Error(`Expected no arguments or --root <directory>; received ${JSON.stringify(args)}`);
  }
  root = fs.realpathSync(path.resolve(args.length ? args[1] : path.join(__dirname, '..')));
  if (!fs.statSync(root).isDirectory()) throw new Error('Expected a project directory');
} catch (cause) { error('arguments', cause.message); }
if (report.errors.length === 0) {
  try { audit(); } catch (cause) { error('docs/design-baseline.json', cause.message); }
}
report.automationPassed = report.errors.length === 0;
report.phase0Complete = report.automationPassed && report.pendingReviews.length === 0;
console.log(JSON.stringify(report, null, 2));
process.exitCode = report.automationPassed ? 0 : 1;
