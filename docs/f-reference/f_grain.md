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
| `edge_mode` | int | Edge handling mode (Clear/Clamp/Wrap/Mirror) |
| `field` | float | Field scale |
| `sv_seed` | int | Random seed for grain field |

## Signal Chain

```
texture in → jit.gl.pix (grain field codebox)
           → feedback accumulation
           → texture out
```

Parameters routed via `route bypass density amount persistence fade size size_var shape softness jitter ch_diverge luma_gate displace edge_mode field sv_seed`.

## Loose Threads

- `softness`'s `live.dial` range is `0.0-5.0` with no custom min, unlike `shape`/`jitter` which both got tuned ranges -- appears to be an untuned Max default, never corrected. The codebox only uses it meaningfully in `[0,1]` (`feather = mix(0.02, 0.5, softness)`); values beyond ~1.0 just keep extrapolating with no new effect. Not urgent, but a real inconsistency.
- This module predates `build_patcher.py` (patcher added 2026-05-23, build system added 2026-05-30). `src/f_grain/definition.py` was written after the fact (2026-07-05) as a record of the real `.maxpat`, not a generator for it -- **never regenerate this module via `build_patcher.py`.**

## Source File

`patchers/f_grain.maxpat`
