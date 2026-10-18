# slab chain architecture (stub)

Status: RETIRED 2026-10-12 — no remaining justification (see Conclusion
in "Why this exists"). Kept as the decision record.

## Why this exists

Several ideas on the horizon were thought to need true multi-pass GPU
pipelines with ping-pong textures and per-pass uniforms — something a
*single* jit.gl.pix fused GenExpr kernel cannot do:

- ~~FFT-based Stable Fluids~~ (`ceyron_simulation_scripts_notes.md`) —
  **resolved without this track (2026-10-11 update).** Shipped as
  `f_vf_fluid` using the ordinary pix/GenExpr pattern: 8 chained
  `jit.gl.pix` objects (`pass`/`adv`/`fx`/`fy`/`spec`/`iy`/`ix`/`enc`),
  each its own single fused kernel, with `pass` supplying one-frame
  feedback state. No real GLSL, no `jit.gl.slab`/`pass`/`node`
  ping-pong anywhere in it (`docs/f-reference/f_vf_fluid.md`'s Signal
  Flow section). This weakens the premise above: chaining several pix
  objects *is* multi-pass, at least for this case — "cannot do
  multi-pass" should have read "cannot do multi-pass in one object."
- 2D Lattice Boltzmann D2Q9 (`ceyron_simulation_scripts_notes.md`) —
  **answered 2026-10-12: does NOT need this track.**
  `tests/records/spike_lbm_d2q9_architecture.py` ran the full D2Q9 pipeline in
  the chained-pix stage shape: streaming is a pure gather (directional
  texture samples, the `f_vf_streak` idiom), collision/equilibrium fuse
  into one local codebox, bounce-back is a mask-driven local swap, 9
  channels/cell pack into 3 RGBA planes on the same `pass` feedback
  idiom. Two real constraints recorded in the notes file (periodic +
  obstacle is unstable at omega ~ 1.97 — open channel boundaries are
  load-bearing for the vortex street; shedding is slow at performance
  resolutions), but neither is an architecture-track constraint.
- Kuramoto-Sivashinsky (`ceyron_simulation_scripts_notes.md`) —
  **answered 2026-10-12: does NOT need this track.**
  `tests/records/spike_ks_stability.py` measured real-space explicit FD at
  ~2000 substeps/frame (dead) and the spectral linear-exact +
  explicit-nonlinear scheme — `f_vf_fluid`'s exact stage shape —
  stable at one step per frame (dt ~ 0.076 vs the reference ETDRK's
  0.1), with one mandatory k=0 mean-zeroing per step. Buildable in
  the ordinary pix pattern.

**Conclusion (2026-10-12): with LBM and KS both confirmed to fit the
ordinary chained-pix-objects pattern, this track has no remaining
justification.** FFT fluids shipped without it; LBM and KS are now
proven not to need it. Keep this file as the record of why the track
was considered and retired; do not specced/build anything on it unless
a future idea surfaces that genuinely needs per-pass GLSL uniforms
beyond what chained `jit.gl.pix` objects provide.

## Core technical difference from f_ pix pattern

- pix/GenExpr: one fused kernel, one draw call, per frame.
- slab chain: N sequential fragment-shader passes per frame, each with
  its own uniforms, reading/writing ping-ponged textures via
  jit.gl.slab / jit.gl.pass / jit.gl.node chains.
- Real GLSL (not GenExpr) — none of the jit-gen-codebox skill's
  constraints (Param collisions, no vec2/frac/noise, etc.) apply here.
  A separate skill file would be needed for slab-chain conventions.

## Open questions (not decided)

- Does this live inside f_ proper, or as a separate experimental repo/
  namespace until it proves out?
- Does it need its own bpatcher archetype, or can it reuse dual/
  src_mode conventions loosely?
- Build tooling: build_patcher.py/definition.py assume the pix+codebox
  shape. A slab chain (pass count, ping-pong wiring, per-pass uniform
  sets) isn't representable in the current JSON schema at all — new
  generator, or hand-built like f_masonry/f_sirds/f_vf_advect/f_vf_seeds?
- Vsynth interop: how does a multi-pass slab module expose a single
  vecfield/texture outlet to the rest of the chain? Does temporal
  state (1-frame draw-order delay convention) still apply, or does
  the pass chain need its own delay handling?
- Performance ceiling: moot for FFT Stable Fluids now (shipped at ~2.5ms/
  frame via chained pix objects, no draw-call-count problem to solve).
  Still open for LBM if it turns out to need this track — worth a
  throwaway scratch-patch perf test before committing architecture time.

## Gate before promoting to spec

Do not promote this to .specify/f_name/{spec,plan,tasks}.md until:

1. Current gain/mix rollout is fully closed out (f_caustic, f_vf_streak
   verified in Max; f_vf_vorticity status confirmed).
2. There's a concrete first module target to design the architecture
   against — not architecture for its own sake. **No longer FFT Stable
   Fluids** (shipped as `f_vf_fluid` without this track, 2026-10-11) —
   the only remaining candidates are 2D LBM and possibly
   Kuramoto-Sivashinsky, and whether either genuinely needs this track
   rather than the chained-pix-objects pattern is itself unconfirmed.
3. A scratch-patch spike (outside f_/patchers proper) has confirmed
   jit.gl.slab / jit.gl.pass ping-pong actually behaves as expected
   in Max 9 — see "reference reading rule" / empirical-verification
   principle before trusting any of this on paper.
