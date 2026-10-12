const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,browserOptions}=require('./qa-browser.cjs');
const out=path.resolve(__dirname,'../.impeccable/review/home-preview');fs.mkdirSync(out,{recursive:true});
(async()=>{const browser=await chromium.launch(browserOptions());try{
 const cases=[];
 for(const [width,height] of [[1280,1040],[390,844],[390,650],[320,568],[280,656]]){
  const page=await browser.newPage({viewport:{width,height}});
  await page.goto('http://127.0.0.1:8796/animation-preview.html?scene=time');
  await page.waitForTimeout(250);
  for(const minutes of [40,360]){
   await page.evaluate(minutes=>{beginTimeSelection(minutes);chooseTimeJourney('2014')},minutes);await page.waitForTimeout(250);
   const layout=await page.evaluate(()=>{const phone=document.querySelector('.phone').getBoundingClientRect(),panel=$('time').getBoundingClientRect(),scroll=$('time').querySelector('.sheet-scroll'),footer=$('time').querySelector('.sheet-footer').getBoundingClientRect();return {panel:panel.left>=phone.left&&panel.right<=phone.right&&panel.top>=phone.top,footer:footer.bottom<=phone.bottom-10,scroll:scroll.scrollWidth<=scroll.clientWidth+1,legacyHidden:$('home').classList.contains('hidden')&&$('startJourney').getClientRects().length===0};});assert(Object.values(layout).every(Boolean),JSON.stringify({width,height,minutes,layout}));cases.push({width,height,minutes,layout});
  }
  await page.locator('#routePreview').click();assert.equal(await page.evaluate(()=>previewDuration),12000);assert.equal(await page.evaluate(()=>progress),0);
  await page.locator('#timeRuler').focus();await page.keyboard.press('ArrowLeft');assert.equal(await page.evaluate(()=>previewRunning),false);
  await page.evaluate(()=>{selectTime(40);chooseTimeJourney('2014')});await page.locator('#book').click();assert.equal(await page.evaluate(()=>scene),'prepare');await page.close();
 }
 fs.writeFileSync(out+'/verification.json',JSON.stringify({passed:true,cases},null,2));console.log(JSON.stringify({passed:true,cases:cases.length,flow:'minute selection directly to preparation; fixed preview/CTA and canceled preview on time change'}));
 }finally{await browser.close()}})().catch(error=>{console.error(error);process.exitCode=1});
