# Spec: f_lens

_Last updated: 2026-05-27_
_Status: Draft_

---

## Clarifications

### Session 2026-05-27

- Q: Can a single jit.gl.pix accept three texture inlets (in1, in2, in3) in the Vsynth context? → A: Yes — confirmed by prior knowledge. Multiple texture inlets on jit.gl.pix work in the Vsynth context.
- Q: Tilt blur implementation approach? → A: **jit.fx.cf.tiltshift** — empirically confirmed working inside a Vsynth-context bpatcher. Exposes blur_amount, angle, center, mode (radial/linear), slope, bypass. Supersedes fixed multi-sample codebox approximation (ADR-2 fallback). lens_pix handles aberration/distortion/transmission/modulation; jit.fx.cf.tiltshift handles tilt-shift downstream.
- Q: Is jit.gl.pass viable in a Vsynth bpatcher? → A: No — jit.gl.pass requires jit.world for its GL context setup. Dropping it into a bpatcher that Vsynth already owns produces no output. Not usable.
- Q: Unconnected in2/in3 behavior? → A: Neutral-guard in codebox — remap black in2/in3 to neutral values so unplugged inlets produce no effect regardless of surface_amt/field_amt values. in2 black → dust_mask = 1.0 (fully transparent, no darkening). in3 black → field_mod = 1.0 (uniform field, no spatial variation).

---



A texture processor that simulates the experiential qualities of looking through an imperfect physical lens. Not a physically accurate optical simulation — the goal is **evocativeness**: the filmic register of 20th century cinema, Super-8, and glass-and-silver-halide photography. The imperfections of the medium are expressive material, not errors to correct.

The lens operates entirely in UV space and pixel values. No 3D scene, no light source model, no camera geometry. The incoming texture is simply what's seen through the lens; the bpatcher transforms it.

**Chain position:** Processor — sits between any source and any downstream display layer. Can be placed late in the chain (before f_stereo or output) for a "the whole image is seen through glass" effect, or early for a more subtle texture transformation.

**Acceptance criteria:**
- All params at default → passthrough (lens barely visible)
- `aberration` swept up → RGB channels visibly separate, strongest at edges, minimal at center
- `distortion` swept → barrel (edges bow outward) to pincushion (edges bow inward) warp
- `transmission` swept → vignette deepens toward edges, slight warm color shift in shadow regions
- `tilt` swept with `tilt_axis` at 45° → visible sharp band crossing the frame diagonally, blurring above and below it
- `in2` connected with f_grain → surface character becomes spatially non-uniform; dust/coating variation visible
- `in3` connected with slow noise → distortion field varies organically across frame rather than uniformly
- Bypass passes raw texture unaltered
- Loads in Vsynth, composes cleanly upstream and downstream of other f_ bpatchers

---

## Inlets

**in1** — texture + control (Vsynth convention: control messages always arrive on the first inlet alongside the texture). Standard `routepass jit_gl_texture jit_matrix` handles both — texture passes to pix, control messages route via routepass out2 to the `route` object.

**in2** — surface texture (texture only, optional). Describes the lens as a physical material. Drives spatial variation in dust/coating, transmission character, and inter-reflection intensity. Wants to be fine-grained and relatively static — f_grain is the natural source. Unplugged: neutral-guard ensures no effect at default surface_amt=0.

**in3** — field texture (texture only, optional). Describes how the lens deforms space non-uniformly. Drives local variation in distortion and focus field deviation. Wants to be smoother and potentially animated — slow noise, f_chladni, or LFO-driven sources. Unplugged: neutral-guard ensures no effect at default field_amt=0.

Three inlets total. The in2/in3 split reflects a meaningful distinction: in2 is the lens as a material object, in3 is the lens as a spatial transformer. These are plausibly driven by completely different sources and changed independently in performance.

---

## Parameters

### Radially Symmetric (optical axis)

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `aberration` | 0–1 | 0.0 | Lateral chromatic aberration — RGB channels sampled at progressively offset UVs, scaled by distance from center. 0 = no separation. |
| `distortion` | 0–1 | 0.5 | Lens distortion — 0.5 = none, below = barrel (edges bow out), above = pincushion (edges bow in). |
| `transmission` | 0–1 | 0.0 | Edge transmission falloff — vignette toward edges with slight warm color shift (film base scatter quality). 0 = no falloff. |

### Axially Asymmetric (tilt — via jit.fx.cf.tiltshift)

| Param | Range | Default | jit.fx param | Description |
|-------|-------|---------|--------------|-------------|
| `tilt` | 0–1 | 0.0 | `blur_amount` | Focal plane tilt — amount of tilt-shift blur. 0 = uniform focus. |
| `tilt_axis` | 0–1 | 0.0 | `angle` | Angle of the tilt band across the frame. 0 = horizontal, 0.5 = vertical, wraps. |
| `tilt_pos` | 0–1 | 0.5 | `center` | Position of the sharp band along the tilt axis. 0.5 = center of frame. |
| `mode` | enum | linear | `mode` | Focus shape — linear (band across frame) or radial (focus falloff from center point). |
| `slope` | 0–1 | 0.5 | `slope` | Sharpness of the transition from sharp to blurred. Low = gradual, high = abrupt. |

### in2-Modulated (surface character)

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `surface_amt` | 0–1 | 0.0 | How strongly in2 modulates surface character. 0 = uniform surface. in2 unplugged = no effect regardless of value. |

### in3-Modulated (field character)

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `field_amt` | 0–1 | 0.0 | How strongly in3 modulates the distortion/focus field. 0 = uniform field. in3 unplugged = no effect regardless of value. |

### Standard

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `bypass` | 0/1 | 0 | Standard bypass — raw texture passthrough. |

**Note on UI:** Ten effect parameters plus bypass. Three rows of four dials, two empty slots at end of row 3. Layout: Row 1: aberration, distortion, transmission, tilt. Row 2: tilt_axis, tilt_pos, slope, mode. Row 3: surface_amt, field_amt, [empty], [empty]. `mode` is a live.text enum selector (linear/radial), not a dial — follows f_stereo `circ` pattern. `aberration`, `distortion`, and `tilt` are the most likely primary live controls; remaining params are typically set during rehearsal.

**Note on defaults:** All effect parameters default to 0 (or 0.5 for distortion, which is the neutral point). The lens should be invisible at defaults — it only becomes present as parameters are dialed in. This differs from f_stereo and f_droste which have a distinct look even at defaults.

---

## Codebox Structure (sketch)

**Internal architecture (Phase 0 result):** `jit.gl.pix vsynth @name lens_pix` handles aberration, distortion, transmission, and in2/in3 modulation. `jit.fx.cf.tiltshift` sits downstream of lens_pix and handles all tilt-shift. Tilt params (tilt, tilt_axis, tilt_pos, mode, slope) are routed to jit.fx.cf.tiltshift, not into the codebox.

Three inlets to lens_pix: `in1` (image), `in2` (surface texture), `in3` (field texture).

```
Param aberration(0.0);
Param distortion(0.5);
Param transmission(0.0);
Param surface_amt(0.0);
Param field_amt(0.0);
Param bypass(0.0);

// 1. UV from norm, centered
uv = norm.xy;
cx = uv.x - 0.5;
cy = uv.y - 0.5;
dist = length(vec(cx, cy));

// 2. in3: field texture → distortion field modulation
// Neutral-guard: black in3 (unplugged) → field_mod = 1.0 (no spatial variation)
field = sample(in3, uv).x;
field_mod = mix(1.0, field + (1.0 - field_amt), field_amt);

// 3. Radial distortion (barrel/pincushion)
// distortion=0.5 → no warp; below → barrel, above → pincushion
k = (distortion - 0.5) * 2.0 * field_mod;
r2 = cx*cx + cy*cy;
warp_uv = vec(0.5 + cx * (1.0 + k * r2), 0.5 + cy * (1.0 + k * r2));

// 4. Chromatic aberration: per-channel UV offset from center, scaled by dist
ab = aberration * dist;
r_uv = vec(0.5 + cx * (1.0 + ab), 0.5 + cy * (1.0 + ab));
g_uv = warp_uv;
b_uv = vec(0.5 + cx * (1.0 - ab), 0.5 + cy * (1.0 - ab));
r_val = sample(in1, r_uv).x;
g_val = sample(in1, g_uv).y;
b_val = sample(in1, b_uv).z;
effect_out = vec(r_val, g_val, b_val, 1.0);

// 5. Transmission / vignette with warm color shift
vignette = 1.0 - smoothstep(0.3, 0.7, dist);
warm_shift = vec(1.05, 1.0, 0.92, 1.0);
transmission_out = mix(effect_out, effect_out * warm_shift, (1.0 - vignette) * transmission);

// 6. in2: surface texture → transmission/coating modulation
// Neutral-guard: black in2 (unplugged) → dust_mask = 1.0 (no darkening)
surface = sample(in2, uv);
dust_mask = mix(1.0, surface.x, surface_amt);
surface_out = transmission_out * dust_mask;

// 7. Bypass
out1 = mix(surface_out, sample(in1, norm), bypass);
```

Tilt-shift is not in the codebox — handled entirely by `jit.fx.cf.tiltshift` downstream. The route object dispatches tilt params (tilt → blur_amount, tilt_axis → angle, tilt_pos → center, mode → mode, slope → slope) directly to jit.fx.cf.tiltshift via prepend messages.

---

## Out of Scope (This Version)

**Inter-reflection / ghost images** — cascading attenuated copies of the image offset in a consistent direction. Evocative and worth building, but architecturally distinct (additive superposition, different parameter set). To be specced as `f_interreflect` separately.

**Anamorphic effects** — directional stretch, oval bokeh, horizontal flare characteristic of widescreen cinema lenses. Interesting but a large additional scope; deferred.

---

## Open Questions

- **Distortion and aberration interaction:** The codebox sketch applies distortion first, then aberration on the distorted UVs. Alternative is to apply them independently to the original UV. Visual results differ — to be decided during codebox development.
- **Panel layout:** Eight dials — single row vs two rows. To be determined in build phase.
- **Prefix:** `lens` → `lens_pix`. Confirm no collision with Vsynth objects.
