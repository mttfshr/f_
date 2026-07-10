---
name: vsynth-bpatcher
description: Conventions and checklist for building f_ Vsynth bpatchers in Max. Use when creating or editing a patcher in /Users/matt/Github/f_/patchers/. Covers file structure, signal flow pattern, parameter wiring, UI styling, codebox writing workflow, and the required objects every patcher must have.
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
/Users/matt/Github/f_/patchers/   — production f_ bpatchers (version controlled)
/Users/matt/Vsynth/patterns/      — experiments and signal flow scratch (not version controlled)
```

`patterns/` is where you develop and understand a signal flow. Once stable and reusable, it becomes an `f_` bpatcher in `patchers/`. Never put one-off performance files or experiments in the repo.

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
  patchers/    — all bpatcher .maxpat files (source of truth)
  code/        — JS files (on Max search path)
  help/        — .maxhelp files (derived from docs/ eventually)
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
  .specify/    — planning workspace (version controlled — no longer gitignored)
    constitution.md
    f_<name>/           — one dir per bpatcher under active development
      spec.md           — what it does and how you know it's working
      plan.md           — ADRs, blocks, phases (added when build begins)
      tasks.md          — flat task list, session anchor (added when build begins)
      definition.py     — patcher definition: codebox + params + archetype (added at end of Phase 2)
  package-info.json
  HANDOFF.md   — session notes (ephemeral; written fresh each session)
  README.md    — permanent project state: bpatcher status table, build queue
```

- File naming: `f_<name>.maxpat`
- JS files referenced by filename only — Max finds via search path
- Every patcher: `"openinpresentation": 1`

### Naming Convention: f_vf_ prefix for vecfield producers

Bpatchers whose **primary output is an f_vecfield texture** (float32, RG=XY, 0.5=zero vector) use the `f_vf_` prefix rather than `f_`. This signals to users that the output is a specialized texture consumed by specific downstream modules (f_caustic, f_lens field inlet) rather than a standard Vsynth char texture.

Current f_vf_ family:
- `f_vf_vortex` — single analytic fixed-point vortex field
- `f_vf_vortex_multi` — three-site additive vortex field
- `f_vf_chladni` — modal superposition, audio-driven (vecfield outlet pending)
- `f_vf_cymascope` — FDTD wave propagation, audio-driven (planned)
- `f_vf_fieldmap` — scalar texture → vecfield via spatial derivative (planned)

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

- [ ] File in `patchers/f_<name>.maxpat`
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

`patchers/f_modules.maxpat` is the f_ module insertion menu. Drop it as a bpatcher directly into a user patch — no wrapper needed. Selecting an item from any category menu spawns the corresponding `f_` bpatcher adjacent to the menu.

### Architecture

- Five categorized `live.menu` objects (visible, display names) each paired with a hidden `live.menu` (filenames)
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

Two files must be updated together:

1. **`.specify/f_modules/build_modules.py`** — add entry to `CATEGORIES` list: `("Display Name", "filename")`. Run the script to regenerate `f_modules.maxpat`.
2. **`javascript/f_addmod.js`** — add entry to `SIZES` dict: `"filename": [w, h]`. Get the size from the module's `presentation_rect` on its background panel.

Then validate: `python3 -c "import json; json.load(open('patchers/f_modules.maxpat'))"`

### Why No f_menu Wrapper

The original design had `f_menu.maxpat` as a thin bpatcher wrapper around `f_modules.maxpat` (mirroring Vsynth's `vs_menu` → `vs_modules` pattern). This was removed — `f_modules` is self-contained and the extra indirection broke the `f_addmod.js` parent navigation. Use `f_modules.maxpat` directly.

### Regeneration Warning

The build script overwrites `f_modules.maxpat` completely. Max reformats the file on open and may alter typography attributes. The build script bakes in the exact font/color/size values from the last manually-edited version — but if you edit typography in Max and then regenerate, your edits will be lost. **Read the file back after any manual typography edits and update the build script constants before regenerating.**

### Module Categories

| Category | Modules |
|---|---|
| Generators | Masonry, Chladni, Stipple, Grain |
| Processors | Droste, Mobius, Stereo, Lens, Caustic |
| Color / Tone | Channel Grader, Hue Processor, Luma Processor, Tone Curve |
| Utilities | Tex Router, Profile |
| Vecfield | Vortex, Vortex Multi, Fieldmap |
