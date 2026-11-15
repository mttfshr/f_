---
name: vsynth-bpatcher
description: Conventions for building and changing f_ modules, the Vsynth bpatchers in package/patchers/ built from each module's definition.py by build/build_patcher.py. Use this skill whenever creating a module, changing a shipped patcher or its definition.py, choosing an archetype (processor or dual-mode generator), adding a texture inlet, wiring params, dials or bypass, naming a control, adding a module to the f_modules menu, fixing drift, or making a scratch patch in Vsynth, even if the user only says "new module", "add a dial", "wire this up" or "rebuild f_name". Load it especially on these symptoms: a module that renders nothing or flips white/black when unconnected; bypass that leaves outlet 2 flipped or wrong; "name X_pix already in use" with two instances; "patchcord source not found" or "type is not a sampler" on load; a hand edit in Max lost on rebuild; a full -1 field from an empty vecfield inlet. For the code inside the pix see jit-gen-codebox; for .maxpat JSON text see maxpat-json-authoring.
---

# Vsynth Bpatcher Skill

Conventions for building `f_` modules — visual processing bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in Max 9.

**Repo:** `/Users/matt/Github/f_`
**Vsynth package:** `/Users/matt/Documents/Max 9/Packages/Vsynth`

Patchers are generated from `src/<module>/definition.py` by `build/build_patcher.py` (schema: `build/spec.md`); patcher files are outputs, not references. **`definition.py` is the source of truth:** a change made by hand in Max is written back into it, and hand-tuned presentation state goes in its `overrides` block via `build/capture.py`. Details in `references/builder.md`.

## Quick rules

1. **Change `definition.py`, then rebuild;** never leave a hand edit only in the patcher. `build/py.sh build/drift.py -v f_x` shows drift. (builder.md)
2. **Codebox first, numbers before eyes:** write `src/f_name/codebox_<stage>.gen`, pass tiers 1-2 (mirror, bench), then build the module directly. No scratch-patch stage. (Codebox Writing Workflow)
3. **Pick the archetype:** dual-mode generator if the module can make anything on its own, processor only if it is meaningless without input. (Two Patcher Archetypes)
4. **A generator needs `r draw` → pix and a fixed output size** (`@adapt 0` plus `render_dim`); `vs_black` is 1x1 and triggers nothing. (Dual-Mode Generator)
5. **Every optional texture inlet gets its own `vs_inState`.** An empty vecfield inlet reads as a full -1 field: gate it. (Optional Texture Modulation Inlets)
6. **Name the pix `#0_<prefix>_pix`,** or two instances collide. (Checklist)
7. **Bypass is a passthrough on every outlet,** through `bypass_mode: "param"` and `Param bypass_gate`; native `@bypass` flips outlets 2+. A new param-bypass module extends `BYPASS_EXPECT`. (bypass-and-control.md)
8. **Two names only for blend roles:** `gain` (effect intensity, unbounded) and `mix` (0-100% numbox, codebox Param `mix_pct`). (parameters-and-ui.md)
9. **A correctness setting gets no panel slot:** `"ui": False`. (parameters-and-ui.md)
10. **Add to the menu in `src/f_modules/menu.py` and regenerate;** never hand-edit `f_modules.maxpat` or `f_addmod.js`. (f-modules-menu.md)
11. **Relaunch Max before looking at a new patcher, JS or media file.** (project-layout.md)
12. **After changing a shipped bpatcher,** run the offline contract test and the module contract bench (ask first). (Codebox Writing Workflow)

## Reference files

Read the one the task needs; SKILL.md has the workflow and the core structure.

| File | Read when |
|---|---|
| `references/builder.md` | editing `definition.py`, fixing drift, capture, the edit-view layout, builder keys for hand-built and multi-stage modules |
| `references/patcher-anatomy.md` | reading or checking a patcher: full signal flow, pix declaration and `@type`, gen subpatcher, codebox skeleton, moduleSize chain, UI styling, `parameters` block |
| `references/parameters-and-ui.md` | adding or naming a control: attrui, live.dial, live.numbox, `gain`/`mix` and the dry/wet formula, `signal_type` labels and type dots, header toggles, ranges, panel slots |
| `references/bypass-and-control.md` | anything about bypass, the bypass jsui, or named control messages and `route_name` |
| `references/f-modules-menu.md` | adding a module to the menu, `f_addmod.js`, menu sizes |
| `references/project-layout.md` | where files live, the `f_vf_` prefix, idea-to-stable lifecycle, Vsynth reference docs |
| `references/scratch-patches.md` | a scratch patch (only for something that is not a module yet), or "nothing renders at all" |

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

**Verification follows the tiers in `.specify/constitution.md` → Verification
Tiers (adopted 2026-09-22).** In short: numbers before eyes.

1. **Write the codebox as a file** — `src/f_name/codebox_<stage>.gen` —
   from the start, not only after it's confirmed. The test bench loads that
   exact file, so what gets verified is what ships.
2. **Tier 1 (nontrivial math):** a NumPy mirror in `tests/modules/<m>/test_<m>.py`,
   float32, pass-for-pass, checked against independent ground truth;
   mutation-check it once. `tests/lib/gpu_sim.py` provides the jit.gl.pix model
   (texel-center `norm`, sampling, float32 storage).
3. **Tier 2 (numeric criteria exist):** `tests/modules/<m>/bench_<m>.py`, copied from
   `tests/templates/bench_module_template.py` — compiles clean, matches the
   mirror, holds invariants (e.g. `bypass=1` is exact identity), and cost at
   target resolutions if cost matters. Claude runs it with `tests/bench.sh -q <file>`
   (ask first; see the bench-test-authoring skill); Matt only needs Max with
   `tests/bench/bench.maxpat` open.
4. Once the codebox has passed tiers 1–2, write the full `definition.py` and run
   `build_patcher.py`: the module is built DIRECTLY, with no scratch-patch stage
   (Matt, 2026-10-26; constitution Verification Tiers).
5. **Tier 3:** judge the built module live: expressive tuning, param ranges,
   visual character, integration. Tuning edits go back into the codebox file and
   `definition.py`, then tiers 1–2 are re-run.

**Bench coverage:** ≤3 inputs, all 4 outputs (`all_outputs=True`), float32
or char (`pix_type=`), multi-frame feedback runs (`run_temporal`), cost
(`measure`). Multi-stage modules: stage by stage. **After changing any shipped
bpatcher,** run `tests/run.sh tests/contracts/test_module_contracts.py` (offline wiring)
and `tests/bench.sh tests/contracts/bench_modules.py` (live contracts in `vs_render`).

### Phase 0 template for codebox modules (tasks.md)

```
## Phase 0: Verification (BLOCKING)
- [ ] T001 DECISION GATE — verification tiers: which apply (math mirror /
      bench correctness / bench cost / scratch only) and why; record
      "n/a because ..." for each skipped tier.
- [ ] T002 Write src/f_name/codebox_<stage>.gen.
- [ ] T003 (Tier 1) NumPy mirror in tests/modules/<m>/test_<m>.py against independent
      ground truth; mutation-check once.
- [ ] T004 (Tier 2) tests/modules/<m>/bench_<m>.py from the template: compiles clean,
      GPU vs mirror, invariants. Record measured errors here.
- [ ] T005 (Tier 2, if cost matters) bench cost at target resolutions.
- [ ] T006 (Tier 3) is not a Phase 0 task: Phase 1 builds the module from definition.py,
      Phase 2 tunes ranges, defaults and integration live on it.
```

**Debugging an existing module:** if the question is "math or plumbing?",
bench its codebox file in isolation first (a throwaway `bench_*.py` or a
`benchclient.run_pass()` one-off) before opening the patch.

---
## Required Objects (Every Patcher)

1. **`jit.gl.pix vsynth @name #0_<prefix>_pix`** — shader core, draws to vsynth context
2. **`routepass jit_gl_texture jit_matrix`** — peels texture from inlet; unmatched outlet goes to `route`
3. **`route <param1> <param2> ...`** — named control message dispatch for all params except bypass
4. **`bypass_toggle.js` (jsui)** — custom bypass UI; wired directly to the pix (attrui for native bypass, `prepend param bypass_gate` for param bypass), not through route
5. **`live.dial`** per float param — with `parameter_enable`, `varname`
6. **`attrui`** per param — sits between dial and pix in0; `attr` key names the target param
7. **Title comment** — in presentation layer, Ableton Sans Light
8. **Background panel** — black with blue border in presentation
9. **Texture inlet** (`inlet`, comment "texture in") → `routepass`
10. **Texture outlet** (`outlet`, comment "texture out") ← pix out0
11. **`moduleSize.js` chain** — for Vsynth module sizing (see below)
12. **`parameters` block** at end of JSON — registers all params
13. **`autopattr`** with scripting name (box `varname`) `<prefix>_autopattr` — state save/restore (use in all patchers). The box text is plain `autopattr`; `autopattr @varname X` is *invalid* in Max 9 (the attribute is rejected and Max assigns a `u123456` name)

---

## Two Patcher Archetypes

### Processor (texture in → texture out)

Requires an upstream texture. Has no self-generated content — meaningful only when something is wired to inlet 0. Bypass passes the input texture through unmodified.

```
bpatcher in0 → routepass jit_gl_texture jit_matrix → pix in0   [texture]
               routepass out2 (unmatched)           → route      [control]
```

Inside gen: `in 1` → codebox inlet 0, `out 1` ← codebox outlet 0.

Codebox bypass (param bypass): `out1 = mix(effect_out, sample(in1, norm), bypass_gate);`

Examples: `f_lens`, `f_droste`, `f_luma_processor`, `f_channel_grader`.

---

### Dual-Mode Generator (self-generating, optionally uses upstream texture)

The default archetype for any f_ patch that produces its own content. Uses `vs_inState` on inlet 0:

- **Unconnected** — `vs_inState` passes `vs_black`, a **1x1** black texture (`vs_render.maxpat`). It does **not** by itself make the pix render: wire `r draw` → pix inlet 0 (or the builder's render trigger) so the patch draws every frame, and fix the output size (`@adapt 0` plus `render_dim`), or a pix that adapts to its first input renders 1x1. Codebox generates content from its own parameters. Bypass outputs black.
- **Connected** — upstream texture available in the codebox. Use it as a modulation source, a luma gate, a color source, or process it directly. Bypass passes input through.

This is the pattern for f_ generators: `vs_inState` gives the codebox a defined input when nothing is cabled, and an `r draw` cord drives the render. Evidence: `f_quasi` drew nothing unconnected with only `vs_inState` on its inlet (Matt, live, 2026-10-30) and drew once `r draw` → pix was added; the same check on `f_stipple`, `f_weave` and `f_vf_flow` closed 2026-11-01. Unconnected, `f_stipple` showed a solid frame flipping white / black (Matt, live); the cause, the pix adapting to the 1x1 `vs_black`, is inferred, and `@adapt 0 @dim` plus `render_dim` fixed it (Matt, live). That `vs_black` alone never triggers a render is likewise inferred from these, not probed. Kevin's native source modules (vs_sources/) use no texture inlet at all because they live at the top of the Vsynth signal chain and are driven directly by the render clock.

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

**Caveat for bipolar (`f_vecfield`, 0.5 = zero) inlets** (bench-verified 2026-09-23, `f_vf_fluid`): `vs_black` is all **zeros**, which decodes to a full −1 field, not neutral — gate the inlet with the `src_vecfield` flag from `vs_inState` outlet 1. That flag **lags ~180 ms at load and at disconnect** (it starts "connected"), so a module that *holds state* must also gate by content: a real `f_vecfield` has B = 0.5 and `vs_black` has B = 0 (`abs(sample(inN, norm).z - 0.5) < 0.25`). A stateless module only shows the flag lag as a brief glitch; a solver keeps a phantom velocity (~−0.1 uniform) that decays only as fast as its drag.

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

## Checklist: New Patcher

- [ ] **Verification tiers recorded** in tasks.md Phase 0 — `tests/modules/<m>/bench_<m>.py` exists and passes, or the reason it doesn't apply is written down
- [ ] File in `package/patchers/f_<name>.maxpat`
- [ ] `"openinpresentation": 1`
- [ ] `jit.gl.pix vsynth @name #0_<prefix>_pix` — no `@dim` (see the `#0_` item below)
- [ ] `autopattr` box present with `varname` = `<prefix>_autopattr` (box text is just `autopattr`, no `@varname`)
- [ ] `routepass jit_gl_texture jit_matrix` on inlet 0 — no param names on routepass
- [ ] `route <params...>` separate from routepass — bypass NOT in route
- [ ] routepass outlet 2 (unmatched) → route inlet 0
- [ ] routepass outlet 0 (texture) → pix in0 (processor) or → vs_inState in0 (dual-mode generator)
- [ ] Gen subpatcher: `in 1` present (upstream texture for processors; texture or vs_black for generators)
- [ ] Gen subpatcher: `r dim` present if generator needs aspect correction (inlet 1 → codebox inlet 1)
- [ ] Codebox `numinlets` matches wired inlets in gen patcher
- [ ] Bypass: `bypass_mode: "param"` with `Param bypass_gate` mixed to the passthrough on EVERY outlet, and a `BYPASS_EXPECT` entry (`references/bypass-and-control.md`); native `Param bypass` only for a single-outlet module that needs nothing else
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
- [ ] **Pix object name is `#0_<prefix>_pix`** (hash-zero prefix, 2026-10-17) — Ob3D bindings are context-global; two live instances of a bare-named module collide ("name X_pix already in use. ob3d does not allow multiple bindings") and the loser's params go unset ("no attribute ... on target pix") — which shows up live as the module rendering its first texture passthrough. The shipped multi-stage modules (`#0_tm_stage_a`...) had the right form all along; single-pix definitions get it too. `param_connect` continues to target the *name text* as written in the definition.
- [ ] **`driving_inlet` processors single-pix** — when a `processor`/`dual`-archetype definition sets `driving_inlet: True`, its gen has NO `in 1`-as-bang-tap box: the primary texture rides mod_inlets[0] and the codebox has exactly `len(mod_inlets)` inlets (the multi-stage/pix_chain branch handles this; build_patcher's processor branch does too since 2026-10-17). Symptom of the old gap, if seen anywhere: "patchcord source not found: deleting patchcord" + "type is not a sampler" on load, and the module behaves as a passthrough. If a definition needs the bang-only-tap shape, do NOT set driving_inlet.

---

## What Vsynth Handles (Don't Replicate in Bpatcher)

- Render tempo (`qmetro`, `metro`)
- Output to screen (`cornerpins`, `jit.pwindow`)
- GL context creation (`vs_render`, `vs_modules`)
- Preview windows (`jit.pwindow`)

