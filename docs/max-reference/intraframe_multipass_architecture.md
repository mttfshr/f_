# Intra-Frame Multi-Pass Rendering — Architecture Reference

_Last updated: 2026-07-05 (consolidated — see note below)_
_Status: Investigated for f_stereogram/f_sirds, ultimately NOT what that
module uses. Kept as reference for the parts that are still true and
potentially useful for a future module._

## Resolution, stated up front

This document was a live investigation into using `jit.gl.node @capture`
+ `@layer` to solve intra-frame multi-pass rendering (pass N+1 reading
pass N's *current-frame* output, before the frame presents) — needed for
`f_stereogram`'s strip-based autostereogram algorithm. That investigation
included a real false start (an earlier version claimed `jit.gl.pix`
could bind *inside* a node's sub-context like a 3D scene object; an
isolated test falsified this — `jit.gl.pix` is a texture-domain operator,
not a scene member).

**The actual answer turned out to be much simpler and didn't need any of
this:** a plain forward chain of `jit.gl.pix` objects has no inherent
frame delay at all. The one-frame latency everyone assumes is universal
is actually a property of **closing a feedback loop** specifically (both
`jit.gl.pix` and `jit.gl.slab` copy their incoming texture, which is what
prevents infinite instantaneous regress in a loop — and that copy-on-cycle
behavior is what produces the delay, not texture handoff in general). Full
reasoning: `temporal_synthesis_architecture.md`. The built module,
`f_sirds`, is 13 plain chained `jit.gl.pix` objects — no `jit.gl.node`, no
`@layer`, nothing from this document.

**What's still worth keeping here:** the `jit.gl.node @capture`/`@layer`
mechanism itself is real and confirmed working — for actual 3D scene
content, which was never `f_stereogram`'s problem. If a future module
genuinely needs to composite 3D geometry into a Vsynth context (not just
chain 2D texture passes), this is the right starting reference.

---

## The confirmed mechanism (for 3D content specifically)

`jit.gl.node @capture 1` with the `@layer` attribute enables intra-frame
render-to-texture for 3D scene content. Two `jit.gl.node @capture 1`
objects assigned different `@layer` values are guaranteed to draw in
layer order within a single frame — the lower-layer node draws first, and
its captured texture is fully available to the higher-layer node's *3D
objects* within the same frame (e.g. as a texture map on a
`jit.gl.videoplane`).

**Sources (canonical):**
- Rob Ramirez (C74 engineering), Cycling '74 forum: "node A (@layer 1)
  draws the 'renders-depth' objects and outputs the depth texture. node B
  (@layer 2) draws 'needs-depth' with the depth values from node A...
  that should work without a delayed frame."
- Federico Foderaro (C74 staff/educator), same thread, confirmed
  empirically: "the method of using two nodes gives me no frame delay."
- Kevin's own Vsynth tutorial patch ("Capture with jit.gl.node to mix
  Vsynth with 3D content") confirms `jit.gl.node @capture` is a supported,
  documented Vsynth pattern:
  ```
  jit.gl.node vsynth @capture 1 @erase_color 0 0 0 0 @fsaa 1 @adapt 0
  ```
  - First argument `vsynth` = parent context
  - `@erase_color 0 0 0 0` = transparent background, required for correct
    Vsynth compositing (opaque would paint over content)
  - `@fsaa 1` = full-scene anti-aliasing on the captured texture
  - `@adapt 0` = fixed dimensions; use `@adapt 1` to match input texture size
  - The captured texture feeds directly into standard `vs_op2` mixer
    inlets — no adapter needed. 3D objects bind to the node's sub-context
    via `drawto`-name-matching or the middle outlet.

**What this does NOT do:** bind a `jit.gl.pix` inside a node's
sub-context. `jit.gl.pix`/`jit.gl.slab` consume a node's captured texture
as an ordinary inlet-0 input, after the fact — they are never scene
members. This was the false start mentioned above.

**Layer values** must be strictly increasing (0, 1, 2, ...) — objects
sharing a layer have no guaranteed draw order relative to each other.

**Constraint:** `jit.gl.node @capture` only renders automatically when
`@automatic 1` (the default) — you cannot manually bang individual passes.
Fine for real-time rendering, rules out manually-timed single-frame
capture (for which `jit.gl.textureset.js` is the documented workaround).

---

## Kevin's second tutorial (unrelated use case, noted for completeness)

"Shows how to make your render context child of Vsynth" — a *separate*
`jit.gl.render`/`jit.window` synchronized to Vsynth's render loop via a
shared `r draw` bang and `jit.window @shared 1` (shares the GL context so
texture names stay valid across both). This is for secondary output
windows / multi-projector setups, not intra-context multi-pass — a
different problem from everything above.

---

## Tools investigated and ruled out (for this specific problem)

| Tool | Why it didn't end up needed |
|---|---|
| `jit.gl.node` + `@layer` + child-pix binding | The child-pix binding half was falsified; the node/layer half works but for 3D content, which f_stereogram never needed |
| `jit.gl.textureset` | Named texture ring buffer, not a render target — right tool for multi-frame history (temporal_synthesis_architecture.md Pattern 2), wrong tool for intra-frame chaining |
| `jit.gl.render to_texture` message | Deprecated per C74 staff, char-type only, no float32 |
| Plain forward `jit.gl.pix` chain | **This is what actually works** — see Resolution above |

## If this is ever revisited

The open question that would actually matter for a *future* 3D-compositing
module: does a `node → pix (processes captured texture) → next node
(uses pix's output as a texture map) → next node's capture` chain
preserve same-frame ordering end-to-end once a pix step sits between two
nodes? Not tested — never needed to be, since f_stereogram/f_sirds took
the plain-chain path instead. Worth a scratch test before building
anything real on this if the need ever arises.
