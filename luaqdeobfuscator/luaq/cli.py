"""CLI for pinned-build Luaq capture import and semantic devirtualization."""
import argparse, hashlib, importlib.util, json, os, re, shutil, subprocess, sys, time
from pathlib import Path
from .lift import lift

ROOT=Path(__file__).resolve().parent.parent
PROFILES=ROOT/'luaq/profiles'


def load_module(path):
    spec=importlib.util.spec_from_file_location('luaq_capture_reader',path)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module


def profiles():
    return [(p,json.loads((p/'profile.json').read_text()))for p in sorted(PROFILES.iterdir())if (p/'profile.json').is_file()]


def validate_assets(profile):
    for name,digest in json.loads((profile/'manifest.json').read_text()).items():
        if hashlib.sha256((profile/name).read_bytes()).hexdigest()!=digest:
            raise ValueError('Profile asset changed: '+name)


def identify(path):
    raw=path.read_bytes();digest=hashlib.sha256(raw).hexdigest()
    found=next(((p,c)for p,c in profiles()if c['input_sha256']==digest),None)
    ids=re.findall(rb'\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\b',raw)
    return found,{'input':str(path.resolve()),'sha256':digest,'bytes':len(raw),'luaq_banner':b'Luaq Obfuscator' in raw[:1000],
                 'build_candidates':list(dict.fromkeys(x.decode()for x in ids)),
                 'supported':found is not None,'profile':found[1]['id']if found else None,
                 'note':'A matching build profile is available. Application recovery may still require a runtime capture.'if found else 'Unknown input. A new randomized VM profile must be derived; no code was executed.'}


def fresh_output(path):
    path=path.resolve()
    if path.exists() and (not path.is_dir()or any(path.iterdir())):raise ValueError('Output must be a new or empty directory: '+str(path))
    path.mkdir(parents=True,exist_ok=True);return path


def read_captures(paths):
    # Reader handles JSONL and XML/binary Roblox capture folders; it never executes Scripts.
    sys.path.insert(0,str(PROFILES/'sample1'))
    reader=load_module(PROFILES/'sample1/import_capture.py');header=None;rows=[];seen=set();payloads={}
    for path in paths:
        head,items=reader.read_capture(path)
        if header is not None and head.get('build')!=header.get('build'):raise ValueError('Cannot merge captures from different builds')
        header=head
        for row in items:
            kind=row.get('kind')
            if kind in ['prototype','application_root','region','constant']:
                # Reject contradictory cleartext, rather than silently overwriting a recovered value.
                key=(row.get('phase'),kind,row.get('seed'),row.get('label'),row.get('index'))
                content=row.get('data_hex')
                if key in payloads and payloads[key]!=content:raise ValueError('Conflicting capture payload for '+str(key))
                payloads[key]=content
            fingerprint=json.dumps(row,sort_keys=True,separators=(',',':'))
            if fingerprint not in seen:seen.add(fingerprint);rows.append(row)
    return header,rows


def binary(name,override):
    if override:
        p=Path(override).expanduser().resolve()
        if not p.is_file():raise ValueError('Missing executable: '+str(p))
        return p
    installed=shutil.which(name)
    if installed:return Path(installed)
    bundled=ROOT/'bin'/name
    if sys.platform=='darwin'and bundled.is_file():return bundled
    raise ValueError(name+' is required. Supply --'+name+' /path/to/'+name)


def import_data(profile,header,rows,out,phase):
    merged=out/'merged_capture.jsonl'
    merged.write_text('\n'.join(json.dumps(x)for x in [header]+rows)+'\n')
    result=subprocess.run([sys.executable,str(profile/'import_capture.py'),str(merged),'--out',str(out),'--phase',phase],capture_output=True,text=True,timeout=180)
    (out/'import.log').write_text(result.stdout+result.stderr)
    if result.returncode:raise ValueError('Capture import did not complete. See import.log and status.json.')
    return json.loads((out/'status.json').read_text())


def wait_for_capture(path,build,timeout):
    deadline=time.monotonic()+timeout;last=None
    while True:
        try:
            info=path.stat();signature=(info.st_mtime_ns,info.st_size)
            if signature==last:
                header,rows=read_captures([path])
                if header.get('build')!=build:raise ValueError('Capture file belongs to another build')
                if any(x.get('kind')=='application_root'and x.get('phase')=='application'for x in rows):return
            last=signature
        except (FileNotFoundError,json.JSONDecodeError,AssertionError):pass
        if time.monotonic()>=deadline:raise ValueError('Timed out waiting for a complete application capture: '+str(path))
        time.sleep(1)


def main(argv=None):
    ap=argparse.ArgumentParser(description='Luaq Deobfuscator 0.3 — capture-assisted, pinned builds; no universal version claim.')
    sub=ap.add_subparsers(dest='command',required=True)
    sub.add_parser('profiles',help='List tested randomized VM profiles')
    process=sub.add_parser('process',help='Automatically discover the layout, validate it and prepare capture; optionally recover a supplied capture')
    process.add_argument('input',type=Path);process.add_argument('--out',type=Path,required=True)
    process.add_argument('--capture',type=Path);process.add_argument('--luau');process.add_argument('--node');process.add_argument('--luau-compile',dest='compiler')
    local=sub.add_parser('standalone',help='Prepare and capture locally using Lune; no Roblox client or executor, and no application execution')
    local.add_argument('input',type=Path);local.add_argument('--out',type=Path,required=True)
    local.add_argument('--lune');local.add_argument('--luau');local.add_argument('--node');local.add_argument('--luau-compile',dest='compiler')
    local.add_argument('--timeout',type=float,default=120)
    resume=sub.add_parser('resume',help='Recover using a generated job profile; optionally wait for its capture file')
    resume.add_argument('job',type=Path);resume.add_argument('--capture',type=Path,required=True);resume.add_argument('--out',type=Path,required=True)
    resume.add_argument('--wait',action='store_true');resume.add_argument('--timeout',type=float,default=600)
    resume.add_argument('--luau');resume.add_argument('--node');resume.add_argument('--luau-compile',dest='compiler')
    inspect=sub.add_parser('inspect' ,help='Identify an input without executing it');inspect.add_argument('input',type=Path)
    cap=sub.add_parser('capture',help='Export the matching instrumented runner; does not run it');cap.add_argument('input',type=Path);cap.add_argument('--out',type=Path,required=True)
    for command in ['import','recover']:
        p=sub.add_parser(command,help='Import capture data'+(' and emit decoded source'if command=='recover'else ' only'))
        p.add_argument('captures',type=Path,nargs='+');p.add_argument('--out',type=Path,required=True);p.add_argument('--input',type=Path)
        p.add_argument('--profile',type=Path,help='Use an automatically generated profile directory')
        p.add_argument('--phase',choices=['application','bootstrap'],default='application')
        if command=='recover':p.add_argument('--luau');p.add_argument('--node');p.add_argument('--luau-compile',dest='compiler')
    args=ap.parse_args(argv)
    if args.command=='standalone':
        from .prepare import prepare
        from .standalone import standalone
        luau=binary('luau',args.luau);node=binary('node',args.node);compiler=binary('luau-compile',args.compiler);lune=binary('lune',args.lune)
        out=fresh_output(args.out)
        try:
            prepare(args.input,out,node,luau,compiler)
            report=standalone(out,lune,args.timeout)
            code=main(['recover',report['capture'],'--profile',str(out/'profile'),'--out',str(out/'recovery'),'--luau',str(luau),'--node',str(node),'--luau-compile',str(compiler)])
            if code:return code
            report['recovery']=str(out/'recovery');(out/'standalone_report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));return 0
        except Exception as exc:
            (out/'standalone_report.json').write_text(json.dumps({'status':'FAILED','executor_used':False,'clean_source_available':False,'error':str(exc)},indent=2)+'\n');raise
    if args.command=='resume':
        profile=args.job.resolve()/'profile';validate_assets(profile)
        cfg=json.loads((profile/'profile.json').read_text())
        if args.wait:
            print('Waiting for '+str(args.capture)+' ...',flush=True)
            wait_for_capture(args.capture,cfg['build'],args.timeout)
        params=['recover',str(args.capture),'--profile',str(profile),'--out',str(args.out)]
        for flag,value in [('--luau',args.luau),('--node',args.node),('--luau-compile',args.compiler)]:
            if value:params += [flag,value]
        return main(params)
    if args.command=='process':
        from .prepare import prepare
        luau=binary('luau',args.luau);node=binary('node',args.node);compiler=binary('luau-compile',args.compiler)
        out=fresh_output(args.out)
        try:
            report=prepare(args.input,out,node,luau,compiler)
            if args.capture:
                code=main(['recover',str(args.capture),'--input',str(args.input),'--profile',str(out/'profile'),'--out',str(out/'recovery'),'--luau',str(luau),'--node',str(node),'--luau-compile',str(compiler)])
                if code:return code
                report.pop('application_recovered',None)
                report.update(status='INTERMEDIATE_SOURCE_RECOVERED',application_data_recovered=True,recovery=str(out/'recovery'),clean_source_available=False,next_step='Clean-source reconstruction remains required; inspect recovery/report.json for data coverage.',note='Decoded source is an intermediate. Automatic clean-source structuring is not yet implemented.')
            (out/'process_report.json').write_text(json.dumps(report,indent=2)+'\n')
        except Exception as exc:
            (out/'process_report.json').write_text(json.dumps({'status':'FAILED','error':str(exc),'clean_source_available':False},indent=2)+'\n');raise
        print(json.dumps(report,indent=2));return 0
    if args.command=='profiles':
        print(json.dumps([{'profile':c['id'],'build':c['build'],'input_sha256':c['input_sha256']}for _,c in profiles()],indent=2));return 0
    if args.command in ['inspect','capture']:
        match,report=identify(args.input)
        if args.command=='inspect':print(json.dumps(report,indent=2));return 0 if match else 3
        if not match:raise ValueError(report['note'])
        profile,cfg=match;validate_assets(profile);out=fresh_output(args.out)
        shutil.copy2(profile/'capture_runner.luau',out/'capture_runner.luau');shutil.copy2(profile/'CaptureStudio.rbxlx',out/'CaptureStudio.rbxlx')
        report.update(status='RUNNER_EXPORTED',instruction='Run capture_runner.luau in the intended environment, or open CaptureStudio.rbxlx in Studio. This executes the protected application. Import the saved JSONL or capture Folder model afterward.')
        (out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));return 0
    header,rows=read_captures(args.captures)
    if args.profile:
        profile=args.profile.expanduser().resolve()
        cfg=json.loads((profile/'profile.json').read_text())
        match=(profile,cfg)if cfg['build']==header.get('build')else None
    else:match=next(((p,c)for p,c in profiles()if c['build']==header.get('build')),None)
    if not match:raise ValueError('Unsupported capture build: '+str(header.get('build')))
    profile,cfg=match;validate_assets(profile)
    if args.input:
        if hashlib.sha256(args.input.read_bytes()).hexdigest()!=cfg['input_sha256']:raise ValueError('Input does not match the capture profile')
    # Dependency checks happen before creating any output.
    if args.command=='recover':
        luau=binary('luau',args.luau);node=binary('node',args.node);compiler=binary('luau-compile',args.compiler)
    out=fresh_output(args.out)
    report={'tool_version':'0.3.0','profile':cfg['id'],'build':cfg['build'],'status':'IMPORTING','captures':[str(x.resolve())for x in args.captures],
            'profile_validation':cfg.get('validation','Application regression tested'),
            'scope':'Decoded source retains register storage and explicit instruction dispatch. Original names/comments and arbitrary new layouts are not recovered automatically.'}
    try:
        status=import_data(profile,header,rows,out,args.phase);report.update(import_status=status)
        if args.command=='recover':
            if args.phase!='application':raise ValueError('Source emission currently supports application captures only; use import for bootstrap data')
            count=lift(profile,out,luau)
            emitted=subprocess.run([str(node),str(ROOT/'luaq/emit.cjs'),str(profile),str(out)],capture_output=True,text=True,timeout=120)
            (out/'emit.log').write_text(emitted.stdout+emitted.stderr)
            if emitted.returncode:raise ValueError('Source emission failed; see emit.log')
            report.update(json.loads(emitted.stdout));report['lifted_handlers']=count
            compiled=subprocess.run([str(compiler),str(out/'decoded.luau')],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True,timeout=120)
            (out/'compile.log').write_text(compiled.stderr)
            if compiled.returncode:raise ValueError('Generated source did not compile; see compile.log')
            report.update(source='decoded.luau',source_compiles=True,status='DECODED_SOURCE_EMITTED_WITH_COVERAGE_REPORT')
        else:report['status']='DATA_IMPORTED'
        summary=json.loads((out/'recovery_summary.json').read_text())
        report['all_constants_recovered']=all(x['constants_recovered']==x['constants_total']for x in summary)
        report['all_packet_records_recovered']=all(x['packets_recovered']==x['packets_total']for x in summary)
        report['unresolved_regions']=status['unresolved_regions']
        if args.command=='recover':report['every_packet_has_semantics']=report['undecoded_packet_records']==0
        report['note']='Raw padding and unverified packets are retained in undecoded_packets.json. Static data completeness does not prove every reachable branch or live Roblox behavior.'
    except Exception as exc:
        report.update(status='FAILED',error=str(exc));(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');raise
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));return 0


def run():
    try:return main()
    except (ValueError,OSError,AssertionError,KeyError,IndexError,json.JSONDecodeError,subprocess.TimeoutExpired)as exc:
        print('Luaq: '+str(exc),file=sys.stderr);return 2
