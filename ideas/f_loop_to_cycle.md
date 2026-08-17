# Loop-to-cycle converter (working name) — looped video as a WFG-like phase signal

**Status:** idea only, not specced, not scheduled. Captured 2026-07-26
from a chat conversation, not yet cross-checked against Vsynth internals
in Max.

## Core idea

A WFG (waveform generator) at 60Hz completes one full cycle per second
of screen traversal — think of that cycle unrolled into frames: it's
functionally a loop. Run that logic backwards: can a looped video clip
be treated as if it *were* a saved WFG cycle? If so, the same phase-
domain operations already used on WFG cycles (phase modulation, phase
offset, frequency/speed scaling) should apply structurally to a video
loop's playback position — "phase" of a loop being read as "which frame
plays now," the same way phase of a WFG cycle reads as "where in the
waveform am I now."

Concretely: given a looped video clip of N frames, treat frame-index /
N as phase (0-1, wrapping). Anything that currently modulates a WFG's
phase (a vecfield, a scalar texture, another cycle) could instead
modulate which frame of the loop is sampled — phase modulation becomes
frame-offset modulation; frequency scaling becomes loop-speed scaling
(playback rate independent of phase-mod).

## Motivation / target use case

Named target: feed a video loop's per-frame phase into `f_masonry`'s
brick modulation, so each brick samples a different frame of the loop
based on its own local phase-mod input — bricks become tied to
different points in time in the same clip rather than only to a
spatial or noise-derived modulation source. More generally: this would
let any module that already accepts a WFG-style phase/scalar modulation
input use a video loop as an equally valid modulation source, without
needing a bespoke video-specific inlet type.

## Rough mechanism (untested, not architected)

- Source: a looped video clip, loaded via whatever Vsynth/Max convention
  already handles video playback (needs checking — likely
  `jit.movie`/`jit.qt.movie`-family or Vsynth's own clip-loading
  convention, not yet confirmed).
- "Phase" derivation: current frame index / total frame count, kept in
  [0,1) with wraparound — this is the loop's native cycle position.
- Phase modulation: an incoming mod texture/scalar offsets this phase
  value before it's used to select a frame (sample position), same
  operation shape as WFG phase-mod.
  - Whether this samples via `jit.gl.pix` texture-array indexing, or
  requires driving an actual playback-position message into a movie
  player object (seek-based, not sample-based), is the central open
  technical question — texture-based phase reads (arbitrary offset,
  smooth interpolation, GPU-resident) and playback-object seeking
  (likely per-frame discrete, CPU-driven, possibly with real seek
  latency) are architecturally very different and may not both be
  viable at interactive/live-performance rates.
- Frequency modulation: separate from phase-mod — scales loop playback
  rate (like WFG frequency), independent of any phase offset applied on
  top.

## Open questions

- **Feasibility of GPU-resident frame access.** Does Vsynth/Max expose
  a way to get all frames of a loop resident as an indexable texture
  (e.g. pre-baked into a texture array or atlas) versus only sequential
  movie-object playback with seek? This determines whether phase-mod
  can be a per-pixel `jit.gl.pix` operation (matching how WFG phase-mod
  already works) or is fundamentally a CPU-side, coarser-grained seek
  operation.
- **Frame count / memory ceiling.** A texture-array/atlas approach
  bounds loop length by GPU memory — what's a practical frame budget
  for a circular-screen live performance context?
- **Per-consumer sampling** (the `f_masonry` case specifically) implies
  potentially many simultaneous reads at different phase offsets in one
  frame (one per brick, or per group of bricks) — very different load
  profile than a single global phase read, worth scoping before
  assuming the same mechanism serves both a "single global playhead"
  use case and a "many simultaneous localized reads" use case.
- **Between-frame state under texture-driven phase-mod.** A WFG is
  continuous, so phase-mod always lands on a well-defined value — no
  such thing as "between" states. A video loop is discrete (integer
  frame indices), so a per-pixel phase-mod texture will constantly push
  individual pixels to non-integer frame positions (e.g. frame 3.4).
  What happens there is undefined so far: interpolate between frame 3
  and frame 4 (blend, cross-fade — cheap but may look like smear/ghost
  on fast motion), interlace/dither between neighboring frames
  per-pixel (avoids blending artifacts but introduces temporal noise),
  or just floor/round to the nearest integer frame (simplest, but
  reintroduces stepping and defeats the smooth-phase-mod premise this
  idea is chasing in the first place). Whichever is chosen also
  interacts with the GPU-resident-vs-seek question above — an indexable
  texture array makes interpolation cheap (two texture reads + lerp);
  a seek-based player likely can't do sub-frame interpolation at all.
- Relationship to existing modulation-texture work (`f_util_matrix_2`,
  vecfield family) — not yet reconciled. This idea produces a *video
  frame*, not a scalar or vecfield; how it hands off into
  `f_masonry`'s existing modulation inlet (whatever type that currently
  expects) needs checking against `f_masonry`'s actual definition.
- Naming: "loop-to-cycle converter" is descriptive, not proposed as a
  final module name.

## Explicitly not decided / not in scope yet

- No spec, no plan, no build. No scratch-patch testing done.
- Not yet confirmed against how Max/Vsynth actually handles video
  playback — this idea currently assumes a mechanism (indexable frame
  texture) without having verified it exists or is practical.
- Not yet connected to any specific `f_` module beyond the illustrative
  `f_masonry` target use case.
