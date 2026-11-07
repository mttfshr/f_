# f_vf_warp

**Type:** Processor (f_vecfield consumer)
**Status:** Complete

---

## What it does

Warps a source texture's UV coordinates using an f_vecfield texture. At each pixel, samples the vector field, remaps the XY vector from [0,1] to [-1,1], scales by `gain`, and displaces the UV before sampling the source texture. `mix_pct` crossfades the composite outlet between the source and the warped result. Output is a standard Vsynth char texture.

It is one offset read per pixel: nothing follows a streamline and nothing accumulates between frames. For those, use `f_vf_streak` and `f_vf_advect`. It is the plainest way to see what a field does.

**Direction:** the pixel reads the source at its own position plus the offset, so content appears to move against the field vector, not along it. A sink field (vectors pointing at a center) swells the center outward; a repulsion field closes the surroundings in on what repels (worked from the codebox, not run).

Takes any f_vecfield on inlet 1: `f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_fieldmap`, `f_vf_flow`, `f_vf_fluid`, `f_tf_axisflow` and the rest. `f_tf_tensormap` outlet 1 is not one (see `f_tensor_type.md`).

---

## Signal Flow

```
in0 (texture + control) → routepass → vfwarp_pix in0   [source texture; the render trigger]
                           routepass unmatched → route gain mix_pct → dial / numbox → attrui → vfwarp_pix in0
in1 (f_vecfield texture, optional) → vs_inState out0 → vfwarp_pix in1
                                     vs_inState out1 → prepend param src_vecfield → vfwarp_pix in0
bypass toggle (jsui) → prepend param bypass_gate → vfwarp_pix in0

vfwarp_pix (@type char) → out0 (composite: source crossfaded to the warped result by mix_pct)
vfwarp_pix                → out1 (warped layer, unmixed; equals the unwarped source when bypassed)
```

**Render trigger:** only a texture on inlet 0 triggers the pix. There is no `r draw` here, and the `vs_inState` is on the vecfield inlet only, so with nothing on inlet 0 there is no output, and a vecfield alone draws nothing (wiring read, not run).

**Vecfield inlet unconnected:** `src_vecfield` stays or drops to 0 and the offset is suppressed, so the output is the unwarped source. The suppression is needed because `vs_black` is all zeros, which decodes to (-1, -1), not to zero. `vs_inState` senses a connection by timing, not by the cord: it goes to 0 and sends `vs_black` when no texture has arrived for its `vs_noConnectionTimer` threshold, so a field that stalls reads as unconnected (`vs_inState.maxpat` read, not run).

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `gain` | 0–1.5 | 0.0 | Warp depth. 0 = no warp, 1 = ±1 UV offset, up to 1.5 extrapolates further. Renamed from `strength` 2026-10-19 (T052, library gain/mix convention). |
| `mix_pct` | 0–100% | 100.0 | Dry/wet crossfade on the composite outlet (out0): 0 = source, 100 = fully warped. New 2026-10-19; 100 keeps the previous behavior. Rendered as `live.numbox`; internal Param named `mix_pct` to avoid colliding with the codebox's `mix()` operator. The warped-layer outlet (out1) is not mixed. |
| `bypass` | 0/1 | 0 | Toggle only (the route has no `bypass` selector, so a `bypass 1` message does nothing). Passes the unwarped source through on both outlets (drives codebox Param `bypass_gate`, not the native `@bypass`) |

**Prefix:** `vfwarp` — **Object name:** `vfwarp_pix`

---

## Warp Algorithm

```
field_x = sample(vecfield, uv).x   // [0,1]
field_y = sample(vecfield, uv).y

offset_x = (field_x - 0.5) * 2.0 * gain       // [-gain, +gain]
offset_y = (field_y - 0.5) * 2.0 * gain
// both offsets are zeroed when src_vecfield is 0 (inlet 1 unconnected)

warped_uv = clamp(uv + offset, 0.001, 0.999)
warped = sample(source, warped_uv)
composite = mix(sample(source, uv), warped, mix_pct / 100.0)   // out0
// out1 = warped; both outlets mix to the source under bypass
```

Edge behavior: pixels displaced outside [0,1] UV clamp to edge — boundary pixels stretch/smear. No wrap or mirror. The clamp bounds are 0.001 / 0.999, not 0 / 1 (2026-10-20): on the GPU a coordinate of exactly x = 1.0 or y = 0.0 sits on the wrap seam and reads the opposite edge (probe P9), so a clamp to exact 0 / 1 smeared the far side of the frame in from the right and low-y edges. The clamp runs at every gain, so even at `gain` 0 the outermost 0.1% of the frame on each side repeats the texel at the bound (about 2 px at 1920 wide; worked from the codebox, not run). Bypass and `mix_pct` 0 read the source at the plain UV and do not have this.

---

## Bypass implementation (fixed 2026-09-23)

Earlier this module used the native `jit.gl.pix` `bypass` attribute like every other `f_` module. Native bypass skips the shader and passes outlets 2+ through **vertically flipped**, so the warped-layer outlet could never respect bypass. The toggle now drives a codebox Param (`jsui → prepend param bypass_gate → pix`), so both outlets run through the shader and each mixes to the unwarped source by `bypass_gate`: `mix(composite, src_sample, bypass_gate)` on the first, `mix(warped_sample, src_sample, bypass_gate)` on the second. Verified on the module bench: the contract bench's `BYPASS_EXPECT` (which counts outlets from 1, as the codebox does) has both equal to the source under bypass (`bench_modules.py` 2/2, `tests/logs/20261106-081412-bench.log`). The module builds from `definition.py` and reproduces exactly (`build/drift.py -v f_vf_warp`); it came off the never-regenerate list 2026-10-19.

---

## Notes

- Single-pass, single-sample warp — O(1) per pixel, unconditionally real-time
- `src_vecfield` is a hidden system param driven by vs_inState outlet 1; not user-facing
- At gain=1 the warp spans ±1 UV (full texture width/height) — extreme values produce strong edge smear; typical expressive range is 0.05–0.3
- Works well with animated vortex fields (f_vf_vortex with modulated cx/cy/curl)
- See `docs/f-reference/f_vecfield_type.md` for f_vecfield type contract
- The mechanism (sample field, remap, scale, add to UV, sample source) is the refraction technique of Sousa, "Generic Refraction Simulation", *GPU Gems 2*, Ch. 19, arrived at independently. The chapter's refraction mask is not implemented here: the offset applies across the whole frame (`ideas/gpu_gems_research.md`)
- Tests: no tier-1 mirror (skip decided by Matt, T051, `.specify/f_vf_warp/tasks.md`) and no `bench_*` file of its own; the contract bench's bypass entry and `tests/build/test_build_multistage.py` cover it
