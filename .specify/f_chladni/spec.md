# Spec: f_chladni

_Last updated: 2026-05-25_

## What it does

Visualizes Chladni plate physics — modal superposition of Bessel functions on a circular plate — as a real-time GLSL shader. Drives 8 modal amplitude inputs (`m0amp`–`m7amp`) from live audio or EEG data, making the nodal pattern respond to sound or brain activity.

**Acceptance criteria:**
- Chladni figure animates visibly in response to mic input
- Chladni figure animates visibly in response to Muse EEG headset
- ph0 slider produces a visible global phase shift across all modes
- view_mode blends smoothly between circular and strip display
- All 8 modes (m0–m7) are independently drivable from any source

---

## Signal Chain — Audio Path

```
mic → bandpass bank (8 filters, switchable tuning)
    → peakamp~
    → slide~    (~10ms attack)
    → m0amp–m7amp
```

- 8 bandpass filters with two switchable tuning modes (umenu in companion patch):
  - **Log** (default) — 8 bands geometrically spaced ~80Hz–8kHz; works for varied/ambient material
  - **Bessel** — 8 bands at Bessel-zero ratios relative to a reference fundamental chosen at build time; physically accurate modal tuning
- `peakamp~` extracts envelope per band
- `slide~` smooths (~10ms attack; tune empirically)
- Output: `m0amp $1` … `m7amp $1` messages

**Companion patch UI (`f_chladni_audio.maxpat`):**
- Tuning mode toggle (Log / Bessel)
- Master gain
- Per-band level meters

---

## Signal Chain — EEG Path (Muse Headset)

```
Muse OSC → udpreceive
         → route by band name
         → scale (raw → 0.0–1.0)
         → line (~150ms ramp)
         → m0amp–m7amp
```

- Muse sends at ~10Hz — `line` smoothing hides the step rate
- Raw value range calibrated from a measurement pass before building
- Band → mode mapping:

| Band | Mode |
|------|------|
| Delta | m0 |
| Theta | m1 |
| Alpha | m2 |
| Beta-lo | m3 |
| Beta-hi | m4 |
| Gamma-lo | m5 |
| Gamma-hi | m6 |
| Total power (sum/7) | m7 |

**Companion patch UI (`f_chladni_eeg.maxpat`):**
- Master gain
- Per-band level meters (same convention as audio patch)

---

## Path Switching

No switching mechanism in the bpatcher. Open either companion patch to drive from that source. The bpatcher only receives `m0amp`–`m7amp` regardless of source.

---

## Loose Threads

**ph0 — repurpose as global phase offset**
`cos(0·θ + ph0)` is constant for m=0 (no angular dependence). Decision: repurpose ph0 as a global phase offset added to all modal phases. Minimal codebox change. Update parameter table in docs/ when done.

**Near-center singularity**
`sqrt(2/πr)` diverges at origin. Accept for now — characteristic of real Chladni images. Revisit only if it becomes distracting in performance.

**view_mode blend**
Implemented but not tested with a live signal. Verify after audio companion patch is working.

**Plate shape morphing**
Possible future: morph between Bessel (circular plate) and sine products (rectangular plate). Hold — significant GLSL change; pending scope review.

---

## Patcher File Rename

`patchers/f_cymascope.maxpat` → `patchers/f_chladni.maxpat`

Must be done in Max (File → Save As), not filesystem rename. After rename:
- Update `docs/f_chladni.md` source file line
- Check `package-info.json`; update if needed
- Update `README.md` patch table

---

## Clarifications

- **Filter tuning:** Two switchable modes (Log default, Bessel available). Bessel reference fundamental chosen at build time.
- **Companion patch UI scope:** Tuning toggle + master gain + per-band meters. No per-band gain/mute or preset recall.
- **m7:** Total power — average of all 7 Muse band values (sum / 7), scaled 0–1.
