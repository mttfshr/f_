# f_droste — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

Log-polar spiral transform producing Droste / Escher-style recursive zoom effects. Maps the input texture through a log-polar coordinate transformation; by varying zoom and rotation continuously, the image appears to zoom infinitely inward along a spiral path.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing — 0/1 |
| `zoom` | float | Zoom scale — rate of logarithmic zoom — 1.1–100.0 |
| `n_arms` | int | Number of spiral arms — 1–16 |
| `twist` | float | Twist amount — angular winding per zoom cycle — -8.0–8.0 |
| `rotation` | float | Global rotation offset — 0.0–1.0 |
| `time_s` | float | Animation driver — scalar signal, use LFO data outlet — continuous |

## Signal Chain

```
texture in → jit.gl.pix (log-polar transform codebox)
           → texture out
```

Parameters routed via `route bypass zoom n_arms twist rotation`.

## Loose Threads

- `time_s` inlet is on in[1] (texture inlet on in[0]). Vsynth convention puts time/scalar control on in[0] — should be swapped in a future refactor. Not urgent.
- `time_s` expects a scalar signal, not a texture. Use an LFO's data outlet (out[1]), not its texture outlet (out[0]). The helpfile uses `vs_wfg_s` — wire from its second outlet.

## Source File

`patchers/f_droste.maxpat`

## References

The log-polar transform is grounded in classical complex analysis: the mapping `log(z) = log|z| + i·arg(z)` converts multiplication (zoom/rotation) into addition (translation in log-polar space), which is what makes seamless tiling possible.

The specific application to recursive image tiling is described in:
- Lenstra, H.W. & de Smit, B. (2003). "Solving Escher's Problem." https://www.math.leidenuniv.nl/~smit/escher/

The symmetric shear formulation used here — shearing `s` by `t` and `t` by `s` simultaneously — was derived during development and is not taken from any specific source. It produces the property that both angular and radial tiling lines become spirals simultaneously. At `twist=1`, one full revolution equals one zoom level: the "Escher coupling." Earlier implementations sheared only one direction, giving one spiral family and one circular family.
