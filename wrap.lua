-- Wrap a machine definition in an object factory.

local M = {}

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

    local function newUnit()
        local state = {public = {knobInfo = publicKnobInfo}}

        local proxy = {}
        local meta = {
            __index = state.public,
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

        state.public.process = function(self, samples)
            local i = 1
            while samples[i] do
                samples[i] = defs.processOneSample(state, samples[i])
                i = i+1
            end
        end

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
        -- The public interface is to use .knobInfo, :process, .name,
        -- and setting and getting [key] for keys in .knobInfo.
        return proxy
    end

    -- Public interface for prototype: .name, .knobInfo, .new
    return {name = defs.name, knobInfo = publicKnobInfo, new = newUnit}
end

return M
