"""Discover an observed Luaq loader layout and build its capture adapter automatically."""
from pathlib import Path
import hashlib, importlib.util, json, re, shutil, subprocess
from .lift import literal, lift
ROOT=Path(__file__).resolve().parent.parent
TOKEN=re.compile(r'--\[(=*)\[.*?\]\1\]|--[^\n]*|\[(=*)\[.*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[A-Za-z_]\w*|\+=|-=|\*=|/=|%=|\^=|\S',re.S)


def normalize(source):
    if not source.isascii():raise ValueError('Automatic discovery currently requires an ASCII protected wrapper')
    tokens=list(TOKEN.finditer(source));edits=[]
    for i,m in enumerate(tokens):
        if m.group()in ['+=','-=','*=','/=','%=','^=']:
            prev=tokens[i-1]
            if not re.fullmatch(r'[A-Za-z_]\w*',prev.group()):raise ValueError('Unsupported compound assignment')
            edits.append((m.start(),m.end(),'='+prev.group()+m.group()[0]))
        elif m.group()=='continue':edits.append((m.start(),m.end(),'__continue()'))
    for a,b,r in reversed(edits):source=source[:a]+r+source[b:]
    return source


def apply(source,edits):
    for start,end,text in sorted(edits,reverse=True):
        if start!=end and text.endswith(';')and source[end:end+1]==';':text=text[:-1]
        source=source[:start]+text+source[end:]
    return source.replace('__continue()','continue')


def make_hook(d,ops,offline=False):
    r=d['roles'];f=d['fields'];cfg=d['profile']
    hook=(ROOT/'luaq/templates/completion.luau').read_text()
    hook=hook.replace('local __completionVM,__completionDecode,__completionLanes=f,s,l','do local __completionVM,__completionDecode,__completionLanes='+','.join([r['vm'],r['decode'],r['lanes']])+'\nlocal E,z,B,P,U,tFetch='+','.join([r['builtin'],r['xor'],r['mix'],r['constant'],r['child'],r['fetch']]))
    hook=hook.replace('pcall(T,proto','pcall(tFetch,proto').replace('local packet=T(proto','local packet=tFetch(proto')
    # Replace fields simultaneously: sequential replacements can collide across randomized names.
    mapping={'h':f['packetCount'],'G':f['seed'],'P':f['packetCache'],'E':f['packetRaw'],'R':f['childCache'],'N':f['childRegion'],'D':f['constantCount']}
    hook=re.sub(r'\bproto\.([hGPERND])\b',lambda m:'proto.'+mapping[m[1]],hook)
    hook=hook.replace('root.G','root.'+f['seed'])
    a=hook.index("     if bank=='d'");b=hook.index('\n     decoded+=1',a)
    rows=[]
    for i,(bank,args)in enumerate(cfg['decoder_calls'].items()):
        parts=[{'decode':'__completionDecode','lanes':'__completionLanes','error':'E['+str(d['errorIndex'])+']'}.get(x,x)for x in args.split(',')]
        rows.append(('     if'if i==0 else'     elseif')+" bank=='"+bank+"'then __completionVM:"+bank+'('+','.join(parts)+')')
    hook=hook[:a]+'\n'.join(rows)+' end'+hook[b:]
    hook=hook.replace('E[32]','E['+str(d['errorIndex'])+']')
    meta={int(k):{'bank':v['bank'],'params':v['packet_params'],'constants':v['constant_slots'],'children':v['child_slots']}for k,v in ops.items()}
    hook=hook.replace('METADATA',literal(meta))+'\nend\n'
    if offline:hook=hook.replace('for pc=1,proto.'+f['packetCount']+' do','for pc=1,proto.'+f['packetCount']+' do pcall(tFetch,proto,pc,B(proto.'+f['seed']+',0));')
    return hook


def capture_source(source,d,ops,prefix,offline_regions=None,bootstrap=None):
    r=d['roles'];f=d['fields'];i=d['instrument'];edits=[]
    def insert(pos,text):edits.append((pos,pos,text))
    def replace(pos,text):edits.append((*pos,text))
    insert(i['environment']['position'],r['environment']+'=__LQ_CAPTURE.environment('+r['environment']+');')
    p=i['proto'];insert(p['start'],'local __captureImage='+p['input']+';');insert(p['emit'],'__LQ_CAPTURE.emit("prototype",'+p['result']+'.'+f['seed']+',0,"",__captureImage);')
    p=i['region'];insert(p['start'],'local __captureSeed,__captureKind,__captureIndex='+p['proto']+'.'+f['seed']+','+p['label']+','+p['index']+';');replace(p['ret'],'local __capturePlain='+p['expr']+';__LQ_CAPTURE.emit("region",__captureSeed,__captureIndex,__captureKind,__capturePlain);return __capturePlain;')
    p=i['constant'];insert(p['position'],'__LQ_CAPTURE.emit("constant",'+p['proto']+'.'+f['seed']+','+p['index']+',type('+p['value']+'),type('+p['value']+')=="string"and '+p['value']+' or tostring('+p['value']+'));')
    if offline_regions is None:
        insert(i['hook'],make_hook(d,ops))
        insert(i['entry'],'if __LQ_CAPTURE.stopBeforeApplication then __LQ_CAPTURE.emit("application_execution_skipped",__LQ_CAPTURE.applicationRoot.'+f['seed']+',0,"","capture-only");return function()end end;')
        insert(i['session']['position'],'__LQ_CAPTURE.phase="application";__LQ_CAPTURE.emit("session_stream",0,0,"",'+i['session']['stream']+');')
        p=i['application'];replace(p['range'],'local __applicationImage='+p['image']+';local '+p['variable']+'='+r['parse']+'(__applicationImage);__LQ_CAPTURE.emit("application_root",'+p['variable']+'.'+f['seed']+',0,"",__applicationImage);__LQ_CAPTURE.applicationRoot='+p['variable']+';')
    else:
        p=d['resolve'];proto,label,index=p['parameters'][:3]
        insert(p['head'],'local __clear=__offlineRegions[tostring('+proto+'.'+f['seed']+')..":"..'+label+'..":"..tostring('+index+')];if __clear then __LQ_CAPTURE.emit("region",'+proto+'.'+f['seed']+','+index+','+label+',__clear);return __clear end;')
        replace(d['bootstrap']['remove'],make_hook(d,ops,True)+'__LQ_CAPTURE.applicationRoot='+r['parse']+'('+literal(bootstrap.decode('latin1'))+');return function()end;')
        # Use byte literals, not UTF-8 conversion, for binary prototype data.
        wrong=literal(bootstrap.decode('latin1'));right=byte_literal(bootstrap)
        edits=[(a,b,t.replace(wrong,right))for a,b,t in edits]
        head='local warn=print\nlocal writefile=function(name,value)print(value)end\nlocal __offlineRegions={'+','.join('['+literal(k)+']='+byte_literal(v)for k,v in offline_regions.items())+'}\n'
        prefix=head+prefix
    return prefix+'\nlocal function __captureRun(...)\n'+apply(source,edits)+'\n'+(ROOT/'luaq/templates/capture_suffix.luau').read_text()


def byte_literal(value):
    return '"'+''.join(chr(c)if 32<=c<=126 and c not in (34,92)else'\\'+str(c).zfill(3)for c in value)+'"'


def module_at(path):
    spec=importlib.util.spec_from_file_location('luaq_auto_recovery',path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module


def prepare(input_path,out,node,luau,compiler):
    out=out.resolve();profile=out/'profile';profile.mkdir(parents=True)
    raw=input_path.read_bytes();source=normalize(raw.decode('utf8'));normalized=out/'normalized.lua';normalized.write_text(source)
    result=subprocess.run([str(node),str(ROOT/'luaq/discover.cjs'),str(normalized),str(profile)],capture_output=True,text=True,timeout=120)
    (out/'discovery.log').write_text(result.stdout+result.stderr)
    if result.returncode:raise ValueError('Automatic discovery failed; see discovery.log. No input application was run.')
    d=json.loads((profile/'discovery.json').read_text());cfg=d['profile'];cfg['input_sha256']=hashlib.sha256(raw).hexdigest();crypto=d['crypto'];capsule=d['capsule']
    (profile/'capsule_fields.json').write_text(json.dumps(capsule,indent=2))
    template=(ROOT/'luaq/profiles/sample2/recovery.py').read_text()
    template=template.replace("['S','W','l','w','a']",repr(d['wire_order'])).replace(" p['W'],p['l']=p['l'],p['W']\n",'')
    a=template.index(" f=json.loads((ROOT/'capsule_fields.json').read_text());build=");b=template.index('\n authkey=',a)
    template=template[:a]+" f=json.loads((ROOT/'capsule_fields.json').read_text());build=f["+repr(crypto['build'])+"].encode();secret=xor(base93(f["+repr(crypto['secret'][0])+"]),base93(f["+repr(crypto['secret'][1])+ "]));nonce=base93(f["+repr(crypto['nonce'])+"]);blob=base93(f["+repr(crypto['blob'])+"][5:])"+template[b:]
    template=template.replace("base93(f['x'])",'base93(f['+repr(crypto['auth'])+'])').replace('if typ==95:v=frame(v)','if typ=='+str(cfg['constant_tags'][-1])+':v=frame(v)')
    (profile/'recovery.py').write_text(template)
    importer=(ROOT/'luaq/profiles/sample2/import_capture.py').read_text().replace('in[75,95]','in'+repr(cfg['constant_tags'][-2:]))
    (profile/'import_capture.py').write_text(importer);shutil.copy2(ROOT/'luaq/profiles/sample2/rbxm_capture.py',profile/'rbxm_capture.py')
    m=module_at(profile/'recovery.py');regions={};original=m.access
    def access(p,kind,index,region,token):
        value=original(p,kind,index,region,token)
        if value is not None:regions[f'{p["w"]}:{kind}:{index}']=value
        return value
    m.access=access;m.ALL=[];image=m.extract_bootstrap();m.recover(m.proto(image),'bootstrap')
    totals={'bootstrap_bytes':len(image),'prototypes':len(m.ALL),'constants':sum(len(p['constants'])for _,p in m.ALL),'packet_records':sum(len(p['packets'])for _,p in m.ALL),'verified_operands':sum('operands'in x for _,p in m.ALL for x in p['packets'].values()),'unresolved_regions':sum(len(v)for _,p in m.ALL for v in p['unresolved'].values())}
    if totals['unresolved_regions']or not totals['verified_operands']:raise ValueError('Bootstrap data did not recover completely')
    # Internal runtime strings are decoded as data; do not run the original crypto or bootstrap VM.
    internals={}
    for i,(encoded,seed,stride)in enumerate(d['internal_constants'],1):internals[i]=bytes(c^((seed+j*stride)%256)for j,c in enumerate(m.base93(encoded),1))
    r=d['roles'];runtime='-- Intermediate decoded application. Clean-source reconstruction is a separate stage.\nlocal function __recovered(environment,...)\n'+d['runtime']['builtins']+'\nlocal internalErrors={'+','.join('['+str(i)+']='+byte_literal(v)for i,v in internals.items())+'}\nlocal function '+r['internal']+'(i)return internalErrors[i]or("Luaq error "..i)end\nlocal '+r['unpack']+'=table.unpack\nlocal '+r['xor']+'=bit32.bxor\nlocal function '+r['mix']+'(value,index)\n index=(index*0x79b9+bit32.lshift(index,16)*0x9e37)%4294967296\n value=bit32.bxor(value,index);value=bit32.bxor(value,bit32.lshift(value,13));value=bit32.bxor(value,bit32.rshift(value,17));return bit32.bxor(value,bit32.lshift(value,5))\nend\n'+d['runtime']['support']+'\n'
    (profile/'runtime_prefix.luau').write_text(runtime)
    prefix=(ROOT/'luaq/templates/capture_prefix.luau').read_text().replace('bac1f4e0-cb24-4dfb-ad25-a2a5bc3500d2',cfg['build']).replace('luaq-runtime-capture.jsonl','luaq-'+cfg['build'][:8]+'-capture.jsonl').replace('folderName = "LuaqCapture"','folderName = "LuaqCapture_'+cfg['build'][:8]+'"')
    prefix=prefix.replace('stopBeforeApplication = false','stopBeforeApplication = __LUAQ_CAPTURE_ONLY == true')
    prefix=prefix.replace('local ok, message = api.Flush(false)','if api.Complete then local ok,message=pcall(api.Complete);if not ok then api.emit("completion_error",0,0,"",tostring(message))end end\nlocal ok, message = api.Flush(false)')
    ops=json.loads((profile/'packet_handlers.json').read_text());runner=capture_source(source,d,ops,prefix)
    (out/'capture_runner.luau').write_text(runner);(profile/'capture_runner.luau').write_text(runner)
    checked=subprocess.run([str(compiler),str(out/'capture_runner.luau')],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True,timeout=120)
    if checked.returncode:raise ValueError('Generated runner does not compile: '+checked.stderr)
    # Exercise helper boundaries and all bootstrap operand banks under the bounded offline runtime.
    offline=capture_source(source,d,ops,prefix,regions,image);test=out/'capture_offline.test.luau';test.write_text(offline)
    checked=subprocess.run([str(luau),str(test)],capture_output=True,text=True,timeout=120);(out/'offline.log').write_text(checked.stdout);(out/'offline_errors.log').write_text(checked.stderr)
    if checked.returncode:raise ValueError('Offline capture check failed; see offline_errors.log')
    rows=[json.loads(x)for x in checked.stdout.splitlines()if x.startswith('{')];errors=[x for x in rows if x.get('kind')in ['execution_error','completion_error','completion_probe_error']]
    if errors:raise ValueError('Offline capture traversal failed: '+str(errors[:1]))
    actual={(x['seed'],x['index']):x for x in rows if x.get('kind')=='constant'}
    for _,p in m.ALL:
        for index,c in p['constants'].items():
            got=actual.get((p['w'],index))
            if not got:raise ValueError('Offline capture missed a bootstrap constant')
            if c['type']in cfg['constant_tags'][-2:]and got['data_hex']!=c['hex']:raise ValueError('Offline constant mismatch')
    if not any(x.get('kind')=='completion_status'and bytes.fromhex(x['data_hex']).decode().endswith('read failures=0')for x in rows):raise ValueError('Offline traversal did not complete')
    cfg['validation']='Automatically discovered; bootstrap authentication, all available packet operands and offline capture traversal validated. Application validation remains separate.'
    (profile/'profile.json').write_text(json.dumps(cfg,indent=2)+'\n')
    # A Studio export is assembled with the same exact compiled runner.
    xml='<roblox version="4"><Item class="Script" referent="AutoCapture"><Properties><string name="Name">LuaqCaptureRunner</string><bool name="Disabled">false</bool><ProtectedString name="Source"><![CDATA['+runner.replace(']]>',']]]]><![CDATA[>')+']]></ProtectedString></Properties></Item></roblox>'
    (out/'CaptureRunner.rbxmx').write_text(xml)
    place='<roblox version="4"><Item class="Workspace" referent="Workspace"><Properties><string name="Name">Workspace</string></Properties></Item><Item class="ReplicatedStorage" referent="Storage"><Properties><string name="Name">ReplicatedStorage</string></Properties></Item><Item class="HttpService" referent="Http"><Properties><string name="Name">HttpService</string><bool name="HttpEnabled">true</bool></Properties></Item><Item class="ServerScriptService" referent="Server"><Properties><string name="Name">ServerScriptService</string></Properties>'+xml.split('<roblox version="4">',1)[1].rsplit('</roblox>',1)[0]+'</Item></roblox>'
    (out/'CaptureStudio.rbxlx').write_text(place);(profile/'CaptureStudio.rbxlx').write_text(place)
    manifest={str(p.relative_to(profile)):hashlib.sha256(p.read_bytes()).hexdigest()for p in profile.rglob('*')if p.is_file()and '__pycache__'not in p.parts and p.name!='manifest.json'};(profile/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    report={'status':'CAPTURE_READY','build':cfg['build'],'profile':str(profile),'bootstrap':totals,'capture_filename':'luaq-'+cfg['build'][:8]+'-capture.jsonl','application_recovered':False,'clean_source_available':False,'next_step':'Run capture_runner.luau or CaptureStudio.rbxlx in the intended environment, then process the returned capture.','note':'Automatic discovery supports the observed 107-statement loader family. New structural families fail explicitly.'}
    (out/'prepare_report.json').write_text(json.dumps(report,indent=2)+'\n');return report
