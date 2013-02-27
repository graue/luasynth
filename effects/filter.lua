-- filter: highpass, lowpass, bandpass, notch
--
-- Implemented with formulas from Robert Bristow-Johnson's
-- Audio EQ Cookbook.

local wrap      = require "util.wrap"
local HistArray = require "util.histArray"


local function initIfNeeded(state)
    -- Create buffers (history arrays) if not already extant.
    -- XXX This is called from updateCoefs(), but should be in a separate
    -- init function once the framework supports that.
    if not state.xLeft then
        state.xLeft  = HistArray.new(2)
        state.yLeft  = HistArray.new(2)
        state.xRight = HistArray.new(2)
        state.yRight = HistArray.new(2)
        state.n      = 0
    end
end


local function updateCoefs(state)
    local Fs = 44100  -- XXX: need interface to set/get a custom sample rate
    local f0 = state.public.center  -- Cutoff or center frequency
    local Q  = state.public.q

    local w0 = 2*math.pi*f0/Fs
    local cos_w0 = math.cos(w0)
    local sin_w0 = math.sin(w0)
    local alpha = sin_w0/(2*Q)

    local b0, b1, b2, a0, a1, a2

    if state.public.filtType == 'Lowpass' then
        b0 =  (1 - cos_w0)/2
        b1 =   1 - cos_w0
        b2 =  (1 - cos_w0)/2
        a0 =   1 + alpha
        a1 =  -2*cos_w0
        a2 =   1 - alpha
    elseif state.public.filtType == 'Highpass' then
        b0 =  (1 + cos_w0)/2
        b1 = -(1 + cos_w0)
        b2 =  (1 + cos_w0)/2
        a0 =   1 + alpha
        a1 =  -2*cos_w0
        a2 =   1 - alpha
    elseif state.public.filtType == 'Bandpass' then
        b0 =   sin_w0/2
        b1 =   0
        b2 =  -sin_w0/2
        a0 =   1 + alpha
        a1 =  -2*cos_w0
        a2 =   1 - alpha
    elseif state.public.filtType == 'Notch' then
        b0 =   1
        b1 =  -2*cos_w0
        b2 =   1
        a0 =   1 + alpha
        a1 =  -2*cos_w0
        a2 =   1 - alpha
    end

    -- The formula recommended by RBJ's cookbook is:
    --
    -- y[n] = (b0/a0)*x[n] + (b1/a0)*x[n-1] + (b2/a0)*x[n-2]
    --                     - (a1/a0)*y[n-1] - (a2/a0)*y[n-2]
    --
    -- By saving each of the quotients as constants we can gain
    -- a little efficiency and simplicity:
    --
    state.c1 = b0/a0
    state.c2 = b1/a0
    state.c3 = b2/a0
    state.c4 = a1/a0
    state.c5 = a2/a0

    initIfNeeded(state)
end


local defs = {name = 'Filter', knobs = {}}

defs.knobs.filtType = {
    label    = 'Filter type',
    options  = {'Lowpass', 'Highpass', 'Bandpass', 'Notch'},
    default  = 'Lowpass',
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


local function processSample(s, n, x, y, c1, c2, c3, c4, c5)
    y[n] = c1*x[n] + c2*x[n-1] + c3*x[n-2]
                   - c4*y[n-1] - c5*y[n-2]
    return y[n]
end


function defs.processSamplePair(state, l, r)
    local n = state.n + 1
    state.xLeft[n], state.xRight[n] = l, r
    outL = processSample(l, n, state.xLeft,  state.yLeft,  state.c1,
                         state.c2, state.c3, state.c4, state.c5)
    outR = processSample(r, n, state.xRight, state.yRight, state.c1,
                         state.c2, state.c3, state.c4, state.c5)
    state.n = n
    return outL, outR
end


return wrap.wrapMachineDefs(defs)
