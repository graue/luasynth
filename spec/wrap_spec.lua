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
end)
