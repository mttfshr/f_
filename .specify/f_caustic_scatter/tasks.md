# Tasks: f_caustic sheets mode

**Spec**: `.specify/f_caustic_scatter/spec.md`
**Plan**: `.specify/f_caustic_scatter/plan.md`
**Build order**: Sequential by phase. Phase 0 and Phase 1 are hard gates: nothing in the module changes until the
soft-path baseline exists and the three feasibility spikes are answered. Within a phase, `[P]` tasks touch different
files and can run in parallel. Everything that needs Max (every bench run) is serial, and the look patch / any
Vsynth patch must be closed while the bench runs.
**Commits**: After each phase checkpoint. A commit that sweeps in files Claude did not work on is a plain save
checkpoint (Matt, 2026-10-07).
**Convention**: `- [ ] T### [P] [US#] description with exact path`. `[US#]` maps to the stories below; omitted for
setup, foundational and polish.

**Stories** (the spec has requirements, not stories, so they are named here):
- **US1** Sheets mode renders correct light (the MVP; proven standalone, before the module changes)
- **US2** The `detail` ladder sets capture size and density in one message
- **US3** `f_caustic` has a mode switch; soft mode is unchanged
- **US4** Shared behaviours hold in both modes (bypass, unconnected inputs, instances, gain, cost)

---

## Expected Output Layout

```
src/f_caustic/
  definition.py            # EXTENDED (pix_chain x3, mode / detail params, raw scene)      — T025
  codebox_v2.gen           # soft path: UNCHANGED
  codebox_sheets.gen       # sheets composite                                              — T013
  codebox_select_comp.gen  # select stage, composite outlet                                — T023
  codebox_select_layer.gen # select stage, caustic-layer outlet                            — T023
  scatter_scene.py         # generates raw_ui.json (scene, detail network, mode network)   — T014, T018, T024
  raw_ui.json              # generated                                                     — T014
package/code/f_caustic_sheets.jxs                                                          — T012
package/patchers/f_caustic.maxpat                # rebuilt                                 — T026
tests/
  record_caustic_baseline.py                                                               — T001
  baselines/f_caustic_soft.npz                                                             — T001
  scatter_truth.py         # promoted from scratch/caustic_fidelity.py                     — T004
  scatter_mirror.py        # promoted ref_scatter, box_down, upscale, tone                  — T005
  test_scatter_mirror.py   # tier 1                                                        — T006
  bench_caustic_sheets.py  # tier 2                                                        — T016 onward
  bench_caustic_sheets_cost.py   # interleaved cost (not a gate)                           — T021
  bench_caustic_codebox.py # tier 2, codebox bench: the sheets composite and select codeboxes   — T013, T023
  bench/caustic_sheets_standalone.maxpat   # generated standalone wrapper                  — T015
  bench/probe_*.maxpat     # throwaway feasibility probes                                  — T007, T008
docs/f-reference/f_caustic.md                                                              — T038
package/help/f_caustic.maxhelp                                                             — T039
.specify/constitution.md                          # amendment at ship                      — T040
```

---

## Phase 0: Setup

**Purpose**: Protect the soft path before anything changes.

- [x] T001 Write `tests/record_caustic_baseline.py` and record `tests/baselines/f_caustic_soft.npz`: the UNMODIFIED
  `package/patchers/f_caustic.maxpat` through the module bench with fixed inputs (a gradient source and a
  deterministic vecfield) at the defaults and four non-default parameter sets (`scale`, `softness`, `color_shift`,
  `gain`, `mix_pct`), both outlets saved per set. Commit the `.npz`.
- [x] T002 Run `./tests/run.sh` and the `f_caustic` module-bench entry (`tests/bench_modules.py`) and record the green
  counts as the "before" state in HANDOFF.md.

**Checkpoint**: a committed baseline and a recorded green state; `package/patchers/f_caustic.maxpat` still untouched.

---

## Phase 1: Foundational (BLOCKING)

**Purpose**: The tier-1 mirror, and answers to the three questions the design rests on.

⚠️ CRITICAL: no story work until the checkpoint.

- [x] T003 [P] Create `tests/scatter_truth.py`: promote the functions the mirror needs from `scratch/caustic_fidelity.py`
  (`field_texture`, `first_fold_distance`, `truth`, `interior`, `pearson`, `top_iou`) so `tests/` no longer imports
  from `scratch/` for this module.
- [x] T004 [P] Create `tests/scatter_mirror.py`: promote `ref_scatter`, `box_down`, `upscale`, `resize_bilinear` and the
  tone curve (`t = v/(1+v)`, `t^0.7`) from `tests/spike_scatter.py`.
- [x] T005 Create `tests/test_scatter_mirror.py` (tier 1, offline, NumPy only): tent weights sum to 1; energy conserved;
  identity at `scale = 0`; N points on one pixel sum to N; truth agreement at 4 points per pixel (r >= 0.99 at
  1 d* and 3.5 d*); the tone curve's properties. Add it to `tests/run.sh` if the suite lists files.
- [x] T006 Confirm the promoted mirror reproduces the recorded spike numbers (r 0.9985 at 1 d*, 0.9937 at 3.5 d* for 4
  points per pixel) inside `tests/test_scatter_mirror.py`.
- [x] T007 Spike V1, shader search path: place a probe copy of the shader at `package/code/f_caustic_sheets_probe.jxs`,
  load it from a probe bpatcher (`tests/bench/probe_shader_path.maxpat`) that is NOT beside it, run it in the module
  bench, and record whether `jit.gl.shader` finds it; if not, try the other candidate folders Vsynth uses. Record
  the result and the chosen location in HANDOFF.md. (Matt checks one case from a patch outside the repo if the
  bench result is positive.)
- [x] T008 Spike V2, unconnected pix input: a probe pix (`tests/bench/probe_unconnected_input.maxpat`) reads its second
  inlet while only the first is connected; capture what it reads (zero, last frame, undefined). Record the result:
  it decides the unconnected-vecfield guard (spec Decisions item 6).
- [x] T009 Spike V3a, builder multi-stage targets: build a throwaway two-stage definition in
  `scratch/probe_builder_targets.py` that gives one param (`gain`) and `bypass` to two `pix_chain` stages through
  `pix_target` lists, build it into a temp directory, and read the cords. Record whether `bypass_gate` reaches both
  stages or needs the raw `prepend param` fallback (plan, ADR-4).
- [x] T010 Spike V3b, builder routing: in the same throwaway, test `outlet_source_override` with a `pix_chain` node (not a
  raw box) feeding both outlets, and `mod_inlets` `fanout` into a `raw_boxes` id. Record what works.
- [x] T011 Decide ADR-1 from T007-T010: stay declarative, or fall back to a dedicated `src/f_caustic/build_caustic.py`.
  Write the outcome into plan.md (ADR-1, ADR-4, ADR-7), delete the probes that served their purpose, commit.

**Checkpoint**: the mirror is green; all four spikes are answered in writing; ADR-1 is settled (or the fallback chosen).

---

## Phase 2: User Story 1 - Sheets mode renders correct light (Priority: P1) 🎯 MVP

**Goal**: The scene, shader and sheets composite produce correct illuminance, proven standalone (no change to
`f_caustic` yet).

**Independent Test**: the standalone tier-2 suite passes against the mirror and truth.

### Implementation for User Story 1

- [x] T012 [P] [US1] Write `package/code/f_caustic_sheets.jxs` from `tests/bench/spike_scatter.jxs` per plan ADR-7: remove the
  `h`, `jit`, `latn`, `taps` and `snap` uniforms; fix the corner snap, `point_size 2`, one source read and
  `F.y *= -1`; keep `scale` (the distance), `weight` and `res`.
- [x] T013 [P] [US1] Write `src/f_caustic/codebox_sheets.gen` (header checklist: functions before `Param`; components inline
  on `sample()`; no `Param` named after a built-in): tone curve, `sample(in, norm)` upscale, additive composite,
  `mix_pct`, the unconnected-field guard chosen in T008, both outputs. Verify it compiles and matches the NumPy
  tone/composite on the codebox bench before it goes anywhere.
- [x] T014 [US1] Write `src/f_caustic/scatter_scene.py`: generate the scene (node, mesh, gridshape, slabs for source and
  field, `jit.gl.shader`, `prepend param` boxes) with `#0`-scoped names, writing `src/f_caustic/raw_ui.json` in the
  shape `src/f_grain/definition.py` reads. Reuse the construction in `tests/bench/make_spike_scatter.py` (which stays
  as the record).
- [x] T015 [US1] Make `scatter_scene.py --standalone` emit `tests/bench/caustic_sheets_standalone.maxpat`: the scene plus
  `sheets_pix` as a bpatcher the module bench can load (the `spike_scatter.maxpat` precedent), so this phase never
  touches `f_caustic`.
- [x] T016 [US1] Write `tests/bench_caustic_sheets.py` part 1 (standalone): identity at `scale = 0` vs the mirror
  (<= 1e-3); energy within 0.5%; N points on one pixel within 0.1%; orientation vs the mirror (r >= 0.999);
  truth agreement at step 5 (r >= 0.995 at 1 d* and 3.5 d*); tone and upscale vs NumPy at 512² and 1920 x 1080
  (the `s10` check promoted; measured 1.3e-8 in 1 - r, max difference 2.7e-3 from the hardware's 8-bit bilinear weights). **The 1-frame-lag assertion is NOT in this suite: it moved to T043.**
- [x] T017 [US1] Run T016, fix what fails, commit.

**Checkpoint**: sheets mode is correct standalone; Matt can open the standalone wrapper if he wants to see it.

---

## Phase 3: User Story 2 - The `detail` ladder (Priority: P2)

**Goal**: One message sets capture size, lattice size, weight and `n` (last), for five steps.

**Independent Test**: each step is identical to the equivalent explicit messages and meets its quality floor.

### Implementation for User Story 2

- [x] T018 [US2] Add the `detail` select-and-message network (steps from the spec table; `n` last) to `scatter_scene.py`.
- [x] T019 [US2] Extend `tests/bench_caustic_sheets.py` part 2: each of the five steps identical to the explicit messages
  (max|diff| 0; the `s11` check promoted).
- [x] T020 [US2] Measure quality for all five steps against the 16-points-per-pixel reference at 1 d* and 3.5 d*, including
  step 3 (768², unmeasured): set its floor just below the measurement, record it in the spec's table and in
  `tests/bench_caustic_sheets.py` (floors from the spec: 5 and 4 >= 0.995; 2 >= 0.995 / 0.95; 1 >= 0.99 / 0.89).
- [x] T021 [US2] **Re-scoped:** the plan was an interleaved timing comparison of the steps, but every step is below the bench's
  60 fps cap, which hides any cost under it (why the spike needed 16.8 M points), so an A/B would report "at the cap" five times.
  Done instead in `tests/bench_caustic_sheets.py` (`test_T021_...`): each step's frame period is measured and printed (all 16-17 ms,
  i.e. at the cap) and the default step 5 is asserted to fit the budget (16.1 ms; the limit is 1.15 x the cap). The cost MODEL stays
  spike S6's (density-driven, timings vary up to 2x between runs). No `bench_caustic_sheets_cost.py` file.
- [x] T022 [US2] Commit.

**Checkpoint**: the ladder works standalone and its floors are tests, not prose.

---

## Phase 4: User Story 3 - Mode switch; soft mode unchanged (Priority: P3)

**Goal**: `f_caustic` has `mode` and `detail`; soft mode is bit-identical to today.

**Independent Test**: the rebuilt module's soft output equals the Phase 0 baseline; sheets mode equals the standalone.

### Implementation for User Story 3

- [x] T023 [P] [US3] Write `src/f_caustic/codebox_select_comp.gen` and `codebox_select_layer.gen` (two stages, one per outlet, because the
  codebox bench takes three inputs; header checklist; `Param sheets_gate`, `bypass_gate`): verified on the codebox bench in
  `tests/bench_caustic_codebox.py`: gate 0 returns the soft input exactly, gate 1 the sheets input, bypass gives the source on
  BOTH outlets (as the soft path does), linear in the gate (8 of 8 checks). Found: the bench counts `outN` tokens in comment
  text to size the codebox, so keep them out of comments.
- [x] T024 [US3] Add the mode network to `scatter_scene.py`: `mode` menu output -> `prepend param sheets_gate` to the select
  stage; `enable` to the node, mesh and sheets stage (1 in sheets mode; the soft stage stays enabled, see plan ADR-5); entering
  sheets mode resends the current `detail` (which builds the lattice); soft mode builds nothing.
- [x] T025 [US3] Extend `src/f_caustic/definition.py`: add `pix_chain` (keep `caustic_pix` as the primary with its name and
  gen unchanged; add `sheets_pix`, `select_comp` and `select_layer`), `pix_wires`, the `mode` (menu: soft, sheets, default soft) and
  `detail` (menu 1-5, default 5, `pix_wire: False`) params, the fanouts and `outlet_source_override` as settled in
  T011, and `raw_*` from `raw_ui.json`. Every existing param, default and range stays as it is.
- [x] T026 [US3] Build: `build/py.sh build/build_patcher.py src/f_caustic/definition.py`; run `build/py.sh build/drift.py`;
  review every difference; update `tests/drift_baseline.json` only for the intended ones.
- [x] T027 [US3] Soft-mode identity: the rebuilt module vs `tests/baselines/f_caustic_soft.npz` for every recorded parameter
  set (r = 1.0000 on both outlets).
- [x] T028 [US3] Mode-switch bench: sheets mode through the real module equals the standalone output; switching back to
  soft restores the baseline output exactly; disabled branches are not drawing (the inactive branch's enable is 0).
- [x] T029 [US3] Update `tests/module_contract.py`, `tests/test_module_contracts.py` and the `f_caustic` entry in
  `tests/bench_modules.py` (`BYPASS_EXPECT`) for the new stages and outlet sources until `./tests/run.sh` is green.
- [x] T030 [US3] Commit.

**Checkpoint**: the module has both modes; soft is provably unchanged; the whole offline suite is green.

---

## Phase 5: User Story 4 - Shared behaviours (Priority: P4)

**Goal**: bypass, unconnected inputs, multiple instances, brightness and cost behave in both modes.

**Independent Test**: each bullet of the spec's tier-2 list that remains passes through the real module.

### Implementation for User Story 4

- [x] T031 [US4] Bypass in both modes: passthrough on every outlet (both outlets = the source, as the soft path does); extend the
  `BYPASS_EXPECT` entry; native `@bypass` is not used.
- [x] T032 [US4] Unconnected vecfield in sheets mode: composite = source and layer black (the T008 guard); unconnected source:
  black.
- [x] T033 [US4] Two instances in one patch, both in sheets mode, do not interfere. DONE STRUCTURALLY (offline: every new GL object name is
  `#0`-scoped; the one fixed name is the soft stage's `caustic_pix`, kept so soft mode stays bit-identical). **The live two-instance
  check is left to T037**: the bench wrapper takes one module.
- [x] T034 [US4] Measured: at the default `gain` and `scale` 0.3 the sheets layer's mean luma is 0.299 against the soft layer's 0.193, a ratio of
  1.55 (within the 2x target). `k_sheets` is deliberately left at 2.0: it makes the default `gain` 0.5 equal the look Matt approved
  in the look patch (lev = 1), and tuning to 1.0 would change that look.
- [x] T035 [US4] Cost through the real module with the interleaved method: soft mode vs the Phase 0 baseline (the select
  pass only), step 5 vs step 2; record in HANDOFF.md. No single timing is a gate.
- [~] T043 [US4] **DROPPED (Matt, 2026-10-07: "1 frame is fine").** The lag is documented as accepted, not asserted through the module. One unknown stays
  unmeasured and is written into the reference doc: the select stages are triggered by the soft stage's output, so depending on message
  order the sheets result could land one EXTRA frame behind. The spike's `s3b` (`tests/spike_scatter.py`) remains the record of the 1-frame lag
  of the scatter itself.
- [x] T036 [US4] Commit.

**Checkpoint**: every tier-2 criterion in the spec passes; HANDOFF records the cost numbers.

---

## Phase 6: Polish & Cross-Cutting

**Purpose**: Tier 3, documentation, release.

- [ ] T037 (PARTIAL 2026-10-07: Matt confirmed live that the Mode menu and the Detail select work; still to check: two instances, the Detail hitch. **2026-10-08 live-test findings:** Sheets clearly reads better than Soft ("makes soft mode look like crude embossing"); `color_shift`/`softness` show no effect in Sheets — EXPECTED, by design (`codebox_sheets.gen` never reads either Param; spec's param table marks both soft-only), see T047; `detail` has little visible effect on frame rate but the Vsynth *output* resolution clearly does, see T046; `scale` and `gain` both want more headroom than the current ranges give, see T044/T045.) Tier 3: a scratch patch in `~/Vsynth/patterns/` (generated by `scratch/build_caustic_sheets_check.py`) with the REAL
  `f_caustic` on real video; Matt checks the mode switch, `scale` / `gain` ranges, the `detail` hitch, two
  instances, and the default look.
- [x] T038 [P] Update `docs/f-reference/f_caustic.md`: both modes, the new params, the signal flow, outlets, the cost note; also fix its stale signal-flow section (it describes three inlets; the patcher has two: texture + control, and the vecfield).
- [x] T039 (done 2026-10-07: edited in place; the diff is 15 lines; follows the library's vecfield-consumer pattern, a hint comment and no wired field source; `docs/f-reference/f_caustic.md` gained the `## References` section the skill requires; **not yet opened in Max**: check the layout there) [P] Regenerate `package/help/f_caustic.maxhelp` through `build/generate_helpfiles.py` and the helpfile queue.
- [x] T040 Apply the constitution amendment (spec, Decisions item 7) to `.specify/constitution.md` through the
  amend-constitution workflow.
- [x] T041 (done: the README row, which also regenerated `package/extras/f_Launch.maxpat` (the row feeds the launcher; 110-char limit), and two findings added to `skills/jit-gen-codebox/SKILL.md`; **Matt must re-upload that skill and run `./skills/check.sh stamp`**) Update `README.md` (the `f_caustic` row), `HANDOFF.md` and `.specify/plan.md` item 15; add any new
  fact to `skills/jit-gen-codebox/SKILL.md` only if one was found, then `./skills/check.sh` (Matt re-uploads, then
  `stamp`).
- [x] T042 (DONE 2026-10-07: offline 237/237; drift unchanged; the release zip ships `code/f_caustic_sheets.jxs`; `tests/bench.sh --changed` ends with every bench file green on record, `bench_caustic_sheets` 18/18. Note: T020's 16.8 M-point reference jobs stalled Max on 2 of 3 full runs before the lattice was freed after each reference; since then it passes, but it is the suite's most resource-fragile test) Final `./tests/run.sh`, `build/py.sh build/drift.py`, `build/release.sh --working-tree` dry run; commit.
- [x] T044 [DECIDE] `gain` range select (Matt, 2026-10-08): a discrete menu, not a continuous 0-2 dial — `[0.1, 1.0, 2.0]`. **DONE 2026-10-08:** `"range_tiers": [0.1, 1.0, 2.0]` added to `gain` in `definition.py`; `scatter_scene.py` + `build_patcher.py` regenerated; `build/drift.py -v f_caustic` clean; `tests/run.sh` green for every caustic-related file (`test_scatter_mirror` 7/7, `test_scatter_scene` 4/4, `test_module_contracts` 8/8, `test_overrides` 12/12, `test_layout` 12/12, `test_drift` 16/16). Not opened in Max yet.
- [x] T045 [DECIDE] `scale` extended range (Matt, 2026-10-08): push past 1.0, to around 2.5; **confirmed available in both modes** (Matt, 2026-10-08) rather than gated to sheets. **DONE 2026-10-08:** `"range_tiers": [1.0, 2.5]` added to `scale` in `definition.py` (tier 1 = original 0-1, tier 2 = 0-2.5); same build/regen/test pass as T044. Soft mode above 1.0 remains untested by Matt — worth a look next time the module is open in Max.
- [x] T046 Investigate: `detail` barely moves frame rate; Vsynth *output* resolution clearly does (Matt, 2026-10-08). **DONE 2026-10-08:** `tests/spike_caustic_res_cost.py` (diagnostic, not a regression gate) swept `detail` {1, 5} x source size {512^2, 1920x1080, 3840x2160} through the real module (sheets mode) via `cr.period_ms`. First pass (1 sample/cell) was noisy/non-monotonic — cold-bench warmup artifact. Repeated with 3 samples/cell, median: every cell lands at the vsync floor (~16.7 ms, tight ±0.1-0.3 ms spread) regardless of `detail` or size, 4K included — `f_caustic` alone never clears 60 fps in isolation at this config. Conclusion: the composite/select `@adapt 1` resolution-scaling cost is real (per the architecture read) but too small on its own to explain what Matt saw live; the live slowdown is more likely this module's real but modest per-resolution cost compounding on top of an already-near-budget full performance patch, not something specific to `f_caustic`'s own architecture. The bench can't see that (it isolates one module). Matt is checking his demo patch directly for the actual expensive chain; not pursuing further here unless that points back at `f_caustic`.
- [ ] T047 [DECIDE] `color_shift` / `softness` stay visible but inert in Sheets mode — expected per spec (soft-only params), not a bug. Open, not yet decided: leave as-is (simplest; matches that the builder has no per-mode conditional-UI key today) or greyed/hidden when `mode = Sheets` (would need a new schema capability). Low priority — logged so it isn't mistaken for a regression later.

---
## Dependencies & Execution Order

### Phase Dependencies
- Setup -> Foundational (BLOCKS all stories) -> US1 -> US2 -> US3 -> US4 -> Polish.

### User Story Dependencies
- US1: after Foundational. Standalone; the module is untouched.
- US2: after US1 (the ladder is part of the scene). Independently testable on the standalone wrapper.
- US3: after US1 and US2 (it integrates both into `f_caustic`).
- US4: after US3 (it tests the real module).

### Within Each Story
- Codebox and shader files -> scene generator -> wrapper / definition -> build -> tests.
- Verify the codebox on the bench before it is wired (constitution 2).

### Parallel Opportunities
- Phase 1: T003 and T004 (different files); T007-T010 are serial (each uses Max or the build directory).
- Phase 2: T012 and T013 (different files).
- Phase 3: T021 with T019/T020 is possible but uses Max: keep serial.
- Phase 4: T023 alone before T024.
- Phase 6: T038 and T039.

---

## Implementation Strategy

### MVP first
1. Phases 0 and 1 (baseline, mirror, spikes).
2. Phase 2 (US1): sheets mode correct and standalone. **Stop and validate**: Matt can open the standalone wrapper;
   the module has not changed.
3. Then US2, US3, US4 in order.

### Risks and their early warnings
- A builder limit (T009, T010): the fallback is a dedicated build script; decided at T011, before any module change.
- The shader not found from `package/code/` (T007): decided before the shader is written.
- An unconnected pix input reading something that defeats the guard (T008): decided before `codebox_sheets.gen`.
- Soft-mode regression: guarded by the Phase 0 baseline and T027.

---

## Notes

- [P] = different files, no dependencies.
- [US#] = maps a task to its story.
- Stop at any checkpoint to validate independently.
- The bench and any live Vsynth patch share the `vsynth` render context: close one before running the other.
- Commit after each phase checkpoint.
