# f_vf_glow

**Type:** Processor (f_vecfield consumer)
**Status:** Complete

---

## What it does

Accumulates source texture samples along vecfield streamlines with exponential falloff, producing a directional glow shaped by the field topology. Unlike radially symmetric bloom, the glow is anisotropic — it follows field geometry, producing halos that arc along vortex arms, trail along gradient flows, or spread in any direction the field defines.

Two outlets: a composite (source + glow) and the isolated glow layer for external compositing.

Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap.

---

## Signal Flow

```
in0 (texture + control) → routepass → vfglow_pix in0   [source texture]
in1 (f_vecfield texture) → vs_inState → vfglow_pix in1  [field direction]
in2 (radius mod texture) → vs_inState → vfglow_pix in2  [spatial radius variation]

vfglow_pix (@type char) out0 → composite (source + glow * strength)
vfglow_pix (@type char) out1 → glow layer (isolated)
```

When in1 is unconnected, vs_inState delivers vs_black; raw field value near (0,0) is detected pre-remap and field is suppressed — no glow is produced. When in2 is unconnected, vs_black (0.0) adds nothing to the base radius — clean default.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `radius` | 0–0.2 | 0.01 | UV step size per accumulation step. Controls spatial extent of glow. |
| `falloff` | 0–0.05 | 0.002 | Exponential decay coefficient per step. Higher = tighter glow. |
| `strength` | 0–1 | 0.8 | Wet/dry mix of glow layer into out0. out1 unaffected. |
| `color_mix` | 0–1 | 0.0 | 0 = full-color glow; 1 = luma-only (neutral/white) glow. |
| `direction` | 0–2 | 0 | 0 = bidirectional, 1 = forward only (trail), 2 = backward only (lead). |
| `bypass` | 0/1 | 0 | out0 passes source; out1 goes black. |

**Prefix:** `vfglow` — **Object name:** `vfglow_pix`

---

## Algorithm

At each pixel, walks 48 steps forward and/or backward along the local field direction, accumulating weighted source samples. Step positions are jittered per-pixel per-step to break up banding artifacts.

```
// field remap and vs_black suppression
field_suppress = step(0.02, raw_x + raw_y)   // 0 if vs_black, 1 otherwise
fx = (raw_x - 0.5) * 2.0 * field_suppress
fy = (raw_y - 0.5) * 2.0 * field_suppress

// effective radius with modulation
radius_eff = clamp(radius + mod_val * radius, 0.0, 0.3)
dx = fx * radius_eff
dy = fy * radius_eff

// direction weights (branchless)
fwd_weight = 1.0 - step(1.5, direction)
bwd_weight = 1.0 - step(0.5, direction) + step(1.5, direction)

// 48-step accumulation with jitter
for i in 1..48:
    w = exp(-i * i * falloff)
    jitter = hash(uv, i) * 0.1          // ±0.05 step perturbation
    stepped = i + jitter
    fwd_uv = clamp(uv + field * stepped)
    bwd_uv = clamp(uv - field * stepped)
    accumulate fwd and bwd samples weighted by w * fwd/bwd_weight

glow = accumulated / total_weight
glow_rgb = mix(glow.rgb, luma(glow), color_mix)

out0 = mix(src + glow * strength, src, bypass)
out1 = mix(glow, black, bypass)
```

Step count is fixed at 48. Jitter amplitude is 0.1 steps (±0.05), enough to eliminate banding without visible noise.

---

## Notes

### Field topology determines glow character
The visual result depends entirely on the field source:
- **f_vf_vortex** → arc-shaped halos following rotational streamlines; asymmetric with `direction=1` or `2`
- **f_vf_fieldmap** → tangential edge feathering; glow follows the gradient of the source (tangent to isolines, not radially outward from bright areas)
- **f_vf_vortex_multi** → complex multi-arm halos with superimposed field contributions

This is intentional — f_vf_glow is a field-aligned blur, not a conventional bloom. The field drives the blur direction. For radially-outward bloom, use f_vf_vortex with `curl=0, converge` negative — see Signal chain recipes below.

### vs_black suppression
Raw field texture value is tested before remapping. Values near (0,0) in texture space (vs_black) suppress the field, producing no glow displacement. This correctly handles the unconnected-inlet case. A zero-vector region in a real field is encoded as (0.5, 0.5), which passes through normally and produces zero displacement after remapping — no glow spread, which is also correct.

### Radius and banding
At high `radius` values, step spacing increases and banding can appear on sources with sharp tonal transitions. The 48-step count and jitter handle most cases; if banding persists, lower `radius` or lower `falloff` to distribute weight across more steps.

### Radius modulation (in2)
Modulation is additive and scales with `radius`: `radius_eff = radius + mod * radius`. At full modulation (1.0) the effective radius doubles. Unconnected inlet (vs_black = 0.0) adds nothing — exact no-op.

### Direction modes
- `direction=0` (bidirectional): symmetric halo around source edges along field
- `direction=1` (forward): glow trails in the positive field direction — streaks follow flow
- `direction=2` (backward): glow leads against the field direction — bloom precedes flow

Forward/backward distinction is most visible with f_vf_vortex where the rotational direction is clear.

### Typical expressive ranges
`radius` 0.005–0.05, `falloff` 0.001–0.01, `strength` 0.5–1.0. Extreme `radius` (>0.1) with low `falloff` (<0.001) produces long comet-tail streaks — expressive at high `direction` values with an asymmetric vortex field.

- See `docs/f-reference/f_vecfield_type.md` for f_vecfield type contract

---

## Signal chain recipes

### Conventional radial bloom
f_vf_vortex already spans the full rotational/radial axis via its **Converge** param. At `curl=0, converge` negative, the field is purely radially outward — a divergence source. Feed this into f_vf_glow for bloom that radiates outward from the vortex center rather than arcing tangentially.

Suggested starting point:
- f_vf_vortex: `curl=0, converge=-0.5 to -1.0`, position centered
- f_vf_glow: `direction=0` (bidirectional), `radius=0.02`, `falloff=0.002`

For texture-driven bloom (glow radiates from bright image regions rather than a fixed point), try `f_vf_fieldmap` on a blurred or low-frequency source texture — fieldmap's gradient output points outward from bright regions along luminance isolines, approximating a divergence field driven by image content.

### Comet tails / trailing streaks
- f_vf_vortex: high curl, moderate converge
- f_vf_glow: `direction=1` (forward) or `2` (backward), `radius=0.05–0.15`, `falloff=0.001`

Long asymmetric streaks that arc around the vortex center. The isolated glow outlet (out1) composited additively downstream produces a bright trail without washing out the source.

### Edge feathering
- f_vf_fieldmap on source texture → f_vf_glow
- `direction=0`, low `radius`, moderate `falloff`

Softens edges by spreading them tangentially along the image gradient. Different from a Gaussian blur — the feathering direction follows image structure rather than spreading uniformly.
