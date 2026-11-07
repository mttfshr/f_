# Tasks: f_vf_glow

**Spec**: .specify/f_vf_glow/spec.md
**Plan**: .specify/f_vf_glow/plan.md
**Build order**: Sequential. Complete each phase before next.

---

## Expected Source Layout

```
f_/
  patchers/
    f_vf_glow.maxpat              — built by build_patcher.py from definition.py
  .specify/f_vf_glow/
    spec.md                       — done
    plan.md                       — done
    tasks.md                      — this file
    definition.py                 — written in Phase 2, input to build_patcher.py
  docs/
    f_vf_glow.md                  — as-built reference, written in Phase 4
```

Scratch work lives at `~/Vsynth/patterns/` (not version controlled).

---

## Phase 1: Codebox — write and verify in scratch patch

**Purpose**: Lock all shader logic before writing any build infrastructure. Highest-risk phase.

⚠️ CRITICAL: definition.py and build cannot happen until codebox is confirmed working.

- [x] T001 Open scratch patch at `~/Vsynth/patterns/glow_scratch.maxpat` with `vs_render` bpatcher + toggle; add `jit.gl.pix @drawto vsynth @name glow_pix @type char` with gen subpatcher
- [x] T002 Add `in 1`, `in 2`, `in 3` objects to gen subpatcher; wire all three to codebox inlets
- [x] T003 Write codebox — core accumulation loop (see codebox draft below); paste into Max and confirm compile (no red errors in console)
- [x] T004 Wire a test source texture to pix in0; wire `f_vf_vortex` output to pix in1; leave pix in2 unconnected — confirm vs_black suppression: glow should be absent with no field connected
- [x] T005 Connect `f_vf_vortex` to pix in1 — confirm glow traces vortex streamlines (arcs, not radial halos)
- [x] T006 Test `direction` param: verify 0=bidirectional (symmetric), 1=forward (trail), 2=backward (lead) all produce visually distinct results
- [x] T007 Test `radius` param across range 0.0–0.2: confirm glow extent scales proportionally
- [x] T008 Test `falloff` param across range 0.0–0.05: confirm tight vs. diffuse glow shape
- [x] T009 Test `color_mix` param: 0.0 = chromatic glow, 1.0 = neutral/white glow
- [x] T010 Test `strength` param: 0.0 = source only, 1.0 = fully glowed composite
- [x] T011 Connect a gradient texture to pix in2 (radius mod): confirm glow extent varies spatially across frame
- [x] T012 Test out1 isolated glow: confirm it carries only accumulated glow with no source texture bleedthrough
- [x] T013 Test `bypass`: out0 = clean source, out1 = black
- [x] T014 Test zero-magnitude field region (vortex center): confirm tight spot with no spread, no artifacts

**Checkpoint**: All 14 test cases passing. Codebox text is final — copy it before closing Max.

---

## Phase 2: definition.py + build

**Purpose**: Encode confirmed codebox into definition.py; generate the production patcher.

- [x] T015 Create `.specify/f_vf_glow/definition.py` — patcher dict with confirmed codebox text, archetype, name, all params
- [x] T016 Add `outlets` key: `[{"label": "composite", "color": "green"}, {"label": "glow layer", "color": "cyan"}]`
- [x] T017 Add inlet definitions: in0 = `texture / control` (standard), in1 = `vecfield` (float32, cyan label), in2 = `radius mod` (gray label); all three with `vs_instate: true`
- [x] T018 Add all six params to definition.py params block with correct ranges and defaults from spec
- [x] T019 Run `tools/py.sh tools/build_patcher.py .specify/f_vf_glow/definition.py patchers/f_vf_glow.maxpat`
- [x] T020 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_glow.maxpat'))"` — must pass with no error
- [x] T021 Open `f_vf_glow.maxpat` in Max — confirm pix compiles (no red errors), all params visible in UI, presentation layer looks correct
- [x] T022 Verify inlet/outlet count in Max: 3 inlets, 2 outlets with correct label colors

_T015-T022 closed 2026-11-06 (offline by Claude): shipped build checklist. `build/drift.py` reproduces `package/patchers/f_vf_glow.maxpat` from `src/f_vf_glow/definition.py`; 3 inlets and 2 outlets read from the patcher; the contract bench loads it (`tests/logs/20261106-081412-bench.log`). Paths here are the old ones. As shipped, in0 has no `vs_inState` (T017 said all three) and the params follow the gain/mix rollout._

**Checkpoint**: Patch opens clean. All params present. Two outlets correctly labeled.

---

## Phase 3: Integration testing

**Purpose**: Verify f_vf_glow works correctly as a bpatcher inside a real Vsynth signal chain.

- [ ] T023 Drop `f_vf_glow` as bpatcher into a Vsynth patch; connect source texture to in0, `f_vf_vortex` to in1 — confirm visual output on composited outlet
- [ ] T024 Re-run all Phase 1 acceptance tests (T004–T014) against the built bpatcher — confirm all pass
- [ ] T025 Test out1 isolated glow outlet: connect to a downstream `f_channel_grader` or viewer — confirm isolated layer only
- [ ] T026 Test with `f_vf_vortex_multi` and `f_vf_fieldmap` as field sources — confirm module works with all vecfield producers
- [x] T027 Test bypass toggle in presentation: confirm clean pass-through on out0, black on out1
- [ ] T028 Save patch state with autopattr; close and reopen — confirm all params restore correctly

_2026-11-06 (offline by Claude): T027 closed under the later all-outlets rule, so out1 passes the source, not black (ca02912; `BYPASS_EXPECT` in `tests/contracts/bench_modules.py`). T023-T026 and T028 stay open: no dated live record found. T045 covers T023; the rest are Matt's to confirm or waive._

**Checkpoint**: All spec acceptance scenarios confirmed in production bpatcher context.

---

## Phase 4: Registration + docs

**Purpose**: Make f_vf_glow a first-class member of the f_ library.

- [x] T029 Write `docs/f-reference/f_vf_glow.md` — as-built reference: params table, signal chain, inlet/outlet contract, known quirks (vs_black suppression behavior, radius mod scaling)
- [x] T030 Add `f_vf_glow` to `patchers/f_modules.maxpat` Vecfield category — run `.specify/f_modules/build_modules.py` to regenerate
- [x] T031 Add entry to `javascript/f_addmod.js` SIZES dict: `"vf_glow": [w, h]` — get dimensions from presentation_rect of background panel in built patcher
- [x] T032 Validate `f_modules.maxpat` JSON: `python3 -c "import json; json.load(open('patchers/f_modules.maxpat'))"`
- [x] T033 Add `f_vf_glow` row to `README.md` patch table (after `f_vf_advect`)
- [x] T034 Update `.specify/plan.md` work queue: mark f_vf_glow done, advance next item
- [x] T035 Write `HANDOFF.md` for session end

_T029-T035 closed 2026-11-06 (offline by Claude): doc exists; `src/f_modules/menu.py:84`; `package/javascript/f_addmod.js:41` [190, 120]; `generate_menu.py --check` up to date; `README.md:83`. T034-T035 are superseded by the current plan and HANDOFF records._

**Checkpoint**: `f_vf_glow` spawnable from f_modules menu. Docs complete. README current.

---

## Codebox Draft (for T003)

Starting point — verify and adjust in Max before treating as final.

```
// f_vf_glow codebox — 24-step field-aligned accumulation
// in1 = source texture, in2 = vecfield (float32 RG, 0.5=zero), in3 = radius mod

Param radius(0.05);
Param falloff(1.5);
Param strength(0.8);
Param color_mix(0.0);
Param direction(0.0);
Param bypass(0.0);

uv = norm;

// sample source at current pixel
src_r = sample(in1, uv).x;
src_g = sample(in1, uv).y;
src_b = sample(in1, uv).z;
src_a = sample(in1, uv).w;

// read raw vecfield — check for vs_black before remapping
raw_x = sample(in2, uv).x;
raw_y = sample(in2, uv).y;
field_suppress = step(0.02, raw_x + raw_y);  // 0 if both near zero (vs_black), 1 otherwise

// remap field from [0,1] to [-1,1]
fx = (raw_x - 0.5) * 2.0 * field_suppress;
fy = (raw_y - 0.5) * 2.0 * field_suppress;

// radius modulation — additive, scaled by base radius
mod_val = sample(in3, uv).x;
radius_eff = clamp(radius + mod_val * radius, 0.0, 0.3);

// step delta per iteration
dx = fx * radius_eff;
dy = fy * radius_eff;

// direction weights (branchless)
// dir=0 (bi): fwd=1, bwd=1 | dir=1 (fwd): fwd=1, bwd=0 | dir=2 (bwd): fwd=0, bwd=1
fwd_weight = 1.0 - step(1.5, direction);
bwd_weight = 1.0 - step(0.5, direction) + step(1.5, direction);

// 24-step accumulation
accum_r = 0.0; accum_g = 0.0; accum_b = 0.0; accum_w = 0.0;

for (i = 1.0; i <= 24.0; i += 1.0) {
  w = exp(-i * i * falloff * 0.1);

  fwd_u = uv.x + dx * i;
  fwd_v = uv.y + dy * i;
  fwd_u = clamp(fwd_u, 0.0, 1.0);
  fwd_v = clamp(fwd_v, 0.0, 1.0);

  bwd_u = uv.x - dx * i;
  bwd_v = uv.y - dy * i;
  bwd_u = clamp(bwd_u, 0.0, 1.0);
  bwd_v = clamp(bwd_v, 0.0, 1.0);

  fwd_uv = vec(fwd_u, fwd_v);
  bwd_uv = vec(bwd_u, bwd_v);

  accum_r = accum_r + sample(in1, fwd_uv).x * w * fwd_weight;
  accum_g = accum_g + sample(in1, fwd_uv).y * w * fwd_weight;
  accum_b = accum_b + sample(in1, fwd_uv).z * w * fwd_weight;

  accum_r = accum_r + sample(in1, bwd_uv).x * w * bwd_weight;
  accum_g = accum_g + sample(in1, bwd_uv).y * w * bwd_weight;
  accum_b = accum_b + sample(in1, bwd_uv).z * w * bwd_weight;

  accum_w = accum_w + w * fwd_weight + w * bwd_weight;
}

// normalize accumulation
norm_r = accum_r / max(accum_w, 0.0001);
norm_g = accum_g / max(accum_w, 0.0001);
norm_b = accum_b / max(accum_w, 0.0001);

// color_mix: blend toward luma
luma = norm_r * 0.2126 + norm_g * 0.7152 + norm_b * 0.0722;
glow_r = mix(norm_r, luma, color_mix);
glow_g = mix(norm_g, luma, color_mix);
glow_b = mix(norm_b, luma, color_mix);

// composite: source + glow
comp_r = clamp(src_r + glow_r * strength, 0.0, 1.0);
comp_g = clamp(src_g + glow_g * strength, 0.0, 1.0);
comp_b = clamp(src_b + glow_b * strength, 0.0, 1.0);

// bypass
out1 = mix(vec(comp_r, comp_g, comp_b, src_a), vec(src_r, src_g, src_b, src_a), bypass);

// isolated glow outlet (zeroed on bypass)
glow_out = mix(vec(glow_r, glow_g, glow_b, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);
out2 = glow_out;
```

**Notes on the draft**:
- `falloff * 0.1` scaling keeps the param range (0–5) feeling proportional — weight at step 1 with falloff=1.5 is `exp(-1 * 1 * 0.15)` ≈ 0.86, at step 10 ≈ 0.22. Adjust multiplier in Max to taste.
- `bwd_weight` expression: `1.0 - step(0.5, dir) + step(1.5, dir)` — verify in Max: dir=0→1, dir=1→0, dir=2→1. ✓
- Component access is all inline on `sample()` calls — no stored-variable `.x` access.
- `for` loop uses `1.0` not `1` — GenExpr is typeless but float literals are safer.
- `out2` reference in codebox is what creates the second codebox outlet (same mechanism as `in3` creating a third inlet).

---

## Dependencies & Execution Order

- Phase 1 → Phase 2 (codebox must be confirmed before definition.py is written)
- Phase 2 → Phase 3 (patcher must build and open before integration testing)
- Phase 3 → Phase 4 (all tests must pass before registration)
- T030 depends on T031 (need presentation_rect dimensions before updating f_addmod.js)
- T032 depends on T030 (validate after regenerating f_modules)

No parallel opportunities — this build is inherently sequential due to the scratch-patch-first workflow.

---

## Maintenance (2026-10-12 audit)

_This module moved off .specify/stable/ this session: the audit found
actionable items, and a module with open tasks doesn't meet stable/'s
nothing-outstanding bar (.specify/maintenance/SKILL.md)._

- [x] T036 (closed 2026-11-06: profiled and decided in T036a, 0b6f3b1): Profile the 48-tap accumulation loop's cost and A/B an
  early-exit guard under param bypass. bypass_gate currently only
  mixes at the end — the loop runs full cost while bypassed (the known
  open item from plan.md's "Open: GPU cost", unmeasured for this
  module). Two open ideas name it: ideas/incremental_gaussian_taps.md
  (unprofiled; also names prism/streak) and
  ideas/glow_profile_and_afterimage.md (3 more tabled ideas). A single
  profiling session could cover glow + prism + streak together.
- [x] T037 (closed 2026-11-06 by the stable preflight below): Refresh docs/f-reference/f_vf_glow.md — it still documents
  `strength` (renamed gain/mix_pct 2026-07-17) and the pre-2026-10-05
  bypass behavior ("out1 passes source; out1 goes black" — the rule is
  now all-outlets passthrough). One doc pass.
- [x] T038 (closed 2026-11-06: mirror built, T044): Record a tier-1-skip decision (or build the trivial
  closed-form mirror: falloff weights + zero-vector field →
  passthrough). The module predates Verification Tiers with no
  recorded decision — same shape as f_grain/f_vf_advect's finding.

- [x] T036a (2026-10-13): Profiled on the live bench
  (`tests/records/spike_four_module_cost.py`, 512², chain=128, median of 3):
  **0.0573 ms/pass active, 0.0582 ms/pass bypassed** — GPU-bound at
  this config (the only one of the glow/prism/streak/chladni group that
  resolved as GPU-bound rather than an upper bound). Confirms
  `bypass_gate` does not skip the 48-tap loop — the delta is slightly
  negative, i.e. no measurable savings. Absolute cost is small for a
  single instance (~0.06 ms, ~0.3% of a 60 fps frame budget), so T036's
  "A/B an early-exit guard" has not been built/measured this session.
  **Decision (Matt, 2026-10-13): not worth building now.** Revisit only
  if a general reason to build early-exit guards emerges across modules
  (not specific to glow's chained-instance case) — not a standing TODO
  against this module alone.

## Phase 5: Tensor anisotropy inlet (hub Q12; unblocked 2026-10-16)

`f_tf_tensormap` now exists, so the zero-new-UI design in
`ideas/f_tensorfield.md` Q12 can be built. Design stands, with one change:
tensormap outlet 1 carries **coherence in A (`.w`)**, not `.x`, so the gate
reads `sample(in4, uv).w`.

- [ ] T039 Add a third `mod_inlets` entry `{"label": "anisotropy", "state_param": "src_anisotropy"}` in `definition.py`; rebuild; update contract tests.
- [ ] T040 Codebox: `Param src_anisotropy(0.0); aniso = mix(1.0, sample(in4, uv).w, src_anisotropy); fwd_weight = mix(1.0, fwd_mode, aniso); bwd_weight = mix(1.0, bwd_mode, aniso);` Connection detection MUST use `src_anisotropy` (an unconnected inlet samples 0, but the neutral here is 1.0).
- [ ] T041 Tier-1 mirror of the weight maths (direction 0 unchanged; low coherence pulls modes 1/2 to the bidirectional floor) and a bench parity check.
- [ ] T042 Live check: `f_tf_tensormap` outlet 1 -> glow anisotropy inlet at `direction` 1 and 2; unconnected = unchanged from today.
- [ ] T043 Docs: `docs/f-reference/f_vf_glow.md` (new inlet), helpfile, README note. Deferred (do not build): a performer-facing gain dial (waits for `mod_depth_ui_density.md`).

- [x] T044 **Tier-1 NumPy mirror (omp run mirror-build-1, landed 2026-10-19).** `tests/modules/vf_glow/{vf_glow_mirror,test_vf_glow}.py`, 10/10 offline. Checks: a zero field returns the source, ramp readbacks, the closed-form composite and Rec. 709 luma (color_mix 1), bypass on both outlets. See `HANDOFF.md` 2026-10-19.
- [x] T046 Stable preflight (2026-11-06, offline by Claude), record below.
- [x] T045 Matt's helpfile look: the new demo chain, the digest, the two notes, and the Mix 50 load message.

## Stable preflight (2026-11-06)

Part 1 offline by Claude: drift ok, no baseline entry; menu and launcher `--check` up to date; README row 110 chars before the edit offered, no ⚠; menu entry `menu.py:84`, recipe Chladni Glow; bypass is `bypass_gate` (`bypass_mode: "param"`, `BYPASS_EXPECT` `{2: IN1}`; contract bench line in `tests/logs/20261106-081412-bench.log`, from before these edits, which touch no patcher or codebox); helpfile box 208x130 against a 190x120 frame. The route is `radius falloff gain mix_pct color_mix direction`, no `bypass` selector, and the helpfile has no `bypass [0 / 1]` line, which is right. No gate row holds Glow except `G-helpfiles`, which names it. Tests: mirror `tests/modules/vf_glow/` (T044; read, not run this session) and the contract bench; no `bench_*` file of its own.

Patcher against docs: three inlets (texture / control, vecfield, radius mod), two outlets (composite, glow). `vs_inState` on inlets 1 and 2 only. No `r draw`, so only the source triggers the pix, and no source means no output (wiring read; behavior inferred, not run).

Fixed in the doc: `strength` at line 25; "streamlines", since the codebox reads the field once and steps in a straight line (code read, not run); "exponential" falloff, which is Gaussian in the step index; the `mix_pct` pseudocode; `direction` 1 and 2, which had the glow on the wrong side (a gather lands the glow opposite the sampling direction); `converge`, which is `convergence`; "high `direction` values"; "tangentially along the image gradient"; the cost note still saying unprofiled. Added: no threshold, Mix 0 means composite = source, bypass is toggle only.

Found, not changed: `vs_inState` outlet 1 feeds `param src_vecfield`, but the codebox has no such Param; the field is gated by value (`step(0.02, raw_x + raw_y)`). Output is unaffected as far as the code shows. Whether Max logs anything for the unknown param was not checked. `spec.md` and `plan.md` still say `strength` (6 lines each) and predate the rollout.

Chains in `library-characteristics.md`: several fed Glow no field, which gives no spread; the row profile varies across x, not per row (its doc: consumers sample at normalized X). Edits returned to the main session, not applied here.

Helpfile: nothing was wired upstream, and the bpatcher box said 2 inlets (now 3). Added `vs_sources_main` -> inlet 0, `f_vf_vortex` -> inlet 1, and loadbang -> `delay 300` -> `mix_pct 50`, the `f_vf_ch` pattern, because at Mix 0 the preview would show only the source. Added `direction`, which was missing from the message list. Window height raised 50 px to fit the stack. Expected (from the codebox, not seen): source plus 0.4 x glow, radial streaks through the center, frame brighter; depends on a movie being loaded on the Movie tab. No box overlaps another by rect (preview 338-574 x 466-715; notes 556-761 x 328-426 and 590-766 x 466-686). `test_generate_menu.py` 17/17 (`tests/logs/20261106-181204-offline.log`). Live by Matt: T045.

Phase 5 (T039-T043) is unbuilt and stays open: Matt's call whether it carries over, since `stable/` means nothing outstanding.

## Moved to stable/ (2026-11-06)

Matt's helpfile looks passed 2026-11-06 ("helpfile looks pass", for the group, live by Matt). Contract bench `tests/contracts/bench_modules.py` 2/2, 0 unexpected live contract issues, all four modules in the roster (log `tests/logs/20261106-192009-bench.log`, Max 9.2.0, git fb693ee dirty; run by Claude at Matt's go, live). The folder holds only markdown: no scripts, no `parents[N]` or `../` paths, and `definition.py` has no `Spec:` line, so nothing needed changing there. References to this folder in docs and ideas were updated to `.specify/stable/`.

Carried over under the stable bar (Matt confirmed 2026-11-06): T039-T043, the unbuilt tensor anisotropy inlet (a future feature, not a bug or a doc fault); T023-T026 and T028, no dated live record found; the dead `src_vecfield` binding (the patcher sends a param the codebox never declares; output looks unaffected, Max's log not checked). Gate `G-helpfiles` still lists the old audit finding; this module's helpfile was rewritten and looked at.
