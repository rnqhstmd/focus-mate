import json, os, subprocess, time
from pathlib import Path
root = Path(__file__).resolve().parents[3]
dev = root / '.dev/codex-feat-live-activity-design'
env = dict(os.environ, FOCUSMATE_SIMULATOR_ID='F5C2655F-70B3-4B70-AFCA-77813611A4AC', FOCUSMATE_DERIVED_DATA=str(root / '.build/w17-ios'))
commands = [('node','test',['npm','test'],'warn'),('node','build',['npm','run','build'],'warn'),('ios-swiftui','test',['python3','scripts/check-ios.py','test'],'warning:'),('ios-swiftui','build',['python3','scripts/check-ios.py','build'],'warning:'),('python-scripts','test',['python3','-m','unittest','discover','-s','scripts/tests','-t','scripts'],'Warning:'),('python-scripts','build',['python3','-m','compileall','-q','scripts/route_data','scripts/build_route_data.py'],'Warning:')]
results=[]
for kind,action,cmd,pattern in commands:
    log=dev / ('baseline-'+kind+'-'+action+'.log')
    start=time.time()
    print('START',kind,action,flush=True)
    with log.open('w') as f: result=subprocess.run(cmd,cwd=root,env=env,stdout=f,stderr=subprocess.STDOUT)
    warnings=sum(pattern.lower() in line.lower() for line in log.read_text(errors='replace').splitlines())
    results.append(dict(type=kind,action=action,command=cmd,exit_code=result.returncode,seconds=round(time.time()-start,1),warnings=warnings,log=str(log)))
    (dev/'reports/baseline-results.json').write_text(json.dumps(results,indent=2))
    print('DONE',results[-1],flush=True)
    if result.returncode: raise SystemExit(result.returncode)
