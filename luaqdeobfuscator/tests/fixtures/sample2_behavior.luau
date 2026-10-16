local function mix(v,n)
 n=bit32.band(n*0x79b9+bit32.lshift(n,16)*0x9e37,0xffffffff)
 v=bit32.bxor(v,n);v=bit32.bxor(v,bit32.lshift(v,13));v=bit32.bxor(v,bit32.rshift(v,17));return bit32.bxor(v,bit32.lshift(v,5))
end
local constants={[1]="loadstring",[2]="game",[3]="HttpGet",[4]="https://raw.githubusercontent.com/ThatsMyMute/testing/refs/heads/main/V1.75",[5]="Vector3",[6]="new",[7]=3.2445058822631836,[8]=200.0,[9]="Players",[10]="LocalPlayer",[11]="Character",[12]="CharacterAdded",[13]="Wait",[14]="WaitForChild",[15]="Humanoid",[16]="task",[17]="wait",[18]="FollowPath",[19]=-1842.9215087890625,[20]=-3.4413368701934814,[21]=3615548683.0,[22]=758969380.0,[23]=2115355715.0,[24]=863916311.0}
local function reference(environment)
 local registers,nextPc,running={},1,true
 local prototype={h=58};local accessState={}
 local bxor=bit32.bxor;local builtins={[32]=error};local pack=table.pack;local unpack=table.unpack
 local setMeta=setmetatable;local trackedSetMetatable=setmetatable;local setEnvironment=setfenv;local getEnvironment=getfenv
 local function J() return "invalid guard" end
 local function getConstant(_,i) return constants[i] end
 local function stopExecution() error("unexpected stop") end
 local e,u={},{}
 local handlers={}
handlers[1]=function() nextPc=nextPc+19;local E=(16);local J=(11);local c=(9);local z=(6);do registers[(11)]=environment[("loadstring")];end;if not running then return;end;do registers[(14)]=environment[("game")];end;if not running then return;end;do registers[(12)]=("HttpGet");end;if not running then return;end;do registers[(16)]=registers[(14)][registers[(12)]];end;if not running then return;end;do registers[(8)]=("https://raw.githubusercontent.com/ThatsMyMute/testing/refs/heads/main/V1.75");end;if not running then return;end;do local C=registers[E];if C==setMeta then C=trackedSetMetatable;end;local x=({[1]=14,[2]=8});registers[(6)]=pack(C(registers[x[1]],registers[x[2]]));if registers[E]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return;end;do local H=({});local O={n=#H};for L=1,#H do O[L]=registers[H[L]];end;local H=(6);if H~=0 then local p=registers[H];for H=1,p.n do O[O.n+H]=p[H];end;O.n=O.n+p.n;end;registers[(15)]=O;end;if not running then return;end;do local C=registers[J];if C==setMeta then C=trackedSetMetatable;end;local x=registers[(15)];registers[(9)]=C(unpack(x,1,x.n));if registers[J]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return;end;do local C=registers[c];if C==setMeta then C=trackedSetMetatable;end;local x=({});registers[(2)]=C();if registers[c]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return;end;do registers[(4)]=registers[(2)];end;if not running then return;end;do registers[(2)]={};end;if not running then return;end;do registers[(9)]=environment[("Vector3")];end;if not running then return;end;do registers[(15)]=("new");end;if not running then return;end;do registers[(6)]=registers[(9)][registers[(15)]];end;if not running then return;end;do registers[(16)]=(-1842.9215087890625);end;if not running then return;end;do registers[(12)]=(3.2445058822631836);end;if not running then return;end;do registers[(11)]=(-3.4413368701934814);end;if not running then return;end;do local C=registers[z];if C==setMeta then C=trackedSetMetatable;end;local x=({[1]=16,[2]=12,[3]=11});registers[(3)]=pack(C(registers[x[1]],registers[x[2]],registers[x[3]]));if registers[z]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return;end;do local p,O=registers[(2)],registers[(3)];local H=(1);for L=1,O.n do p[H+L-1]=O[L];end;end;if not running then return;end;do registers[(5)]=registers[(2)];end end
handlers[21]=function() nextPc=nextPc+11;do registers[(11)]=(200);end;if not running then return;end;do registers[(3)]=environment[("game")];end;if not running then return;end;do registers[(14)]=("Players");end;if not running then return;end;do registers[(12)]=registers[(3)][registers[(14)]];end;if not running then return;end;do registers[(16)]=("LocalPlayer");end;if not running then return;end;do registers[(8)]=registers[(12)][registers[(16)]];end;if not running then return;end;do registers[(6)]=registers[(8)];end;if not running then return;end;do registers[(8)]=registers[(8)];end;if not running then return;end;do registers[(16)]=("Character");end;if not running then return;end;do registers[(12)]=registers[(8)][registers[(16)]];end;if not running then return;end;do registers[(14)]=registers[(12)];end;if not running then return;end;do if registers[(12)]then nextPc=nextPc+(1);end;end end
handlers[33]=function() do local p=(3615548730);local O=bxor((3615548683),p);if O<1 or O>prototype.h or mix(p,O)~=(212428137)then running=false;builtins[32](J(76),0);end;nextPc=O;end end
handlers[34]=function() nextPc=nextPc+4;local E=(2);do registers[(7)]=registers[(14)];end;if not running then return;end;do registers[(13)]=("WaitForChild");end;if not running then return;end;do registers[(2)]=registers[(14)][registers[(13)]];end;if not running then return;end;do registers[(9)]=("Humanoid");end;if not running then return;end;do local C=registers[E];if C==setMeta then C=trackedSetMetatable;end;local x=({[1]=14,[2]=9});registers[(15)]=C(registers[x[1]],registers[x[2]]);if registers[E]==setEnvironment then environment=getEnvironment(1);end;end end
handlers[39]=function() do local p=(758969364);local O=bxor((758969380),p);if O<1 or O>prototype.h or mix(p,O)~=(2991991555)then running=false;builtins[32](J(76),0);end;nextPc=O;end end
handlers[48]=function() local S=(15);local E=(9);local z=(15);local Q=(2);local v=({[1]=7,[2]=5,[3]=11});local g=(9);local J=(2);local Y=(9);local G=(18);local B=(17);local j=(4);local t=(9);local c=({});local A=(40);local A=(48);local A=(16);local f=(2);local I=(2);local R,b=nil,false;local V,n=nil,false;local a,K=nil,false;while running do do end;if not running then return;end;do if not b then R=getConstant(prototype,A,accessState);b=true;end;registers[z]=environment[R];end;if not running then return;end;do if not n then V=getConstant(prototype,B,accessState);n=true;end;registers[Y]=V;end;if not running then return;end;do registers[Q]=registers[S][registers[t]];end;if not running then return;end;do local I=registers[J];if I==setMeta then I=trackedSetMetatable;end;local x=c;I();if registers[J]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return;end;do if not K then a=getConstant(prototype,G,accessState);K=true;end;registers[I]=a;end;if not running then return;end;do registers[g]=registers[j][registers[f]];end;if not running then return;end;do local I=registers[E];if I==setMeta then I=trackedSetMetatable;end;local x=v;I(registers[x[1]],registers[x[2]],registers[x[3]]);if registers[E]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return;end;do end;end end
handlers[49]=function() do if mix((4129120444),nextPc-1)~=(3089484409)then nextPc=nextPc+(8);end;end end
handlers[50]=function() do local p=(863916324);local O=bxor((863916311),p);if O<1 or O>prototype.h or mix(p,O)~=(2922415625)then running=false;builtins[32](J(76),0);end;nextPc=O;end end
handlers[51]=function() nextPc=nextPc+5;local E=(13);do registers[(15)]=("CharacterAdded");end;if not running then return;end;do registers[(9)]=registers[(6)][registers[(15)]];end;if not running then return;end;do registers[(2)]=("Wait");end;if not running then return;end;do registers[(13)]=registers[(9)][registers[(2)]];end;if not running then return;end;do local C=registers[E];if C==setMeta then C=trackedSetMetatable;end;local x=({[1]=9});registers[(1)]=C(registers[x[1]]);if registers[E]==setEnvironment then environment=getEnvironment(1);end;end;if not running then return;end;do registers[(14)]=registers[(1)];end end
handlers[57]=function() do local p=(2115355745);local O=bxor((2115355715),p);if O<1 or O>prototype.h or mix(p,O)~=(304372121)then running=false;builtins[32](J(76),0);end;nextPc=O;end end
handlers[58]=function() do running=false;if e[builtins[3]()or u]then stopExecution();end;return;end end
 while running do
  local pc=nextPc;nextPc=nextPc+1
  assert(handlers[pc],"missing handler "..pc);handlers[pc]()
 end
end
local recovered=assert(loadstring(__GENERATED_SOURCE__))
local function run(which,mode,limit)
 local trace={};local function record(s) trace[#trace+1]=s end
 local character={}
 function character:WaitForChild(name) assert(self==character and name=="Humanoid");record("WaitForChild:"..name);return {} end
 local player={Character=mode=="existing" and character or nil}
 local event={}
 function event:Wait() assert(self==event);record("CharacterAdded:Wait");return character end
 player.CharacterAdded=event
 local game={Players={LocalPlayer=mode~="nil-player" and player or nil}}
 function game:HttpGet(url) assert(self==game);assert(url==constants[4]);record("HttpGet:"..url);return "INERT_SOURCE" end
 local library={}
 function library.FollowPath(...)
  local args=table.pack(...);assert(args.n==3);assert(args[1]==character and args[3]==200)
  local targets=args[2];assert(#targets==1);local v=targets[1]
  assert(v[1]==-1842.9215087890625 and v[2]==3.2445058822631836 and v[3]==-3.4413368701934814)
  record("FollowPath:character,targets,200")
 end
 local waits=0;local stop={}
 local env={game=game,Vector3={new=function(x,y,z) record("Vector3.new");return {x,y,z} end},task={wait=function()
  waits+=1;record("task.wait");if waits>limit then error(stop,0) end
  return nil -- loop must continue even with a falsy wait return
 end}}
 setmetatable(env,{__index=getfenv()})
 env.loadstring=function(src) assert(src=="INERT_SOURCE");record("loadstring");return function() record("loaded chunk");return library end end
 local ok,err
 if which=="reference" then ok,err=pcall(reference,env) else setfenv(recovered,env);ok,err=pcall(recovered) end
 assert(not ok)
 if mode=="nil-player" then assert(type(err)=="string" and string.find(err,"Character",1,true));record("nil-player Character error")
 else assert(err==stop,"unexpected error: "..tostring(err));assert(waits==limit+1) end
 return table.concat(trace,"\n")
end
for _,mode in {"existing","spawn","nil-player"} do
 for _,limit in {0,1,5} do
  local a=run("reference",mode,limit);local b=run("recovered",mode,limit)
  assert(a==b,mode.." trace mismatch\n"..a.."\nVERSUS\n"..b)
  print("PASS "..mode.." limit="..limit)
 end
end
