# Tasks: f_weave

**Spec**: `.specify/f_weave/spec.md`
**Plan**: `.specify/f_weave/plan.md`
**Build order**: Sequential. Complete each phase before next.
**Commits**: Per phase checkpoint, or per logical milestone within a phase.

---

## Expected File Layout

```
~/Vsynth/patterns/
  f_weave_scratch.maxpat        — scratch patch (not version controlled)

/Users/matt/Github/f_/
  .specify/f_weave/
    spec.md                     ✅ done
    plan.md                     ✅ done
    tasks.md                    ✅ this file
    definition.py               — Phase 3
  patchers/
    f_weave.maxpat              — Phase 3
  javascript/
    f_addmod.js                 — Phase 4 (add SIZES entry)
  .specify/f_modules/
    build_modules.py            — Phase 4 (add category entry)
  patchers/
    f_modules.maxpat            — Phase 4 (regenerated)
```

---

## Phase 1: Codebox in scratch patch — ✅ COMPLETE

All tasks verified empirically. Architecture changed significantly from original plan —
see spec.md for rationale.

### Key findings from Phase 1:

- **No euclidean_hit function** — Euclidean rhythm requires metered slots (grid
  structure). Replaced with continuous fract-based mark distance field.
- **No band_idx as grid identity** — line_idx used only as hash seed for per-line
  phase offset. Not a grid lane.
- **No curl param** — per-pixel orientation rotation aliases at any meaningful density.
  Vecfield inlet provides smooth orientation variation correctly.
- **No continuity, swing** — both require slot/band identity. Deferred to v2.
- **`marklen` not `softness`** — renamed to reflect actual function (mark length
  along line). Note: `length` is a reserved word in GenExpr — use `marklen`.
- **`regularity` must be clamped [0,1]** — unbounded values corrupt the hash.
- **Droste compatibility confirmed** — distance field marks survive singularity
  cleanly. Reference implementation for correct approach vs f_masonry.

### Confirmed working codebox (paste into gen subpatcher):

```
Param density(0.5);
Param angle(0.0);
Param weight(0.1);
Param marklen(0.3);
Param regularity(0.5);
Param phase(0.0);
Param bypass(0.0);

cs = cos(angle * pi);
sn = sin(angle * pi);
across = norm.x * cs + norm.y * sn;
along  = norm.x * (-sn) + norm.y * cs;

density_scale = pow(2.0, density * 5.0 - 1.0);

dist_to_line = abs(fract(across * density_scale) - 0.5);

line_idx = floor(across * density_scale);
line_hash = fract(sin(line_idx * 127.1) * 43758.5453) * (1.0 - clamp(regularity, 0.0, 1.0));
pos = along * density_scale + phase + line_hash;
dist_to_mark = abs(fract(pos) - 0.5);

mark = smoothstep(weight, 0.0, dist_to_line) * smoothstep(marklen, 0.0, dist_to_mark);

out1 = mix(vec(mark, mark, mark, 1.0), vec(0.5, 0.5, 0.5, 1.0), bypass);
```

### Completed tasks:
- [x] T001 Scratch patch scaffolded
- [x] T002–T006 Euclidean rhythm core — superseded; continuous fract approach used instead
- [x] T007–T011 Orientation field and rotation — working cleanly
- [x] T012–T014 Band structure — redesigned as continuous distance field
- [x] T015–T018 Mark rendering — confirmed working
- [x] T019 Denim character verified (low weight, high marklen, regularity=0.5)
- [x] T020 Scattered character verified (low regularity)
- [x] T021 Continuous woven surface verified (high weight + marklen)
- [x] T022 Phase animation smooth and continuous
- [x] T023 Droste compatibility confirmed ✅

---

## Phase 2: Vecfield inlet in scratch patch

**Purpose**: Verify additive vecfield orientation contribution.

- [ ] T024 Add `in2` reference to codebox; add `in 2` gen object in gen subpatcher;
      wire to codebox in2
- [ ] T025 Add `vs_inState` bpatcher on pix inlet 1 in scratch patch; wire mode
      outlet to `prepend param src_vecfield` → pix inlet 0
- [ ] T026 Add `Param src_vecfield(0.0)` to codebox (system-driven, not user-facing)
- [ ] T027 Refactor orientation to use theta variable:
      `theta = angle * pi;`
      `cs = cos(theta); sn = sin(theta);`
- [ ] T028 Implement vecfield angle decode (inline — no stored vec component access):
      `vf_angle = atan2(sample(in2, norm).y - 0.5, sample(in2, norm).x - 0.5);`
- [ ] T029 Add gated vecfield contribution:
      `theta = angle * pi + vf_angle * src_vecfield * SCALE;`
      where SCALE is TBD from empirical testing
- [ ] T030 Connect f_vf_vortex to pix inlet 1; sweep SCALE value — field should
      deflect lines expressively without overwhelming angle param; document chosen value
- [ ] T031 Verify: vecfield connected → lines deflect along field direction
- [ ] T032 Verify: vecfield disconnected → orientation param-only, no residual
      from vs_black output

**Checkpoint**: Vecfield inlet working, scale factor documented.

---

## Phase 3: definition.py + built patcher

**Purpose**: Promote confirmed codebox to built patcher via build system.

- [ ] T033 Read `tools/spec.md` for definition.py schema
- [ ] T034 Write `.specify/f_weave/definition.py`:
      - Confirmed codebox (Phase 1 + Phase 2 vecfield addition)
      - Params: density, angle, weight, marklen, regularity, phase, bypass, src_vecfield
      - Archetype: generator
      - Two inlets: char in0, float32 in1
      - `src_vecfield` system-driven: omit from route, UI objects, parameters block
- [ ] T035 Run build:
      `tools/py.sh tools/build_patcher.py .specify/f_weave/definition.py patchers/f_weave.maxpat`
- [ ] T036 Validate JSON:
      `python3 -c "import json; json.load(open('patchers/f_weave.maxpat'))"`
- [ ] T037 Open in Max; verify patch loads without errors
- [ ] T038 Verify all params respond: density, angle, weight, marklen, regularity, phase
- [ ] T039 Verify bypass toggles correctly (output → mid-grey)
- [ ] T040 Verify UI layout in presentation mode
- [ ] T041 Commit: `feat: add f_weave generator (codebox + patcher)`

**Checkpoint**: Patcher opens, all params work, UI correct, committed.

---

## Phase 4: Integration + registration

**Purpose**: Register in f_modules, integration-test, finalize.

- [ ] T042 Measure `presentation_rect` of f_weave background panel (w, h)
- [ ] T043 Add to `javascript/f_addmod.js` SIZES dict: `"weave": [w, h]`
- [ ] T044 Add to `.specify/f_modules/build_modules.py` under Generators:
      `("Weave", "weave")`
- [ ] T045 Regenerate f_modules:
      `tools/py.sh .specify/f_modules/build_modules.py`
- [ ] T046 Validate f_modules JSON
- [ ] T047 Open f_modules in Max; confirm Weave in Generators menu
- [ ] T048 Spawn f_weave from menu; confirm size correct and patch loads
- [ ] T049 Integration test: f_weave → f_droste (distance field criterion)
- [ ] T050 Integration test: f_vf_vortex → f_weave in1 (vecfield deflection)
- [ ] T051 Integration test: f_weave → f_vf_fieldmap → f_caustic
- [ ] T052 Update `README.md` — add f_weave under Generators
- [ ] T053 Update `ideas/f_weave.md` — mark status as Built
- [ ] T054 Commit: `feat: register f_weave in f_modules menu`

**Checkpoint**: f_weave spawns from menu, integration tests pass, committed.

---

## Notes

- `marklen` not `length` — `length` is a reserved word in GenExpr
- `src_vecfield`: system-driven param, omit from route/UI/parameters block
- `regularity` clamped [0,1] in codebox — do not expose unbounded
- vecfield scale factor from T030: document in definition.py codebox comments
- Phase 2 vecfield decode: use inline sample() — no stored vec component access
  (GenExpr silent failure: `v = sample(...); v.x` → 0)
