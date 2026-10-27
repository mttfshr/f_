# Tasks: f_cmap

_Created: 2026-10-26. Spec: `spec.md`. Record of each task goes under it when done._

Verification follows the three tiers (`.specify/constitution.md`): mirror first, the real
`src/` codebox on the bench second, a live look third. No scratch-patch stage.

## Phase 0 - model, mirror, measurements (offline, no Max except T006)

- [ ] **T001** `tests/modules/cmap/cmap_mirror.py`: float64 NumPy mirror of one frame
  (coordinates, `z^n + w` by repeated multiplication, bounds rules, `mix`), plus a
  `run_temporal` that ping-pongs frames with a chosen sampler (nearest, bilinear,
  Catmull-Rom) and wrap rules matching `tests/lib/gpu_sim.py`.
- [ ] **T002** `test_cmap.py` tier-1 checks: identity-map invariance (FR-010); Jacobian is
  a scaled rotation at aspect 1, 16:9, 9:16 (SC-002, finite difference); fixed points of
  `z = z^2 + w`; bounds region exactly the pulled-outside-frame set (SC-004); `rate` 0
  freezes `w`; mutations caught (aspect applied twice, `n` off by one, swapped x/y).
- [ ] **T003** Composition test (SC-003): nearest sampling, no decay, no injection, after
  n frames the image at z equals the original at `f^n(z)` for n = 1..5.
- [ ] **T004** Smear measurement (`tests/records/spike_cmap_smear.py`): impulse
  persistence and blur growth per frame, bilinear versus Catmull-Rom, centre versus edge;
  where aliasing starts. Decides gate G4.
- [ ] **T005** Look stills from the mirror on synthetic input (noise, gradient, a moving
  edge; never the checker as a module feature): usable `decay` / `inject` / `radius` /
  `sweep` region, whether `sweep` is needed, trim for G6.
- [ ] **T006** Cost bench (Max, with Matt): single pass plus `pass` copy at 1080p and 4K;
  report a bound if under the bench's resolution floor. NF-001; M1 unmeasured.

### Gates (Matt)

- [ ] **G1** Naming (`f_cmap` or a name a performer reads).
- [ ] **G2** Bounds region: frame rectangle (proposed) or the source's disk.
- [ ] **G3** `power`: integer 2-4 or fixed at 2.
- [ ] **G4** Sampler: bilinear plus injection, or Catmull-Rom (after T004).
- [ ] **G5** No `gain` / `mix_pct` in v1 (inject is the source blend): confirm.
- [ ] **G6** Control trim (after T005).

## Phase 1 - build (T020-T023)

- [ ] **T020** Codeboxes `src/f_cmap/codebox_cmap_pass.gen` and `codebox_cmap.gen`, and
  `definition.py` modelled on `src/f_vf_advect/definition.py` (Pattern 1: pass and primary
  pix, float32, `adapt`, `pix_wires` state -> pass -> state in2). Check every control
  name against `jit.gl.pix` attributes and GLSL builtins (FR-009; the `depth`, `texture`
  and `t` traps), frame-size-change behaviour, NaN guard (NF-003).
- [ ] **T021** Patcher clock for `theta` / the sqrt(2) phase on `rate` (`f_quasi` clock
  precedent), exact freeze at rate 0; freeze and reset wiring (`f_wc` header toggle).
- [ ] **T022** `tests/modules/cmap/bench_cmap.py` (register in `tests/lib/benchdeps.py`,
  pick an unused ORDER): codebox versus mirror frame by frame, bypass, bounds modes. Give
  the first input the render's size (the `dim` finding).
- [ ] **T023** Registration: README row (Patterns, with a unverified marker until Phase 3),
  `build/py.sh build/generate_launch.py`, `NOT_IN_MENU` entry until Phase 3, drift,
  module contract bench. Offline suite once at the end.

## Phase 2 - tuning and extensions (gated)

- [ ] **T030** Tuning with live camera (Matt): defaults, ranges, `inject` / `decay` feel.
- [ ] **T031** Optional vecfield offset inlet for structure-aligned pull (tensormap ->
  axisflow). First check whether `f_vf_warp` through `vs_feedback` already gives it.
- [ ] **T032** Optional `scale` dial (the `L` constant, currently baked at 1.75).

## Phase 3 - docs and menu

- [ ] **T040** Reference doc `docs/f-reference/f_cmap.md`, inventory rows.
- [ ] **T041** Helpfile (`f-helpfile` skill), menu entry (Patterns), README row final,
  `plan.md` and `ideas/INDEX.md` updated, module-preflight, move to `.specify/stable/`.
