# f_vf_glow

**Type:** Processor (f_vecfield consumer)
**Status:** Complete — gain/mix rollout applied 2026-07-12; doc checked line by line against the shipped patcher and codebox 2026-11-06 (stable preflight, offline by Claude)

---

## What it does

Averages source texture samples along the local field direction with Gaussian weights, producing a directional glow shaped by the field topology. Unlike radially symmetric bloom, the glow is anisotropic — it follows field geometry, producing halos that turn with vortex arms, trail along gradient flows, or spread in any direction the field defines. Each pixel reads the field once, at the pixel, and sums along a straight line through it: it does not integrate a curved streamline, so curves come from neighboring pixels' lines turning with the field, and long reaches run straight along the tangent (code read, not run).

There is no brightness threshold: the glow is a blurred copy of the whole source, so adding it brightens the whole frame. `mix_pct` defaults to 0, where the composite equals the source; raise Mix to see the glow on out0. out1 carries the glow at any Mix.

Two outlets: a composite (source + glow) and the isolated glow layer for external compositing.

Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap.

Processor archetype: only the texture on in0 triggers the pix. There is no `vs_inState` on in0 and no `r draw`, so with no source connected the module outputs nothing (wiring read from the patcher; the behavior is inferred, not run). The vecfield goes on in1, not in0.

---

## Signal Flow

```
in0 (texture + control) → routepass jit_gl_texture jit_matrix
  jit_gl_texture → vfglow_pix in0   [source texture; the only trigger]
  unmatched control → route radius falloff gain mix_pct color_mix direction → dials → vfglow_pix
in1 (f_vecfield texture) → vs_inState → vfglow_pix in1  [field direction]
in2 (radius mod texture) → vs_inState → vfglow_pix in2  [spatial radius variation]

bypass jsui → prepend param bypass_gate → vfglow_pix

vfglow_pix (@type char) out0 → composite (source crossfaded by mix_pct toward source + glow * gain)
vfglow_pix (@type char) out1 → glow layer (isolated)
```

When in1 is unconnected, vs_inState delivers vs_black; raw field value near (0,0) is detected pre-remap and the displacement is zeroed, so every accumulation step samples the source pixel itself: with the default `mix_pct` 0 the output equals the source, and with `mix_pct` > 0 it gains a source-brightness boost (`gain` × source) rather than a glow. When in2 is unconnected, vs_black (0.0) adds nothing to the base radius — clean default.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `radius` | 0–0.2 | 0.01 | UV step per accumulation step at field magnitude 1; the step is `field * radius`, so weak field regions spread less. |
| `falloff` | 0–0.05 | 0.002 | Gaussian weight coefficient: step `i` weighs `exp(-i * i * falloff)`. Higher = tighter glow; 0 = all 48 steps equal. |
| `gain` | 0–1.5 | 0.8 | Glow intensity — scales the glow layer's contribution into the driven (fully-composited) state. Renamed from `strength` 2026-07-12 (gain/mix rollout). |
| `mix_pct` | 0–100 | 0 | Mix numbox. Continuous crossfade toward the driven state, off by default: at 0, out0 equals the source. The message is `mix_pct`, not `mix`. |
| `color_mix` | 0–1 | 0.0 | 0 = full-color glow; 1 = luma-only (Rec. 709, neutral/white) glow. |
| `direction` | 0–2 | 0 | 0 = bidirectional, 1 = forward only (trail), 2 = backward only (lead). |
| `bypass` | 0/1 | 0 | Panel toggle only: it drives the codebox Param `bypass_gate`. The route has no `bypass` selector, so a `bypass` message does nothing. out0 and out1 both pass the source (2026-10-05 all-outlets-passthrough rule). The 48-step loop still runs at full cost while bypassed (see Notes). |

**Prefix:** `vfglow` — **Object name:** `vfglow_pix`

---

## Algorithm

At each pixel, takes 48 straight steps forward and/or backward along the field vector read at that pixel, accumulating weighted source samples. Step positions are jittered per-pixel per-step to break up banding artifacts.

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
    jitter = (hash(uv, i) - 0.5) * 0.1  // ±0.05 step perturbation
    stepped = i + jitter
    fwd_uv = clamp(uv + (dx, dy) * stepped)
    bwd_uv = clamp(uv - (dx, dy) * stepped)
    accumulate fwd and bwd samples weighted by w * fwd/bwd_weight

glow = accumulated / total_weight
glow_rgb = mix(glow.rgb, luma(glow), color_mix)

driven = clamp(src + glow * gain, 0, 1)             // gain/mix rollout, 2026-07-12
comp = mix(src, driven, mix_pct / 100)              // mix_pct is the blend toward driven
out0 = mix(comp, src, bypass_gate)                  // alpha is the source's
out1 = mix(glow, src, bypass_gate)                  // glow alpha 1; all-outlets passthrough (2026-10-05)
```

Step count is fixed at 48. Jitter amplitude is 0.1 steps (±0.05), enough to eliminate banding without visible noise.

---

## Notes

### Field topology determines glow character
The visual result depends entirely on the field source:
- **f_vf_vortex** → halos turning around the center with `curl`, radial streaks at its default `curl` 0; asymmetric with `direction=1` or `2`
- **f_vf_fieldmap** → edge feathering; glow follows the gradient of the source (across isolines, uphill toward brighter areas; `rotate` 90 turns it along them)
- **f_vf_vortex_multi** → complex multi-arm halos with superimposed field contributions

This is intentional — f_vf_glow is a field-aligned blur, not a conventional bloom. The field drives the blur direction. For radial bloom, use f_vf_vortex with `curl=0` — see Signal chain recipes below.

### vs_black suppression
Raw field texture value is tested before remapping. Values near (0,0) in texture space (vs_black) zero the displacement, so each accumulation step samples the source pixel itself (no spatial glow spread; see above). This correctly handles the unconnected-inlet case. The test is by value: `vs_inState`'s connection flag is wired to `param src_vecfield`, but the codebox declares no such Param and nothing reads it. A zero-vector region in a real field is encoded as (0.5, 0.5), which passes through normally and produces zero displacement after remapping — no glow spread, which is also correct. There the glow equals the source, so with Mix raised those regions still gain `gain` × source.

### Radius and banding
At high `radius` values, step spacing increases and banding can appear on sources with sharp tonal transitions. The 48-step count and jitter handle most cases; if banding persists, lower `radius` or lower `falloff` to distribute weight across more steps.

### Radius modulation (in2)
Modulation is additive and scales with `radius`: `radius_eff = radius + mod * radius`. At full modulation (1.0) the effective radius doubles. Unconnected inlet (vs_black = 0.0) adds nothing — exact no-op.

### Direction modes
- `direction=0` (bidirectional): symmetric halo around source edges along field
- `direction=1` (forward): each pixel samples ahead along the field, so a bright area's glow lands upstream of it — a trail behind anything moving with the field
- `direction=2` (backward): each pixel samples behind, so the glow lands downstream — bloom ahead of the flow

Forward/backward distinction is most visible with f_vf_vortex where the rotational direction is clear.

### Typical expressive ranges
`radius` 0.005–0.05, `falloff` 0.001–0.01, `gain` 0.5–1.0. Extreme `radius` (>0.1) with low `falloff` (<0.001) produces long comet-tail streaks — expressive at `direction` 1 or 2 with an asymmetric vortex field.

- See `docs/f-reference/f_vecfield_type.md` for f_vecfield type contract
- **2026-10-12 maintenance audit:** this doc was found stale (documented `strength`, pre-rollout bypass behavior); corrected the same day. Cost: the 48-step accumulation loop runs at full cost while bypassed (bypass_gate only mixes the final result — no early-exit guard). Profiled 2026-10-13: 0.0573 ms/pass active, 0.0582 bypassed (512², tasks.md T036a); Matt decided a guard is not worth building now.

---

## Signal chain recipes

### Conventional radial bloom
f_vf_vortex already spans the full rotational/radial axis via its `convergence` param. At `curl=0` the field is purely radial; negative `convergence` points it outward, though at `direction=0` the sign makes no difference. Feed this into f_vf_glow inlet 1 for bloom that radiates from the vortex center rather than turning around it. Raise `mix_pct` to see it on the composite.

Suggested starting point:
- f_vf_vortex: `curl=0, convergence=-0.5 to -1.0`, position centered
- f_vf_glow: `direction=0` (bidirectional), `radius=0.02`, `falloff=0.002`

For texture-driven bloom (glow radiates from bright image regions rather than a fixed point), try `f_vf_fieldmap` on a blurred or low-frequency source texture — fieldmap's gradient output points uphill toward brighter regions, perpendicular to luminance isolines, approximating an image-content-driven field.

### Comet tails / trailing streaks
- f_vf_vortex: high `curl`, moderate `convergence`
- f_vf_glow: `direction=1` (forward) or `2` (backward), `radius=0.05–0.15`, `falloff=0.001`

Long asymmetric streaks around the vortex center, straight along each pixel's tangent at this reach. The isolated glow outlet (out1) composited additively downstream produces a bright trail without washing out the source.

### Edge feathering
- f_vf_fieldmap on source texture → f_vf_glow
- `direction=0`, low `radius`, moderate `falloff`

Softens edges by spreading them across the edge, along the image gradient (`rotate` 90 on f_vf_fieldmap spreads along the edge instead). Different from a Gaussian blur — the feathering direction follows image structure rather than spreading uniformly.

---

## References

The spec and plan name no external source for this technique. Each pixel gathers along a straight line in the local field direction, with Gaussian step weights and per-step jitter. Field type contract: `docs/f-reference/f_vecfield_type.md`.
