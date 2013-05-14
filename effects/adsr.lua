-- Adds an ADSR (Attack, Decay, Sustain, Release) envelope to the input

-- Convert from dB to voltage ratio,
-- e.g. dbToRatio(6) is about 2, dbToRatio(-3) is about 0.7
local function dbToRatio(db)
    return 10 ^ (db/20)
end

local defs = {name = 'ADSR', knobs = {}}

defs.knobs.attack = {
    min = 0.5, max = 10000.0, default = 10.0,
    label = 'Attack (ms)',
    onChange = function(state, newVal)
        state.attackSmps = newVal * state.sampleRate / 1000
    end
}

defs.knobs.decay = {
    min = 0.5, max = 10000.0, default = 1000.0,
    label = 'Decay (ms)',
    onChange = function(state, newVal)
        state.decaySmps = newVal * state.sampleRate / 1000
    end
}

defs.knobs.sustainLevel = {
    min = -40.0, max = 0.0, default = -9.0,
    label = 'Sustain level (dB)',
    onChange = function(state, newVal)
        state.sustainRatio = dbToRatio(newVal)
    end
}

defs.knobs.sustainLen = {
    min = 0.5, max = 10000.0, default = 2000.0,
    label = 'Sustain time (ms)',
    onChange = function(state, newVal)
        state.sustainSmps = newVal * state.sampleRate / 1000
    end
}

defs.knobs.release = {
    min = 0.5, max = 10000.0, default = 1000.0,
    label = 'Release (ms)',
    onChange = function(state, newVal)
        state.releaseSmps = newVal * state.sampleRate / 1000
    end
}

function defs.processSamplePair(state, left, right)
    if not state.n then state.n = 0 end
    local mul = 0
    local n = state.n
    if n <= state.attackSmps then
        mul = n / state.attackSmps  -- [0, 1]
    else
        n = n - state.attackSmps
        if n <= state.decaySmps then
            mul = 1 - (n / state.decaySmps * (1 - state.sustainRatio))
            -- [sustainRatio, 1]
        else
            n = n - state.decaySmps
            if n <= state.sustainSmps then
                mul = state.sustainRatio
            else
                n = n - state.sustainSmps
                if n <= state.releaseSmps then
                    mul = state.sustainRatio * (1 - (n / state.releaseSmps))
                    -- [0, sustainRatio]
                end
            end
        end
    end
    state.n = state.n + 1
    return left * mul, right * mul
end

return require("util.wrap").wrapMachineDefs(defs)
