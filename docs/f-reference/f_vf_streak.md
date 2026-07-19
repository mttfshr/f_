# f_vf_streak

**Type:** Processor (f_vecfield consumer)
**Status:** Complete — gain/mix rollout applied 2026-07-12 (see Notes)

---

## What it does

Accumulates source texture samples along vecfield streamlines, producing a directional smear of the source image aligned with the field geometry. Fast-moving regions streak further; slow or zero regions stay relatively sharp. Two outlets: a composite (source + streak layer) and the isolated streak layer for external compositing.

Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap.

---

## Signal Flow

```
in0 (texture + control) → routepass → vfstreak_pix in0   [source texture]
in1 (f_vecfield texture, optional) → vs_inState → vfstreak_pix in1

vfstreak_pix (@type char) out0 → composite (driven state = source + streak*gain, crossfaded by mix_pct)
vfstreak_pix (@type char) out1 → streak layer (isolated)
```

When in1 is unconnected, vs_inState delivers vs_black; `src_vecfield` system param suppresses field vectors — step positions collapse to current UV, output passes through source on out0 and black on out1.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `gain` | 0–1.5 | 0.3 | Streak intensity — scales the streak layer's contribution into the driven (fully-composited) state. Renamed from `strength` 2026-07-12 (gain/mix rollout). |
| `mix_pct` | 0–100% | 0.0 | Wet/dry crossfade toward the driven state — a continuous blend, not spatial masking. Rendered as `live.numbox`; internal Param named `mix_pct` to avoid colliding with the codebox's `mix()` operator. Default 0 (off by default, matching this module's original load behavior). |
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

driven = source + streak * gain                    // fully-composited state
composite = mix(source, driven, mix_pct / 100)      // wet/dry crossfade

out1 = mix(composite, source, bypass)
out2 = mix(streak, black, bypass)
```

Step count is fixed at 8. Field vectors are suppressed by `src_vecfield` when inlet is unconnected.

---

## Notes

- **2026-07-12 gain/mix rollout:** `strength` renamed to `gain`; `mix_pct` added (0–100% crossfade toward the driven/fully-composited state, default 0 — off by default, matching this module's original load behavior). Composite rewritten to the two-stage driven/mix pattern confirmed correct on `f_vf_prism`: `mix_pct` is a continuous blend toward the driven state, not spatial masking.
- `src_vecfield` is a hidden system param driven by vs_inState outlet 1; not user-facing
- `falloff > 1` extrapolates into negative tail weights — the normalization still holds but produces a contrast-boosted leading edge; expressive at high values
- `color_shift` offsets R and B channels in opposite directions along the field X axis — chromatic aberration follows the streak geometry
- out1 clips at high `gain`/`mix_pct` with bright sources; this is expected and often desirable
- Typical expressive ranges: `length` 0.1–2.0, `falloff` 0–1.5, `color_shift` 0–3.0; extreme values available for deliberate effect
- Works well chained after f_vf_vortex or f_vf_fieldmap; out1 (streak layer) pairs well with additive compositing in Vsynth
- See `docs/f-reference/f_vecfield_type.md` for f_vecfield type contract
