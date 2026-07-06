# f_mobius — Bpatcher Spec

_Last updated: 2026-07-05_
_Status: Working_

## Concept

A UV-space processor applying a Möbius-family transformation to the sampling coordinates of an incoming texture — the texture itself is unchanged, but where each pixel samples from moves according to the transform. Möbius transformations map circles to circles and preserve angles, so the warp stays geometrically coherent (no pinching, no shearing) even at extreme settings.

Two paths blend via `invert`: a rotation+zoom path (identity at defaults) and a complex-inversion path (`1/z`). At `invert=0` the effect is pure rotation/zoom; at `invert=1`, full inversion (center and edges trade places); the 0.2–0.8 range produces loxodromic (hyperbolic spiral) motion — the primary expressive territory.

## Parameters

| Name | Type | Range | Default | Description |
|------|------|-------|---------|-------------|
| `cx` | float | 0.0–1.0 | 0.5 | Transform center X |
| `cy` | float | 0.0–1.0 | 0.5 | Transform center Y |
| `rotate` | float | 0.0–1.0 | 0.0 | Rotation — full sweep = one revolution (mapped to 0–2π) |
| `zoom` | float | 0.0–1.0 | 0.5 | Zoom — 0.5 = identity, logarithmic scale (`10^((zoom-0.5)*5)`) |
| `invert` | float | 0.0–10.0 | 0.0 | Blend from rotation/zoom (0) toward complex inversion 1/z (1); values beyond 1 extrapolate |
| `bypass` | bypass | 0/1 | 0 | Standard bypass — raw texture passthrough |

## Signal Chain

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix

routepass out0 (texture) → mobius_pix in0
routepass unmatched → route cx cy rotate zoom invert bypass → live.dials → prepend param <name> → mobius_pix in0

mobius_pix out0 → out0
```

## Algorithm

```
zx, zy = norm - (cx, cy)                          // center on transform origin
scale = 10^((zoom - 0.5) * 5)                      // logarithmic zoom
rot_x/rot_y = rotate zx,zy by (rotate * 2π), scaled by `scale`

mag_sq = max(zx² + zy², 0.0001)
inv_x, inv_y = zx/mag_sq, -zy/mag_sq               // complex inversion 1/z

out_x = mix(rot_x, inv_x, invert)
out_y = mix(rot_y, inv_y, invert)

uv = fract((out_x, out_y) + (cx, cy))              // wrap back into [0,1]
effect_out = sample(in1, uv)
out1 = mix(effect_out, sample(in1, norm), bypass)
```

Edge wrapping uses `fract` (tiling), not mirroring — differs from the mirror-edge-guard approach described in `.specify/f_mobius/spec.md`'s original sketch.

## Loose Threads

- `invert` range in `definition.py` is 0.0–10.0 (spec.md describes it as a 0–1 blend) — values above 1 push past pure inversion into extrapolated territory; expressive but unverified against spec's stated acceptance criteria.
- Loxodromic sweet-spot exploration (spec.md's "budget an exploration session") not confirmed as complete.
- Singularity guard is a fixed `max(mag_sq, 0.0001)` floor — no explicit NaN/inf check beyond that.

## Source File

`patchers/f_mobius.maxpat`
