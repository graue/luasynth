-- pan effect: horizontally pan a waveform

local wrap = require "wrap"


local defs = { name = 'Pan' }

defs.knobs = {}

defs.knobs.angle = {
    min     = -90.0,
    max     =  90.0,
    default =   0.0,
    label   = 'Angle (degrees)',

    onChange = function(state, newVal)
        local angleRad = math.rad(newVal)

        -- Implement trig formula for equal-power panning.
        state.leftAmp  = math.cos(angleRad) + math.sin(angleRad)
        state.rightAmp = math.cos(angleRad) - math.sin(angleRad)
    end
}

defs.processSamplePair = function(state, left, right)
    return left * state.leftAmp, right * state.rightAmp
end


return wrap.wrapMachineDefs(defs)
