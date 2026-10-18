# Spec: f_tf_sharpen

_Created: 2026-10-17_
_Status: Draft_

_Promoted from `ideas/f_tf_build_brief.md` §4 ("f_tf_sharpen — the single most leveraged
performer gesture in the whole family") and `ideas/f_tf_triage.md` (verdict: build, after
`f_tf_smooth`, review confirmed 2026-10-17)._

---

## What it does

An eigengap exaggerator/relaxer. Decodes the incoming raw tensor to its eigenvalues and
axis, scales the gap between the two eigenvalues while holding trace fixed, re-encodes:

```
λ1' = trace/2 + gap·(λ1 − trace/2)
λ2' = trace/2 + gap·(λ2 − trace/2)      gap ≥ 0 (one-sided here; see One-sided vs bipolar)
θ'  = θ                                  (axis rides through untouched)
```

*(Correction 2026-10-17: the original prose wrote a MINUS on the λ2' line; that form
collapses λ1'==λ2' for every γ≠1 and breaks trace preservation — caught by the tier-1
mirror's trace-invariance test, tasks T003. The trace-preserving relax form is the same
PLUS sign for both eigenvalues.)*

- gap > 1: anisotropy exaggerated — hesitant edges commit toward line-like tensors.
- gap < 1: the field relaxes toward the isotropic identity — everything softens toward
  the trace ball.
- gap = 1: exact passthrough (neutral).

This is the tensor-space analog of a contrast dial on an image, applied to the anisotropy
axis rather than the luminance axis. Every downstream renderer's character shifts with
it (`f_tf_glyph` marks snap toward needles, `f_tf_aniso_blur` kernels stretch, `f_tf_hatch`
strokes commit) — the brief's "most leveraged gesture" claim.

**Named `sharpen` here per the brief's catalog; naming is an open question below** —
`sharpen` collides with image-sharpening vocabulary (`jit.fx.cf.sharpen`, source-read in
the audit, is unrelated edge-enhancement), while this module's semantics are anisotropy
gain. Renaming is cheap before definition.py exists (T032 gate) and expensive after.

## Tensor-native test (explicit)

Collapse to a scalar and the operator does nothing to defend: a scalar-coherence boost
(`A' = f(A)`) can exaggerate the *confidence number*, but the ellipse stays the same —
glyphs would render thin confidence as fat ellipses. Collapse to a vecfield: an axis-angle
can be doubled, but there is no "gap" to scale — a vecfield's magnitude scaling moves both
eigenvalues together (isotropic), which is exactly the mush this module refuses to create.
The eigengap *is* λ2 participating; without it, no.

## jitfx-audit note

`ideas/f_tf_jitfx_audit.md` §3: nothing shipped does anything in this territory
("eigen-gap operators unheard of"; cf.sharpen is image sharpening, unrelated semantics).
No don't-claim-novelty caveat applies to this module (unlike smooth/mix).

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | tensor (required) + control | — | Raw tensor from `f_tf_tensormap` outlet 0 (or from `f_tf_smooth` outlet 0 in chain A order). |

No second inlet in v1. Sharpen-of-a-target is meaningless — the operation is per-pixel,
context-free.

## Outlets

| Outlet | Content | Channels |
|---|---|---|
| 0 | Gap-scaled raw tensor, float32 | Same f_tensor raw out0 encoding as the input. |

Pass-through of format (raw → raw); consumers downstream need no special handling when
sharpen is inserted or removed mid-chain at gap 1.

**Decode idiom: canonical copy, not this file's.** The family's canonical per-consumer
decode idiom lives in `.specify/f_tf_glyph/plan.md` ADR-2 (recorded 2026-10-17; cited by
every consumer plan after glyph). This module copies it when Phase 1 writes the codebox —
note glyph's idiom does the whole job **without atan2** (closed-form eigen on the raw
components; the axis rides through unchanged), which makes sharpen's axis-invariance
acceptance row trivially true by construction. No independent decode sketch is kept here.

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `sharpen` | live.dial | 0–4 (provisional; see OQ1) | 1.0 | The gap multiplier γ (see math above). **One-sided or bipolar?** (Open Question 2.) One-sided 0–4: 1 = neutral, <1 relaxes (identity-mix), >1 exaggerates. Bipolar −2/+2: dial centers at 0, direction is a sign convention (− = relax, + = exaggerate) — but the actual math for γ<1 is *not* "negative γ", it's identity-mix, so a bipolar dial maps 0..-1 → identity-mix (1→0), 0..+1 → γ scaling (1→∞). The dial-mapping choice is a Phase 0 decision gate. |
| `floor` | live.dial | 0–1 | 0 (off?) | Trace gate below which γ is forced to 1. Protects flat/noisy pixels from invented structure (coherence noise amplified by γ is the known failure; the Frangi eigenvalue-ratio floor in `f_tf_expressive_consumers.md`). Whether this ships as a param or a fixed internal epsilon is an open question (OQ3) — one more dial is UI cost (paused `mod_depth_ui_density.md`). |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Standard bypass. |

## Signal Flow

Single pass, stateless, one codebox:

```
in0 (tensor + control) -> routepass -> sharpen_pix in0
sharpen_pix out0 -> outlet 0
```

Per-pixel: decode out0 channels → Jxx/Jxy/Jyy → λ1/λ2 closed-form → scale gap with floor
gate → re-encode R/G/B. The decode block is copied verbatim from
`.specify/f_tf_glyph/plan.md` ADR-2 (see above).

## Acceptance Criteria

Numbers first. Tier 1 applies (eigen algebra has `np.linalg.eigh` ground truth); tier 2
applies (decode/re-encode round-trip on GPU); tier 3 applies (dial feel, floor behavior).

- **Neutral at γ=1:** out = in, bit-exact expected (the pipeline is decode → gap=1 →
  re-encode; re-encoding after untouched eigen-decompose should round-trip within float32
  tolerance — measure and record the actual round-trip error).
- **Exaggerate:** known tensor with coherence 0.5 at γ=2 gives coherence' = 1.0 exactly
  (the gap doubles, trace fixed, axis unchanged); glyph/axis reads identical.
- **Relax:** same tensor, mapped through the identity-mix branch to γ=0, gives an isotropic
  tensor (R'=B', G'=0.5): axis neutral at exactly (0.5, 0.5), trace preserved.
- **Trace invariance:** trace' = trace for all γ (first-order float32 tolerance).
- **Axis invariance:** the decoded axis angle is unchanged by any γ, including γ=0 (the
  isotropic endpoint outputs the neutral axis by the eps_trace rule, matching tensormap's
  own degenerate-pixel convention).
- **Floor:** with floor=ε, γ applies only above ε trace; below it output = input exactly.
- **Bypass:** exact passthrough.
- **Unconnected inlet:** vs_black decodes to garbage axes (c2=s2=−1 territory in packed
  terms, and to a zero raw tensor in out0 terms): confirm the zero tensor gives neutral
  output (trace 0 → all γ outputs identical to input at the eps_trace floor) — the zero
  tensor is already a fixed point; verify.
- **Loads in Vsynth** and renders in `vs_render`.

## Out of Scope (v1)

- **Any spatial operation.** This module never reads a neighborhood; it is per-pixel at
  exactly one pixel.
- **Anisotropy remap curves beyond linear gap scaling** — if the dial wants a curve
  (log-scale around 1, as the expressive-consumers doc spec'd "log-scaled around 1"),
  that is a Phase 0/T031 dial-mapping decision, not new math.
- **Directional rotation / twist operators.** Rotating a tensor field is a *different*
  operator (mix of axis + rotation); keep this module gap-only. If a rig wants twist, it
  is a separate idea, not this module — flag to the brief's OQ7 follow-up only if a chain
  demands it.
- **Per-pixel γ mod inlet.** Same mod-UI question as every module; follows the parked
  Q12/`mod_depth_ui_density.md` conventions. Not v1.

## Open Questions

1. **Dial mapping: one-sided vs bipolar.** One knob, center-of-dial at 1 vs center at 0 —
   the family has no precedent for a center-anchored dial; tensormap `strength` is log
   1–1000; `f_droste` zoom is bipolar-ish. Decision needed in Phase 3 before definition.py
   (dial exponent / range), after tier-3 feel.
2. **The relax branch: identity-mix vs literal negative gap.** γ<1 as literal scaling
   produces λ2' *above* λ1' (eigenvalue swap = axis rotation by 90°!) if γ < 0 — the
   correct relax form is `λ' = trace/2 + (λ − trace/2)·max(γ, 0)` plus isotropic remainder
   `trace/2·(1−max(γ,0))`. Encode whichever the dial mapping picks; the acceptance rows
   above assume no axis-flip ever occurs. **This is a math correctness item, not taste** —
   the NumPy mirror encodes the exact chosen form.
3. **`floor`: param or fixed epsilon?** Fixed internal eps_trace (tensormap precedent)
   = zero new UI; param = performer control over how deep the floor bites. UI cost
   (one more live.dial) vs expressive value. Decision gate at Phase 3.
4. **Name.** `f_tf_sharpen` per the brief; alternative `f_tf_eigengap` / `f_tf_aniso`
   say what they mean without the image-sharpening collision. Cheap to rename now,
   expensive later (constitution naming table, modules menu, helpfiles). Decision gate
   before definition.py (T033).

## Clarifications

- Q: Does sharpen touch the axis? -> A: Never (θ' = θ; acceptance row).
- Q: Does sharpen touch coherence? -> A: Implied by the gap; coherence' = (λ1'−λ2')/trace,
  computed by whoever decodes next; no separate handling.
- Q: What about tensormap outlet 1 (packed) input? -> A: Out of scope v1 — raw out0 only.
  Taking packed in would double the encode/decode work and split the module's identity
  between two contracts; raw-only keeps the family rule "packed is tensormap's job".

---

## Sources (precedents cited)

- `ideas/f_tf_build_brief.md` §4 (`f_tf_sharpen` entry) — promotion + "most leveraged"
  claim; §5 chain A position (after smooth, before renderers).
- `ideas/f_tf_triage.md` — verdict; build-after-smooth sequencing rationale (sharpening
  amplifies flicker).
- `ideas/f_tf_jitfx_audit.md` §2.1/§3 — cf.sharpen unrelated-semantics note; eigen-gap
  open ground.
- `ideas/f_tf_expressive_consumers.md` §2.5 — concept origin, floor rationale (Frangi
  stability logic).
- `.specify/f_tf_tensormap/spec.md` — eps_trace convention, encode/decode contract.