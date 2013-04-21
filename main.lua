local effects = {}

effects.amp = require "effects.amp"
effects.pan = require "effects.pan"
effects.delay = require "effects.delay"
effects.power = require "effects.power"
effects.filter = require "effects.filter"
effects.softsat = require "effects.softsat"
effects.stwidth = require "effects.stwidth"

if #arg < 1 then
    error("usage: luasynth unitname [-param val] ...")  
end

local isEffect = true
local unit = effects[arg[1]] and effects[arg[1]].new()
if not unit then
    unit = gens[arg[1]] and gens[arg[1]].new()
    if not unit then
        error("No such unit: " .. arg[1])
    end
    isEffect = false
end

local lengthLimitSecs = -1

for i=3,#arg,2 do
    local param = arg[i-1]
    if string.sub(param, 1, 1) ~= "-" then
        error("Expected a knob name starting with `-`: " .. param)
    end

    local knobName = string.sub(param, 2)

    if knobName == "length" then
        lengthLimitSecs = tonumber(arg[i])
    elseif unit.knobInfo[knobName] then
        unit[knobName] = arg[i]
    else
        error("Unit `" .. unit.name .. "` has no knob called `"
              .. knobName .. "`")
    end
end


-- Use LuaJIT's FFI to handle reading and writing floats.
local ffi = require "ffi"

ffi.cdef[[
typedef struct { float f[2]; } sample_pair;
size_t fread(void *ptr, size_t size, size_t nmemb, void *stream);
size_t fwrite(const void *ptr, size_t size, size_t nmemb, void *stream);
int isatty(int fd);
]]

-- Refuse to run if stdout is a terminal.
if ffi.C.isatty(1) ~= 0 then
    error("Stdout should not be a terminal. Try redirecting to a file")
end

local samplePair = ffi.new("sample_pair[?]", 1)
local plainSamples = {}
local rate = 44100  -- XXX
local pairsLeft = math.floor(lengthLimitSecs * rate)

while pairsLeft ~= 0 do
    if isEffect then
        if ffi.C.fread(samplePair, 8, 1, io.stdin) <= 0 then break end
        plainSamples[1] = samplePair[0].f[0]
        plainSamples[2] = samplePair[0].f[1]
        unit.process(plainSamples)
    else
        plainSamples = unit.generate(1)
    end
    samplePair[0].f[0] = plainSamples[1]
    samplePair[0].f[1] = plainSamples[2]
    if ffi.C.fwrite(samplePair, 8, 1, io.stdout) < 1 then break end

    pairsLeft = pairsLeft - 1
end
