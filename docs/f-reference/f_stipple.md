# f_stipple — Bpatcher Spec

_Last updated: 2026-07-05_
_Status: Working_

## Concept

A 2D hash field rendered as stipple — no mark geometry, no course structure, pure field operation. Dual-mode: **source mode** (inlet 0 unconnected) generates a standalone luminance stipple texture from parameters alone; **processor mode** (texture present on inlet 0) uses the incoming texture to modulate the hash field, in one of two sub-modes selected via `src_mode`:

- **Dither/density:** incoming luma modulates local threshold — bright regions get dense stipple, dark regions get sparse (halftone/mezzotint character). Output inherits input color when `colorize=1`.
- **Displacement:** incoming luma warps the hash-field coordinates spatially — stipple bends around bright/dark regions, amount set by `threshold`.

Mode is auto-detected via `vs_inState` (Vsynth convention: connection-event timing, not alpha/luma) and drives the internal `src_mode` param — not user-facing.

Two orthogonal hash fields — a sin-based directional hash and an arithmetic isotropic hash — are blended by `anisotropy`. At `anisotropy=1`, parallel lines read clearly; at `anisotropy=0`, isotropic grain; in between is the primary expressive zone.

## Parameters

| Name | Type | Range | Default | Description |
|------|------|-------|---------|-------------|
| `freq` | float | 0.0–20.0 | 5.0 | Hash field spatial frequency |
| `coarseness` | float | 1.0–100.0 | 1.0 | Grain period scale — higher = chunkier grains |
| `anisotropy` | float | 0.0–4.0 | 0.5 | 0=isotropic grain, 1=parallel lines, >1=expressive aliasing |
| `angle` | float | -360–360 | 0.0 | Orientation of along/across coordinate frame |
| `zoom` | float | 0.1–4.0 | 1.0 | Scales viewport into hash field — same character, bigger or smaller |
| `threshold` | float | 0.0–2.0 | 0.5 | Dither bias (dither mode) / displacement amount (displacement mode) |
| `colorize` | float | 0.0–1.0 | 0.0 | Processor only: 0=monochrome dither output, 1=inherit input color |
| `along_phase` | float | -1.0–1.0 | 0.0 | Hash field offset along angle axis; drive externally for drift |
| `across_phase` | float | -1.0–1.0 | 0.0 | Hash field offset perpendicular to angle axis; drive externally for drift |
| `softness` | float | 0.0–2.0 | 0.1 | Smoothstep width at comparison boundary |
| `src_mode` | internal | 0/1 | — | Driven by `vs_inState`; 0=source, 1=processor. Not user-facing. |
| `bypass` | bypass | 0/1 | 0 | Source bypass → black. Processor bypass → passthrough. |

## Signal Chain

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix

routepass out0 (texture or vs_black) → stipple_pix in0   [render trigger]
vs_inState outlet 1 (0/1 state) → prepend param src_mode → stipple_pix in0

routepass unmatched → route <params> → live.dials → prepend param <name> → stipple_pix in0

stipple_pix out0 (composite) → out0
stipple_pix out1 (stipple mask) → out1
stipple_pix out2 (displaced source) → out2
```

Three outlets: composite (color-graded stipple), stipple mask (raw scalar), and displaced source (input resampled at the displacement-warped UV — always computed regardless of mode).

## Algorithm

Coordinate frame rotates by `angle` into `along`/`across` axes; `along_phase`/`across_phase` offset the field for drift. `coarseness` scales the hash's large prime multiplier down to lengthen the grain period. Two hash fields — `h_parallel` (sin-based, directional) and `h_iso` (arithmetic, combining both axes) — blend via `anisotropy`. In dither mode, the field is thresholded against `threshold ± softness/2` directly; in displacement mode, `along`/`across` are warped by `input_luma * threshold` before the field is evaluated. `src_mode` selects between them:

```
lo = threshold - softness*0.5; hi = threshold + softness*0.5;
source_stipple  = smoothstep(lo, hi, hash_field)
dither_stipple  = smoothstep(hash_field - softness*0.5, hash_field + softness*0.5, input_luma + threshold - 0.5)
stipple = mix(source_stipple, dither_stipple, src_mode)
```

Displaced-source output (out2) resamples the input at UV coordinates rotated back from the along/across-displaced frame — independent of `src_mode`, always available.

## Loose Threads

- `proc_mode` (dither vs. displacement sub-mode) described in spec.md as a separate exposed param — the shipped codebox instead computes displacement unconditionally into out2 and blends dither vs. source-mode stippling via `src_mode` only. If a live dither/displacement toggle is wanted, it isn't currently wired as its own param.
- Source-mode alpha handling flagged as unverified in spec.md — not reconfirmed since.

## Source File

`patchers/f_stipple.maxpat`
