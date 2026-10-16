"""Capture loader data in standalone Lune, with the protected application disabled."""
from pathlib import Path
import json,shutil,subprocess
from .lift import literal
ROOT=Path(__file__).resolve().parent.parent

def standalone(job,lune,timeout=120):
    job=job.resolve();profile=job/'profile';cfg=json.loads((profile/'profile.json').read_text())
    runner=job/'capture_runner.luau'
    if '__LQ_CAPTURE.stopBeforeApplication then'not in runner.read_text():
        raise ValueError('This job predates capture-only support. Generate it again with process.')
    # Derive the service origins from the authenticated bootstrap, not from external input URLs.
    import importlib.util
    spec=importlib.util.spec_from_file_location('luaq_local_recovery',profile/'recovery.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
    m.ALL=[];m.recover(m.proto((profile/'bootstrap.bin').read_bytes()),'bootstrap')
    from urllib.parse import urlsplit
    origins=set()
    for _,p in m.ALL:
        for c in p['constants'].values():
            if c['type']in cfg['constant_tags'][-2:]and c['text'].startswith('https://'):
                u=urlsplit(c['text']);origins.add(u.scheme+'://'+u.netloc+'/')
    if not origins:raise ValueError('No HTTPS service origin found in the authenticated bootstrap')
    directory=job/'standalone';directory.mkdir(exist_ok=True)
    shutil.copy2(ROOT/'luaq/templates/roblox_bootstrap.luau',directory/'roblox_bootstrap.luau')
    capture=directory/'capture.jsonl'
    program='''local fs=require('@lune/fs')
local originalRequire=require
local net=originalRequire('@lune/net')
local compat=originalRequire('./roblox_bootstrap')
local origins=__ORIGINS__
local calls=0
local safeNet={request=function(options)
 local url=type(options)=='string'and options or options.url
 local allowed=false
 for _,origin in ipairs(origins)do if type(url)=='string'and string.sub(url,1,#origin)==origin then allowed=true;break end end
 assert(allowed,'Unexpected loader request destination')
 calls+=1
 print('[standalone loader] HTTP request '..calls)
 return net.request(options)
end}
local modules={['@lune/net']=safeNet,['@lune/serde']=originalRequire('@lune/serde'),['@lune/task']=originalRequire('@lune/task')}
local environment=setmetatable({
 require=function(name)assert(modules[name],'Unexpected runtime module');return modules[name]end,
 http_request=function(options)
  local response=safeNet.request({url=options.Url,method=options.Method,headers=options.Headers,body=options.Body})
  return{Success=response.ok,StatusCode=response.statusCode,StatusMessage=response.statusMessage,Body=response.body,Headers=response.headers}
 end,
 writefile=function(_,data)fs.writeFile(__CAPTURE__,data)end,
 warn=print,
 __LUAQ_CAPTURE_ONLY=true,
 task=false,
},{__index=getfenv()})
for key,value in pairs(compat)do environment[key]=value end
local source=fs.readFile(__SOURCE__)
local chunk=assert(loadstring(source,'standalone-luaq-loader'));setfenv(chunk,environment)
local success,message=pcall(chunk)
print('[standalone loader] Requests: '..calls)
if not success then error(message,0)end
'''.replace('__ORIGINS__',literal(sorted(origins))).replace('__CAPTURE__',literal(str(capture))).replace('__SOURCE__',literal(str(runner)))
    launcher=directory/'run.luau';launcher.write_text(program)
    result=subprocess.run([str(lune),'run',str(launcher)],capture_output=True,text=True,timeout=timeout)
    (directory/'run.log').write_text(result.stdout);(directory/'errors.log').write_text(result.stderr)
    if result.returncode:raise ValueError('Standalone capture did not complete; see standalone/errors.log. No executor fallback was run.')
    if not capture.is_file():raise ValueError('Standalone loader did not write a capture')
    rows=[json.loads(x)for x in capture.read_text().splitlines()]
    if rows[0].get('build')!=cfg['build']:raise ValueError('Standalone capture has the wrong build')
    if not any(x.get('kind')=='application_root'for x in rows):raise ValueError('Standalone loader did not reach an application image')
    if not any(x.get('kind')=='application_execution_skipped'for x in rows):raise ValueError('Capture-only stop marker was not observed')
    report={'status':'STANDALONE_APPLICATION_CAPTURED','capture':str(capture),'runtime':'Lune','executor_used':False,'roblox_client_used':False,'application_executed':False,'network_required':True,'capture_only_stop_seen':True,'http_request_count':result.stdout.count('[standalone loader] HTTP request '),'service_origins':sorted(origins),'build':cfg['build'],'clean_source_available':False}
    (directory/'report.json').write_text(json.dumps(report,indent=2)+'\n');return report
