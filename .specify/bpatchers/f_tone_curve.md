# f_tone_curve — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

Tone curve adjustment with shadow, midtone, and highlight bands. Applies brightness/luminance adjustments selectively by tonal range. The `low_mid` and `mid_high` breakpoints define the band boundaries; `edge_falloff` softens transitions between bands.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `shadows` | float | Adjustment applied to shadow tones |
| `midtones` | float | Adjustment applied to midtones |
| `highlights` | float | Adjustment applied to highlights |
| `edge_falloff` | float | Softness of transitions between tonal bands |
| `low_mid` | float | Breakpoint between shadows and midtones |
| `mid_high` | float | Breakpoint between midtones and highlights |

## Signal Chain

```
texture in → jit.gl.pix (tone curve codebox)
           → texture out
```

Parameters routed via `route bypass shadows midtones highlights edge_falloff low_mid mid_high`.

## Loose Threads

- None known. Shares `low_mid` / `mid_high` / `edge_falloff` convention with `f_luma_processor` — consider whether these should always match when used in sequence.

## Source File

`patchers/f_tone_curve.maxpat`
