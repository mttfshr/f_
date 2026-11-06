# f_vf_fieldmap

**Type:** Processor (f_vecfield producer)
**Status:** Complete

---

## What it does

Converts any scalar texture into an f_vecfield texture by computing the spatial gradient via central difference. Output encodes the gradient direction at each pixel as an f_vecfield — float32, RG = XY gradient direction, 0.5 = zero vector.

Primary use case: patch `jit.gl.bfg` (Perlin, simplex, Voronoi, fractal) into inlet 0 and get a coherent vector field out. Any scalar-dominant texture works — f_grain, f_stipple, luma from video, etc.

Processor archetype — requires input. There is no `vs_inState` or `vs_black` fallback and no `r draw`: the pix runs only when a texture arrives, so with nothing connected the module outputs nothing, and the output takes the input texture's size (read from the patcher; the behavior is inferred, not run).

---

## Signal Flow

```
in0 (source texture + control) → routepass jit_gl_texture jit_matrix
  jit_gl_texture → fieldmap_pix
  unmatched control → route gain scale rotate thresh → dials → fieldmap_pix

bypass jsui → prepend param bypass_gate → fieldmap_pix

fieldmap_pix (@type float32) → out0 (f_vecfield)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `gain` | -10–10 | 4.0 | Scales gradient magnitude into f_vecfield range. Negative inverts field direction. Renamed from `strength`. |
| `scale` | -0.05–0.05 | 0.004 | Central difference neighbor distance (normalized UV). Low = fine structure; High = coarse/smooth. ~2px at 480p. Negative inverts gradient axis. |
| `rotate` | -180–180 | 0.0 | Rotates the field vector in degrees, applied after gradient computation. |
| `thresh` | −2–2 | 0.0 | Suppresses the field (outputs neutral 0.5) below this center-pixel luma threshold. Luma is 0–1, so values below 0 never suppress and values above 1 suppress everywhere. |
| `bypass` | 0/1 | 0 | Panel toggle only: it drives the codebox Param `bypass_gate`, which mixes the output to the neutral field (0.5, 0.5, 0.5, 1). The route has no `bypass` selector, so a `bypass` message does nothing. Native `@bypass` is not used (migrated 2026-11-06). |

**Prefix:** `fieldmap` — **Object name:** `fieldmap_pix`

---

## Field Computation

UV is inset by `scale` before sampling (`suv = norm * (1 - 2*scale) + scale`) to keep all four neighbor samples within texture bounds. That holds for positive `scale` only: a negative `scale` pushes the samples outside 0–1, where they wrap (`G-edge-wrap`). Luminance (Rec. 601: `0.299R + 0.587G + 0.114B`) sampled at center and 4 neighbors via central difference:

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
- The inset also stretches the field against the source by up to ±`scale`. It matters only where the field must register with something else (`ideas/f_vf_glass.md`, NumPy only).
- At `rotate` 0 the field is a pure gradient: curl-free, flowing uphill across the contours. At 90 it runs along the contours and is divergence-free. `f_caustic` and `f_vf_warp` are fine with either, but `f_vf_fluid` at its default `project` 1 removes a gradient force (its mirror: pure-gradient force gives velocity ≈ 0), so use `rotate` near 90 there. NumPy estimate 2026-11-06, offline by Claude, not run in Max: under 1% of the force energy survives a divergence-free projection on smooth noise at `rotate` 0, about 12% on hard edges, and 50% at 45.
- Compatible with `vs_displacement` as a dumb two-channel texture (treats RG as independent scalars)
- See `docs/f-reference/f_vecfield_type.md` for full type contract and consumer conventions
