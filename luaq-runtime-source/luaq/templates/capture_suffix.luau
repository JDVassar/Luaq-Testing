
end
local __captureResults=table.pack(pcall(__captureRun,...))
if not __captureResults[1]then __LQ_CAPTURE.emit('execution_error',0,0,'',tostring(__captureResults[2]))end
if __LQ_CAPTURE.Complete then local ok,message=pcall(__LQ_CAPTURE.Complete);if not ok then __LQ_CAPTURE.emit('completion_error',0,0,'',tostring(message))end end
local __saved,__message=__LQ_CAPTURE.Flush(true)
if not __saved then warn('[Luaq capture] '..tostring(__message))end
if not __captureResults[1]then error(__captureResults[2],0)end
return table.unpack(__captureResults,2,__captureResults.n)
