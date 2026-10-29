# Implementation Plan: f_tf_hatch (v2 — streamline renderer)

_Rewritten: 2026-10-28. v1 plan archived as `plan_v1.md`. Spec: `spec.md` (same date).
Tasks: not generated yet (`tasks_v1.md` is archived and stale); generate fresh tasks from
this plan once Matt has approved it._

## Summary

Replace the v1 lattice-of-marks renderer with a per-pixel streamline (LIC) renderer, to
make a tensor's coherence and topology visible. Keep what is sound in v1: the in-pixel
decode, the presence floor, the contract and registration. The work is front-loaded with
cheap, decisive evidence: a NumPy mirror judged on synthetic fields with known coherence,
then a GPU cost spike, *before* any production codebox is written.

## Technical Context

- Module: `src/f_tf_hatch/` (v1 files stay until Phase 1 replaces them; v1 is recoverable
  at git `a24b8cd`). Three `jit.gl.pix` stages: E1 decode, E2 march, E3 style/encode.
- Tensor contract: `docs/f-reference/f_tensor_type.md`; decode idiom copied from
  `f_tf_tensormap`/`f_tf_glyph` (v1 ADR-2, `plan_v1.md`).
- Platform rules unchanged: ADR-4 (bounded loops, floats unclamped between stages, one
  clamp in E3), `jit-gen-codebox` skill for the dialect, `bench-test-authoring` skill for
  the bench file.
- Measurement: chain-divisor bug fixed 2026-10-26; the v1 cost numbers were 4× low until
  re-measured 2026-10-28 (≈0.8 ms/pass upper bound per simple pass at 1080p, M3 Max).
- The three verification tiers are kept. Ask before any bench run.

## Decisions (these replace v1's ADR-1/3/9)

- **D1 — The primitive is the streamline, not the mark.** Seeds/cells/lattices are out.
  Reason: continuity and degenerate points are the topology; isolated marks cannot show
  them; a lattice anchored in the pixel frame produced the v1 rings.
- **D2 — Noise lives in world coordinates.** Never in the pixel's local frame.
- **D3 — Sign continuity by dot-product alignment** against the previous step. No branch
  cut by construction.
- **D4 — Coherence enters only as direction persistence** (OQ1), never as shape or
  brightness. Presence (`structure_floor`) is the only brightness gate.
- **D5 — The evidence comes first.** The mirror and the acceptance tests exist before the
  codeboxes; a failed test 2 or 3 stops the design before any GPU work.

## Files

Replaced in Phase 1 (v1 equivalents deleted, never stubbed):
- `src/f_tf_hatch/codebox_stage_e1.gen` (edit: aux layout per OQ2, drop commit/aspect)
- `src/f_tf_hatch/codebox_stage_e2.gen` (new: the march) — replaces `codebox_stage_e2_T.gen`
- `src/f_tf_hatch/codebox_stage_e3.gen` (rewrite: normalize, style, presence, encode)
- `src/f_tf_hatch/definition.py` (params per spec; drop the v1 mark dials)
- `tests/modules/tf_hatch/tf_hatch_mirror.py`, `test_tf_hatch.py`, `bench_tf_hatch.py` (rewrite)
- `docs/f-reference/f_tf_hatch.md`, helpfile (Phase 5)

New scratch, outside the repo until it earns a place: a stills renderer
(`.specify/f_tf_hatch/spike/` for anything kept).

## Dependency Blocks

### Block 0: Mirror + synthetic-field evidence (BLOCKING, FIRST)
The LIC march in NumPy; synthetic encoded-tensor fields (straight, isotropic, coherence
ramp, rings, branch-cut sweep, degenerate point). Tests 1–8 from the spec's acceptance
criteria. Rendered stills for Matt to look at. Decides OQ1 and informs OQ2/OQ3.
**Gate: tests 2 and 3 pass.** If the isotropic field renders streaks, or streak length
does not rise monotonically with coherence, the design stops here.

**RESULT (2026-10-28): GATE PASSED, tier 1 10/10** (`tests/modules/tf_hatch/test_tf_hatch_lic.py`,
mirror `tf_hatch_lic_mirror.py`, beside the v1 files until Phase 2). Measured: coherent
straight field L_along/L_across = 12.2; isotropic field ratio 1.04 (grain); coherence ramp
streak length 2.6 → 14.3 px, rank correlation 0.94; ridge-vs-axis error median 4.6° (rings) /
6.7° (sweep) / 3.1° (random field), against v1's recorded 25–64°; branch cut no seam in any
aux layout; degenerate point grain at the centre (1.08) and streaks around it (3.04).
The mutation (coherence ignored) is caught: anisotropy 13.6 on the isotropic field.
OQ1 is provisionally decided (mix, coherence^0.5) and OQ2 leans `unsigned_nearest`; see spec.
Stills: `spike/lic_stills_2026-10-28.png` (clean and heavily noisy sources). They show streaks
following the rings and stripes, grain where the tensor is noisy, and the "coherence ignored"
column drawing false worm-like curls in the noise that the real version renders as grain.
**Honest read:** it looks like contour-streaked noise, and `line = 1` reads as engraving, not
as hatching marks. The look is promising; tier 3 decides whether it is the look Matt wants.

### Block 1: GPU cost spike (BLOCKING after Block 0)
A throwaway march codebox on the bench at N = 8 / 16 / 32, nearest vs bilinear aux. Reports
ms/pass at 1080p and compares to the ≤ 5 ms module budget. Decides OQ2, OQ3 and whether
E2 stays one pass. Needs Matt's go-ahead to run (bench rule).

### Block 2: Production codeboxes + bench
E1/E2/E3 as in Files; tier-2 diff against the mirror.

### Block 3: Judgment on real content
Matt, live: camera, wfg stripes, a degenerate-rich scene; with and without `f_tf_smooth`.
Locks defaults (provisional until now). Confirms or kills OQ4.

### Block 4: definition.py, build, drift and contract tests

### Block 5: Docs and handoff
`docs/f-reference/f_tf_hatch.md`, helpfile (f-helpfile skill, written in a Claude session),
`f_tensor_type.md` family row, README status.

## Implementation Phases

Per CLAUDE.md: one phase or coherent group per turn, stop with three lines.

- **Phase 0 — Mirror + synthetic tests (Block 0).** Offline only; no Max, no GPU.
- **Phase 1 — Cost spike (Block 1).** Needs go-ahead; one named bench.
- **Phase 2 — Production codeboxes on the bench (Block 2).**
- **Phase 3 — Scratch patch + judgment (Block 3).**
- **Phase 4 — definition.py and build (Block 4).**
- **Phase 5 — Docs and handoff (Block 5).**

## Out of this plan

- Tone / cross-hatch / color / engraving layers / animated flow.
- A seeds-based path-with-identity renderer.
- **Fallback if the streamline look fails in Phase 0 or 3:** extend `f_vf_seeds` with a
  tensor-reading `axis_mode` (render codebox reads the doubled-angle pair at the seed and
  recovers the half angle; coherence drives scatter). Seeds near the capture ceiling means
  this needs its own spec amendment first. Recorded here so it is not rediscovered.
- Tensor → vecfield alignment-only hatching is already what `f_tf_axisflow` → `f_vf_seeds`
  gives; this module must show something that route cannot (coherence/topology), or it
  should be paused.

## Risks

- **False streaks in incoherent regions** (`atan2(0,0)`): addressed by D4, gated by test 2.
- **Cost:** ~33 taps/pixel; gated by Block 1, with N, resolution and two-pass fallbacks.
- **Low-contrast raw LIC:** normalization is E3's job (spec E3); check range in the mirror.
- **Tensormap radius/strength calibration:** coherence depends on the window; the helpfile
  must say so. A noisy camera tensor will look like grain no matter what; that is correct
  output, not a bug.
