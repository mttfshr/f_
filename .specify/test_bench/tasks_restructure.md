# tests/ restructure: tasks

_Opened 2026-10-18 from a read-only assessment of `tests/` (nothing was run). Decisions are Matt's, same day._

## Decisions

- **Module tests live in `tests/modules/<m>/`**, not in `src/<m>/`, for now. `src/` is build input that `build/`, the drift checker and several skills glob; revisit co-location after Phase B.
- **Audience:** forks / collaborators / CI are not a goal yet. Keep portability cheap (no hardcoded Max path, skip when Max is absent); no CI work now.
- **`f_a_*` in the module bench: XFAIL with a pointer**, using the existing known-issues registry (an XPASS means the entry gets removed). Not excluded.
- **The seven `bench_tf_*` benches join the default regression set.** Taken as implied by "Policy: XFAIL for now"; Matt can veto, it is a one-line list change.
- **Research records move to `tests/records/`** (`.specify/` and `ideas/` docs cite them, so paths must be rewritten, not the files dropped).

## Findings this answers (evidence in the 2026-10-18 chat)

Flat 76-file namespace mixing libraries, offline tests, live benches, build-tool tests and one-off records; README's Files list omits all 14 `f_tf_*` files; 33 files `sys.path.insert`; tf benches `import test_tf_x as m` (mirror lives in a test file); durable `bench_green.json` shares `tests/jobs/` with a cache; `bench_last.log` is overwritten each run and `run.sh` writes no log; `test_jxf` / `test_genjit` need Max installed with no skip; Params persist between bench jobs (found three times: caustic, aniso/sharpen, fluid); the tf benches are in `benchdeps.DATA` but not in `bench.sh DEFAULT`; `bench_modules` is red by a known cause (4 `f_a_decorrelate` errors).

## Phase A: small fixes, no file moves (one session, commit at the end)

- [x] **A1 state / logs.** _(done 2026-10-18, except moving the generated `bench/job_*.genjit` / `mjob_*.maxpat` into `jobs/`: Max resolves them by bare name from the bench patcher's folder, so that needs a `bench.js` / `bench_module.js` change and a live run.)_ `tests/.state/bench_green.json` (durable); `tests/jobs/` becomes cache only; `tests/logs/<timestamp>-<kind>.log` plus a `latest` link, last 20 kept, written by `bench.sh`, `run.sh` and `bg.sh` alike (bg already does this per run). Log header: Max version, git SHA, dirty flag, flags used. Delete the stale `bench_modules_last.log`; send generated `bench/job_*.genjit` and `bench/mjob_*.maxpat` into `jobs/`; update `.gitignore`, `benchdeps.py`, `test_benchdeps.py`, `test_bg.py`.
- [x] **A2 `run.sh`.** _(log, per-file timing, total done 2026-10-18. Serial baseline 68.8 s over 30 files; slowest `test_fluid_mirror` 24.6 s, `test_fft_separable` 13.3 s, `test_bg` 12.4 s. `-j N` NOT added yet: Matt decides, verifying it needs a second full run.)_ Log file, per-file timing, total. Measure the serial baseline first; only then add `-j N` parallel (files are independent).
- [x] **A3 portability-lite.** _(done 2026-10-18; `benchdeps.py` is stdlib-only and runs under the system `python3`, a test enforces it.)_ `MAX_APP` env var (default `/Applications/Max.app`); a `harness.skip(reason)` so `test_jxf` / `test_genjit` skip with a printed reason when Max is absent; check whether `benchdeps.py` needs numpy (it runs under bare system python3 today) and say which interpreter runs what.
- [x] **A4 Param reset.** _(done 2026-10-18: offline tests incl. a mutation check of the checks; live `bench_control.py::test_unsupplied_params_reset_to_their_defaults` passes, and the full default bench run stayed green with it.)_ `benchclient.run_pass` / `measure` / `run_temporal` parse `Param name(default)` from the codebox and send defaults for any param not supplied, which removes the keeps-Params-between-jobs bug class. Mutation-check it. Needs a bench run: ask first.
- [x] **A5 health probe.** _(done 2026-10-18 as `benchclient.ensure_healthy` + `benchclient.py health`; `bench.sh` calls it per codebox-bench file. Exercised offline through the fake-uv glue only; first live use is the next bench run.)_ Move `gather_proto.ensure_healthy` into `benchclient`; `bench.sh` runs it before each file and reopens on a stale image.
- [x] **A6 `f_a_*` XFAIL.** _(done 2026-10-18: three `KNOWN` keys in `bench_modules.py`, the four errors being three distinct messages. Keys copied from the 10-18 log, not yet confirmed live.)_ Add the four `f_a_decorrelate` module-bench errors to the known-issues registry with a pointer to the HANDOFF 2026-10-18 audio entry. Look at how `module_contract.KNOWN_ISSUES` / `bench_modules` key entries first.
- [x] **A7 default set.** _(done 2026-10-18: full default run, 16 files, all green, 389 s; the seven `bench_tf_*` files account for about 110 s of it.)_ Add the seven `bench_tf_*` to `DEFAULT` in `bench.sh`. Measure the added time with one bench run (ask).
- [x] **A8 name lookups.** _(done 2026-10-18: Fluid route tokens come from the definition, `taps` index by name.)_ Tests that pin positional indices of generated structure (`test_build_multistage` Fluid route tokens and taps param index) should look them up by name.

Verify: `tests/run.sh -q` once at the end (same 30 files, same counts). Benches only with Matt's go.

_Verified 2026-10-18: 30 files green, 68.8 s serial. Counts changed only by the new tests: `test_benchclient` +2, `test_benchdeps` +2, `test_bg` +1, `test_harness` +1. One stale assertion (the bench log header, `test_benchdeps`) was updated for the new header._

## Phase B: reorganise (own session, own commit checkpoint, mechanical)

Target (entry scripts stay at `tests/` top level so muscle memory and docs keep working):

    tests/
      run.sh  bench.sh  bg.sh  README.md
      lib/        gpu_sim harness benchclient modulebench module_contract benchdeps genjit jxf patchbuild
      toolchain/  tests of the harness itself + the bench-of-the-bench (control, selftest, perf, temporal)
      build/      tests of build/ tooling + drift_baseline.json
      modules/<m>/  fluid, caustic, tf_tensormap, tf_axisflow, tf_smooth, tf_glyph, tf_sharpen, tf_aniso_blur, tf_hatch
                    (mirror + tier-1 test + tier-2 bench; moved AS-IS first, mirror extraction is Phase C)
      math/       fft_separable, conservative_field
      records/    spike_*, fluid_feasibility, gather_proto, bench_fluid_probes + bench/spike_* patchers
      bench/      generated bench patches, bench.js (stays)
      .state/  jobs/  logs/   (gitignored)

- [ ] **B1 map.** Write the old-path to new-path table once; apply with `git mv` (history kept). Do not hand-edit.
- [ ] **B2 imports.** One mechanism replaces the 33 `sys.path.insert` hacks (runners export `PYTHONPATH` for `lib/` and the subdirs, plus a tiny `_paths` shim so a file still runs standalone). Decide when starting.
- [ ] **B3 discovery.** `run.sh` globs `tests/**/test_*.py`; `benchdeps.DATA` keys become paths; the registration test follows; `bench.sh DEFAULT` becomes a `GROUP = "regression" | "record" | "perf"` declaration per bench file, read via `benchdeps.py list --group`.
- [ ] **B4 references.** Rewrite `tests/...` paths in README, `skills/*/SKILL.md`, `.specify/**` tasks/specs/plans, `docs/f-reference/*`, `ideas/*` (esp. `optics_map.md` and `.specify/f_vf_fluid/` which cite records), `templates/bench_module_template.py`, `build/` scripts that name `tests/drift_baseline.json`, `.gitignore`. Leave historical HANDOFF entries; add one line saying old paths moved. Find them with `grep -rn "tests/" --include=*.md --include=*.py --include=*.sh --include=*.json .`
- [ ] **B5 README.** Replace the hand-kept Files list with the layout above and a one-line description per directory.

- [ ] **B6 demote the FFT Phase 0 pair (Matt, 2026-10-18: yes).** `bench_fft.py` and `test_fft_separable.py` move to `tests/records/` (Phase 0 for `f_vf_fluid`; `bench_fluid` and `test_fluid_mirror` now cover the shipped stages). Before moving, check what else depends on them so coverage is not lost silently: importers (`grep -rn "bench_fft\|test_fft_separable\|dft_x\|dft_y" .`), `bench_perf`'s DFT-cost case and the `bench/codeboxes/dft_*` files it may share, `benchdeps._MACHINERY` / `DATA`, the `fft` entry in `bench.sh DEFAULT` (drops out of the regression set, i.e. out of A7's list), and the "mutation-checked" notes in the README Files list (move them into `records/README`). If `test_fft_separable` is the only place something is asserted (README names a gradient/curl projection test that catches wrong wavenumbers), confirm `test_fluid_mirror` has an equivalent before it leaves the offline suite. Run the offline suite afterwards: the file count drops by one and that is expected.

Verify: offline suite green with the same file and test counts (minus the demoted `test_fft_separable`); `tests/bench.sh --list` shows the same set (plus the tf benches, minus `fft`); one full bench run, ask first.

## Phase C: later, not scheduled

- Extract the mirror functions out of the `test_tf_*` files into `modules/<m>/mirror.py` (benches stop importing a test file).
- A shared `tf` helper for the tensor encode / run / diff skeleton (small gain: text overlap between the benches is only 13-21 lines).
- `check()` results to a JSONL so measured errors and tolerance headroom can be tracked over time.
- `tests/check.sh quick|full` (before commit / before release).
- CI for the pure-offline tier, once A3 skips exist (audience decision above: not yet).
- Revisit `src/<m>/` co-location.
- (Decided, see B6.) `bench_fft` + `test_fft_separable` are demoted to records.
