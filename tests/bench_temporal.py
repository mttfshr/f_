"""
bench_temporal.py -- E4: multi-frame runs with feedback on the Max test bench
(.specify/test_bench/tasks_extensions.md T131-T132). Needs Max with
tests/bench/bench.maxpat open.

Feedback = Pattern 1 (state pix + identity pass pix), one-frame delay: step s
reads step s-1's output; step 1 reads the initial state. Checked against
closed forms, including an exact step counter (catches off-by-one stepping).

Run:  tests/bench.sh tests/bench_temporal.py
"""
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run

F32 = np.float32


def rand(n, lo=0.0, hi=1.0, seed=0):
    return np.random.default_rng(seed).uniform(lo, hi, (n, n, 4)).astype(F32)


def test_step_counter_exact():
    """T131 gate (frame-exact stepping): out = state + 1/64 must give exactly
    init + s/64 at step s -- any skipped or doubled frame shows up."""
    x, init = rand(32, seed=1), rand(32, 0, 0.5, seed=2)
    steps = [1, 2, 3, 5, 10, 20]
    frames, r = bc.run_temporal("out1 = in2 + 1.0 / 64.0;", [x, init], steps)
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    for s in steps:
        expect = init + F32(s) / F32(64)
        check(f"step {s:2d} == init + {s}/64", np.abs(frames[s][0] - expect).max(), 1e-6)


def test_decay_accumulator_closed_form():
    """state_s = 0.5 * state_{s-1} + 0.25 * x  =>  0.5^s init + 0.5 x (1 - 0.5^s)."""
    x, init = rand(32, seed=3), rand(32, seed=4)
    steps = [1, 2, 4, 8, 16]
    frames, r = bc.run_temporal("out1 = in2 * 0.5 + in1 * 0.25;", [x, init], steps)
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    for s in steps:
        h = F32(0.5) ** s
        expect = h * init + F32(0.5) * x * (F32(1) - h)
        check(f"step {s:2d} closed form", np.abs(frames[s][0] - expect).max(), 1e-6)


def test_route_out2_to_in3():
    """Other routing: second outlet feeds back into the third input; out1 is an
    independent passthrough that must be unaffected."""
    x, dummy, init = rand(32, seed=5), rand(32, seed=6), rand(32, 0, 0.5, seed=7)
    steps = [1, 4, 9]
    code = "out1 = in1;\nout2 = in3 + 1.0 / 32.0;"
    frames, r = bc.run_temporal(code, [x, dummy, init], steps, feedback=(2, 3))
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    for s in steps:
        check(f"step {s} out2 == init + {s}/32", np.abs(frames[s][1] - (init + F32(s) / F32(32))).max(), 1e-6)
        check(f"step {s} out1 == in1 (untouched)", np.abs(frames[s][0] - x).max(), 0)


def test_char_feedback_quantizes_each_step():
    """char state: each step re-quantizes (round, clamp -- E2 finding), so
    +0.4/255 per step never accumulates, while +1/255 does."""
    init = np.round(rand(16, 0, 0.5, seed=8) * 255) / 255
    x = rand(16, seed=9)
    frames, r = bc.run_temporal("out1 = in2 + 1.0 / 255.0;", [x, init.astype(F32)], [1, 6], pix_type="char")
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    check("char +1/255 accumulates: step 6 == init + 6/255",
          np.abs(frames[6][0] - (init + 6 / 255)).max(), 1e-6)
    frames, r = bc.run_temporal("out1 = in2 + 0.4 / 255.0;", [x, init.astype(F32)], [6], pix_type="char")
    note("char +0.4/255 per step, max drift after 6 steps (x255)", np.abs(frames[6][0] - init).max() * 255)
    check("char +0.4/255 never accumulates (rounds away each step)", np.abs(frames[6][0] - init).max(), 1e-6)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
