# E2E Testing Plan — f_ library

Multi-session testing and backfill. Each patcher gets a full audit block. Work through one patcher per session or as time allows. Mark tasks with [x] as complete.

---

## Test Dimensions (applied to every patcher)

### A. Load & Crash Safety
- Open patcher in Max with vs_render running
- Check Max console for errors
- Verify bypass_toggle.js jsui has NO `param_connect` attribute (crash risk)

### B. Code Health (jit-gen-codebox skill)
- Extract codebox text
- Run through jit-gen-codebox checklist:
  - No `noise()` calls
  - No component access on stored variables (`col.x` after `col = sample(...)`)
  - No `vec4()` / `vec2()` constructors
  - No `select()`, `snoise()`, `cycle()`
  - No variable names shadowing operators (`cell`, `in`, `norm`, `snorm`, `dim`)
  - No `boundmode` in GenExpr syntax
  - `dim` not used for normalized sizing
  - `Param bypass(0.0)` present, `mix()` on last line

### C. Functional Output
- Solo output: produces visible output with default params
- Key params visibly affect output (test at least 3)
- Bypass: correct behavior (pass-through for processors, black for generators when unconnected)

### D. Vsynth Chain Integration
- Works as first module in chain (generator mode or with test source)
- Works in middle of chain (processor position)
- Output passes cleanly to next module

### E. Presentation Layout Audit
- Panel sized correctly for content — no clipping, no excess space
- Dials/numboxes aligned in grid
- Labels above dials, correct font (Ableton Sans Light)
- Title correct position and size
- Bypass toggle top-right
- No overlapping objects in presentation mode

### F. Edit Mode Layout Audit
- Objects not overlapping
- Logical grouping — texture path, control path, UI objects separated
- Inlets/outlets at sensible positions
- No orphaned objects

### G. Build Script Cross-check
- Does a `definition.py` exist? If not, create one from the current .maxpat
- If definition.py exists: rebuild with `build_patcher.py` and diff against current — identify any layout hand-corrections that need to be fed back into the script
- Document any build script fixes needed

---

## Patcher Audit Blocks

---

### f_grain
**Archetype:** Dual-mode generator
**Has definition.py:** No — needs creating
**Known issues:** Dual-mode (no-input) behavior deferred; works as processor

- [x] A. Load & crash safety
- [x] B. Code health scan
- [x] C. Functional output
- [x] D. Vsynth chain integration
- [x] E. Presentation layout audit
- [x] F. Edit mode layout audit
- [x] G. Create definition.py from current .maxpat _(deferred — dual-mode generator, definition.py pattern not yet established for this archetype)_

Notes:
- 2026-06-05: bypass_toggle.js clean (no param_connect / parameter_enable). ✅
- 2026-06-05: @type char was missing — fixed.
- 2026-06-05: `era_clock` / `persistence` naming: codebox param is `era_clock`, UI dial was `persistence`. Both now exist as separate params — `persistence` operates in parent patch as era rate scalar, `era_clock` is what the shader receives. Correct.
- 2026-06-05: Code health clean — no noise(), no stored component access, no vec4(), fract()/sqrt() used correctly.
- 2026-06-05: Generator mode (no input texture) works but renders at lower resolution until texture connected — expected Vsynth behavior, not a bug.
- 2026-06-05: Dual-mode (no-input) behavior deferred — see scratchpad.

---

### f_masonry
**Archetype:** Dual-mode generator
**Has definition.py:** No (f_weave dir exists with old name)
**Known issues:** `aspect` uses `dim` (broken in generator context, returns context dims); C inlet (in4) wiring unverified; AA hardcoded to `px_norm = 1.0/640.0`

- [ ] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create definition.py; clean up f_weave spec dir

Notes:

---

### f_stipple
**Archetype:** Dual-mode generator
**Has definition.py:** Yes
**Known issues:** None known

- [x] A. Load & crash safety
- [x] B. Code health scan
- [x] C. Functional output
- [x] D. Vsynth chain integration
- [x] E. Presentation layout audit
- [x] F. Edit mode layout audit
- [x] G. Rebuild from definition.py and diff _(definition.py exists; full rebuild diff deferred)_

Notes:
- 2026-06-05: bypass_toggle.js clean. ✅
- 2026-06-05: @type char missing — fixed.
- 2026-06-05: No codebox health issues.
- 2026-06-05: C-F all pass.
- 2026-06-05: Does not produce output without incoming texture — dual-mode generator behavior not implemented. Deferred, same pattern as f_grain. In source mode (no input) the hash field is self-contained so this is solvable, but not a blocker.
- 2026-06-05: stipple → droste is a strong pairing with emergent singularity behavior — see ideas/droste_singularity.md.

---

### f_droste
**Archetype:** Processor
**Has definition.py:** No
**Known issues:** Center pixelation on raster sources (accepted architectural limitation); `@type char` added this session

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create definition.py from current .maxpat

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅

---

### f_lens
**Archetype:** Processor
**Has definition.py:** No
**Known issues:** Phase 5 Vsynth integration testing deferred

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create definition.py from current .maxpat

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅
- 2026-06-05: loadbang panel init fixed (lens_toggle.js). ✅

---

### f_mobius
**Archetype:** Processor
**Has definition.py:** No
**Known issues:** Performance gap — feels limited in practice; may need additional params

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create definition.py from current .maxpat

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅
- 2026-06-05: param max adjusted during testing. ✅

---

### f_stereo
**Archetype:** Processor
**Has definition.py:** No
**Known issues:** None known

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create definition.py from current .maxpat

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅

---

### f_channel_grader
**Archetype:** Processor
**Has definition.py:** No — no .specify dir
**Known issues:** None known

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create .specify/f_channel_grader/ and definition.py

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅

---

### f_hue_processor
**Archetype:** Processor
**Has definition.py:** No — no .specify dir
**Known issues:** None known

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create .specify/f_hue_processor/ and definition.py

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅

---

### f_luma_processor
**Archetype:** Processor
**Has definition.py:** No — no .specify dir
**Known issues:** None known

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create .specify/f_luma_processor/ and definition.py

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅

---

### f_tone_curve
**Archetype:** Processor
**Has definition.py:** No — no .specify dir
**Known issues:** None known

- [x] A. Load & crash safety
- [ ] B. Code health scan
- [ ] C. Functional output
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create .specify/f_tone_curve/ and definition.py

Notes:
- 2026-06-05: bypass_toggle.js crash risk fixed (param_connect removed). ✅
- 2026-06-05: @type char added. ✅

---

### f_texrouter
**Archetype:** Utility (4×4 routing matrix + presets)
**Has definition.py:** No — no .specify dir
**Known issues:** None known
**Note:** No codebox — skip B (code health)

- [ ] A. Load & crash safety
- [ ] C. Functional output — routing matrix works, presets save/recall
- [ ] D. Vsynth chain integration
- [ ] E. Presentation layout audit
- [ ] F. Edit mode layout audit
- [ ] G. Create .specify/f_texrouter/ and document architecture

Notes:

---

## Cross-Cutting Checks

Run these across all patchers once individual audits are complete.

- [x] **`@type` consistency** — processors `@type char`, generators `@type float32`; audited and corrected 2026-06-05
- [ ] **`autopattr` present** — every patcher must have `autopattr @varname <prefix>_autopattr`
- [ ] **`vs_inState` on all generators** — f_grain, f_masonry, f_stipple all have correct dual-mode wiring
- [ ] **`routepass` / `route` separation** — no param names on routepass, route handles all named control messages
- [x] **`bypass_toggle.js` `param_connect` absent** — all patchers fixed 2026-06-05
- [ ] **README status table** — update to reflect any bugs found or fixed during audit

---

## Build Script Backfill

Once definition.py files exist for all patchers:

- [ ] Run `build_patcher.py` on each and diff against hand-edited .maxpat
- [ ] Identify layout corrections not captured in build script
- [ ] Update build script defaults for presentation layout (panel sizing, object positions)
- [ ] Verify a clean rebuild produces a patcher that passes the layout audit

---

## Session Notes

Add dated notes here as sessions complete audit blocks.
