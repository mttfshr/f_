# Tasks: f_vortex_multi

**Spec**: .specify/f_vortex_multi/spec.md
**Plan**: .specify/f_vortex_multi/plan.md
**Build order**: Sequential. Complete each phase before next.
**Branching**: All work on main. Commit after each verified milestone.

---

## Expected Source Layout

```
f_/
  patchers/
    f_vortex_multi.maxpat          — final production patcher
  .specify/f_vortex_multi/
    spec.md                        — done
    plan.md                        — done
    tasks.md                       — this file
    definition.py                  — written in Phase 2
  ~/Vsynth/patterns/
    vortex_multi_scratch.maxpat    — scratch patch (not version controlled)
```

---

## Phase 1: Scratch Codebox Verification (BLOCKING)

**Purpose**: Verify the three-site additive field math works correctly on GPU before writing any patcher JSON. Exit criterion gates all subsequent phases.

⚠️ CRITICAL: Do not write definition.py until codebox is confirmed working in scratch patch.

- [ ] T001 Write three-site additive vortex codebox in plain text — three unrolled copies of f_vortex math with s1_/s2_/s3_ prefixes, summed fx/fy, encoded to RG float32
- [ ] T002 Open scratch patch at ~/Vsynth/patterns/ with vs_render running; paste codebox into jit.gl.pix gen subpatcher
- [ ] T003 Wire f_caustic downstream in scratch patch; confirm three caustic hot spots appear at default site positions (0.3/0.3, 0.5/0.5, 0.7/0.7)
- [ ] T004 Test superposition: move all three sites to same position; confirm single bright caustic zone (additive intensity)
- [ ] T005 Test falloff sweep: confirm caustic clusters tighten at high falloff and spread/merge at low falloff
- [ ] T006 Test per-site independence: set s1 convergence to zero; confirm site 1 hot spot disappears, sites 2 and 3 unchanged
- [ ] T007 Test curl independence: set s1 curl positive, s2 curl negative; confirm opposite spiral character in f_caustic output
- [ ] T008 Simulate position animation: drive s1_cx/s1_cy via numboxes in scratch patch; confirm hot spot tracks position correctly

**Checkpoint**: f_caustic shows correct multi-focal behavior. All three sites independently controllable. Codebox compiles without errors on GPU.

---

## Phase 2: definition.py

**Purpose**: Encode confirmed codebox and full param contract into the build input file.

- [ ] T009 [US1,US2,US4,US5] Write .specify/f_vortex_multi/definition.py — archetype: dual-mode generator; 13 params (s1_cx, s1_cy, s1_conv, s1_curl, s2_cx, s2_cy, s2_conv, s2_curl, s3_cx, s3_cy, s3_conv, s3_curl, falloff); bypass toggle
- [ ] T010 [US1,US2,US4,US5] Set param defaults: s1 at (0.3, 0.3), s2 at (0.5, 0.5), s3 at (0.7, 0.7); all conv=0.5, all curl=0.0, falloff=2.0
- [ ] T011 [US1,US2,US4,US5] Set param ranges: cx/cy 0–1, conv 0–1, curl -1–1, falloff 0–10
- [ ] T012 [US1,US2,US4,US5] Run python3 tools/build_patcher.py to generate patchers/f_vortex_multi.maxpat
- [ ] T013 [US1,US2,US4,US5] Validate JSON: python3 -c "import json; json.load(open('patchers/f_vortex_multi.maxpat'))"
- [ ] T014 [US1,US2,US4,US5] Load f_vortex_multi.maxpat in Max; confirm no errors on load, pix compiles, dials present

**Checkpoint**: Patcher loads cleanly in Max. All 13 params visible and functional. Caustic output correct with static dial positions.

---

## Phase 3: Position Inlet Wiring (US3)

**Purpose**: Add three independent position inlets accepting center messages from vsc_center_ctrl.

- [ ] T015 [US3] Open f_vortex_multi.maxpat in Max (or edit JSON directly); add inlet 1 with comment "site 1 pos"
- [ ] T016 [US3] Wire inlet 1 → routepass jit_gl_texture jit_matrix → route center → unpack f f → s1_cx dial + s1_cy dial
- [ ] T017 [US3] Add inlet 2 with comment "site 2 pos"; wire same pattern to s2_cx / s2_cy dials
- [ ] T018 [US3] Add inlet 3 with comment "site 3 pos"; wire same pattern to s3_cx / s3_cy dials
- [ ] T019 [US3] Validate JSON after edits: python3 -c "import json; json.load(open('patchers/f_vortex_multi.maxpat'))"
- [ ] T020 [US3] Test: send center 0.2 0.8 to inlet 1 manually; confirm s1_cx/s1_cy dials update and hot spot moves
- [ ] T021 [US3] Connect vsc_center_ctrl to inlet 1; confirm position tracks controller output
- [ ] T022 [US3] Connect three vsc_center_ctrl instances (each driven by vs_lfo at different rates); confirm three hot spots orbit independently

**Checkpoint**: US3 acceptance scenarios pass. Three sites fully independently animatable via vsc_center_ctrl.

---

## Phase 4: Vsynth Integration Verification

**Purpose**: Confirm f_vecfield type contract compliance and drop-in f_vortex compatibility.

- [ ] T023 [US4] Swap f_vortex_multi for f_vortex in existing f_caustic signal chain; confirm f_caustic output correct with no other changes
- [ ] T024 [US4] Connect f_vortex_multi to vs_displacement; confirm spatially coherent displacement visible
- [ ] T025 [US5] Enable bypass toggle; confirm f_caustic downstream shows no caustic (neutral field)
- [ ] T026 [US5] Toggle bypass off; confirm caustic pattern returns immediately
- [ ] T027 [US3] Run full orbital motion test: three vsc_center_ctrl at different LFO rates; record that three hot spots orbit independently with no cross-interference

**Checkpoint**: All spec acceptance scenarios verified. Module is production-ready.

---

## Phase 5: Documentation and Commit

- [ ] T028 Update README.md: add f_vortex_multi row to patch table (Generator, "Three-site additive vortex field — f_vecfield producer")
- [ ] T029 Update docs/f-reference/f_vecfield_type.md: mark f_vortex_multi as Complete in family members table
- [ ] T030 Update HANDOFF.md with session state
- [ ] T031 Commit: "feat: f_vortex_multi — three-site additive vortex field generator"

**Checkpoint**: All docs current. Clean commit.

---

## Dependencies & Execution Order

### Phase Dependencies
- Phase 1 (scratch) → BLOCKS Phase 2 (definition.py)
- Phase 2 (build) → BLOCKS Phase 3 (position inlets)
- Phase 3 (position inlets) → BLOCKS Phase 4 (integration)
- Phase 4 (integration) → Phase 5 (docs)

### Within Phase 1
- T001 (write codebox) must complete before T002 (paste into Max)
- T003–T008 are sequential verification steps; each builds on prior

### Within Phase 2
- T009–T011 (write definition.py) before T012 (build)
- T013 (validate JSON) before T014 (load in Max)

### Within Phase 3
- T015–T018 (add inlets) before T019 (validate JSON)
- T019 (validate) before T020–T022 (test)

---

## Notes

- [US#] = maps task to user story from spec
- Scratch patch (Phase 1) is the most important phase — do not skip or abbreviate
- Position inlet wiring (Phase 3) may be done via direct JSON edit or in Max — JSON edit preferred for precision
- If build_patcher.py doesn't support three extra inlets natively, add them via Python JSON edit post-build (same pattern as f_caustic build)
