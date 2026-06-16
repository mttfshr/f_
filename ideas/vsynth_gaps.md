# Vsynth Capability Gaps — Strategic Analysis

_Last updated: 2026-06-09_
_Original: 2026-05-31. Cross-references: `ideas/f_util_analysis.md`, `ideas/f_cymascope.md`_

## Four genuine gaps

### Gap 1: Texture analysis → control signals ✅ Partially filled

`f_util_profile` establishes the GPU→CPU readback pattern. The analysis family (`f_util_envelope`, centroid, variance, motion energy) is named and prioritised in `ideas/f_util_analysis.md`. `f_util_audio_spectra` covers the audio→control side. Infrastructure is in place; remaining utilities need specific integration targets to motivate them.

### Gap 2: Temporal synthesis

Vsynth handles temporal state via feedback and frame delay. It has nothing that *synthesizes* motion across frames from a mathematical description — wave propagation, reaction-diffusion (vs_chemical_osc is one specific system), cellular automata.

- `f_cymascope` — FDTD wave propagation; establishes the ping-pong texture pattern in f_. See `ideas/f_cymascope.md`.
- Reaction-diffusion variants, cellular automata — further out.

**Priority: high.** f_cymascope is the natural first move after f_vf_chladni.

### Gap 3: Geometric generators with non-rectilinear structure ✅ Substantially filled

f_ has filled this aggressively: f_masonry, f_stipple, f_grain, f_chladni, f_weave (planned). Remaining territory:

- Non-Euclidean geometry (f_poincare — hyperbolic tiling). Möbius math is already in f_; hyperbolic tiling is the next step.
- Aperiodic tiling (Penrose, Wang tiles) — no Vsynth equivalent; high complexity, no spec yet.
- Apollonian gasket — interesting, not yet developed.

**Priority: medium.** f_ is already strong here; new additions should be aesthetically motivated.

### Gap 4: Coordinate space transforms ✅ Substantially filled

f_ has substantially extended Vsynth: f_droste (log-polar), f_mobius (Möbius), f_lens (optical distortion), f_stereo (stereographic). Remaining:

- Poincaré disk / hyperbolic space — overlaps Gap 3.
- Projective transforms (homography) — no clear aesthetic motivation yet.

**Priority: low.** New additions should be driven by specific aesthetic goals.

---

## What is NOT worth pursuing

- Compositing, color processing, keying, mixing — Vsynth has these comprehensively.
- WFG variants — the WFG family is extensive; f_ additions would be redundant.
- Basic displacement/offset — `vs_displacement` covers this well. Structured displacement *field generators* (f_vf_ family) are the interesting f_ contribution — not more processors.
