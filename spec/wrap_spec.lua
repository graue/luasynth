local wrap     = require "util.wrap"
local wrapDefs = wrap.wrapMachineDefs

describe("Processing function wrapper", function()
    it("errors if no processing function is provided", function()
        local noProcessingUnit = {
            name = 'Bad Unit',
            knobs = {}
        }
        assert.has_error(function() wrapDefs(noProcessingUnit) end,
                         "Unit `Bad Unit` has no processing function")
    end)

    it("wraps mono effects", function()
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

    it("wraps mono generators", function()
        local squareWave = {1, 1, 1,-1,-1,-1}
        local squareWaverDefs = {
            name = 'SquareWaver',
            knobs = {},
            generateOneSample = function(state)
                if not state.n then state.n = 0 end
                state.n = state.n + 1
                return squareWave[1 + ((state.n-1) % #squareWave)]
            end
        }
        local squareWaverUnit = wrapDefs(squareWaverDefs).new()
        local samples  = squareWaverUnit.generate(8)
        local expected = { 1, 1, 1, 1, 1, 1,
                          -1,-1,-1,-1,-1,-1,
                           1, 1, 1, 1 }
        assert.are.same(expected, samples)
    end)

    it("wraps stereo effects", function()
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

    it("makes knob info publicly visible in the prototype", function()
        assert.are.equal(-90,         knobberProto.knobInfo.gain.min)
        assert.are.equal( 40,         knobberProto.knobInfo.gain.max)
        assert.are.equal(  3,         knobberProto.knobInfo.gain.default)
        assert.are.equal('Fake gain', knobberProto.knobInfo.gain.label)

        assert.are.same({'Square', 'Tri', 'Sine'},
                        knobberProto.knobInfo.oscType.options)
        assert.are.equal('Fake oscillator type',
                         knobberProto.knobInfo.oscType.label)
        assert.are.equal('Sine', knobberProto.knobInfo.oscType.default)
    end)

    it("sets default values for numeric and option knobs", function()
        local unit = knobberProto.new()
        assert.are.equal(3.0, unit.gain)
        assert.are.equal('Sine', unit.oscType)
    end)

    it("calls callbacks on init", function()
        local unit = knobberProto.new()
        assert.spy(gainChange).was.called_with(3.0)
        assert.spy(oscTypeChange).was.called_with('Sine')
    end)

    it("sets all defaults before calling callbacks", function()
        local unit = knobberProto.new()
        assert.spy(checkBothG ).was.called_with(3.0, 'Sine')
        assert.spy(checkBothOT).was.called_with(3.0, 'Sine')
    end)

    it("updates numeric knobs when set", function()
        local unit = knobberProto.new()
        unit.gain = -6.0
        assert.are.equal(-6.0, unit.gain)
    end)

    it("calls callbacks when numeric knobs are set", function()
        local unit = knobberProto.new()
        unit.gain = -6.0
        assert.spy(gainChange).was.called_with(-6.0)
    end)

    it("sets the new value before calling a callback", function()
        local unit = knobberProto.new()
        unit.gain = -6.0
        assert.spy(checkBothG).was.called_with(-6.0, 'Sine')
    end)

    it("clamps numeric knobs to within min/max", function()
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

    it("updates option knobs when set", function()
        local unit = knobberProto.new()
        unit.oscType = 'Tri'
        assert.are.equal('Tri', unit.oscType)
    end)

    it("calls callbacks when option knobs are set", function()
        local unit = knobberProto.new()
        unit.oscType = 'Tri'
        assert.spy(oscTypeChange).was.called_with('Tri')
    end)

    it("rejects option knob settings not in the list", function()
        local unit = knobberProto.new()
        assert.has_error(function() unit.oscType = 'Pentagon' end,
                         "Knob `oscType` has no option `Pentagon`")
        assert.are_not.equal('Pentagon', unit.oscType)
        assert.spy(oscTypeChange).was_not.called_with('Pentagon')
    end)

    it("sets initial knob values if you pass a table", function()
        local unit = knobberProto.new({oscType = 'Square', gain = -20})
        assert.are.equal('Square', unit.oscType)
        assert.spy(oscTypeChange).was.called_with('Square')
        assert.are.equal(-20, unit.gain)
        assert.spy(gainChange).was.called_with(-20)
    end)

    it("catches illegal default values for knobs", function()
        local bogusProto = wrapDefs{
            name = "Bogus Unit",
            knobs = {bogusNum = {
                min = 0, max = 10,
                default = -2,
                label = "Bogus numeric knob"
            }},
            processSamplePair = function(state, l, r) return l, r end
        }
        local secondBogusProto = wrapDefs{
            name = "Another Bogus Unit",
            knobs = {bogusOpt = {
                options = {'Blue', 'Green', 'Red'},
                default = 'Pink polka dots',
                label = "Bogus option knob"
            }},
            processSamplePair = function(state, l, r) return l, r end
        }
        assert.has_error(function() bogusProto.new() end,
                         "Default for knob `bogusNum` is out of range")
        assert.has_error(function() secondBogusProto.new() end,
                         "Default for knob `bogusOpt` is not in options list")
    end)
end)


describe("Sample rate handling in wrapper", function()
    local testUnitProto = wrapDefs{
        name = 'Inverter',
        knobs = {testKnob = {
            min = 0, max = 10,
            default = 5,
            label = "Test knob",
            onChange = function(state, newVal)
                -- Expose the sample rate that's set internally.
                state.public._detectedSampleRate = state.sampleRate
            end
        }},
        processOneSample = function(state, sample) return -sample end
    }

    it("defaults the sample rate to 44100", function()
        local testUnit = testUnitProto.new()
        assert.are.equal(44100, testUnit._detectedSampleRate)
    end)

    it("sets sample rate if you pass a table with 'sampleRate'", function()
        local testUnit = testUnitProto.new({sampleRate = 48000})
        assert.are.equal(48000, testUnit._detectedSampleRate)
    end)

    it("allows mixing 'sample_rate' with actual knob settings", function()
        local testUnit = testUnitProto.new({sampleRate = 22050, testKnob = 10})
        assert.are.equal(22050, testUnit._detectedSampleRate)
        assert.are.equal(10, testUnit.testKnob)
    end)
end)
