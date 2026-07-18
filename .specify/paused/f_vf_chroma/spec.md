# f_vf_chroma — spec

_Written: 2026-06-20_

## Concept

Vecfield-driven chromatic aberration. At each pixel, sample the vecfield to get
a direction vector and use it to offset R and B channel samples in opposite
directions, with G held at the unshifted UV. The result is color fringing that
follows field geometry — vortex fields produce spiral fringing, gradient fields
produce directional fringing, convergent fields produce radial fringing.

This is the expressive, field-steered cousin of f_lens's radial aberration.
f_lens aberration is physically grounded (centrifugal, scaled by radius from
center). f_vf_chroma is geometrically driven — the field defines the axis and
direction of channel separation at every point independently.

## Signal Chain

- **in1** — source texture (char)
- **in2** — f_vecfield (float32, RG=XY, 0.5=zero vector); vs_inState gated via `src_vecfield` param
- **out1** — composite (chroma effect blended over source via `strength`)
- **out2** — isolated chroma layer (black on bypass); matches caustic/streak/glow convention

## Core Mechanic

```
uv = norm
field = sample(in2, uv)  →  remap 0–1 to -1–1, suppress when disconnected
dir = field.xy * spread

R = sample(in1, uv + dir).x
G = sample(in1, uv      ).y
B = sample(in1, uv - dir).z
```

Single-sample split. No accumulation loop. Sharp fringing, not blurred.

G stays at uv (unshifted center channel). R and B diverge symmetrically along
the field direction. This matches the optical model: chromatic aberration
separates short and long wavelengths in opposite directions along the aberration
axis.

## Parameters

| Name           | Type     | Range  | Default | Label    | Notes                                       |
|----------------|----------|--------|---------|----------|---------------------------------------------|
| `spread`       | float    | 0–0.1  | 0.0     | Spread   | UV-space separation magnitude per channel; expressive range extends past "correct" |
| `strength`     | float    | 0–1.5  | 0.0     | Strength | Composite blend depth on out1 (additive)    |
| `src_vecfield` | internal | —      | 0.0     | —        | vs_inState gate; suppresses vs_black offset |
| `bypass`       | bypass   | —      | 0.0     | —        | Standard bypass; out2 → black on bypass     |

No mode toggle. No accumulation. Streak mode is a separate concern (f_vf_streak
already covers it, and its color_shift param handles per-step channel offset).

## Silent / Default Behavior

- **No vecfield connected:** `src_vecfield` = 0 → field suppressed → dir = (0,0)
  → R/G/B all sample at uv → out1 = source passthrough, out2 = black. Clean.
- **spread = 0:** dir = (0,0) → same as above. Dial at zero = off.
- **bypass:** out1 = source, out2 = black. Standard.

## Composite Model

out2 (isolated layer) is the raw chroma-split RGB — separated channels only,
no source underneath.

out1 crossfades from source to chroma-split image, scaled by `strength`:
```
out1 = mix(src_px, chroma, strength)
```
At strength=0, out1 = clean source. At strength=1, out1 = full chroma split.
This is a replace model, not additive — the displaced channels are the full image
content shifted, not a light-adding layer on top. Additive was tested and
produced no visible change at low strength values because displaced ≈ source
when in-range. Crossfade is the correct model for this effect.

## Acceptance Criteria

- [ ] f_vf_vortex into in2: fringing spirals around the vortex center
- [ ] f_vf_fieldmap (gradient source) into in2: fringing follows gradient direction
- [ ] No vecfield connected: out1 = clean source, out2 = black
- [ ] spread=0: out1 = clean source regardless of field or strength
- [ ] bypass: out1 = source, out2 = black
- [ ] out2 is a valid isolated layer suitable for downstream compositing

## What This Is Not

- Not a physically-grounded lens simulation (that's f_lens)
- Not a streak/blur effect (that's f_vf_streak with color_shift)
- Not a UV warp (that's f_vf_warp) — image content is not displaced, only the
  channel sampling positions diverge
