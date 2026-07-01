# Intra-Frame Multi-Pass Rendering — Architecture Discovery

_Last updated: 2026-06-30_
_Status: Mechanism confirmed by canonical sources (C74 staff + Kevin's Vsynth
tutorial patch). Ready to build minimal 2-strip scratch patch._

---

## Relationship to temporal_synthesis_architecture.md

`temporal_synthesis_architecture.md` covers **frame-to-frame** feedback: how
one frame's output becomes the next frame's input, using chained `jit.gl.pix`
instances or `jit.gl.textureset`. That pattern is about temporal state across
frames — the one-frame GPU pipeline delay is a feature, not a problem.

This document covers a different problem: **within a single frame**, rendering
to a texture and immediately reading that texture in a subsequent pass — before
the frame is presented. The one-frame delay is an obstacle here, not a feature.
These are two distinct architectural categories that should not be confused.

**Use intra-frame multi-pass when:**
- Pass N+1 depends on the *current frame's* output of pass N (not a previous frame's)
- The algorithm requires sequential horizontal/spatial propagation within one frame
- Examples: autostereogram strip generation (f_stereogram), multi-pass
  accumulation effects where each pass builds on the current frame's previous
  pass output

**Use frame-to-frame feedback (temporal_synthesis_architecture.md) when:**
- Pass N+1 depends on the *previous frame's* output
- Examples: IIR per-pixel filtering, advection, reaction-diffusion

---

## The core finding

**`jit.gl.node @capture 1` with the `@layer` attribute enables intra-frame
render-to-texture with no frame delay.**

Two `jit.gl.node @capture 1` objects assigned different `@layer` values are
guaranteed to draw in layer order within a single frame. The lower-layer node
draws first, its captured texture is fully available to the higher-layer node's
shaders *within the same frame*.

**Sources:**
- Rob Ramirez (C74 engineering staff), Cycling '74 forum, confirmed intra-frame:
  "node A (@layer 1) draws the 'renders-depth' objects and outputs the depth
  texture. node B (@layer 2) draws 'needs-depth' with the depth values from
  node A. AFAIK, that should work without a delayed frame. The layer attribute
  will ensure that A draws first, and that B's depth texture is up to date."
  Thread: cycling74.com/forums/is-it-possible-to-augment-jit-gl-render-to_texture-precision
- Federico Foderaro (C74 staff/educator), confirmed empirically in reply:
  "Indeed the method of using two nodes gives me no frame delay."

These are canonical sources — Rob Ramirez is C74 engineering, Federico
Foderaro is the leading independent Max/Jitter educator, now also C74 staff.

---

## The pattern

### N-pass intra-frame chain

```
jit.gl.node vsynth @capture 1 @layer 0 (node_0)
  └── jit.gl.pix (pass-0 shader)
      └── in: source texture(s)
      └── out → captured by node_0
         ↓ node_0 outlet (captured texture, current frame)

jit.gl.node vsynth @capture 1 @layer 1 (node_1)
  └── jit.gl.pix (pass-1 shader)
      └── in0: node_0 captured texture ← same frame, no delay
      └── in1: any other inputs (depth, etc.)
      └── out → captured by node_1
         ↓ node_1 outlet (captured texture, current frame)

... (repeat for N passes)

jit.gl.node vsynth @capture 1 @layer N-1 (node_N-1)
  └── jit.gl.pix (pass-N-1 shader)
      └── in0: node_N-2 captured texture ← same frame, no delay
      └── out → captured by node_N-1
         ↓ node_N-1 outlet = final output for this frame
```

**Layer values:** Must be strictly increasing (0, 1, 2, ...). Objects in the
same layer have no guaranteed draw order — use distinct layers for each pass.

**Context argument:** The first argument to `jit.gl.node` is the parent
context name. In Vsynth patches, this is `vsynth`. Each node also creates its
own sub-context (named by its `name` attribute); child `jit.gl.pix` objects
draw to the node's sub-context, not to `vsynth` directly.

**Naming convention (proposed):** `{module}_node_{i}` for the node name
attribute, `{module}_pass_{i}` for the child pix `@name`. Example for
f_stereogram: `magiceye_node_0`, `magiceye_pass_0`, etc.

---

## Constraints and failure modes

### Automatic mode only
`jit.gl.node @capture` only works when `@automatic 1` (the default). The node
renders automatically with the parent render context each frame. You cannot
manually bang individual passes. This is fine for always-on real-time
rendering, but rules out using this pattern for non-realtime or manually-timed
single-frame captures. (For single-frame capture, `jit.gl.textureset.js` is
the workaround per C74 forum guidance.)

### Not a pix-to-pix wire
Unlike frame-to-frame feedback (where you literally wire one pix outlet to
another pix inlet and the one-frame GPU delay makes it safe), intra-frame
multi-pass requires explicit `jit.gl.node @capture` objects. You cannot wire
pix_A's outlet directly to pix_B's inlet and expect same-frame ordering —
that path has the one-frame delay built in. The node's capture mechanism is
specifically what provides same-frame availability.

### Objects in same layer have undefined order
The `@layer` attribute guarantees ordering *between* layers, not within a
layer. If two nodes share a `@layer` value, their draw order relative to each
other is undefined. Use strictly distinct layer values for each sequential pass.

### Vsynth context compatibility — confirmed
Kevin (Vsynth author) uses `jit.gl.node vsynth @capture 1` in his own
tutorial patch ("Capture with jit.gl.node to mix Vsynth with 3D content"),
confirming this is a supported, documented Vsynth pattern. Key attributes
from Kevin's patch:

```
jit.gl.node vsynth @capture 1 @erase_color 0 0 0 0 @fsaa 1 @adapt 0
```

- First argument `vsynth` = parent context — correct for Vsynth patches
- `@capture 1` — enables render-to-texture
- `@erase_color 0 0 0 0` — transparent background; required so node-captured
  content composites correctly into the Vsynth signal chain rather than
  painting over with an opaque background color
- `@fsaa 1` — full-scene anti-aliasing on the captured texture
- `@adapt 0` — fixed dimensions (set via `r dim` or explicit `@dim`); use
  `@adapt 1` when output should match input texture dimensions

The captured texture outlet feeds directly into standard `vs_op2` Vsynth
mixer inlets in Kevin's patch — no adapter needed. Standard Vsynth bpatchers
coexist in the same patch drawing to the same `vsynth` context alongside the
node. This confirms that `jit.gl.node @capture` is a first-class Vsynth
pattern, not an edge case.

The `@layer` ordering for multiple nodes within the Vsynth context follows
from the C74 staff confirmation above and Kevin's established use of the
mechanism — no further verification needed before building.

---

## Tools investigated and ruled out

| Tool | Why it doesn't solve intra-frame multi-pass |
|---|---|
| `jit.gl.pix vsynth` draw-order chaining | 1-frame delay between pix instances — definitively frame-rate-locked. N strips at 60fps = N×16ms lag. |
| `jit.gl.textureset` | Named texture store, not a render target. Holds and retrieves textures by index but cannot render to a slot and immediately read it back within the same frame. Useful for multi-frame history buffers (see temporal_synthesis_architecture.md Pattern 2), wrong tool here. |
| `jit.gl.render to_texture` message | "Old technology" per Rob Ramirez. Deprecated in favor of `jit.gl.node @capture`. Also char-type only, no float32. |
| `jit.gl.pix @output_texture` | This is for `jit.movie`/`jit.grab`/`jit.world` objects to stream to a texture rather than a matrix — not a render-to-texture mechanism for pix output. |
| Single pix self-loop | Always has one-frame delay (see temporal_synthesis_architecture.md Pattern 3). |

---

## Kevin's Vsynth tutorial patches (canonical references)

Two tutorial patches from Kevin document the established Vsynth patterns for
working with GL contexts beyond the standard `jit.gl.pix vsynth` chain.

### Tutorial 1: "Capture with jit.gl.node to mix Vsynth with 3D content"

**Use case:** Embed 3D objects or multi-pass rendering *within* the `vsynth`
context, capturing the result as a texture that feeds back into the Vsynth
signal chain.

**Key object:**
```
jit.gl.node vsynth @capture 1 @erase_color 0 0 0 0 @fsaa 1 @adapt 0
```

- `vsynth` = parent context (first argument)
- `@capture 1` = render this node's sub-context to an internal texture
- `@erase_color 0 0 0 0` = transparent background — critical for correct
  compositing into the Vsynth signal chain; opaque would paint over content
- `@fsaa 1` = full-scene anti-aliasing on the captured texture
- `@adapt 0` = fixed output dimensions (set `@dim` explicitly or via `r dim`);
  use `@adapt 1` when output should match input texture dimensions

The node's left outlet emits the captured `jit_gl_texture` message each frame,
which plugs directly into `vs_op2` mixer inlets or any other Vsynth module
inlet. 3D objects (e.g. `jit.gl.plato`) and `jit.gl.pix` objects draw to the
node's sub-context by using the node's name as their `drawto` attribute.

**This is the pattern for f_stereogram's strip-chain architecture.**

---

### Tutorial 2: "Shows how to make your render context child of Vsynth"

**Use case:** Run a *separate* render context (separate `jit.gl.render` +
`jit.window`) synchronized to Vsynth's render loop — e.g. a second output
window, a projection-mapped surface on a different display.

**Key pattern:**
```
r draw                          ← receives Vsynth's render-loop bang
  ↓
t b b erase
  ├── s your_context_draw       ← bang your context's draw
  └── [erase] → jit.gl.render your_context_name @erase_color 0. 0. 0. 1.
                                ← your separate render context

jit.window your_context_name @shared 1 @pos 300 300
                                ← @shared 1 = shares OpenGL context with Vsynth
                                  (textures valid across both contexts)

[vsynth texture] → jit.gl.cornerpin your_context_name @preserve_aspect 1 ...
                                ← display Vsynth content in your window
```

**Key insight — `r draw`:** Vsynth's render loop publishes a global draw bang
via a named send. Any patch in the same Max environment can receive this bang
via `r draw` and use it to drive a synchronized render context. This is how
Vsynth's timing propagates to sibling contexts.

**Key insight — `@shared 1`:** The `jit.window @shared 1` attribute shares the
underlying OpenGL context with Vsynth. Without this, texture names from the
`vsynth` context are not valid references in the sibling context.

**This is NOT the pattern for f_stereogram** — which needs intra-context
multi-pass (Tutorial 1), not a sibling context. Tutorial 2 is useful for:
separate output windows, multi-projector setups, secondary display contexts
that consume Vsynth output.

---

`f_stereogram` is the first module in this library to require intra-frame
multi-pass rendering. It implements the GPU Gems Chapter 41 SIS algorithm
(Policarpo 2004): N vertical strips, each strip reading from the previous
strip's output displaced by depth.

**Algorithm (per frame):**

Strip 0: tile pattern texture at strip_width period across full frame
```
// strip 0 codebox
Param num_strips(8.);
uv = norm;
strip_width = 1. / num_strips;
x_tiled = fract(uv.x / strip_width) * strip_width;
out1 = sample(in1, vec(x_tiled, uv.y));  // in1 = pattern texture
```

Strips 1 to N-1: GPU Gems displacement formula, pass-through elsewhere
```
// strip i codebox (i = 1 to N-1)
// in1 = previous node's captured texture
// in2 = depth texture
Param strip_i(1.);       // which strip this pass renders
Param num_strips(8.);
Param depth_factor(0.3);

uv = norm;
strip_width = 1. / num_strips;
strip_start = (strip_i - 1.) * strip_width;
strip_end = strip_i * strip_width;

// Is this pixel in this strip's x range?
in_strip = step(strip_start, uv.x) * (1. - step(strip_end, uv.x));

depth = sample(in2, uv).x;
x_displaced = uv.x - strip_width + depth * depth_factor * strip_width;

displaced = sample(in1, vec(x_displaced, uv.y));
passthrough = sample(in1, uv);

out1 = mix(passthrough, displaced, in_strip);
```

**Existing prior art:** `/Users/matt/Vsynth/sirds.genjit` is a single-pass
approach to the same problem in genjit node-graph format. It confirms the
correct displacement math but doesn't produce a fusible autostereogram (single-
pass confirmed insufficient 2026-06-30). The displacement formula it uses is
identical to the per-strip formula above.

**Spec:** `.specify/f_stereogram/spec.md`

---

## Bpatcher integration notes

Unlike simple single-`jit.gl.pix` modules, an intra-frame multi-pass module
contains multiple `jit.gl.node` objects rather than one `jit.gl.pix`. This is
a different structural container than the standard bpatcher convention:

- The bpatcher's texture inlet(s) wire to the *first* node's child pix
- The bpatcher's texture outlet comes from the *last* node's captured texture outlet
- Internal nodes are entirely invisible to the Vsynth signal chain — just
  plumbing between the first and last
- Standard param wiring (`attrui` → `route` → `set param` messages) still
  applies to the child pix objects, but each pix needs its own route if params
  differ between strips

`build_patcher.py` likely cannot express this structure via `definition.py`
without extension — the current schema assumes one `jit.gl.pix` per module.
This is a build system question to resolve when f_stereogram reaches the build
phase. May require hand-building the patcher JSON rather than generating it.

---

## Open questions

- **Strip count vs. perceptual minimum:** GPU Gems recommends 8–24 strips for
  comfortable stereo fusion at normal viewing distance. For performance/projection
  contexts (viewers at distance, casual fusion), the minimum may be 4–6. Test
  empirically once the mechanism is confirmed in a scratch patch.

- **`@adapt` setting for chained nodes:** Kevin's patch uses `@adapt 0` with
  explicit dimensions (mixing fixed-size 3D content). For f_stereogram, where
  output should match the input depth/pattern texture dimensions, `@adapt 1`
  is likely correct — but needs verification that adapt correctly propagates
  through a chain of nodes.

- **build_patcher.py extension:** Multi-node modules don't fit the current
  single-pix schema. Determine whether to extend the build system or hand-build
  the patcher JSON for multi-pass modules.
