# HANDOFF — f_ library

Last session: 2026-06-29

## What just happened — full session summary

### f_vf_seeds — shape-tex architecture (major revision) ✓

The original f_vf_seeds (internal smoothstep mark geometry, identity tex as
weight/marklen modulator) was superseded this session by a cleaner architecture:
external shape texture as the mark footprint, with f_vf_seeds reduced to a pure
placement/orientation engine.

**Architecture, current state:**
- Inlets: shape tex (in1), vecfield (in2), mod tex (in3). No source inlet —
  module is a generator (`archetype: source`), not a processor.
- Mark rendering: project pixel into seed-local (along, across) frame as before,
  but instead of computing geometry, normalize into a local UV and sample an
  external shape tex. Gate (hard clip) on UV bounds. No internal edge/profile
  logic at all.
- Outlets: mark color (out1, full RGB from shape tex), mark mask (out2, luma
  greyscale), seed coord (out3, RG seed UV per pixel).
- Passthrough convention: no shape connected → src_shape=0 → black output.
  No internal fallback shape; the module has no opinion about mark appearance.
- Shape tex canonical convention: square domain, mark centered, oriented
  rightward, any color/source (WFG, camera, gradient, jit.gl.pix generator —
  no dedicated shape-generator module family needed).

**Param simplification — `size` + `stretch` replaces `weight` + `marklen`:**
Independent per-axis scale params were fussy (dialing one threw off the other).
Replaced with a single `size` (overall scale) + `stretch` (aspect ratio) pair:
`marklen_eff = size_eff * (1+stretch)`, `weight_eff = size_eff / (1+stretch)`.
Reciprocal relationship keeps mark from collapsing/ballooning as stretch increases.

**Bipolar modulation depths:** `size_mod` and `stretch_mod` extended to -1..1
(from 0..1). Bipolar reads as substantially more expressive/alive than unipolar
for this kind of per-seed modulation — mod tex can grow or shrink the base value
around its set point rather than only adding.

**`softness` removed entirely.** Edge character now lives in the shape tex.
The footprint-boundary feather softness used to provide was a narrow effect
not worth a dedicated static dial — see "Near-term" below for a mod-tex-driven
revival of this idea.

**Both definition.py and codebox_seeds.gen synced to match current patcher.**
Findings captured in `docs/discrete_item_conventions.md`:
- size+stretch pattern (recommended for future discrete-item modules)
- bipolar modulation depths (recommended as new default)
- shape-tex-inlet architecture (full writeup, mechanics, consequences)
- open flag: cross-module `density`/`size` semantic audit needed (not started)

**Original mark-quality refinement goals (analytical AA, taper, aspect
correction) are now moot** — taper and shape moved upstream to the shape tex
entirely, so there's no internal geometry left to refine. This is a good
outcome but worth naming explicitly: those HANDOFF items are obsolete, not
completed.

**Session also involved real Max-plumbing debugging** — inlet/outlet index
vs. patching_rect x-position ordering bugs, stale shader cache after codebox
edits, route numinlets/outlets mismatches after param count changes. None of
this was architecture-related, but it ate significant time. Worth hardening
the build/edit workflow before doing this kind of patcher surgery again on
f_grain or f_weave.

**Status: shape-tex architecture proven and working. Proof of concept succeeded.**

---

## What's next — priority order

### 1. f_vf_seeds: per-seed softness/low-pass mod
Static `softness` dial was removed (see above) since a fixed footprint feather
wasn't worth a dial. But a **mod-tex-driven** version is a stronger case — same
mechanism as `size_mod`/`stretch_mod`, modulating edge feather per-seed via the
mod tex rather than a static value. Worth adding as a third bipolar mod depth
(`soft_mod`?) once the gate logic supports a feathered (smoothstep) boundary
again, parameterized per-seed instead of globally.

### 2. f_vf_seeds helpfile
Write `help/f_vf_seeds.maxhelp` following f_droste.maxhelp conventions.
Read `skills/f-helpfile/SKILL.md` first. Deferred from prior session pending
architecture stabilization — architecture is now stable, ready to write.

### 3. Discrete-item family: cross-module semantic audit
Flagged in `docs/discrete_item_conventions.md` (OPEN section at top): `density`
and `size` likely mean different things across f_grain/f_weave/f_masonry/
f_vf_seeds in ways that haven't been reconciled. Needs a deliberate side-by-side
pass before drawing conclusions.

### 4. Discrete-item family: extend shape-tex-inlet pattern
Candidate for f_grain and f_weave per the architecture validated in f_vf_seeds.
Own session each. Also reconsider size+stretch and bipolar-mod findings when
touching either module.

### 5. UI density pass
Section 1 (intrinsic character) / Section 2 (field response) layout for all
discrete-item modules. Blocked pending compound dial widget design.

---

## Captured but not scheduled — see ideas/

- **Breaking the grid entirely** (f_vf_seeds seed distribution): current 3x3
  neighborhood search assumes a roughly uniform grid with jitter. True
  non-grid placement (Poisson disk, density-field-driven scatter, or something
  else) is a different seed-distribution algorithm, not a parameter tweak.
  Captured as its own exploration in `ideas/` — see
  `ideas/seed_distribution_beyond_grid.md`.

---

## Known issues / loose threads

- f_masonry square output at non-square render dimensions — root cause unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- f_weave: mod inlets (identity tex + screen tex) — deferred
- f_grain: vecfield inlet — deferred
- `rename strength → amount` across modules — parked

---

## Module inventory (current)

**Generators:** f_masonry, f_chladni, f_stipple, f_grain, f_weave
**Processors:** f_droste, f_mobius, f_stereo, f_lens, f_caustic
**Color/Tone:** f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve
**Utilities:** f_texrouter, f_util_profile
**Vecfield:** f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, f_vf_warp,
  f_vf_streak, f_vf_advect, f_vf_glow, f_vf_repulse, f_vf_split, f_vf_chroma,
  f_vf_prism, f_vf_potential, f_vf_flow, f_vf_seeds
