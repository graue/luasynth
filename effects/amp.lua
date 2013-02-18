-- amp effect

local wrap = require "wrap"


-- Convert from dB to voltage ratio,
-- e.g. dbToRatio(6) is about 2, dbToRatio(-3) is about 0.7
local function dbToRatio(db)
    return 10 ^ (db/20)
end


local defs = {name = 'Amp'}

-- Define the user-controllable parameters for the amp effect.
defs.knobs = {}

defs.knobs.gain = {
    min      = -120.0,
    max      =   90.0,
    default  =    0.0,
    label    = 'dB gain',

    -- Callback that updates an internal state value when the knob is
    -- changed.
    onChange = function(state, newVal)
        state.linearGain = dbToRatio(newVal)
    end
}


function defs.processOneSample(state, sample)
    return sample * state.linearGain
end


return wrap.wrapMachineDefs(defs)
