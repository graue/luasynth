PLAN: Adapt Truesynth framework to use Lua-written generators and effects


## Array note

Based on the benchmarks on the LuaJIT FFI's image example (see LuaJIT's doc/ext_ffi.html), memory usage will probably be way too f'ing great using tables for sample arrays, and speed will be slow. In the example, the FFI gives a 35x improvement in memory usage and performs 20x faster.

What I may want to do is create an opaque object (provided by the host) that acts like a table, but provides a more efficient 32- (not 64-)bit float array. Send that to the Lua code.

In the JavaScript implementation, maybe use typed arrays or whatever the new speedy JS hotness is for that kind of thing. For the native implementations, use the LuaJIT FFI functions.

I'm not sure actually if the Lua code has to change to accommodate this. It seems not. In fact, as long as the Lua implementation uses functions that only processOneSample() at a time, obviously nothing will need to change because they never see arrays to begin with... but some effects will need internal arrays of their own, e.g. a delay line or reverb. So for that I think I need to provide an FFI- or JS-whatever-backed array object the Lua code can create.