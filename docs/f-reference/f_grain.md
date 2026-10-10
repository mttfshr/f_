# f_grain — Bpatcher Spec

_Last updated: 2026-10-09_
_Status: Working_

## Concept

Stochastic grain field with per-grain displacement and luma gating. Generates a field of randomized grains whose position, size, shape, and color are driven by the input texture's luminance. A persistent feedback layer allows grains to accumulate or decay over time.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `density` | float | Number of grains per field |
| `gain` | float | Grain intensity (unbounded, 0-2). Renamed from `amount` 2026-10-09 (T003) to match the library-wide gain/mix convention. |
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
| `mix_pct` | float | Dry/wet crossfade (0-100%) toward the fully-composited (displaced-source + grain) state. New 2026-10-09 (T003); default 100 keeps the module's prior look unchanged. Internal codebox `Param` named `mix_pct`, not `mix`, to avoid colliding with the codebox's `mix()` operator. |

## Signal Chain

```
texture in → jit.gl.pix (grain field codebox)
           → feedback accumulation
           → texture out
```

Parameters routed via `route bypass density gain persistence fade size size_var shape softness jitter ch_diverge luma_gate displace mix_pct edge_mode field sv_seed`.

`displaced-source + grain` is the full composite (`driven`); `mix_pct` crossfades toward it from the plain displaced source, same shape as the gain/mix convention elsewhere in the library.

## Loose Threads

- ~~`softness`'s `live.dial` range is `0.0-5.0`~~ -- **FIXED 2026-10-09** (`.specify/f_grain/tasks.md` T002). The codebox only ever reads `softness` meaningfully in `[0,1]` (`feather = mix(0.02, 0.5, softness)`); hand-edited the shipped `.maxpat`'s dial (`parameter_mmax` 5.0 -> 1.0, `obj-31`) and `src/f_grain/definition.py` to match, surgically (this module is on the never-regenerate list).
- ~~This module predates `build_patcher.py`... never regenerate this module via `build_patcher.py`~~ -- **STALE, corrected 2026-10-09** (T003). `build/drift.py -v f_grain` shows it reproducing the shipped patch byte for byte; `src/f_grain/definition.py` is the generator again, same as any other module. The bespoke, hand-built parts (persistence era-clock chain, second `route field sv_seed`, edge_mode umenu) are captured verbatim in `raw_ui.json`'s `raw_boxes`/`raw_lines`.
- **Standing hazard**: `raw_ui.json`'s `raw_lines` hardcode source-outlet *indices* on the shared `route` object (not symbolic references). `build_patcher.py` always orders the generated route tokens as `ui_params + header_toggles + raw_ui_params` — grouped by type, not by `definition.py` list position — so adding *any* new `float`/`int`/`menu`/`text_button` param (anywhere in the list) shifts every `raw_ui`-type param's (`edge_mode`, `field`, `sv_seed`) outlet index by one, silently breaking their raw_lines. Hit and fixed once already (T003, adding `mix_pct`). The next param added to this module will need the same manual re-index in `raw_ui.json` -- check `tests/test_module_contracts.py`'s `unrouted`/`route_map` output after any rebuild, don't assume it's safe.

## Source File

`patchers/f_grain.maxpat`
