# Tasks: f_chladni Signal Chain

**Spec**: `.specify/spec.md`
**Plan**: `.specify/plan.md`
**Build order**: Sequential by phase. Complete each phase before next.
**Branching**: All work on main. Commit per task or logical group.

---

## Expected Source Layout

```
f_/
  patchers/
    f_chladni.maxpat          ← rename target (currently f_cymascope.maxpat)
    f_chladni_audio.maxpat    ← new: audio companion patch
    f_chladni_eeg.maxpat      ← new: EEG companion patch
  docs/
    f_chladni.md              ← update: source ref, ph0 description, signal chain section
  README.md                   ← update: patch table
  package-info.json           ← update if patcher name listed
```

---

## Phase 0: Rename

**Purpose**: Get the bpatcher file into its correct name before any other Max work.

⚠️ Do this first — all subsequent Max work opens `f_chladni.maxpat`.

- [ ] T001 Open `patchers/f_cymascope.maxpat` in Max; File → Save As `patchers/f_chladni.maxpat`
- [ ] T002 Verify `f_chladni.maxpat` opens correctly and Vsynth loads it without errors
- [ ] T003 Update source file reference in `docs/f_chladni.md` (last line: "Source File")
- [ ] T004 Check `package-info.json` for patcher name references; update if present
- [ ] T005 Update `README.md` patch table: rename f_cymascope row → f_chladni

**Checkpoint**: `f_chladni.maxpat` exists in `patchers/`; loads in Vsynth; `docs/` and `README.md` consistent.

---

## Phase 1: ph0 Fix

**Purpose**: Resolve the dead ph0 parameter before signal chain work, so any visual regression is attributable to this change alone.

- [ ] T006 Open codebox in `f_chladni.maxpat`; rewrite per-mode phase terms to `(ph_m + ph0)` across all 8 modes
- [ ] T007 Verify fix: moving ph0 slider visibly rotates/shifts the nodal pattern globally
- [ ] T008 Update `docs/f_chladni.md` parameter table: ph0 description → "Global phase offset applied to all modes"

**Checkpoint**: ph0 slider produces visible global phase shift; no regression in other parameters.

---

## Phase 2: Audio Companion Patch

**Purpose**: Build `f_chladni_audio.maxpat` — the primary signal chain deliverable. Audio path only; no Muse hardware required for testing.

- [ ] T009 Create `patchers/f_chladni_audio.maxpat` (new patch, not a bpatcher)
- [ ] T010 Build `adc~ → biquad~ × 8` filter bank; wire DSP chain
- [ ] T011 [P] Compute Log frequency set: 8 bands geometrically spaced ~80Hz–8kHz; store as `coll` or message list in patch
- [ ] T012 [P] Compute Bessel frequency set: 8 center frequencies at z0–z7 Bessel-zero ratios; choose reference fundamental at build time; document choice in patch comment
- [ ] T013 Add `umenu` (items: Log, Bessel); wire to swap active frequency set into `biquad~` coefficients on selection
- [ ] T014 Connect `biquad~ × 8 → peakamp~ × 8 → slide~ × 8` (slide~ attack ~10ms)
- [ ] T015 Add master gain: `*~ ` or float multiplier scaling all 8 outputs; wire to a `number~` or `live.gain~`
- [ ] T016 Add per-band level meters: `meter~` or `number~` display for each of the 8 bands
- [ ] T017 Route 8 smoothed outputs as messages: `m0amp $1`, `m1amp $1` … `m7amp $1`
- [ ] T018 Test with mic: speech and varied tones should visibly animate Chladni figure across multiple modes
- [ ] T019 Test tuning toggle: switch Bessel ↔ Log while signal active; confirm no audible click or visual snap

**Checkpoint**: Mic input drives Chladni figure visibly; all 8 modes respond; tuning toggle switches cleanly.

---

## Phase 3: EEG Companion Patch

**Purpose**: Build `f_chladni_eeg.maxpat`. Requires Muse headset. Do measurement pass before building.

- [ ] T020 Measurement pass: connect Muse, open `udpreceive` and print raw OSC output; record actual value range per band; document in patch comment before building
- [ ] T021 Create `patchers/f_chladni_eeg.maxpat` (new patch, not a bpatcher)
- [ ] T022 Build `udpreceive [port] → route` by Muse band name (delta, theta, alpha, beta, gamma or exact OSC addresses)
- [ ] T023 Scale each of the 7 bands from measured raw range → 0.0–1.0 (use `scale` object per band)
- [ ] T024 Smooth each scaled band via `line` with ~150ms ramp time
- [ ] T025 Compute m7 total power: sum all 7 smoothed band values, divide by 7; output as `m7amp $1`
- [ ] T026 Add master gain and per-band level meters matching `f_chladni_audio.maxpat` UI convention
- [ ] T027 Route 8 outputs as `m0amp $1` … `m7amp $1` messages (same protocol as audio patch)
- [ ] T028 Test with Muse headset: figure animates; transitions are smooth; m7 reflects overall activity; no visible 10Hz stepping

**Checkpoint**: Muse headset drives Chladni figure smoothly; all 8 modes active including m7; 10Hz update rate hidden.

---

## Phase 4: view_mode Verification

**Purpose**: Confirm the existing view_mode blend works with a live signal — it was implemented but never tested with real input.

- [ ] T029 With `f_chladni_audio.maxpat` running and mic active, blend `view_mode` 0 → 1
- [ ] T030 Confirm circular ↔ strip transition is smooth with no artifacts at the boundary
- [ ] T031 If issues found, note in `docs/f_chladni.md` loose threads section; file tasks to fix

**Checkpoint**: view_mode blend confirmed working (or issues documented for follow-up).

---

## Phase 5: Docs Cleanup

**Purpose**: Leave everything in a consistent state before closing out f_chladni signal chain work.

- [ ] T032 Final pass on `docs/f_chladni.md`: update Signal Chain section to reflect as-built audio and EEG paths; update loose threads (ph0 resolved, view_mode status)
- [ ] T033 Update `.specify/spec.md`: mark f_chladni signal chain and ph0 items resolved in Active Development section
- [ ] T034 Update `tasks.md`: mark T001–T033 complete; promote any follow-up items to backlog

**Checkpoint**: docs/, spec.md, and tasks.md all reflect actual state of the build.

---

## Dependencies & Execution Order

### Phase Dependencies
```
Phase 0 (Rename) → Phase 1 (ph0) → Phase 2 (Audio) → Phase 4 (view_mode verify)
Phase 0 (Rename) → Phase 3 (EEG)   [parallel to Phase 2 if Muse available]
Phase 2 + Phase 3 + Phase 4 → Phase 5 (Docs)
```

### Parallel Opportunities
- **T011 + T012** — Log and Bessel frequency set computation are independent calculations; do together
- **Phase 2 + Phase 3** — if Muse hardware is available and a second session is running, EEG patch can be built in parallel with audio patch (both depend only on Phase 0)
- **T020** (Muse measurement pass) — can be done in parallel with Phase 1 (ph0 fix) if Muse is to hand

### Within-Phase Dependencies
- Phase 2: T010 → T011/T012 → T013 → T014 → T015/T016 → T017 → T018 → T019
- Phase 3: T020 → T021 → T022 → T023 → T024 → T025 → T026 → T027 → T028

---

## Implementation Strategy

**Start with Phase 0 and 1** — both are quick (< 30 min total) and unblock everything else.

**Audio patch first (Phase 2)** — no hardware dependency; verifiable immediately with any mic. This is the primary deliverable.

**EEG patch when Muse is available (Phase 3)** — needs a deliberate hardware session; budget time for the measurement pass before building.

**Stop at any phase checkpoint** — each phase leaves the system in a working, committable state.

---

## Backlog (Cross-Session)

Items not part of the f_chladni signal chain build; tracked here for continuity.

- [ ] **Scope review** — conversational; taxonomy, optics family prioritization, f_cymascope vs optics sequencing
- [ ] **f_mobius** — specced in `ideas/f_mobius.md`; build after f_chladni signal chain; foundation for f_stereo and f_poincare; codebox-first (verify cmul/cdiv and full transform before patcher wrapper)
- [ ] **f_cymascope: feasibility check** — can jit.gl.pix read/write feedback texture at Vsynth render tempo without frame-order issues?
- [ ] **Help patches** — none exist; start with f_texrouter (bypass=freeze must be documented), then f_droste, then f_chladni
- [ ] **f_chladni: near-center singularity** — accept or add epsilon floor; low priority
- [ ] **f_chladni: plate shape morphing** — hold until scope review
- [ ] **Optics family** — f_lens/f_aberration (review prior session work first), f_caustic, f_flare, f_diffraction; pending scope review
- [ ] **Apollonian fractal** — GLSL approach TBD; see `ideas/scratchpad.md`
- [ ] **Circular screen family** — f_stereo (stereographic projection), f_sharmonics (spherical harmonics visualizer), f_poincare (Poincaré disk); all depend on f_mobius; see `ideas/circular_screen.md`
- [ ] **Non-Euclidean geometry** — absorbed into circular screen direction; see `ideas/circular_screen.md`
- [ ] **f_hue_processor: hue_lower/hue_upper remote control** — on hold; revisit if needed in performance
- [ ] **f_luma_processor/f_tone_curve: shared parameter convention** — low_mid/mid_high/edge_falloff; note only, no action needed now

---

## Done (Recent)

- [x] Repo migration — `docs/` and `ideas/` directories created; bpatcher specs moved from `.specify/bpatchers/`
- [x] `spec.md` written — all planned work consolidated
- [x] `plan.md` written — architecture decisions, dependency blocks, implementation phases
- [x] Spec clarified — 3 ambiguities resolved (filter tuning modes, companion patch UI scope, m7 total power)
- [x] `plan.md` updated to reflect clarifications
- [x] f_chladni vs f_cymascope distinction — separate specs, distinct physics
- [x] vsynth-bpatcher skill updated — package structure and bpatcher lifecycle
- [x] f_chladni initial build (as f_cymascope) — Bessel mode visualizer, 8 modal amps, confirmed working visually
