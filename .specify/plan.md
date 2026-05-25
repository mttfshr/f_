# Implementation Plan: f_chladni Signal Chain

**Date**: 2026-05-25
**Spec**: `.specify/spec.md`

---

## Summary

Build the signal chain that drives f_chladni's 8 modal amplitude inputs (`m0amp`–`m7amp`) from live audio and EEG data. The bpatcher itself requires no changes — it is generic over its input source. All signal chain work lives in companion patches outside the bpatcher. Two companion patches will be built: one audio-driven (mic → bandpass bank with switchable Bessel/Log tuning → envelope → amplitudes), one EEG-driven (Muse OSC → band routing → smoothing → amplitudes, with m7 driven by total power). Both output the same message protocol to the bpatcher. Companion patches include basic UI: tuning mode toggle, master gain, per-band level meters. Additionally: resolve the ph0 dead parameter, rename the patcher file, and verify view_mode with a live signal.

---

## Technical Context

**Platform**: Max 9 + Vsynth
**Patch language**: Max patching (visual, .maxpat JSON)
**GLSL**: jit.gl.pix codeboxes (for any codebox edits)
**JS**: `code/` directory (no JS changes anticipated for signal chain)
**Testing**: Visual and audio verification in Max — no automated tests
**Build process**: None — .maxpat files are the artifacts; save in Max

**Constraints from Constitution**:
- Codebox-first — if any GLSL changes needed (ph0), write and verify in codebox text before touching patcher structure
- One bpatcher, one concern — signal chain lives in companion patches, not inside f_chladni
- Specs before building — plan.md (this file) before opening Max
- Vsynth compatibility — bpatcher must continue to follow Vsynth signal flow conventions

---

## Constitution Check

✅ **Don't break Vsynth compatibility** — bpatcher internals unchanged for signal chain work; companion patches are separate and don't affect Vsynth integration
✅ **Codebox before patcher** — ph0 codebox change is small and isolated; write new expression first, verify math, then apply
✅ **One bpatcher, one concern** — signal chain is explicitly outside the bpatcher; the bpatcher only receives m0amp–m7amp regardless of source
✅ **Specs before building** — spec.md written, plan.md (this file) written before any Max work
✅ **Tasks.md is the session anchor** — tasks.md is current

---

## Project Structure

No new directories. Work touches existing locations:

```
f_/
  patchers/
    f_cymascope.maxpat      → rename to f_chladni.maxpat (in Max)
    f_chladni_audio.maxpat  → new: audio companion patch
    f_chladni_eeg.maxpat    → new: EEG companion patch
  docs/
    f_chladni.md            → update: source file ref after rename, ph0 resolution
  .specify/
    spec.md                 → update: mark ph0 resolved once decided
    plan.md                 → this file
    tasks.md                → update as items complete
```

**Structure decision**: Companion patches live in `patchers/` alongside the bpatcher. They are not bpatchers themselves (no Vsynth inlet) — they are driver patches that output the `m0amp`–`m7amp` message protocol. Named with `_audio` / `_eeg` suffix to distinguish from the bpatcher.

---

## Architecture Decisions

### Decision 1: Companion Patch Pattern (Signal Chain Outside Bpatcher)

**Context**: The bpatcher receives `m0amp`–`m7amp` as float messages. These could come from audio analysis, EEG, or any other source. The bpatcher doesn't need to know which.

**Decision**: Signal chain lives entirely in separate companion patches (`f_chladni_audio.maxpat`, `f_chladni_eeg.maxpat`). The bpatcher is unchanged.

**Rationale**: Keeps the bpatcher generic and reusable. Audio and EEG paths can be developed and tested independently. Either patch can drive the bpatcher without any bpatcher modification.

**Alternatives considered**:
- Signal chain inside f_chladni bpatcher: rejected — violates "one concern" constraint and bloats the bpatcher
- Single combined patch with switching: rejected — adds complexity with no benefit; just open whichever companion patch you need

**Consequences**:
- Positive: bpatcher stays simple; paths are independently testable; easy to add future sources (CV, MIDI, generative)
- Negative: user must open the right companion patch; no in-bpatcher switching UI

---

### Decision 2: Smoothing Strategy

**Context**: Audio envelope data (~signal rate) and EEG data (~10Hz) both need smoothing before driving visual parameters. Too fast → visual noise; too slow → unresponsive.

**Decision**:
- Audio path: `slide~` after `peakamp~`, attack ~10ms, release ~50ms (tune empirically)
- EEG path: `line` object with ramp time ~100–200ms per update (hides the 10Hz step rate)

**Rationale**: `slide~` is the standard Max envelope smoother for audio-rate signals. `line` (not `line~`) is appropriate for EEG because Muse delivers control-rate data via OSC, not audio-rate. Using `line` produces smooth interpolation between 10Hz updates without audio-rate overhead.

**Alternatives considered**:
- `snapshot~` + `slide~` for EEG: snapshot~ is audio-rate, unnecessary for 10Hz OSC; `line` is cleaner
- Fixed ramp time: use `line` with a fixed time for now; expose as a parameter only if needed

---

### Decision 3: ph0 Resolution — Global Phase Offset

**Context**: `cos(0·θ + ph0)` = `cos(ph0)` for m=0 (mode 0 has no angular dependence), so ph0 has no angular effect. The parameter exists in the UI but does nothing meaningful.

**Decision**: Repurpose ph0 as a global phase offset added to all modal phases before evaluation.

**Rationale**: More interesting than hiding it. A global phase offset uniformly rotates the phase reference for all modes simultaneously — a plausible and useful control. Minimal codebox change.

**Implementation**: In codebox, change per-mode phase term from `ph_m` to `(ph_m + ph0)` across all modes. ph0 UI stays, semantic changes from "mode 0 phase" to "global phase offset".

**Update needed**: `docs/f_chladni.md` — update parameter table description for ph0.

---

### Decision 4: Near-Center Singularity — Accept for Now

**Context**: `sqrt(2/πr)` diverges at origin. Visible as a bright center spike.

**Decision**: Accept. No epsilon floor for now.

**Rationale**: Low visual impact in practice; characteristic of Chladni images; adds work for minimal gain. Revisit only if it becomes distracting in performance use.

---

## Dependency Blocks

### Block 0: Rename
**Dependencies**: None — do first, before any other Max work
**Builds**: `f_chladni.maxpat` in correct location with correct name
**Why this block**: All subsequent Max work should open the correctly-named file
**Verification**: File appears as `f_chladni.maxpat` in patchers/; opens correctly in Max; Vsynth loads it

### Block 1: ph0 Codebox Fix
**Dependencies**: Block 0 (working in the right file)
**Builds**: Corrected codebox expression; ph0 now acts as global phase offset
**Why this block**: Small, isolated change; should be done before the signal chain so any visual regression is attributable to the codebox change, not the signal chain
**Verification**: Moving ph0 slider visibly rotates/shifts the nodal pattern globally

### Block 2: Audio Companion Patch
**Dependencies**: Block 0 (correct file exists to route messages into)
**Builds**: `f_chladni_audio.maxpat` — mic → bandpass bank → peakamp~ → slide~ → m0–m7 messages
**Why this block**: Primary signal chain deliverable; audio is simpler to test than EEG (no hardware required)
**Verification**: Speaking or playing audio into mic visibly animates the Chladni figure

### Block 3: EEG Companion Patch
**Dependencies**: Block 0; Muse hardware available
**Builds**: `f_chladni_eeg.maxpat` — udpreceive → band routing → scale → line → m0–m7 messages
**Why this block**: Secondary signal chain; needs Muse measurement pass first (calibrate raw value range)
**Verification**: Wearing Muse headset animates the Chladni figure; transitions are smooth (no visible 10Hz stepping)

### Block 4: view_mode Verification
**Dependencies**: Block 2 (needs live signal to test meaningfully)
**Builds**: Confirmed working view_mode blend with live data
**Why this block**: view_mode was implemented but never tested with a live signal chain
**Verification**: Blending view_mode 0→1 transitions smoothly between circular and strip views while signal is active

---

## Implementation Phases

### Phase 0: Rename (Block 0)
- Open `patchers/f_cymascope.maxpat` in Max
- File → Save As → `f_chladni.maxpat` (same directory)
- Verify it opens and loads in Vsynth
- Update `docs/f_chladni.md` source file line
- Check `package-info.json` for patcher name references; update if present
- Update `README.md` patch table

### Phase 1: ph0 Fix (Block 1)
- Open codebox in f_chladni.maxpat
- Change per-mode phase term to include global ph0 offset across all 8 modes
- Update `docs/f_chladni.md` — ph0 parameter description → "Global phase offset applied to all modes"
- Update `spec.md` — mark ph0 decision resolved

### Phase 2: Audio Companion Patch (Block 2)
- Create `patchers/f_chladni_audio.maxpat`
- Build filter bank: `adc~ → biquad~ × 8` with two stored frequency sets:
  - **Log set**: 8 logarithmically-spaced center frequencies ~80Hz–8kHz (default)
  - **Bessel set**: 8 center frequencies at Bessel-zero ratios (reference fundamental chosen at build time; document in patch)
- Add `umenu` toggle (Bessel / Log) that swaps the active frequency set into the biquad~ coefficients
- Connect each biquad~ → `peakamp~` → `slide~` (attack ~10ms)
- Add master gain (scales all 8 peakamp~ outputs before message routing)
- Add per-band level meters (`meter~` or `number~` display per band)
- Route outputs as `m0amp 0.x` … `m7amp 0.x` messages
- Test with mic: speech and varied tones should animate figure across modes
- Verify tuning toggle switches modes without clicks or discontinuities

### Phase 3: EEG Companion Patch (Block 3)
- Measurement pass first: connect Muse, print raw OSC values, document actual range per band
- Create `patchers/f_chladni_eeg.maxpat`
- Build: `udpreceive 5000` (or appropriate port) → `route` by band name
- Scale each band's raw range → 0.0–1.0 using measured values
- Smooth each band via `line` with ~150ms ramp time (adjust empirically)
- Compute m7 (total power): sum all 7 scaled band values, divide by 7, output as `m7amp`
- Add master gain and per-band level meters (same UI convention as audio patch)
- Route outputs as `m0amp`–`m7amp` messages
- Test: Muse-animated figure should have smooth, responsive transitions; m7 should reflect overall activity level

### Phase 4: view_mode Verification (Block 4)
- With audio companion patch running, test view_mode 0→1 blend
- Confirm no artifacts at the blend boundary
- Note any visual issues in `docs/f_chladni.md` loose threads

### Phase 5: Docs Cleanup
- Final pass on `docs/f_chladni.md` — update all loose threads, signal chain section
- Update `spec.md` — mark active development items resolved
- Update `tasks.md` — mark completed items

---

## Complexity Notes

- **Bandpass filter tuning** — two frequency sets will be computed and stored in the audio patch: Log (straightforward, 8 bands geometrically spaced 80Hz–8kHz) and Bessel (ratios from z0–z7 applied to a reference fundamental chosen at build time). Log is the default and works for any material. Bessel requires a deliberate pitch reference and is most meaningful with a sustained tone source.
- **Muse calibration** is empirical — raw OSC values must be measured before the EEG path can be properly scaled. Budget a measurement session before building the EEG patch.
- **EEG smoothing** will need tuning in use. Start with 150ms ramp; adjust based on visual feel in performance.
- **Tuning toggle continuity** — switching filter frequency sets mid-signal may cause a transient. If this is audible or visually disruptive, the toggle should only switch when signal is below a threshold, or crossfade between sets.
