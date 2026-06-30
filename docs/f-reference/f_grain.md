# f_grain — Bpatcher Spec

_Last updated: 2026-05-25_
_Status: Working_

## Concept

Stochastic grain field with per-grain displacement and luma gating. Generates a field of randomized grains whose position, size, shape, and color are driven by the input texture's luminance. A persistent feedback layer allows grains to accumulate or decay over time.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `density` | float | Number of grains per field |
| `amount` | float | Overall grain intensity |
| `persistence` | float | Temporal persistence — 0 = boil, 1 = frozen |
| `fade` | float | Fade rate of accumulated grains |
| `size` | float | Base grain size |
| `size_var` | float | Grain size variance (randomization) |
| `shape` | float | Grain shape (circular → elongated) |
| `softness` | float | Grain edge softness |
| `jitter` | float | Positional jitter / displacement amount |
| `ch_diverge` | float | Per-channel color divergence |
| `luma_gate` | float | Luminance threshold for grain placement |
| `displace` | float | Displacement magnitude |
| `edge_mode_menu` | int | Edge handling mode |
| `field` | float | Field scale |
| `sv_seed` | int | Random seed for grain field |

## Signal Chain

```
texture in → jit.gl.pix (grain field codebox)
           → feedback accumulation
           → texture out
```

Parameters routed via `route bypass density amount persistence fade size size_var shape softness jitter ch_diverge luma_gate displace edge_mode_menu field sv_seed`.

## Loose Threads

- None known.

## Source File

`patchers/f_grain.maxpat`
