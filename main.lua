local effects = {}

effects.amp = require "amp"

if #arg < 1 then
    error("usage: luasynth unitname [-param val] ...")  
end

local effect = effects[arg[1]] && effects[arg[1]].new()
if not effect then
    error("No such effect: " .. arg[1])
end

for i=3,#arg,2 do
    local param = arg[i-1]
    if string.sub(param, 1, 1) ~= "-" then
        error("Expected a knob name starting with `-`: " .. param)
    end
    local knobName = string.sub(param, 2)
    if not effect.knobDefs[knobName] then
        error("Effect `" .. effect.name .. "` has no knob called `"
              .. knobName .. "`")
    end
    effect[knobName] = arg[i]
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
