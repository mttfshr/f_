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

- [ ] T001 Open scratch patch at `~/Vsynth/patterns/vf_warp_scratch.maxpat` — add `vs_render` bpatcher and toggle to start render clock
- [ ] T002 Add `jit.gl.pix vsynth @name vfwarp_pix` with two texture inlets; wire a test source (noise or video) to in0 and `f_vf_vortex` to in1
- [ ] T003 Add gen subpatcher with `in 1` (source texture) and `in 2` (vecfield texture) objects; reference `in2` in codebox code first (this makes the codebox inlet appear), then wire both `in N` gen objects to their respective codebox inlets — neither `numinlets` on pix nor on codebox is settable
- [ ] T004 Paste the following confirmed codebox into the gen subpatcher:

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
- [ ] T005 Add float number boxes for `strength` and `src_vecfield` wired to pix in0 via `prepend param`; verify codebox compiles (no errors in Max console)
- [ ] T006 Verify: warp is visible with f_vf_vortex connected; strength=0 gives no warp; strength=1 gives strong distortion scaling smoothly
- [ ] T007 Verify: set src_vecfield=0 — output matches source exactly (zero offset); set src_vecfield=1 — warp active; confirm the mix/step suppression works
- [ ] T008 Verify: disconnect f_vf_vortex from pix in1 entirely; confirm no crash and output resembles source (vs_black → src_vecfield logic handles it via vs_inState in the final patcher — in scratch, manually set src_vecfield=0)
- [ ] T009 Verify: bypass=1 outputs source texture exactly regardless of strength and src_vecfield values
- [ ] T010 Verify: edge behavior at high strength — pixels at boundaries smear/stretch, no wrap artifacts
- [ ] T011 Freeze codebox text — copy final codebox content to a local note or comment. No further changes.

**Checkpoint:** Warp visible and correct. All verifications pass. Codebox is frozen.

---

## Phase 2: definition.py

**Purpose:** Encode the confirmed codebox and full patcher structure into the definition file that `build_patcher.py` consumes.

- [ ] T012 Read `tools/spec.md` to confirm current definition.py schema (do not guess field names)
- [ ] T013 Read an existing two-inlet processor definition for reference — `f_caustic` is the closest match (also has a second texture inlet via vs_inState)
- [ ] T014 Write `.specify/f_vf_warp/definition.py` — set `archetype: "processor"`, prefix `vfwarp`, object name `vfwarp_pix`, `@type char`
- [ ] T015 Add inlet declarations: in0 (texture + control, via routepass), in1 (vecfield, via vs_inState with outlet 1 wired to `prepend param src_vecfield`)
- [ ] T016 Add user params block: `strength` as live.dial, range 0.0–1.0, default 0.1
- [ ] T017 Add bypass_toggle.js jsui — confirm `param_connect` is absent (must not appear in generated JSON)
- [ ] T018 Add frozen codebox content verbatim to definition.py — confirm `src_vecfield` Param declaration is present in codebox but absent from the params list
- [ ] T019 Add gen subpatcher structure: `in 1` (source texture), `in 2` (vecfield texture), `out 1`; reference `in2` in codebox code so the second codebox inlet is present — do not set `numinlets` anywhere
- [ ] T020 Add `autopattr @varname vfwarp_autopattr` to definition
- [ ] T021 Add moduleSize.js chain to definition
- [ ] T022 Confirm parameters block includes `strength` and `bypass` (from jsui) but NOT `src_vecfield`

**Checkpoint:** definition.py authored and internally consistent. Ready for build.

---

## Phase 3: Build and JSON Inspection

**Purpose:** Run the build script, validate JSON, and inspect the generated patcher structure.

- [ ] T023 Run `python3 tools/build_patcher.py .specify/f_vf_warp/definition.py` from repo root
- [ ] T024 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_warp.maxpat'))"` — must pass with no errors
- [ ] T025 Inspect generated patcher: confirm two `in N` gen objects are present (in 1, in 2) and both wired to their codebox inlets; `numinlets` on pix is auto-derived and read-only — do not look for a set value
- [ ] T026 Inspect gen subpatcher: confirm `in 1` and `in 2` are both present and wired to codebox inlets; confirm `in2` is referenced in codebox code (this is what makes the second codebox inlet exist — codebox `numinlets` is not settable)
- [ ] T027 Inspect vs_inState wiring on in1: confirm outlet 0 → pix texture inlet 2; confirm outlet 1 → `prepend param src_vecfield` → pix in0 (message inlet)
- [ ] T028 Inspect parameters block: confirm `strength` and `bypass` registered; confirm `src_vecfield` absent
- [ ] T029 Inspect route object args: confirm `strength` present; confirm `src_vecfield` absent; confirm `bypass` absent (bypass goes direct, not through route)
- [ ] T030 Inspect routepass object: confirm args are `jit_gl_texture jit_matrix` only (no param names on routepass)

**Checkpoint:** JSON valid. Patcher structure correct per manual inspection. No structural errors.

---

## Phase 4: Vsynth Integration Testing

**Purpose:** Open the built patcher in a live Vsynth patch and verify all acceptance criteria from the spec.

- [ ] T031 Open a Vsynth patch; add f_vf_warp as a bpatcher; confirm it loads without errors or console warnings
- [ ] T032 Wire a source texture (video or noise) to in0 and f_vf_vortex to in1; confirm warp is visible around vortex center
- [ ] T033 Sweep `strength` dial from 0 to 1; confirm distortion scales smoothly, no artifacts, no black frames
- [ ] T034 Disconnect f_vf_vortex from in1; confirm output passes through source unwarped (src_vecfield suppression working via vs_inState)
- [ ] T035 Disconnect source texture from in0; confirm output is black
- [ ] T036 Enable bypass; confirm output exactly matches source texture regardless of strength or vecfield state
- [ ] T037 [P] Test with f_vf_vortex_multi on in1 if available; confirm no crash and warp visible
- [ ] T038 [P] Test with f_vf_fieldmap on in1 if available; confirm no crash and warp visible
- [ ] T039 Save the Vsynth patch and reload; confirm f_vf_warp reopens correctly with params restored, no crash
- [ ] T040 Confirm presentation layer renders correctly in Vsynth: title, panel, dials, bypass toggle all visible and correctly styled

**Checkpoint:** All acceptance criteria from spec pass. Patcher survives save/load.

---

## Phase 5: Docs and Registration

**Purpose:** Update permanent project records. Nothing here until Phase 4 checkpoint is confirmed.

- [ ] T041 Write `docs/f-reference/f_vf_warp.md` — as-built reference: params table, signal chain summary, usage notes (what fields work well with it), known edge behaviors (high-strength smear at boundaries)
- [ ] T042 Update `README.md` bpatcher table — add f_vf_warp row with type "Processor" and status "Working"
- [ ] T043 Add "Warp" entry to Vecfield category in `.specify/f_modules/build_modules.py` — use filename `f_vf_warp`
- [ ] T044 Add size entry for `f_vf_warp` to `SIZES` dict in `javascript/f_addmod.js` — get dimensions from `presentation_rect` of the background panel in the generated patcher JSON
- [ ] T045 Regenerate `patchers/f_modules.maxpat`: run `.specify/f_modules/build_modules.py`; validate JSON; confirm Vecfield category now includes Warp entry
- [ ] T046 Update `HANDOFF.md` for session end — what was done, what's next

**Checkpoint:** README updated. f_modules menu includes f_vf_warp. Docs written. Ready to commit.

---

## Phase 6: Bug — `out2` ignores bypass

**Purpose:** With the module bypassed, `out2` (the vecfield outlet) still appears to change the direction of the incoming vecfield instead of passing it through untouched. Found through use 2026-07-17, not a documentation gap — a real behavior bug. Tracked here rather than only in `plan.md` so it isn't orphaned again.

- [ ] T047 Reproduce in isolation: feed a known static vecfield to in1, enable bypass, confirm `out2` differs from the input vecfield (rule out that this is expected behavior misread as a bug)
- [ ] T048 Trace the codebox/gen wiring for `out2` — confirm whether `bypass` is referenced at all in the branch that produces `out2`, versus only gating `out1`
- [ ] T049 Decide the correct bypassed behavior for `out2` (likely: pass the input vecfield through unmodified) and implement
- [ ] T050 Re-verify T036-equivalent for `out2`: with bypass enabled, `out2` exactly matches the incoming vecfield regardless of `strength`

**Checkpoint:** `out2` passes through unmodified when bypassed. Update `docs/f_vf_warp.md` if it documents current (buggy) behavior.

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
