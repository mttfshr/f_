# Variable frame rate / time-scale control — can breath or an oscillator drive the frame rate?

**Status:** idea only, not specced, not scheduled. Captured 2026-10-18 from a chat
question ("is it possible to have a free-running frame rate, e.g. for the breath control
idea, controlling the frame rate with breathing or something oscillating?"). The Max
facts below come from the Cycling '74 `jit.world` / `jit.pworld` reference pages and
forum threads; the Vsynth facts come from this repo's docs. **Nothing here has been tried
in Max or in Vsynth.**

## Short answer

Yes for going slower, no for going faster than the display, and "frame rate" hides two
different things worth keeping apart:

| | 1. Render rate | 2. Content time |
|---|---|---|
| What changes | how often the context draws | how far state advances per drawn frame |
| Upper limit | the display refresh, with vsync on | none in principle; solver stability |
| Looks like | stutter / stop-motion at low rates | smooth speed-up and slow-down at a steady frame rate |
| Mechanism | `jit.world` `fps` / `interval`, or the interval of the clock Vsynth uses | per-module time params (`dt`, rate, phase step); read-head rate for stored frames |
| Affects | everything at once | only modules that take a time param |

For breath, the second is the more natural fit and the first is a deliberate aesthetic.

## What Max allows (reference pages and forum, not tried here)

- On `jit.world`, `fps` and `interval` are one setting: setting either sets the other.
  `jit.pworld` documents that with sync on, the frame rate is clamped at the display
  refresh. A forum answer says the same thing from the other side: `sync` limits a rate
  that is too high, not one that is too low.
- So the render interval can be lengthened at runtime, and cannot beat the refresh while
  vsync is on. With vsync off the rate floats with load (and on a fixed-refresh display
  would tear; general knowledge, not checked here).
- A rate that is truly free-running on the display side needs a variable-refresh display.
  Whether Max or Vsynth can drive one on Matt's setup is unchecked, and a projector
  chain is probably fixed-rate anyway.
- Forum threads agree that `qmetro` fires on the GUI thread, so some timing jitter is
  expected, and that frame rate dips under load. Absolutely constant rate is not a thing
  to expect. Another thread has a performer choosing a lower rate on purpose for a
  stop-motion look, which supports the "low render rate as aesthetic" reading.

## What this repo says about the clock

- `vs_render` owns the render context, the `qmetro` and the fps
  (`docs/vsynth-reference/vocabulary.md`). `r draw` is the per-frame heartbeat of the
  whole system; `r vs_ntime` is a normalized global time that `vs_newTime` uses.
- State-holding modules advance **per draw, not per second.** `f_vf_fluid`'s `enc`
  stage is triggered by `r draw`; its `dt`, `drag` and the `drift` factor
  (`drift^(1/16)` per frame) are all per-step; `vs_bline` smoothing counts frames.
  Slowing the render rate therefore slows all of them together, and a 6-frame `vs_bline`
  ramp takes longer in wall-clock time.
- A per-step solver does not know about wall time, so a slower render rate should not
  destabilize `f_vf_fluid` (unverified). Going *faster* than the refresh would need
  sub-stepping inside a module; nothing in the docs read for this note suggests one
  has it.
- Cost is also per draw. `f_caustic` alone is ~21-23 ms/frame and the 59-60 fps seen in
  real patches is the vsync ceiling, so the real headroom is not measured.

## Breath (or any oscillator) mapped three ways

1. **Breath to render interval.** Everything breathes together; low rates read as
   stutter, which may be the point. Cost: the interface also updates slowly, and every
   frame-counted smoother stretches.
2. **Breath phase to read position.** With a frame store (`f_texture_sampler.md`) or
   `f_loop_to_cycle.md`, the tier-2 phase from `f_a_breath_phase.md` (0-1) can *be* the
   position in a loop, so a clip scrubs in lockstep with the lungs. A held breath freezes
   the picture. That is the open "does a hold freeze phase?" question in the breath note,
   answered by the mapping instead of by a design rule. Sub-frame positions need the
   lerp noted in the sampler and loop notes.
3. **Breath rate or envelope to a shared time scale.** A `time_scale` value (1 =
   nominal) read by modules that have a `dt`, rate or phase-step param, so generators and
   solvers speed up and slow down smoothly at a steady frame rate. This needs a
   convention; nothing like it exists in `f_` today.

An LFO or any other control source works in place of breath in all three. An oscillating
render interval is the odd one out: it gives a pulsing, heartbeat-like cadence.

## Cheap version available today: freeze a WFG, drive its phase (Matt, 2026-10-18)

Set a WFG's time / rate control to 0 and drive its phase from the breath signal. This is
mapping 2 applied to a generator that already exists, and the "breath directly drives
phase" mode of `f_a_breath_phase.md`. It needs no new infrastructure (the WFG's exact
control names are unchecked).

- **Why it works:** a WFG's output is a pure function of phase, so there is no
  accumulated state to disturb. Phase can jump, hold or reverse and the picture just
  follows. It is also the same trick `f_loop_to_cycle.md` wants for stored video loops.
- **One module at a time is a wiring limit, not a processing one.** One breath utility
  could publish its phase as a named message that several WFGs receive: N wires, not N
  copies of the breath chain. You still choose which modules breathe.
- **Reach:** only things that are functions of phase (WFGs, and stored loops once a frame
  store exists). Stateful modules (`f_vf_fluid`, `f_vf_advect`, the temporal filters)
  accumulate frame to frame and have no phase to drive. For those the breath would have
  to scale a `dt` / rate param (mapping 3) or the render clock (mapping 1).
- **Consequence for ordering:** this suggests doing the WFG route first, with the shared
  `time_scale` convention as a later step for the modules that integrate over time. The
  fork it leaves open is the one from the breath note: rate-averaged phase vs
  per-breath reset, and what a hold does (here a hold simply freezes the output).

## Design questions and hazards

- **Which clock:** all modules together (render rate) or per module (time scale). They
  can be combined, but they are different knobs with different failure modes.
- **Smoothing the control:** abrupt interval changes are visible. Smooth the *control*
  in wall-clock time (a Max-scheduler `line` / `slide` in ms), not with `vs_bline`,
  whose smoothing is frame-counted and so stretches exactly when the rate drops.
- **Temporal consumers change their wall-clock behavior** when the rate changes:
  `vs_filter_temp` attack/release, `f_tf_smooth` release, `f_vf_advect` decay. A camera
  or movie source at a fixed rate gets duplicated or skipped frames.
- **Audio does not slow down.** The `f_a_` side runs at audio rate; whether the breath
  should also drive anything there is separate.
- **Scope of the render clock:** it belongs to Vsynth's `vs_render`, not to any `f_`
  module. Driving it means reaching outside the library's usual bpatcher boundary.

## Possible utility (sketch, not a spec)

A small control-domain utility, no GPU: takes a control source (breath envelope, LFO,
MIDI CC) and outputs (a) an interval message toward the render clock and (b) a smoothed
`time_scale` for consumers. Whether (a) belongs in the library at all is open; (b) and
mapping 2 look the more `f_`-shaped.

## Open questions

- How does `vs_render` set fps / interval, and can it change live without side effects?
  Does `r draw` simply follow the new interval? (Expected, unverified.)
- Which modules have wall-clock-dependent behavior worth auditing, beyond those named
  above?
- Is a `time_scale` convention worth having, or is exposing `dt` / rate where it already
  exists enough? `f_vf_fluid`'s `dt` appears in its doc; whether it is an exposed Param
  is unchecked.
- Mapping direction and range (slow on exhale or on inhale?) and hold handling: taste
  questions that need the real signal.
- Do the lower render rates stay usable once a display refresh and a projector are in
  the loop?

## Cheapest first step

Read `vs_render` in the Vsynth package. Then, with a running chain (say `f_vf_fluid` into
`f_vf_advect`), send interval changes by hand while watching `jit.fpsgui` and the picture.
Separately, drive an existing time-like param from an LFO to hear/see mapping 3 with no
new objects. All of it is scratch-patch judgment work; a real `time_scale` param would be
the first thing worth a mirror and a bench test.

## Explicitly not decided / not in scope yet

No spec, plan, build or testing. No module name chosen. Not checked against Vsynth's
package source. No claim here about which of the three mappings is right.
