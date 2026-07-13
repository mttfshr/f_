# f_chladni — Bpatcher Reference (As-Built)

_Last updated: 2026-07-12_
_Status: Working — three outlets confirmed in Max_

## Role

Single-resonance audio-to-vecfield transducer. A `note` (MIDI 0–127) selects
one dominant Chladni mode out of 8, `amp` scales output brightness. Physically
faithful to a real Chladni plate — driven at one frequency at a time, not an
8-band superposition — which gives the pattern identity per mode rather than
visualizer-style spectral legibility.

As with the earlier framing, this is an **ingredient**, not necessarily a
final display layer — useful as a modulation source (vecfield outlet) or a
raw-energy signal (magnitude outlet) as much as a direct visual.

## Concept

Circular plate Chladni figure. Superimposes up to 8 circular membrane modes
using large-x asymptotic Bessel function approximations. `mode` selects
between two mode-selection behaviors:

- **`mode=0` (linear interp)** — `note` maps linearly across the Bessel zero
  span (z0=2.4048 – z7=11.0864); active mode is a weighted blend of the two
  adjacent modes.
- **`mode=1` (Gaussian resonance snap)** — each Bessel zero is a resonance
  peak; active amplitude follows a Gaussian falloff (`spread` controls width)
  centered on the nearest zero. Stronger per-mode identity, more sculptural.

Per-mode contribution:
```
(env*cos(r - z_m) + reflectamt*env*cos(radius - r - z_m)) * cos(m*θ + ph0)
```
where `env = sqrt(2/(π*r))`.

## Outlets

| Outlet | Content | Bypass behavior |
|---|---|---|
| `out1` | luma — nodal line pattern (`1 - clamp(sqrt(abs(total))*linesharpness, 0, 1)`) | black |
| `out2` | float32 f_vecfield — central-difference gradient of `total`, unit-normalized (0.5=zero vector); points toward nodal lines | neutral (0.5, 0.5) |
| `out3` | unsigned magnitude scalar — `clamp(abs(total) * gain, 0, 1)`; raw modal interference energy, distinct from both other outlets (out1 is lossily compressed via `sqrt`, out2 discards magnitude entirely) | black |

`out3` was added 2026-07-12 per `.specify/f_chladni/plan.md` Decision 7 —
see `ideas/dry_wet_gain_and_novel_field_outlet.md` finding 6 for the
"novel-signal" heuristic that motivated it. `gain=1.0` confirmed visually
correct in Max (not blown out, not too dim) — no further tuning needed.

## Parameters

| Name | Type | Range | Default | Description |
|---|---|---|---|---|
| `note` | float | 0–127 | 60.0 | MIDI note — selects Bessel mode position |
| `amp` | float | 0–1 | 1.0 | Amplitude envelope — scales output brightness |
| `dishradius` | float | 0.1–4.0 | 1.0 | Plate radius — scales field in both view modes |
| `reflectamt` | float | 0–1 | 0.0 | Boundary reflection amount — adds reflected wave |
| `linesharpness` | float | 0.1–100 | 10.0 | Nodal line sharpness — higher = thinner lines |
| `ph0` | float | -2π–2π | 0.0 | Global phase offset — rotates nodal pattern |
| `spread` | float | 0.1–1.0 | 0.3 | Mode B (Gaussian snap) falloff width — 0.1=snap, 0.5=broad |
| `mode` | float | 0–1 | 0.0 | 0=linear interp between modes, 1=Gaussian resonance snap |
| `view_mode` | float | 0–1 | 0.0 | 0=circular plate, 1=unwrapped strip (for f_stereo routing) |
| `gain` | float | 0–20 | 1.0 | Scales `out3` only — no effect on `out1`/`out2` (confirmed empirically 2026-07-12) |
| `bypass` | bypass | — | 0 | All three outlets go to their bypass state |

## Geometry

Circular plate only, Bessel functions (J_m) on radial coordinate. Strip
view mode retained for f_stereo routing. Rectangular/sine-mode boundary
would be a separate module, not a mode switch.

Near-center singularity (`sqrt(2/πr)` diverges at origin) is accepted —
characteristic of real Chladni images.

## Signal Chain Recipes

```
f_chladni out2 (vecfield) → f_caustic field inlet     — convergence at nodal lines
f_chladni out2 (vecfield) → f_vf_warp field inlet      — source texture warps toward nodal lines
f_chladni out3 (magnitude) → f_weave scalar inlet      — matches f_vf_potential's existing
                                                          vecfield-in/scalar-out precedent
```

## Companion Patches (Not Yet Built)

Interface is `note` + `amp` only (much simpler than the superseded 8-band
filterbank contract). Design deferred until wanted:

- `f_chladni_audio.maxpat` — sigmund~/pitch follower → `note`; peakamp~ → `amp`
- `f_chladni_eeg.maxpat` — dominant band or weighted centroid → `note`; total power → `amp`

## Loose Threads

- Companion patches (audio, EEG) not built — interface is stable and ready for them whenever wanted
- Preferred MIDI playing range not empirically pinned down beyond "1–2 octaves is the expected expressive range"

## Superseded

The original 8-mode filterbank architecture (`m0amp`–`m7amp`, `z0`–`z7`,
`ph1`–`ph7`, per-mode EEG band mapping) was replaced by the 2026-06-17
single-resonance reframe. See `.specify/f_chladni/spec.md` for the full
rationale and the superseded-parameter list.

## Source File

`package/patchers/f_chladni.maxpat`
