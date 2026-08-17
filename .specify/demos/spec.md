# Demo Patches — Spec

_Started 2026-07-19._

## Purpose

Planning-only doc; patches themselves live in `package/demos/`, not here.

Separate from `package/help/` (per-module `.maxhelp` reference, one
module in isolation, Max's native help system) and from scratch work in
`~/Vsynth/patterns/` (throwaway, not meant to persist or be presented).
Demos are a third category: durable, polished, multi-module (~4-6)
patches that teach a *concept* the library covers, using real modules
chained together as the vehicle. Dual purpose — Matt's own working
reference (scratch-file sprawl makes past work hard to relocate), and
show-off patches presentable to other people.

## Format

Full standalone `.maxpat` files, not bpatcher-in-fixed-frame like
`.maxhelp`. Freeform layout, real title/caption comment objects
explaining what's being shown, room for an A/B toggle or before/after
comparison where that clarifies the concept. Not bound by the
`f-helpfile` skill's layout conventions.

## Naming / location

`package/demos/demo_<concept>.maxpat`. `demo_` prefix keeps them visually
distinct from `package/patchers/` (the library itself) and
`package/help/` (per-module reference) in a file browser.

## Concept map (grouped by domain)

Not all demos need the full 4-6 module range — some concepts (e.g.
hyperbolic space) may be better served by a tighter, more focused patch
than a wide module tour. Module lists below are a starting point, subject
to revision once each demo is actually built.

### Space / geometry
- **`demo_vecfield_basics`** — what a vecfield *is*. One `f_vf_vortex`
  field feeding 3 consumers side-by-side (`f_vf_warp`, `f_caustic`,
  `f_vf_streak` or `f_vf_advect`) so the same field is visibly one shared
  thing driving different effects. Likely flagship demo — vecfield is an
  invisible intermediate texture, easy to stay abstract without a visual.
- **`demo_advection`** — accumulation over time. `f_vf_vortex` (or
  `f_vf_fieldmap`) -> `f_vf_advect`, A/B'd against the same field going
  straight to `f_vf_warp` (single-frame displacement, no accumulation) —
  makes the accumulates-vs-doesn't distinction visible rather than just
  read about.
- **`demo_hyperbolic_and_reparam_family`** — `f_poincare` (Poincaré disk
  model, closed-form {4,5} tiling) as the hyperbolic-space anchor, paired
  with `f_mobius` / `f_droste` / `f_stereo` as a family of different
  plane/sphere reparametrizations (complex-plane inversion, log-polar
  spiral, spherical projection) shown side by side so the *contrast*
  between approaches lands, not just each module read in isolation.

### Color
- **`demo_color_grading_pipeline`** — `f_channel_grader` ->
  `f_hue_processor`/`f_luma_processor` -> `f_tone_curve` as a real
  grading chain. Distinguishes *global* adjustment (channel lift/gamma/
  gain) from *selective* adjustment (hue-band, luma-band) — an actual
  workflow concept, not a module tour.

### Discrete / procedural generation
- **`demo_modulation_inlets`** — texture-driven parameters. `f_masonry`
  or `f_grain`'s A/B/C modulation inlets fed by `f_util_profile` or a
  simple generator, showing a param going from flat dial-value to
  spatially-varying. Genuinely non-obvious from a single helpfile.
- **`demo_discrete_generation`** — `f_masonry` (candidate-search
  grid+jitter+per-cell hash), `f_stipple` (hash-field dither/
  displacement), `f_grain` (stochastic per-grain voronoi-jitter field)
  side by side on the same underlying idea (per-cell randomness) with
  different math — contrast makes each module's specific approach
  legible.

### Lens / optical
- **`demo_lens_effects`** — `f_lens`'s aberration/distortion/
  transmission/ghost/halation/tilt-shift stages. Include as-is; note the
  known bypass bug (`f_lens` bypass only gates `lens_pix`, not
  `lens_halation`/tiltshift — see `docs/f-reference/f_lens.md` Loose
  Threads) directly in the demo patch as a comment rather than waiting
  for the fix, since it's a real current behavior a viewer would
  otherwise be confused by.

## Explicitly out of scope for now
- `demo_bypass_gain_mix` (the gain/mix_pct/bypass UI convention itself)
  — considered and set aside as too UI-trivia to warrant its own demo;
  may resurface as a short intro panel *within* another demo instead of
  its own file.
- Anything using paused/shelved/unverified modules (`f_apollonian`,
  `f_focus`, `f_vf_vorticity`, `f_poincare`'s Phase 3) beyond what's
  already confirmed working.

## Open questions
- Priority order across the 6 concepts — not yet decided.
- Whether to source content/layout from existing `~/Vsynth/patterns/`
  scratch work per-demo, or design each fresh — deferred, decide
  per-demo as we get to it rather than up front.
