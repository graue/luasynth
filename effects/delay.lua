-- delay effect

local wrap      = require "util.wrap"
local HistArray = require "util.histArray"




-- Convert a millisecond measurement to a whole number of samples.
local function msToSamples(ms)
    local sampleRate = 44100  -- XXX not changeable yet

    local function round(x)
        return math.floor(0.5+x)
    end

    return round(ms / 1000 * sampleRate)
end


defs = {name = 'Delay'}

defs.knobs = {}

defs.knobs.len = {
    min     =     0.11,
    max     = 10000,
    default =    48,
    label   = 'Length (ms)',

    onChange = function(state, newLen)
        state.sampleDelay = msToSamples(newLen)
    end
}

defs.knobs.feedback = {
    min      =   0.0,
    max      = 100.0,
    default  =  65.0,
    label    = 'Feedback (%)',
    onChange = function(state, newVal) state.feedback = newVal / 100 end
}

defs.knobs.dryOut = {
    min      =   0.0,
    max      = 100.0,
    default  = 100.0,
    label    = 'Dry Out (%)',
    onChange = function(state, newVal) state.dryOut = newVal / 100 end
}

defs.knobs.wetOut = {
    min      =   0.0,
    max      = 100.0,
    default  =  50.0,
    label    = 'Wet Out (%)',
    onChange = function(state, newVal) state.wetOut = newVal / 100 end
}


local function processInMono(dryOut, wetOut, feedback, buf, n, delay, sample)
    buf[n] =      sample + feedback*buf[n - delay]
    return dryOut*sample + wetOut  *buf[n - delay]
end


function defs.processSamplePair(state, l, r)
    if not state.n then
        state.n = 0
        local maxHistory = msToSamples(defs.knobs.len.max)
        state.bufL = HistArray.new(maxHistory)
        state.bufR = HistArray.new(maxHistory)
    end

    state.n = state.n+1
    local outL = processInMono(state.dryOut, state.wetOut, state.feedback,
                               state.bufL, state.n, state.sampleDelay, l)
    local outR = processInMono(state.dryOut, state.wetOut, state.feedback,
                               state.bufR, state.n, state.sampleDelay, r)
    return outL, outR
end


return wrap.wrapMachineDefs(defs)
