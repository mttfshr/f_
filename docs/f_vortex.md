# f_vortex

**Type:** Generator (f_vecfield producer)
**Status:** Complete

---

## What it does

Generates a single fixed-point vector field encoded as an f_vecfield texture — float32, RG = XY direction, 0.5 = zero vector. The field topology is continuously variable between sink, spiral sink, center (pure rotation), spiral source, and source via two independent params.

Output is intended for f_vecfield consumers. Also compatible with `vs_displacement` as a dumb two-channel texture.

---

## Signal Flow

```
in0 (bang + control) → params route to dials → vortex_pix
in1 (cx mod texture, optional)          → vs_inState → vortex_pix
in2 (cy mod texture, optional)          → vs_inState → vortex_pix
in3 (convergence mod texture, optional) → vs_inState → vortex_pix
in4 (curl mod texture, optional)        → vs_inState → vortex_pix

vortex_pix (@type float32) → out0
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `cx` | 0–1 | 0.5 | Fixed point X position |
| `cy` | 0–1 | 0.5 | Fixed point Y position |
| `convergence` | -1–1 | 0.5 | Inward pull. 0=none, >0=sink, <0=source |
| `curl` | -1–1 | 0.0 | Rotation. 0=none, >0=CCW, <0=CW |
| `falloff` | 0–10 | 2.0 | Exponential decay rate. 0=uniform field |
| `cx_amt` | 0–1 | 0.0 | cx modulation depth (inlet 1) |
| `cy_amt` | 0–1 | 0.0 | cy modulation depth (inlet 2) |
| `convergence_amt` | 0–1 | 0.0 | convergence modulation depth (inlet 3) |
| `curl_amt` | 0–1 | 0.0 | curl modulation depth (inlet 4) |
| `bypass` | 0/1 | 0 | Outputs neutral field (all 0.5) |

**Prefix:** `vortex` — **Object name:** `vortex_pix`

---

## Field Encoding

f_vecfield convention: `R = fx * 0.5 + 0.5`, `G = fy * 0.5 + 0.5`, `B = 0.5`, `A = 1.0`. Consumers decode via `(sample - 0.5) * 2.0`.

Modulation inlets decode the same way: `(sample.x - 0.5) * 2.0 * amt` added to the base param value. At vs_black (0.5), offset is zero regardless of amt.

---

## Field Topology Reference

| convergence | curl | Topology |
|---|---|---|
| > 0 | 0 | Sink |
| < 0 | 0 | Source |
| 0 | ≠ 0 | Center (pure rotation) |
| > 0 | ≠ 0 | Spiral sink |
| < 0 | ≠ 0 | Spiral source |

---

## Notes

- Off-screen fixed points (cx/cy outside 0–1 via modulation) are valid — field computes cleanly
- Falloff uses `exp(-r * falloff)` — always positive, no ring artifact
- See `docs/f_vecfield_type.md` for full type contract
