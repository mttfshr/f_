# Web Shim Candidates

Running list of existing projects that could serve as a bridge — full
framework or just reference architecture — for getting `f_`/Vsynth-style
GPU visual synthesis running in a browser. Started 2026-08-04, prompted by
wanting to show demo patches on mattfisher.io. Not evaluated or scored yet —
just collecting real candidates before deciding on an approach.

**Correction, 2026-08-04 same session:** Max has this built in already —
`jit.gl.pix`/`jit.gen` codeboxes support direct **export to ISF** via the
`exportcode isf` message (`.fs` file output), in Max since v6.1.7 (2014).
`jit.gl.pix` export also explicitly supports two other targets: **JXS**
and **WebGL** — the WebGL target specifically has not been investigated
yet and may be a more direct path than going through ISF at all. This is
the load-bearing fact for the whole list below: the realistic port path
for `f_` modules starts from *Max's own export*, not from hand-translated
GLSL. Known friction from Max forum reports: ISF export param types are
limited to scalar/vec2/vec4 (float/point2D/color) — some of `f_`'s
multi-inlet mod-texture and `pix_chain` multi-stage patterns may not
survive export cleanly; min/max limits must be set explicitly pre-export
or ISF-side controls get unusable infinite ranges.

## Export mechanics, in detail (checked 2026-08-04)

`jit.gl.pix`/`jit.gen` codeboxes support **three separate `exportcode`
targets**, not one:

- **JXS** (`exportcode`, no argument) — Max's native shader interchange:
  GLSL wrapped in XML tags, loaded by `jit.gl.shader`/`jit.gl.slab`.
  Desktop-only — not directly browser-runnable, this is Jitter's internal
  format, relevant mainly as what the other two targets are derived from.
- **WebGL** (`exportcode webgl` — older docs call it `webjxs`) — exports a
  **complete standalone `.html` file**, built on **TWGL** (small WebGL
  helper lib), requires `twgl-full.min.js` alongside the exported file.
  This is the only target that produces something directly openable in a
  browser with no separate renderer needed — closer to "done" than ISF.
- **ISF** (`exportcode isf`) — `.fs` fragment shader for the ISF
  ecosystem (see above): scalar/vec2/vec4 params only, explicit min/max
  required pre-export.

**Known reliability problem, not resolved as of last check:** multiple
Max forum threads (2015, Max 7.0.4 → 2017+, Max 7.3.4) report
`exportcode jxs`/`webgl` silently producing broken output — missing/
unbound uniforms (`dim1` specifically named), exported file fails to load
in `jit.gl.slab`. Workaround people use: an undocumented `full_source_code`
message instead of `exportcode`. No confirmation this is fixed in current
Max 9 — needs to be tested directly, not assumed from the docs.

**Practical read:** WebGL export is the more direct path *if it actually
works* — skips ISF's param-type ceiling, hands back a running page
immediately instead of a shader fragment needing a host renderer. Given
the export mechanism's bug history, the concrete next step isn't
ISF-vs-WebGL — it's running `exportcode webgl` on one simple, already-
shipped `f_` module (single codebox, no `pix_chain`, no mod-texture
inlets — something like `f_droste` or `f_mobius`) and seeing whether it
produces a working page or lands in `full_source_code` workaround
territory.

## Shader interchange format (most relevant to porting `f_` codeboxes)

- **`jit.gl.isf` (Cycling '74 / Vidvox)** — https://github.com/vidvox/jit.gl.isf
  — free, open-source Max package. Two relevant halves: (1) plays ISF
  files inside Max via the `jit.gl.isf` object, 300+ bundled shaders; (2)
  `jit.gl.pix`/`jit.gen` patchers export directly to ISF (`exportcode isf`
  message → `.fs` file). This is the actual bridge — check first before
  building anything else.

- **ISF (Interactive Shader Format)** — https://github.com/Vidvox/isf,
  https://isf.video — GLSL fragment shader + JSON metadata describing
  inputs/params. Supports multi-pass rendering, persistent buffers
  (feedback), floating-point textures — structurally close to what
  `pix_chain`/`f_vf_advect`-style feedback modules need. Has a JS
  renderer (`interactive-shader-format-js`) for browser playback. Also
  used by VDMX, and has a Mac/Windows editor. **Worth a closer look
  first** — if `f_`'s codebox math can target ISF's parameter/pass model,
  that's a real interchange format, not just a one-off port, and gets
  Vidvox's existing web renderer for free.
- ISF reference shader library — https://github.com/Vidvox/ISF-Files —
  200+ existing ISF generators/filters, useful for seeing idiomatic
  ISF patterns before writing one from scratch.

### ISF web wrappers/renderers (checked 2026-08-04)

- **`interactive-shader-format-js`** —
  https://github.com/msfeldstein/interactive-shader-format-js, npm as
  `interactive-shader-format` — the actual JS renderer: `ISFRenderer`
  class (`loadSource`, `setValue`, `draw(canvas)` against a raw WebGL
  context) plus a standalone `ISFParser` (ISF → plain GLSL + input
  mapping — usable alone if only the parsed shader is needed, not the
  renderer). Small, simple API, this is the most direct "load an ISF
  file in a browser" option. **Caveat:** ~39 weekly npm downloads per
  Snyk, limited recent maintenance signal — functional but thin, not a
  heavily-trafficked project. A `modv`-specific fork exists
  (`interactive-shader-format-for-modv`), smaller still.
- **`editor.isf.video`** — https://editor.isf.video — full hosted
  browser-based ISF editor/community site: create, browse, remix ISF
  shaders directly; webcam/image/GIF as filter test sources;
  auto-generated UI per shader input; can preview individual render
  passes of multi-pass shaders. Not something to build on, but a useful
  first sanity check — paste an `f_`-exported `.fs` file in here to
  confirm it's well-formed ISF *before* writing any custom web embedding
  code, isolating "did Max's export work" from "does my own page work."
- **VVISF-GL / ISF Editor (desktop, not web, noted for reference)** —
  https://github.com/mrRay/VVISF-GL — the canonical open-source desktop
  editor (Mac/Win) bundling 200+ shaders, with a Shadertoy/GLSL-Sandbox
  importer. Same validation role as `editor.isf.video` but local/offline.

## Multi-pass / feedback GLSL rendering libraries (the plumbing layer)

These don't provide a patching UI — they're the JS layer under a
hand-written shader, roughly parallel to what `jit.gl.pix`/`pix_chain`
handles in Max.

- **shader-web-background** — https://github.com/xemantic/shader-web-background
  — Shadertoy-compatible, explicit support for ping-pong offscreen
  buffers, feedback loops, floating-point textures, WebGL1/2 fallback.
  Closest single-purpose match to what `f_vf_advect`/`f_vf_glow`-style
  temporal feedback modules would need.
- **glsl-canvas** — https://github.com/actarian/glsl-canvas — buffer
  chaining via `#ifdef BUFFER_N`, simpler/older, Shadertoy-adjacent.
- **regl** — (not directly surfaced this pass, known from prior
  knowledge) functional WebGL wrapper, popular for multi-pass GPGPU-style
  work; worth checking against feedback-loop needs specifically.
- **twigl** — https://twigl.app — live-coding shader editor, Shadertoy
  alternative, has a "Sound Shader" mode. Editor/prototyping tool more
  than a library to build on.

## Node-based / patching environments (closest UX analog to Max/Vsynth)

Not for the demo-patch port itself, necessarily, but relevant if a
patching-style authoring UI is ever wanted on the web side rather than
hand-written GLSL per demo.

- **Vynth** — https://github.com/jdillonh/Vynth — web-based visual
  programming environment for video synthesis, explicitly Max/MSP/Jitter-
  inspired, patches compile to GLSL fragment shaders via WebGL. Closest
  conceptual sibling to `f_` found so far — same lineage (analog video
  synth inspiration → node patching → GLSL). Worth a real look.
- **cables.gl** — node-based WebGL patching environment, engine open-source
  even though the main platform is a hosted service.
- **Hydra** — https://github.com/hydra-synth/hydra — live-coding video
  synth, analog-modular-inspired, browser-based, framebuffer
  mixing/compositing/streaming between browser instances. Code-first
  rather than patch-first, different authoring model than `f_` but same
  aesthetic lineage (explicitly analog-video-synth inspired).
- **Gibber** — https://github.com/gibber-cc/gibber — browser-based live-
  coding environment combining audio synthesis/sequencing *with*
  ray-marching 3D graphics (Three.js-based, shader support built in) in
  one coupled system, not separate audio/visual pipelines — notably
  parallel to `f_`'s own shape (`f_a_` audio prefix alongside the GL
  visual family). Code-first authoring, not patch-based. Actively
  maintained (v2.1.0, current deps, real recent commit activity) —
  healthier-looking than most of the shader-porting tools above.
  **Different category from everything else on this list**, worth
  flagging explicitly: this is a full authoring environment to write new
  work *in*, not a translation target for existing `f_` patches.
- **`gibberwocky.max`** — https://github.com/gibber-cc/gibberwocky.max —
  same org, a **live Max/MSP-side bridge to Gibber**. Not yet checked
  what it actually bridges (likely OSC/MIDI-style parameter/sequencing
  control, not GL texture streaming — needs verification) but the
  existence of *any* live Max↔browser link is notable: this is a
  fundamentally different model from every export path above (ISF/WebGL
  are static, one-time translations of a shader; a live bridge would let
  a running Max patch drive browser visuals in real time over the
  network instead). Given `f_`'s live-performance use (circular screen,
  shows), a live-bridge model may fit that use case better than a baked
  export ever could, even if it's a worse fit for showing static demo
  patches on mattfisher.io. Worth a closer look specifically to see what
  it actually carries across the bridge.
- **fsynth** — https://github.com/grz0zrg/fsynth — web-based pixel/canvas
  to audio synthesis (opposite direction — image drives sound, not sound/
  param driving image) but same WebGL2 float-precision feedback-buffer
  territory technically.

## The bridge idea: GLSL/ISF as shared intermediate, not a destination

**2026-08-04, later in session.** Reframing worth writing down: instead of
picking one JS destination framework (Gibber vs. Hydra vs. a plain page)
and porting each `f_` module to it individually, the more leveraged move
may be building the `f_` → JS bridge **once**, at the GLSL/ISF layer, and
letting each destination frame consume that shared layer on its own terms.

This isn't hypothetical plumbing — it's already how the ecosystem is
structured, because raw GLSL fragment shader source is the actual lowest
common denominator underneath nearly everything on this list:

- **Three.js** (which Gibber's graphics layer wraps) takes raw vertex/
  fragment GLSL + a uniforms object directly via `THREE.ShaderMaterial`
  (or `RawShaderMaterial` for a leaner path with no built-in
  uniforms/attributes). Confirmed via Three.js docs — this is a first-
  class, standard mechanism, not a workaround.
- Since Gibber wraps Three.js for its graphics/shader support (per its
  own repo description), it's plausible Gibber's shader-wrapping objects
  ultimately route through `ShaderMaterial` too — **not yet confirmed
  against Gibber's own API/docs**, this is inference from the Three.js
  dependency, not a checked fact. Real next step: find Gibber's actual
  shader-authoring API (something like the `Film()` object seen in a
  Gibber code sample) and see whether it accepts external GLSL source or
  only its own DSL.
- **regl**, **shader-web-background**, **glsl-canvas** are all thin JS
  scaffolding around a GLSL string + uniform bindings — same shape.
- **Hydra** is the likely odd one out: its primary authoring mode is a
  chained-function DSL (`osc().rotate().out()`) that *compiles to* GLSL
  internally, rather than a mode built around ingesting external raw
  GLSL. Whether it has any documented "inject your own shader" escape
  hatch is **unchecked** — needs verification before counting on it as a
  destination for this bridge.

**Why ISF specifically might be the right export shape for the bridge,**
not just "GLSL": ISF's JSON metadata block (typed/ranged/named param
declarations, multi-pass structure) is exactly the information any JS
adapter would otherwise have to hand-write or reverse-engineer per
module. `f_`'s existing `exportcode isf` path (see above) means that
metadata comes for free from Max on export — the bridge doesn't need to
invent a param-description format, it can reuse ISF's.

**Shape of the bridge, as currently imagined (untested):**

```
f_ jit.gl.pix codebox
  → exportcode isf (Max-native, already exists)
  → .fs file (GLSL + JSON param/pass metadata)
  → thin per-destination adapter:
      - plain web page: interactive-shader-format-js reads ISF natively
      - Three.js / Gibber: pull raw GLSL out, hand-map ISF JSON params
        to a ShaderMaterial uniforms object
      - Hydra: unknown fit, needs checking first
```

**What's unconfirmed and needs checking before this is more than an
idea:**
- Gibber's actual shader-authoring API — does it accept external GLSL,
  or only its own shader-object DSL?
- Hydra's capacity (if any) to ingest external GLSL/ISF rather than only
  its own function-chain syntax
- Whether ISF's param-type ceiling (scalar/vec2/vec4 only, per the export
  caveats above) survives being re-mapped into a `ShaderMaterial`
  uniforms object without further loss beyond what was already lost on
  the Max→ISF export step
- Whether this is worth building generically before even one single `f_`
  module has been round-tripped through *any* export path successfully
  (see "concrete next step" note above — still hasn't been done)

## Not yet checked, flagged for follow-up

- Whether ISF has any existing GenExpr-adjacent prior art (anyone having
  ported Jitter/`jit.gen` shaders to ISF before)
- vvvv / vvvv gamma web export options
- Whether TouchDesigner's GLSL TOP/MAT shader text (closer to raw GLSL
  than jit.gen) has better-documented porting paths that could inform the
  `f_` case even though TD itself isn't the target
- `regl` specifically for feedback-loop suitability, not just general use

## Non-goals for this list right now

- Not evaluating/scoring candidates yet
- Not picking an approach
- Not attempting a real port of any `f_` module yet

## Build-pipeline question, for after the first successful export

**2026-08-04, later still.** Once a real export (WebGL or ISF) is proven
working on a test module, a bigger question follows: should the export
format become part of the `f_` build pipeline itself, not a one-off
post-hoc export off a finished patch?

Concretely: `src/f_name/definition.py` + codebox `.gen` files are already
the canonical source of truth (`build_patcher.py` generates the `.maxpat`
from them — see main project plan/README). If ISF (or whatever format
proves out) became a **second build target of that same pipeline**, the
underlying question is whether the codebox math should be written from
the start in a GenExpr subset that's known to export cleanly, rather than
writing it freely and hoping export survives the translation after the
fact.

**Real costs on both sides, not yet weighed:**
- GenExpr already has real constraints/workarounds baked into the
  `jit-gen-codebox` skill (no `noise()`/`snoise()`, hand-rolled hash-based
  noise, no `PI`/`TWO_PI` built in, `fract()` unavailable, etc.) — some of
  these might vanish in a GLSL/ISF target (which has real `noise()`,
  real `fract()`), others might be replaced by new ISF-specific
  constraints (the scalar/vec2/vec4-only param ceiling already noted
  above).
- Writing "for the strictest common subset" from the start is a
  discipline cost on every future module, paid whether or not that
  module ever actually gets exported — only worth it if web export
  becomes a real, recurring target, not a one-off demo need.

**Explicitly not decided, not to be decided yet:** this is a downstream
question that only makes sense to answer once the concrete
`exportcode webgl`/`exportcode isf` test (see above) has actually run on
a real module and it's known what survives and what breaks. Deciding to
change the build pipeline's source-of-truth conventions before that
would be designing around an untested assumption.

## Also needed eventually, not now: GenExpr vs. GLSL language-differences doc

Flagged 2026-08-04, explicitly deferred. Once an export round-trip has
actually been tested, a real reference doc comparing GenExpr (`jit.gen`)
and GLSL/ISF as languages would be useful groundwork for the build-
pipeline question above — not just the export-mechanics facts already
in this file, but the language-level differences that would determine
what "write in a subset that exports cleanly" actually means in
practice. Likely shape: built-ins each has/lacks (`noise()`, `fract()`,
`PI`/`TWO_PI`, etc. — partial list already scattered through the
`jit-gen-codebox` skill for the GenExpr side), type system differences
(GenExpr is typeless, GLSL is not), control-flow/function differences,
param/uniform models. Not started. Do this after the concrete export
test, not before — no point comparing languages in the abstract before
knowing which specific constructs in real `f_` codeboxes actually failed
to survive export.
