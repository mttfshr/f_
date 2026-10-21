# Tasks: f_ks

**Spec**: `.specify/f_ks/spec.md`
**Plan**: none yet (written after Phase 0)
**Build order**: Sequential. Phase 0 is the gate; nothing in Phase 1 starts until its decision gates are closed.
**Commits**: After each phase checkpoint.

Created 2026-10-20 from the spec's "Open Experiments". Each task says whether the omp offline run (`f_omp_runs/ks-lbm-1/`) can do it or whether it needs the Max bench or a human look. omp is offline only: it cannot run the bench, and it writes no GenExpr (codeboxes are written in Phase 1 against the bench).

---

## Phase 0: Offline verification and decision gates (BLOCKING)

**Tier decision (constitution, Verification Tiers):** tier 1 applies (closed forms exist: single-mode rate, mean after the nonlinear update, the u = 0 fixed point); tier 2 applies (multi-frame feedback against the mirror, like `f_vf_fluid`); tier 3 for output mapping and rate feel.

- [x] T001 Stage-decomposed float32 NumPy mirror of the one-frame update (forward DFT, spectral step with k = 0 zeroed, inverse DFT, real-space nonlinearity, bounded encode, reset seeding, rate-to-dt clamp), with tests grounded in the spec and independent references. Landing place: `tests/modules/ks/`. *omp wave 1 (`ks-lbm-1`, unit `f_ks`); architect reviews and lands.* Landed 2026-10-20: `tests/modules/ks/` (16 tests, mutants 27/30; the 3 survivors are fast-path artifacts, unreviewed).
- [~] T002 Float32 versus float64: does the GPU-style float32 path (texel-level DFT passes) track np.fft closely enough over a few hundred frames? Tied to T001's tolerance check; the long-run answer is T004. *omp wave 1 (part), wave 2 (long run).*
- [x] T003 Resolve the spec-versus-experiment statements the mirror run flags (for example the sign of the mean drift without the k = 0 fix). Record each as a one-line decision here. 2026-10-20: the only flag (drift 'upward') was a planted control; the real spec says downward, matching maths and spike. Open for Matt: rate dial 0..1 with dt0 = 0.1, uniform [-1, 1] seeding, no Nyquist special case; at L = 50, N = 32 soaks blow up within 300 frames, so the dt ceiling depends strongly on DX (T004 must cover both domains). *Architect, from the wave-1 report.*
- [ ] T004 Stability measurements at N = 256 and N = 128: the dt ceiling of the simple scheme, the `rate` clamp value, a 10,000-frame soak at the rate extremes with resets interspersed (NF-003). *omp wave 2 (unit `ks-limits`), needs a sweep tool built after wave 1.*
- [ ] T005 Output encoding: compare hard clamp, soft compression and auto-range on the same warmed-up states, as numbers (fraction clipped, range per frame) plus image strips for Matt's tier-3 look. *omp wave 2 (part of `ks-limits`); the choice is Matt's (Phase 2).*
- [ ] T006 Resolution cost in a real Vsynth patch at 256² versus the 128² fallback (open experiment 2). *Needs the Max bench; not omp.*
- [ ] T007 Spectral step and the real codeboxes on the GPU against the mirror, including DC zeroing, and a frame-exact 100+ frame feedback run (`run_temporal`, like `f_vf_fluid`). *Phase 1, Max bench; codeboxes written by hand against the mirror's stages.*

### Decision gates (Matt)

- [ ] T010 Naming: `f_ks` is a placeholder (see the spec header). Decide before the Phase 3 menu and README entry.
- [ ] T011 Bypass behavior for a pure generator with no pass-through input (open experiment 5): decide in Phase 1, not inherited from `f_vf_fluid`.
- [ ] T012 Output mapping (T005's comparison) and `rate` range and default: tier 3, Phase 2.
- [ ] T013 Whether the reset trigger is a message, a UI bang, or both (spec FR-007 allows either).

---

## Phase 1: Solver stages and bpatcher (after Phase 0 gates)

- [ ] T020 Codeboxes for the stages T001 defined, verified on the bench against the mirror.
- [ ] T021 `definition.py`, multi-stage `pix_chain` (hand-edit territory like `f_vf_advect` until the schema covers it), module contract bench green.

## Phase 2: Tuning (tier 3, Matt)

- [ ] T030 Output mapping, `rate` range and default, reset behavior, whether the pattern reads as organic and distinct from every existing generator.

## Phase 3: Docs and registration

- [ ] T040 Reference doc, helpfile, `f_modules` menu placement, README row, final name.

---

## Record

- 2026-10-20: tasks file created; omp run `ks-lbm-1` prepared (wave 1: mirrors; wave 2: measurements). The run tooling is `f_omp_runs/ks-lbm-1/`.
