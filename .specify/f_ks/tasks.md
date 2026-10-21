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
- [x] T003 Resolve the spec-versus-experiment statements the mirror run flags (for example the sign of the mean drift without the k = 0 fix). Record each as a one-line decision here. 2026-10-20: the only flag (drift 'upward') was a planted control; the real spec says downward, matching maths and spike. Postulated 2026-10-20 at Matt's instruction (revisit at tier 3): rate dial 0..1 mapped to dt = rate * dt0 (dt0 was 0.1; CHANGED 2026-10-21 by Matt's yes to dt0 = 0.05, because the measured ceiling at L = 50 is about 0.05 to 0.0625, so the whole dial now sits at or below it; T004 still sets the clamp margin), uniform [-1, 1] noise seeding, no Nyquist special case; at L = 50, N = 32 soaks blow up within 300 frames, so the dt ceiling depends strongly on DX (T004 must cover both domains). *Architect, from the wave-1 report.*
- [~] T004 Stability measurements at N = 256 and N = 128: the dt ceiling of the simple scheme, the `rate` clamp value, a 10,000-frame soak at the rate extremes with resets interspersed (NF-003). *omp wave 2 (unit `ks-limits`), needs a sweep tool built after wave 1.* Result from `ks-lbm-3` (2026-10-21; the worker was marked incomplete, so these figures are my own recomputation from the frozen 55-cell table, 2 seeds per rung, 2000 frames, L = 50, dt ladder): largest dt that survived all seeds / smallest that failed any: N = 64 0.05 / 0.075 (same at L = 12.5, so DX did not matter), N = 128 0.0625 / 0.075, N = 256 0.0625 / 0.09375. Soaks of 10000 frames at the clamp (0.05 at N = 128 with and without resets every 1000 frames, rates 0.1 and 0.49; 0.03125 at N = 256) stayed finite, bounded (max |u| 15 to 20) and not frozen. The factory dt 0.1 is above the ceiling (blew up by about frame 259 at N = 128). Follow-up `ks-lbm-4` / `ks-limits-2` tightens the bracket with 5 seeds and checks 10000-frame survival at the bracket.
- [ ] T005 Output encoding: compare hard clamp, soft compression and auto-range on the same warmed-up states, as numbers (fraction clipped, range per frame) plus image strips for Matt's tier-3 look. *omp wave 2 (part of `ks-limits`); the choice is Matt's (Phase 2).*
- [ ] T006 Resolution cost in a real Vsynth patch at 256² versus the 128² fallback (open experiment 2). *Needs the Max bench; not omp.*
- [x] T007 Spectral step and the real codeboxes on the GPU against the mirror, including DC zeroing, and a frame-exact 100+ frame feedback run (`run_temporal`, like `f_vf_fluid`). *Phase 1, Max bench; codeboxes written by hand against the mirror's stages.* Done 2026-10-21 (`tests/modules/ks/bench_ks.py`, 9/9 with `--slow`): spec vs mirror 7.8e-8 relative with the DC bin exactly 0; nl vs mirror 2.4e-7 plus the periodic seam; enc 1.6e-6 at off-size render targets; a 30-frame host-sequenced chain from a real GPU seed differs from the mirror by 4.6e-7, 100 frames by 2.3e-6 (the mean of u matches to every digit shown). KS is chaotic: pixel comparison is a short-horizon check, longer runs compare statistics.

### Decision gates (Matt)

- [ ] T010 Naming: `f_ks` is a placeholder (see the spec header). Decide before the Phase 3 menu and README entry.
- [x] T011 Bypass behavior for a pure generator with no pass-through input (open experiment 5): decide in Phase 1, not inherited from `f_vf_fluid`. Decided 2026-10-21 (Matt: "do what other modules do"): follow `f_chladni`, the existing generator with no texture input, whose bypass outputs black with alpha 1. Implemented as a `bypass_gate` Param on `enc` only (the f_vf_fluid ADR-8 mechanism), so the solver keeps running and the state stays warm.
- [ ] T012 Output mapping (T005's comparison) and `rate` default: tier 3, Phase 2. NEW FINDING (live patcher, 2026-10-21): after a reset the field is near-flat for about a second (luma std 0.011 at frame 30, 0.095 at 240, 0.435 at 600) because white-noise energy sits in wavenumbers the linear step kills and the unstable band holds ~0.2%; and the 0.5+0.25u map saturates at std 0.435. Seed shape/warm-up and the map are Matt's call.
- [x] T013 Reset trigger: both (decided 2026-10-21): a button on the panel and a `reset` message on the control inlet; also fires once on load. Holds `reseed` for three draw bangs (never a timer), and bumps the seed `salt` so every reset is a new pattern.

---

## Phase 1: Solver stages and bpatcher (after Phase 0 gates)

- [x] T020 Codeboxes for the stages T001 defined, verified on the bench against the mirror. Done 2026-10-21 in `src/f_ks/`: `codebox_pass` (feedback hold / reseed from a noise texture), four DFT codeboxes generated by `gen_dft.py` from f_vf_fluid's template (code lines asserted identical), `codebox_spec`, `codebox_nl` (with a NaN/Inf zap and a +-100 clamp, modeled in the mirror and tested), `codebox_enc` (periodic 4-tap upsample, placeholder 0.5+0.25u map, `bypass_gate` outputs black alpha 1). Stage chain: pass, fx, fy, spec, iy, ix, nl (feedback to pass), enc. Cost on the bench: 2.39 ms/frame for the whole chain at 256 (DFT passes 0.49-0.53 ms each; the small stages are upper bounds of 0.06-0.10 ms).
- [x] T021 `definition.py` (10-stage chain; hold/seed/pass/fx/fy/spec/iy/ix/nl/enc), `package/patchers/f_ks.maxpat` built; drift 0, offline contracts 9/9, live module contracts green (BYPASS_EXPECT f_ks = black A=1), `tests/modules/ks/bench_ks_module.py` 2/2 (real patcher: seeds on load, grows to contrast, evolves). Changes forced by the patcher: `pass` gained the draw-bang first inlet (feedback and noise now in2/in3) and a new `codebox_seed.gen` hash stage replaced the planned jit.noise texture (no raw texture wiring); `rate` dial IS dt (0-0.0625, the stability ceiling) via pix_attr, so the planned patcher-side min() expr is not needed; Params `L`/`amp` are listed in KNOWN_ISSUES (fixed constants kept as Params for the bench).

## Phase 2: Tuning (tier 3, Matt)

- [ ] T030 Output mapping, `rate` range and default, reset behavior, whether the pattern reads as organic and distinct from every existing generator.

## Phase 3: Docs and registration

- [ ] T040 Reference doc, helpfile, `f_modules` menu placement, README row, final name.

---

## Record

- 2026-10-20: tasks file created; omp run `ks-lbm-1` prepared (wave 1: mirrors; wave 2: measurements). The run tooling is `f_omp_runs/ks-lbm-1/`.

- [x] T022 (2026-10-21, Matt's request) `scale` dial (L 25-100) and `sharp` dial (enc crisp blend); dt-ceiling-vs-L spike; output follows render size via `r dim` + @adapt 0 (needs a live check in Vsynth).
