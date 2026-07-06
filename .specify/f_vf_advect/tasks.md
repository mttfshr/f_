# Tasks: f_vf_advect

**Spec**: `.specify/f_vf_advect/spec.md`
**Plan**: `.specify/f_vf_advect/plan.md`
**Build order**: Sequential. Complete each phase before the next. Phase 1 (scratch) is the hard gate — codeboxes are frozen before any build work begins.

---

## Expected Artifacts

```
patchers/
└── f_vf_advect.maxpat              # Built patcher (distributed artifact)

.specify/f_vf_advect/
├── spec.md                         # ✅ Done
├── plan.md                         # ✅ Done
├── tasks.md                        # ✅ This file
├── build_advect.py                 # Per-module build script
└── codebox_advect.gen              # Frozen advect_pix codebox (from scratch)

~/Vsynth/patterns/
└── advect_scratch.maxpat           # Scratch patch (not committed)
```

---

## Phase 1: Scratch patch — codebox verification

**Purpose:** Write and verify both codeboxes in a live Max environment before any build work. The pass_pix codebox is trivial; the advect_pix codebox contains all the logic. Confirm `#0_` name scoping with two instances. **Nothing proceeds until this phase is complete and codeboxes are frozen.**

⚠️ CRITICAL: Do not write build_advect.py until Phase 1 is complete.

- [ ] T001 Open `~/Vsynth/patterns/` and create `advect_scratch.maxpat` with a vs_render, a noise or video source, and an f_vf_vortex
- [ ] T002 Add pass_pix inside the scratch patch: `jit.gl.pix vsynth @name #0_vfadvect_pass @type char @adapt 1` with a trivial gen subpatcher (`in 1 → out 1`)
- [ ] T003 Add advect_pix: `jit.gl.pix vsynth @name #0_vfadvect_pix @type char @adapt 1` with 3 gen inlets (`in 1` source, `in 2` vecfield, `in 3` previous frame) and the advect codebox
- [ ] T004 Wire feedback loop: `advect_pix out0 → pass_pix in0`, `pass_pix out0 → advect_pix in2` (gen in3)
- [ ] T005 Wire inputs: source → advect_pix in0 (gen in1), f_vf_vortex → vs_inState → advect_pix in1 (gen in2), vs_inState out1 → prepend param src_vecfield → advect_pix in0
- [ ] T006 Add sliders/dials for `dt`, `decay`, `injection`, `mix_amt`, `bypass`, `src_vecfield` and connect via attrui or message boxes to advect_pix
- [ ] T007 Verify advect codebox: flow accumulates along vortex streamlines over multiple frames with default params (dt=0.02, decay=0.95, injection=0.05)
- [ ] T008 Verify `src_vecfield` suppression: disconnect f_vf_vortex, confirm no diagonal drift artifact — content decays in place only
- [ ] T009 Verify each parameter in isolation: dt=0 stops flow; decay=0 clears each frame; injection=0 decays to black; mix=0 shows raw source; bypass=1 shows source with loop warm
- [ ] T010 Verify `@adapt 1`: connect a source at a different resolution from vs_render output — confirm no black output or resolution mismatch artifact
- [ ] T011 Verify `#0_` scoping: duplicate the bpatcher (or add a second identical block) in the same patch — confirm both instances advect independently with separate feedback state
- [ ] T012 Copy finalized advect_pix codebox content to `.specify/f_vf_advect/codebox_advect.gen` — this is the frozen source of truth

**Checkpoint:** Flow is visible and correct. All params work as specced. Two instances are independent. Codeboxes frozen. Do not modify codebox_advect.gen after this point.

---

## Phase 2: Build script

**Purpose:** Write `build_advect.py` that generates the full bpatcher JSON from the frozen codebox, following the same pattern as `build_caustic.py`.

- [ ] T013 Create `.specify/f_vf_advect/build_advect.py` — copy boilerplate from `build_caustic.py` (constants, wire/box helpers, moduleSize chain, bypass, param loop)
- [ ] T014 Define module identity constants in `build_advect.py`: `NAME`, `PREFIX` (`vfadvect`), `OBJECT_NAME` (`vfadvect_pix`), `PASS_NAME` (`vfadvect_pass`), `TITLE` (`Advect`), `PW`, `PH`
- [ ] T015 Define `PARAMS` list in `build_advect.py`: `dt` (float, 0–0.1, default 0.02), `decay` (float, 0–1, default 0.95), `injection` (float, 0–1, default 0.05), `mix` (float, 0–1, default 1.0); `src_vecfield` as internal (not in PARAMS loop — driven by vs_inState)
- [ ] T016 Write `gen_subpatcher_pass()` in `build_advect.py`: trivial 1-inlet gen (`in 1 → out 1`)
- [ ] T017 Write `gen_subpatcher_advect()` in `build_advect.py`: 3-inlet gen (`in 1` source, `in 2` vecfield, `in 3` previous frame) wired to codebox with content from `codebox_advect.gen`; codebox `numinlets=3`, `numoutlets=1`
- [ ] T018 Add pass_pix box in `build_advect.py` (`obj-50`): `jit.gl.pix vsynth @name #0_vfadvect_pass @type char @adapt 1`, numinlets=1, patcher=gen_subpatcher_pass()
- [ ] T019 Add advect_pix box in `build_advect.py` (`obj-5`): `jit.gl.pix vsynth @name #0_vfadvect_pix @type char @adapt 1`, numinlets=3 (source in0, vecfield in1, previous in2), patcher=gen_subpatcher_advect()
- [ ] T020 Add vecfield inlet (`obj-51`), vs_inState (`obj-52`), prepend param src_vecfield (`obj-53`) boxes in `build_advect.py`
- [ ] T021 Wire patchlines in `build_advect.py`: feedback loop (`advect_pix out0 → pass_pix in0`, `pass_pix out0 → advect_pix in2`), vecfield chain (`inlet → vs_inState → advect_pix in1`; `vs_inState out1 → prepend src_vecfield → advect_pix in0`), outlet (`advect_pix out0 → outlet`)
- [ ] T022 Run `python3 .specify/f_vf_advect/build_advect.py` and validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_advect.maxpat')); print('valid')"`
- [ ] T023 Inspect generated JSON: confirm numinlets on advect_pix=3, pass_pix=1; confirm feedback wire and pass wire both present; confirm vs_inState wired correctly; confirm src_vecfield absent from route args

**Checkpoint:** `f_vf_advect.maxpat` is valid JSON. Structural inspection passes.

---

## Phase 3: Vsynth integration testing

**Purpose:** Open the built patcher in a live Vsynth patch and verify all spec acceptance criteria.

- [ ] T024 Load `f_vf_advect.maxpat` as a bpatcher in a Vsynth patch; connect source → in0, f_vf_vortex → in1; confirm patch loads without errors or console warnings
- [ ] T025 Verify basic advection: content flows along vortex streamlines and accumulates over multiple frames at default params
- [ ] T026 Verify `src_vecfield` suppression in built patcher: disconnect vecfield inlet, confirm no diagonal drift
- [ ] T027 Verify all four user params save and restore via autopattr: close and reopen the patch, confirm dt/decay/injection/mix values are retained
- [ ] T028 Verify bypass: enable bypass, confirm output matches source; disable, confirm accumulated state is restored (loop was warm)
- [ ] T029 Verify two instances: add a second f_vf_advect bpatcher to the same Vsynth patch; connect different sources/fields; confirm independent feedback state
- [ ] T030 Test with f_vf_vortex_multi and f_vf_fieldmap as vecfield sources; confirm no artifacts
- [ ] T031 Save and reload the full Vsynth patch; confirm no crash and no parameter reset

**Checkpoint:** All acceptance criteria from spec pass. Two independent instances confirmed. Save/load cycle clean.

---

## Phase 4: Docs and registration

**Purpose:** Update permanent project records. No build work.

- [ ] T032 Update `ideas/f_vf_advect.md`: change status to Built, note Pattern 1 architecture and build date
- [ ] T033 Update `README.md`: add `f_vf_advect` row to bpatcher table (Processor, "Temporal fluid advection via f_vecfield — accumulates flow across frames")
- [ ] T034 Add `f_vf_advect` to Vecfield category in `.specify/f_modules/build_modules.py`: label "Advect", size entry matching `PW`/`PH`
- [ ] T035 Add `f_vf_advect` size entry to `javascript/f_addmod.js`
- [ ] T036 Regenerate `f_modules.maxpat`: `python3 .specify/f_modules/build_modules.py`; validate JSON; confirm Advect appears in Vecfield category
- [ ] T037 Add build_patcher.py multi-pix extension to `.specify/plan.md` work queue as a follow-on task (item 8 or similar)
- [ ] T038 Commit: `git add patchers/f_vf_advect.maxpat README.md javascript/f_addmod.js patchers/f_modules.maxpat && git commit -m "feat: f_vf_advect — temporal fluid advection via vecfield"`

**Checkpoint:** README updated. f_modules menu includes Advect. Committed.

---

## Dependencies

```
Phase 1 (Scratch) ──→ Phase 2 (Build) ──→ Phase 3 (Integration) ──→ Phase 4 (Docs)
     ↑ HARD GATE           ↑ JSON valid           ↑ All criteria pass
  Codeboxes frozen
  before T013
```

**Within Phase 2:** T013–T015 (setup) → T016–T019 (pix objects) → T020–T021 (wiring) → T022–T023 (validate). Sequential; each task builds on the previous.

**Within Phase 3:** T024 (load) must pass before other Phase 3 tasks. T025–T031 can be verified in any order once the patch loads.

**Within Phase 4:** T032–T036 are independent of each other [P]. T037–T038 depend on T032–T036 all being done.

---

## Notes

- The pass_pix codebox is trivial — no need to save it separately. The advect_pix codebox (T012) is the one that must be frozen before Phase 2.
- If `#0_` scoping fails in T011 (two instances share state), do not proceed to Phase 2. Investigate the correct Vsynth scoping mechanism for `jit.gl.pix @name` before continuing.
- If `@adapt 1` causes issues in T010, test without it and with explicit `@dim` matching the Vsynth render resolution. Document the finding before proceeding.
- Object IDs in build_advect.py: standard infrastructure uses obj-1 through obj-16; advect_pix is obj-5; pass_pix and vecfield objects use obj-50+; param UI objects use obj-20+. Post-build injections (if any) should use obj-200+.
