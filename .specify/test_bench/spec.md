# Max Test Bench — Spec

**Created**: 2026-09-22
**Status**: Implemented 2026-09-22 (all 34 tasks; as-built revisions in plan.md)

## Purpose

Proofs of concept in `f_` stall at the same point: every experiment needs a
hand-built scratch patch, and a scratch patch tests two things at once —
*is the math right?* and *does Max/GPU run it?* — so failures can't be
attributed (the `f_vf_advect` confinement saga, `f_apollonian`'s stale
compile state, `f_a_ripple`'s screenshot misreadings).

The two questions are now split. **Math** is settled in NumPy first
(`tests/`, see `tests/README.md` — `test_fft_separable.py` is the first
user). **Execution** is this bench: one reusable Max patch that runs a
known-correct codebox and reports back numbers, driven from the terminal so
the whole loop (write codebox → NumPy test → Max run → numeric diff) can run
from Desktop Commander without per-experiment patching.

Infrastructure, not a module. Not registered in `f_modules`, not shipped in
`package/`. Lives in `tests/` alongside the NumPy side.

## Background

- Borrows conventions from Cycling '74's `max-test` package
  (github.com/Cycling74/max-test, MIT): self-starting/self-terminating test
  patches, assertions, remote control over OSC. The package itself is not
  used — aging (no releases, externals must be compiled, Ruby runner broken
  on modern Ruby, runner always exits 0), and message/MSP-domain only, with
  no Jitter/GL coverage. Its console-error check turned out to be Max's
  native `error` object, which this bench uses directly.
- Discussion: `ideas/ceyron_simulation_scripts_notes.md`, 2026-09-22 addenda.

## Decisions already made (from discussion)

- **Bench stays open, triggered remotely.** Matt opens Max and the bench
  once per session; runs are triggered over OSC/UDP. No Max relaunch per test.
- **Python owns the knowledge, Max only executes.** Inputs, reference
  outputs, and pass/fail judgement live on the Python side. The bench is a
  dumb runner with no per-test logic.
- **Correctness mode is one pass per job.** Multi-pass algorithms run pass
  by pass, each output feeding the next job, so a numeric failure points at
  one pass. Chained multi-pass runs are for performance measurement only.
- **Float32-exact transfer** of inputs and outputs (Jitter `.jxf`), never
  8-bit image formats.

---

## User Stories

### User Story 1 — Bench self-verification (Priority: P1)

Before the bench is trusted for anything, it proves its own plumbing: data
goes in and comes out unchanged, errors surface instead of rendering
silently black, and a changed codebox actually recompiles.

**Why this priority**: every later result depends on this. The library's
history is full of results that looked confirmed and weren't — the bench
must not become another source of those.

**Independent Test**: run the three self-test jobs (identity, broken,
reload) and inspect the reports.

**Acceptance Scenarios**:
1. **Given** an identity codebox (`out1 = in1`) and a float32 input with
   values outside [0,1] and fine structure, **When** the job runs, **Then**
   the captured output equals the input exactly (bitwise, float32), with no
   flip, offset, or clamping.
2. **Given** a codebox with a deliberate compile error, **When** the job
   runs, **Then** the report contains the error text and status `error` —
   not a black frame reported as success.
3. **Given** two consecutive jobs with different codeboxes, **When** the
   second runs, **Then** its output reflects the second codebox, not stale
   state from the first.
4. **Given** the identity result, **When** compared with `tests/gpu_sim.py`'s
   conventions, **Then** the sim's y-orientation convention is confirmed or
   corrected to match Jitter.

### User Story 2 — Correctness run of one pass (Priority: P1)

A single codebox pass runs against given float32 inputs at a chosen
internal resolution, and the output is compared numerically against the
NumPy mirror of the same pass.

**Why this priority**: this is the actual job the bench exists for. The
FFT T1 question (does a fixed 128-iteration loop compile and match NumPy)
is the first real use.

**Independent Test**: run the separable-DFT row pass at N=128 and diff
against `test_fft_separable.py`'s `pass_dft` output.

**Acceptance Scenarios**:
1. **Given** a codebox, input files, a resolution, and param values,
   **When** the job is triggered from the terminal, **Then** a report comes
   back with status, captured output file, and any errors.
2. **Given** the captured output, **When** the Python side diffs it against
   the NumPy reference, **Then** it prints measured error against a
   tolerance, same style as `tests/harness.py`.
3. **Given** a job whose codebox compiles but produces wrong numbers,
   **When** diffed, **Then** the failure is reported with measured error,
   distinguishable from a compile/run failure.
4. **Given** a multi-pass algorithm, **When** run pass by pass, **Then**
   each pass's output can be fed as the next pass's input without leaving
   the terminal.

### User Story 3 — Performance measurement (Priority: P2)

A stage (or K chained copies of it) runs for a sustained period at a
chosen resolution and the bench reports frame rate.

**Why this priority**: several open architecture questions are cost
questions (separable DFT vs. Stockham vs. Jacobi iteration counts, 128² vs.
256²). Needed soon, but correctness comes first.

**Independent Test**: run the identity codebox chained K=1 and K=8 and
confirm the fps figures differ plausibly and repeat within tolerance.

**Acceptance Scenarios**:
1. **Given** a stage, a chain length K, and a resolution, **When** a
   performance job runs, **Then** the report includes a frame rate measured
   after warm-up, excluding compile time.
2. **Given** the same job run twice, **When** reports are compared,
   **Then** fps agrees within 10%.

### User Story 4 — Agent-driven loop (Priority: P2)

Claude can run the full loop — generate job, trigger, wait, read report,
diff — through Desktop Commander, with Matt's only involvement being that
Max and the bench are open.

**Why this priority**: removes the per-experiment wiring/screenshot
bottleneck. Depends on Stories 1–2 working first.

**Independent Test**: a single terminal command runs a named test end to
end and exits nonzero on failure.

**Acceptance Scenarios**:
1. **Given** Max and the bench are open, **When** a test command runs,
   **Then** it completes without any manual action in Max.
2. **Given** Max or the bench is not open, **When** a test command runs,
   **Then** it fails fast with a clear "bench not reachable" message.
3. **Given** a job that hangs, **When** the timeout elapses, **Then** the
   command reports a timeout and the bench is ready for the next job.

---

## Requirements

### Functional Requirements

- **FR-001**: The bench MUST accept a job describing: codebox source,
  input files (up to 3), output resolution, output type (float32 or char),
  param values, warm-up frame count, and mode (correctness / performance).
- **FR-002**: The bench MUST load the job's codebox into its pass without
  hand-editing the patch.
- **FR-003**: The bench MUST run at the job's resolution independent of any
  window or Vsynth render size.
- **FR-004**: In correctness mode the bench MUST capture one output frame
  after warm-up as float32 without loss.
- **FR-005**: The bench MUST capture every Max error posted during the job
  and include them in the report.
- **FR-006**: The bench MUST write a machine-readable report (status,
  errors, fps if measured, output path) and signal completion.
- **FR-007**: In performance mode the bench MUST run a stage chained K
  times and report frame rate measured after warm-up.
- **FR-008**: The Python side MUST write inputs and read outputs in the
  bench's file format, float32-exact.
- **FR-009**: The Python side MUST enforce a per-job timeout and a
  reachability check.
- **FR-010**: Test results MUST print measured error values, not just
  pass/fail (consistent with `tests/harness.py`).
- **FR-011**: The bench MUST reset between jobs so no state (textures,
  compiled code, params) leaks from one job to the next.

### Non-Functional Requirements

- **NF-001**: No compiled externals and no dependencies beyond Max itself
  and the existing `tests/` toolchain (Python via `uv`).
- **NF-002**: A correctness job at 256² SHOULD complete in under 5 seconds
  wall time, excluding first-run compile.
- **NF-003**: The bench patch is hand-built or generated once and then
  treated as stable infrastructure; per-test changes happen only in job
  files.
- **NF-004**: The bench MUST NOT touch `package/` or any shipped module.

---

## Success Criteria

1. All three self-tests (Story 1) pass on first trusted run, with their
   evidence recorded.
2. FFT T1 (separable-DFT row pass, N=128) runs through the bench and its
   output is diffed against NumPy with a printed error figure — the first
   real question answered without a hand-built scratch patch.
3. A new proof-of-concept codebox goes from written to Max-verified with
   zero patch edits.
4. Matt's per-session involvement is limited to opening Max and the bench.

---

## Edge Cases

- Codebox compiles but outputs black (e.g. a known silent-failure
  pattern from the `jit-gen-codebox` skill) → correctness diff must catch
  it; no Max error will fire.
- Gen compile errors may not reach the `error` object at all → self-test 2
  decides; if they don't, the plan needs another detection route.
- Loop too long for the GPU compiler (unrolling / instruction limits) →
  may appear as an error, a black frame, or a hang; all three must be
  reported distinctly.
- Job triggered while a previous job is still running → rejected or
  queued, never interleaved.
- Input resolution differs from job resolution → explicit, not silently
  resampled (correctness diffs assume exact texel alignment).
- Max window closed, bench closed, or UDP port in use → reachability check
  fails with a clear message.
- First run after opening pays compile cost → warm-up frames absorb it;
  performance numbers exclude it.

---

## Out of Scope (This Version)

- Running inside Vsynth's render context or through real bpatchers
  (module-level integration testing).
- Visual/perceptual judgement — the bench reports numbers only.
- Audio (`gen~`) testing, though the same pattern could extend there later.
- CI or unattended runs without Max already open.
- A GenExpr-to-NumPy interpreter (possible later step, see `tests/README.md`
  discussion).

## Open Questions (for plan / self-tests)

- Texture → float32 matrix readback path (`jit.gl.asyncread` reads the
  context and is likely 8-bit; a float32 `jit.matrix` receiving the texture
  is believed to work — unverified).
- Whether gen compile errors reach the `error` object.
- `.jxf` read/write from Python (documented binary chunk format; needs a
  small parser/writer).
- GL context: the bench's own small `jit.world`, visible window acceptable.
- fps measurement method (world timing vs. `cpuclock` deltas).
- Whether `jit.gl.pix`'s `gen` attribute reloads reliably per job or the
  pass object needs recreating (bears on FR-011 / self-test 3).
