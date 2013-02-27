local wrap     = require "util.wrap"
local wrapDefs = wrap.wrapMachineDefs

describe("Processing function wrapper", function()
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
end)


describe("Knob interface wrapper", function()
    local gainChange    = spy.new(function(newVal) end)
    local oscTypeChange = spy.new(function(newVal) end)
    local checkBothG    = spy.new(function(gain, oscType) end)
    local checkBothOT   = spy.new(function(gain, oscType) end)
    local knobberDefs = {
        name = 'Knobber Test',
        knobs = {
            gain = {
                min      = -90.0,
                max      =  40.0,
                default  =   3.0,
                label    = 'Fake gain',
                onChange = function(state, newVal)
                    gainChange(newVal)
                    checkBothG(state.public.gain, state.public.oscType)
                end
            },

            oscType = {
                options  = {'Square', 'Tri', 'Sine'},
                default  =  'Sine',
                label    =  'Fake oscillator type',
                onChange = function(state, newVal)
                    oscTypeChange(newVal)
                    checkBothOT(state.public.gain, state.public.oscType)
                end
            }
        },
        processSamplePair = function(state, l, r) return l, r end
    }
    local knobberProto = wrapDefs(knobberDefs)

    it("should set default values for numeric and option knobs", function()
        local unit = knobberProto.new()
        assert.are.equal(3.0, unit.gain)
        assert.are.equal('Sine', unit.oscType)
    end)

    it("should call callbacks on init", function()
        local unit = knobberProto.new()
        assert.spy(gainChange).was.called_with(3.0)
        assert.spy(oscTypeChange).was.called_with('Sine')
    end)

    it("should set all defaults before calling callbacks", function()
        local unit = knobberProto.new()
        assert.spy(checkBothG ).was.called_with(3.0, 'Sine')
        assert.spy(checkBothOT).was.called_with(3.0, 'Sine')
    end)

    it("should update numeric knobs when set", function()
        local unit = knobberProto.new()
        unit.gain = -6.0
        assert.are.equal(-6.0, unit.gain)
    end)

    it("should call callbacks when numeric knobs are set", function()
        local unit = knobberProto.new()
        unit.gain = -6.0
        assert.spy(gainChange).was.called_with(-6.0)
    end)

    it("sets the new value before calling a callback", function()
        local unit = knobberProto.new()
        unit.gain = -6.0
        assert.spy(checkBothG).was.called_with(-6.0, 'Sine')
    end)

    it("should clamp numeric knobs to within min/max", function()
        local unit = knobberProto.new()

        local tooLow = knobberDefs.knobs.gain.min - 10.0
        unit.gain = tooLow
        assert.are.equal(knobberDefs.knobs.gain.min, unit.gain)
        assert.spy(gainChange).was.called_with(knobberDefs.knobs.gain.min)

        local tooHigh = knobberDefs.knobs.gain.max + 0.01
        unit.gain = tooHigh
        assert.are.equal(knobberDefs.knobs.gain.max, unit.gain)
        assert.spy(gainChange).was.called_with(knobberDefs.knobs.gain.max)
    end)

    it("should update option knobs when set", function()
        local unit = knobberProto.new()
        unit.oscType = 'Tri'
        assert.are.equal('Tri', unit.oscType)
    end)
    it("should call callbacks when option knobs are set", function()
        local unit = knobberProto.new()
        unit.oscType = 'Tri'
        assert.spy(oscTypeChange).was.called_with('Tri')
    end)

    it("should reject option knob settings not in the list", function()
        local unit = knobberProto.new()
        assert.has_error(function() unit.oscType = 'Pentagon' end,
                         "Knob `oscType` has no option `Pentagon`")
        assert.are_not.equal('Pentagon', unit.oscType)
        assert.spy(oscTypeChange).was_not.called_with('Pentagon')
    end)
end)
