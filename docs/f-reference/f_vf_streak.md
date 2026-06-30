# f_vf_streak

**Type:** Processor (f_vecfield consumer)
**Status:** Complete

---

## What it does

Accumulates source texture samples along vecfield streamlines, producing a directional smear of the source image aligned with the field geometry. Fast-moving regions streak further; slow or zero regions stay relatively sharp. Two outlets: a composite (source + streak layer) and the isolated streak layer for external compositing.

Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap.

---

## Signal Flow

```
in0 (texture + control) → routepass → vfstreak_pix in0   [source texture]
in1 (f_vecfield texture, optional) → vs_inState → vfstreak_pix in1

vfstreak_pix (@type char) out0 → composite (source + streak * strength)
vfstreak_pix (@type char) out1 → streak layer (isolated)
```

When in1 is unconnected, vs_inState delivers vs_black; `src_vecfield` system param suppresses field vectors — step positions collapse to current UV, output passes through source on out0 and black on out1.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `strength` | 0–1 | 0.3 | Wet/dry mix of streak layer into out0. out1 unaffected. |
| `length` | 0–20 | 0.15 | Streamline trace distance in UV space. Controls streak reach. |
| `falloff` | 0–2.5 | 0.0 | 0 = uniform directional blur. 1 = linear trailing smear. >1 = negative tail weights (expressive artifact territory). |
| `color_shift` | 0–20 | 0.0 | Chromatic separation along streak direction. 0 = none. |
| `bypass` | 0/1 | 0 | out0 passes source; out1 goes black. |

**Prefix:** `vfstreak` — **Object name:** `vfstreak_pix`

---

## Algorithm

At each pixel, walks backward along the field streamline for 8 steps, accumulating weighted source texture samples:

```
step_size = length / 8.0
connected = step(0.5, src_vecfield)   // suppress when no field connected

for n in 0..7:
    posN = pos(N-1) - field(N-1) * step_size
    wN = mix(1.0, 1.0 - (n/7.0), falloff)
    srcN.r = sample(source, posN + field * color_shift * step_size).r
    srcN.g = sample(source, posN).g
    srcN.b = sample(source, posN - field * color_shift * step_size).b

streak = weighted_sum(srcN, wN) / sum(wN)

out1 = clamp(source + streak * strength, 0, 1)   // additive composite
out2 = streak                                      // isolated layer
```

Step count is fixed at 8. Field vectors are suppressed by `src_vecfield` when inlet is unconnected.

---

## Notes

- `src_vecfield` is a hidden system param driven by vs_inState outlet 1; not user-facing
- `falloff > 1` extrapolates into negative tail weights — the normalization still holds but produces a contrast-boosted leading edge; expressive at high values
- `color_shift` offsets R and B channels in opposite directions along the field X axis — chromatic aberration follows the streak geometry
- out1 clips at high `strength` with bright sources; this is expected and often desirable
- Typical expressive ranges: `length` 0.1–2.0, `falloff` 0–1.5, `color_shift` 0–3.0; extreme values available for deliberate effect
- Works well chained after f_vf_vortex or f_vf_fieldmap; out1 (streak layer) pairs well with additive compositing in Vsynth
- See `docs/f-reference/f_vecfield_type.md` for f_vecfield type contract
