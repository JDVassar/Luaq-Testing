-- Small deterministic test fixture, not a Roblox emulator.
-- Used only to compare replay and recovered execution under identical inputs.
local originalTypeof=typeof
function typeof(v) if type(v)=='table' and rawget(v,'__type') then return rawget(v,'__type') end;return originalTypeof(v)end
Vector3={}
local vector={};vector.__index=vector
function Vector3.new(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,__type='Vector3'},vector)end
Vector3.zero=Vector3.new()
function vector:Dot(b)return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
function vector:Cross(b)return Vector3.new(self.Y*b.Z-self.Z*b.Y,self.Z*b.X-self.X*b.Z,self.X*b.Y-self.Y*b.X)end
function vector.__add(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function vector.__sub(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
function vector.__mul(a,b)if type(a)=='number'then a,b=b,a end;return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
function vector.__div(a,b)return Vector3.new(a.X/b,a.Y/b,a.Z/b)end
function vector.__unm(a)return Vector3.new(-a.X,-a.Y,-a.Z)end
CFrame={};local cf={};cf.__index=cf
function CFrame.new(x,y,z)return setmetatable({Position=type(x)=="table" and x or Vector3.new(x,y,z),__type='CFrame'},cf)end
function CFrame.Angles(x,y,z)return CFrame.new()end
function cf.__mul(a,b)return CFrame.new(a.Position.X+b.Position.X,a.Position.Y+b.Position.Y,a.Position.Z+b.Position.Z)end
function cf:Lerp(b,t)local p=self.Position+(b.Position-self.Position)*t;return CFrame.new(p.X,p.Y,p.Z)end
CFrame.identity=CFrame.new()
Color3={}
function Color3.fromHSV(h,s,v)
 local i=math.floor(h*6);local f=h*6-i;local p=v*(1-s);local q=v*(1-f*s);local t=v*(1-(1-f)*s)
 local colors={{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}};local c=colors[i%6+1];return {R=c[1],G=c[2],B=c[3],__type='Color3'}
end
NumberRange={new=function(a,b)return {Min=a,Max=b or a,__type='NumberRange'}end}
NumberSequenceKeypoint={new=function(t,v,e)return {Time=t,Value=v,Envelope=e or 0,__type='NumberSequenceKeypoint'}end}
NumberSequence={new=function(points)return {Keypoints=points,__type='NumberSequence'}end}
Enum={Material={GetEnumItems=function()local a={};for i=1,40 do a[i]={Value=i*16,__type='EnumItem'}end;return a end}}
