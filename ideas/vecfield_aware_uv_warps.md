# Vecfield-aware UV warps (`f_mobius`, `f_droste`)

_Status: Parked. Captured only: on 2026-10-20 Matt asked for this to go into an ideas file and for nothing to be done now._
_Spec: `.specify/f_mobius_vecfield/spec.md` (Draft, 2026-10-10; not built, not scheduled). Plan pointer: `plan.md`, Still open 5._
_Discussed: 2026-10-20 (options and recommendation below; no decision taken)._

## The idea

`f_mobius` and `f_droste` resample whatever is piped into their inlet with a generic `sample()`. If a vecfield (`f_vf_*`)
goes through them, its R/G values are carried to the new pixel position unchanged: the field value is never rotated or
scaled to match the local transform, although the transform does exactly that to everything else in the frame. A
vecfield-aware variant would carry the vector correctly (a pushforward of the field under the map).

## What is already settled (from the spec and its spikes)

- `f_mobius` is conformal on both paths (`rotate + zoom` is `g(z) = scale * e^{i*angle} * z`; `invert` is `g(z) = 1/z`), so
  the correct carried vector is a complex division, `v' = v_source(uv) / g'(z)`. At a rotate-and-zoom setting the naive
  error is a constant (the rotation angle); on `invert` it is position-dependent, up to 180 degrees near the singularity.
  Characterized in `tests/records/spike_mobius_vecfield_transform.py`.
- `f_droste` is essentially never conformal (its log-polar step scales the radial and angular axes by different
  constants unless `log(zoom) = 2*pi`), so the correct transform is a 2x2 Jacobian solve, `v' = J(z)^-1 v`. Verified only
  by finite differences (`tests/records/spike_droste_conformality.py`); a closed-form Jacobian is tractable by hand but not
  yet derived, and a shipped codebox should not evaluate four extra `droste_T` calls per pixel.
- The two fixes are different shapes of work; one shared module is unlikely to be right.
- `f_poincare` has no codebox yet, so nothing to check there.

## What changed since the spec (2026-10-20)

- Both modules now have tier-1 mirrors (`tests/modules/mobius/`, `tests/modules/droste/`; mobius includes a check at generic
  angle, zoom, centre and invert together). A build can therefore verify its carried vector against a finite-difference
  pushforward of the mirror's own map, which is independent ground truth and cheap.
- A GPU probe (`tests/records/bench_mirror_findings_probes.py`, P2) showed that on the codebox bench `sample()` WRAPS for
  uv outside [0, 1], while `skills/jit-gen-codebox/SKILL.md` says the default boundmode is CLAMP. Unresolved which governs a
  shipped module. It matters here, because the `invert` path samples far outside the frame near its singularity: settle it
  before any build that depends on edge behaviour.

## Options discussed

1. **Park it with a stated trigger** (this file). Build only when a real chain needs it. Costs nothing.
2. **A second outlet on `f_mobius`** (a dedicated vecfield inlet, as `f_vf_warp` does through `state_param`). Smallest diff,
   but it changes a shipped module, and mobius and droste need different math anyway.
3. **Separate modules in the `f_vf_` family**: a conformal one for mobius first (complex division), a matrix one for droste
   later (analytic Jacobian). Fits the constitution's "one bpatcher, one concern" and leaves `f_mobius` / `f_droste` as pure
   texture processors; costs duplicated warp math.
4. **Skip it and spend the effort elsewhere** (`f_ks`, `f_vf_lbm`, packaging).

Recommendation given: option 1 unless there is a concrete chain; if there is, option 3, starting with mobius.

## Questions to settle before any build

1. **Is there a real use case?** The spec's open question 3 still stands: the idea came from reading about vector and tensor
   fields (`ideas/vector_field_math_concepts.md` #6 and #10), not from a module that needed it. The current behaviour is a
   different, undocumented look, not an obvious bug. A candidate chain worth testing: optical flow computed on
   kaleidoscope content feeding a warp.
2. **Shape:** separate `f_vf_*` module (leaning) or a second outlet on the existing module.
3. **Near the `invert` singularity:** how should the carried vector behave (fade toward the neutral vector, or clamp its
   magnitude)? A leaning toward fading to neutral (no motion at a point where the map is singular), but this was not decided
   and wants a look in Max.

## Trigger to revisit

A concrete chain that needs it, or Matt wanting the corrected field for its look.

## If it is built (per the constitution's order)

Update the spec (answer the three questions) -> scratch codebox -> tier-1 test using the existing mirror's map as
independent ground truth -> tier-2 bench (after the boundmode question is settled) -> definition and build -> tier-3 live
check. Mobius first; droste needs the analytic Jacobian first.

## Related

`ideas/vector_field_math_concepts.md` (#6, #10); `src/f_vf_warp/definition.py` (precedent for a vecfield inlet via
`state_param`); `ideas/f_poincare.md`; `.specify/f_mobius_vecfield/spec.md`.
