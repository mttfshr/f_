# f_luma_processor — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

Luminance-selective processing. Isolates a luma range within the input texture and applies saturation, luminance shift, and hue shift within that range. The luma selection band is set by `low_mid` and `mid_high` breakpoints.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `sat_amt` | float | Saturation adjustment within selected luma range |
| `lum_shift` | float | Luminance shift within selected luma range |
| `hue_shift` | float | Hue rotation within selected luma range |
| `edge_falloff` | float | Softness of the luma selection boundary |
| `low_mid` | float | Breakpoint between low and mid luma bands |
| `mid_high` | float | Breakpoint between mid and high luma bands |

## Signal Chain

```
texture in → jit.gl.pix (luma selection + processing codebox)
           → texture out
```

Parameters routed via `route bypass sat_amt lum_shift hue_shift edge_falloff low_mid mid_high`.

## Loose Threads

- None known. Parallel structure to `f_hue_processor` — changes to one often suggest parallel changes to the other.

## Source File

`patchers/f_luma_processor.maxpat`
