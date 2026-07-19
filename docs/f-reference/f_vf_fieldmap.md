# f_vf_fieldmap

**Type:** Processor (f_vecfield producer)
**Status:** Complete

---

## What it does

Converts any scalar texture into an f_vecfield texture by computing the spatial gradient via central difference. Output encodes the gradient direction at each pixel as an f_vecfield — float32, RG = XY gradient direction, 0.5 = zero vector.

Primary use case: patch `jit.gl.bfg` (Perlin, simplex, Voronoi, fractal) into inlet 0 and get a coherent vector field out. Any scalar-dominant texture works — f_grain, f_stipple, luma from video, etc.

Processor archetype — requires input. Without a connected source, outputs neutral field (all 0.5).

---

## Signal Flow

```
in0 (source texture + control) → vs_inState → fieldmap_pix
  unmatched control → params route to dials → fieldmap_pix

fieldmap_pix (@type float32) → out0 (f_vecfield)
```

vs_black fallback when inlet 0 unconnected: neutral field (all 0.5, zero gradient).

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `gain` | -10–10 | 4.0 | Scales gradient magnitude into f_vecfield range. Negative inverts field direction. Renamed from `strength`. |
| `scale` | -0.05–0.05 | 0.004 | Central difference neighbor distance (normalized UV). Low = fine structure; High = coarse/smooth. ~2px at 480p. Negative inverts gradient axis. |
| `rotate` | -180–180 | 0.0 | Rotates the field vector in degrees, applied after gradient computation. |
| `thresh` | 0–1 | 0.0 | Suppresses the field (outputs neutral 0.5) below this center-pixel luma threshold. |
| `bypass` | 0/1 | 0 | Outputs neutral field (all 0.5) |

**Prefix:** `fieldmap` — **Object name:** `fieldmap_pix`

---

## Field Computation

UV is inset by `scale` before sampling (`suv = norm * (1 - 2*scale) + scale`) to keep all four neighbor samples within texture bounds. Luminance (Rec. 601: `0.299R + 0.587G + 0.114B`) sampled at center and 4 neighbors via central difference:

```
gx = (luma(suv.x + scale, suv.y) - luma(suv.x - scale, suv.y)) * gain
gy = (luma(suv.x, suv.y + scale) - luma(suv.x, suv.y - scale)) * gain
```

The gradient is then rotated by `rotate` degrees:

```
angle = rotate * pi / 180
gx' = gx*cos(angle) - gy*sin(angle)
gy' = gx*sin(angle) + gy*cos(angle)
```

Encoded to f_vecfield convention: `R = clamp(gx'*0.5+0.5, 0, 1)`, `G = clamp(gy'*0.5+0.5, 0, 1)`, `B = 0.5`, `A = 1.0` — then gated by `thresh`: pixels whose center luma is at or below `thresh` are replaced with the neutral field (0.5, 0.5, 0.5).

Flat input regions produce exactly R = G = 0.5 (zero gradient, neutral field). Consumers decode via `(sample - 0.5) * 2.0`. See `docs/f-reference/f_vecfield_type.md` for full type contract.

---

## Typical Use

```
jit.gl.bfg → f_vf_fieldmap → f_caustic
```

The fieldmap derives a vector field from the noise spatial structure. f_caustic accumulates streamlines along convergence zones in that field, producing bright bands along noise ridge lines.

---

## Calibration by Input Type

| Input | Gain | Scale | Character |
|---|---|---|---|
| simplex / Perlin | ~4.0 | 0.004 | Smooth lens-like caustic blobs |
| Voronoi smooth | ~4.0 | 0.004 | Sharp radial fan structures at cell centers |
| fractal.fbm | ~0.1 | 0.01–0.02 | Fine scattered caustic flecks; fbm gradient is high-contrast |

`gain` default (4.0) is calibrated for simplex/Perlin. High-contrast inputs like fractal.fbm need significantly lower gain to avoid saturation.

---

## Notes

- **2026-07-19:** `strength` renamed to `gain`; `rotate` and `thresh` params added (rotate the field vector post-gradient; suppress field below a luma threshold). Also fixed: neighbor sampling now insets UV by `scale` to stay within texture bounds, avoiding edge-sample artifacts present in the earlier version.
- `scale` doubles as a spatial frequency selector: low scale tracks fine noise structure, high scale extracts coarse structure from high-frequency inputs
- No auto-normalization — gradient magnitude varies with input contrast; `gain` is the user calibration control
- Compatible with `vs_displacement` as a dumb two-channel texture (treats RG as independent scalars)
- See `docs/f-reference/f_vecfield_type.md` for full type contract and consumer conventions
