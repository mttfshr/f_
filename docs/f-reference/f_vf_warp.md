# f_vf_warp

**Type:** Processor (f_vecfield consumer)
**Status:** Complete

---

## What it does

Warps a source texture's UV coordinates using an f_vecfield texture. At each pixel, samples the vector field, remaps the XY vector from [0,1] to [-1,1], scales by `gain`, and displaces the UV before sampling the source texture. `mix_pct` crossfades the composite outlet between the source and the warped result. Output is a standard Vsynth char texture.

Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap.

---

## Signal Flow

```
in0 (texture + control) → routepass → vfwarp_pix in0   [source texture]
in1 (f_vecfield texture, optional) → vs_inState → vfwarp_pix in1

vfwarp_pix (@type char) → out0 (composite: source crossfaded to the warped result by mix_pct)
vfwarp_pix                → out1 (warped layer, unmixed; equals the unwarped source when bypassed)
```

When in1 is unconnected, vs_inState delivers vs_black; `src_vecfield` system param suppresses the offset — output passes through source unwarped.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `gain` | 0–1.5 | 0.0 | Warp depth. 0 = no warp, 1 = ±1 UV offset, up to 1.5 extrapolates further. Renamed from `strength` 2026-10-19 (T052, library gain/mix convention). |
| `mix_pct` | 0–100% | 100.0 | Dry/wet crossfade on the composite outlet (out0): 0 = source, 100 = fully warped. New 2026-10-19; 100 keeps the previous behavior. Rendered as `live.numbox`; internal Param named `mix_pct` to avoid colliding with the codebox's `mix()` operator. The warped-layer outlet (out1) is not mixed. |
| `bypass` | 0/1 | 0 | Passes the unwarped source through on both outlets (drives codebox Param `bypass_gate`, not the native `@bypass`) |

**Prefix:** `vfwarp` — **Object name:** `vfwarp_pix`

---

## Warp Algorithm

```
field_x = sample(vecfield, uv).x   // [0,1]
field_y = sample(vecfield, uv).y

offset_x = (field_x - 0.5) * 2.0 * gain       // [-gain, +gain]
offset_y = (field_y - 0.5) * 2.0 * gain

warped_uv = clamp(uv + offset, 0.0, 1.0)
warped = sample(source, warped_uv)
composite = mix(sample(source, uv), warped, mix_pct / 100.0)   // out0
// out1 = warped; both outlets mix to the source under bypass
```

Edge behavior: pixels displaced outside [0,1] UV clamp to edge — boundary pixels stretch/smear. No wrap or mirror.

---

## Bypass implementation (fixed 2026-09-23)

Earlier this module used the native `jit.gl.pix` `bypass` attribute like every other `f_` module. Native bypass skips the shader and passes outlets 2+ through **vertically flipped**, so the warped-layer outlet could never respect bypass. The toggle now drives a codebox Param (`jsui → prepend param bypass_gate → pix`), so both outlets run through the shader and `mix(warped_sample, sample(in1, uv), bypass_gate)` gates each. Verified on the module bench (`out1` and `out2` == source under bypass). The module builds from `definition.py` and reproduces exactly (`build/drift.py -v f_vf_warp`); it came off the never-regenerate list 2026-10-19.

---

## Notes

- Single-pass, single-sample warp — O(1) per pixel, unconditionally real-time
- `src_vecfield` is a hidden system param driven by vs_inState outlet 1; not user-facing
- At gain=1 the warp spans ±1 UV (full texture width/height) — extreme values produce strong edge smear; typical expressive range is 0.05–0.3
- Works well with animated vortex fields (f_vf_vortex with modulated cx/cy/curl)
- See `docs/f-reference/f_vecfield_type.md` for f_vecfield type contract
