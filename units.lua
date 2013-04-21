local effects = {}

effects.amp = require "effects.amp"
effects.pan = require "effects.pan"
effects.delay = require "effects.delay"
effects.power = require "effects.power"
effects.filter = require "effects.filter"
effects.softsat = require "effects.softsat"
effects.stwidth = require "effects.stwidth"

local gens = {}

gens.osc = require "gens.osc"

return {effects = effects, gens = gens}
