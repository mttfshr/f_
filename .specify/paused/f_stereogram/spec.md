# Spec: f_stereogram

_Created: 2026-06-30_
_Status: Draft — implementation blocked, see Shader Architecture_

---

## What it does

A single-image autostereogram (SIRDS-style) generator/processor. Takes a depth
texture and a pattern texture and produces a field in which a 3D shape resolves
when viewed with relaxed/crossed eyes — the classic "stereogram" effect, applied
live to animated/video-synthesis sources rather than a static print.

**Not a stereo pair.** Output is a single field encoding depth via strip-based
pattern feedback, not two side-by-side images for direct visual comparison.

**Processor archetype, two required inlets, no internal pattern fallback.**
in1 is the depth/shape texture (scalar, read from luma). in2 is the pattern
texture (the repeating visual content carrying the illusion). Both must be
connected for meaningful output.

---

## Background — why this exists

Existing crude prototype (`/Users/matt/Vsynth/magic-eye.maxpat`) chains two
general-purpose `vs_displacement` stages (x-only param driven). Problems:

1. **Per-pixel warping** — traced to depth-map smoothness (not displacement
   DOF; x-only was already correctly isolated).
2. **Repeating pattern visibly tiling and running off-frame** — traced to
   fixed global period; real SIRDS encodes depth in strip-to-strip feedback,
   not in a shifted fixed-period tile.

**Motivating context:** animated/real-time SIRDS is extremely rare. A
working real-time implementation in a video synthesis context would have
essentially no precedent. This drives every architectural decision — real-time
correctness is the primary constraint, not perceptual perfection.

---

## Algorithm Reference

**GPU Gems Chapter 41 — "Real-Time Stereograms" (Fabio Policarpo, 2004)**
https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-41-real-time-stereograms

This is the authoritative real-time GPU reference. Key findings:

- The correct SIS algorithm is **strip-based, multi-pass, with intra-frame
  feedback**. The frame is divided into N vertical strips (typically 8–24).
  Strip 0 renders the pattern texture directly. Each subsequent strip i
  samples strip i-1's *already-rendered output* displaced horizontally by
  `depth * depth_factor * strip_width`. Rows within a strip are independent
  (parallel-safe); strips depend sequentially on each other.
- The per-strip fragment program is trivial — one displaced texture lookup.
  The architectural challenge is intra-frame texture feedback between passes.
- GPU Gems implements feedback via `glCopyTexSubImage2D` between strip passes
  — explicit GPU texture readback/rebind per strip.
- Parameters: `num_strips` (8–24 typical), `depth_factor` (0.0–1.0),
  `invert_depth` (boolean).
- Strip count controls convergence comfort: more strips = smaller strip width
  = convergence point closer to image plane = more comfortable viewing.

**What single-pass cannot do (confirmed empirically 2026-06-30):**
Single-pass `jit.gl.pix` — even with depth-modulated local period or
fixed-period-plus-shift — does not produce a fusible autostereogram. Tested
with stipple, f_grain, and wfg noise sources against triangle, concentric
square, and radial depth maps. Core problem: each pixel independently samples
the pattern at a shifted coordinate with no reference to what neighboring
pixels resolved to, so there is no consistent horizontal repeat structure for
the eye to lock onto across depth discontinuities.

---

## Shader Architecture

**Status: blocked — implementation requires intra-frame multi-pass render-to-
texture, which is new infrastructure territory for this library.**

Per GPU Gems, the correct render sequence per frame:

1. Render strip 0 (leftmost, width = `1/num_strips` in UV space): sample
   pattern texture directly at `(fract(uv.x / strip_width) * strip_width, uv.y)`
2. Copy strip 0 output to a result texture
3. For strips i = 1 to num_strips-1:
   - Fragment program: `result_uv.x = uv.x - strip_width + depth(uv) * depth_factor * strip_width`
   - Sample result texture at `result_uv` → output color for this strip
   - Copy this strip's output back into result texture at correct x offset
4. Output the completed result texture

The per-strip fragment math is simple. The blocking requirement is that each
strip's output must be readable as a texture by the next strip *within the
same frame*.

### Architectural blocker: intra-frame render-to-texture in Vsynth/Max

**Vsynth draw-order chaining** (`jit.gl.pix vsynth` instances in draw order)
introduces a 1-frame delay between passes — definitively frame-rate-locked.
For N strips at 60fps, strip N lags strip 1 by N/60 seconds. At 8 strips
= 133ms lag across the frame width → visible diagonal smearing for any
animated depth source. Not acceptable for the real-time animated target.

**`jit.gl.textureset`** (investigated 2026-06-30): a named texture store,
not a render target. Holds and retrieves textures by index; does not provide
intra-frame render-to-texture capability. Wrong tool.

**`jit.gl.node @capture 1 @layer N`**: confirmed correct tool (researched
2026-06-30). C74 staff (Rob Ramirez) confirmed on the Cycling '74 forum that
two `jit.gl.node` objects at different `@layer` values communicate within the
same frame without delay — layer ordering guarantees node A draws and captures
first, and its texture is available to node B in the same frame. Empirically
confirmed by a forum user ("no frame delay"). Reference: cycling74.com/forums/
is-it-possible-to-augment-jit-gl-render-to_texture-precision

Concrete architecture: N `jit.gl.node vsynth @capture 1 @layer N` objects at
ascending layers, each containing one `jit.gl.pix` with the strip shader. Node
i's captured texture feeds node i+1's pix as its first inlet. Depth texture
feeds all nodes simultaneously as their second inlet. The `layer` attribute
guarantees the intra-frame sequential ordering the algorithm requires.

Constraint: `jit.gl.node @capture` only works in automatic mode — nodes render
automatically with the parent context each frame. Fine for always-on real-time.

Note: `/Users/matt/Vsynth/sirds.genjit` already exists in the Vsynth dir —
this is the single-pass approach in genjit node-graph form. It implements the
correct per-pixel displacement math (mod-based wrapping + depth scaling) that
each strip's pix will use, but as a standalone module doesn't produce a fusible
result (single-pass confirmed insufficient). Useful as reference for the per-
strip codebox math.

**Open question for Kevin — CLOSED (2026-06-30):**
Kevin's own tutorial patch ("Capture with jit.gl.node to mix Vsynth with 3D
content") uses `jit.gl.node vsynth @capture 1 @erase_color 0 0 0 0 @fsaa 1
@adapt 0` with its outlet feeding directly into `vs_op2` Vsynth mixers. This
confirms `jit.gl.node @capture` is a first-class Vsynth pattern. The Vsynth
context compatibility question is closed. See
`docs/max-reference/intraframe_multipass_architecture.md` for the full confirmed pattern.

### Fallback: 1-frame-delay chain (slow depth sources only)

Chain N `jit.gl.pix vsynth` instances using existing Vsynth draw-order
convention. Documented limitations:
- Correct for static or slow-moving depth sources
- Produces diagonal strip-smearing for fast animated depth
- Reduce strip count to 4–6 to minimize lag
- Treat as a design constraint ("optimized for slow depth sources"), not a bug

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | bang + control | — | Vsynth standard. Control messages route to params. |
| 1 | texture (required) | depth | Depth/shape source, luma-read. Plain texture, NOT vecfield-typed (depth is scalar near/far, not 2D direction — see Decisions). No fallback. |
| 2 | texture (required) | pattern | Repeating visual content. No internal fallback — unconnected = silent/black, matching f_caustic precedent. Stochastic, isotropic sources (f_grain, vs_noise) strongly preferred over structured/anisotropic sources (stipple at coarse settings reads as organized stripes, disrupts the uniform-noise appearance required for the illusion). |

---

## Parameters

**Note: param shape is fixed; ranges and defaults are TBD pending working
implementation.**

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `num_strips` | live.numbox | 4–24 | TBD | Number of vertical strips. Controls convergence comfort and per-strip lag (if using fallback architecture). Integer — use live.numbox not live.dial. |
| `depth_factor` | live.dial | 0.0–1.0 | TBD | Depth → displacement scaling. GPU Gems name retained for clarity. |
| `invert_depth` | jsui toggle | 0/1 | 0 | Inverts depth values (1 - depth). Controls whether bright = near or bright = far. |
| `depth_blur` | live.dial | 0.0–1.0 | TBD | Internal depth smoothing. Module-owned — addresses per-pixel warping from sharp depth edges. |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Bypass. |

**Prefix:** `magiceye` (tentative)
**Type:** TBD — may need float32 for depth precision; revisit once architecture is resolved.

---

## Outlets

| Outlet | Label | Description |
|---|---|---|
| out1 | autostereogram | The resolved SIS field. Bypass-respecting. |
| out2 | debug | Isolated depth/shift field visualization for tuning — not a compositing layer. |

---

## Decisions (closed in discussion 2026-06-30)

- **No vecfield typing on depth inlet.** Depth is a scalar (near/far), not a
  2D direction+magnitude quantity. Vecfield encoding doesn't fit and would
  invite nonsensical patches. Vecfield-driven shift modulation is a possible
  future idea, out of scope for v1 (would reintroduce non-horizontal
  displacement, which breaks stereo correspondence).
- **No stereo-pair mode.** Confirmed target is single-field SIRDS-style
  resolve. Ruled out after initial discussion ambiguity.
- **No full Tyler-Clark link-chain relaxation.** Out of scope — sequential
  per-row scan is CPU-only and doesn't address the strip-feedback problem.
- **Pattern inlet has no internal fallback.** Matches f_caustic precedent.
- **Depth preconditioning is module-owned.** `depth_blur` is internal, not
  a caller requirement — per-pixel warping was the prototype's primary failure
  mode and traced directly to insufficient depth smoothness.
- **Horizontal-only shift.** Any vertical/angular component breaks stereo
  correspondence. Hard-constrained in the fragment program, not a tunable
  parameter.
- **Single-pass is confirmed insufficient.** Not a parameter/tuning issue —
  a structural impossibility. The eye needs consistent horizontal repeat
  structure that single-pass independent per-pixel sampling cannot provide.
  Do not revisit this without a new architectural approach.

---

## Tabled empirical questions

Require working implementation before testing — captured to avoid re-deriving.

- **Temporal stability of strip feedback with animated depth.** Primary open
  risk for the animated use case: does the field reshuffle visibly frame to
  frame as depth animates, or does it hold a stable-enough fusion lock?
  Cannot be tested until a working multi-pass implementation exists.
- **Minimum strip count for acceptable fusion.** 8–24 is GPU Gems recommendation;
  minimum for a performance/projection context may be lower. Test empirically.
- **`invert_depth` convention.** Which direction reads as popping out vs
  receding — needs visual confirmation with a working stereogram.
- **`depth_blur` uniformity.** Whether uniform blur is sufficient or
  edge-aware blur is needed at depth discontinuities. Start uniform.

---

## Open questions for next session

- **Primary:** What is the correct Max/Jitter pattern for intra-frame
  render-to-texture? Candidates: `jit.gl.node`, `jit.gl.pix @output_texture`.
  Research task queued — see HANDOFF.
- Confirm `magiceye` prefix against existing conventions before build.
- Revisit `num_strips` UI once architecture is resolved.
