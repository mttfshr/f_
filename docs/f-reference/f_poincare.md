# f_poincare

**Type:** Processor: one texture in, one texture out, at the render size. Single `jit.gl.pix` stage, float32.
**Status:** Built 2026-11-07. Mirror 21/21, GPU benches 9/9 (codebox) and 2/2 (module), live contract bench 2/2, live looks passed (Matt, 2026-11-06 and 2026-11-07); defaults and ranges confirmed by Matt 2026-11-07. Not yet through the stable preflight.

_Reference written 2026-11-07 from `src/f_poincare/` (definition and codebox), `.specify/f_poincare/{spec,tasks}.md` and `tests/modules/poincare/`._

---

## What it does

Tiles the input texture across the hyperbolic plane. Each output pixel is a point in the Poincare disk. It is folded by reflections in geodesic circles until it lands in a fixed fundamental domain of a regular **{p,q}** tiling (p-sided tiles, q meeting at each vertex), and the texture is sampled at that settled position. The tiles shrink toward the rim of the disk, the Escher *Circle Limit* look. Outside the unit disk the output is black.

Two folds, picked by **Mode**:

- **Whole**: the fundamental domain is the whole curved p-gon at the centre. The texture sits inside that tile and mirrored copies fill its neighbours.
- **Sliver**: the kaleidoscope. The domain is a thin (2, p, q) triangle, one 2p-th of the tile, so the look is more abstract.

A hyperbolic **camera** (Rot, Cam x, Cam y) moves the view through the tiling: Cam x / Cam y translate by a disk isometry, so steps look the same size at every depth, and Rot turns the view about the centre.

---

## Signal Flow

Inlet 0: texture plus the control messages. Outlet 1: texture.

```
inlet 0 -> routepass -> pix (first input)       r dim -> pix (render size: width, height)
control messages -> route -> attrui -> pix       bypass jsui -> `param bypass_gate` -> pix
```

One codebox does both folds and the camera; both folds are computed per pixel and `fold_mode` picks one (the cost is both). The camera runs first, then the fold loop (32 iterations), then one sample of the settled position. The output follows the render size (the Params `width`, `height`).

---

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `fold_mode` | Whole / Sliver | 0 / 1 | 0 | Which fold. Read as a threshold at 0.5 |
| `p_sides` | int | 3 - 10 | 4 | Sides of each tile. Live in both modes |
| `q_vertex` | int | 3 - 10 | 5 | Tiles meeting at each vertex |
| `tile_scale` | float | 0.05 - 1.0 | 0.26 | Extent of the texture in the disk: the settled position `z` samples at `z / (2 tile_scale) + 0.5` |
| `cam_x`, `cam_y` | float | -0.99 - 0.99 | 0 | Camera translation. A length past 0.99 is held at 0.99 |
| `rot` | float | -3.1416 - 3.1416 | 0 | View rotation in radians, applied before the translation |
| `bypass` | toggle | 0 / 1 | 0 | Passes inlet 0 through |

Not controls (codebox Params with fixed values): `iterations` 32, `rim_fade` 0.99, `width`, `height`, `bypass_gate`.

**External control messages** (on inlet 0): `fold_mode`, `p_sides`, `q_vertex`, `tile_scale`, `cam_x`, `cam_y`, `rot`. `bypass` is not a message: it comes from the toggle only.

---

## Behaviour and guards

- **Hyperbolic only.** A {p,q} tiling exists in the disk only if 1/p + 1/q < 1/2. `p_sides` is rounded and held to 3..10; a `q_vertex` below the smallest value that satisfies the inequality is raised to it (p 4 needs q 5 or more, p 3 needs 7, p 5 and 6 need 4, p 8 needs 3). The dial can sit anywhere; the frame shows the nearest valid tiling.
- **Whole mode and the order of circles.** Each fold tests the three circles nearest by angle and uses the lowest index that contains the point. That order is part of the look (the other order gives a different tile orientation) and three circles match the full p-circle chain on every pixel both settle, at all 56 pairs p, q in 3..10 (offline).
- **Crop, not warp.** In Whole mode the texture is cropped to the curved tile (not warped into it). At 0.26 the {4,5} tile shows cleanly with dark star gaps at its corners; the tile's vertex radius (0.4 at {4,5}) fills them.
- **The rim.** Points near the rim need unboundedly many folds and float32 rounding is worst there. Pixels not settled after 32 iterations go black, and a smooth fade to black runs from screen radius 0.99 to 1. Near the camera's clamp the fade starts earlier, by `0.04 (|a|/0.99)^2` (0.95 at 0.99), because float32 drifts from float64 sooner there (measured offline, worst at {3,7}).
- **Zero camera is the static tiling**, exactly (identical points in the offline mirror in both precisions; the GPU frame with explicit zeros equals the default frame).
- **Seams.** Points on a mirror circle are fixed by the inversion, so there are none (checked offline at 100,000 nearby pairs per case, and by eye).
- **Bypass** passes inlet 0 through exactly (contract bench).

---

## Notes

- Sampling is nearest-like in the folded space, so very small `tile_scale` values magnify the texture's pixels visibly. Feed a texture at or above the render size for sharp tiles.
- In Sliver mode the sample region is the wedge's corner, so try `tile_scale` 0.3 to 0.5.
- A pixel exactly on a mirror line of the group (for example the diagonal of a square frame at p 4) lands on an edge circle; both modes accept a final point within 1e-5 of the circle as settled so float64 and float32 agree.
- A vecfield-aware version (carry a piped-through vecfield through the fold) is parked: gate `P-uv-vecfield`. `f_apollonian` (paused) is the fractal sibling.

---

## References

The geometry is the standard right-triangle construction for regular tilings of the hyperbolic plane. With the tile's centre, an edge midpoint and a vertex as corners, `cosh(l) = cos(pi/q) / sin(pi/p)` gives the edge-circle distance and radius in closed form (derived and checked in development against two independent hyperbolic-trigonometry calculations; the module's scratch phase and tests are in `.specify/f_poincare/`). The fold itself is the usual reflect-until-inside loop for a Coxeter reflection group; the Poincare-disk isometry used by the camera is the Moebius map `z -> (z - a) / (1 - conj(a) z)`.

- Coxeter, H.S.M. (1957). "Crystal Symmetry and its Generalizations." Royal Society of Canada: the {p,q} tessellation notation.
- Kopczynski, Celinska-Kopczynska & Czyzowicz (HyperRogue project). "Conformal Models of the Hyperbolic Plane." https://www.roguetemple.com/z/hyper/papers/conformal.pdf (the note on numerical precision near the disk boundary; read for background, no code taken).
- Escher, M.C., *Circle Limit* woodcuts: the visual reference, not a source of code.

No code was taken from another implementation. The three-nearest-circles selection and the rim-fade shift are original to this module (offline derivations, `.specify/f_poincare/tasks.md` T005 and T032).
