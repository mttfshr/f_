# f_quasi — Shepard-zoom quasicrystal generator with gradient outlet (working name)

_Status: 🟢 SHIPPED 2026-10-26 as `f_quasi` (reference: `docs/f-reference/f_quasi.md`; specced 2026-10-23 as `.specify/f_quasi/spec.md`). Drafted from the
webgpgpu mining run (`webgpgpu-ideas-1`). The Relief and Slope-hue looks (modes 1 and 2 below) were NOT built: Phase 2 of its tasks._

**Corrections found when the spec read the source shaders (the spec is authoritative):** the zoom wrap is
approximate (weight about 1e-8 at `sigma` 0.5, a visible pop by `sigma` 1), so `envelope` needs a cap; the source
gradient omits the 2 pi B s factor; the source aspect handling is not isometric; the source banded look is
already part of the generator (Example_27). Relief and Slope-hue are Phase 2.

## Concept

A stateless, self-sufficient interference-pattern generator, plus three rendering
modes that all hang off one by-product of its inner loop.

**Generator** (`Example_27_quasizoom`, `Example_28`): sum of cosine plane waves over
NWAVE orientations (5) and NSCALE octaves (7). Each octave doubles the spatial
frequency and is weighted by a Gaussian in log2(scale). Animating the base scale
upward zooms forever without the pattern changing character, the visual analogue of a
Shepard tone: when the base scale advances one doubling, the envelope shifts exactly
one octave and the weight profile is invariant.

**Gradient by-product** (`Example_31`): the same loop can accumulate the exact
directional derivative (`gradient += -sin(phase) * ...`) at no extra sampling cost, so
the module can emit an analytic gradient vecfield with no finite-difference taps.
Everything below uses it.

**Rendering modes:**
1. *Relief shading*: a fake surface normal from (gradX, gradY, const) and one
   specular dot product against a light direction; hue can come from the gradient's
   angle. Dials: light direction, relief depth, hue mix, hue bias.
2. *Hue from the field's own slope* (`Example_28`): hue set by `atan` of the summed
   gradient plus a radial term, so colour follows slope and screen position and is
   continuously animatable. The closed-form RGB rotation in the example is not the
   point (GenExpr already has hue conversion); the hue source is.
3. *Triangle-wave contour banding* (`Example_33`): `abs(mod(p*k, 1)*2 - 1)` folds any
   scalar into crisp contour bands; a non-integer k gives moire-like band-density control.
   Small enough to be a shared scalar-to-scalar helper for `f_vf_potential`,
   `f_chladni` magnitude and this module, not a module of its own.

## What f_ has today

- `f_chladni`: modal figure, audio-driven, three outlets (luma, vecfield, scalar).
  Same generator family and the dual-outlet precedent, but fixed pattern, no zoom.
- `f_ks`: chaotic, no zoom coherence.
- `f_weave` draws isolines only through its own line geometry; `f_lens` has a
  surface-emboss displacement (worth a look for overlap with mode 1, which shades a
  field rather than displacing it).
- Nothing shades an analytic field as lit relief, colours by field slope, or has an
  endless-zoom generator.

## Proposed shape

- Signature: none -> texture + vecfield (analytic gradient).
- Dials: wave orientation and phase, zoom rate (base-scale drift), octave envelope
  width, band density; render mode (Plain, Relief, Slope hue, Banded) with its own
  dials. Optional scalar outlet for the potential.
- Stateless: no ping-pong, no sampling. Cost is about 35 cosine evaluations per pixel
  at the example's settings; fixed-count loops of this size compile fine (bench-verified
  in the skill).
- GenExpr has `exp` but no `exp2`; write the octave weight as `exp(x * ln 2)`.
- Easiest build of the eight themes.

## Tier-1 checks (closed form)

- Normalised sum is bounded in [-1, 1].
- Advancing the base scale by one doubling shifts the log-Gaussian envelope by exactly one
  octave (weight profile invariant).
- Gradient outlet equals a finite-difference gradient of the potential to tolerance.
- Slope hue equals `atan2(gy, gx)` plus bias; specular peaks where the gradient opposes
  the light direction in the XY plane.
- Triangle fold edges sit at `round(p*k)` isocontours.

## Risks and open questions

- `atan2` of a near-zero gradient is NaN-prone at flat regions; use the +1e-7 bias idiom
  from the skill.
- Aliasing of the high octaves at small scale and HD render size; limit the band or
  fade octaves near Nyquist.
- Loop budget if NWAVE x NSCALE grows well beyond the example's values.
- Relief mode overlaps in spirit with `f_lens` emboss: decide whether it lives here or
  as a generic "shade a scalar + gradient" stage.

## Related

`f_chladni`, `f_ks`, `f_vf_potential`, `f_weave`, vecfield consumers (`f_caustic`,
`f_vf_warp`, `f_vf_streak`).

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 42, 07, 08, 09. Verified by subagents
against the example files and the f_ inventory; the NWAVE/NSCALE values and the
log-Gaussian loop were checked by hand.
