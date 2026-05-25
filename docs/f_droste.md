# f_droste — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

Log-polar spiral transform producing Droste / Escher-style recursive zoom effects. Maps the input texture through a log-polar coordinate transformation; by varying zoom and rotation continuously, the image appears to zoom infinitely inward along a spiral path.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `zoom` | float | Zoom scale — rate of logarithmic zoom |
| `n_arms` | float | Number of spiral arms |
| `twist` | float | Twist amount — angular winding per zoom cycle |
| `rotation` | float | Global rotation offset |

## Signal Chain

```
texture in → jit.gl.pix (log-polar transform codebox)
           → texture out
```

Parameters routed via `route bypass zoom n_arms twist rotation`.

## Loose Threads

- None known. Considered the most stable bpatcher in the package.

## Source File

`patchers/f_droste.maxpat`
