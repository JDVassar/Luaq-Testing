"""Import this sample's runtime capture. Does not run the captured application."""
from pathlib import Path
import argparse, json, xml.etree.ElementTree as ET, importlib.util, hashlib, sys
HERE=Path(__file__).resolve().parent

def read_capture(path):
 raw=path.read_bytes()
 if raw.startswith(b'<roblox!'):
  from rbxm_capture import extract
  raw,_=extract(path)
 text=raw.decode('utf-8-sig')
 if text.lstrip().startswith('<'):
  tree=ET.fromstring(text);chunks={}
  for item in tree.iter('Item'):
   if item.get('class')!='StringValue':continue
   props=item.find('Properties')
   if props is None:continue
   fields={child.get('name'):child.text or '' for child in props}
   name=fields.get('Name','')
   if name.startswith('Chunk_'):
    number=int(name[6:]);assert number not in chunks,'Duplicate capture chunks'
    chunks[number]=fields.get('Value','')
  assert chunks,'No Luaq capture StringValues found; save the LuaqCapture Folder, not the runner Script'
  assert sorted(chunks)==list(range(1,len(chunks)+1)),'Missing capture chunks'
  text=''.join(chunks[k] for k in sorted(chunks))
 records=[json.loads(line) for line in text.splitlines() if line.strip()]
 assert records and records[0].get('format')=='luaq-runtime-capture-v1','Not a Luaq runtime capture'
 return records[0],records[1:]

def main():
 ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('capture',type=Path);ap.add_argument('--out',type=Path,default=HERE/'imported');ap.add_argument('--phase',choices=['application','bootstrap'],default='application');args=ap.parse_args()
 header,records=read_capture(args.capture);dest=args.out.resolve();dest.mkdir(parents=True,exist_ok=True)
 (dest/'capture.jsonl').write_text('\n'.join(json.dumps(x) for x in [header]+records)+'\n')
 errors=[bytes.fromhex(x['data_hex']).decode('utf8','replace') for x in records if x.get('kind')=='execution_error']
 roots=[x for x in records if x.get('kind')=='application_root' and x.get('phase')==args.phase]
 candidates=[x for x in records if x.get('kind')=='prototype' and x.get('phase')==args.phase]
 if args.phase=='bootstrap' and not roots and candidates:roots=[candidates[0]]
 if not roots:
  status={'status':'NO_APPLICATION_ROOT','errors':errors,'records':len(records),'message':'The loader did not reach the application image. Preserve the error; a Roblox environment or successful server response is still needed.'}
  (dest/'status.json').write_text(json.dumps(status,indent=2));print(json.dumps(status,indent=2));return 2
 # recover.py's helpers are imported without running its bootstrap main routine.
 spec=importlib.util.spec_from_file_location('luaq_recovery',HERE/'recovery.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
 module.ALL=[]
 regions={}
 for row in records:
  if row.get('phase')==args.phase and row.get('kind')=='region':regions[(row['seed'],row['label'],row['index'])]=bytes.fromhex(row['data_hex'])
 original_access=module.access
 def access(p,kind,index,region,token):
  captured=regions.get((p['w'],kind,index))
  if captured is not None:return captured
  if len(region[0]) < 44:return None  # A remote region ID is not an encrypted region body.
  return original_access(p,kind,index,region,token)
 module.access=access
 seen=set()
 for n,row in enumerate(roots,1):
  data=bytes.fromhex(row['data_hex']);digest=hashlib.sha256(data).hexdigest()
  if digest in seen:continue
  seen.add(digest);(dest/f'application_root_{n}.bin').write_bytes(data)
  module.recover(module.proto(data),f'application_{n}')
 # Retain any executed prototype not reachable using the available parent region records.
 seeds={p['w'] for _,p in module.ALL}
 for row in candidates:
  if row['seed'] in seeds:continue
  p=module.proto(bytes.fromhex(row['data_hex']));module.recover(p,f'observed_{p["w"]}');seeds.update(p['w'] for _,p in module.ALL)
 summary=[];metadata={};symbols=[];raw=[]
 semantics=json.loads((HERE/'semantics_by_opcode.json').read_text())
 for name,p in module.ALL:
  file=name.replace('/','_');metadata[name]={k:p[k] for k in ['Q','K','w','X','a','l','S','W','u','R']}
  (dest/(file+'.constants.json')).write_text(json.dumps(p['constants'],indent=2));(dest/(file+'.packets.json')).write_text(json.dumps(list(p['packets'].values()),indent=2))
  summary.append({'path':name,'seed':p['w'],'constants_recovered':len(p['constants']),'constants_total':p['R'],'packets_recovered':len(p['packets']),'packets_total':p['u'],'unresolved_regions':p['unresolved']})
  for i,value in sorted(p['constants'].items()):
   if value['type']in[75,95]:symbols.append(f'{name} K[{i}] '+json.dumps(value['text']))
  raw.extend([f'\nPROTOTYPE {name} SEED {p["w"]}', 'Constants: '+json.dumps(p['constants'])])
  for pc,item in sorted(p['packets'].items()):
   raw.append(f'PC {pc:05d} OP {item["opcode"]} '+json.dumps(item))
   if str(item['opcode']) in semantics:raw.append('HANDLER '+semantics[str(item['opcode'])][0]['source'])
 (dest/'recovery_summary.json').write_text(json.dumps(summary,indent=2));(dest/'prototype_metadata.json').write_text(json.dumps(metadata,indent=2));(dest/'strings.txt').write_text('\n'.join(symbols)+'\n');(dest/'packet_ir.txt').write_text('\n'.join(raw)+'\n')
 observed=[row for row in records if row.get('phase')==args.phase and row.get('kind')=='constant'];(dest/'runtime_constants.json').write_text(json.dumps(observed,indent=2))
 status={'status':'APPLICATION_DATA_RECOVERED' if args.phase=='application' else 'BOOTSTRAP_TEST_RECOVERED','phase':args.phase,'prototypes':len(summary),'constants':sum(x['constants_recovered'] for x in summary),'packets':sum(x['packets_recovered'] for x in summary),'unresolved_regions':sum(len(v) for x in summary for v in x['unresolved_regions'].values()),'errors':errors,'note':'These outputs are recovered data and IR, not original source. Regions never supplied by the server may remain missing.'}
 (dest/'status.json').write_text(json.dumps(status,indent=2));print(json.dumps(status,indent=2));return 0
if __name__=='__main__':
 try:sys.exit(main())
 except (AssertionError,ValueError,IndexError,KeyError) as error:raise SystemExit('Capture import failed: '+str(error))
