"""
bench_selftest.py -- spec Story 1: the bench proves its own plumbing before
anything it produces is trusted (.specify/test_bench/tasks.md T017-T020,
T022). Needs Max with tests/bench/bench.maxpat open.

Run:  tests/bench.sh tests/bench_selftest.py
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from gpu_sim import grid, jitter_cell
from harness import check, note, run

CB = Path(__file__).resolve().parent / "bench" / "codeboxes"


def cb(name):
    return (CB / f"{name}.gen").read_text()


def rand(h, w, lo=0.0, hi=1.0, seed=0):
    return np.random.default_rng(seed).uniform(lo, hi, (h, w, 4)).astype(np.float32)


def test_1_identity_bitwise():
    """float32 in/out, values outside [0,1]: must survive exactly."""
    x = rand(64, 64, -10, 10, seed=1)
    out, r = bc.run_pass(cb("identity"), [x])
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    check("shape preserved", 0 if out is not None and out.shape == x.shape else 1, 0)
    check("max |out - in|", np.abs(out - x).max(), 0)
    check("bitwise equal", 0 if out.tobytes() == x.tobytes() else 1, 0)


def test_1b_probe_coordinates():
    """norm at texel centers, no row flip, cell == norm*(dim-1), plane order.
    Non-square (64 wide x 32 high) so a width/height swap can't hide."""
    h, w = 32, 64
    out, r = bc.run_pass(cb("probe"), [rand(h, w)])
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    check("output is 32 x 64 (h x w)", 0 if out.shape == (h, w, 4) else 1, 0)
    nx, ny, _, _ = grid(h, w)
    cx, cy = jitter_cell(h, w)
    check("R == norm.x (texel centers)", np.abs(out[..., 0] - nx).max(), 0)
    check("G == norm.y (row 0 = smallest, no flip)", np.abs(out[..., 1] - ny).max(), 0)
    check("B == cell.x == norm.x*(w-1)", np.abs(out[..., 2] - cx).max(), 1e-6)
    check("A == cell.y == norm.y*(h-1)", np.abs(out[..., 3] - cy).max(), 1e-6)
    note("cell.x at column 0 (0 if cell were an integer index)", out[0, 0, 2])


def test_1b_plane_order():
    out, r = bc.run_pass(cb("const"), [rand(16, 16)])
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    check("RGBA == (1,2,3,4) everywhere", np.abs(out - np.array([1, 2, 3, 4], np.float32)).max(), 0)


def test_2_broken_codebox_reports_error():
    out, r = bc.run_pass(cb("broken"), [rand(16, 16)])
    for e in r["errors"]:
        print(f"      error text: {e}")
    check("status error (not ok)", 0 if r["status"] == "error" else 1, 0)
    check("compile error text captured",
          0 if any("codebox" in e for e in r["errors"]) else 1, 0)
    check("no bench.js exception", 0 if not any("bench.js" in e for e in r["errors"]) else 1, 0)


def test_2b_errors_isolated_and_bench_recovers():
    """After a failing job, the next job must be clean and the bench alive."""
    bc.run_pass(cb("broken"), [rand(16, 16)])
    x = rand(16, 16, seed=3)
    out, r = bc.run_pass(cb("identity"), [x])
    check("bench still answers ping", 0 if bc.ping() else 1, 0)
    check("next job status ok", 0 if r["status"] == "ok" else 1, 0)
    check("next job has no leaked errors", len(r["errors"]), 0)
    check("next job output correct", np.abs(out - x).max(), 0)


def test_3_reload_recompiles():
    x = rand(32, 32, seed=4)
    o1, r1 = bc.run_pass(cb("identity"), [x])
    o2, r2 = bc.run_pass(cb("alt"), [x])
    check("identity job exact", np.abs(o1 - x).max(), 0)
    check("following alt job == 2*in (not stale)", np.abs(o2 - 2 * x).max(), 0)


def test_4_two_inputs_physical_cords():
    a, b = rand(32, 32, seed=5), rand(32, 32, seed=6)
    out, r = bc.run_pass(cb("two_input"), [a, b])
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    expect = a + b * np.float32(10)
    note("max |out - in1| (large if in2 arrived)", np.abs(out - a).max())
    check("out == in1 + 10*in2 (rel)", np.abs(out - expect).max() / np.abs(expect).max(), 1e-6)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
