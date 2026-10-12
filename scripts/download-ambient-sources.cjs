// Download publicly offered CC0 WAVs through each site's ordinary download flow.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {chromium,browserOptions,completeFirstUse}=require('./qa-browser.cjs');
const out=path.resolve(__dirname,'../.impeccable/review/audio-sources');fs.mkdirSync(out,{recursive:true});
const sources=[
 {key:'rain',number:'1295',title:'Rain on car windshield',url:'https://bigsoundbank.com/rain-on-car-windshield-s1295.html'},
 {key:'forest',number:'0905',title:'Forest: On the Edge',url:'https://bigsoundbank.com/forest-on-the-edge-s0905.html'},
 {key:'bus',number:'0644',title:'London bus',url:'https://bigsoundbank.com/london-bus-s0644.html'},
 {key:'pink',number:'0432',title:'Pink Noise',url:'https://bigsoundbank.com/pink-noise-s0432.html'}
];
(async()=>{
 const browser=await chromium.launch(browserOptions());
 try {
  const results=await Promise.all(sources.map(async source=>{
   const page=await browser.newPage({acceptDownloads:true});
   await page.goto(source.url,{waitUntil:'domcontentloaded'});
   const text=await page.locator('body').innerText();
   if(!text.includes('CC0 (public domain)'))throw Error('Missing source license: '+source.key);
   fs.writeFileSync(out+'/'+source.key+'.html',await page.content());
   const form=page.locator('form[action="/download.php"]').first();await form.locator('select[name="format"]').selectOption('wav');
   const pending=page.waitForEvent('download',{timeout:90000});await form.locator('input[type="submit"]').click();
   const download=await pending;await download.saveAs(out+'/'+source.key+'-original.wav');
   if(await download.failure())throw Error(await download.failure());
   const bytes=fs.readFileSync(out+'/'+source.key+'-original.wav');if(bytes.toString('ascii',0,4)!=='RIFF')throw Error('Invalid WAV');
   const result={...source,author:'Joseph SARDIN',license:'CC0-1.0',licenseUrl:'https://bigsoundbank.com/licenses.html',downloadUrl:download.url(),originalFilename:download.suggestedFilename(),bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
   console.log(JSON.stringify({downloaded:source.key,bytes:bytes.length}));await page.close();return result;
  }));
  fs.writeFileSync(out+'/downloads.json',JSON.stringify(results,null,2));
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exit(1)});
