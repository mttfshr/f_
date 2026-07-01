# jit.gl.pass — Architecture Reference

_Created: 2026-07-01_
_Status: Sourced from Cycling '74 canonical documentation (Max 9 user guide
"Render Passes" + jit.gl.pass object reference + C74 tutorial article). Not
yet empirically tested in a scratch patch. Where this doc states something
as fact, it's from C74 documentation, not from a Max session — see "Open
questions" at the bottom for what still needs a real test._

## Relationship to the other two architecture docs

- `intraframe_multipass_architecture.md` — node+pix intra-frame chaining,
  written for f_stereogram, flagged `jit.gl.pass` as a "potentially simpler
  alternative" without having researched it. This doc is that research.
- `temporal_synthesis_architecture.md` — frame-to-frame feedback, a
  different problem (previous *frame's* output, not previous *pass's*
  output within the same frame).

**Bottom line up front:** `jit.gl.pass` is real and does have exactly the
`PREVIOUS`/`SUBPASSN` intra-frame chaining mechanism the multipass doc was
hoping for. But it is architecturally a **3D-scene post-processing system**,
not a general-purpose pix multipass tool — and it has a fundamentally
different authoring workflow (XML pass-description files, not just wiring
objects in a patcher). Whether it's actually a good fit for f_stereogram
specifically is not yet resolved — see "Fit assessment" below.

---

## What jit.gl.pass actually is

`jit.gl.pass` loads a **JXP file** — an XML pass-description file — that
defines one or more render passes, each built from one or more **subpasses**.
Each subpass runs a shader: either a `.jxs` text shader or a `.genjit` file
(a saved `jit.gl.pix` Gen patcher — see "Genjit files and the codebox
workflow" below).

Critically, per C74's docs: `jit.gl.pass` "works with intermediate render
targets like the depth buffer," which is **explicitly contrasted** with
`jit.gl.slab`/`jit.gl.pix`, described as working "as simple video effects."
`jit.gl.pass` always binds to a `jit.gl.node` (even the internal node inside
`jit.world`), and the documented precondition is: **"geometry must have a
material attached to it"** (`jit.gl.material` or `jit.gl.pbr`) for
`jit.gl.pass` to work at all.

This is the single most important framing fact: the built-in pass effects
(bloom, motion blur, SSAO, depth of field, TAA, tonemap, etc.) are all
**3D-scene post-processing effects**. They exist to take a rendered 3D scene
plus its auxiliary buffers (depth, normals, velocity, material properties)
and process those into a final image. This is a different problem than
"chain several 2D texture-processing passes together," even though the
subpass mechanism *could* express the latter.

### The binding pattern

```
jit.gl.node <ctx> @capture 1        (or jit.world's internal node)
        |
        | (jit.gl.pass binds to this node by matching name)
        v
jit.gl.pass <ctx> @fxname bloom-hq  (or @file custom.jxp @fxname passname)
        |
        | outlet 0 = final texture, outlet 1 = chain to next pass, outlet 2 = dumpout
        v
jit.gl.pass <ctx> @fxname vignette  (chained via @child attribute or outlet 1)
        |
        v
jit.gl.layer                        (displays final texture in root context)
```

When a `jit.gl.pass` is bound to a node, **the node's `@capture` attribute is
controlled automatically** by the pass object — it sets capture on to
whatever render targets (color/depth/normals/velocity) the bound pass
effects require. You don't set `@capture` yourself in this pattern.

Multiple `jit.gl.pass` objects chain via the documented `@child`/`@layer`
attribute pair (an alternative to literally patching outlet-to-inlet, useful
across patcher levels) — this is the same `@layer` mechanism already
confirmed sound in `intraframe_multipass_architecture.md` for node ordering,
now also documented as the pass-chaining mechanism specifically.

### The JXP file format

```xml
<jitterpass>
  <pass name="passname">
    <bind name="amount" param="blendAmount" />   <!-- optional: expose shader param as Max attribute -->
    <inputs>
      <input source="COLOR" type="char" erase_color="0 0 0 1" />
    </inputs>
    <subpass file="cf.radialblur.jxs" name="blur_pass">
      <input source="COLOR" />
    </subpass>
    <subpass gen="kaleido.genjit">
      <input subpass="blur_pass" />
    </subpass>
  </pass>
</jitterpass>
```

- `<pass name="...">` — one JXP file can define several named passes;
  `@fxname` selects which one to load. Built-in fxnames only resolve from a
  package's `media/jitter/passes/` folder; custom JXPs need `@file` pointing
  at the file (search-path or absolute), then `@fxname` to pick the pass
  inside it if it defines more than one.
- `<bind>` — exposes a shader parameter as a Max attribute on the
  `jit.gl.pass` object itself (this is how `attrui`-style param control
  would work for a custom pass, analogous to `param` statements in a
  `jit.gl.pix` codebox).
- `<inputs>` — pass-level render-target config (shared across all subpasses
  in that pass — e.g. inverting depth clear value).
- `<subpass>` — one shader stage. `file=` for a `.jxs` shader, `gen=` for a
  `.genjit` (compiled `jit.gl.pix` Gen patcher). Optional `name=` lets other
  subpasses reference it. Optional `dimscale` (resize output) and `rect`
  (remap/flip UV) — same concepts as `jit.gl.pix` attributes.

### Subpass input sources — the actual multipass mechanism

This is the part that matters for f_stereogram-style chaining. A
`<subpass>`'s `<input>` tag can reference:

| Source | Meaning |
|---|---|
| `name="X"` | a named texture (e.g. fed via the pass's `@texture` attribute list) |
| `source="COLOR"` | the bound node's RGBA color render target |
| `source="NORMALS"` | normals in RGB, depth in A — **requires material** |
| `source="VELOCITY"` | per-pixel motion vectors — **requires material** |
| `source="PREVIOUS"` | **the immediately preceding subpass's output** — this is the same-frame sequential-dependency mechanism |
| `source="HISTORY"` | the previous **frame's** output of the whole `<pass>` (temporal, not intra-frame — same category as `temporal_synthesis_architecture.md`, not this doc) |
| `source="TEXTURE0"…"TEXTUREN"` | textures bound to the pass object's own `@texture` attribute list, addressed by list position |
| `subpass="name"` | explicit reference to any named subpass by name (equivalent to `SUBPASS0…N` by position) |
| `source="ALBEDO"`, `"ROUGHMETAL"`, `"ENVIRONMENT"` | material/PBR-derived — **requires material** |

`PREVIOUS` and named-`subpass`/`SUBPASSN` referencing are exactly the
"pass N+1 reads pass N's current-frame output" pattern the intraframe
multipass doc was trying to hand-build with separate `jit.gl.node` objects.
Within a single `jit.gl.pass`'s subpass chain, this is native and doesn't
need the node-per-pass workaround at all.

### Genjit files and the codebox workflow

Important compatibility note: a `.genjit` file is not a foreign format —
it's literally what you get from opening a live `jit.gl.pix` object's Gen
window and doing **File > Save As**. The C74 tutorial confirms the same
mechanism used elsewhere in Max: `jit.gl.pix @gen <name>` loads a saved
Gen patcher by name instead of holding it inline. This means the existing
**codebox-first development practice is preserved** — you'd still write and
iterate on the strip-displacement math live in an ordinary `jit.gl.pix`
codebox in a scratch patch, exactly as today. The JXP-authoring step only
happens *after* the codebox is verified, to package the finished shader into
a subpass. It's an extra packaging step at the end, not a different way of
writing shader code.

Custom JXP files must live in a package's `media/jitter/passes/` folder to
be reachable via `@fxname`, or be loaded via `@file` with an explicit path
otherwise (confirmed via forum thread with C74 staff — file-location
handling in the pass system is stricter than ordinary `.jxs`/search-path
loading).

---

## Grounded against real examples (2026-07-01)

C74's own example patches are not installed by default — not in the Max
app bundle, not in any installed Package. They live in
`~/Library/Application Support/Cycling '74/Max 9/Examples/jitter-examples/
render/mrt/` (found via Spotlight, not bundled with a Package). Reading
the real files there confirms most of the above but also surfaces two
real discrepancies against the user-guide prose, plus one significant gap:

- **`pass.custom.effects.maxpat`'s actual shipped JXP uses `<pass
  fxname="edge">`, not `<pass name="edge">`** as the user guide's prose
  examples show. This patch is stamped Max 8.2.0 — could be a version
  difference, could be that both work, could be that only one does.
  **Untested which is correct for Max 9.**
- The same example's final subpass uses an **`output="COLOR"`** attribute
  (`<subpass file="co.multiply.jxs" output="COLOR">`) that isn't mentioned
  anywhere in the user-guide prose covered above — controls which render
  target a subpass writes its result to.
- **Confirmed good news:** the workflow really is live-editable, same
  shape as `jit.gl.pix`'s `.genjit` pattern. Double-click the `jit.gl.pass`
  object to open a text editor, type/paste the JXP XML, then File > Save
  As to export a `.jxp`. Not a separate hand-authoring-in-Xcode process.
- **The gap:** searched the entire example folder (8 `pass.*.maxpat`
  files, all the JXP text they contain) for `TEXTURE0`/`@texture` usage.
  The only hit anywhere is the documentation comment describing the
  mechanism in the abstract — **no shipped C74 example actually
  demonstrates a texture-only, no-3D-scene subpass chain.** Every real
  `.jxp` in the examples sources from `COLOR`/`NORMALS`/scene content, tied
  to an actual 3D scene (models, gridshapes, lights, materials) in every
  single example patch. This doesn't mean the texture-only pattern doesn't
  work — but it means we're testing genuinely unexplored territory in this
  environment, not just filling a documentation gap with something everyone
  already knows works.

**Confirmed (2026-07-01, via screenshot of a live Vsynth module):** every
Vsynth bpatcher's outlet already carries a `jit_gl_texture <name>` message
with an auto-generated unique name (e.g. `u118011937`) — there's an
internal `jit.gl.texture` object per module already. This means feeding a
Vsynth module's output into `jit.gl.pass`'s `@texture` attribute list (for
`TEXTURE0..N` addressing) needs no intermediate naming step — the module
outlet can wire straight into the `@texture` inlet or a `texture` message,
same as wiring it into any other Vsynth `vs_op2`-style inlet.

## Fit assessment for f_stereogram — CONFIRMED (2026-07-01, scratch tested)

**Resolved via scratch patch in this Max 9 install (`glpass-scratch.maxpat`,
`/Users/matt/Vsynth/patterns/`).** `jit.gl.pass` renders correctly against a
`jit.world` context with **zero 3D geometry** — a single subpass sourcing
`TEXTURE0` (fed via `jit.gl.pass`'s own `@texture` attribute, built at
runtime from two Vsynth module outputs via `route jit_gl_texture` → `pack`
→ `prepend texture`) rendered a known-good shader (`cf.edgedetect.jxs`)
correctly with no `jit.gl.material`/`jit.gl.gridshape` or any other 3D
content present in the context at all. Removing the 3D content that had
briefly been added as a positive control made **no difference** to the
result — confirmed by closing and reopening the patch and testing both
with and without it. The "geometry must have a material attached" language
in the C74 docs applies specifically to the `NORMALS`/`VELOCITY`/`ALBEDO`/
`ROUGHMETAL`/`ENVIRONMENT` sources, not to `jit.gl.pass`/`TEXTURE0..N`
usage in general.

**Real bug hit along the way, worth remembering on its own:** `jit.world`'s
`@enable` attribute defaults to 0 (confirmed in the local maxref — "Enable
automatic rendering (default = 0)"). A bare `jit.world` object never
renders a single frame without either `@enable 1` or an external bang.
This produced black output identically across every variable tested that
session (missing `jit.gl.layer`, context ambiguity, bad `.genjit`
reference, known-good shader, no-geometry test) — none of those were
actually the problem; the window had simply never rendered at all. Same
category of gotcha as the stale-`.maxpat`-reload issue already documented
in HANDOFF.md: check the boring, easy-to-overlook thing before trusting a
"still broken" result as evidence about the actual question being tested.

**Simplification found (2026-07-01):** `jit.gl.layer` isn't actually
necessary for display — `jit.gl.pass`'s outlet wired directly into
Vsynth's own `CORNERPINS` display bpatcher works fine, confirmed visually
(both the `testworld` window and a second Vsynth-native preview window
showed the identical mixed result). This is a better fit for f_ generally
than `jit.gl.layer` would have been anyway — it means a `jit.gl.pass`
module's output texture can feed straight into whatever Vsynth's normal
display/output chain already is, the same as any other module's texture
output, rather than introducing an unfamiliar display object as a
required extra step.

**What's now confirmed:**
1. Texture-only, no-3D-scene subpasses work — the single highest-priority
   open question from the original fit assessment.
2. The `@fxname`-on-object + `fxname=`-on-`<pass>`-tag pairing works
   (tested via variant B/D `.jxp` files) — the `name=`/`fxname=`
   discrepancy noted earlier resolves in favor of `fxname=` for custom
   `@file`-loaded JXPs, at least in this Max 9 install.
3. `route jit_gl_texture` → `pack s s` → `prepend texture` is a working,
   general pattern for feeding any two dynamically-named Vsynth module
   outputs into `jit.gl.pass`'s `@texture` attribute at runtime.

**Not yet tested:** ~~the actual `PREVIOUS`/multi-subpass chaining~~ —
**RESOLVED, same session.** `jit_gl_pass_scratch_B_fxname.jxp` (two
subpasses: subpass 0 samples `TEXTURE0`, subpass 1 mixes `PREVIOUS` +
`TEXTURE1` via `mix_test.genjit`) loaded and rendered correctly against
`testworld` — a clean 50/50 blend of the two Vsynth source textures,
visually confirmed (circle over bars, both at partial opacity, exactly
matching `mix(sample(in1,norm), sample(in2,norm), 0.5)`). **Both halves of
the core mechanism question are now confirmed via direct observation, not
inference:** no 3D content required, and same-frame sequential dependency
across subpasses via `PREVIOUS` works as documented.

**What's still unresolved from the original fit assessment** (points 2-3
below, from before this test):

**What's attractive:** `PREVIOUS`/named-subpass chaining is precisely
"sequential passes with same-frame dependency," which is the strip
algorithm's core requirement, and it's a first-class documented mechanism
rather than something to reverse-engineer from node/layer ordering.

**What's unresolved and could still complicate this path:**

1. ~~Does a subpass chain actually need 3D geometry+material to function at
   all~~ — **RESOLVED above: no, it doesn't**, for `TEXTURE0..N`/`PREVIOUS`
   sourcing. Confirmed via scratch test, not just inference.

2. **Integration with Vsynth's signal-chain conventions.** Every other f_
   module is a `jit.gl.pix vsynth` object (or chain of them) with ordinary
   inlet/outlet texture wiring, matching Vsynth's `vs_inState`/passthrough
   conventions. A `jit.gl.pass`-based module would need `jit.gl.node`
   binding, a JXP file living alongside the module (not just a `.maxpat`),
   and the pass's own attribute/param exposure via `<bind>` instead of the
   `attrui`/`route`/`set` param-dispatch pattern used everywhere else. This
   is a structurally different bpatcher shape, not a drop-in replacement —
   `vsynth-bpatcher` skill conventions would need real extension, not a
   tweak, if this path is taken.

3. **`build_patcher.py` fit.** Already flagged as unresolved in the
   intraframe multipass doc for the node-chain approach — a
   `jit.gl.pass`-based module has the same problem (current schema assumes
   one `jit.gl.pix` per module) plus an additional JXP file to generate/
   maintain, which `definition.py` has no concept of at all.

**Net assessment:** `jit.gl.pass` is a real, sourced answer to "does Max
have a native same-frame multi-subpass mechanism" (yes), which corrects the
uncertainty in the multipass doc. But it comes with real architectural cost
— a different bpatcher shape, an extra file format, and an unverified
dependency on 3D scene/material content that could make it a poor fit for a
pure 2D texture-processing module like f_stereogram. **It should not be
treated as a lighter-weight alternative to the node-chain approach without
testing #1 above first** — if a scene/material really is required, the
node-chain approach (or the still-untested plain pix-to-pix wire, which
remains the cheapest thing to test first per HANDOFF.md) may end up simpler
for this specific module even though `jit.gl.pass` is the more
"official"-feeling tool.

---

## Where jit.gl.pass could be a strong fit elsewhere in f_ (separate from stereogram)

Independent of f_stereogram, the built-in pass effects (`bloom-hq`,
`vignette`, `grain`, `dof-hq`, `motionblur-hq`, `tonemap`, `fxaa`, `ssao`,
`taa`, etc.) are polished, C74-maintained implementations of things that
would otherwise be hand-rolled shader work. These are **candidates for new
generator/processor modules in their own right** (e.g. a
`f_bloom`/`f_vignette` wrapper), not for retrofitting into existing pix-based
modules — same reasoning as above: it's a different bpatcher shape, so this
would be new modules built around the pass/node/layer pattern from scratch,
not an extension mechanism for f_grain/f_weave/etc.

This is a separate, smaller-scope idea from the f_stereogram question and
not assessed further here — flagging as a possible future exploration.

---

## Open questions (need a scratch-patch test before any of this is trusted for building)

- **Highest priority:** can a `jit.gl.pass` subpass chain run against a
  `jit.gl.node` with no 3D scene content, using only `TEXTURE0`/`TEXTURE1`
  (via `@texture`) and `PREVIOUS`/named-subpass sourcing? This is the
  question that determines whether `jit.gl.pass` is even viable for
  f_stereogram.
- Whether `@fxname`'s package-folder requirement (`media/jitter/passes/`)
  is workable for a released f_ module, or whether `@file` with a path
  relative to the module's own folder is the only realistic option for a
  distributed package.
- Whether the `<bind>` param-exposure mechanism can be made to look/feel
  consistent with the `attrui`/`route` param convention used everywhere
  else in f_, or whether it would read as a visibly different control
  surface to a performer switching between modules live.
- Not yet tested at all in a Max 9 session — everything above is sourced
  from C74 documentation and one tutorial article, not from empirical use
  in this environment. Per house practice, none of this should be treated
  as settled until it's been through a scratch patch.

**Recommended next step, if this is pursued at all:** a minimal isolated
test — bind a `jit.gl.pass` to an empty (no scene content) `jit.gl.node`,
feed it two plain textures via `@texture`, write a trivial two-subpass JXP
(`subpass 0` reads `TEXTURE0`, `subpass 1` reads `PREVIOUS` and `TEXTURE1`
and mixes them) — before touching f_stereogram's scratch patch with it.
This directly answers open question #1 and is cheap to build.
