# Tasks: f_vf_streak

**Spec**: `.specify/f_vf_streak/spec.md`
**Plan**: `.specify/f_vf_streak/plan.md`
**Build order**: Sequential. Complete each phase before the next. Phase 1 is the hard gate.
**Commits**: After each phase checkpoint.

---

## Expected Output Layout

```
patchers/
  f_vf_streak.maxpat              — built by build script from definition.py

.specify/f_vf_streak/
  spec.md                         — ✅ done
  plan.md                         — ✅ done
  tasks.md                        — this file
  definition.py                   — authored in Phase 2, input to build script
  build_streak.py                 — custom build script (if build_patcher.py lacks dual outlet support)

docs/
  f_vf_streak.md                  — as-built reference (Phase 5)

~/Vsynth/patterns/
  vf_streak_scratch.maxpat        — scratch patch for codebox verification (Phase 1, not committed)
```

---

## Phase 1: Codebox Verification (BLOCKING)

**Purpose:** Write and verify the streak GLSL in a scratch patch before touching the build system. This is the hard gate — the codebox is frozen after this phase.

⚠️ CRITICAL: Do not write definition.py until the codebox is confirmed working in scratch.

- [ ] T001 Open scratch patch at `~/Vsynth/patterns/vf_streak_scratch.maxpat` — add `vs_render` bpatcher and toggle to start render clock
- [ ] T002 Add `jit.gl.pix vsynth @name vfstreak_pix @type float32` with two texture inlets and two outlets; wire a test source (noise, WFG, or video) to in0 and `f_vf_vortex` to in1
- [ ] T003 Build gen subpatcher: add `in 1` (source texture), `in 2` (vecfield texture); add codebox with numinlets=2 by referencing `in2` in codebox code first; add `out 1` (composite) and `out 2` (streak layer); wire in1→codebox inlet 0, in2→codebox inlet 1, codebox out0→out1, codebox out1→out2
- [ ] T004 Add float number boxes for `strength`, `length`, `falloff`, `color_shift`, `src_vecfield` wired to pix in0 via `prepend param`; add separate bypass number box
- [ ] T005 Write and paste the 8-step unrolled streak codebox — structure:

  ```
  Param strength(0.3);
  Param length(0.15);
  Param falloff(0.0);
  Param color_shift(0.0);
  Param src_vecfield(0.0);
  Param bypass(0.0);

  uv = norm;
  step_size = length / 8.0;
  cs = color_shift * step_size;

  // suppress field when inlet unconnected
  connected = step(0.5, src_vecfield);

  // --- step 0: current pixel ---
  pos0x = uv.x;
  pos0y = uv.y;
  f0x = (sample(in2, vec(pos0x, pos0y)).x - 0.5) * 2.0 * connected;
  f0y = (sample(in2, vec(pos0x, pos0y)).y - 0.5) * 2.0 * connected;
  w0 = mix(1.0, 1.0, falloff);   // = 1.0 always at step 0
  src0r = sample(in1, vec(pos0x + f0x * cs, pos0y)).x;
  src0g = sample(in1, vec(pos0x, pos0y)).y;
  src0b = sample(in1, vec(pos0x - f0x * cs, pos0y)).z;

  // --- steps 1–7: walk backward, each posN = pos(N-1) - f(N-1) * step_size ---
  // (unroll all 8 steps in full — see caustic codebox for loop structure reference)
  // wN = mix(1.0, 1.0 - (n/7.0), falloff)

  // --- weighted accumulation ---
  w_sum = w0 + w1 + w2 + w3 + w4 + w5 + w6 + w7;
  streak_r = (w0*src0r + w1*src1r + ... + w7*src7r) / w_sum;
  streak_g = (w0*src0g + w1*src1g + ... + w7*src7g) / w_sum;
  streak_b = (w0*src0b + w1*src1b + ... + w7*src7b) / w_sum;

  streak_layer = vec(clamp(streak_r, 0.0, 1.0),
                     clamp(streak_g, 0.0, 1.0),
                     clamp(streak_b, 0.0, 1.0),
                     1.0);

  src_px = sample(in1, uv);

  // out2: isolated streak layer
  out2 = mix(streak_layer, vec(0.0, 0.0, 0.0, 1.0), bypass);

  // out1: additive composite — streak adds light over source
  composite = vec(clamp(src_px.x + streak_r * strength, 0.0, 1.0),
                  clamp(src_px.y + streak_g * strength, 0.0, 1.0),
                  clamp(src_px.z + streak_b * strength, 0.0, 1.0),
                  1.0);
  out1 = mix(composite, src_px, bypass);
  ```

  Note: T005 is a structural outline — write the full 8-step unroll in scratch, referencing `f_caustic/codebox_v3.gen` for the step-walk pattern.

- [ ] T006 Verify codebox compiles with no errors in Max console
- [ ] T007 Verify: streak is visible and directionally aligned with vortex field streamlines; smear follows field flow
- [ ] T008 Verify: `length` increasing from 0 to 0.5 extends streak reach smoothly along streamlines
- [ ] T009 Verify: `falloff=0` gives symmetric directional blur; `falloff=1` gives trailing smear with sharper leading edge; intermediate values interpolate correctly
- [ ] T010 Verify: `color_shift > 0` produces chromatic separation along streak axis — R/B channels offset in field direction
- [ ] T011 Verify: `src_vecfield=0` (simulating unconnected inlet) — no diagonal artifact; output is source passthrough on out1 and black on out2
- [ ] T012 Verify: `strength=0` — out1 matches source exactly; out2 is streak layer unaffected by strength
- [ ] T013 Verify: `bypass=1` — out1 passes source; out2 is black; no streak contribution
- [ ] T014 Verify: out2 contains isolated streak layer usable as additive composite source (dark background, colored streaks)
- [ ] T015 Confirm normalization is correct: sweep falloff 0→1 and confirm overall brightness of streak layer does not shift significantly
- [ ] T016 Freeze codebox — copy final full codebox text to a comment or local note. No further changes.

**Checkpoint:** Both outlets correct. All params have visible effect. Passthrough clean. Normalization stable. Codebox frozen.

---

## Phase 2: Build System Check and definition.py

**Purpose:** Confirm build_patcher.py dual-outlet support, then author definition file.

- [ ] T017 Read `tools/build_patcher.py` — check whether dual gen outlet (two `out N` objects, two pix outlets, two bpatcher outlets) is supported via definition.py keys; look for any `dual_outlet`, `num_outlets`, or similar configuration
- [ ] T018 If dual outlet is NOT supported natively: write `.specify/f_vf_streak/build_streak.py` modelled on `.specify/f_caustic/build_caustic.py` — adapt for f_vf_streak params (strength, length, falloff, color_shift), prefix `vfstreak`, vs_inState on in1 with src_vecfield state param
- [ ] T019 If dual outlet IS supported natively: write `.specify/f_vf_streak/definition.py` with appropriate dual-outlet key; skip T018
- [ ] T020 Set presentation rect width — four dials + two outlet triangles requires wider than standard 78px; target ~120px wide; verify against moduleSize.js by checking similar multi-param patchers (f_caustic uses 190px as reference)
- [ ] T021 Confirm params in definition/build script: `strength` (live.dial, 0–1, default 0.3), `length` (live.dial, 0–0.5, default 0.15), `falloff` (live.dial, 0–1, default 0.0), `color_shift` (live.dial, 0–1, default 0.0), `src_vecfield` (internal/hidden), `bypass`
- [ ] T022 Confirm `src_vecfield` is present in codebox Param declaration and in vs_inState wiring — absent from route args, UI objects, and parameters block
- [ ] T023 Confirm gen subpatcher structure encodes: `in 1` (source), `in 2` (vecfield), codebox (numinlets=2 via in2 reference, numoutlets=2), `out 1` (composite), `out 2` (streak layer)
- [ ] T024 Confirm outlet labels: outlet 0 labeled "out", outlet 1 labeled "streak"

**Checkpoint:** Build script or definition.py authored and internally consistent. Ready to build.

---

## Phase 3: Build and JSON Inspection

**Purpose:** Run the build script, validate JSON, inspect generated patcher structure.

- [ ] T025 Run build script from repo root: `python3 .specify/f_vf_streak/build_streak.py` (or `python3 tools/build_patcher.py .specify/f_vf_streak/definition.py`)
- [ ] T026 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_streak.maxpat'))"` — must pass with no errors
- [ ] T027 Inspect pix object: confirm numinlets=3 (control, source, vecfield), numoutlets=2
- [ ] T028 Inspect gen subpatcher: confirm `in 1`, `in 2`, codebox (numinlets=2, numoutlets=2), `out 1`, `out 2` all present and wired correctly
- [ ] T029 Inspect vs_inState wiring on in1: outlet 0 → pix texture inlet 2 (vecfield); outlet 1 → `prepend param src_vecfield` → pix in0
- [ ] T030 Inspect bpatcher outlets: confirm two outlets present, labeled "out" and "streak"
- [ ] T031 Inspect parameters block: confirm strength, length, falloff, color_shift, bypass registered; confirm src_vecfield absent
- [ ] T032 Inspect route object args: confirm strength, length, falloff, color_shift present; confirm src_vecfield and bypass absent
- [ ] T033 Inspect presentation layer: confirm four live.dials visible, panel correct width, title "Streak", bypass toggle present

**Checkpoint:** JSON valid. Structure correct. No structural errors.

---

## Phase 4: Vsynth Integration Testing

**Purpose:** Open built patcher in live Vsynth patch and verify all acceptance criteria.

- [ ] T034 Open Vsynth patch; add f_vf_streak as bpatcher; confirm loads without errors or console warnings
- [ ] T035 Wire source texture to in0 and f_vf_vortex to in1; confirm streak visible on both outlets
- [ ] T036 Verify out0 (composite): source image with streak layer added additively; `strength=0` passes source cleanly
- [ ] T037 Verify out1 (isolated streak): dark background with colored streaks; usable as additive layer externally
- [ ] T038 Sweep `length` 0→0.5; confirm streak reach extends smoothly along streamlines
- [ ] T039 Sweep `falloff` 0→1; confirm blur→trailing smear transition; no brightness shift
- [ ] T040 Sweep `color_shift` 0→1; confirm chromatic separation appears along streak direction
- [ ] T041 Disconnect f_vf_vortex from in1; confirm out0 passes source through cleanly; confirm out1 is black
- [ ] T042 Disconnect source from in0; confirm both outlets black
- [ ] T043 Enable bypass; confirm out0 = source, out1 = black
- [ ] T044 [P] Test with f_vf_vortex_multi on in1; confirm no crash and streak visible
- [ ] T045 [P] Test with f_vf_fieldmap on in1; confirm no crash and streak follows gradient
- [ ] T046 Save Vsynth patch and reload; confirm f_vf_streak reopens correctly with params restored, no crash
- [ ] T047 Confirm presentation layer renders correctly in Vsynth: title, panel, dials, bypass toggle all visible and correctly styled

**Checkpoint:** All acceptance criteria from spec pass. Survives save/load cycle.

---

## Phase 5: Docs and Registration

**Purpose:** Update permanent project records. Nothing here until Phase 4 checkpoint is confirmed.

- [ ] T048 Write `docs/f-reference/f_vf_streak.md` — as-built reference: params table, signal chain summary, usage notes (chain suggestions: vortex → streak; fieldmap → streak; streak out1 into composite layer), known edge behaviors (clipping at high strength + bright source is expected)
- [ ] T049 Update `README.md` bpatcher table — add f_vf_streak row under f_vf_ family description with type "Processor"
- [ ] T050 Add "Streak" entry to Vecfield category in `.specify/f_modules/build_modules.py`
- [ ] T051 Add size entry for `f_vf_streak` to `SIZES` dict in `javascript/f_addmod.js` — get dimensions from `presentation_rect` of background panel in generated patcher JSON
- [ ] T052 Regenerate `patchers/f_modules.maxpat`: run `.specify/f_modules/build_modules.py`; validate JSON; confirm Vecfield category includes Streak entry
- [ ] T053 Update `HANDOFF.md` — what was done, what's next

**Checkpoint:** README updated. f_modules includes f_vf_streak. Docs written. Ready to commit.

---

## Dependencies

**Phase dependencies (strict):**
- Phase 1 → Phase 2: codebox frozen before definition.py / build script
- Phase 2 → Phase 3: build input complete before running build
- Phase 3 → Phase 4: valid patcher JSON before opening in Max
- Phase 4 → Phase 5: acceptance criteria confirmed before docs

**Parallel opportunities within phases:**
- T044 and T045 (alternate vecfield producer tests) can run in parallel
- T048 (docs draft) can be started during Phase 4 testing; finalized after checkpoint

**No cross-phase parallelism** — each phase gate is hard.

---

## Notes

- T005 codebox outline is structural only — write the full 8-step unroll in scratch. Use `f_caustic/codebox_v3.gen` as the reference for the step-walk pattern; replace divergence accumulation with direct source color sampling.
- `src_vecfield` suppression multiplies decoded field vectors by `step(0.5, src_vecfield)` — not the mix/step on offsets pattern from f_vf_warp. Either approach works; confirm which reads cleaner in the full unrolled code during scratch patch.
- If normalization produces a brightness artifact when sweeping falloff, the w_sum calculation may have a float precision issue — verify each wN is computed correctly for n=0..7.
- T017/T018 are the build system branch point — resolve before writing any other Phase 2 tasks. If build_patcher.py needs extension, that work belongs in a separate session, not inline here.
- Commit after Phase 3 checkpoint and again after Phase 5.
