# slab chain architecture (stub)

Status: unspecced, unscheduled. Not touching plan.md.

## Why this exists

Several ideas on the horizon need true multi-pass GPU pipelines with
ping-pong textures and per-pass uniforms — something jit.gl.pix's single
fused GenExpr kernel cannot do:

- FFT-based Stable Fluids (ceyron_simulation_scripts_notes.md)
- 2D Lattice Boltzmann D2Q9 (ceyron_simulation_scripts_notes.md)
- Possibly Kuramoto-Sivashinsky, depending on stepping scheme

This is a candidate second architectural track alongside the existing
pix/GenExpr bpatcher pattern, not a replacement for it.

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
- Performance ceiling: FFT Stable Fluids is 2*log2(N) draw calls/frame
  minimum. Worth a throwaway scratch-patch perf test before committing
  architecture time.

## Gate before promoting to spec

Do not promote this to .specify/f_name/{spec,plan,tasks}.md until:

1. Current gain/mix rollout is fully closed out (f_caustic, f_vf_streak
   verified in Max; f_vf_vorticity status confirmed).
2. There's a concrete first module target (most likely FFT Stable
   Fluids per Ceyron notes) to design the architecture against —
   not architecture for its own sake.
3. A scratch-patch spike (outside f_/patchers proper) has confirmed
   jit.gl.slab / jit.gl.pass ping-pong actually behaves as expected
   in Max 9 — see "reference reading rule" / empirical-verification
   principle before trusting any of this on paper.
