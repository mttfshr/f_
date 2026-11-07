# Tasks: f_vf_warp

**Spec**: `.specify/f_vf_warp/spec.md`
**Plan**: `.specify/f_vf_warp/plan.md`
**Build order**: Sequential. Complete each phase before the next. Phase 1 is the hard gate.
**Commits**: After each phase checkpoint.

---

## Expected Output Layout

```
patchers/
  f_vf_warp.maxpat              — built by build_patcher.py from definition.py

.specify/f_vf_warp/
  spec.md                       — ✅ done
  plan.md                       — ✅ done
  tasks.md                      — this file
  definition.py                 — authored in Phase 2, input to build script

docs/
  f_vf_warp.md                  — as-built reference (Phase 5)

~/Vsynth/patterns/
  vf_warp_scratch.maxpat        — scratch patch for codebox verification (Phase 1, not committed)
```

---

## Phase 1: Codebox Verification (BLOCKING)

**Purpose:** Write and verify the warp GLSL in a scratch patch before touching the build system. This is the hard gate — the codebox is frozen after this phase.

⚠️ CRITICAL: Do not write definition.py until the codebox is confirmed working.

- [x] T001 Open scratch patch at `~/Vsynth/patterns/vf_warp_scratch.maxpat` — add `vs_render` bpatcher and toggle to start render clock
- [x] T002 Add `jit.gl.pix vsynth @name vfwarp_pix` with two texture inlets; wire a test source (noise or video) to in0 and `f_vf_vortex` to in1
- [x] T003 Add gen subpatcher with `in 1` (source texture) and `in 2` (vecfield texture) objects; reference `in2` in codebox code first (this makes the codebox inlet appear), then wire both `in N` gen objects to their respective codebox inlets — neither `numinlets` on pix nor on codebox is settable
- [x] T004 Paste the following confirmed codebox into the gen subpatcher:

  ```
  Param strength(0.1);
  Param src_vecfield(0.0);
  Param bypass(0.0);

  uv = norm;

  // Sample field channels inline — never store vec and access component
  field_x = sample(in2, uv).x;
  field_y = sample(in2, uv).y;

  // Remap [0,1] → [-1,1], scale by strength
  offset_x = (field_x - 0.5) * 2.0 * strength;
  offset_y = (field_y - 0.5) * 2.0 * strength;

  // Suppress offset when vecfield inlet is unconnected (vs_black → field=0 → offset=-strength without this)
  offset_x = mix(0.0, offset_x, step(0.5, src_vecfield));
  offset_y = mix(0.0, offset_y, step(0.5, src_vecfield));

  // Displace UV and clamp to edge
  warped_x = clamp(uv.x + offset_x, 0.0, 1.0);
  warped_y = clamp(uv.y + offset_y, 0.0, 1.0);
  warped_uv = vec(warped_x, warped_y);

  // Output — sample inline, no stored vec component access
  out1 = mix(sample(in1, warped_uv), sample(in1, uv), bypass);
  ```

  **Verified in scratch patch 2026-06-07:** warp visible, strength scales correctly, edge clamp confirmed, suppression logic correct.
- [x] T005 Add float number boxes for `strength` and `src_vecfield` wired to pix in0 via `prepend param`; verify codebox compiles (no errors in Max console)
- [x] T006 Verify: warp is visible with f_vf_vortex connected; strength=0 gives no warp; strength=1 gives strong distortion scaling smoothly
- [x] T007 Verify: set src_vecfield=0 — output matches source exactly (zero offset); set src_vecfield=1 — warp active; confirm the mix/step suppression works
- [x] T008 Verify: disconnect f_vf_vortex from pix in1 entirely; confirm no crash and output resembles source (vs_black → src_vecfield logic handles it via vs_inState in the final patcher — in scratch, manually set src_vecfield=0)
- [x] T009 Verify: bypass=1 outputs source texture exactly regardless of strength and src_vecfield values
- [x] T010 Verify: edge behavior at high strength — pixels at boundaries smear/stretch, no wrap artifacts
- [x] T011 Freeze codebox text — copy final codebox content to a local note or comment. No further changes.

**Checkpoint:** Warp visible and correct. All verifications pass. Codebox is frozen.

---

## Phase 2: definition.py

**Purpose:** Encode the confirmed codebox and full patcher structure into the definition file that `build_patcher.py` consumes.

- [x] T012 Read `tools/spec.md` to confirm current definition.py schema (do not guess field names)
- [x] T013 Read an existing two-inlet processor definition for reference — `f_caustic` is the closest match (also has a second texture inlet via vs_inState)
- [x] T014 Write `.specify/f_vf_warp/definition.py` — set `archetype: "processor"`, prefix `vfwarp`, object name `vfwarp_pix`, `@type char`
- [x] T015 Add inlet declarations: in0 (texture + control, via routepass), in1 (vecfield, via vs_inState with outlet 1 wired to `prepend param src_vecfield`)
- [x] T016 Add user params block: `strength` as live.dial, range 0.0–1.0, default 0.1
- [x] T017 Add bypass_toggle.js jsui — confirm `param_connect` is absent (must not appear in generated JSON)
- [x] T018 Add frozen codebox content verbatim to definition.py — confirm `src_vecfield` Param declaration is present in codebox but absent from the params list
- [x] T019 Add gen subpatcher structure: `in 1` (source texture), `in 2` (vecfield texture), `out 1`; reference `in2` in codebox code so the second codebox inlet is present — do not set `numinlets` anywhere
- [x] T020 Add `autopattr @varname vfwarp_autopattr` to definition
- [x] T021 Add moduleSize.js chain to definition
- [x] T022 Confirm parameters block includes `strength` and `bypass` (from jsui) but NOT `src_vecfield`

**Checkpoint:** definition.py authored and internally consistent. Ready for build.

---

## Phase 3: Build and JSON Inspection

**Purpose:** Run the build script, validate JSON, and inspect the generated patcher structure.

- [x] T023 Run `python3 tools/build_patcher.py .specify/f_vf_warp/definition.py` from repo root
- [x] T024 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_warp.maxpat'))"` — must pass with no errors
- [x] T025 Inspect generated patcher: confirm two `in N` gen objects are present (in 1, in 2) and both wired to their codebox inlets; `numinlets` on pix is auto-derived and read-only — do not look for a set value
- [x] T026 Inspect gen subpatcher: confirm `in 1` and `in 2` are both present and wired to codebox inlets; confirm `in2` is referenced in codebox code (this is what makes the second codebox inlet exist — codebox `numinlets` is not settable)
- [x] T027 Inspect vs_inState wiring on in1: confirm outlet 0 → pix texture inlet 2; confirm outlet 1 → `prepend param src_vecfield` → pix in0 (message inlet)
- [x] T028 Inspect parameters block: confirm `strength` and `bypass` registered; confirm `src_vecfield` absent
- [x] T029 Inspect route object args: confirm `strength` present; confirm `src_vecfield` absent; confirm `bypass` absent (bypass goes direct, not through route)
- [x] T030 Inspect routepass object: confirm args are `jit_gl_texture jit_matrix` only (no param names on routepass)

**Checkpoint:** JSON valid. Patcher structure correct per manual inspection. No structural errors.

---

## Phase 4: Vsynth Integration Testing

**Purpose:** Open the built patcher in a live Vsynth patch and verify all acceptance criteria from the spec.

- [x] T031 Open a Vsynth patch; add f_vf_warp as a bpatcher; confirm it loads without errors or console warnings
- [x] T032 Wire a source texture (video or noise) to in0 and f_vf_vortex to in1; confirm warp is visible around vortex center
- [x] T033 Sweep `strength` dial from 0 to 1; confirm distortion scales smoothly, no artifacts, no black frames
- [x] T034 Disconnect f_vf_vortex from in1; confirm output passes through source unwarped (src_vecfield suppression working via vs_inState)
- [x] T035 Disconnect source texture from in0; confirm output is black
- [x] T036 Enable bypass; confirm output exactly matches source texture regardless of strength or vecfield state
- [x] T037 [P] Test with f_vf_vortex_multi on in1 if available; confirm no crash and warp visible
- [x] T038 [P] Test with f_vf_fieldmap on in1 if available; confirm no crash and warp visible
- [x] T039 Save the Vsynth patch and reload; confirm f_vf_warp reopens correctly with params restored, no crash
- [x] T040 Confirm presentation layer renders correctly in Vsynth: title, panel, dials, bypass toggle all visible and correctly styled

**Checkpoint:** All acceptance criteria from spec pass. Patcher survives save/load.

---

## Phase 5: Docs and Registration

**Purpose:** Update permanent project records. Nothing here until Phase 4 checkpoint is confirmed.

- [x] T041 Write `docs/f-reference/f_vf_warp.md` — as-built reference: params table, signal chain summary, usage notes (what fields work well with it), known edge behaviors (high-strength smear at boundaries)
- [x] T042 Update `README.md` bpatcher table — add f_vf_warp row with type "Processor" and status "Working"
- [x] T043 Add "Warp" entry to Vecfield category in `.specify/f_modules/build_modules.py` — use filename `f_vf_warp`
- [x] T044 Add size entry for `f_vf_warp` to `SIZES` dict in `javascript/f_addmod.js` — get dimensions from `presentation_rect` of the background panel in the generated patcher JSON
- [x] T045 Regenerate `patchers/f_modules.maxpat`: run `.specify/f_modules/build_modules.py`; validate JSON; confirm Vecfield category now includes Warp entry
- [x] T046 Update `HANDOFF.md` for session end — what was done, what's next

**Checkpoint:** README updated. f_modules menu includes f_vf_warp. Docs written. Ready to commit.

---

## Phase 6: Bug — `out2` ignores bypass  ✅ RESOLVED 2026-09-23

**Purpose:** With the module bypassed, `out2` (the isolated *warped source* layer — not a vecfield) came out vertically flipped instead of matching the source. Found through use 2026-07-17.

**Root cause (bench-verified):** the bypass toggle set the pix's native `bypass` attribute, which skips the shader and passes outlets 2+ through flipped; the codebox's `mix(..., bypass)` never ran. Earlier task text calling `out2` "the vecfield outlet" was wrong — see `docs/f-reference/f_vf_warp.md`.

- [x] T047 Reproduce: bench showed `bypassed_out2` == `in1` flipped vertically (max diff 0.0 vs `flipud(in1)`)
- [x] T048 Trace: native bypass short-circuits the shader; `out1` was correct only because outlet 1 passes through cleanly
- [x] T049 Decision (Matt): bypassed `out2` = unwarped source, like `out1`. Implemented: Param renamed `bypass_gate`, toggle wired `jsui → prepend param bypass_gate → pix` (attrui `obj-24` replaced), both outlets `mix(warped_sample, sample(in1, uv), bypass_gate)`. Hand-edited `.maxpat` + `definition.py` codebox; **do not regenerate** (shipped patch has hand edits, see comment in `definition.py`)
- [x] T050 `tests/contracts/bench_modules.py` now checks `out2 == in1` under bypass for `f_vf_warp` (`BYPASS_PASSTHROUGH_OUTLETS`); passes

**Checkpoint:** met — `out1` and `out2` both equal the source when bypassed.

---

## Maintenance pass (2026-10-09)

Run via `.specify/maintenance/SKILL.md`; full findings in
`.specify/maintenance/status.json`. This module came out clean relative to
everything else audited so far — bypass fix (T048-T050 above) is
confirmed and the reference doc already documents it accurately, unlike
`f_masonry`/`f_vf_advect`'s stale docs. Two small items:

- [x] T051 **Bench: record the tier-1 skip decision explicitly.** No
  NumPy mirror exists, but the codebox is linear remap + clamp + single
  sample — about as textbook-trivial as a codebox gets, and the
  constitution explicitly permits skipping tiers 1-2 for trivial cases
  "but say so." Nobody has said so in writing; add the one-line decision
  to `plan.md` rather than leaving it implicit.
  **Decided 2026-10-19 (Matt): tier 1 skipped.** Linear remap, clamp and one
  sample; a mirror would restate the codebox. Recorded here (the task
  record), not in `plan.md`.
- [x] T052 **Convention decision gate: does `strength` need the gain/mix
  split?** Same open question filed for `f_grain`'s `amount`
  (`.specify/f_grain/tasks.md` T003) — `strength` here is a single
  0-1.5 param doing the same blend-weight-ish job the six rolled-out
  modules split into `gain`+`mix`. Now two modules outside that rollout
  with the same shape of question; worth deciding once, generally,
  rather than module by module.
  **Decided 2026-10-19 (Matt): the split applies; built the same day**, as
  `f_grain`'s T003. `strength` is now `gain` (0-1.5, default 0.0, unchanged) and
  `mix_pct` (0-100, default 100 = the previous behavior) is new: out0 is
  `mix(source, warped, mix_pct / 100)`, out1 is the warped layer unmixed, both
  mix to the source under bypass. The older "saved default 0.1" comment in
  `definition.py` was wrong (patcher, definition and codebox all had 0.0) and is
  corrected. Done: `src/f_vf_warp/definition.py`, patcher rebuilt (`build/drift.py
  -v f_vf_warp` ok; `lens_toggle.js` restored; panel size unchanged at 78 x 90),
  `docs/f-reference/f_vf_warp.md`, `module-inventory.md`, the helpfile's External
  Control text and parameter binding, and the demo preset key
  `f_vf_warp::gain` in `package/examples/f_demo_warp.json`;
  `tests/run.sh -q tests/contracts/test_module_contracts.py` 9/9. **Not done
  (owed):** Matt's look in Max (the new Mix numbox sits at x 41-75, its label box
  overhangs the 78 px frame by about 1.5 px; the title bar is still crowded);
  `f_demo_warp.maxpat` and `f_demo_sampleplatter.maxpat` embed warp instances whose
  saved dial bindings still say `strength`, so open them once and re-save; a live
  `bench_modules` run for warp (no bench was run); the helpfile's References text
  still mentions a bypass bug that was fixed 2026-09-23.
  **Decided 2026-10-19 (Matt): the warp panel is fine for now** (Mix numbox position, label overhang and the crowded title bar stay as built; the "look in Max" item is closed). Still owed: the two demo re-saves, a live `bench_modules` warp entry, the stale References text.

---

## Dependencies

**Phase dependencies (strict):**
- Phase 1 → Phase 2: codebox frozen before definition.py
- Phase 2 → Phase 3: definition.py complete before build
- Phase 3 → Phase 4: valid patcher JSON before opening in Max
- Phase 4 → Phase 5: acceptance criteria confirmed before docs

**Parallel opportunities within phases:**
- T037 and T038 (alternate vecfield producer tests) can run in parallel
- T041 (docs) can be drafted during Phase 4 testing; finalized after checkpoint

**No cross-phase parallelism** — each phase gate is hard.

---

## Notes

- `src_vecfield` appears in the codebox `Param` declaration and in the vs_inState wiring — it must NOT appear in the params list, route args, or parameters block. Three places to check in T022, T028, T029.
- If `mix`/`step` suppression fails unexpectedly in jit.gen, fallback: use `src_vecfield * raw_offset` (multiply by 0 when unconnected, 1 when connected — same effect, slightly less precise at intermediate states, but simpler).
- T013 (read f_caustic definition for reference) is optional if the schema is already familiar from the current session.
- Commit after Phase 3 checkpoint (patcher builds clean) and again after Phase 5 (fully integrated and documented).
- **2026-10-20, clamp edge fix (pilot for the clamp triage):** the codebox clamped the displaced UV to exact [0, 1]; probe P9 showed that on the GPU x = 1.0 reads the first column and y = 0.0 reads the last row, so a warp reaching past the right or low-y edge smeared the far edge in. Bounds are now 0.001 / 0.999 (option A; the `f_tf_` `width`/`height` texel-centre idiom was rejected because those dials are being removed). Patcher regenerated, `drift.py -v f_vf_warp` ok. **Tier 3 pending (Matt):** look in Max with a field that pushes content past the right and bottom edges; the edge should stretch its own colour, not the opposite side's. No tier-1 mirror exists (T051 skip), so there is no numeric test.
  **2026-11-06 note:** this look is recorded as passed in `HANDOFF_ARCHIVE.md`, see "Stable preflight" below.

---

## Stable preflight tasks

- [x] T053 Close T001-T046 as a passed build checklist. Source: the module shipped and is in use: `ddd9a0e` (first patcher commit), `package/patchers/f_vf_warp.maxpat`, `docs/f-reference/f_vf_warp.md`, README row, `f_addmod.js` size entry, menu entry under ∇ Effects (`src/f_modules/menu.py:87`), all opened 2026-11-06. No per-item results were recorded at build time, so T031-T040 are not individual observations, and T037 (`f_vf_vortex_multi`) and T039 (save and reload) have no specific record. Paths and `strength` in those tasks are as written then.
- [x] T054 Stable preflight (2026-11-06, offline by Claude), record below.
- [x] T055 Matt's helpfile look: the new chain at defaults and with Gain raised, the digest, the two notes. Then the move to `.specify/stable/`.

## Stable preflight (2026-11-06)

Part 1 offline by Claude: `drift.py -v f_vf_warp` ok, no baseline entry; menu and launcher `--check` up to date; README row 92 chars, no ⚠; menu entry present (`menu.py:87`), recipe Grain Warp; bypass is `bypass_gate` (`bypass_mode: "param"`, `BYPASS_EXPECT` `{2: IN1}`, out1 implicit; `bench_modules.py` 2/2 in `tests/logs/20261106-081412-bench.log`, from before these edits, which touch no patcher or codebox; last patcher commit `672a8dc`); helpfile box 154x91 against a frame of 78x90 (labels reach x -18 to 102.5, width 120.5). The route is `gain mix_pct`, no `bypass` selector, and the helpfile has no `bypass [0 / 1]` line, which is right. `definition.py` unchanged. No gate row holds Warp (`.specify/gates.md` grepped). Tests: no mirror (T051, skip decided by Matt), no `bench_*` file of its own; contract bench entry above, plus `test_f_vf_warp_uses_param_bypass_and_reproduces_exactly` in `tests/build/test_build_multistage.py` (not run here).

Claims checked. Tier 3 at line 237: `HANDOFF_ARCHIVE.md` line 950 (the triage says 941), the 2026-10-20 20:35 entry, lists warp among the clamp fixes "with all tier-3 looks passed". That is the only record: it names no observer and no detail, and nothing was looked at here, so per the docs, not verified. The same entry says the demo re-saves and the live `bench_modules` warp entry are done, which settles T052's owed list with `b91bf84` and the log above. T052's third item, the stale References text, was still there and is fixed below. `status.json` lists the module under `.specify/stable/f_vf_warp/T001`: stale, the folder is at the `.specify/` root and the tasks it means are T051 and T052. Not edited.

Dead keys: `f_vf_warp::strength` does NOT exist in `package/examples/` (grepped; `f_demo_warp.json` and `f_demo_quasi.json` use `gain`), so the mentions in `.specify/f_vf_streak/tasks.md:234`, `.specify/maintenance/tasks.md:69` and `status.json:216` are out of date for warp. It exists in `package/help/streak-demo.json` (outside `examples/`). What remains in `examples/` is saved dial naming: `f_demo_warp.maxpat` has longname `strength`, shortname `gain`; `f_demo_sampleplatter.maxpat` has `strength[3]` / `strength`. Effect on recall not run. Nothing touched.

Patcher against docs: two inlets, source on 0 and vecfield on 1, two outlets. `vs_inState` on inlet 1 only, its out1 driving `src_vecfield`; no `vs_inState` on inlet 0, no `r draw`, so only a texture on inlet 0 triggers the pix (wiring read; behavior inferred, not run). `vs_inState.maxpat` read: connection is sensed by timing, and `vs_black` goes out when the state falls to 0.

Fixed in the doc: no trigger facts, and nothing about control wiring. The pseudocode dropped the `src_vecfield` gate. The bypass section still gave the pre-T052 mix and said `out1` and `out2` where the rest says out0 and out1. The bypass row now says toggle only. "Compatible with" named three producers; `f_vf_flow`, `f_vf_fluid` and `f_tf_axisflow` also feed it. The sign was undocumented: it reads at uv + offset, so content moves against the vector (code read, not run). The README row and digest said "along field streamlines", wrong by meaning: one offset read, nothing follows a streamline. Also new: the clamp runs at every gain, so gain 0 is not bit-exact in the outer 0.1% (worked from the codebox, not run). The GPU Gems citation from `definition.py` is now in the doc and helpfile.

Chains in `library-characteristics.md`: by type all feed Warp a source and a vecfield. By meaning, three need edits, returned to the main session: Warp-away portrait has the sign backward (repulse vectors point away from bright, confirmed in `f_vf_repulse`'s codebox, so bright regions shrink); Vortex-stirred warp says "carried", but warp transports nothing; Warp-with-feedback has `vs_mixer_fdbk` after the warp, an additive mixer with its own feedback, so displacement cannot compound, and "out1" is the composite in that file's numbering. `f_chladni.md`'s "warps toward nodal lines" holds if the field points at antinodes as its table says (inferred). The `f_util_matrix_2` chain was not assessed (draft, and `f_vf_chroma` is paused).

Helpfile: confirmed no vecfield was wired, so `src_vecfield` stayed 0 and the demo could only show the source. Added `f_vf_vortex` (`d-11`, 196x160, its footprint), triggered by `vs_sources_main` on its inlet 0 since it has no `r draw`, out to Warp inlet 1. Warp and preview moved down. The old note sat on the preview and named producers; replaced. Stale bypass-bug References text replaced. Digest now says what it is for. Expected (from the codebox, not seen): at defaults the output equals the source, because Gain is 0; a note says so. With Gain raised, the center swells outward and a small disc in the middle reads point-flipped, because the default sink's vector (0.5 at center) overshoots the center there. `vs_sources_main` opens on the Movie tab, so all of this, the vortex included, depends on a movie being loaded. No overlaps (rects: vortex 420-616 x 160-320; Warp 338-492 x 330-421; preview 338-574 x 431-680; notes 510-760 x 330-388 and 590-780 x 431-529). Preview ends at y 680 of a 681 window. JSON parses and round-trips in the file's format. Live by Matt: T055.

Left alone: `spec.md` and `plan.md` are pre-T049 and pre-T052 (`strength`, default 0.1, out2 ungated); outside this pass's edit list, header line returned to the main session. The codebox comments and the `definition.py` REVISIT note's `strength` are dated. `ideas/f_vf_seeds.md:157` says Warp can feed a vecfield (it outputs textures; an old idea note). `f_vf_vortex.maxhelp` has its own box at 154x91 against a 196x160 footprint and nothing upstream, which is Vortex's record.

## Moved to stable/ (2026-11-06)

Matt's helpfile looks passed 2026-11-06 ("helpfile looks pass", for the group, live by Matt). Contract bench `tests/contracts/bench_modules.py` 2/2, 0 unexpected live contract issues, all four modules in the roster (log `tests/logs/20261106-192009-bench.log`, Max 9.2.0, git fb693ee dirty; run by Claude at Matt's go, live). The folder holds only markdown: no scripts, no `parents[N]` or `../` paths, and `definition.py` has no `Spec:` line, so nothing needed changing there. References to this folder in docs and ideas were updated to `.specify/stable/`.

Carried over (stable bar: optional cost and parked mirrors do not block): no tier-1 mirror (T051, Matt's skip); the clamp-edge tier-3 look is recorded only as "per the docs, not verified" (`HANDOFF_ARCHIVE.md` line 950 names no observer); `f_demo_sampleplatter.maxpat`'s dial and `package/help/streak-demo.json` still say `strength` (not touched).
