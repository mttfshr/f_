# f_ — Spec

_Last updated: 2026-05-25_

Planned work across the package. Working bpatcher state lives in `docs/`. Ideas and future bpatchers live in `ideas/`. This file covers intended changes, signal chain builds, enhancements to working bpatchers, and the planned bpatcher backlog.

---

## Active Development

### f_chladni — Signal Chain

**Status:** Bpatcher is working visually. Signal chain (audio and EEG input → modal amplitude parameters) is not yet built.

**Goal:** Drive the 8 modal amplitude inputs (`m0amp`–`m7amp`) from live audio or EEG data, making the Chladni figure respond in real time to sound or brain activity.

#### Audio Path

```
mic → bandpass bank (8 filters, switchable tuning mode)
    → peakamp~
    → slide~    (smoothing, ~10ms attack)
    → m0amp–m7amp
```

- 8 bandpass filters with two switchable tuning modes (toggle/umenu in companion patch):
  - **Bessel** — center frequencies at Bessel-zero ratios relative to a reference fundamental; physically accurate Chladni modal tuning
  - **Log** — 8 logarithmically-spaced bands covering ~80Hz–8kHz; more responsive to varied material in performance
- Default tuning: Log
- `peakamp~` extracts envelope per band
- `slide~` smooths the signal before driving amplitude parameters (~10ms attack; tune empirically)
- Output: 8 float messages routed to the bpatcher as `m0amp`–`m7amp`

**Companion patch UI (`f_chladni_audio.maxpat`):**
- Tuning mode toggle (Bessel / Log)
- Master gain (scales all 8 outputs)
- Per-band level meters (visual confirmation signal is arriving)

#### EEG Path (Muse Headset)

```
Muse OSC → udpreceive
         → band routing (route or unpack by band name)
         → scale (raw Muse values → 0.0–1.0)
         → line / slide~    (Muse updates ~10Hz; smoothing required)
         → m0amp–m7amp
```

- Muse sends OSC at ~10Hz — raw values must be smoothed heavily or stepped via `line` to avoid visible snapping
- Band routing maps Muse's named bands to the 8 mode slots

**EEG Band → Mode Mapping:**

| Band | Mode |
|------|------|
| Delta | m0 |
| Theta | m1 |
| Alpha | m2 |
| Beta-lo | m3 |
| Beta-hi | m4 |
| Gamma-lo | m5 |
| Gamma-hi | m6 |
| Total power (sum of all 7 bands) | m7 |

#### Path Switching

No switching mechanism is designed yet. Likely approach: separate patches (audio patch, EEG patch) each capable of driving the same bpatcher. The bpatcher itself needs no switching logic — it only receives `m0amp`–`m7amp` regardless of source.

#### Open Questions for Signal Chain

- **Smoothing time:** ~10ms is a starting guess for audio; EEG will need much longer (~100–200ms) to hide the 10Hz update rate. Tune empirically.
- **Scale mapping:** Muse raw values need calibration — what range do they actually output? Needs a measurement pass.
- **Bandpass tuning:** Log-spaced bands default; document center frequencies once built. Bessel mode requires a reference fundamental — defer tuning decision to build time.

---

### f_chladni — Loose Threads (decide before signal chain build)

#### ph0 Dead Parameter

`cos(0·θ + ph0)` = `cos(ph0)` = constant. Phase has no angular effect for mode 0 (m=0 has no angular dependence). Options:
- **Repurpose:** use ph0 as a global phase offset applied across all modes
- **Hide:** remove ph0 from UI; document that m=0 has no phase

Decision pending. Repurpose as global phase offset is the more interesting option.

#### Near-Center Singularity

`sqrt(2/πr)` diverges at the origin, producing a visible bright spike at center. Options:
- Add an epsilon floor to `r` before the sqrt (e.g. `r = max(r, 0.01)`)
- Accept it as characteristic of Chladni images — real sand patterns also have artifacts near the plate center

Low priority. Accept for now unless it becomes distracting in practice.

#### view_mode Blend

`view_mode` parameter blends between 0 (circular) and 1 (unwrapped strip). Implemented in the codebox but not tested with a live signal chain. Verify once audio path is working.

#### Plate Shape Morphing

A morph parameter could blend between circular plate geometry (Bessel basis) and rectangular plate geometry (sine products). Pending scope review — this is a significant GLSL change and may not be worth the complexity.

**Hold until scope review is done.**

---

### f_chladni — Patcher File Rename

`patchers/f_cymascope.maxpat` → `patchers/f_chladni.maxpat`

Must be done in Max (File → Save As), not via filesystem rename, to avoid breaking internal references. After rename:
- Update `docs/f_chladni.md` source file reference
- Update `package-info.json` if it lists patchers by name
- Update `README.md` patch table

---

## Enhancements — Working Bpatchers

### f_hue_processor — Remote Control for hue_lower / hue_upper

`hue_lower` and `hue_upper` are rslider params intentionally excluded from the `route` object. They work via UI interaction but cannot be driven by message from outside the bpatcher. If remote control is needed (e.g. for preset recall or CV control), the rslider widget would need to be replaced or supplemented with a parallel message path.

**Status:** On hold. Revisit only if remote control becomes a real need in performance use.

### f_luma_processor / f_tone_curve — Shared Parameter Convention

Both use `low_mid`, `mid_high`, and `edge_falloff` with the same semantics. When used in sequence (e.g. luma-selective processing followed by tone curve), it may be useful to link or match these values. No action required now — just a convention to be aware of.

### Help Patches — All Bpatchers

No `.maxhelp` files exist for any bpatcher. When help patches are built, start with the most-used bpatchers in performance. Priority order (rough):
1. f_texrouter — bypass semantics especially need documentation
2. f_droste — most stable, good first help patch
3. f_chladni — complex enough to need explanation
4. Others as needed

**f_texrouter specifically:** bypass = freeze (hold last routed frame), not pass-through. This differs from all other f_ bpatchers and must be clearly documented in the help patch.

---

## Planned Bpatchers

### f_cymascope

Wave propagation through a fluid medium (FDTD). Physically distinct from f_chladni:
- f_chladni: modal superposition on a solid plate (Bessel functions, nodal lines, standing waves)
- f_cymascope: FDTD wave equation integration in a fluid medium, potentially with texture as boundary condition

**Status:** Concept specced. See `ideas/f_cymascope.md`.
**Next step:** Feasibility check — confirm ping-pong texture / FDTD wave propagation is viable in `jit.gl.pix` within the Vsynth context before committing to build. Specific question: can a jit.gl.pix codebox read from and write to a feedback texture at Vsynth render tempo without frame-order issues?

### Optics Family

Four bpatchers sharing a unifying concept: **the incoming texture is the light source**. Bright regions are where light originates. Each bpatcher models what happens when that light passes through a real optical element.

See `ideas/scratchpad.md` for full brainstorm. Summary:

| Bpatcher | Mechanism |
|----------|-----------|
| f_lens / f_aberration | Refractive lens — RGB channels displaced differently (lateral chromatic aberration) |
| f_caustic | Focused light from a refractive surface → additive brightness field seeded by bright input regions |
| f_flare | Bright regions scatter light inside a virtual lens housing — radial streaks, rings, aperture polygons |
| f_diffraction | Wave-optics interference at an aperture edge — fine fringe patterns around bright regions |

**Shared parameter vocabulary to use consistently:**
- `intensity` — effect strength
- `source_brightness` or drive from input luma
- `focal_length` / `aperture` where physically meaningful
- `refraction_index` for lens/caustic

**Note:** Prior session work on aberration / f_lens exists — review before speccing any of these.

**Status:** Brainstormed. Pending scope review to decide prioritization vs. f_cymascope and f_chladni completion.

### Apollonian Fractal

Circular Apollonian gasket — iterative circle packing fractal. Naturally animatable by slowly varying seed circle geometry. GLSL implementation approach not yet determined (distance field? iterative inversion?). See `ideas/scratchpad.md`.

### Non-Euclidean Geometry / Hyperbolic Space

Three possible angles: hyperbolic tiling (Poincaré disk, Möbius transformations), spherical projection with controllable curvature, geodesic displacement as a processor. Möbius transformation math overlaps with Apollonian fractal. See `ideas/scratchpad.md`.

---

## Pending: Scope Review

Before prioritizing the optics family, f_cymascope build, or f_chladni plate morphing, a brief scope review is needed:

- What is the emerging taxonomy? (processors / optical elements / wave physics / geometry)
- Is there a performance arc that suggests what should be built next?
- Does f_cymascope feasibility block or unblock the caustic bpatcher?
- How does the generative side (f_chladni, f_cymascope) fit with the processor side (grader, hue, luma, tone)?

This scope review should inform task prioritization and can be done conversationally at the start of a session before touching any files.

---

## Clarifications

### Session 2026-05-25

- Q: How should bandpass filters be tuned — fixed fundamental, user-controlled, or broad-spectrum? → A: Two switchable modes (Bessel-ratio and log-spaced), toggled in companion patch via umenu. Default: Log. Bessel mode kept for physically-accurate use when audio source is a sustained tone.
- Q: What UI scope for companion patches? → A: Utility + basic controls — tuning mode toggle, master gain, per-band level meters. No per-band gain/mute or preset recall.
- Q: What drives m7 in the EEG path ("Spare" slot)? → A: Total power — sum of all 7 Muse band values, scaled to 0.0–1.0.
