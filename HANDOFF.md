# HANDOFF — f_ library

Last session: 2026-06-30 (scratch patch + research session — spec updated)

## f_magic_eye — spec updated, implementation blocked on infrastructure question

Full spec at `.specify/f_magic_eye/spec.md`.

**What we learned this session (scratch patch testing):**
- Single-pass `jit.gl.pix` is confirmed insufficient — not a tuning problem,
  a structural impossibility. Tested with multiple pattern sources (stipple,
  f_grain, noise) and depth sources (wfg shapes, triangle, concentric squares).
  Each pixel independently samples the pattern at a shifted coordinate with no
  reference to neighboring pixels → no consistent horizontal repeat structure
  → eye cannot fuse.
- Correct algorithm: GPU Gems Chapter 41 ("Real-Time Stereograms", Policarpo
  2004) — strip-based, multi-pass, intra-frame texture feedback. Frame divided
  into N vertical strips (8–24 typical). Strip 0 = pattern direct. Strip i =
  strip i-1's output sampled at `uv.x - strip_width + depth * depth_factor *
  strip_width`. Per-strip fragment math is trivial; the blocker is intra-frame
  render-to-texture feedback between strips.

**Current blocker — RESOLVED by research (2026-06-30):**
`jit.gl.node @capture 1 @layer N` is the correct intra-frame render-to-texture
mechanism. C74 staff confirmed (Cycling '74 forum, Rob Ramirez) that two nodes
at different `@layer` values share texture within the same frame, no delay.
User confirmed empirically "no frame delay." Architecture:
- N nodes at ascending layers, each `@capture 1`, each containing one `jit.gl.pix`
- Node 0 (layer 0): takes pattern texture, tiles it at strip width
- Node i (layer i): takes node i-1 captured texture + depth, applies GPU Gems
  displacement formula within its strip range, passes through elsewhere
- Final output = node N-1's captured texture

Constraint: `@capture` only works in automatic mode. Fine for always-on use.

**Remaining open question — for Kevin specifically:**
Does the Vsynth `vsynth` render context (wrapped by `vs_render`) support N
`jit.gl.node @capture 1 @layer N` children inside a bpatcher with guaranteed
intra-frame layer ordering? Documented for `jit.world`/`jit.gl.render`;
needs confirmation it holds for the Vsynth context specifically.

Also note: `/Users/matt/Vsynth/sirds.genjit` exists — single-pass genjit
approach that doesn't produce fusible results, but contains correct per-pixel
displacement math useful as reference for the per-strip codebox.

**Next step:** Build a minimal 2-strip scratch patch using `jit.gl.node
@capture 1` at layers 0 and 1, verify no-delay intra-frame texture handoff,
then scale to N strips once the mechanism is confirmed in Vsynth context.

**Scratch patch saved at:** `/Users/matt/Vsynth/patterns/magic_eye_scratch.maxpat`
(contains v2 single-pass codebox — useful as a starting point for the strip-0
fragment program once multi-pass infrastructure is resolved)

## Discussion session — soft-mod, grain, weave

No code touched this session — pure architecture/strategy discussion across
three threads. Captured here so next session starts with full context.

**f_vf_seeds soft-mod — tabled, not decided.** Explored feather (cheap,
single-sample vignette on local-UV boundary distance — this is what f_grain's
`softness` actually does, via `shape_t`/`soft_falloff`) vs. true blur
(multi-tap neighborhood sampling, real cost, softens internal shape detail
not just silhouette edge). Conclusion: which one (or both, on different axes)
reads as the "disproportionately expressive" hard↔soft control depends
entirely on the upstream shape tex content, and isn't resolvable by reasoning
alone — needs a scratch-patch comparison across several shape sources (soft
blob, hard geometric mark, detailed/textured shape, asymmetric shape) before
committing to a mechanism. Explicitly tabled, come back to it.

**f_grain extension — resolved, see "Captured but not scheduled" section
below.** Ruled out shape-tex inlet (too disruptive to grain's core voronoi
identity) and vecfield-driven displacement-steering (displace only offsets
the *background sample* under each grain, not grain position/orientation —
no real anchor for field-steering). Landed on: a plain mod-texture inlet
blended into `cell_size`, new `size_mod` depth param. Small, scoped, additive.
Full reasoning + integration point captured below — ready to build next time.

**f_weave — open, needs a scratch-patch A/B before deciding anything.**
Started from the HANDOFF item "extend shape-tex-inlet pattern to f_grain and
f_weave" — on inspection this doesn't transfer cleanly. f_weave's marks are
procedural line/hash geometry (`dist_to_line`/`dist_to_mark` smoothstep
gates), not item-based like f_vf_seeds; there's no per-mark local-UV frame to
sample a shape tex against. Building one from scratch would be a real
architecture port, not an extension.

Separately, Matt shared a screenshot: f_weave fed a video→optical-flow
vecfield on in1 produces dense, organic, scribble/hatching-like output that
tracks scene structure — visually strong, but Matt described it as feeling
"uncontrolled," specifically in **orientation response**, not (or not only)
density/spacing.

Root cause identified in the orientation block:
```
cs = base_cs + (-vy); sn = base_sn + vx;
mag = sqrt(cs*cs+sn*sn); cs/=mag; sn/=mag;
```
This is vector addition + renormalize, not angular blending. Two problems:
(1) field contribution depth is implicit and fixed (ratio of unit base vector
to ±0.5-range field vector), not an exposed/dialable param; (2) vector-add
renormalization isn't proportional to angular difference — response isn't
linear/predictable, and near-zero (flat/no-motion) field regions still get
normalized into *some* direction rather than falling back to base angle.

Two candidate fixes discussed, not chosen:
- **A — exposed depth param, same mechanism.** Scale field term before
  adding (`field_amount` param). Minimal change, inherits non-proportional
  response behavior.
- **B — true angular blend.** Compute field angle directly (atan2 or
  equivalent — verify availability/safety in GenExpr first), circular-
  interpolate with base angle, weighted by depth and optionally by field
  magnitude (so flat regions fall back to base automatically). More correct,
  bigger change to the block.

Matt was unsure which would actually feel better — correctly identified as
an empirical question, not a reasoning-from-the-couch one. **Next step:**
scratch patch with both mechanisms wired side-by-side/switchable, same
video→flow source as the screenshot, A/B live before committing to either.
Stopped here — session ended due to fatigue, explicitly flagged by Matt.

---

## Prior session — full summary

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

## Captured but not scheduled — f_grain

- **f_grain: size mod inlet.** Decided NOT to extend f_grain with a shape-tex
  inlet (too disruptive to its core voronoi mechanism) or a vecfield inlet
  for displacement-steering (on inspection, `displace` only offsets the
  *background sample* under each grain — `uv_d` → `sample(in1, uv_d)` — it
  does not move or orient grains; grain has no position/orientation concept
  to redirect, so "field-steered displacement" doesn't have a real anchor
  here). Instead: a plain mod-texture inlet (not vecfield-typed) sampled
  per-cell at `(best_gx, best_gy)`, blended into the existing `cell_size`
  computation:
  ```
  cell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);
  ```
  New mod sample blends in here (e.g. `mix(cell_size, mod_sample, mod_depth)`),
  with a new `size_mod`/depth param controlling blend amount. `size_var` and
  its existing hash-based variation stay untouched when nothing's connected —
  this is additive, not a replacement. Small, contained: one new inlet, one
  new param, one line of codebox touched. Deliberately scoped to avoid the
  rest of grain's mechanism (displacement, era/fade, luma gate, shape).

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
