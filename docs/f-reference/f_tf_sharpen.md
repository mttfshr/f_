# f_tf_sharpen

**Type:** Processor (f_tensor stage — raw in, raw out)
**Status:** Draft — codebox tier-2 bench and tier-3 live judgment pending (Phase 1 execution and Phase 2 scratch are owner-gated; tier-1 mirror green 15/15, 2026-10-17).

---

## What it does

An **eigengap exaggerator/relaxer**. Per pixel it decodes the incoming raw tensor to its
eigenvalues, scales the gap between them by γ while holding the trace fixed, and
re-encodes the same raw outlet-0 contract:

```
λ1' = trace/2 + γ·(λ1 − trace/2)
λ2' = trace/2 + γ·(λ2 − trace/2)      (same PLUS sign for both — see Notes)
Jxy' = γ·Jxy,   θ' = θ                (axis rides through untouched)
```

- **γ > 1:** anisotropy exaggerated — hesitant edges commit toward line-like tensors.
- **γ < 1:** the field relaxes toward the isotropic identity; γ = 0 is the exact
  isotropic tensor with the trace preserved.
- **γ = 1:** bit-exact passthrough (measured 0.0 in the tier-1 mirror; asserted again
  on the GPU in the bench file).

It is the tensor-space analog of a contrast dial applied to the anisotropy axis rather
than the luminance axis. Every downstream renderer's character shifts with it (`f_tf_glyph`
marks snap toward needles, `f_tf_aniso_blur` kernels stretch, `f_tf_hatch` strokes commit).

**The relax branch is never a negative gap.** A literal negative γ would swap the
eigenvalues and silently rotate every axis by 90°; `g = max(γ, 0)` plus the isotropic
mix is the correct form (plan ADR-2; guarded forever by mirror tests T006/T009a).

## Signal Flow

```
in0 (raw tensor, f_tf_tensormap outlet 0) -> routepass -> sharpen_pix in0
sharpen_pix out0 -> outlet 0
```

Single pass, stateless, per-pixel, no neighborhood reads. One `@type float32` codebox:
decode → component-space gap scale (`g = max(γ,0)` mix) → floor gate → re-encode
(clamps only in the final stage). **No `atan2` anywhere** — the decode idiom
(`.specify/f_tf_glyph/plan.md` ADR-2, copied into the codebox with a citation) works on
the raw components in closed form and the axis rides through in component space, which
sidesteps the ±π branch-cut class entirely.

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `sharpen` | 0–4 (linear, one-sided, provisional) | 1.0 | The gap multiplier γ. 1 = neutral; <1 relaxes toward isotropy; >1 exaggerates. Dial mapping is a live-judgment gate (spec OQ1): the alternative is bipolar −2/+2 mapped through the same math, or a log curve around 1. |
| `bypass` | 0/1 | 0 | Exact passthrough (codebox `bypass_gate`, not the native @bypass). |

**No `floor` dial** (plan ADR-3): the trace floor below which the operator passes the
pixel through untouched is a fixed internal `eps_trace = 1e-6`, the tensormap T019
convention. "Flat regions pass through unchanged by design." A floor dial is a recorded
v2 option if performers reach for it in tier 3.

**Prefix:** `sharpen` — **Object name:** `sharpen_pix` — **Type:** `@type float32`

`sharpen` does not need width/height params: there are no neighborhood taps, so the
texel-step problem tensormap solved never arises here. This is the smallest definition in
the family — single node, one inlet, one outlet.

## Outlets

| Outlet | R | G | B | A |
|---|---|---|---|---|
| 0 raw tensor (gap-scaled) | Jxx′·strength | Jxy′·strength·0.5 + 0.5 | Jyy′·strength | 1 |

Raw in, raw out, same encoding as the input (`docs/f-reference/f_tensor_type.md`
outlet 0): consumers downstream need no special handling when `f_tf_sharpen` is inserted
or removed mid-chain at γ = 1. Unconnected inlet (`vs_black`, all zeros) is a **fixed
point**: trace 0 hits the floor at every γ, so output = input exactly.

## Linear range and clamping

The operator is linear in the components; the outlet-0 encoding clamps R/B to [0,1].
Where γ·coherence > 1 the linear result pushes λ1′ above 1 or λ2′ below 0 and the encode
clamp saturates (mirror `tests/modules/tf_sharpen/test_tf_sharpen.py::test_encode_clamp_beyond_linear_range`).
Inside the linear range the trace is preserved to float32 tolerance
(measured: worst 1.2e-7 over γ ∈ {0, 0.25, 0.5, 1, 2, 4}) and the axis (cos 2θ, sin 2θ)
is unchanged (worst 1.2e-6 pre-clamp). Whether extreme-γ saturation matters is a
tier-3 judgment item.

## The strength/floor caveat

The floor is an **absolute threshold in encoded units** (post-strength). The effective
pre-gain floor is `eps_trace / strength`:

| tensormap `strength` | effective pre-gain floor |
|---|---|
| 1 | trace 1e-6 |
| 100 (default) | trace 1e-8 |
| 1000 | trace 1e-9 |

So dialing tensormap's `strength` up moves pixels *out of* the floor and into sharpen's
gamma range. Away from the floor the operator commutes with a uniform scale
(measured 2.9e-7 relative at scale factors 1/10/1000 — the glyph-idiom gain-free
identity holds); **only the floor gate breaks the commutation**, and that is by design
(measured: the exact analytic break `k·|γ−1|·trace/2` on a sub-floor tensor scaled ×1000).
If a rig's flat regions start showing gamma-scaled noise, lower tensormap `strength`
before reaching for anything else.

## Typical use

```
jit.gl.bfg -> f_tf_tensormap (outlet 0) -> f_tf_smooth -> f_tf_sharpen -> f_tf_glyph
```

One dial moves the whole rig's commitment: sharpen feeds the family renderers on chain A
(smooth before sharpen — sharpening smooths, not raw, per the triage's flicker argument;
live confirmation pending). Insert/remove-at-γ=1 is free: raw in, raw out.

## Notes

- Tier-1 NumPy mirror: `tests/modules/tf_sharpen/test_tf_sharpen.py` (15/15 pass, 2026-10-17; ground truth
  `np.linalg.eigh`, labeled-Rayleigh no-swap check, two mutation checks — dropped
  `max(γ,0)` and swapped gap sign — both caught). Spec/plan/tasks: `.specify/f_tf_sharpen/`.
- Spec prose sign slip (caught by the mirror's trace invariance test, 2026-10-17): the
  spec's original `λ2' = trace/2 − gap·(λ2 − trace/2)` collapses λ1′==λ2′ for every γ≠1
  and breaks trace preservation. The trace-preserving form is the PLUS sign for both
  eigenvalues (as above). Corrected in the codebox/mirror/docs; spec text fixed via
  `.specify/f_tf_sharpen/REGISTRATION_NOTES.md`.
- Tier-2 bench file exists (`tests/modules/tf_sharpen/bench_tf_sharpen.py`, registered in benchdeps per
  T014) — **not yet executed**; needs the live bench (owner-gated, ask before running).
- The obvious no-swap test is vacuous: `np.linalg.eigh` sorts, so it can never see a
  swap. The mirror checks labeled Rayleigh quotients along the input's major axis —
  note for anyone extending the tests.
- The name is provisional (spec OQ4): `f_tf_sharpen` collides with image-sharpening
  vocabulary. Renaming is one find-replace across definition.py/codebox/docs before
  live shipping (gate open, tasks T017).
- Decode idiom citation: `.specify/f_tf_glyph/plan.md` ADR-2. Consumers of sharpen's
  output keep that idiom's θ+180° symmetry caveat in mind; sharpen itself never
  reconstructs an angle.

## References

- Frangi et al. (1998). "Multiscale vessel enhancement filtering." MICCAI. The
  eigenvalue-ratio stability logic behind the floor gate.
- The isotropic-mix form of the relax branch follows the glyph plan's strength-cancellation
  identity (`.specify/f_tf_glyph/plan.md` ADR-2); the eigengap operator itself is this
  library's own (audit `ideas/f_tf_research.md` §4: eigen-gap operators are open ground).