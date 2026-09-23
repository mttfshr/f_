# Tasks: Max Test Bench

**Spec**: `.specify/test_bench/spec.md`
**Plan**: `.specify/test_bench/plan.md`
**Build order**: Sequential. Complete each phase before the next.
**Commits**: After each phase checkpoint.

---

## Expected Output Layout

```
tests/
  jxf.py, genjit.py, benchclient.py      — Phase 0
  test_jxf.py, test_genjit.py,
  test_benchclient.py                    — Phase 0
  bench.sh                               — Phase 1
  bench_selftest.py                      — Phase 2
  bench_fft.py                           — Phase 3
  bench_perf.py                          — Phase 4
  bench/
    make_bench.py, bench.maxpat,
    bench.js                             — Phase 1 (extended in 2, 4)
    codeboxes/identity.gen, probe.gen,
      const.gen, broken.gen, alt.gen     — Phase 2
    codeboxes/dft_x.gen                  — Phase 3
  jobs/                                  — runtime, gitignored (Phase 0)
```

---

## Phase 0: Offline toolchain — no Max (BLOCKING)

**Purpose:** Everything that can be verified without Max, verified first.

- [x] T001 Add `tests/jobs/` and `tests/bench/job_*.genjit` to `.gitignore`
- [x] T002 Write `tests/jxf.py`: `write_jxf(path, rgba)` / `read_jxf(path)`
  for `FL32` 4-plane matrices per plan's decoded format; also read
  `LONG`/`CHAR` for the format check. Keep plane-order and row-order
  conversion in two clearly named functions with a `PROVISIONAL` comment —
  resolved in T021.
- [x] T003 Write `tests/test_jxf.py`: write→read round trip is bitwise exact;
  parsing `/Applications/Max.app/Contents/Resources/C74/help/jitter/matrix1.jxf`
  yields type LONG, 2 planes, dims 320×240, and a chunk-size check that
  matches file size. Mutation-check once (e.g. flip endianness → test fails).
  Done 2026-09-22. Mutation-checked: little-endian reader → Max-file cell check fails (6.7e7 off).
- [x] T004 Write `tests/genjit.py`: `make_genjit(codebox_text, n_inputs,
  n_outputs) -> dict` producing a gen patcher with `in 1..n`, one codebox,
  `out 1..m`, wired. Standalone; don't import `build/build_patcher.py`.
- [x] T005 Write `tests/test_genjit.py`: generated JSON has the same
  top-level structure/keys as a shipped example
  (`Examples/jitter-examples/gen/pinch.genjit`), codebox text embedded
  verbatim, inlet/outlet counts and patchlines correct.
- [x] T006 Write OSC encode/decode (string args only) in
  `tests/benchclient.py`, plus `tests/test_benchclient.py` round-tripping
  `/ping`, `/run <path with spaces>`, `/done <id>`.
- [x] T007 Run `tests/run.sh`; all offline tests plus existing
  `test_fft_separable.py` pass.
  Done 2026-09-22: 21/21 offline (test_benchclient 3, test_fft_separable 9, test_genjit 3, test_jxf 6).

**Checkpoint:** offline toolchain green. → Commit. → Phase 1.

---

## Phase 1: Bench patch + JS, reachability (BLOCKING)

⚠️ First phase needing Max. Matt opens the bench; everything else is driven
from the terminal.

- [x] T008 Write `tests/bench/bench.js` skeleton: `/ping` → reply `/pong`;
  `/run <dir>` → read `job.json`, reply `/busy` if a job is active, else
  (for now) write a stub `result.json` with `status: ok` and reply `/done`.
- [x] T009 Write `tests/bench/make_bench.py` generating `bench.maxpat`:
  `udpreceive 7471` → `js bench.js`; `js` → `udpsend 127.0.0.1 7472`;
  `error` → `js`; `jit.world bench_ctx` (small, visible) draw bang → `js`;
  input chain ×3 (`jit.matrix bench_inN @type float32 @planecount 4` →
  `jit.gl.texture bench_texN @type float32 @drawto bench_ctx`); 8
  `jit.gl.pix bench_p1..8 @drawto bench_ctx @adapt 0 @type float32` in
  series with in2/in3 fan-out; capture tap `bench_p1` → gate →
  `jit.matrix bench_out @type float32`. Scripting names on everything
  `bench.js` addresses.
  Done 2026-09-22: 23 boxes, 19 lines. **Design change found while writing:** `jit.gl.pix`'s `inputs` attribute is read-only (follows the loaded gen code), so only inlet 0 of each slot is wired; inputs 2–3 are delivered by `bench.js` via `activeinput` (to implement in T014, verify with a 2-input codebox). `gen`-dependent inlet counts would otherwise delete cords on every 1-input job.
- [x] T010 Generate `bench.maxpat`. **Matt:** open it in Max; confirm it
  loads with a clean console and the world window appears. Note any object
  errors here.
  2026-09-22: opened in Matt's running Max session via `open -a Max` (Claude, with the session live). Loads and runs — every Phase 1 check passes through it, so the JS, udp objects, world and draw-bang path all instantiated. **Confirmed by Matt:** Max console clean at load — no object or patchline errors.
- [x] T011 Implement `ping()` and the `/run` round trip in
  `benchclient.py`, with reachability timeout (1 s) and per-job timeout.
- [x] T012 Write `tests/bench.sh` (runs `tests/bench_*.py` via `uv`).
- [x] T013 Verify from the terminal: ping succeeds with the bench open; a
  stub `/run` round-trips; with the bench closed, ping fails fast with
  "bench not reachable"; a second `/run` during an active job gets `/busy`.
  Done 2026-09-22, `tests/bench_control.py` 5/5: ping; stub round trip; frames reach `bench.js` during a job; second `/run` refused with `/busy`, first completes, refused job writes nothing; missing `job.json` → `status: error` naming the file. Bench-closed case: `tests/bench.sh` failed fast in 1.4 s with the "bench not reachable" message, exit 2. **Finding:** 177 draw bangs in 1.5 s (~118 fps) with `jit.world @enable 1` and default `fps 30` — the world is running display-synced (likely displaylink on a 120 Hz display), not at the `fps` attribute. Phase 4 must set rate control explicitly (T027).

**Checkpoint:** terminal ↔ bench control loop works with no manual action
in Max. → Commit. → Phase 2.

---

## Phase 2: Self-verification — spec Story 1 (BLOCKING)

⚠️ Nothing produced by the bench is trusted until this phase passes.

- [x] T014 Implement the correctness path in `bench.js`: set `gen`, `dim`,
  `type`, params on `bench_p1`; bypass slots 2–8; `read` inputs into
  `bench_inN`; enable `error` listening and collect errors; count draw
  bangs; after `warmup`, open the capture gate for one frame; `write
  out.jxf`; write `result.json`; reply `/done`. Watchdog → `stalled`.
  Done 2026-09-22. As built: inputs reach the pix by **physical cords** (not `activeinput` — see T018/ADR-6 rev.); the pix re-renders every frame on its own, inputs are set once when their matrices are banged at job start. Handlers wrapped so JS exceptions become job errors.
- [x] T015 Implement `run_pass()` in `benchclient.py`: creates the job dir,
  writes inputs + `job_<id>.genjit` + `job.json`, triggers, waits, reads
  `result.json` and `out.jxf`, deletes the job's `.genjit`.
  Done. `.genjit` cleanup changed: the just-loaded file is kept and older ones deleted after the next job — deleting the *loaded* file made Max try to reload it ("could not find gen patcher"), an error that could land in the next job's report. Also added `benchclient.reopen()` + a `/close` bench command, so a regenerated `bench.maxpat` can be reloaded without manual steps.
- [x] T016 Write codeboxes: `identity.gen` (`out1 = in1;`), `probe.gen`
  (`out1 = vec(norm.x, norm.y, cell.x, cell.y);`), `const.gen`
  (`out1 = vec(1, 2, 3, 4);`), `broken.gen` (deliberate compile error),
  `alt.gen` (`out1 = in1 * 2;`).
  Done, plus `two_input.gen` (`out1 = in1 + in2 * 10;`) to verify the second-input path.
- [x] T017 **Self-test 1 — identity:** 64×64 input with values in
  [-10, 10] and per-texel unique structure. Output must equal input
  bitwise. If it doesn't: record whether it's clamping (readback not truly
  float32), flip/offset, or plane scramble — do not proceed until exact.
  **PASS** — 64×64, values in [-10, 10]: bitwise exact. Max-written `out.jxf` is `FL32` with a header byte-identical to `write_jxf`'s.
- [x] T018 **Self-test 1b — probe + const:** check `norm = (cell + 0.5)/dim`
  exactly; find which matrix row holds `norm.y ≈ 0`; from `const`, find
  which plane holds R/G/B/A.
  **PASS, with one real finding.** Planes are ARGB (const → raw `[4,1,2,3]`); no row flip (`norm.y` smallest at matrix row 0); `norm = (i+0.5)/dim` exactly; non-square 64×32 correct (no w/h swap). **Finding: GenExpr `cell` on jit.gl.pix is NOT an integer index — it is `norm * (dim - 1)`** (0.492, 1.477, … at dim 64; exact to float32 across the frame). Integer index = `floor(norm * dim)`. This invalidated the planned FFT codebox's `switch(cell < N*0.5, …)` signed-wavenumber line before it was written — corrected in the ceyron notes and `test_fft_separable.py`.
- [x] T019 **DECISION GATE — error capture:** run `broken.gen`. Does the
  gen compile error reach `error`? If yes → `status: error` with text,
  done. If no → implement the plan's fallback detection
  (`getparamlist` / `full_source_code` after load, or empty-compile
  heuristic) and document which signal is actually reliable. Record the
  exact console text either way.
  **DECIDED: yes, compile errors reach `[error]`** — text `codebox: addition op missing argument`, status `error`. **Real bug found and fixed on the way:** wiring `[error]` straight into `js` made js re-report the incoming error, `[error]` caught that, and it recursed into a Max stack overflow ("outlets are disabled until this message is cleared") — which froze the whole bench (frames stopped, no `/done`, no ping). Matt cleared the flag. Fix: `[error] → [deferlow] → [prepend bench_error] → js`, a reentrancy-guarded, capped, never-throwing `bench_error()` handler, and try/catch around all handlers. Verified: failing job → next job clean (no leaked errors), bench still answers.
- [x] T020 **DECISION GATE — reload:** run `identity` then `alt` in
  consecutive jobs. Second output must be 2× input. If stale: try ADR-3
  fallbacks in order (`file` absolute path → `compile` after `gen` →
  scripted recreation); record which works and update ADR-3.
  **DECIDED: primary ADR-3 approach works, no fallback needed** — identity then `alt` in consecutive jobs: second output exactly 2× input. Unique-name `.genjit` + `gen` recompiles immediately.
- [x] T021 Bake T018's findings into `jxf.py` (remove `PROVISIONAL`, cite
  the probe) and, if they differ from the sim, into `gpu_sim.py`'s
  documented conventions. Re-run `tests/run.sh` — math tests still pass.
  Done: `jxf.py` PROVISIONAL removed with evidence cited; `gpu_sim.py` conventions documented as bench-verified, `grid()`'s indices relabeled as integer indices (not `cell`), new `jitter_cell()` reproduces Jitter's `cell`. `tests/run.sh` still green.
- [x] T022 Write `tests/bench_selftest.py` encoding T017–T020 as repeatable
  checks with printed measurements.
  Done: `tests/bench_selftest.py` 7/7 (identity, probe incl. non-square, plane order, broken → error, error isolation + recovery, reload, two inputs). With `bench_control.py`: 12/12 via `tests/bench.sh`. **Two-input path took three attempts:** `activeinput N` + `jit_gl_texture` (landed on input 0 — output was exactly `in2 + (0,0,0,10)`), then `sendinput N jit_gl_texture` (input stayed default), then the structural fix: every bench `.genjit` carries `in 1..3` (`make_genjit(min_inputs=3)`) and slots start from a committed 3-input `bench_default.genjit`, so inlet counts never change and inputs 2–3 are plain physical cords.

**Checkpoint:** all four self-tests pass from `tests/bench.sh`, evidence
recorded in this file. → Commit. → Phase 3.

---

## Phase 3: FFT T1 through the bench — spec Story 2

- [x] T023 Translate `test_fft_separable.pass_dft` (axis x) into
  `codeboxes/dft_x.gen`, N as a hard constant (128), carrying the three
  findings: `nearest()` at texel centers, `mod(k*n, N)` before scaling to
  an angle, signed index via `switch`. Health-check against the
  `jit-gen-codebox` checklist (inline component access, no stored-vector
  `.x`, etc.).
  Done 2026-09-22: `tests/bench/codeboxes/dft_x.gen`, plus `dft_y.gen` (not planned — cheap, and it lets T2's full 2D forward/round trip run on the GPU too). Uses `floor(norm.x * N)` for the bin index per the Phase 2 `cell` finding; `Param inverse(0)` selects direction and 1/N scale. Compiled clean on first load.
- [x] T024 Write `tests/bench_fft.py`: same input as the NumPy test, run
  `dft_x.gen` at 128², diff against `pass_dft` output and against
  `np.fft.fft`; print errors with `harness.check`.
  Done: `tests/bench_fft.py` (5 tests).
- [x] T025 Run it. Record the outcome — any of these is a real T1 answer:
  matches within tolerance / compiles but numerically off (by how much) /
  compile error (text) / black output / stall. If precision is off, note
  the naive-vs-reduced angle comparison on real GPU `sin`.
  **T1 ANSWERED: yes.** A fixed 128-iteration loop with 4 `nearest()` reads per iteration compiles in `jit.gl.pix` and matches NumPy: GPU vs float32 mirror 7.3e-8 rel; vs `np.fft.fft` 4.8e-7 (u) / 4.6e-7 (v) — same accuracy class as NumPy's own float32 mirror. Also: 1D forward+inverse via the `inverse` Param 3.0e-6 abs (proves Param delivery); **full 2D forward vs `np.fft.fft2` 1.0e-7 / 2.0e-7 rel, 2D round trip 4.2e-6 / 4.8e-6 abs** (T2 on the GPU). Angle reduction on real GPU sin/cos: naive 8.0e-6 vs reduced 6.8e-7 at N=256 — ~12× better, same ratio as NumPy predicted; keep the `mod`.
- [x] T026 If T025 passes at 128: repeat at 256 (N constant changed). If it
  fails at 128 on a compile/loop limit: try N=64 to bracket the limit.
  N=256: 9.9e-8 vs mirror, 7.1e-7 vs `np.fft`. Bracketed further: **N=512 also compiles and matches (1.0e-6)** — no loop/compile limit in sight at the resolutions this is for. 1024 deliberately not tried (~4G texture reads/frame, risk of stalling the GPU mid-session).

**Checkpoint:** FFT T1 answered with numbers, no hand-built scratch patch.
→ Commit. → Phase 4.

---

## Phase 4: Performance mode — spec Story 3

- [x] T027 Implement perf path in `bench.js`: world `sync 0` + high `fps`
  for the job (restored afterward); enable slots 1..K, bypass rest; warmup;
  time `frames` draw bangs; then a K=0 baseline; report both.
  Done 2026-09-22. Rate control = world `displaylink 0` + `sync 0` + `fps 1000` for the job, restored after (verified: ~388 fps during, back to display-synced ~119 after). Throughput ceiling with no GPU work is ~300–600 fps (Max per-frame overhead ~2–3.5 ms; baseline varies run to run by up to ~2×, so it's only used to classify runs, not subtracted). **Two bugs found and fixed on the way:** (1) params sent with `gen` raced the new gen's compile ("invalid message inverse") — a new gen compiles at its first *render*, and the draw bang precedes the render, so params now go out at frame 3 (both modes; capture/measure start after); (2) an interim per-frame "kick" (js re-sending `bench_tex1` to slot 1) doubled downstream work — every texture message triggers a render — and was removed. Added `bench_src` (identity pix before slot 1) so slot 1 is fed exactly like slots 2..K.
- [x] T028 Implement `measure()` in `benchclient.py`; write
  `tests/bench_perf.py`.
  Done: `benchclient.measure()` + `tests/bench_perf.py` (4 tests). **Measurement model corrected mid-phase:** frame time ≈ max(CPU overhead, K × pass cost) — CPU/GPU overlap — not overhead + K × cost. An early reading of the numbers as "slot 1 re-emits a cached result" was wrong; a decisive test (8000-iteration sin loop at 512², ~9 ms GPU) gave K=1 8.8 ms, K=2 17.3 ms: slot 1 recomputes every frame, cost is linear once GPU-bound. So: `ms_per_pass = frame_ms / K` only when `gpu_bound` (fps < 0.75 × baseline); otherwise an upper bound `frame_ms_k0 / K`. The plan's baseline-subtraction formula was dropped.
- [x] T029 Verify: identity at K=1 vs K=8; repeat each twice — agree
  within 10%.
  **PASS.** Heavy codebox K=1 9.19 ms → K=2 17.02 ms (ratio 1.85, within tolerance of linear). Repeats 8.55 / 8.62 ms (0.9% apart; spec asks ≤10%). Identity K=1 vs K=8 is NOT a meaningful test — identity is far below the overhead, so fps is overhead noise; replaced by the heavy-codebox scaling test.
- [x] T030 Measure `dft_x.gen` at 128² and 256² (K=1 and K=4, i.e. one full
  2D round trip's worth of passes). Record fps against the K=0 baseline.
  **Results — DFT pass cost (K=8 chains, 2026-09-22, this Mac):** N=512: **2.96 ms/pass** (GPU-bound) → a 2D FFT round trip (4 passes) ≈ **11.9 ms**. N=256: below resolution, **< 0.51 ms/pass** → round trip < 2.0 ms. N=128: < 0.48 ms/pass → round trip < 1.9 ms (both limited by the bench's overhead, not the GPU; true cost likely far lower — the loop work scales N³, so 256 ≈ 512/8 ≈ 0.37 ms/pass by extrapolation). Conclusion: at the 128–256² velocity-grid resolutions this was always meant for, a full FFT round trip per frame is comfortably real-time; 512² is possible but eats most of a 60 fps frame budget.
  **Open intermittent:** one `ERROR` in `bench_control.py::test_frames_arrive_during_job` in the first full-suite run of this phase; not reproduced in 3 further full runs + 3 standalone; traceback lost to output filtering. `tests/bench.sh` now always writes full output to `tests/jobs/bench_last.log` so the next occurrence is diagnosable.

**Checkpoint:** fps numbers for the FFT candidate recorded. → Commit.

---

## Phase 5: Records

- [x] T031 `tests/README.md`: bench section (how to open, `bench.sh`, job
  format pointer, what status `ok` does and doesn't mean).
  Done 2026-09-22: `tests/README.md` now documents both layers (math / bench), per-session setup, `reopen()`, don't-edit-the-generated-patch, what `ok`/`error`/`stalled` mean, `run_pass`/`measure` semantics incl. the overlap caveat, and the full file list.

- [x] T032 `jit-gen-codebox` skill: empirically verified `norm`/`cell`
  conventions, error-capture behavior, loop-length compile result.
  Done: new "Bench-Verified Facts (2026-09-22)" section + corrected `cell` line + a checklist item, applied to BOTH copies (`f_/skills/` and `claude-scaffold/skills/`). Found the two copies have diverged in both directions — reconciliation left as a loose thread in HANDOFF (not in this spec's scope).

- [x] T033 `ideas/ceyron_simulation_scripts_notes.md`: FFT status update
  with T025/T030 numbers; whether the Jacobi comparison is still needed.
  Done during Phases 3–4 (T1/T2 results, cost table, Jacobi now looks unnecessary, `cell` correction).

- [x] T034 HANDOFF entry.
  Done: HANDOFF rewritten for this session; `f_a_ripple`'s open "start here" items carried forward.
