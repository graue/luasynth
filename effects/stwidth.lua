-- stereo width adjuster

local wrap = require "util.wrap"

local defs = {name = 'Stereo Widener', knobs = {}}

defs.knobs.width = {
    min     =  0.0,
    max     = 10.0,
    default =  1.0,
    label   = 'Width'
}

function defs.processSamplePair(state, l, r)
    local mid  = 0.5 * (l + r)
    local side = 0.5 * (r - l) * state.public.width
    return mid - side, mid + side
end

return wrap.wrapMachineDefs(defs)
