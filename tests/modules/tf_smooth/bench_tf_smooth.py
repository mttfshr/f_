"""
bench_tf_smooth.py -- Tier 2 verification for f_tf_smooth: the real codeboxes
(src/f_tf_smooth/codebox_state.gen, codebox_render.gen) run on the GPU
through the Max test bench and are diffed against the NumPy mirror in
tests/modules/tf_smooth/test_tf_smooth.py. Feedback is driven with bc.run_temporal (identity
pass pix feeding the state pix's in2, the f_vf_advect two-domain pattern).
Tasks T012-T014.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/tf_smooth/bench_tf_smooth.py   (ASK FIRST)
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 120

import paths as _paths
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
import test_tf_smooth as m          # the tier-1 mirror

REPO = _paths.REPO
SRC = REPO / "src" / "f_tf_smooth"
STATE = SRC / "codebox_state.gen"
RENDER = SRC / "codebox_render.gen"
F32 = np.float32
TOL = 1e-6
N = 32


def state_code():
    return STATE.read_text()


def render_code():
    return RENDER.read_text()


def rand_rgba(h, w, lo=0.0, hi=1.0, seed=0):
    x = np.random.default_rng(seed).uniform(lo, hi, (h, w, 4)).astype(F32)
    x[..., 3] = 1.0
    return x


def ok(r):
    check("status ok", 0 if r["status"] == "ok" else 1, 0)


# ------------------------------------------------------------ T012: compile + frame-boundary round-trip

def test_compiles_and_runs():
    """Cheapest check: the state codebox loads without Max errors and the
    render passthrough is an exact identity."""
    x = rand_rgba(N, N, seed=1)
    out, r = bc.run_pass(state_code(), [x, x])
    ok(r)
    check("state output captured", 0 if out is not None else 1, 0)
    r_out, r = bc.run_pass(render_code(), [x])
    ok(r)
    check("render is exact identity (abs)", float(np.abs(r_out - x).max()), 0.0)


def test_frame_boundary_unbounded_round_trip():
    """ADR-3 proof (tasks T012): the state carries an unbounded tensor
    (Jxx-strength 4.0) across a frame boundary and comes back unclamped:
    state starts at A, then the input goes to B -> out = A*release, exactly
    a round-tripped value, not a re-clamped one.

    E4 convention (bench.js loadInputs: one upload per slot, no per-step
    swap): the story runs as two chained jobs -- job 1 renders with state A
    and in1 B (out = A*(1-r) + B*r ... the blend already exercises the
    round-trip of A's out-of-range values through write+read), job 2 seeds
    the state with job 1's output and renders with in1 = 0 (a zero frame):
    out == (job1 out) * release, unclamped."""
    a = np.zeros((N, N, 4), F32); a[..., 0] = 4.0; a[..., 1] = 0.5; a[..., 2] = 0.1; a[..., 3] = 1.0
    b = rand_rgba(N, N, 0.0, 0.02, seed=2)          # ~zero tensor with A=1
    zero = np.zeros((N, N, 4), F32)
    for release in (0.3, 0.5, 0.9):
        # E4 wiring (bench.js): initial state -> in2, feedback copies out1 -> in2
        # one frame later; in1 = this frame's tensor. The state codebox computes
        # out = release*in2 + (1-release)*in1 (mix(prev, new, 1-r)).
        frames, r = bc.run_temporal(state_code(), [b, a], [1],
                                    params={"release": release})
        ok(r)
        exp1 = (a * F32(release) + b * F32(1 - release)).astype(F32)
        check(f"r={release} out == A*r + B*(1-r) (abs)",
              float(np.abs(frames[1][0] - exp1).max()), TOL)
        check(f"r={release} values above 1.0 survive the state write+read (no clamp)",
              0 if frames[1][0][..., 0].max() > 1.0 else 1, 0)
        frames2, r = bc.run_temporal(state_code(), [zero, frames[1][0]], [1],
                                     params={"release": release})
        ok(r)
        exp2 = frames[1][0] * F32(release)          # in1 = 0: out = r * state
        check(f"r={release} state round-trip: out == state*r, unclamped (abs)",
              float(np.abs(frames2[1][0] - exp2).max()), TOL)


# ------------------------------------------------------------ T013: recurrence vs mirror

def test_recurrence_matches_mirror_over_frames():
    """5 frames of alternating input vs the tier-1 mirror; also release 0 is
    exact GPU passthrough.

    run_temporal convention (bench.js loadInputs, one upload per slot):
    in1 is the SAME texture every step -- there is no per-step input swap in
    E4. The step-wise story the module exists for (a changing world) is
    therefore driven from the PYTHON side here by one temporal run per input
    frame, state carried through by feedback, each compared frame by frame:
    run A: steps 1-5 with in1 = f0 (state evolves under a fixed input);
    then a second run whose in1 = f1 and whose INITIAL state is run A's
    final state fed as inputs[1]: the mirror's sequence. The GPU identity of
    the state read-back closes the chain: exp(s) from the mirror."""
    rng = np.random.default_rng(5)
    frames_in = [rand_rgba(N, N, 0.0, 3.0, seed=10 + i) for i in range(5)]
    init = rand_rgba(N, N, 0.0, 3.0, seed=20)
    for release in (0.0, 0.3, 0.5, 0.9):
        # every input in turn, the state chaining through feedback: one
        # run_temporal per input frame (E4's in1 is constant per job -- no
        # per-step texture swap exists; bench.js loadInputs, one upload/slot)
        state = init
        for i, f1 in enumerate(frames_in):
            frames, r = bc.run_temporal(state_code(), [f1, state], [1],
                                        params={"release": release})
            ok(r)
            outs = m.run_sequence([f1], release, init=state)
            step = frames[1][0]
            worst = float(np.abs(step - outs[0]).max())
            note(f"release {release} step in1=f{i} GPU-vs-mirror (abs)", worst)
            check(f"release {release} frame {i} GPU vs mirror (abs)", worst, TOL)
            if release == 0.0:
                check(f"release 0 frame {i}: out == in1 exactly (abs)",
                      float(np.abs(step - f1).max()), 0.0)
            state = frames[1][0]


def test_render_chain_matches_state_output():
    """state -> render passthrough must equal the state pix's own output
    (the module outlet is fed through the render node)."""
    x = rand_rgba(N, N, 0.0, 3.0, seed=7)
    init = rand_rgba(N, N, seed=8)
    state_out, r = bc.run_pass(state_code(), [x, init], params={"release": 0.5})
    ok(r)
    chain_out, r = bc.run_pass(render_code(), [state_out])
    ok(r)
    check("render(state_out) == state_out (abs)",
          float(np.abs(chain_out - state_out).max()), 0.0)


def test_bypass_is_exact_passthrough_on_gpu():
    """ADR-4 on the GPU: bypass=1, dirty state, two chained runs whose in1
    changes -> each run's output == its own input bitwise, so the state does
    NOT freeze the output at step1's scene. (E4 has no per-step input swap;
    the two frames of the story are two chained jobs with the second started
    from the first's ending state.)"""
    init = rand_rgba(N, N, 0.0, 3.0, seed=9)
    f1 = rand_rgba(N, N, 0.0, 3.0, seed=11)
    f2 = rand_rgba(N, N, 0.0, 3.0, seed=12)
    frames, r = bc.run_temporal(state_code(), [f1, init], [1, 2],
                                params={"release": 0.7, "bypass_gate": 1.0})
    ok(r)
    check("bypass step1 == input (abs)", float(np.abs(frames[1][0] - f1).max()), 0.0)
    check("bypass step2 == input still (not frozen at step1) (abs)",
          float(np.abs(frames[2][0] - f1).max()), 0.0)
    # second job: in1 = f2, state = the first job's final state (dirty)
    frames2, r = bc.run_temporal(state_code(), [f2, frames[2][0]], [1],
                                 params={"release": 0.7, "bypass_gate": 1.0})
    ok(r)
    check("bypass new in1 shows through dirty state (abs)",
          float(np.abs(frames2[1][0] - f2).max()), 0.0)


# ------------------------------------------------------------ cost (tasks.md note: measure once)

def test_cost():
    """One feedback tap, no loops: cost should be the bench frame floor.
    Report per the tensormap T016 convention (upper bounds where CPU-bound)."""
    x = rand_rgba(640, 480, seed=3)
    r = bc.measure(state_code(), [x, x], chain=8)
    check("cost status ok", 0 if r["status"] == "ok" else 1, 0)
    if r["gpu_bound"]:
        note("1080p-ish 640x480 ms per pass", r["ms_per_pass"])
    else:
        note("640x480 ms per pass (upper bound)", r["ms_per_pass_upper_bound"])


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))