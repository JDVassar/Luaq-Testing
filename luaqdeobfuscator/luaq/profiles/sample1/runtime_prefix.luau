-- Recovered execution source from Studio, executor and completion captures.
-- Original names/comments are unavailable. Register operations are preserved.
-- This contains no network loader, encrypted VM image, or bytecode decoder.
-- Decoded handlers are generated from the supplied capture; gaps are reported separately.
local function __recovered(environment, ...)
local F={pcall,bit32.rrotate,string.char,math.floor,coroutine.running,table.isfrozen,bit32.bor,bit32.bnot,math.abs,select,next,tostring,table.create,rawequal,math.ceil,coroutine.yield,getmetatable,coroutine.wrap,bit32.band,bit32.lrotate,type,bit32.rshift,string.byte,table.concat,bit32.lshift,table.unpack,table.freeze,string.sub,unpack,string.rep,error,math.max,setfenv,rawget,bit32.bxor,tonumber,pairs,getfenv,math.min,setmetatable}
local internalErrors={[1]="Luaq key length",[2]="string",[3]="",[4]="Luaq hash block",[5]="EncodingService",[6]="function",[7]="abc",[8]="Luaq hash integrity",[9]="Luaq cipher parameters",[10]="number",[11]="Luaq cipher length",[12]="Luaq encoding tail",[13]="Luaq encoding",[14]="Luaq base93",[15]="Luaq base93 tail",[16]="Luaq frame length",[17]="Luaq frame limit",[18]="Luaq frame mode",[19]="Luaq truncated frame",[20]="Luaq truncated reference",[21]="Luaq invalid reference",[22]="Luaq truncated literal",[23]="Luaq trailing frame",[24]="Luaq truncated image",[25]="Luaq image integer",[26]="Luaq image length",[27]="Luaq trailing image",[28]="Luaq stream region count",[29]="Luaq stream region",[30]="Luaq stream grant",[31]="Luaq region access count",[32]="Luaq region access",[33]="Luaq opcode alphabet",[34]="Luaq region key",[35]="Luaq region width",[36]="Luaq region length",[37]="LUAQ_REGION_V1\000",[38]="\000",[39]="\001",[40]="Luaq region authentication",[41]="Luaq region index",[42]="LUAQ_ACCESS_V2\000",[43]="Luaq stream unavailable",[44]="Luaq stream dependency",[45]="Luaq ",[46]="P",[47]="page",[48]="C",[49]="constant",[50]=" dependency",[51]="F",[52]="Luaq constant index",[53]="Infinity",[54]="-Infinity",[55]="NaN",[56]="Luaq numeric constant",[57]="Luaq constant type",[58]="Luaq opcode word",[59]="Luaq packet length",[60]="Luaq instruction pointer",[61]="Luaq packet operand",[62]="Luaq packet integrity",[63]="Luaq stream range",[64]="Luaq stream directory",[65]="#",[66]="kv",[67]="__metatable",[68]="Luaq iteration arity",[69]="__iter",[70]="__call",[71]="table",[72]="k",[73]="Luaq native prototype",[74]="Luaq dispatch",[75]="Luaq arithmetic opcode",[76]="Luaq route integrity",[77]="invalid numeric for bounds",[78]="Luaq table arity",[79]="Luaq unary opcode",[80]="Luaq operand state",[81]="LUAQ{",[82]="Luaq watermark",[83]="LUAQ_LOCAL_AUTHENTICATION_KEY_V3\000",[84]="LUAQ_LOCAL_PAYLOAD_V3\000",[85]="Luaq capsule authentication",[86]="LUAQ_LOCAL_ENCRYPTION_KEY_V3\000",[87]="Luaq tamper",[88]="Luaq precheck capsule",[89]="Luaq precheck result",[90]="Luaq precheck integer",[91]="LUAQ_PRECHECK_STEP_V1\000",[92]="LUAQ_GUARD_CREDENTIAL_V1\000bac1f4e0-cb24-4dfb-ad25-a2a5bc3500d2\000",[93]="LUAQ_PRECHECK_CREDENTIAL_V1\000bac1f4e0-cb24-4dfb-ad25-a2a5bc3500d2\000",[94]="LUAQ_GUARD_CAPABILITY_V1\000bac1f4e0-cb24-4dfb-ad25-a2a5bc3500d2\000",[95]="LUAQ_PRECHECK_CAPABILITY_V1\000bac1f4e0-cb24-4dfb-ad25-a2a5bc3500d2\000"}
local function P(i)return internalErrors[i] or ("Luaq error "..tostring(i))end
local s=table.unpack or unpack
local u=bit32.bxor
local function m(value,index)
 index=(index*0x79b9+bit32.lshift(index,16)*0x9e37)%4294967296
 value=bit32.bxor(value,index);
 value=bit32.bxor(value,bit32.lshift(value,13));
 value=bit32.bxor(value,bit32.rshift(value,17));
 return bit32.bxor(value,bit32.lshift(value,5))
end
local V,M=F[38],F[33];
 local function d(...)return{n=F[10](P(65),...),...};
 end;
 local ee={n=0};
 if F[27]then F[27](ee);
 end;
 local S={};
 local g={4042771136,4072449165,576332624};
 local C={2312820528,1097389125,1032380133};
 if F[27]then F[27](g);
 F[27](C);
 end;
 local z=F[40];
 local E=F[11];
 local E=F[37]({});
 local E=z({},{__mode=P(66)});
 local function I(N,e)local N=z(N,e);
 E[N]=e;
 return N;
 end;
 local y={[2]=function(e,N,E)return F[18](function()for e,N in e,N,E do F[16](d(e,N));
 end;
 end);
 end,[1]=function(e,N,E)return F[18](function()for e in e,N,E do F[16](d(e));
 end;
 end);
 end};
 local function k(e,N)local e,c,K=e[1],e[2],e[3];
 if F[21](e)==P(6)then return{e,c,K,M=N,f={n=N}};
 end;
 local B=E[e];
 local E=F[17](e);
 if B then local e=F[34](B,P(67));
 if not F[14](E,e==nil and B or e)then B=nil;
 end;
 end;
 if not B and E~=nil then local N=y[N];
 if not N then F[31](P(68),0);
 end;
 return{t=N(e,c,K)};
 end;
 local E=B and F[34](B,P(69));
 if E~=nil then local c,K,B;
 F[12](z({},{__tostring=function()c,K,B=E(e);
 return P(3);
 end}));
 return{c,K,B,M=N,f={n=N}};
 end;
 if B and F[34](B,P(70))~=nil then return{e,c,K,M=N,f={n=N}};
 end;
 if F[21](e)==P(71)and(F[21](B)==P(71)or B==nil)then return{s=e,N=0,Y=false,Z=nil,f={n=2}};
 end;
 local N=y[N];
 if not N then F[31](P(68),0);
 end;
 return{t=N(e,c,K)};
 end;
 local function y(e)if e.t then local e=e.t();
 return e or{n=0};
 end;
 if e.s then local E=e.s;
 local N=e.f;
 if not e.Y then local c=e.N+1;
 local E=F[34](E,c);
 if E~=nil then e.N=c;
 N[1],N[2]=c,E;
 return N;
 end;
 e.Y=true;
 end;
 local c,K=F[11](E,e.Z);
 while c~=nil and F[21](c)==P(10)and c>=1 and c<=e.N and c%1==0 do c,K=F[11](E,c);
 end;
 e.Z=c;
 N[1],N[2]=c,K;
 return N;
 end;
 local N=e.f;
 local E=e.M;
 if E==1 then N[1]=e[1](e[2],e[3]);
 elseif E==2 then N[1],N[2]=e[1](e[2],e[3]);
 elseif E==3 then N[1],N[2],N[3]=e[1](e[2],e[3]);
 elseif E==4 then N[1],N[2],N[3],N[4]=e[1](e[2],e[3]);
 else N=d(e[1](e[2],e[3]));
 end;
 e[3]=N[1];
 return N;
 end;
 local eN;
 local E=true;
 local b={};
 local D={};
 local R=F[40]({},{__mode=P(72)});
 local h=F[36];
 local function h()E=false;
 F[31](b,0);
 end;
 local function ec(...)if not E then h();
 end;
 return...;
 end;
 local function ec(e,N)if F[21](e)==P(2)then return N[e]or e;
 end;
 return e;
 end;
 local function ec(e,N,...)if not E then return;
 end;
 if M then M(e,N);
 end;
 local N=F[5]()or D;
 local E=R[N]or 0;
 R[N]=E+1;
 local e=d(F[1](e,...));
 R[N]=E>0 and E or nil;
 if not e[1]then if e[2]==b then if E>0 then F[31](b,0);
 end;
 return;
 end;
 F[31](e[2],0);
 end;
 return s(e,2,e.n);
 end;
 local function b(e,N,E,c,K)return eN(nil,c,K,e,N,E);
 end;
 local ec={};
 
