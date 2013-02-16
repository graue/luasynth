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
-- Wait, how am I gonna do this?
-- I don't think I can... does the FFI auto convert Lua filehandles
-- to FILE * and vice versa? Probably not.
-- Though, I can define a sample pair. Let's try it.
ffi.cdef[[
typedef struct { float f[2]; } sample_pair;
size_t fread(void *ptr, size_t size, size_t nmemb, void *stream);
size_t fwrite(const void *ptr, size_t size, size_t nmemb, void *stream);
]]

local samplePair = ffi.new("sample_pair[?]", 1)
local plainSamples = {}
while ffi.C.fread(samplePair, 8, 1, io.stdin) do
    plainSamples[1] = samplePair[0].f[0]
    plainSamples[2] = samplePair[0].f[1]
    effect:process(plainSamples)
    samplePair[0].f[0] = plainSamples[1]
    samplePair[0].f[1] = plainSamples[2]
    if not ffi.C.fwrite(samplePair, 8, 1, io.stdout) then break end
end

-- It turns out reading and writing binary data (e.g. floats)
-- is annoying in Lua, requiring an add-on C library.
--
-- Basic idea here though:
-- Read N float samples from io.stdin.
-- Call effect:process(samples)
-- Write `samples` to io.stdout.
--
-- Then, if there are no bugs (lol), running this file
-- should result in a working gain effect.
--
-- To read/write floats you can use LHF's lpack library,
-- or write your own C code.
