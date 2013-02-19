# luasynth

The third incarnation of my audio framework
(first [synth](https://github.com/graue/synth),
then [truesynth](https://github.com/graue/truesynth),
now luasynth).

All generators and effects will be written with Lua
for its mix of safety, portability and speed.

Currently there's a demo driver app and you can run this:

    luajit main.lua amp -gain -20

The above command reads 32-bit float samples from stdin,
attenuates them by 20 decibels, and writes the result to stdout.

Unfortunately, vanilla Lua doesn't provide a way to do
binary IO, so LuaJIT is required for the driver (main.lua).
However, the effects themselves, such as amp.lua, will work
(albeit slower) in plain Lua.


## Tests

Luasynth uses [Busted](http://olivinelabs.com/busted/) for testing.
To run tests:

    busted spec
