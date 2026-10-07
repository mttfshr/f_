# Spec: f_vf_glass

_Created: 2026-10-06_
_Status: ON HOLD (2026-10-06, Matt) — Vsynth already ships smooth, morphing sources; see Open Questions
and `ideas/f_vf_glass.md`, "Findings". Draft only. Nothing built or tested._

Concept and rationale: `ideas/f_vf_glass.md`. Context: `ideas/optics_map.md` (caustic and scatter findings),
`ideas/f_lumia.md`.

---

## What it does

A self-generating **glass height field** and its exact gradient, as an f_vecfield. The glass is the medium in
the light pipeline: its slope deflects light and its curvature focuses it. `f_vf_glass` produces that field,
animated, for any vecfield consumer: `f_vf_warp` (image through the glass), `f_vf_prism` / `f_vf_chroma`
(dispersion), `f_caustic` (soft convergence), `f_vf_streak` / `f_vf_glow`, `f_vf_advect`, `f_lens`'s field
inlet, and the scatter module (`.specify/f_caustic_scatter/`).

**Producer in the f_vecfield family** (`f_vf_` prefix, per the constitution). **"source" archetype** as
`f_vf_vortex` and `f_vf_seeds` ship it: no source inlet; the single inlet carries control messages.

**Outlets** (proposed): `vecfield` (primary), `height` (scalar), `focus` (signed divergence of the field).

---

## Algorithm

Glass is a sum of cosine modes, evaluated analytically per pixel:

```
arg_k = 2π (kx_k * x' + ky_k * y') + φ_k + ω_k * phase        x', y' = rotated, drifted, scaled uv
h     = Σ_k a_k cos(arg_k)
grad  = -Σ_k a_k 2π (kx_k, ky_k) sin(arg_k)
div   =  -Σ_k a_k (2π)² (kx_k² + ky_k²) cos(arg_k)           (the `focus` outlet)
F     = clamp(gain * grad, -1, 1)
out1  = (F * 0.5 + 0.5, 0.5, 1)      f_vecfield: float32, RG = XY, 0.5 = zero
out2  = h mapped to 0..1             (mapping is an open question)
out3  = div mapped to 0..1 with 0.5 = zero
```

- **Families are wave-vector sets** (one codebox for all): `modes` = N seeded integer vectors (N 1..8, hashed
  from `seed`, each with its own amplitude, initial phase and drift rate); `fluted` = 1 vector; `hobnail` = 2
  orthogonal vectors, equal amplitude; `hex` = 3 vectors at 60°. The unrolled loop count is fixed in the
  codebox; unused modes get amplitude 0.
- **Seamless when unrotated:** integer vectors with `scale` an integer and `rotate` = 0 give a field periodic
  in the unit square (matters to a consumer's wrap mode). Non-integer `scale` or `rotate` keeps the field
  smooth everywhere but breaks the tiling.
- **Time:** the `phase` param moves every mode at its own rate (`ω_k`, incommensurate), so the pattern does
  not repeat and caustic lines split and merge. Time source: see Open Questions.
- **Encoding limit:** `|F| <= 1`. Clipping is a hard clamp unless the soft-limit question is resolved the
  other way.
- Reference implementation of the `modes` family and its gradient and Hessian already exists as the test
  glass in `scratch/caustic_fidelity.py` (`raw_field`); the NumPy mirror should start from it.

---

## Inlets

| Inlet | Type | Label | Required | Description |
|---|---|---|---|---|
| 0 | control | control | — | control messages only; no texture is consumed |

## Outlets

| Outlet | Type | Comment | Description |
|---|---|---|---|
| 0 | f_vecfield (float32) | vecfield | `gain * grad h` |
| 1 | float32 scalar | height | `h`, 0..1 |
| 2 | float32 scalar | focus | divergence of `F`, 0.5 = zero |

Bypass is a passthrough on every outlet (convention, 2026-10-05): a generator has no input, so each outlet
goes to its neutral value: vecfield 0.5/0.5, `height` black, `focus` 0.5. Needs `bypass_mode: "param"` and a
`BYPASS_EXPECT` row.

---

## Parameters (proposed ranges; builder representation decided at plan time)

| Param | Type | Range | Default | Description |
|---|---|---|---|---|
| `type` | int selector | 0–3 | 0 | modes / fluted / hobnail / hex |
| `gain` | float | 0–? | ? | field amplitude (`F = gain * grad h`); canonical name for the intensity role |
| `scale` | float | 0.25–8 | 1 | multiplies the wave vectors (pattern frequency) |
| `modes` | int | 1–8 | 5 | mode count for `type` 0 |
| `seed` | int | 0–999 | 7 | hashes wave vectors, amplitudes, phases, rates |
| `phase` | float | 0–? | 0 | evolution position; automatable |
| `drift_x`, `drift_y` | float | ±? | 0 | translate the pattern |
| `rotate` | float | -180–180 | 0 | degrees |
| `bypass` | toggle | 0/1 | 0 | |

Not every parameter earns a panel slot (skill: "Not every parameter earns a panel slot"). A candidate cut:
panel gets `type`, `gain`, `scale`, `phase`, `rotate`; `seed`, `modes`, `drift_*` stay message-only. The
default `gain` depends on the regime-normalisation decision.

---

## Signal Flow

```
in0 (control) → routepass → route → dials / numboxes → attrui → glass_pix (@type float32)
                                                          glass_pix out0 → out0 (vecfield)
                                                                    out1 → out1 (height)
                                                                    out2 → out2 (focus)
[if an internal clock is adopted]  r draw → counter → … → prepend param phase → glass_pix
```

---

## Acceptance Criteria

Verification tiers per the constitution; the gate decision (which tiers apply) is the first task of
Phase 0 in `tasks.md`.

1. **Tier 1 (NumPy mirror).** Analytic gradient equals the central difference of `h`; analytic divergence
   equals the divergence of that gradient; encode/decode round trip; periodicity (`rotate` 0, integer `scale`):
   `field(0, y) = field(1, y)`; `h` continuous in `phase`.
2. **Tier 2 (bench, real codebox).** All three outlets against the mirror in float32; neutral values at
   bypass; shipped-patcher contract (`tests/test_module_contracts.py`, `tests/bench_modules.py`) and drift
   (`build/drift.py`) pass.
3. **Tier 3 (scratch patch).** Into `f_vf_warp`, `f_vf_prism` and `f_caustic`: families look distinct, no pops
   when `phase` is swept, ranges sensible. Judgement, not numbers.
4. If regime normalisation is adopted: the predicted first-fold distance matches the photon-counting truth
   (`scratch/caustic_fidelity.py` machinery) to within an agreed tolerance.

---

## Out of Scope (v1)

- Audio input (modulate `phase` / `gain` from the patch).
- An upstream scalar as base height (that is `f_vf_fieldmap`'s job).
- Families that are not mode sums: lens array, rain-glass ripples, Fresnel rings.
- A reduction pass over the field (the analytic bound makes it unnecessary if normalisation is adopted).

---

## Clarifications

### Session 2026-10-06

- Q: Should the glass be inside the scatter module or a separate producer? → A: Separate producer (Matt).
  Reasons recorded in `ideas/f_vf_glass.md`.
- Q: One algorithm or one per glass type? → A: One mode-sum codebox; types are wave-vector sets.

---

## Open Questions

- **Does the vecfield outlet earn its place?** Checked 2026-10-06 (NumPy, fieldmap emulated from its doc,
  not run in Max; `ideas/f_vf_glass.md`, "Findings"): a smooth height through `f_vf_fieldmap` gives the same
  caustics as the analytic field (precision does not matter, even at 8 bits). The fieldmap route's only
  difference is its UV inset, a registration stretch. So the new capability is the smooth, evolving height
  generator; the vecfield outlet saves a pass and removes the inset but is not a quality gain. Options: keep
  all three outlets (as drafted); height-only generator feeding `f_vf_fieldmap` (then not an `f_vf_` module);
  or vecfield primary only if regime normalisation is adopted (the one thing a texture route cannot do).
  A scratch chain (height codebox → `f_vf_fieldmap` → consumers) is the cheap test before building.
- **Time source:** a pix codebox has no confirmed clock. A plain automatable `phase`, an internal
  `r draw` counter chain (as used in the 2026-10-06 lag spike), or both?
- **`jit.gl.bfg` time axis:** the refpage lists a two-component `@offset`; confirm in Max whether a usable
  third axis exists, since that changes how much this module adds.
- **Regime normalisation:** scale the field so a consumer's `distance` is in units of the first fold? Needs
  a convention a consumer can know (the vecfield type carries only RG) and an answer to the `|F| <= 1` limit.
- **`height` mapping to 0..1:** fixed bound from the amplitudes, or a normalised range?
- **`focus` definition:** divergence (distance-free; what `f_caustic` weights) vs a Hessian determinant
  (needs a distance; belongs to a consumer).
- **Soft limit vs hard clamp** at `|F| = 1`.
- **Panel size:** default 78×90 will not hold five dials plus three outlets; check `moduleSize.js` limits.
- **Lag:** the scatter consumer is one frame behind pix consumers; visible on fast glass motion.
