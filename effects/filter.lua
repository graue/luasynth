-- filter: highpass, lowpass, bandpass, notch

local wrap = require "wrap"


local function updateCoefs(state)
    -- TODO
end


local defs = { name = 'Filter' }

defs.knobs = {}

defs.knobs.filttype = {
    label    = 'Filter type',
    options  = {'Lowpass', 'Highpass', 'Bandpass', 'Notch'},
      -- XXX: 'options' is not yet supported, needs implementing
    onChange = function(state, newVal) updateCoefs(state) end
}

defs.knobs.center = {
    label    = 'Cutoff/center frequency',
    min      =     0.0,
    max      = 20000.0,
    default  =  2000.0,
    onChange = function(state, newVal) updateCoefs(state) end
}

defs.knobs.q = {
    label    = 'Q',
    min      =   0.001,
    max      = 500.0,
    default  =   1.0,
    onChange = function(state, newVal) updateCoefs(state) end
}

function defs.processSamplePair(state, l, r)
    -- TODO
end


return wrap.wrapMachineDefs(defs)
