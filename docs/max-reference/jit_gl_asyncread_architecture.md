# jit.gl.asyncread — Architecture Reference

_Created: 2026-07-01_
_Status: Sourced from Cycling '74 documentation (Max 8 object reference —
the Max 9 refpage on disk has several `TEXT_HERE` placeholder gaps C74
never filled in, so the Max 8 docs page fills those in), the "GL Texture
Output" vignette, the "Best Practices in Jitter Part 1" tutorial, and
several C74 forum threads including a Rob Ramirez reply and a 2026 Max
9.1.4-specific bug thread. Not yet tested empirically in this Max 9
environment — see "Open questions" at the bottom, in particular a live
compatibility issue that may affect Matt's setup directly._

## What it is

`jit.gl.asyncread` reads a GPU framebuffer or texture **back into a Jitter
matrix** (CPU-side) using Pixel Buffer Objects (PBOs), so the read doesn't
block the render pipeline the way a naive readback would. It is the
opposite direction of everything else in the f_ library's signal chain:
every f_ module stays in the GPU texture domain end-to-end
(`jit.gl.pix`/`jit.gl.slab`, texture in, texture out). `jit.gl.asyncread`
exists specifically for the case where you need **CPU-side matrix data**
extracted from something that's currently a GPU texture — because some
Jitter operations (color tracking via `jit.findbounds`, color analysis via
`jit.3m`, and other matrix-only CPU objects) have no GPU/texture-domain
equivalent and can only run on a Jitter matrix.

Per C74's "GL Texture Output" docs: **matrix readback is a relatively
costly operation**, full stop — async vs. sync readback is a choice about
*how* costly, not whether it's free. Async (via `jit.gl.asyncread`) is
described as the preferred, more performant route when a readback is
required at all; sync readback (texture output wired directly into a plain
`jit.matrix` object) is simpler but blocks the pipeline. Downsampling on
the GPU (a `jit.gl.texture` with `@adapt 0` and small explicit dims) before
either kind of readback is the standard mitigation when only coarse data
is actually needed (e.g. blob/color tracking doesn't need full-res input).

## Mechanism

- **Two PBOs in tandem**, alternating every frame, so the GPU can keep
  rendering while the previous frame's buffer is being transferred to
  system memory — this is what "asynchronous" refers to.
- **`mode` attribute — `interleaved` (default) vs. `split`:**
  `interleaved` reads a full frame into each internal buffer, switching
  which buffer is active every other frame — **this mode has a one-frame
  readback delay**, explicitly documented ("asyncread stands for
  asynchronous readback because the output matrix is delayed by a single
  frame from the input texture" — C74 tutorial). `split` reads a single
  frame across two passes with concurrent output — implies no added frame
  delay, though the doc doesn't spell out the trade-off it costs for that
  (presumably some throughput or completeness trade against interleaved).
  **Not tested — which mode is right for a given use case is a real
  open question, not just a default-vs-alternative footnote.**
- **`texture` attribute:** target a specific named texture for readback.
  If unset, it reads back the whole `drawto` context instead.
- **Object argument / `drawto`:** required — the name of a drawing context
  (`jit.window`, `jit.pwindow`, or a `jit.gl.node` sub-context). Confirms
  this can read back a `jit.gl.node`'s captured sub-context specifically,
  not just a whole top-level window — relevant if this were ever combined
  with the intra-frame multipass/node work already in this repo's other
  reference docs.
- **`@layer` should be set high (e.g. 1000)** per a Rob Ramirez forum
  reply — this ensures the asyncread object renders *after* everything
  else in its context, so it's reading a complete frame rather than a
  partially-drawn one. This is a load-bearing practical detail, not
  optional tuning — get it wrong and you're reading back an incomplete
  frame.
- **`matrixoutput` attribute:** must be on for the object to actually emit
  the readback matrix out the left outlet.

## Practical gotchas

- **Matrix readback is fundamentally a performance cost, not a free
  convenience.** Every source consulted treats this as something to avoid
  unless a CPU-only matrix operation genuinely requires it — not a casual
  bridge between GPU and CPU domains. For a real-time performance system
  built around staying GPU-resident (which is exactly what f_'s existing
  design principles already do), any use of this object is an intentional
  exception, not a routine pattern.
- **UNVERIFIED, high relevance to this environment:** a 2026 C74 forum
  thread ("jit.gl.asyncread not working in Max 9.1.4") reports the object
  silently produces no output under Max's newer **Global Context**
  feature — even its own help patch breaks, because `jit.world` can't
  `drawto` a named `jit.gl.asyncread` under that feature. The fix
  reported in the thread is either disabling Global Context in Max's
  preferences, or using `@output_texture` on the upstream object (the
  thread doesn't fully spell out whether that's `@output_texture` on
  `jit.gl.asyncread` itself or on whatever feeds it — worth confirming
  directly before relying on this). **If this is ever tried in this Max 9
  install, check Global Context preference status first** — this is
  exactly the kind of silent-failure-that-looks-like-a-different-bug
  this project has been burned by before (cf. the `.maxpat` stale-reload
  issue in HANDOFF.md).

## Fit assessment for f_ — no established use case yet

Unlike `jit.gl.pass` (researched same session, see
`jit_gl_pass_architecture.md`), which was investigated against a specific
named problem (f_stereogram's multipass need), **`jit.gl.asyncread` doesn't
map onto any existing gap in the f_ library.** Every current module — the
vecfield family, the discrete-item generators, the color/tone processors —
operates entirely in the GPU texture domain, consuming and producing
`jit.gl.texture`s through `jit.gl.pix`/`jit.gl.slab`. There's no module
today that needs CPU-side matrix analysis of a rendered frame.

Plausible future reasons this could become relevant (speculative, not
scoped or requested):
- Computer-vision-style analysis feeding back into a module's parameters
  (e.g. blob/color tracking driving a mod inlet) — this is the canonical
  use case in all the sources above, and it's the kind of thing a live
  performance system could conceivably want, but nothing in the current
  module inventory or HANDOFF backlog points at this.
- Exporting frame data out of the GPU pipeline for logging, OSC output, or
  external tooling that only understands Jitter matrices.
- Bridging into any future CPU-matrix-only Jitter object (comparable to
  `jit.findbounds`/`jit.3m`) that has no GPU equivalent.

**Recommendation:** hold this as a reference doc only. It answers "how does
this work" precisely, but there's no module or feature request this maps
onto right now, so there's nothing to build or to fold into
`vsynth-bpatcher`/`jit-gen-codebox` skill guidance yet. Worth asking what
prompted interest in it — if there's a concrete use case in mind (e.g.
audio/video-reactive tracking, external data export), that would change
this from "reference only" to something worth scoping properly.

## Open questions

- **Global Context compatibility in this Max 9 install** — untested here,
  but the forum thread above is specific enough (Max 9.1.4, the exact
  failure mode) to be worth checking preferences before ever patching this
  in, rather than debugging it as a mystery later.
- **`interleaved` vs `split` mode trade-off** — the one-frame-delay-vs-not
  distinction is documented, but what `split` costs in exchange isn't
  spelled out anywhere found. Untested.
- **What `@output_texture` actually refers to in the Max 9.1.4 workaround**
  — attached to `jit.gl.asyncread` itself, or to whatever feeds it (e.g.
  `jit.movie`/`jit.grab`, which do have their own `@output_texture`
  attribute for a different purpose)? Ambiguous in the source thread.
- **No concrete f_ use case identified** — this whole doc is "how it
  works," not "here's why we need it." See fit assessment above.
