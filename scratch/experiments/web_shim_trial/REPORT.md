# web_shim_candidates — exportcode trial report

**Date:** 2026-10-12 · **Scope:** reconnaissance only (idea-stage item from the
2026-10-11 gates digest). No go/no-go decision, no recommendation. Nothing
outside `scratch/experiments/web_shim_trial/` was written; no commits.

## Module chosen + rationale

**f_vf_split.** Selected on conceptual simplicity, not line count:
- Codebox is two `sample()` reads + two `mix()` calls (bipolar remap, bypass
  mix). No loops, no trig, no helper functions, no multi-pass, no exotic GL
  state, no feedback. Fewest params of any module with a shader (bipolar,
  bypass only).
- f_texrouter is smaller in lines but is patcher plumbing (js routing logic,
  pattrstorage, toggle matrix) with *no codebox at all* — nothing for
  `exportcode` to export. The trial needed a gen-based module.
- f_vf_fieldmap/f_ngon/f_mobius all carry real math (gradients, 32-iteration
  fold loops, complex inversion) — more failure surface than needed for a
  first export probe.

Source of truth: `src/f_vf_split/definition.py` (read only, never modified).

## How the trial was run

`exportcode` is a message to a live `jit.gl.pix` in a running Max — the repo's
UDP bench (`tests/lib/benchclient.py`) can't send arbitrary messages, so a
self-driving throwaway patcher was built in the scratch dir
(`build_js_trial.py` → `split_export_js.maxpat` + `export_trial.js`):
loadbang → js builds `jit.gl.pix` (genjit via `tests/lib/genjit.py`, same wrapper
the bench uses) → sends `exportcode webgl`, waits 2 s, sends `exportcode isf`,
waits 2 s, closes its own window (Max's live session is the user's; never
quit). Status appended to `_status.json` per phase.

**Exact commands (as sent to jit.gl.pix):**
1. `gen split_export.genjit` (loads f_vf_split's codebox as a gen patcher)
2. `exportfolder <scratch>/_exports`
3. `exportcode webgl`
4. `exportcode isf`

## Raw output / errors

Status log (`_status.json`, verbatim):
```
{"stage":"start","t_ms":0}
{"stage":"gen_loaded","t_ms":12}
{"stage":"sent_webgl","t_ms":15}
{"stage":"webgl_phase_done","t_ms":2028,"files":["","split_export.genjit.html"]}
{"stage":"sent_isf","t_ms":2033}
{"stage":"isf_phase_done","t_ms":4054,"files":["","split_export.genjit.fs","split_export.genjit.html"]}
{"stage":"done","t_ms":4068,"files":["","split_export.genjit.fs","split_export.genjit.html"]}
```

Errors hit along the way (each fixed, kept for the record):
- `cannot export: please set exportfolder first` — js property assignment
  (`pix.exportfolder = …`) does not register; the message form
  (`pix.message("exportfolder", …)`) works.
- First-attempt JSON-only patcher lost 4 patchcords on load in Max 9.2.0
  ("patchcord source/destination not found"); rebuilding objects
  programmatically from js (repo's own `f_addmod.js` pattern) avoided the
  loader entirely. Not a finding about exportcode, just about hand-written
  .maxpat JSON.
- `wind.close is not a function` in js — `thispatcher` message `wclose` is the
  working form.

## Results per target

| Target | Outcome | Artifact |
|---|---|---|
| `exportcode webgl` | **Succeeded** | `split_export.genjit.html` (7 KB, TWGL-based page) + `split_export.genjit.fs` |
| `exportcode isf` | **Succeeded** | `split_export.genjit.fs` (ISF: JSON header + GLSL body) |
| Runtime check (webgl) | **Page runs clean** | loaded in headless Chromium (twgl-full.min.js v4.4.0 fetched per maxref); program compiles/links, `gl.getError()==0`, rAF loop draws; zero console entries. Only page errors: two `NotAllowedError: Permission denied` from the auto-`getUserMedia` camera call (expected headless denial). Output is black because tin1 is the empty camera texture — see gaps. |

The `.fs` file appears during the isf phase but is shared: webgl export also
writes it (same filename) — the html embeds its fragment shader inline, and
the `.fs` is the ISF-format artifact.

## Gap analysis (vs. the module's normal in-Max behavior)

1. **Single outlet only.** f_vf_split is defined with two outlets (X channel,
   Y channel). The exported shader computes both (`tmp_expr_6`, `tmp_expr_7`)
   but `gl_FragColor` is assigned twice — **only the last one (y_ch) survives**.
   In Max, out1/out2 are separate jit matrices; in any single-FBO export both
   channels collapse to one RGBA output and X is silently lost. This is the
   biggest real gap for any multi-outlet module.
2. **Inputs hardwired to a webcam.** The webgl page auto-opens
   `getUserMedia` and feeds *all three* texture inputs (`tin1/tin2/tin3`)
   from the same camera. In Max, in1 is the vecfield source and the other
   inlets are mod/param streams. No exported hook exists for piping a
   different source in without editing the generated JS.
3. **Params are uniforms, not controls.** `bipolar`/`bypass_gate` become
   uniforms set to defaults once (`bipolar : [0.0]`). No UI. In Max these are
   live dial/button params. ISF declares them properly (`INPUTS` floats with
   defaults), so an ISF host would expose them — but the raw webgl export has
   no control surface at all.
4. **No `r draw` clock.** Vsynth's message clock (`r draw`) doesn't exist;
   the webgl page runs a free-running `requestAnimationFrame` loop.
5. **float32 vs 8-bit.** Module runs `pix_type float32`; the webgl page is
   `RGBA UNSIGNED_BYTE` (8-bit). Bipolar remap to -1..1 doesn't fit 8-bit
   unorm without the sign convention being lost — the exported shader does
   `r*2-1` on already-quantized values.
6. **vecfield semantics absent.** in1 is a vecfield in the module contract
   (X in R, Y in G). The export treats it as an opaque RGBA texture. Fine
   for this module; meaningful for anything that consumes `dim`, multi-pass,
   or feedback — f_vf_split has none of those, which is exactly why it made
   a good probe.

## Questions surfaced for whoever picks this up

- Is the **outlet collapse** (gap 1) inherent to `exportcode` for all
  multi-outlet modules, or does a different export path (jxs? gen~ export?)
  preserve them? Only f_vf_split was tested.
- Do modules that use `dim`, multiple passes, or feedback (`f_vf_advect`,
  `f_vf_fluid`, `f_caustic`) export at all, or fail loudly? Unknown — one
  module tested.
- Is 8-bit quantization (gap 5) acceptable for the vecfield family, or is a
  float-texture wrapper (16F/32F) required? The generated JS doesn't request
  float textures; WebGL1 would need `OES_texture_float` either way.
- Would the ISF route be the more practical shim (hosts give you param UI
  for free, per gap 3) with the webgl html treated as a demo rather than a
  target? Not tested beyond compile: no ISF host was run against the `.fs`.
- twgl-full.min.js must ship alongside the html (fetched from
  greggman/twgl.js v4.4.0 per the maxref's pinned link) — a packaging
  dependency to remember if these artifacts are ever distributed.

## Artifacts (all in scratch/experiments/web_shim_trial/, uncommitted)

- `build_export_trial.py`, `build_js_trial.py` — trial builders (throwaway)
- `export_trial.js`, `split_export_js.maxpat` — the working driver
- `split_export.genjit` — f_vf_split codebox wrapped via tests/lib/genjit.py
- `_exports/split_export.genjit.html` + `.fs` — the exported artifacts
- `_status.json` — verbatim phase log quoted above
- First-attempt `split_export.maxpat` (JSON-loader casualties) kept for the
  record; safe to delete the whole directory.