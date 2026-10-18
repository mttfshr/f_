# f_tf_tensormap

**Type:** Processor (f_tensor producer)
**Status:** Built 2026-10-16; mirror and bench tests green, live-checked on noise. Helpfile pending.

---

## What it does

Derives a **structure tensor** from any scalar-dominant texture: at each pixel, a 2x2 symmetric matrix describing the local gradient orientation, how strong it is, and how one-directional it is. It is the tensor-field family's analog of `f_vf_fieldmap`: same input shape (noise, luma, f_grain, f_stipple...), but where a vecfield stores one signed direction per pixel, the tensor stores an *unoriented line* plus a confidence.

Two outlets from one computed pass:

- **Outlet 0, raw tensor.** Lossless Jxx, Jxy, Jyy. Nothing consumes it today; it is for a future glyph/stress renderer.
- **Outlet 1, packed.** The convenience form: axis direction (angle-doubled), trace and coherence in one RGBA texture.

Neither outlet is an `f_vecfield`. See `docs/f-reference/f_tensor_type.md` for the encoding contract, and **`f_tf_axisflow`** to turn outlet 1 into a vecfield for consumers like `f_vf_advect`.

Processor archetype, requires input. Without a connected source both outlets are the zero-tensor neutral.

---

## Signal Flow

```
in0 -> stage A  luma (Rec. 601) -> 3x3 Sobel -> gx*gx, gx*gy, gy*gy
    -> stage B_h  horizontal box smooth (bounded loop, R_MAX 16)
    -> stage B_v  vertical box smooth
    -> stage C    trace, closed-form eigen, theta, coherence -> both outlets
```

Stateless (no previous-frame pass). Internal textures are unbounded float32; only stage C's encoded outputs leave the module.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `strength` | 1-1000 (log) | 100 | Gain on trace and the raw tensor terms before clamping. Not applied to coherence. See calibration. |
| `radius` | 0-16 | 3 | Smoothing radius in pixels (box). 0 = no smoothing. |
| `width` | 64-8192 | 640 | Render width in pixels. **Set to your real frame width.** |
| `height` | 64-8192 | 480 | Render height in pixels. **Set to your real frame height.** |
| `bypass` | 0/1 | 0 | Zero-tensor neutral on both outlets. |

**Prefix:** `tensormap` - **Object name:** `tensormap_pix` - **Type:** `@type float32`

`width`/`height` exist because `dim` reads 1 inside a live `jit.gl.pix`, so the module cannot read its own render size. They set the one-pixel tap step; left at the defaults on a different frame size, `radius` stops meaning pixels and the smoothing is anisotropic by the aspect ratio. They are exposed for now.

**`radius` cost does not scale with the dial.** The loop runs to a fixed maximum of 16 taps and weights unused taps to zero, so turning `radius` down does not buy back frame time.

---

## Outlets

| Outlet | R | G | B | A |
|---|---|---|---|---|
| 0 raw tensor | Jxx * strength | Jxy * strength * 0.5 + 0.5 | Jyy * strength | 1 |
| 1 packed | cos 2θ * 0.5 + 0.5 | sin 2θ * 0.5 + 0.5 | clamp(trace * strength) | coherence (0-1, no gain) |

- **θ is the dominant gradient direction: it points *across* the edge**, not along it. The along-edge direction is θ + 90°.
- **Coherence** = (λ1-λ2)/(λ1+λ2): 1 on a clean edge, 0 where the structure has no preferred direction. Contrast-independent. It is noisy where trace is very small.
- **Neutral values:** raw (0, 0.5, 0, 1); packed (0.5, 0.5, 0, 0). Isotropic pixels (trace < 1e-6) and pixels where the direction is undefined (equal eigenvalues) output R = G = 0.5, never an arbitrary angle.
- **Angle-doubled:** outlet 1's R/G must **not** be fed to sign-sensitive consumers (`f_vf_advect`, `f_vf_warp`, `f_caustic`, `f_vf_fluid`, `f_vf_potential`, `f_weave`, ...). Route it through `f_tf_axisflow`.

---

## Calibration by input type

Trace is gradient *squared*, so the gain needed to bring the 95th-percentile trace to 1.0 scales with feature size squared. At radius 3, 640x480, on noise:

| Feature size (noise cells across) | Strength |
|---|---|
| fine (16) | ~35 |
| medium (8) | ~150 |
| coarse (4) | ~900 |

Default 100 and the 1-1000 log range were chosen live on a smooth source (100 and 300 both looked right). Coherence does not need calibration.

---

## Cost

Per pass, M3 Max (M1 unmeasured), at R_MAX 16 and radius 16: about 0.9 ms at 1080p and 3.4 ms at 4K per stage, as upper bounds (the bench frame floor, not real GPU cost). The four-stage chain is bounded by about 3.5 ms at 1080p and 13.4 ms at 4K; real cost is lower.

---

## Typical use

```
jit.gl.bfg -> f_tf_tensormap (outlet 1) -> f_tf_axisflow -> f_vf_advect (vecfield in)
```

Also: coherence (A) as a "where is structure" matte; trace (B) as a strength map; outlet 1 into `f_vf_split` returns cos 2θ and sin 2θ as two scalar textures with no `atan2`.

---

## Notes

- Built in `tests/modules/tf_tensormap/test_tf_tensormap.py` (NumPy mirror, 18 tests) and `tests/modules/tf_tensormap/bench_tf_tensormap.py` (GPU parity per stage, 8 tests). Spec, plan, tasks: `.specify/f_tf_tensormap/`.
- Bench GPU wraps out-of-range texture reads; the codeboxes clamp coordinates in-shader to the first/last texel center.
- GPU `atan2(0,0)` differs from NumPy's, hence the explicit neutral R = G where the direction is undefined.
- The A channel is coherence, not raw λ1-λ2 (plan ADR-2).
- Hub and consumer audit: `ideas/f_tensorfield.md`.

---

## References

- Bigun & Granlund (1987). "Optimal orientation detection of linear symmetry." ICCV. The structure tensor as local orientation estimator.
- Kass & Witkin (1987). "Analyzing oriented patterns." Computer Vision, Graphics, and Image Processing 37(3). Orientation fields from smoothed gradient outer products.
- Sobel gradient, box window and closed-form 2x2 symmetric eigendecomposition are standard; no code was taken from other implementations. The packed (cos 2theta, sin 2theta, trace, coherence) layout is this library's own.
