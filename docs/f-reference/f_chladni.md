# f_chladni — Bpatcher Spec

_Last updated: 2026-05-27_
_Status: Working — role being discovered through use_
_Previously named: f_cymascope_

## Role

f_chladni is an **ingredient**, not a display layer. Chladni glyphs are visually well-known enough that presenting them as a final image isn't the goal. The patch is more useful as a texture that modulates other activity — driving displacement in f_droste, density in f_grain, or other downstream parameters.

The sparseness of the nodal field (only some modes active at a time) is a feature in this role: sparse fields leave room for whatever they're modulating to breathe. Audio-responsiveness becomes interesting rather than limiting — slow modulation of which modes are active produces an evolving texture driven by something real.

**Natural downstream targets:** f_droste (displacement), f_grain (density/threshold), f_mobius (UV distortion).

The circular mask question is deferred — as a texture ingredient, output boundary shape matters less than texture quality.

## Concept

Circular plate Chladni figure visualizer. Superimposes 8 circular membrane modes using large-x asymptotic Bessel function approximations to render nodal lines — the geometric standing wave patterns that emerge on a vibrating plate when sand accumulates at zero-displacement regions.

Each mode `m` contributes:
```
sqrt(2/πr) * cos(r - z_m) * cos(m*θ + ph_m) * amplitude
```

Nodal lines rendered via:
```
1 - clip(sqrt(abs(total)) * linesharpness, 0, 1)
```

**Note on naming:** This is Chladni plate physics (modal superposition, Bessel functions, nodal lines on a solid plate). A separate `f_cymascope` bpatcher will model wave propagation through a fluid medium — a physically distinct approach. See `f_cymascope.md`.

## Parameters

| Name | Type | Range | Description |
|------|------|-------|-------------|
| `m0amp`–`m7amp` | signal (float) | 0.0–1.0 | Modal amplitudes — primary signal inputs |
| `z0`–`z7` | float | positive | Bessel zeros — J_m first zeros by default, tweakable |
| `ph0` | float | 0.0–1.0 | Global phase offset applied to all modes |
| `ph1`–`ph7` | float | 0.0–1.0 | Per-mode phase offset |
| `dishradius` | float | — | Plate radius scale |
| `reflectamt` | float | 0.0–1.0 | Boundary reflection standing wave mix |
| `linesharpness` | float | — | Nodal line width (higher = sharper) |
| `globalscale` | float | — | Output brightness |
| `view_mode` | int | 0–1 | 0 = circular (default), 1 = unwrapped strip, blendable |

## Signal Chain (Intended — Not Yet Built)

### Audio Path
```
mic → bandpass bank (8 filters at modal freq ratios)
    → peakamp~
    → snapshot~ / slide~    (smoothing, ~10ms)
    → m0amp–m7amp
```

### EEG Path (Muse headset)
```
Muse OSC → udpreceive
         → band routing
         → scale
         → line / slide~    (Muse updates ~10Hz, needs smoothing)
         → m0amp–m7amp
```

### EEG Band → Mode Mapping
| Band | Mode |
|------|------|
| Delta | m0 |
| Theta | m1 |
| Alpha | m2 |
| Beta-lo | m3 |
| Beta-hi | m4 |
| Gamma-lo | m5 |
| Gamma-hi | m6 |
| Spare | m7 |

## Loose Threads

- **ph0 global offset** — Repurposed as global phase offset added to all modal phases (`ph_m + ph0`). Done.
- **Near-center singularity** — `sqrt(2/πr)` diverges at origin, visible as bright spike. Low priority — somewhat characteristic of Chladni images. Could add epsilon floor to r if distracting.
- **view_mode blend** — implemented but not tested with a live signal chain yet.
- **Audio vs EEG path** — no switching mechanism designed yet; probably separate patches that feed into the same bpatcher.
- **Plate shape morphing** — pending scope review. Circular plate uses Bessel basis; rectangular uses sine products. A morph parameter could blend between geometries. See tasks.md.

## Source File

`patchers/f_chladni.maxpat`
