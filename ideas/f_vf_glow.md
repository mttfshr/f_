# f_vf_glow

_Status: Idea — not yet specced. Last updated: 2026-06-09._

## Concept

Flow-aligned directional glow. At each pixel, walks backward along the field streamline for N steps accumulating source luminance, then uses that accumulated value as a brightness multiplier on the current pixel's color. The field geometry appears as a directional halo around bright source regions — convergence zones glow, laminar regions stay dark.

Visually distinct from f_vf_streak: source content stays spatially grounded — no displacement, no overlay artifact — just a directional brightness halo that follows the field. Natural companion to f_caustic: caustic highlights convergence zones geometrically; glow highlights them via source luminance.

## Algorithm sketch

```
for n in 0..7:
    posN = walk backward along streamline N steps
    lumaN = luma(sample(source, posN))
    wN = falloff weight at step n

glow_weight = weighted_sum(lumaN, wN) / sum(wN)
out = source_px * (1.0 + glow_weight * strength)
```

## Parameters (sketch)

- `strength` — glow intensity multiplier
- `length` — streamline trace distance (same meaning as f_vf_streak)
- `falloff` — weight distribution along path
- `color_shift` — optional chromatic separation along glow direction

## Outlets

- out0: composite (source + glow layer)
- out1: isolated glow layer

## Notes

- Single-pass, stateless — no feedback required
- 8-step unroll; same budget as f_caustic and f_vf_streak
- `build_streak.py` is the direct template for the build script
