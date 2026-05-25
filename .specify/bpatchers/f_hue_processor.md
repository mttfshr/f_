# f_hue_processor — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

Hue-selective processing. Isolates a hue range within the input texture and applies saturation, luminance, and hue shift operations only within that range. The selection boundary is controlled by `hue_lower` / `hue_upper` range sliders with a falloff parameter for smooth edges.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `sat_amt` | float | Saturation adjustment within selected hue range |
| `lum_shift` | float | Luminance shift within selected hue range |
| `hue_shift` | float | Hue rotation within selected hue range |
| `edge_falloff` | float | Softness of the hue selection boundary |
| `hue_lower` | float | Lower hue bound (rslider — **not remotely controllable**) |
| `hue_upper` | float | Upper hue bound (rslider — **not remotely controllable**) |

## Signal Chain

```
texture in → jit.gl.pix (hue selection + processing codebox)
           → texture out
```

Parameters routed via `route bypass sat_amt lum_shift hue_shift edge_falloff`.
Note: `hue_lower` and `hue_upper` are intentionally excluded from the route.

## Loose Threads

- **hue_lower / hue_upper not remotely controllable** — rslider params intentionally excluded from `route`. The rslider widget works in UI but cannot be driven by message. Revisit if remote control is needed.

## Source File

`patchers/f_hue_processor.maxpat`
