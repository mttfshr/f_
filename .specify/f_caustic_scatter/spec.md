# Spec addendum: f_caustic "sheets" mode (GPU forward scatter)

_Created: 2026-10-06. Rewritten 2026-10-07 as an addendum to `f_caustic` (it began as a separate-module draft)._
_Status: Decisions resolved 2026-10-07; ready for Phase 1 (technical plan, tasks, build). Nothing here is built. The behaviour below was measured in the 2026-10-06 and
2026-10-07 spikes (`tests/spike_scatter.py` stages `s0`-`s11`, `tests/bench/spike_scatter*.maxpat`,
`spike_scatter.jxs`, `scratch/scatter_spike_*`) and recorded in `ideas/optics_map.md` ("Findings: scatter
feasibility spike", "Findings: scatter density, cost and detail"). The seven items that were marked [DECIDE] were resolved on 2026-10-07 (Matt: "go with your recommendations"); see Decisions at the end._

Concept: `ideas/f_lumia.md`, `ideas/optics_map.md`. Existing module: `docs/f-reference/f_caustic.md`,
`src/f_caustic/definition.py`.

**This is not a new module.** `f_caustic` gains a second mode. The gather (soft) path is **untouched**; the sheets
path is added beside it; the inactive branch is disabled; one stage picks the outlets. `f_vf_glass` stays on hold
(any vecfield works: `f_vf_fieldmap`, `f_chladni`, `f_vf_vortex`, ...).

---

## What the sheets mode does

Forward-scatters light through the vecfield. A lattice of points ("glass samples") is displaced to
`u + scale * F(u)` and each deposits a bilinear splat of `weight * source(u)` there, additively, into a float32
capture. Accumulated splat density is illuminance: thin fold lines up to about the first fold and, beyond about
twice that distance, the overlapping translucent folded sheets that the 8-tap gather cannot form at any setting
(measured against photon-counting truth at 3.5 d*: gather r = 0.51, scatter r = 0.994).

**Deliberate deviation from "codebox-first".** The constitution says GLSL lives in `jit.gl.pix` codeboxes. The
scatter's shader is a GLSL 1.20 `.jxs` vertex + fragment pair drawn by `jit.gl.mesh` into a `jit.gl.node` (as
Vsynth's own `vs_xyz_disp` does with `vtfk.jxs`), because a pix codebox is a per-pixel gather and cannot scatter.
Composite, tone map, mode selection and bypass stay in normal pix stages. Record the deviation in the constitution
when the mode ships (wording: Decisions, item 7).

---

## Algorithm (as built in the spike and shown to work)

### Scene (a `jit.gl.node vsynth @capture 1 @type float32`, drawn each frame)

- **Lattice.** `n x n` points from `jit.gl.gridshape @matrixoutput 1 @automatic 0` into
  `jit.gl.mesh @draw_mode points` (multiplicity exactly 1; gridshape's own poly modes emit each vertex about 6
  times). 12 planes, 48 bytes per vertex. Points at `u_i = i/(n-1)`. Regular lattice: jitter was tested and is a
  net loss (grain for moire; r drops 1-13%).
- **Vertex program** (GLSL 1.20, vertex texture fetch on float32 textures):
  ```
  u   = gl_Vertex.xy * 0.5 + 0.5
  F   = (texture2D(field, u).xy - 0.5) * 2;   F.y *= -1           // orientation baked (see below)
  x   = u + scale * F
  col = texture2D(source, u) * weight                              // ONE bilinear read per point
  ppx = x * res
  xs  = floor(ppx + 0.5) / res                                     // corner snap
  gl_Position = (xs * 2 - 1, 0, 1)                                 // straight to clip space: no camera
  ```
- **Fragment program:** tent weight `max(0, 1-|dx|) * max(0, 1-|dy|)` from `gl_FragCoord.xy - ppx` (the
  UNsnapped position), output `col * w`. **`point_size 2`** with the corner snap: a size-2 round point on a pixel
  corner covers exactly the four pixel centres the tent can reach, and the image is bit-identical to `point_size 3`
  (spike S5), at roughly half the fragments.
- **Blend:** additive (`blend_mode 1 1`), `depth_enable 0`, `lighting_enable 0`, node `@erase_color 0 0 0 0`.
- **Weight:** `weight = (capture / n)^2`, so a uniform source of 1 has mean illuminance 1.
- **Texture adapters:** source and field go through `jit.gl.slab @rectangle 0 @type float32` (normalised 2D
  float32, as `vs_xyz_disp` does).
- **Shader simplifications for the module:** the spike shader's experiment uniforms (`h`, `jit`, `latn`, `taps`)
  and the `snap` switch are removed; snap, size 2, a regular lattice and one source read are fixed. `fy` is baked.

**Orientation.** Texture upload and capture each flip vertically, so the field's Y is inverted; `fy = -1`
restores the pix-chain convention (r = 1.0000 against the matrix-space mirror in the bench). **Confirmed live
2026-10-07:** in a real Vsynth chain with a real `f_vf_fieldmap` upstream Matt did not need the flip.

### The `detail` ladder (a setup control)

`detail` is a five-step ladder, not a free resolution. Each step is a capture size and points per capture pixel;
one message sets `capture`, `n`, `weight` (n last, so the lattice is rebuilt once and never at an intermediate
size). Verified by bench stage `s11` (each step identical to the equivalent explicit messages, max|diff| 0).

| `detail` | capture | points / capture px | points | lattice (48 B/vertex) |
|---|---|---|---|---|
| 1 | 256² | 2 | 0.13 M | 6 MB |
| 2 | 512² | 2 | 0.52 M | 25 MB |
| 3 | 768² | 2 | 1.18 M | 57 MB |
| 4 | 1024² | 2 | 2.10 M | 101 MB |
| 5 | 1024² | 4 | 4.19 M | 201 MB |

The capture is a **fixed internal size** (square), independent of the Vsynth render size; the composite stage
upscales it bilinearly to the output. Output resolution therefore changes sharpness, not cost (4K costs the same
as 1080p). Changing `detail` rebuilds the lattice on the CPU, which hitches at the high steps: it is a setup
control, not something to automate during a performance. Matt's default look is step 5; the cheap fallback is
step 2. Matt judged the presets "different, none worse, all useful" (2026-10-07), so the ladder is a creative
control as well as a cost control.

### Measured facts the design depends on

| Fact | Measurement |
|---|---|
| Point footprint | a GL point deposits `pi (size/2)^2` of energy (0.777, 3.126, 7.009 for sizes 1, 2, 3); the tent splat conserves energy; size 2 plus the corner snap equals size 3 exactly |
| Float accumulation | exact, no clamp at 1.0: 4096 points on one pixel sum to 4096.0 |
| Density | at a full-size capture the quality plateau is about 4 points per pixel (r 0.9998 at 3.5 d*); at 1 point per pixel a regular lattice shows a visible moire cross-hatch that Pearson barely registers |
| Coarse capture | quality against a 16 points-per-pixel reference at 1024²: see the S7 table in `optics_map.md` (e.g. 512², 2 per pixel: r 0.998 at 1 d*, 0.958 at 3.5 d*; the loss is resolution, not noise) |
| Source aliasing | small at a lattice about 0.7x the source (r 0.993-0.996 after a box-down); a 4-tap prefilter does nothing; `texture2D` in a vertex program has no mip selection |
| Cost | density-driven (blend contention): at 16.8 M points 1 point per pixel is about 17-22 ms, 16 per pixel 29-69 ms; vertex work about 1 ms per million points; **timings vary up to 2x between runs**. Rough estimate on an M3 Max: step 5 about 5-9 ms (only ever observed to fit the 16.7 ms cap); an M1 is unmeasured (guess: 3-5x slower) |
| Memory | gridshape matrix 12 planes, 48 bytes per vertex |
| Lag | node/mesh/capture is exactly 1 frame behind an upstream pix (8 of 8 captures); **accepted** (the library already has such lags) |
| Dynamic range | peak illuminance about 18x the mean on the test glass |

---

## Parameters

Existing parameters keep their names, ranges and defaults. Added parameters are marked **new**.

| Param | Mode | Description |
|---|---|---|
| `mode` **new** | both | `soft` (the existing gather, default, so existing patches are unchanged) or `sheets`. A live.tab or menu |
| `scale` | both | soft: streamline trace distance (existing). sheets: the propagation distance `d`, UV per unit field. **Decided:** one shared parameter, so switching mode keeps the geometry (range 0-1 covers the `d` values tried, 0.02-0.5) |
| `gain` | both | brightness. sheets: scales the illuminance into the tone curve; an internal constant makes the same slider value comparable across modes (calibrate in Phase 1). **Decided:** one parameter with an internal constant (the alternative, a different default per mode, cannot be expressed by the builder) |
| `mix_pct` | both | dry/wet, unchanged (0-100, default 0) |
| `softness` | soft | unchanged; ignored in sheets mode |
| `color_shift` | soft | unchanged; ignored in sheets mode |
| `detail` **new** | sheets | 1-5, the ladder above. **Decided:** default 5 (Matt's look); an M1 user steps down the ladder |
| `bypass` | both | unchanged: passthrough on every outlet |

Not built (v1): `edge: wrap` (untested), per-channel dispersion, an analytic glass.

## Inlets / Outlets

Unchanged from `f_caustic`: **two inlets, two outlets**. Inlet 0 carries the light-source texture AND the control
messages (`routepass`; `vs_inState` on the texture); inlet 1 is the vecfield (no `vs_inState`: unconnected =
silent). Outlet 0 composite; outlet 1 isolated caustic layer. (An earlier draft of this spec, copied from the stale
`docs/f-reference/f_caustic.md` signal-flow section, said three inlets; the shipped patcher has two.)

**Unconnected vecfield in sheets mode must be silent too** (composite = source, layer = black). An unbound
float32 input reads 0, which decodes to `F = -1` and would throw a displaced copy of the source, so this needs
explicit handling. **Decided:** a guard in the sheets composite stage that treats a field texture
which is exactly 0 at several fixed sample points as absent (real vecfields encode zero as 0.5), and zeroes the
light. Phase 1 verifies how an unconnected pix input actually reads in Vsynth first.

---

## Signal flow

```
inlet 0 (texture + control) ─ routepass ─┬─ route <params> ─ (existing) ─ + mode / detail handling
                                          └─ vs_inState ─┬─ caustic_pix in1 ....... (existing soft path, untouched)
                                                         └─ slab(float32, @rectangle 0) source ─┐
inlet 1 (vecfield, no vs_inState) ───────┬─ caustic_pix in2                                      ├─ scatter scene
                                          └─ slab(float32, @rectangle 0) field ───────────────────┘   (node, mesh, .jxs)
caustic_pix  out1 composite, out2 layer ────────────────────────┐
sheets composite pix (tone map, bilinear upscale to the source's size, mix) ───────────┤
select stages, one per outlet (Param sheets_gate picks soft or sheets; bypass_gate) ─┬─ outlet 0 composite
                                                                                     └─ outlet 1 caustic layer
```

- **Selection in a pix, not by routing.** The select stage picks between the two branches with a `Param`, as the
  library does elsewhere, so no routing object touches a texture message. **Decided** (the alternatives, `gate`s as in `f_texrouter` or the `gswitch` UI objects Matt used in the look patch, were not chosen).
- **The sheets branch is disabled in soft mode** (`@enable 0` on the node, the mesh and the sheets pix). The soft stage is NOT
  disabled in sheets mode: the select stages render on its output, and a disabled stage emits nothing (found on the bench) and the lattice is only built while the mode is `sheets` (rebuilt on `detail`). In soft mode the module
  costs what it costs today plus one select pass.
- **Composite (sheets).** `light` (float32 illuminance, capture-sized) and `src` in; the pix follows the source's
  size (`@adapt 1`, no fixed `@dim`), reads `light` with `sample(in, norm)` (bilinear upscale):
  ```
  exposed = tone(light * gain)                    // see the curve below
  driven  = clamp(src + exposed, 0, 1)            // additive over the source, as the soft path
  out1    = mix(src, driven, mix_pct / 100)                       // composite
  out2    = clamp(exposed, 0, 1)                                  // caustic layer (as the soft path: clamped)
  ```
  Bypass and the soft / sheets pick are NOT here: the two select stages (one per outlet) apply them. Under bypass
  every outlet mixes to the source, the layer outlet too ("every outlet mixes to its passthrough", Matt 2026-10-05;
  the soft codebox does exactly this), in either mode.
  Tone curve as tried in the look patch (Matt's first-look default, never tuned): `t = v / (1 + v)`, `out = t^0.7`.
  **Decided:** keep it; the exponent is not exposed in v1.
- **A non-square output is handled in UV space.** The capture is square and maps the UV square; the composite
  stretches it to the output, so geometry is consistent (the look patch ran a 16:9 output from a square capture).
  The distance `scale` is anisotropic in pixels exactly as in the soft path.
- **The shader** lives in a new `package/code/` folder (Vsynth's precedent: `Vsynth/code/vtfk.jxs`).
  Phase 1 verifies the shader is found from the module bench and from a patch outside the package.
- **Per-instance names.** The scene's node and shader names use `#0` (unique per instance), so several `f_caustic`
  instances can coexist in one patch. (The collision seen between the spike's bench and a live patch was the shared
  `vsynth` render context, not the names.)

---

## Acceptance criteria

Tier decision: tier 1 (NumPy mirror) and tier 2 (module bench) apply; tier 3 for the look.

1. **Soft mode unchanged.** Soft-mode output is identical to the current module (bench against a recorded
   baseline, r = 1.0000), the existing contract, bypass and drift tests pass, and cost in soft mode is within one
   select pass of today's.
2. **Tier 1 (NumPy mirror, offline).** Promote the spike emulation (`ref_scatter`) and the photon-counting truth
   to `tests/`: tent weights sum to 1; energy conserved; identity at `scale = 0`; agreement with truth.
3. **Tier 2 (module bench), sheets mode.** Targets set just below the measured values:
   - identity (`scale = 0`) matches the mirror, relative error <= 1e-3 (measured 0.0000);
   - energy conserved for in-viewport points to within 0.5%; N points on one pixel sum to N within 0.1%;
   - orientation matches the matrix-space mirror, r >= 0.999, with the flip baked;
   - `detail N` is identical to the explicit messages for every step (the `s11` check, promoted);
   - quality against the 16-per-pixel reference (Pearson r at 1 d* / 3.5 d*, from the S7 table): step 5 >= 0.998 / 0.998; step 4 >= 0.995 / 0.995; step 3 >= 0.998 / 0.975 (measured 2026-10-07: 0.9990 / 0.9820, IoU 0.979 / 0.939); step 2 >= 0.995 / 0.95; step 1 >= 0.99 / 0.89;
   - the tone-map and upscale stage matches its NumPy curve (the `s10` check, promoted: r = 1.0000);
   - unconnected vecfield: composite = source, layer black;
   - bypass: passthrough on every outlet; `BYPASS_EXPECT` extended (`tests/test_bench_expect.py` enforces);
   - lag: 1 frame, documented and ACCEPTED (Matt, 2026-10-07); not asserted through the module (task T043 dropped);
   - cost: the default step holds the frame budget on the target machine; headroom measured beyond the cap with a
     better method than the K-meshes multiplier, which failed (run-to-run variation up to 2x: interleave A/B).
4. **Contract and drift:** `tests/test_module_contracts.py`, `tests/bench_modules.py` and `build/drift.py` pass
   (the scene's node, mesh and slab objects are raw boxes and follow the `f_grain` / `f_lens` precedent).
5. **Tier 3 (live).** Matt, on real video in a real chain: the sheets appear, `scale` and `gain` ranges feel right,
   the mode switch and the `detail` hitch are acceptable, two instances coexist. First look (2026-10-07): the
   presets looked different, none worse, all useful.

---

## Out of scope (v1)

- Per-channel dispersion (three draws with different `scale`, or a colour mask); candidate for v2.
- `edge: wrap`; an analytic-glass mode (glass evaluated in the vertex shader, no field texture).
- Multi-bounce, total internal reflection, volumetric light.
- Removing the 1-frame lag (accepted).
- An M1 measurement and a per-machine default (skipped by Matt 2026-10-07; the `detail` ladder is the escape hatch).

---

## Clarifications

### Session 2026-10-06

- Q: Consumer only, or own the glass? -> A: Consumer only; `f_vf_glass` stays a separate producer, on hold (Matt).
- Q: Pursue the sheet regime rather than only a better gather? -> A: Yes (Matt). It becomes a second mode of `f_caustic`.
- Q: How is the GL scene built? -> A: Builder `definition.py` for UI, params, bypass and layout, with the scene in
  `raw_boxes` / `raw_lines` (`f_lens`, `f_grain`, `f_vf_vortex_multi` use them); normal pix stages host the
  composite, the selection and the bypass.

### Session 2026-10-07

- Q: Gather or scatter for the sheets mode? -> A: **Scatter** (Matt: "the numbers strongly suggest the gl method").
  The multi-start gather stays in `tests/` as the fallback.
- Q: The 1-frame lag? -> A: Accepted.
- Q: How is the lattice resolution set? -> A: **A fixed internal capture size** (not a scale relative to the output),
  exposed as the `detail` 1-5 ladder; Matt's default look is a 1024² capture with 4 points per capture pixel (step 5),
  the cheap fallback step 2. Built and verified in the spike (`s11`).
- Q: Which look? -> A: Matt tried the presets in a live chain: they look different, none worse, all useful.
- Q: Orientation? -> A: The flip is baked; Matt did not need the `fy 1` override live.
- Q: M1 / performance machine? -> A: This M3 Max or an M1; the M1 measurement is skipped.
- Settled by the density spikes (`optics_map.md`): regular lattice, corner-snap with `point_size 2`, one bilinear
  source read, a 48-byte lattice is fine at these counts.
- Q: The seven open decisions? -> A: **All as recommended** (Matt: "go with your recommendations"); see Decisions.

---

## Decisions (resolved 2026-10-07; Matt: "go with your recommendations")

1. **`scale` is shared** as the distance in both modes (soft: trace distance; sheets: the propagation distance), so
   switching mode keeps the geometry. Range 0-1, default 0.3 as today.
2. **`gain` is one parameter** (default 0.5 as today); the sheets branch applies an internal constant so the same
   slider value gives comparable brightness (calibrated in Phase 1).
3. **Tone curve:** `t = v / (1 + v)`, `out = t^0.7`, as tried in the look patch. The exponent is not exposed in v1.
4. **`detail` defaults to 5** (Matt's look, 1024² capture, 4 points per capture pixel); a weaker machine steps down
   the ladder (1-5).
5. **Mode selection is a select pix driven by a `Param`**, not routing objects; the inactive branch is disabled.
6. **Unconnected vecfield in sheets mode is silent** (composite = source, layer black) through a guard in the
   sheets composite that treats a field texture reading exactly 0 at several fixed points as absent. Phase 1 first
   verifies how an unconnected pix input reads in Vsynth.
7. **Constitution wording** (apply when the mode ships, through the amend-constitution workflow): the line
   "**Codebox-first** — GLSL logic lives in jit.gl.pix codeboxes; patchers are thin wrappers" gains: "One exception
   class: an effect that needs a many-to-one write (scatter) may draw a `jit.gl.mesh` with a `.jxs` shader into a
   `jit.gl.node`, as Vsynth's own `vs_xyz_disp` does; everything around it (composite, tone map, mode selection,
   bypass) stays in pix codeboxes", and "GLSL in codebox, not inline" gains "(exception: see Codebox-first)".
   Constraint 3 (one bpatcher, one concern) is met: both modes are the same concern, redistributing light through a
   vecfield, and Matt chose a second mode over a separate module.

Phase 1 verification tasks (not decisions): the shader found from a new `package/code/` folder; an unconnected pix
input in Vsynth; the builder accepting the node/mesh/slab scene as `raw_boxes`; cost on the target machine with an
interleaved method.
