# Plan: f_chladni Signal Chain

_Last updated: 2026-05-25_
**Spec**: `.specify/f_chladni/spec.md`

---

## Summary

The f_chladni bpatcher is working visually. This build adds the signal chain that drives its 8 modal amplitude inputs from live audio or EEG. The bpatcher itself is unchanged — all signal chain work lives in two companion patches. Also in scope: ph0 codebox fix (global phase offset), patcher rename, view_mode verification.

---

## Technical Context

**Platform**: Max 9 + Vsynth
**Artifacts**: .maxpat files — save in Max; no build process
**Testing**: Visual and audio verification in Max
**Constraints**: Codebox-first; one bpatcher one concern; Vsynth compatibility

---

## Architecture Decisions

### Decision 1: Companion Patch Pattern
Signal chain in separate companion patches (`f_chladni_audio.maxpat`, `f_chladni_eeg.maxpat`). The bpatcher only receives `m0amp`–`m7amp` — it doesn't know or care what's driving it.

Rejected: signal chain inside bpatcher (violates one-concern constraint); combined patch with switching (complexity, no benefit).

**Consequence**: Easy to add future sources (CV, MIDI, generative) without touching f_chladni.

### Decision 2: Bandpass Filter Tuning — Two Switchable Modes
Log (default) and Bessel frequency sets, switchable via `umenu`. Both stored in the patch. Bessel reference fundamental chosen at build time and documented in patch comment.

**Risk**: Switching mid-signal may cause a transient. Accept for now.

### Decision 3: Smoothing Strategy
- Audio: `slide~` after `peakamp~`, attack ~10ms
- EEG: `line` with ~150ms ramp (hides 10Hz Muse update rate)

`line` not `slide~` for EEG — control-rate OSC doesn't need audio-rate smoothing.

### Decision 4: EEG m7 = Total Power
m7 driven by average of all 7 Muse band values (sum / 7). Keeps all 8 modes active; m7 reflects overall brain activity.

### Decision 5: ph0 = Global Phase Offset
Repurpose ph0 as a global phase offset added to all modal phases in codebox. Minimal change. ph0 UI stays; semantic changes from "mode 0 phase" to "global phase offset".

---

## Dependency Blocks

**Block 0: Rename** — do first; all Max work opens the correctly-named file
**Block 1: ph0 Fix** — isolated codebox change before signal chain; isolates regressions
**Block 2: Audio Companion** — primary deliverable; no hardware required
**Block 3: EEG Companion** — requires Muse; measurement pass first
**Block 4: view_mode Verify** — needs live signal (Block 2 minimum)
**Block 5: Docs** — wraps up the build

```
Block 0 → Block 1 → Block 2 → Block 4
Block 0 → Block 3   [parallel to Block 2 if Muse available]
Block 2 + Block 3 + Block 4 → Block 5
```

---

## Implementation Phases

### Phase 0: Rename (Block 0)
- Open `patchers/f_cymascope.maxpat` → File → Save As `f_chladni.maxpat`
- Verify loads in Vsynth
- Update `docs/f_chladni.md` source file line; check `package-info.json`; update `README.md`

### Phase 1: ph0 Fix (Block 1)
- Open codebox; change per-mode phase to `(ph_m + ph0)` across all 8 modes
- Verify: ph0 slider shifts nodal pattern globally
- Update `docs/f_chladni.md` ph0 description

### Phase 2: Audio Companion Patch (Block 2)
- Create `f_chladni_audio.maxpat`
- `adc~ → biquad~ × 8`; Log and Bessel frequency sets stored; `umenu` to swap
- `biquad~ × 8 → peakamp~ × 8 → slide~ × 8` (attack ~10ms)
- Master gain; per-band meters; route `m0amp $1` … `m7amp $1`
- Test: speech and varied tones animate figure; tuning toggle clean

### Phase 3: EEG Companion Patch (Block 3)
- Measurement pass first: print raw Muse OSC values; document range per band
- Create `f_chladni_eeg.maxpat`
- `udpreceive → route` by band name; scale raw → 0–1; `line` ~150ms
- m7 = sum 7 bands / 7; master gain; per-band meters; route `m0amp $1` … `m7amp $1`
- Test: smooth Muse-driven animation; no visible 10Hz stepping

### Phase 4: view_mode Verification (Block 4)
- With audio patch running: blend view_mode 0 → 1
- Confirm smooth circular ↔ strip transition; document result

### Phase 5: Docs Cleanup (Block 5)
- Update `docs/f_chladni.md`: signal chain as-built, loose threads, ph0 resolved
- Update `.specify/f_chladni/tasks.md`: mark complete
- Update `HANDOFF.md`: reflect completed state

---

## Complexity Notes

- **Bessel set tuning**: compute Hz values from Bessel-zero ratios at the chosen fundamental; document in patch comment
- **Muse calibration**: raw OSC range must be measured — do not guess; budget a dedicated session
- **EEG smoothing**: 150ms is a starting point; tune in performance context
- **Tuning toggle transient**: acceptable for now; revisit if disruptive in performance
