# f_mobius — Bpatcher Spec

_Last updated: 2026-07-05_
_Status: Working_

## Concept

A UV-space processor applying a Möbius-family transformation to the sampling coordinates of an incoming texture — the texture itself is unchanged, but where each pixel samples from moves according to the transform. Möbius transformations map circles to circles and preserve angles, so at the blend endpoints the warp stays geometrically coherent (no pinching, no shearing) even at extreme settings.

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

## References

Mobius transformations (`z -> (az + b) / (cz + d)`) are classical complex analysis: they map circles and lines to circles and lines and preserve angles. The four composing transformations (translation, rotation, scale, inversion) and the complex-arithmetic encoding are textbook material; no specific source was consulted.

The blend parameter (`blend` between transform and identity) and the invert-range interaction are this module's own additions. The vecfield-transform question (whether the module could output the transform's Jacobian as a field instead of resampling) was investigated and closed during development: resample is the correct mechanism (`tests/records/spike_mobius_vecfield_transform.py`, 2026-07).

See `docs/f-reference/f_mobius.md` (this file) for the full algorithm and loose threads (invert range, singularity guard).

## Source File

`patchers/f_mobius.maxpat`
