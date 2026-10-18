# Implementation Plan: f_tf_aniso_blur

_Date: 2026-10-17_
_Spec: .specify/f_tf_aniso_blur/spec.md_
_Triage: ideas/f_tf_triage.md (build order 4; per-consumer decode confirmed)_
_Brief: ideas/f_tf_build_brief.md (§4 strategy row 12)_
_Research: ideas/f_tf_expressive_consumers.md (prior art, Chain A)_
_Audit: ideas/f_tf_jitfx_audit.md (§2.1, §3: open ground; cf.directional analysis)_

---

## Summary

`f_tf_aniso_blur` is a **single-pass, two-texture consumer**: decode the raw
structure tensor per-pixel (tensormap outlet 0), build an elliptical kernel
from the eigenvalues, accumulate weighted source samples along the local
edge axis, fall back to isotropic blur where the field has no direction.
One outlet: the smoothed source, `@type float32`, unclamped.

```
in0 (tensormap out0, raw tensor) ─┐
                                  ├─> aniso_pix codebox (decode → eigen → kernel → accumulate)
in1 (source texture + control)  ──┘
                                  └─> outlet 0 (smoothed source)
```

The shape the tensormap plan was four-stage pix_chain because a producer
needs multiple smoothing passes. This module needs none: one codebox, two
texture reads per tap. The risk is correspondingly concentrated: the kernel
shape itself (ADR-2, the plan's central decision gate), the statement budget
under ~450 lines (`skills/jit-gen-codebox`) fighting the tap count, and the
strength-coupling story the decode inherits from tensormap's gain.

Unlike the tensormap, a NumPy spike already exists for the family idiom
(its mirror `tests/test_tf_tensormap.py` verified the eigen decode forms);
the new math here is the kernel and its gating, which the tier-1 mirror owns.

## Technical Context

**Environment:** Max 9, Vsynth, `jit.gl.pix` gen codeboxes, `@type float32`
throughout. `dim` reads 1 inside live Vsynth jit.gl.pix (tensormap T012 live
finding), so any pixel-unit tap spacing needs an exposed `width`/`height`
param pair, same as tensormap — or normalized-UV taps dimensioned against
those params.
**Build method:** NumPy mirror (tier 1) → codeboxes on the bench (tier 2) →
scratch patch (tier 3) → `src/f_tf_aniso_blur/definition.py` →
`build/build_patcher.py`.
**Output:** `package/patchers/f_tf_aniso_blur.maxpat`.
**GPU budget:** M3 Max costs measured here say so; M1 unmeasured
(ways-of-working), same caveat as the tensormap plan.
**Decode idiom:** `.specify/f_tf_glyph/plan.md`, ADR-2 ("The canonical decode
idiom lives HERE, in this file") — the fenced GenExpr block with decode
lines, gain-free identities, θ+180° caveat, axisflow pointer; its tasks.md
TG003 finalizes it before Phase 1. This plan cites it rather than re-derives;
any divergence found in Phase 1 goes back to the idiom owner. The prose
anchor is glyph's own spec §Field Architecture.
**Per-tap texture sampling must clamp to texel centres in-shader** (bench
GPU wraps out-of-range reads; `docs/f-reference/f_tf_tensormap.md` Notes,
tensormap ADR-5). For a kernel that samples up to ~16 px from the center this
is not a border nicety: the clamp is on *every* tap, via the same
`clamp(uv + offset, texel, one_minus_texel)` idiom the tensormap codeboxes
use.

## Files

```
.specify/f_tf_aniso_blur/
  spec.md             done
  plan.md             this file
  tasks.md            next to this file
  codebox_aniso.gen   Phase 1 (single stage, unless ADR-2 picks the ellipse
                      grid and cost forces a two-stage split; name follows
                      the stage convention then)

src/f_tf_aniso_blur/
  definition.py       Phase 3 (src/<name>/ is where codeboxes live per the
                      f_vf_optical_flow layout; tensormap T028 read precedent)

tests/
  test_tf_aniso_blur.py    tier 1 NumPy mirror, kernel + fallback + guards  (Phase 0)
  bench_tf_aniso_blur.py   tier 2, real codebox on the GPU                 (Phase 1)

~/Vsynth/patterns/ (not in repo)
  tf_aniso_blur_scratch.maxpat   tier 3 judgement                          (Phase 2)

docs/f-reference/
  f_tf_aniso_blur.md  as-built reference                                   (Phase 5)
```

## Architecture Decisions

### ADR-1: Single codebox, two texture inlets; no pix_chain in v1

**Context:** The tensormap needed four stages because a structure tensor
requires a window sum (separable). This module's per-pixel work is: decode
(6 closed-form expressions), gate computation (a few), and an accumulation
loop over ≤ TAPS_MAX taps, each tap one texture sample of in1 plus the
center tensor read. No window sum anywhere.

**Decision:** One codebox (`aniso_pix`), one outlet, no intermediate
textures. Inlet 0 = tensor, inlet 1 = source, both consumed in the same pass.

**Rationale:** The statement-budget ceiling (~450 lines,
`skills/jit-gen-codebox`) is the binding constraint and a single codebox
spends it all on taps rather than on stage plumbing. If ADR-2's cost
analysis forces more taps than fit, the fallback is a two-stage split
(precompute the gate fields in stage 1, sample and accumulate in stage 2) —
a cost-driven contingency, decided by the bench, not pre-built.

**Consequences:** Bypass lives in this one codebox (`param bypass` →
passthrough of inlet 1). The unconnected-inlet-0 behavior (SPD guard →
isotropic fallback) also lives here. Both become benchmarkable facts of
exactly one file.

### ADR-2: Kernel shape — fixed-tap line integration vs ellipse-grid (DECISION GATE, not decided here)

**Context:** Two kernel families were discussed for the ellipse
specification. Both are legal under the spec's constraints (positive
sum-normalized weights, compile-time tap bound, per-tap gating).

**Family (a) — fixed-tap line integration with per-tap transverse offset.**
The `cf.directional` shape, made tensor-driven. A bounded 1D loop (or fully
unrolled fixed taps for small TAPS_MAX) of N_taps samples along the decoded
axis v (and its negation — bilateral), each tap at
`uv + (i·Δ)·v ± (w_i)·v_perp`, i.e. each tap carries its own transverse
offset toward the ellipse's width at that station. Elliptical weighting comes
from choosing the tap positions/weights as the ellipse's discrete
approximation up front — e.g. taps on the ellipse perimeter or a
Gauss-in-both-directions separable approximation collapsed to one loop.
- Cost: N_taps samples; if unrolled (no loop), zero loop overhead and trivial
  compile; if a bounded loop, one loop. At TAPS_MAX = 16, well under the
  statement ceiling.
- The `cf.directional` audit precedent (`ideas/f_tf_jitfx_audit.md` §2.1:
  3-tap tri-weight `0.294 center, 0.353±offset`) is exactly this family with
  N=3, uniform direction, no gating — confirming it compiles, runs at video
  rate, and has the artifact character (visible tap structure at low N per
  the audit).
- Isotropic fallback: set the axis rotation aside (kernel becomes the same
  tap set unrotated) — the fallback is *cheap* and *exact*, and the tier-1
  mirror can verify it bit-for-bit.
- Weakness: the ellipse is only sampled where taps are placed; a coarse tap
  set is a dotted approximation of the ellipse, visible as banding on smooth
  content (cf.directional's own artifact).

**Family (b) — ellipse-grid kernel, bounded 2D loop.**
A `for u in -U..U, for t in -T..T` grid of taps in the ellipse's local
frame, each tap weighted by the analytic ellipse/Gaussian weight
`exp(-(u²/L² + t²/D²))` evaluated per tap, with per-tap gating by the live
knobs. This is the tensormap ADR-3 shape (bounded loop to a compile-time
max, live weight gating) generalized from 1D to 2D.
- Cost: U·T taps, quadratic in the radii. To match a `length` = 4 pixel
  semi-axis with a comparable transverse resolution needs roughly 9×7 grid ≈
  60+ samples per pixel — 4× family (a) at comparable quality, and at
  TAPS_MAX = 16 the ellipse is coarsely discretized in the transverse
  direction. Quadratic cost grows fast with `length`'s range top.
- Strength: the *weight field* is continuous — no banding, the "correct"
  anisotropic-Gaussian look, the same kernel Weickert's closed-form
  simplification assumes. Tapping a grid of an analytic Gaussian is what the
  strategy doc's row-12 sketch ("kernel ellipse from the eigenvalues") most
  directly describes.

**Decision:** NOT picked in this plan. This is Phase 0's first blocking
gate (T002 in tasks.md), resolved by a NumPy cost + artifact spike (tier 1
mirror of both families side by side on the same synthetic edge) and a bench
compile/cost probe of both codeboxes (tier 2), then Matt's call. The spec
stays silent (its Out of Scope item 2); both families are specified as
mirror functions so the spike compares implementations, not descriptions.

**Constraints binding both families regardless:** TAPS_MAX is a compile-time
constant (provisional 16, from the tensormap ADR-3 precedent and the
statement-budget arithmetic: ~10 statements/tap × 16 ≈ 160, comfortably
under 450); tap weights are gated by the live knobs via
`step()`/multiplier (cost scales with TAPS_MAX, not the dial — the tensormap
fact worth repeating to Matt in this module's docs); coordinates clamped to
texel centres in-shader; floats unclamped until the (absent) final encode.

### ADR-3: The gate model — trace-gated energy, coherence-gated shape

**Context:** The spec's knob set maps two tensor-derived quantities to two
kernel properties:
- kernel semi-length L (along-edge extent) from absolute eigenvalue energy:
  W = min(1, λ1·strength_scale), L = length·W;
- kernel semi-width D (transverse extent) from coherence:
  w = max(floor, coherence·width_gate), D = L·(1 − w) bounded to
  [D_MIN, L].

**Decision:** Implement exactly this two-channel gate in the mirror and the
codebox; both gates are pure arithmetic on the decode outputs. The SPD
guard (λ2 ≤ 0 impossible after closed-form solve → treat as isotropic) is
part of this ADR because it is one more gate, not a separate mechanism.

**Rationale:** This is the model the spec's acceptance criteria are written
against (isotropic-exactness at `width_gate` 0 or `floor` 1; identity at
`length` 0), and the model Weickert's fallback logic corresponds to
(diffusion speeds anisotropic along structure, isotropic elsewhere). The
alternative "gate everything through one coherence knob" was rejected at
spec level because absolute energy ("no blur where there is no structure")
is a property ratios cannot express, and it is the failure-mode guard for
the tensormap-strength-coupling problem (spec OQ3) — measured, not guessed.

**Consequences:** The tensormap-strength echo problem (spec OQ3) is now a
concrete implementation question: the mirror must parameterize both
`strength` (tensormap's) and `strength_scale` (this module's) so tier 1 can
measure the coupling; tier 3 then either locks a documented pairing (the
spec's lean) or Matt overrides toward ratio gating.

### ADR-4: Straight-axis kernel in v1; curved integration is a recorded open question

**Context:** The brief flags curved contours as the module's medium risk
("step-by-step continuity-based sign choice to avoid a seam",
`ideas/f_tf_build_brief.md` §4).

**Decision:** v1 samples strictly along the local axis through the center
pixel — no per-step re-orientation, no curvature following. The open
question (step-sign continuity choice for curved integration) is documented
in the spec (OQ6) and restated in this plan's "Out of this plan"; it is not
a v2 promise, it is an unspecced design question with its own spike when (if)
ever reopened.

**Rationale:** The straight-axis kernel is *exactly* the building block any
future curved version needs (a curved integrator is a sequence of straight
segments with a sign-continuity policy between them); building the straight
one first loses nothing. Specifying curvature now would reopen the kernel-
shape decision under a harder constraint for no confirmed need.

**Consequences:** Curved corners get slightly *cut* on real content rather
than smoothed around. Tier-3 judgement includes looking at exactly this
artifact and recording whether it is acceptable on real material — that is
the evidence that decides whether the curved question ever reopens.

### ADR-5: Verification tiers

**Decision (recorded as the Phase 0 gate, T001):**
- **Tier 1 (NumPy mirror) applies.** The line-integral kernel including the
  isotropic fallback has independent ground truth: brute-force weighted-sum
  reference in NumPy, analytic constant/ramp/synthetic-tensor inputs,
  convex-hull invariant, exact isotropic-reference equality in the fallback
  regime. The eigen decode forms are already verified in the tensormap
  mirror; the *kernel* is what is new here, and it is pure arithmetic on
  decoded values — ideal mirror territory.
- **Tier 2 (bench) applies.** One real codebox to compile; the statement
  budget is a compile-time fact to measure, not assume; cost at 1080p/4K on
  M3 Max (M1 unmeasured) is an open question for the ADR-2 gate; the texel-
  centre clamp behavior vs the bench's wrap must be verified, not argued
  (tensormap ADR-5 precedent).
- **Tier 3 (scratch patch) applies.** `strength_scale`, `length`,
  `width_gate`, `floor` defaults on real content; the curved-corner-cut
  artifact (ADR-4); whether the anisotropic look separates from isotropic
  cleanly at the `floor` boundary.

**Consequence:** Test discipline per ways-of-working: one affected test at a
time, `tests/bg.sh`, `-q`, ask before any bench run, never rerun the bench
to re-verify a change.

### ADR-6 (2026-10-17, post-bench): every texture read uses the four-tap nearest() idiom

**Context:** the bench verified parity at 64×64, but glyph's live finding
(family rule 6b) showed `sample()` silently drops to nearest when its
coordinate is data-dependent and jumps between neighbouring pixels. This
module's centre tap and every kernel tap read at **cell-coherent**
coordinates — constant within a cell (length/width texels apart), teleporting
at the 1-px cell-boundary bands. The 64×64 bench green was boundary-fraction
luck, not safety: a 97×64 spot-check measured the fallback live.

**Decision:** all reads of `in2` (centre tap and in-loop taps) use the
four-tap `nearest()` hand-bilinear idiom (`skills/jit-gen-codebox`).
Coordinates derived in texel space, taps at normalized texel centres, weights
(1−ax)(1−ay)...-form; the loop's taps read straight-line four terms (no
nested loop). Cost: 4× the reads per tap; the recorded per-pass floor was
~0.2 ms (E-class) — the 49-tap kernel now runs ~196 reads/pixel, still far
inside budget (bench 6/6 green post-refactor, 97×64 spot-check 4.4e-6).
The `t`/`tr_off` rename removes a shadowing collision with the tap's `t_px`
family (GenExpr hoists one namespace).

**Consequence:** the idiom is now mandatory family-wide for lattice reads;
doc record in `f_tensor_type.md` rule 6's refactor note.

## Dependency Blocks

### Block 1: Kernel math settled in NumPy, both families
**Dependencies:** none (the decode idiom is cited, not re-derived; the glyph
ADR-2 citation is read-only).
**Builds:** `tests/test_tf_aniso_blur.py` — decode+eigen reuse, both kernel
families as mirror functions, the gate model (ADR-3), the isotropic fallback
and SPD guard, brute-force weighted-sum reference, analytic synthetic-tensor
inputs.
**Verification:** matches the brute-force reference; isotropic-fallback
equality; convex-hull invariant; identity cases (`length` 0, `width_gate` 0,
`floor` 1); vs_black and bypass-neutral tensor inputs take the guard path;
one mutation check.

### Block 2: Codebox on the bench; kernel-shape gate resolved
**Dependencies:** Block 1.
**Builds:** both candidate codeboxes (`codebox_aniso_line.gen`,
`codebox_aniso_grid.gen`) if the gate needs a live cost comparison, or the
one chosen codebox if the NumPy spike is decisive; `tests/bench_tf_aniso_blur.py`.
**Verification:** compiles under the statement budget; matches the tier-1
mirror on the GPU per channel; texel-clamp border behavior confirmed;
per-family cost measured at 1080p and 4K (M1 caveat); ADR-2 decision
recorded with the numbers.

### Block 3: Judgement on real content
**Dependencies:** Block 2.
**Builds:** scratch patch only.
**Verification:** the four defaults on bfg Perlin/Voronoi/fbm and a live
video source; isotropic↔anisotropic boundary invisible at the chosen
`floor`; curved-corner-cut artifact assessed (ADR-4); tensormap-strength
pairing sanity (ADR-3 consequence).

### Block 4: Patcher
**Dependencies:** Block 3; ADR-2 resolved.
**Builds:** `src/f_tf_aniso_blur/definition.py`, generated `.maxpat`,
modules-menu registration.
**Verification:** loads in Vsynth; params addressable; outlet renders;
unconnected tensor (guard → isotropic fallback), unconnected source (black),
bypass (passthrough) all confirmed; drift-clean; contract tests green.

### Block 5: Docs and handoff
**Dependencies:** Block 4.
**Builds:** `docs/f-reference/f_tf_aniso_blur.md`; README/constitution/
module-inventory rows; hub doc (`ideas/f_tensorfield.md`) planned-consumer
list updated; HANDOFF.
**Verification:** helpfile preflight; the strength-pairing note lands in
both tensormap's and this module's docs (one explanation, cross-linked, per
the glyph plan's no-two-explanations rule).

## Implementation Phases

### Phase 0: Tier gate + mirror of both kernel families (BLOCKING)
Record the tier gate (ADR-5), mirror the decode (citing glyph's idiom) and
both kernel families with the ADR-3 gate model and the guards. Exit: mirror
matches the brute-force reference and every acceptance-criterion invariant
in the spec; mutation check caught.

### Phase 1: Codebox(es) on the bench (BLOCKING)
Compile and parity-test the candidate kernel codeboxes against the mirror;
measure cost; resolve ADR-2 with numbers. Exit: chosen kernel matches its
mirror including borders; cost recorded; ADR-2 decided and recorded in this
plan as an addendum below.

> **ADR-2 addendum (Phase 1 records the decision here):**
> RESOLVED PROVISIONAL-OPEN, recorded 2026-10-17 by the owner (build
> directive: no bench run in this build — the cost experiment cannot run;
> Matt's call stays open).
>
> **Chosen: family (a), fixed-tap straight-axis line integration with
> per-tap transverse offset** — the `cf.directional` audit shape made
> tensor-driven. Geometry as built (T005): centre tap + 8 half-integer 1 px
> stations per side (u = ±0.5..±7.5), station along-mass g(u) = exp(−2u²/L²)
> (mid-point quadrature of the continuous Gaussian: 1e-4 relative vs its own
> integral — the 1-px lattice IS the converged kernel), each station three
> transverse taps (t = 0, ±D/2 px) at the discrete-Gaussian rule (1/4, 1/2,
> 1/4). 49 samples = TAPS_MAX; bounded loop, weights gated per tap
> (tensormap ADR-3); coordinates clamped to texel centres in-shader on
> every tap (ADR-5).
>
> **Mirror-side cost model vs the tensormap bench floor** (~0.9 ms/pass at
> 1080p R_MAX 16, `docs/f-reference/f_tf_tensormap.md`): the kernel loop is
> 48 samples of one texture + 1 centre + 1 tensor `nearest` read — the same
> order as tensormap's 16-tap stage B loop (33 samples), so the model
> predicts a single pass in the same ~0.9 ms/pass class at 1080p, well
> under the statement budget (the shipped codebox is ~77 statements vs the
> ~450 ceiling). At 4K the same ~4× linear scaling as tensormap's stages
> (~3.4 ms/pass → 49-tap ≈ 4 ms class). PROVISIONAL: these are model
> numbers derived from the loop structure, not measurements.
>
> **Artifact data (tier 1, both families as mirrors, same edge, matched
> budgets, against the continuous area Gaussian):** family (a) 49-tap
> mean abs 0.0362; family (b) 5×5 grid mean abs 0.0300; the densified
> (129-tap) family (a) reference closes to 1.1e-2 max/3e-4 mean relative to
> the delivered 49-tap kernel — the delivered kernel's own discretization
> datum, banding data in `tests/test_tf_aniso_blur.py`
> (test_adr2_family_b_ellipse_grid_reference). Family (a)'s transverse
> weights are continuous (3-point rule), not dotted: the banding magnitude
> is in the 0.03 mean-abs class on unit-contrast noise, not cf.directional's
> 3-tap structure.
>
> **The experiment that closes the gate:** T013/T014 on the bench
> (`tests/bench_tf_aniso_blur.py`, written, not run) — compile both
> codeboxes, parity each against its mirror including borders, measure
> `bc.measure` at 1080p and 4K across the `length` range (M1 unmeasured —
> say so), then compare against family (b)'s cost at matched tap count and
> against the tensormap floor. Decision: the cheaper family unless the
> artifact report favors the other; the shipped file stays family (a)
> until then.

### Phase 2: Scratch patch, judgement tier
Defaults, floor-boundary look, corner-cut artifact, strength pairing. Exit:
provisional parameter table replaced with live values, or the spec says why
they did not.

### Phase 3: definition.py and build
Follow the f_vf_optical_flow/f_tf_tensormap precedents for a one-outlet
two-texture module (the two-texture precedent is `f_vf_optical_flow`'s
previous-frame pair; tensormap T028's read covers the wiring pattern).
Exit: loads in Vsynth, unconnected/bypass behaviors per spec, drift-clean,
contract tests green.

### Phase 4: Integration check in Chain A
Wire the canonical chain `f_tf_tensormap → f_tf_aniso_blur` (both inlets
hand-fed the same structure source = denoise mode), and the expressive
version (tensormap on in0, a *different* texture on in1) in the scratch
context. Exit: both modes render; the kernel visibly follows the tensor
field (rotating the structure source rotates the blur direction).

### Phase 5: Docs and handoff
Reference doc, README/constitution/inventory rows, hub update, HANDOFF. Exit:
Chain A's renderer slot documented; the strength-pairing explanation
cross-linked with tensormap's docs.

## Out of this plan

- Curved-axis integration (spec OQ6 / plan ADR-4): recorded open question,
  its own spike if ever reopened; not a v2 placeholder in any task list.
- `f_tf_smooth`/`f_tf_sharpen` (built separately, earlier in build order);
  this module only consumes their outputs when present.
- `f_tf_mix`, `f_tf_hatch` (later build order), `f_tf_glow` (merged into Q12
  per triage review outcome 1 — no tensor-in glow inlets invented here).
- Mod inlets on any param.
- A tensormap v2 (gain-on-outlet, third eigen outlet): tensormap's roadmap
  (spec OQ3); this module works against outlet 0 as-is.