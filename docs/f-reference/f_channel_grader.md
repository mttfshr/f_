# f_channel_grader — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

Per-channel color grading using lift/gamma/gain controls on R, G, B, and Master channels. A standard film-style grading model: lift sets the black point, gamma adjusts midtones, gain sets the white point.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `r_lift` | float | Red channel lift (black point) |
| `r_gamma` | float | Red channel gamma (midtone) |
| `r_gain` | float | Red channel gain (white point) |
| `g_lift` | float | Green channel lift |
| `g_gamma` | float | Green channel gamma |
| `g_gain` | float | Green channel gain |
| `b_lift` | float | Blue channel lift |
| `b_gamma` | float | Blue channel gamma |
| `b_gain` | float | Blue channel gain |
| `m_lift` | float | Master lift (all channels) |
| `m_gamma` | float | Master gamma |
| `m_gain` | float | Master gain |

## Signal Chain

```
texture in → jit.gl.pix (lift/gamma/gain codebox, per channel)
           → texture out
```

Parameters routed via `route bypass r_lift r_gamma r_gain g_lift g_gamma g_gain b_lift b_gamma b_gain m_lift m_gamma m_gain`.

## Loose Threads

- None known.

## Source File

`patchers/f_channel_grader.maxpat`
