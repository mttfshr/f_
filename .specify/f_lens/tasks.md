# Tasks: f_lens

**Spec**: .specify/f_lens/spec.md
**Plan**: .specify/f_lens/plan.md
**Build order**: Sequential by phase. Complete each phase checkpoint before proceeding.

---

## Architecture Note (as-built, supersedes original spec)

Final architecture diverged from original spec during Phase 3/4:
- **5 inlets**: in0 (texture+ctrl), in1 (aberration mod), in2 (distortion mod), in3 (transmission mod), in4 (surface mod)
- **Surface** → gradient emboss (UV displacement via in5 gradient), not darkening multiply
- **Field** → split into 3 independent targets: aberration_mod, distortion_mod, transmission_mod
- **8 front dials**: aberration, distortion, transmission, tilt, tilt_axis, tilt_pos, slope, mode
- **4 back dials** (field panel): aberration_mod, distortion_mod, transmission_mod, surface_mod
- **lens/field toggle** button scripts visibility via lens_toggle.js → thispatcher script sendbox
- **lens_toggle.js** added to code/

---

## Phase 0: Feasibility ✅

- [x] T001–T006 Architecture decided and documented

---

## Phase 1: Radially Symmetric Effects ✅

- [x] T008–T013 aberration, distortion, transmission — all working in scratch patch

---

## Phase 2: Tilt-Shift ✅

- [x] T014–T019 jit.fx.cf.tiltshift wired and verified; lens_tiltcenter.js perpendicular fix applied

---

## Phase 3: in2/in3 Modulation ✅ (redesigned)

Original plan (surface_amt darkening + field_amt distortion) was replaced with:

- [x] T020 Codebox redesigned: aberration_mod, distortion_mod, transmission_mod, surface_mod
- [x] T021 distortion_mod: spatially varies k via in3 texture; neutral guard confirmed (black = no effect)
- [x] T022 surface_mod: gradient emboss via in5; UV displacement from in5 gradient; neutral guard confirmed
- [x] T023 aberration_mod: spatially varies ab via in2; neutral guard confirmed
- [x]      transmission_mod: spatially varies vignette dist via in4; neutral guard confirmed

---

## Phase 4: Build Script → f_lens.maxpat ✅

- [x] T024–T027 Build script written at ~/Vsynth/patterns/build_f_lens.py
- [x] T028 UI layout: front 8 dials (2 rows × 4), back 4 dials (1 row), lens/field toggle, bypass
- [x] T029 parameters block complete (bypass, panel_toggle, 8 front + 4 back dials)
- [x] T030 Build script runs clean; output written to patchers/f_lens.maxpat
- [x] T031 Opens in Max without errors; presentation layout correct; toggle verified working
- [x]      lens_toggle.js uses script sendbox (not script visible) — confirmed working

---

## Phase 5: Vsynth Integration and Composition ✅

- [x] T032 Load f_lens in Vsynth context with vs_noise_3 → in0; sweep each param
- [x] T033 Verify bypass passthrough
- [x] T034 Verify autopattr state save/restore
- [x] T035 Verify moduleSize.js chain reports correct size
- [x] T036 Test f_grain → f_lens → output
- [x] T037 Test f_grain → f_lens → f_stereo → output
- [x] T038 Test aberration_mod and distortion_mod inlets with f_grain and slow noise sources
- [x] T039 Test transmission_mod with slow noise
- [x] T040 Test surface_mod (emboss) with f_grain — verify micro-refraction character vs old darkening
- [x] T041 Test named float messages on in0 (aberration 0.5, tilt 0.8, etc.)
- [x] T042 Check frame rate: no significant GPU drop vs baseline

---

## Phase 6: Documentation

- [ ] T043 Write docs/f_lens.md — as-built reference
- [ ] T044 Update README.md: f_lens → ✅ Working
- [ ] T045 Update HANDOFF.md with session summary


---
---

# Tasks: f_lens v2 (ghost, halation, anamorphic)

**Spec**: `.specify/f_lens/spec.md` (v2 Scope section)
**Plan**: `.specify/f_lens/plan.md` (ADR-6)
**Build order**: Sequential. Complete each phase before the next.
**Scope**: v2 additions only (ghost images, halation, static +
field-driven anamorphic). Does NOT include tilt-shift removal — that's
gated on `f_focus` shipping first (see `.specify/f_focus/tasks.md` T029)
and isn't itself blocking v2 codebox work, since the new effects don't
touch the tilt-shift object.
**Commits**: After each phase checkpoint.

⚠️ **Phase 0 is a decision-making phase, not a build phase.** Per
plan.md ADR-6: "None of these are resolved yet — this ADR records the
scope decision, not a green light to start building." This task list
front-loads the open questions as explicit tasks so they get resolved
deliberately, in order, before any codebox work starts — rather than
getting improvised mid-build.

Note: the v1 task history above (Phase 0–6) remains as the historical
record of the original build. This v2 section is additive, appended
2026-07-15, and does not modify or supersede anything above it. v1's
own Phase 6 (Documentation) is still open — see Phase 5 below, which
folds that outstanding v1 doc debt into the v2 documentation pass rather
than tracking it twice.

---

## Expected Output Layout (v2 additions)

```
patchers/
  f_lens.maxpat                   — modified in place (existing file, not regenerated from scratch)

.specify/f_lens/
  spec.md                         — ✅ done (corrected 2026-07-15)
  plan.md                         — ✅ done (ADR-6)
  tasks.md                        — this file (v1 history + v2 section)

docs/f-reference/
  f_lens.md                       — as-built reference, still not written even for v1 (Phase 6 of the
                                     v1 task history above is still open) — first version of this file
                                     will need to cover both v1 and v2 state, see T037 below

~/Vsynth/patterns/
  lens_v2_scratch.maxpat          — scratch patch for ghost/halation/anamorphic verification (Phase 1–3, not committed)
```

---

## Phase 0: Resolve Open Architecture Questions (BLOCKING)

**Purpose:** Every question below is listed as open in `spec.md`'s "v2
open questions" section. None have been decided. Resolve each — with
Matt, in conversation, per standing "discuss architecture before writing
code" preference — before any task past this phase is started.

- [x] T001 **Vecfield inlet: driving vs. modulating?** RESOLVED 2026-07-15: bias/blend, via new `anamorphic_field_amt` dial (0-1, default 0.0). See spec.md Clarifications.
- [x] T002 **Vecfield inlet labeling convention.** RESOLVED 2026-07-15 — this convention was already documented (established 2026-07-12) in `vsynth-bpatcher/SKILL.md`'s "Vecfield labeling for non-f_vf_-prefixed modules" section, just not re-found before this task was written. Header `signal_type` = `"vecfield in"` (this is an inlet only, no outlet). `f_modules` menu nabla: add `"lens"` to `tools/append_nabla_menu.py`'s `VECFIELD_MODULES` set — already present there (added early, based on the old incorrect "field inlet" assumption; will become accurate once this inlet ships). No skill update needed.
- [x] T003 **Halation architecture.** RESOLVED 2026-07-15: second `jit.gl.pix` stage in series downstream of `lens_pix`, the same shape `jit.fx.cf.tiltshift` already occupies in this exact bpatcher — not a nested internal multi-pix bpatcher. No dedicated architecture scratch test needed: multi-object-in-series-within-one-bpatcher is already proven precedent (`f_lens`'s own tiltshift chain, `f_vf_advect`/`f_vf_seeds`), not a genuine unknown the way v1's three-inlet question was. The halation GLSL math (luma-gate → blur-accumulate → composite) still gets normal scratch verification as part of Phase 2's codebox-before-patcher work (T015–T017) — that's standard practice for any new codebox, not a special Phase 0 concern.
- [x] T004 **Ghost tap count vs. performance.** RESOLVED 2026-07-15: proceed on assumption, no dedicated Phase 0 profiling gate — matches the library's actual track record (no frame-rate hit yet across any multi-tap/multi-pass module shipped so far). Default `ghost_count` range **1–4, default 3**, per spec.md's original suggestion. Normal frame-rate verification happens in Phase 1's existing T014, same as every other module's build — not a special pre-check.
- [x] T005 **Panel layout at v2 scale.** RESOLVED 2026-07-15: all v2 params go on the front panel alongside the existing 8 — no third panel, no reorganized front/back split. Explicitly provisional (Matt's call) — a broader UI density refactor across all module layouts is in progress separately and will supersede whatever gets built here, so this isn't worth getting precious about now. Back panel's existing 4 `*_mod` dials stay as-is, untouched by this decision.
- [x] T006 Update `spec.md`'s v2 Scope section with concrete param tables (range/default/description) for all three effect families, replacing the current "candidate params" prose — this can only happen once T001–T005 are resolved, since several param shapes depend on those decisions (e.g. whether `anamorphic_axis` survives at all depends on T001). DONE 2026-07-15 — param tables written, "v2 open questions" section in spec.md updated to show all resolved.

**Checkpoint reached 2026-07-15: All five open questions resolved, param tables locked. → Phase 1 (Ghost Images) is next.**

---

## Phase 1: Ghost Images (Codebox Extension)

**Purpose:** Extends the existing `lens_pix` codebox in place — no new
render object, no new inlet. Lowest-risk of the three v2 features since
it reuses proven machinery (`warp_cx`/`warp_cy`).

**Dependencies:** T006 (concrete ghost param table)

- [x] T007 Opened scratch copy in Max, pasted ghost codebox — CONFIRMED 2026-07-15
- [x] T008 `Param ghost`, `Param ghost_count`, `Param ghost_spacing` added to codebox — CONFIRMED
- [x] T009 N-tap additive superposition using `warp_cx`/`warp_cy`, color-coupled to `ab` — CONFIRMED
- [x] T010 `ghost=0` → passthrough matches v1 exactly — PASS
- [x] T011 `ghost` swept up → visible attenuated offset copies along radial vector — PASS
- [x] T012 `ghost_count` changes tap count cleanly, no banding/popping at integer steps — PASS
- [x] T013 `ghost_spacing` changes offset scale between taps (including negative/inward-mirrored per the later bipolar-range decision) — PASS
- [x] T014 Frame rate at max `ghost_count` — PASS, no drop

**Checkpoint:** Ghost images working, no regression on v1 effects, frame rate acceptable. ✅ REACHED 2026-07-15.

**Unplanned but real work done alongside this checkpoint:** getting the
verified codebox into the *live* patcher surfaced that `definition.py`
was an incomplete/inaccurate record of the shipped module (missing
`mod_inlets` entirely; tilt-shift's real UI mischaracterized as
"internal"). Fixed properly rather than worked around — see
`build_patcher.py`'s new `raw_ui`/`raw_boxes`/`panel_toggle` support and
`ideas/build_patcher_schema_gaps.md`'s Resolution section for the full
story. `f_lens.maxpat` is now a genuine, verified, full regeneration
from `definition.py` for the first time — not a hand-edited JSON file
with an aspirational definition.py alongside it.

---

## Phase 2: Halation (Architecture Per T003 Decision)

**Purpose:** Build whichever architecture T003 decided on. This phase's
task shape depends entirely on that decision — the tasks below assume
the "second `pix_chain` stage" path since it's the more concrete of the
two options; if T003 chose the separate-multi-pix-bpatcher path instead,
revise these tasks accordingly before starting.

**Dependencies:** T003 (architecture decision), T006 (concrete halation param table)

- [x] T015 Luma-gate stage — implemented inline per-tap (8 fixed isotropic directions, single radius, each independently re-deriving luma/threshold since no intermediate gated buffer is possible within one codebox pass) — CONFIRMED 2026-07-15
- [x] T016 Blur-accumulate stage — 8-direction unrolled (not a `for` loop like `f_vf_glow`'s, since GenExpr has no dynamic array indexing to loop over multiple fixed directions) — CONFIRMED
- [x] T017 Additive warm-shifted composite — CONFIRMED, `warm_r/g/b = 1.1/1.0/0.85`
- [x] T018 `halation=0` → passthrough matches Phase 1 output — by construction (multiply-by-zero on the composite step); architecture (separate `jit.gl.pix` stage per T003) built and regenerated into the live patcher
- [x] T019 Verify in Max: `halation` swept up → warm glow visible around bright regions only — CONFIRMED 2026-07-15
- [x] T020 Verify in Max: `halation_threshold` correctly gates which regions bloom — CONFIRMED
- [x] T021 Verify in Max: no interaction artifacts between halation and ghost (both active simultaneously) — CONFIRMED, visible in the same test grid (ghost/aberration fringing compounding cleanly toward frame edges alongside halation's glow, no artifacts)
- [x] T022 Check frame rate with halation active — CONFIRMED 60+ fps at 8-tap single-ring. Given the headroom, upgraded to a **second radius ring** (16 directions × 2 radii = 48 texture samples total, weighted `w1=1.0`/`w2=0.5` falloff between rings, same weighting shape as `f_vf_glow`'s radius falloff) for a softer glow — regenerated and redeployed 2026-07-15. Re-confirmed 59-60fps at the doubled sample count — no measurable cost, plenty of headroom remains.

**Checkpoint: ✅ REACHED 2026-07-15.** Halation fully verified in Max — correct visual behavior (glow, threshold gating, clean composition with ghost/aberration), 59-60fps sustained even at the 2-ring/48-sample version. Phase 2 complete.

---

## ~~Phase 3: Anamorphic (Static + Field-Driven)~~ — REMOVED 2026-07-15

Anamorphic (both static and field-driven variants) moved out of
`f_lens` v2 scope entirely — see `spec.md` Clarifications for the
removal rationale. Concept, param contract, and the vecfield
hemisphere-alignment mechanism preserved in
`ideas/f_anamorph_unnamed.md` for whenever that module gets specced as
its own build. Original task list kept below, struck through, for
history:

~~**Purpose:** Static anamorphic extends existing distortion math; field-driven adds the new vecfield inlet.~~

~~**Dependencies:** T001 (driving-vs-modulation decision), T002 (labeling convention), T006 (concrete param table)~~

~~- [ ] T023 Implement static anamorphic: `anamorphic` + `anamorphic_axis` params, per-axis multiplier on the existing `(1.0 + k*r2)` distortion scale~~
~~- [ ] T024 Verify: `anamorphic=0` → no change from Phase 2 output~~
~~- [ ] T025 Verify: `anamorphic` swept with `anamorphic_axis` at various angles → visible directional squeeze along the chosen axis~~
~~- [ ] T026 Add new vecfield inlet at bpatcher-level in5 (`lens_pix in6`, per spec.md's corrected inlet numbering) — texture-only, per T002's labeling decision~~
~~- [ ] T027 Wire vecfield inlet per T001's driving-vs-modulation decision — either full override of `anamorphic_axis` direction when connected, or a bias/blend, whichever was decided~~
~~- [ ] T028 Verify: vecfield inlet unconnected → behaves identically to static-only anamorphic (T023–T025 results unchanged)~~
~~- [ ] T029 Verify: vecfield inlet connected to an `f_vf_` producer (e.g. `f_vf_vortex`) → squeeze direction varies per-pixel per the field, per T001's decided behavior~~
~~- [ ] T030 Confirm no naming collision with existing inlets — final check against all inlet comments in the live patcher (per spec.md's note that this concern "no longer applies as stated" but should be reconfirmed, not assumed)~~

---

## Phase 4: Full Integration and Regression

**Purpose:** Confirm the whole v2-expanded module still satisfies v1's original acceptance criteria, not just the new ones (now: ghost + halation only, anamorphic removed from scope).

- [x] T031 Re-run all v1 acceptance criteria from spec.md (aberration/distortion/transmission/mod-texture behaviors) — confirm zero regression from Phases 1–2. CONFIRMED 2026-07-16.
- [x] T032 Test both new effect families (ghost, halation) active simultaneously with all v1 effects active — confirm no unexpected interaction, no GL errors. CONFIRMED.
- [x] T033 Full frame-rate check with everything maxed — this is the real cost question the individual phase checks (T014, T022) only partially answer. CONFIRMED — 59-60fps sustained.
- [x] T034 Confirm UI per T005's panel-layout decision — all params reachable, panel(s) render correctly, `moduleSize.js` reports correct size. CONFIRMED.
- [x] T035 Verify autopattr save/restore across the full expanded param set. CONFIRMED — first real test of range-tier menu state persistence, passes.
- [x] T036 Save/reload cycle in a real Vsynth session. CONFIRMED.

**Checkpoint: ✅ REACHED 2026-07-16.** Full regression pass clean. `f_lens` v2 (ghost + halation) is complete, verified, and stable — ready for Phase 5 (docs/registration).

**Known issue, not fixed:** this Phase 4's task IDs (T031–T036) collide with the v1 history section's own T031–T036 above (line ~58) — v2's numbering restarted at T001 instead of continuing after v1's highest number. Ambiguous if referenced by ID alone across sections; disambiguate by phase name when discussing, until a renumbering pass happens (not scheduled).

---

## Phase 5: Docs and Registration

- [x] T037 Write/update `docs/f-reference/f_lens.md` — as-built reference covering both v1 and v2 in one document (v1 docs were never written per the v1 task history's Phase 6 above — this is the first real doc for this module, covering its full current state). DONE 2026-07-16 — file already existed but was stale (its own "Loose Threads" section flagged tilt-shift as unconfirmed wiring, resolved this session by direct inspection); fully rewritten to match shipped v2.
- [x] T038 Update `README.md` bpatcher table — `f_lens` description updated to mention ghost/halation. DONE — also fixed a separate long-stale claim in the vecfield-family table row that `f_lens` has a vecfield-consuming "field inlet" (never true, confirmed against the live patcher early this session).
- [x] T039 Update `.maxhelp` file per `f-helpfile` skill conventions to cover the new effects. DONE — file already existed but predated tilt-shift being wired at all; External Control Messages block and References block both rewritten for full v2 param set, rect/linecount math recomputed to fit the fixed-height panel.
- [x] T040 Update `HANDOFF.md` — session summary. DONE.

**Bonus fix (Matt's catch, not originally in this task list):** `f_modules.maxpat`'s "Lens ∇" nabla — leftover from the same stale "field inlet" assumption fixed in T038 — removed from both the live menu and `tools/append_nabla_menu.py`'s `VECFIELD_MODULES` set (so it won't silently re-add itself on a future menu regeneration).

**Checkpoint: ✅ REACHED 2026-07-16. `f_lens` v2 is fully complete — built, verified, and documented.**

---

## Dependencies

**Phase dependencies (strict):**
- Phase 0 → everything: no codebox work starts until all five open questions are resolved and documented
- Phase 1 (ghost) has no dependency on Phase 2 — could be built first in isolation
- Phase 2 (halation) depends on T003's architecture decision specifically, independent of Phase 1's completion
- Phase 4 requires Phases 1–2 complete (regression check needs everything built)
- Phase 5 requires Phase 4 checkpoint

**Real parallel opportunity:** Phases 1 and 2 don't depend on each other's *implementation*, only on their respective Phase 0 sub-decisions. If Matt wants to parallelize architecture discussion (T001–T005 don't depend on each other either), all five could be resolved in one session rather than sequentially — the sequential numbering here is for clarity, not a hard ordering requirement within Phase 0.

---

## Notes (v2)

- This task list's Phase 0 is unusual for this project's tasks.md convention (which normally starts with a feasibility *build* phase, not a pure decision phase) — justified here because ADR-6 explicitly said these decisions weren't made yet, unlike `f_focus`'s Phase 0 which was a build-verification gate for an already-decided architecture.
- T009 and T016 both call out reference-reading-rule checks (verify `warp_cx`/`warp_cy` naming, verify `f_vf_glow`'s actual codebox) rather than trusting spec.md's paraphrased description — spec.md was itself corrected once already this session for exactly this kind of staleness, worth staying skeptical of any single doc as the last word once codebox work actually starts.
- T037 is notable: this will be the first `docs/f-reference/f_lens.md` ever written for this module — v1 shipped without it. Worth flagging to Matt as its own small piece of debt being paid down here, not just a formality.
- **Anamorphic removed from scope entirely, 2026-07-15** (both static and field-driven variants) — moved to `ideas/f_anamorph_unnamed.md`. Original Phase 3 kept struck-through above for history. Task numbers T023–T030 are permanently retired from this file's v2 section, not reused.
- Commit after Phase 0 (decisions recorded), after each of Phases 1–2, and after Phase 5.
