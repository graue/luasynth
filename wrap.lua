-- Wrap a machine definition in an object factory.

local M = {}


-- Create a processing function for a mono effect,
-- based on the unit's internally defined processOneSample().
local function wrapMonoEffect(monoFunc, state)
    return function(samples)
        local i = 1
        while samples[i] do
            samples[i] = monoFunc(state, samples[i])
            i = i+1
        end
    end
end


-- Create a processing function for a stereo effect
-- based on processSamplePair().
local function wrapStereoEffect(stereoFunc, state)
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


function M.wrapMachineDefs(defs)
    -- Copy the knob definitions but without callbacks.
    local publicKnobInfo = {}
    for k,v in pairs(defs.knobs) do
        publicKnobInfo[k] = {
            min = defs.knobs[k].min,
            max = defs.knobs[k].max,
            default = defs.knobs[k].default,
            label = defs.knobs[k].label
        }
    end

    -- The following function creates a new instance of this machine.
    -- It's called via the prototype's .new() method.
    -- Note that it encloses defs and publicKnobInfo from above.
    local function newUnit()
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

                newVal = tonumber(newVal)
                if newVal < knobDef.min then
                    newVal = knobDef.min
                elseif newVal > knobDef.max then
                    newVal = knobDef.max
                end

                state.public[key] = newVal

                if knobDef.onChange then
                    knobDef.onChange(state, newVal)
                end
            end
        }
        setmetatable(proxy, meta)

        -- Process a whole array of samples by wrapping the unit's
        -- internally defined processing function.
        local wrapFunc = nil
        if defs.processOneSample then
            wrapFunc = wrapMonoEffect(defs.processOneSample, state)
        elseif defs.processSamplePair then
            wrapFunc = wrapStereoEffect(defs.processSamplePair, state)
        else
            error("Unit `" .. foobar .. "` has no processing function")
        end
        state.public.process = wrapFunc

        -- Initialize all knobs, making sure their onChange methods
        -- get called to initialize internal state as well.
        -- XXX: This is probably stupid. What if Knob A's onChange method
        -- expects the internal state corresponding to Knob B to already
        -- be set?
        for k,v in pairs(proxy.knobInfo) do
            proxy[k] = v.default
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
