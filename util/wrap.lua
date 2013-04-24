-- Wrap a machine definition in an object factory.

local M = {}


local function findElement(array, el)
    for i,v in ipairs(array) do
        if v == el then return i end
    end
    return nil
end


-- Wrappers for mono and stereo effects.
-- We wrap each processing function twice:
--   1. to process a whole array instead of a single sample / sample pair,
--   2. to encapsulate private state.

-- For stateless functions that process one sample at a time,
-- and for which stereo is irrelevant.
local function wrapMonoEffect(monoFunc)
    return function(state)
        return function(samples)
            local i = 1
            while samples[i] do
                samples[i] = monoFunc(state, samples[i])
                i = i+1
            end
        end
    end
end

-- For stateful or stereo-aware functions.
local function wrapStereoEffect(stereoFunc)
    return function(state)
        return function(samples)
            local i = 1
            while samples[i+1] do
                samples[i], samples[i+1] = stereoFunc(state, samples[i],
                                                    samples[i+1])
                i = i+2
            end
            if samples[i] then error "Odd number of samples given" end
        end
    end
end

-- For generators.
local function wrapMonoGenerator(genFunc)
    return function(state)
        return function(numSamples)
            local i, samples = 1, {}
            while i <= numSamples do
                f = genFunc(state)
                samples[2*i-1] = f
                samples[2*i]   = f
                i = i+1
            end
            return samples
        end
    end
end


local function duplicateKnobInfo(knobs)
    -- Copy knob definitions but without callbacks.
    local info = {}
    for k,v in pairs(knobs) do
        info[k] = {
            min     = v.min,
            max     = v.max,
            default = v.default,
            label   = v.label,
            options = v.options
        }
    end
    return info
end


function M.wrapMachineDefs(defs)
    local publicKnobInfo = duplicateKnobInfo(defs.knobs)

    -- Wrap the processing function to operate on a whole array.
    local wrapProcFunc, wrapGenFunc = nil, nil
    if defs.processOneSample then
        wrapProcFunc = wrapMonoEffect(defs.processOneSample)
    elseif defs.processSamplePair then
        wrapProcFunc = wrapStereoEffect(defs.processSamplePair)
    elseif defs.generateOneSample then
        wrapGenFunc = wrapMonoGenerator(defs.generateOneSample)
    else
        error("Unit `" .. defs.name .. "` has no processing function")
    end

    -- The following function creates a new instance of this machine.
    -- It's called via the prototype's .new() method.
    -- Note that it encloses defs and publicKnobInfo from above.
    -- If passed, options is a table containing some initial values.
    local function newUnit(options)
        local state = {public = {knobInfo = publicKnobInfo}}

        local proxy = {}
        local meta = {
            -- When values in the proxy table are looked up
            -- (either "knobInfo" or a knob's name),
            -- pull them from the unit's public state.
            __index = state.public,

            -- When values in the proxy table are assigned,
            -- check for a valid key, clamp to between min/max,
            -- and call the on-change callback.
            __newindex = function(proxy, key, newVal)
                local knobDef = defs.knobs[key]
                if not knobDef then
                    error("Attempt to set undefined knob: " .. key)
                end

                if knobDef.options then
                    -- Multiple choice knob (set of strings).
                    newVal = tostring(newVal)
                    if not findElement(knobDef.options, newVal) then
                        error("Knob `" .. key .. "` has no option `"
                              .. newVal .. "`")
                    end
                else
                    -- Numeric knob.
                    newVal = tonumber(newVal)
                    if newVal < knobDef.min then
                        newVal = knobDef.min
                    elseif newVal > knobDef.max then
                        newVal = knobDef.max
                    end
                end

                state.public[key] = newVal

                if knobDef.onChange then
                    knobDef.onChange(state, newVal)
                end
            end
        }
        setmetatable(proxy, meta)

        -- Expose the wrapped sample-processing function
        -- (enclosing private state).
        if (wrapProcFunc) then
            state.public.process = wrapProcFunc(state)
        else
            state.public.generate = wrapGenFunc(state)
        end

        -- Initialize all knobs, first stealthily (no onChange callbacks).
        -- If the knob was included in the `options` argument, that
        -- overrides the default.
        for k,v in pairs(proxy.knobInfo) do
            if v.min and (v.default < v.min or v.default > v.max) then
                error("Default for knob `" .. k .. "` is out of range")
            end
            if v.options and not findElement(v.options, v.default) then
                error("Default for knob `" .. k .. "` is not in options list")
            end
            local initVal = v.default
            if options and options[k] then
                if v.min and options[k] < v.min then
                    initVal = v.min
                elseif v.max and options[k] > v.max then
                    initVal = v.max
                elseif v.options then
                    if findElement(v.options, options[k]) then
                        initVal = options[k]
                    end
                else
                    initVal = options[k]
                end
            end
            state.public[k] = initVal  -- Direct, doesn't call callback
        end

        -- Now call each onChange method.
        -- This way, if the onChange method uses the state of a second knob,
        -- that second knob is guaranteed to be set already.
        for k,v in pairs(proxy.knobInfo) do
            if defs.knobs[k].onChange then
                defs.knobs[k].onChange(state, state.public[k])
            end
        end

        -- For convenience, save the name with the new object.
        state.public.name = defs.name

        -- Return the proxy object.
        -- The public interface is to use .knobInfo, .process, .name,
        -- and setting and getting [key] for keys in .knobInfo.
        return proxy
    end

    -- Public interface for prototype: .name, .knobInfo, .new
    return {name = defs.name, knobInfo = publicKnobInfo, new = newUnit}
end

return M
