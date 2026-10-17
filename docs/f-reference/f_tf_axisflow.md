# f_tf_axisflow

**Type:** Processor (f_vecfield producer, tensor input)
**Status:** Built 2026-10-16; mirror and bench tests green, live-checked with `f_vf_advect`. Helpfile pending.

---

## What it does

Turns `f_tf_tensormap` outlet 1 into an ordinary **signed vecfield**, so sign-sensitive consumers (`f_vf_advect`, `f_vf_warp`, `f_caustic`, `f_vf_fluid`, `f_vf_potential`...) can follow image structure.

The tensormap gives an *axis* (a line has no direction: θ and θ+180° are the same). A vector needs a sign, and any "recover the angle, pick a sign" route puts a hard seam where the axis crosses vertical. This module never picks a sign. It **projects a reference direction onto the edge line**:

```
g = (cos θ, sin θ)               tensormap axis: gradient direction, ACROSS the edge
r = (cos φ, sin φ)               the Angle control
across = (g . r) g
along  = r - across              Mode = Along (default)
```

In terms of the packed values c2 = cos 2θ, s2 = sin 2θ:

```
along  = 0.5 * ((1 - c2) rx - s2 ry,  (1 + c2) ry - s2 rx)
across = 0.5 * ((1 + c2) rx + s2 ry,  s2 rx + (1 - c2) ry)
```

No `atan2`, no branch cut: the output is as smooth as the input, and replacing the axis by its opposite changes nothing.

**The trade-off:** |along| = |sin(θ - φ)|. Flow is full strength where an edge runs parallel to `angle` and fades smoothly to zero where an edge is perpendicular to it. That fade is the price of having no seam.

---

## Signal Flow

```
in0 (tensormap outlet 1) -> axisflow_pix -> out0 (vecfield, @type float32)
```

One pass, no loops, no state.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `mode` | Along / Across | Along | Along: flow follows the edges. Across: flow crosses them (gradient direction). |
| `angle` | -180-180 deg | 0 | Reference direction. Where the fade-to-zero lands. |
| `gain` | 0-10 | 1 | Output amplitude. Units are the short side of the frame, so consumers usually want small values. |
| `gate` | 0-1 | 1 | 0 = ignore coherence; 1 = scale flow by the tensormap's coherence, so only confident structure moves. |
| `width` | 64-8192 | 640 | Render width in pixels. Set to the real frame width. |
| `height` | 64-8192 | 480 | Render height in pixels. Set to the real frame height. |
| `bypass` | 0/1 | 0 | Neutral vecfield. |

**Prefix:** `axisflow` - **Object name:** `axisflow_pix` - **Type:** `@type float32`

---

## Output

A standard f_vecfield (`docs/f-reference/f_vecfield_type.md`): R,G = v * 0.5 + 0.5, B = 0.5, A = 1. Neutral = (0.5, 0.5, 0.5, 1).

- **Isotropic pixels** (tensormap R = G = 0.5) and an **unconnected inlet** (`vs_black`, which decodes to a vector of length sqrt 2) both give the neutral vecfield. Valid tensormap output always has |(c2, s2)| <= 1, so anything above 1.05 is treated as invalid.
- **Aspect:** the tensor lives in pixel space, vecfield vectors in normalized screen coordinates. The module converts so the vector keeps its *pixel* direction (units: the short side). Without this a 45-degree edge on 16:9 would drift at about 29 degrees. On a square frame the conversion is the identity. This needs `width`/`height` set correctly.

---

## Typical use

```
jit.gl.bfg -> f_tf_tensormap -(outlet 1)-> f_tf_axisflow -> f_vf_advect (vecfield in)
                       source texture ------------------------------> f_vf_advect (texture in)
```

Sweep `angle` to move where the flow fades. `gate` at 1 keeps flat or noisy areas still. Use **Across** to push along the gradient instead (toward or away from edges).

---

## Notes

- Tests: `tests/test_tf_axisflow.py` (NumPy mirror, 16 tests, including a mutation check that catches along/across swapped) and `tests/bench_tf_axisflow.py` (GPU parity, 5 tests). Spec, plan, tasks: `.specify/f_tf_axisflow/`.
- `phi` is a predefined GenExpr constant and cannot be assigned; the codebox uses `ref_ang`.
- Deferred: per-pixel reference direction (a second inlet), a `normalize` mode that keeps full magnitude at the cost of a seam, trace gating.

---

## References

- Original construction (2026-10-16): projecting a reference direction onto the structure axis, written in terms of the stored cos 2theta / sin 2theta (a rank-one projector, standard linear algebra). No external source; not taken from other implementations.
- Input encoding and the line-field (axis) versus vector-field distinction: see `docs/f-reference/f_tensor_type.md`.
