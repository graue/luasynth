local wrap     = require "wrap"
local wrapDefs = wrap.wrapMachineDefs

describe("Unit definition wrapper", function()
    it("should error if no processing function is provided", function()
        local noProcessingUnit = {
            name = 'Bad Unit',
            knobs = {}
        }
        assert.has_error(function() wrapDefs(noProcessingUnit) end,
                         "Unit `Bad Unit` has no processing function")
    end)

    it("should correctly wrap a mono effect", function()
        local inverterDefs = {
            name = 'Inverter',
            knobs = {},
            processOneSample = function(state, sample) return -sample end
        }
        local inverterUnit = wrapDefs(inverterDefs).new()
        local samples  = {0,-0.5,-1,-5, 0.5, 1}
        local expected = {0, 0.5, 1, 5,-0.5,-1}
        inverterUnit.process(samples)
        assert.are.same(expected, samples)
    end)

    it("should correctly wrap a stereo effect", function()
        local swapperDefs = {
            name = 'Stereo Swapper',
            knobs = {},
            processSamplePair = function(state, l, r) return r, l end
        }
        local swapperUnit = wrapDefs(swapperDefs).new()
        local samples  = {0, 1,   0.25, 0.5,   -1,  0}
        local expected = {1, 0,   0.5,  0.25,   0, -1}
        swapperUnit.process(samples)
        assert.are.same(expected, samples)
    end)

    pending("test knob value clamping (max/min)", function() end)
    pending("test onChange callbacks", function() end)
end)
