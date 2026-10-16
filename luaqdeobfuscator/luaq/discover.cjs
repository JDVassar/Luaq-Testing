// Structural discovery for the observed 107-statement Luaq v2.3.1 loader family.
// No protected code is executed by this file.
const fs=require('fs'),path=require('path'),parse=require('../vendor/luaparse/luaparse.js');
const [input,out]=process.argv.slice(2),source=fs.readFileSync(input,'utf8');
const ast=parse.parse(source,{ranges:true,scope:true,luaVersion:'5.3',encodingMode:'pseudo-latin1'});
const fail=m=>{throw Error('Unsupported Luaq structure: '+m)},check=(v,m)=>{if(!v)fail(m);return v},text=n=>source.slice(...n.range),name=n=>check(n?.name,'identifier').toString();
function walk(n,fn){if(!n||typeof n!=='object')return;fn(n);for(let[k,v]of Object.entries(n))if(!['range','globals'].includes(k)&&v&&typeof v==='object'){if(Array.isArray(v))v.forEach(x=>walk(x,fn));else walk(v,fn)}}
function all(n,p){let out=[];walk(n,x=>{if(p(x))out.push(x)});return out}
const tables=all(ast,n=>n.type==='TableConstructorExpression'&&n.fields.filter(f=>f.value.type==='FunctionDeclaration').some(f=>f.value.body.length===107));check(tables.length===1,'loader table');const fields=tables[0].fields;
const main=fields.find(f=>f.value.body?.length===107).value,B=main.body;const decl=i=>name(B[i].identifier||B[i].variables?.[0]);
check(B[83].type==='AssignmentStatement'&&B[83].init[0].type==='FunctionDeclaration','interpreter seam');
const factory=B[83].init[0],inner=factory.body.find(n=>n.type==='AssignmentStatement'&&n.init[0]?.type==='FunctionDeclaration')?.init[0];check(inner,'interpreter closure');
const block=B[85];check(block.type==='DoStatement','bootstrap seam');const boot=block.body.at(-1);check(boot.type==='AssignmentStatement'&&boot.init[0].type==='CallExpression','bootstrap invocation');
const bootCall=boot.init[0].base,protoImage=bootCall.arguments?.[0]?.arguments?.[0];check(protoImage?.type==='CallExpression','bootstrap image');
const capsule=Object.fromEntries(fields.filter(f=>f.value.type==='StringLiteral').map(f=>[f.key.name,f.value.value]));
const builtins=B[0].init[0].fields.map(f=>text(f.value));const builtinVar=decl(0);const errorIndex=builtins.indexOf('error')+1;check(errorIndex,'error builtin');
const vm=name(main.parameters[0]),environment=name(main.parameters[1]),internal= name(B[38].variables[0]);
const roles={vm,environment,builtin: builtinVar,internal,mix:decl(43),frame:decl(44),reader:decl(45),parse:decl(46),decrypt:decl(47),resolve:decl(48),child:decl(49),constant:decl(50),packet:decl(51),fetch:decl(52),decode:decl(53),factory:name(B[83].variables[0]),pack:decl(56),setMeta:decl(63),trackedSetMetatable:decl(67),beginIteration:decl(69),nextIteration:decl(70),running:decl(72),stopExecution:decl(77),makeClosure:decl(81),lanes:decl(61)};
roles.getEnvironment=name(B[55].variables[0]);roles.setEnvironment=name(B[55].variables[1]);roles.unpack=decl(9);roles.xor=name(B[7].variables[0]);
// The interpreter's first destructuring assignment binds prototype, upvalues, VM table.
const regBindings=inner.body.find(n=>n.type==='LocalStatement'&&n.variables.length===3&&n.init.length===3&&n.init[0].name===factory.parameters[0].name&&n.init[1].name===factory.parameters[1].name);
check(regBindings,'frame bindings');roles.prototype=name(regBindings.variables[0]);roles.upvalues=name(regBindings.variables[1]);
const bi=inner.body.indexOf(regBindings);roles.envRegister=name(inner.body[bi+1].variables[0]);roles.registers=name(inner.body[bi+2].variables[0]);roles.varargs=name(inner.body[bi+4].variables[0]);
const protDef=B[46].body.find(n=>n.type==='LocalStatement'&&n.init[0]?.type==='TableConstructorExpression'&&n.init[0].fields.length>10);check(protDef,'prototype layout');
const protoVar=name(protDef.variables[0]),initial=protDef.init[0].fields;const nativeId=initial[0].key.name,registerCount=initial[1].key.name;
const assignments=B[46].body.filter(n=>n.type==='AssignmentStatement'&&n.variables[0]?.type==='MemberExpression'&&n.variables[0].base.name===protoVar&&n.init[0]?.type==='CallExpression');
const wire=assignments.slice(0,5).map(n=>n.variables[0].identifier.name);check(wire.length===5,'prototype fields');
const seedCall=all(inner,n=>n.type==='CallExpression'&&n.base.name===roles.mix&&n.arguments[0]?.type==='MemberExpression'&&n.arguments[1]?.value===0)[0];check(seedCall,'seed initialization');const seed=seedCall.arguments[0].identifier.name;
roles.accessState=name(inner.body.find(n=>n.type==='LocalStatement'&&n.init.includes(seedCall)).variables[0]);
const varargIf=all(inner,n=>n.type==='IfClause'&&n.condition?.operator==='=='&&n.condition.right?.value===0&&n.condition.left?.type==='MemberExpression'&&n.condition.left.base.name===roles.prototype&&wire.includes(n.condition.left.identifier.name))[0];check(varargIf,'vararg flag');const varargFlag=varargIf.condition.left.identifier.name;
const opDecode=all(B[51],n=>n.type==='BinaryExpression'&&n.operator==='%'&&n.right.value===65536&&n.left.operator==='*'&&n.left.right.type==='MemberExpression')[0];check(opDecode,'opcode affine decode');const multiplier=opDecode.left.right.identifier.name,offset=opDecode.left.left.right.identifier.name;check(wire.includes(multiplier)&&wire.includes(offset),'opcode fields');
const unused=wire.filter(x=>![seed,varargFlag,multiplier,offset].includes(x));check(unused.length===1,'remaining prototype field');
const protoFields={Q:nativeId,K:registerCount,w:seed,a:varargFlag,u: null,X:null};
const argWrite=all(B[46],n=>n.type==='AssignmentStatement'&&n.variables[0]?.type==='IndexExpression'&&n.variables[0].base.type==='MemberExpression')[0];protoFields.X=argWrite.variables[0].base.identifier.name;
const fetchRange=all(B[52],n=>n.type==='IfClause'&&n.condition?.operator==='or'&&n.condition.right?.operator==='>')[0];protoFields.u=check(fetchRange,'packet bound').condition.right.right.identifier.name;
const bound=all(B[50],n=>n.type==='IfClause'&&n.condition?.operator==='or'&&n.condition.right?.operator==='>')[0];const constantCount=bound.condition.right.right.identifier.name;
const cacheRead=B[52].body[0].init[0],packetCache=cacheRead.base.identifier.name;
const encodedPacket=all(B[52],n=>n.type==='ReturnStatement'&&n.arguments[0]?.type==='CallExpression'&&n.arguments[0].base.name===roles.packet)[0]?.arguments[0].arguments[2];check(encodedPacket,'encoded packet read');
const packetRawDecl=B[52].body.findLast(n=>n.type==='LocalStatement'&&n.init[0]?.type==='IndexExpression'&&n.init[0].base.type==='MemberExpression'&&n.variables[0].name===encodedPacket.name);check(packetRawDecl,'encoded packet cache');
const childCache=B[49].body[0].init[0].base.identifier.name;
const childRegion=all(B[49],n=>n.type==='CallExpression'&&n.base.name===roles.resolve)[0].arguments[3].base.identifier.name;
const constantWrite=B[50].body.findLast(n=>n.type==='AssignmentStatement'&&n.init[0]?.type==='Identifier'&&n.variables[0]?.type==='IndexExpression'&&n.variables[0].base.type==='MemberExpression');check(constantWrite,'constant result write');
const tagIf=B[50].body.find(n=>n.type==='IfStatement'&&n.clauses.length===7&&n.clauses.slice(0,6).every(c=>c.condition?.right?.type==='NumericLiteral'));check(tagIf,'constant tags');const tags=tagIf.clauses.slice(0,6).map(c=>c.condition.right.value);
const cacheSelector=all(B[53],n=>n.type==='LocalStatement'&&n.init[0]?.type==='IndexExpression'&&n.init[0].base.type==='MemberExpression')[0].init[0].base.identifier.name;
function num(n,vname,v){if(n.type==='NumericLiteral')return n.value;if(n.type==='Identifier'&&n.name===vname)return v;if(n.type==='BinaryExpression'){let l=num(n.left,vname,v),r=num(n.right,vname,v);if(n.operator==='+')return l+r;if(n.operator==='*')return l*r;if(n.operator==='%')return l%r;}throw Error('not affine')}
function affine(n){const vars=all(n,x=>x.type==='Identifier').map(x=>x.name);if(new Set(vars).size!==1)throw Error('affine variables');let add=num(n,vars[0],0),mul=(num(n,vars[0],1)-add+65536)%65536;let inverse=1;for(;inverse<65536;inverse+=2)if(mul*inverse%65536===1)break;if(inverse>=65536)throw Error('affine inverse');return{add,mul,inverse,variable:vars[0]}}
function decode(a,c){return((c-a.add)*a.inverse%65536+65536)%65536}
const banks=[],ops={};
for(const field of fields.filter(f=>f.value.type==='FunctionDeclaration'&&f.value!==main)){
 const f=field.value,first=f.body[0];if(first.type!=='LocalStatement'||first.variables.length!==1)continue;let af;try{af=affine(first.init[0])}catch{continue}
 const selector=first.variables[0].name;let count=0;
 walk(f,n=>{if(n.type!=='IfClause'||n.condition?.operator!=='=='||n.condition.left?.name!==selector||n.condition.right?.type!=='NumericLiteral')return;
  const calls=all(n.body,x=>x.type==='CallExpression'&&x.arguments.length===6&&x.arguments.slice(3).every(z=>z.type==='NumericLiteral'));check(calls.length===1,'packet decoder case');const op=decode(af,n.condition.right.value);check(!ops[op],'duplicate packet opcode');ops[op]={bank:field.key.name,packet_params:calls[0].arguments.slice(3).map(x=>x.value),source:text(n),case:n.condition.right.value};count++;
 });check(count,'empty bank');banks.push({name:field.key.name,fn:f,affine:af,params:f.parameters.map(x=>x.name)});
}
check(banks.length>=4,'packet banks');
const semantics={};
function scan(xs,env={}){env={...env};for(let n of xs){if(n.type==='LocalStatement'&&n.variables.length===1&&n.init[0]?.type==='BinaryExpression')try{env[n.variables[0].name]=affine(n.init[0])}catch{}
 if(n.type==='IfStatement')for(let c of n.clauses){let cond=c.condition;if(cond?.operator==='=='&&env[cond.left?.name]&&cond.right?.type==='NumericLiteral'){const af=env[cond.left.name],op=decode(af,cond.right.value);(semantics[op]??=[]).push({case:cond.right.value,source:source.slice(c.body[0].range[0],c.body.at(-1).range[1])});roles.opcode=af.variable;}scan(c.body,env)}else if(n.body)scan(n.body,env);else if(n.type==='AssignmentStatement')for(let v of n.init)if(v.type==='FunctionDeclaration')scan(v.body,env)
}}scan(inner.body);
// Operand table has a private table at numeric key zero.
const operandDecl=inner.body.find(n=>n.type==='LocalStatement'&&n.init[0]?.type==='TableConstructorExpression'&&n.init[0].fields.some(f=>f.key?.value===0&&f.value.type==='TableConstructorExpression'));roles.operands=name(check(operandDecl,'operand table').variables[0]);
const calls={};
const laneAlias=inner.body.find(n=>n.type==='LocalStatement'&&n.init.some(x=>x.name===roles.lanes));check(laneAlias,'decoder lane alias');roles.lanesRegister=laneAlias.variables[laneAlias.init.findIndex(x=>x.name===roles.lanes)].name;
for(let bank of banks){const call=all(inner,n=>n.type==='CallExpression'&&n.base.type==='MemberExpression'&&n.base.indexer===':'&&n.base.identifier.name===bank.name)[0];check(call,'bank invocation');
 const bindings={};bank.params.forEach((p,i)=>{bindings[p]=i===0?call.base.base:call.arguments[i-1]});
 const decoderCall=all(bank.fn,n=>n.type==='CallExpression'&&n.arguments.length===6&&n.arguments.slice(3).every(x=>x.type==='NumericLiteral'))[0];
 const actual=x=>{if(x.type==='Identifier')return bindings[x.name];return x};
 const packet=actual(decoderCall.arguments[0]);roles.packetRegister=name(packet);
 const pcExpression=decoderCall.arguments[2];check(pcExpression.operator==='-'&&pcExpression.right.value===1,'packet PC');roles.nextPc=name(actual(pcExpression.left));
 const map={ [roles.prototype]:'F',[roles.operands]:'I',[roles.packetRegister]:'D',[roles.nextPc]:'c',[roles.opcode]:'m',[roles.decode]:'decode',[roles.lanesRegister]:'lanes',[roles.xor]:'z'};
 calls[bank.name]=call.arguments.map(n=>{if(n.type==='Identifier')return map[n.name]||'0';if(n.type==='IndexExpression'&&n.base.name===builtinVar&&n.index.value===errorIndex)return'error';fail('bank argument '+text(n))}).join(',');
}
function references(src){const a=parse.parse(src,{luaVersion:'5.3'}),constants=new Set(),children=new Set();function slot(n,e){if(n?.type==='Identifier')return e[n.name];if(n?.type==='IndexExpression'&&n.base.name===roles.operands&&n.index.type==='NumericLiteral')return n.index.value}
 function expressions(n,e){if(!n||typeof n!=='object')return;if(n.type==='CallExpression'&&[roles.constant,roles.makeClosure].includes(n.base.name)&&n.arguments[0]?.name===roles.prototype&&n.arguments[2]?.name===roles.accessState&&e[n.base.name]===undefined){const i=slot(n.arguments[1],e);if(i!==undefined)(n.base.name===roles.constant?constants:children).add(i)}for(let[k,v]of Object.entries(n))if(k!=='globals'&&v&&typeof v==='object'){if(Array.isArray(v))v.forEach(x=>expressions(x,e));else expressions(v,e)}}
 function statements(xs,e={}){e={...e};for(let n of xs){if(['LocalStatement','AssignmentStatement'].includes(n.type)){n.init.forEach(x=>expressions(x,e));let values=n.init.map(x=>slot(x,e));n.variables.forEach((x,i)=>{if(x.type==='Identifier')e[x.name]=values[i]})}else if(n.type==='IfStatement')for(let c of n.clauses){expressions(c.condition,e);statements(c.body,e)}else if(n.body)statements(n.body,e);else expressions(n,e)}}statements(a.body);return{constants:[...constants],children:[...children]}}
for(let[op,rec]of Object.entries(ops)){const sem=semantics[op];check(sem&&new Set(sem.map(x=>x.source)).size===1,'semantic coverage '+op);const ref=references(sem[0].source);rec.constant_slots=ref.constants;rec.child_slots=ref.children}
const capsuleMember=n=>{check(n?.type==='MemberExpression'&&n.base.name===vm,'capsule field');return n.identifier.name};
const secret=block.body[0].init[0].arguments.map(n=>capsuleMember(n.arguments[0])),nonce=capsuleMember(block.body[1].init[0].arguments[0]),blob=capsuleMember(block.body[2].init[0]);
const authCandidates=all(block,n=>n.type==='CallExpression'&&n.base.name===decl(35)&&n.arguments[0]?.type==='MemberExpression').map(n=>capsuleMember(n.arguments[0]));const auth=authCandidates.filter(k=>!secret.includes(k)&&k!==nonce&&k!==blob);check(auth.length===1,'capsule authentication field');
const buildKey=capsuleMember(B[39].init[0]);check(/^[0-9a-f-]{36}$/.test(capsule[buildKey]),'build id');
const semanticRename={ [roles.registers]:'registers',[roles.upvalues]:'upvalues',[roles.envRegister]:'environment',[roles.nextPc]:'nextPc',[roles.prototype]:'prototype',[roles.accessState]:'accessState',[roles.varargs]:'varargs',[builtinVar]:'builtins',[roles.trackedSetMetatable]:'trackedSetMetatable',[roles.setEnvironment]:'setEnvironment',[roles.getEnvironment]:'getEnvironment',[roles.setMeta]:'setMeta',[roles.constant]:'getConstant',[roles.makeClosure]:'makeClosure',[roles.beginIteration]:'beginIteration',[roles.nextIteration]:'nextIteration',[roles.pack]:'pack',[roles.unpack]:'unpack',[roles.xor]:'bxor',[roles.mix]:'mix',[roles.running]:'running',[roles.stopExecution]:'stopExecution'};
const app=B[93],appVar=name(app.variables[0]),image=text(app.init[0].arguments[0]),stream=name(app.init[0].arguments[0].arguments[0]);
const constProto=name(B[50].parameters[0]),constIndex=name(B[50].parameters[1]),constValue=name(constantWrite.init[0]);
const fn47=B[47],regionProto=name(fn47.parameters[0]),regionLabel=name(fn47.parameters[1]),regionIndex=name(fn47.parameters[2]);
const bootstrapSetup=source.slice(block.range[0],boot.range[0]),bootstrapImage=text(protoImage),protoInput=name(B[46].parameters[0]),protoResult=name(B[46].body.at(-1).arguments[0]);
const profile={id:'auto-'+capsule[buildKey],build:capsule[buildKey],operand_name:roles.operands,constant_fn:roles.constant,child_fn:roles.child,register_cache:cacheSelector,constant_tags:tags,main_name:roles.factory,running_name:'running',pack_name:roles.pack,unpack_name:roles.unpack,setenv_name:roles.setEnvironment,env_name:roles.getEnvironment,proto_fields:protoFields,rename:semanticRename,banks:banks.map(x=>x.name),decoder_calls:calls,validation:'Automatically discovered structure; bootstrap authentication and operand lifting must pass before use.'};
const aliasKeys=['trackedSetMetatable','setEnvironment','getEnvironment','setMeta','constant','makeClosure','beginIteration','nextIteration','pack','unpack','xor','mix','stopExecution'];profile.aliases='local builtins,trackedSetMetatable,setEnvironment,getEnvironment,setMeta,getConstant,makeClosure,beginIteration,nextIteration,pack,unpack,bxor,mix,stopExecution='+[builtinVar,...aliasKeys.map(k=>roles[k])].join(',')+'\nlocal running=true';
const wireMap={ [seed]:'w',[varargFlag]:'a',[multiplier]:'S',[offset]:'W',[unused[0]]:'l'};
const discovery={profile,capsule,crypto:{build:buildKey,secret,nonce,blob,auth:auth[0]},wire_order:wire.map(x=>wireMap[x]),roles,fields:{seed,packetCount:protoFields.u,constantCount,packetCache,packetRaw:packetRawDecl.init[0].base.identifier.name,childCache,childRegion},bootstrap:{setup:bootstrapSetup,image:bootstrapImage,seam:boot.range,remove:[B[84].range[0],B[106].range[1]]},instrument:{environment:{position:B[0].range[0],name:environment},proto:{start:B[46].body[0].range[0],input:protoInput,result:protoResult,emit:B[46].body.at(-1).range[0]},region:{start:fn47.body[0].range[0],proto:regionProto,label:regionLabel,index:regionIndex,ret:fn47.body.at(-1).range,expr:text(fn47.body.at(-1).arguments[0])},constant:{position:constantWrite.range[0],proto:constProto,index:constIndex,value:constValue},hook:B[84].range[0],entry:B[105].range[0],session:{position:B[92].range[0],stream},application:{range:app.range,variable:appVar,image}},runtime:{builtins:text(B[0]),support:source.slice(B[55].range[0],B[83].range[0])},internal_constants:B[36].init[0].fields.map(f=>f.value.fields.map(x=>x.value.value)),resolve:{head:B[48].body[0].range[0],parameters:B[48].parameters.map(x=>x.name)},errorIndex};
fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'discovery.json'),JSON.stringify(discovery,null,2));fs.writeFileSync(path.join(out,'packet_handlers.json'),JSON.stringify(ops,null,2));fs.writeFileSync(path.join(out,'semantics_by_opcode.json'),JSON.stringify(semantics,null,2));fs.writeFileSync(path.join(out,'decoder_methods.luau'),'local VM={}\n'+banks.map(b=>'VM.'+b.name+'='+text(b.fn)).join('\n')+'\nreturn VM\n');
console.log(JSON.stringify({build:profile.build,banks:profile.banks,packet_opcodes:Object.keys(ops).length,semantic_opcodes:Object.keys(semantics).length}));
