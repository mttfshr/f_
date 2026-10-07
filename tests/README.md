# tests/

Math-first tests for codebox algorithms, run in NumPy before anything is
patched in Max. Motivation: a scratch patch tests two things at once (is the
math right? does Max/GPU run it?) and failures can't be attributed. Settle the
math here; the scratch patch then answers only "does known-correct code compile
and run fast enough."

## Two layers

- **Math tests** (`tests/test_*.py`, `tests/run.sh`) — NumPy only, run
  anywhere. Settle the math before Max is involved.
- **Bench tests** (`tests/bench_*.py`, `tests/bench.sh`) — run codeboxes on
  the GPU in a live Max through the test bench and diff the results against
  the NumPy mirrors. Spec/plan/tasks: `.specify/test_bench/`.

## Run

    tests/run.sh                              # every tests/test_*.py
    tests/run.sh tests/test_fft_separable.py  # one file
    tests/bench.sh                            # regression set (needs the bench open)
    tests/bench.sh --changed                  # only files whose inputs changed since their last green run
    tests/bench.sh --slow                     # the regression set plus its @slow tests
    tests/bench.sh --all                      # every bench_*.py, incl. perf and probes, and slow tests
    tests/bench.sh --list                     # show what would run (no Max needed)
    tests/bench.sh tests/bench_fft.py         # one file

The regression set is the `DEFAULT` list at the top of `tests/bench.sh`. It
leaves out `bench_perf.py` (fps-based checks that can fail on a busy machine
without a regression) and `bench_fluid_probes.py` (a Phase 0 record of
bench-verified facts); `--all` adds them.

`--changed` (`tests/benchdeps.py`) skips a bench file whose Python imports, data files and environment
(Max and Vsynth versions) equal those of its last green run, and says why; `bench_modules` runs only the
modules whose patcher changed (`BENCH_MODULES`). The record is `tests/jobs/bench_green.json` (local,
gitignored): a passing file is recorded, a failing one is forgotten, so any plain `tests/bench.sh` run
seeds it. A new `tests/bench_*.py` must be registered in `benchdeps.DATA` (a test enforces it). It does
not see the GPU driver, macOS, or what else is open in Max, so run without `--changed` before a release.

**Background runs** (`tests/bg.sh`): `start [offline|bench|all]` returns at once and runs detached;
`status` (exit 0 passed, 1 failed, 2 running, 3 none), `log`, `stop`, `list`. One bench run at a time (a
lock); an offline run may overlap anything; `bench` defaults to `--changed`; a macOS notification when it
finishes. Logs are in `tests/jobs/bg/` (gitignored). A bench run needs Max up with the bench open, else it
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
newest `JOBS_KEEP` = 50 and prunes older ones, since a job dir can hold 100+ MB).
All bench logic is in `tests/bench/bench.js`; the patch is only objects and wiring.

**Per session:** open Max, open `tests/bench/bench.maxpat` once (or, with
Max already running, `benchclient.reopen()` does it). `tests/bench.sh`
fails fast with "bench not reachable" if it isn't open. Full output of the
last bench run is always in `tests/jobs/bench_last.log`.

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
  (`gather_proto.ensure_healthy` does this and reopens). `measure` readings
  under the empty-pass floor (~2.1-2.5 ms per frame here) are upper bounds.

## The module bench (shipped bpatchers)

A second generated patch, `tests/bench/bench_module.maxpat` (ports
7473/7474), runs **shipped** `f_` bpatchers inside Vsynth's real `vs_render`
context. **Close Vsynth performance patches while it's open** — it creates
the global `vsynth` context. `tests/bench_modules.py` loads each module (a
fresh bench session per module), feeds it textures, sends every route
parameter as a control message and reads the attribute back off the inner
pix, exercises bypass (documented control message and the jsui), and
captures every outlet. `tests/test_module_contracts.py` is its offline half:
static route → attrui → Param wiring from the patch JSON, no Max needed.
Both keep a registry of known issues (reported XFAIL with a pointer; a fixed
one reports XPASS so the entry gets removed). Run both after changing any
shipped bpatcher. Debugging hooks: `/probe` and a localhost-only `/eval`
(`modulebench.bench_eval(js)`), which run inside the module bench.

Open Max with `bench.maxpat` for `tests/bench.sh`. `bench_modules.py` and
`bench_fluid_module.py` open `bench_module.maxpat` themselves, so close Vsynth
performance patches before running them.

**Adding a bench test for a module:** copy `tests/templates/bench_module_template.py` to `tests/bench_<module>.py`, point `CODEBOX` at the module's real `src/<module>/codebox_*.gen`, fill in the mirror/invariants, and add it to `DEFAULT` in `tests/bench.sh` once it is a regression gate. Which tests a module needs is decided per module (constitution: Verification Tiers).

**Writing a bench codebox:** plain GenExpr text (see `bench/codeboxes/`).
Up to 3 inputs (`in1..in3`); `Param` values arrive on frame 3. Remember the
bench-verified facts: `cell` is `norm * (dim - 1)`, not an integer — use
`floor(norm.x * dim.x)` (see the `jit-gen-codebox` skill's Bench-Verified
Facts section).

## Files

- `gpu_sim.py` -- jit.gl.pix execution-model emulation (grid, sampling, storage)
- `harness.py` -- minimal runner
- `test_fft_separable.py` -- separable-DFT FFT plan, T1-T3 correctness
  (see `ideas/ceyron_simulation_scripts_notes.md`, 2026-09-22 addenda).
  Mutation-checked 2026-09-22: half-texel sampling offset, unsigned
  wavenumbers, and wrong inverse sign are each caught. Known weak test:
  `test_projection_random_field_divergence_free` shares `signed_k` with the
  code under test, so it passes even with wrong wavenumbers; the
  gradient/curl projection test is the one that catches that class of bug.
- `jxf.py` -- Jitter `.jxf` read/write <-> RGBA float32 (format decoded from
  a Max-shipped file; conventions bench-verified)
- `genjit.py` -- codebox text -> `.genjit` gen patcher
- `benchclient.py` -- bench client: OSC, jobs, `run_pass`, `measure`, `reopen`
- `test_jxf.py`, `test_genjit.py`, `test_benchclient.py` -- offline checks of
  the bench toolchain (against Max-shipped files / OSC spec bytes)
- `bench.sh` -- runs the bench regression set (`--all` for every `bench_*.py`)
- `bench_control.py` -- control loop (ping, /busy, error reporting)
- `bench_selftest.py` -- the bench's own plumbing: identity, coordinate
  probe, plane order, compile-error capture, reload, two inputs
- `bench_fft.py` -- FFT T1/T2 on the GPU vs NumPy (`dft_x`/`dft_y` codeboxes)
- `bench_perf.py` -- rate control, scaling, repeatability, DFT cost
- `bench_temporal.py` -- E4 feedback runs: step counter, accumulator, routing, char
- `fluid_mirror.py` + `test_fluid_mirror.py` -- NumPy mirror of every
  `f_vf_fluid` stage and its offline tests
- `bench_fluid.py` -- `f_vf_fluid` stage codeboxes on the GPU vs the mirror,
  100-frame chain, cost (regression set)
- `bench_fluid_module.py` -- `f_vf_fluid` inside Vsynth's render context:
  once-per-frame update, two instances, fresh load, tap grid (regression set)
- Records, kept because `.specify/f_vf_fluid/` cites them as evidence, not
  regression gates: `bench_fluid_probes.py` (Phase 0 GPU probes; run with
  `--all`) and `fluid_feasibility.py` (Phase 0 module-bench feasibility
  study, no assertions, matches no runner)
- Records for `ideas/optics_map.md` (the caustic / Lumia research, 2026-10-06),
  not regression gates, matching no runner: `spike_scatter.py` plus
  `bench/make_spike_scatter.py`, `bench/spike_scatter.jxs`,
  `bench/spike_scatter.maxpat` and `bench/spike_scatter_chain.maxpat`
  (GPU point-scatter caustic on the MODULE bench with a custom wrapper:
  identity, orientation flips, float accumulation, truth agreement, density,
  cost, frame lag; stages `s0 s1 s2 s2b s3 s3b`, and from 2026-10-07 `s4` (single-mesh
  cost sweep), `s5` (corner-snap equals size 3), `s6` (fixed n, capture size varied: separates
  vertex, fill and contention), `s7` (coarse capture + upscale quality), `s8` (lattice jitter),
  `s9` (gobo / source aliasing), `s10` (the tone-map + upscale stage behind the scatter, `spike_scatter_tone.maxpat`), `s11` (`detail N` equals the explicit parameter messages); timings vary up to 2x between runs, compare within a run), and `gather_proto.py`
  (generator and CODEBOX-bench runner for the multi-start gather: compile
  ladder, size/cost measurement, `make_code_fn(..., bil=True)` is the working
  version; needs `scratch/caustic_fidelity.py` and
  `scratch/multi_guess_gather2.py` as its NumPy mirror and truth, which are
  tracked in `scratch/` since 2026-10-07)
- `bg.sh` + `test_bg.py` -- the background runner (start, status, log, stop, list; lock; fake-command tests)
- `benchdeps.py` + `test_benchdeps.py` -- what `bench.sh --changed` runs (input hashing, decision table, record)
- `test_harness.py` -- the runner's `@slow` marker (skipped by default, skip printed by name)
- `module_contract.py` + `test_module_contracts.py` -- offline wiring
  contracts of every shipped bpatcher: route -> attrui -> Param wiring, plus
  per-pix checks on every stage (each codebox Param is driven and read, a
  codebox-less pix is a pure identity pass, every gen in/out has a cord).
  Known issues live in `KNOWN_ISSUES` with a pointer each (XFAIL; a fixed one
  reports XPASS). Replaced `build/audit_interface.py`.
- `drift.py` (in `build/`) + `test_drift.py` + `drift_baseline.json` -- the
  definition.py ratchet: every shipped patcher is rebuilt from its definition
  in memory and compared with the shipped file. A module must reproduce
  exactly unless it is in the baseline, which may only shrink (drift growing,
  shrinking without the baseline being lowered, or a module that now
  reproduces all fail the test). Rewrite the baseline with
  `python3 tests/test_drift.py --write-baseline`. See `build/spec.md`,
  "Source of Truth and Drift".
- `modulebench.py` + `bench_modules.py` -- live module contracts (module bench)
- `templates/bench_module_template.py` -- starting point for a module's bench test
- `bench/` -- `make_bench.py` (generates `bench.maxpat` and
  `bench_default.genjit`), `bench.js`, `codeboxes/`; module bench:
  `make_module_bench.py` (generates `bench_module.maxpat` and
  `bench_module_empty.maxpat`), `bench_module.js`
