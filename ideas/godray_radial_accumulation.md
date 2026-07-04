> **Author:** Claude, GPU Gems 3 research sweep (2026-07-03)
> **Status:** tabled — real finding, composition not a new module

# Radial "god ray" accumulation — from GPU Gems 3 Ch. 13 (Volumetric Light Scattering as a Post-Process)

Sparked by reading GPU Gems 3 Ch. 13 (Mitchell) against the `f_vf_glow`/
`f_vf_streak`/`f_vf_vortex` family.

## The chapter's technique

Crepuscular rays ("god rays") as a pure 2D post-process, no 3D scene
required, works on "any image source": for each pixel, step `NUM_SAMPLES`
times toward a fixed screen-space point (the light source), accumulating
`color += sample * weight * decay^i`, with `exposure`, `weight`, `decay`,
and `density` (sample-spacing) as tunable scalars. Single pass, no
render-to-texture, no CPU round-trip — architecturally trivial to port.

## Why this isn't a new module — it's a composition that already works

The mechanism is: **radial accumulation from a fixed point, with
exponential decay, sampling the source image's own brightness along the
path.** Strip out the "light source"/"atmosphere" framing and this is
structurally identical to what `f_vf_glow`/`f_vf_streak` already do —
accumulate samples along a direction with exponential falloff — except
the direction field is *radial from a point* instead of an arbitrary
vecfield.

`f_vf_vortex` already produces exactly this content: a single
fixed-point field with `convergence`/`curl`/`position` params. With
`curl = 0` and `convergence` set to pull outward (divergence), it's a
pure radial-from-a-point field — precisely the direction field Ch. 13's
technique needs. Feed that into `f_vf_streak` or `f_vf_glow` and the
god-ray effect should fall out of the existing signal chain with no new
code: `f_vf_vortex` (radial field) → `f_vf_streak`/`f_vf_glow`
(directional accumulation) → done.

This is the same category of finding as GPU Gems 2 Ch. 19's confirmation
against `f_vf_warp` (Sousa's refraction technique turned out to be
exactly what the module already did) — not a code gap, a **confirmation
that the vecfield-family architecture already generalizes to a case the
literature treats as a distinct technique.**

## What doesn't transfer

The chapter's screen-space occlusion machinery (Sections 13.5.1–13.5.3 —
pre-pass rendering occluders black, stencil-bit gating, contrast
reduction) exists to solve a 3D-scene problem: telling apart "this pixel
is dark because it's shadowed" from "this pixel is dark because the
source content is dark." `f_` has no 3D occluder geometry — the source
texture's own luma *is* the signal, same as `f_vf_streak`/`f_vf_glow`
already assume. Not a gap, just inapplicable.

## Open question, not yet tried

Whether this reads as a genuine "god ray" look through the existing
chain is untested — the chapter's dual-curve/decay tuning
(`ideas/glow_profile_and_afterimage.md` idea #1) might matter more here
than in `f_vf_glow`'s normal directional-streak use, since a radial
source concentrates all rays through one point and small profile changes
may read very differently at that convergence point. Also untested:
whether `f_vf_vortex`'s existing param set can produce a *clean* enough
pure-radial field (no residual curl/asymmetry) for the effect to read as
rays rather than a swirl.

## Cross-references

- `ideas/f_vf_glow.md` (if none exists — check), `ideas/glow_profile_and_afterimage.md`
- `ideas/f_vecfield.md` (f_vf_vortex family)
- `ideas/gpu_gems_research.md` — Vol 3 Ch. 13 entry
