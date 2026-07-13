---
name: vsynth-bpatcher
description: Conventions and checklist for building f_ Vsynth bpatchers in Max. Use when creating or editing a patcher in /Users/matt/Github/f_/package/patchers/. Covers file structure, signal flow pattern, parameter wiring, UI styling, codebox writing workflow, and the required objects every patcher must have.
---

# Vsynth Bpatcher Skill

Conventions for building `f_` utility bpatchers — visual processing modules for [Vsynth](https://www.kevinkripper.com/vsynth) in Max 9.

**Repo:** `/Users/matt/Github/f_`
**Vsynth package:** `/Users/matt/Documents/Max 9/Packages/Vsynth`

Patches are generated from definition files via `build/build_patcher.py` — not hand-built from a template. The schema for definition files is in `build/spec.md`. This SKILL.md is the authoritative source of structural conventions; individual patcher files are outputs, not references.

The repo splits build scripts into two directories: `build/` is the general, reusable build system (`build_patcher.py`, `extract_params.py`, `generate_helpfiles.py`, `audit_interface.py`, `migrate_to_attrui.py`, `spec.md`) meant to be presentable to other Vsynth module authors; `tools/` holds one-off, module-specific scripts (e.g. `tools/masonry/`, `tools/build_texrouter.py`) kept for reference, not permanent infrastructure. When writing a new general-purpose build utility, it belongs in `build/`; a surgical one-time fix for a single patcher belongs in `tools/`.

---

## Vsynth Reference Documentation

Systematic analysis of Vsynth internals is documented in the f_ repo:

```
/Users/matt/Github/f_/docs/vsynth-reference/
  module-inventory.md   — every Vsynth module: tier, inlets/outlets, notes
  patterns.md           — Kevin's recurring architectural patterns
  vocabulary.md         — named abstractions, sends/receives, conventions
```

Consult these before designing a new f_ patch: capability map (what Vsynth already provides), pattern library (how Kevin solves common problems), vocabulary (what specific terms and objects mean).

---

## File Locations

```
/Users/matt/Github/f_/package/patchers/   — production f_ bpatchers (version controlled)
/Users/matt/Vsynth/patterns/              — experiments and signal flow scratch (not version controlled)
```

`patterns/` is where you develop and understand a signal flow. Once stable and reusable, it becomes an `f_` bpatcher in `package/patchers/`. Never put one-off performance files or experiments in the repo.

### Scratch patch GL context requirement

Scratch patches that use any `vsynth`-context GL object (`jit.gl.pix`, `jit.gl.asyncread`, `jit.gl.texture`, `jit.gl.slab`, etc.) require the **`vs_render` bpatcher** to be present and running — not the bare `vs_render` object. The bpatcher initializes the full Vsynth GL context including `jit.gl.render`, context naming, and qmetro. Without it, GL objects silently fail or output black.

Always include in scratch patches:
- `vs_render` bpatcher (from Vsynth package, `patchers/vs_render.maxpat`)
- A toggle wired to its inlet to start the render clock

### Scratch patch starting point: `scratch_template.maxpat`

`/Users/matt/Vsynth/patterns/scratch_template.maxpat` is the canonical starting
shell for new scratch work. Clone it (copy + rename) rather than building a
scratch patch from scratch each time, and rather than Claude generating raw
`.maxpat` JSON for a new scratch shell — Claude has no verified template for
hand-building a gen-subpatcher-with-codebox from inference, and getting that
JSON subtly wrong (inlet/outlet ordering, numinlets mismatches) costs more
debugging time than it saves. Matt builds/clones scratch shells in Max
directly; Claude provides codebox text to paste in (see "Codebox Writing
Workflow" above).

Contents of the template:
- `vs_modules` (module menu, for spawning test/source bpatchers) and
  `vs_render` (GL context — required, see above)
- `vs_wfg_3` pre-wired into `jit.gl.pix` `in1`, as a default test source
- A two-inlet `jit.gl.pix` containing a gen subpatcher with `in 1`, `in 2`,
  a `codebox` object (default content `out1 = in1 + in2;`, replace this),
  and `out 1` — `in 1`→codebox inlet 0, `in 2`→codebox inlet 1, codebox
  out→`out 1`
- `vs_output` wired to the pix's outlet, for final display

**To adapt for a new module's scratch session:**
- Add/remove `in N` objects in the gen subpatcher and `inN` references in
  the codebox to match the inlet count needed (see "Inlet count on
  jit.gl.pix" in the jit-gen-codebox skill for the three-things-must-be-true
  rule)
- Add a second `out N` + `outN` codebox assignment if a debug/isolated
  outlet is needed (e.g. f_magic_eye's period-field visualization)
- Swap or add source bpatchers (`vs_wfg_3`, `vs_noise_3`, `f_stipple`,
  `f_grain`, etc.) feeding the additional inlets as appropriate to what's
  being tested
- Add a `vs_preview` bpatcher per extra outlet that needs its own viewable
  window (the template's single `vs_output` only displays one texture
  stream at a time)

### Debugging "no output at all" — check the wire before the math

If `vs_render` is confirmed running (fps reads a real number, not 0) and
the console is clean, but nothing appears in the Vsynth output window,
**visually verify the pix's outlet is actually wired to the output chain
(`vs_output`/`CORNERPINS`) before suspecting the codebox math.** A codebox
object placed in Max can visually overlap the connection point below it,
hiding a missing or disconnected wire from the outlet — the patch looks
wired at a glance but isn't. Drag the codebox object aside (or check the
patcher JSON directly) to confirm the actual connection exists, rather
than assuming a rendering-pipeline issue (missing `VISIBLE`/`PREW` toggle,
wrong `@drawto` context, etc.) or a math bug in the codebox itself.
Empirically hit 2026-07-08 on `f_apollonian`'s first scratch test — the
codebox visually covered a missing outlet wire, and appeared correctly
wired at a glance.

---

## The One-Sentence Mental Model

A Vsynth bpatcher accepts one or more texture inlets, draws to the `vsynth` GL context, and passes a texture outlet back out. **Vsynth owns render tempo and cornerpins routing** — the bpatcher never touches `qmetro`, `jit.pwindow`, or `vs_render`. The bpatcher just draws and passes through.

---

## Design Principle: Texture Inlets as Structural Modulation Sources

The most powerful use of a texture inlet is modulating a *structural* parameter — one that controls geometry, phase, or selection — rather than appearance directly. Driving color with a texture is blending. Driving phase, frequency, angle, or threshold with a texture produces spatially-varying, temporally-coherent complexity that scalar parameters cannot achieve.

This is the established Vsynth pattern (WFGs, displacement modules) and should be considered during ideation for any f_ patch with periodic structure, geometric transforms, or selection/gating behavior. Ask: *which parameter, if spatially varied, would produce disproportionate visual complexity?* That parameter is the texture inlet candidate.

---

## Translating Reference Shaders/Algorithms — Reread Before Characterizing

When a module is based on an external reference (shadertoy source, a paper,
another shader), **always reread the actual saved reference file in full
before characterizing what it does or proposing a change based on that
characterization** — especially before proposing an architecture pivot.
Do not rely on a prior session's summary, `HANDOFF.md`'s language, or your
own earlier restatement of the reference, even if it sounds familiar or
matches a known named concept (e.g. "this looks like Descartes' Circle
Theorem"). Pattern-matching a verbal description to a known algorithm is
not the same as checking what the saved source actually does — the two
can diverge, and confidently asserting the pattern-matched version instead
of the actual one has produced real, corrected-in-session mistakes on
`f_apollonian` (2026-07-09: incorrectly claimed the reference used explicit
Descartes-theorem circle construction, when the saved reference source is
actually the same iterated-inversion/escape-time method already in use —
the real gap was a missing accumulated-transform step, not a different
algorithm family). If you catch yourself naming a concept without having
just reread the source in this session, stop and reread it first.

---

## Codebox Writing Workflow

**Write codebox content as plain text, paste manually into Max.**

This is the most token-efficient approach:
- Claude writes the codebox code as a fenced text block
- Matt pastes it into the codebox in Max
- Verify the math works before building the wrapper JSON
- Only write the full `definition.py` and run `build_patcher.py` when the codebox is confirmed working

---
## Package Structure

```
f_/
  package/     — the installable Max package (this alone is what Max needs)
    patchers/    — all bpatcher .maxpat files (source of truth)
    javascript/  — JS files (on Max search path)
    help/        — .maxhelp files, generated via build/generate_helpfiles.py
    package-info.json
  docs/        — as-built reference docs for working bpatchers + vsynth-reference/ analysis docs
  ideas/       — planned and half-formed bpatchers
    scratchpad.md       — low-friction idea dump, no structure required
    f_<name>.md         — specced but not yet built
  build/       — official build system (version controlled, presentable to other authors)
    build_patcher.py    — generates .maxpat from a definition file (see build/spec.md)
    spec.md             — build script spec
    extract_params.py, generate_helpfiles.py, audit_interface.py, migrate_to_attrui.py
  tools/       — one-off / module-specific scripts (version controlled, not build infra)
    masonry/, util_profile/, build_texrouter.py, etc.
  skills/      — Claude skills for collaborating on this repo (copies of the source
                 skills in claude-scaffold; this file's copy lives here)
  .specify/    — planning workspace (version controlled — no longer gitignored)
    constitution.md
    f_<name>/           — one dir per bpatcher under active development
      spec.md           — what it does and how you know it's working
      plan.md           — ADRs, blocks, phases (added when build begins)
      tasks.md          — flat task list, session anchor (added when build begins)
      definition.py     — patcher definition: codebox + params + archetype (added at end of Phase 2)
  HANDOFF.md   — session notes (ephemeral; written fresh each session)
  README.md    — permanent project state: bpatcher status table, build queue
```

- File naming: `f_<name>.maxpat`
- JS files referenced by filename only — Max finds via search path
- Every patcher: `"openinpresentation": 1`

### Naming Convention: f_vf_ prefix for vecfield producers

Bpatchers whose **primary output is an f_vecfield texture** (float32, RG=XY, 0.5=zero vector) use the `f_vf_` prefix rather than `f_`. This signals to users that the output is a specialized texture consumed by specific downstream modules (f_caustic, f_lens field inlet) rather than a standard Vsynth char texture.

Current f_vf_ family (float32 `f_vecfield` producers/consumers — see README's patch table for full descriptions):
- Producers: `f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_flow`, `f_vf_fieldmap`, `f_vf_repulse`
- Processors (consume + re-emit a vecfield): `f_vf_potential`, `f_vf_warp`, `f_vf_streak`, `f_vf_advect`, `f_vf_glow`, `f_vf_chroma`, `f_vf_prism`
- Utility: `f_vf_split` (splits X/Y channels to greyscale, does not re-emit a vecfield)
- Also consumes a vecfield without the prefix: `f_caustic`, `f_lens` (field inlet), `f_vf_seeds` (shape/mod tex inlets)
- `f_vf_vorticity` exists as a built module but is explicitly **not confirmed working** — do not treat it as shipped (see HANDOFF.md)

The type contract is in `docs/f_vecfield_type.md`. User-facing disambiguation (UI badge on each producer, helpfile explanation) reinforces the distinction without requiring users to memorize the prefix meaning.

## Bpatcher Lifecycle

Each bpatcher moves through three stages:

**1. `ideas/scratchpad.md`** — half-formed idea, no structure required. Drop it here to avoid losing it.

**2. `ideas/f_name.md`** — graduated from scratchpad when the idea has a concept, rough parameter contract, and known open questions. Not yet built. Create this file before opening Max.

**3. `docs/f_name.md`** — as-built reference. Bpatcher is working and confirmed. Documents params, signal chain, usage, and known issues as they actually exist. Nothing lives in `docs/` that isn't working.

### Planning Workflow

- **`ideas/f_name.md`** — spec for a planned bpatcher: concept, parameter contract, open questions. Lives here until the build begins.
- **`.specify/f_name/spec.md`** — what the bpatcher does and how you know it's working. Written before touching Max.
- **`.specify/f_name/plan.md`** — ADRs, dependency blocks, implementation phases. Added when build begins.
- **`.specify/f_name/tasks.md`** — flat ordered task list; the session anchor for this build. Added when build begins.
- **`.specify/f_name/definition.py`** — patcher definition file: confirmed codebox + full param contract + archetype. Written at end of Phase 2 (codebox confirmed). Input to `build/build_patcher.py`. See `build/spec.md` for schema.
- **`docs/f_name.md`** — as-built reference. Updated when the bpatcher changes, not during planning.

**At session end, update all three:**
1. **`.specify/f_name/tasks.md`** — mark done, add new items, reorder
2. **`README.md`** — permanent project state: bpatcher status table, build queue
3. **`HANDOFF.md`** — session notes only: what was done, what's next, loose threads

`HANDOFF.md` is written fresh each session — do not put permanent project state there. `README.md` is maintained continuously.

---
## Required Objects (Every Patcher)

1. **`jit.gl.pix vsynth @name <prefix>_pix`** — shader core, draws to vsynth context
2. **`routepass jit_gl_texture jit_matrix`** — peels texture from inlet; unmatched outlet goes to `route`
3. **`route <param1> <param2> ...`** — named control message dispatch for all params except bypass
4. **`bypass_toggle.js` (jsui)** — custom bypass UI; wired directly through attrui to pix, not through route
5. **`live.dial`** per float param — with `parameter_enable`, `varname`
6. **`attrui`** per param — sits between dial and pix in0; `attr` key names the target param
7. **Title comment** — in presentation layer, Ableton Sans Light
8. **Background panel** — black with blue border in presentation
9. **Texture inlet** (`inlet`, comment "texture in") → `routepass`
10. **Texture outlet** (`outlet`, comment "texture out") ← pix out0
11. **`moduleSize.js` chain** — for Vsynth module sizing (see below)
12. **`parameters` block** at end of JSON — registers all params
13. **`autopattr @varname <prefix>_autopattr`** — state save/restore (use in all patchers)

---

## Two Patcher Archetypes

### Processor (texture in → texture out)

Requires an upstream texture. Has no self-generated content — meaningful only when something is wired to inlet 0. Bypass passes the input texture through unmodified.

```
bpatcher in0 → routepass jit_gl_texture jit_matrix → pix in0   [texture]
               routepass out2 (unmatched)           → route      [control]
```

Inside gen: `in 1` → codebox inlet 0, `out 1` ← codebox outlet 0.

Codebox bypass: `out1 = mix(effect_out, sample(in1, norm), bypass);`

Examples: `f_lens`, `f_droste`, `f_luma_processor`, `f_channel_grader`.

---

### Dual-Mode Generator (self-generating, optionally uses upstream texture)

The default archetype for any f_ patch that produces its own content. Uses `vs_inState` on inlet 0:

- **Unconnected** — `vs_black` fallback keeps the patch drawing. Codebox generates content from its own parameters. Bypass outputs black.
- **Connected** — upstream texture available in the codebox. Use it as a modulation source, a luma gate, a color source, or process it directly. Bypass passes input through.

This is the correct pattern for f_ generators. The old "source requires a render-trigger texture" model was a workaround — `vs_inState` with `vs_black` fallback is the right solution. Kevin's native source modules (vs_sources/) use no texture inlet at all because they live at the top of the Vsynth signal chain and are driven directly by the render clock; f_ bpatchers sitting inside that chain need `vs_inState`/`vs_black` to participate in the draw cycle when unconnected.

```
bpatcher in0 → routepass jit_gl_texture jit_matrix
               routepass out0 (texture) → vs_inState in0
                 vs_inState out0 (texture or vs_black) → pix in0
                 vs_inState out1 (0/1 int)             → prepend param src_mode → pix in0
               routepass out2 (unmatched)              → route      [control]
```

`src_mode` is a hidden codebox Param (0 = unconnected/generator, 1 = connected/processor) — **absent from UI, `route`, and `parameters` block**.

```glsl
Param src_mode(0.0);
Param bypass(0.0);

// ... generate content ...
generated = /* patch's own synthesis */;

// If connected, upstream texture is available as sample(in1, norm)
// Use it for modulation, gating, color, or full processing

// Bypass: output black in generator mode, pass through in processor mode
out1 = mix(result, mix(vec(0,0,0,1), sample(in1, norm), step(0.5, src_mode)), bypass);
```

Gen subpatcher: `in 1` → codebox inlet 0 (texture or vs_black). Add `r dim` to inlet 1 if aspect correction is needed in generator mode.

**When to use processor instead:** only when the patch is genuinely meaningless without upstream content — color grading, keying, displacement. If the patch can produce anything interesting standalone, use dual-mode generator.

Examples: `f_grain`, `f_masonry`, `f_stipple`, `f_chladni`.


### Optional Texture Modulation Inlets

Some patches accept additional optional texture inlets that modulate structural parameters — angle, zoom, phase, frequency, etc. This is Kevin's established pattern (e.g. `vs_displacement` has four optional modulation inlets, each via `vs_inState`).

**Key rule:** every optional texture inlet gets its own `vs_inState`. The `vs_black` fallback when unconnected produces zero modulation naturally — the codebox sees a black texture (all zeros) and the modulation term evaluates to zero. No special-casing needed.

**Wiring pattern (one optional modulation inlet):**
```
bpatcher in1 → vs_inState in0
                 vs_inState out0 → pix in1   [modulation texture or vs_black]
```

**Three things that must change together when adding a texture inlet:**

1. **Outer bpatcher:** add an `inlet` object with a descriptive comment (e.g. "phase modulation texture")
2. **`jit.gl.pix` `numinlets`:** increment by 1 for each additional texture inlet
3. **Gen subpatcher:** add `in 2` (or `in 3`, etc.) wired to the codebox; increment codebox `numinlets` to match

**In the codebox:** sample the modulation inlet and scale to the parameter's useful range:
```glsl
// Modulation texture arrives as [0,1] — remap to bipolar [-1,1] for signed params
mod_val = sample(in2, norm).r * 2.0 - 1.0;
// Or keep unipolar [0,1] for additive/scale params
mod_val = sample(in2, norm).r;
param_effective = base_param + mod_val * mod_amount;
```

**Do not use luma or alpha detection to check if the inlet is connected** — use `vs_inState`. A black texture (unconnected) and a legitimately dark modulation texture are indistinguishable by value.

**Note on `vs_inState` outlet 1:** the 0/1 state-change signal is useful if the patch needs to branch behavior when the inlet is connected vs. not. For pure modulation inlets where `vs_black` → zero modulation is sufficient, outlet 1 can be left unwired.

---

## Signal Flow (Full Detail)

```
bpatcher in0 (texture + ctrl)
  → routepass jit_gl_texture jit_matrix
      outlet 0 (jit_gl_texture match) → [texture path: vs_inState or pix in0]
      outlet 1 (jit_matrix match)     → (unused or matrix path)
      outlet 2 (unmatched)            → route param1 param2 ...
                                            outlet 0 → live.dial → attrui (param1) → pix in0
                                            outlet 1 → live.dial → attrui (param2) → pix in0
                                            ...

bypass_toggle.js → attrui (bypass) → pix in0   [wired directly, not through route]

pix out0 → bpatcher out0 (texture out)
```

Key points:
- **`routepass` only declares `jit_gl_texture jit_matrix`** — no param names on routepass
- **`route` dispatches named messages to the correct `live.dial`** — outlet indices start at 0 for first param
- **`attrui` replaces `prepend param <name>`** — it sits between the dial and pix in0, with the attribute name declared on the `attrui` object itself
- **bypass_toggle wires directly** — `jsui → attrui (bypass) → pix in0`, not through route
- **All `attrui` outputs go to pix in0** (the message inlet)

---

## jit.gl.pix Declaration

```
jit.gl.pix vsynth @name <prefix>_pix
```

- First positional arg `vsynth` = drawto context
- `@name <prefix>_pix` = scripting name, used by `param_connect`
- `numinlets: 1` — single message inlet; all params arrive as messages
- No `@dim` attribute — let Vsynth context set dimensions

**Output precision (`@type`):** Omitting `@type` defaults to float32, which is correct for most f_ patches. Two cases where it matters:

- **`@type float32`** — explicit full precision. Use when the patch output will be used as a modulation source by another patch (WFGs use this). Preserves sub-pixel values that would be lost at 8-bit.
- **`@type char`** — 8-bit integer output. Kevin uses this intentionally on feedback paths in `vs_feedback` and `vs_filter_temp` — the quantization artifacts are part of the aesthetic. Only use in f_ if that character is specifically wanted.

---

## Gen Subpatcher Structure

**Processor:**
```
in 1  →  codebox (inlet 0)   [upstream texture]
out 1  ←  codebox (outlet 0)
```

**Dual-mode generator:**
```
in 1   →  codebox (inlet 0)   [texture or vs_black fallback]
r dim  →  codebox (inlet 1)   [render dimensions — for aspect correction in generator mode]
out 1  ←  codebox (outlet 0)
```

`r dim` is only needed if the generator requires aspect correction (most do). Omit it if all computation is in normalized [0,1] UV space with no aspect dependency.

Codebox `numinlets` must match the number of wired inlets (1 for processor, 2 for dual-mode generator with `r dim`).

---

## Codebox Structure

```glsl
// Params declared at top
Param zoom(2.0);
Param bypass(0.0);

// ... computation ...

// Processor bypass — pass input through
out1 = mix(effect_out, sample(in1, norm), bypass);

// Dual-mode generator bypass — black in generator mode, pass-through in processor mode
Param src_mode(0.0);
out1 = mix(result, mix(vec(0,0,0,1), sample(in1, norm), step(0.5, src_mode)), bypass);
```

- `in1` = upstream texture (processor) or texture/vs_black (dual-mode generator)
- `norm` = normalized UV [0,1] as vec2
- `dim` = texture dimensions as vec2 — use `dim.x / dim.y` for aspect ratio
- `out1` = output — vec4 RGBA
- `bypass` always present, `mix()` always the last line

### jit.gl.pix Codebox Operators

**Load the `jit-gen-codebox` skill** for the full empirically-verified operator reference, silent failure patterns, and code health checklist. Key points:

- `fract()`, `sqrt()`, `sin()`, `cos()`, `floor()`, `ceil()`, `abs()`, `pow()`, `mix()`, `step()`, `smoothstep()`, `clamp()`, `wrap()`, `mod()` — all valid
- `noise()` — **silently outputs black on GPU**; always use sin hash instead
- `vec4()`, `vec2()`, `select()`, `snoise()`, `cycle()` — hard errors ("operator not defined")
- Component access (`.x/.y/.z/.w`) on **stored variables** silently fails — always access inline: `sample(in1, uv).x` not `col = sample(...); col.x`
- `boundmode` attribute in GenExpr syntax silently ignored — use `fract()` on coord instead
- `dim` returns pixel dimensions (e.g. 640×480), not normalized values

### Sampling Syntax

```glsl
// Correct — inline component access only
luma = sample(in1, norm).x;

// Aspect-correct UV for generators
aspect = dim.x / dim.y;
px = norm.x * aspect;
py = norm.y;
```

---

## Parameter Wiring

Parameters are wired via `attrui` — the preferred convention over `prepend param <name>`. `attrui` sits between the `live.dial` (or `live.numbox`) and `jit.gl.pix in0`, with the attribute name declared on the `attrui` object. This is tidier and more readable than the older `prepend` pattern.

### attrui

```json
{
  "maxclass": "attrui",
  "attr": "<param_name>",
  "numinlets": 1,
  "numoutlets": 1,
  "outlettype": [""],
  "parameter_enable": 0,
  "patching_rect": [x, y, 150.0, 22.0]
}
```

- `attr` — the param name, matching the `Param <name>` declaration in the codebox
- `parameter_enable: 0` — attrui is not itself a Live parameter; the dial above it is
- Output wires to `jit.gl.pix in0`

### live.dial (float params)

```json
{
  "maxclass": "live.dial",
  "parameter_enable": 1,
  "varname": "<param_shortname>",
  "saved_attribute_attributes": {
    "valueof": {
      "parameter_longname": "<param_longname>",
      "parameter_shortname": "<param_shortname>",
      "parameter_mmin": 0.0,
      "parameter_mmax": 1.0,
      "parameter_initial": [0.0],
      "parameter_initial_enable": 1,
      "parameter_linknames": 1,
      "parameter_modmode": 3,
      "parameter_type": 0,
      "parameter_unitstyle": 1
    }
  }
}
```

- `parameter_type`: 0 = float, 1 = int/toggle, 2 = enum
- `parameter_modmode: 3` = relative modulation (standard for dials)
- `varname` = `parameter_shortname`
- Note: `param_connect` is **not** used on live.dial — attrui handles the connection to pix

### live.numbox (integer/seed params)

Use for integer values like seeds, counts, mode selectors. Wires identically to live.dial — through `attrui` → pix in0. In the codebox, use `floor()` to extract the integer value.

```json
{
  "maxclass": "live.numbox",
  "parameter_enable": 1,
  "varname": "<param_shortname>",
  "patching_rect": [x, y, 44.0, 15.0],
  "presentation_rect": [x, y, 34.0, 15.0],
  "saved_attribute_attributes": {
    "valueof": {
      "parameter_longname": "<param_longname>",
      "parameter_shortname": "<param_shortname>",
      "parameter_mmin": 0.0,
      "parameter_mmax": 999.0,
      "parameter_initial": [0.0],
      "parameter_initial_enable": 1,
      "parameter_linknames": 1,
      "parameter_modmode": 3,
      "parameter_type": 0,
      "parameter_unitstyle": 0
    }
  }
}
```

In codebox: `seed_int = floor(seed_param);`

### Canonical naming: `gain` vs `mix` (locked 2026-07-12)

Any module with a composite/blended outlet (source combined with an
effect via add/multiply/etc.) has **two separate, always-separately-
named controls** — never more than these two names, never a synonym:

- **`gain`** — unbounded, can overdrive past 1:1. Controls how intense
  the effect itself is, independent of blend. This is the *only* name
  used for this role anywhere in the library — never `strength`,
  `intensity`, or any other synonym, regardless of what an individual
  module's codebox variable happens to be called internally.
- **`mix`** — bounded 0–100%, `live.numbox` (see below). Controls the
  ratio of source to effect on the composite outlet. Also the *only*
  name used for this role — never `wet`, `strength`, or `blend`.

This was reaffirmed 2026-07-12 after real drift across the rollout:
`f_vf_advect` and `f_chladni` used `gain`; `f_vf_prism` used `strength`
(its own plan called for renaming to `gain` and then abandoned the
rename mid-fix); `f_caustic` used `intensity` for the same role. All of
these are being retrofitted to `gain`. There is no acceptable reason for
two modules to name the same *role* differently — a performer needs to
build one muscle memory for "the intensity knob," not five.

### live.numbox (mix — dry/wet crossfade params)

For `mix` dry/wet blend controls: `live.numbox`, deliberately, not
`live.dial` — a dedicated convention distinct from the float-param
default. Unipolar **0–100%** (not bipolar) — nothing in the additive-
layer dry/wet design (`ideas/dry_wet_gain_and_novel_field_outlet.md`
finding 1) gives a negative range meaning. Wires identically to other
`live.numbox` params — through `attrui` → pix in0.

**Naming collision warning:** `mix` is also the codebox's built-in
blend operator (`mix(a, b, t)`). Declaring `Param mix(100.0)` and then
calling `mix(src, layer, mix / 100.0)` on the same line silently
produces black output — no compile error — confirmed on `f_vf_advect`
2026-07-12 (see `jit-gen-codebox` skill's matching entry). **Always name
the internal codebox `Param` something that doesn't collide** — e.g.
`mix_pct` — while keeping the user-facing label, `attrui` `attr`,
`live.numbox` `varname`, and any external control-message keyword as
plain `mix`. Those live outside the codebox and aren't part of the
collision, so the control still reads "Mix" to the user.

In codebox (additive-layer modules — glow, prism, streak, caustic, etc.),
**final formula, confirmed correct on `f_vf_prism` after five attempts
(2026-07-12)** — see `ideas/dry_wet_gain_and_novel_field_outlet.md`
finding 1 for the full round-by-round history of what was tried first:

```
driven = clamp(src + layer * gain, 0.0, 1.0);   // the COMPLETE composited state, source included
comp   = mix(src, driven, mix_pct / 100.0);      // plain crossfade toward that complete state
```

**Why `driven` must include `src`, not be a bare effect layer**: three
earlier attempts all failed by crossfading toward a *bare, sparse*
effect layer instead:
- `driven = clamp(layer*gain, 0, 1)` with a plain crossfade → produced a
  frame-uniform double exposure at intermediate `mix` values, because
  the bare layer is mostly black/empty and blending toward it visibly
  superimposes two unrelated images.
- Coverage-based "over" compositing (using the layer's own magnitude as
  per-pixel opacity) → still double-imaged, because the soft, feather-
  blurred gate value used as "coverage" rarely reaches a clean 1.0
  across its intentionally-wide transition band, so source kept
  bleeding through even at `mix=100%`.
- Pure additive `src + layer*gain*mix` (mix as an attenuator, no
  crossfade at all) → same superimposition problem, just via a
  different mechanism.

`driven = clamp(src + layer*gain, 0, 1)` sidesteps all three failure
modes because it's a **complete, non-sparse image everywhere** (source
is baked in) — crossfading between two complete images produces a
genuine "N% of the way there" blend with no region where one side is
empty/black, so no double-exposure artifact. Matt's own framing: "an
effect applied 30% isn't the same as an effect applied to 30% of a
masked shape... it bends 30% of the way toward what it would be at
100%." Note this is the *reverse* of what earlier guidance in this
section said — that guidance was wrong, corrected 2026-07-12.

**Open, unresolved question** (flagged on `f_vf_prism`, not fixed): this
`driven` formula is "additive/screen" — light added on top of source.
Whether some effects should instead use "occlusion" (effect locally
replaces source rather than stacking with it) is a real per-module
design question — see `ideas/dry_wet_gain_and_novel_field_outlet.md`
finding 1's vocabulary section, and `f_vf_prism`'s own plan.md "Open
follow-up." `f_vf_advect` was independently unaffected by any of this —
it's replacement-shape (`driven` was already the full
standalone processed result, no separate source term to accidentally
include).

### Vecfield labeling for non-`f_vf_`-prefixed modules

Only the `f_vf_` prefix is reserved for modules whose **primary** output
is a vecfield. A module with a *mixed* outlet set — e.g. `f_chladni`
(luma + vecfield + magnitude) — keeps its plain name but still needs the
vecfield outlet surfaced to users in two places:

1. **Header label** (`definition.py`): set `"signal_type"` to a free-text
   direction string — `"vecfield in"`, `"vecfield out"`, or
   `"vecfield in/out"` — not the bare `"vecfield"` (that plain string is
   reserved for actual `f_vf_`-prefixed producers/consumers whose *entire*
   output/input is vecfield-typed; it also happens to be the only key
   `SIGNAL_TYPE_COLORS` matches, so a directional string always renders
   grey `[0.6,0.6,0.6,1]` on first build). After building, hand-fix the
   header comment box (`obj-8`) `textcolor` to the library's standard
   value `[0.302, 0.325, 0.463, 1.0]` to match the rest of the library —
   `build_patcher.py` doesn't do this automatically for non-exact-match
   signal_type strings.
2. **`f_modules` menu**: add the module's bare filename (e.g. `"chladni"`)
   to `tools/append_nabla_menu.py`'s `VECFIELD_MODULES` set, then rerun
   the script — appends `" ∇"` to its display label. Note the script's
   `PATH` constant points at `package/patchers/f_modules.maxpat` (repo
   reorg location, not the old `patchers/` path).

Established 2026-07-12 via `f_chladni`'s `out3`/vecfield labeling pass —
see HANDOFF.md and `.specify/f_chladni/plan.md` for the concrete example.

---

## bypass_toggle.js

```json
{
  "maxclass": "jsui",
  "filename": "bypass_toggle.js",
  "hint": "Bypass",
  "numinlets": 1,
  "numoutlets": 1,
  "outlettype": [""],
  "presentation": 1,
  "presentation_rect": [<PW - 22>, 5.0, 18.0, 12.0],
  "parameter_enable": 1,
  "valuepopuplabel": 1,
  "varname": "bypass",
  "saved_attribute_attributes": {
    "valueof": {
      "parameter_invisible": 1,
      "parameter_longname": "bypass",
      "parameter_shortname": "bypass",
      "parameter_type": 1,
      "parameter_modmode": 4,
      "parameter_unitstyle": 0
    }
  }
}
```

- `filename: "bypass_toggle.js"` is **required** — omitting it crashes Max on load
- `numoutlets: 1`, `outlettype: [""]` — single outlet
- `parameter_type: 1` (int/toggle), `parameter_modmode: 4`
- `parameter_invisible: 1` — hidden from automation
- `varname: "bypass"` — no index suffix
- Position: top-right of presentation panel (`PW - 22`, y=5)
- Wired directly: `jsui → attrui (bypass) → pix in0` (not through route)
- **`param_connect` must NOT be set on jsui in generated JSON** — setting it causes Max to crash on load. The `build_patcher.py` script omits it; do not add it manually.

### header_toggle (boolean mode param in header area)

For boolean mode switches that live next to the bypass toggle in the header rather than as a dial in the param grid. Introduced in `f_stipple` for the "Displace" mode toggle. Rendered as a `live.toggle` by `build_patcher.py`.

Declared in `definition.py` with `type: "header_toggle"`. The build script positions it in the header area adjacent to bypass, wires it through `route` → `attrui` → pix in0, and registers it in the `parameters` block. In the codebox, read it as a float and threshold at 0.5:

```glsl
Param proc_mode(0.0);  // 0 = off, 1 = on
mode_active = step(0.5, proc_mode);
```

Unlike `bypass`, `header_toggle` params **do** go through `route` and **do** appear in the `parameters` block — they're user-facing params, not system params.

---

## Parameter Ranges: Vsynth Conventions

Check existing Vsynth patchers before choosing ranges:

| Type | Convention | Source |
|---|---|---|
| Angle/rotation | -360–360 degrees | vs_wfg_3, vs_offset+rot, vs_wfg_polarizer |
| 0–1 normalized | 0.0–1.0 | most params |
| Count/frequency (direct) | 0–1000, value = count at angle 0 | f_masonry courses/bond |
| Integer seeds | 0–999, live.numbox | f_masonry course_seed/brick_seed |

Angle codebox mapping: `theta = angle * (PI / 180.0)`

---

## moduleSize.js Chain

Every bpatcher includes this chain to report its presentation size to Vsynth's module layout system:

```
loadbang → [getattr presentation_rect] → thispatcher → [zl slice 2] → [prepend tam] → js moduleSize.js
```

---

## UI Styling

- **Font:** `"fontname": "Ableton Sans Light"` on all text-bearing objects
- **Font sizes:** title 12pt, param labels 9.5pt
- **Background:** `panel` object, black bg `[0,0,0,1]`, blue border `[0, 0.035, 0.227, 1.0]`, presentation only
- **Dials:** `activedialcolor: [0.8, 0.8, 0.8, 1.0]`, `showname: 0`, `triangle: 1`, `valuepopup: 1`
- **Numboxes:** `44×15` patching, `34×15` presentation, Ableton Sans Light

---

## parameters Block (end of JSON)

Every param registered in `live.dial`, `live.numbox`, or `jsui` must appear here:

```json
"parameters": {
  "obj-2":  ["zoom", "zoom", 0],
  "obj-24": ["bypass", "bypass", 0],
  "obj-37": ["course_seed", "course_seed", 0],
  "parameterbanks": {
    "0": {
      "index": 0, "name": "",
      "parameters": ["-","-","-","-","-","-","-","-"],
      "buttons":    ["-","-","-","-","-","-","-","-"]
    }
  },
  "inherited_shortname": 1
}
```

Format per entry: `"<obj-id>": ["<longname>", "<shortname>", 0]`

---

## Control Message Convention

External control arrives on in0 as named messages (after routepass peels the texture):

```
courses 16
angle 45
bypass 1
course_seed 7
```

The `route` object dispatches by name to the correct `live.dial` or `live.numbox`.
`bypass` is handled by the jsui directly — it does not go through `route`.

---

## Checklist: New Patcher

- [ ] File in `package/patchers/f_<name>.maxpat`
- [ ] `"openinpresentation": 1`
- [ ] `jit.gl.pix vsynth @name <prefix>_pix` — no `@dim`
- [ ] `autopattr @varname <prefix>_autopattr` present
- [ ] `routepass jit_gl_texture jit_matrix` on inlet 0 — no param names on routepass
- [ ] `route <params...>` separate from routepass — bypass NOT in route
- [ ] routepass outlet 2 (unmatched) → route inlet 0
- [ ] routepass outlet 0 (texture) → pix in0 (processor) or → vs_inState in0 (dual-mode generator)
- [ ] Gen subpatcher: `in 1` present (upstream texture for processors; texture or vs_black for generators)
- [ ] Gen subpatcher: `r dim` present if generator needs aspect correction (inlet 1 → codebox inlet 1)
- [ ] Codebox `numinlets` matches wired inlets in gen patcher
- [ ] Codebox: `Param bypass(0.0)` present, `mix()` on last line
- [ ] `bypass_toggle.js` jsui: `filename` key present, `numoutlets: 1`, wired directly to pix, **`param_connect` absent**
- [ ] All float params: `live.dial` with `parameter_enable`, `varname`
- [ ] All integer params: `live.numbox` with same wiring pattern; codebox uses `floor()`
- [ ] All params: `attrui` (with `attr` key) between dial/numbox and pix in0
- [ ] Title comment and background panel in presentation
- [ ] `moduleSize.js` chain present
- [ ] `parameters` block at end of JSON — all param objects registered
- [ ] **Optional modulation inlets:** each has its own `vs_inState`; pix `numinlets`, gen `in N`, and codebox `numinlets` all incremented together
- [ ] **Dual-mode generator:** `vs_inState` on inlet 0; outlet 0 → pix in0, outlet 1 → `prepend param src_mode` → pix in0 (src_mode is system-driven, not user-facing — `prepend` is correct here, not attrui)
- [ ] **Dual-mode generator:** `src_mode` absent from `route`, UI objects, and `parameters` block

---

## What Vsynth Handles (Don't Replicate in Bpatcher)

- Render tempo (`qmetro`, `metro`)
- Output to screen (`cornerpins`, `jit.pwindow`)
- GL context creation (`vs_render`, `vs_modules`)
- Preview windows (`jit.pwindow`)

---

## f_modules — Module Menu

`package/patchers/f_modules.maxpat` is the f_ module insertion menu. Drop it as a bpatcher directly into a user patch — no wrapper needed. Selecting an item from any category menu spawns the corresponding `f_` bpatcher adjacent to the menu.

### Architecture

- Eight categorized `live.menu` objects (visible, display names) each paired with a hidden `live.menu` (filenames) — reorganized 2026-07-10 from an earlier 5-category set (Generators/Processors/Color-Tone/Utilities/Vecfield), by visual character rather than module archetype; see the Module Categories table below
- Selection: display menu outlet 0 → filename menu inlet 0; filename menu outlet 1 → `prepend addmod` → `gate` → `js f_addmod.js`
- Gate is held open by `loadmess 1` → `pipe 250` on load (debounce — prevents spurious spawn on patch open)
- `f_addmod.js` navigates **one level up** (`this.patcher.parentpatcher`) — f_modules is a direct bpatcher in the user's patch, not nested in a wrapper

### f_addmod.js

`javascript/f_addmod.js` spawns the bpatcher:

```javascript
function addmod(mod) {
    var size = SIZES[mod] || [200, 150];
    var loc = this.patcher.box.rect;       // f_modules coords in user's patch
    var offset = 85;
    var target = this.patcher.parentpatcher;
    var myobj = target.newobject("bpatcher");
    target.bringtofront(myobj);
    myobj.message("bgmode", 1);
    myobj.message("border", 0);           // no border — matches hand-placed convention
    myobj.replace("f_" + mod + ".maxpat");
    myobj.rect = [loc[0]+offset, loc[1], loc[0]+offset+w, loc[1]+h];
}
```

Key decisions:
- **Hardcoded size table** (`SIZES` dict keyed by bare module name) — not reliant on `moduleSize` Global, so sizing is correct even on cold spawn before the module has ever been opened
- **`border: 0`** — matches how bpatchers look when placed by hand
- **`bgmode: 1`** — required for bpatcher to show its presentation layer

### Adding a New Module

**`f_modules.maxpat` has no build script** — unlike production module patchers, it's fully hand-built JSON, edited directly via small one-off Python scripts in `tools/` (e.g. `tools/rebuild_modules_menu.py`, `tools/append_nabla_menu.py`) that load/mutate/rewrite the JSON. These are one-off per edit, not a reusable generator — see `tools/README.md`. (An earlier `.specify/f_modules/build_modules.py` script is no longer how this file is maintained.)

Two things need updating when a module is added:

1. **`package/patchers/f_modules.maxpat`** — add the module's display name + filename to the appropriate category's menu, via a small script or direct JSON edit. `python3 -c "import json; json.load(open('package/patchers/f_modules.maxpat'))"` to validate after.
2. **`javascript/f_addmod.js`** — add entry to `SIZES` dict: `"filename": [w, h]`. Get the size from the module's `presentation_rect` on its background panel.

### Why No f_menu Wrapper

The original design had `f_menu.maxpat` as a thin bpatcher wrapper around `f_modules.maxpat` (mirroring Vsynth's `vs_menu` → `vs_modules` pattern). This was removed — `f_modules` is self-contained and the extra indirection broke the `f_addmod.js` parent navigation. Use `f_modules.maxpat` directly.

### Editing Warning

Since there's no build script, edits happen directly against the live `.maxpat` JSON via small one-off scripts (see above) — always `git diff` before and after to confirm the change is exactly what was intended, and nothing else. Max reformats the file on open and may alter typography attributes, so a manual typography edit made in Max should be treated as the new source of truth — don't let a stale script overwrite it later. This file previously had a `build_modules.py` generator that overwrote it completely on every run; that workflow is no longer in use (see "Adding a New Module" above).

### Module Categories

Reorganized 2026-07-10 by visual character rather than generator/processor archetype — menu category doesn't have to equal module type. "∇"-prefixed categories are entirely vecfield-typed; individual module labels also get a "∇" suffix if they take or produce an `f_vecfield` texture, even outside those two categories.

| Category | Modules |
|---|---|
| Scope | Chladni |
| Discrete | Masonry, Stipple, Grain, Weave, Seeds |
| Spatial | Mobius, Stereo, SIRDS, Droste |
| Optical | Lens, Prism |
| ∇ Generators | Vortex, Vortex Multi |
| ∇ Processors | Caustic, Fieldmap, Flow, Repulse, Warp, Streak, Glow, Advect, Chroma |
| Color / Tone | Channel Grader, Hue Processor, Luma Processor, Tone Curve |
| Utilities | Tex Router, Profile, Split, Potential, Matrix 2 |

`f_apollonian`, `f_poincare`, and `f_vf_vorticity` are intentionally excluded (unshipped/unverified — see HANDOFF.md).
