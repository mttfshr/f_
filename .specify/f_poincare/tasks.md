# Tasks: f_poincare

**Spec**: `.specify/f_poincare/spec.md` (draft 2026-11-06, Matt: "the spec is great")
**Plan**: `.specify/f_poincare/plan.md` holds the 2026-07 scratch-phase results and ADRs; this build has no new plan yet.
**Build order**: Sequential. Phase 0 closes the open questions; nothing in Phase 2 starts until its gates are closed.
**Commits**: After each phase checkpoint.

Created 2026-11-06 from the spec's Acceptance criteria and Open questions. Nothing here is done yet. Codeboxes are `jit.gl.pix` (read the `jit-gen-codebox` skill before writing one); any bench file is written after reading `bench-test-authoring`. No test or bench runs without Matt's go (CLAUDE.md).

Who observed what: results marked "offline" are Claude's NumPy runs; "live" means Matt in Max. Record the date with each.

---

## Phase 0: Bring the work in, close the open questions

- [x] T001 Copy `~/Vsynth/patterns/poincare-p4q5-scratch.maxpat` into the repo as the reference starting point (spec open question 5). Done 2026-11-06: `tests/modules/poincare/reference/poincare-p4q5-scratch.maxpat` (byte-identical, checked with `cmp`; `scratch/` is gitignored so it could not go there). The other two scratch patches (`tangent-circle-priority-scratch`, `apollonian-scratch`) were not copied; they are not needed by this build. Original instruction: do not edit it. Strip nothing: its `N`-matrix and `debug_ok` code stays in the copy as the record, and is not carried into `src/`.
- [x] T002 (done 2026-11-06, offline by Claude: `tests/modules/poincare/poincare_mirror.py`, `test_poincare.py`, 11/11 with `tests/run.sh -q`; the float32 variant is not built; mutants: wrong r2, unmirrored mode-B angle and conjugate-free camera are caught, but a mutation of the mode-A priority order is not a mutant, see Record) Float64 NumPy mirror of both folds in `tests/modules/poincare/`: geometry (`d`, `r2` from `p`, `q`), mode A chain, mode B angle fold plus single circle, camera isometry. Tests grounded in the spec's closed forms: `d^2 - r2 = 1`; `q -> large` limit gives `d = 1/cos(pi/p)`, `rho = tan(pi/p)` (the f_apollonian ring); {4,5} values equal the scratch patch's defaults (2.0582, 3.2361); settled points lie outside all edge circles (A) or inside the wedge and outside the edge circle (B); zero camera equals the static tiling. Float32 variant of the mirror only after the float64 one passes (the repo rule is a pass-for-pass float32 mirror for GPU comparison).
- [ ] T003 Second {p,q} pair, offline: render {4,6} for mode A and {5,4}, {3,7} for mode B from the mirror and check each by eye. This is the spec's acceptance item; the closed form has only been checked at {4,5}.
- [ ] T004 Iteration count and rim depth, offline: for each tested pair, measure the fraction of in-disk pixels unsettled after 16, 24, 32, 48 iterations and the radius where unsettled pixels begin. Output is a recommended count and a rim-fade radius, stated as a measurement, not a guess. Float32 behavior at the rim is a separate follow-up (T032).
- [ ] T005 Live p in mode A (spec open question 1). Offline, decide between: (a) fix the nearest-circle test (candidate: test the nearest two circles, or the nearest by hyperbolic rather than angular distance); (b) size the chain for a maximum p. Offline result decides the default; (a) is only chosen if it matches the 4-circle result on every pixel that both settle.
- [ ] T006 **Decision (Matt):** texture in the tile for mode A (spec open question 2): crop to the curved tile (current), or warp the image into it. Needs a look at `scratch/poincare_compare.png`.
- [ ] T007 **Decision (Matt):** `P-moebius-tiling` in `.specify/gates.md` (malformed, names this module and f_apollonian): reword, split, or clear. Reconcile gates.md, plan.md and this file per the Claims section, then run `tests/run.sh -q tests/build/test_gates.py` with Matt's go.
- [ ] T008 Module placement and name: confirm `f_poincare` (name used by the spec, ideas file and all docs; no objection recorded). Confirm whether the module sits with the other texture processors in `f_modules` and which category.

**Checkpoint:** mirror tests green (offline, with Matt's go), T003-T005 recorded here, T006-T007 decided.

---

## Phase 1: Mode A in a scratch patch (texture sampling)

- [ ] T010 Codebox for mode A: closed-form `d`/`r2` from live `q` (p fixed at 4), 4-circle priority chain with the single resolved inversion (the simplification from plan.md Step 2), settle loop at the T004 count, texture sample at the settled position, `tile_scale`, unsettled-pixel fade, outside-disk empty. No `N` matrices. Written against the mirror's stages.
- [ ] T011 Bench the codebox against the mirror (tier 2): settled position and sampled color agree away from the rim; the threshold is written before the run and is not loosened afterwards. Include {4,5} and the T003 second pair for mode A. *Needs the Max bench.*
- [ ] T012 Live look (Matt): mode A at {4,5} reproduces the 2026-07-09 scratch result (square central cell, 4-fold symmetry, depth growing to the rim), now with the test texture visible, and no seams.

**Checkpoint:** T011 and T012 recorded; commit.

---

## Phase 2: Mode B and the mode switch

- [ ] T020 Codebox for mode B: live `p` and `q`, angle fold into [0, pi/p], single circle on +x, repeat; same sampling, fade and empty-outside rules as T010. Guard `1/p + 1/q < 1/2` (clamp or hold the last valid pair, per the T008 decision; spec lists this as a constraint, not yet a behavior).
- [ ] T021 Combine into one codebox with a `mode` param, or two codeboxes behind a mode switch, whichever stays under the parser limits. Decide from a size check, not a guess.
- [ ] T022 Bench mode B against the mirror, including {5,4} and {3,7}. *Needs the Max bench.*
- [ ] T023 Live look (Matt): mode B and the switch between modes; the sliver look reads as intended at a few `tile_scale` values.

**Checkpoint:** T022 and T023 recorded; commit.

---

## Phase 3: Camera and rim

- [ ] T030 Add `rot`, `cam_x`, `cam_y`: rotation then disk translation `z -> (z - a) / (1 - conj(a) z)`, `|a|` clamped below 1. Zero camera must equal the static tiling bit-for-bit (test in the mirror and on the bench).
- [ ] T031 Rim policy as built: unsettled pixels fade to black at the T004 radius; check no NaN anywhere in the frame with the camera pushed toward the rim (`|a|` at the clamp).
- [ ] T032 Float32 rim behavior: measure how far from the origin the float32 path departs from the float64 mirror, as a function of radius and depth; record the radius past which the fade should start. Compare with the roguetemple paper's note in `ideas/f_poincare.md` (inferred there to bite harder in float32; this task measures it).
- [ ] T033 Live look (Matt): moving the camera through the tiling is smooth and recognizable, and the rim fade reads as intended.

**Checkpoint:** T030-T033 recorded; commit.

---

## Phase 4: Module and bpatcher

- [ ] T040 `src/f_poincare/definition.py` plus codebox files; `package/patchers/f_poincare.maxpat` built by `build/build_patcher.py`. Params per the spec table; `p` is a live param only in mode B unless T005 says otherwise.
- [ ] T041 Drift test passes for the new module (`tests/build/test_drift.py`; the baseline list only shrinks, so f_poincare must not be added to it), offline contracts, live module contracts, bypass behavior following the other texture processors (decide and record, do not assume).
- [ ] T042 `tests/modules/poincare/bench_poincare_module.py` against the real patcher: renders both modes, camera at zero equals static, outside the disk is empty.

**Checkpoint:** T040-T042 recorded; commit.

---

## Phase 5: Tuning and docs

- [ ] T050 Tier-3 look (Matt): defaults and ranges for `mode`, `p`, `q`, `tile_scale`, `iterations` (if exposed), camera and `rot`.
- [ ] T051 Reference doc (`docs/f-reference/`), helpfile (written in a Claude session, never by an API call; follow the `f-helpfile` skill), `f_modules` menu placement (`src/f_modules/menu.py`, then `build/generate_menu.py`), README Patches row (110 characters max, then `build/generate_launch.py`).
- [ ] T052 Preflight (`module-preflight` skill) before the module goes to `.specify/stable/`: mechanical checks plus the human gate (does the helpfile explain what the module is for).

---

## Record

- 2026-11-06: tasks file created from the spec (commit 756a218 for the resume and spec). No task is ticked.
- Carried from the 2026-07 scratch phase (plan.md, observed live by Matt): composition logic, multi-candidate priority selection, and a {4,5} tiling are confirmed; the float32 precision softness near the rim is expected, not a logic bug.
- Observed offline by Claude, 2026-11-06 (T002, float64): (1) the geometry passes two derivations that do not use the mirror's formula (edge distance and tile-vertex distance from hyperbolic trigonometry) at 8 {p,q} pairs; (2) mode A at p=4 and mode B agree once A's result is folded into the wedge, at {4,5}, {4,6}, {4,7}; (3) no seams: 0 jumps > 0.05 in 100,000 nearby pairs per case, modes A ({4,5}, {4,6}) and B ({4,5}, {5,4}, {3,7}); (4) **mode A's settled position depends on the priority order** (lowest-index-wins vs highest-index-wins disagree on a large share of points). Reason inferred, not confirmed: at {4,5} the vertex angle is 2pi/5, not pi/n, so the edge-reflection group contains the tile's own symmetries and the tile is not a strict fundamental domain. Consequence: the scratch patch's order (lowest index wins) is part of mode A's definition and must be kept, and the acceptance for A should pin it. Not yet checked: whether the texture orientation inside a tile looks right in Max with that order (T012).
- Observed offline by Claude, 2026-11-06: the single nearest-circle shortcut for mode A differs from the 4-circle result on 2.4% of pixels inside r<0.6 (the basis for T005). Cause is inferred, not confirmed.
