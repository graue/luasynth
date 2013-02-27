-- soft saturator
--
-- Based on a formula posted by Bram de Jong:
--   http://musicdsp.org/showArchiveComment.php?ArchiveID=42
--
-- But I'm not convinced I understand how it works,
-- nor even sure I implemented the same thing. (This code
-- ignores the separate x>1 case.)
--
-- Long story short, this effect maps samples from (-inf, inf)
-- onto (-1, 1) in a way that sounds much more pleasing to the ear
-- than hard clipping.

local wrap = require "util.wrap"

local defs = {name = 'SoftSat', knobs = {}}

defs.knobs.range = {
    min     = 0.01,
    max     = 2.0,
    default = 1.0,
    label   = 'Range',

    onChange = function(state, newRange)
        if not state.public.hardness then return end  -- XXX need proper init
        state.normalizedRange = newRange * 2 / (state.public.hardness + 1)
    end
}

defs.knobs.hardness = {
    min     = 0.0,
    max     = 0.99,
    default = 0.5,
    label   = 'Hardness',

    onChange = function(state, newHardness)
        if not state.public.range then return end  -- XXX
        state.normalizedRange = state.public.range * 2 / (newHardness + 1)
    end
}


function shape(x, g)
    if x <= g then return x end

    return g + (x-g)/(1 + ( (x-g)/(1-g) * (x-g)/(1-g) ))
end


function defs.processOneSample(state, x)
    local g = state.public.hardness
    if x < 0 then
        return -shape(-x / state.normalizedRange, g) * state.normalizedRange
    else
        return  shape( x / state.normalizedRange, g) * state.normalizedRange
    end
end


return wrap.wrapMachineDefs(defs)
