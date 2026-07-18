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

- [ ] T015 Create `.specify/f_vf_glow/definition.py` — patcher dict with confirmed codebox text, archetype, name, all params
- [ ] T016 Add `outlets` key: `[{"label": "composite", "color": "green"}, {"label": "glow layer", "color": "cyan"}]`
- [ ] T017 Add inlet definitions: in0 = `texture / control` (standard), in1 = `vecfield` (float32, cyan label), in2 = `radius mod` (grey label); all three with `vs_instate: true`
- [ ] T018 Add all six params to definition.py params block with correct ranges and defaults from spec
- [ ] T019 Run `tools/py.sh tools/build_patcher.py .specify/f_vf_glow/definition.py patchers/f_vf_glow.maxpat`
- [ ] T020 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_glow.maxpat'))"` — must pass with no error
- [ ] T021 Open `f_vf_glow.maxpat` in Max — confirm pix compiles (no red errors), all params visible in UI, presentation layer looks correct
- [ ] T022 Verify inlet/outlet count in Max: 3 inlets, 2 outlets with correct label colors

**Checkpoint**: Patch opens clean. All params present. Two outlets correctly labeled.

---

## Phase 3: Integration testing

**Purpose**: Verify f_vf_glow works correctly as a bpatcher inside a real Vsynth signal chain.

- [ ] T023 Drop `f_vf_glow` as bpatcher into a Vsynth patch; connect source texture to in0, `f_vf_vortex` to in1 — confirm visual output on composited outlet
- [ ] T024 Re-run all Phase 1 acceptance tests (T004–T014) against the built bpatcher — confirm all pass
- [ ] T025 Test out1 isolated glow outlet: connect to a downstream `f_channel_grader` or viewer — confirm isolated layer only
- [ ] T026 Test with `f_vf_vortex_multi` and `f_vf_fieldmap` as field sources — confirm module works with all vecfield producers
- [ ] T027 Test bypass toggle in presentation: confirm clean pass-through on out0, black on out1
- [ ] T028 Save patch state with autopattr; close and reopen — confirm all params restore correctly

**Checkpoint**: All spec acceptance scenarios confirmed in production bpatcher context.

---

## Phase 4: Registration + docs

**Purpose**: Make f_vf_glow a first-class member of the f_ library.

- [ ] T029 Write `docs/f-reference/f_vf_glow.md` — as-built reference: params table, signal chain, inlet/outlet contract, known quirks (vs_black suppression behavior, radius mod scaling)
- [ ] T030 Add `f_vf_glow` to `patchers/f_modules.maxpat` Vecfield category — run `.specify/f_modules/build_modules.py` to regenerate
- [ ] T031 Add entry to `javascript/f_addmod.js` SIZES dict: `"vf_glow": [w, h]` — get dimensions from presentation_rect of background panel in built patcher
- [ ] T032 Validate `f_modules.maxpat` JSON: `python3 -c "import json; json.load(open('patchers/f_modules.maxpat'))"`
- [ ] T033 Add `f_vf_glow` row to `README.md` patch table (after `f_vf_advect`)
- [ ] T034 Update `.specify/plan.md` work queue: mark f_vf_glow done, advance next item
- [ ] T035 Write `HANDOFF.md` for session end

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
