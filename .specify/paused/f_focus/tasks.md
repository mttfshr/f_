# Tasks: f_focus

**Spec**: `.specify/f_focus/spec.md`
**Plan**: `.specify/f_focus/plan.md`
**Build order**: Sequential. Complete each phase before the next.
**Scope**: Phase 1 (tiltshift extraction) only. Phase 2 (focus-map
gather-blur) is out of scope for this task list — per plan.md ADR-2,
its architecture isn't decided yet and it isn't blocking Phase 1.
**Commits**: After each phase checkpoint.

---

## Expected Output Layout

```
patchers/
  f_focus.maxpat                  — built by build script from definition.py

.specify/f_focus/
  spec.md                         — ✅ done
  plan.md                         — ✅ done
  tasks.md                        — this file
  definition.py                   — authored in Phase 1, input to build script

docs/f-reference/
  f_focus.md                      — as-built reference (Phase 4)

~/Vsynth/patterns/
  focus_scratch.maxpat            — scratch patch for verification (Phase 0, not committed)
```

---

## Phase 0: Feasibility Check (BLOCKING)

**Purpose:** Confirm `jit.fx.cf.tiltshift` behaves identically standing
alone as it did inside `f_lens` — low risk per plan.md, but not zero
risk, since it's never been wired as the sole render object in a
bpatcher before (previously always downstream of `lens_pix`).

⚠️ Do not write `definition.py` until this is confirmed.

- [x] T001 Open scratch patch at `~/Vsynth/patterns/focus_scratch.maxpat` — add `vs_render` bpatcher and toggle to start render clock
- [x] T002 Add `jit.fx.cf.tiltshift vsynth` as the sole render object, no upstream `jit.gl.pix` — wire a test source (noise, WFG, or video) directly to its inlet
- [x] T003 Confirm it renders correctly standing alone (no GL errors, output visible) — CONFIRMED 2026-07-17, works fine as sole render object
- [x] T004 Confirm all five params (`blur_amount`, `angle`, `center`, `mode`, `slope`) respond as they did inside `f_lens` — CONFIRMED 2026-07-17
- [x] T005 Confirm whether `jit.fx.cf.tiltshift` has its own native `@bypass`-style attribute. **RESOLVED 2026-07-17: it does — the object exposes a native `bypass` boolean attribute directly.** Simpler than expected: no external raw/processed gate needed, `bypass` param just routes straight to the object's own `@bypass` attribute like any other param. Supersedes the "needs external gate" expectation written into this task earlier the same session.

**Checkpoint:** `jit.fx.cf.tiltshift` confirmed working standalone, same behavior as inside `f_lens`. No surprises. → Proceed to Phase 1.

---

## Phase 1: definition.py and Build

**Purpose:** Author the build input and generate the patcher.

- [ ] T006 Write `.specify/f_focus/definition.py` — single render object (`jit.fx.cf.tiltshift vsynth`), standard single inlet (texture+control), standard single outlet
- [ ] T007 Define params in `definition.py`: `blur` (live.dial, 0–1, default 0.0, maps to `blur_amount`), `axis` (live.dial, 0–1, default 0.0, maps to `angle`), `pos` (live.dial, 0–1, default 0.5, maps to `center`), `slope` (live.dial, 0–1, default 0.5, maps to `slope`), `mode` (live.menu or live.text enum, linear/radial, default linear, maps to `mode`), `bypass` (standard bypass toggle)
- [ ] T008 Confirm route object dispatches each param to its correct `jit.fx.cf.tiltshift` attribute name via `prepend` (param names differ from attribute names — `blur`→`blur_amount`, `axis`→`angle`, `pos`→`center` — get this mapping right, it's the one place a typo would silently no-op a control)
- [ ] T009 Confirm standard Vsynth wrapper present: `routepass jit_gl_texture jit_matrix` on the single inlet, `autopattr @varname focus_autopattr`, `bypass_toggle.js` jsui, `moduleSize.js` chain, title comment + background panel
- [ ] T010 Run build script: `python3 tools/build_patcher.py .specify/f_focus/definition.py` (or equivalent per current `build_patcher.py` invocation convention — check `tools/build_patcher.py` usage if unfamiliar, don't assume the same invocation as older custom build scripts)
- [ ] T011 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_focus.maxpat'))"` — must pass with no errors

**Checkpoint:** Valid `f_focus.maxpat` generated. No structural errors.

---

## Phase 2: JSON Inspection

**Purpose:** Verify generated structure before opening in Max, per house convention (JSON inspection before Max round-trip).

- [ ] T012 Inspect `jit.fx.cf.tiltshift` object: confirm `numinlets: 1`, `numoutlets: 1`
- [ ] T013 Inspect bpatcher inlet/outlet count: confirm single inlet, single outlet
- [ ] T014 Inspect route object args: confirm `blur`, `axis`, `pos`, `slope`, `mode` present; confirm `bypass` handled separately (matches `f_lens`'s own bypass pattern — check that pattern directly in `f_lens.maxpat` rather than assuming, since bypass wiring for a single-object bpatcher may differ from `f_lens`'s two-object bypass)
- [ ] T015 Inspect parameters block: confirm all six params (`blur`, `axis`, `pos`, `slope`, `mode`, `bypass`) registered
- [ ] T016 Inspect presentation layer: confirm dials/menu present, panel sized correctly, title "Focus" (or agreed display name — confirm with Matt if `f_focus` bpatcher title should read "Focus" or something else before finalizing)

**Checkpoint:** Structure correct. Ready to open in Max.

---

## Phase 3: Vsynth Integration Testing

**Purpose:** Open in live Vsynth patch, verify all acceptance criteria from spec.md.

- [ ] T017 Open Vsynth patch; add `f_focus` as bpatcher; confirm loads without errors or console warnings
- [ ] T018 Verify passthrough: all params at default → visually unchanged from source
- [ ] T019 Sweep `blur` with `axis` at 45°; confirm visible sharp band crossing the frame diagonally, blurring above/below it
- [ ] T020 Sweep `axis`; confirm band rotates
- [ ] T021 Sweep `pos`; confirm band moves along the axis
- [ ] T022 Toggle `mode` between linear and radial; confirm band-vs-radial-falloff character switches correctly
- [ ] T023 Sweep `slope`; confirm sharp/gradual transition control
- [ ] T024 Enable `bypass`; confirm raw texture passthrough
- [ ] T025 Test in place of where `f_lens`'s tilt-shift previously sat in an existing chain (e.g. `f_grain → f_focus → f_stereo → output`) — confirm no loss of character versus the old in-`f_lens` version
- [ ] T026 Save Vsynth patch and reload; confirm `f_focus` reopens correctly with params restored, no crash
- [ ] T027 Check frame rate: no significant GPU drop versus baseline (should be near-identical to `f_lens`'s prior tilt-shift cost, since it's the same object)

**Checkpoint:** All acceptance criteria from spec.md pass. Survives save/load cycle.

---

## Phase 4: Docs and Registration

**Purpose:** Update permanent project records. Nothing here until Phase 3 checkpoint is confirmed.

- [ ] T028 Write `docs/f-reference/f_focus.md` — as-built reference: params table, signal chain summary, usage notes, note that this replaces `f_lens`'s former tilt-shift
- [ ] T029 Update `README.md` bpatcher table — add `f_focus` row; update `f_lens`'s own README row to remove "tilt-shift" from its description once `f_lens` v2 actually ships the removal (do NOT remove tilt-shift from `f_lens`'s live patcher as part of this task list — that's `f_lens` v2 work, tracked separately, not implied by `f_focus` shipping)
- [ ] T030 Add `f_focus` to the appropriate category in `.specify/f_modules/build_modules.py` (likely Optical, alongside `f_lens`)
- [ ] T031 Add size entry for `f_focus` to `SIZES` dict in `javascript/f_addmod.js` — get dimensions from `presentation_rect` of background panel in generated patcher JSON
- [ ] T032 Regenerate `patchers/f_modules.maxpat`: run `.specify/f_modules/build_modules.py`; validate JSON; confirm new category entry
- [ ] T033 Write `.maxhelp` file per `f-helpfile` skill conventions
- [ ] T034 Update `HANDOFF.md` — what was done, what's next

**Checkpoint:** README updated, f_modules includes f_focus, docs and helpfile written. Ready to commit.

---

## Dependencies

**Phase dependencies (strict):**
- Phase 0 → Phase 1: standalone behavior confirmed before writing definition.py
- Phase 1 → Phase 2: valid patcher JSON before inspection
- Phase 2 → Phase 3: structure confirmed before opening in Max
- Phase 3 → Phase 4: acceptance criteria confirmed before docs

**No cross-phase parallelism** — each phase gate is hard, though phases are short given the low-risk nature of this build.

---

## Notes

- This is a near-mechanical port (per plan.md) — the main real risk is Phase 0's T003 (never tested `jit.fx.cf.tiltshift` as the sole render object before). If that fails unexpectedly, stop and reassess before continuing — plan.md's "low risk" framing assumed this would just work.
- T009/T014 flag two places where this task list intentionally says "check `f_lens.maxpat` directly, don't assume" rather than presuming the pattern carries over — matches the reference-reading-rule; `f_lens`'s own bypass/wrapper wiring around tiltshift hasn't been independently re-verified since the corrected codebox reading in this session, only the codebox itself was.
- T029 exists to explicitly prevent scope creep: shipping `f_focus` does NOT mean removing tilt-shift from the live `f_lens.maxpat` — that removal is `f_lens` v2 work and has its own (currently unwritten) task list, gated on the open architecture questions in `f_lens/spec.md`.
- Commit after Phase 2 checkpoint and again after Phase 4.
