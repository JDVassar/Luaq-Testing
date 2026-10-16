// Specialize authenticated operands into explicit Luau statements. Never execute the application.
const fs=require('fs'),path=require('path'),parse=require('../vendor/luaparse/luaparse.js');
const [profile,dir]=process.argv.slice(2),cfg=require(path.join(profile,'profile.json'));
const sem=require(path.join(profile,cfg.id==='sample1'?'recovered/semantics_by_opcode.json':'semantics_by_opcode.json'));
const meta=require(path.join(dir,'prototype_metadata.json')),lift=require(path.join(dir,'lifted_operands.json'));
const stringBytes=b=>'"'+Array.from(b).map(c=>c>=32&&c<=126&&c!==34&&c!==92?String.fromCharCode(c):'\\'+String(c).padStart(3,'0')).join('')+'"';
function lua(v){if(v==null)return'nil';if(typeof v==='number'||typeof v==='boolean')return String(v);if(typeof v==='string')return stringBytes(Buffer.from(v));if(Array.isArray(v))return'{'+v.map(lua).join(',')+'}';return'{'+Object.entries(v).map(([k,x])=>'['+lua(isNaN(+k)?k:+k)+']='+lua(x)).join(',')+'}';}
function constant(v){const [nil,f,t,num,...str]=cfg.constant_tags;if(v.type===nil)return'nil';if(v.type===f)return'false';if(v.type===t)return'true';if(v.type===num){if(['Infinity','inf'].includes(v.text))return'math.huge';if(['-Infinity','-inf'].includes(v.text))return'-math.huge';if(['NaN','nan'].includes(v.text))return'(0/0)';if(!Number.isFinite(Number(v.text)))throw Error('Invalid number');return v.text;}if(str.includes(v.type))return stringBytes(Buffer.from(v.hex,'hex'));throw Error('Unknown constant tag '+v.type);}
function specialize(source,Y,C,pc){
 source=source.replaceAll('continue;','__continue();');
 const ast=parse.parse(source,{scope:true,ranges:true,luaVersion:'5.3'}),edits=[];
 function val(n){if(n?.type==='NumericLiteral')return n.value;if(n?.type==='IndexExpression'&&n.base?.name===cfg.operand_name&&!n.base.isLocal&&n.index.type==='NumericLiteral')return Y[n.index.value];}
 function walk(n,depth=0){if(!n||typeof n!=='object')return;if(Array.isArray(n)){n.forEach(x=>walk(x,depth));return;}
  if(n.type==='FunctionDeclaration')depth++;
  if(n.type==='ReturnStatement'&&depth===0){edits.push([n.range[0],n.range[0]+6,'return true,pack('],[n.range[1]-(source[n.range[1]-1]===';'?1:0),n.range[1]-(source[n.range[1]-1]===';'?1:0),')']);n.arguments.forEach(x=>walk(x,depth));return;}
  if(n.type==='CallExpression'&&n.base.name===cfg.constant_fn&&!n.base.isLocal&&n.arguments.length===3){let i=val(n.arguments[1]);if(typeof i==='number'&&C[i]){edits.push([...n.range,'('+constant(C[i])+')']);return;}}
  if(n.type==='IndexExpression'&&n.base.name===cfg.operand_name&&!n.base.isLocal&&n.index.type==='NumericLiteral'){let v=Y[n.index.value];if(v===undefined)throw Error('Missing operand at PC '+pc);edits.push([...n.range,'('+lua(v)+')']);return;}
  if(n.type==='Identifier'&&n.isLocal===false&&cfg.rename[n.name]){edits.push([...n.range,cfg.rename[n.name]]);return;}
  for(let[k,v]of Object.entries(n))if(!['range','globals'].includes(k)&&v&&typeof v==='object')walk(v,depth);
 }
 walk(ast);edits.sort((a,b)=>b[0]-a[0]);for(let[a,b,v]of edits)source=source.slice(0,a)+v+source.slice(b);return source.replaceAll('__continue()','continue');
}
let out=[fs.readFileSync(path.join(profile,'runtime_prefix.luau'),'utf8')];
const cf=cfg.constant_fn;
out.push(`local prototypes,constants,steps={},{},{}
local function ${cf}(prototype,index)
 local values=constants[prototype.id]
 if not values.present[index]then error("Uncaptured constant: "..prototype.id.." #"..index,0)end
 return values[index]
end
local function lookupChild(parent,index)
 local id=parent.id.."/"..index
 local child=prototypes[id];assert(child,"Uncaptured child: "..id);return child
end
`);
// Runtime closure adapters refer to the original factory identifier.
if(cfg.id==='sample1')out.push('local Q=lookupChild');else out.push('local '+(cfg.child_fn||'U')+'=lookupChild');
out.push(cfg.aliases);
const byKey=new Map(lift.map(x=>[x.prototype+'@'+x.pc,x]));let records=[],gaps=[];
for(let[id,p]of Object.entries(meta)){
 const C=require(path.join(dir,id.replaceAll('/','_')+'.constants.json'));
 let fields={id};for(let[k,v]of Object.entries(cfg.proto_fields))fields[v]=p[k];
 if(cfg.id==='sample2')Object.assign(fields,{h:p.u});
 out.push('prototypes['+lua(id)+']='+lua(fields)+'\nconstants['+lua(id)+']={present={'+Object.keys(C).map(i=>'['+i+']=true').join(',')+'},'+Object.entries(C).map(([i,v])=>'['+i+']='+constant(v)).join(',')+'}\nsteps['+lua(id)+']={}');
 for(let pkt of require(path.join(dir,id.replaceAll('/','_')+'.packets.json'))){
  let row=byKey.get(id+'@'+pkt.pc);if(!row){gaps.push({prototype:id,pc:pkt.pc,opcode:pkt.opcode,reason:pkt.unverified||'No verified decoder'});continue;}
  const choices=sem[pkt.opcode];if(!choices||new Set(choices.map(x=>x.source)).size!==1)throw Error('Ambiguous semantic opcode '+pkt.opcode);
  const body=specialize(choices[0].source,row.operands,C,pkt.pc);records.push({prototype:id,pc:pkt.pc,opcode:pkt.opcode,body});
  out.push('-- '+id+' PC '+pkt.pc+' opcode '+pkt.opcode+'\nsteps['+lua(id)+']['+pkt.pc+']=function(frame)\n local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs\n local nextPc,accessState='+(pkt.pc+1)+','+pkt.next_access_state+'\n do '+body+' end\n frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs\n return false\nend');
 }
}
const f=cfg.proto_fields;
out.push(`
${cfg.main_name}=function(prototype,upvalues,environment,parent,index)
 local fn
 fn=function(...)
  if not prototype then prototype=lookupChild(parent,index);parent=nil end
  assert(prototype.${f.Q}==0,"Unsupported native prototype")
  local registers={}
  local args=${cfg.pack_name}(...)
  for i=1,#prototype.${f.X} do registers[prototype.${f.X}[i]]=args[i]end
  local varargs={n=0}
  if prototype.${f.a}~=0 then varargs.n=math.max(0,args.n-#prototype.${f.X});for i=1,varargs.n do varargs[i]=args[#prototype.${f.X}+i]end end
  local frame={prototype=prototype,registers=registers,upvalues=upvalues,environment=environment,pc=1,varargs=varargs}
  while ${cfg.running_name} do
   local step=steps[prototype.id][frame.pc]
   assert(step,"Undecoded instruction reached: "..prototype.id.." PC "..frame.pc)
   local done,result=step(frame)
   if done then return ${cfg.unpack_name}(result,1,result.n)end
  end
 end
 if ${cfg.setenv_name} then ${cfg.setenv_name}(fn,environment)end
 return fn
end
return ${cfg.main_name}(prototypes["application_1"],{},environment)(...)
end
return __recovered((type(getfenv)=="function" and getfenv() or _G),...)
`);
fs.writeFileSync(path.join(dir,'decoded.luau'),out.join('\n'));
fs.writeFileSync(path.join(dir,'source_records.json'),JSON.stringify(records,null,2));
fs.writeFileSync(path.join(dir,'undecoded_packets.json'),JSON.stringify(gaps,null,2));
console.log(JSON.stringify({specialized_handlers:records.length,undecoded_packet_records:gaps.length}));
