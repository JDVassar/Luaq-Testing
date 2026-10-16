local sources=__SOURCES__
local function run(source,limit)
 local trace={};local function record(s)trace[#trace+1]=s end
 local state={}
 local lighting=setmetatable({}, {__index=state,__newindex=function(_,k,v)state[k]=v;record("Lighting."..k.."="..tostring(v))end})
 local function color(c)return table.concat(c,",")end
 local tweenService={}
 function tweenService:Create(target,info,goals)
  assert(self==tweenService and target==lighting)
  assert(info.duration==10 and info.style=="Quad"and info.direction=="InOut")
  assert(goals.TimeOfDay==nil)
  record("Create:"..color(goals.Ambient)..";"..color(goals.OutdoorAmbient)..";"..goals.Brightness)
  local completed={};function completed:Wait()assert(self==completed);record("Completed:Wait")end
  local tween={Completed=completed};function tween:Play()assert(self==tween);record("Play")end
  return tween
 end
 local game={}
 function game:GetService(name)
  assert(self==game);record("GetService:"..name)
  if name=="Lighting"then return lighting end
  assert(name=="TweenService");return tweenService
 end
 local queued={};local waits=0;local stop={}
 local env=setmetatable({game=game,Color3={fromRGB=function(r,g,b)record("Color3:"..r..","..g..","..b);return {r,g,b}end},Enum={EasingStyle={Quad="Quad"},EasingDirection={InOut="InOut"}},TweenInfo={new=function(duration,style,direction)record("TweenInfo:"..duration);return{duration=duration,style=style,direction=direction}end},print=function(s)record("print:"..s)end,task={spawn=function(fn)record("spawn");queued[#queued+1]=fn;return {}end,wait=function(seconds)assert(seconds==10);waits+=1;record("wait:"..seconds);if waits>limit then error(stop,0)end end}},{__index=getfenv()})
 local fn=assert(loadstring(source));setfenv(fn,env)
 local result=table.pack(fn());assert(result.n==0)
 assert(#queued==1)
 local ok,message=pcall(queued[1]);assert(not ok and message==stop,"unexpected worker failure: "..tostring(message))
 return table.concat(trace,"\n")
end
for _,limit in {0,1,2,3,5}do
 local reference=run(sources.executor,limit)
 assert(reference==run(sources.clean,limit),"clean source mismatch")
 assert(reference==run(sources.standalone,limit),"automated standalone capture mismatch")
 print("PASS limit="..limit)
end
