local gens, effects = require("units").gens, require("units").effects

local function showHelpFor(unit, name)
    local unitType = "a generator"
    if unit.new().process then unitType = "an effect" end
    io.stderr:write(name .. " is " .. unitType .. "\n\n")
    for k,v in pairs(unit.knobInfo) do
        io.stderr:write("-" .. k .. ": " .. v.label .. "\n")
        if v.options then
            io.stderr:write("    Options: ")
            for k_,v_ in pairs(v.options) do
                io.stderr:write('"' .. v_ .. '" ')
            end
            io.stderr:write("\n")
        else
            io.stderr:write("    Minimum: " .. v.min .. "\n")
            io.stderr:write("    Maximum: " .. v.max .. "\n")
        end
        io.stderr:write("    Default: " .. v.default .. "\n")
    end
end

local function showHelp(topic)
    if not topic then
        io.stderr:write("usage: luasynth unitname [-param val] ...\n")
        io.stderr:write("for a list of units, run 'luasynth help units'\n")
    elseif topic == 'units' then
        io.stderr:write("generators:\n")
        for k,_ in pairs(gens) do
            io.stderr:write("  " .. k .. "\n")
        end
        io.stderr:write("effects:\n")
        for k,_ in pairs(effects) do
            io.stderr:write("  " .. k .. "\n")
        end
        io.stderr:write("for info on a unit, run 'luasynth help unitname'\n")
    else
        local unit = gens[topic] or effects[topic]
        if unit then
            showHelpFor(unit, topic)
        else
            io.stderr:write(topic .. " is not a unit\n")
        end
    end
    os.exit(1)
end


if #arg < 1 or arg[1] == 'help' or arg[1] == '--help' then
    showHelp(arg[2])
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
