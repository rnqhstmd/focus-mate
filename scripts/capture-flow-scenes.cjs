const fs=require('node:fs'),path=require('node:path');
const {chromium,browserOptions,completeFirstUse}=require('./qa-browser.cjs');
(async()=>{
 const browser=await chromium.launch(browserOptions());
 try{
  const page=await browser.newPage({viewport:{width:402,height:874},timezoneId:'Asia/Seoul'}),out=path.resolve(__dirname,'../.impeccable/review/research-flow'),url='http://127.0.0.1:8796/animation-preview.html';
  await page.goto(url);const cases=await page.evaluate(()=>flowStudy.cases);fs.writeFileSync(out+'/cases.json',JSON.stringify(cases,null,2));
  const regionFile=out+'/card-regions.json';const regions=fs.existsSync(regionFile)?JSON.parse(fs.readFileSync(regionFile,'utf8')):{};const keys=process.argv.slice(2);for(const [key] of cases){if(keys.length&&!keys.includes(key))continue;await page.goto(url+'?capture=1&scene='+key);await page.evaluate(()=>document.fonts.ready);await page.waitForTimeout(300);await page.locator('.phone').screenshot({path:out+'/'+key+'.png'});await page.addStyleTag({content:'@media print{.tagged .transit-card,.pass-contact{filter:none!important}}'});await page.emulateMedia({media:'print'});regions[key]=await page.evaluate(()=>Array.from(document.querySelectorAll('.pass-face')).filter(node=>{const r=node.getBoundingClientRect();if(r.width<1||r.height<1)return false;for(let e=node;e&&e!==document.body;e=e.parentElement){const c=getComputedStyle(e);if(c.display==='none'||c.visibility==='hidden'||Number(c.opacity)===0)return false;}return true;}).map(node=>{const r=node.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,radius:parseFloat(getComputedStyle(node).borderRadius)||14};}));await page.pdf({path:out+'/'+key+'.pdf',width:'402px',height:'874px',margin:{top:0,right:0,bottom:0,left:0},printBackground:true});await page.emulateMedia({media:'screen'});console.log('Captured '+key)}
 fs.writeFileSync(regionFile,JSON.stringify(regions,null,2));
 }finally{await browser.close()}
})().catch(error=>{console.error(error);process.exitCode=1});
