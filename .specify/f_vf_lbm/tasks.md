# Tasks: f_vf_lbm

**Spec**: `.specify/f_vf_lbm/spec.md`
**Plan**: none yet (written after Phase 0)
**Build order**: Sequential. Phase 0 is the gate; nothing in Phase 1 starts until its decision gates are closed.
**Commits**: After each phase checkpoint.

Created 2026-10-20 from the spec's "Open Experiments". Each task says whether the omp offline run (`f_omp_runs/ks-lbm-1/`) can do it or whether it needs the Max bench or a human look. omp is offline only: it cannot run the bench, and it writes no GenExpr (codeboxes are written in Phase 1 against the bench).

---

## Phase 0: Offline verification and decision gates (BLOCKING)

**Tier decision (constitution, Verification Tiers):** tier 1 applies (collision conserves mass and momentum, bounce-back is a permutation, single-cell propagation per lattice velocity); tier 2 applies (multi-frame feedback against the mirror); tier 3 decides whether the wake reads as shedding.

- [x] T001 Stage-decomposed float32 NumPy mirror of the one-frame update (fused local stage with bounce-back from pre-collision values, streaming gather, channel inflow and outflow as texel-coordinate branches, vecfield encode), with the two spike traps as permanent regression tests (stream direction: `new[x] = old[x - e_i]`; bounce-back reads pre-collision values) and mutants that must be caught. Landing place: `tests/modules/vf_lbm/`. *omp wave 1 (`ks-lbm-1`, unit `f_vf_lbm`); architect reviews and lands.* Landed 2026-10-20: 15 tests, mutants 30/30.
- [x] T002 Channel boundary conditions (Zou/He inflow, zero-gradient outflow) as branches on the texel coordinate; the empty-mask uniform-flow baseline with near-zero curl (spec US1 scenario 1). *Part of T001's unit.*
- [x] T003 Float32 versus float64: mass and field drift of the float32 path over a short run (the experiment is float64 throughout). *Part of T001's unit; the long run is T005.* Finding: float32 vs float64 diverge by 0.02 in 30 frames at omega 1.99; slow total-mass drift (~0.05/cell near the mask) with bounce-back plus Zou/He; inflow-dial direction has no check yet.
- [ ] T004 Resolve the spec-versus-experiment statements the run flags (the streaming roll-direction wording in the Clarifications and FR-004; what 'pre-collision' means relative to the outflow copy; whether y is periodic). Record each as a one-line decision here. *Architect, from the wave-1 report.*
  Decisions, POSTULATED 2026-10-20 at Matt's instruction ("postulate answers and proceed"); revisit if tier 3 disagrees:
  - Streaming: `new[x] = old[x - e_i]` is the definition; the spec's roll-direction wording is not authoritative where it differs (an omp wave-1 control sentence was planted here and was missed, so re-read FR-004 and the Clarifications against the experiment when writing the codebox).
  - y is periodic, as in the experiment; only x has inflow and outflow. Obstacle cells on y edges are ordinary bounce-back cells.
  - 'Pre-collision' is the state at frame start, copied before the outflow copy, as in the experiment.
  - Zou/He inflow forces the whole inflow column, every row (periodic y leaves no corner cases); outflow copies the neighbour column.
  - Encode follows `f_vf_fluid` R/G/B/A; the default gain is a placeholder for tier 3.
  - Slow total-mass drift with bounce-back plus Zou/He is acceptable for v1 if it stays bounded over the T005 soak.
  - The inflow dial gets a direction check when the codebox lands (not covered by the mirror).
- [ ] T005 Safe `omega` ceiling for the channel-BC case (open experiment 3), measured on the mirror with mass conservation and a long soak (10,000+ frames) with an obstacle. *omp wave 2 (unit `lbm-omega`), needs a sweep tool built after wave 1.*
- [ ] T006 Shedding quality at performable resolutions and warm-up lengths (open experiment 4): a sweep over resolution, omega, inflow and obstacle shape, measuring wake curl and a probe signal, with image strips. The honest answer may be that nothing sheds well at performable settings; that outcome returns to Matt (spec success criterion 7). *omp wave 2 (unit `lbm-shedding`).*
- [ ] T007 Obstacle edge cases: full-coverage obstacle stays bounded; a mid-run mask change gives no NaN at the transition; the mask resampling filter (nearest, bilinear, box) (open experiment 5). *omp wave 2 (unit `lbm-edges`).*
- [ ] T008 Solver codeboxes on the GPU against the mirror, frame-exact over 100+ frames (`run_temporal`). *Phase 1, Max bench; codeboxes written by hand against the mirror's stages.*

### Decision gates (Matt)

- [ ] T010 Naming: `f_vf_lbm` (technique) versus `f_vf_karman` or `f_vf_obstacle` (visual result).
- [ ] T011 Bypass behavior for a module whose only texture inlet is the obstacle mask (open experiment 6).
- [ ] T012 Whether to build at all, if T006 finds no performable settings where the wake reads as shedding.
- [ ] T013 `omega` or viscosity as the user-facing control, and the inflow range (tier 3, Phase 2).

---

## Phase 1: Solver stages and bpatcher (after Phase 0 gates)

- [ ] T020 Codeboxes for the stages T001 defined (3-plane state ping-pong), verified on the bench against the mirror.
- [ ] T021 `definition.py`, multi-stage `pix_chain` (hand-edit territory like `f_vf_advect` and `f_vf_fluid`), module contract bench green.

## Phase 2: Tuning (tier 3, Matt)

- [ ] T030 Obstacle shapes, inflow and `omega` range, and the shedding judgment call.

## Phase 3: Docs and registration

- [ ] T040 Reference doc, helpfile, `f_modules` menu placement (vecfield producers), README row, final name.

---

## Record

- 2026-10-20: tasks file created; omp run `ks-lbm-1` prepared (wave 1: mirrors; wave 2: measurements). The run tooling is `f_omp_runs/ks-lbm-1/`.
