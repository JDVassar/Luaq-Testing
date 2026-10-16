-- Standalone reconstruction of the captured Luaq application.
-- No loader or network access. Requires the Roblox APIs used below.
-- Compatibility for captured Luau iteration and multiple-return behavior.
local unpack = table.unpack
local function pack(...)
    return {n = select('#', ...), ...}
end
 
local trackedMetatables = setmetatable({}, {__mode = 'kv'})
local function trackedSetMetatable(object, metatable)
    local result = setmetatable(object, metatable)
    trackedMetatables[result] = metatable
    return result
end
 
local function coroutineIterator(iterator, state, control, arity)
    if arity == 1 then
        return coroutine.wrap(function()
            for key in iterator, state, control do coroutine.yield(pack(key)) end
        end)
    elseif arity == 2 then
        return coroutine.wrap(function()
            for key, value in iterator, state, control do coroutine.yield(pack(key, value)) end
        end)
    end
    error('Luaq iteration arity', 0)
end
 
local function beginIteration(values, arity)
    local iterator, state, control = values[1], values[2], values[3]
    if type(iterator) == 'function' then
        return {iterator, state, control, M = arity, f = {n = arity}}
    end
    local metatable = trackedMetatables[iterator]
    local visibleMetatable = getmetatable(iterator)
    if metatable then
        local protected = rawget(metatable, '__metatable')
        if not rawequal(visibleMetatable, protected == nil and metatable or protected) then metatable = nil end
    end
    if not metatable and visibleMetatable ~= nil then
        return {t = coroutineIterator(iterator, state, control, arity)}
    end
    local customIterator = metatable and rawget(metatable, '__iter')
    if customIterator ~= nil then
        local nextFunction, nextState, nextControl
        tostring(setmetatable({}, {__tostring = function()
            nextFunction, nextState, nextControl = customIterator(iterator)
            return ''
        end}))
        return {nextFunction, nextState, nextControl, M = arity, f = {n = arity}}
    end
    if metatable and rawget(metatable, '__call') ~= nil then
        return {iterator, state, control, M = arity, f = {n = arity}}
    end
    if type(iterator) == 'table' and (type(metatable) == 'table' or metatable == nil) then
        return {s = iterator, N = 0, Y = false, Z = nil, f = {n = 2}}
    end
    return {t = coroutineIterator(iterator, state, control, arity)}
end
 
local function nextIteration(iterator)
    if iterator.t then return iterator.t() or {n = 0} end
    if iterator.s then
        local values, result = iterator.s, iterator.f
        if not iterator.Y then
            local index = iterator.N + 1
            local value = rawget(values, index)
            if value ~= nil then
                iterator.N = index
                result[1], result[2] = index, value
                return result
            end
            iterator.Y = true
        end
        local key, value = next(values, iterator.Z)
        while key ~= nil and type(key) == 'number' and key >= 1 and key <= iterator.N and key % 1 == 0 do
            key, value = next(values, key)
        end
        iterator.Z = key
        result[1], result[2] = key, value
        return result
    end
    local result, count = iterator.f, iterator.M
    if count == 1 then result[1] = iterator[1](iterator[2], iterator[3])
    elseif count == 2 then result[1], result[2] = iterator[1](iterator[2], iterator[3])
    elseif count == 3 then result[1], result[2], result[3] = iterator[1](iterator[2], iterator[3])
    elseif count == 4 then result[1], result[2], result[3], result[4] = iterator[1](iterator[2], iterator[3])
    else result = pack(iterator[1](iterator[2], iterator[3])) end
    iterator[3] = result[1]
    return result
end
 
local function invoke(fn, ...)
    if fn == setmetatable then fn = trackedSetMetatable end
    return fn(...)
end
 
local function joinArguments(prefix, count, tail)
    local result = {n = count}
    for index = 1, count do result[index] = prefix[index] end
    if tail then
        for index = 1, tail.n do result[count + index] = tail[index] end
        result.n = count + tail.n
    end
    return result
end
 
local function P(index)
    if index == 77 then return 'invalid numeric for bounds' end
    return 'Luaq error ' .. tostring(index)
end
 
local Helpers=(function()
-- Recovered helper logic. Names are inferred, not original author names.
-- This covers the 23 helper bodies; the main application is not reconstructed here.
local Helpers = {}
 
-- application_1/1
function Helpers.mix32(value)
    value = bit32.bxor(value, bit32.rshift(value, 16))
    value = bit32.band(value * 73244475, 4294967295)
    value = bit32.bxor(value, bit32.rshift(value, 16))
    value = bit32.band(value * 73244475, 4294967295)
    return bit32.bxor(value, bit32.rshift(value, 16))
end
 
-- application_1/2: FNV-1a over an array of byte values.
function Helpers.hashBytes(bytes)
    local hash = 2166136261
    for index = 1, #bytes do
        hash = bit32.band(bit32.bxor(hash, bytes[index]) * 16777619, 4294967295)
    end
    return hash
end
 
-- application_1/4: callback used by the string transformation.
function Helpers.shiftCharacter(character)
    return string.char(string.byte(character) + 8)
end
 
-- application_1/5: the original helper closes over its input string.
function Helpers.makePrefixReader(text)
    return function()
        return text:sub(1, 12)
    end
end
 
-- application_1/6
function Helpers.makeBoxConstructor(metatable)
    return function(value)
        return setmetatable({ value = value }, metatable)
    end
end
 
-- application_1/7, /8, /9. The and/or fallback is retained from the code.
function Helpers.makeArithmeticMethods(boxType)
    local function add(left, right)
        local leftValue = type(left) == "table" and left.value or left
        local rightValue = type(right) == "table" and right.value or right
        return boxType.new(leftValue + rightValue)
    end
 
    local function subtract(left, right)
        local leftValue = type(left) == "table" and left.value or left
        local rightValue = type(right) == "table" and right.value or right
        return boxType.new(leftValue - rightValue)
    end
 
    local function multiply(left, right)
        local leftValue = type(left) == "table" and left.value or left
        local rightValue = type(right) == "table" and right.value or right
        return boxType.new(leftValue * rightValue)
    end
 
    return add, subtract, multiply
end
 
-- application_1/10
function Helpers.makeNegationMethod(boxType)
    return function(object)
        return boxType.new(-object.value)
    end
end
 
-- application_1/11
function Helpers.absoluteValue(object)
    return math.abs(object.value)
end
 
-- application_1/12: recovered from the completion capture.
function Helpers.stringifyValue(object)
    return tostring(object.value)
end
 
-- application_1/3 and /3/1
function Helpers.makeSaltedMixer(salt, mixer)
    return function(value, round)
        local mixed = bit32.bxor(value, salt)
        mixed = bit32.lrotate(mixed, round % 32)
        mixed = bit32.bxor(mixed, mixer(round * 2654435769))
        return bit32.band(mixed, 4294967295)
    end
end
 
-- application_1/13 and /13/1
function Helpers.makeIterator(object)
    local index = 0
    return function()
        index = index + 1
        if index > object.count then
            return nil
        end
        return index, object.base * index + index % 3
    end
end
 
-- application_1/14
function Helpers.yieldSequence(limit)
    local state = 1
    for index = 1, limit do
        state = (state * 33 + index * 17) % 1000003
        if index % 4 == 0 then
            coroutine.yield(index, state)
        end
    end
    return limit, state
end
 
-- application_1/15
function Helpers.makeNumericErrorProbe(value, mixer)
    return function()
        if value % 9 == 0 then
            error(value * 101, 0)
        end
        return mixer(value * 74565)
    end
end
 
-- application_1/16
function Helpers.makeTableErrorProbe(value)
    return function()
        if value % 6 == 0 then
            error({ code = value }, 0)
        end
        return value * value * value
    end
end
 
-- application_1/17
function Helpers.errorCode(errorValue)
    if type(errorValue) == "table" then
        return errorValue.code * 99
    end
    return 0
end
 
-- application_1/18: the original closure refers to its own function cell.
function Helpers.makeRecursiveSequence()
    local function sequence(value)
        if value <= 1 then
            return 1
        end
        return (sequence(value - 1) + sequence(value - 2) + value) % 1000003
    end
    return sequence
end
 
-- application_1/19: the original captures both the cache and recursion function.
function Helpers.makeMemoizedSequence(cache)
    local function sequence(value)
        local cached = cache[value]
        if cached ~= nil then
            return cached
        end
        local result = (sequence(value - 1) + sequence(value - 2)) % 2147483647
        cache[value] = result
        return result
    end
    return sequence
end
 
-- application_1/20
function Helpers.makeKeyedTransform(key, mixer)
    return function(value)
        local mixed = bit32.bxor(value, key)
        return mixer(mixed + key * 3)
    end
end
 
-- application_1/21
function Helpers.compareScrambled(left, right)
    local leftKey = bit32.bxor(left, 324508639)
    local rightKey = bit32.bxor(right, 324508639)
    if leftKey == rightKey then
        return left < right
    end
    return leftKey < rightKey
end
 
return Helpers
 
end)()
-- Bridge captured upvalue cells to the recovered source-style helper bodies.
local function makeReadableHelper(id, cells)
    if id == 'application_1/1' then
        return function(value) return Helpers.mix32(value) end
    elseif id == 'application_1/2' then
        return function(bytes) return Helpers.hashBytes(bytes) end
    elseif id == 'application_1/3' then
        return function(salt)
            return function(value, round)
                local mixed = bit32.bxor(value, salt)
                mixed = bit32.lrotate(mixed, round % 32)
                mixed = bit32.bxor(mixed, cells[1][1](round * 2654435769))
                return bit32.band(mixed, 4294967295)
            end
        end
    elseif id == 'application_1/3/1' then
        return function(value, round)
            local mixed = bit32.bxor(value, cells[1][1])
            mixed = bit32.lrotate(mixed, round % 32)
            mixed = bit32.bxor(mixed, cells[2][1](round * 2654435769))
            return bit32.band(mixed, 4294967295)
        end
    elseif id == 'application_1/4' then
        return function(character) return Helpers.shiftCharacter(character) end
    elseif id == 'application_1/5' then
        return function() return cells[1][1]:sub(1, 12) end
    elseif id == 'application_1/6' then
        return function(value) return trackedSetMetatable({value = value}, cells[1][1]) end
    elseif id == 'application_1/7' then
        return function(left, right)
            local a = type(left) == 'table' and left.value or left
            local b = type(right) == 'table' and right.value or right
            return cells[1][1].new(a + b)
        end
    elseif id == 'application_1/8' then
        return function(left, right)
            local a = type(left) == 'table' and left.value or left
            local b = type(right) == 'table' and right.value or right
            return cells[1][1].new(a - b)
        end
    elseif id == 'application_1/9' then
        return function(left, right)
            local a = type(left) == 'table' and left.value or left
            local b = type(right) == 'table' and right.value or right
            return cells[1][1].new(a * b)
        end
    elseif id == 'application_1/10' then
        return function(object) return cells[1][1].new(-object.value) end
    elseif id == 'application_1/11' then
        return function(object) return math.abs(object.value) end
    elseif id == 'application_1/12' then
        return function(object) return tostring(object.value) end
    elseif id == 'application_1/13' then
        return function(object) return Helpers.makeIterator(object) end
    elseif id == 'application_1/13/1' then
        return function()
            cells[1][1] = cells[1][1] + 1
            local index, object = cells[1][1], cells[2][1]
            if index > object.count then return nil end
            return index, object.base * index + index % 3
        end
    elseif id == 'application_1/14' then
        return function(limit) return Helpers.yieldSequence(limit) end
    elseif id == 'application_1/15' then
        return function()
            local value = cells[1][1]
            if value % 9 == 0 then error(value * 101, 0) end
            return cells[2][1](value * 74565)
        end
    elseif id == 'application_1/16' then
        return function()
            local value = cells[1][1]
            if value % 6 == 0 then error({code = value}, 0) end
            return value * value * value
        end
    elseif id == 'application_1/17' then
        return function(errorValue) return Helpers.errorCode(errorValue) end
    elseif id == 'application_1/18' then
        return function(value)
            if value <= 1 then return 1 end
            local recurse = cells[1][1]
            return (recurse(value - 1) + recurse(value - 2) + value) % 1000003
        end
    elseif id == 'application_1/19' then
        return function(value)
            local cache, recurse = cells[1][1], cells[2][1]
            local cached = cache[value]
            if cached ~= nil then return cached end
            local result = (recurse(value - 1) + recurse(value - 2)) % 2147483647
            cache[value] = result
            return result
        end
    elseif id == 'application_1/20' then
        return function(value)
            local key = cells[1][1]
            return cells[2][1](bit32.bxor(value, key) + key * 3)
        end
    elseif id == 'application_1/21' then
        return function(left, right) return Helpers.compareScrambled(left, right) end
    end
    error('Unknown recovered helper: ' .. tostring(id), 0)
end
 
-- Reconstructed application source. Names and phase boundaries are inferred.
-- The main routine uses ordinary loops, conditions, and local hashWords.
-- See RECOVERY.md for validation scope and remaining limitations.
local state = {}
 
do -- 1. Seed table
    local hashWords = {[1] = 1, [2] = 3, [3] = 5, [4] = 7, [5] = 11, [6] = 13, [7] = 17, [8] = 19}
    local seedValues = {}
    local bound = tonumber(1)
    local bound2 = tonumber(128)
    local bound3 = tonumber(1)
    if (((bound == nil) or (bound2 == nil)) or (bound3 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value = bound
    while true do
        if (not (((bound3 > 0) and (value <= bound2)) or ((not (bound3 > 0)) and (value >= bound2)))) then
            break
        end
        local value4 = (value * 73244475)
        local value5 = (value % 31)
        local results = pack(bit32.lrotate(value, value5))
        local arguments = joinArguments({[1] = value4}, 1, results)
        local bxor = bit32.bxor(unpack(arguments, 1, arguments.n))
        local band = bit32.band(bxor, 2147483647)
        seedValues[value] = band
        local value6 = (value + bound3)
        value = value6
    end
    state.seedValues = seedValues
    state.hashWords = hashWords
end
 
do -- 2. Integer mixing and accumulator updates
    local mixerCell = {[1] = nil}
    local mix32 = makeReadableHelper("application_1/1", {})
    mixerCell[1] = mix32
    local hashBytes = makeReadableHelper("application_1/2", {})
    local bound8 = tonumber(1)
    local bound9 = tonumber(192)
    local bound10 = tonumber(1)
    if (((bound8 == nil) or (bound9 == nil)) or (bound10 == nil)) then
        error(invoke(P, 77), 0)
    end
    local randomState = 1831565813
    local primaryChecksum = 0
    local secondaryChecksum = 0
    local value14 = bound8
    while true do
        local value15 = primaryChecksum
        local value16 = secondaryChecksum
        if (not (((bound10 > 0) and (value14 <= bound9)) or ((not (bound10 > 0)) and (value14 >= bound9)))) then
            value15 = primaryChecksum
            value16 = secondaryChecksum
        else
            local arguments17 = joinArguments({[1] = randomState}, 1, nil)
            local item = arguments17[1]
            local results18 = pack(bit32.lshift(item, 13))
            local arguments19 = joinArguments({[1] = item}, 1, results18)
            local bxor20 = bit32.bxor(unpack(arguments19, 1, arguments19.n))
            local results21 = pack(bit32.rshift(bxor20, 17))
            local arguments22 = joinArguments({[1] = bxor20}, 1, results21)
            local bxor23 = bit32.bxor(unpack(arguments22, 1, arguments22.n))
            local results24 = pack(bit32.lshift(bxor23, 5))
            local arguments25 = joinArguments({[1] = bxor23}, 1, results24)
            local bxor26 = bit32.bxor(unpack(arguments25, 1, arguments25.n))
            local results27 = pack(bit32.band(bxor26, 4294967295))
            local item28 = results27[1]
            local length = (#state.hashWords)
            local value29 = (item28 % length)
            local value30 = (value29 + 1)
            local item31 = mixerCell[1]
            local value32 = (value14 - 1)
            local length33 = (#state.seedValues)
            local value34 = (value32 % length33)
            local value35 = (value34 + 1)
            local item36 = state.seedValues[value35]
            local value37 = (item28 + item36)
            local item38 = invoke(item31, value37)
            local item39 = state.hashWords[value30]
            local bxor40 = bit32.bxor(item39, item38)
            state.hashWords[value30] = bxor40
            local value41 = (item38 % 997)
            local value42 = (value41 + value14)
            local arguments43 = joinArguments({[1] = value42}, 1, nil)
            local item44 = arguments43[1]
            local value45 = (item44 * 17)
            local value46 = (value45 + 31)
            local value47 = (value46 * item44)
            local value48 = (value47 - 11)
            local value49 = (value48 * item44)
            local value50 = (value49 + 7)
            local value51 = (value50 % 1000003)
            local arguments52 = joinArguments({[1] = value51}, 1, nil)
            local item53 = arguments52[1]
            local value54 = (primaryChecksum + item53)
            local value55 = (value54 % 2147483647)
            local value56 = (value14 * 31337)
            local arguments57 = joinArguments({[1] = item38, [2] = value56, [3] = value55}, 3, nil)
            local item58 = arguments57[1]
            local item59 = arguments57[2]
            local item60 = arguments57[3]
            local value61 = (item59 % 32)
            local lrotate = bit32.lrotate(item58, value61)
            local value62 = (item60 % 32)
            local rrotate = bit32.rrotate(item59, value62)
            local bxor63 = bit32.bxor(item60, lrotate, rrotate)
            local value64 = (lrotate + rrotate)
            local value65 = (value64 + bxor63)
            local results66 = pack(bit32.band(value65, 4294967295))
            local arguments67 = joinArguments({[1] = secondaryChecksum}, 1, results66)
            local bxor68 = bit32.bxor(unpack(arguments67, 1, arguments67.n))
            local value69 = (value14 + bound10)
            randomState = item28
            primaryChecksum = value55
            secondaryChecksum = bxor68
            value14 = value69
            continue
        end
        primaryChecksum = value15
        secondaryChecksum = value16
        break
    end
    state.mixerCell = mixerCell
    state.primaryChecksum = primaryChecksum
    state.secondaryChecksum = secondaryChecksum
    state.hashBytes = hashBytes
end
 
do -- 3. Salted mixer inputs
    local saltedMixer = makeReadableHelper("application_1/3", {[1] = state.mixerCell})
    local saltedMixer70 = invoke(saltedMixer, 2779096485)
    local saltedMixer71 = invoke(saltedMixer, 1515870810)
    local create = table.create(96)
    local bound72 = tonumber(1)
    local bound73 = tonumber(96)
    local bound74 = tonumber(1)
    if (((bound72 == nil) or (bound73 == nil)) or (bound74 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value75 = bound72
    while true do
        if (not (((bound74 > 0) and (value75 <= bound73)) or ((not (bound74 > 0)) and (value75 >= bound73)))) then
        else
            local value76 = (value75 * 7)
            local value77 = (value76 - 1)
            local length78 = (#state.seedValues)
            local value79 = (value77 % length78)
            local value80 = (value79 + 1)
            local item81 = state.seedValues[value80]
            local value82 = (value75 % 3)
            local condition = (value82 == 0)
            if (not condition) then
                local value83 = (value75 % 3)
                local condition84 = (value83 == 1)
                if (not condition84) then
                    local item85 = state.mixerCell[1]
                    local value86 = (value75 * value75)
                    local value87 = (item81 + value86)
                    local item88 = invoke(item85, value87)
                    create[value75] = item88
                else
                    local value89 = (97 - value75)
                    local saltedMixer90 = invoke(saltedMixer71, item81, value89)
                    create[value75] = saltedMixer90
                end
            else
                local saltedMixer91 = invoke(saltedMixer70, item81, value75)
                create[value75] = saltedMixer91
            end
            local value92 = (value75 + bound74)
            value75 = value92
            continue
        end
        break
    end
    state.create = create
end
 
do -- 4. Rotated inputs
    local hashBytes93 = invoke(state.hashBytes, state.create)
    local result = type(hashBytes93)
    local condition94 = (result == "number")
    assert(condition94)
    local create95 = table.create(8)
    local bound96 = tonumber(1)
    local bound97 = tonumber(8)
    local bound98 = tonumber(1)
    if (((bound96 == nil) or (bound97 == nil)) or (bound98 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value99 = bound96
    while true do
        if (not (((bound98 > 0) and (value99 <= bound97)) or ((not (bound98 > 0)) and (value99 >= bound97)))) then
        else
            local create100 = table.create(8)
            local bound101 = tonumber(1)
            local bound102 = tonumber(8)
            local bound103 = tonumber(1)
            if (((bound101 == nil) or (bound102 == nil)) or (bound103 == nil)) then
                error(invoke(P, 77), 0)
            end
            local value104 = bound101
            while true do
                if (not (((bound103 > 0) and (value104 <= bound102)) or ((not (bound103 > 0)) and (value104 >= bound102)))) then
                    break
                end
                local value105 = (value99 * 31)
                local value106 = (value104 * 17)
                local value107 = (value105 + value106)
                local value108 = (value99 * value104)
                local length109 = (#state.create)
                local value110 = (value108 % length109)
                local value111 = (value110 + 1)
                local item112 = state.create[value111]
                local value113 = (value107 + item112)
                local value114 = (value113 % 65536)
                create100[value104] = value114
                local value115 = (value104 + bound103)
                value104 = value115
            end
            create95[value99] = create100
            local value116 = (value99 + bound98)
            value99 = value116
            continue
        end
        break
    end
    state.hashBytes93 = hashBytes93
    state.create95 = create95
end
 
do -- 5. Rotate and xor accumulation
    local bound117 = tonumber(1)
    local bound118 = tonumber(8)
    local bound119 = tonumber(1)
    if (((bound117 == nil) or (bound118 == nil)) or (bound119 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value120 = 0
    local value121 = bound117
    while true do
        if (not (((bound119 > 0) and (value121 <= bound118)) or ((not (bound119 > 0)) and (value121 >= bound118)))) then
            break
        end
        local item122 = state.create95[value121]
        local item123 = item122[value121]
        local value124 = (value120 + item123)
        local item125 = state.create95[value121]
        local value126 = (9 - value121)
        local item127 = item125[value126]
        local value128 = (value124 + item127)
        local value129 = (value121 + bound119)
        value120 = value128
        value121 = value129
    end
    state.value120 = value120
end
 
do -- 6. Generate character bytes
    local condition130 = (state.value120 > 0)
    assert(condition130)
    local create131 = table.create(64)
    local bound132 = tonumber(1)
    local bound133 = tonumber(64)
    local bound134 = tonumber(1)
    if (((bound132 == nil) or (bound133 == nil)) or (bound134 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value135 = bound132
    while true do
        if (not (((bound134 > 0) and (value135 <= bound133)) or ((not (bound134 > 0)) and (value135 >= bound133)))) then
        else
            local item136 = state.create[value135]
            local band137 = bit32.band(item136, 15)
            local value138 = (65 + band137)
            local rshift = bit32.rshift(item136, 4)
            local band139 = bit32.band(rshift, 15)
            local value140 = (97 + band139)
            local char = string.char(value138, value140)
            create131[value135] = char
            local value141 = (value135 + bound134)
            value135 = value141
            continue
        end
        break
    end
    state.create131 = create131
end
 
do -- 7. String checksum
    local concat = table.concat(state.create131)
    local values142 = {[1] = concat}
    local item143 = values142[1]
    local length144 = (#item143)
    local condition145 = (length144 == 128)
    assert(condition145)
    local item146 = values142[1]
    local reverse = string.reverse(item146)
    local length147 = (#reverse)
    local bound148 = tonumber(1)
    local bound149 = tonumber(length147)
    local bound150 = tonumber(1)
    if (((bound148 == nil) or (bound149 == nil)) or (bound150 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value151 = 0
    local value152 = bound148
    while true do
        local value153 = value151
        if (not (((bound150 > 0) and (value152 <= bound149)) or ((not (bound150 > 0)) and (value152 >= bound149)))) then
            value153 = value151
        else
            local byte = string.byte(reverse, value152)
            local value154 = (byte * value152)
            local value155 = (value151 + value154)
            local value156 = (value155 % 1000000007)
            local value157 = (value152 + bound150)
            value151 = value156
            value152 = value157
            continue
        end
        value151 = value153
        break
    end
    state.value151 = value151
    state.values142 = values142
end
 
do -- 8. String replacements and pair iteration
    local item158 = state.values142[1]
    local shiftCharacter = makeReadableHelper("application_1/4", {})
    local results159 = pack(string.gsub(item158, "[A-H]", shiftCharacter))
    local item160 = results159[1]
    local item161 = results159[2]
    local condition162 = (item161 >= 0)
    local value163 = condition162
    if (not condition162) then
        value163 = condition162
    else
        local length164 = (#item160)
        local item165 = state.values142[1]
        local length166 = (#item165)
        local condition167 = (length164 == length166)
        value163 = condition167
    end
    assert(value163)
    local values168 = {}
    local results169 = pack(string.gmatch(item160, ".."))
    local arguments170 = joinArguments({}, 0, results169)
    local iterator = beginIteration(arguments170, 1)
    while true do
        local iteration = nextIteration(iterator)
        local item171 = iteration[1]
        if (item171 == nil) then
            break
        end
        local item172 = iteration[1]
        local length173 = (#values168)
        local value174 = (length173 + 1)
        values168[value174] = item172
    end
    state.values168 = values168
end
 
do -- 9. Packed integers and buffer setup
    local length175 = (#state.values168)
    local condition176 = (length175 == 64)
    assert(condition176)
    local pack177 = string.pack("<I4I4I4I4", state.hashBytes93, state.secondaryChecksum, state.primaryChecksum, state.value151)
    local results178 = pack(string.unpack("<I4I4I4I4", pack177))
    local item179 = results178[1]
    local item180 = results178[2]
    local item181 = results178[3]
    local item182 = results178[4]
    local item183 = results178[5]
    local length184 = (#pack177)
    local value185 = (length184 + 1)
    local condition186 = (item183 == value185)
    assert(condition186)
    local condition187 = (item179 == state.hashBytes93)
    local value188 = condition187
    if (not condition187) then
        value188 = condition187
    else
        local condition189 = (item180 == state.secondaryChecksum)
        value188 = condition189
    end
    local value190 = value188
    if (not value188) then
        value190 = value188
    else
        local condition191 = (item181 == state.primaryChecksum)
        value190 = condition191
    end
    local value192 = value190
    if (not value190) then
        value192 = value190
    else
        local condition193 = (item182 == state.value151)
        value192 = condition193
    end
    assert(value192)
    local byteBuffer = buffer.create(512)
    local bound194 = tonumber(0)
    local bound195 = tonumber(63)
    local bound196 = tonumber(1)
    if (((bound194 == nil) or (bound195 == nil)) or (bound196 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value197 = bound194
    while true do
        if (not (((bound196 > 0) and (value197 <= bound195)) or ((not (bound196 > 0)) and (value197 >= bound195)))) then
        else
            local value198 = (value197 + 1)
            local item199 = state.create[value198]
            local value200 = (value197 * 4)
            buffer.writeu32(byteBuffer, value200, item199)
            local value201 = (value197 + bound196)
            value197 = value201
            continue
        end
        break
    end
    state.byteBuffer = byteBuffer
end
 
do -- 10. Buffer xor updates
    local bound202 = tonumber(0)
    local bound203 = tonumber(31)
    local bound204 = tonumber(1)
    if (((bound202 == nil) or (bound203 == nil)) or (bound204 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value205 = bound202
    while true do
        if (not (((bound204 > 0) and (value205 <= bound203)) or ((not (bound204 > 0)) and (value205 >= bound203)))) then
        else
            local value206 = (value205 * 4)
            local readu = buffer.readu32(state.byteBuffer, value206)
            local value207 = (63 - value205)
            local value208 = (value207 * 4)
            local readu209 = buffer.readu32(state.byteBuffer, value208)
            local value210 = (value205 * 4)
            local value211 = (256 + value210)
            local results212 = pack(bit32.bxor(readu, readu209))
            local arguments213 = joinArguments({[1] = state.byteBuffer, [2] = value211}, 2, results212)
            buffer.writeu32(unpack(arguments213, 1, arguments213.n))
            local value214 = (value205 + bound204)
            value205 = value214
            continue
        end
        break
    end
end
 
do -- 11. Buffer checksum
    local bound215 = tonumber(0)
    local bound216 = tonumber(31)
    local bound217 = tonumber(1)
    if (((bound215 == nil) or (bound216 == nil)) or (bound217 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value218 = 0
    local value219 = bound215
    while true do
        local value220 = value218
        if (not (((bound217 > 0) and (value219 <= bound216)) or ((not (bound217 > 0)) and (value219 >= bound216)))) then
            value220 = value218
        else
            local value221 = (value219 * 4)
            local value222 = (256 + value221)
            local results223 = pack(buffer.readu32(state.byteBuffer, value222))
            local arguments224 = joinArguments({[1] = value218}, 1, results223)
            local bxor225 = bit32.bxor(unpack(arguments224, 1, arguments224.n))
            local value226 = (value219 + bound217)
            value218 = bxor225
            value219 = value226
            continue
        end
        value218 = value220
        break
    end
    state.value218 = value218
end
 
do -- 12. Buffer copy and vector setup
    buffer.fill(state.byteBuffer, 384, 90, 64)
    local readstring = buffer.readstring(state.byteBuffer, 384, 8)
    local condition227 = (readstring == "ZZZZZZZZ")
    assert(condition227)
    local byteBuffer228 = buffer.create(64)
    buffer.copy(byteBuffer228, 0, state.byteBuffer, 64, 64)
    local len = buffer.len(byteBuffer228)
    local condition229 = (len == 64)
    assert(condition229)
    local create230 = table.create(24)
    local bound231 = tonumber(1)
    local bound232 = tonumber(24)
    local bound233 = tonumber(1)
    if (((bound231 == nil) or (bound232 == nil)) or (bound233 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value234 = bound231
    while true do
        if (not (((bound233 > 0) and (value234 <= bound232)) or ((not (bound233 > 0)) and (value234 >= bound232)))) then
            break
        end
        local value235 = (value234 % 7)
        local value236 = (value235 - 3)
        local value237 = (value234 % 5)
        local value238 = (value237 - 2)
        local value239 = (value234 % 11)
        local value240 = (value239 - 5)
        local vector = Vector3.new(value236, value238, value240)
        create230[value234] = vector
        local value241 = (value234 + bound233)
        value234 = value241
    end
    state.create230 = create230
end
 
do -- 13. Build vector inputs
    local length242 = (#state.create230)
    local bound243 = tonumber(1)
    local bound244 = tonumber(length242)
    local bound245 = tonumber(1)
    if (((bound243 == nil) or (bound244 == nil)) or (bound245 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value246 = Vector3.zero
    local value247 = bound243
    while true do
        local value248 = value246
        if (not (((bound245 > 0) and (value247 <= bound244)) or ((not (bound245 > 0)) and (value247 >= bound244)))) then
            value248 = value246
        else
            local item249 = state.create230[value247]
            local value250 = (value247 % 3)
            local value251 = (value250 - 1)
            local value252 = (value247 + 1)
            local value253 = (value252 % 3)
            local value254 = (value253 - 1)
            local value255 = (value247 + 2)
            local value256 = (value255 % 3)
            local value257 = (value256 - 1)
            local vector258 = Vector3.new(value251, value254, value257)
            local value259 = (item249 + vector258)
            local value260 = (value246 + value259)
            local value261 = (value247 + bound245)
            value246 = value260
            value247 = value261
            continue
        end
        value246 = value248
        break
    end
    state.value246 = value246
end
 
do -- 14. Vector dot accumulation
    local length262 = (#state.create230)
    local value263 = (length262 - 1)
    local bound264 = tonumber(1)
    local bound265 = tonumber(value263)
    local bound266 = tonumber(1)
    if (((bound264 == nil) or (bound265 == nil)) or (bound266 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value267 = 0
    local value268 = bound264
    while true do
        local value269 = value267
        if (not (((bound266 > 0) and (value268 <= bound265)) or ((not (bound266 > 0)) and (value268 >= bound265)))) then
            value269 = value267
        else
            local item270 = state.create230[value268]
            local dot = item270.Dot
            local value271 = (value268 + 1)
            local item272 = state.create230[value271]
            local dot273 = item270.Dot
            local Dot = invoke(item270.Dot, item270, item272)
            local value274 = (value267 + Dot)
            local value275 = (value268 + bound266)
            value267 = value274
            value268 = value275
            continue
        end
        value267 = value269
        break
    end
    state.value267 = value267
end
 
do -- 15. Vector cross accumulation
    local bound276 = tonumber(1)
    local bound277 = tonumber(12)
    local bound278 = tonumber(1)
    if (((bound276 == nil) or (bound277 == nil)) or (bound278 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value279 = Vector3.zero
    local value280 = bound276
    while true do
        local value281 = value279
        if (not (((bound278 > 0) and (value280 <= bound277)) or ((not (bound278 > 0)) and (value280 >= bound277)))) then
            value281 = value279
        else
            local item282 = state.create230[value280]
            local cross = item282.Cross
            local length283 = (#state.create230)
            local value284 = (length283 - value280)
            local value285 = (value284 + 1)
            local item286 = state.create230[value285]
            local cross287 = item282.Cross
            local Cross = invoke(item282.Cross, item282, item286)
            local value288 = (value279 + Cross)
            local value289 = (value280 + bound278)
            value279 = value288
            value280 = value289
            continue
        end
        value279 = value281
        break
    end
    state.value279 = value279
end
 
do -- 16. Build CFrame transforms
    local typeof290 = typeof(state.value246)
    local condition291 = (typeof290 == "Vector3")
    local value292 = condition291
    if (not condition291) then
        value292 = condition291
    else
        local typeof293 = typeof(state.value279)
        local condition294 = (typeof293 == "Vector3")
        value292 = condition294
    end
    assert(value292)
    local create295 = table.create(20)
    local bound296 = tonumber(1)
    local bound297 = tonumber(20)
    local bound298 = tonumber(1)
    if (((bound296 == nil) or (bound297 == nil)) or (bound298 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value299 = bound296
    while true do
        if (not (((bound298 > 0) and (value299 <= bound297)) or ((not (bound298 > 0)) and (value299 >= bound297)))) then
        else
            local value300 = (value299 * 0.25)
            local sin = math.sin(value299)
            local results301 = pack(math.cos(value299))
            local arguments302 = joinArguments({[1] = value300, [2] = sin}, 2, results301)
            local vector303 = Vector3.new(unpack(arguments302, 1, arguments302.n))
            local value304 = (value299 * 0.01)
            local value305 = (value299 * 0.02)
            local value306 = (value299 * 0.03)
            local transform = CFrame.Angles(value304, value305, value306)
            local transform307 = CFrame.new(vector303)
            local value308 = (transform307 * transform)
            create295[value299] = value308
            local value309 = (value299 + bound298)
            value299 = value309
            continue
        end
        break
    end
    state.create295 = create295
end
 
do -- 17. Compose CFrame transforms
    local length310 = (#state.create295)
    local bound311 = tonumber(1)
    local bound312 = tonumber(length310)
    local bound313 = tonumber(1)
    if (((bound311 == nil) or (bound312 == nil)) or (bound313 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value314 = CFrame.identity
    local value315 = bound311
    while true do
        local value316 = value314
        if (not (((bound313 > 0) and (value315 <= bound312)) or ((not (bound313 > 0)) and (value315 >= bound312)))) then
            value316 = value314
        else
            local lerp = value314.Lerp
            local item317 = state.create295[value315]
            local value318 = (value315 % 5)
            local value319 = (value318 / 5)
            local lerp320 = value314.Lerp
            local Lerp = invoke(value314.Lerp, value314, item317, value319)
            local value321 = (value315 + bound313)
            value314 = Lerp
            value315 = value321
            continue
        end
        value314 = value316
        break
    end
    state.value314 = value314
end
 
do -- 18. Interpolate transforms and generate colors
    local position = state.value314.Position
    local x = state.value314.Position.X
    local position322 = state.value314.Position
    local y323 = state.value314.Position.Y
    local position324 = state.value314.Position
    local z = state.value314.Position.Z
    local x325 = state.value314.Position.X
    local y326 = state.value314.Position.Y
    local z327 = state.value314.Position.Z
    local x328 = state.value314.Position.X
    local x329 = state.value314.Position.X
    local x330 = state.value314.Position.X
    local x331 = state.value314.Position.X
    local condition332 = (state.value314.Position.X == state.value314.Position.X)
    local value333 = condition332
    if (not condition332) then
        value333 = condition332
    else
        local y334 = state.value314.Position.Y
        local y335 = state.value314.Position.Y
        local y336 = state.value314.Position.Y
        local y337 = state.value314.Position.Y
        local condition338 = (state.value314.Position.Y == state.value314.Position.Y)
        value333 = condition338
    end
    local value339 = value333
    if (not value333) then
        value339 = value333
    else
        local z340 = state.value314.Position.Z
        local z341 = state.value314.Position.Z
        local z342 = state.value314.Position.Z
        local z343 = state.value314.Position.Z
        local condition344 = (state.value314.Position.Z == state.value314.Position.Z)
        value339 = condition344
    end
    assert(value339)
    local create345 = table.create(32)
    local bound346 = tonumber(1)
    local bound347 = tonumber(32)
    local bound348 = tonumber(1)
    if (((bound346 == nil) or (bound347 == nil)) or (bound348 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value349 = bound346
    while true do
        if (not (((bound348 > 0) and (value349 <= bound347)) or ((not (bound348 > 0)) and (value349 >= bound347)))) then
        else
            local value350 = (value349 * 0.071)
            local value351 = (value350 % 1)
            local value352 = (value349 % 5)
            local value353 = (value352 * 0.1)
            local value354 = (0.5 + value353)
            local value355 = (value349 % 3)
            local value356 = (value355 * 0.1)
            local value357 = (0.6 + value356)
            local color = Color3.fromHSV(value351, value354, value357)
            create345[value349] = color
            local value358 = (value349 + bound348)
            value349 = value358
            continue
        end
        break
    end
    state.create345 = create345
end
 
do -- 19. Color accumulation
    local length359 = (#state.create345)
    local bound360 = tonumber(1)
    local bound361 = tonumber(length359)
    local bound362 = tonumber(1)
    if (((bound360 == nil) or (bound361 == nil)) or (bound362 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value363 = 0
    local value364 = bound360
    while true do
        if (not (((bound362 > 0) and (value364 <= bound361)) or ((not (bound362 > 0)) and (value364 >= bound361)))) then
            break
        end
        local item365 = state.create345[value364]
        local r = item365.R
        local g = item365.G
        local value366 = (item365.R + item365.G)
        local b = item365.B
        local value367 = (value366 + item365.B)
        local value368 = (value367 * 1000)
        local floor = math.floor(value368)
        local value369 = (value363 + floor)
        local value370 = (value364 + bound362)
        value363 = value369
        value364 = value370
    end
    state.value363 = value363
end
 
do -- 20. Create number ranges
    local create371 = table.create(16)
    local bound372 = tonumber(1)
    local bound373 = tonumber(16)
    local bound374 = tonumber(1)
    if (((bound372 == nil) or (bound373 == nil)) or (bound374 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value375 = bound372
    while true do
        if (not (((bound374 > 0) and (value375 <= bound373)) or ((not (bound374 > 0)) and (value375 >= bound373)))) then
        else
            local value376 = (value375 * 0.25)
            local value377 = (value375 * 0.25)
            local value378 = (value375 % 4)
            local value379 = (value377 + value378)
            local result380 = NumberRange.new(value376, value379)
            create371[value375] = result380
            local value381 = (value375 + bound374)
            value375 = value381
            continue
        end
        break
    end
    state.create371 = create371
end
 
do -- 21. Accumulate range bounds
    local length382 = (#state.create371)
    local bound383 = tonumber(1)
    local bound384 = tonumber(length382)
    local bound385 = tonumber(1)
    if (((bound383 == nil) or (bound384 == nil)) or (bound385 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value386 = 0
    local value387 = bound383
    while true do
        if (not (((bound385 > 0) and (value387 <= bound384)) or ((not (bound385 > 0)) and (value387 >= bound384)))) then
            break
        end
        local item388 = state.create371[value387]
        local min = item388.Min
        local value389 = (item388.Min * 17)
        local item390 = state.create371[value387]
        local max = item390.Max
        local value391 = (item390.Max * 13)
        local value392 = (value389 + value391)
        local value393 = (value386 + value392)
        local value394 = (value387 + bound385)
        value386 = value393
        value387 = value394
    end
    state.value386 = value386
end
 
do -- 22. Create number sequence
    local create395 = table.create(8)
    local bound396 = tonumber(1)
    local bound397 = tonumber(8)
    local bound398 = tonumber(1)
    if (((bound396 == nil) or (bound397 == nil)) or (bound398 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value399 = bound396
    while true do
        if (not (((bound398 > 0) and (value399 <= bound397)) or ((not (bound398 > 0)) and (value399 >= bound397)))) then
        else
            local value400 = ((table.create and table.create(3)) or {})
            local value401 = (value399 / 8)
            local result402 = NumberSequenceKeypoint.new(0, value401)
            value400[1] = result402
            local value403 = (9 - value399)
            local value404 = (value403 / 8)
            local result405 = NumberSequenceKeypoint.new(0.5, value404)
            value400[2] = result405
            local value406 = (value399 * 3)
            local value407 = (value406 % 8)
            local value408 = (value407 / 8)
            local results409 = pack(NumberSequenceKeypoint.new(1, value408))
            for _i3 = 1, results409.n, 1 do
                value400[((3 + _i3) - 1)] = results409[_i3]
            end
            local result410 = NumberSequence.new(value400)
            create395[value399] = result410
            local value411 = (value399 + bound398)
            value399 = value411
            continue
        end
        break
    end
    state.create395 = create395
end
 
do -- 23. Read material enumeration
    local item412 = state.create395[1]
    local typeof413 = typeof(item412)
    local condition414 = (typeof413 == "NumberSequence")
    assert(condition414)
    local GetEnumItems = invoke(Enum.Material.GetEnumItems, Enum.Material)
    local length415 = (#GetEnumItems)
    local min416 = math.min(length415, 32)
    local bound417 = tonumber(1)
    local bound418 = tonumber(min416)
    local bound419 = tonumber(1)
    if (((bound417 == nil) or (bound418 == nil)) or (bound419 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value420 = 0
    local value421 = bound417
    while true do
        local value422 = value420
        if (not (((bound419 > 0) and (value421 <= bound418)) or ((not (bound419 > 0)) and (value421 >= bound418)))) then
            value422 = value420
        else
            local item423 = GetEnumItems[value421]
            local value424 = item423.Value
            local value425 = item423.Value
            local value426 = (item423.Value * value421)
            local value427 = (value420 + value426)
            local value428 = (value421 + bound419)
            value420 = value427
            value421 = value428
            continue
        end
        value420 = value422
        break
    end
    state.value420 = value420
end
 
do -- 24. Proxy, boxed arithmetic, and custom iteration
    local newproxy429 = newproxy(true)
    local getmetatable430 = getmetatable(newproxy429)
    local prefixReader = makeReadableHelper("application_1/5", {[1] = state.values142})
    getmetatable430.__tostring = prefixReader
    getmetatable430.__metatable = "locked"
    local tostring431 = tostring(newproxy429)
    local length432 = (#tostring431)
    local condition433 = (length432 == 12)
    assert(condition433)
    local getmetatable434 = getmetatable(newproxy429)
    local condition435 = (getmetatable434 == "locked")
    assert(condition435)
    local values436 = {}
    local values437 = {[1] = values436}
    local item438 = values437[1]
    local item439 = values437[1]
    item438.__index = item439
    local item440 = values437[1]
    local constructBox = makeReadableHelper("application_1/6", {[1] = values437})
    item440.new = constructBox
    local item441 = values437[1]
    local addBox = makeReadableHelper("application_1/7", {[1] = values437})
    item441.__add = addBox
    local item442 = values437[1]
    local subtractBox = makeReadableHelper("application_1/8", {[1] = values437})
    item442.__sub = subtractBox
    local item443 = values437[1]
    local multiplyBox = makeReadableHelper("application_1/9", {[1] = values437})
    item443.__mul = multiplyBox
    local item444 = values437[1]
    local negateBox = makeReadableHelper("application_1/10", {[1] = values437})
    item444.__unm = negateBox
    local item445 = values437[1]
    local absoluteBox = makeReadableHelper("application_1/11", {})
    item445.__len = absoluteBox
    local item446 = values437[1]
    local stringifyBox = makeReadableHelper("application_1/12", {})
    item446.__tostring = stringifyBox
    local item447 = values437[1]
    local result448 = item447.new
    local result449 = item447.new
    local result450 = invoke(item447.new, 9)
    local value451 = (result450 + 7)
    local value452 = (value451 * 3)
    local value453 = (value452 - 5)
    local value454 = (-value453)
    local value455 = value454.value
    local value456 = (-43)
    local value457 = value454.value
    local condition458 = (value454.value == value456)
    local value459 = condition458
    if (not condition458) then
        value459 = condition458
    else
        local length460 = (#value454)
        local condition461 = (length460 == 43)
        value459 = condition461
    end
    assert(value459)
    local values462 = {}
    values462.base = 7
    values462.count = 12
    local values463 = {}
    local sequenceIterator = makeReadableHelper("application_1/13", {})
    values463.__iter = sequenceIterator
    local setmetatable = invoke(setmetatable, values462, values463)
    local arguments464 = joinArguments({[1] = setmetatable}, 1, nil)
    local iterator465 = beginIteration(arguments464, 2)
    local value466 = 0
    while true do
        local iteration467 = nextIteration(iterator465)
        local item468 = iteration467[1]
        local value469 = value466
        if (item468 == nil) then
            value469 = value466
        else
            local item470 = iteration467[1]
            local item471 = iteration467[2]
            local value472 = (item470 * 19)
            local value473 = (item471 * 23)
            local bxor474 = bit32.bxor(value472, value473)
            local value475 = (value466 + bxor474)
            value466 = value475
            continue
        end
        value466 = value469
        break
    end
    state.value466 = value466
end
 
do -- 25. Coroutine yields
    local condition476 = (state.value466 > 0)
    assert(condition476)
    local yieldSequence = makeReadableHelper("application_1/14", {})
    local create477 = coroutine.create(yieldSequence)
    local value478 = 0
    while true do
        local status = coroutine.status(create477)
        local condition479 = (status ~= "dead")
        local value480 = value478
        if (not condition479) then
            value480 = value478
        else
            local results481 = pack(coroutine.resume(create477, 28))
            local item482 = results481[1]
            local item483 = results481[2]
            local item484 = results481[3]
            assert(item482)
            local value485 = value478
            if (not item483) then
                value485 = value478
            else
                local value486 = (item483 * 7)
                local value487 = item484
                if item484 then
                    value487 = item484
                else
                    value487 = 0
                end
                local value488 = (value486 + value487)
                local value489 = (value478 + value488)
                value485 = value489
            end
            value478 = value485
            continue
        end
        value478 = value480
        break
    end
    state.value478 = value478
end
 
do -- 26. Protected numeric-error probes
    local bound490 = tonumber(1)
    local bound491 = tonumber(40)
    local bound492 = tonumber(1)
    if (((bound490 == nil) or (bound491 == nil)) or (bound492 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value493 = 0
    local value494 = bound490
    while true do
        local value495 = value493
        if (not (((bound492 > 0) and (value494 <= bound491)) or ((not (bound492 > 0)) and (value494 >= bound491)))) then
            value495 = value493
        else
            local values496 = {[1] = value494}
            local numericErrorProbe = makeReadableHelper("application_1/15", {[1] = values496, [2] = state.mixerCell})
            local results497 = pack(pcall(numericErrorProbe))
            local item498 = results497[1]
            local item499 = results497[2]
            local value500 = value493
            if (not item498) then
                local item501 = values496[1]
                local value502 = (item501 * 101)
                local bxor503 = bit32.bxor(value493, value502)
                value500 = bxor503
            else
                local bxor504 = bit32.bxor(value493, item499)
                value500 = bxor504
            end
            local value505 = (value494 + bound492)
            value493 = value500
            value494 = value505
            continue
        end
        value493 = value495
        break
    end
    state.value493 = value493
end
 
do -- 27. Table errors and error handlers
    local bound506 = tonumber(1)
    local bound507 = tonumber(20)
    local bound508 = tonumber(1)
    if (((bound506 == nil) or (bound507 == nil)) or (bound508 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value509 = 0
    local value510 = bound506
    while true do
        local value511 = value509
        if (not (((bound508 > 0) and (value510 <= bound507)) or ((not (bound508 > 0)) and (value510 >= bound507)))) then
            value511 = value509
        else
            local values512 = {[1] = value510}
            local tableErrorProbe = makeReadableHelper("application_1/16", {[1] = values512})
            local errorCode = makeReadableHelper("application_1/17", {})
            local results513 = pack(xpcall(tableErrorProbe, errorCode))
            local item514 = results513[1]
            local item515 = results513[2]
            local value516 = item514
            if (not item514) then
                value516 = item514
            else
                value516 = item515
            end
            local value517 = value516
            if value516 then
                value517 = value516
            else
                local value518 = (-item515)
                value517 = value518
            end
            local value519 = (value509 + value517)
            local value520 = (value510 + bound508)
            value509 = value519
            value510 = value520
            continue
        end
        value509 = value511
        break
    end
    state.value509 = value509
end
 
do -- 28. Recursive and memoized sequences
    local values521 = {[1] = nil}
    local recursiveSum = makeReadableHelper("application_1/18", {[1] = values521})
    values521[1] = recursiveSum
    local item522 = values521[1]
    local item523 = invoke(item522, 17)
    local values524 = {}
    values524[0] = 0
    values524[1] = 1
    local values525 = {[1] = values524}
    local values526 = {[1] = nil}
    local memoizedSum = makeReadableHelper("application_1/19", {[1] = values525, [2] = values526})
    values526[1] = memoizedSum
    local item527 = values526[1]
    local item528 = invoke(item527, 35)
    local arguments529 = joinArguments({[1] = 11, [2] = 22, [3] = 33, [4] = 44}, 4, nil)
    local item530 = arguments529[1]
    local item531 = arguments529[2]
    local item532 = arguments529[3]
    local item533 = arguments529[4]
    local bxor534 = bit32.bxor(item530, item532)
    local value535 = (item531 + item532)
    local arguments536 = joinArguments({[1] = item533, [2] = bxor534, [3] = value535, [4] = item530}, 4, nil)
    local item537 = arguments536[1]
    local item538 = arguments536[2]
    local item539 = arguments536[3]
    local item540 = arguments536[4]
    local bound541 = tonumber(1)
    local bound542 = tonumber(32)
    local bound543 = tonumber(1)
    if (((bound541 == nil) or (bound542 == nil)) or (bound543 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value544 = item540
    local value545 = item537
    local value546 = item538
    local value547 = item539
    local value548 = bound541
    while true do
        local value549 = value544
        local value550 = value545
        local value551 = value546
        local value552 = value547
        if (not (((bound543 > 0) and (value548 <= bound542)) or ((not (bound543 > 0)) and (value548 >= bound542)))) then
            value549 = value544
            value550 = value545
            value551 = value546
            value552 = value547
        else
            local arguments553 = joinArguments({[1] = value545, [2] = value546, [3] = value547, [4] = value544}, 4, nil)
            local item554 = arguments553[1]
            local item555 = arguments553[2]
            local item556 = arguments553[3]
            local item557 = arguments553[4]
            local bxor558 = bit32.bxor(item554, item556)
            local value559 = (item555 + item556)
            local arguments560 = joinArguments({[1] = item557, [2] = bxor558, [3] = value559, [4] = item554}, 4, nil)
            local item561 = arguments560[1]
            local item562 = arguments560[2]
            local item563 = arguments560[3]
            local item564 = arguments560[4]
            local value565 = (value548 * 13)
            local value566 = (item561 + value565)
            local band567 = bit32.band(value566, 2147483647)
            local value568 = (value548 * 17)
            local value569 = (item562 + value568)
            local band570 = bit32.band(value569, 2147483647)
            local value571 = (value548 * 19)
            local value572 = (item563 + value571)
            local band573 = bit32.band(value572, 2147483647)
            local value574 = (value548 * 23)
            local value575 = (item564 + value574)
            local band576 = bit32.band(value575, 2147483647)
            local value577 = (value548 + bound543)
            value544 = band576
            value545 = band567
            value546 = band570
            value547 = band573
            value548 = value577
            continue
        end
        value544 = value549
        value545 = value550
        value546 = value551
        value547 = value552
        break
    end
    state.value544 = value544
    state.value547 = value547
    state.value546 = value546
    state.value545 = value545
    state.item528 = item528
    state.item523 = item523
end
 
do -- 29. Stateful integer mixing
    local bound578 = tonumber(1)
    local bound579 = tonumber(160)
    local bound580 = tonumber(1)
    if (((bound578 == nil) or (bound579 == nil)) or (bound580 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value581 = 0
    local value582 = bound578
    while true do
        local value583 = value581
        if (not (((bound580 > 0) and (value582 <= bound579)) or ((not (bound580 > 0)) and (value582 >= bound579)))) then
            value583 = value581
        else
            local value584 = (value582 - 1)
            local length585 = (#state.create)
            local value586 = (value584 % length585)
            local value587 = (value586 + 1)
            local item588 = state.create[value587]
            local band589 = bit32.band(item588, 7)
            local condition590 = (band589 == 0)
            local value591 = value581
            if (not condition590) then
                local condition592 = (band589 == 1)
                local value593 = value581
                if (not condition592) then
                    local condition594 = (band589 == 2)
                    local value595 = value581
                    if (not condition594) then
                        local condition596 = (band589 == 3)
                        local value597 = value581
                        if (not condition596) then
                            local condition598 = (band589 == 4)
                            local value599 = value581
                            if (not condition598) then
                                local condition600 = (band589 == 5)
                                local value601 = value581
                                if (not condition600) then
                                    local condition602 = (band589 == 6)
                                    local value603 = value581
                                    if (not condition602) then
                                        local value604 = (value582 // 3)
                                        local value605 = (value581 + value604)
                                        value603 = value605
                                    else
                                        local value606 = (value582 % 31)
                                        local results607 = pack(bit32.lrotate(value582, value606))
                                        local arguments608 = joinArguments({[1] = value581}, 1, results607)
                                        local bxor609 = bit32.bxor(unpack(arguments608, 1, arguments608.n))
                                        value603 = bxor609
                                    end
                                    value601 = value603
                                else
                                    local value610 = (value582 % 11)
                                    local value611 = (value582 % 13)
                                    local value612 = (value610 * value611)
                                    local value613 = (value581 + value612)
                                    value601 = value613
                                end
                                value599 = value601
                            else
                                local item614 = state.mixerCell[1]
                                local item615 = invoke(item614, value582)
                                local band616 = bit32.band(item615, 65535)
                                local value617 = (value581 - band616)
                                value599 = value617
                            end
                            value597 = value599
                        else
                            local value618 = (value582 % 97)
                            local arguments619 = joinArguments({[1] = value618}, 1, nil)
                            local item620 = arguments619[1]
                            local value621 = (item620 * 17)
                            local value622 = (value621 + 31)
                            local value623 = (value622 * item620)
                            local value624 = (value623 - 11)
                            local value625 = (value624 * item620)
                            local value626 = (value625 + 7)
                            local value627 = (value626 % 1000003)
                            local arguments628 = joinArguments({[1] = value627}, 1, nil)
                            local item629 = arguments628[1]
                            local value630 = (value581 + item629)
                            value597 = value630
                        end
                        value595 = value597
                    else
                        local value631 = (value582 * 7)
                        local bxor632 = bit32.bxor(value581, value631)
                        value595 = bxor632
                    end
                    value593 = value595
                else
                    local value633 = (value582 * 5)
                    local value634 = (value581 - value633)
                    value593 = value634
                end
                value591 = value593
            else
                local value635 = (value582 * 3)
                local value636 = (value581 + value635)
                value591 = value636
            end
            local value637 = (value582 + bound580)
            value581 = value591
            value582 = value637
            continue
        end
        value581 = value583
        break
    end
    state.value581 = value581
end
 
do -- 30. Rotated integer accumulation
    local value638 = 0
    local value639 = 1
    while true do
        local condition640 = (value639 <= 80)
        local value641 = value638
        if (not condition640) then
            value641 = value638
        else
            local value642 = (value639 * 5)
            local value643 = (value642 - 1)
            local length644 = (#state.create)
            local value645 = (value643 % length644)
            local value646 = (value645 + 1)
            local item647 = state.create[value646]
            local value648 = (value639 % 32)
            local results649 = pack(bit32.rrotate(item647, value648))
            local arguments650 = joinArguments({[1] = value638}, 1, results649)
            local bxor651 = bit32.bxor(unpack(arguments650, 1, arguments650.n))
            local value652 = (value639 + 1)
            value638 = bxor651
            value639 = value652
            continue
        end
        value638 = value641
        break
    end
    state.value638 = value638
end
 
do -- 31. Numeric accumulation
    local value653 = 0
    local value654 = 0
    while true do
        local value655 = (value653 + 1)
        local value656 = (value655 % 5)
        local condition657 = (value656 == 0)
        local value658 = value654
        if (not condition657) then
            local value659 = (value655 * 3)
            local value660 = (value654 + value659)
            value658 = value660
        else
            local value661 = (value655 * value655)
            local value662 = (value654 + value661)
            value658 = value662
        end
        local condition663 = (value655 >= 75)
        if (not condition663) then
            value653 = value655
            value654 = value658
            continue
        end
        value653 = value655
        value654 = value658
        break
    end
    state.value654 = value654
end
 
do -- 32. Keyed transform inputs
    local create664 = table.create(24)
    local bound665 = tonumber(1)
    local bound666 = tonumber(24)
    local bound667 = tonumber(1)
    if (((bound665 == nil) or (bound666 == nil)) or (bound667 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value668 = bound665
    while true do
        if (not (((bound667 > 0) and (value668 <= bound666)) or ((not (bound667 > 0)) and (value668 >= bound666)))) then
        else
            local value669 = (value668 * 101)
            local values670 = {[1] = value669}
            local keyedMixer = makeReadableHelper("application_1/20", {[1] = values670, [2] = state.mixerCell})
            create664[value668] = keyedMixer
            local value671 = (value668 + bound667)
            value668 = value671
            continue
        end
        break
    end
    state.create664 = create664
end
 
do -- 33. Keyed transform accumulation
    local bound672 = tonumber(1)
    local bound673 = tonumber(96)
    local bound674 = tonumber(1)
    if (((bound672 == nil) or (bound673 == nil)) or (bound674 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value675 = 0
    local value676 = bound672
    while true do
        if (not (((bound674 > 0) and (value676 <= bound673)) or ((not (bound674 > 0)) and (value676 >= bound673)))) then
            break
        end
        local value677 = (value676 - 1)
        local length678 = (#state.create664)
        local value679 = (value677 % length678)
        local value680 = (value679 + 1)
        local item681 = state.create664[value680]
        local value682 = (value676 * 65537)
        local results683 = pack(invoke(item681, value682))
        local arguments684 = joinArguments({[1] = value675}, 1, results683)
        local bxor685 = bit32.bxor(unpack(arguments684, 1, arguments684.n))
        local value686 = (value676 + bound674)
        value675 = bxor685
        value676 = value686
    end
    state.value675 = value675
end
 
do -- 34. Sort inputs
    local create687 = table.create(80)
    local bound688 = tonumber(1)
    local bound689 = tonumber(80)
    local bound690 = tonumber(1)
    if (((bound688 == nil) or (bound689 == nil)) or (bound690 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value691 = bound688
    while true do
        if (not (((bound690 > 0) and (value691 <= bound689)) or ((not (bound690 > 0)) and (value691 >= bound689)))) then
        else
            local item692 = state.mixerCell[1]
            local value693 = (value691 * 521288629)
            local item694 = invoke(item692, value693)
            local band695 = bit32.band(item694, 2147483647)
            create687[value691] = band695
            local value696 = (value691 + bound690)
            value691 = value696
            continue
        end
        break
    end
    state.create687 = create687
end
 
do -- 35. Scrambled sorting
    local compareScrambled = makeReadableHelper("application_1/21", {})
    table.sort(state.create687, compareScrambled)
    local length697 = (#state.create687)
    local bound698 = tonumber(1)
    local bound699 = tonumber(length697)
    local bound700 = tonumber(1)
    if (((bound698 == nil) or (bound699 == nil)) or (bound700 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value701 = 0
    local value702 = bound698
    while true do
        local value703 = value701
        if (not (((bound700 > 0) and (value702 <= bound699)) or ((not (bound700 > 0)) and (value702 >= bound699)))) then
            value703 = value701
        else
            local item704 = state.create687[value702]
            local value705 = (item704 % 1000003)
            local value706 = (value705 * value702)
            local value707 = (value701 + value706)
            local value708 = (value707 % 2147483647)
            local value709 = (value702 + bound700)
            value701 = value708
            value702 = value709
            continue
        end
        value701 = value703
        break
    end
    state.value701 = value701
end
 
do -- 36. Formatted string keys
    local values710 = {}
    local bound711 = tonumber(1)
    local bound712 = tonumber(64)
    local bound713 = tonumber(1)
    if (((bound711 == nil) or (bound712 == nil)) or (bound713 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value714 = bound711
    while true do
        if (not (((bound713 > 0) and (value714 <= bound712)) or ((not (bound713 > 0)) and (value714 >= bound712)))) then
            break
        end
        local item715 = state.create[value714]
        local results716 = pack(bit32.band(item715, 255))
        local arguments717 = joinArguments({[1] = "k_%02x_%02x", [2] = value714}, 2, results716)
        local format = string.format(unpack(arguments717, 1, arguments717.n))
        local item718 = state.create[value714]
        values710[format] = item718
        local value719 = (value714 + bound713)
        value714 = value719
    end
    state.values710 = values710
end
 
do -- 37. Iterate formatted keys
    local values720 = {}
    local arguments721 = joinArguments({[1] = state.values710}, 1, nil)
    local iterator722 = beginIteration(arguments721, 1)
    while true do
        local iteration723 = nextIteration(iterator722)
        local item724 = iteration723[1]
        if (item724 == nil) then
            break
        end
        local item725 = iteration723[1]
        local length726 = (#values720)
        local value727 = (length726 + 1)
        values720[value727] = item725
    end
    state.values720 = values720
end
 
do -- 38. Sort and accumulate results
    table.sort(state.values720)
    local length728 = (#state.values720)
    local bound729 = tonumber(1)
    local bound730 = tonumber(length728)
    local bound731 = tonumber(1)
    if (((bound729 == nil) or (bound730 == nil)) or (bound731 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value732 = 0
    local value733 = bound729
    while true do
        local value734 = value732
        if (not (((bound731 > 0) and (value733 <= bound730)) or ((not (bound731 > 0)) and (value733 >= bound730)))) then
            value734 = value732
        else
            local item735 = state.values720[value733]
            local item736 = state.values710[item735]
            local bxor737 = bit32.bxor(value732, item736)
            local value738 = (value733 + bound731)
            value732 = bxor737
            value733 = value738
            continue
        end
        value732 = value734
        break
    end
    state.value732 = value732
end
 
do -- 39. Frozen tables, clones, and moves
    local values739 = {}
    values739.alpha = state.hashBytes93
    values739.beta = state.secondaryChecksum
    values739.gamma = state.primaryChecksum
    local freeze = table.freeze(values739)
    local results740 = pack(table.isfrozen(freeze))
    local arguments741 = joinArguments({}, 0, results740)
    assert(unpack(arguments741, 1, arguments741.n))
    local clone = table.clone(freeze)
    local isfrozen = table.isfrozen(clone)
    local value742 = (not isfrozen)
    assert(value742)
    clone.delta = state.value151
    local value743 = ((table.create and table.create(9)) or {})
    value743[1] = 9
    value743[2] = 2
    value743[3] = 7
    value743[4] = 1
    value743[5] = 8
    value743[6] = 3
    value743[7] = 6
    value743[8] = 4
    value743[9] = 5
    local length744 = (#value743)
    local create745 = table.create(length744)
    local length746 = (#value743)
    table.move(value743, 1, length746, 1, create745)
    table.sort(create745)
    local concat747 = table.concat(create745, ",")
    local condition748 = (concat747 == "1,2,3,4,5,6,7,8,9")
    assert(condition748)
    local create749 = table.create(50)
    local bound750 = tonumber(1)
    local bound751 = tonumber(50)
    local bound752 = tonumber(1)
    if (((bound750 == nil) or (bound751 == nil)) or (bound752 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value753 = 74565
    local value754 = bound750
    while true do
        if (not (((bound752 > 0) and (value754 <= bound751)) or ((not (bound752 > 0)) and (value754 >= bound751)))) then
        else
            local value755 = (value753 * 1103515245)
            local value756 = (value755 + 12345)
            local value757 = (value756 % 2147483648)
            create749[value754] = value757
            local value758 = (value754 + bound752)
            value753 = value757
            value754 = value758
            continue
        end
        break
    end
    state.create749 = create749
end
 
do -- 40. Trigonometric functions
    local hashBytes759 = invoke(state.hashBytes, state.create749)
    local bound760 = tonumber(1)
    local bound761 = tonumber(100)
    local bound762 = tonumber(1)
    if (((bound760 == nil) or (bound761 == nil)) or (bound762 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value763 = 0
    local value764 = bound760
    while true do
        local value765 = value763
        if (not (((bound762 > 0) and (value764 <= bound761)) or ((not (bound762 > 0)) and (value764 >= bound761)))) then
            value765 = value763
        else
            local value766 = (value764 * math.pi)
            local value767 = (value766 / 37)
            local sin768 = math.sin(value767)
            local cos = math.cos(value767)
            local value769 = (value767 * 0.25)
            local tan = math.tan(value769)
            local value770 = (sin768 * sin768)
            local value771 = (cos * cos)
            local value772 = (value770 + value771)
            local value773 = (tan * 0.001)
            local value774 = (value772 + value773)
            local value775 = (value774 * 100000)
            local floor776 = math.floor(value775)
            local value777 = (value763 + floor776)
            local value778 = (value764 + bound762)
            value763 = value777
            value764 = value778
            continue
        end
        value763 = value765
        break
    end
    state.value763 = value763
    state.hashBytes759 = hashBytes759
end
 
do -- 41. Logarithms and square roots
    local bound779 = tonumber(1)
    local bound780 = tonumber(60)
    local bound781 = tonumber(1)
    if (((bound779 == nil) or (bound780 == nil)) or (bound781 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value782 = 0
    local value783 = bound779
    while true do
        local value784 = value782
        if (not (((bound781 > 0) and (value783 <= bound780)) or ((not (bound781 > 0)) and (value783 >= bound780)))) then
            value784 = value782
        else
            local value785 = (value783 + 0.125)
            local log = math.log(value785)
            local value786 = (value785 + 1)
            local log787 = math.log10(value786)
            local value788 = (log + log787)
            local value789 = (value785 * 17)
            local sqrt = math.sqrt(value789)
            local value790 = (value788 + sqrt)
            local value791 = (value782 + value790)
            local value792 = (value783 + bound781)
            value782 = value791
            value783 = value792
            continue
        end
        value782 = value784
        break
    end
    state.value782 = value782
end
 
do -- 42. Clamp, round, and sign
    local condition793 = (state.value782 > 0)
    assert(condition793)
    local value794 = (-50)
    local bound795 = tonumber(value794)
    local bound796 = tonumber(50)
    local bound797 = tonumber(1)
    if (((bound795 == nil) or (bound796 == nil)) or (bound797 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value798 = 0
    local value799 = bound795
    while true do
        local value800 = value798
        if (not (((bound797 > 0) and (value799 <= bound796)) or ((not (bound797 > 0)) and (value799 >= bound796)))) then
            value800 = value798
        else
            local value801 = (value799 * 3)
            local value802 = (-37)
            local clamp = math.clamp(value801, value802, 41)
            local value803 = (value798 + clamp)
            local value804 = (value799 / 7)
            local round = math.round(value804)
            local value805 = (value803 + round)
            local sign = math.sign(value799)
            local value806 = (value805 + sign)
            local value807 = (value799 + bound797)
            value798 = value806
            value799 = value807
            continue
        end
        value798 = value800
        break
    end
    state.value798 = value798
end
 
do -- 43. Integer and fractional parts
    local bound808 = tonumber(1)
    local bound809 = tonumber(40)
    local bound810 = tonumber(1)
    if (((bound808 == nil) or (bound809 == nil)) or (bound810 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value811 = 0
    local value812 = bound808
    while true do
        if (not (((bound810 > 0) and (value812 <= bound809)) or ((not (bound810 > 0)) and (value812 >= bound809)))) then
            break
        end
        local value813 = (value812 / 7)
        local results814 = pack(math.modf(value813))
        local item815 = results814[1]
        local item816 = results814[2]
        local value817 = (item815 * 13)
        local value818 = (item816 * 1000)
        local floor819 = math.floor(value818)
        local value820 = (value817 + floor819)
        local value821 = (value811 + value820)
        local value822 = (value812 + bound810)
        value811 = value821
        value812 = value822
    end
    state.value811 = value811
end
 
do -- 44. UTF-8 construction and iteration
    local char823 = utf8.char(65, 945, 937, 128578, 128640)
    local results824 = pack(utf8.codes(char823))
    local arguments825 = joinArguments({}, 0, results824)
    local iterator826 = beginIteration(arguments825, 2)
    local value827 = 0
    while true do
        local iteration828 = nextIteration(iterator826)
        local item829 = iteration828[1]
        local value830 = value827
        if (item829 == nil) then
            value830 = value827
        else
            local item831 = iteration828[1]
            local item832 = iteration828[2]
            local value833 = (item831 * 17)
            local value834 = (value833 + item832)
            local value835 = (value827 + value834)
            value827 = value835
            continue
        end
        value827 = value830
        break
    end
    state.value827 = value827
    state.char823 = char823
end
 
do -- 45. UTF-8 accumulation
    local len836 = utf8.len(state.char823)
    local condition837 = (len836 == 5)
    assert(condition837)
    local values838 = {}
    values838.A = state.primaryChecksum
    values838.B = state.secondaryChecksum
    values838.C = state.hashBytes93
    values838.D = state.value218
    values838.E = state.value151
    values838.F = state.value466
    values838.G = state.value478
    values838.H = state.value493
    values838.I = state.value509
    values838.J = state.item523
    values838.K = state.item528
    values838.L = state.value581
    values838.M = state.value638
    values838.N = state.value654
    values838.O = state.value675
    values838.P = state.value701
    values838.Q = state.value732
    values838.R = state.hashBytes759
    local arguments839 = joinArguments({[1] = values838}, 1, nil)
    local iterator840 = beginIteration(arguments839, 2)
    local value841 = 0
    while true do
        local iteration842 = nextIteration(iterator840)
        local item843 = iteration842[1]
        if (item843 == nil) then
            break
        end
        local item844 = iteration842[1]
        local item845 = iteration842[2]
        local item846 = state.mixerCell[1]
        local length847 = (#item844)
        local value848 = (length847 * 131)
        local band849 = bit32.band(item845, 4294967295)
        local value850 = (value848 + band849)
        local results851 = pack(invoke(item846, value850))
        local arguments852 = joinArguments({[1] = value841}, 1, results851)
        local bxor853 = bit32.bxor(unpack(arguments852, 1, arguments852.n))
        value841 = bxor853
    end
    state.value841 = value841
end
 
do -- 46. State machine and checksum preparation
    local value854 = ((table.create and table.create(34)) or {})
    value854[1] = state.hashBytes93
    value854[2] = state.secondaryChecksum
    value854[3] = state.primaryChecksum
    value854[4] = state.value151
    value854[5] = state.value218
    local floor855 = math.floor(state.value267)
    value854[6] = floor855
    local x856 = state.value246.X
    local x857 = state.value246.X
    local value858 = (state.value246.X * 1000)
    local floor859 = math.floor(value858)
    value854[7] = floor859
    local y860 = state.value279.Y
    local y861 = state.value279.Y
    local value862 = (state.value279.Y * 1000)
    local floor863 = math.floor(value862)
    value854[8] = floor863
    value854[9] = state.value363
    local floor864 = math.floor(state.value386)
    value854[10] = floor864
    value854[11] = state.value420
    value854[12] = state.value466
    value854[13] = state.value478
    value854[14] = state.value493
    value854[15] = state.value509
    value854[16] = state.item523
    value854[17] = state.item528
    value854[18] = state.value545
    value854[19] = state.value546
    value854[20] = state.value547
    value854[21] = state.value544
    value854[22] = state.value581
    value854[23] = state.value638
    value854[24] = state.value654
    value854[25] = state.value675
    value854[26] = state.value701
    value854[27] = state.value732
    value854[28] = state.hashBytes759
    local floor865 = math.floor(state.value763)
    value854[29] = floor865
    local floor866 = math.floor(state.value782)
    value854[30] = floor866
    value854[31] = state.value798
    value854[32] = state.value811
    value854[33] = state.value827
    value854[34] = state.value841
    local length867 = (#value854)
    local bound868 = tonumber(1)
    local bound869 = tonumber(length867)
    local bound870 = tonumber(1)
    if (((bound868 == nil) or (bound869 == nil)) or (bound870 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value871 = 3221344269
    local value872 = bound868
    while true do
        local value873 = value871
        if (not (((bound870 > 0) and (value872 <= bound869)) or ((not (bound870 > 0)) and (value872 >= bound869)))) then
            value873 = value871
        else
            local item874 = value854[value872]
            local condition875 = (item874 == item874)
            local value876 = condition875
            if (not condition875) then
                value876 = condition875
            else
                value876 = item874
            end
            local value877 = value876
            if value876 then
                value877 = value876
            else
                value877 = 0
            end
            local floor878 = math.floor(value877)
            local item879 = state.mixerCell[1]
            local value880 = (value872 * 2654435769)
            local value881 = (floor878 + value880)
            local results882 = pack(bit32.band(value881, 4294967295))
            local arguments883 = joinArguments({}, 0, results882)
            local results884 = pack(invoke(item879, unpack(arguments883, 1, arguments883.n)))
            local arguments885 = joinArguments({[1] = value871}, 1, results884)
            local bxor886 = bit32.bxor(unpack(arguments885, 1, arguments885.n))
            local value887 = (value872 * 7)
            local value888 = (value887 % 32)
            local lrotate889 = bit32.lrotate(bxor886, value888)
            local value890 = (value872 + bound870)
            value871 = lrotate889
            value872 = value890
            continue
        end
        value871 = value873
        break
    end
    state.value871 = value871
end
 
do -- 47. Checksum formatting and mixing round 1
    local format891 = string.format("%08x:%08x:%08x", state.value871, state.hashBytes93, state.secondaryChecksum)
    local length892 = (#format891)
    local condition893 = (length892 == 26)
    assert(condition893)
    local result894 = type(state.value871)
    local condition895 = (result894 == "number")
    assert(condition895)
    local result896 = type(format891)
    local condition897 = (result896 == "string")
    assert(condition897)
    local values898 = {}
    values898[127545045] = state.value871
    values898[610498934] = format891
    local value899 = (state.primaryChecksum + state.value151)
    local value900 = (value899 + state.value218)
    local value901 = (value900 + state.value466)
    values898[598294610] = value901
    local item902 = values898[127545045]
    local condition903 = (item902 == state.value871)
    local value904 = condition903
    if (not condition903) then
        value904 = condition903
    else
        local item905 = values898[610498934]
        local condition906 = (item905 == format891)
        value904 = condition906
    end
    local value907 = value904
    if (not value904) then
        value907 = value904
    else
        local item908 = values898[598294610]
        local item909 = values898[598294610]
        local condition910 = (item908 == item909)
        value907 = condition910
    end
    assert(value907)
    local bound911 = tonumber(1)
    local bound912 = tonumber(25)
    local bound913 = tonumber(1)
    if (((bound911 == nil) or (bound912 == nil)) or (bound913 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value914 = 0
    local value915 = bound911
    while true do
        local value916 = value914
        if (not (((bound913 > 0) and (value915 <= bound912)) or ((not (bound913 > 0)) and (value915 >= bound912)))) then
            value916 = value914
        else
            local item917 = state.mixerCell[1]
            local value918 = (value915 * 1046)
            local value919 = (value918 + 7919)
            local item920 = invoke(item917, value919)
            local value921 = (value915 + 1)
            local value922 = (value921 % 32)
            local lrotate923 = bit32.lrotate(item920, value922)
            local bxor924 = bit32.bxor(item920, lrotate923)
            local value925 = (value915 * 2)
            local value926 = (value925 % 32)
            local rrotate927 = bit32.rrotate(bxor924, value926)
            local band928 = bit32.band(rrotate927, 1)
            local condition929 = (band928 == 0)
            local value930 = value914
            if (not condition929) then
                local item931 = state.mixerCell[1]
                local value932 = (rrotate927 + value915)
                local results933 = pack(invoke(item931, value932))
                local arguments934 = joinArguments({[1] = value914}, 1, results933)
                local bxor935 = bit32.bxor(unpack(arguments934, 1, arguments934.n))
                value930 = bxor935
            else
                local bxor936 = bit32.bxor(value914, rrotate927)
                value930 = bxor936
            end
            local value937 = (value915 + bound913)
            value914 = value930
            value915 = value937
            continue
        end
        value914 = value916
        break
    end
    state.value914 = value914
end
 
do -- 48. Mixing round 2
    local result938 = type(state.value914)
    local condition939 = (result938 == "number")
    assert(condition939)
    local bound940 = tonumber(1)
    local bound941 = tonumber(26)
    local bound942 = tonumber(1)
    if (((bound940 == nil) or (bound941 == nil)) or (bound942 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value943 = 0
    local value944 = bound940
    while true do
        local value945 = value943
        if (not (((bound942 > 0) and (value944 <= bound941)) or ((not (bound942 > 0)) and (value944 >= bound941)))) then
            value945 = value943
        else
            local item946 = state.mixerCell[1]
            local value947 = (value944 * 1083)
            local value948 = (value947 + 15838)
            local item949 = invoke(item946, value948)
            local value950 = (value944 + 2)
            local value951 = (value950 % 32)
            local lrotate952 = bit32.lrotate(item949, value951)
            local bxor953 = bit32.bxor(item949, lrotate952)
            local value954 = (value944 * 3)
            local value955 = (value954 % 32)
            local rrotate956 = bit32.rrotate(bxor953, value955)
            local band957 = bit32.band(rrotate956, 1)
            local condition958 = (band957 == 0)
            local value959 = value943
            if (not condition958) then
                local item960 = state.mixerCell[1]
                local value961 = (rrotate956 + value944)
                local results962 = pack(invoke(item960, value961))
                local arguments963 = joinArguments({[1] = value943}, 1, results962)
                local bxor964 = bit32.bxor(unpack(arguments963, 1, arguments963.n))
                value959 = bxor964
            else
                local bxor965 = bit32.bxor(value943, rrotate956)
                value959 = bxor965
            end
            local value966 = (value944 + bound942)
            value943 = value959
            value944 = value966
            continue
        end
        value943 = value945
        break
    end
    state.value943 = value943
end
 
do -- 49. Mixing round 3
    local result967 = type(state.value943)
    local condition968 = (result967 == "number")
    assert(condition968)
    local bound969 = tonumber(1)
    local bound970 = tonumber(27)
    local bound971 = tonumber(1)
    if (((bound969 == nil) or (bound970 == nil)) or (bound971 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value972 = 0
    local value973 = bound969
    while true do
        local value974 = value972
        if (not (((bound971 > 0) and (value973 <= bound970)) or ((not (bound971 > 0)) and (value973 >= bound970)))) then
            value974 = value972
        else
            local item975 = state.mixerCell[1]
            local value976 = (value973 * 1120)
            local value977 = (value976 + 23757)
            local item978 = invoke(item975, value977)
            local value979 = (value973 + 3)
            local value980 = (value979 % 32)
            local lrotate981 = bit32.lrotate(item978, value980)
            local bxor982 = bit32.bxor(item978, lrotate981)
            local value983 = (value973 * 4)
            local value984 = (value983 % 32)
            local rrotate985 = bit32.rrotate(bxor982, value984)
            local band986 = bit32.band(rrotate985, 1)
            local condition987 = (band986 == 0)
            local value988 = value972
            if (not condition987) then
                local item989 = state.mixerCell[1]
                local value990 = (rrotate985 + value973)
                local results991 = pack(invoke(item989, value990))
                local arguments992 = joinArguments({[1] = value972}, 1, results991)
                local bxor993 = bit32.bxor(unpack(arguments992, 1, arguments992.n))
                value988 = bxor993
            else
                local bxor994 = bit32.bxor(value972, rrotate985)
                value988 = bxor994
            end
            local value995 = (value973 + bound971)
            value972 = value988
            value973 = value995
            continue
        end
        value972 = value974
        break
    end
    state.value972 = value972
end
 
do -- 50. Mixing round 4
    local result996 = type(state.value972)
    local condition997 = (result996 == "number")
    assert(condition997)
    local bound998 = tonumber(1)
    local bound999 = tonumber(28)
    local bound1000 = tonumber(1)
    if (((bound998 == nil) or (bound999 == nil)) or (bound1000 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value1001 = 0
    local value1002 = bound998
    while true do
        local value1003 = value1001
        if (not (((bound1000 > 0) and (value1002 <= bound999)) or ((not (bound1000 > 0)) and (value1002 >= bound999)))) then
            value1003 = value1001
        else
            local item1004 = state.mixerCell[1]
            local value1005 = (value1002 * 1157)
            local value1006 = (value1005 + 31676)
            local item1007 = invoke(item1004, value1006)
            local value1008 = (value1002 + 4)
            local value1009 = (value1008 % 32)
            local lrotate1010 = bit32.lrotate(item1007, value1009)
            local bxor1011 = bit32.bxor(item1007, lrotate1010)
            local value1012 = (value1002 * 5)
            local value1013 = (value1012 % 32)
            local rrotate1014 = bit32.rrotate(bxor1011, value1013)
            local band1015 = bit32.band(rrotate1014, 1)
            local condition1016 = (band1015 == 0)
            local value1017 = value1001
            if (not condition1016) then
                local item1018 = state.mixerCell[1]
                local value1019 = (rrotate1014 + value1002)
                local results1020 = pack(invoke(item1018, value1019))
                local arguments1021 = joinArguments({[1] = value1001}, 1, results1020)
                local bxor1022 = bit32.bxor(unpack(arguments1021, 1, arguments1021.n))
                value1017 = bxor1022
            else
                local bxor1023 = bit32.bxor(value1001, rrotate1014)
                value1017 = bxor1023
            end
            local value1024 = (value1002 + bound1000)
            value1001 = value1017
            value1002 = value1024
            continue
        end
        value1001 = value1003
        break
    end
    state.value1001 = value1001
end
 
do -- 51. Mixing round 5
    local result1025 = type(state.value1001)
    local condition1026 = (result1025 == "number")
    assert(condition1026)
    local bound1027 = tonumber(1)
    local bound1028 = tonumber(29)
    local bound1029 = tonumber(1)
    if (((bound1027 == nil) or (bound1028 == nil)) or (bound1029 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value1030 = 0
    local value1031 = bound1027
    while true do
        local value1032 = value1030
        if (not (((bound1029 > 0) and (value1031 <= bound1028)) or ((not (bound1029 > 0)) and (value1031 >= bound1028)))) then
            value1032 = value1030
        else
            local item1033 = state.mixerCell[1]
            local value1034 = (value1031 * 1194)
            local value1035 = (value1034 + 39595)
            local item1036 = invoke(item1033, value1035)
            local value1037 = (value1031 + 5)
            local value1038 = (value1037 % 32)
            local lrotate1039 = bit32.lrotate(item1036, value1038)
            local bxor1040 = bit32.bxor(item1036, lrotate1039)
            local value1041 = (value1031 * 6)
            local value1042 = (value1041 % 32)
            local rrotate1043 = bit32.rrotate(bxor1040, value1042)
            local band1044 = bit32.band(rrotate1043, 1)
            local condition1045 = (band1044 == 0)
            local value1046 = value1030
            if (not condition1045) then
                local item1047 = state.mixerCell[1]
                local value1048 = (rrotate1043 + value1031)
                local results1049 = pack(invoke(item1047, value1048))
                local arguments1050 = joinArguments({[1] = value1030}, 1, results1049)
                local bxor1051 = bit32.bxor(unpack(arguments1050, 1, arguments1050.n))
                value1046 = bxor1051
            else
                local bxor1052 = bit32.bxor(value1030, rrotate1043)
                value1046 = bxor1052
            end
            local value1053 = (value1031 + bound1029)
            value1030 = value1046
            value1031 = value1053
            continue
        end
        value1030 = value1032
        break
    end
    state.value1030 = value1030
end
 
do -- 52. Mixing round 6
    local result1054 = type(state.value1030)
    local condition1055 = (result1054 == "number")
    assert(condition1055)
    local bound1056 = tonumber(1)
    local bound1057 = tonumber(30)
    local bound1058 = tonumber(1)
    if (((bound1056 == nil) or (bound1057 == nil)) or (bound1058 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value1059 = 0
    local value1060 = bound1056
    while true do
        local value1061 = value1059
        if (not (((bound1058 > 0) and (value1060 <= bound1057)) or ((not (bound1058 > 0)) and (value1060 >= bound1057)))) then
            value1061 = value1059
        else
            local item1062 = state.mixerCell[1]
            local value1063 = (value1060 * 1231)
            local value1064 = (value1063 + 47514)
            local item1065 = invoke(item1062, value1064)
            local value1066 = (value1060 + 6)
            local value1067 = (value1066 % 32)
            local lrotate1068 = bit32.lrotate(item1065, value1067)
            local bxor1069 = bit32.bxor(item1065, lrotate1068)
            local value1070 = (value1060 * 7)
            local value1071 = (value1070 % 32)
            local rrotate1072 = bit32.rrotate(bxor1069, value1071)
            local band1073 = bit32.band(rrotate1072, 1)
            local condition1074 = (band1073 == 0)
            local value1075 = value1059
            if (not condition1074) then
                local item1076 = state.mixerCell[1]
                local value1077 = (rrotate1072 + value1060)
                local results1078 = pack(invoke(item1076, value1077))
                local arguments1079 = joinArguments({[1] = value1059}, 1, results1078)
                local bxor1080 = bit32.bxor(unpack(arguments1079, 1, arguments1079.n))
                value1075 = bxor1080
            else
                local bxor1081 = bit32.bxor(value1059, rrotate1072)
                value1075 = bxor1081
            end
            local value1082 = (value1060 + bound1058)
            value1059 = value1075
            value1060 = value1082
            continue
        end
        value1059 = value1061
        break
    end
    state.value1059 = value1059
end
 
do -- 53. Mixing round 7
    local result1083 = type(state.value1059)
    local condition1084 = (result1083 == "number")
    assert(condition1084)
    local bound1085 = tonumber(1)
    local bound1086 = tonumber(31)
    local bound1087 = tonumber(1)
    if (((bound1085 == nil) or (bound1086 == nil)) or (bound1087 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value1088 = 0
    local value1089 = bound1085
    while true do
        local value1090 = value1088
        if (not (((bound1087 > 0) and (value1089 <= bound1086)) or ((not (bound1087 > 0)) and (value1089 >= bound1086)))) then
            value1090 = value1088
        else
            local item1091 = state.mixerCell[1]
            local value1092 = (value1089 * 1268)
            local value1093 = (value1092 + 55433)
            local item1094 = invoke(item1091, value1093)
            local value1095 = (value1089 + 7)
            local value1096 = (value1095 % 32)
            local lrotate1097 = bit32.lrotate(item1094, value1096)
            local bxor1098 = bit32.bxor(item1094, lrotate1097)
            local value1099 = (value1089 * 8)
            local value1100 = (value1099 % 32)
            local rrotate1101 = bit32.rrotate(bxor1098, value1100)
            local band1102 = bit32.band(rrotate1101, 1)
            local condition1103 = (band1102 == 0)
            local value1104 = value1088
            if (not condition1103) then
                local item1105 = state.mixerCell[1]
                local value1106 = (rrotate1101 + value1089)
                local results1107 = pack(invoke(item1105, value1106))
                local arguments1108 = joinArguments({[1] = value1088}, 1, results1107)
                local bxor1109 = bit32.bxor(unpack(arguments1108, 1, arguments1108.n))
                value1104 = bxor1109
            else
                local bxor1110 = bit32.bxor(value1088, rrotate1101)
                value1104 = bxor1110
            end
            local value1111 = (value1089 + bound1087)
            value1088 = value1104
            value1089 = value1111
            continue
        end
        value1088 = value1090
        break
    end
    state.value1088 = value1088
end
 
do -- 54. Mixing round 8
    local result1112 = type(state.value1088)
    local condition1113 = (result1112 == "number")
    assert(condition1113)
    local bound1114 = tonumber(1)
    local bound1115 = tonumber(32)
    local bound1116 = tonumber(1)
    if (((bound1114 == nil) or (bound1115 == nil)) or (bound1116 == nil)) then
        error(invoke(P, 77), 0)
    end
    local value1117 = 0
    local value1118 = bound1114
    while true do
        local value1119 = value1117
        if (not (((bound1116 > 0) and (value1118 <= bound1115)) or ((not (bound1116 > 0)) and (value1118 >= bound1115)))) then
            value1119 = value1117
        else
            local item1120 = state.mixerCell[1]
            local value1121 = (value1118 * 1305)
            local value1122 = (value1121 + 63352)
            local item1123 = invoke(item1120, value1122)
            local value1124 = (value1118 + 8)
            local value1125 = (value1124 % 32)
            local lrotate1126 = bit32.lrotate(item1123, value1125)
            local bxor1127 = bit32.bxor(item1123, lrotate1126)
            local value1128 = (value1118 * 9)
            local value1129 = (value1128 % 32)
            local rrotate1130 = bit32.rrotate(bxor1127, value1129)
            local band1131 = bit32.band(rrotate1130, 1)
            local condition1132 = (band1131 == 0)
            local value1133 = value1117
            if (not condition1132) then
                local item1134 = state.mixerCell[1]
                local value1135 = (rrotate1130 + value1118)
                local results1136 = pack(invoke(item1134, value1135))
                local arguments1137 = joinArguments({[1] = value1117}, 1, results1136)
                local bxor1138 = bit32.bxor(unpack(arguments1137, 1, arguments1137.n))
                value1133 = bxor1138
            else
                local bxor1139 = bit32.bxor(value1117, rrotate1130)
                value1133 = bxor1139
            end
            local value1140 = (value1118 + bound1116)
            value1117 = value1133
            value1118 = value1140
            continue
        end
        value1117 = value1119
        break
    end
    state.value1117 = value1117
end
 
do -- 55. Final type check
    local result1141 = type(state.value1117)
    local condition1142 = (result1141 == "number")
    assert(condition1142)
    return
end
