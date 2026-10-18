# Implementation Plan: f_tf_smooth

_Date: 2026-10-17_
_Spec: .specify/f_tf_smooth/spec.md_
_Hub: ideas/f_tf_build_brief.md §4/§5; audit: ideas/f_tf_jitfx_audit.md §2.2_

---

## Summary

`f_tf_smooth` is a temporal one-pole feedback smoother operating on the f_tensor raw
encoding. Two-domain architecture (state pix + render pix, the `f_vf_advect` precedent;
`jit.fx.tp.filter`'s MRT mechanism, simplified):

```
                        ┌──────────────────────────┐
in0 (tensor) ──> state_pix ──> state texture (float32, feedback)
                        │            │
                        v            │ (next frame: Param srcSmoothTensor via vs_inState)
                   render_pix ──────┘ (reads state texture, passes through)
                        │
                        v
                     outlet 0
```

State pix computes `T_blend = T_new + release·(T_prev − T_new)` per channel and both
writes it back (feedback) and forwards it. Render pix is a passthrough that surfaces the
state texture to the outlet. One feedback tap per channel.

Most of the build is wiring, not math. The recurrence has closed-form ground truth; the
risks are the feedback wiring in `pix_chain` (does the state texture hold unbounded
float32 negative-offset tensors correctly across frames?) and clamp discipline at the
feedback write.

## Technical Context

**Environment:** Max 9, Vsynth, `jit.gl.pix` gen codeboxes, `@type float32` throughout
**Build method:** NumPy mirror (tier 1) -> codeboxes on the bench (tier 2) -> scratch
patch (tier 3) -> `definition.py` -> `tools/build_patcher.py` (per repo convention)
**Precedents to read in Phase 2:** `f_vf_advect` (two-domain pix_chain), `jit.fx.tp.filter`
(MRT recurrence — audit source-read already notes its shape), `f_vf_optical_flow`
(param-to-non-primary-node wiring).
**GPU budget:** M3 Max measured, M1 unmeasured; costs reported as upper bounds where
CPU-bound (tensormap T016 convention).

## Files

```
.specify/f_tf_smooth/
  spec.md  plan.md  tasks.md      — this triad

src/f_tf_smooth/                  — per built-module layout (ADR-6)
  codebox_state.gen               — Phase 1: the recurrence + feedback write
  codebox_render.gen              — Phase 1: passthrough render (kept separate per ADR-2)
  definition.py                   — Phase 3

tests/
  test_tf_smooth.py               — tier 1 mirror (Phase 0)
  bench_tf_smooth.py              — tier 2 (Phase 1)

~/Vsynth/patterns/ tf_smooth_scratch.maxpat   — tier 3 (not committed)

docs/f-reference/f_tf_smooth.md  — Phase 5
```

## Architecture Decisions

### ADR-1: One-pole release-only feedback; no attack, no two-pole taps
**Context:** tp.filter runs a two-pole recurrence (a0,a1,a2,b1,b2 — five coefficients,
audio-adjacent character). The f-family wants a one-knob performable gesture.
**Decision:** `T' = T_new + release·(T_prev − T_new)`; single feedback tap.
**Rationale:** the release gesture is the product (`f_tf_expressive_consumers.md` §2.3
"attack, release as the performable surface" — reduced here to release-only per spec
Out of Scope). One tap also avoids float32 drift accumulation of a deeper delay line.
**Consequence:** attack-shaped dulling of real structure is accepted as out of scope; if
tier 3 finds the field too laggy at useful release values, two-pole is the v2 door.

### ADR-2: Two-domain pix_chain, state pix + render pix
**Context:** feedback in a single codebox is awkward (the codebox must read its own
previous-frame output; that IS what `vs_inState`-sourced Params are for, as advect does).
**Decision:** state pix reads `Param srcSmoothTensor` (previous frame, via `vs_inState`)
and writes blended output to the state texture; render pix reads the state texture and
passes it to the outlet. Both nodes in one `pix_chain`, advect wiring as precedent.
**Rationale:** separates "compute" from "present" exactly as the family's temporal
modules already do; keeps the render outlet independent of the feedback node's own
timing.
**Consequence:** `definition.py` needs a two-node `pix_chain` with `pix_wires` fan — the
T028-style precedent read (optical_flow for param-to-non-primary wiring) is mandatory
before writing definition.

### ADR-3: No clamp on the feedback write; encode only at the outlet
**Context:** raw tensor values are unbounded floats (strong edges give Jxx >> 1); the
feedback loop must not clip them against 0–1.
**Decision:** state texture and all internal reads are unclamped float32. The only place
encoding/ clamping appears is where the outlet contract demands it — and since the outlet
encoding IS the inlet encoding (raw out0 passthrough), the outlet needs no additional
clamp beyond what tensormap already applied. In other words: this module never clamps at
all in v1.
**Rationale:** matches the brief's global constraint ("floats can go unclamped between
stages") and the feedback loop's own math (clipping inside a feedback loop creates
stuck-at-boundary artifacts). Also matches `jit.fx.tp.filter` (MRT, unclamped).
**Consequence:** a degenerate input (e.g. NaN) persists forever in the feedback.
Acceptable: NaN persistence is a debug situation, and the bypass path recovers it (see
ADR-4), but worth a docs note.

### ADR-4: Bypass is a param-level passthrough, not a feedback hold
**Context:** standard f_-family bypass semantics.
**Decision:** `Param bypass` in the state pix: when bypass=1, `T' = T_new` (feedback
ignored) and render passes it through. On unconnected inlet (vs_black -> zero tensor),
the feedback naturally decays to zero — correct neutral behavior for "nothing wired in".
**Rationale:** bypass must be exactly passthrough (contract tests check it); unconnected
must decay to neutral rather than freeze a stale field.
**Consequence:** bypass never freezes the last smoothed frame (unlike `f_texrouter`'s
documented freeze quirk); it's a hard passthrough. Document in the reference doc.

### ADR-5: Verification tiers
**Decision (Phase 0 gate, T001):**
- **Tier 1 applies** — the recurrence has closed-form ground truth; line-field and
  opposite-axis behaviors are synthetic-sequence checks.
- **Tier 2 applies** — the real risk is feedback on the GPU; the bench must prove the
  state texture round-trips unbounded floats across a frame boundary exactly.
- **Tier 3 applies** — `release` default/range is a feel question on live noise.

### ADR-6: Files/layout — build-directive
**Context:** the triad's original Files sketch placed the codeboxes and definition.py in
`.specify/f_tf_smooth/`; the build directive puts built modules in `src/`.
**Decision:** codeboxes and `definition.py` live in `src/f_tf_smooth/` per the parent's
built-module layout (matching `src/f_tf_tensormap/`), overriding the sketch above.
**Consequence:** the two codebox files (`codebox_state.gen`, `codebox_render.gen`) exist
there as separate .gen files — the passthrough render node is kept as its own file, not
folded into state.

## Dependency Blocks

### Block 1: Recurrence settled in NumPy
**Builds:** `tests/modules/tf_smooth/test_tf_smooth.py` — per-channel one-pole over synthetic tensor
sequences; the opposite-axis reinforcement invariant; decay-curve check `out(N+k) =
B + (A−B)·release^k`.
**Verification:** mirror passes on flat/edge/synthetic sequences; mutation check (swap
the feedback sign; confirm a test catches it).

### Block 2: Codeboxes on the bench
**Dependencies:** Block 1.
**Builds:** `codebox_state.gen` (+ render passthrough, possibly folded).
**Verification:** recurrence matches the mirror on the GPU *across a frame boundary* (the
bench's own frame-advance mechanics: how `vs_inState`/`srcSmoothTensor` behaves in the
bench harness is the thing to confirm, mirroring how `f_vf_advect`'s bench was built);
float32 round-trip of unbounded values (Jxx = 4.0 in -> 4.0 out the next frame).

### Block 3: Scratch patch, judgement
**Dependencies:** Block 2.
**Builds:** scratch patch only.
**Verification:** `release` default and ceiling on jit.gl.bfg-driven live noise; the
gesture feel (ride 0 → 0.9) confirmed by Matt in a live session; no visible drift on
static content.

### Block 4: definition.py and build
**Dependencies:** Block 3.
**Builds:** definition.py (two-node pix_chain per ADR-2, reading f_vf_advect's and
f_vf_optical_flow's precedents first — same T028 discipline as tensormap).
**Verification:** built patcher loads in Vsynth; params addressable; drift-clean; contract
tests green (add to BYPASS_EXPECT with passthrough semantics).

### Block 5: Docs and handoff
**Dependencies:** Block 4.
**Builds:** reference doc (note the ADR-3 NaN-persistence caveat), module inventory row,
constitution naming (f_tf_ already exists), HANDOFF.

## Implementation Phases

### Phase 0: Gates + tier-1 math (BLOCKING)
T001 records the tier decision (all three apply, ADR-5). Write the mirror and its
sequence-level checks. Exit: mirror passes its own decay theorem; mutation caught.

### Phase 1: Codeboxes on the bench (BLOCKING)
Stage-by-stage bench of the state codebox against the mirror, frame-boundary behavior
explicitly. Exit: float32 round-trip proven; feedback wiring understood and recorded.

### Phase 2: Scratch patch
Calibrate `release` default/ceiling on live noise; feel-check by Matt. Exit: locked
values recorded in the spec (same discipline as tensormap T027).

### Phase 3: definition.py and build
Read the two pix_chain precedents first; write definition.py; build; validate; register
in the modules menu; drift + contract tests. Exit: loads in Vsynth with correct neutrals.

### Phase 4: Integration check
Wire tensormap → smooth → glyph (once glyph's patcher exists). Interim check before
glyph ships: smooth's output format equals its input format (raw out0), so the same
decode preview built for tensormap Phase 2 (T026 there) demonstrates smooth's throughput
with nothing else. Note: `f_tf_axisflow` is NOT a valid consumer here — it takes tensormap
outlet 1 (packed), not raw outlet 0. Exit: a second patcher consumes smooth's output
live.

### Phase 5: Docs and handoff
Reference doc, inventory, HANDOFF. Exit: consumer modules (glyph at latest) cite smooth as
the standard stabilizer stage.

## Out of this plan

- Any tensor mixing (f_tf_mix, chain B).
- Attack/release curve shaping, two-pole taps (v2 doors, spec Out of Scope).
- Packed-outlet 1 passthrough (out of scope, spec).
- Bench runs without asking — every bench run here asks first, per the standing rule.