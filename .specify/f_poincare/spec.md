# Spec: f_poincare

**Date**: 2026-11-06 (supersedes the 2026-07-09 Phase 0 spec; that spec is in git history)
**Status**: Draft, not yet reviewed by Matt
**Idea file**: `ideas/f_poincare.md`

---

## What this module does

A texture processor. Each output pixel is a point in the Poincaré disk. The point is folded
by reflections across geodesic circles until it lands in a fixed fundamental domain of a
hyperbolic {p,q} tiling, and the input texture is sampled at that settled position. The
result is the input tiled across the hyperbolic plane, shrinking toward the disk rim.

Outside the unit disk the output is empty (the disk is the domain of the geometry).

## Where this stands (basis for the draft)

Per `plan.md` (dated results, 2026-07-09, observed live by Matt in Max): composition logic,
branchless multi-candidate priority selection (including exact tangency), and a real {4,5}
tiling were confirmed in `poincare-p4q5-scratch.maxpat`. Not yet done: texture sampling,
live p/q, a second {p,q} pair, iteration-count tuning.

Observed offline by Claude, 2026-11-06 (NumPy, float64; not yet checked against Max):
both looks below render correctly at {4,5}, and a single nearest-circle shortcut for mode A
does **not** reproduce the 4-circle result (2.4% of pixels differ inside r<0.6).
Comparison script is not committed; `scratch/poincare_compare.png` shows the two looks.

## Modes

`mode` selects the look. Both share the geometry, the inversion, the camera, and the
texture mapping.

### Mode A: whole tile (Escher look)

Fundamental domain is the whole curved p-gon centered on the origin. Settling loop: each
iteration, test the point against the p edge-geodesic circles, pick the winner with the
branchless priority chain, invert once in the winner. The input texture shows in the central
cell, mirrored copies in neighbors, cells shrinking toward the rim.

- Fixed at **p = 4** for the first build (the confirmed chain). q live, q >= 5.
- Live p is an open item, not a promise (see Open questions).

### Mode B: sliver kaleidoscope

Fundamental domain is a (2,p,q) triangle (1/(2p) of the tile). Settling loop: reflect the
angle into [0, pi/p], then invert in the single edge circle on the +x axis if the point is
inside it; repeat. No priority chain.

- p and q both live (subject to 1/p + 1/q < 1/2).
- The texture shows only the triangle's corner of the sampled region; the look is abstract.

## Geometry (shared)

Closed form, worked from the right-angled triangle (center, edge midpoint, vertex) and
checked on paper in `plan.md` Phase 3 Step 3:

```
cosh(l) = cos(pi/q) / sin(pi/p)          valid iff 1/p + 1/q < 1/2
t       = sqrt((cosh(l) - 1) / (cosh(l) + 1))
d       = (t + 1/t) / 2                  edge-circle center distance from origin
rho     = (1/t - t) / 2                  edge-circle radius, r2 = rho^2
```

Check: d^2 - rho^2 = 1 (circle is orthogonal to the unit circle). `d` and `r2` are computed
in the codebox from live `p`, `q`; no hyperbolic functions are needed. The scratch patch's
hand-entered defaults ({4,5}: d = 2.0582, r2 = 3.2361) become test fixtures.

Inversion in circle (c, r2): `z -> c + (z - c) * r2 / |z - c|^2`, with the denominator
floored (the scratch patch uses 0.0001).

## Camera (in scope)

Before settling, apply a hyperbolic isometry to the input point: a rotation by `rot`, then
the disk translation `z -> (z - a) / (1 - conj(a) z)` with `a = (cam_x, cam_y)`, |a| clamped
below 1. This is "travel through the tiling" from the idea file. Zero camera must give the
static tiling bit-for-bit.

## Rim policy (in scope)

The loop runs a fixed iteration count. Points near the rim need unbounded depth and float32
precision is worst there (`ideas/f_poincare.md`, roguetemple reference). Pixels that have
not settled when the loop ends are faded toward black, not sampled. The iteration count is a
tuning item for the build (24 is the untested guess from the scratch patch).

## Texture mapping

Settled position `z` samples the input at `u = z / (2 * tile_scale) + 0.5`. Pixels whose
`u` falls outside [0,1] are dark. The tile is a curved shape, so the image is cropped to it
in mode A. Whether to warp the image into the tile instead is an open question.

## Parameters (draft names)

| Param | Meaning | Notes |
|---|---|---|
| `mode` | 0 = whole tile (A), 1 = sliver (B) | |
| `p` | polygon sides | A: fixed 4. B: live |
| `q` | polygons per vertex | live; must satisfy 1/p + 1/q < 1/2 |
| `tile_scale` | texture extent in settled-z space | |
| `cam_x`, `cam_y` | disk translation | clamped inside the disk |
| `rot` | rotation | |
| `iterations` | settle count | may be fixed rather than a param |

## Acceptance criteria

- Mode A at {4,5} reproduces the confirmed scratch result: square central cell, 4-fold
  symmetry, depth growing toward the rim.
- No visible seam between tiles in either mode (points on a mirror circle are fixed by the
  inversion, so this should hold; confirm by eye).
- Settled check (offline, float64 mirror in `tests/modules/f_poincare/`): after the loop,
  every settled point lies outside all edge circles (A) or inside the wedge and outside the
  edge circle (B).
- The float64 mirror and the GPU path agree away from the rim; the agreement threshold is
  stated up front and not loosened to make a failure pass (the old `debug_ok` passed only
  after 0.01 -> 0.3).
- A second {p,q} pair renders as a plausible tiling: {4,6} for mode A (p fixed at 4), and
  {5,4} and {3,7} for mode B.
- No NaN, no console errors, clean compile.
- Zero camera equals the static tiling.

## Out of scope

- The `N`-matrix accumulated-transform tracking and `debug_ok` from the scratch patch. They
  were built to diagnose `f_apollonian` and are not needed to sample a texture.
- Any change to `f_apollonian` (stays paused) or to `f_mobius`/`f_droste`.
- Arbitrary-shape conformal mapping (roguetemple method), vecfield-masked presentation
  regions, upper-half-plane model.
- Performance tuning beyond the iteration count.

## Open questions

1. **Live p in mode A.** The nearest-circle shortcut failed offline (inferred cause: points
   near a vertex sit inside a circle other than the nearest-by-angle one). Options: fix it,
   or size the chain for a maximum p.
2. **Texture in the tile.** Crop to the curved tile (current), or warp the image into it.
3. **Ports and archetype details.** Follow the processor pattern of the other texture
   processors; exact inlets/outlets are not specified here.
4. **Gate row.** `P-moebius-tiling` in `.specify/gates.md` names this module and is
   malformed (four cells in a five-column table). It needs rewording or splitting once
   Matt decides what it still holds.
5. **Scratch patches** (`~/Vsynth/patterns/poincare-p4q5-scratch.maxpat` and the others)
   are not in the repo and need to be brought in as the starting point.
