# Spec: f_tf_axisflow

_Created: 2026-10-16_
_Status: Draft_
_Design history: `design.md` (same directory). Where they differ, this spec wins._
_Hub: `ideas/f_tensorfield.md` (consumer audit, exclusion list)._

---

## What it does

Turns the axis field from `f_tf_tensormap` (outlet 1) into an ordinary signed **vecfield**, so
the sign-sensitive consumers (`f_vf_advect`, `f_vf_warp`, `f_caustic`, `f_vf_fluid`,
`f_vf_potential`, ...) can follow image structure.

An axis has no sign (θ and θ+π are the same line), so any "recover θ, then (cos θ, sin θ)"
route puts a hard seam where the axis crosses vertical. This module avoids the sign choice
altogether: it **projects a reference direction onto the axis line**.

    g = (cos θ, sin θ)            the tensormap's axis: the dominant GRADIENT direction,
                                  i.e. ACROSS the edge (theta = 0.5*atan2(2Jxy, Jxx-Jyy))
    r = (cos φ, sin φ)            reference direction ("angle")
    v_across = (g · r) g  =  ½ ( (1+c2)·rx + s2·ry ,  s2·rx + (1−c2)·ry )
    v_along  = r − v_across =  ½ ( (1−c2)·rx − s2·ry , (1+c2)·ry − s2·rx )   [default]

with c2 = cos 2θ, s2 = sin 2θ read straight from the packed input. No `atan2`, no branch
cut; the output is as smooth as the input. |v_along| = |sin(θ − φ)|: full strength where the edge runs parallel to the
reference, fading to zero where the edge is perpendicular to it (gradient parallel to r). That fade is
the price of having no seam.

**Processor archetype, `driving_inlet`.** Inlet 0 carries the tensormap's outlet 1 (packed
direction/trace/coherence) and all control messages. One outlet: vecfield.

---

## Decisions (2026-10-16, Matt)

- **Name `f_tf_axisflow`.** Family prefix `f_tf_`.
- **Projection only.** No `normalize` (renormalize toward |v| = 1) in v1. Add it only if the
  live test shows the fade is a problem.
- **Input is outlet 1 only.** Outlet 0 (raw tensor) is a different contract and not accepted.
- **Aspect corrected, always.** See Output.

## Input

Tensormap outlet 1: R,G = (cos 2θ, sin 2θ)·0.5+0.5, B = clamp(trace·strength), A = coherence.
Decode `c2 = (R−0.5)·2`, `s2 = (G−0.5)·2`. θ is the tensormap's principal axis, the dominant
gradient direction, so it points ACROSS the edge; "along" therefore uses the complement
projector. (Found 2026-10-16 while writing the mirror; the design sketch had these swapped.)

## Output

Standard f_vecfield (`docs/f-reference/f_vecfield_type.md`): R,G = v·0.5+0.5, B = 0.5, A = 1.
Neutral = (0.5, 0.5, 0.5, 1).

**Aspect.** The axis is a direction in *pixel* space (the tensormap works per texel), but
vecfield vectors are in normalized screen coordinates, where a displacement (a, b) moves
(a·W, b·H) pixels. Naively emitting (vx, vy) would drift edges off their own direction by an
angle that grows with the aspect ratio (a 45° edge on 16:9 comes out at about 29°). So the
vector is converted to preserve its pixel direction, in units of the short side:

    s = min(W, H);   out = ( vx·s/W , vy·s/H )          (identity on a square frame)

`f_vf_fieldmap` does no such correction (it differences in UV); that is its own matter and not
changed here.

## Parameters

| Param | Range / default | Meaning |
|---|---|---|
| `mode` | menu: along / across, along | follow the edge (reference projected onto the edge line), or its normal (onto the gradient axis) |
| `angle` | −180–180°, 0 | reference direction φ; where the fade-to-zero lands |
| `gain` | −4–4, 1 | signed output amplitude; negative reverses the flow (changed 2026-10-17) |
| `gate` | 0–1, 1 | 0 = ignore coherence; 1 = multiply magnitude by coherence (A) |
| `width`, `height` | 64–8192, 640 / 480, numbox | frame size in pixels. `dim` reads 1 inside live `jit.gl.pix` (see tensormap spec), so they are Params |
| `bypass` | param bypass (`bypass_gate`) | neutral vecfield |

## Functional requirements

- **FR-001** The module MUST NOT use `atan2` or any sign-picking step; the output MUST be
  unchanged if the input axis is replaced by its opposite (c2, s2 are already sign-free, so
  this holds by construction; verified against a brute-force reference).
- **FR-002** `|v_along| = |sin(θ − φ)|` and `|v_across| = |cos(θ − φ)|` before gain/gate, to float tolerance.
- **FR-003** `v_along + v_across = r` before gain/gate.
- **FR-004** Isotropic input (c2 = s2 = 0, i.e. R = G = 0.5) MUST give the neutral vecfield,
  not the drift ½r.
- **FR-005** An unconnected inlet (`vs_black` decodes to c2 = s2 = −1, length √2) MUST give
  the neutral vecfield. Valid tensormap output has length ≤ 1, so a content guard
  (length > 1.05 → neutral) is the primary mechanism.
- **FR-006** `gate` = 1 multiplies the magnitude by A; `gate` = 0 leaves it unscaled.
- **FR-007** Aspect conversion: identity when `width` = `height`; the pixel direction of v is
  preserved otherwise.
- **FR-008** Bypass MUST output the neutral vecfield via a `bypass_gate` Param (not the native
  `@bypass`), registered in `tests/contracts/bench_modules.py` `BYPASS_EXPECT`.
- **FR-009** Vector magnitude MUST stay within the encodable range [−1, 1] for gain ≤ 1
  (|v| ≤ 1 and the aspect scale ≤ 1 guarantee it); the output is clamped for higher gain.

## Non-functional

- One `jit.gl.pix` pass, float32, no loops: cost negligible next to the tensormap.
- `@type float32` output required (signed encoded values; same as the tensormap).

## Success criteria

1. tensormap → axisflow → `f_vf_advect` (vecfield in) on noise: contours stream along edges
   with no visible seam, and the `angle` control visibly moves where the flow fades.
2. All mirror, contract and bench tests green; bypass leaves the neutral vecfield.
3. A 16:9 frame advects along its edges, not at a skewed angle (aspect check on a 45° ramp).

## Edge cases

- Edge exactly perpendicular to the reference (gradient parallel to it): v_along = 0 there (by design).
- Very low coherence with `gate` = 1: flow vanishes; with `gate` = 0 it follows noisy axes.
- `width`/`height` left at defaults on a different frame size: direction skewed by the ratio;
  document it, same as the tensormap.

## Out of scope

- Per-pixel reference direction (a second inlet, e.g. bias toward a swirl field): built 2026-10-17 (see tasks Phase 5).
- `normalize` / full-magnitude mode with a seam.
- Trace gating (B channel): add only if the live test wants it.
- Outlet 0 (raw tensor) input.
