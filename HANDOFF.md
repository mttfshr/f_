# HANDOFF — f_ session 2026-06-04

## Status
f_masonry three-space modulation architecture designed, spec/plan/tasks updated, codebox (phase6) written and working. C inlet wiring issue blocking final verification — left for next session.

---

## What was done this session

### f_masonry: three-space modulation architecture

**Design discussion:** Identified that A and B were both sampling in brick identity space (slot/course center quantized). This is correct for structural params but limits expressive range. Developed a principled three-space model:

- **A (slot space)** — brick identity, `brick_uv` — structural + appearance params
- **B (intra-brick space)** — `vec(along_frac, across_phase)`, tiles per brick face — appearance params only
- **C (pixel/screen space)** — `norm`, continuous across field — appearance params only

Key insight: upstream screen-space textures get chopped by the brick mask — they do not modulate brick structure. So pixel space is genuinely a third distinct space, not redundant with upstream processing.

Structural/appearance param split is principled: modulating offset, drift, etc. from intra-brick or screen space breaks slot quantization or causes circularity. Appearance params (mortar, softness, width, roundness, course_color, brick_color) are safe from all three spaces. Framed as discovery — C may make some appearance params redundant.

**Spec/plan/tasks updated:**
- spec.md Phase 5 fully rewritten for three-space model
- plan.md ADR 6 added documenting the decision
- tasks.md M001 marked superseded, M002 written

**Codebox:** `codebox_phase6.gen` written and pasted into patcher. Compiles and runs correctly. B sampling moved to after full geometry block (needs `along_frac`, `across_phase`). C samples at `norm`. `sqrt()` replaced with `pow(x, 0.5)`.

**Matrix UI:** `f_util_matrix_grid.js` updated to 3 sources (A/B/C). `f_util_mod_handler.js` updated with C suffix routing. Matrix now shows three columns.

**Anti-aliasing investigation:** `dFdx`/`dFdy` confirmed NOT available in jit.gl.pix gen codebox (Gen compiles to GLSL but only exposes documented GenExpr operators). Approximation via `courses/dim.y` tried but caused artifacts. Reverted. Aliasing is a known limitation for now.

---

## Loose thread: C inlet wiring

C inlet "no data" in vs_inState despite WFG wired to it in Vsynth. Traced through JSON:
- `in 4` exists in gen subpatcher and is wired to codebox
- `numinlets` on pix is 4 (correct)
- Three vs_inState objects present, third feeds pix inlet 3
- Outer bpatcher inlet objects all show `index: 0` — possible inlet ordering/indexing issue
- Suspect bpatcher inlet positions may not match expected order in Vsynth

**Next session: hover over each texture inlet on the outer bpatcher in Max and confirm which inlet index each reports. Check if inlet 4 on the outer bpatcher is correctly declared.**

---

## Param split reference (A only vs A+B+C)

**A only (structural):** drift, offset, speed_var, regularity, phase, quantize, skip

**A + B + C (appearance):** mortar, softness, width, roundness, course_color, brick_color

---

## Files changed this session
- `.specify/f_masonry/spec.md` — Phase 5 rewritten for three-space model
- `.specify/f_masonry/plan.md` — ADR 6 added
- `.specify/f_masonry/tasks.md` — M001 superseded, M002 written
- `.specify/f_masonry/codebox_phase6.gen` — new codebox
- `patchers/f_masonry.maxpat` — codebox updated (phase6), pix numinlets=4
- `code/f_util_matrix_grid.js` — NUM_SOURCES 2→3, SOURCE_LABELS A/B/C
- `code/f_util_mod_handler.js` — C suffix routing added
