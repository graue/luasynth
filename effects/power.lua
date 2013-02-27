-- power: waveshaper distortion (raise samples to a power)

local wrap = require "util.wrap"

local defs = {name = 'Power', knobs = {}}

defs.knobs.exponent = {
    min     = 0.0001,
    max     = 8.0,
    default = 1.0,
    label   = 'Exponent'
}

function defs.processOneSample(state, sample)
    if sample < 0.0 then
        return -math.pow(-sample, state.public.exponent)
    else
        return  math.pow( sample, state.public.exponent)
    end
end

return wrap.wrapMachineDefs(defs)
