# jit.gl.pass — Architecture Reference

_Created: 2026-07-01, tightened 2026-07-05_
_Status: Scratch-tested and confirmed (2026-07-01) — texture-only subpass
chains with zero 3D content DO work. Ultimately NOT used for f_stereogram/
f_sirds, which took a simpler plain forward jit.gl.pix chain instead (see
temporal_synthesis_architecture.md and intraframe_multipass_architecture.md).
Kept as reference for a future module that genuinely needs C74's built-in
pass effects (bloom, DOF, motion blur, etc.) or real 3D-scene compositing._

## What it is

`jit.gl.pass` loads a **JXP file** — an XML pass-description file — that
defines one or more render passes, each built from one or more
**subpasses**. Each subpass runs a shader: either a `.jxs` text shader or
a `.genjit` file (a saved `jit.gl.pix` Gen patcher — see below).

Per C74's docs, this object "works with intermediate render targets like
the depth buffer," explicitly contrasted with `jit.gl.slab`/`jit.gl.pix`
("simple video effects"). It always binds to a `jit.gl.node`. The
documented precondition — "geometry must have a material attached"
(`jit.gl.material`/`jit.gl.pbr`) — turned out to apply only to specific
subpass sources (`NORMALS`/`VELOCITY`/`ALBEDO`/`ROUGHMETAL`/`ENVIRONMENT`),
**not** to `TEXTURE0..N`/`PREVIOUS` sourcing, which is the part that
matters for pure 2D texture chaining (confirmed via scratch test, see
"Confirmed findings" below).

### The binding pattern

```
jit.gl.node <ctx> @capture 1        (or jit.world's internal node)
        |  (jit.gl.pass binds to this node by matching name)
        v
jit.gl.pass <ctx> @fxname bloom-hq  (or @file custom.jxp @fxname passname)
        |  outlet 0 = final texture, outlet 1 = chain to next pass
        v
jit.gl.pass <ctx> @fxname vignette  (chained via @child/@layer or outlet 1)
        |
        v
Vsynth's own display/output chain (jit.gl.layer not required — see below)
```

When bound to a node, the node's `@capture` attribute is controlled
automatically by the pass object.

### The JXP file format

```xml
<jitterpass>
  <pass fxname="passname">
    <bind name="amount" param="blendAmount" />
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

- `<pass fxname="...">` — confirmed via shipped C74 examples this is the
  correct attribute name for custom `@file`-loaded JXPs (user-guide prose
  examples show `name=`, but the real shipped examples and this project's
  own scratch test both used `fxname=` successfully).
- `<bind>` — exposes a shader parameter as a Max attribute on the
  `jit.gl.pass` object, analogous to `param` statements in a `jit.gl.pix`
  codebox.
- `<subpass>` — `file=` for a `.jxs` shader, `gen=` for a `.genjit`.
  Optional `output="COLOR"` (seen in shipped examples, not in user-guide
  prose) controls which render target a subpass writes to.

### Subpass input sources

| Source | Meaning |
|---|---|
| `source="COLOR"` | the bound node's RGBA color render target |
| `source="NORMALS"` / `"VELOCITY"` / `"ALBEDO"` / `"ROUGHMETAL"` / `"ENVIRONMENT"` | material/PBR-derived — **requires a material** |
| `source="PREVIOUS"` | the immediately preceding subpass's output — same-frame sequential dependency, no material required |
| `source="HISTORY"` | previous **frame's** output of the whole `<pass>` (temporal, not intra-frame) |
| `source="TEXTURE0"..."TEXTUREN"` | textures bound via the pass object's own `@texture` attribute list |
| `subpass="name"` | explicit named-subpass reference (equivalent to `SUBPASS0..N` by position) |

`PREVIOUS` and named-subpass referencing are exactly "pass N+1 reads pass
N's current-frame output" — the mechanism this doc originally went
looking for, confirmed real.

### Genjit files and the codebox workflow

A `.genjit` file is just what you get from a live `jit.gl.pix`'s Gen
window via File > Save As — the existing codebox-first development
practice is preserved. You'd still write and iterate on shader math live
in an ordinary `jit.gl.pix` codebox in a scratch patch; JXP-authoring only
happens after the codebox is verified, to package it into a subpass.

Custom JXPs must live in a package's `media/jitter/passes/` folder to be
reachable via `@fxname` alone, or be loaded via `@file` with an explicit
path otherwise (confirmed via C74 forum thread — stricter than ordinary
search-path loading).

Every Vsynth bpatcher's outlet already carries a `jit_gl_texture <n>`
message with an auto-generated unique name — feeding a Vsynth module's
output into `@texture` needs no intermediate naming step.

---

## Confirmed findings (scratch-tested 2026-07-01, `glpass-scratch.maxpat`)

1. **Texture-only, zero-3D-content subpass chains work.** A subpass
   sourcing `TEXTURE0` (fed via `@texture`, built at runtime from two
   Vsynth module outputs via `route jit_gl_texture` → `pack s s` →
   `prepend texture`) rendered a known-good shader (`cf.edgedetect.jxs`)
   correctly against a `jit.world` context with no
   `jit.gl.material`/`jit.gl.gridshape` or any 3D content present at all.
   Removing 3D content that had briefly been added as a positive control
   made no difference (confirmed by closing/reopening the patch, testing
   both ways).
2. **`PREVIOUS`/multi-subpass chaining works.** A two-subpass JXP
   (subpass 0 samples `TEXTURE0`; subpass 1 mixes `PREVIOUS` + `TEXTURE1`
   via a `.genjit`) rendered a clean 50/50 blend of two Vsynth source
   textures — visually confirmed, matching `mix(a, b, 0.5)` exactly.
3. **`jit.gl.layer` is not required for display.** `jit.gl.pass`'s outlet
   wired directly into Vsynth's own `CORNERPINS` display bpatcher works
   fine — meaning a `jit.gl.pass`-based module's output could feed
   straight into whatever Vsynth's normal display chain already is,
   rather than requiring an unfamiliar extra display object.

**Real bug hit along the way, worth remembering generally:** `jit.world`'s
`@enable` defaults to 0 — a bare `jit.world` never renders a frame without
`@enable 1` or an external bang. Produced identical black output across
every variable tested in one session (missing layer, bad `.genjit`
reference, the no-geometry test itself) — none of those were the actual
problem. Same category as the stale-`.maxpat`-reload gotcha documented
elsewhere in this repo: check the boring, easy-to-overlook setting before
trusting a "still broken" result as evidence about the real question.

---

## Why this ended up unused for f_stereogram/f_sirds

Confirming `jit.gl.pass` works for texture-only chaining resolved the
mechanism question, but two real costs remained unresolved when the
simpler plain-forward-chain approach (see
`intraframe_multipass_architecture.md`) turned out to make the whole
question moot:

1. **A structurally different bpatcher shape.** Every other f_ module is
   `jit.gl.pix vsynth` with ordinary inlet/outlet wiring. A `jit.gl.pass`
   module needs `jit.gl.node` binding, a JXP file alongside the `.maxpat`
   (not just the patch itself), and param exposure via `<bind>` instead
   of the `attrui`/`route` convention used everywhere else.
2. **`build_patcher.py` has no concept of a JXP file** — same category of
   gap as any multi-pix module, plus an additional file format to
   generate/maintain.

Neither was resolved because they didn't need to be — `f_sirds` shipped
using 13 plain chained `jit.gl.pix` objects, no `jit.gl.pass` anywhere.

## Where jit.gl.pass could be a strong fit — a genuinely separate idea

C74's built-in pass effects (`bloom-hq`, `vignette`, `grain`, `dof-hq`,
`motionblur-hq`, `tonemap`, `fxaa`, `ssao`, `taa`) are polished,
C74-maintained implementations that would otherwise be hand-rolled shader
work. These are candidates for **new** generator/processor modules built
around the pass/node pattern from scratch (e.g. `f_bloom`), not for
retrofitting into existing pix-based modules. Not scoped or requested —
flagged as a possible future exploration only.

## Open questions, if this is ever picked back up

- Whether `@fxname`'s package-folder requirement is workable for a
  distributed f_ module, or `@file` with a relative path is the only
  realistic option.
- Whether `<bind>`'s param-exposure mechanism can be made to feel
  consistent with the `attrui`/`route` convention used everywhere else in
  f_, or would read as a visibly different control surface.
