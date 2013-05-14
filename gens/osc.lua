-- osc: sine, square, triangle and saw oscillators

local defs = {name = 'Osc', knobs = {}}

-- Define all the functions that map a phase to a [-1, 1] amplitude.
-- Lua is pretty verbose here :( This should really all be 5 lines.
-- Note that these all have a periodicity of 2, just 'cuz

local function sine(phase)
    return math.sin(phase * math.pi)
end

local function tri(phase)
    local f = phase % 2
    if f < 0.5 then
        return 2*f
    elseif f < 1.5 then
        return -2*f + 2
    else
        return 2*f - 4
    end
end

local function square(phase)
    if phase % 2 < 1 then
        return 1
    else
        return -1
    end
end

local function sawUp(phase)
    local f = (phase + 1) % 2
    return f - 1
end

local function sawDown(phase)
    return -sawUp(phase)
end


local funcForOsc = {
    ['Sine'] = sine,
    ['Triangle'] = tri,
    ['Square'] = square,
    ['Saw Up'] = sawUp,
    ['Saw Down'] = sawDown
}

local function dbToRatio(db)
    return 10 ^ (db/20)
end

defs.knobs.oscType = {
    label    = 'Oscillator type',
    options  = {'Sine', 'Triangle', 'Square', 'Saw Up', 'Saw Down'},
    default  = 'Sine',
    onChange = function(state, newVal)
        state.func = funcForOsc[newVal]
    end
}

defs.knobs.gain = {
    min      = -120.0,
    max      =    0.0,
    default  =   -8.0,
    label    = 'Gain (dB)',
    onChange = function(state, newVal)
        state.linearGain = dbToRatio(newVal)
    end
}

defs.knobs.freq = {
    label    = 'Frequency',
    min      =     0.0,
    max      = 22000.0,
    default  =   500.0,
    onChange = function(state, newVal)
        state.phaseInc = 2 * newVal / state.sampleRate
    end
}


function defs.generateOneSample(state)
    if not state.n then state.n = 0 end
    state.n = state.n + state.phaseInc
    return state.linearGain * state.func(state.n)
end


return require("util.wrap").wrapMachineDefs(defs)
