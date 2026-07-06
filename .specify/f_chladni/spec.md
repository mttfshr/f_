# Spec: f_chladni

_Last updated: 2026-06-17_

## What it does

Visualizes Chladni plate physics — modal superposition of Bessel functions on a circular plate — as a real-time GPU shader. Operates as an **audio-to-vecfield transducer**: a single resonant mode is selected by a MIDI pitch input and scaled by an amplitude input, producing a living nodal pattern that responds to sound without graphing it. The module is a sculptural object shaped by audio, not a visualizer.

**Two outlets:**
- Out 1: luma texture — nodal line pattern (bright lines at modal zeros)
- Out 2: float32 f_vecfield — gradient of modal field, pointing toward nodal lines; suitable for f_caustic, f_vf_warp, f_vf_streak, f_vf_glow downstream

**Acceptance criteria:**
- Single resonant mode animates visibly in response to MIDI note input
- Pattern reorganizes as note changes (smoothly or with snap — determined by scratch patch)
- Amplitude input scales output brightness
- Vecfield outlet encodes gradient of modal field, verified by routing to f_caustic
- ph0 produces visible global phase shift
- view_mode blends smoothly between circular and strip display
- Strip mode suitable for routing to f_stereo

---

## Architecture

### Reframe from previous spec (2026-06-17)

The original architecture drove 8 independent modal amplitude params (`m0amp`–`m7amp`) from a filterbank companion patch. That design produces a complex superposition but requires calibrated per-band tuning and reads as a visualizer — the spectral content is legible in the pattern.

The new architecture treats the plate as a **single resonant object** excited at one frequency. This is physically faithful (real Chladni plates respond to one driving frequency at a time) and produces more sculptural behavior — the pattern has identity at each mode and reorganizes as the frequency moves between resonances.

### Mode selection

A `note` param (MIDI 0–127) maps to the Bessel zero space (z0=2.4048 through z7=11.0864). Two selection behaviors to be evaluated in scratch patch:

**Linear interpolation** — `note` position within a defined MIDI range maps smoothly to a position along the Bessel zero span. The active mode is a weighted blend of the two adjacent Bessel modes. Smooth, continuous, visualizer-like.

**Resonance snap** — each Bessel zero is a resonance peak. The active mode amplitude follows a falloff curve centered on the nearest zero. Pattern has strong identity at each mode; dissolves between them. More physically faithful, more sculptural.

The scratch patch determines which behavior is preferred, or whether a `snap` param blending between them is warranted.

### MIDI range

MIDI is the canonical input unit — natural common currency for sigmund, analog inputs, and manual dials. The useful playing range within 0–127 is determined empirically in scratch patch. One to two octaves is the expected expressive range for navigating 8 mode characters.

### Params

**Audio interface:**
- `note` — MIDI pitch (0–127); selects resonant mode
- `amp` — amplitude (0.0–1.0); scales output brightness; driven by signal envelope upstream

**Geometry (carried from previous build):**
- `dishradius` — plate radius; scales field in both view modes
- `reflectamt` — boundary reflection amount; adds reflected wave component
- `linesharpness` — nodal line sharpness; higher = thinner lines
- `view_mode` — 0 = circular plate, 1 = unwrapped strip (for f_stereo routing)
- `ph0` — global phase offset applied to all modes

**Possible additions (determined in scratch patch):**
- `spread` — controls how much adjacent modes bleed in; soft vs. hard pattern transitions
- `snap` — blend between linear interpolation and resonance snap behaviors

### Vecfield outlet

The gradient of the modal amplitude field ∇(total) is computed analytically or via numerical differencing of `total` at offset UV positions. Encodes as f_vecfield (RG float32, 0.5 = zero vector). Vectors point toward nodal lines — convergence at nodes, divergence at antinodes.

Numerical differencing (evaluate `total` at `norm ± epsilon`) is preferred over symbolic differentiation — simpler codebox, equivalent result at shader resolution. Epsilon calibrated to avoid aliasing.

### Companion patches

Companion patches supply `note` and `amp` messages — a much simpler interface than the previous 8-amplitude contract.

**f_chladni_audio.maxpat** — mic/audio source:
- `sigmund~` or pitch follower → `note` message
- `peakamp~ → slide~` → `amp` message
- Master gain

**f_chladni_eeg.maxpat** — Muse headset source:
- Dominant band selection or weighted centroid → `note` message
- Total power → `amp` message
- Smoothing via `line` (~150ms)

Companion patch design is deferred until bpatcher architecture is verified in scratch patch.

---

## Signal chain

```
[note 0–127] → mode selection (linear or snap) → Bessel mode blend
[amp 0–1]    → amplitude scale
             → total = Σ weighted Bessel modes
             → out1: luma (nodal lines)
             → out2: vecfield (∇total → RG float32)
```

---

## Geometry

Circular plate only. Bessel functions (J_m) on radial coordinate. Strip view mode retained for f_stereo routing. Rectangular/sine-mode boundary is a separate module if ever warranted — different math, different param space, not a mode switch.

Near-center singularity (`sqrt(2/πr)` diverges at origin) — accepted. Characteristic of real Chladni images.

---

## Loose Threads

- Scratch patch will determine: linear vs. snap behavior, preferred MIDI range, whether `spread` param adds value
- Numerical vs. analytical gradient for vecfield outlet — decide during codebox write
- EEG companion patch: dominant band → note mapping needs design (weighted centroid? highest-amplitude band?)
- Previous 8-mode manual params (`m0amp`–`m7amp`, `z0`–`z7`, `ph1`–`ph7`) are superseded; existing patcher will be rebuilt from definition.py

---

## Superseded

The following from the previous spec are superseded by this reframe:
- 8-mode filterbank companion patch architecture
- Per-band amplitude params (`m0amp`–`m7amp`)
- Per-mode Bessel zero tuning params (`z0`–`z7`)
- Per-mode phase params (`ph1`–`ph7`; ph0 retained as global offset)
- Log/Bessel frequency set switching
- EEG band → mode mapping table
