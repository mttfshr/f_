# f_poincare

_Status: Planned — not yet specced_
_Last updated: 2026-07-07 — see `ideas/f_apollonian.md` for a closely related idea revisited this session_

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

- `f_apollonian` (see `ideas/f_apollonian.md`) — separate idea file, real shared DNA: both are iterated-Möbius-transform tilings (a point repeatedly transformed by a generating set until it settles, then sampled/colored). Ford circles specifically are the circle-packing shadow of a hyperbolic tessellation by the modular group — not just an architectural analogy. Real divergence: {p,q} tessellation is space-filling (every point converges quickly to a fundamental domain), Apollonian gaskets have a genuine fractal residual boundary that never settles. Undecided whether these end up as one module (mode switch) or two siblings sharing a `.genexpr` helper library — see that file for reference-shader findings (fixed-boundary + one live final inversion as the clean way to animate region size without breaking tangency; half-plane-as-degenerate-boundary as prior art for the "arbitrary boundary" question below).
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

## Reference: numerical stability near the disk boundary (2026-07-09)

Matt found ["Conformal Models of the Hyperbolic Plane" (roguetemple.com/z/hyper/papers/conformal.pdf)](https://www.roguetemple.com/z/hyper/papers/conformal.pdf) (HyperRogue project). Directly relevant, not just adjacent — the paper's actual subject is conformal maps of H² including the Poincaré disk model itself, which is this module's stated end target.

Two concrete carryovers for when real {p,q} tiling work starts:

- **The paper's framing matches ADR-8's math.** It treats conformal projections of H² as functions into a subset of ℂ, and composes them as biholomorphic/anti-holomorphic complex functions — the same frame `f_apollonian`'s accumulated-Möbius-matrix tracking (plan.md ADR-8) already uses for circle inversion. The paper's note that one model can be obtained by composing another with a biholomorphic `f` is the same move as mapping canonical circles through an inverse accumulated transform. When this module reintroduces real circular-arc geodesics (per its "Relationship back to f_apollonian" path), ADR-8's composition/parity-tracking machinery is the direct starting point, not a new derivation.
- **Numerical instability near the boundary is a real, quantified concern, not speculation.** The paper measures conformal maps of H² losing precision as distance from origin grows — points get squeezed into a vanishingly small float neighborhood near the boundary (their example: `1 − 2.8×10⁻¹¹` at hyperbolic distance 25, right at double-precision's edge). This is the same failure family `f_poincare`/`f_apollonian`'s own scratch testing just found empirically this week (Möbius maps ill-conditioned near their pole, requiring a relaxed debug-mismatch threshold rather than assuming a logic bug) — the paper confirms it's inherent to the math, not a GenExpr- or project-specific artifact. Important asymmetry to remember: this project runs in GPU float32, meaningfully less precise than the paper's doubles, so the effect will bite harder and closer to the origin than the paper's own numbers suggest. Anything that pushes points near the disk boundary — deep tiling recursion, points near a geodesic's pole — should expect this, and any fixed debug-mismatch threshold likely needs to scale with depth/distance rather than being one constant.

**Not directly applicable yet**: the paper's core numerical method (discretely solving a boundary-value/Laplace problem to conformally map H² onto an arbitrary bitmap shape) is a different problem than this module's fixed-symmetry {p,q} tiling — no arbitrary-shape mapping is in scope here. Worth revisiting only if presentation-region work (see above) ever wants to conform the tiling to an arbitrary mask shape rather than just crop/gate it.

## Build sequence

After f_mobius is well-understood in performance. Spec should incorporate droste singularity geometry explicitly from the start. Vecfield masking requires f_vf_scalar (not yet built) — the two could be developed together.
