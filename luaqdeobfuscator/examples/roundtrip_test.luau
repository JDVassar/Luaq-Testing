-- Obfuscate this whole file, then send back only the protected output.
-- No downloads, executor APIs, or Roblox services are required.
local trace = {}
local function record(label, value)
    trace[#trace + 1] = label .. "=" .. tostring(value)
end

local function makeCounter(initial)
    local total = initial
    return function(delta)
        total = total + delta
        return total
    end, function()
        return total
    end
end

local add, peek = makeCounter(7)
record("counter.first", add(5))
record("counter.second", add(-3))
record("counter.peek", peek())

local function collect(...)
    local result = { n = select("#", ...), ... }
    return result
end
local function forward(...)
    return collect(...)
end
local values = forward("alpha", nil, false, 17, nil)
record("varargs.count", values.n)
record("varargs.hole", values[2] == nil)
record("varargs.false", values[3] == false)
record("varargs.last", values[4])

local total = 0
for i = 1, 9 do
    if i % 2 == 0 then
        total = total + i * i
    else
        total = total - i
    end
end
record("loop.numeric", total)

local attempts, accumulated = 0, 0
while attempts < 12 do
    attempts = attempts + 1
    if attempts > 5 then
        break
    end
    accumulated = accumulated + attempts
end
record("loop.break", attempts)
record("loop.sum", accumulated)

local countdown = 5
repeat
    countdown = countdown - 1
until countdown == 0
record("loop.repeat", countdown)

local weights = { 3, 1, 4, 1, 5 }
local weighted = 0
for index, value in ipairs(weights) do
    weighted = weighted + index * value
end
record("table.weighted", weighted)

local methods = {}
function methods:scale(multiplier)
    return self.value * multiplier
end
local box = setmetatable({ value = 6 }, {
    __index = methods,
    __add = function(left, right)
        return left.value + right.value
    end,
    __tostring = function(value)
        return "box(" .. value.value .. ")"
    end,
})
record("metatable.method", box:scale(7))
record("metatable.add", box + { value = 8 })
record("metatable.string", tostring(box))

local function factorial(n)
    if n <= 1 then
        return 1
    end
    return n * factorial(n - 1)
end
record("recursive", factorial(6))

local calls = 0
local function touch()
    calls = calls + 1
    return "touched"
end
local left = false and touch()
local right = true or touch()
local chosen = nil or touch()
record("logic.false", left)
record("logic.true", right)
record("logic.choice", chosen)
record("logic.calls", calls)

local ok, message = pcall(function()
    error("roundtrip-sentinel", 0)
end)
record("pcall.ok", ok)
record("pcall.error", message == "roundtrip-sentinel")
record("string", string.sub("obfuscation-check", 1, 11))
record("math", math.floor(17 / 3))

local checksum = 19
local text = table.concat(trace, "|")
for i = 1, #text do
    checksum = (checksum * 31 + string.byte(text, i)) % 1000003
end
print("LUAQ_ROUNDTRIP_V1")
print(text)
print("CHECKSUM=" .. checksum)
return text, checksum
