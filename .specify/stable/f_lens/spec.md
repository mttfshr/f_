# Spec: f_lens

_Last updated: 2026-07-15 (anamorphic removed from v2 scope, moved to new module)_
_Status: Draft — v1 (aberration/distortion/transmission/tilt) built and working; v2 expansion (ghost, halation) specced below, not yet built_

---

## Clarifications

### Session 2026-07-15 (cont'd, 2) — Anamorphic moved out of f_lens entirely

- Q: Does static anamorphic add anything `distortion`/`distortion_mod` doesn't already cover — e.g. could an angled sine WFG on `distortion_mod` already produce the same effect? → A: **No, not redundant.** `distortion_mod` varies warp *magnitude* spatially, but at any given pixel `k` is one scalar multiplying both `warp_cx` and `warp_cy` identically — always isotropic per-pixel. Anamorphic squeeze is a *constant* per-axis scale ratio applied uniformly everywhere — a structurally different degree of freedom, not a spatial variant of the existing one.
- Q: Given it's non-redundant, does it still belong in `f_lens`? → A: **No** (Matt's call). `f_lens` was judged "already very full of expressive potential," and the field-driven variant specifically needs a vecfield inlet — a signal type nothing else in `f_lens` uses, and a closer structural match to the `f_vf_` consumer family (`f_vf_warp`, `f_vf_streak`) than to `f_lens`'s own radial-optical character.
- Q: Does static-only stay, with just field-driven leaving? → A: **No — both variants leave together.** One future module owns the whole anamorphic concept; static is just that module's `field_amt=0` case, not a separate feature split across two files.
- Where did it go? → `ideas/f_anamorph_unnamed.md` — concept, rough param contract, and the vecfield hemisphere-alignment mechanism (worked out during this same conversation) are preserved there. Not yet named, not yet specced as a real build.

This removes `anamorphic`/`anamorphic_axis`/`anamorphic_field_amt` and the associated new vecfield inlet from `f_lens` v2 scope entirely — see the Anamorphic subsection and its Open Questions further below, kept struck-through for history rather than deleted, per this file's existing convention for superseded content.

### Session 2026-07-15 (cont'd) — Phase 0 decision: T001 vecfield driving-vs-modulation (superseded — see above, anamorphic moved out entirely; kept for history)

- Q: When the new vecfield inlet is connected, does it fully override `anamorphic_axis`, or bias/blend with it? → A: **Bias/blend** (Matt's call). Matches the existing `aberration_mod`/`distortion_mod`/`transmission_mod`/`surface_mod` pattern — a dial always scales the modulation rather than the modulation replacing the base value outright. New dial: **`anamorphic_field_amt`** (0–1, default 0.0). 0 = static `anamorphic_axis` only, unaffected by the vecfield regardless of connection. 1 = axis fully driven by the field. In between = blend. Deliberately named `_field_amt`, not `_mod`, to distinguish "vecfield biases a direction" from the existing `_mod` dials' "scalar texture modulates a scalar effect" — same shape of control, different underlying math, worth keeping visually distinct in the param list so the difference isn't read as arbitrary.

### Session 2026-07-15 — v2 scope: ghost, halation, anamorphic; tilt-shift extraction

- Q: Where does tilt-shift go now that it's an unrelated mechanism sharing a file (see `ideas/f_lens_tiltshift_split.md`)? → A: Extracted to a new module, `f_focus`. `f_lens` loses `tilt`/`tilt_axis`/`tilt_pos`/`mode`/`slope` and the `jit.fx.cf.tiltshift` object entirely. `f_focus` Phase 1 is a near-mechanical port of the existing tilt-shift ADR-1/ADR-2 content from this file. `f_focus` Phase 2 (content-driven focus-map gather-blur, GPU Gems Ch. 28 recipe) is tracked separately in `.specify/f_focus/` and is not blocking Phase 1.
- Q: Are ghost images (inter-reflection) still out of scope, per the original spec's "Out of Scope" section? → A: No longer — promoted into v2 scope. Ghosts share the existing radial `cx`/`cy`/`dist` vector machinery already in `lens_pix` (aberration/distortion both key off the same center-outward vector), so they extend the existing codebox rather than requiring a new stage.
- Q: Is halation still out of scope? → A: No longer — promoted into v2 scope, but as **a mode within `f_lens`**, not a separate module (Matt's explicit call, 2026-07-15) — decided even though halation's mechanism (luma-gated isotropic blur/accumulation, closer to `f_vf_glow`'s idiom than to the radial UV-displacement machinery) doesn't share math with the rest of the codebox. Architecturally this most likely means a second `pix_chain` stage or a multi-pix bpatcher (like `f_vf_advect`), not a single codebox — real open question, see Open Questions below.
- Q: Is anamorphic distortion still deferred? → A: No longer — promoted into v2 scope, and expanded beyond the original "directional stretch" framing. Two variants: **static anamorphic** (fixed axis + squeeze ratio, small addition to existing distortion math, no new inlet) and **field-driven anamorphic** (squeeze direction driven per-pixel by a new vecfield inlet — genuinely new capability, not just a mode). Both are in scope for v2; field-driven is the one requiring new inlet plumbing.
- Q: Does `f_lens` have an existing vecfield inlet, per the README's vecfield-consumer table listing "f_lens field inlet"? → A: **No** — checked directly against `f_lens.maxpat`, confirmed no `vecfield` string anywhere in the file and no field-typed inlet exists. The three existing inlets are in1 (image+control), in2 (surface, scalar), in3 (field, scalar — this is the *scalar* distortion-field texture from the original spec, not a vecfield; unfortunate naming overlap with the new vecfield inlet below, worth a rename pass). The README's table entry is stale/incorrect and should be corrected as a docs cleanup, independent of this build.

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
- `in1` (aberration mod) connected with texture, `aberration_mod` swept → aberration strength becomes spatially non-uniform
- `in2` (distortion mod) connected with slow noise, `distortion_mod` swept → distortion field varies organically across frame rather than uniformly
- `in3` (transmission mod) connected, `transmission_mod` swept → vignette distance varies spatially
- `in4` (surface texture) connected with f_grain, `surface_mod` swept → visible micro-refraction/emboss displacement, not darkening
- Bypass passes raw texture unaltered
- Loads in Vsynth, composes cleanly upstream and downstream of other f_ bpatchers

---

## Inlets (as-built — corrected 2026-07-15, see Clarifications)

Five inlets total, not three. Diverged from the original 3-inlet design during Phase 3/4 build (see `tasks.md` Architecture Note); this section previously still described the old design and has been corrected against the live `f_lens.maxpat` codebox.

**in0** — texture + control (Vsynth convention: control messages always arrive on the first inlet alongside the texture). Feeds `lens_pix in1`.

**in1** — aberration mod texture (texture only, optional). Spatially varies aberration strength via `aberr_tex` sampled from this texture, scaled by the `aberration_mod` dial. Feeds `lens_pix in2`. Neutral-guard: black texture + `aberration_mod`=0 → no spatial variation.

**in2** — distortion mod texture (texture only, optional). Spatially varies distortion `k` via `dist_tex`, scaled by the `distortion_mod` dial. Feeds `lens_pix in3`. Neutral-guard: black + `distortion_mod`=0 → uniform distortion.

**in3** — transmission mod texture (texture only, optional). Spatially varies vignette distance via `trans_tex`, scaled by the `transmission_mod` dial. Feeds `lens_pix in4`. Neutral-guard: black + `transmission_mod`=0 → uniform vignette.

**in4** — surface texture (texture only, optional). Read at three offset UV samples (`surf_c`/`surf_r`/`surf_u`) to compute a local gradient, which nudges `warp_uv` — an emboss/micro-refraction effect, not a darkening multiply as the original spec assumed. Scaled by the `surface_mod` dial. Feeds `lens_pix in5`. Neutral-guard: flat (including black) texture → zero gradient → no displacement regardless of `surface_mod`.

Each of the four mod textures has a dedicated dial controlling how strongly it modulates its target effect — this is a different shape than the original spec's two-texture (`in2`/`in3`) two-dial (`surface_amt`/`field_amt`) design: **each of the three radial effects (aberration, distortion, transmission) gets its own independent spatial-modulation texture and dial**, and surface is a separate fourth, mechanistically different (gradient emboss) input. There is no longer a single "surface" vs. "field" split — that framing from the original spec no longer describes the built module.

---

## Parameters (as-built — corrected 2026-07-16, reflects shipped v2)

### Radially Symmetric (optical axis) — bipolar ranges + range-tier menus, 2026-07-15

| Param | Range | Default | Tiers | Description |
|-------|-------|---------|-------|-------------|
| `aberration` | -1–1 | 0.0 | ±1 / ±2 / ±10 | Lateral chromatic aberration — RGB channels sampled at progressively offset UVs, scaled by distance from center. 0 = no separation. Negative flips lead/lag side. |
| `distortion` | -1–1 | 0.0 | ±1 / ±5 | Lens distortion — 0 = none, negative = barrel (edges bow out), positive = pincushion (edges bow in). |
| `transmission` | -1–1 | 0.0 | ±1 / ±2 | Edge transmission falloff — vignette toward edges with slight warm color shift (film base scatter quality). 0 = no falloff. Negative overshoots into reverse-vignette (brighter edges than center). |

Range-tier menus (small `live.menu` next to each dial) let these
extend well past their default ±1 range for extreme effects — testing
during Phase 1 build found interesting results at the wider ranges,
which is why this shipped as a real feature rather than staying at the
originally-planned unipolar 0–1.

### Axially Asymmetric (tilt — via jit.fx.cf.tiltshift)

| Param | Range | Default | jit.fx param | Description |
|-------|-------|---------|--------------|-------------|
| `tilt` | 0–1 | 0.0 | `blur_amount` | Focal plane tilt — amount of tilt-shift blur. 0 = uniform focus. |
| `tilt_axis` | 0–1 | 0.0 | `angle` | Angle of the tilt band across the frame. 0 = horizontal, 0.5 = vertical, wraps. |
| `tilt_pos` | 0–1 | 0.5 | `center` | Position of the sharp band along the tilt axis. 0.5 = center of frame. |
| `mode` | enum | linear | `mode` | Focus shape — linear (band across frame) or radial (focus falloff from center point). |
| `slope` | 0–1 | 0.5 | `slope` | Sharpness of the transition from sharp to blurred. Low = gradual, high = abrupt. |

### Mod-Texture Modulated (as-built — corrected 2026-07-15)

| Param | Range | Default | Modulates | Description |
|-------|-------|---------|-----------|-------------|
| `aberration_mod` | 0–1 | 0.0 | `in1` texture | Spatial variation strength for aberration. 0 = uniform. `in1` unplugged = no effect regardless of value. |
| `distortion_mod` | 0–1 | 0.0 | `in2` texture | Spatial variation strength for distortion `k`. 0 = uniform. `in2` unplugged = no effect regardless of value. |
| `transmission_mod` | 0–1 | 0.0 | `in3` texture | Spatial variation strength for vignette distance. 0 = uniform. `in3` unplugged = no effect regardless of value. |
| `surface_mod` | 0–1 | 0.0 | `in4` texture | Gradient-emboss displacement strength from `in4`'s local gradient. 0 = no displacement. `in4` unplugged (or flat) = zero gradient = no effect regardless of value. |

### Standard

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `bypass` | 0/1 | 0 | Standard bypass — raw texture passthrough. |

**Note on UI (as-built — corrected 2026-07-15):** Front panel: 8 dials in two rows of four — Row 1: aberration, distortion, transmission, tilt. Row 2: tilt_axis, tilt_pos, slope, mode. Back panel (toggled via `panel_toggle`/`lens_toggle.js`, not always visible): 4 dials in one row — aberration_mod, distortion_mod, transmission_mod, surface_mod. `mode` is a live.text enum selector (linear/radial), not a dial — follows f_stereo `circ` pattern. `aberration`, `distortion`, and `tilt` are the most likely primary live controls; the back-panel mod dials are typically set during rehearsal, which is presumably why they're on a separate toggled panel rather than sharing the front 8.

**Note on defaults:** All effect parameters default to 0 (or 0.5 for distortion, which is the neutral point). The lens should be invisible at defaults — it only becomes present as parameters are dialed in. This differs from f_stereo and f_droste which have a distinct look even at defaults.

---

## Codebox Structure (as-built — corrected 2026-07-15, read directly from `patchers/f_lens.maxpat`)

**Internal architecture:** `jit.gl.pix vsynth @name lens_pix @type char` — **5 inlets, 2 outlets** — handles aberration, distortion, transmission, and all four mod-texture modulations. `jit.fx.cf.tiltshift vsynth` — 1 inlet, 1 outlet — sits downstream and handles all tilt-shift. Tilt params (tilt, tilt_axis, tilt_pos, mode, slope) are routed to `jit.fx.cf.tiltshift`, not into the codebox. (Note: per `.specify/f_lens/plan.md` ADR-6 and `.specify/f_focus/spec.md`, tilt-shift is slated for extraction to a new `f_focus` module — this section documents current as-built state, not the post-extraction target.)

Bpatcher-level in0–in4 map to `lens_pix` in1–in5 respectively (confirmed by `patching_rect` x-position ordering, per the bpatcher-inlet-ordering convention in the `vsynth-bpatcher` skill).

```
Param aberration(0.0);
Param distortion(0.5);
Param transmission(0.0);
Param aberration_mod(0.0);
Param distortion_mod(0.0);
Param transmission_mod(0.0);
Param surface_mod(0.0);
Param bypass(0.0);

// --- UV setup ---
uv = norm;
cx = uv.x - 0.5;
cy = uv.y - 0.5;
dist = length(vec(cx, cy));

// --- Sample mod textures (black = neutral for all) ---
aberr_tex = sample(in2, uv).x;
dist_tex  = sample(in3, uv).x;
trans_tex = sample(in4, uv).x;
eps    = 0.002;
surf_c = sample(in5, uv).x;
surf_r = sample(in5, vec(uv.x + eps, uv.y)).x;
surf_u = sample(in5, vec(uv.x, uv.y + eps)).x;

// --- Distortion (spatially modulated by in3) ---
k = (distortion - 0.5) * 2.0;
k = k * (1.0 + dist_tex * distortion_mod);
r2 = cx*cx + cy*cy;
warp_cx = cx * (1.0 + k*r2);
warp_cy = cy * (1.0 + k*r2);
warp_uv = vec(0.5 + warp_cx, 0.5 + warp_cy);

// --- Surface emboss (nudge warp_uv by in5 gradient) ---
surf_dx = (surf_r - surf_c) * surface_mod;
surf_dy = (surf_u - surf_c) * surface_mod;
warp_uv = vec(warp_uv.x + surf_dx, warp_uv.y + surf_dy);
warp_cx = warp_uv.x - 0.5;
warp_cy = warp_uv.y - 0.5;

// --- Chromatic aberration (spatially modulated by in2) ---
ab = aberration * dist * (1.0 + aberr_tex * aberration_mod);
r_uv = vec(0.5 + warp_cx * (1.0 + ab), 0.5 + warp_cy * (1.0 + ab));
b_uv = vec(0.5 + warp_cx * (1.0 - ab), 0.5 + warp_cy * (1.0 - ab));
r_val = sample(in1, r_uv).x;
g_val = sample(in1, warp_uv).y;
b_val = sample(in1, b_uv).z;
effect_out = vec(r_val, g_val, b_val, 1.0);

// --- Transmission vignette (spatially modulated by in4) ---
dist_v = dist * (1.0 + trans_tex * transmission_mod);
vignette = 1.0 - smoothstep(0.3, 0.7, dist_v);
warm_shift = vec(1.05, 1.0, 0.92, 1.0);
effect_out = mix(effect_out * warm_shift * vignette, effect_out, 1.0 - transmission);

// --- Bypass ---
out1 = mix(effect_out, sample(in1, uv), bypass);
```

Key differences from the original sketch (kept here as a record of what changed, not for future reference — the code above is the source of truth):
- Distortion and aberration are applied **sequentially** — aberration's `warp_cx`/`warp_cy` already include the distortion warp (and the surface-emboss nudge) rather than being computed independently from the original `cx`/`cy`. This resolves the old ADR-4 "deferred" question: sequential was the choice made.
- Transmission's vignette/warm-shift math differs from the original sketch's `mix(effect_out, effect_out*warm_shift, (1-vignette)*transmission)` — the built version is `mix(effect_out*warm_shift*vignette, effect_out, 1.0-transmission)`, and `dist` itself is spatially modulated (`dist_v`) before the vignette calculation, not vignette modulated after.
- Surface is a **gradient-emboss UV nudge** (three-tap finite-difference gradient of `in5`, used to perturb `warp_uv`), not a post-multiply darkening mask as originally sketched.
- No neutral-guard `mix(1.0, ...)` pattern visible in the mod-texture handling — modulation is applied as `base * (1.0 + tex * mod_amount)`, which is neutral by construction when `mod_amount=0` regardless of texture content (a black-safe design without needing an explicit `mix(1.0, ...)` guard). Worth confirming this is intentional and not a place where ADR-3's originally-specified neutral-guard pattern quietly changed shape during the build — functionally it still produces "no effect when mod dial is at 0," which is the property that mattered.

Tilt-shift is not in the codebox — handled entirely by `jit.fx.cf.tiltshift` downstream, matching the original plan.

---

## v2 Scope (2026-07-15) — Ghost, Halation, Anamorphic

Supersedes the "Out of Scope" section below, which is kept for history.
Tilt-shift (`tilt`/`tilt_axis`/`tilt_pos`/`mode`/`slope`, and the
`jit.fx.cf.tiltshift` object) is removed from `f_lens` as part of this
pass — see `.specify/f_focus/spec.md` for its new home.

### Ghost images (inter-reflection) — SHIPPED 2026-07-15, verified in Max

Extends the existing `lens_pix` codebox — uses `warp_cx`/`warp_cy`
(post-distortion/emboss vector, confirmed correct — not plain `cx`/`cy`).
Additive superposition of 1–4 offset taps, each independently sampling
R/G/B at slightly different UVs scaled by `ab` (color-coupled to
`aberration` — real lens ghosts show more color fringing than the
primary image, physically motivated during build discussion). Bipolar
`ghost`/`ghost_spacing`: negative `ghost` subtracts (dark ghosts);
negative `ghost_spacing` mirrors ghosts inward through center rather
than outward (also physically motivated — real lens ghosts often appear
point-mirrored through the optical axis).

| Param | Range | Default | Tiers | Description |
|-------|-------|---------|-------|-------------|
| `ghost` | -1–1 | 0.0 | — | Overall ghost intensity, additive. 0 = no ghosting. Negative = dark ghosts. |
| `ghost_count` | 1–4 (int) | 3 | — | Number of offset taps. `live.numbox`, `floor()` in codebox. |
| `ghost_spacing` | -1–1 | 0.3 | ±1 / ±5 | Offset scale between taps. Negative mirrors ghosts inward. |

### Halation (mode within f_lens) — SHIPPED 2026-07-15, verified in Max

Second `jit.gl.pix` stage in series (`obj-raw-17`, manually-declared
`raw_boxes` object — see `.specify/f_lens/tasks.md` Phase 2 architecture
note for why this used `raw_boxes`/`pix_target` rather than `pix_chain`)
downstream of `lens_pix`, upstream of `jit.fx.cf.tiltshift`: chain order
is `lens_pix → halation → tiltshift → outlet`, chosen because halation
represents a film/sensor-capture-time property and should be blurred
along with everything else by the depth-of-field simulation, not applied
after it. Mechanism: 16 fixed isotropic taps (8 directions × 2 radii,
weighted `w1=1.0`/`w2=0.5` falloff between rings — same weighting shape
as `f_vf_glow`'s radius falloff), each independently re-deriving its own
luma/threshold gate (no intermediate gated buffer is possible within one
codebox pass) — 48 texture samples/pixel total. Confirmed 59-60fps in
Max even at this sample count.

| Param | Range | Default | Description |
|-------|-------|---------|-------------|
| `halation` | 0–1 | 0.0 | Overall halation intensity, additive. 0 = no glow. |
| `halation_threshold` | 0–1 | 0.7 | Luma gate point; regions above this bloom. |

`halation_tint` is **not** a user-facing param — fixed warm/amber
constant in the codebox (`warm_r=1.1, warm_g=1.0, warm_b=0.85`), per
spec's original "likely fixed... unless Matt wants it live" framing; no
explicit ask to make it live surfaced during Phase 0, so it stays fixed.

### ~~Anamorphic (static + field-driven)~~ — REMOVED 2026-07-15, moved to `ideas/f_anamorph_unnamed.md`

Kept here for history only — no longer part of `f_lens` v2 scope. See
Clarifications above for the removal rationale.

~~**Static** — fixed axis + squeeze ratio, extends the existing distortion
math with a per-axis multiplier instead of the current uniform
`(1.0 + k*r2)` radial scale. No new inlet.~~

~~**Field-driven** — new vecfield inlet (bpatcher in5, `lens_pix in6`,
per the corrected inlet numbering above), labeled `"vecfield in"` per
the `vsynth-bpatcher` skill's existing (2026-07-12) convention. Biases
the static axis rather than overriding it (Phase 0 T001 decision).~~

~~| Param | Range | Default | Description |~~
~~|-------|-------|---------|-------------|~~
~~| `anamorphic` | 0–1 | 0.0 | Squeeze amount. 0 = no anamorphic distortion. |~~
~~| `anamorphic_axis` | 0–1 | 0.0 | Static squeeze axis angle. Same wrap convention as the old `tilt_axis`: 0 = horizontal, 0.5 = vertical. |~~
~~| `anamorphic_field_amt` | 0–1 | 0.0 | Vecfield inlet's influence on squeeze direction. 0 = `anamorphic_axis` only, unaffected by the field regardless of connection. 1 = axis fully driven by the field. Inlet unplugged: `anamorphic_field_amt` has no effect at any value (neutral-guard, same shape as the existing `*_mod` params). |~~


---

## Out of Scope (This Version) — superseded 2026-07-15, kept for history

**Inter-reflection / ghost images** — cascading attenuated copies of the image offset in a consistent direction. Evocative and worth building, but architecturally distinct (additive superposition, different parameter set). To be specced as `f_interreflect` separately.

**Anamorphic effects** — directional stretch, oval bokeh, horizontal flare characteristic of widescreen cinema lenses. Interesting but a large additional scope; deferred.

---

## Open Questions

- **Distortion and aberration interaction:** The codebox sketch applies distortion first, then aberration on the distorted UVs. Alternative is to apply them independently to the original UV. Visual results differ — to be decided during codebox development.
- **Panel layout:** Eight dials — single row vs two rows. To be determined in build phase.
- **Prefix:** `lens` → `lens_pix`. Confirm no collision with Vsynth objects.

### v2 open questions — all resolved 2026-07-15 (Phase 0, `.specify/f_lens/tasks.md` T001–T005)

- **Vecfield inlet: driving vs. modulating?** MOOT — anamorphic (both
  variants) removed from `f_lens` v2 scope entirely 2026-07-15, moved to
  `ideas/f_anamorph_unnamed.md`. This decision (bias/blend) still holds
  and is preserved there for whenever that module gets specced.
- **Vecfield inlet labeling convention** — RESOLVED, and now moot for
  `f_lens` specifically (no vecfield inlet remains in this module) —
  still correctly documented in `vsynth-bpatcher/SKILL.md`'s "Vecfield
  labeling for non-f_vf_-prefixed modules" section for whichever future
  module actually adds one.
- **`in3` rename** — RESOLVED as moot: no single "field" texture exists
  in the as-built module to collide with.
- **Halation architecture** — RESOLVED — second `jit.gl.pix` stage in
  series downstream of `lens_pix`, same shape as the existing
  `jit.fx.cf.tiltshift` object. No dedicated architecture scratch test
  needed; precedent already established in this codebase.
- **Ghost tap count vs. performance** — RESOLVED — proceed on
  assumption (`ghost_count` 1–4, default 3), no dedicated profiling
  gate. Matches this library's actual track record of no frame-rate
  hits so far.
- **Panel layout at v2 scale** — RESOLVED — all v2 params go on the
  front panel for now, explicitly provisional pending a separate,
  broader UI density refactor across all module layouts already in
  progress.
