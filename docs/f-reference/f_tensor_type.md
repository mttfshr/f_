# f_tensor - Tensor Field Type Contract

_Created: 2026-10-16_
_Status: Draft - one producer (`f_tf_tensormap`), one bridge (`f_tf_axisflow`), no direct consumers yet_

---

## What this document is

The encoding contract for textures produced by the `f_tf_` family. Sibling of `docs/f-reference/f_vecfield_type.md`. **Neither tensor outlet is an f_vecfield** and must not be labeled or wired as one.

---

## Why not a vecfield

A structure tensor describes an *unoriented line field*: the orientation of local structure and how confident it is, with no direction of travel (θ and θ+180° are the same structure). A vecfield stores a signed vector. Forcing one into the other either invents a sign (a hard seam in the field) or hides line data in unused vecfield channels, which was explicitly rejected (it would create two ordinary-looking vecfields that are not interchangeable).

---

## Textures

Both `float32`, both from `f_tf_tensormap`.

### Raw tensor (outlet 0)

| Channel | Content |
|---|---|
| R | Jxx * strength (>= 0) |
| G | Jxy * strength * 0.5 + 0.5 (signed; 0.5 = zero) |
| B | Jyy * strength (>= 0) |
| A | 1 |

Neutral = zero tensor = (0, 0.5, 0, 1). Lossless apart from the gain, no angle doubling, sign-safe. Decode: Jxx = R/strength, Jxy = (G - 0.5) * 2/strength, Jyy = B/strength.

### Packed (outlet 1)

| Channel | Content |
|---|---|
| R | cos 2θ * 0.5 + 0.5 |
| G | sin 2θ * 0.5 + 0.5 |
| B | clamp(trace * strength) |
| A | coherence = (λ1-λ2)/(λ1+λ2), 0-1, no gain |

Neutral = (0.5, 0.5, 0, 0). θ is the dominant **gradient** direction, i.e. **across** the edge; along the edge is θ + 90°. R and G are signed with 0.5 = zero, like vecfield components, and decode with `(sample - 0.5) * 2`.

---

## Why angle-doubled

Storing (cos θ, sin θ) of an unoriented axis forces an arbitrary sign, and the stored value flips discontinuously where the axis crosses the chosen branch. (cos 2θ, sin 2θ) is the same for θ and θ+180°, so the stored field is continuous. The cost is that R/G are no longer a vector in screen space: a line at 45° stores as a vector pointing at 90°.

---

## Consumer rules

1. **Never feed outlet 1's R/G directly to a sign-sensitive consumer.** That is any module that displaces, accumulates, or forces along a direction: `f_vf_advect`, `f_vf_warp`, `f_caustic`, `f_vf_fluid`, `f_vf_potential`, `f_weave`, `f_vf_streak`, and (inferred) `f_vf_chroma`/`f_vf_prism`. The doubled angle moves them the wrong way, and the decoded sign flips at the branch cut.
2. **To drive them, go through `f_tf_axisflow`**, which turns the axis into a continuous vecfield without picking a sign.
3. **Axis-blind uses are fine as-is:** B (trace) and A (coherence) as scalar mattes or modulation inputs; `f_vf_split` on outlet 1 returns cos 2θ and sin 2θ as scalar textures.
4. **A consumer that needs θ itself** decodes `θ = 0.5 * atan2(G', R')` (G', R' decoded to -1..1). GenExpr `atan2` on sampled-texture input is verified safe on the GPU, with a benign ±pi difference exactly at the branch cut. The recovered θ flips by 180° where the true axis crosses vertical; use it only where the algorithm is symmetric to that.
5. **Unconnected inputs** are `vs_black` (all zeros), which decodes to c2 = s2 = -1, not neutral. Gate on content or the in-state flag; `f_tf_axisflow` rejects |(c2, s2)| > 1.05.

---

## Family members

| Patch | Role | Notes |
|---|---|---|
| `f_tf_tensormap` | Producer | Image/scalar texture -> raw tensor + packed |
| `f_tf_axisflow` | Bridge | Packed tensor -> vecfield (projection of a reference angle onto the edge line) |

Planned consumers (hub: `ideas/f_tensorfield.md`): `f_vf_glow` anisotropy inlet, anisotropic blur, confidence-scaled marks in `f_vf_seeds`, a glyph-field renderer.
