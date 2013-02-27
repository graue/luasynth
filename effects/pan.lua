-- pan effect: horizontally pan a waveform

local wrap = require "util.wrap"


local defs = { name = 'Pan' }

defs.knobs = {}

defs.knobs.angle = {
    min     = -180.0,
    max     =  180.0,
    default =    0.0,
    label   = 'Angle (degrees)',

    onChange = function(state, newVal)
        local angleRad = math.rad(newVal)

        -- Implement trig formula for equal-power panning.
        -- 0 degrees is center, -45 full left, 45 full right.
        state.leftAmp  = math.cos(angleRad) - math.sin(angleRad)
        state.rightAmp = math.cos(angleRad) + math.sin(angleRad)

        -- Fun fact: 90 degrees inverts the left channel, -90
        -- inverts the right, and 180 or -180 inverts both channels
        -- (which is occasionally useful, and the only reason this
        -- machine supports values outside of [-90, 90]).
    end
}

defs.processSamplePair = function(state, left, right)
    return left * state.leftAmp, right * state.rightAmp
end


return wrap.wrapMachineDefs(defs)
