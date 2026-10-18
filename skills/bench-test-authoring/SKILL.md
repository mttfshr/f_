---
name: bench-test-authoring
description: How to author tier-2 test files for the Max test bench (tests/bench_*.py) and the module contract bench (tests/bench_modules.py) without rediscovering their harness conventions the hard way. Read before writing any new bench file. Exists because 2026-10-17's five-module batch shipped three bench files whose tests assumed mechanisms the harness does not have (per-step input swaps), and because two sibling sessions deleted each other's bench files over a layout assumption — the failures were test-authoring failures, not module failures.
---

# Bench test authoring (tests/bench_*.py, tests/bench_modules.py)

**Cost asymmetry:** a bench run costs minutes and asks the owner for permission; a wrong
assumption costs a misleading FAIL (or worse, a green that measured nothing). The harness
conventions below are load-bearing — hold to them.

## Conventions the harness has (verified 2026-10-17)

1. **There is NO per-step input swap in the temporal harness.** `bc.run_temporal(code,
   inputs, steps)` uploads `job.inputs` ONCE (bench.js `loadInputs()`); every step renders
   the same `in1`+`in2`. A test that compares step s against `frames_in[s-1]` measures the
   harness, not the module. To test a changing world: **chain single-step
   `run_temporal` jobs**, seeding each job's state input with the previous job's captured
   output. (Done this way in `tests/bench_tf_smooth.py` — the decay-theorem and
   bypass-invariance rows compare chained outputs against a NumPy sequence model.)

2. **The bench keeps a `Param`'s last value between jobs.** A job that omits a Param
   inherits whatever the previous job set — including from the previous bench FILE's
   run. Pin EVERY Param a measurement depends on in EVERY param dict (cost readings,
   parity readings, anything). Symptom if you don't: a test that passes in isolation
   and fails when run after another file — e.g. a "default" job inheriting `bypass_gate=1`
   from a prior run's bypass test and measuring the raw source instead of the filter
   (this exact failure hit `tests/bench_tf_aniso_blur.py` 2026-10-17).

3. **The codebox compile caches nothing across jobs, but Params persist** — a fresh
   compile resets declared defaults only for params the job names. The skill's
   `jit-gen-codebox` "pin every Param" note covers the codebox side; this is the same rule
   at the test-file layer: build param dicts from a single `PINNED` base dict + the case's
   deltas, not from ad-hoc dicts.

4. **BYPASS_EXPECT forms** (`tests/bench_modules.py.bypass_expected`): `("in", k)` = outlet
   equals harness inlet k bit-exact; `("in_a1", k)` = inlet k with alpha forced to 1 (for
   modules whose bypass mixes rgb only — outlet contract A=1); `("vec", k, tol)` = vecfield
   neutral override; `("const", (r,g,b,a), tol)` = fixed color. Processors not in the table
   get the implicit `{1: IN1}` — correct ONLY for native-@bypass modules. Param-bypass
   modules (`bypass_mode: "param"`) must state their TRUE bypass source:
   - `f_tf_smooth`/`f_tf_sharpen` — bypass = passthrough of the module's first inlet
     (the tensor) → `{1: IN1}`
   - `f_tf_glyph`/`f_tf_aniso_blur` — bypass = passthrough of the module's SECOND inlet
     (the source/tint) → `{1: ("in", 2)}`; note glyph's mix has no alpha arm (its outlet
     alpha is always 1 → use `in_a1`), while aniso's carries an alpha arm (passes in2's
     alpha through exactly → plain `in`)
   - `f_tf_hatch` — bypass = the module neutral (black) with alpha 1 →
     `("const", (0.0, 0.0, 0.0, 1.0), 1e-6)`
   The bypassed frame comes from the **jsui click** (`bypass_toggle.js` → `bypass_gate 1`),
   not the native `bypass 1` message (that is informational-only for param-bypass modules).

5. **Fixture values must stay inside the real outlet contract's encoding.** Outlet 0's
   contract clamps (`R = clamp(Jxx·strength, 0, 1)`, G likewise) — encoding at strength
   100 with pre-gain components in [0,1] exceeds the range and the comparison measures the
   contract's clamp, not the operator. Encode at strength 1 (or a strength that keeps the
   encoded values in range) and prove gain-commutation as its own row.

6. **`tests/benchdeps.py` DATA: glob the codebox path `src/<module>/codebox_*.gen`.** When a
   bench file changes, its DATA entry's fingerprint changes — that is the registration
   contract. Do NOT delete other modules' bench files when a sibling's registration glob
   disagrees with an on-disk path: shared-file conflicts get reported to the parent session
   (see the layout-convention rule below).

7. **Tolerances are calibrated per mechanism, and the mechanism is documented in the
   tolerance's comment**: `1e-6` for pure-arithmetic chains (unattainable for anything that
   samples — the hardware's 8-bit interpolation weights sit at median 2e-5, max 1.2e-4 per
   read, see jit-gen-codebox's sample() facts); `~2e-4` for stacked single reads
   (`bench_tf_glyph`), `~1e-2` where the compared quantity contains a huge-argument hash
   (`bench_tf_hatch`'s E3 sweep: `sin(line_idx·127.1·43758)` reaches ~1e9, where GPU and
   NumPy argument-reduction legitimately differ; the reg-1.0 geometry row that zeroes the
   hash proves the math exact at 3.5e-6 — pair the look-dependent row with an
   exact-geometry row).

## Layout and ownership (multi-agent builds)

- **`src/<module>/` is the shipped layout** — definition.py and codeboxes live there,
  matching tensormap/axisflow/optical_flow/f_lens. `.specify/<module>/` holds the triad
  docs + REGISTRATION_NOTES only. Two builder agents working from different precedents
  (`.specify/`-relative layouts in triad docs vs the shipped `src/` layout) put files in
  both — the parent normalizes to `src/` and the triad's Files-layout headers get amended
  to match what was built.
- **One module = one owner.** Sibling agents never delete or "clean up" another module's
  files (a bench file at an unexpected path is a registration question, not a stray).
- Shared files (`menu.py`, `bench_modules.py`, `benchdeps.py`, README, module-inventory,
  launch) are parent-owned during parallel builds: builders write the exact needed lines
  into `.specify/<module>/REGISTRATION_NOTES.md`, diff-style; the parent applies and
  regenerates (`generate_menu.py`, `generate_launch.py`) and runs the offline suites.

## The module bench is the only thing that tests the SHIPPED patcher

The codebox bench wraps code in its own genjit wrapper — it cannot see a broken builder
wiring. The module contract bench (`tests/bench_modules.py`) instantiates the SHIPPED
patchers as Max does. A module can be 30/30 green on its own bench and still ship broken
(this exact shape: the 2026-10-17 builder driving_inlet gap — "patchcord source not
found" + "type is not a sampler" on load, then the module passthroughs its first texture
irrespective of any dial). Run `tests/bench_modules.py` before declaring any builder-touching
change done.