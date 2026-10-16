
local __completionVM,__completionDecode,__completionLanes=f,s,l
local __completionInfo=METADATA
__LQ_CAPTURE.Complete=function()
 local root=__LQ_CAPTURE.applicationRoot
 if not root or __LQ_CAPTURE.completionDone or __LQ_CAPTURE.completionBusy then return end
 __LQ_CAPTURE.completionBusy=true
 local queue,seen={root},{[root]=true}
 local processed,decoded,failures=0,0,0
 local function enqueue(proto)if proto and not seen[proto]then seen[proto]=true;queue[#queue+1]=proto end end
 while processed<#queue do
  processed+=1
  local proto=queue[processed]
  for _,child in pairs(proto.R)do enqueue(child)end
  if proto.h>0 then
   local ok,message=pcall(T,proto,1,B(proto.G,0))
   if not ok then failures+=1;__LQ_CAPTURE.emit('completion_probe_error',proto.G,1,'entry_page',tostring(message))end
  end
  local tokens,tokenSet={B(proto.G,0)},{[B(proto.G,0)]=true}
  local inspected={}
  for pass=1,proto.h+1 do
   local progress=false
   for pc=1,proto.h do
    if not inspected[pc]and not(proto.P[pc]or proto.E[pc])then
     for _,token in ipairs(tokens)do
      local success=pcall(T,proto,pc,token)
      if success then break end
     end
    end
   if not inspected[pc]and(proto.P[pc]or proto.E[pc])then
    inspected[pc]=true;progress=true
    local ok,message=pcall(function()
     local packet=T(proto,pc,B(proto.G,0))
     local info=__completionInfo[packet[1]]
     if not info then return end
     local read,finish=__completionDecode(packet,proto,pc,info.params[1],info.params[2],info.params[3])
     for index=2,#packet-2 do read()end
     local permutation,nextState=finish()
     if not tokenSet[nextState]then tokenSet[nextState]=true;tokens[#tokens+1]=nextState end
     local F,I,c,D,V,m,t=proto,{[0]={}},pc+1,packet,0,packet[1],0
     local bank=info.bank
     if bank=='d'then __completionVM:d(c,E[32],z,F,__completionLanes,I,D,__completionDecode,V,m,t)
     elseif bank=='s'then __completionVM:s(c,V,E[32],m,F,__completionLanes,__completionDecode,D,t,I,z)
     elseif bank=='S'then __completionVM:S(c,E[32],V,I,__completionLanes,z,t,m,__completionDecode,D,F)
     elseif bank=='H'then __completionVM:H(__completionLanes,D,z,m,E[32],F,I,c,__completionDecode,V,t)end
     decoded+=1
     for _,slot in ipairs(info.constants)do
      local index=I[slot]
      if type(index)=='number'and index>=1 and index<=proto.D then
       local success,value=pcall(P,proto,index,nextState)
       if not success then failures+=1;__LQ_CAPTURE.emit('completion_probe_error',proto.G,index,'constant',tostring(value))end
      end
     end
     for _,slot in ipairs(info.children)do
      local index=I[slot]
      if type(index)=='number'and(proto.N[index]or proto.R[index])then
       local success,child=pcall(U,proto,index,nextState)
       if success then enqueue(child)else failures+=1;__LQ_CAPTURE.emit('completion_probe_error',proto.G,index,'child',tostring(child))end
      end
     end
    end)
    if not ok then __LQ_CAPTURE.emit('completion_packet_skipped',proto.G,pc,'',tostring(message))end
   end
   end
   if not progress then break end
  end
 end
 __LQ_CAPTURE.emit('completion_status',root.G,processed,'decoded_packets',tostring(decoded)..'; read failures='..tostring(failures))
 __LQ_CAPTURE.completionBusy=false
 __LQ_CAPTURE.completionDone=true
end
