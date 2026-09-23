# HANDOFF

_Session: 2026-09-22_

## What happened

Started as a design question — does the September 2026 Navier–Stokes
Millennium result change the viscous-fluid shader ideas? — and turned into
building testing infrastructure for the whole library.

**Navier–Stokes: no change.** The result (OpenAI's claimed finite-time
blowup for 3D NS, Clay still lists the problem active) is a blowup proof,
not a solver; it's 3D-only (2D NS has been known smooth since the 1960s);
and grids can't represent the singular data anyway. Recorded in
`ideas/ceyron_simulation_scripts_notes.md`, which also got a scoped **"rung
2"** option: `f_vf_advect` has no velocity state, so viscosity has nothing
to act on — self-advected velocity + explicit diffusion (≈ viscous Burgers)
is a cheap middle rung between today's module and full Stam.

**FFT thread, answered.** Reframes: velocity doesn't need render resolution
(128–256² is standard), and "~40 passes" was one implementation — a
*separable DFT* is 4 passes, each a fixed-count loop. Math verified in NumPy
first (new `tests/`), then on the GPU through the new bench: row pass and
full 2D FFT match `np.fft` to ~1e-7; N=128/256/512 all compile; cost 2.96
ms/pass at 512², below the bench's resolution (< 0.5 ms) at 128–256². A full
FFT round trip per frame is real-time at the resolutions it's for, which
makes the planned Jacobi comparison look unnecessary.

**New infrastructure: two test layers** (Matt's prompt: stop getting bogged
down building a patcher wrapper for every proof of concept).
- **`tests/` math layer** — NumPy mirror of the jit.gl.pix execution model
  (`gpu_sim.py`); codebox passes mirrored pass-for-pass, float32,
  mutation-checked. `tests/run.sh`.
- **Max test bench** — spec/plan/tasks in `.specify/test_bench/`, all 5
  phases done. One generated patch (`tests/bench/bench.maxpat`) stays open;
  Python drives it over OSC and swaps float32 `.jxf` files;
  `benchclient.run_pass()` / `measure()`. `tests/bench.sh` 21/21. Found
  `Cycling74/max-test` (Matt) and borrowed its conventions rather than the
  package (aging, no Jitter coverage).

**Real findings the bench produced** (all in the `jit-gen-codebox` skill's
new "Bench-Verified Facts" section, in both the `f_` and `claude-scaffold`
copies):
- **GenExpr `cell` on jit.gl.pix is `norm * (dim - 1)`, not an integer
  index** — caught by the coordinate probe *before* the FFT codebox was
  written (the plan had used `cell` as the bin index). Integer index =
  `floor(norm * dim)`.
- Gen compile errors are catchable via `[error]` — but a direct
  `[error] → js` wire recursed into a Max stack overflow that disabled every
  outlet in Max (Matt cleared it). Fixed with `deferlow` + `prepend`.
- jit.gl.pix inlet count follows the gen patcher's `in` objects; messages
  to the pix land on input 0 regardless of `activeinput`; a new gen compiles
  at its first render (params sent earlier fail); every received texture
  triggers a render.
- Performance: CPU/GPU overlap — frame ≈ max(overhead, K × pass cost). An
  early "cached re-emit" reading of the numbers was wrong and corrected by a
  decisive heavy-shader test.

## Done

- `ideas/ceyron_simulation_scripts_notes.md`: rung-2 addendum, FFT dive,
  bench results (T1/T2 on GPU, cost), `cell` correction.
- `tests/`: math layer (`gpu_sim.py`, `harness.py`, `test_fft_separable.py`,
  `run.sh`) + bench toolchain (`jxf.py`, `genjit.py`, `benchclient.py`,
  offline tests) + bench tests (`bench_control/selftest/fft/perf.py`,
  `bench.sh`) + `bench/` (generator, `bench.js`, codeboxes incl.
  `dft_x.gen`/`dft_y.gen`). `tests/README.md` documents both layers.
- `.specify/test_bench/{spec,plan,tasks}.md` — all 34 tasks done, with the
  as-built revisions recorded in plan ADRs.
- `.gitignore`: `tests/jobs/`, `tests/bench/job_*.genjit`.
- Skill: `jit-gen-codebox` Bench-Verified Facts (both copies).

**Nothing committed yet.** The working tree also holds changes from before
this session (`README.md`, `docs/vsynth-reference/module-inventory.md`,
`package/demos/sampleplatter.maxpat`, `skills/vsynth-bpatcher/SKILL.md`,
untracked `docs/f-reference/module-inventory.md`, `scratch/`) — stage this
session's files by name.

## Next session — start here

Two open threads; pick one:

**1. Fluid work, now unblocked.** Write the spectral pass codebox
(diffusion + projection, math already verified in `test_fft_separable.py`)
and verify it on the bench — that completes a GPU-verified FFT fluid step
except for advection. Then an architecture discussion: rung 2 vs full
spectral Stam as a module; internal-resolution resampling in a real
bpatcher (`@adapt 0` + `@dim` — bench confirms `dim` works on the pix,
untested inside Vsynth); the torus (wraparound boundary) decision.

**2. `f_a_ripple` production UI polish** — carried forward unchanged from
the 2026-09-15/16 session: DSP done and confirmed by ear; UI still plain
flonums/toggles, not the `f_` convention. `ideas/f_a_build_process.md` has
the reuse analysis. Then Phase 5 (docs/helpfile). Its loose ends
(`carrier_phase` random not wired; modulated-band loop still fixed at 200
iterations; T7b/T8 unstarted, not blocking) are unchanged — see git history
of this file (2026-09-16 entry) for the detail.

## Loose threads

- **Two `jit-gen-codebox` skill copies have diverged both ways** (the `f_`
  and `claude-scaffold` copies each have sections the other lacks — e.g. the
  "`Param` named after a built-in operator" entry exists only in the
  scaffold copy). Needs a reconciliation pass. The skill uploaded to
  claude.ai is a third copy — re-upload after reconciling.
- **Bench intermittent:** one unexplained `ERROR` in
  `bench_control.py::test_frames_arrive_during_job` (first full run of
  Phase 4 only; six reruns clean). `tests/jobs/bench_last.log` now keeps
  full output for next time.
- `bench_src` (identity pix before slot 1) is kept but not proven
  necessary — see `make_bench.py` comment.
- Other tools could use the bench beyond fluids: any `f_` codebox can now be
  verified numerically without a scratch patch (e.g. re-verifying the
  UNVERIFIED `f_vf_vorticity`, or tracing `f_apollonian`'s `debug_ok`).
