local roblox=require('@lune/roblox')
local serde=require('@lune/serde')
local nativeTypeof=typeof
local types=setmetatable({},{__mode='k'})
local controlPoints=setmetatable({},{__mode='k'})
local function controlPoint(position,left,right)
 local data={Position=position or roblox.UDim2.new(),LeftTangent=left or roblox.UDim2.new(),RightTangent=right or roblox.UDim2.new()}
 local value=newproxy(true);local mt=getmetatable(value)
 mt.__index=data;mt.__newindex=function(_,k,v)assert(data[k]~=nil,'Invalid control-point property');data[k]=v end
 mt.__tostring=function()return 'Path2DControlPoint'end
 types[value]='Path2DControlPoint';controlPoints[value]=data
 return value
end
local points=setmetatable({},{__mode='k'})
local function clonePoint(value)
 return controlPoint(value.Position,value.LeftTangent,value.RightTangent)
end
roblox.implementMethod('Path2D','SetControlPoints',function(self,values)
 local result={};for i,value in ipairs(values)do result[i]=clonePoint(value)end;points[self]=result
end)
roblox.implementMethod('Path2D','GetControlPoints',function(self)
 local result={};for i,value in ipairs(points[self]or{})do result[i]=clonePoint(value)end;return result
end)
roblox.implementMethod('Path2D','GetControlPoint',function(self,index)
 local value=(points[self]or{})[index];assert(value,'Control point index out of range');return clonePoint(value)
end)
roblox.implementMethod('Path2D','UpdateControlPoint',function(self,index,value)local values=points[self]or{};assert(values[index],'Control point index out of range');values[index]=clonePoint(value)end)
local function curveSegment(self,t)
 local values=points[self]or{};assert(#values>=2,'Not enough control points')
 local location=math.clamp(t,0,1)*(#values-1)
 local index=math.min(math.floor(location)+1,#values-1)
 return values[index],values[index+1],location-index+1
end
local function cubic(a,b,c,d,t)
 local u=1-t;return u*u*u*a+3*u*u*t*b+3*u*t*t*c+t*t*t*d
end
local function curvePosition(self,t)
 local a,b,t=curveSegment(self,t)
 local p0,p1,p2,p3=a.Position,a.Position+a.RightTangent,b.Position+b.LeftTangent,b.Position
 return roblox.UDim2.new(cubic(p0.X.Scale,p1.X.Scale,p2.X.Scale,p3.X.Scale,t),math.round(cubic(p0.X.Offset,p1.X.Offset,p2.X.Offset,p3.X.Offset,t)),cubic(p0.Y.Scale,p1.Y.Scale,p2.Y.Scale,p3.Y.Scale,t),math.round(cubic(p0.Y.Offset,p1.Y.Offset,p2.Y.Offset,p3.Y.Offset,t)))
end
roblox.implementMethod('Path2D','GetPositionOnCurve',curvePosition)
roblox.implementMethod('Path2D','GetTangentOnCurve',function(self,t)
 local a,b,t=curveSegment(self,t)
 local p0,p1,p2,p3=a.Position,a.Position+a.RightTangent,b.Position+b.LeftTangent,b.Position
 local function derivative(a,b,c,d)local u=1-t;return 3*u*u*(b-a)+6*u*t*(c-b)+3*t*t*(d-c)end
 local size=self.Parent and self.Parent.Size or roblox.UDim2.new()
 local x=derivative(p0.X.Offset,p1.X.Offset,p2.X.Offset,p3.X.Offset)+size.X.Offset*derivative(p0.X.Scale,p1.X.Scale,p2.X.Scale,p3.X.Scale)
 local y=derivative(p0.Y.Offset,p1.Y.Offset,p2.Y.Offset,p3.Y.Offset)+size.Y.Offset*derivative(p0.Y.Scale,p1.Y.Scale,p2.Y.Scale,p3.Y.Scale)
 local v=roblox.Vector2.new(x,y);return v.Magnitude>0 and v.Unit or roblox.Vector2.new()
end)
roblox.implementMethod('HttpService','JSONEncode',function(_,v)return serde.encode('json',v)end)
roblox.implementMethod('HttpService','JSONDecode',function(_,v)return serde.decode('json',v)end)
roblox.implementMethod('RunService','IsStudio',function()return false end)
local game=roblox.Instance.new('DataModel')
local workspace=roblox.Instance.new('Workspace');workspace.Parent=game
return {Instance=roblox.Instance,Enum=roblox.Enum,Vector2=roblox.Vector2,Vector3=roblox.Vector3,UDim2=roblox.UDim2,game=game,workspace=workspace,
 Path2DControlPoint={new=controlPoint},typeof=function(x)return types[x]or nativeTypeof(x)end}
