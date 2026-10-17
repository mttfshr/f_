# Design: tensor → vecfield bridge (working name `f_tf_tovec`)

_Created: 2026-10-16_
_Superseded by spec.md (2026-10-16). NOTE: the tensormap axis theta is the across-edge gradient axis, so "along" is the complement projector r - (g.r)g and |v_along| = |sin(theta-phi)|; formulas below have along/across swapped._
_Status: Design for discussion. No code, no spec yet. Decide the open items at the bottom first._

_Context: `f_tf_tensormap` outlet 1 packs (cos 2θ, sin 2θ) in R/G. That is an AXIS field
(θ and θ+π are the same line). Sign-sensitive consumers (`f_vf_advect`, `f_vf_warp`,
`f_caustic`, `f_vf_fluid`, `f_vf_potential`, ...) need a signed VECTOR field. The hub doc
(`ideas/f_tensorfield.md`, "Explicit exclusion list") bans wiring outlet 1 into them. This
design is the sanctioned way to get a tensor-derived field into those consumers._

---

## The problem, precisely

Recovering a vector from an axis needs a sign choice. The classic route is
`θ = 0.5·atan2(s2, c2)`, then `(cos θ, sin θ)`. θ is confined to (−π/2, π/2], so the
vector flips sign wherever the axis crosses vertical. That is a hard seam: neighbouring
pixels flow in opposite directions, and advect accumulates or tears along it. Picking a
different convention only moves the seam.

## Core idea: project a reference direction onto the axis (no atan2, no seam)

Let `a = (cos θ, sin θ)` be the structure axis and `r = (cos φ, sin φ)` a user-chosen
reference direction (a "bias angle"). The vector

    v_along = (a · r) a  =  a aᵀ r

is the projection of `r` onto the axis line. It is invariant under a → −a, because the two
sign flips cancel, so there is no sign choice and no seam. And `a aᵀ` is written
directly in the doubled-angle values the tensor map already stores:

    a aᵀ = ½ · [[1 + c2,  s2 ],
                [ s2,  1 − c2]]           (c2 = cos 2θ, s2 = sin 2θ)

    v_along = ½ · ( rx + c2·rx + s2·ry ,  ry + s2·rx − c2·ry )

Properties:
- No atan2 and no branch cut. The output is as smooth as c2/s2.
- |v_along| = |cos(θ − φ)|: full strength where the edge runs parallel to the bias, fading
  smoothly to zero where it is perpendicular. A real, visible trade-off. The cost of
  removing the seam is that edges perpendicular to the bias don't move.
- Across-edge variant, free: `v_across = r − v_along` (projection onto the normal).
- Isotropic pixels (R=G=0.5 → c2=s2=0) would give ½r, a spurious drift. Gate on
  `length(c2,s2)`: zero it where that is < eps (the same iso convention as the tensormap).

## Proposed shape

**Archetype:** processor, tensor packed texture in (inlet 0), vecfield out. One pass, one
`jit.gl.pix`, a few multiplies per pixel. Cost is negligible next to the tensormap itself.

**Input:** the tensormap's outlet 1 packed texture, only. (Outlet 0 raw is a different input
contract and not accepted.)

**Output:** a standard f_vecfield (`R,G = 0.5 + 0.5·v`, B = 0.5, A = 1; neutral 0.5,0.5).
Because the output is an ordinary signed vecfield, every consumer on the exclusion list can
take it. The exclusion applies to the tensormap's outlet 1, not to this module's output.

**Params (draft):**

| Param | Range / default | Meaning |
|---|---|---|
| mode | along / across (menu), along | project onto the edge line, or onto its normal |
| angle | −180–180°, 0 | the reference/bias direction φ. Where the seam-free fade-to-zero lands. |
| gain | 0–10, 1 | output amplitude (vecfield units are normalized screen coords, so consumers usually want small values) |
| gate | 0–1, 1 | 0 = ignore coherence, 1 = multiply magnitude by coherence (A). Gates flow to confident structure only |
| bypass | param, `bypass_gate` | neutral 0.5,0.5 |

Trace (B) gating can be added the same way later; leave out of v1 unless the live test wants it.

## Why this, not the alternatives

- **atan2 + sign pick (per consumer or in a bridge):** hard seam, the problem above.
- **Fix it in each consumer:** touches ~8 modules and each one's maths. Rejected.
- **Add a third tensormap outlet:** the two-outlet shape was decided 2026-10-13; a separate
  bridge keeps the producer clean and lets the bridge grow (rotate, mode, gate) on its own.
- **Make the bias angle per-pixel (an optional second inlet):** a good v2 (e.g. bias
  toward a swirl field), explicitly out of scope for v1.

## Verification plan (mirror first, like the tensormap)

1. NumPy mirror in `tests/` of the projection maths.
2. Properties: invariant under θ→θ+π; |v| = |cos(θ−φ)| against a brute-force `atan2` reference
   on a sweep of θ and φ; `along + across = r`; iso pixels → exactly 0.5,0.5 output.
3. Chain test: tensormap mirror → bridge mirror on ramps/stripes, check direction and fade.
4. Contract + bypass tests (BYPASS_EXPECT const 0.5,0.5,0.5,1).
5. Bench for parity on the GPU; then live: tensormap → bridge → advect `vecfield in`,
   judged by eye on noise, with the `angle` sweep showing where the fade lands.

## Open items for Matt

1. **Name.** `f_tf_tovec` is a placeholder. Alternatives: `f_tf_axisflow`, `f_tf_tovecfield`.
   (`f_tf_` family prefix, producers of vecfields from tensors.)
2. **Accept the fade?** The consequence of seam-free is that edges ⟂ the bias angle get zero
   flow. If you'd rather keep full magnitude and tolerate a seam, add a `normalize` 0–1
   param (renormalize |v| toward 1; trades smoothness for strength). Recommend: ship
   projection only, add `normalize` only if the live test needs it.
3. **Aspect ratio.** The tensor is in pixel space, vecfield vectors are normalized screen
   coords. Check how `f_vf_fieldmap` treats a non-square frame before locking the maths.
4. **Hub doc.** The exclusion list in `ideas/f_tensorfield.md` should point here ("outlet 1
   direct is banned; through the bridge is fine"). Update after the design is accepted.

## Task outline (once accepted; promote to a spec)

- Spec + plan + tasks in `.specify/f_tf_tovec/`.
- Mirror + tests, codebox, definition, build, menu/README registration, contract/bypass tests.
- Live check: tensormap → bridge → `f_vf_advect`.
- Docs: `docs/f-reference/f_tf_tovec.md`, hub doc update, HANDOFF entry.
