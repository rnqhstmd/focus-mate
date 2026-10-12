const fs=require('node:fs');
const {chromium}=require('playwright');

function browserOptions(){
  const configured=process.env.FOCUS_MATE_BROWSER_PATH;
  const windowsChrome='C:/Program Files/Google/Chrome/Application/chrome.exe';
  const executablePath=configured||(process.platform==='win32'&&fs.existsSync(windowsChrome)?windowsChrome:undefined);
  return {headless:true,...(executablePath?{executablePath}:{}),timeout:30000};
}

async function completeFirstUse(page){
  if(await page.evaluate(()=>scene)!=='issue')return;
  if(!await page.evaluate(()=>currentPass())){
    await page.locator('#issueCardAction').click();
    await page.waitForFunction(()=>!passIssuing&&!!currentPass());
  }
  await page.locator('#issueCardAction').click();
  await page.locator('#searchConfirm').click();
  await page.evaluate(()=>show('main'));
}

module.exports={chromium,browserOptions,completeFirstUse};
