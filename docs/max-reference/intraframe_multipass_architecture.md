# Intra-Frame Multi-Pass Rendering — Architecture Discovery

_Last updated: 2026-06-30_
_Status: PARTIALLY CORRECTED. An earlier version of this document claimed the
child-pix-drawto-node binding mechanism was "confirmed" — it was not; an
isolated empirical test falsified it (see HANDOFF.md, 2026-06-30 session).
The `@layer` two-node ordering claim (sourced from C74 staff forum quotes)
is probably still sound, but the specific "child pix inside each node"
wiring built on top of it is wrong and has been corrected below. Sections
still needing empirical verification are marked **UNVERIFIED** — do not
treat this document as settled until those are tested. Do not build the
2-strip scratch patch from this doc's wiring diagrams as-is; verify the
corrected pattern in the isolated learning patch first._

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
render-to-texture with no frame delay — for 3D scene content. This part is
sourced from canonical C74 staff testimony and is probably sound.**

Two `jit.gl.node @capture 1` objects assigned different `@layer` values are
guaranteed to draw in layer order within a single frame. The lower-layer node
draws first, its captured texture is fully available to the higher-layer node's
shaders *within the same frame*.

**Correction (2026-06-30):** the Rob Ramirez/Federico Foderaro quotes below
describe node A rendering *3D objects* ("renders-depth" objects) and node B's
*3D objects* consuming node A's captured texture (e.g. as a texture map) —
not a `jit.gl.pix` bound as a child of either node. An isolated empirical
test this session showed `jit.gl.pix` cannot bind into a `jit.gl.node`
sub-context via `drawto`-name-matching or the middle outlet — `jit.gl.pix`/
`jit.gl.slab` are texture-domain operators, not scene members, and are
meant to be **chained to** a node's captured-texture output (received as a
normal inlet-0 input), not bound inside it. See HANDOFF.md 2026-06-30 and
the corrected pattern below. The `@layer` ordering claim itself is not
falsified by this — only the assumption that it lets you put a *pix* inside
each layer's node.

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

### N-pass intra-frame chain — CORRECTED, still UNVERIFIED end-to-end

The version of this diagram previously here had each `jit.gl.pix` bound
*inside* a node (`captured by node_0`, etc.) via drawto/name-matching. That
binding mechanism was empirically falsified this session (see correction
above). `jit.gl.pix` is not a scene member of a node — it consumes a node's
captured-texture output as an ordinary inlet-0 texture input instead. The
corrected shape of the pattern, not yet built or tested as a full chain:

```
jit.gl.node vsynth @capture 1 @layer 0 (node_0)
  └── (3D scene content only — e.g. jit.gl.plato/gridshape/videoplane
       bound via drawto=node_0's name, or the middle outlet)
      ↓ node_0 left outlet = captured jit.gl.texture, current frame

jit.gl.pix (pass-0 shader)
  └── in0: node_0's captured texture ← ordinary texture input, not a binding
  └── out: pass-0 result texture

jit.gl.node vsynth @capture 1 @layer 1 (node_1)
  └── (3D scene content that itself uses pass-0's result texture as a
       texture map — e.g. via @texture attribute on a videoplane/gridshape)
      ↓ node_1 left outlet = captured jit.gl.texture, current frame
        (same-frame relative to node_0 per @layer ordering — this part
        rests on the Ramirez/Foderaro sourcing above)

jit.gl.pix (pass-1 shader)
  └── in0: node_1's captured texture
  └── out: pass-1 result texture

... repeat for N passes
```

**UNVERIFIED — the actual open question for f_stereogram:** the algorithm
needs each strip pass to feed a *pix* shader's math directly (per-pixel
displacement sampling), not a 3D object's texture map. Whether wrapping
each strip's content in a throwaway `jit.gl.plato`/`jit.gl.videoplane` just
to get it through a node's capture, then handing that texture to a pix,
each pass, actually reproduces same-frame ordering end-to-end has NOT been
tested. Neither has the simpler alternative: a plain message-driven
pix→pix chain (pass-0's outlet texture wired straight into pass-1's inlet,
no nodes at all) — see "Not a pix-to-pix wire" below, which asserts this
has a frame delay but that assertion is itself unverified.

**Layer values:** Must be strictly increasing (0, 1, 2, ...). Objects in the
same layer have no guaranteed draw order — use distinct layers for each pass.
(This part of the claim is unaffected by the correction above.)

**Context argument:** The first argument to `jit.gl.node` is the parent
context name. In Vsynth patches, this is `vsynth`. Each node also creates its
own sub-context (named by its `name` attribute); **3D scene objects** draw to
the node's sub-context via drawto/middle-outlet — `jit.gl.pix` objects do
not draw to it at all, they consume its captured-texture output as a normal
inlet.

**Naming convention (proposed, premature):** `{module}_node_{i}` for the
node name attribute, `{module}_pass_{i}` for each pass's pix `@name`. This
was written against the falsified architecture — keep the naming idea, but
don't lock in the wiring it implies until the corrected pattern above is
actually tested.

---

## Constraints and failure modes

### Automatic mode only
`jit.gl.node @capture` only works when `@automatic 1` (the default). The node
renders automatically with the parent render context each frame. You cannot
manually bang individual passes. This is fine for always-on real-time
rendering, but rules out using this pattern for non-realtime or manually-timed
single-frame captures. (For single-frame capture, `jit.gl.textureset.js` is
the workaround per C74 forum guidance.)

### Not a pix-to-pix wire — UNVERIFIED, flagged for re-check
Unlike frame-to-frame feedback (where you literally wire one pix outlet to
another pix inlet and the one-frame GPU delay makes it safe), this document
has asserted that intra-frame multi-pass requires explicit
`jit.gl.node @capture` objects, and that wiring pix_A's outlet directly to
pix_B's inlet has a one-frame delay built in. **This claim has not itself
been empirically tested or sourced** — it was written with the same
unearned confidence that produced the drawto-binding error above, so it
should not be trusted without a check. It's plausible pix-to-pix is
message-driven (Max's normal immediate-execution model) rather than
render-loop-driven, in which case a straight pix→pix chain might have
*no* delay at all, which would make the whole node-based approach
unnecessary for f_stereogram. Test this directly — it's simpler than the
node-based pattern and worth ruling in or out before building anything else.

### Objects in same layer have undefined order
The `@layer` attribute guarantees ordering *between* layers, not within a
layer. If two nodes share a `@layer` value, their draw order relative to each
other is undefined. Use strictly distinct layer values for each sequential pass.

### Vsynth context compatibility — node itself confirmed, pix-binding claim retracted
Kevin (Vsynth author) uses `jit.gl.node vsynth @capture 1` in his own
tutorial patch ("Capture with jit.gl.node to mix Vsynth with 3D content"),
confirming `jit.gl.node @capture` itself is a supported, documented Vsynth
pattern for capturing 3D content. What is retracted below (see Tutorial 1
description further down) is the claim that Kevin's tutorial shows
`jit.gl.pix` binding into the node's sub-context the same way 3D objects
do — re-checking that patch for what it actually shows is on the next-
session list. Key attributes from Kevin's patch:

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
mechanism for 3D content — this part is reasonably solid. It does NOT by
itself establish anything about how a `jit.gl.pix` gets its content into
that ordering; that's the still-open question this whole document is
tracking. Do not read "no further verification needed" here as covering
the pix side.

---

## Tools investigated and ruled out

| Tool | Why it doesn't solve intra-frame multi-pass |
|---|---|
| `jit.gl.pix vsynth` draw-order chaining | UNVERIFIED claim (see "Not a pix-to-pix wire" above) — previously stated as "definitively frame-rate-locked," but that was asserted without a test or source, using the same unearned confidence that produced the drawto-binding error. Needs an actual check before this row is trusted. |
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
inlet. 3D objects (e.g. `jit.gl.plato`) draw to the node's sub-context by
using the node's name as their `drawto` attribute or the middle outlet.

**Retracted:** this document previously stated `jit.gl.pix` objects draw to
the node's sub-context the same way. An isolated test falsified that —
`jit.gl.pix` isn't a scene member and doesn't bind via drawto/middle-outlet
at all; it consumes a node's captured texture as an ordinary inlet input
after the fact. **UNVERIFIED:** whether this tutorial pattern, once
correctly wired, actually solves f_stereogram's strip-chain need — see the
open question flagged in "The pattern" section above.

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

**UNVERIFIED — this whole section was written against the falsified
pix-as-node-child architecture and needs rethinking once the corrected
pattern (or the plain pix-to-pix chain, if that turns out delay-free) is
actually tested.** Provisional shape, not to be built from yet:

- If the corrected node→texture→pix pattern is what's needed: the
  bpatcher's texture inlet(s) wire into whatever 3D object lives inside
  the *first* node (not directly into a pix); the bpatcher's texture
  outlet comes from the *last* pass's pix outlet (not a node's captured
  texture outlet, since the last step is pix processing after the last
  node's capture)
- If the plain pix-to-pix chain turns out to have no delay, none of this
  node-based structure is needed at all — reconsider from scratch
- Standard param wiring (`attrui` → `route` → `set param` messages) still
  applies to whichever pix objects end up in the chain, one route per pix
  if params differ between strips

`build_patcher.py` likely cannot express this structure via `definition.py`
without extension — the current schema assumes one `jit.gl.pix` per module.
This is a build system question to resolve when f_stereogram reaches the build
phase. May require hand-building the patcher JSON rather than generating it.

---

## Open questions

- **Pix-to-pix message chain delay (highest priority, cheapest test):** does
  wiring pix_A's outlet directly to pix_B's inlet (no nodes) actually incur
  a one-frame delay, or was that assumed without testing? If delay-free,
  the entire node-based architecture in this document may be unnecessary.
  Test this first, before anything else here.

- **Node→pix chain, corrected version:** does `node (3D content) → captured
  texture → pix (processes it) → [next node reuses pix's output as a
  texture map] → next node's capture → next pix` actually preserve
  same-frame ordering end to end, or does inserting a pix step between
  nodes reintroduce a frame boundary somewhere? Not yet tested.

- **What Kevin's Tutorial 1 patch actually shows:** re-open
  `vs_Render to Node_help.maxpat` (or the tutorial patch it came from) and
  check literally what's wired to what, rather than reasoning from a
  description of it — this is what produced the original error.

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
