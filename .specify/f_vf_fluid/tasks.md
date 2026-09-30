# Tasks: f_vf_fluid

**Spec**: `.specify/f_vf_fluid/spec.md`
**Plan**: `.specify/f_vf_fluid/plan.md`
**Build order**: Sequential by phase; Phase 0 and Phase 1 are hard gates (nothing
is built into a patcher until the math and stage codeboxes pass). Within a
phase, `[P]` tasks touch different files and can run in parallel.
**Commits**: After each phase checkpoint.
**Convention**: `- [ ] T### [P] [US#] description with exact path`. `[US#]`
maps to the spec's user stories (US1 producer, US2 viscosity, US3
incompressibility, US4 stirring from motion, US5 standard `f_` behavior);
omitted for infrastructure, verification and docs.

---

## Expected Output Layout

```
src/f_vf_fluid/
  definition.py            # metadata only (params, docs/helpfile tooling)   — Phase 2
  build_fluid.py           # dedicated build script → package/patchers/      — Phase 2
  gen_dft.py               # writes the 4 DFT codeboxes from one template    — Phase 1
  codebox_adv.gen          # stage 1                                         — Phase 1
  codebox_dft_fx.gen       # stage 2   (generated)                           — Phase 1
  codebox_dft_fy.gen       # stage 3   (generated)                           — Phase 1
  codebox_spec.gen         # stage 4                                         — Phase 1
  codebox_dft_iy.gen       # stage 5   (generated)                           — Phase 1
  codebox_dft_ix.gen       # stage 6   (generated, + real part + NaN guard)  — Phase 1
  codebox_enc.gen          # stage 7                                         — Phase 1
tests/
  fluid_mirror.py          # NumPy mirror of every stage + step()            — Phase 0
  test_fluid_mirror.py     # tier 1                                          — Phase 0
  bench_fluid.py           # tier 2                                          — Phase 1
  bench/codeboxes/         # throwaway probes: seam_fract.gen, seam_tap4.gen,
                           #   nan_probe.gen, dft_param_n.gen                — Phase 0
package/patchers/f_vf_fluid.maxpat     # built                               — Phase 2
docs/f-reference/f_vf_fluid.md         # reference doc                       — Phase 4
package/help/f_vf_fluid.maxhelp        # helpfile pipeline                   — Phase 4
~/Vsynth/patterns/fluid_dim_test.maxpat, fluid_tuning.maxpat   # scratch, not committed
```

---

## Phase 0: Verification and Feasibility (BLOCKING)

**Purpose**: Fix the definition of every stage in NumPy (plan Block A) and
answer the in-Vsynth feasibility questions (Block C) before any stage
codebox or patcher exists. Block C could reshape ADR-2, so its experiments
run first.

⚠️ CRITICAL: no `codebox_*.gen` is written until T009 passes.

### Decision gate

- [x] T001 DECISION GATE — verification tiers, recorded here: **Tier 1 applies**
      (nontrivial numerics with analytic ground truth: Taylor–Green, projection,
      viscosity decay). **Tier 2 applies** (numeric criteria exist for every stage;
      cost matters — NF-001). **Tier 3 applies** (ranges, look, integration).
      **Nothing skipped.** Known limit: the bench drives one codebox at a time, so
      multi-frame verification of the whole chain is host-sequenced from Python
      (plan ADR-10); GPU-resident feedback timing is covered by the existing
      Pattern-1 tests and re-checked in the real module (T034, T040).

### Block C — in-Vsynth feasibility (highest risk; start first, in parallel with the math)

- [x] T002 [P] Build the scratch patch `~/Vsynth/patterns/fluid_dim_test.maxpat`:
      a `jit.gl.pix vsynth @adapt 0 @dim 256 256 @type float32` stage fed by a test
      source, and a downstream `jit.gl.pix vsynth @adapt 1 @type float32` stage
      that samples it (bilinear) — the solver/encode split of plan ADR-2. Not committed.
      **Done 2026-09-23 without a hand-built patch:** `tests/fluid_feasibility.py`
      generates the scratch module and runs it through the module bench (inside
      `vs_render`); it always deletes the scratch file afterwards.
- [x] T003 E1 — with T002, record in "Findings" below: does the 256² stage run
      inside Vsynth's render context without errors; what dimensions does each
      stage report; does the render-res stage upsample it smoothly (no visible
      blockiness/edge artifacts)?
- [x] T004 E1b — with T002, disconnect the source so the stage sees `vs_black`
      (via `vs_inState`): record the render-res stage's output size. If it is
      not render size, record the fallback (adapt to a Vsynth render-size source)
      and update plan ADR-2.
- [x] T005 [P] E-seam probes: write throwaway `tests/bench/codeboxes/seam_fract.gen`
      (`sample()` with `fract()` on the coordinate) and `seam_tap4.gen` (four
      wrapped `nearest()` taps, manual bilinear). Bench-compare both against the
      periodic reference (`gpu_sim.sample(..., wrap=True)`) on the two seam
      columns/rows; record which one matches and by how much (plan ADR-3).
- [x] T006 [P] E-nan probe: throwaway `tests/bench/codeboxes/nan_probe.gen` that
      produces a NaN (0/0) and passes it through `switch(x == x, x, 0)`; bench it;
      record whether GenExpr on `jit.gl.pix` detects NaN this way (plan ADR-6).
      If not, record the working alternative.
- [x] T007 [P] E5 (optional) — throwaway `tests/bench/codeboxes/dft_param_n.gen`:
      does a `Param`-bounded DFT loop compile and match `np.fft` at N = 128 and 256?
      Record; if yes, runtime resolution becomes possible later (does not change v1).

### Block A — NumPy mirror (tier 1)

- [x] T008 Write `tests/fluid_mirror.py`: float32 mirrors of every stage, importing
      `gpu_sim` and `pass_dft` from `tests/test_fft_separable.py` —
      `adv(state, force, dt, force_gain, src_vecfield)` (periodic bilinear + force),
      `spec(tex, viscosity, project, drag, dt)` (Nyquist-zeroed operator wavenumbers,
      projection blend, `exp(-(nu*|k|^2 + mu)*dt)` decay; k = 0 bin only gets drag),
      `ix_cleanup(tex)` (real part, Im = 0, non-finite → 0),
      `enc(force, velocity, gain, bypass_gate, src_vecfield)` (bilinear upsample,
      encode, clamp, bypass = force passthrough or neutral), and
      `step(state, force, params)` composing pass → adv → fx → fy → spec → iy → ix.
      Provide an `np.fft`-backed fast path for long runs, asserted equal to the
      `pass_dft`-based step over 3 frames.
- [x] T009 Write `tests/test_fluid_mirror.py` (run with
      `tests/run.sh tests/test_fluid_mirror.py`), each check against *independent*
      truth: single-mode decay = `exp(-nu*dt*|k|^2)` within 1e-4 (SC1); projection of
      a random field leaves spectral divergence at numerical zero; pure-gradient force
      → velocity ≈ 0, pure-curl force unchanged (SC2); `project` = 0.5 equals the
      linear blend; **Taylor–Green** decay `exp(-2*nu*k^2*t)` within 5% over 100 frames
      at N = 64 and 256 (SC3); energy non-increasing with no force (ν ≥ 0, drag ≥ 0);
      zero state + zero force → exactly neutral outlet on every frame (SC6);
      Nyquist bins: real input stays real (max |Im| < 1e-6) after a full step;
      10⁴ frames at parameter extremes (N = 32 — the math is N-independent; N = 64 was ~4× slower), all finite and in [0, 1] (SC5, tier 1).
- [x] T010 Mutation-check the mirror once: separately break (a) the Nyquist rule,
      (b) the projection sign, (c) the decay exponent, (d) the periodic wrap; each
      must make a named test fail. Record the results here.

**Checkpoint**: T003/T004 answered in Findings; T009 green and mutation-checked;
E-seam, E-nan (and optional E5) recorded. *BLOCKS Phase 1.*

**Phase 0 outcome (2026-09-23): met.** `tests/test_fluid_mirror.py` 16/16 with all
five mutations caught; `tests/bench_fluid_probes.py` 4/4; `tests/fluid_feasibility.py`
answers E1/E1b/E1c. Two plan changes came out of it (ADR-2, ADR-3, ADR-6 updated):
(1) `adv` and `enc` are triggered by `r draw` bangs on inlet 0 — an `enc` that adapts
to the force texture is 1×1 when the inlet is unconnected (`vs_black`); (2) all
interpolation is manual 4-tap reads and the NaN guard is `switch(abs(x) < 1e30, x, 0)`
(hardware `sample()` clamps at the seam, has 8-bit weights, and is nearest-like when
minifying; `NaN == NaN` is true on this GPU).

---

## Phase 1: Solver Stages on the Bench (BLOCKING) — US1, US2, US3

**Purpose**: Turn the mirrored stages into real codebox files and prove each on
the GPU (plan Block B). Success criteria 1–6 must hold on the GPU path.

**Independent Test**: `tests/bench.sh tests/bench_fluid.py` passes.

- [x] T011 [P] [US2] Write `src/f_vf_fluid/gen_dft.py` and run it to produce
      `src/f_vf_fluid/codebox_dft_fx.gen`, `codebox_dft_fy.gen`, `codebox_dft_iy.gen`,
      `codebox_dft_ix.gen` from one template (axis and direction baked; `N = 256`
      as a literal appearing exactly twice; header notes "generated by gen_dft.py").
      `codebox_dft_ix.gen` additionally outputs `vec(Re u, 0, Re v, 0)` and replaces
      non-finite values with 0 using `switch(abs(x) < 1e30, x, 0)` (bench-verified in
      T006; the `x == x` form does not work — `NaN == NaN` is true on this GPU).
- [x] T012 [P] [US1] Write `src/f_vf_fluid/codebox_adv.gen`: `Param dt`, `Param force`,
      `Param src_vecfield`; in1 = `r draw` bang (unused), in2 = force, in3 = previous
      velocity; backward self-advection with the manual periodic 4-tap read of
      `tests/bench/codeboxes/seam_tap4.gen` (T005); the force uses hardware
      `sample()` (a codebox cannot read an input texture's size — no `texdim` —
      so manual taps are impossible there; plan ADR-3); `+ force * F` gated by
      `src_vecfield`; outputs `vec(u, 0, v, 0)`.
- [x] T013 [P] [US2] [US3] Write `src/f_vf_fluid/codebox_spec.gen`: `Param viscosity`,
      `Param project`, `Param drag`, `Param dt`; signed wavenumbers via
      `floor(norm * N)` (not `cell`); Nyquist bins zeroed in the operator; projection
      blend; combined decay factor per plan ADR-5. Avoid built-in operator names for Params.
- [x] T014 [P] [US1] Write `src/f_vf_fluid/codebox_enc.gen`: `Param gain`,
      `Param bypass_gate`, `Param src_vecfield`; in1 = `r draw` bang (unused; gives
      the render-context size), in2 = force (render res), in3 = velocity (256²)
      read with the periodic 4-tap; encode `0.5 + 0.5 * clamp(gain * v, -1, 1)`,
      B = 0.5, A = 1; gated output `mix(neutral, force, src_vecfield)` when bypassed.
- [x] T015 Create `tests/bench_fluid.py` from `tests/templates/bench_module_template.py`,
      pointing at the real `src/f_vf_fluid/codebox_*.gen` files; first test: every
      codebox compiles with no Max errors (`test_compiles_and_runs` per stage).
- [x] T016 [US3] Bench `spec` vs the mirror at N = 256 over random spectral fields,
      `project` ∈ {0, 0.5, 1}, several viscosity/drag values; tol 1e-4. Record
      measured errors in Findings.
- [x] T017 [US1] Bench `adv` (3 inputs: bang, force, state) vs the mirror on random
      velocity + force, including the seam rows/columns; `src_vecfield = 0` must add
      exactly zero force. tol 1e-4 (the 4-tap read should match to ~1e-6).
- [x] T018 [US1] Bench `enc` vs the mirror: periodic 4-tap upsample from 256² to a
      non-square render size and to a size *smaller* than 256² (minification), gain,
      clamp to [0, 1], `bypass_gate = 1` returns the force exactly when
      `src_vecfield = 1` and exactly neutral `(0.5, 0.5, 0.5, 1)` when 0.
- [x] T019 [US2] Bench the four baked DFT codeboxes at N = 256: forward `fx`→`fy` vs
      `np.fft.fft2` within 2e-7 relative; full round trip `fx→fy→iy→ix` identity within
      1e-5 absolute; `ix` returns Im = 0 exactly and maps injected NaN/Inf to 0.
- [x] T020 [US1] [US2] [US3] Host-sequenced multi-frame run: 100 frames of the full
      stage chain (Python passes each stage's real GPU output to the next) from a
      Taylor–Green initial state, compared frame by frame to the mirror `step()`
      within 1e-4 (SC4); also assert the GPU-path Taylor–Green decay within 5% (SC3).
      Record error growth per 10 frames.
- [x] T021 Bench cost: `bc.measure` per stage at 256² (raise `chain` until it is GPU
      bound), sum against NF-001 (≤ 3 ms/frame). Record the per-stage table in Findings.
      If the sum exceeds the budget, generate an N = 128 set with `gen_dft.py` and
      rerun T016–T020 at 128 before proceeding.
- [x] T022 Bench soak: 300 frames GPU-sequenced at the extremes of every parameter
      (viscosity max, drag 0 and max, `project` 0 and 1, `dt` both ends, large force):
      all finite (SC5, GPU part).

**Checkpoint**: SC1–SC6 pass on the GPU path (with measured errors and cost
recorded). Commit. *BLOCKS Phase 2.*

**Phase 1 outcome (2026-09-23): met.** `tests/bench_fluid.py` 9/9 (~6 min). All seven
stage codeboxes in `src/f_vf_fluid/` match the mirror at float precision; the 100-frame
chained GPU run tracks the mirror to 3.1e-6 and Taylor–Green decays within 0.85% of
analytic at frame 100; total cost 2.4–2.8 ms/frame at 256² (budget 3 ms). One GenExpr
parsing quirk found and fixed on the way: `-(a + b) * c` mis-parses (see Findings).

---

## Phase 2: Build the Module — US1, US2, US3, US5

**Purpose**: Assemble the eight-stage patcher from the verified codeboxes with a
dedicated build script (plan ADR-9), then pass the module contracts.

**Independent Test**: `tests/test_module_contracts.py` and
`tests/bench_modules.py` green with no new `KNOWN` entries; two instances
coexist; bypass check passes.

- [x] T023 [P] [US5] Write `src/f_vf_fluid/definition.py`: metadata only (name, prefix
      `vffluid`, title, `signal_type` vecfield, outlets, params `force`, `dt`,
      `viscosity`, `project`, `drag`, `gain`, `bypass`, internal `src_vecfield` and
      `bypass_gate`, provisional ranges) so `build/extract_params.py`, docs and
      helpfile tooling work; header comment states the build script is the source.
- [x] T024 [US1] Write `src/f_vf_fluid/build_fluid.py` part 1: module chrome —
      identity/prefix constants, panel, title, `moduleSize` chain, `routepass`,
      `route` object and `autopattr` with `varname` `vffluid_autopattr` (plain
      `autopattr` text), importing helpers from `build/build_patcher.py`.
- [x] T025 [US1] `build_fluid.py` part 2: the eight `jit.gl.pix` boxes with `#0_`-scoped
      names (`#0_fluid_pass`, `_adv`, `_fx`, `_fy`, `_spec`, `_iy`, `_ix`, `_enc`),
      solver stages `@adapt 0 @dim 256 256 @type float32`, `enc` `@adapt 1
      @type float32`, gen subpatchers from the `codebox_*.gen` files, identity gen
      for `pass`.
- [x] T026 [US1] `build_fluid.py` part 3: wiring — `routepass out0 → vs_inState`; its
      texture output fans out to `adv`'s force inlet (inlet 1) and `enc`'s force inlet
      (inlet 1); `r draw` → inlet 0 of `adv` and of `enc` (plan ADR-2: they run every
      frame and `enc` takes the render-context size regardless of the force inlet);
      `vs_inState` out1 → `prepend param src_vecfield` → `adv` and `enc`; chain
      `pass → adv (inlet 2) → fx → fy → spec → iy → ix`; `ix → pass` feedback;
      `ix → enc` inlet 2; `enc` → outlet. Inlet/outlet orders exactly as plan ADR-1/ADR-2.
- [x] T027 [US2] [US3] `build_fluid.py` part 4: parameter UI and routing — dials,
      `attrui` per param with the plan ADR-9 stage targets (`dt`→`adv`,`spec`;
      `force`→`adv`; `viscosity`,`project`,`drag`→`spec`; `gain`→`enc`), route tokens,
      `parameters` block; canonical `gain` naming.
- [x] T028 [US5] `build_fluid.py` part 5: bypass — jsui → `prepend param bypass_gate`
      → `enc` (no native `attrui @attr bypass` anywhere in the patcher).
- [x] T029 [US5] Run `build/py.sh src/f_vf_fluid/build_fluid.py` → writes
      `package/patchers/f_vf_fluid.maxpat`; assert it parses and every route token
      wires to the same-named control (reuse the check used for `f_masonry`).
- [x] T030 [US5] Run `tests/run.sh tests/test_module_contracts.py`; fix wiring until no
      new `KNOWN_ISSUES` entries are needed.
- [x] T031 [US5] Add `f_vf_fluid` to `PARTIAL_BYPASS_BY_DESIGN` in `tests/bench_modules.py`
      (Param bypass gate, solver stays warm); run `tests/bench.sh tests/bench_modules.py`
      with the bench prerequisites (other patches closed); `bypass_out1` must pass
      and no `KNOWN` entry may be added.
- [x] T031a [US5] The module bench feeds 64² inputs but its render context is 512² and `enc`
      follows the context, so `bypass_out1` cannot compare like with like: give
      `tests/bench_modules.py` a per-module input size (the context size for
      `f_vf_fluid`) so the passthrough check stays exact; no `KNOWN` entry.
- [x] T032 [US5] Two-instance check: two `f_vf_fluid` in one Vsynth patch run
      independently with no "already in use" errors (FR-012); record the method used.
- [x] T033 [US1] Save/reopen check: parameters restore, solver starts from zero state,
      output finite (spec US5 scenario 3).
- [x] T033a [US1] Confirm the solver advances **exactly once per frame** (only the `r draw`
      bang on inlet 0 may trigger a render; inlets 1–2 must be cold): in the module bench
      run a known decaying state for K frames and check the amplitude ratio equals the
      single-step factor to the K-th power (a doubled update would square it).
- [x] T034 [US1] Smoke test in a scratch patch: `f_vf_vortex → f_vf_fluid →
      f_vf_advect` on a source; disable the vortex and confirm the flow persists and
      fades (US1 independent test, judgement).

**Checkpoint**: contracts and module bench green; two instances independent;
bypass passes through / neutral; US1 smoke test works. Commit.

**Phase 2 outcome (2026-09-23): met.** T033 (save/reopen restores parameters) and T034 (the `f_vf_vortex → f_vf_fluid → f_vf_advect` smoke test in a real Vsynth patch) were confirmed by Matt, who also judged the panel look good.
`build_fluid.py` builds `package/patchers/f_vf_fluid.maxpat` (46 boxes, 46 lines) and
self-verifies; the static contract test and the live module bench (33 modules) pass with
no new `KNOWN` entries; `tests/bench_fluid_module.py` 3/3 (once-per-frame, two instances,
fresh load). One real bug found and fixed on the way: **`vs_black` (all zeros = decoded −1)
was injected as a force for the first ~10 frames after load** because `vs_inState`'s
connected flag lags; fixed with a content check (B = 0.5) in `adv` and `enc`. 

---

## Phase 3: Tuning in Vsynth — US4 (and final parameter design)

**Purpose**: Tier 3 — ranges, look, integration; decide 256² vs 128².

**Independent Test**: each force source visibly drives the flow; none produces
edge or disconnect artifacts.

- [x] T035 [US4] Build `~/Vsynth/patterns/fluid_tuning.maxpat` with `f_vf_vortex`,
      `f_vf_flow`, `f_vf_repulse` and `f_vf_optical_flow` (on video) as selectable force
      sources into `f_vf_fluid` → `f_vf_advect` / `f_vf_warp` / `f_vf_glow`. Not committed.
      **DONE 2026-09-29**, generated by `scratch/build_fluid_tuning.py` (42 boxes, 33
      lines, self-verifying: unique ids, no dangling wires, every producer/consumer
      reaches its switch). Shape: 4 force producers → `switch 4` → Fluid → advect/warp/
      glow/split → `switch 5` → `vs_output`. Video for optical flow comes from
      `vs_sources_main.maxpat` (movie tab) — the only noisy force, and the only one that
      can make `taps` visible. `vs_render` already carries `jit.fpsgui` and routes `dim`,
      so T041's HD/4K switch and fps readout are message boxes (`dim 1280 720` /
      `1920 1080` / `3840 2160`). Message boxes into Fluid's control inlet: a RESET to the
      Phase 2 defaults (the T038a inconclusive result came partly from an unknown
      saturating state), `taps 1/8/16`, `project 0./1.`. **Unused producers are not
      disabled** — f_ modules use the bypass toggle, not Vsynth's `enable`. (The plan here
      was to measure Fluid's cost differentially, fps with bypass on vs off; that was
      dropped, see T041: bypass gates only `enc`, so it cannot measure the solver.)
- [x] T036 [US2] Define the `viscosity` curve (UI → physical ν·dt, plan ADR-5 guidance)
      and set ranges/defaults for `dt`, `force`, `drag`, `gain`, `project` in
      `src/f_vf_fluid/definition.py` and the patcher; record the mapping in Findings.
      **Viscosity curve DONE 2026-09-28** (dial 0–1, per-frame ν·dt = 1.6e-3·v³, default
      0.085; codebox, mirror, definition, bench updated; see Findings). **DONE 2026-09-29,
      Matt by eye: passes as is.** Defaults for `dt` (0.01), `force` (0.02), `drag` (0.5),
      `gain` (1.0) and `viscosity` (0.085) all stay; ranges (0–0.05, 0–0.2, 0–5, 0–10, and
      0–1 for viscosity) were not judged separately and stay as built. No regeneration.
- [x] T037 [US3] Judge `project` 0 vs 1 (shock-front vs swirl character); set its default.
      **DONE 2026-09-29, Matt's call: leave as is** (stays on the panel, default 1). Matt
      could not tell 0 from 1 on the force he tried. Not run: the discriminating test with a
      compressive force (vortex with `convergence` up and `curl` 0, or `f_vf_repulse`), where
      the Helmholtz projection should remove nearly all of the force at `project 1`. On
      solenoidal forces (vortex with convergence 0, uniform `f_vf_flow`, mostly-rigid video
      motion) no visible difference is expected, so this is not evidence the wiring is bad.
      If `project` ever looks dead on a compressive force, check that the tuning patch's
      RESET box doesn't also send `project`.
- [x] T038 [US4] Final force-downsample filter decision (bilinear vs 2×2 box) on a noisy
      source (`f_vf_optical_flow`); if it changes, update `src/f_vf_fluid/codebox_adv.gen`,
      the mirror, and rerun T017/T020. **Study done 2026-09-28 (see Findings): the single
      force tap aliases badly at HD/4K; fix = a k×k tap grid, see T038a.**
- [x] T038a [US4] Implement the force tap grid in `codebox_adv.gen`: a `Param taps` loop
      bound averaging taps offset in NORMALISED coordinates across the target texel
      footprint (no source size needed); mirror gets the same tap model + a minified-force
      case scored against an exact area average; rerun T017/T020, measure the `adv` cost,
      decide the default from that cost. **DONE 2026-09-28: default `taps` = 8** (16 was
      ideal but 1.2–1.7 ms, over the frame budget; see Findings). **Exposed on the panel**
      (Matt's call 2026-09-28: it is the one live cost/cleanliness trade-off) as an int
      numbox `taps`, 1–16, default 8, in row 2 slot 2 (definition.py + build_fluid.py
      `TARGETS`, routed to `adv`; rebuilt, 49 boxes/lines; offline contract test 0 issues).
      **Tier 3 INCONCLUSIVE (2026-09-28, Matt):** no visible or fps difference between taps 1
      and 16 in his patch. Likely causes, none confirmed: the force was `f_vf_repulse` (smooth;
      taps changes nothing by design), and Fluid was set to an undamped, saturating state
      (dt ≈ 0 so drag·dt ≈ 0, Visc 0, Force 0.20, Gain 9.37 → output pinned at the clamp);
      also ~1.5 ms of a 16.7 ms vsync-locked frame cannot move an fps counter. Not run: a
      module-level check (module bench with a noisy force at taps 1 vs 8) — needs Matt's
      patches closed. Re-test at Fluid defaults with `f_vf_optical_flow` as the force.
      **Still open:** module bench on the rebuilt patcher; tier 3 by eye in Vsynth at
      HD/4K on `f_vf_optical_flow` (does a noisy force now look calm? is 4K's 1.4× residual
      noise acceptable, or raise `taps`?).
      **CLOSED 2026-09-29 (Matt's call): `taps` comes off the panel; T038a done.** The
      GPU study already answered the only real question (what default), and a module-level
      re-verification would have confirmed through the patcher what the stage bench proved,
      while still being unable to reach 4K (the bench render context is 512²; a 4K force
      matrix is ~236 MB over the jxf transfer). `taps` also fails the library's own bar for
      a panel control — it does nothing on smooth forces by design, and on noisy ones it
      only removes noise, so there is no expressive range to perform. Now `"ui": False` in
      `definition.py`: **route token kept** (so `taps 1/8/16` messages still work from the
      tuning patch for a 10-second A/B if 4K ever looks noisy), widget and label gone.
      `Param taps(8)` in `codebox_adv.gen` is what actually governs — verified, since with
      no widget nothing sends the value at load. `build_fluid.py` now splits `routed` (route
      tokens) from `panel` (widgets); rebuilt 47 boxes / 48 lines (was 49/49), self-verified,
      JSON valid. Module bench after the rebuild: **0 issues**, 8 pix, `taps` still reaches
      `adv`. Side effect: the bench can no longer range-scale `taps` (no widget to read
      `parameter_range` from) so it sends a raw fraction — wiring checked, range not.
      Also fixes the cosmetic "1.00" float display, which no longer exists. Generalised
      learning captured in `skills/jit-gen-codebox/SKILL.md` ("a fixed-`@dim` stage is a
      resampler") and `skills/vsynth-bpatcher/SKILL.md` ("Not every parameter earns a
      panel slot") — f_ copies only.
- [x] T039 [US4] Edge cases in Vsynth: a uniform force (`f_vf_flow`) settles to a bounded
      speed with `drag > 0`; disconnecting the force mid-run leaves no corner-offset
      artifact; resizing the render does not reset or corrupt the state.
      **PASS 2026-09-29, Matt's call.** Uniform force: covered offline (the mirror runs
      "uniform force, no drag", the worst case, for 10,000 frames: finite, outlet in
      [0, 1]; drag only lowers it). Disconnect and resize were **not run** in Vsynth:
      disconnect shares the `vs_black` content gate already confirmed for fresh load
      (T033); resize is safe by design, since solver state is in fixed 256² textures and
      only `enc` follows the render size.
- [x] T040 Soak: run at parameter extremes for 10 minutes; output never NaN or stuck black
      (SC5, tier 3).
      **SKIPPED 2026-09-29, Matt's call.** Not run on the GPU. Tier 1 (SC5) stands: the mirror
      runs 10,000 frames at parameter extremes (`test_stability_at_extremes_10k_frames`),
      state finite and outlet in [0, 1].
- [x] T041 Cost in a real patch: record fps with a typical chain against NF-001; decide
      256² vs 128² (if 128², regenerate with `gen_dft.py`, rerun Phase 1 bench, rebuild).
      **DONE 2026-09-29: 256² stays.** Matt, by fps counter at 3840×2160: `fluid_tuning.maxpat`
      as built (four parallel consumer chains) ran ~42 fps; a single chain with Fluid ran
      59–60. Fluid is in both, so the ~7 ms overrun is the three extra consumer chains, not
      Fluid. The planned bypass on/off differential was dropped: `bypass_gate` only gates
      `enc`, the solver stays warm by design (ADR-8), so it would have measured ~0.1–0.2 ms.
      Margin unknown (59–60 is the vsync ceiling); Fluid's isolated cost was not measured.
- [x] T042 Matt judges SC7–SC8 (persistent swirl distinct from `f_vf_advect` alone;
      video-driven stirring works); record the verdict.
      **PASS 2026-09-29, Matt.** SC7 and SC8 judged by eye in Vsynth; no notes recorded.

**Checkpoint**: parameters final; success criteria 7–8 judged. Commit.

---

## Phase 4: Docs and Integration

**Purpose**: Make the module a documented, listed member of the library.

- [ ] T043 [P] Write `docs/f-reference/f_vf_fluid.md` (signal flow, stage table, parameters,
      periodic-domain and 256² notes, bypass behavior, cost).
- [ ] T044 [P] Add `f_vf_fluid` to the producers table in
      `docs/f-reference/f_vecfield_type.md` and a row in
      `docs/f-reference/module-inventory.md`.
- [ ] T045 [P] Add the README patch-table row in `README.md` (type: vecfield producer /
      processor; short description).
- [ ] T046 Generate the helpfile per `skills/f-helpfile/SKILL.md` (state check via
      `build/extract_params.py --all`; generation is in-session by hand) →
      `package/help/f_vf_fluid.maxhelp`.
- [ ] T047 Register the module in the `f_modules` menu with the ∇ marking
      (`tools/append_nabla_menu.py`: add to `VECFIELD_MODULES`; place under the ∇
      category that fits).
- [ ] T048 Add the four build-schema gaps this module hit (inlet fan-out through
      `vs_inState`, per-node `@dim`, multi-stage param targets, Param-based bypass) to
      `ideas/build_patcher_schema_gaps.md`.
- [ ] T049 Update `.specify/plan.md`: Work Queue item 11 → status; add `f_vf_fluid` to the
      never-regenerate list if the patcher was hand-edited after the first build.
- [ ] T050 Final regression: `tests/run.sh`, `tests/bench.sh` (both benches open),
      `tests/test_module_contracts.py` — all green, `KNOWN` registries still empty.
- [ ] T051 Update `HANDOFF.md` and this file's checkboxes and Findings.

**Checkpoint**: module documented, listed, and regression-clean. Commit.

---

## Dependencies & Execution Order

### Phase dependencies
- Phase 0 (gate) → Phase 1 (hard gate) → Phase 2 → Phase 3 → Phase 4.
- Within Phase 0: T002–T004 (Block C) and T008–T010 (Block A) are independent and can
  run together; T005–T007 are independent probes; **T009 must pass before any Phase 1
  codebox is written** (it fixes the Nyquist rule, units and decay form).
- Within Phase 1: T011–T014 are parallel (different files); T015 needs at least one
  codebox to exist; T016–T019 each need their codebox; T020 needs all stages; T021–T022
  need T020's stage set.
- Phase 2: T023 is independent; T024 → T025 → T026 → T027/T028 (same file, sequential)
  → T029 → T030–T033; T034 last.
- Phase 3 needs Phase 2; T036–T039 iterate; T041 may send work back to Phase 1 (128²).

### User story independence
- **US1** (producer): first to work end-to-end (T034); needs Phase 1 stages.
- **US2 / US3** (viscosity, projection): verified numerically in Phases 0–1
  independent of the patcher; surface as dials in T027.
- **US4** (stirring): tier 3 only, after Phase 2.
- **US5** (standard behavior): Phase 2 contract tasks.

### Parallel opportunities
- Phase 0: T002 ∥ T005 ∥ T006 ∥ T007 ∥ T008.
- Phase 1: T011 ∥ T012 ∥ T013 ∥ T014.
- Phase 4: T043 ∥ T044 ∥ T045.

---

## Implementation Strategy

### MVP first
Phase 0 → Phase 1 → Phase 2 through T034: a verified, contract-clean module that
stirs `f_vf_advect` from `f_vf_vortex` (US1–US3, US5). Stop and judge before
tuning.

### Incremental delivery
Phase 3 adds US4 and the final parameter design; Phase 4 documents it. Each phase
ends in a commit and a working state.

### If Block C fails
If T003/T004 show a 256² pix or the render-res encode stage misbehaves in Vsynth,
stop after Phase 0, revise plan ADR-2 (candidate fallbacks: run the whole chain at
render resolution with a smaller N, or encode from a `jit.gl.texture` at 256² with an
explicit resample), update the spec's Open Experiment 1, then continue.

---

## Notes

- `[P]` = different files, no incomplete dependencies.
- Bench prerequisites: Max open with `tests/bench/bench.maxpat` and
  `tests/bench/bench_module.maxpat`; every other patch closed (fixed-`@name`
  conflicts — see HANDOFF 2026-09-23).
- Tooling: Desktop Commander scripts must live under an allowed path (`scratch/` is
  fine); never regenerate a hand-edited patcher without a `git diff -w --stat` dry run.
- Update this file at session end; log measured values in Findings below.

---

## Findings (fill in as tasks complete)

| Task | Finding |
|---|---|
| T003 (E1) | **Pass.** `jit.gl.pix vsynth @adapt 0 @dim 256 256 @type float32` runs inside `vs_render`; reports `dim [256, 256]`, output 256² with the exact pattern (6e-8). A downstream `@adapt 1` stage adapts to its inlet-0 texture (64² input → 64²) and reads the 256² texture (2× magnification: bilinear exact to 6e-8; only the outermost ring differs from a periodic reference because `sample()` clamps). |
| T004 (E1b) | **Failed for the original wiring.** With the inlet unconnected `vs_inState` delivers `vs_black`; a stage adapting to it is **1×1** (`dim [1, 1]`). Fix confirmed (E1c): trigger `enc` (and `adv`) with `r draw` on inlet 0 → output is the render-context size (512² in the bench) whether or not the inlet is connected. |
| T005 (E-seam) | 4-tap (`seam_tap4.gen`): 1.3e-6 interior, 7.7e-7 on the seam vs the periodic reference. `sample()`+`fract()`: wrong on the wrap rows/column (0.52) and ~1e-3 elsewhere (8-bit GL weights). **Also found:** `sample()` is nearest-like when the output is *smaller* than the source (256→128/64/32: 1.84e-2 = half a source texel vs bilinear); exact bilinear at 1:1 and magnifying. → all interpolation is manual 4-tap (ADR-3). |
| T006 (E-nan) | `switch(abs(x) < 1e30, x, 0)` maps NaN and +Inf to 0 and leaves finite values unchanged. **`NaN == NaN` is TRUE on this GPU**, so the originally planned `x == x` guard would not have worked. |
| T007 (E5) | A `Param`-bounded DFT loop (`dft_param_n.gen`) compiles and matches the mirror at N = 128 and N = 64 (7e-8). Runtime-selectable resolution is possible; cost of a non-literal loop bound unmeasured. |
| T009 (mirror tests) | 16/16. Single-mode decay 2.5e-7–4.2e-7 (N = 64, 256); projection identities 5–6e-7; spectral divergence 8e-8–1.3e-7; Nyquist \|Im\|/\|Re\| 1.2e-16; Taylor–Green amplitude error at frames 10/50/100: N = 64 0.7% / 2.6% / 3.5%, N = 256 0.17% / 0.6% / 0.85% (bounds bilinear advection's numerical dissipation); energy always drops even at ν = 0 (worst −0.36%/frame); 10⁴-frame runs finite in all five extreme cases (uniform force with no drag reaches \|u\| ≈ 5e3, clamped at the outlet). |
| T011–T014 (codeboxes) | Written: `codebox_dft_{fx,fy,iy,ix}.gen` (generated by `gen_dft.py`, N = 256 literal twice each), `codebox_adv.gen`, `codebox_spec.gen`, `codebox_enc.gen`. **GenExpr quirk found by the first spec run:** a unary minus before a parenthesis mis-parses — `exp(-(v*k2 + drag) * dt)` evaluated as `-v*k2 + drag*dt` (control probe: `0 - (v*k2 + drag) * dt` is correct). All codeboxes and the DFT template now write `0 - ...`. **Also:** a codebox cannot read an input texture's size (`texdim` not defined; `in1.dim` returns 0), so the force is read with hardware `sample()`. |
| T015 | All seven stages compile and run (0.7 s). |
| T016 (spec vs mirror) | rel err 0–1.9e-7 over six (ν, project, drag, dt) cases incl. white noise with Nyquist energy. |
| T017 (adv vs mirror) | 6.5e-7 (force 1:1), 6.6e-7 (force magnified 2×), exact zero force at `src_vecfield` = 0, exact periodic seam gather (0.0). Force **minified** 2× (512² → 256²): 0.44 max error vs a bilinear mirror on white-noise force — hardware `sample()` is nearest-like when minifying (informational; harmless for a smooth force, E4). |
| T018 (enc vs mirror) | ≤ 9.4e-6 over 15 combos (90×120, 60×100 — smaller than 256² —, 256²; gain 1–30; gate/src combos); bypass passes the force through exactly (0.0) and gives an exactly neutral field when unconnected (0.0). |
| T019 (DFT stages) | Forward `fx→fy` vs `np.fft.fft2`: 1.3e-7 (u), 4.1e-7 (v) relative. Round trip `fx→fy→iy→ix`: 8.6e-6 / 9.1e-6 absolute (tolerance 1e-5 — close; the tolerance is now the binding number for the float32 transform at N = 256). `ix` returns Im = 0 exactly; NaN/Inf in one row → that row 0, other rows unchanged (0.0). |
| T020 (multi-frame) | 100 host-sequenced frames (6 jobs/frame, ~0.09 s/job) from a Taylor–Green state: max \|GPU − mirror\| 3.1e-6 over all frames (peaks ~3e-6 around frames 30–60, then falls as the field decays). GPU Taylor–Green amplitude vs analytic: 0.17% / 0.61% / 0.85% at frames 10 / 50 / 100 — identical to the mirror. 30-frame force run: 5.8e-7. |
| T021 (cost, ms/pass at 256²; enc at 1280×720) | adv ≤ 0.06–0.10 (upper bound), fx 0.52–0.54, fy 0.51–0.54, spec 0.10–0.13, iy 0.53–0.65, ix 0.54–0.65, enc 0.11–0.18. **Sum 2.38–2.76 ms/frame** over two runs (budget 3 ms): the four DFT passes are ~2.1–2.5 ms of it. 256² is viable on this measure; margin is ~10–20% and the in-a-real-patch cost (T041) is still to be measured. Runtime-selectable resolution (E5) was not benchmarked for cost. |
| T022 (soak) | 100 frames each, host-sequenced, at three extremes: thick honey/big dt (|u|max 0.0028), inviscid/no drag/big dt (1.22), unprojected + uniform force (50): all finite, outlet in [0, 1]. (Shorter than the planned 300 frames: 3 × 100 frames = 1,800 jobs, ~3 min; the 10⁴-frame runs live in tier 1.) |
| T023–T029 (build) | `definition.py` (metadata only) + `build_fluid.py` (imports the shared chrome helpers from `build/build_patcher.py`; reads UI params from `definition.py`; self-verifies unique ids, no dangling wires, every route token wired to the same-named control, 8 unique `#0_` pix names, no native `bypass` attrui). Output: 46 boxes, 46 lines. In the live module bench inside `vs_render` the module loads first try: 8 pix, every param reaches the right stage (`dt` reaches both `adv` and `spec`), 512² outlet. |
| T030 / T031 / T031a | Static contract test 3/3 (33 modules). Live module bench: **33 modules, 0 unexpected issues**; `f_vf_fluid`: 8 pix, `bypass_out1` exact (the bench feeds it a 512² input, `INPUT_SIZE` in `bench_modules.py`, because the render context is 512²), listed in `PARTIAL_BYPASS_BY_DESIGN` (Param gate, native attribute never set). |
| T033a (once per frame) | Uniform force, two captures 20 frames apart: **1.000000 updates per frame** (error 5e-6) under the drag hypothesis (0.90 if drag were 0). Only the `r draw` bang triggers `adv`; the force/state inlets are cold. A doubled update would read ~2. |
| T032 (two instances) | Two `f_vf_fluid` in one patch: no errors ("already in use" would show); the force-connected one is driven (|R,G − 0.5| up to 0.17), the unconnected one is **exactly** neutral; both outlets 512². |
| T033 (fresh load) | Unconnected inlet, fresh load: exactly neutral, render size — **after the fix below**. Before it: a uniform phantom velocity of about −0.04…−0.07 (R − 0.5) persisted at every warmup from 6 to 80 frames. |
| **vs_black finding** | `vs_black` is **all zeros**, decoding to −1 (the contract doc said "all 0.5" — corrected). `vs_inState`'s connected flag lags ~180 ms at load/disconnect, so `src_vecfield = 1` briefly while the inlet is unconnected; the solver injected the −1 force for ~7–10 frames and the resulting phantom velocity decays only at the drag rate. Fix: gate the force by content in `codebox_adv.gen` and `codebox_enc.gen` — `abs(sample(in2, norm).z - 0.5) < 0.25` (a real `f_vecfield` has B = 0.5, `vs_black` B = 0) — mirrored in `fluid_mirror.py`, tested at tier 1 (17/17), on the stage bench, and in the module bench. Caveat added to the `vsynth-bpatcher` skill. |
| T010 (mutation check) | All five mutations caught: Nyquist not zeroed, projection sign flipped, decay exponent wrong, drag dropped, advection clamps instead of wrapping. |
| T016–T019 (bench errors) | |
| T020 (multi-frame error growth) | |
| T021 (cost per stage / total) | |
| T036 (viscosity mapping) | **Before:** the dial was ν∈[0, 0.002], linear, with the codebox taking physical ν and multiplying by `dt`. At its extreme (ν=0.002, dt=0.05) it only reached m_c≈16 (m_c = 1/(2π√(ν·dt)) = the mode index that e-folds per frame); mid-scale swirls (m≈8) still passed at 78–95% per frame, so "honey" was unreachable (a blobby look needs m_c≈4–6, ν·dt≈1e-3). Also `dt` moved the smoothness: sweeping dt 0.002→0.05 at a fixed dial moved m_c from 80 to 16. **After (2026-09-28, Matt chose "smoothing independent of dt"):** `viscosity` is a 0–1 dial and the shader computes per-frame `nu_dt = 1.6e-3·v³`, decay `exp(-(nu_dt·k² + drag·dt))`; `dt` is speed only, drag stays time-based. Anchors: dial 1.0 → m_c 3.98; default 0.085 → nu_dt 9.8e-7 (= the old default 1e-4×0.01, so nothing shifts until tuned by eye); dial 0.25 ≈ m_c 32, 0.5 ≈ m_c 11. Mirror `visc_to_nudt()`/`nudt_to_visc()`. Checks: `test_fluid_mirror.py` 19/19 (new: dial law, dt-independence; sixth mutation "viscosity coupled to dt again" caught; Taylor–Green unchanged at 0.85% off analytic, N=256 frame 100); `bench_fluid.py` 9/9 (spec vs mirror ≤1.9e-7 across the dial incl. v=1 and out-of-range v=2; 100 GPU frames within 3.0e-6 of the mirror; cost 2.15 ms/frame). Module rebuilt by `build_fluid.py` (patcher diff: shader text, dial hint, initial 0.085, max 1.0). **Not yet run:** module bench `bench_fluid_module.py` on the rebuilt patcher; Matt's look in Max. Saved `viscosity` values from before this change mean something different now (dial vs physical ν). |
| T038 (force downsample, `scratch/e4_force_alias.py`, 2026-09-28) | Matt performs at HD/4K, so the force is minified into 256² by 4–7× (HD) / 8–15× (4K); a single tap reads <1% of the source pixels. Noise gain vs an ideal area average (1.0 = ideal), bilinear-tap model / nearest-tap model (hardware is nearest-like when minifying, so the truth is nearer the second): today's single tap **HD 3.8× / 5.9×, 4K 9.3× / 11.5×**; k×k tap grid: tap4 HD 1.1/1.5, 4K 1.9/2.9; tap8 HD 1.0/1.0, 4K 1.1/1.4; **tap16 HD 1.0/1.0, 4K 1.0/1.05**. Above-Nyquist sinusoids pass today's tap at ~full amplitude (mean 1.0) vs ≈0.1 with tap16. Smooth flow + 0.5σ pixel noise: rms error vs the noise-free flow ≈0.5 today vs ≈0.045 with tap16 (flow rms 1). Taps offset in normalised coordinates need no source size, so no Param size or extra stage is needed. Smooth producers (`f_vf_vortex`, `f_vf_flow`, `f_vf_repulse`) are unaffected. Limit no tap grid fixes: content just above the grid Nyquist still aliases even under the ideal box (worst-case output ≈0.57). Bench context is 512² so 4K cannot be verified there. → T038a. |
| T038a (force tap grid, 2026-09-28) | Shader: `Param taps(8)`, nested `for` loop (expression bound `max(1, floor(taps))`) averaging `sample(in2, ...)` at normalised offsets; content gate stays on the centre tap. Mirror: `tap_weights()` / `force_taps()` = the same average in separable form (matches a literal brute-force translation to 6e-7). **Hardware confirmed on the GPU** (white-noise force, noise gain vs an exact area average; the nearest-tap model predicted these to 2 decimals): HD taps 1/4/8/16 = **5.97 / 1.49 / 1.01 / 1.02**; 4K = **11.6 / 2.88 / 1.44 / 1.05**. `adv` cost at an HD force: taps 1 = 0.05–0.08 ms, taps 8 = 0.36–0.7 ms, taps 12 ≈ 1.0, taps 16 = 1.2–1.7 ms (varies with GPU state run to run); 4K force costs about the same. **Default 8**: frame total 2.49 ms (budget 3), HD ≈ ideal, 4K 8× less noise than before (1.44× ideal); 16 would give 3.3–4.4 ms. Checks: mirror 22/22 (three new tests; seventh mutation "tap grid ignored" caught), bench 12 tests (taps=1 reproduces the old shader at 1:1 to 6e-7; taps=8/16 match the mirror at 1:1 and magnified to 1e-6; 100-frame chain still 3.0e-6). A `taps` Param was left un-pinned in the T021 cost test and inherited 16 from the previous job (the bench keeps attribute values between jobs), which briefly showed a bogus 4.35/3.31 ms total — fixed by pinning. Exposed as a panel control (int numbox, 1–16, default 8) the same day; the 190×150 panel had a free slot, no other control moved. Tap grid at 1:1 slightly blurs a very sharp 256² force (box of about one texel); `taps = 1` restores the exact old read. |
| T041 (cost in a real patch; 256² vs 128²) | **256² stays (2026-09-29, Matt, fps counter, 3840×2160).** `fluid_tuning.maxpat` with four parallel consumer chains ≈ 42 fps (≈ 23.8 ms/frame); one chain with Fluid = 59–60 fps. Fluid is present in both, so the overrun is the extra consumer chains. If the single chain sits near 16.7 ms, each extra heavy consumer costs ≥ ~2.4 ms at 4K, the same order as Fluid, so 4K has room for Fluid plus about one heavy consumer. Not measured: Fluid's isolated cost and the real margin (59–60 is the vsync ceiling). Method note: bypass on/off cannot measure the solver, `bypass_gate` gates `enc` only (ADR-8), so the handoff's planned differential was replaced by a chain-count comparison. |
