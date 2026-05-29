# Tasks: f_lens

**Spec**: .specify/f_lens/spec.md
**Plan**: .specify/f_lens/plan.md
**Build order**: Sequential by phase. Complete each phase checkpoint before proceeding.

---

## Architecture Note (as-built, supersedes original spec)

Final architecture diverged from original spec during Phase 3/4:
- **5 inlets**: in0 (texture+ctrl), in1 (aberration mod), in2 (distortion mod), in3 (transmission mod), in4 (surface mod)
- **Surface** → gradient emboss (UV displacement via in5 gradient), not darkening multiply
- **Field** → split into 3 independent targets: aberration_mod, distortion_mod, transmission_mod
- **8 front dials**: aberration, distortion, transmission, tilt, tilt_axis, tilt_pos, slope, mode
- **4 back dials** (field panel): aberration_mod, distortion_mod, transmission_mod, surface_mod
- **lens/field toggle** button scripts visibility via lens_toggle.js → thispatcher script sendbox
- **lens_toggle.js** added to code/

---

## Phase 0: Feasibility ✅

- [x] T001–T006 Architecture decided and documented

---

## Phase 1: Radially Symmetric Effects ✅

- [x] T008–T013 aberration, distortion, transmission — all working in scratch patch

---

## Phase 2: Tilt-Shift ✅

- [x] T014–T019 jit.fx.cf.tiltshift wired and verified; lens_tiltcenter.js perpendicular fix applied

---

## Phase 3: in2/in3 Modulation ✅ (redesigned)

Original plan (surface_amt darkening + field_amt distortion) was replaced with:

- [x] T020 Codebox redesigned: aberration_mod, distortion_mod, transmission_mod, surface_mod
- [x] T021 distortion_mod: spatially varies k via in3 texture; neutral guard confirmed (black = no effect)
- [x] T022 surface_mod: gradient emboss via in5; UV displacement from in5 gradient; neutral guard confirmed
- [x] T023 aberration_mod: spatially varies ab via in2; neutral guard confirmed
- [x]      transmission_mod: spatially varies vignette dist via in4; neutral guard confirmed

---

## Phase 4: Build Script → f_lens.maxpat ✅

- [x] T024–T027 Build script written at ~/Vsynth/patterns/build_f_lens.py
- [x] T028 UI layout: front 8 dials (2 rows × 4), back 4 dials (1 row), lens/field toggle, bypass
- [x] T029 parameters block complete (bypass, panel_toggle, 8 front + 4 back dials)
- [x] T030 Build script runs clean; output written to patchers/f_lens.maxpat
- [x] T031 Opens in Max without errors; presentation layout correct; toggle verified working
- [x]      lens_toggle.js uses script sendbox (not script visible) — confirmed working

---

## Phase 5: Vsynth Integration and Composition ← NEXT

- [ ] T032 Load f_lens in Vsynth context with vs_noise_3 → in0; sweep each param
- [ ] T033 Verify bypass passthrough
- [ ] T034 Verify autopattr state save/restore
- [ ] T035 Verify moduleSize.js chain reports correct size
- [ ] T036 Test f_grain → f_lens → output
- [ ] T037 Test f_grain → f_lens → f_stereo → output
- [ ] T038 Test aberration_mod and distortion_mod inlets with f_grain and slow noise sources
- [ ] T039 Test transmission_mod with slow noise
- [ ] T040 Test surface_mod (emboss) with f_grain — verify micro-refraction character vs old darkening
- [ ] T041 Test named float messages on in0 (aberration 0.5, tilt 0.8, etc.)
- [ ] T042 Check frame rate: no significant GPU drop vs baseline

---

## Phase 6: Documentation

- [ ] T043 Write docs/f_lens.md — as-built reference
- [ ] T044 Update README.md: f_lens → ✅ Working
- [ ] T045 Update HANDOFF.md with session summary
