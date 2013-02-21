-- XXX: not fully implemented yet. See the tests in spec/

local M = {}

local function lookupKeyIn(proxy, private, key)
    -- XXX
    if type(key) == 'number' then
        -- blah blah blah
    elseif key == 'histSize' then
        return private.histSize
    else
        return 'whatever'
    end
end

local function setKeyIn(proxy, private, key, newVal)
    if type(key) ~= 'number' then
        error("attempt to set non-number in HistArray")
    end

    if math.floor(key) ~= key then
        error("attempt to set non-integer index in HistArray")
    end

    if key <= private.latestIndex then
        error("attempt to set old index in HistArray")
    end

    -- actually set it XXX
end

function M.new(histSize)
    if type(histSize) ~= 'number' or math.floor(histSize) ~= histSize then
        error("history size must be an integer")
    end
    if histSize < 1 then error("history size must be at least 1") end

    local private = {}
    local proxy = {}
    local meta = {
        __index = function(proxy, key)
            return lookupKeyIn(proxy, private, key)
        end,

        __newindex = function(proxy, key, newVal)
            setKeyIn(proxy, private, key, newVal)
        end
    }
    setmetatable(proxy, meta)

    private.histSize = histSize
    -- XXX: more initialization

    return proxy
end

return M
