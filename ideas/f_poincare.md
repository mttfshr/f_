# f_poincare

_Status: Planned — not yet specced_
_Last updated: 2026-06-09_

## Concept

Poincaré disk model of hyperbolic geometry rendered as a UV-space processor. The Poincaré disk maps the entire hyperbolic plane into a unit disk — tiling is perfect and infinite, with no seams, because the boundary of the disk is at infinity. Dense kaleidoscopic patterns with infinite refinement toward the edge.

Escher's Circle Limit prints are the canonical visual reference. The circular screen is the natural display surface — the disk shape isn't incidental, it's the domain of the geometry.

---

## Architecture

Processor archetype — takes an input texture and applies hyperbolic tiling via UV transformation. The UV transform maps each output pixel back to a canonical fundamental domain of the hyperbolic tessellation, then samples the input texture there. The result is the input texture tiled across the Poincaré disk in hyperbolic space.

The Möbius transformations that tile hyperbolic space are closely related to f_stereo's stereographic math and f_mobius's UV transform — implementation will share DNA with both.

---

## Key design questions (pre-spec)

- **Tessellation type:** Which hyperbolic tessellation? The {p,q} notation (p-gon faces meeting q at each vertex) parameterizes the space. {4,5}, {5,4}, {3,7} are Escher's choices. Should this be a fixed choice, a discrete selector, or a continuous parameter?
- **Fundamental domain:** How is the input texture mapped onto the fundamental domain? Stretch to fill, preserve aspect ratio, tile internally?
- **Animation:** Möbius transformation parameters controlling "camera position" in hyperbolic space — analogous to droste's rotation param. The viewer can travel through the tiling.
- **Relationship to f_mobius:** f_mobius applies a single arbitrary Möbius transformation. f_poincare applies a group of them (the hyperbolic tessellation group). Is f_poincare a specialisation of f_mobius or a separate patch?
- **Singularity behavior:** The boundary of the disk is at infinity — behavior near the edge needs careful handling. The droste singularity notes apply here directly. See `ideas/droste_singularity.md`.

---

## Relationship to other patches

- `f_mobius` — shares Möbius transformation math; f_poincare is a group of Möbius transformations rather than a single one
- `f_stereo` — shares conformal map geometry; stereographic projection and hyperbolic tiling are both conformal
- `f_droste` — the singularity boundary behavior in droste is the same conformal compression phenomenon as Poincaré disk tile edges near the boundary
- `circular_screen.md` — the disk geometry of the Poincaré model is native to the circular screen

---

## Presentation region — disk is not a hard constraint

The Poincaré disk is a *model*, not a required output shape. The disk boundary (|z| = 1) is where hyperbolic space reaches infinity, but the UV transform works anywhere inside it. You can render any subregion — rectangular crop, off-center oval, arbitrary shape — and the hyperbolic geometry is still valid, just cropped. The tiling and Möbius symmetries are all present; you simply don't see the full boundary compression.

**Vecfield masking is the natural mechanism for dynamic presentation regions.** A vecfield-derived scalar mask (magnitude, divergence, curl — any geometric property of the field) can gate where the Poincaré tiling is visible:

```
f_vf_vortex → f_vf_scalar (divergence) → mask
f_poincare (source) → masked composite → output
```

The hyperbolic tiling appears only where the field has the right character — convergence zones, vortex centers, laminar regions. The visible region is animated and continuous, following field topology as it evolves. The disk boundary may not appear at all; what's visible is a dynamic window into the hyperbolic tiling determined by field geometry.

This also inverts cleanly: mask *out* the Poincaré region and show the field's own caustic or streak rendering elsewhere — two geometrically coherent systems occupying different frame regions, boundaries set by the field itself.

Note: the **upper half-plane model** is mathematically equivalent (convertible via Möbius transformation) but maps hyperbolic space to an infinite half-plane rather than a disk. Geodesics are semicircles on the real axis. More natural for rectangular/widescreen frames if that presentation ever becomes relevant.

---

## Build sequence

After f_mobius is well-understood in performance. Spec should incorporate droste singularity geometry explicitly from the start. Vecfield masking requires f_vf_scalar (not yet built) — the two could be developed together.
