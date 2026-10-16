-- Intermediate decoded application. Clean-source reconstruction is a separate stage.
local function __recovered(environment,...)
local h={coroutine.running,string.byte,table.unpack,rawget,error,string.sub,bit32.bnot,bit32.bor,setfenv,next,getfenv,unpack,getmetatable,bit32.lrotate,table.create,select,bit32.rrotate,bit32.band,table.freeze,bit32.lshift,bit32.rshift,table.isfrozen,tonumber,math.max,string.rep,bit32.bxor,pcall,pairs,coroutine.yield,rawequal,math.ceil,table.concat,setmetatable,string.char,math.min,math.floor,coroutine.wrap,tostring,type}
local internalErrors={[1]="Luaq key length",[2]="string",[3]="",[4]="Luaq hash block",[5]="EncodingService",[6]="function",[7]="abc",[8]="Luaq hash integrity",[9]="Luaq cipher parameters",[10]="number",[11]="Luaq cipher length",[12]="Luaq encoding tail",[13]="Luaq encoding",[14]="Luaq base93",[15]="Luaq base93 tail",[16]="Luaq frame length",[17]="Luaq frame limit",[18]="Luaq frame mode",[19]="Luaq truncated frame",[20]="Luaq truncated reference",[21]="Luaq invalid reference",[22]="Luaq truncated literal",[23]="Luaq trailing frame",[24]="Luaq truncated image",[25]="Luaq image integer",[26]="Luaq image length",[27]="Luaq trailing image",[28]="Luaq stream region count",[29]="Luaq stream region",[30]="Luaq stream grant",[31]="Luaq region access count",[32]="Luaq region access",[33]="Luaq opcode alphabet",[34]="Luaq region key",[35]="Luaq region width",[36]="Luaq region length",[37]="LUAQ_REGION_V1\000",[38]="\000",[39]="\001",[40]="Luaq region authentication",[41]="Luaq region index",[42]="LUAQ_ACCESS_V2\000",[43]="Luaq stream unavailable",[44]="Luaq stream dependency",[45]="Luaq ",[46]="P",[47]="page",[48]="C",[49]="constant",[50]=" dependency",[51]="F",[52]="Luaq constant index",[53]="Infinity",[54]="-Infinity",[55]="NaN",[56]="Luaq numeric constant",[57]="Luaq constant type",[58]="Luaq opcode word",[59]="Luaq packet length",[60]="Luaq instruction pointer",[61]="Luaq packet operand",[62]="Luaq packet integrity",[63]="Luaq stream range",[64]="Luaq stream directory",[65]="#",[66]="kv",[67]="__metatable",[68]="Luaq iteration arity",[69]="__iter",[70]="__call",[71]="table",[72]="k",[73]="Luaq native prototype",[74]="Luaq dispatch",[75]="Luaq unary opcode",[76]="invalid numeric for bounds",[77]="Luaq table arity",[78]="Luaq arithmetic opcode",[79]="Luaq route integrity",[80]="Luaq operand state",[81]="LUAQ?",[82]="Luaq watermark",[83]="LUAQ_LOCAL_AUTHENTICATION_KEY_V3\000",[84]="LUAQ_LOCAL_PAYLOAD_V3\000",[85]="Luaq capsule authentication",[86]="LUAQ_LOCAL_ENCRYPTION_KEY_V3\000",[87]="Luaq tamper",[88]="LUAQ_GUARD_CREDENTIAL_V1\0006dab2007-4ad4-4cdf-8669-3fbbca79bc58\000",[89]="LUAQ_GUARD_CAPABILITY_V1\0006dab2007-4ad4-4cdf-8669-3fbbca79bc58\000"}
local function a(i)return internalErrors[i]or("Luaq error "..i)end
local D=table.unpack
local f=bit32.bxor
local function S(value,index)
 index=(index*0x79b9+bit32.lshift(index,16)*0x9e37)%4294967296
 value=bit32.bxor(value,index);value=bit32.bxor(value,bit32.lshift(value,13));value=bit32.bxor(value,bit32.rshift(value,17));return bit32.bxor(value,bit32.lshift(value,5))
end
local d,R=h[11],h[9];local function j(...)return{n=h[16](a(65),...),...};end;local r={n=0};if h[19]then h[19](r);end;local q={};local k={981257744,2125421207,762059671};local t={1883763327,1530696452,161227544};if h[19]then h[19](k);h[19](t);end;local W=h[33];local l=h[10];local l=h[28]({});local C=W({},{__mode=a(66)});local function l(E,X)local E=W(E,X);C[E]=X;return E;end;local Q={[2]=function(X,E,R)return h[37](function()for X,E in X,E,R do h[29](j(X,E));end;end);end};local function J(X,E)local X,R,d=X[1],X[2],X[3];if h[39](X)==a(6)then return{X,R,d,Q=E,s={n=E}};end;local l=C[X];local b=h[13](X);if l then local X=h[4](l,a(67));if not h[30](b,X==nil and l or X)then l=nil;end;end;if not l and b~=nil then local E=Q[E];if not E then h[5](a(68),0);end;return{f=E(X,R,d)};end;local b=l and h[4](l,a(69));if b~=nil then local R,d,l;h[38](W({},{__tostring=function()R,d,l=b(X);return a(3);end}));return{R,d,l,Q=E,s={n=E}};end;if l and h[4](l,a(70))~=nil then return{X,R,d,Q=E,s={n=E}};end;if h[39](X)==a(71)and(h[39](l)==a(71)or l==nil)then return{p=X,S=0,U=false,R=nil,s={n=2}};end;local E=Q[E];if not E then h[5](a(68),0);end;return{f=E(X,R,d)};end;local function P(X)if X.f then local X=X.f();return X or{n=0};end;if X.p then local R=X.p;local E=X.s;if not X.U then local d=X.S+1;local R=h[4](R,d);if R~=nil then X.S=d;E[1],E[2]=d,R;return E;end;X.U=true;end;local d,b=h[10](R,X.R);while d~=nil and h[39](d)==a(10)and d>=1 and d<=X.S and d%1==0 do d,b=h[10](R,d);end;X.R=d;E[1],E[2]=d,b;return E;end;local E=X.s;local R=X.Q;if R==1 then E[1]=X[1](X[2],X[3]);elseif R==2 then E[1],E[2]=X[1](X[2],X[3]);elseif R==3 then E[1],E[2],E[3]=X[1](X[2],X[3]);elseif R==4 then E[1],E[2],E[3],E[4]=X[1](X[2],X[3]);else E=j(X[1](X[2],X[3]));end;X[3]=E[1];return E;end;local Q;local C=true;local x={};local m={};local z=h[33]({},{__mode=a(72)});local g=h[23];local function g()C=false;h[5](x,0);end;local function N(...)if not C then g();end;return...;end;local function N(X,E)if h[39](X)==a(2)then return E[X]or X;end;return X;end;local function N(X,E,...)if not C then return;end;if R then R(X,E);end;local E=h[1]()or m;local R=z[E]or 0;z[E]=R+1;local X=j(h[27](X,...));z[E]=R>0 and R or nil;if not X[1]then if X[2]==x then if R>0 then h[5](x,0);end;return;end;h[5](X[2],0);end;return D(X,2,X.n);end;local function x(X,E,R,d,b)return Q(nil,d,b,X,E,R);end;local N={};

local prototypes,constants,steps={},{},{}
local function o(prototype,index)
 local values=constants[prototype.id]
 if not values.present[index]then error("Uncaptured constant: "..prototype.id.." #"..index,0)end
 return values[index]
end
local function lookupChild(parent,index)
 local id=parent.id.."/"..index
 local child=prototypes[id];assert(child,"Uncaptured child: "..id);return child
end

local Y=lookupChild
local builtins,trackedSetMetatable,setEnvironment,getEnvironment,setMeta,getConstant,makeClosure,beginIteration,nextIteration,pack,unpack,bxor,mix,stopExecution=h,l,R,d,W,o,x,J,P,j,D,f,S,g
local running=true
prototypes["application_1"]={["id"]="application_1",["j"]=0,["W"]=32,["x"]=2977748463,["w"]=1,["d"]=77,["G"]={}}
constants["application_1"]={present={[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,[16]=true,[17]=true,[18]=true,[19]=true,[20]=true,[21]=true,[22]=true,[23]=true,[24]=true,[25]=true},[1]="game",[2]="GetService",[3]="TweenService",[4]="Lighting",[5]="Ambient",[6]="Color3",[7]="fromRGB",[8]=128,[9]="OutdoorAmbient",[10]=150,[11]=170,[12]="Brightness",[13]=3,[14]="TimeOfDay",[15]="12:00:00",[16]=30,[17]=50,[18]=20,[19]=40,[20]=0.5,[21]="00:00:00",[22]=nil,[23]="task",[24]="spawn",[25]=4286889906}
steps["application_1"]={}
-- application_1 PC 1 opcode 4655
steps["application_1"][1]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=2,2071578779
 do do if mix((946737551),nextPc-1)~=(3768737465)then nextPc=nextPc+(75);end;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1 PC 2 opcode 18129
steps["application_1"][2]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=3,3891217202
 do do local X=(4286889905);local E=bxor((4286889906),X);if E<1 or E>prototype.d or mix(X,E)~=(2437155170)then running=false;builtins[5](a(79),0);end;nextPc=E;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1 PC 3 opcode 14041
steps["application_1"][3]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=4,2682503871
 do nextPc=nextPc+21;local Q=(7);local h=(7);local a=(20);do registers[(12)]=environment[("game")];end;if not running then return true,pack();end;do registers[(13)]=("GetService");end;if not running then return true,pack();end;do registers[(7)]=registers[(12)][registers[(13)]];end;if not running then return true,pack();end;do registers[(32)]=("TweenService");end;if not running then return true,pack();end;do local C=registers[Q];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=12,[2]=32});registers[(20)]=C(registers[W[1]],registers[W[2]]);if registers[Q]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(14)]={registers[(20)]};end;if not running then return true,pack();end;do registers[(20)]=environment[("game")];end;if not running then return true,pack();end;do registers[(32)]=("GetService");end;if not running then return true,pack();end;do registers[(7)]=registers[(20)][registers[(32)]];end;if not running then return true,pack();end;do registers[(13)]=("Lighting");end;if not running then return true,pack();end;do local C=registers[h];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=20,[2]=13});registers[(12)]=C(registers[W[1]],registers[W[2]]);if registers[h]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(21)]={registers[(12)]};end;if not running then return true,pack();end;do registers[(12)]={};end;if not running then return true,pack();end;do registers[(13)]=("Ambient");end;if not running then return true,pack();end;do registers[(7)]=environment[("Color3")];end;if not running then return true,pack();end;do registers[(32)]=("fromRGB");end;if not running then return true,pack();end;do registers[(20)]=registers[(7)][registers[(32)]];end;if not running then return true,pack();end;do registers[(10)]=(128);end;if not running then return true,pack();end;do registers[(11)]=(128);end;if not running then return true,pack();end;do registers[(16)]=(128);end;if not running then return true,pack();end;do local C=registers[a];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=10,[2]=11,[3]=16});registers[(15)]=C(registers[W[1]],registers[W[2]],registers[W[3]]);if registers[a]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(12)][registers[(13)]]=registers[(15)];end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1 PC 25 opcode 46120
steps["application_1"][25]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=26,1420591943
 do nextPc=nextPc+22;local Q=(1);do registers[(24)]=("OutdoorAmbient");end;if not running then return true,pack();end;do registers[(4)]=environment[("Color3")];end;if not running then return true,pack();end;do registers[(9)]=("fromRGB");end;if not running then return true,pack();end;do registers[(1)]=registers[(4)][registers[(9)]];end;if not running then return true,pack();end;do registers[(6)]=(150);end;if not running then return true,pack();end;do registers[(23)]=(150);end;if not running then return true,pack();end;do registers[(17)]=(170);end;if not running then return true,pack();end;do local C=registers[Q];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=6,[2]=23,[3]=17});registers[(2)]=C(registers[W[1]],registers[W[2]],registers[W[3]]);if registers[Q]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(12)][registers[(24)]]=registers[(2)];end;if not running then return true,pack();end;do registers[(18)]=("Brightness");end;if not running then return true,pack();end;do registers[(8)]=(3);end;if not running then return true,pack();end;do registers[(12)][registers[(18)]]=registers[(8)];end;if not running then return true,pack();end;do registers[(3)]=("TimeOfDay");end;if not running then return true,pack();end;do registers[(5)]=("12:00:00");end;if not running then return true,pack();end;do registers[(12)][registers[(3)]]=registers[(5)];end;if not running then return true,pack();end;do registers[(22)]={registers[(12)]};end;if not running then return true,pack();end;do registers[(5)]={};end;if not running then return true,pack();end;do registers[(3)]=("Ambient");end;if not running then return true,pack();end;do registers[(8)]=environment[("Color3")];end;if not running then return true,pack();end;do registers[(18)]=("fromRGB");end;if not running then return true,pack();end;do registers[(2)]=registers[(8)][registers[(18)]];end;if not running then return true,pack();end;do registers[(17)]=(30);end;if not running then return true,pack();end;do registers[(23)]=(30);end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1 PC 48 opcode 63589
steps["application_1"][48]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=49,1328419040
 do nextPc=nextPc+20;local Q=(2);local h=(15);do registers[(6)]=(50);end;if not running then return true,pack();end;do local C=registers[Q];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=17,[2]=23,[3]=6});registers[(1)]=C(registers[W[1]],registers[W[2]],registers[W[3]]);if registers[Q]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(5)][registers[(3)]]=registers[(1)];end;if not running then return true,pack();end;do registers[(9)]=("OutdoorAmbient");end;if not running then return true,pack();end;do registers[(4)]=environment[("Color3")];end;if not running then return true,pack();end;do registers[(24)]=("fromRGB");end;if not running then return true,pack();end;do registers[(15)]=registers[(4)][registers[(24)]];end;if not running then return true,pack();end;do registers[(16)]=(20);end;if not running then return true,pack();end;do registers[(11)]=(20);end;if not running then return true,pack();end;do registers[(10)]=(40);end;if not running then return true,pack();end;do local C=registers[h];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=16,[2]=11,[3]=10});registers[(20)]=C(registers[W[1]],registers[W[2]],registers[W[3]]);if registers[h]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(5)][registers[(9)]]=registers[(20)];end;if not running then return true,pack();end;do registers[(32)]=("Brightness");end;if not running then return true,pack();end;do registers[(7)]=(0.5);end;if not running then return true,pack();end;do registers[(5)][registers[(32)]]=registers[(7)];end;if not running then return true,pack();end;do registers[(13)]=("TimeOfDay");end;if not running then return true,pack();end;do registers[(12)]=("00:00:00");end;if not running then return true,pack();end;do registers[(5)][registers[(13)]]=registers[(12)];end;if not running then return true,pack();end;do registers[(19)]={registers[(5)]};end;if not running then return true,pack();end;do registers[(13)]=(nil);end;if not running then return true,pack();end;do registers[(12)]={registers[(13)]};end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1 PC 69 opcode 21856
steps["application_1"][69]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=70,3701350721
 do nextPc=nextPc+7;local h=(32);do local d=({[1]={[1]=79,[2]=21},[2]={[1]=79,[2]=14}});local R={};for E=1,#d do local d=d[E];if d[1]==79 then R[E]=registers[d[2]];else R[E]=upvalues[d[2]];end;end;registers[(7)]=makeClosure(prototype,(1),accessState,R,environment);end;if not running then return true,pack();end;do registers[(12)][1]=registers[(7)];end;if not running then return true,pack();end;do registers[(7)]=environment[("task")];end;if not running then return true,pack();end;do registers[(13)]=("spawn");end;if not running then return true,pack();end;do registers[(32)]=registers[(7)][registers[(13)]];end;if not running then return true,pack();end;do local d=({[1]={[1]=79,[2]=12},[2]={[1]=79,[2]=22},[3]={[1]=79,[2]=19}});local R={};for E=1,#d do local d=d[E];if d[1]==79 then R[E]=registers[d[2]];else R[E]=upvalues[d[2]];end;end;registers[(20)]=makeClosure(prototype,(2),accessState,R,environment);end;if not running then return true,pack();end;do local C=registers[h];if C==setMeta then C=trackedSetMetatable;end;local b=({[1]=20});C(registers[b[1]]);if registers[h]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do return true,pack();end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1 PC 77 opcode 27948
steps["application_1"][77]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=78,1048232501
 do do running=false;if z[builtins[1]()or m]then stopExecution();end;return true,pack();end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
prototypes["application_1/1"]={["id"]="application_1/1",["j"]=0,["W"]=32,["x"]=2969211194,["w"]=0,["d"]=52,["G"]={32,21}}
constants["application_1/1"]={present={[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,[16]=true},[1]="TweenInfo",[2]="new",[3]="Enum",[4]="EasingStyle",[5]="Quad",[6]="EasingDirection",[7]="InOut",[8]="Ambient",[9]="OutdoorAmbient",[10]="Brightness",[11]="TimeOfDay",[12]="Create",[13]="Play",[14]="Completed",[15]="Wait",[16]=3863431310}
steps["application_1/1"]={}
-- application_1/1 PC 1 opcode 11522
steps["application_1/1"][1]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=2,267620670
 do do if mix((2132587519),nextPc-1)~=(2483783831)then nextPc=nextPc+(1);end;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/1 PC 2 opcode 18129
steps["application_1/1"][2]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=3,3091197875
 do do local X=(3863431306);local E=bxor((3863431310),X);if E<1 or E>prototype.d or mix(X,E)~=(2713088869)then running=false;builtins[5](a(79),0);end;nextPc=E;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/1 PC 3 opcode 26323
steps["application_1/1"][3]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=4,2934786521
 do do running=false;if z[builtins[1]()or m]then stopExecution();end;return true,pack();end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/1 PC 4 opcode 7073
steps["application_1/1"][4]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=5,1356632114
 do nextPc=nextPc+23;local Q=(20);do registers[(30)]=environment[("TweenInfo")];end;if not running then return true,pack();end;do registers[(26)]=("new");end;if not running then return true,pack();end;do registers[(20)]=registers[(30)][registers[(26)]];end;if not running then return true,pack();end;do registers[(22)]=environment[("Enum")];end;if not running then return true,pack();end;do registers[(27)]=("EasingStyle");end;if not running then return true,pack();end;do registers[(28)]=registers[(22)][registers[(27)]];end;if not running then return true,pack();end;do registers[(25)]=("Quad");end;if not running then return true,pack();end;do registers[(19)]=registers[(28)][registers[(25)]];end;if not running then return true,pack();end;do registers[(10)]=environment[("Enum")];end;if not running then return true,pack();end;do registers[(31)]=("EasingDirection");end;if not running then return true,pack();end;do registers[(29)]=registers[(10)][registers[(31)]];end;if not running then return true,pack();end;do registers[(23)]=("InOut");end;if not running then return true,pack();end;do registers[(24)]=registers[(29)][registers[(23)]];end;if not running then return true,pack();end;do local C=registers[Q];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=21,[2]=19,[3]=24});registers[(17)]=C(registers[W[1]],registers[W[2]],registers[W[3]]);if registers[Q]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(18)]=registers[(17)];end;if not running then return true,pack();end;do registers[(17)]={};end;if not running then return true,pack();end;do registers[(24)]=("Ambient");end;if not running then return true,pack();end;do registers[(29)]=("Ambient");end;if not running then return true,pack();end;do registers[(31)]=registers[(32)][registers[(29)]];end;if not running then return true,pack();end;do registers[(17)][registers[(24)]]=registers[(31)];end;if not running then return true,pack();end;do registers[(10)]=("OutdoorAmbient");end;if not running then return true,pack();end;do registers[(25)]=("OutdoorAmbient");end;if not running then return true,pack();end;do registers[(28)]=registers[(32)][registers[(25)]];end;if not running then return true,pack();end;do registers[(17)][registers[(10)]]=registers[(28)];end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/1 PC 28 opcode 51054
steps["application_1/1"][28]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=29,640420080
 do nextPc=nextPc+18;local h=(22);local a=(20);do registers[(27)]=("Brightness");end;if not running then return true,pack();end;do registers[(9)]=("Brightness");end;if not running then return true,pack();end;do registers[(20)]=registers[(32)][registers[(9)]];end;if not running then return true,pack();end;do registers[(17)][registers[(27)]]=registers[(20)];end;if not running then return true,pack();end;do registers[(20)]=upvalues[(1)][1];end;if not running then return true,pack();end;do registers[(9)]=("TimeOfDay");end;if not running then return true,pack();end;do registers[(27)]=("TimeOfDay");end;if not running then return true,pack();end;do registers[(28)]=registers[(32)][registers[(27)]];end;if not running then return true,pack();end;do registers[(20)][registers[(9)]]=registers[(28)];end;if not running then return true,pack();end;do registers[(28)]=upvalues[(2)][1];end;if not running then return true,pack();end;do registers[(27)]=("Create");end;if not running then return true,pack();end;do registers[(22)]=registers[(28)][registers[(27)]];end;if not running then return true,pack();end;do registers[(9)]=upvalues[(1)][1];end;if not running then return true,pack();end;do local C=registers[h];if C==setMeta then C=trackedSetMetatable;end;local W=({[1]=28,[2]=9,[3]=18,[4]=17});registers[(19)]=C(registers[W[1]],registers[W[2]],registers[W[3]],registers[W[4]]);if registers[h]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[(10)]=registers[(19)];end;if not running then return true,pack();end;do registers[(19)]=registers[(19)];end;if not running then return true,pack();end;do registers[(25)]=("Play");end;if not running then return true,pack();end;do registers[(20)]=registers[(19)][registers[(25)]];end;if not running then return true,pack();end;do local C=registers[a];if C==setMeta then C=trackedSetMetatable;end;local b=({[1]=19});C(registers[b[1]]);if registers[a]==setEnvironment then environment=getEnvironment(1);end;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/1 PC 47 opcode 15629
steps["application_1/1"][47]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=48,3098441353
 do nextPc=nextPc+5;local Q=(22);do registers[(20)]=("Completed");end;if not running then return true,pack();end;do registers[(25)]=registers[(10)][registers[(20)]];end;if not running then return true,pack();end;do registers[(19)]=("Wait");end;if not running then return true,pack();end;do registers[(22)]=registers[(25)][registers[(19)]];end;if not running then return true,pack();end;do local C=registers[Q];if C==setMeta then C=trackedSetMetatable;end;local b=({[1]=25});C(registers[b[1]]);if registers[Q]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do return true,pack();end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
prototypes["application_1/2"]={["id"]="application_1/2",["j"]=0,["W"]=8,["x"]=3025634893,["w"]=0,["d"]=27,["G"]={}}
constants["application_1/2"]={present={[1]=true,[2]=true,[3]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true},[1]=10,[2]="print",[3]="\226\152\128\239\184\143 Transitioning to Morning...",[4]="task",[5]="wait",[6]="\240\159\140\153 Transitioning to Nightfall...",[7]=1644613641,[8]=120288811}
steps["application_1/2"]={}
-- application_1/2 PC 1 opcode 11522
steps["application_1/2"][1]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=2,682585395
 do do if mix((3341803956),nextPc-1)~=(154844449)then nextPc=nextPc+(24);end;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/2 PC 2 opcode 1959
steps["application_1/2"][2]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=3,2416712410
 do do local X=(120288819);local E=bxor((120288811),X);if E<1 or E>prototype.d or mix(X,E)~=(4015515057)then running=false;builtins[5](a(79),0);end;nextPc=E;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/2 PC 24 opcode 55186
steps["application_1/2"][24]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=25,986653528
 do do registers[(8)]=(10);end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/2 PC 25 opcode 18129
steps["application_1/2"][25]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=26,1720059839
 do do local X=(1644613650);local E=bxor((1644613641),X);if E<1 or E>prototype.d or mix(X,E)~=(2360029943)then running=false;builtins[5](a(79),0);end;nextPc=E;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/2 PC 26 opcode 27948
steps["application_1/2"][26]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=27,2682554732
 do do running=false;if z[builtins[1]()or m]then stopExecution();end;return true,pack();end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end
-- application_1/2 PC 27 opcode 5010
steps["application_1/2"][27]=function(frame)
 local registers,upvalues,environment,prototype,varargs=frame.registers,frame.upvalues,frame.environment,frame.prototype,frame.varargs
 local nextPc,accessState=28,2273963587
 do local h=(3);local h=(3);local n=(5);local I=(3);local S=(1);local x=(4);local K=(4);local v=(2);local M=(1);local F=(2);local a=(7);local c=(3);local A=(3);local H=(4);local i=(7);local O=(1);local s=(4);local D=(2);local L=(1);local f=(7);local j=({[1]=7});local z=(4);local U=(4);local Z=(2);local w=(7);local P=(27);local u=(2);local G=(5);local J=({[1]=7,[2]=8});local m=({[1]=2,[2]=8});local B=(4);local V=(3);local q=(2);local k=(2);local y=({[1]=2});local p=({[1]=8});local g=({[1]=8});local P=(2);local t=(6);local Y=(2);local T=(4);local N=(3);local XX=(7);local b=(7);local XE,XR=nil,false;local Xd,Xb=nil,false;local XW,Xl=nil,false;local XC,Xe=nil,false;local Xr,Xo=nil,false;local XQ,Xh=nil,false;local Xa,Xs=nil,false;local XD,Xf=nil,false;while running do do end;if not running then return true,pack();end;do if not XR then XE=getConstant(prototype,k,accessState);XR=true;end;registers[x]=environment[XE];end;if not running then return true,pack();end;do if not Xb then Xd=getConstant(prototype,N,accessState);Xb=true;end;registers[Y]=Xd;end;if not running then return true,pack();end;do local b=registers[s];if b==setMeta then b=trackedSetMetatable;end;local W=y;b(registers[W[1]]);if registers[s]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[XX]=upvalues[O][1];end;if not running then return true,pack();end;do registers[Z]=upvalues[v][1];end;if not running then return true,pack();end;do local b=registers[f];if b==setMeta then b=trackedSetMetatable;end;local W=m;b(registers[W[1]],registers[W[2]]);if registers[f]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do if not Xl then XW=getConstant(prototype,K,accessState);Xl=true;end;registers[L]=environment[XW];end;if not running then return true,pack();end;do if not Xe then XC=getConstant(prototype,n,accessState);Xe=true;end;registers[H]=XC;end;if not running then return true,pack();end;do registers[q]=registers[S][registers[z]];end;if not running then return true,pack();end;do local b=registers[P];if b==setMeta then b=trackedSetMetatable;end;local W=p;b(registers[W[1]]);if registers[P]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do if not Xo then Xr=getConstant(prototype,F,accessState);Xo=true;end;registers[A]=environment[Xr];end;if not running then return true,pack();end;do if not Xh then XQ=getConstant(prototype,t,accessState);Xh=true;end;registers[b]=XQ;end;if not running then return true,pack();end;do local b=registers[h];if b==setMeta then b=trackedSetMetatable;end;local W=j;b(registers[W[1]]);if registers[h]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do registers[u]=upvalues[M][1];end;if not running then return true,pack();end;do registers[w]=upvalues[I][1];end;if not running then return true,pack();end;do local b=registers[D];if b==setMeta then b=trackedSetMetatable;end;local W=J;b(registers[W[1]],registers[W[2]]);if registers[D]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do if not Xs then Xa=getConstant(prototype,B,accessState);Xs=true;end;registers[T]=environment[Xa];end;if not running then return true,pack();end;do if not Xf then XD=getConstant(prototype,G,accessState);Xf=true;end;registers[V]=XD;end;if not running then return true,pack();end;do registers[i]=registers[U][registers[c]];end;if not running then return true,pack();end;do local b=registers[a];if b==setMeta then b=trackedSetMetatable;end;local W=g;b(registers[W[1]]);if registers[a]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return true,pack();end;do end;end end
 frame.pc,frame.environment,frame.varargs=nextPc,environment,varargs
 return false
end

Q=function(prototype,upvalues,environment,parent,index)
 local fn
 fn=function(...)
  if not prototype then prototype=lookupChild(parent,index);parent=nil end
  assert(prototype.j==0,"Unsupported native prototype")
  local registers={}
  local args=j(...)
  for i=1,#prototype.G do registers[prototype.G[i]]=args[i]end
  local varargs={n=0}
  if prototype.w~=0 then varargs.n=math.max(0,args.n-#prototype.G);for i=1,varargs.n do varargs[i]=args[#prototype.G+i]end end
  local frame={prototype=prototype,registers=registers,upvalues=upvalues,environment=environment,pc=1,varargs=varargs}
  while running do
   local step=steps[prototype.id][frame.pc]
   assert(step,"Undecoded instruction reached: "..prototype.id.." PC "..frame.pc)
   local done,result=step(frame)
   if done then return D(result,1,result.n)end
  end
 end
 if R then R(fn,environment)end
 return fn
end
return Q(prototypes["application_1"],{},environment)(...)
end
return __recovered((type(getfenv)=="function" and getfenv() or _G),...)
