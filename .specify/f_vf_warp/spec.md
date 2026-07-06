# Spec: f_vf_warp

_Created: 2026-06-07_
_Revised: 2026-06-07_
_Status: Revised — architecture clarified_

---

## What it does

A vecfield-based UV warp processor for Vsynth. Takes a source texture and a vector field (as a float32 RG f_vecfield texture), and displaces each pixel's UV coordinates based on the XY vector sampled from the field at that location. The resulting warped texture is output.

**Consumer in the f_vecfield family.** Expects a valid f_vecfield texture in the vecfield inlet. Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, etc.

**Pure Processor archetype.** Requires an upstream source texture on in0. The vecfield inlet is optional — if unconnected, output passes through unwarped. Bypass passes the source texture through unmodified.

---

## Warp Algorithm

At each pixel:

1. Sample the vecfield texture at the current UV coordinates
2. Remap the XY vector from [0, 1] to [-1, 1] (f_vecfield convention: 0.5 = zero vector)
3. Scale by `strength` parameter
4. Add the scaled offset to the current UV
5. Sample the source texture at the displaced UV (clamp to edge)
6. Output the result

Codebox pseudocode:

```glsl
Param strength(0.1);
Param src_vecfield(0.0);   // system param: 0 = no field connected, 1 = connected
Param bypass(0.0);

vec2 uv = norm;
vec2 field = sample(in2, uv).rg;
vec2 raw_offset = (field - 0.5) * 2.0 * strength;

// When no vecfield is connected, in2 delivers vs_black (all zeros),
// which would produce a constant offset of -strength. We suppress this
// via src_vecfield state: offset is zeroed when inlet is unconnected.
vec2 offset = mix(vec(0.0, 0.0), raw_offset, step(0.5, src_vecfield));

vec2 warpedUV = clamp(uv + offset, 0.0, 1.0);
vec4 warped = sample(in1, warpedUV);
warped.a = 1.0;

out1 = mix(warped, sample(in1, uv), bypass);
```

**Strength:** At `strength = 1.0`, the full dynamic range of the field maps to ±1 UV offset. Useful range is typically 0.0–0.3 in practice; full range kept for expressive headroom.

**Edge behavior:** UV coordinates are clamped to [0,1], giving a stretched/smeared appearance at boundaries. No wrap or mirror modes in v1.

**`src_vecfield` state param:** Hidden system parameter driven by `vs_inState` outlet 1 on the vecfield inlet. Not user-facing — absent from route, UI, and parameters block.

---

## Inlets

| Inlet | Type | Label | Required | Description |
|---|---|---|---|---|
| 0 | texture + control | texture | Yes | Source texture to warp; control messages |
| 1 | f_vecfield texture | vecfield | No | Deformation field (float32, RG=XY, 0.5=zero) |

When in1 is unconnected: `vs_inState` delivers `vs_black` to pix in2, and `src_vecfield` is set to 0 — suppressing the offset. Output matches input.

When in0 is unconnected: pix receives no texture, output is black.

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `strength` | live.dial | 0.0–1.0 | 0.1 | Warp depth. 0 = no warp, 1 = ±1 UV offset. |
| `bypass` | bypass_toggle.js | 0/1 | 0 | Passes source texture through unmodified. |

Hidden system params (not in UI, route, or parameters block):

| Param | Source | Notes |
|---|---|---|
| `src_vecfield` | vs_inState out1 on in1 | 0 = no field connected, 1 = connected |

**Prefix:** `vfwarp`
**Object name:** `vfwarp_pix`
**Output type:** `@type char`

---

## Signal Flow

```
in0 (texture + control) → routepass jit_gl_texture jit_matrix
  jit_gl_texture branch → vfwarp_pix in0      [source texture, direct — no vs_inState]
  unmatched → route strength → live.dial → attrui (strength) → vfwarp_pix in0

in1 (vecfield texture) → vs_inState in0
  vs_inState out0 (texture or vs_black) → vfwarp_pix in1   [gen in2]
  vs_inState out1 (0/1) → prepend param src_vecfield → vfwarp_pix in0

bypass_toggle.js → attrui (bypass) → vfwarp_pix in0

vfwarp_pix out0 → out0 (warped texture, @type char)
```

**Gen subpatcher inlets:**
- `in 1` → source texture (from routepass texture branch)
- `in 2` → vecfield texture or vs_black (from vs_inState out0)
- Codebox `numinlets`: 2

---

## Acceptance Criteria

- **Basic warp:** Connect a source texture to in0 and `f_vf_vortex` to in1. The source should appear warped around the vortex center.
- **Strength control:** Increasing `strength` from 0 to 1 scales distortion smoothly from none to ±1 UV offset.
- **Edge behavior:** Pixels displaced outside texture bounds smear/stretch the edge pixels — no wrap or mirror.
- **No vecfield connected:** With in1 unconnected, output matches the source texture exactly.
- **No source connected:** With in0 unconnected, output is black.
- **Bypass:** With bypass enabled, output exactly matches source texture regardless of vecfield or strength.
- **Accepts any f_vf_ producer:** Works with f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap without artifacts.
- **Resolution independence:** Warp is consistent regardless of source and vecfield texture resolutions.
- **Loads in Vsynth.** Survives a save/load cycle in a Vsynth patch without crashing.

---

## Out of Scope

- Wrap/mirror edge modes — clamp to edge sufficient for v1
- Vecfield passthrough outlet — single outlet design
- Separate X/Y strength controls — single `strength` param sufficient
- Multi-step streamline tracing (flow warp) — v1 is single-sample only
- Strength modulation via texture inlet — v1 keeps param surface minimal

---

## Open Questions

- **Strength upper bound:** Range 0–1 maps to ±1 UV offset. May be insufficient for very small-scale fields (e.g. tight vortex with low divergence). Revisit after testing — could extend to 0–2 if needed.
