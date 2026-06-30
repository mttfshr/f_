# f_vf_warp

**Type:** Processor (f_vecfield consumer)
**Status:** Complete

---

## What it does

Warps a source texture's UV coordinates using an f_vecfield texture. At each pixel, samples the vector field, remaps the XY vector from [0,1] to [-1,1], scales by `strength`, and displaces the UV before sampling the source texture. Output is a standard Vsynth char texture.

Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap.

---

## Signal Flow

```
in0 (texture + control) → routepass → vfwarp_pix in0   [source texture]
in1 (f_vecfield texture, optional) → vs_inState → vfwarp_pix in1

vfwarp_pix (@type char) → out0
```

When in1 is unconnected, vs_inState delivers vs_black; `src_vecfield` system param suppresses the offset — output passes through source unwarped.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `strength` | 0–1 | 0.1 | Warp depth. 0 = no warp, 1 = ±1 UV offset |
| `bypass` | 0/1 | 0 | Passes source texture through unmodified |

**Prefix:** `vfwarp` — **Object name:** `vfwarp_pix`

---

## Warp Algorithm

```
field_x = sample(vecfield, uv).x   // [0,1]
field_y = sample(vecfield, uv).y

offset_x = (field_x - 0.5) * 2.0 * strength   // [-strength, +strength]
offset_y = (field_y - 0.5) * 2.0 * strength

warped_uv = clamp(uv + offset, 0.0, 1.0)
output = sample(source, warped_uv)
```

Edge behavior: pixels displaced outside [0,1] UV clamp to edge — boundary pixels stretch/smear. No wrap or mirror.

---

## Notes

- Single-pass, single-sample warp — O(1) per pixel, unconditionally real-time
- `src_vecfield` is a hidden system param driven by vs_inState outlet 1; not user-facing
- At strength=1 the warp spans ±1 UV (full texture width/height) — extreme values produce strong edge smear; typical expressive range is 0.05–0.3
- Works well with animated vortex fields (f_vf_vortex with modulated cx/cy/curl)
- See `docs/f-reference/f_vecfield_type.md` for f_vecfield type contract
