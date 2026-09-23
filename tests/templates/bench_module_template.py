"""
bench_MODULE.py -- Tier 2 verification for f_MODULE: run the module's real
codebox file(s) on the GPU through the Max test bench and check them
numerically. (Template: copy to tests/bench_<module>.py and fill the TODOs.
See .specify/constitution.md "Verification Tiers" and tests/README.md.)

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/bench_<module>.py

Bench coverage: <=3 inputs, all 4 outputs (run_pass(all_outputs=True)),
float32 or char (pix_type=), multi-frame feedback runs (bc.run_temporal),
cost (bc.measure). Multi-stage modules: stage by stage. The shipped
bpatcher's wiring is covered separately by tests/test_module_contracts.py
and tests/bench_modules.py.
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from gpu_sim import grid                 # norm / integer-index grids, bench-verified
from harness import check, note, run

REPO = Path(__file__).resolve().parent.parent
# TODO: the module's real codebox -- test the shipped file, not a copy
CODEBOX = REPO / "src" / "f_MODULE" / "codebox_MAIN.gen"
TOL = 1e-4


def code():
    return CODEBOX.read_text()


def rand(h, w, lo=0.0, hi=1.0, seed=0):
    return np.random.default_rng(seed).uniform(lo, hi, (h, w, 4)).astype(np.float32)


# ---------------------------------------------------------------- reference
# Tier 1: the NumPy mirror, if the math is nontrivial. Either import it from
# tests/test_<module>.py or write it here. It must be checked against
# INDEPENDENT ground truth in its own test (analytic result, np reference
# function), not only against the codebox.

def mirror(rgba, **params):
    raise NotImplementedError("TODO: NumPy mirror of the codebox pass")


# ---------------------------------------------------------------- tests

def test_compiles_and_runs():
    """Cheapest check: loads without Max errors and produces a frame."""
    out, r = bc.run_pass(code(), [rand(64, 64)])
    for e in r["errors"]:
        print(f"      error text: {e}")
    check("status ok (no Max errors)", 0 if r["status"] == "ok" else 1, 0)
    check("output captured", 0 if out is not None else 1, 0)


def test_matches_mirror():
    """TODO: pick inputs that exercise the math (edges, extremes, values
    outside [0,1] if the module is float32), and params that matter."""
    x = rand(64, 64, seed=1)
    params = {}                          # TODO: e.g. {"gain": 2.0}; arrive on frame 3
    out, r = bc.run_pass(code(), [x], params=params)
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    ref = mirror(x, **params)
    check("GPU vs mirror (rel)", np.abs(out - ref).max() / max(np.abs(ref).max(), 1e-12), TOL)


def test_invariants():
    """TODO: properties that must hold regardless of the mirror, e.g.
    bypass=1 returns the input exactly; zero gain is identity; output range;
    symmetry; a round trip. Often catches what a shared-convention mirror
    can't (see tests/README.md, 'Test against independent ground truth')."""
    x = rand(64, 64, seed=2)
    out, _ = bc.run_pass(code(), [x], params={"bypass": 1})
    check("bypass=1 is exact identity", np.abs(out - x).max(), 0)


# Performance (only when cost is a real question: multi-pass, long loops,
# high resolution). Frame time ~= max(CPU overhead, K * pass cost), so a
# per-pass number only exists when the run is gpu_bound -- otherwise you get
# an upper bound.
def test_cost():
    for n in (256, 640):                 # TODO: the resolutions that matter
        r = bc.measure(code(), [rand(n, n)], chain=8)
        check(f"{n}^2 status ok", 0 if r["status"] == "ok" else 1, 0)
        if r["gpu_bound"]:
            note(f"{n}^2 ms per pass", r["ms_per_pass"])
        else:
            note(f"{n}^2 ms per pass (upper bound)", r["ms_per_pass_upper_bound"])


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
