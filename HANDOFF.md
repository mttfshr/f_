# HANDOFF — f_ session 2026-05-31

## Status
Clean. All committed work passing. No broken state.

---

## What was completed this session

### Tech debt audit and resolution
Full audit of all active patchers against current vsynth-bpatcher conventions.
Four debt axes identified and paid:

**`prepend param` → `attrui`** (all patchers)
141 boxes migrated across 13 patchers. `build_patcher.py` updated to generate
`attrui` going forward. `tools/migrate_to_attrui.py` added for future reference.
`src_mode` correctly left as `prepend` (system-driven, intentional).

**Missing `routepass` on 4 processor patchers**
`f_channel_grader`, `f_hue_processor`, `f_luma_processor`, `f_tone_curve` all had
`inlet → route` directly — texture path broken entirely. Fixed by inserting
`routepass jit_gl_texture jit_matrix` in each. `tools/add_routepass.py` added.

**Missing `autopattr` on `f_droste`**
Added `autopattr @varname droste_autopattr`.

**Missing `vs_inState` on `f_grain` and `f_masonry`**
Both patchers now use `vs_inState` + `vs_black` fallback. Draw when unconnected.
`Param src_mode(0.0)` prepended to both codeboxes. `tools/add_instate.py` added.

All patchers opened and verified working in Max after migration.

### f_lens Phase 5
Vsynth integration testing passed. README updated (was already marked Working —
Phase 5 confirmation now on record).

### README / status table
`f_stipple` added to status table (was missing). Removed from build queue.
`f_masonry` naming note: pix object has `@name weave_pix` — pre-existing
inconsistency, not introduced this session. Not fixed (low priority).

### f_util_profile spec + plan + tasks
Full spec locked:
- Output: always `1×128` GL texture (fixed dimensions)
- `resolution` param (1–128, default 64): CPU-side analysis sharpness via
  interpolation — real-time modulatable, does not change output dimensions
- `freq` param (1–64, default 8): sync vocabulary only, not used internally
- Bypass: freeze last computed profile; 0.5 flat on first load
- Architecture: `jit.gl.asyncread` → `js profile_compute.js` → `jit.gl.texture`
- New archetype: no `jit.gl.pix`, CPU-side only, hand-built JSON (no build script)

Plan written with 6 ADRs. Tasks written T001–T039 across 5 phases.

---

## Recommended next session

### Start: f_util_profile Phase 1 (T001–T008)
Build the scratch patch and prove the GPU→CPU→GPU round trip.

Four open questions Phase 1 will answer:
1. Does `jit.gl.asyncread` need `@drawto vsynth` to read from the right context?
2. Is asyncread output `char` (0–255) or `float32`? (Affects JS normalization)
3. Is `f_/code/profile_compute.js` found by Max when bpatcher loaded from `patchers/`?
4. `jit.gl.texture @name` collision strategy for multiple instances — defer to Phase 4

### Then: f_util_profile Phase 2 (T009–T016)
Aggregation and interpolation in JS. f_masonry as upstream texture for verification.

### Remaining backlog (lower priority)
- `f_chladni` signal chain — EEG/spectral driving via muse.maxpat
- `f_util_envelope` — spec alongside or immediately after profile build; needed
  once profile is producing raw signal
- `f_masonry` pix naming: `@name weave_pix` should be `masonry_pix` — trivial
  fix but requires closing the patcher first

---

## Files changed this session
- `patchers/*.maxpat` — all 13 active patchers (attrui migration + routepass + instate)
- `tools/build_patcher.py` — prepend_box → attrui_box
- `tools/migrate_to_attrui.py` — new
- `tools/add_routepass.py` — new
- `tools/add_instate.py` — new
- `README.md` — f_stipple added, f_lens Phase 5 noted, build queue updated
- `.specify/f_util_profile/spec.md` — new (gitignored)
- `.specify/f_util_profile/plan.md` — new (gitignored)
- `.specify/f_util_profile/tasks.md` — new (gitignored)

## Git log this session
```
80b2a1d README: add f_stipple to table, remove from build queue; f_lens Phase 5 confirmed
416de72 tech debt: autopattr on f_droste, vs_inState on f_grain + f_masonry
deb9646 add routepass to 4 processor patchers missing texture/control separation
01ab900 migrate prepend param → attrui across all patchers and build script
```
