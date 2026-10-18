# tests/

Math-first tests for codebox algorithms, run in NumPy before anything is
patched in Max. Motivation: a scratch patch tests two things at once (is the
math right? does Max/GPU run it?) and failures can't be attributed. Settle the
math here; the scratch patch then answers only "does known-correct code compile
and run fast enough."

## The idea, and what it does and doesn't prove

A `jit.gl.pix` codebox is a GPU fragment program: a pure function from input textures and Params to
one output color per pixel, run for every pixel in parallel. That makes it unusually easy to
re-express on the CPU, and the whole test strategy rests on three separate questions, each answered
by a different tool, so a failure points at one cause:

1. **Is the algorithm right?** Answered in NumPy, with no Max. We write a *mirror*: a plain Python
   function per codebox pass that takes `(H, W, 4)` float32 arrays and computes every pixel at once.
   We then check the mirror against **independent ground truth** (`np.fft` for the fluid solver,
   closed forms for the solver's drift term, photon counting for caustics, analytic angles for the
   tensor modules), never against a second copy of the same logic.
2. **Does the real codebox do what the mirror does?** Answered by the bench. The shipped `.gen`
   file runs on the actual GPU inside a live Max, the frame is read back, and it is diffed against
   the mirror, pixel by pixel, with the measured error printed.
3. **Does it look and feel right?** Not measurable here. That is a scratch patch and your eyes
   (expressive tuning, ranges, Vsynth integration).

**What "emulating with NumPy" means.** `tests/lib/gpu_sim.py` models the parts of the execution
model a mirror needs: texel-center coordinates (`norm = (i + 0.5) / dim`, array index `[row, col]`
with row 0 where `norm.y` is smallest), `nearest()` and bilinear `sample()` with clamp or wrap,
float32 arithmetic throughout (so precision problems the GPU will have show up on the CPU too), and
`store_char` for 8-bit textures. It is **not** a GenExpr interpreter. Nothing parses the codebox:
a mirror is a hand translation, written to follow the shader (same fixed-count loops, one function
per pass, every read through `gpu_sim.sample` / `nearest`). Two consequences follow. A mirror can
be wrong about the shader, and nothing offline will notice; only the bench diff (question 2)
closes that gap. And a mirror that shares a wrong convention with the code under test cannot catch
it, which is why the ground truth in question 1 must be independent.

**How we know the simulator's own conventions are right.** They were each verified against Max 9
`jit.gl.pix` with probe codeboxes, not assumed: `norm`, the row orientation, and the fact that
GenExpr's `cell` is `norm * (dim - 1)`, not an integer index (bench-verified 2026-09-22, probe
exact to float32). Findings like this are pinned in `gpu_sim.py`'s docstring and in
`skills/jit-gen-codebox`, so the mirror follows what the GPU does rather than what the docs imply.

**Fidelity: what has been measured.** Agreement depends on the operation, so there is no single
number; the tolerance for each check is printed beside its measured error (`harness.check`).
Measured examples, from the bench runs recorded in `HANDOFF.md`:

- Plain float32 arithmetic and trig: very tight. `atan2` as used on a sampled vecfield matched
  NumPy to about 6e-7 rad over all quadrants.
- Multi-stage solvers: the shipped DFT stages match `np.fft.fft2` to 1e-5 at N=256; the caustic
  scatter's edge modes match their mirror to roughly 3e-6 to 1e-5.
- Interpolated reads of float textures have a floor: the GPU filters with 8-bit weights, so
  bilinear results sit about 2e-4 away from an exact float32 interpolation once stacked.
  A tolerance below that fails for a reason that is not a bug.
- Known, deliberate gaps (each explained where it is recorded): at the `atan2` branch cut the GPU
  returns +pi where IEEE gives -pi, so comparisons there must wrap; a border pixel case where the
  GPU snaps and the mirror clips (about 1e-3 in `f_caustic` with edge mode off).

**Where the GPU disagrees with the textbook (found on the bench, so now rules).** Runtime
`atan2(0, 0)` is NaN, though constants fold to 0; `sample()` falls back to nearest when its
coordinate is data-dependent and jumps; `phi` is a predefined constant and assigning it fails the
whole compile. These could not have been found by the mirror alone. They are the reason the bench
exists.

**Honest limits.**

- A green bench run means the codebox ran, was captured, and matched the mirror on the inputs
  the test fed it. It says nothing about inputs it did not feed it. Test inputs are chosen to hit
  branches (degenerate points, seams, extremes), and tests are mutation-checked once (inject a
  plausible bug, confirm a test fails) to show they can fail at all.
- `report["status"] == "ok"` means *ran and captured*, nothing more. Numeric correctness is only
  ever judged by the diff.
- The bench runs shaders in isolation at test resolutions, so it cannot see compile limits at
  Vsynth scale, fps under a real chain, GPU driver differences or `@adapt`/`@dim` behavior. The
  bench also keeps Params between jobs, so every test pins the Params it depends on.
- It does not replace tier 3. A module can match its mirror to 1e-6 and still look wrong.

For how these map to the repo's verification tiers (math, execution, judgment), see the root
`README.md` and `.specify/constitution.md`.

## Two layers

- **Math tests** (`tests/**/test_*.py`, `tests/run.sh`) — NumPy only, run
  anywhere. Settle the math before Max is involved.
- **Bench tests** (`tests/**/bench_*.py`, `tests/bench.sh`) — run codeboxes on
  the GPU in a live Max through the test bench and diff the results against
  the NumPy mirrors. Spec/plan/tasks: `.specify/test_bench/`.

## Run

    tests/run.sh                              # every tests/**/test_*.py
    tests/run.sh tests/toolchain/test_gpu_sim.py   # one file
    tests/bench.sh                            # regression set (needs the bench open)
    tests/bench.sh --changed                  # only files whose inputs changed since their last green run
    tests/bench.sh --slow                     # the regression set plus its @slow tests
    tests/bench.sh --all                      # every bench_*.py, incl. perf and probes, and slow tests
    tests/bench.sh --list                     # show what would run (no Max needed)
    tests/bench.sh tests/modules/fluid/bench_fluid.py  # one file
    tests/check.sh quick                      # offline suite only: the before-commit check, no Max
    tests/check.sh full                       # quick, then bench.sh --changed -q (needs the bench open)

The regression set is every bench file that declares `GROUP = "regression"` (ordered by its `ORDER`;
`tests/lib/benchdeps.py list --group regression` prints it). It
leaves out `bench_perf.py` (fps-based checks that can fail on a busy machine
without a regression) and `bench_fluid_probes.py` (a Phase 0 record of
bench-verified facts); `--all` adds them.

`--changed` (`tests/lib/benchdeps.py`) skips a bench file whose Python imports, data files and environment
(Max and Vsynth versions) equal those of its last green run, and says why; `bench_modules` runs only the
modules whose patcher changed (`BENCH_MODULES`). The record is `tests/.state/bench_green.json` (local,
gitignored): a passing file is recorded, a failing one is forgotten, so any plain `tests/bench.sh` run
seeds it. A new `tests/**/bench_*.py` must be registered in `benchdeps.DATA` (a test enforces it). It does
not see the GPU driver, macOS, or what else is open in Max, so run without `--changed` before a release.

**Background runs** (`tests/bg.sh`): `start [offline|bench|all]` returns at once and runs detached;
`status` (exit 0 passed, 1 failed, 2 running, 3 none), `log`, `stop`, `list`. One bench run at a time (a
lock); an offline run may overlap anything; `bench` defaults to `--changed`; a macOS notification when it
finishes. Run state is in `tests/.state/bg/` (gitignored). A bench run needs Max up with the bench open, else it
fails fast with "bench not reachable" in its log. It does not isolate the bench from your Max session:
reopening the bench still brings Max to the front, and the bench's global error trap can pick up errors you
cause in Max meanwhile (`build_cleanup` T033).

A test marked `@slow` (`harness.slow`) is skipped unless `--slow` or `--all` is given, and the
skip is printed by name. Today that is `bench_fluid` T021 (cost against the 3 ms budget, ~45 s)
and T022 (soak at parameter extremes, ~190 s). Measured 2026-10-04: the default run is ~190 s
with them skipped, ~440 s with them. Run them when a shader, the solver's parameters or the bench
setup changes. A bench job costs ~75-100 ms whatever its work (a stub job alone is ~12 ms; the rest is
~7 rendered frames, file I/O, a shader compile and the Python-side file work, spread over many small
parts), which is why a 6-job solver frame costs ~0.6 s.

**Tried on 2026-10-04 and rejected; do not retry without a new idea:**

- *Free-running frames for correctness jobs* (`displaylink 0`, `sync 0`, `fps 1000`, as performance
  mode does). 4% faster (188 s to 180 s), and it broke `bench_selftest` and `bench_temporal`: secondary
  outputs (`out2`, ...) came back `None`. Their GPU-to-CPU readback needs wall-clock time, so the
  capture is not purely frame-synchronous.
- *Content-hashed `.genjit` names, to avoid recompiling.* The same code repeated was ~20% faster
  (59 ms against 75 ms per pass), but the real pattern, alternating stages, gained nothing (74 ms).
  Outputs were bitwise identical either way.
- *Running the codebox bench and the module bench concurrently* (separate ports, one Max). The module
  group passed (101 s); the codebox group failed 15 assertions, all `jpatcher: doesn't understand
  getattr`. The bench traps every Max error through one global route, so errors raised while the other
  bench loads Vsynth land inside unrelated jobs. It needs per-bench error capture first. Both runners
  also prune the same `tests/jobs/` to the newest 50, which would need an age floor.

What is left is structural: a chain of passes in one job (T020's 100 solver frames), or running only
the modules that changed (`bench_modules` is 33 forced reopens, ~75 s).

Uses `uv` to supply NumPy in an ephemeral environment -- nothing installed
system-wide. No pytest; each test file runs standalone via `harness.py`.

## Conventions

- **Mirror the shader, not just the algorithm.** One Python function per
  planned codebox pass; each reads only its input textures and computes every
  pixel. Loops written as the codebox's fixed-count loop would be.
- **float32 everywhere**, textures as `(H, W, 4)` RGBA, stored through
  `store_float32` / `store_char` between passes.
- **Sample through `gpu_sim.nearest` / `gpu_sim.sample`**, which model
  texel-center coordinates, bilinear filtering and clamp/wrap. Don't index
  arrays directly inside a pass mirror.
- **Test against independent ground truth** (NumPy reference functions,
  analytic solutions), not against another copy of the same logic -- a test
  that shares a convention with the code under test can't catch errors in
  that convention (see the divergence-test note below).
- **Print measured errors** via `harness.check`, so every run leaves numbers.
- **Mutation-check new tests once**: inject a plausible bug, confirm a test fails.

## What the math layer can't answer

Loop unrolling / instruction limits, fps, GPU trig precision, texture format
behavior in Jitter, `@adapt`/`@dim`. Those are what the bench is for.

## The Max test bench

One generated patch, `tests/bench/bench.maxpat`, stays open in Max; Python
drives it over OSC/UDP (7471 in, 7472 out) and exchanges data through files
in a per-job directory under `tests/jobs/` (gitignored; `new_job()` keeps the
newest `JOBS_KEEP` = 50 and prunes older ones, since a job dir can hold 100+ MB; after an all-green `tests/bench.sh` run it is cut to
`JOBS_KEEP_AFTER_RUN` = 8, and a failed run keeps its dirs for debugging).
All bench logic is in `tests/bench/bench.js`; the patch is only objects and wiring.

**Per session:** open Max, open `tests/bench/bench.maxpat` once (or, with
Max already running, `benchclient.reopen()` does it). `tests/bench.sh`
fails fast with "bench not reachable" if it isn't open. Full output of the
last bench run is always in `tests/logs/latest-bench` (see Logs and state, below).

**Don't edit or save `bench.maxpat`** — it's generated
(`python3 tests/bench/make_bench.py`), and unsaved edits make `reopen()`
hit a save prompt. After regenerating, call `benchclient.reopen()`.

**From Python** (`benchclient.py`):

    out, report = run_pass(code, [rgba_in1, ...], params={"name": v})
    report = measure(code, [rgba_in1], chain=K)

- `run_pass` — correctness: one pass, one captured float32 frame, returned
  as RGBA `(H, W, 4)`. `report["status"] == "ok"` means *ran and captured*,
  nothing more; numeric correctness is always judged by diffing against the
  NumPy mirror. `error` = Max errors were captured during the job (text in
  `report["errors"]`, e.g. gen compile errors); `stalled` = no capture
  before the timeout. Multi-pass algorithms: one pass per job, feeding
  outputs forward.
- `measure` — performance: K chained copies, fps, and a K=0 baseline.
  CPU and GPU overlap (frame ≈ max(overhead, K × pass cost)), so
  `ms_per_pass` is only reported when `gpu_bound`; otherwise
  `ms_per_pass_upper_bound`. Throughput numbers for comparisons, not
  absolute GPU time.
- `run_pass(..., all_outputs=True)` returns `[out1..out4]` (an unused outlet
  comes back all zeros); `pix_type="char"` runs the pass as char (round-to-
  nearest, clamped; read back scaled to 0..1).
- `run_temporal(code, [in1, init_state, ...], steps=[1, 5, 20],
  feedback=(from_out, to_in))` — multi-frame runs with a one-frame-delay
  feedback loop (Pattern 1): step s reads step s-1's output from input
  `to_in` (2 or 3). Returns `{step: [out1..out4]}`.
- **A codebox compile failure can wedge the bench** (seen 2026-10-06 with the
  parser's "stack overflow (too many captures)" on a program over ~450
  statements, see `skills/jit-gen-codebox`): every later job then returns the
  SAME stale image, whatever the code, with no error, until
  `benchclient.reopen()`. A long session that may compile something large
  should probe with a known-good codebox before trusting a result
  (`benchclient.ensure_healthy` does this and reopens; `tests/bench.sh` runs it before every codebox-bench file). `measure` readings
  under the empty-pass floor (~2.1-2.5 ms per frame here) are upper bounds.
- **Params are reset per job** (`benchclient.with_param_defaults`, used by `run_pass`, `run_temporal` and `measure`): the
  bench keeps Params between jobs (found three times: caustic, aniso/sharpen, fluid), so every job now sends the codebox's own
  `Param name(default)` for any Param the test did not supply. Only declared Params are added; a Param with no plain numeric
  default (`Param x;`, `Param x(PI)`) is left alone. Offline checks, with a mutation check of the checks, are in
  `test_benchclient.py`; the live one is `bench_control.py::test_unsupplied_params_reset_to_their_defaults`.

## The module bench (shipped bpatchers)

A second generated patch, `tests/bench/bench_module.maxpat` (ports
7473/7474), runs **shipped** `f_` bpatchers inside Vsynth's real `vs_render`
context. **Close Vsynth performance patches while it's open** — it creates
the global `vsynth` context. `tests/contracts/bench_modules.py` loads each module (a
fresh bench session per module), feeds it textures, sends every route
parameter as a control message and reads the attribute back off the inner
pix, exercises bypass (documented control message and the jsui), and
captures every outlet. `tests/contracts/test_module_contracts.py` is its offline half:
static route → attrui → Param wiring from the patch JSON, no Max needed.
Both keep a registry of known issues (reported XFAIL with a pointer; a fixed
one reports XPASS so the entry gets removed). Run both after changing any
shipped bpatcher. Debugging hooks: `/probe` and a localhost-only `/eval`
(`modulebench.bench_eval(js)`), which run inside the module bench.

Open Max with `bench.maxpat` for `tests/bench.sh`. `bench_modules.py` and
`bench_fluid_module.py` open `bench_module.maxpat` themselves, so close Vsynth
performance patches before running them.

**Adding a bench test for a module:** copy `tests/templates/bench_module_template.py` to `tests/modules/<module>/bench_<module>.py`, point `CODEBOX` at the module's real `src/<module>/codebox_*.gen`, fill in the mirror/invariants, register it in `benchdeps.DATA`, and declare `GROUP = "regression"` (and an `ORDER`) once it is a regression gate. Which tests a module needs is decided per module (constitution: Verification Tiers).

**Writing a bench codebox:** plain GenExpr text (see `bench/codeboxes/`).
Up to 3 inputs (`in1..in3`); `Param` values arrive on frame 3. Remember the
bench-verified facts: `cell` is `norm * (dim - 1)`, not an integer — use
`floor(norm.x * dim.x)` (see the `jit-gen-codebox` skill's Bench-Verified
Facts section).

## Files

Entry scripts stay at the top of `tests/`; everything else lives in a directory named for what it is. Imports
need no `sys.path` edits: the runners export `PYTHONPATH` (`lib/`, every test directory, `build/`), and
`tests/py.sh <file>` runs one file the same way. Stem names are unique repo-wide, so `benchdeps.DATA` is keyed by
stem. The old-path to new-path table for the 2026-10-18 move is `.specify/test_bench/path_map.tsv`.

- `run.sh`, `bench.sh`, `bg.sh`, `check.sh`, `_log.sh`, `py.sh` -- the offline runner (finds `tests/**/test_*.py`, per-file timing
  table), the bench runner, background runs, the log helper the first three share, a one-file runner, and `check.sh quick|full` (offline suite; or offline plus the changed benches).
- `lib/` -- shared code, no tests of its own except through `toolchain/`:
  - `gpu_sim.py` jit.gl.pix execution-model emulation (grid, sampling, storage); `harness.py` minimal runner
    (`check`, `slow`, `skip(reason)`, `max_path()`, `MAX_APP`); `paths.py` `REPO` / `TESTS` / `BENCH`
  - `dft_mirror.py` the separable-DFT mirror (`pass_dft`, `fft2_passes`, `ifft2_passes`), `pack` / `make_image` / `rel_err`,
    and `dft_codebox` (the bench's `dft_x` / `dft_y` test codebox at size N); used by the fluid mirror and benches
  - `benchclient.py` bench client (OSC, jobs, `run_pass`, `run_temporal`, `measure`, `reopen`, `ensure_healthy`,
    `with_param_defaults`); `modulebench.py` and `module_contract.py` the module bench's client and the offline wiring
    contracts (`KNOWN_ISSUES` are XFAIL with a pointer; a fixed one reports XPASS)
  - `benchdeps.py` what `bench.sh --changed` runs (input hashing, decision table, record, `list --group`);
    stdlib only, run under the system `python3`
  - `jxf.py` Jitter `.jxf` read/write <-> RGBA float32; `genjit.py` codebox text -> `.genjit`; `patchbuild.py`
    patch-building helpers for the bench generators
- `toolchain/` -- tests of the harness itself and the bench of the bench: `test_harness`, `test_gpu_sim` (the emulator's sampling), `test_benchclient`,
  `test_benchdeps`, `test_bg`, `test_jxf`, `test_genjit`, `test_bench_patchbuild` (offline), `bench_control` (ping,
  /busy, error reporting, Param reset), `bench_selftest` (identity, coordinate probe, plane order, compile-error
  capture, reload, two inputs), `bench_temporal` (feedback runs: step counter, accumulator, routing, char),
  `bench_perf` (rate control, scaling, repeatability, DFT cost; group `perf`, not in the regression set).
- `build/` -- tests of the `build/` tooling, all offline: `test_drift` (the definition.py ratchet: every shipped
  patcher is rebuilt from its definition in memory and compared with the shipped file; a module must reproduce
  exactly unless it is in `drift_baseline.json`, which may only shrink; rewrite it with
  `python3 tests/build/test_drift.py --write-baseline`; see `build/spec.md`, "Source of Truth and Drift"),
  `test_build_conventions`, `test_build_multistage`, `test_build_seeds_keys`, `test_capture_raw`,
  `test_generate_menu`, `test_launch`, `test_layout`, `test_overrides`.
- `contracts/` -- cross-module checks of every shipped bpatcher: `test_module_contracts` (offline route -> attrui ->
  Param wiring from the patch JSON, plus per-pix checks), `test_bench_expect` (the bypass-expectation table), and
  `bench_modules` (live, on the module bench; `--changed` runs only the modules whose patcher changed).
- `modules/<m>/` -- one directory per module with its own verification, moved as-is (mirror extraction is Phase C):
  - `fluid/` -- `fluid_mirror.py` (NumPy mirror of every `f_vf_fluid` stage) + `test_fluid_mirror.py`;
    `bench_fluid.py` (stage codeboxes on the GPU vs the mirror, 100-frame chain, cost) and `bench_fluid_module.py`
    (inside Vsynth's render context: once-per-frame update, two instances, fresh load, tap grid)
  - `caustic/` -- `scatter_mirror.py`, `scatter_truth.py`, `caustic_runner.py`, `test_scatter_mirror.py`,
    `test_scatter_scene.py`, `bench_caustic_codebox.py`, `bench_caustic_sheets.py`
  - `tf_tensormap/ tf_axisflow/ tf_smooth/ tf_glyph/ tf_sharpen/ tf_aniso_blur/ tf_hatch/` -- each holds
    `tf_<m>_mirror.py` (the NumPy mirror of the shader, which the bench imports), `test_tf_<m>.py` (tier-1 tests) and
    `bench_tf_<m>.py` (tier-2 bench). Mirror names carry the module name because every test directory shares one
    import path, so a bare `mirror.py` would collide
- `math/` -- standalone NumPy math tests with no module of their own: `test_conservative_field.py`.
- `records/` -- evidence that `.specify/` and `ideas/` docs cite, not regression gates, matching no default runner
  (a bench among them has `GROUP = "record"` and runs under `--all`):
  - Fluid Phase 0: `bench_fluid_probes.py` (GPU probes), `fluid_feasibility.py` (module-bench feasibility study, no
    assertions), and the separable-DFT pair `fft_separable.py` (NumPy correctness, T1-T3; run with
    `tests/py.sh`, no longer in the offline suite) and `bench_fft.py` (the DFT codeboxes on the GPU). Mutation-checked
    2026-09-22: half-texel sampling offset, unsigned wavenumbers, and wrong inverse sign are each caught. Known weak
    test: `test_projection_random_field_divergence_free` shares `signed_k` with the code under test, so it passes even
    with wrong wavenumbers; the gradient/curl projection test is the one that catches that class of bug (see
    `ideas/ceyron_simulation_scripts_notes.md`, 2026-09-22 addenda). The mirror itself lives in `lib/dft_mirror.py`.
  - Caustic / Lumia research for `ideas/optics_map.md` (2026-10-06): `spike_scatter.py` plus `bench/make_spike_scatter.py`,
    `bench/spike_scatter.jxs` and the `bench/spike_scatter*.maxpat` patchers (GPU point-scatter caustic on the MODULE bench
    with a custom wrapper: identity, orientation flips, float accumulation, truth agreement, density, cost, frame lag;
    stages `s0 s1 s2 s2b s3 s3b`, and from 2026-10-07 `s4` single-mesh cost sweep, `s5` corner-snap equals size 3,
    `s6` fixed n with capture size varied (separates vertex, fill and contention), `s7` coarse capture + upscale
    quality, `s8` lattice jitter, `s9` gobo / source aliasing, `s10` the tone-map + upscale stage, `s11` `detail N`
    equals the explicit parameter messages; timings vary up to 2x between runs, compare within a run);
    `gather_proto.py` (generator and codebox-bench runner for the multi-start gather: compile ladder, size/cost
    measurement, `make_code_fn(..., bil=True)` is the working version; needs `scratch/caustic_fidelity.py` and
    `scratch/multi_guess_gather2.py` as its NumPy mirror and truth); `spike_caustic_res_cost.py`,
    `spike_caustic_trace_vs_jacobian.py`
  - Vector-field and tensor research: `spike_lie_bracket`, `spike_mobius_vecfield_transform`,
    `spike_droste_conformality`, `spike_structure_tensor_range`, `spike_atan2_safety`, `spike_tf_hatch_costshape`
  - Other: `spike_ks_stability`, `spike_lbm_d2q9_architecture`, `spike_a_decorrelate_t7`, `spike_grain_cost`,
    `spike_four_module_cost`
- `templates/bench_module_template.py` -- starting point for a module's bench test.
- `bench/` -- the generated bench patches and their scripts: `make_bench.py` (generates `bench.maxpat` and
  `bench_default.genjit`), `bench.js`, `codeboxes/` (plain GenExpr test codeboxes, including `dft_x/dft_y/dft_param_n`);
  module bench: `make_module_bench.py` (generates `bench_module.maxpat` and `bench_module_empty.maxpat`),
  `bench_module.js`; the spike patchers named above, and `caustic_sheets_standalone.maxpat`. They stay here because
  Max resolves them by bare name from this folder.
- `.state/`, `jobs/`, `logs/` -- generated, gitignored (see below).

## Logs, state and interpreters

- **`tests/logs/`** (gitignored): every `run.sh`, `bench.sh` and `bg.sh` run writes `<timestamp>-<kind>.log` (kinds `offline`,
  `bench`; a `bg.sh` run keeps its own log in `tests/.state/bg/<id>/` and the runs it starts write theirs here). `latest` and
  `latest-<kind>` point at the newest; the newest 20 of each kind are kept. The first line records the Max version, the git
  SHA, whether the tree had uncommitted changes, and the flags, because results depend on all four. `run.sh` also writes a
  per-file timing table and prints the total and the three slowest files.
- **`tests/.state/`** (gitignored, durable): `bench_green.json` (what `--changed` trusts) and `bg/` (background-run state).
  **`tests/jobs/`** is cache only: per-job directories, safe to delete while no run is in flight.
- **`MAX_APP`** (default `/Applications/Max.app`) names the Max install for the log header, the environment hash and the two
  offline tests that read Max-shipped files (`test_jxf`, `test_genjit`); without Max they report SKIPPED with the reason
  instead of passing silently (`harness.skip`).
- **Which interpreter runs what:** `run.sh` and `bench.sh` run everything with `uv run --no-project --with numpy python3`,
  except `benchdeps.py`, which `bench.sh` calls with the bare system `python3`, so it imports only the standard library
  (`test_benchdeps.py` enforces that).
- The generated `bench/job_*.genjit` and `bench/mjob_*.maxpat` stay in `tests/bench/` (gitignored): Max resolves a job's gen
  and a module wrapper by name from the bench patcher's folder.

**Check history** (`tests/lib/checkhist.py`): every `harness.check(label, value, tol)` also appends one JSON line
to `tests/.state/check_results.jsonl` (gitignored, per machine: GPU and Max versions change the numbers), tagged with
run id, kind (offline or bench), git SHA, dirty flag and Max version. `run.sh` and `bench.sh` turn it on through
`tests/_log.sh`; a bare `tests/py.sh` run does not write. The last 30 runs of each kind are kept. Read it with
`python3 tests/lib/checkhist.py report`: each check is judged on its own latest value (if it was seen in the last 10
runs of its kind) and flagged `tight` when it passes but uses at least 50% of its tolerance, or `rising` when it is
more than 2x the median of its earlier runs. Booleans and counts (integer value against an integer tolerance) and
values over tolerance (real failures fail the run; `test_mutations_are_caught` feeds broken code through `check()` on
purpose) are left out. `tests/check.sh full` ends with the one-line summary. Only `check()` calls are recorded, not
plain `assert`s. A failing check is recorded before it raises.

## Quiet mode

`tests/run.sh -q [files]` and `tests/bench.sh -q [flags]` (harness env var `TEST_QUIET=1`) print **one line per test file**
(`ok   test_x.py: 7/7`) and a final verdict. A passing test prints nothing; a failing test prints its whole output and the
traceback. Normal mode is unchanged. Under `bench.sh -q` the full output, passes included, still goes to the log
(`tests/logs/latest-bench`, or `BENCH_LOG`), and the "skip ... unchanged since green" lines collapse to one count.
The exit status is the same in both modes, and it is what decides a green run on record. Prefer `-q` for routine runs.
