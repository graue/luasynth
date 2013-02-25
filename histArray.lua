-- HistArray: an array that automatically forgets its history,
-- except for a fixed number of old values.
--
-- See spec/histArray_spec.lua for tests documenting how it works.

local M = {}

local function computeActualIndexFor(key, histSize)
    return ((key-1) % (histSize+1) + 1)
end

local function getAllElementsFrom(proxy, private)
    local results = {}
    local earliestIndex = private.latestIndex - private.histSize

    for i=earliestIndex,private.latestIndex do
        results[i] = private[computeActualIndexFor(i, private.histSize)]
    end
    return results
end

local function lookupKeyIn(proxy, private, key)
    if type(key) == 'number' then
        if math.floor(key) ~= key then
            error("attempt to access non-integer index in HistArray")
        end

        -- Check if index is valid
        if key > private.latestIndex then
            error("attempt to access too-new index in HistArray")
        elseif key < private.latestIndex - private.histSize then
            error("attempt to access too-old index in HistArray")
        end

        return private[computeActualIndexFor(key, private.histSize)]
    elseif key == 'histSize' then
        return private.histSize
    elseif key == 'all' then
        return private.all
    else
        error("attempt to access undefined HistArray key " .. tostring(key))
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

    local previousHighIndex = private.latestIndex

    private[computeActualIndexFor(key, private.histSize)] = newVal
    private.latestIndex = key

    -- Zero-fill if we advanced by more than one.
    local backFillTo = math.max(key - private.histSize, previousHighIndex + 1)
    for i=key-1,backFillTo,-1 do
        private[computeActualIndexFor(i, private.histSize)] = 0
    end
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
    private.all = function(proxy)
        return getAllElementsFrom(proxy, private)
    end

    -- Initialize array with zeroes.
    for v = 1, histSize+1 do private[v] = 0 end
    private.latestIndex = 0

    return proxy
end


return M
