const fs=require('fs'),path=require('path'),assert=require('assert/strict');
const {chromium,browserOptions,completeFirstUse}=require('./qa-browser.cjs');
const out=path.resolve(__dirname,'../.impeccable/review/main-welcome');fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=await chromium.launch(browserOptions());
 const errors=[],results=[];
 const page=await browser.newPage({viewport:{width:1280,height:1040},timezoneId:'Asia/Seoul'});
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:8796/animation-preview.html');
 assert.equal(await page.locator('#mainWelcomeTitle').innerText(),'오늘은 어디에서\n출발해볼까요?');
 assert.equal(await page.evaluate(()=>scene),'issue');await completeFirstUse(page);
 const greetings=['고요한 밤이에요.','좋은 아침이에요.','좋은 오후예요.','오늘도 수고했어요.'];
 for(const [i,hour] of [0,6,12,18].entries()){
  await page.evaluate(hour=>syncMainWelcome(hour),hour);assert.equal(await page.locator('#mainGreeting').innerText(),greetings[i]);
 }
 for(let index=0;index<9;index++){
  await page.evaluate(index=>{onboarded=true;startOffset=index;show('main');syncMainWelcome(9)},index);
  assert.equal(await page.locator('#mainLocation').innerText(),await page.evaluate(()=>stopNames[startOffset]));
  assert((await page.locator('#mainWelcomeTitle').innerText()).startsWith(await page.evaluate(()=>stationWelcomes[startOffset].place+'에서,')));
 }
 results.push('first-use and four time periods; all nine saved stations');
 // The actual alighting action must update the greeting from its reached station.
 await page.evaluate(()=>{startOffset=0;onboarded=true;hasTaskSelection=true;selectedTag=pendingTag='read';draftTask=taskText='한 챕터 읽기';$('taskInput').value=draftTask;selectTime(25);show('alighting')});
 const landing=await page.evaluate(()=>stopIndex(totalStops));await page.locator('#alightCard').press('Enter');await page.waitForTimeout(1100);await page.locator('#arrivalHome').click();
 assert.equal(await page.evaluate(()=>scene),'main');assert.equal(await page.evaluate(()=>startOffset),landing);
 assert((await page.locator('#mainWelcomeTitle').innerText()).startsWith(await page.evaluate(()=>stationWelcomes[startOffset].place+'에서,')));
 await page.reload();assert.equal(await page.evaluate(()=>startOffset),landing);assert((await page.locator('#mainWelcomeTitle').innerText()).includes('에서,'));
 await page.locator('#mainStart').click();assert.equal(await page.evaluate(()=>scene),'time');results.push('alight, persisted relaunch, and normal start');
 for(const [width,height] of [[1280,1040],[390,844],[390,650],[320,568],[280,656]]){
  const p=await browser.newPage({viewport:{width,height},timezoneId:'Asia/Seoul'});p.on('pageerror',e=>errors.push(e.message));
  await p.goto('http://127.0.0.1:8796/animation-preview.html');await completeFirstUse(p);
  for(const index of [6,8]){
   await p.evaluate(index=>{onboarded=true;startOffset=index;show('main');syncMainWelcome(9)},index);await p.waitForTimeout(250);
   const layout=await p.evaluate(()=>{
    const rect=e=>e.getBoundingClientRect(),welcome=rect(document.querySelector('.main-welcome')),pin=rect(document.querySelector('.main-location')),
     tools=rect(document.querySelector('.main-tools')),button=rect($('mainStart')),phone=rect(document.querySelector('.phone'));
    return {welcomeInPhone:welcome.left>=phone.left&&welcome.right<=phone.right&&welcome.bottom<=phone.bottom,
     pinSeparated:welcome.bottom+8<=pin.top,toolsSeparated:tools.bottom+8<=welcome.top,buttonVisible:button.bottom<=phone.bottom-6};
   });assert(Object.values(layout).every(Boolean),JSON.stringify({width,height,index,layout}));
  }
  if(width===390&&height===844)await p.screenshot({path:out+'/mobile.png'});
  if(width===1280)await p.screenshot({path:out+'/desktop.png'});
  await p.emulateMedia({reducedMotion:'reduce'});await p.locator('#mainStart').click();assert.equal(await p.evaluate(()=>scene),'time');
  await p.close();
 }
 results.push('five viewport sizes: welcome, tools, location pin, and start remain separate');
 const capture=await browser.newPage({viewport:{width:402,height:874},timezoneId:'Asia/Seoul'});
 await capture.goto('http://127.0.0.1:8796/animation-preview.html?capture=1&scene=main');
 await capture.evaluate(()=>{onboarded=true;startOffset=8;show('main');syncMainWelcome(9)});await capture.evaluate(()=>document.fonts.ready);
 await capture.locator('.phone').screenshot({path:out+'/seongsu.png'});
 await capture.goto('http://127.0.0.1:8796/animation-preview.html?capture=1&scene=main');
 await capture.evaluate(()=>{onboarded=false;show('main');syncMainWelcome(9)});
 await capture.locator('.phone').screenshot({path:path.resolve(__dirname,'../.impeccable/review/research-flow/main.png')});
 await capture.pdf({path:path.resolve(__dirname,'../.impeccable/review/research-flow/main.pdf'),width:'402px',height:'874px',margin:{top:0,right:0,bottom:0,left:0},printBackground:true});
 await capture.goto('http://127.0.0.1:8796/animation-preview.html?capture=1&scene=main-saved');await capture.evaluate(()=>syncMainWelcome(9));
 await capture.locator('.phone').screenshot({path:path.resolve(__dirname,'../.impeccable/review/research-flow/main-saved.png')});
 await capture.pdf({path:path.resolve(__dirname,'../.impeccable/review/research-flow/main-saved.pdf'),width:'402px',height:'874px',margin:{top:0,right:0,bottom:0,left:0},printBackground:true});
 assert.deepEqual(errors,[]);fs.writeFileSync(out+'/verification.json',JSON.stringify({passed:true,results,pageErrors:errors},null,2));
 console.log(JSON.stringify({passed:true,results,pageErrors:errors}));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
