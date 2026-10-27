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

- [x] T001 (2026-10-26, `tests/modules/quasi/`, 11/11, 0.5 s) Float32 NumPy mirror of the settled model (weights, potential, exact gradient, bounded vecfield encoding, banded look, isotropic coordinates, parameter wrapping), with tests grounded in the spec and independent reference formulas (a float64 evaluation, a finite difference). *Offline.*
- [x] T002 (2026-10-26, `tests/records/spike_quasi_float32.py`) Float32 versus float64: `psi` reaches about 1.6e3 rad at the finest octave; measure the `cos` error and decide whether argument reduction is needed (NF-002). *Offline.*
- [x] T003 (2026-10-26, `tests/records/spike_quasi_gradient.py`) Gradient check: the analytic gradient against a central finite difference of `P`, and the vecfield bound (magnitude at most 1) across a parameter sweep (SC-002, SC-003). *Offline.*
- [x] T004 (2026-10-26, `tests/records/spike_quasi_wrap.py`) Zoom-wrap residual versus `envelope`: tabulate the max difference of `P` between `zoom` just below 1 and 0 for `sigma` 0.25 to 1.5, then set the `envelope` cap and the tolerance (SC-001, FR-010). *Offline.*
- [x] T005 (2026-10-26, `tests/records/spike_quasi_nyquist.py`) Nyquist fade: per-octave cutoff by cycles per pixel at 1920×1080 and at smaller sizes, against a supersampled reference; decide per-octave versus global fade (FR-009). *Offline.*
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

- 2026-10-26: **Phase 0 offline half done (T001-T005).** Mirror `tests/modules/quasi/quasi_mirror.py` + `test_quasi.py` 11/11 (independent scalar float64 reference, finite difference, rotation covariance, wrap weights, four mutations caught); measurements in `tests/records/spike_quasi_{float32,gradient,wrap,nyquist}.py`. Findings, all carried into Phase 1:
  - **T001 conventions:** the unit is the frame HEIGHT (`x = (norm_x - 0.5) * aspect`, `y = norm_y - 0.5`), so `density` is cycles per frame height at scale 1 (the spec table said width; amended). The five `beta_k = frac(exp(pi k))` must be float64 LITERALS in the codebox: float32 `exp(4 pi)` is 286751.4 with an ulp of 0.031 (frac 0.406 against the true 0.313).
  - **T002:** float32 error in `P` is at most 2.6e-5 over zoom 0 / 0.5 / 0.999, density 1-12, envelope 0.5 / 1.0 (0.003 of an 8-bit output level; the NF-002 tier-1 tolerance is set at 1e-3). Set by rounding `psi` itself; a cycles-form (`2 pi frac(c)`) is no better. **No argument reduction.** The 1.6e3 rad figure holds at density 4; at density 12 the finest octave reaches 9.8e3 rad but carries weight exp(-32). GPU `cos` accuracy at large arguments is NOT covered (NumPy float32 `cos` is not the GPU's): T006 / T020 bench. **Drift finding:** the offset is `(beta + p) * s_i`, so an unbounded `p` costs precision (3.6e-4 at p = 1e3, 4.3e-3 = half a level at p = 1e4). **T021 must wrap the accumulator:** define drift as a base-octave phase in turns `phi`, offset `2 pi phi 2^i` (integer multiples of the base, so exactly periodic), wrap at 1. Side effect: drift speed no longer scales with `2^zoom`.
  - **T003:** analytic gradient against a float64 central difference 1.8e-6 relative to the peak; float32 against float64 3.6e-4. `|v|` stays at or below 1 (sweep max 0.62; encoded R, G span 0.19 to 0.80 at gain 1). `|grad P|` spans 24 to 337 across the sweep, which confirms a fixed scale cannot serve both ends (G2 supports the bounded form on the maths). At the defaults the typical `|v|` is 0.22 (median), p99 0.47, so the bound is loose in practice and a default `gain` above 1 may suit the look: a T007 question.
  - **T004:** wrap residual at envelope 0.5 is 1.7e-8, matching `(w_enter + w_leave) / sum w` to within 35% at every envelope tested (35% at 0.6, tightening to 0-14% from 1.0 up; it ignores the change in the normaliser). **Tolerance set: half an output LSB of the banded texture at bands 12, i.e. 1.5e-4 in P (residual * 1.1 * bands * 255 <= 0.5).** **Cap set: `envelope` max 0.7** (residual 7.6e-5; 0.75 gives 2.3e-4, 1.0 gives 5.2e-3, about 17 levels of texture at bands 12). Revisit only if the look wants wider.
  - **T005:** at 1080p the Nyquist fade is irrelevant inside the parameter ranges: the top octave carrying weight (>= 1e-3 of the peak) reaches only 0.50 cycles per pixel at density 12 and envelope 0.7, so SC-004 holds with no fade. Aliasing appears at small render sizes (the H = 270 crop). Against a 4x4-supersampled reference: renormalised fades (hard or smooth) are rejected (they inflate contrast, mean kept 1.12-1.16, and err about twice as much as no fade on average, mean RMS 31 against 14.5 and worst 197 against 54, x1e-3, worst where the weighted octaves sit past Nyquist); a single global factor is rejected (dims the whole pattern, min contrast kept 0.0, and cannot remove an aliasing octave; with renormalisation it would cancel). The candidate is a per-octave smooth fade WITHOUT renormalisation (start 0.25, end 0.5): identical to no fade at 1080p, close to it elsewhere (mean RMS 17 against 14.5, x1e-3), ahead of it in several 270 px cases (270 / density 8 / zoom 0.5 / envelope 0.5: 17.7 against 26.2) and behind in others. Limits: a static RMS against a pre-filtered reference understates shimmer, which is a temporal artifact, and the 4x4 reference is adequate only while octave cpp < 2. **Decision deferred to T030 (look at a small render size) with the cost from T006:** ship the fade as insurance (7 smoothsteps, not exposed, `fade_factors` in the mirror) or leave it out.
  - **For T020/T021:** beta literals; drift as a wrapped phase in turns; zoom accumulator wrapped on [0, 1); `envelope` dial max 0.7; the codebox carries `wrap` of `zoom` itself (FR-004).
