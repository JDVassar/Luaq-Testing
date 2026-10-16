"""Read StringValue capture chunks from Roblox binary model v0; never execute scripts.
Format reference: https://dom.rojo.space/binary.html
"""
from pathlib import Path
import struct

def lz4_block(data,expected):
 out=bytearray();i=0
 def length(base):
  nonlocal i
  n=base
  if base==15:
   while True:
    x=data[i];i+=1;n+=x
    if x!=255:break
  return n
 while i<len(data):
  token=data[i];i+=1;n=length(token>>4)
  assert i+n<=len(data);out.extend(data[i:i+n]);i+=n
  if i==len(data):break
  offset=int.from_bytes(data[i:i+2],'little');i+=2;assert 0<offset<=len(out)
  n=length(token&15)+4
  assert len(out)+n<=expected
  for _ in range(n):out.append(out[-offset])
 assert len(out)==expected;return bytes(out)
class Reader:
 def __init__(self,data):self.data=data;self.i=0
 def u32(self):v=struct.unpack_from('<I',self.data,self.i)[0];self.i+=4;return v
 def u8(self):v=self.data[self.i];self.i+=1;return v
 def string(self):n=self.u32();v=self.data[self.i:self.i+n];self.i+=n;assert len(v)==n;return v

def extract(path):
 data=Path(path).read_bytes();assert data[:14]==b'<roblox!\x89\xff\r\n\x1a\n';assert struct.unpack_from('<H',data,14)[0]==0
 i=32;classes={};properties={};inventory=[]
 while i<len(data):
  name,compressed,size,reserved=struct.unpack_from('<4sIII',data,i);i+=16
  assert size<=256*1024*1024,'Chunk too large';body=data[i:i+(compressed or size)];i+=compressed or size
  if compressed:
   if body[:4]==b'\x28\xb5\x2f\xfd':
    try:import zstandard
    except ImportError:raise ValueError('Zstandard chunk needs the optional zstandard package')
    body=zstandard.ZstdDecompressor().decompress(body,max_output_size=size)
   else:body=lz4_block(body,size)
  assert len(body)==size
  r=Reader(body)
  if name==b'INST':
   cls=r.u32();typ=r.string().decode();r.u8();count=r.u32();classes[cls]=(typ,count);inventory.append({'class':typ,'count':count})
  elif name==b'PROP':
   cls=r.u32();prop=r.string().decode();typ=r.u8()
   if typ==1 and prop in ['Name','Value','Source']:
    count=classes[cls][1];values=[r.string() for _ in range(count)];properties[(cls,prop)]=values
  elif name==b'END\0':break
 chunks={}
 for cls,(typ,count) in classes.items():
  if typ!='StringValue':continue
  names=properties.get((cls,'Name'),[]);values=properties.get((cls,'Value'),[])
  assert len(names)==len(values)==count
  for name,value in zip(names,values):
   name=name.decode()
   if name.startswith('Chunk_'):
    number=int(name[6:]);assert number not in chunks,'Duplicate capture chunk';chunks[number]=value
 assert chunks,'No capture StringValues found'
 assert sorted(chunks)==list(range(1,len(chunks)+1)),'Missing capture chunks'
 return b''.join(chunks[k] for k in sorted(chunks)),inventory
if __name__=='__main__':
 import sys,json
 text,inventory=extract(sys.argv[1]);Path(sys.argv[2]).write_bytes(text);print(json.dumps({'inventory':inventory,'capture_bytes':len(text)},indent=2))
