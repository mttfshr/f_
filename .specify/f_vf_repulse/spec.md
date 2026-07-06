# f_vf_repulse — Spec

## Status: Scratch patch verified 2026-06-18

## Concept

Texture in → f_vecfield out. For each pixel, samples 16 points evenly distributed around a ring at radius `reach` and accumulates repulsion vectors away from bright (above `threshold`) regions. Single-pass, per-frame, no feedback required.

Primary use case: any texture source → repulsion vecfield → f_vf_advect, producing fluid motion away from bright regions. Multiple instances produce interacting repulsion fields.

Replaces the earlier sobel+dilate approach — this architecture correctly produces omnidirectional outward flow from arbitrary shapes without edge detection or multipass propagation.

## Signal Flow

```
texture in → [16-sample ring accumulation] → encode as f_vecfield → vecfield out
```

## Parameter Contract

| Param     | Type    | Range      | Default | Description |
|-----------|---------|------------|---------|-------------|
| strength  | float   | -10 – 10   | 4.0     | Field magnitude scale. Negative = attraction. |
| reach     | float   | -0.5 – 0.5 | 0.1     | Ring sample radius in normalized UV. Negative samples inside shapes. |
| threshold | float   | -1 – 1     | 0.3     | Luma threshold for repulsion contribution. Negative = repulse from dark regions. |
| mode      | integer | 0 – 3      | 0       | Accumulation mode (see below). |
| bypass    | bool    | 0/1        | 0       | Pass input texture through unchanged. |

## Mode Behaviors

All params produce meaningful results with negative values — do not clamp externally.

| Mode | Name      | Behavior |
|------|-----------|----------|
| 0    | Cancel    | Straight vector accumulation. Opposing contributions neutralize — stagnation zones between blobs. |
| 1    | Max       | Strongest single sample wins. No cancellation. Nearest bright region dominates at each pixel. |
| 2    | Abs add   | Accumulate magnitudes regardless of direction. Normalize to direction of strongest. Fields reinforce. |
| 3    | Turbulent | Cancel behavior, but inject curl rotation in cancellation zones (where abs_mag high, cancel_mag low). |

## Architecture

Pure processor — single jit.gl.pix, float32 in/out. No feedback, no textureset. Stateless per-frame computation.

16 evenly-spaced sample directions (precomputed unit vectors). Luma weighting: Rec. 601 (0.299r + 0.587g + 0.114b). if/else branching on mode_i = floor(mode) — only active mode computed per pixel.

## Archetype

Pure processor. Single texture inlet, single vecfield outlet. `@type float32`.

## Notes on f_vf_dilate

The dilate module (earlier planned) is not needed for this architecture. f_vf_repulse handles spatial reach directly via the ring sample radius. f_vf_dilate remains specced but deprioritized — may be useful for spreading other vecfields (vortex, fieldmap) but is not required for the repulse use case.

## Acceptance Criteria

- [x] Scratch patch: omnidirectional repulsion field around masonry blobs
- [x] reach sweeps influence radius smoothly
- [x] threshold cleanly isolates repulsion source regions
- [x] All four modes produce distinct, useful field characters
- [x] Negative strength → attraction field
- [x] Negative reach → samples inside shapes
- [x] Negative threshold → repulse from dark regions
- [x] f_vf_advect downstream produces fluid motion away from shape boundaries
- [ ] Audit passes clean
- [ ] Build verified in Max
