# Scratch patches

When to make one, the GL context it needs, the template to clone, hand-authored bpatcher-composition patches, and the first thing to check when nothing renders. Part of the vsynth-bpatcher skill.

## File locations

```
/Users/matt/Github/f_/package/patchers/   — production f_ bpatchers (version controlled)
/Users/matt/Vsynth/patterns/              — experiments and signal flow scratch (not version controlled)
```

`patterns/` is where you develop and understand a signal flow. Once stable and reusable, it becomes an `f_` bpatcher in `package/patchers/`. Never put one-off performance files or experiments in the repo.

## Scratch patch GL context requirement

**Scratch patches are now the exception (amended 2026-10-26, Matt).** A module is built
directly from its definition once tiers 1–2 pass and is judged on the shipped bpatcher.
Use a scratch patch only to investigate something that is not a module yet (an unfamiliar
Max object, a Vsynth integration question, a comparison of existing modules). The rest of
this section and the next two apply when you do.

Scratch patches that use any `vsynth`-context GL object (`jit.gl.pix`, `jit.gl.asyncread`, `jit.gl.texture`, `jit.gl.slab`, etc.) require the **`vs_render` bpatcher** to be present and running — not the bare `vs_render` object. The bpatcher initializes the full Vsynth GL context including `jit.gl.render`, context naming, and qmetro. Without it, GL objects silently fail or output black.

Always include in scratch patches:
- `vs_render` bpatcher (from Vsynth package, `patchers/vs_render.maxpat`)
- A toggle wired to its inlet to start the render clock

## Scratch patch starting point: `scratch_template.maxpat`

`/Users/matt/Vsynth/patterns/scratch_template.maxpat` is the canonical starting
shell for new scratch work. Clone it (copy + rename) rather than building a
scratch patch from scratch each time, and rather than Claude generating raw
`.maxpat` JSON for a new scratch shell — Claude has no verified template for
hand-building a gen-subpatcher-with-codebox from inference, and getting that
JSON subtly wrong (inlet/outlet ordering, numinlets mismatches) costs more
debugging time than it saves. Matt builds/clones scratch shells in Max
directly; Claude provides codebox text to paste in (see "Codebox Writing
Workflow" in SKILL.md). When Matt asks, Claude may instead write the codebox straight into a
cloned template's embedded gen patcher, copying the schema from a shipped module with the
same outlet count (`f_chladni` for three) and verifying the structure offline (done for
`f_quasi` 2026-10-26); that is Matt's call, not the default.

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
  the codebox to match the inlet count needed (see jit-gen-codebox `references/pix-object.md` on inlet counts, and
  "Three things that must change together" in SKILL.md)
- Add a second `out N` + `outN` codebox assignment if a debug/isolated
  outlet is needed (e.g. f_magic_eye's period-field visualization)
- Swap or add source bpatchers (`vs_wfg_3`, `vs_noise_3`, `f_stipple`,
  `f_grain`, etc.) feeding the additional inlets as appropriate to what's
  being tested
- Add a `vs_preview` bpatcher per extra outlet that needs its own viewable
  window (the template's single `vs_output` only displays one texture
  stream at a time)

## Exception: bpatcher-composition scratch patches (comparing existing modules)

The "don't hand-generate raw JSON" guidance above is about a **new**
`jit.gl.pix`/gen/codebox object — Claude has no verified template for that
internal wiring, and a subtle `numinlets`/inlet-order mistake there is
expensive to debug. It does not apply to a scratch patch that only **wires
together already-shipped `f_`/`vs_` bpatchers** — e.g. comparing two or
three module chains side by side (a vortex field into `f_caustic` vs. into
`f_vf_warp`, feeding separate `vs_preview` windows). For that case, Claude
hand-authoring the `.maxpat` JSON directly is fine and is the preferred
approach — validated 2026-09-20 on `scratch/fresnel_comparison.maxpat`.
Each bpatcher's public interface (numinlets/numoutlets/outlettype) is
already documented in `docs/f-reference/*.md` and `docs/vsynth-reference/`,
so there's no inference risk the way there is for a new codebox — Claude
is just placing `bpatcher` boxes (`name`, `varname`, `patching_rect`) and
`patchline` connections between documented inlets/outlets. Base the JSON
structure on an existing file already in the repo (e.g.
`package/examples/f_demo_general.maxpat`) for the exact box/patchline schema Max
expects, and validate the result parses (`python3 -c "import json;
json.load(open(path))"`) before handing it off.

Do **not** reach for the `maxmsp` MCP server for this. It requires its own
`max/mcp_host.maxpat` host patch open in Max — a generic audio-DSP sandbox
unrelated to this project's actual Vsynth session — has no mechanism to
point a `bpatcher` box at a specific module file, and its object
cheat-sheet is oriented around plain audio objects (`cycle~`, `dac~`),
not Vsynth's bpatcher/global-send architecture. Confirmed a poor fit in
practice, not just in theory.

## Debugging "no output at all" — check the wire before the math

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
