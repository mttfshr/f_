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
| `strength` | 0–10 | 4.0 | Scales gradient magnitude into f_vecfield range. Calibrate to input contrast. |
| `scale` | 0.001–0.05 | 0.004 | Central difference neighbor distance (normalized UV). Low = fine structure; High = coarse/smooth. ~2px at 480p. |
| `bypass` | 0/1 | 0 | Outputs neutral field (all 0.5) |

**Prefix:** `fieldmap` — **Object name:** `fieldmap_pix`

---

## Field Computation

Luminance (Rec. 601: `0.299R + 0.587G + 0.114B`) sampled at 4 neighbors via central difference:

```
gx = luma(x + scale, y) - luma(x - scale, y)
gy = luma(x, y + scale) - luma(x, y - scale)
```

Scaled by `strength`, encoded to f_vecfield convention:
`R = clamp(gx * 0.5 + 0.5, 0, 1)`, `G = clamp(gy * 0.5 + 0.5, 0, 1)`, `B = 0.5`, `A = 1.0`.

Flat input regions produce exactly R = G = 0.5 (zero gradient, neutral field). Consumers decode via `(sample - 0.5) * 2.0`. See `docs/f_vecfield_type.md` for full type contract.

---

## Typical Use

```
jit.gl.bfg → f_vf_fieldmap → f_caustic
```

The fieldmap derives a vector field from the noise spatial structure. f_caustic accumulates streamlines along convergence zones in that field, producing bright bands along noise ridge lines.

---

## Calibration by Input Type

| Input | Strength | Scale | Character |
|---|---|---|---|
| simplex / Perlin | ~4.0 | 0.004 | Smooth lens-like caustic blobs |
| Voronoi smooth | ~4.0 | 0.004 | Sharp radial fan structures at cell centers |
| fractal.fbm | ~0.1 | 0.01–0.02 | Fine scattered caustic flecks; fbm gradient is high-contrast |

`strength` default (4.0) is calibrated for simplex/Perlin. High-contrast inputs like fractal.fbm need significantly lower strength to avoid saturation.

---

## Notes

- `scale` doubles as a spatial frequency selector: low scale tracks fine noise structure, high scale extracts coarse structure from high-frequency inputs
- No auto-normalization — gradient magnitude varies with input contrast; `strength` is the user calibration control
- No mod inlets in v1 — expressiveness comes from input source variety
- Compatible with `vs_displacement` as a dumb two-channel texture (treats RG as independent scalars)
- See `docs/f_vecfield_type.md` for full type contract and consumer conventions
