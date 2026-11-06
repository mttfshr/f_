# f_tone_curve — Bpatcher Spec

_Last updated: 2026-11-06_
_Status: Working_

## Concept

Quick tonal shaping: brighten or darken shadows, mids and highlights separately. Each pixel's luma (Rec. 601) picks its band, and the band's dial is added equally to R, G and B, then clamped to 0-1; alpha passes through. The `low_mid` and `mid_high` breakpoints define the band boundaries (set on the two-handle slider or the numboxes; swapped handles are sorted); `edge_falloff` softens transitions between bands. All defaults are neutral, so the output equals the source until a dial moves.

It is not a curve editor (see References). At `edge_falloff` 0, the default, the bands meet at a hard step, so different lifts on either side leave a visible contour at the crossover (inferred from the codebox, not run; `smoothstep` with equal edges is undefined in GLSL).

## Parameters

| Name | Type | Range | Default | Description |
|------|------|-------|---------|-------------|
| `bypass` | toggle | 0/1 | 0 | Native `@bypass`: passes the raw input texture. The codebox's `Param bypass` mix does not run from the toggle (`G-bypass-native`) |
| `shadows` | float | -1 to 1 | 0 | Lift added to shadow tones |
| `midtones` | float | -1 to 1 | 0 | Lift added to midtones |
| `highlights` | float | -1 to 1 | 0 | Lift added to highlights |
| `edge_falloff` | float | 0-1 | 0 | Softness of transitions between tonal bands |
| `low_mid` | float | 0-1 | 0.33 | Breakpoint between shadows and midtones |
| `mid_high` | float | 0-1 | 0.67 | Breakpoint between midtones and highlights |

## Signal Chain

```
in0 (texture + control) → routepass jit_gl_texture jit_matrix → jit.gl.pix @name tone_curve @type char → out0
```

One inlet; the texture is required. There is no `vs_inState`, no `vs_black` fallback and no `r draw`, so the incoming texture is the only thing that triggers the pix: nothing connected means no output. `@type char` means 8-bit output, so a float input is quantized and clamped here.

Parameters routed via `route bypass shadows midtones highlights edge_falloff low_mid mid_high`; anything else goes to the pix.

## Loose Threads

- Bypass stays native (Matt, 2026-11-06; `G-bypass-native`). For a texture processor the visible result is the same source passthrough.
- Uses the same low_mid / mid_high / edge_falloff parameters as f_luma_processor, but with different defaults (this module's edge_falloff default is 0.0, while luma_processor's is 0.1); consider whether these should always match when used in sequence.

## References

The three-band smoothstep lift implemented here is an original construction; no external source was consulted. Despite the name, it is not a curve editor -- `ideas/lut_curve_and_color_controls.md` records both the naming critique and the dependent-texture 1x256 LUT successor design (flagged by Matt as "wants this pursued for real").

See `docs/f-reference/f_tone_curve.md` (this file) for the full parameter reference; see the ideas file for the LUT direction.

## Source File

`package/patchers/f_tone_curve.maxpat`
