# Spec: f_caustic_scatter (working name)

_Created: 2026-10-06_
_Status: Draft — Phase 0 spikes and decisions pending (see Open Questions). Nothing here is built; the
behaviour below was measured in the 2026-10-06 spike (`tests/spike_scatter.py`, `tests/bench/spike_scatter.*`,
`scratch/scatter_spike_*.log`) and recorded in `ideas/optics_map.md`, "Findings: scatter feasibility spike"._

Concept: `ideas/f_lumia.md`, `ideas/optics_map.md`. Producer for its field: `.specify/f_vf_glass/`.

**Working name.** `f_caustic` (the gather) stays. This module is its forward-scatter counterpart. "f_lumia"
is the look (the umbrella idea, a preset or demo patch), not this module's name. Rename before build if
something better turns up.

---

## What it does

Forward-scatters light through a vecfield. A lattice of points ("glass samples") is displaced to
`u + d * F(u)` by the vecfield and each point deposits a bilinear splat of `weight * source(u)` there with
additive blending into a float32 capture. Accumulated splat density is illuminance: thin bright fold lines up
to about the first fold, and, beyond about twice that distance, the overlapping translucent folded sheets
that a gather (`f_caustic`) cannot form at any setting (measured: gather r = 0.51 against photon-counting
truth at 3.5 d*, scatter r = 0.994).

**Consumer in the f_vecfield family.** Vecfield in, source in, light out. Not a producer: the glass is
`f_vf_glass` (or any vecfield: `f_vf_fieldmap`, `f_chladni`, ...).

**Deliberate deviation from "codebox-first".** The constitution says GLSL lives in `jit.gl.pix` codeboxes.
The scatter's shader is a GLSL 1.20 `.jxs` vertex+fragment pair drawn by `jit.gl.mesh` into a
`jit.gl.node` (as Vsynth's own `vs_xyz_disp` does with `vtfk.jxs`), because a pix codebox is a
per-pixel gather and cannot scatter. Everything else (composite, tone map, bypass) stays in a normal pix
stage. The deviation is recorded here and should be recorded in the constitution when the module ships.

---

## Algorithm

### Scene (in a `jit.gl.node vsynth @capture 1 @type float32`, drawn each frame)

- **Lattice.** `n × n` points from `jit.gl.gridshape @matrixoutput 1 @automatic 0` into
  `jit.gl.mesh @draw_mode points`. (Measured: gridshape's own `@poly_mode 2 2` emits each vertex about 6
  times; `@draw_mode` is not valid on gridshape. The matrix into a points mesh gives multiplicity exactly 1.)
  Points are at `u_i = i/(n-1)`.
- **Vertex program** (GLSL 1.20, vertex texture fetch on float32 textures):
  ```
  u   = gl_Vertex.xy * 0.5 + 0.5
  F   = (texture2D(field, u).xy - 0.5) * 2;   F.y *= fy
  x   = u + d * F
  col = texture2D(source, u) * weight
  ppx = x * res
  gl_Position = (x * 2 - 1, 0, 1)             // straight to clip space; no camera
  ```
- **Fragment program:** tent weight `max(0, 1-|dx|) * max(0, 1-|dy|)` from `gl_FragCoord.xy - ppx`; output
  `col * w`. Draw with `point_size 3` (round footprint of radius 1.5 covers every pixel centre within ±1 px).
- **Blend:** additive (`blend_mode 1 1`), `depth_enable 0`, `lighting_enable 0`, node `@erase_color 0 0 0 0`.
- **Weight:** `weight = (R / n)²`, so a uniform source of 1 gives mean illuminance 1 for points that stay
  inside the viewport.
- **Texture adapters:** incoming source and field go through `jit.gl.slab @rectangle 0 @type float32`
  (normalised 2D float32, as `vs_xyz_disp` does; `@type float32` is set explicitly).

### Measured facts the design depends on

| Fact | Measurement |
|---|---|
| Orientation | texture upload and capture readback each flip vertically (net upright), so the field's Y is inverted; `fy = -1` restores the pix-chain convention (r = 1.0000 against the matrix-space mirror) |
| Point footprint | a GL point deposits `π (size/2)²` of energy (0.777, 3.126, 7.009 for sizes 1, 2, 3); a size-1 point aliases against the lattice and loses about 21%. The tent splat conserves energy |
| Float accumulation | exact, no clamp at 1.0: 4096 points on one pixel sum to 4096.0 |
| Density | quality plateau by about 4 points per pixel (r 0.9985 at 1 d*, 0.9937 at 3.5 d*) |
| Cost | realistic glass at 3.5 d* held the 60 fps cap up to 6.55 M points into a 1024² capture (headroom unknown: the cap hides it); worst case, all points on one pixel, about 88 ns per point |
| Memory | gridshape matrix is 12 planes, 48 bytes per vertex (about 200 MB at 2048²) |
| Lag | node/mesh/capture path is exactly 1 frame behind an upstream pix (8 of 8 captures); pix → pix lags 0 |
| Dynamic range | peak illuminance about 18× the mean on the test glass |

### Composite (a normal pix stage, builder-made)

`light` (float32 illuminance) in, source in:
```
exposed = tonemap(light * gain)                  // curve is an open question; out1 keeps raw float
driven  = clamp(src + exposed, 0, 1)             // additive over the source, as f_caustic / f_vf_streak
out0    = mix(mix(src, driven, mix_pct / 100), src, bypass_gate)     // composite
out1    = mix(light, src, bypass_gate)                               // isolated light layer
```
This stage hosts `Param bypass_gate`, so the builder's `bypass_mode: "param"` applies.

---

## Inlets

| Inlet | Type | Label | Required | Description |
|---|---|---|---|---|
| 0 | texture + control | texture | Yes | source (gobo / light); control messages |
| 1 | f_vecfield texture | vecfield | No | the glass field (float32, RG = XY, 0.5 = zero) |

Unconnected vecfield: output the source unchanged (suppress via `src_vecfield`, as `f_vf_warp` does).
Unconnected source: output black.

## Outlets

| Outlet | Type | Comment | Description |
|---|---|---|---|
| 0 | texture | composite | source + tone-mapped light, `mix` |
| 1 | texture (float32) | light | isolated illuminance layer |

## Parameters (proposed; ranges and defaults to be set in Phase 0/1)

| Param | Type | Description |
|---|---|---|
| `distance` | float | propagation distance `d`, UV per unit field. The thin-line regime is up to about `d*`, sheets beyond about 2 `d*`, where `d* = 1 / (most negative Hessian eigenvalue)` of the field (`optics_map.md`). Units to be revisited with `f_vf_glass` normalisation |
| `gain` | float | exposure into the tone map |
| `mix` | numbox 0–100 | dry/wet, canonical naming (default 0 per the 2026-07-12 convention) |
| `detail` | discrete | points per pixel (e.g. 1, 2, 4, 8). Sets lattice size `n` from the capture size; changing it rebuilds the lattice matrix, so it is not a continuous control |
| `resolution` | discrete | capture size relative to the Vsynth render size (cost is points × fragments, not pixels) |
| `edge` | choice | `clip` (points leaving the viewport are lost; measured) or `wrap` (re-enter opposite side; not yet tested) |
| `bypass` | toggle | passthrough on every outlet |

`fy` is not a user control: it is baked in (`-1`).

---

## Signal Flow

```
in0: source + control ─ routepass ─ slab(float32, @rectangle 0) ──────────────┐
in1: vecfield (vs_inState) ─────── slab(float32, @rectangle 0) ──────────────┤
        scatter scene (raw_boxes): gridshape matrix → mesh points (+ .jxs) → float32 node
                                                                              │
        composite pix (builder-made; bypass_gate, mix, tone map)
                                   ├ out0 composite
                                   └ out1 light
```

---

## Acceptance Criteria

Tier decision is Phase 0, task 1: tier 1 applies (non-trivial math with a known reference); tier 2 applies
through the **module bench**, not the codebox bench (a `.jxs` shader is not a pix codebox); tier 3 for the look.

1. **Tier 1 (NumPy mirror, offline).** Promote the spike emulation (`ref_scatter`) and the photon-counting
   truth to `tests/`: tent weights sum to 1; energy conserved; identity at `d = 0`; agreement with truth.
2. **Tier 2 (module bench).** Targets set just below the measured values:
   - identity (`d = 0`) matches the mirror, relative error ≤ 1e-3 (measured 0.0000);
   - energy conserved for in-viewport points to within 0.5% (measured within 0.1%);
   - N points on one pixel sum to N within 0.1% (measured exact);
   - truth agreement at ≥ 4 points per pixel: r ≥ 0.99 at 0.6 and 1.0 d*, r ≥ 0.98 at 3.5 d*
     (measured 0.9985 / 0.9937 at 4 per pixel, 1 d* / 3.5 d*);
   - orientation: matches the matrix-space mirror, r ≥ 0.999, with `fy` baked in;
   - bypass: passthrough on every outlet; `BYPASS_EXPECT` extended (`tests/test_bench_expect.py` enforces);
   - lag: 1 frame documented, or removed if the `@layer` spike succeeds, and asserted either way;
   - cost: default `detail` / `resolution` hold the frame budget; headroom measured beyond the cap
     (open: how, since the bench paces at 60 fps).
3. **Contract and drift:** `tests/test_module_contracts.py`, `tests/bench_modules.py` and `build/drift.py`
   pass (the contract tests assume pix stages with Param wiring; the node/mesh/slab objects are raw and
   `pix_wire: False` controls follow the `f_grain` precedent; confirm in Phase 0).
4. **Tier 3 (scratch patch).** Fed by `f_vf_glass` through a real chain in a real Vsynth patch: the sheets
   appear, `distance` and `gain` ranges feel right, the tone curve reads well on stage.

---

## Out of Scope (v1)

- Per-channel dispersion (three draws with different `d`, or a colour mask); candidate for v2.
- An analytic-glass mode (glass evaluated in the vertex shader, no field texture).
- Multi-bounce, total internal reflection, volumetric light.
- Anything that needs scatter without GL (not possible in a pix codebox).

---

## Clarifications

### Session 2026-10-06

- Q: Consumer only, or own the glass? → A: Consumer only; the glass is a separate `f_vf_glass` producer
  (Matt), so one glass can feed warp, prism, caustic and this module together.
- Q: Pursue the sheet-regime scatter module rather than only a better gather? → A: Yes (Matt).
- Q: How is the GL scene built? → A: Builder `definition.py` for UI, params, bypass and layout, with the
  scene in `raw_boxes` / `raw_lines` (`f_lens`, `f_grain`, `f_vf_vortex_multi` use them); a normal pix
  stage after the node hosts the bypass. (Proposed; Phase 0 confirms the contract tests accept it.)

### Session 2026-10-07

- Q: Gather or scatter for the sheets mode? -> A: **Scatter** (Matt: "the numbers strongly suggest the gl method").
  The gather stays in `tests/` as the fallback.
- Q: The 1-frame lag? -> A: Accepted (the library already has them elsewhere); Phase 0 spike 1 is closed.
- Q: How is the lattice resolution set? -> A: **MVP: a fixed internal capture size** (Matt's default look: a 1024^2
  capture, 4 points per capture pixel, so about 4.2 M points; the 512^2 / 2-point preset, about 1 M points, is the cheap fallback), upscaled bilinearly to the output, not a scale relative to the
  output. Output resolution then changes sharpness, not cost. The exact size, and non-square captures, are chosen in Phase 1.
- Settled by the density spikes (`ideas/optics_map.md`, "Findings: scatter density, cost and detail"): regular
  lattice (jitter is a net loss), corner-snap with `point_size 2` (bit-identical to size 3), one bilinear source read
  (a 4-tap prefilter does not help), and a 48-byte lattice is fine at these counts (Phase 0 spike 2 is not needed for the MVP).

---

## Open Questions

**Superseded in part (2026-10-06, later):** Matt wants the sheet regime as a **second mode of `f_caustic`**, not
a separate module, and `f_vf_glass` is on hold. This draft still describes a separate scatter module and must be
rewritten as an addendum to `f_caustic` (add, don't modify: the soft path stays untouched; a selector picks the
output; the inactive branch should be disabled). The **method** for the sheets mode is open: scatter (this
spec; best quality; GL scene, 1-frame lag, lattice memory) or a **multi-start gather** (an ordinary pix
codebox; r 0.94–0.95 at 2–3.5 d* with 16–36 starts and 2x2 samples per pixel, missing 3–5% of the light and
sharing less of the bright lines than scatter, at about 5,800 texture reads per pixel; see `ideas/optics_map.md`,
"Findings: multi-guess gather"). Decide after measuring the gather's real cost in Max and its accuracy when
reading field textures instead of the analytic field.

**Update 2026-10-07:** the method is decided (scatter, fixed internal capture size; see Clarifications). Of the five spikes below, 1 (lag) is closed (accepted), 2 (lattice memory) is not needed at MVP counts, 4 (source aliasing) and 5 (headroom) are answered for a square capture (`ideas/optics_map.md`); **3 (real integration, render-size adaptation, non-square) is still open**, and the cost numbers need a re-measure with a better method (run-to-run variation was up to 2x).

Phase 0 spikes, each small and bench-attributable:

1. **Lag.** Does a different `@layer` ordering of the node remove the 1-frame lag? If not, accept and document.
2. **Lattice memory.** Can a 3-plane (12-byte) lattice, built another way, replace the 48-byte gridshape matrix?
3. **Real integration.** Behaviour with a real `f_vf_fieldmap` / `f_vf_glass` upstream, in a real Vsynth patch,
   and adapting the node to Vsynth's render size (the spike used a fixed `@adapt 0 @dim`).
4. **Source aliasing.** The source is sampled once per lattice point, so a detailed gobo aliases on a coarse
   lattice. Is `texture2DLod` with mipmaps, or a prefilter pass, needed? Highest risk to image quality.
5. **Headroom.** The bench's 60 fps pacing hides the real margin; find the point where it breaks (larger
   lattice or capture) to size `detail` / `resolution` defaults.

Decisions:

- **Tone map and HDR policy:** which curve, and whether out2 stays raw float (peaks about 18× the mean).
- **`edge: wrap`:** worth building? Untested; needs `fract` in the vertex program and agrees with the
  periodic test glass.
- **Shader file location:** `.jxs` must be on Max's search path; Vsynth keeps its own in its package `code/`.
  Where f_ puts it is unchecked.
- **Name:** `f_caustic_scatter` is a placeholder.
- **Constitution wording:** how to record the codebox-first deviation.
