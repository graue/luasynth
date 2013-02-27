-- Wrap a machine definition in an object factory.

local M = {}


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

    -- Wrap the processing function to operate on a whole array.
    local wrapProcFunc = nil
    if defs.processOneSample then
        wrapProcFunc = wrapMonoEffect(defs.processOneSample)
    elseif defs.processSamplePair then
        wrapProcFunc = wrapStereoEffect(defs.processSamplePair)
    else
        error("Unit `" .. defs.name .. "` has no processing function")
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

                if knobDef.options then
                    -- Multiple choice knob (set of strings).
                    newVal = tostring(newVal)
                    local found = false
                    for _,v in ipairs(knobDef.options) do
                        if v == newVal then
                            found = true
                            break
                        end
                    end
                    if not found then
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

                -- TODO: Is it worthwhile not calling onChange if the new
                -- value is the same as the old? Does this ever result in a
                -- worthwhile performance gain? Complications?
                if knobDef.onChange then
                    knobDef.onChange(state, newVal)
                end
            end
        }
        setmetatable(proxy, meta)

        -- Expose the wrapped sample-processing function
        -- (enclosing private state).
        state.public.process = wrapProcFunc(state)

        -- Initialize all knobs, first stealthily (no onChange callbacks).
        for k,v in pairs(proxy.knobInfo) do
            if v.min and (v.default < v.min or v.default > v.max) then
                error("Default for knob " .. k .. " is out of range")
            end
            state.public[k] = v.default  -- Direct, doesn't call callback
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
