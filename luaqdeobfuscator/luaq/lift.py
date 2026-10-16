"""Run trusted profile operand-bank decoders over already authenticated packet data."""
import json, subprocess, shutil
from pathlib import Path


def literal(v):
    if v is None:return 'nil'
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,(int,float)):return str(v)
    if isinstance(v,str):return '"'+''.join(chr(c) if 32<=c<=126 and c not in (34,92) else '\\'+str(c).zfill(3) for c in v.encode())+'"'
    if isinstance(v,list):return '{'+','.join(literal(x)for x in v)+'}'
    return '{'+','.join('['+literal(k)+']='+literal(x)for k,x in v.items())+'}'

CALLS1={'D':'L,u,t,a,K,Z,W,Y,N,J,error','s':'J,Y,N,W,t,K,a,u,error,Z,L','X':'a,K,J,error,Y,L,Z,W,N,t,u','J':'u,t,N,K,Y,error,W,J,Z,a,L','v':'a,t,N,u,K,Y,J,L,error,W,Z','M':'a,J,Z,N,L,t,error,K,Y,W,u'}
CALLS2={'d':'c,error,z,F,lanes,I,D,decode,V,m,t','s':'c,V,error,m,F,lanes,decode,D,t,I,z','S':'c,error,V,I,lanes,z,t,m,decode,D,F','H':'lanes,D,z,m,error,F,I,c,decode,V,t'}


def lift(profile, out, luau):
    cfg=json.loads((profile/'profile.json').read_text());meta=json.loads((out/'prototype_metadata.json').read_text())
    shutil.copy2(profile/'decoder_methods.luau',out/'decoder_methods.luau')
    code=['''local VM=require("./decoder_methods")
local function json(v)
 if type(v)=="number" then return tostring(v) end
 local out={}
 for k,x in pairs(v)do if k~=0 then out[#out+1]='"'..k..'":'..json(x)end end
 return "{"..table.concat(out,",").."}"
end
local u,z=bit32.bxor,bit32.bxor
''']
    expected=0
    for name,p in meta.items():
        packets=json.loads((out/(name.replace('/','_')+'.packets.json')).read_text())
        for packet in packets:
            if 'operands' not in packet:continue
            expected+=1
            code.append('do local operands='+literal(packet['operands'])+';local ptr=0;local perm='+str(packet['register_permutation'])+';local mapping={}\n')
            code.append('for i=1,'+str(p['K'])+' do mapping[i]=bit32.bxor(i-1,perm)+1 end\n')
            code.append('local function decode() return function() ptr+=1;assert(operands[ptr]~=nil,"operand overread");return operands[ptr] end,function()return mapping,'+str(packet['next_access_state'])+' end end\n')
            if cfg['id']=='sample1':
                code.append('local K={K='+str(p['K'])+',o={}};local Y={[0]={}};local J,a=0,0;local N='+str(packet['pc']+1)+';local Z='+str(packet['opcode'])+';local W={0,0,0};local L='+literal(packet['raw'])+';local t=decode\n')
                code.append('VM:'+packet['bank']+'('+CALLS1[packet['bank']]+')\nlocal result=Y\n')
            else:
                code.append('local F={'+cfg['proto_fields']['K']+'='+str(p['K'])+','+cfg['register_cache']+'={}};local I={[0]={}};local c='+str(packet['pc']+1)+';local D='+literal(packet['raw'])+';local V,m,t=0,'+str(packet['opcode'])+',0;local lanes={0,0,0}\n')
                code.append('VM:'+packet['bank']+'('+cfg.get('decoder_calls',CALLS2)[packet['bank']]+')\nlocal result=I\n')
            code.append('assert(ptr==#operands,"operand underread");result[0]=nil;print("LIFT\\t"..'+literal(name)+'.."\\t'+str(packet['pc'])+'\\t'+str(packet['opcode'])+'\\t"..json(result))\nend\n')
    (out/'lift_operands.luau').write_text(''.join(code))
    result=subprocess.run([str(luau),str(out/'lift_operands.luau')],capture_output=True,text=True,timeout=120)
    (out/'lift.log').write_text(result.stdout);(out/'lift_errors.log').write_text(result.stderr)
    if result.returncode:raise ValueError('Operand lifting failed; see lift_errors.log')
    lifted=[]
    for line in result.stdout.splitlines():
        if not line.startswith('LIFT\t'):continue
        _,name,pc,op,operands=line.split('\t')
        lifted.append({'prototype':name,'pc':int(pc),'opcode':int(op),'operands':json.loads(operands)})
    if len(lifted)!=expected:raise ValueError('Incomplete operand lift')
    (out/'lifted_operands.json').write_text(json.dumps(lifted,indent=2))
    return len(lifted)
