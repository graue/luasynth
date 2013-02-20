-- filter: highpass, lowpass, bandpass, notch
--
-- Implemented with formulas from Robert Bristow-Johnson's
-- Audio EQ Cookbook.

local wrap = require "wrap"


local function updateCoefs(state)
    local Fs = 44100  -- XXX: need interface to set/get a custom sample rate
    local f0 = state.public.center  -- Cutoff or center frequency
    local Q  = state.public.q

    local w0 = 2*math.pi*f0/Fs
    local cos_w0 = math.cos(w0)
    local sin_w0 = math.sin(w0)
    local alpha = sin_w0/(2*Q)

    if state.public.filtType == 'Lowpass' then
        state.b0 =  (1 - cos_w0)/2
        state.b1 =   1 - cos_w0
        state.b2 =  (1 - cos_w0)/2
        state.a0 =   1 + alpha
        state.a1 =  -2*cos_w0
        state.a2 =   1 - alpha
    elseif state.public.filtType == 'Highpass' then
        state.b0 =  (1 + cos_w0)/2
        state.b1 = -(1 + cos_w0)
        state.b2 =  (1 + cos_w0)/2
        state.a0 =   1 + alpha
        state.a1 =  -2*cos_w0
        state.a2 =   1 - alpha
    elseif state.public.filtType == 'Bandpass' then
        state.b0 =   sin_w0/2
        state.b1 =   0
        state.b2 =  -sin_w0/2
        state.a0 =   1 + alpha
        state.a1 =  -2*cos_w0
        state.a2 =   1 - alpha
    elseif state.public.filtType == 'Notch' then
        state.b0 =   1
        state.b1 =  -2*cos_w0
        state.b2 =   1
        state.a0 =   1 + alpha
        state.a1 =  -2*cos_w0
        state.a2 =   1 - alpha
    end
end


local defs = { name = 'Filter' }

defs.knobs = {}

defs.knobs.filtType = {
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
