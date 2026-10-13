const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const {chromium,browserOptions,completeFirstUse}=require('./qa-browser.cjs');
const out=path.resolve(__dirname,'../.impeccable/review/recorded-audio');fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await chromium.launch(browserOptions());
 const page=await browser.newPage({viewport:{width:390,height:844}}),errors=[],requests=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(/(cc0-v1|bus-cabin-hum-v1)\.wav/.test(r.url()))requests.push(r.url())});
 await page.goto('http://127.0.0.1:8796/animation-preview.html?scene=sound');
 const results=[];
 for(const [id,label,channels,duration] of [['white','핑크 노이즈',2,30],['rain','빗소리',1,40],['forest','숲 소리',2,40],['bus','버스 엔진',2,40]]){
  await page.getByRole('button',{name:'◖ '+label,exact:true}).click();await page.locator('#soundPreview').click();
  await page.waitForFunction(()=>previewNodes.length===2&&Math.abs(previewNodes[1].gain.value-.65)<1e-6);
  const decoded=await page.evaluate(()=>({state:audioContext.state,loop:previewNodes[0].loop,channels:previewNodes[0].buffer.numberOfChannels,duration:previewNodes[0].buffer.duration,gain:previewNodes[1].gain.value}));
  assert.equal(decoded.state,'running');assert(decoded.loop);assert.equal(decoded.channels,channels);assert.equal(decoded.duration,duration);assert(Math.abs(decoded.gain-.65)<1e-6);
  await page.evaluate(()=>{window.stoppedPreview=previewNodes.slice();window.previewEnded=false;stoppedPreview[0].onended=()=>window.previewEnded=true});
  await page.locator('#soundPreview').click();await page.waitForFunction(()=>window.previewEnded);assert.equal(await page.evaluate(()=>previewNodes.length),0);
  assert.equal(await page.evaluate(()=>window.stoppedPreview[1].gain.value),0);
  results.push({id,decoded,startAndStopFade:true});
 }
 // Render the actual playback helper over two loops, checking fades and the repeated seam.
 const rendered=await page.evaluate(async()=>{
  const saved=audioContext,results=[];
  for(const id of ['white','rain','forest','bus']){
   const buffer=await audioBuffers.get(id),rate=buffer.sampleRate,frames=buffer.length;
   audioContext=new OfflineAudioContext(buffer.numberOfChannels,frames*2,rate);playSoundBuffer(buffer);
   const result=await audioContext.startRendering();let peak=0,seam=0,adjacent=[];
   for(let channel=0;channel<result.numberOfChannels;channel++){
    const samples=result.getChannelData(channel);const assertStart=Math.abs(samples[0]);if(assertStart>1e-8)throw Error('Abrupt start');
    for(let i=0;i<samples.length;i++)peak=Math.max(peak,Math.abs(samples[i]));
    seam=Math.max(seam,Math.abs(samples[frames]-samples[frames-1]));
    for(let i=rate;i<rate*2;i++)adjacent.push(Math.abs(samples[i]-samples[i-1]));
   }
   adjacent.sort((a,b)=>a-b);const p99=adjacent[Math.floor(adjacent.length*.99)];
   results.push({id,peak,seam,adjacentP99:p99,frames,rate});
  }
  audioContext=saved;return results;
 });
 for(const r of rendered){assert(r.peak<.5);assert(r.seam<=r.adjacentP99*1.15,JSON.stringify(r))}
 await page.evaluate(()=>{show('sound');pendingSound='rain';renderSoundChoices()});await page.locator('#soundPreview').click();await page.waitForFunction(()=>previewNodes.length===2);
 await page.getByRole('button',{name:'◖ 숲 소리',exact:true}).click();assert.equal(await page.evaluate(()=>previewNodes.length),0);
 await page.locator('#soundPreview').click();await page.waitForFunction(()=>previewNodes.length===2);await page.locator('#soundApply').click();await page.waitForTimeout(130);assert.equal(await page.evaluate(()=>previewNodes.length),0);
 await page.evaluate(()=>{selectedSound='forest';hasTaskSelection=true;taskText='실제 소리 재생 검사';show('focus')});await page.waitForFunction(()=>audioNodes.length===2);
 await page.locator('#focusPause').click();await page.waitForTimeout(130);assert.equal(await page.evaluate(()=>audioNodes.length),0);
 await page.locator('#focusPause').click();await page.waitForFunction(()=>audioNodes.length===2);
 await page.evaluate(()=>show('main'));await page.waitForTimeout(130);assert.equal(await page.evaluate(()=>audioNodes.length),0);
 assert.equal(requests.length,4,'Decoded recordings must be cached across preview/travel');
 // Network failure stays recoverable; it must never restart an earlier selection.
 await page.route('**/forest-edge-cc0-v1.wav',r=>r.abort());await page.evaluate(()=>{audioBuffers.delete('forest');show('sound');pendingSound='forest';renderSoundChoices()});await page.locator('#soundPreview').click();await page.waitForFunction(()=>$('soundNotice').textContent.includes('재생하지 못했어요'));assert.equal(await page.evaluate(()=>previewNodes.length),0);
 await page.unroute('**/forest-edge-cc0-v1.wav');await page.locator('#soundPreview').click();await page.waitForFunction(()=>previewNodes.length===2);await page.locator('#soundPreview').click();
 for(const [width,height] of [[1280,1040],[390,844],[320,568]]){
  await page.setViewportSize({width,height});await page.evaluate(()=>{show('sound');pendingSound='none';renderSoundChoices()});await page.waitForTimeout(200);
  const contained=await page.evaluate(()=>{const panel=$('sound').getBoundingClientRect(),button=$('soundApply').getBoundingClientRect();return button.bottom<=panel.bottom&&$('sound').scrollWidth<=$('sound').clientWidth});assert(contained);
 }
 const capture=await browser.newPage({viewport:{width:402,height:874}});await capture.goto('http://127.0.0.1:8796/animation-preview.html?capture=1&scene=sound');await capture.evaluate(()=>document.fonts.ready);await capture.waitForTimeout(250);
 await capture.locator('.phone').screenshot({path:path.resolve(__dirname,'../.impeccable/review/research-flow/sound.png')});
 await capture.pdf({path:path.resolve(__dirname,'../.impeccable/review/research-flow/sound.pdf'),width:'402px',height:'874px',margin:{top:0,right:0,bottom:0,left:0},printBackground:true});
 assert.deepEqual(errors,[]);const report={passed:true,decoded:results,offlineRendered:rendered,cachedAcrossScenes:true,failureRecovery:true,pageErrors:errors,limit:'Real Web Audio decoding/rendering; no speaker or headphone listening assessment.'};fs.writeFileSync(out+'/verification.json',JSON.stringify(report,null,2));console.log(JSON.stringify(report));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
