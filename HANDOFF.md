# HANDOFF

_Session: 2026-07-18 (continued, long session — picked up mid-`f_vf_optical_flow` build and carried it through to Phase 6 completion)_

## Start Here — Next Session

Read `README.md` → this file → `.specify/plan.md`.

**`f_vf_optical_flow` is now functionally complete through Phase 6** (docs/registration). All six phases done, checked into `tasks.md` with real findings, not just checkboxes. Two honest rough edges remain (see below) — not blockers, just known limitations worth remembering. **Nothing from this session is committed yet** — see Committed state at bottom.

---

## This session, in order

Continued directly from the prior HANDOFF's "module not stable" state through Stage E's build and all of Phase 6. Full blow-by-blow in `.specify/f_vf_optical_flow/tasks.md` — headline points:

### `step` naming question — resolved
The two-session-old open question (does a `Param` named `step` collide with GenExpr's built-in `step()` operator) was tested directly in the built module rather than left to ride further: added it as a real live dial, confirmed via visible dial-driven changes in Max that it does **not** collide. Promoted from temporary test to a permanent control (bipolar range -0.1–0.1).

### Edge-banding artifact — found, fixed, one honest rough edge left
Real testing surfaced a genuine artifact: any nonzero `scale` produced banding at frame edges. Root-caused to `sample()`'s always-clamp behavior at texture boundaries (boundmode args silently ignored on this GPU path) creating a biased asymmetric derivative near borders. Fixed in `codebox_stage_a.gen` by zeroing `Ix`/`Iy` within an edge margin — Stage C's existing `mask_lo`/`mask_hi` gate then naturally treats that as "no data," no separate masking mechanism needed. **Confirmed improved, not fully resolved:** the hard cutoff now produces a visibly blank/dead border rather than a graceful falloff. Matt's call: note it, move on. Real fix when revisited: soften to a `smoothstep`-based falloff.

### Phase 5 — Stage E (confidence-gated directional fill) — built and confirmed
The aperture-problem failure mode (perfectly axis-aligned content makes the LK solve exactly singular — confirmed directly via a WFG at Angle=0°/90°, ruled out as source-specific by swapping sources) is scoped as a real internal fix, not a downstream module (Matt's call). Went straight for the directional-propagation mechanism (Matt's call, skipping an isotropic-blur first pass):

- **T035**: derived the locally-ambiguous axis via a standard structure-tensor double-angle result (`cos2θ`/`sin2θ` from `Sxx`/`Syy`/`Sxy`), packed into Stage C's previously-decorative `out2` y/z channels. Double-angle specifically to avoid a wraparound discontinuity an axis (vs. a directed vector) would otherwise hit. Confirmed smooth/continuous directly in Max (`f_vf_advect`/`f_vf_prism` consuming it showed no discontinuities).
- **T036**: built Stage E itself — 4-tap directional sampling along that axis, confidence-weighted average (reusing Stage C's own `mask_lo`/`mask_hi`, not a duplicate pair), neutral fallback, `mix_pct` global dry/wet. Inserted C→E→D (spatial fill before temporal accumulation, Matt's call) — this shifted every downstream hardcoded obj id in `definition.py`, all recomputed and verified against the actual built patchlines, not just JSON validity.
- **T037/T038**: confirmed directly in Max — the Angle=0°/90° case now shows real, plausible flow instead of flat; real Vsynth kaleidoscope content (polarizer → Optical Flow → Advect/Prism) read as coherent and pleasing. T038 was called done on the strength of this same test rather than a dedicated live-camera/`f_vf_warp` re-check — worth knowing if `f_vf_warp` behavior in particular ever gets its own follow-up look.
- One clarification worth remembering: with `mask_lo` near 0, most richly-textured content already reads high-confidence, so `reach`'s effect can look subtle in busy scenes even when working correctly — it only dominates in genuinely low-confidence regions. Not a bug.

### Phase 6 — docs and registration — done, after a real mid-session mistake, caught and corrected
- `docs/f-reference/f_vf_optical_flow.md` written fresh (params, both outlets explained, aperture-problem handling, honest Notes on the remaining edge-framing and untested-fast-motion limitations).
- `README.md` bpatcher table entry added — **as Processor**, not Generator (matches `definition.py`'s own `archetype` field; caught and fixed a mislabel mid-session before it shipped).
- `f_addmod.js` SIZES entry added (190×130, matching `definition.py`'s own presentation size).
- `f_vf_optical_flow.maxhelp` written from scratch, closely modeled on `f_vf_fieldmap.maxhelp` (closer structural match than the skill's own `f_droste.maxhelp` template, since this module — like fieldmap — has no separate scalar/LFO inlet). Built the JSON programmatically (via a throwaway script, deleted after use) rather than hand-edited, specifically to get line counts/rect heights and the real per-param object ids exact — pulled the actual `obj-N` ids straight from our own built `.maxpat` rather than hand-computing them.

**A real mistake happened here, worth remembering precisely.** First attempt at registering the module in `f_modules.maxpat` used `build/tools/f_modules/build_modules.py` — its `CATEGORIES` list only knew 5 categories, but the live file has genuinely evolved to 8 (`Scope`, `Discrete`, `Spatial`, `Optical`, `∇ Generators`, `∇ Processors`, `Color / Tone`, `Utilities`), with nabla suffixes maintained by a separate script (`tools/append_nabla_menu.py`) editing the live file directly. Running the stale generator overwrote all of that real, evolved structure — 706 deletions in the diff, wiping out nablas and category reorganization from past sessions. **Matt caught this immediately** ("f_modules has reverted back to the old organization... you must have been working from an outdated script"). Reverted cleanly via `git checkout` before anything else was touched.

Root cause fully chased down, not just reverted-and-avoided: the real source of truth is `tools/rebuild_modules_menu.py`, which had its own stale hardcoded output path (identical bug class to `build_modules.py`'s — both predate a repo reorg) and was also missing the `∇` prefix on its two nabla-category labels (`"Generators"` vs. the real `"∇ Generators"`). Both fixed; verified via a dry run written to a scratch path and diffed field-by-field against the live file *before* running for real, given the mistake that had just happened. Added the new entry to `∇ Processors` (Matt's call — matches its actual neighbors: `Flow`, `Caustic`, `Advect`, `Warp`, `Streak`, `Glow`, `Chroma`, `Repulse`, `Fieldmap`; declined the tempting "Optical" category despite the name coincidence, since that category is thematically lens/prism effects, not vecfield tech). Final real diff: exactly 8 insertions/8 deletions — the intended addition, plus an incidental fix of a pre-existing duplicate `'Chladni ∇'` entry in slot 0 that predates this session entirely (flagged to Matt, left fixed rather than reintroduced).

**`build/tools/f_modules/build_modules.py` is now confirmed stale and superseded by `tools/rebuild_modules_menu.py` — should not be run again** until/unless its `CATEGORIES` is reconciled against reality or the script is retired outright. Its own output-path bug was fixed in passing during an earlier part of this session, but that fix does not make the script safe to use — its category taxonomy is the real, separate problem, and conflating "path is fixed" with "script is correct" is exactly what nearly caused lasting damage here.

### Also noticed, not yet fixed
The `f-helpfile` skill's own doc says helpfiles live at `/Users/matt/Github/f_/help/` — actual location is `/Users/matt/Github/f_/package/help/`. Same class of staleness as the build-tooling path bugs above, just in a skill doc rather than executable code. Didn't fix the skill file itself this session (out of scope for this build), just worked around it by finding the real path directly.

---

## Loose threads / open items for next session

- **T024c (edge-framing softening)** — carried forward, not closed. Real next step: `smoothstep`-based falloff instead of the current hard `step()` cutoff at frame borders. Also still open from when this was found: whether the falloff width should be based on `scale` alone or `scale + step` combined.
- **T025 (fast-motion breakdown)** — still genuinely untested, not just deferred. Single-scale LK is expected to degrade on large frame-to-frame displacement; this was never explicitly tested against real fast motion this build. Documented as an honest known-limitation in the new reference doc, not as a confirmed finding.
- **T038's real scope** — called done on kaleidoscope-content evidence, not a dedicated `f_vf_warp`/live-camera re-check. Low-priority, but worth knowing if `f_vf_warp` behavior specifically ever needs its own look.
- **Chladni's duplicate menu entry — deduplication may have been load-bearing, revisit before assuming it's just a stray fix.** Matt's hypothesis: `live.menu` may have a quirk where a single-item enum breaks index-based selection (needs 2+ items to select correctly, or similar), and the duplicate `'Chladni ∇'` entry removed this session might have been an intentional workaround rather than an accidental leftover. Worth testing directly in Max (does selecting "Chladni" from its menu slot still work correctly with only one real entry now) before treating last session's dedup as a clean win. Not urgent — can wait.
- **Stale build-tooling paths — a real pattern now, not a one-off.** Three separate instances found this session: `build_modules.py`'s output path, `rebuild_modules_menu.py`'s output path, and the `f-helpfile` skill's stated helpfile location — all off by the same repo-reorg-shaped gap. Worth a deliberate audit of remaining build/tool scripts for the same issue rather than continuing to find them one at a time when they bite.
- **`build/tools/f_modules/build_modules.py` should be reconciled against reality or retired** — confirmed stale and superseded by `tools/rebuild_modules_menu.py` this session (see Phase 6 above for the near-miss that revealed this). Leaving both scripts present risks a repeat of tonight's mistake for whoever reaches for the wrong one next.
- **Uncommitted work — now substantial.** Nothing from this session or the last two has been committed. `.specify/f_vf_optical_flow/` (all `.gen` files including new `codebox_stage_e.gen`, `definition.py`, `tasks.md`, `plan.md`), `package/patchers/f_vf_optical_flow.maxpat`, `package/patchers/f_modules.maxpat`, `package/javascript/f_addmod.js`, `package/help/f_vf_optical_flow.maxhelp`, `docs/f-reference/f_vf_optical_flow.md`, `README.md`, `build/tools/f_modules/build_modules.py` (path fix only — script itself confirmed stale, see above), `tools/rebuild_modules_menu.py` (path fix + new entry + label fix), and `tools/append_nabla_menu.py` (new module added to its set) all have real, tested changes sitting uncommitted. Strongly worth committing before anything else piles on top — suggested split (Matt's call, as always): one commit for the `step`/edge-banding fixes, one for Stage E, one for Phase 6 docs/registration (including the `tools/` script fixes and the module-menu update), one for the `build_modules.py` path fix alone (unrelated to optical flow itself, and arguably moot now that the script is confirmed stale).
- All items from three sessions ago (repo reorg follow-up, `.specify/stable`/`paused` re-audit, `f_vf_warp` out2/bypass bug, `f_vf_streak` status question, `jit-gen-codebox` skill's own stale path reference, the feedback-loop-needs-a-cycle lesson not yet promoted to that skill file) are unchanged — not re-touched this session.

## Committed state

Not committed. See "Uncommitted work" above for suggested commit split — now four logical commits' worth, not one.
