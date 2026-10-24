# Tasks: f_quasi

**Spec**: `.specify/f_quasi/spec.md`
**Plan**: none yet (written after Phase 0)
**Build order**: Sequential. Phase 0 is the gate; nothing in Phase 1 starts until its decision gates are closed.
**Commits**: After each phase checkpoint.

Created 2026-10-23 from the spec's "Open Experiments" and phasing. Each task says whether it is offline NumPy (no Max), the Max bench, or a human look (tier 3, Matt). The offline tasks (T001-T005) suit an omp run if wanted; they need no GPU.

---

## Expected Source Layout

```
src/f_quasi/
├── definition.py              # archetype: source, three outlets (tex, vecfield, scalar)
├── codebox_quasi.gen          # the one stateless pass: potential, gradient, banded look
tests/modules/quasi/
├── quasi_mirror.py            # tier-1 mirror (float32, stage-decomposed)
├── test_quasi.py              # tier-1 tests
├── bench_quasi_module.py      # tier-2 shipped-patcher bench
```

The patcher also holds a small clock (zoom and drift accumulators); see T021.

## Phase 0: NumPy mirror, measurements and decision gates (BLOCKING)

**Tier decision (constitution, Verification Tiers):** tier 1 applies (closed forms exist: boundedness of the potential, octave-shift invariance of the envelope, analytic gradient against finite difference, vecfield bound); tier 2 applies (the real codebox on the GPU against the mirror, plus cost); tier 3 for look. No feedback, so no frame-exact temporal bench.

- [ ] T001 Float32 NumPy mirror of the settled model (weights, potential, exact gradient, bounded vecfield encoding, banded look, isotropic coordinates, parameter wrapping), with tests grounded in the spec and independent reference formulas (a float64 evaluation, a finite difference). *Offline.*
- [ ] T002 Float32 versus float64: `psi` reaches about 1.6e3 rad at the finest octave; measure the `cos` error and decide whether argument reduction is needed (NF-002). *Offline.*
- [ ] T003 Gradient check: the analytic gradient against a central finite difference of `P`, and the vecfield bound (magnitude at most 1) across a parameter sweep (SC-002, SC-003). *Offline.*
- [ ] T004 Zoom-wrap residual versus `envelope`: tabulate the max difference of `P` between `zoom` just below 1 and 0 for `sigma` 0.25 to 1.5, then set the `envelope` cap and the tolerance (SC-001, FR-010). *Offline.*
- [ ] T005 Nyquist fade: per-octave cutoff by cycles per pixel at 1920×1080 and at smaller sizes, against a supersampled reference; decide per-octave versus global fade (FR-009). *Offline.*
- [ ] T006 Cost at 1920×1080: the codebox with all 7 octaves versus skipping octaves below a weight threshold (and whether skipping stays branchless-safe). *Needs the Max bench; not omp.*
- [ ] T007 Render the proposed vecfield normalisation into `f_caustic` and `f_vf_warp` on real output, compared with a fixed-scale alternative (gate G2). *Tier 3, Matt; needs T001.*

### Decision gates (Matt)

- [ ] G1 Naming: `f_quasi` is a placeholder; decide before the Phase 3 menu and README entry.
- [ ] G2 Vecfield normalisation: bounded form (`sum w s sin dir / sum w s`) versus fixed scale; decided after T007.
- [ ] G3 Clock: frame-count based or time based, and the unit for `zoom_rate`; decided in T021.

---

## Phase 1: Codebox and bpatcher (after Phase 0 gates)

- [ ] T020 `codebox_quasi.gen` written against the mirror; verified on the bench against it, including the three outlets, bypass neutrals and the wrap residual on the GPU. *Phase 1, Max bench; codebox written by hand against the mirror.*
- [ ] T021 The clock in the patcher: `zoom` and `drift` accumulators advancing at their rate dials, wrapping, exactly frozen at rate 0, and exposed as plain params (so mod sources and LFOs can also drive `zoom`). Resolve G3 here.
- [ ] T022 `definition.py` (single stage plus the clock), `package/patchers/f_quasi.maxpat` built; drift 0, offline contracts, live module contracts, `tests/modules/quasi/bench_quasi_module.py`.

## Phase 2: Tuning and looks (tier 3, Matt)

- [ ] T030 Parameter ranges and defaults, `envelope` cap, whether the five-fold structure reads as distinct from `f_chladni` and `f_ks`, whether the zoom reads as endless.
- [ ] T031 Relief and Slope-hue looks (`ideas/f_quasi.md` modes 1 and 2): specular term masked to ridges as in the source, `atan2` of the gradient with the +1e-7 bias idiom; Phase 2 only if T030 passes. Decide whether the contour-banding helper is shared with `f_vf_potential` and `f_chladni`.

## Phase 3: Docs and registration

- [ ] T040 Reference doc, helpfile, `f_modules` menu placement (Patterns), README row (110 characters), final name.

---

## Record

- 2026-10-23: spec and tasks created from `ideas/f_quasi.md`; four design questions settled with Matt (looks in Phase 2, cyclic zoom dial plus patcher clock, fixed 5×7, spectral solver later for `f_wave_field`). The source facts that changed the idea file are in the spec's Clarifications (finite envelope makes the wrap approximate, the source gradient omits the 2π·B·s factor, the source aspect handling is not isometric).
