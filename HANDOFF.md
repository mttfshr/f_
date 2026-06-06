# HANDOFF — f_ session 2026-06-05 (session 2)

## Status
E2E testing in progress. f_grain, f_masonry, f_stipple all audited and passing. f_stipple @type char fix uncommitted. Ready to continue with f_droste next session.

---

## What was done this session

### E2E testing — f_grain (complete)
- A-G all pass
- Fixed: @type char added, bypass_toggle.js crash risk removed
- era_clock / persistence naming clarified — both params now exist, persistence scales era_clock in parent patch
- definition.py created at .specify/f_grain/definition.py
- Generator mode (no input) works but at lower resolution — expected Vsynth behavior

### E2E testing — f_masonry (A-F complete, G deferred)
- A-F all pass
- Fixed: bypass_toggle.js crash risk removed (had param_connect + parameter_enable)
- Fixed: weave_pix → masonry_pix renamed throughout (20 occurrences + autopattr)
- Fixed: duplicate commented-out out1 line removed
- px_norm: attempted 1.0/dim.x fix — produced visible difference (softer output), reverted to 1.0/640.0. Context is 640x640 so values should be identical — cause unclear, left as-is
- definition.py deferred — open design questions around quantize/regularity/drift and mod matrix UI asymmetry
- Known issues documented in scratchpad: in1 texture has no effect (expected), mod matrix A-only structural params not visible in UI

### E2E testing — f_stipple (complete)
- A-G all pass
- Fixed: @type char added (UNCOMMITTED — in current file, not yet committed)
- bypass_toggle.js clean
- Does not produce output without incoming texture — dual-mode not implemented, deferred
- stipple → droste pairing discovered: beautiful emergent singularity behavior

### Key discoveries / ideas
- **droste singularity region** — fully understood. The shape is the innermost tile boundary in droste's log-polar tiling (s_sp=0 isocontour), distorted by twist. It's simultaneously a geometric tile edge (like hyperbolic tiling / Escher Circle Limit) and a sampling rate isocontour — the exact boundary where droste_samples_per_pixel = masonry_feature_frequency. Inside: aliasing. Outside: adequate sampling. Rotation-invariant because rotation shifts t uniformly leaving s_sp seams unchanged. Shape controlled only by zoom, arms, twist. Fully documented in ideas/droste_singularity.md.
- **f_raster** — new idea: resolution as expressive parameter. Downsample/upsample with controllable ratio and interpolation mode. Covers: pipeline utility (supersample hard-edge generators before UV transforms), deliberate pixelation aesthetic, mismatched-resolution compositing (risograph/screenprint look). Would push droste singularity boundary inward by raising Nyquist threshold. Documented in ideas/f_raster.md.
- **f_poincare design implication** — the droste singularity geometry is exactly what f_poincare works with explicitly. Design f_poincare around the tile boundary structure from the start rather than discovering it empirically.
- **masonry → droste aliasing** — fundamental mismatch explained: masonry's floor() discontinuities alias inside the singularity boundary. dFdx/dFdy not available in GenExpr. Finite difference approximation possible for direct output but not through UV warps. f_raster is the practical solution. All documented in scratchpad and droste_singularity.md.

---

## Next session
Continue e2e testing. Next patcher: **f_droste**.
- Commit f_stipple @type char fix first
- f_droste has no definition.py, no known issues beyond center pixelation on raster sources (accepted)
- After droste: f_lens, f_mobius, f_stereo, then color processors

## Loose threads
- px_norm in f_masonry: why did 1.0/dim.x produce different output if context is 640x640? Worth a scratch patch investigation someday
- dual-mode generator (no input) behavior: f_grain and f_stipple both deferred — same underlying issue
- f_masonry design: quantize/regularity/drift — are all three distinct enough? needs performance use to judge
- f_masonry mod matrix UI: A-only structural params not visually distinguished from A+B+C appearance params
