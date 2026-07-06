# f_lens — Bpatcher Spec

_Last updated: 2026-07-05_
_Status: Working (tilt/tilt_axis/tilt_pos/slope/mode present in UI, not yet wired into the codebox)_

## Concept

A filmic lens processor simulating the experiential qualities of an imperfect physical lens — evocative, not physically-accurate optics. Combines radially-symmetric aberration/distortion/transmission (vignette) with texture-driven modulation and a surface-emboss displacement inlet. Chain position: processor, placed anywhere between a source and downstream display layer.

Tilt-shift (axially-asymmetric focus falloff) is designed around `jit.fx.cf.tiltshift` sitting downstream of `lens_pix` per `spec.md`, but `tilt`/`tilt_axis`/`tilt_pos`/`slope`/`mode` are currently marked `"internal"` in `definition.py` — present in the parameter list/UI but not yet wired to any effect. Treat as UI-only placeholders until confirmed connected.

## Parameters

| Name | Type | Range | Default | Description |
|------|------|-------|---------|-------------|
| `aberration` | float | 0.0–1.0 | 0.0 | Chromatic aberration — RGB channel separation scaled by radius from center |
| `distortion` | float | 0.0–1.0 | 0.5 | Barrel/pincushion distortion — 0.5=none, <0.5=barrel, >0.5=pincushion |
| `transmission` | float | 0.0–1.0 | 0.0 | Vignette / transmission falloff, warm-shifted toward edges |
| `aberration_mod` | float | 0.0–1.0 | 0.0 | Aberration modulation depth (inlet 2 texture) |
| `distortion_mod` | float | 0.0–1.0 | 0.0 | Distortion modulation depth (inlet 3 texture) |
| `transmission_mod` | float | 0.0–1.0 | 0.0 | Transmission modulation depth (inlet 4 texture) |
| `surface_mod` | float | 0.0–5.0 | 0.0 | Surface emboss displacement depth (inlet 5 gradient texture) |
| `tilt` | internal | — | — | Not yet wired — reserved for `jit.fx.cf.tiltshift`'s `blur_amount` |
| `tilt_axis` | internal | — | — | Not yet wired — reserved for `angle` |
| `tilt_pos` | internal | — | — | Not yet wired — reserved for `center` |
| `slope` | internal | — | — | Not yet wired — reserved for `slope` |
| `mode` | internal | — | — | Not yet wired — reserved for linear/radial focus-shape select |
| `bypass` | bypass | 0/1 | 0 | Standard bypass — raw texture passthrough |

## Signal Chain

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix
routepass out0 (texture) → lens_pix in1
routepass unmatched → route <params> → live.dials → prepend param <name> → lens_pix in0

in1 (aberration mod texture)  → lens_pix in2
in2 (distortion mod texture)  → lens_pix in3
in3 (transmission mod texture)→ lens_pix in4
in4 (surface/gradient texture)→ lens_pix in5

lens_pix out0 → out0
```

(Inlet numbering above follows the codebox's `in1`–`in5`; consult `patchers/f_lens.maxpat` for the outer bpatcher's actual inlet-to-`in`N mapping.)

## Algorithm

```
dist = length(uv - 0.5)

// distortion (barrel/pincushion), modulated by in3
k = (distortion - 0.5) * 2.0 * (1 + dist_tex * distortion_mod)
warp_uv = (uv - 0.5) * (1 + k * r²) + 0.5

// surface emboss displacement, from in5 (sampled at 3 points, finite difference)
warp_uv += (surf_dx, surf_dy) * surface_mod

// chromatic aberration, modulated by in2
ab = aberration * dist * (1 + aberr_tex * aberration_mod)
r = sample(in1, warp_uv scaled by (1+ab)).r
g = sample(in1, warp_uv).g
b = sample(in1, warp_uv scaled by (1-ab)).b

// transmission / vignette, modulated by in4, warm color shift
vignette = 1 - smoothstep(0.3, 0.7, dist * (1 + trans_tex * transmission_mod))
effect_out = mix(effect_out * warm_shift * vignette, effect_out, 1 - transmission)

out1 = mix(effect_out, sample(in1, uv), bypass)
```

Unconnected `in2`/`in3`/`in4` sample as black; at default `*_mod=0.0` this contributes no modulation regardless (neutral-guard by depth default, not by a texture-presence check).

## Loose Threads

- Tilt-shift (`tilt`, `tilt_axis`, `tilt_pos`, `slope`, `mode`) is speced against `jit.fx.cf.tiltshift` in `.specify/f_lens/spec.md` but is not present anywhere in the shipped codebox — confirm whether the outer `.maxpat` actually instantiates `jit.fx.cf.tiltshift` downstream before assuming this feature works.
- `surface_mod` in `definition.py` samples `in5` (a 4th modulation texture, described as a "gradient texture") for emboss-style displacement — this is a 4th mod inlet beyond the 3 (`aberration_mod`/`distortion_mod`/`transmission_mod`) described in `spec.md`'s original in2/in3 two-inlet design. Spec and shipped code have diverged; this doc follows the shipped codebox.
- Inter-reflection/ghosting and anamorphic effects are explicitly out of scope (see spec.md), tabled as a potential separate `f_interreflect` module.

## Source File

`patchers/f_lens.maxpat`
