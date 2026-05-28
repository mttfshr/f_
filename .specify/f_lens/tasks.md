# Tasks: f_lens

**Spec**: .specify/f_lens/spec.md
**Plan**: .specify/f_lens/plan.md
**Build order**: Sequential by phase. Complete each phase checkpoint before proceeding.

---

## Expected Source Layout

```
f_/
  patchers/
    f_lens.maxpat              — output of Phase 4 build script
  code/
    bypass_toggle.js           — already exists, no changes needed
  docs/
    f_lens.md                  — written in Phase 6
  ideas/
    f_lens.md                  — already exists (brainstorm, keep)
  .specify/
    f_lens/
      spec.md                  — complete
      plan.md                  — complete
      tasks.md                 — this file
~/Vsynth/patterns/
    f_lens_scratch.maxpat      — Phase 0 feasibility (not in repo)
    build_f_lens.py            — Phase 4 build script (not in repo)
```

---

## Phase 0: Feasibility — Internal Architecture and Available Objects

**Purpose:** Determine the right internal arrangement of objects inside f_lens before any effect work begins. Three inlets exist at the bpatcher level; the internal implementation is open. f_lens must orchestrate everything and render to the vsynth context.

⚠️ GATE: Architecture must be decided and documented before effect implementation begins.

- [ ] T001 Test single `jit.gl.pix vsynth @name lens_pix` with three texture inlets in Vsynth context; trivial codebox mixing all three inputs; confirm textures arrive, no GL errors
- [ ] T002 Test pipeline of pix objects (lens_main_pix → lens_surface_pix → lens_field_pix) each drawing to vsynth context; confirm correct compositing order and no context conflicts
- [ ] T003 Test `jit.gl.pass` inside a vsynth-context bpatcher; confirm whether it can receive and output textures within Vsynth's render management without requiring its own GL setup
- [ ] T004 Test `jit.fx` objects inside a vsynth-context bpatcher; identify any available blur, glow, or composite shaders worth using for tilt blur or halation
- [ ] T005 Based on T001–T004: choose internal architecture; document in ADR-1 in plan.md which objects are vsynth-compatible, what arrangement is used, and why
- [ ] T006 Verify unconnected inlet behavior with chosen architecture; update ADR-3 in plan.md if different from assumption
- [ ] T007 Confirm chosen scripting names have no collision with existing Vsynth objects

**Checkpoint:** Internal architecture decided and documented. Available objects catalogued with vsynth compatibility notes. → Proceed to Phase 1.

---

## Phase 1: Radially Symmetric Effects

**Purpose:** Implement aberration, distortion, and transmission using the objects identified in Phase 0. UV displacement effects (aberration, distortion) will likely use jit.gl.pix codebox; transmission/halation may use jit.gl.pass or jit.fx if vsynth-compatible.

**Goal:** All three effects working and independently verifiable. Passthrough at defaults.

- [ ] T008 Set up effect structure using chosen architecture; add params: aberration(0.0), distortion(0.5), transmission(0.0), bypass(0.0); UV/center/dist setup
- [ ] T009 Implement distortion: barrel/pincushion UV warp scaled by distance from center; verify distortion=0.5 → passthrough, below → barrel, above → pincushion
- [ ] T010 Implement chromatic aberration; decide and document effect ordering (ADR-4): sequential (aberration on distorted UV) vs independent (both from original UV); record decision in spec.md Clarifications
- [ ] T011 Implement transmission vignette with warm color shift; verify transmission=0 → no change, transmission=1 → warm darkened edges; use jit.gl.pass here if available and appropriate
- [ ] T012 Add neutral-guards for in2/in3 using confirmed behavior from T006; add bypass
- [ ] T013 Wire param controls in scratch patch; sweep each param across range; confirm visual behavior matches acceptance criteria in spec

**Checkpoint:** aberration, distortion, transmission each visually correct. Passthrough at defaults. Bypass works. → Proceed to Phase 2.

---

## Phase 2: Tilt-Shift

**Purpose:** Implement tilt-shift blur using the best available approach from Phase 0. If `jit.gl.pass` is vsynth-compatible, use a separable blur pass. If not, use 4–8 fixed samples in a jit.gl.pix codebox (ADR-2 fallback).

**Goal:** Visible sharp band across frame; blur increases away from band; tilt_axis and tilt_pos behave correctly.

- [ ] T014 Add params: tilt(0.0), tilt_axis(0.0), tilt_pos(0.5)
- [ ] T015 Implement tilt band geometry: perpendicular axis from tilt_angle; tilt_dist = distance from focal band; blur_amt = tilt_dist * tilt
- [ ] T016 Implement blur: if jit.gl.pass available use separable Gaussian; otherwise unroll 4–8 samples along blur direction and average; determine step size experimentally
- [ ] T017 Verify tilt=0 → no blur; tilt=1 with tilt_axis=0 → horizontal sharp band; tilt_axis rotates band; tilt_pos moves band position
- [ ] T018 Check for banding artifacts at extreme values; adjust sample count or step if needed; document final approach in plan.md

**Checkpoint:** Tilt-shift reads convincingly; no banding at normal values; axis and position controls behave as expected. → Proceed to Phase 3.

---

## Phase 3: in2/in3 Modulation

**Purpose:** Implement surface_amt and field_amt params connecting in2/in3 textures to spatial variation of effects.

**Goal:** With f_grain as in2 — spatially non-uniform surface character visible. With slow noise as in3 — distortion field varies organically. Unplugged inlets — no effect at default amt values.

- [ ] T019 Add params: surface_amt(0.0), field_amt(0.0)
- [ ] T020 Wire field_amt into distortion: distortion k modulated by in3 sample with neutral-guard; verify uniform distortion with in3 unplugged; organic variation with slow noise in in3
- [ ] T021 Wire surface_amt into transmission output: multiply output by in2 sample with neutral-guard; verify no darkening with in2 unplugged at surface_amt=0; dust pattern visible with f_grain in in2 and surface_amt raised
- [ ] T022 Test all eight params simultaneously with f_grain → in2 and slow noise → in3; verify no interaction artifacts between effect families

**Checkpoint:** in2/in3 modulation working; unplugged inlets safe at all amt values; spatial variation reads convincingly. → Proceed to Phase 4.

---

## Phase 4: Build Script → f_lens.maxpat

**Purpose:** Generate the production patcher from the confirmed implementation using a Python build script.

- [ ] T023 Write `~/Vsynth/patterns/build_f_lens.py`; define all objects appropriate to chosen architecture: 3 inlets, routepass objects per texture inlet (in1 routepass out2 → route for control), all internal pix/pass/fx objects, autopattr, moduleSize chain, title, background panel
- [ ] T024 Add `bypass_toggle.js` jsui wired correctly; ensure jsui defined before any jit.gl.pix in boxes array (lesson from f_stereo crash)
- [ ] T025 Add 8× `live.dial` + `prepend param <name>` for: aberration, distortion, transmission, tilt, tilt_axis, tilt_pos, surface_amt, field_amt; correct param_connect, parameter_enable, varname, min/max ranges
- [ ] T026 Define UI presentation layout: two rows of four dials; Row 1: aberration, distortion, transmission, tilt; Row 2: tilt_axis, tilt_pos, surface_amt, field_amt; bypass_toggle top-right; title "f_lens" top-left
- [ ] T027 Add `parameters` block registering all param objects (8 dials + bypass jsui)
- [ ] T028 Run build script; copy output to `patchers/f_lens.maxpat`
- [ ] T029 Open `f_lens.maxpat` in Max; verify no errors, no crashes, all objects load cleanly; verify presentation layout correct

**Checkpoint:** f_lens.maxpat opens without errors. All dials and bypass visible in presentation. → Proceed to Phase 5.

---

## Phase 5: Vsynth Integration and Composition

**Purpose:** Verify f_lens works correctly in full Vsynth context and composes with other f_ bpatchers.

- [ ] T030 Load f_lens in Vsynth context with `vs_noise_3` → in1; sweep each param across full range; verify all effects behave as in scratch patch
- [ ] T031 Verify bypass: bypass=1 → raw texture passthrough
- [ ] T032 Verify autopattr state save/restore: set params to non-default values, save and reopen patch, confirm values restored
- [ ] T033 Verify moduleSize.js chain: confirm f_lens reports correct presentation size to Vsynth
- [ ] T034 Test `f_grain → f_lens → output`; verify f_lens processes f_grain output cleanly
- [ ] T035 Test `f_grain → f_lens → f_stereo → output`; verify correct composition through multiple processors
- [ ] T036 Test in2 in Vsynth: wire `f_grain` → in2 with surface_amt raised; verify spatially non-uniform surface character in full render
- [ ] T037 Test in3 in Vsynth: wire `vs_noise_3` (slow, large scale) → in3 with field_amt raised; verify organic distortion field variation
- [ ] T038 Test named float messages on in1 (`aberration 0.5`, `tilt 0.8` etc.); verify params update correctly
- [ ] T039 Check frame rate: confirm no significant GPU performance drop vs baseline with all effects active at moderate values

**Checkpoint:** f_lens fully functional in Vsynth context. All composition chains work. State save/restore confirmed. → Proceed to Phase 6.

---

## Phase 6: Documentation

- [ ] T040 Write `docs/f_lens.md` — as-built reference: what it does, chain position, inlets, params table, internal architecture summary, effect ordering decision (ADR-4 result), known behaviors and quirks
- [ ] T041 Update `README.md`: add f_lens to patches table as ✅ Working; update build queue
- [ ] T042 Update `HANDOFF.md` with session summary

**Checkpoint:** Documentation complete. f_lens graduates from `.specify/` to `docs/`.

---

## Dependencies

- Phase 0 → gates everything; architecture decided before any effect work
- Phase 1 → gates Phases 2 and 3 (effect structure established first)
- Phases 2 and 3 → independent of each other once Phase 1 complete
- Phase 4 → gates Phase 5 (needs working patch file)
- Phase 5 → gates Phase 6 (docs written from as-built behavior)

---

## Notes

- Phase 0 is genuinely open — the right internal objects may be jit.gl.pix, jit.gl.pass, jit.fx, or a combination; this is discovered empirically in Max
- The scratch patch at `~/Vsynth/patterns/` is not version controlled — development workspace only
- If Phase 0 reveals Option B (pipeline of pix objects), Phases 1–3 task descriptions apply to their respective pix rather than one shared codebox
- bypass_toggle.js jsui must appear before any jit.gl.pix in the boxes array — see f_stereo crash post-mortem
- ADR-4 (effect ordering) resolved during T010; update spec.md Clarifications immediately after deciding
