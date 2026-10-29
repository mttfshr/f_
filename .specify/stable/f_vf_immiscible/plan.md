# Implementation Plan: f_vf_immiscible

_Created: 2026-10-27_
_Spec: `.specify/stable/f_vf_immiscible/spec.md` (user stories, FRs, gates and success
criteria live there; this file is HOW only)_
_Idea record: `ideas/f_vf_immiscible.md`; analysis background: `ideas/f_vf_emulsion.md`_

Everything marked [inference] is general knowledge of the method or my own
derivation, not checked against the repo or tried.

---

## Summary

A module with three inlets (a φ source texture plus control, and two velocity
vecfields, one per phase) and two outlets (φ, and the φ-blended velocity as an
`f_vecfield`). Internally it is a chain of `jit.gl.pix` stages on a fixed 256²
`float32` periodic grid, built from the pieces `f_vf_fluid`, `f_ks` and `f_wc`
already proved: an input stage that decodes and minifies the two velocities, a
real-space stage that blends them, advects φ and injects, a separable DFT pair, a
per-bin spectral stage that does the phase-separation step, the inverse pair, and
a render-resolution encode stage. The candidate phase model is a stabilised
semi-implicit Cahn–Hilliard step, with φ and φ³ carried as the two complex fields
of one DFT chain. Everything numeric is checked in a NumPy mirror (which reuses
`fluid_mirror` for stirring) and on the GPU bench before any patcher is built.

---

## Technical Context

**Stack**: Max 9, Vsynth, `jit.gl.pix` + GenExpr codeboxes (`float32`); Python 3
(NumPy) for the mirror; the Max test bench (`tests/bench*`) for GPU verification.
Built from `src/f_vf_immiscible/definition.py` with raw wiring, as `f_ks` and `f_wc`
are (not a dedicated build script as `f_vf_fluid` was).

**Reused, already verified** (cite, do not rewrite):

| Piece | From | Used for |
|---|---|---|
| Separable DFT codeboxes, generator `gen_dft.py` | `src/f_vf_fluid/gen_dft.py`; adapter pattern as `src/f_ks/gen_dft.py` (code lines asserted identical) | `fx`, `fy`, `iy`, `ix` |
| Periodic 4-tap `nearest()` bilinear read | `f_vf_fluid` `adv` (ADR-3), `tests/bench/codeboxes/seam_tap4.gen` | advecting φ; reading φ and velocities at render size |
| Force tap grid (`taps × taps` hardware taps) and content gate (`B ≈ 0.5`) | `f_vf_fluid` `adv` (T038a, ADR-2) | `inab` minification and gating |
| `hold` → `pass` loop break, reseed held three draws, salt per reset, arithmetic hash (no `sin()`) | `f_ks` | state loop and `reset` |
| Two real fields in one DFT chain (R,G and B,A as two complex fields) | `f_wc` | φ and φ³ |
| `r draw` bang as chain head, render-size encode stage with `r draw` size | `f_vf_fluid` ADR-2 | fixed 256² internals, render-size outlets |
| Param bypass gate on the encode stage, never native `@bypass` | `f_vf_fluid` ADR-8, `plan.md` 2026-10-06 | bypass |
| Periodic interpolation, grid, FFT mirrors | `tests/modules/fluid/fluid_mirror.py`, `gpu_sim.py`, `dft_mirror.py` | tier-1 mirror |

**Constraints from bench-verified facts** (`skills/jit-gen-codebox`, `f_vf_fluid`
plan): `nearest()` at texel centres for transforms; components accessed inline;
`NaN == NaN` is true on this GPU so guard with `abs(x) < 1e30`; a Param must not
share a name with a GenExpr built-in or a `jit.gl.pix` attribute (`mix`, `texture`,
`t`, `depth`, `bypass`); a codebox cannot read an input texture's size; hardware
`sample()` is nearest-like when minifying; fixed `@name`s break a second instance
(`#0_` everywhere). **The bench covers at most three inputs per codebox**
(constitution), so every stage below is kept to three; this is a design
constraint, not an accident.

**Cost budget** (estimate, unmeasured): a `f_ks`-class chain, about 2.4 ms at 256²
(`f_ks.md`; the four DFT passes are most of it), plus input minification, about
0.5–1 ms at `taps` 2–8 for two inputs (`f_vf_fluid.md`: `adv` 0.36–0.7 ms at
`taps` 8). About 3 ms for the module and about 8 ms with two Fluids. The fallback
lever is 128² (spec G6).

---

## Constitution Check

✅ **Codebox before patcher**: every stage is a `src/f_vf_immiscible/codebox_*.gen`
verified (tiers 1–2) before any JSON is built.
✅ **Numbers before eyes**: the mirror and bench precede the live look; tier 3 is
for ranges, character and cost in a real patch.
✅ **Specs before building**: `spec.md` exists.
✅ **`#0_` scoping**: required by FR-013.
✅ **One bpatcher, one concern**: the concern is "the interface between two flows";
φ and the blend are one thing, not two.
⚠️ **Ten `jit.gl.pix` stages**: more than any module so far (`f_vf_fluid` and
`f_vf_optical_flow` have eight); justified by one stage per verified step.
⚠️ **Three inlets**: whether the builder expresses them (spec experiment 5).
⚠️ **Bench limit of three inputs**: constrains stage design (below).
⚠️ **The blend rule is unproven** (G2) and **stage 2 needs an untested cycle**.

---

## Project Structure

```
src/f_vf_immiscible/
  definition.py            # params, three inlets, raw wiring (as f_ks / f_wc)
  gen_dft.py               # adapter: four DFT codeboxes (packing comment: R,G = φ̂, B,A = (φ³)^)
  gen_blend.py             # writes ONE blend block into codebox_adv.gen and codebox_enc.gen
  codebox_inab.gen         # input stage: decode, gate, minify A and B, pack (256²)
  codebox_pass.gen         # state: hold or reseed (hash inline); non-finite self-heal
  codebox_adv.gen          # blend, advect φ, inject, pack φ and φ³ (256²)
  codebox_dft_fx.gen  codebox_dft_fy.gen  codebox_dft_iy.gen  codebox_dft_ix.gen
  codebox_spec.gen         # per-bin phase-separation step
  codebox_enc.gen          # render-size encode: out0 φ, out1 blended velocity, bypass gate
tests/modules/immiscible/
  immiscible_mirror.py     # NumPy mirror of every stage and the full step
  test_immiscible.py       # tier 1
  bench_immiscible.py      # tier 2, stage by stage and host-sequenced
  bench_immiscible_module.py   # the built patcher
tests/records/
  spike_immiscible_stirring.py   # Phase 0 experiment 1 (stills to tests/logs/, gitignored)
  spike_immiscible_blend.py      # Phase 0 experiment 2
docs/f-reference/f_vf_immiscible.md     # Phase 3
package/patchers/f_vf_immiscible.maxpat # built from definition.py
package/help/f_vf_immiscible.maxhelp    # Phase 3
```

**Structure decision**: stage-per-file codeboxes (each verified independently);
`definition.py` is the single source for the patcher (the 2026-10-04 rule), with
the module's raw wiring in it.

---

## Data Model — texture packing

All solver textures are `float32` RGBA at 256 × 256.

| Texture | R | G | B | A | Notes |
|---|---|---|---|---|---|
| `inab` out (packed velocities) | uA.x | uA.y | uB.x | uB.y | decoded `(p − 0.5)·2`, tap-averaged, content-gated; zero for an invalid input |
| φ state / `pass` out | φ | 0 | 0 | 0 | |
| `adv` out (DFT input) | φ | 0 | φ³ | 0 | G, A are the DFT imaginary parts, so zero |
| Spectral (after `fx`, `fy`) | Re φ̂ | Im φ̂ | Re (φ³)^ | Im (φ³)^ | the `f_wc` two-field packing |
| `spec` out | Re φ̂′ | Im φ̂′ | 0 | 0 | second field idle on the way back |
| `ix` out | φ′ | 0 | 0 | 0 | real part, non-finite zapped (identical to Fluid's `ix`) |
| out0 (render size) | w | w | w | 1 | `w = (φ + 1)/2` (G4) |
| out1 (render size) | 0.5 + 0.5 ux | 0.5 + 0.5 uy | 0.5 | 1 | `f_vecfield` contract |

Domain: periodic unit square, wavevector `k = 2π · signed_index`.

---

## Architecture Decisions

### ADR-1: Stage chain (ten `jit.gl.pix`, every stage at most three inputs)

**Context**: spectral phase separation needs real-space advection, blend and
injection plus a per-bin step; the bench covers at most three inputs per codebox;
the two vecfield inlets must be gated individually.

**Decision**:

```
r draw → inab (in0 bang, in1 vecfield A, in2 vecfield B)           256²
inab ─────────────────────────────────────────────┐ (cold, for enc)
pass → adv (in0 state, hot), inab → adv (in1 packed velocities, cold), φ source via vs_inState → adv (in2)   256²
hold → pass (in0 r draw bang, in1 hold)                            256²
(amended 2026-10-27, T008: state rides the hot inlet so a draw reaching inab before pass cannot interleave even and odd frames)
adv → fx → fy → spec → iy → ix → hold                              256²  (feedback)
ix → enc (in2);  inab → enc (in1);  r draw → enc (in0)             render size
enc out0 → outlet 0 (φ);  enc out1 → outlet 1 (blended velocity)
```

| # | Node (`#0_imm_…`) | Does | Inputs |
|---|---|---|---|
| 0 | `inab` | decode and content-gate both vecfields, `taps × taps` box minify, pack | bang, A, B |
| 1 | `hold` | identity; one-frame delay, the loop break | ix |
| 2 | `pass` | holds φ, or re-seeds `fill` + hash noise on `reseed`; zaps non-finite | bang, hold |
| 3 | `adv` | blend by φ (rule per `blend`), backward-advect φ by it, inject, clamp, pack φ and φ³; honours `freeze` | state (hot), packed u, φ source |
| 4–5 | `fx`, `fy` | forward DFT | prev |
| 6 | `spec` | phase-separation step per bin; honours `freeze` | prev |
| 7–8 | `iy`, `ix` | inverse DFT; `ix` keeps the real part and clears non-finite | prev |
| 9 | `enc` | periodic upsample of φ and both velocities, blend, encode out0 and out1, bypass gate | bang, packed u, φ |

**Rationale**: it is `f_vf_fluid`'s chain (`pass → adv → fx → fy → spec → iy → ix →
enc`) with an input stage added in front and the DFT carrying φ and φ³ instead of
velocity. `adv` is triggered by `pass` (state on the hot inlet, amended 2026-10-27),
so `adv` is not a head and needs no bang inlet. `inab` and `pass` are both
chain heads on `r draw`; the cold `inab` output must have landed before `pass`
fires `adv`, which T011 must verify on the bench (draw-order test).

**Alternatives**: one stage reading A, B, φ and the source (rejected: four or five
inputs, beyond the bench); two input stages (rejected: the packed pair fits one
texture); a four-input `enc` that reads A and B at full render size (rejected:
beyond the bench, and Fluid's own detail is 256² anyway).

**Consequences**: +: every stage benchable; the ordering problem of two cold
inlets from separate stages in one frame is avoided because both velocities arrive
packed. −: a velocity input that has detail finer than 256² (a non-Fluid producer)
loses it in `inab`; ten stages is a large chain.

### ADR-2: Phase-separation step: stabilised semi-implicit Cahn–Hilliard [inference]

**Context**: the model is `∂φ/∂t = M ∇²(φ³ − φ − κ ∇²φ)`. The linear part per bin
has the `k² − κk⁴` shape of `f_ks`'s step, but the unstable band makes a pure
exponential-linear split (as KS uses) a growth-then-explicit-clip scheme; the
`φ³` term is a nonlinear diffusion.

**Decision**: a semi-implicit step with a stabilising term, entirely per bin:

```
φ̂'  = [ φ̂ · (1 + Mdt·k²·(a + 1)) − Mdt·k² · (φ³)^ ] / (1 + Mdt·k²·(a + κ·k²))
```

with `κ = (iface / 256)²` (so the flat-interface profile is `tanh(x / (√2 · ε))`,
`ε = iface/256` in domain units), `Mdt` the per-frame mobility from the `coarsen`
dial (a cubic law like `f_vf_fluid`'s `viscosity`, constants in one place in the
codebox and the mirror), and `a` the stabiliser, about 1–2 for this double well,
fixed by a stability sweep in Phase 0. φ and φ³ arrive as the two complex fields,
so `spec` needs no real-space derivative at all.

- **Mean conservation** is exact: at `k = 0` the factor is 1 and the `(φ³)^` term is
  multiplied by 0.
- **Cost** is the DFT chain's, the same as Fluid's: the second complex field costs
  nothing extra because the chain moves four channels regardless.

**Alternatives**: exponential-linear split with a real-space Laplacian of φ³
(rejected for now: the explicit nonlinear diffusion has a time-step limit, whereas
this is unconditionally stable for a large enough `a`); the fallback model (plain
advected φ plus a sharpening term) stays available if Phase 0 experiment 1 says
Cahn–Hilliard does not hold the interface under stirring (G7).

**Consequences**: +: stable at the large per-frame steps real time wants; one
formula, exact mean. −: accuracy at large `Mdt` is unknown (coarsening speed is an
open experiment); the scheme and `a` are unverified until the mirror.

### ADR-3: The blend lives in `adv` and `enc`, generated from one block

**Context**: φ must be advected by the blended velocity at 256² (`adv`), and the
consumer-facing blended vecfield is produced at render size (`enc`).

**Decision**: `gen_blend.py` writes the same blend block into `codebox_adv.gen` and
`codebox_enc.gen`; a test asserts the two copies are identical. Rules:

- **Plain:** `u = (1 − w)·uA + w·uB`, `w = clamp((φ + 1)/2, 0, 1)`.
- **Interface-aware** (candidate, G2) [inference]: `n = ∇φ/|∇φ|` from central
  differences on φ (periodic), confidence `s = smoothstep(g0, g1, |∇φ|·iface)`,
  normal target `ūn = ½ (n·uA + n·uB)`, then `u = u_plain − s · n · (n·u_plain − ūn)`.
  This spreads the normal jump over the band; it does not remove it (spec,
  Settled model). No separate tensor module is needed: the projector is `n nᵀ`
  from φ's own gradient, sign-free.
- **Viscosity-weighted** (candidate): weights `μ_A·(1−w)` against `μ_B·w`. The
  viscosities are not on the wire, so this needs a hand-set ratio dial; deferred
  unless Phase 0 shows it matters.

**Consequences**: +: no drift between the two copies; the rule is swappable behind
the `blend` menu. −: in `enc` the blend reads three textures (φ and the packed
velocities) with periodic four-tap reads (cheap).

### ADR-4: Inputs are minified into 256², and the pair is packed

**Context**: Fluid's outlets are render size; a codebox cannot read an input
texture's size; `vs_black` is 1 × 1 and decodes to −1 (`f_vf_fluid` ADR-2).

**Decision**: `inab` is `@adapt 0 @dim 256 256`, triggered by `r draw`, takes A and B
through `vs_inState` (flags `src_a`, `src_b`) and the content gate (`|B − 0.5| <
0.25`), averages a `taps × taps` grid of hardware taps per solver texel (default
`taps` 2; Fluid outlets are smooth so a high count is unnecessary), decodes, and
writes both velocities into one texture. An invalid input yields zero velocity.

**Consequences**: the module's output detail is 256², the same as a Fluid outlet's
effective detail. A non-periodic producer shows a seam at the wrap.

### ADR-5: φ source, reset and containment

- **φ source (in0):** `adv` reads luma (via `vs_inState`, flag `src_phi`; content
  gate for `vs_black`) and applies `φ += inject · luma · (1 − φ)`: bounded, deposits
  phase B only, nothing when the source is dark or unconnected.
- **Reset:** `pass` replaces φ with `fill + amp · (2h − 1)`, `h` an arithmetic hash
  of texel and `salt` (no `sin()`), `amp` a small baked constant. `reseed` is held
  three draw bangs, as `f_ks`; `salt` counts up per reset; `reset` fires once on
  load after 200 ms.
- **No zero-heal.** `f_ks`'s `pass` reseeds an exactly-zero texel because zero is
  its fixed point and never legitimate. Here a uniform φ = ±1 is a legitimate
  stable state (FR-010), so `pass` reseeds only on non-finite values.
- **Containment:** `ix` zaps non-finite (as Fluid); `adv` clamps φ to a bounded
  range (about ±2, fixed in Phase 0) before use; the blend weight is clamped to
  [0, 1].
- **Freeze:** `adv` outputs the state unchanged (no advect, no inject) and `spec`
  applies factor 1, so the round trip is the identity; the DFT round-trip drift is
  about 1e-7 per frame, negligible against φ's range [inference]. The mirror
  measures it.

### ADR-6: Bypass is a Param gate on `enc`

Never native `@bypass` (it skips the shader and flips secondary outlets: the
library finding, `plan.md`). `enc` carries `bypass_gate`; out0 mixes to neutral
grey and out1 to the neutral vecfield (0.5, 0.5, 0.5, 1). **Spec G5 proposed
passing input A through; that needs a fourth input on `enc`** (A at render size),
beyond the bench's three, so this plan implements neutral outlets and puts the
choice back to Matt (G5). The solver keeps running.

### ADR-7: Build from `definition.py` with raw wiring

Follow `f_ks` / `f_wc`: `definition.py` carries the params and the module's raw
boxes and lines (the `r draw` and `vs_inState` plumbing, the reset logic). Object
ids derived from the control count, not hard-coded (the `f_wc` lesson: positional
ids shift when a control is added; the contract test reports `unrouted`). Phase 0
checks that `build_patcher.py` can express three input inlets with `vs_inState`
gating on two of them (`ideas/build_patcher_schema_gaps.md` is the place to log a
gap).

### ADR-8: Stage 2 is deferred and gated

The nudge and force outlets (spec FR-016) need the cross-module feedback cycle
(experiment 6) and a delivery choice (G8). Not in the v1 chain. When built, each
cycle crosses a `hold`-style delay (the idiom is `f_vf_lbm`'s `hold`), and summing
with the performer's stirring needs `f_vf_mix` additive (`ideas/f_vf_mix.md`,
idea-only), or a new native inlet on `f_vf_fluid`.

### ADR-9: Verification strategy

1. **Tier 1 (no Max):** `immiscible_mirror.py` mirrors each stage and a `step()`.
   Checks against independent truth: mean conservation (exact); single-mode
   growth and decay rate; flat-interface `tanh` profile; free-energy
   non-increase with no flow; blend identities (φ = ±1, swap symmetry);
   `∇·` of the plain blend equals `∇w·d`; divergence integral across a straight
   interface equals the normal jump for every rule; freeze round-trip drift; no
   NaN over 10⁴ frames at extremes; determinism. Mutation-checked, as the fluid
   and quasi mirrors are.
2. **Tier 2 (bench):** each real codebox on the GPU against the mirror (`inab`,
   `pass`, `adv`, the four DFTs, `spec`, `enc`); a host-sequenced multi-frame run
   (the bench feeds a single codebox back, so multi-stage frame-exactness is
   sequenced from Python, as `bench_fluid`); cost per stage and total. The first
   input must have the render size where a codebox uses `dim` (HANDOFF
   2026-10-26).
3. **Module contracts:** `tests/contracts/test_module_contracts.py` and
   `bench_modules.py`, no new XFAIL entries; two instances independent; "advances
   exactly once per frame" (Fluid's Block D check).
4. **Tier 3:** live with two real Fluids; ranges, character, cost in a real patch.

---

## Dependency Blocks

### Block A: Math (tier 1) and the two gating experiments
**Dependencies**: none. **Builds**: `immiscible_mirror.py`, `test_immiscible.py`,
`spike_immiscible_stirring.py`, `spike_immiscible_blend.py`. **Why**: the idea
stands or falls on experiment 1 (does Cahn–Hilliard hold the interface under
stirring, G7) and on experiment 2 (how large the blend's divergence really is, G2).
**Checkpoint**: tier-1 tests green and mutation-checked; G7 and G2 decided on
numbers and stills; coarsening speed (experiment 3) recorded.

### Block B: Stage codeboxes on the bench (tier 2)
**Dependencies**: A. **Builds**: the nine codebox files, `gen_dft.py`,
`gen_blend.py`, `bench_immiscible.py`. **Checkpoint**: every stage matches the
mirror; host-sequenced run within tolerance; cost per stage recorded.

### Block C: Builder and pix limits (parallel with A)
**Dependencies**: none. **Builds**: answers to spec experiment 5, in writing in
`tasks.md`: three input inlets with two gated, three-input stages, the `r draw`
chain-head ordering. **Why**: if the builder cannot express the inlets, the
definition changes shape; better known before Block D.

### Block D: The bpatcher
**Dependencies**: B, C. **Builds**: `definition.py`, `package/patchers/
f_vf_immiscible.maxpat`, contract-bench pass. **Checkpoint**: drift 0, contracts
green with no new XFAIL, two instances coexist, "once per frame" check, bypass.

### Block E: Live look, tuning and docs (tier 3)
**Dependencies**: D. **Builds**: ranges and defaults, `docs/f-reference/
f_vf_immiscible.md`, helpfile, menu entry (∇ marked, Processors), README row,
inventory rows. **Checkpoint**: spec success criteria 7–8 judged by Matt; name
confirmed (G1).

### Block F: Stage 2 (gated)
**Dependencies**: E, experiment 6, G8. **Builds**: the cycle test, `f_vf_mix` if
needed, nudge and force outlets, buoyancy and tension. Not scheduled.

---

## Implementation Phases

### Phase 0: Experiments and math [A, C]
- Verification-tier gate recorded first (which tiers apply and why), per the
  constitution.
- Mirror and tier-1 tests; stability sweep for `a`; experiments 1–3; decide G7
  and G2; builder check (experiment 5).
- **Checkpoint**: G7 and G2 closed; if G7 says Cahn–Hilliard does not hold, stop
  and re-plan around the fallback before any codebox.

### Phase 1: Stages on the bench [B]
- Codeboxes, generators, per-stage bench, host-sequenced run, cost (experiment 4).
- **Checkpoint**: spec success criteria 1–5 pass on the GPU path.

### Phase 2: Build the module [D]; stories 1–4, 6
- `definition.py`, patcher, contracts, `bench_immiscible_module.py`.
- **Checkpoint**: contracts green; the live look with two Fluids is the first
  tier-3 session.

### Phase 3: Docs and integration [E]
- Reference doc, helpfile through the generation pipeline, menu, README, inventory,
  `plan.md` status, HANDOFF; confirm the name.

### Phase 4: Stage 2 [F], gated
- Only after Phase 2 is judged worth extending.

---

## Complexity Notes

- **Ten pix stages.** Justified by one stage per verified step and the
  three-input bench limit; the cost is dominated by the four DFT passes either way.
- **The riskiest piece is not the solver.** The Cahn–Hilliard step is a known
  construction on a proven chain. The unknowns are whether it holds the interface
  under real stirring (G7), whether the blend's divergence matters (G2), and, for
  stage 2, a cross-module cycle never tried. Phase 0 is built to answer the first
  two before any codebox exists.
- **Cost.** About 8 ms with two Fluids is large for a live patch; 128² (G6) and the
  one-map-inlet fallback in `ideas/f_vf_immiscible.md` are the levers.
- **Known limits carried from the spec:** periodic domain; output detail 256²;
  stage 1 gives a picture of two flows, not momentum exchange.

## Next Steps

- `tasks.md` is written (2026-10-27; Phase 0 first task is the verification-tier
  gate). Next: T002, the mirror's φ step, then the stirring experiment (T006).
- Spec G5 needs Matt's call (neutral outlets versus a passthrough of A at the cost
  of a fourth input).
