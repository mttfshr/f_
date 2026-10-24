# Tasks: f_wave_field

**Spec**: `.specify/f_wave_field/spec.md`
**Plan**: none yet (written after Phase 0)
**Build order**: Sequential. Phase 0 is the gate; nothing in Phase 1 starts until its decision gates are closed.
**Commits**: After each phase checkpoint.

Created 2026-10-23 from the spec's "Open Experiments" and phasing. Each task says whether it is offline NumPy (no Max), the Max bench, or a human look (tier 3, Matt). The offline tasks (T001-T005, T007) suit an omp run if wanted; they need no GPU.

---

## Expected Source Layout

```
src/f_wave_field/
├── definition.py               # archetype: source (optional force inlet), outlets luma + vecfield
├── gen_dft.py                  # the shared DFT template (see G5); not copied
├── codebox_pass.gen            # feedback hold / reset
├── codebox_dft_{fx,fy,iy,ix}.gen   # generated, shared with f_ks and f_wc
├── codebox_spec.gen            # exact per-bin 2x2 step, three damping regimes, DC zeroed
├── codebox_nl.gen              # forcing, exciter phase, strike, sponge, gradient, containment
├── codebox_enc.gen             # bilinear to render size, luma and vecfield outlets, bypass_gate
tests/modules/wave_field/
├── wave_field_mirror.py        # tier-1 mirror (float32, stage-decomposed)
├── test_wave_field.py          # tier-1 tests
├── bench_wave_field.py         # tier-2 stage / frame-exact feedback bench
├── bench_wave_field_module.py  # tier-2 shipped-patcher bench
```

## Phase 0: NumPy mirror, measurements and decision gates (BLOCKING)

**Tier decision (constitution, Verification Tiers):** tier 1 applies (closed forms exist: the damped-oscillator solution per mode in all three regimes, energy conservation, dispersion, superposition, wrap and sponge); tier 2 applies (frame-exact multi-frame feedback against the mirror, like `f_ks`'s `bench_ks.py`, plus cost); tier 3 for the look.

- [ ] T001 Float32 stage-decomposed NumPy mirror of the one-frame update (forward DFT, spectral step with DC zeroed, inverse DFT, forcing, exciter, strike, sponge, gradient, containment, bounded encode), with tests grounded in the spec and independent references (single-mode closed form in the underdamped, critical and overdamped regimes). *Offline.*
- [ ] T002 Closed-form checks as tests: energy conservation at zero damping, dispersion (`dispersion` 1 ring radius grows at the phase velocity; 2 gives frequency ∝ k²), superposition, periodic wrap of a pulse at `edge` 0, sponge removes energy and never adds. *Offline.*
- [ ] T003 Float32 versus float64: energy drift over 1,000 and 10,000 frames at zero damping; set the `damping` floor (FR-006) and the tolerance for SC-002. *Offline.*
- [ ] T004 Normalisation constants: `kref` (so `speed` is the mid-scale phase velocity regardless of `dispersion`), the viscosity `nu`, the sponge width and profile (smooth enough not to reflect). *Offline.*
- [ ] T005 Output mapping comparison on the same warmed-up states: hard clamp, `tanh`-style compression, auto-range for luma, and the vecfield normalisation, as numbers (fraction clipped, range per frame) plus image strips for Matt's tier-3 look. *Offline; the choice is Matt's (G2).*
- [ ] T006 Cost in a real Vsynth patch at 256² versus 128², with this as the third DFT user. *Needs the Max bench; not omp.*
- [ ] T007 Operator-splitting accuracy: the real-space forcing and sponge against the exact driven damped response (closed form per mode), to set the useful per-frame step and the `speed` ceiling. *Offline.*

### Decision gates (Matt)

- [ ] G1 Naming: `f_wave_field` is a placeholder; decide before the Phase 3 menu and README entry.
- [ ] G2 Output mapping and vecfield normalisation (T005): tier 3, Phase 2.
- [ ] G3 Time units: per-frame model step or seconds from a measured frame time; `speed` and `frequency` units follow (`ideas/variable_framerate.md`).
- [ ] G4 Dial count and grouping: the proposed set is about 11 dials; trim or group in Phase 2; decide whether a `medium` preset menu (Membrane, Water, Plate, Resonator) replaces some dials.
- [ ] G5 DFT chain factoring: `f_wc` T020 factors `f_ks`'s `gen_dft.py` to a shared location; this module consumes it. Coordinate: whichever builds first does the factoring.

---

## Phase 1: Codeboxes and bpatcher (after Phase 0 gates)

- [ ] T020 Codeboxes for the stages T001 defined, verified on the bench against the mirror, including the three damping regimes on the GPU, DC zeroing and a frame-exact 100+ frame feedback run (`run_temporal`). *Phase 1, Max bench; codeboxes written by hand against the mirror.*
- [ ] T021 `definition.py` (chain: hold, pass, fx, fy, spec, iy, ix, nl, enc, two outlets), `package/patchers/f_wave_field.maxpat` built; drift 0, offline contracts, live module contracts (bypass neutrals: luma black A = 1, vecfield 0.5 / 0.5), `bench_wave_field_module.py`.
- [ ] T022 Reset logic and load behaviour: `reset` zeroes the field, `strike` drops the impulse, both fire once on load; the default exciter makes rings visible with nothing connected (User Story 1).

## Phase 2: Tuning (tier 3, Matt)

- [ ] T030 Ranges and defaults for `speed`, `damping`, `dispersion`, `ring`, `edge`, the exciter; output mapping (G2); whether the rings feel right and read as distinct from `f_chladni`, `f_ks`, `f_vf_fluid`; whether the vecfield drives `f_caustic` well.
- [ ] T031 Dial grouping and possible `medium` presets (G4).

## Phase 3: Docs and registration

- [ ] T040 Reference doc, helpfile, `f_modules` menu placement (Patterns, beside `f_ks`), README row (110 characters), final name.
- [ ] T041 `f_cymascope` follow-on: spec the audio front end (pitch tracker and envelope to `frequency` and `amplitude`) on top of this module; update `ideas/f_cymascope.md`.

---

## Record

- 2026-10-23: spec and tasks created from `ideas/f_wave_field.md`; spectral direction and four design questions settled with Matt (general dispersion family, periodic edges plus an absorbing-edge dial, force inlet plus point exciter plus strike, luma plus gradient vecfield). The general-dispersion idea (`omega^2 = ring^2 + speed^2 k^(2 dispersion)`) is Claude's addition to the omp drafts.
