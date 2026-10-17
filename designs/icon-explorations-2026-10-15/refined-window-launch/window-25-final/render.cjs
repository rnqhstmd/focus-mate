const fs = require('fs');
const path = require('path');
const sharp = require('/Users/bonseung/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const out = __dirname;
const frames = path.join(out, 'frames');
fs.mkdirSync(frames, {recursive:true});
const symbol = (travel=0) => `<rect x="252" y="336" width="520" height="352" rx="64" fill="none" stroke="white" stroke-width="60"/><path d="M${548+travel} 356V668" stroke="white" stroke-width="36"/><path d="M${272+travel} 512H${308+travel}" stroke="white" stroke-width="48" stroke-linecap="round"/>`;
const icon = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><rect width="1024" height="1024" fill="black"/>${symbol()}</svg>`;
const ease = x => x*x*(3-2*x);
const clamp = x => Math.max(0, Math.min(1,x));
function frame(t) {
  const opening = ease(clamp((t-.2)/.6));
  const leaving = ease(clamp((t-.8)/.45));
  const scale = .49 * (1 + .34*leaving);
  const brand = ease(clamp((t-1.02)/.23));
  return `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="1560" viewBox="0 0 720 1560"><rect width="720" height="1560" fill="black"/><g opacity="${1-leaving}" transform="translate(360 780) scale(${scale}) translate(-512 -512)">${symbol(170*opening)}</g><g opacity="${brand}" fill="white"><rect x="343" y="741" width="34" height="3" rx="1.5"/><text x="360" y="800" text-anchor="middle" font-family="Helvetica Neue,Arial,sans-serif" font-size="31" font-weight="500" letter-spacing="1.2">Focus Mate</text></g></svg>`;
}
(async()=>{
  fs.writeFileSync(path.join(out,'icon-25-bold.svg'),icon);
  await sharp(Buffer.from(icon)).png().toFile(path.join(out,'icon-25-bold.png'));
  for(let i=0;i<96;i++) {
    await sharp(Buffer.from(frame(i/60))).png().toFile(path.join(frames,`${String(i).padStart(4,'0')}.png`));
  }
  for(const [name,t] of [['keyframe-closed',0],['keyframe-open',.8],['keyframe-end',95/60]]) {
    await sharp(Buffer.from(frame(t))).png().toFile(path.join(out,`${name}.png`));
  }
  console.log('Rendered 96 frames, final icon, and 3 keyframes.');
})();
