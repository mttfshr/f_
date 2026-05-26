# Tasks: f_chladni Signal Chain

**Spec**: `.specify/f_chladni/spec.md`
**Plan**: `.specify/f_chladni/plan.md`
**Build order**: Sequential by phase. Commit per task or logical group.

---

## Phase 0: Rename

- [x] T001 Open `patchers/f_cymascope.maxpat` in Max; File → Save As `patchers/f_chladni.maxpat`
- [x] T002 Verify `f_chladni.maxpat` opens correctly and Vsynth loads it
- [x] T003 Update source file reference in `docs/f_chladni.md`
- [x] T004 Check `package-info.json`; update if patcher name present
- [x] T005 Update `README.md` patch table: f_cymascope → f_chladni

**Checkpoint**: `f_chladni.maxpat` exists; loads in Vsynth; docs and README consistent.

---

## Phase 1: ph0 Fix

- [x] T006 Open codebox in `f_chladni.maxpat`; change per-mode phase to `(ph_m + ph0)` across all 8 modes
- [x] T007 Verify: ph0 slider visibly shifts nodal pattern globally
- [x] T008 Update `docs/f_chladni.md` parameter table: ph0 → "Global phase offset applied to all modes"

**Checkpoint**: ph0 produces visible global phase shift; no regression in other params.

---

## Phase 2: Audio Companion Patch

- [x] T009 Create `patchers/f_chladni_audio.maxpat`
- [x] T010 Build `adc~ → biquad~ × 8` filter bank DSP chain
- [x] T011 [P] Compute Log frequency set: 8 bands geometrically spaced ~80Hz–8kHz; store in patch
- [x] T012 [P] Compute Bessel frequency set: 8 bands at Bessel-zero ratios; choose and document reference fundamental
- [x] T013 Add `umenu` (Log / Bessel); wire to swap frequency set into `biquad~` coefficients
- [x] T014 Wire `biquad~ × 8 → abs~ × 8 → slide~ × 8` (attack ~10ms)
- [x] T015 Add master gain scaling all 8 outputs
- [x] T016 Add per-band level meters (`meter~` or `number~` per band)
- [x] T017 Route outputs: `m0amp $1` … `m7amp $1`
- [ ] T018 Test with mic: speech and varied tones animate figure across modes
- [ ] T019 Test tuning toggle: Bessel ↔ Log while signal active; no click or visual snap

**Checkpoint**: Mic drives Chladni figure; all 8 modes respond; tuning toggle clean.

---

## Phase 3: EEG Companion Patch

- [ ] T020 Measurement pass: connect Muse; print raw OSC values; record range per band; document in patch comment
- [ ] T021 Create `patchers/f_chladni_eeg.maxpat`
- [ ] T022 Build `udpreceive [port] → route` by Muse band name
- [ ] T023 Scale each band raw → 0.0–1.0 via `scale` per band using measured range
- [ ] T024 Smooth each band via `line` ~150ms ramp
- [ ] T025 Compute m7: sum 7 bands / 7; output as `m7amp $1`
- [ ] T026 Add master gain and per-band meters (match audio patch convention)
- [ ] T027 Route outputs: `m0amp $1` … `m7amp $1`
- [ ] T028 Test: Muse animates figure; smooth transitions; no 10Hz stepping; m7 reflects overall activity

**Checkpoint**: Muse drives figure smoothly; all 8 modes active; 10Hz rate hidden.

---

## Phase 4: view_mode Verification

- [ ] T029 With audio patch running and mic active, blend `view_mode` 0 → 1
- [ ] T030 Confirm circular ↔ strip transition smooth; no artifacts
- [ ] T031 Document result in `docs/f_chladni.md`; file follow-up tasks if issues found

**Checkpoint**: view_mode blend confirmed working or issues documented.

---

## Phase 5: Docs Cleanup

- [ ] T032 Update `docs/f_chladni.md`: signal chain as-built, loose threads resolved, ph0 description updated
- [ ] T033 Update `.specify/f_chladni/tasks.md`: mark T001–T032 complete
- [ ] T034 Update `HANDOFF.md`: reflect f_chladni signal chain complete; f_mobius as next active

**Checkpoint**: All docs consistent with as-built state. Build complete.

---

## Parallel Opportunities

- **T011 + T012** — Log and Bessel frequency computation are independent
- **T020** — Muse measurement pass can run alongside Phase 1 if hardware is available
- **Phase 2 + Phase 3** — can run in parallel if Muse is available during audio patch session
