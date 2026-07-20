# f_lens — Bpatcher Spec

_Last updated: 2026-07-16_
_Status: Working. v2 (ghost images, halation) shipped and verified in Max 2026-07-15/16. Tilt-shift confirmed live and working (resolves this doc's own prior "not yet wired" uncertainty — directly confirmed against the shipped patcher, not assumed)._

## Concept

A filmic lens processor simulating the experiential qualities of an imperfect physical lens — evocative, not physically-accurate optics. Combines radially-symmetric aberration/distortion/transmission (vignette), texture-driven modulation, a surface-emboss displacement inlet, axially-asymmetric tilt-shift focus, inter-reflection ghost images, and halation glow. Chain position: processor, placed anywhere between a source and downstream display layer.

Internally three objects in series: `lens_pix` (aberration/distortion/transmission/ghost/mod-inlets) → `lens_halation` (glow) → `jit.fx.cf.tiltshift` (focus) → outlet. Halation sits before tilt-shift deliberately — it represents a film/sensor-capture-time property, so it should be blurred along with everything else by the depth-of-field simulation, not applied after it.

**Slated for further change:** `tilt`/`tilt_axis`/`tilt_pos`/`slope`/`mode` and the `jit.fx.cf.tiltshift` object are scheduled for extraction to a new module, `f_focus` (`.specify/f_focus/`), once that module ships. Not yet removed as of this writing — `f_focus` hasn't been built yet, only specced.

## Parameters

| Name | Type | Range | Default | Tiers | Description |
|------|------|-------|---------|-------|-------------|
| `aberration` | float | -1.0–1.0 | 0.0 | ±1/±2/±10 | Chromatic aberration — RGB channel separation scaled by radius. Negative flips lead/lag side. |
| `distortion` | float | -1.0–1.0 | 0.0 | ±1/±5 | Barrel/pincushion distortion — 0=none, negative=barrel, positive=pincushion |
| `transmission` | float | -1.0–1.0 | 0.0 | ±1/±2 | Vignette / transmission falloff, warm-shifted toward edges. Negative overshoots into reverse-vignette. |
| `aberration_mod` | float | 0.0–1.0 | 0.0 | — | Aberration modulation depth (inlet 1 texture) |
| `distortion_mod` | float | 0.0–1.0 | 0.0 | — | Distortion modulation depth (inlet 2 texture) |
| `transmission_mod` | float | 0.0–1.0 | 0.0 | — | Transmission modulation depth (inlet 3 texture) |
| `surface_mod` | float | 0.0–5.0 | 0.0 | — | Surface emboss displacement depth (inlet 4 gradient texture) |
| `ghost` | float | -1.0–1.0 | 0.0 | — | Inter-reflection ghost intensity, additive, color-coupled to aberration. Negative subtracts (dark ghosts). |
| `ghost_count` | float (numbox) | 1–4 | 3 | — | Number of ghost taps, `floor()`'d in codebox |
| `ghost_spacing` | float | -1.0–1.0 | 0.3 | ±1/±5 | Offset scale between ghost taps. Negative mirrors ghosts inward through center. |
| `halation` | float | 0.0–1.0 | 0.0 | — | Halation glow intensity, additive, warm-tinted, luma-gated |
| `halation_threshold` | float | 0.0–1.0 | 0.7 | — | Luma gate point; regions above this bloom |
| `tilt` | float | 0.0–1.0 | 0.0 | — | Focal-plane tilt (`jit.fx.cf.tiltshift`'s `blur_amount`) |
| `tilt_axis` | float | 0.0–1.0 | 0.0 | — | Tilt band angle (`angle`) |
| `tilt_pos` | float | 0.0–1.0 | 0.5 | — | Tilt band position along axis (`center`) |
| `slope` | float | 0.0–1.0 | 0.5 | — | Sharp-to-blurred transition sharpness (`slope`) |
| `mode` | enum (live.text) | linear/radial | linear | — | Focus shape (`mode`) |
| `bypass` | bypass | 0/1 | 0 | — | Standard bypass — raw texture passthrough |

## Signal Chain

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix
routepass out0 (texture) → lens_pix in1
routepass unmatched → route <params> → live.dials/numbox/menu → attrui <name> → target object in0

in1 (aberration mod texture)   → lens_pix in2
in2 (distortion mod texture)   → lens_pix in3
in3 (transmission mod texture) → lens_pix in4
in4 (surface/gradient texture) → lens_pix in5

lens_pix out0 → lens_halation in0
lens_halation out0 → jit.fx.cf.tiltshift in0
jit.fx.cf.tiltshift out0 → out0
```

`tilt`/`tilt_axis`/`tilt_pos`/`slope` route to `jit.fx.cf.tiltshift` via attrui, matching its own attribute names directly (Max/Jitter attrui messages bind by name to whichever object receives them, regardless of which object declared the matching `Param`/attribute). `tilt_axis`/`tilt_pos` additionally pass through a `js lens_tiltcenter.js` transform before reaching `jit.fx.cf.tiltshift` (combines the two into whatever `center`/`angle` actually needs — not a direct 1:1 param mapping). `mode` dispatches via `sel 0 1` to two literal `"mode linear"`/`"mode radial"` messages.

`ghost`/`halation`/`halation_threshold` are normal params routed directly to their respective pix's matching-named `Param`, same mechanism as `aberration`/`distortion`/etc. — `ghost` targets `lens_pix`, `halation`/`halation_threshold` target `lens_halation` (a separate `jit.gl.pix` object, not `lens_pix`).

## Algorithm

### `lens_pix` (aberration, distortion, transmission, surface emboss, ghost)

```
dist = length(uv - 0.5)

// distortion (barrel/pincushion), modulated by in2 texture
k = distortion * (1 + dist_tex * distortion_mod)
warp_uv = (uv - 0.5) * (1 + k * r²) + 0.5

// surface emboss displacement, from in4 (sampled at 3 points, finite difference)
warp_uv += (surf_dx, surf_dy) * surface_mod

// chromatic aberration, modulated by in1 texture
ab = aberration * dist * (1 + aberr_tex * aberration_mod)
r = sample(in1, warp_uv scaled by (1+ab)).r
g = sample(in1, warp_uv).g
b = sample(in1, warp_uv scaled by (1-ab)).b

// transmission / vignette, modulated by in3 texture, warm color shift
vignette = 1 - smoothstep(0.3, 0.7, dist * (1 + trans_tex * transmission_mod))
effect_out = mix(effect_out * warm_shift * vignette, effect_out, 1 - transmission)

// ghost: 1-4 offset taps along the same post-distortion warp vector,
// each independently sampling R/G/B at its own aberration-scaled offset
// (color-coupled to `ab` — real lens ghosts show more fringing than the
// primary image), attenuated per tap (0.6^(n-1) falloff), added on top
// with alpha explicitly zeroed to avoid drifting the composite past 1.0
effect_out += ghost_composite * ghost

out1 = mix(effect_out, sample(in1, uv), bypass)
```

### `lens_halation` (separate `jit.gl.pix`, single texture inlet)

```
luma-gate each of 16 fixed isotropic taps independently (8 directions ×
2 radii, weighted 1.0/0.5 falloff between rings — no intermediate
gated buffer is possible within one codebox pass, so each tap re-derives
its own luma/threshold gate from the source texture directly) →
average the gated taps → additive warm-tinted (1.1/1.0/0.85) composite
onto the source, scaled by `halation`
```

48 texture samples/pixel. Confirmed 59-60fps in Max even at this cost.

Unconnected `in1`/`in2`/`in3`/`in4` on `lens_pix` sample as black; at default `*_mod=0.0` this contributes no modulation regardless (neutral-guard by depth default, not by a texture-presence check).

## Loose Threads

- **Bypass is incomplete — real bug, confirmed 2026-07-17.** The bypass jsui → attrui (`@attr bypass`) wiring targets `lens_pix` only. `lens_halation` and `jit.fx.cf.tiltshift` (both downstream in the `lens_pix → lens_halation → tiltshift → outlet` chain) receive no bypass wiring at all — toggling bypass today only makes the radial aberration/distortion stage transparent; halation and tiltshift stay live and keep applying whatever their own params are set to. Intended behavior is full-module passthrough. Fix belongs with the `f_focus` extraction (removing tiltshift simplifies the remaining problem to just `lens_pix`+`lens_halation`) or as its own v2 cleanup pass. See `.specify/plan.md` Work Queue item 9.
- **Tilt-shift is slated for removal** once `f_focus` ships (near-mechanical port, not yet built — see `.specify/f_focus/`). When that lands, `tilt`/`tilt_axis`/`tilt_pos`/`slope`/`mode`, the `jit.fx.cf.tiltshift` object, and `lens_tiltcenter.js` all come out of this module entirely — this doc's Parameters/Signal Chain/Algorithm sections above will need trimming at that point, not just a note.
- **`definition.py`'s tilt-shift representation is a verbatim splice** (`raw_ui` params + `raw_boxes`/`raw_lines`/`raw_parameters`, extracted from the working live patcher and ID-remapped to an `obj-raw-N` namespace), not a declarative schema description — `build_patcher.py` doesn't understand *why* this wiring works, it just preserves it unmodified on regeneration. See `ideas/build_patcher_schema_gaps.md` for the full background.
- Anamorphic (static + field-driven directional squeeze) was considered for v2 and deliberately moved out to its own future module — see `ideas/f_anamorph_unnamed.md`. Not in scope for `f_lens`.
- `panel_toggle` (front="lens"/back="field") is real, generated infrastructure now (`build_patcher.py`'s `panel_toggle` schema key) — not hand-built JSON anymore, though it started that way in v1.

## Source File

`package/patchers/f_lens.maxpat` — built from `src/f_lens/definition.py` (+ `raw_tiltshift.json`, `raw_halation.json`, `codebox_lens.gen`, `codebox_halation.gen`) via `build/build_patcher.py`.
