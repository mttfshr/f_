# Implementation Plan: f_lens

_Date: 2026-05-27_
_Spec: .specify/f_lens/spec.md_

---

## Summary

f_lens is a three-inlet texture processor simulating the experiential qualities of an imperfect physical lens. The core work is a jit.gl.pix codebox implementing four effect families (chromatic aberration, barrel/pincushion distortion, transmission vignette, and tilt-shift blur) modulated by two optional control textures. The plan phases codebox development as a sequence of independently verifiable effects, followed by a Python build script generating the patcher wrapper.

The critical early question — whether jit.gl.pix supports three texture inlets in the Vsynth context — is the first thing verified. Everything else depends on this.

---

## Technical Context

**Environment:** Max 9, Vsynth package  
**Shader:** `jit.gl.pix vsynth @name lens_pix` with gen codebox  
**Inlets:** in1 (image), in2 (surface texture), in3 (field texture) — three texture inlets, needs Phase 0 verification  
**Build:** Python script generating `.maxpat` JSON (same pattern as f_grain, f_stereo)  
**JS:** `bypass_toggle.js` already exists in `code/` — no new JS needed  
**Output:** `patchers/f_lens.maxpat`

**Constraints from constitution:**
- Vsynth owns render tempo — no qmetro, no jit.pwindow
- Codebox before patcher — all GLSL verified working before build script runs
- One bpatcher, one concern — inter-reflection and anamorphic explicitly out of scope

---

## Constitution Check

✅ **Vsynth compatibility** — standard routepass pattern; three inlets are the one structural unknown, addressed in Phase 0 before anything else is built  
✅ **Codebox before patcher** — Phases 0–3 are pure codebox work; build script runs only in Phase 4  
✅ **One bpatcher, one concern** — inter-reflection and anamorphic deferred to separate patches  
✅ **Specs before building** — spec and plan complete before Max is opened  
✅ **Tasks.md as session anchor** — tasks.md generated from this plan  

---

## Architecture Decisions

### ADR-1: Internal pix architecture

**Context:** f_lens has three texture inlets at the bpatcher level, but the internal arrangement of jit.gl.pix objects is a separate question. A single pix with three texture inlets is one option; a pipeline of smaller pix objects composited inside the bpatcher is another. Vsynth owns the render context — multiple pix objects inside one bpatcher all draw to the same `vsynth` context and are composited in order.

**Decision:** Defer to Phase 0. Build two minimal scratch arrangements and compare:
- **Option A:** Single pix, three inlets — one codebox handles all effects
- **Option B:** Pipeline of pix objects — e.g. pix_main (in1 → aberration/distortion/transmission/tilt), pix_surface (+ in2 → dust/coating), pix_field (+ in3 → spatial variation)

Choose based on which is easier to reason about, debug, and extend. Option B is likely cleaner — each pix has a single concern and its own small codebox.

**Consequences:**
- Option A: Simpler patcher wiring; one codebox may become large and hard to debug
- Option B: More pix objects; each codebox is smaller and independently testable; closer to the "one concern per object" principle

---

### ADR-2: Tilt blur via fixed multi-sample

**Context:** True per-pixel tilt-shift blur requires convolution — many samples per output pixel. A ping-pong pass would enable separable blur but adds architectural complexity.

**Decision:** Approximate with 4–8 fixed samples per pixel along the blur direction, weighted by distance from the focal band. Physically inaccurate but reads convincingly as tilt-shift. Single render pass, no ping-pong.

**Sample strategy:** Sample in1 at N evenly spaced offsets perpendicular to the tilt axis, scaled by `blur_amt`. Average the results. Exact N and step size determined experimentally during Phase 2.

**Consequences:**
- Positive: Stays within single jit.gl.pix, no additional objects or passes
- Negative: Not physically accurate; banding may be visible at extreme blur_amt values. Revisit if quality becomes important.

---

### ADR-3: Neutral-guard for unconnected inlets

**Context:** jit.gl.pix likely delivers a black texture (all zeros) on an unconnected inlet. Black in2 would zero out the dust_mask, darkening the image; black in3 would set field_mod to 0, which could collapse distortion unexpectedly.

**Decision:** Neutral-guard in codebox — remap black in2/in3 to neutral values:
- in2: `dust_mask = mix(1.0, surface.x, surface_amt)` — black in2 + surface_amt=0 → dust_mask=1.0 (no effect). With surface_amt > 0 and black in2, darkening will occur — document as user responsibility to only raise surface_amt when in2 is connected.
- in3: `field_mod = mix(1.0, field, field_amt)` — black in3 + field_amt=0 → field_mod=1.0 (uniform). Safe at default.

**Verify:** Confirm actual unconnected inlet behavior in Phase 0.

---

### ADR-4: Effect ordering in codebox

**Context:** Distortion and aberration can be applied sequentially (aberration on distorted UVs) or independently (both applied to original UV). Sequential produces more extreme interactions at high values; independent is more predictable.

**Decision:** Deferred to Phase 1/2 codebox development. Build both, compare results visually, decide which reads better. Document the chosen approach in spec Clarifications after Phase 1.

---

### ADR-5: Inlet structure

**Context:** Vsynth convention: control messages always arrive on the first inlet alongside the texture. The routepass on in1 handles both — texture passes to pix, control messages route via routepass out2 to the `route` object. Additional texture inlets (in2, in3) are texture-only.

**Decision:** Three inlets total:
- **in1** — texture + control (standard routepass pattern; routepass out2 → route)
- **in2** — texture only (surface); `routepass jit_gl_texture jit_matrix` → pix in2
- **in3** — texture only (field); `routepass jit_gl_texture jit_matrix` → pix in3

**Consequences:**
- Positive: Consistent with all existing f_ bpatchers; control convention unchanged
- Neutral: in2 and in3 are texture-only — no parameter messages arrive there, which is correct

---

## Dependency Blocks

### Block 0: Feasibility
**Dependencies:** None  
**Builds:** Confidence that three-inlet jit.gl.pix works in Vsynth  
**Verification:** Minimal three-inlet pix loads in Vsynth, passes textures from all three inlets visibly, no GL errors

### Block 1: Radially symmetric effects
**Dependencies:** Block 0 (confirmed three-inlet architecture)  
**Builds:** Aberration, distortion, transmission — the core lens character  
**Verification:** Each effect visually distinct at swept values; passthrough at defaults

### Block 2: Tilt-shift
**Dependencies:** Block 1 (codebox structure established)  
**Builds:** Tilt blur with multi-sample, tilt_axis and tilt_pos params  
**Verification:** Sharp band visible across frame; blur increases away from band; tilt_axis rotates band angle; tilt_pos moves band position

### Block 3: in2/in3 modulation
**Dependencies:** Block 1 (base effects in place to modulate)  
**Builds:** surface_amt, field_amt with neutral-guards; in2/in3 spatial variation of effects  
**Verification:** With f_grain as in2: spatially non-uniform dust/coating visible. With slow noise as in3: distortion field varies organically. Unplugged inlets: no effect at default amt values.

### Block 4: Patcher wrapper
**Dependencies:** Blocks 1–3 (confirmed working codebox)  
**Builds:** Python build script → f_lens.maxpat with all objects, wiring, UI  
**Verification:** Patch loads in Max without errors; all params reach pix

### Block 5: Vsynth integration
**Dependencies:** Block 4 (working patch)  
**Builds:** Verified performance in Vsynth context; composition with other f_ bpatchers  
**Verification:** Loads in Vsynth; composes upstream and downstream of f_stereo, f_grain, f_droste; no GL context errors

---

## Implementation Phases

### Phase 0: Feasibility — Internal architecture and available objects

Build minimal scratch patches in `~/Vsynth/patterns/` (not in repo) to determine the right internal arrangement of objects inside the bpatcher.

**Architecture options to explore:**
- **Single jit.gl.pix, three inlets** — one codebox handles all effects
- **Pipeline of pix objects** — e.g. lens_main_pix (in1), lens_surface_pix (+ in2), lens_field_pix (+ in3); each with its own small codebox
- **Mixed objects** — e.g. jit.gl.pass for blur/glow effects, jit.gl.pix for UV displacement, jit.fx for compositing; all rendering to vsynth context

**Key constraint:** f_lens orchestrates everything internally and renders to the vsynth context. Whatever objects are used internally, they must draw to or pass through `vsynth` and the final output must flow out of the bpatcher outlet as a standard texture. Vsynth owns render tempo — no `qmetro` or context setup inside the bpatcher.

**Objects worth testing for vsynth compatibility:**
- `jit.gl.pass` — multi-pass rendering; natural fit for separable blur (tilt-shift) and halation/bloom. Better quality ceiling than unrolled codebox samples.
- `jit.fx` — post-processing effects; may have relevant blur or glow shaders
- `jit.gl.pix` — UV displacement (aberration, distortion); codebox is the right tool here
- Any combination of the above, composited inside the bpatcher

**What to verify:**
- Which objects render correctly to the vsynth context without requiring their own GL setup
- Whether jit.gl.pass is viable inside a bpatcher that Vsynth owns
- Unconnected inlet behavior (black/white/undefined) — update ADR-3
- Chosen pix/object scripting names don't collide with Vsynth objects

Document findings and chosen architecture in ADR-1 before proceeding.

**Checkpoint:** Internal architecture decided. Available objects catalogued. Vsynth compatibility confirmed. → Proceed to Phase 1.

---

### Phase 1: Radially symmetric effects

Implement aberration, distortion, and transmission using whatever objects Phase 0 identified as appropriate (likely jit.gl.pix codebox for UV displacement effects; possibly jit.gl.pass or jit.fx for transmission/bloom).

**Step 1a — Distortion alone:**
```
k = (distortion - 0.5) * 2.0;
r2 = cx*cx + cy*cy;
warp_uv = vec(0.5 + cx*(1.0+k*r2), 0.5 + cy*(1.0+k*r2));
effect_out = sample(in1, warp_uv);
```
Verify: distortion=0.5 → passthrough; below → barrel; above → pincushion

**Step 1b — Add aberration:**
Decide effect ordering (ADR-4): apply aberration to warp_uv (sequential) or to original uv (independent). Compare visually, document decision.
```
ab = aberration * dist;
r_val = sample(in1, r_uv).x;
g_val = sample(in1, g_uv).y;
b_val = sample(in1, b_uv).z;
effect_out = vec(r_val, g_val, b_val, 1.0);
```
Verify: RGB channels separate at edges; minimal at center; no separation at aberration=0

**Step 1c — Add transmission:**
```
vignette = 1.0 - smoothstep(0.3, 0.7, dist);
warm_shift = vec(1.05, 1.0, 0.92, 1.0);
effect_out = mix(effect_out, effect_out * warm_shift, (1.0-vignette) * transmission);
```
Verify: transmission=0 → no change; transmission=1 → warm darkened edges

**Step 1d — Add neutral-guards and bypass**

---

### Phase 2: Tilt-shift

Implement tilt-shift blur using the best available approach identified in Phase 0. If `jit.gl.pass` is vsynth-compatible, use a separable blur pass for quality. If not, use 4–8 fixed samples in a jit.gl.pix codebox (per ADR-2).

```
tilt_angle = tilt_axis * PI;
perp_x = -sin(tilt_angle);
perp_y =  cos(tilt_angle);
tilt_dist = abs(perp_x*cx + perp_y*cy - (tilt_pos-0.5));
blur_amt = tilt_dist * tilt * 4.0;

// N samples along blur direction
step = blur_amt / N;
blurred = vec(0,0,0,0);
for i in 0..N:
    offset = (i - N/2) * step
    blurred += sample(in1, uv + vec(perp_x, perp_y)*offset)
blurred /= N;
effect_out = mix(effect_out, blurred, clamp(blur_amt, 0, 1));
```

Determine N and step experimentally. Start with N=6. Check for banding at extreme values.

Verify: tilt=0 → no blur; tilt=1 → visible sharp band; tilt_axis rotates band; tilt_pos moves band

---

### Phase 3: in2/in3 modulation

Implement surface_amt and field_amt modulation using whatever architecture Phase 0 established. If a pipeline of pix objects is used, in2 and in3 feed directly into their dedicated pix; if single pix, in2/in3 are read as texture inputs with neutral-guards.

```
// in3 → field modulation
field = sample(in3, uv).x;
field_mod = mix(1.0, field, field_amt);
// apply field_mod to distortion k

// in2 → surface/dust
surface = sample(in2, uv).x;
dust_mask = mix(1.0, surface, surface_amt);
// multiply final output by dust_mask
```

Test with f_grain → in2, slow noise → in3. Verify spatial variation is visible and convincing.

---

### Phase 4: Python build script → f_lens.maxpat

With the codebox confirmed, write Python build script at `~/Vsynth/patterns/build_f_lens.py`.

**Objects needed:**
- 3 inlets (in1 texture+control, in2 texture, in3 texture)
- 3× `routepass jit_gl_texture jit_matrix` (one per texture inlet; in1's routepass out2 → route)
- `jit.gl.pix vsynth @name lens_pix`
- `route bypass aberration distortion transmission tilt tilt_axis tilt_pos surface_amt field_amt`
- `bypass_toggle.js` jsui + `prepend param bypass`
- 8× `live.dial` + `prepend param <name>` for each effect param
- `autopattr @varname lens_autopattr`
- Title comment + background panel
- `moduleSize.js` chain
- `parameters` block

**UI layout:** Two rows of four dials. Row 1: aberration, distortion, transmission, tilt. Row 2: tilt_axis, tilt_pos, surface_amt, field_amt. Bypass toggle top-right. Consistent with existing multi-row bpatchers (f_grain: 2×6, f_channel_grader: 3×4).

---

### Phase 5: Vsynth integration and composition

Load `f_lens.maxpat` in Vsynth context. Test signal chains:

- `vs_noise_3 → f_lens → output` — verify basic operation with all params
- `f_grain → f_lens → f_stereo → output` — verify composition in both directions
- `f_grain → in2, slow_noise → in3` — verify surface and field modulation in a real chain
- Verify autopattr state save/restore
- Verify moduleSize.js chain
- Verify bypass

---

### Phase 6: Documentation

- `docs/f_lens.md` — as-built reference (params, signal chain, inlet descriptions, known behaviors)
- Update `README.md` — add f_lens to patches table as ✅ Working
- Update build queue
- HANDOFF as usual

---

## Complexity Notes

**Three inlets** are the primary structural novelty. All existing f_ bpatchers use one texture inlet. The build script will need careful handling of inlet/outlet counts and routepass wiring. Phase 0 de-risks this before any other work is done.

**Tilt multi-sample** is the most computationally expensive effect — N texture samples per pixel. At N=6 this is still well within GPU budget for a 1080p Vsynth context, but worth profiling if frame rate drops.

**Eight params** fits comfortably in two rows of four, consistent with existing f_ bpatchers (f_grain: 2×6, f_channel_grader: 3×4).
