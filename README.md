# Luasynth

Luasynth is a small audio framework, written in Lua, emphasizing
clean, modular, declarative code. For a taste, read the source of its
panning effect (`effects/pan.lua`) or delay (`effects/delay.lua`).
Both are very short.

The plan: allow sound generators (oscillator, noise generator,
sampler...) and effects (gain, distortion, reverb, delay...) to be
written, chained together, and embedded in a host program. It's like a
miniature version of the VST or LV2 plugin interfaces.

Why use Lua? Unlike other high-level languages, it's extremely simple
to embed and [LuaJIT](http://luajit.org/) provides excellent
performance for this type of thing.


## Installing and using

By itself, Luasynth doesn't do very much. It only comes with a basic
demo app for generating or processing audio offline, via the command
line. To use that, install [LuaJIT](http://luajit.org/). You'll
probably also want [SoX](http://sox.sourceforge.net/) to convert into
and out of the raw, 32-bit, floating-point audio format Luasynth uses.

Here's an example:

    sox input.wav -tf32 -c2 -r44100 -q - \
     | ./luasynth delay -len 83 -feedback 90 \
     | ./luasynth amp -gain -6 \
     | sox -tf32 -c2 -r44100 -q - -b16 delayed.wav

This adds a delay to `input.wav`, reduces the volume by 6 dB, and
writes the output to `delayed.wav`. The `-tf32 -c2 -r44100` options to
SoX tell it to handle the format Luasynth uses, while `-b16` converts
the output file back to 16-bit, the resolution of CD-quality audio.

In this example, we're using `luasynth` twice. The first usage

    ./luasynth delay -len 83 -feedback 90

creates a `delay` unit with the `len` knob (length of time to
delay) set to 83 milliseconds and `feedback` (amount of feedback) set
to 90%. The second usage

    ./luasynth amp -gain -6

creates an `amp` unit and sets the `gain` knob, which is in
decibels, to -6. For a full list of available units, run `./luasynth
help units`, and for help on an individual one, run `./luasynth help
<unit name>`.

The sample rate is assumed to be 44100 Hz by default, but can be
changed by setting the environment variable `RATE`. For example, to
work at 48KHz, type `export RATE=48000` in the shell followed by
similar commands to those above.


## Embedding

[Moon-Noise](https://github.com/graue/moon-noise), a random noise
generator, provides a small example of embedding Luasynth (in another
Lua program in this case). You can also embed Luasynth in a C
application using Lua's C API.

Luasynth's command-line driver (main.lua, which you're calling if you
run `./luasynth` as above) requires LuaJIT for binary I/O to work.
However, the audio units themselves will run (albeit slower) in
regular Lua.

There's no complete documentation of the API yet, sorry, but it's very
simple, and the tests in `spec/wrap_spec.lua` do describe how most of
it works.


## Tests

Luasynth uses [Busted](http://olivinelabs.com/busted/) for testing.
To run tests:

    busted spec

The specs cover most, if not all, of Luasynth's API, including
graceful error handling in case the API is misused. Audio units
themselves are not currently tested. I'm not aware of an easy way to
test that, for example, a sine-wave generator or lowpass filter is
working as expected, but I'm open to suggestions.


## History and design

Luasynth is an evolution of similar concepts that I explored in two
past projects, both written in C:
[Synth](https://github.com/graue/synth) and
[Truesynth](https://github.com/graue/truesynth).

I started writing "Synth" way back in 2005. At the time, I was using
OpenBSD as my home operating system, which I admit is a pretty unusual
choice. There was next to no audio software available for OpenBSD, and
I wanted to create a little toolbox for the basic stuff.

In Synth, all audio units are command-line programs, piped together to
generate or process sound, like this:

    square -freq 1000 -len 5000 \
     | filter -type bandpass -center 2000 -q 10 \
     | pan -angle -20 \
     | fmt -16 \
     | <some command to play or save the audio>

Luasynth comes with a command-line driver app that can be used
similarly:

    ./luasynth osc -oscType square -freq 1000 -length 5 \
     | ./luasynth filter -filtType Bandpass -center 2000 -q 10 \
     | ./luasynth pan -angle 20 \
     | <command to convert, play or save... "fmt" is not included>

Both pipelines generate 5 seconds of a square wave, bandpass filter
it, and pan it about halfway to the right.

But Truesynth and Luasynth are both embeddable. Audio units do not
parse command-line arguments or handle file I/O directly. Instead,
they define parameters ("knobs" in Luasynth) that the host application
can set, and methods the host application can call to process or
generate audio. The command-line interface is therefore just one
possible host application.

From 2009 to 2010, while a member of the experimental noise band
[Extremities](http://extremitiesnoise.bandcamp.com/), I used Truesynth
as part of my rig to improvise and play live shows. The host
application created a software feedback loop which passed through
several Truesynth effects, whose parameters were controlled by the
orientation, rotation and button state of a joystick.

Luasynth refines the concept by using Lua as the implementation
language instead of C. Compare a [delay effect in
Truesynth](https://github.com/graue/truesynth/blob/master/effects/delay.c)
(C) to [the same effect in
Luasynth](https://github.com/graue/luasynth/blob/master/effects/delay.lua).
The C version is fragile, contains repetitive boilerplate code and is
written in terms of memory allocation, pointers and buffers. In
contrast, the Lua code is simple and elegant, closely resembling a
mathematical description of what the effect does. It also has the
potential to one day run in web browsers, using [compilation to
JavaScript](https://github.com/mherkender/lua.js) and the Web Audio
API.

Luasynth was one of my projects while attending the Winter 2013 batch
of [Hacker School](https://www.hackerschool.com/). Hacker School is
awesome.
