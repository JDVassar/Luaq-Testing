"""Sample-specific Luaq data recovery. Does not execute the protected payload."""
from pathlib import Path
import struct,hashlib,hmac,json,re
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'recovered'
def mac(k,m):return hmac.digest(k,m,'sha256')
def xor(a,b):assert len(a)==len(b);return bytes(x^y for x,y in zip(a,b))
def rol(v,n):return ((v<<n)|(v>>(32-n)))&0xffffffff
def mix(v,n):
 n=(n*0x79b9+((n<<16)&0xffffffff)*0x9e37)&0xffffffff
 v=v^n;v^=(v<<13)&0xffffffff;v^=v>>17;return (v^((v<<5)&0xffffffff))&0xffffffff
def chacha(data,key,nonce):
 base=list(struct.unpack('<4I',b'expand 32-byte k')+struct.unpack('<8I',key)+(0,)+struct.unpack('<3I',nonce));out=bytearray()
 for off in range(0,len(data),64):
  base[12]=off//64+1;x=base.copy()
  def q(a,b,c,d):
   x[a]=(x[a]+x[b])&0xffffffff;x[d]=rol(x[d]^x[a],16);x[c]=(x[c]+x[d])&0xffffffff;x[b]=rol(x[b]^x[c],12)
   x[a]=(x[a]+x[b])&0xffffffff;x[d]=rol(x[d]^x[a],8);x[c]=(x[c]+x[d])&0xffffffff;x[b]=rol(x[b]^x[c],7)
  for _ in range(10):
   for ids in [(0,4,8,12),(1,5,9,13),(2,6,10,14),(3,7,11,15),(0,5,10,15),(1,6,11,12),(2,7,8,13),(3,4,9,14)]:q(*ids)
  stream=struct.pack('<16I',*((a+b)&0xffffffff for a,b in zip(x,base)));out.extend(xor(data[off:off+64],stream[:len(data[off:off+64])]))
 return bytes(out)
class Reader:
 def __init__(self,b):self.b=b;self.i=0
 def uint(self):
  v=0
  for shift in range(0,35,7):
   x=self.b[self.i];self.i+=1;v|=(x&127)<<shift
   if x<128:return v
  raise ValueError('bad integer')
 def string(self):
  n=self.uint();b=self.b[self.i:self.i+n];self.i+=n;assert len(b)==n;return b
 def end(self):assert self.i==len(self.b),(self.i,len(self.b))
def frame(b):
 mode=b[0];length=struct.unpack('<I',b[1:5])[0]
 if mode==0:assert len(b)==length+5;return b[5:]
 assert mode==1;out=bytearray();i=5
 while len(out)<length:
  flags=b[i];i+=1
  for bit in range(8):
   if len(out)==length:break
   if flags&(1<<bit):
    word=int.from_bytes(b[i:i+2],'little');i+=2;distance=word//16+1
    for _ in range(word%16+3):out.append(out[-distance])
   else:out.append(b[i]);i+=1
 assert i==len(b);assert len(out)==length;return bytes(out)
def proto(b):
 r=Reader(b);p={k:{} for k in ['d','j','q','packets','constants','children']}
 for key in ['Q','K']:p[key]=r.uint()
 p['X']=[r.uint()+1 for _ in range(r.uint())]
 for key in ['l','w','W','a','S']:p[key]=r.uint()
 p['Z']=r.string()
 def region():
  grants={}
  for _ in range(r.uint()):
   key=r.string();grants[key]=r.string()
  return r.string(),grants
 for count,width,table in [('R','I','d'),('u','p','j')]:
  p[count]=r.uint();p[width]=r.uint()
  for i in range(1,(p[count]+p[width]-1)//p[width]+1):p[table][i]=region()
 for i in range(1,r.uint()+1):p['q'][i]=region()
 r.end();return p
def base93(s):
 alphabet="!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
 digits={x:i for i,x in enumerate(alphabet)};out=bytearray();bits=value=0;length=len(s)//2*2
 for i in range(0,length,2):
  v=digits[s[i]]+digits[s[i+1]]*93;value+=v<<bits;bits+=13 if v%8192>456 else 14
  count=2 if bits>=16 else 1
  for _ in range(count):out.append(value&255);value>>=8;bits-=8
 if length<len(s):
  value+=digits[s[-1]]<<bits;assert bits and value<=255;out.append(value)
 else:assert value==0
 return bytes(out)
def extract_bootstrap():
 f=json.loads((ROOT/'capsule_fields.json').read_text());build=f['U'].encode();secret=xor(base93(f['g']),base93(f['s']));nonce=base93(f['m']);blob=base93(f['Y'][5:])
 authkey=mac(secret,b'LUAQ_LOCAL_AUTHENTICATION_KEY_V3\0'+build)
 assert hmac.compare_digest(mac(authkey,b'LUAQ_LOCAL_PAYLOAD_V3\0'+build+b'\0'+nonce+blob),base93(f['K'])),'capsule authentication'
 image=frame(chacha(blob,mac(secret,b'LUAQ_LOCAL_ENCRYPTION_KEY_V3\0'+build),nonce))
 previous=ROOT/'bootstrap.bin'
 if previous.exists():assert previous.read_bytes()==image,'Independent bootstrap extraction mismatch'
 previous.write_bytes(image);return image
ops={int(k):v for k,v in json.loads((ROOT/'packet_handlers.json').read_text()).items()}
ALL=[]
def access(p,kind,index,region,token):
 blob,grants=region;msg=b'LUAQ_ACCESS_V2\0'+kind.encode()+b'\0'+str(index).encode()+b'\0'+struct.pack('<I',token)
 selector=mac(p['Z'],msg+b'\0')[:8]
 if selector not in grants:return None
 key=xor(grants[selector],mac(p['Z'],msg+b'\1'))
 tag=b'LUAQ_REGION_V1\0'+kind.encode()+b'\0'+str(index).encode()
 nonce,expected,data=blob[:12],blob[12:44],blob[44:]
 assert hmac.compare_digest(expected,mac(mac(key,tag+b'\1'),nonce+data)),'authentication failed'
 return chacha(data,mac(key,tag+b'\0'),nonce)
def packet(p,pc,b):
 r=Reader(b);raw=[]
 while r.i<len(b):raw.append(r.uint())
 op=(((raw[0]^mix(p['w'],pc))-p['W'])*p['S'])%65536;raw[0]=op
 if op not in ops:return {'pc':pc,'opcode':op,'raw':raw},None
 a,rotation,mask=ops[op]['packet_params'];state=mix(p['w']^a,pc);nextstate=mix(p['w']^a,pc+op);operands=[]
 for encrypted in raw[1:-2]:
  operand=encrypted^state;operands.append(operand);state=rol(state,rotation)^encrypted^mask;nextstate=rol(nextstate,7)^operand
 permutation=state^raw[-2]
 if not (permutation<p['K'] and raw[-1]==(mix(state,pc+op)^mix(permutation,p['w']))):
  return {'pc':pc,'opcode':op,'raw':raw,'unverified':'operand integrity mismatch; retained as raw data'},None
 return {'pc':pc,'opcode':op,'bank':ops[op]['bank'],'operands':operands,'register_permutation':permutation,'raw':raw,'next_access_state':mix(nextstate,pc+op)},mix(nextstate,pc+op)
ALL=[]
def recover(p,path):
 ALL.append((path,p));tokens={mix(p['w'],0)};done=set();changed=True
 while changed:
  changed=False
  for table,kind in [('d','C'),('j','P'),('q','F')]:
   for index,region in p[table].items():
    if (table,index) in done:continue
    result=None
    for token in sorted(tokens):
     result=access(p,kind,index,region,token)
     if result is not None:break
    if result is None:continue
    done.add((table,index));changed=True
    if kind=='F':p['children'][index]=proto(result);continue
    r=Reader(frame(result))
    start=(index-1)*p['I' if kind=='C' else 'p']+1;end=min(start+p['I' if kind=='C' else 'p'],p['R' if kind=='C' else 'u']+1)
    for i in range(start,end):
     if kind=='C':
      typ=r.uint();encoded=r.string();seed=mix(p['w'],i);v=bytes(c^(mix(seed,j)&255) for j,c in enumerate(encoded,1))
      if typ==62:v=frame(v)
      p['constants'][i]={'type':typ,'hex':v.hex(),'text':v.decode('utf8',errors='replace')}
     else:
      item,newtoken=packet(p,i,r.string());p['packets'][i]=item
      if newtoken is not None:tokens.add(newtoken)
    r.end()
 for i,child in p['children'].items():recover(child,path+'/'+str(i))
 p['unresolved']={k:[i for i in p[k] if (k,i) not in done] for k in ['d','j','q']};p['tokens']=sorted(tokens)

if __name__=='__main__':
 OUT.mkdir(exist_ok=True);root=proto(extract_bootstrap());recover(root,'bootstrap')
 summary=[]
 for path,p in ALL:
  name=path.replace('/','_');(OUT/(name+'.constants.json')).write_text(json.dumps(p['constants'],indent=2));(OUT/(name+'.packets.json')).write_text(json.dumps(list(p['packets'].values()),indent=2));summary.append({'path':path,'seed':p['w'],'constants_recovered':len(p['constants']),'constants_total':p['R'],'packets_recovered':len(p['packets']),'packets_total':p['u'],'unresolved_regions':p['unresolved']})
 (OUT/'prototype_metadata.json').write_text(json.dumps({path:{k:p[k]for k in ['Q','K','w','X','a','l','S','W','u','R']}for path,p in ALL},indent=2))
 (OUT/'recovery_summary.json').write_text(json.dumps(summary,indent=2));print(json.dumps({'prototypes':len(ALL),'constants':sum(len(p['constants'])for _,p in ALL),'packets':sum(len(p['packets'])for _,p in ALL),'supported_packets':sum('operands'in i for _,p in ALL for i in p['packets'].values()),'unresolved_regions':sum(len(v)for _,p in ALL for v in p['unresolved'].values())},indent=2))
