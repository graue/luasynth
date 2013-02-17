local effects = {}

effects.amp = require "amp"

if #arg < 1 then
    error("usage: luasynth unitname [-param val] ...")  
end

local effect = effects[arg[1]] and effects[arg[1]].new()
if not effect then
    error("No such effect: " .. arg[1])
end

for i=3,#arg,2 do
    local param = arg[i-1]
    if string.sub(param, 1, 1) ~= "-" then
        error("Expected a knob name starting with `-`: " .. param)
    end
    local knobName = string.sub(param, 2)
    if not effect.knobInfo[knobName] then
        error("Effect `" .. effect.name .. "` has no knob called `"
              .. knobName .. "`")
    end
    effect[knobName] = arg[i]
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
while ffi.C.fread(samplePair, 8, 1, io.stdin) > 0 do
    plainSamples[1] = samplePair[0].f[0]
    plainSamples[2] = samplePair[0].f[1]
    effect:process(plainSamples)
    samplePair[0].f[0] = plainSamples[1]
    samplePair[0].f[1] = plainSamples[2]
    if ffi.C.fwrite(samplePair, 8, 1, io.stdout) < 1 then break end
end
