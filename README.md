# luasynth

The third incarnation of my audio framework
(first [synth](https://github.com/graue/synth),
then [truesynth](https://github.com/graue/truesynth),
now luasynth).

All generators and effects will be written with Lua
for its mix of safety, portability and speed.

Currently there's a demo driver app and you can run this:

    lua main.lua amp -gain -20

But it doesn't actually do anything. Reading/writing floats
is seemingly not practical with pure Lua.
Maybe it could use [struct](http://www.inf.puc-rio.br/~roberto/struct/).
