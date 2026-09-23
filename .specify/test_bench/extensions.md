# Test Bench — Extension Roadmap (draft for discussion)

**Created**: 2026-09-22
**Status**: E1–E4 implemented 2026-09-22 (see tasks_extensions.md); E5 items remain later/if-needed

The v1 bench (spec.md/plan.md/tasks.md, implemented) covers a single
jit.gl.pix codebox: ≤3 texture inputs, `out1` only, one frame, float32,
params. That's enough for new single-stage work (it verified the FFT), but
most of the existing library sits outside it. This file maps the gap and
proposes an order. Nothing here is built.

## Where the library sits relative to v1

| Module shape | Examples | v1 coverage |
|---|---|---|
| Single pass, `out1` only | many color/geometry processors | full |
| Multiple outputs (`out2`+) | vecfield modules' novel-field outlets, `f_vf_optical_flow` confidence, `f_caustic` isolated layer | `out1` only — 39 of 57 `src/` codeboxes write `out2`+ |
| Multi-stage `pix_chain` | `f_vf_seeds`, `f_sirds`, `f_vf_optical_flow` | stage by stage only |
| Feedback / temporal state | `f_vf_advect`, `f_vf_optical_flow`, `f_vf_potential` | none (single frame) |
| char (8-bit) textures | most non-vecfield Vsynth chains | none (float32 forced) |
| Whole bpatcher: routing, attrui, bypass, param names | every shipped module | none |

The last row matters more than its position suggests. A recurring class of
real bugs in this library is *wiring*, not math: `f_vf_advect`'s dial bound
to a nonexistent `strength` attribute while the codebox read `mix_amt`;
`f_lens`'s bypass reaching only one of three stages; `f_vf_warp`'s `out2`
ignoring bypass. None of those are catchable at the codebox level.

## Proposed extensions

### E1 — Multiple outputs (small, high coverage)
Capture `out1..out4` per job. The outlet count of a pix follows its gen
patcher's `out` objects (same mechanism as inputs, bench-verified for `in`),
so keep it constant: every bench `.genjit` carries `out 1..4`
(`make_genjit(min_outputs=4)`), and `bench_default.genjit` too; four gated
capture taps → four float32 matrices → `out1.jxf..out4.jxf`. `run_pass`
returns a list.
**Decision gate:** does an *unwired* `out N` in a gen patcher compile and
keep the outlet? (Probe codebox, one job.) If not: wire unused outs to a
constant inside the generated gen patcher.

### E2 — char textures (small)
Job `type: char` → pix `@type char`, readback still into a float32 matrix
(values quantized to 1/255). NumPy side already has `gpu_sim.store_char`.
Lets tests catch quantization and clamping behavior modules actually hit in
Vsynth chains. **Gate:** confirm char readback lands as k/255 exactly.

### E3 — Bpatcher contract tests (moderate, highest leverage)
Load a *shipped* bpatcher into the bench and test its wiring, data-driven
from `src/f_name/definition.py`, with no per-module mirror needed:
- **Param contract:** for every declared param, send `name value` into the
  module's inlet 0 (the Vsynth control-message path), then read the inner
  pix's attribute back — must equal what was sent. Catches the `mix_amt`
  class: UI/route names bound to attributes the codebox doesn't have.
- **Bypass contract:** `bypass 1` → every outlet equals the pass-through
  expectation. Catches the `f_lens` / `f_vf_warp` class.
- **Smoke:** loads with no Max errors; produces output on every outlet.

Because it's data-driven, one test file covers all ~35 modules, and it
becomes a regression suite for the whole package.
**Decision gates (discovery first):**
- Can a package bpatcher run in the bench? Modules draw to the context
  named `vsynth`; the bench's world is `bench_ctx`. Options: name the bench
  world `vsynth` (conflicts if Vsynth is also open), or run Vsynth's
  `vs_render` inside the bench.
- Loading per job without dirtying the bench patch: a fixed `bpatcher`
  object sent `replace <file>` (candidate — verify it doesn't mark the
  parent dirty) vs. scripting.
- Reading attributes inside a bpatcher from `bench.js`
  (`subpatcher().getnamed(...)` + `getattr`) — needs scripting names on the
  inner pix, which the build system already sets (`@name <prefix>_pix` /
  varnames — confirm per module).

### E4 — Temporal / feedback runs (largest, unlocks the hardest modules)
Run N frames and capture at chosen frames (a time series), with a feedback
path so a pass can read its own previous output — the `state`/`pass`
Pattern 1 from `docs/temporal_synthesis_architecture.md`. Sketch: a
selectable `out K` → identity "pass" pix → back into a chosen input (one-
frame delay by construction). NumPy mirrors step the same number of frames.
This is the tool that would have settled the `f_vf_advect` vorticity-
confinement mystery (curl on `in3` always zero) in minutes: capture `in3`
as seen by the codebox, frame by frame.
**Decision gates:** frame-exact stepping (manual `jit.world` bangs with
`enable 0` vs counting continuous frames); feedback routing selection in a
fixed patch (texture-message `switch`/`gate` — messages route like any
other); float drift tolerance over many frames.

### E5 — Later / only if needed
- **Whole multi-stage chains as wired** — probably unnecessary: stage by
  stage (v1) + E3 (shipped patcher as a whole) + E4 (feedback) covers it.
- **`gen~` audio bench** for the `f_a_` family — same pattern with
  `buffer~` capture; separate build, only when audio work resumes.
- **GenExpr → NumPy interpreter** — only if hand-written mirrors start to
  feel repetitive.

## Proposed order

1. **E1 + E2** together — small, and together they take codebox-level
   coverage from "out1, float32" to most of the library.
2. **E3** — highest leverage: one data-driven suite over every shipped
   module, aimed at the bug class that has actually bitten. Needs a
   discovery phase first (context naming, bpatcher loading).
3. **E4** — biggest build; do it when a temporal module is next on the
   table (`f_vf_advect` confinement, `f_vf_vorticity` re-verification,
   `f_vf_optical_flow` Phase 5).

Alternative worth considering: **E3 first**, since it pays off across the
whole package immediately and doesn't depend on E1/E2 — at the cost of
starting with the most uncertain discovery work.

## Carried-over loose ends (not extensions, but bench hygiene)
- Unexplained intermittent `ERROR` in `bench_control.py` (logs now kept).
- `bench_src` kept but not proven necessary.
