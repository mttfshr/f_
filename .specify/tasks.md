# Tasks: f_chladni Signal Chain + f_mobius

**Spec**: `.specify/spec.md`
**Plan**: `.specify/plan.md`
**Build order**: Sequential by phase. Complete each phase before the next.
**Branching**: All work on main. Commit per task or logical group.

---

## Expected Source Layout

```
f_/
  patchers/
    f_chladni.maxpat          ← rename target (currently f_cymascope.maxpat)
    f_chladni_audio.maxpat    ← new: audio companion patch
    f_chladni_eeg.maxpat      ← new: EEG companion patch
    f_mobius.maxpat           ← new: Möbius transformation bpatcher
  docs/
    f_chladni.md              ← update: source ref, ph0 description, signal chain
    f_mobius.md               ← new: as-built reference (after Build 2)
  ideas/
    f_mobius.md               ← spec source for Build 2
  README.md                   ← update: patch table
  package-info.json           ← update if patcher name listed
```

---

## Build 1: f_chladni Signal Chain

### Phase 0: Rename

**Purpose**: Get the patcher into its correct name before any other Max work.

⚠️ Do this first — all subsequent Max work opens `f_chladni.maxpat`.

- [ ] T001 Open `patchers/f_cymascope.maxpat` in Max; File → Save As `patchers/f_chladni.maxpat`
- [ ] T002 Verify `f_chladni.maxpat` opens correctly and Vsynth loads it without errors
- [ ] T003 Update source file reference in `docs/f_chladni.md`
- [ ] T004 Check `package-info.json` for patcher name references; update if present
- [ ] T005 Update `README.md` patch table: rename f_cymascope row → f_chladni

**Checkpoint**: `f_chladni.maxpat` exists; loads in Vsynth; `docs/` and `README.md` consistent.

---

### Phase 1: ph0 Fix

**Purpose**: Resolve dead ph0 parameter before signal chain. Isolates any visual regression to this change.

- [ ] T006 Open codebox in `f_chladni.maxpat`; change per-mode phase to `(ph_m + ph0)` across all 8 modes
- [ ] T007 Verify: moving ph0 slider visibly rotates/shifts the nodal pattern globally
- [ ] T008 Update `docs/f_chladni.md` parameter table: ph0 → "Global phase offset applied to all modes"

**Checkpoint**: ph0 produces visible global phase shift; no regression in other parameters.

---

### Phase 2: Audio Companion Patch

**Purpose**: Primary signal chain deliverable. No hardware dependency — testable with any mic.

- [ ] T009 Create `patchers/f_chladni_audio.maxpat`
- [ ] T010 Build `adc~ → biquad~ × 8` filter bank DSP chain
- [ ] T011 [P] Compute Log frequency set: 8 bands geometrically spaced ~80Hz–8kHz; store in patch (coll or message list)
- [ ] T012 [P] Compute Bessel frequency set: 8 bands at Bessel-zero ratios; choose reference fundamental; document choice in patch comment
- [ ] T013 Add `umenu` (Log / Bessel); wire to swap active frequency set into `biquad~` coefficients on selection
- [ ] T014 Wire `biquad~ × 8 → peakamp~ × 8 → slide~ × 8` (attack ~10ms)
- [ ] T015 Add master gain scaling all 8 outputs
- [ ] T016 Add per-band level meters (`meter~` or `number~` per band)
- [ ] T017 Route 8 outputs: `m0amp $1` … `m7amp $1` messages
- [ ] T018 Test with mic: speech and varied tones visibly animate Chladni figure across multiple modes
- [ ] T019 Test tuning toggle: switch Bessel ↔ Log while signal active; confirm no audible click or visual snap

**Checkpoint**: Mic input drives Chladni figure; all 8 modes respond; tuning toggle switches cleanly.

---

### Phase 3: EEG Companion Patch

**Purpose**: EEG signal chain. Requires Muse headset. Measurement pass mandatory before building.

- [ ] T020 Measurement pass: connect Muse; open `udpreceive`; print raw OSC values; record actual range per band; document in patch comment
- [ ] T021 Create `patchers/f_chladni_eeg.maxpat`
- [ ] T022 Build `udpreceive [port] → route` by Muse band name (exact OSC addresses from measurement pass)
- [ ] T023 Scale each of the 7 bands from measured raw range → 0.0–1.0 via `scale` per band
- [ ] T024 Smooth each scaled band via `line` ~150ms ramp time
- [ ] T025 Compute m7 total power: sum 7 smoothed band values / 7; output as `m7amp $1`
- [ ] T026 Add master gain and per-band level meters (match audio patch UI convention)
- [ ] T027 Route outputs: `m0amp $1` … `m7amp $1`
- [ ] T028 Test: Muse headset animates figure; transitions smooth; no visible 10Hz stepping; m7 reflects overall activity

**Checkpoint**: Muse drives figure smoothly; all 8 modes active; 10Hz update rate hidden.

---

### Phase 4: view_mode Verification

**Purpose**: Confirm view_mode blend works with a live signal — implemented but never tested with real input.

- [ ] T029 With `f_chladni_audio.maxpat` running and mic active, blend `view_mode` 0 → 1
- [ ] T030 Confirm circular ↔ strip transition smooth; no artifacts at boundary
- [ ] T031 Document result in `docs/f_chladni.md` loose threads section; file follow-up tasks if issues found

**Checkpoint**: view_mode blend confirmed working, or issues documented.

---

### Phase 5: f_chladni Docs Cleanup

**Purpose**: Leave Build 1 in a clean, fully documented state.

- [ ] T032 Update `docs/f_chladni.md`: signal chain section (as-built audio and EEG paths); loose threads (ph0 resolved, view_mode status); ph0 parameter description
- [ ] T033 Update `.specify/spec.md`: mark f_chladni active development items resolved
- [ ] T034 Update `tasks.md`: mark T001–T033 complete; confirm backlog is current

**Checkpoint**: docs/, spec.md, tasks.md all reflect actual build state.

---

## Build 2: f_mobius

### Phase 6: Codebox Math

**Purpose**: Verify complex arithmetic and full transform in codebox before building patcher wrapper. Write as plain text; paste into Max manually.

- [ ] T035 Write `cmul` and `cdiv` helpers for vec2 complex arithmetic in codebox
- [ ] T036 Implement center offset: translate UV by `-(cx, cy)` before transform, `+(cx, cy)` after
- [ ] T037 Implement rotate + zoom path: compute rotation matrix from `rotate` (0–1 → 0–2π); apply log-mapped zoom `pow(10.0, (zoom-0.5))`
- [ ] T038 Implement inversion path: `1/z` in complex arithmetic with mirror edge guard (clamp or modulo UV post-transform)
- [ ] T039 Blend identity and inversion paths by `invert` param: `mix(rotate_zoom_result, inversion_result, invert)`
- [ ] T040 Test case 1: `invert=0, rotate=0, zoom=0.5` → pixel-perfect passthrough (sample at original UV)
- [ ] T041 Test case 2: `invert=1, cx=0.5, cy=0.5` → clean inside-out inversion (center expands, edges contract)
- [ ] T042 Test case 3: `invert=0, rotate=0.25` → 90° rotation of sampling coordinates (horizontal stripes → vertical)

**Checkpoint**: All 3 test cases pass in codebox; no NaN/inf escaping; mirror edges clean.

---

### Phase 7: f_mobius Patcher Build

**Purpose**: Wire confirmed codebox into standard Vsynth bpatcher structure.

- [ ] T043 Create `patchers/f_mobius.maxpat`; add `jit.gl.pix vsynth @name mob_pix`
- [ ] T044 Add texture inlet → `routepass jit_gl_texture jit_matrix`; add control inlet → `route bypass cx cy rotate zoom invert`
- [ ] T045 [P] Add `live.dial` for `cx` (0–1, default 0.5, param_connect mob_pix::cx)
- [ ] T046 [P] Add `live.dial` for `cy` (0–1, default 0.5, param_connect mob_pix::cy)
- [ ] T047 [P] Add `live.dial` for `rotate` (0–1, default 0.0, param_connect mob_pix::rotate)
- [ ] T048 [P] Add `live.dial` for `zoom` (0–1, default 0.5, param_connect mob_pix::zoom)
- [ ] T049 [P] Add `live.dial` for `invert` (0–1, default 0.0, param_connect mob_pix::invert)
- [ ] T050 Add `bypass_toggle.js` (jsui); wire route → bypass_toggle → prepend param bypass → pix
- [ ] T051 Wire all dials → `prepend param <name>` → pix in0
- [ ] T052 Add title comment and background panel (Ableton Sans Light, black bg, blue border)
- [ ] T053 Add `moduleSize.js` chain (loadbang → getattr presentation_rect → thispatcher → zl slice 2 → prepend tam → js moduleSize.js)
- [ ] T054 Add `parameters` block at end of JSON; register all 6 params (cx, cy, rotate, zoom, invert, bypass)
- [ ] T055 Verify: loads in Vsynth; bypass toggles; all 6 params respond to named messages on in1
- [ ] T056 Exploration session: test loxodromic range (invert 0.2–0.8 + rotate); note expressive sweet spots

**Checkpoint**: f_mobius.maxpat loads in Vsynth; all params controllable; bypass works; xy encoder drives cx/cy via named messages.

---

### Phase 8: f_mobius Docs

**Purpose**: Graduate f_mobius from ideas/ to docs/.

- [ ] T057 Create `docs/f_mobius.md` as-built reference: params as actually built, zoom range chosen, any deviations from `ideas/f_mobius.md`, known sweet spots from exploration session
- [ ] T058 Update `.specify/spec.md`: f_mobius status → built; note f_stereo and f_poincare as unblocked
- [ ] T059 Update `tasks.md`: mark T035–T058 complete; add f_stereo/f_poincare to backlog if not present

**Checkpoint**: docs/f_mobius.md exists; spec.md and tasks.md reflect completed state.

---

## Dependencies & Execution Order

```
Build 1:
  Phase 0 (Rename) → Phase 1 (ph0) → Phase 2 (Audio) → Phase 4 (view_mode)
  Phase 0 (Rename) → Phase 3 (EEG)   [can parallel Phase 2 if Muse available]
  Phase 2 + Phase 3 + Phase 4 → Phase 5 (Docs)
  Phase 5 complete → Build 2 begins

Build 2:
  Phase 6 (Codebox) → Phase 7 (Patcher) → Phase 8 (Docs)
```

### Parallel Opportunities
- **T011 + T012** — Log and Bessel frequency computation; independent calculations
- **T020** (Muse measurement) — can run alongside Phase 1 if Muse is available
- **Phase 2 + Phase 3** — if Muse is to hand and two sessions are running simultaneously
- **T045–T049** — all 5 live.dial additions in Phase 7 are independent of each other

### Within-Phase Dependencies
- Phase 2: T010 → T011/T012 → T013 → T014 → T015/T016 → T017 → T018 → T019
- Phase 3: T020 → T021 → T022 → T023 → T024 → T025 → T026 → T027 → T028
- Phase 6: T035 → T036 → T037 → T038 → T039 → T040/T041/T042
- Phase 7: T043 → T044 → T045–T050 → T051 → T052 → T053 → T054 → T055 → T056

---

## Implementation Strategy

**Start with Phase 0 + 1** — quick (< 30 min total); unblocks everything in Build 1.

**Audio patch first (Phase 2)** — no hardware dependency; verifiable immediately.

**EEG patch (Phase 3)** — budget a dedicated hardware session; measurement pass is mandatory before building.

**Build 2 begins after Phase 5** — f_mobius codebox-first; write math as plain text, paste into Max, verify before touching patcher JSON.

**Stop at any phase checkpoint** — each phase leaves the system in a working, committable state.

---

## Backlog (Out of Scope for This Plan)

- Scope review — taxonomy, optics family vs circular screen sequencing
- f_stereo — stereographic projection; unblocked after f_mobius
- f_sharmonics — spherical harmonics visualizer; needs f_stereo first
- f_poincare — Poincaré disk; unblocked after f_mobius
- f_cymascope feasibility check
- Help patches (f_texrouter first — bypass=freeze must be documented)
- f_chladni near-center singularity (low priority)
- f_chladni plate shape morphing (hold for scope review)
- Optics family (pending scope review)
- Apollonian fractal

---

## Done (Recent)

- [x] Repo migration — docs/, ideas/ structure
- [x] spec.md — all planned work consolidated
- [x] spec clarified — 3 ambiguities resolved
- [x] plan.md — written and updated (this file supersedes previous version)
- [x] f_mobius specced — ideas/f_mobius.md, ideas/circular_screen.md
- [x] f_chladni initial build (as f_cymascope) — Bessel mode visualizer, 8 modal amps, confirmed working visually
