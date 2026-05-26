# Implementation Plan: f_chladni Signal Chain + f_mobius

**Date**: 2026-05-25
**Spec**: `.specify/spec.md`
**Covers**: Two sequential builds — f_chladni signal chain first, f_mobius bpatcher second.

---

## Summary

### Build 1: f_chladni Signal Chain
The f_chladni bpatcher is working visually. This build adds the signal chain that drives its 8 modal amplitude inputs (`m0amp`–`m7amp`) from live audio or EEG. All signal chain work lives in companion patches — the bpatcher itself is unchanged. Two companion patches: `f_chladni_audio.maxpat` (mic → bandpass bank with switchable Bessel/Log tuning → envelope → amplitudes) and `f_chladni_eeg.maxpat` (Muse OSC → band routing → smoothing → amplitudes, m7 = total power). Both include basic UI: tuning toggle, master gain, per-band meters. Also in scope: ph0 codebox fix (repurpose as global phase offset), patcher rename, view_mode verification.

### Build 2: f_mobius
A new UV-space processor bpatcher. Applies a Möbius transformation `f(z) = (az + b) / (cz + d)` to sampling coordinates — circle-preserving, angle-preserving, composable in any chain. Parameters: `cx`/`cy` (center, xy encoder), `rotate`, `zoom` (log-mapped), `invert` (0=rotation/zoom, 1=full 1/z). Foundation for the circular screen direction (f_stereo, f_poincare). Codebox-first build.

---

## Technical Context

**Platform**: Max 9 + Vsynth
**Patch language**: Max patching (.maxpat JSON)
**GLSL**: jit.gl.pix codeboxes
**JS**: `code/` directory (no JS changes anticipated)
**Testing**: Visual and audio verification in Max — no automated tests
**Build process**: None — .maxpat files are the artifacts; save in Max

**Constraints from Constitution**:
- Codebox-first — write and verify codebox math before building patcher wrapper
- One bpatcher, one concern — signal chain lives in companion patches, not inside f_chladni
- Specs before building — this plan.md written before opening Max
- Vsynth compatibility — all bpatchers follow Vsynth signal flow conventions (routepass, jit.gl.pix, moduleSize.js chain)

---

## Constitution Check

✅ **Vsynth compatibility** — f_chladni bpatcher unchanged for signal chain work; f_mobius follows required object checklist
✅ **Codebox before patcher** — ph0 fix and f_mobius both start with codebox verification
✅ **One bpatcher, one concern** — f_chladni signal chain in companion patches; f_mobius is a single UV-space concern
✅ **Specs before building** — spec.md written, clarifications resolved, this plan written before any Max work
✅ **Tasks.md is the session anchor** — tasks.md derived from this plan

---

## Project Structure

```
f_/
  patchers/
    f_cymascope.maxpat       → rename to f_chladni.maxpat (in Max, Build 1)
    f_chladni_audio.maxpat   → new: audio companion patch (Build 1)
    f_chladni_eeg.maxpat     → new: EEG companion patch (Build 1)
    f_mobius.maxpat          → new: Möbius transformation bpatcher (Build 2)
  docs/
    f_chladni.md             → update: source file ref, ph0 description, signal chain section
    f_mobius.md              → new: as-built reference (after Build 2 confirmed working)
  ideas/
    f_mobius.md              → spec source for Build 2 (move to docs/ when done)
  .specify/
    spec.md                  → update as items resolve
    plan.md                  → this file
    tasks.md                 → session anchor, derived from this plan
```

---

## Architecture Decisions

### Decision 1: Companion Patch Pattern (f_chladni signal chain)

**Decision**: Signal chain in separate companion patches. The bpatcher only receives `m0amp`–`m7amp` — it doesn't know or care what's driving it.

**Rationale**: Keeps bpatcher generic and reusable. Audio and EEG paths developed independently. Easy to add future sources (CV, MIDI, generative) without touching f_chladni.

**Alternatives rejected**: Signal chain inside bpatcher (violates one-concern constraint); single combined patch with switching (complexity with no benefit).

---

### Decision 2: Bandpass Filter Tuning — Two Switchable Modes

**Decision**: Audio companion patch has two stored frequency sets switchable via `umenu`:
- **Log** (default): 8 bands geometrically spaced ~80Hz–8kHz
- **Bessel**: 8 bands at Bessel-zero ratios relative to a reference fundamental chosen at build time

**Rationale**: Log is more useful for varied/ambient sources in performance. Bessel is available for physically-accurate use with a sustained tone source. Reference fundamental for Bessel deferred to build time.

**Risk**: Switching frequency sets mid-signal may cause a transient. Guard: only switch when signal is below threshold, or accept the transient.

---

### Decision 3: Smoothing Strategy

**Decision**:
- Audio: `slide~` after `peakamp~`, attack ~10ms, release ~50ms
- EEG: `line` with ~150ms ramp time per update (hides 10Hz step rate)

**Rationale**: `slide~` is standard for audio-rate envelope smoothing. `line` is appropriate for EEG's control-rate OSC — no audio-rate overhead, clean interpolation between updates.

---

### Decision 4: EEG m7 = Total Power

**Decision**: m7 driven by average of all 7 Muse band values (sum / 7, scaled 0–1).

**Rationale**: All 8 modes stay active. m7 reflects overall brain activity level — a meaningful signal that complements the individual band → mode mapping.

---

### Decision 5: ph0 — Global Phase Offset

**Decision**: Repurpose ph0 as a global phase offset added to all modal phases in codebox.

**Rationale**: More interesting than hiding it. Minimal codebox change. ph0 UI stays; semantic changes from "mode 0 phase" to "global phase offset".

---

### Decision 6: f_mobius Parameter Model — Intuitive Controls (Model A)

**Decision**: Expose `rotate`, `zoom`, `invert`, `cx`/`cy` as performer controls. Compute a, b, c, d internally from these.

**Rationale**: 8 raw complex constants are unperformable. The four intuitive controls cover the main transformation types and the exotic inversion territory. `cx`/`cy` driven by xy encoder fits the Vsynth control convention cleanly (named float messages on in1).

**Invert is the key control**: 0 = familiar rotation/zoom; 0.2–0.8 = loxodromic/hyperbolic motion (the unique territory); 1 = full 1/z inversion (inside-out).

**Zoom mapping**: log-scale — `pow(10.0, (zoom - 0.5) * 1.0)` gives 0.1× at 0, 1× at 0.5, 10× at 1. Tune range empirically.

---

### Decision 7: f_mobius Edge Behavior — Mirror

**Decision**: UV coordinates that fall outside [0,1] after transformation are mirrored back in.

**Rationale**: Consistent with the existing spherical-surface illusion approach (mirror edges applied in current workflow). Avoids hard seams at the boundary.

---

## Dependency Blocks

### Build 1: f_chladni Signal Chain

**Block 0: Rename** — do first; all other Max work opens the correctly-named file
- Output: `f_chladni.maxpat` in `patchers/`
- Verify: opens in Max; loads in Vsynth

**Block 1: ph0 Codebox Fix** — isolated change; verify before signal chain so regressions are attributable
- Output: corrected codebox; ph0 = global phase offset
- Verify: ph0 slider produces visible global phase shift

**Block 2: Audio Companion Patch** — primary signal chain deliverable; no hardware required
- Output: `f_chladni_audio.maxpat`
- Verify: mic input visibly animates Chladni figure; tuning toggle switches cleanly

**Block 3: EEG Companion Patch** — requires Muse hardware; measurement pass first
- Output: `f_chladni_eeg.maxpat`
- Verify: Muse headset animates figure; no visible 10Hz stepping; m7 reflects overall activity

**Block 4: view_mode Verification** — needs live signal (Block 2 minimum)
- Output: confirmed working blend or documented issues
- Verify: view_mode 0→1 transitions smoothly with signal active

**Block 5: Docs** — wraps up Build 1
- Output: updated `docs/f_chladni.md`, `spec.md`, `tasks.md`

### Build 2: f_mobius

**Block A: Codebox Math** — verify complex arithmetic before building patcher
- Output: confirmed working codebox (cmul, cdiv, full transform, inversion blend, mirror edges)
- Verify: three test cases pass (passthrough, inversion, rotation)

**Block B: Patcher Build** — wire codebox into standard Vsynth bpatcher structure
- Output: `f_mobius.maxpat` following required object checklist
- Verify: all params controllable via named messages; bypass works; loads in Vsynth

**Block C: Docs** — graduate from ideas/ to docs/
- Output: `docs/f_mobius.md` as-built reference
- Archive: `ideas/f_mobius.md` can be removed or retained as design notes

---

## Implementation Phases

### Phase 0: Rename (Block 0)
- Open `patchers/f_cymascope.maxpat` in Max → File → Save As `f_chladni.maxpat`
- Verify loads in Vsynth
- Update `docs/f_chladni.md` source file line
- Check `package-info.json`; update if patcher name present
- Update `README.md` patch table

### Phase 1: ph0 Fix (Block 1)
- Open codebox in `f_chladni.maxpat`
- Change per-mode phase to `(ph_m + ph0)` across all 8 modes
- Verify: ph0 slider shifts nodal pattern globally
- Update `docs/f_chladni.md` — ph0 → "Global phase offset applied to all modes"

### Phase 2: Audio Companion Patch (Block 2)
- Create `patchers/f_chladni_audio.maxpat`
- Build `adc~ → biquad~ × 8` with Log and Bessel frequency sets stored (coll or message list)
- Add `umenu` (Log / Bessel) to swap active frequency set into biquad~ coefficients
- Wire `biquad~ × 8 → peakamp~ × 8 → slide~ × 8` (attack ~10ms)
- Add master gain; add per-band level meters (`meter~` or `number~`)
- Route outputs: `m0amp $1` … `m7amp $1`
- Test: speech and varied tones animate figure; tuning toggle switches without discontinuity

### Phase 3: EEG Companion Patch (Block 3)
- Measurement pass: connect Muse, print raw OSC values, document range per band
- Create `patchers/f_chladni_eeg.maxpat`
- Build `udpreceive [port] → route` by band name
- Scale each band raw → 0.0–1.0 using measured values
- Smooth via `line` ~150ms ramp per update
- Compute m7: sum 7 scaled bands / 7 → `m7amp $1`
- Add master gain and per-band meters (match audio patch UI convention)
- Route: `m0amp $1` … `m7amp $1`
- Test: Muse animates figure; smooth transitions; m7 reflects overall activity

### Phase 4: view_mode Verification (Block 4)
- With audio companion patch running, test view_mode 0→1 blend
- Confirm no artifacts at blend boundary
- Document result in `docs/f_chladni.md`

### Phase 5: f_chladni Docs Cleanup (Block 5)
- Update `docs/f_chladni.md`: signal chain section, loose threads, ph0 resolved
- Update `spec.md`: mark active items resolved
- Update `tasks.md`: mark T001–T034 complete

### Phase 6: f_mobius Codebox (Block A)
- Write codebox as plain text first (paste into Max manually per skill convention)
- Implement: `cmul`, `cdiv` helpers; center offset; rotate+zoom; identity path; inversion path; blend by `invert`; mirror edge guard
- Test case 1: `invert=0, rotate=0, zoom=0.5` → pixel-perfect passthrough
- Test case 2: `invert=1, cx=0.5, cy=0.5` → clean inside-out inversion
- Test case 3: `invert=0, rotate=0.25` → 90° rotation of sampling coordinates

### Phase 7: f_mobius Patcher Build (Block B)
- Create `patchers/f_mobius.maxpat` following Vsynth bpatcher checklist
- Prefix: `mob` (scripting name: `mob_pix`)
- Params: `cx`, `cy`, `rotate`, `zoom`, `invert`, `bypass`
- `cx`/`cy`: standard live.dial, 0–1, respond to named messages on in1 (xy encoder compatible)
- `rotate`: 0–1 (mapped to 0–2π in codebox)
- `zoom`: 0–1 log-mapped (0.5 = unity)
- `invert`: 0–1
- Wire: routepass → pix, route → dials → prepend param → pix, moduleSize.js chain
- Verify: loads in Vsynth; bypass works; all params respond to named messages

### Phase 8: f_mobius Docs (Block C)
- Create `docs/f_mobius.md` as-built reference (params as actually built, any deviations from ideas/f_mobius.md noted)
- Update `spec.md`: mark f_mobius status → built
- Update `tasks.md`: mark complete

---

## Complexity Notes

**Bandpass filter tuning**: Log set is straightforward arithmetic. Bessel set requires computing actual Hz values from Bessel-zero ratios at the chosen reference fundamental — document the chosen fundamental and resulting center frequencies in patch comments.

**Muse calibration**: Raw OSC values must be measured before building the EEG path. Budget a dedicated measurement session. Do not guess the range.

**EEG smoothing**: 150ms is a starting point. Will need empirical tuning — too short and 10Hz updates are visible; too long and the visualization feels unresponsive. Tune in performance context.

**Tuning toggle transient**: Switching biquad~ coefficients mid-signal may produce a click or visual snap. Acceptable for now; revisit if it becomes a problem in performance.

**f_mobius complex arithmetic**: The codebox math is straightforward but precision matters near the singularity (denominator → 0). The mirror edge guard handles most cases, but verify there are no NaN or inf values escaping. Add a `clamp` or `isnan` guard if needed.

**f_mobius loxodromic range**: The interesting performance territory (invert 0.2–0.8 + rotate) is hard to predict without seeing it. Budget a performance exploration session after the basic build is confirmed working — this is where the expressive range lives.
