-- Capture settings. This observer executes the original protected program.
local __LQ_CAPTURE = (function()
    local api = {
        phase = "bootstrap",
        filename = "luaq-runtime-capture.jsonl",
        folderName = "LuaqCapture",
        snapshotSeconds = 15,
        stopBeforeApplication = false,
        records = {},
        last = {},
        revision = 0,
        savedRevision = -1,
    }
    local clock = os.clock
    local function hex(value)
        return (value:gsub(".", function(char)
            return string.format("%02x", string.byte(char))
        end))
    end
    local function quote(value)
        return '"' .. tostring(value):gsub('[%z\1-\31\\"]', function(char)
            if char == '"' then return '\\"' end
            if char == '\\' then return '\\\\' end
            return string.format('\\u%04x', string.byte(char))
        end) .. '"'
    end
    function api.emit(kind, seed, index, label, data)
        if type(data) ~= "string" then return end
        local key = table.concat({api.phase, kind, tostring(seed or 0), tostring(index or 0), label or ""}, "|")
        if api.last[key] == data then return end
        api.last[key] = data
        api.records[#api.records + 1] = {
            kind = kind, phase = api.phase, seed = seed or 0,
            index = index or 0, label = label or "", data = data,
        }
        api.revision += 1
    end
    function api.Export()
        local lines = {'{"format":"luaq-runtime-capture-v1","build":"bac1f4e0-cb24-4dfb-ad25-a2a5bc3500d2"}'}
        local count = #api.records
        for i = 1, count do
            local row = api.records[i]
            lines[#lines + 1] = '{"kind":' .. quote(row.kind) .. ',"phase":' .. quote(row.phase)
                .. ',"seed":' .. tostring(row.seed) .. ',"index":' .. tostring(row.index)
                .. ',"label":' .. quote(row.label) .. ',"data_hex":' .. quote(hex(row.data)) .. '}'
        end
        return table.concat(lines, "\n") .. "\n", count
    end
    function api.Flush(force)
        if not force and api.savedRevision == api.revision then return true end
        local text, count = api.Export()
        local revision = api.revision
        if type(writefile) == "function" then
            local ok, message = pcall(writefile, api.filename, text)
            if not ok then return false, message end
            api.savedRevision = revision
            print("[Luaq capture] Wrote " .. api.filename .. " (" .. count .. " records)")
            return true
        end
        if game then
            local ok, message = pcall(function()
                local storage = game:GetService("ReplicatedStorage")
                local folder = storage:FindFirstChild(api.folderName)
                if folder and not folder:IsA("Folder") then error("LuaqCapture name is already in use") end
                if not folder then folder = Instance.new("Folder"); folder.Name = api.folderName; folder.Parent = storage end
                folder:SetAttribute("Complete", false)
                local total = math.ceil(#text / 60000)
                for i = 1, total do
                    local name = string.format("Chunk_%06d", i)
                    local chunk = folder:FindFirstChild(name)
                    if not chunk then chunk = Instance.new("StringValue"); chunk.Name = name; chunk.Parent = folder end
                    chunk.Value = string.sub(text, (i - 1) * 60000 + 1, i * 60000)
                end
                for _, chunk in ipairs(folder:GetChildren()) do
                    local number = tonumber(string.match(chunk.Name, "^Chunk_(%d+)$"))
                    if number and number > total then chunk:Destroy() end
                end
                folder:SetAttribute("RecordCount", count)
                folder:SetAttribute("ChunkCount", total)
                folder:SetAttribute("Revision", revision)
                folder:SetAttribute("SavedAtClock", clock())
                folder:SetAttribute("Complete", true)
            end)
            if not ok then return false, message end
            api.savedRevision = revision
            print("[Luaq capture] Updated ReplicatedStorage." .. api.folderName .. " (" .. count .. " records)")
            return true
        end
        return false, "No writefile API or Roblox instance storage; use LUAQ_CAPTURE.Export()"
    end
    -- Adds a server-side Studio HTTP adapter only when no request API is present.
    function api.environment(env)
        if env.request or env.http_request or (env.http and env.http.request) or (env.syn and env.syn.request) then return env end
        if not game then return env end
        local ok, service = pcall(function()
            local run = game:GetService("RunService")
            if not run:IsStudio() or not run:IsServer() then return nil end
            return game:GetService("HttpService")
        end)
        if not ok or not service then return env end
        local proxy = {}; for key, value in pairs(env) do proxy[key] = value end
        proxy.http_request = function(options)
            return service:RequestAsync(options)
        end
        return setmetatable(proxy, {__index = env})
    end
    pcall(function() _G.LUAQ_CAPTURE = api end)
    pcall(function() getfenv().LUAQ_CAPTURE = api end)
    if task and task.spawn and task.wait then
        task.spawn(function()
            while true do
                task.wait(api.snapshotSeconds)
                local ok, message = api.Flush(false)
                if not ok then warn("[Luaq capture] " .. tostring(message)) end
            end
        end)
    end
    return api
end)()
