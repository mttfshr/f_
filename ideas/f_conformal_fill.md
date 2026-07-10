# f_conformal_fill (working name)

_Status: Captured, not specced — genuinely new architectural category for this project_
_Last updated: 2026-07-09 — split out of `f_poincare` discussion, prompted by "Conformal Models of the Hyperbolic Plane" (roguetemple.com/z/hyper/papers/conformal.pdf, HyperRogue project)_

## Concept

Conformally map a hyperbolic (or other) tessellation onto an **arbitrary bitmap shape**, not just the closed-form disk/half-plane models `f_poincare` uses. The paper's own example: fitting a tessellation to a cat-silhouette boundary.

The method is a **numerical solve, not a closed-form formula**: treat the source shape's interior as a discrete grid, fix boundary conditions (two boundary points mapped to the model's two poles), and solve a large discrete-Laplace/harmonic linear system so every interior pixel gets a complex value satisfying the mean-of-neighbors (discrete harmonic) constraint. The paper's own performance numbers: ~5 minutes, single-threaded, for a ~1000px source shape on 2018-era hardware.

---

## Why this is not a mode of `f_poincare`

`f_poincare` (and every other module in `f_`) is a live, per-pixel, closed-form GPU computation — each pixel's output depends only on its own coordinate, trivially parallel, real-time. This method is structurally the opposite: every pixel's solved value depends on *all* pixels simultaneously (a global linear system), inherently non-parallel in its native form, and far too slow to run per-frame.

**Architecture implication**: this can't live as a `jit.gl.pix` codebox at all in the way every other `f_` module does. It would need to be:
- An **offline precompute step** (likely Python/numpy, solving the discrete harmonic system once per source shape) producing a lookup texture (the solved complex-value field, or equivalently a UV remap texture)
- A **thin GPU-side sampler module** at runtime that just reads the precomputed texture and applies the tessellation lookup — architecturally closer to `f_vf_fieldmap` (a processor consuming a precomputed/derived field) than to `f_poincare`'s live iterated-transform loop

This is a genuinely new module category for this project — everything else in `f_` is real-time end-to-end. Worth treating as its own build track (precompute tool + thin consumer module), not a spec/plan/tasks pass shaped like the rest of the library.

---

## Relationship to other patches

- `f_poincare` — shares the tessellation-group math (once solved, the same {p,q} generating-set logic applies within the solved coordinate field) but not the runtime architecture. Natural sequencing: build `f_poincare`'s live closed-form version first: reuse whatever generator-set/settle-loop code is proven there as the *tessellation* half of this module; the *novel* half is entirely the offline conformal solve and its texture hand-off.
- `f_vf_fieldmap` — closest architectural precedent in the library for "consume a precomputed field via texture, do live per-pixel work on top of it."

## Open questions (pre-spec, not yet worked)

- Precompute tooling: Python/numpy offline, output format (raw texture? cached `.jxf`?), and how a performer would supply/select a source shape live
- Whether the boundary-point pole selection (the two points mapped to ±∞) needs to be a user choice or can be automated from the shape's geometry
- Resolution/quality tradeoffs given the ~5 minute reference solve time — whether a lower-res solve + GPU upsampling is viable for practical shapes
- Whether this ever needs live animation (the paper's own use case is a static tessellated shape, not a moving one) — if it's static-per-shape, that's a very different performance context than everything else in `f_`, which is arguably fine but worth being explicit about
