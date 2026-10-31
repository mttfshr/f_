# f_grain — Bpatcher Spec

_Last updated: 2026-10-09_
_Status: Working_

## Concept

Stochastic grain field with per-grain displacement and luma gating. Generates a field of randomized grains whose position, size, and shape are driven by a voronoi hash field; the input texture's luminance (via `luma_gate`) only modulates the grains' intensity, and their color is randomized per cell rather than picked from the texture. A persistent feedback layer allows grains to accumulate or decay over time.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass processing |
| `density` | float | Gates which fixed-grid cells show a grain |
| `gain` | float | Grain intensity (unbounded, 0-2). Renamed from `amount` 2026-10-09 (T003) to match the library-wide gain/mix convention. |
| `persistence` | float | Temporal persistence — 0 = boil, 1 = frozen |
| `fade` | float | Width of each grain era's in/out fade envelope |
| `size` | float | Base grain size |
| `size_var` | float | Grain size variance (randomization) |
| `shape` | float | Grain shape blend: voronoi cell outline (0) → circle (1) |
| `softness` | float | Grain edge softness |
| `jitter` | float | Positional jitter / displacement amount |
| `ch_diverge` | float | Per-channel color divergence |
| `luma_gate` | float | Bipolar luma weighting of grain intensity (-1 = shadows, 0 = uniform, +1 = highlights) |
| `displace` | float | Displacement magnitude |
| `edge_mode` | int | Edge handling mode (Clear/Clamp/Wrap/Mirror) |
| `field` | float | Jitter seed position — interpolates smoothly between voronoi jitter topologies |
| `sv_seed` | int | Seed for per-cell size variation, smoothly interpolated |
| `mix_pct` | float | Dry/wet crossfade (0-100%) toward the fully-composited (displaced-source + grain) state. New 2026-10-09 (T003); default 100 keeps the module's prior look unchanged. Internal codebox `Param` named `mix_pct`, not `mix`, to avoid colliding with the codebox's `mix()` operator. |

## Signal Chain

```
texture in → jit.gl.pix (grain field codebox)
           → era-clock persistence (no feedback loop)
           → texture out
```

Parameters routed via `route bypass density gain persistence fade size size_var shape softness jitter ch_diverge luma_gate displace mix_pct edge_mode field sv_seed`.

**Render size (2026-10-30, T063).** The module renders at Vsynth's render size: the pix is `@adapt 0`, and the internal `width` / `height` Params (driven by the builder's `render_dim`, so there is nothing to set) give the grain grid its aspect: `aspect = width / height`, locked to the render size. `dim` reads 1 inside a live `jit.gl.pix`, so the codebox's old `aspect = dim.x / dim.y` may have been 1 live (grid cells stretched with the frame); with the render aspect the cells are square in pixels, and the cell grid scales with the aspect, so a visible pattern can differ from before. An `Aspect` menu (Render / dim / Square) was added and removed the same day: on the GPU bench `Square` cells came out 1.78x wider than `Render` (Size 0.5-0.75), but live all three modes looked identical and Matt chose to lock it at Render. The grid's on-screen cell height is `frame height x 2^(12 Size) / 4096` (1080 high: 0.26 px at Size 0, 17 px at 0.5), so at Size 0 the grain is sub-pixel noise whatever the aspect. The input is assumed render-sized; the output follows the render size.

`displaced-source + grain` is the full composite (`driven`); `mix_pct` crossfades toward it from the plain displaced source, same shape as the gain/mix convention elsewhere in the library.

## Loose Threads

- ~~`softness`'s `live.dial` range is `0.0-5.0`~~ -- **FIXED 2026-10-09** (`.specify/f_grain/tasks.md` T002). The codebox only ever reads `softness` meaningfully in `[0,1]` (`feather = mix(0.02, 0.5, softness)`); hand-edited the shipped `.maxpat`'s dial (`parameter_mmax` 5.0 -> 1.0, `obj-31`) and `src/f_grain/definition.py` to match, surgically (at the time it was still on the never-regenerate list; T003 the same day took it off).
- ~~This module predates `build_patcher.py`... never regenerate this module via `build_patcher.py`~~ -- **STALE, corrected 2026-10-09** (T003). `build/drift.py -v f_grain` shows it reproducing the shipped patch byte for byte; `src/f_grain/definition.py` is the generator again, same as any other module. The bespoke, hand-built parts (persistence era-clock chain, second `route field sv_seed`, edge_mode umenu) are captured verbatim in `raw_ui.json`'s `raw_boxes`/`raw_lines`.
- **Standing hazard**: `raw_ui.json`'s `raw_lines` hardcode source-outlet *indices* on the shared `route` object (not symbolic references). `build_patcher.py` always orders the generated route tokens as `ui_params + header_toggles + raw_ui_params` — grouped by type, not by `definition.py` list position — so adding *any* new `float`/`int`/`menu`/`text_button` param (anywhere in the list) shifts every `raw_ui`-type param's (`edge_mode`, `field`, `sv_seed`) outlet index by one, silently breaking their raw_lines. Hit and fixed once already (T003, adding `mix_pct`). The next param added to this module will need the same manual re-index in `raw_ui.json` -- check `tests/contracts/test_module_contracts.py`'s `unrouted`/`route_map` output after any rebuild, don't assume it's safe.

## References

Film-grain synthesis via hash-noise sampling is an original construction; no external source was consulted. The dual-mode convention (source mode: generator; processor mode: grain over an input texture, auto-detected via `vs_inState`) established here is the pattern `f_stipple` follows.

This module predates `build_patcher.py` (patcher added 2026-05-23, build system 2026-05-30). Taken off the never-regenerate list 2026-10-09 (T003): `src/f_grain/definition.py` is the generator again and reproduces the shipped patch byte for byte.

See `docs/f-reference/f_grain.md` (this file) for the full parameter reference.

## Source File

`patchers/f_grain.maxpat`
