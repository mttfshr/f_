"""
bench_vf_erode_cost.py -- the 1080p cost probe for f_vf_erode (plan NF-102, T065; Matt's go 2026-11-10).

NOT a gate and NOT the real stages: the four codeboxes in probe/ have the planned read pattern and similar arithmetic
(transport = 15 reads, react = 11, hold = 1, enc = 4) and are not checked against the mirror. The result bounds what the
real stages will cost, to decide whether the layers can run at the render size (spec FR-111) or need a fixed solver grid.
The atlas is 1920 x 2160 float32 (two RGBA planes, plan ADR-1). Rows marked UPPER BOUND sit at the bench floor (about 0.2 ms).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/vf_erode/bench_vf_erode_cost.py
"""
GROUP = "record"
ORDER = 90

import sys

import paths as _paths
import numpy as np

import benchclient as bc
from harness import note, run

PROBE = _paths.REPO / "tests" / "modules" / "vf_erode" / "probe"
W, H = 1920, 1080
rng = np.random.default_rng(1)


def code(name):
    return (PROBE / f"probe_{name}.gen").read_text()


def stage_cost(name, inputs, dim, params=None):
    for chain in (8, 16, 32):
        r = bc.measure(code(name), inputs, dim=dim, chain=chain, params=params or {})
        if r.get("gpu_bound"):
            return r["ms_per_pass"], chain, True
    return r.get("ms_per_pass_upper_bound", float("nan")), chain, False


def test_cost_per_stage_and_total_at_1080p():
    atlas = rng.uniform(0.0, 1.0, (2 * H, W, 4)).astype(np.float32)
    terrain = rng.uniform(0.0, 1.0, (H, W, 4)).astype(np.float32)
    field = rng.uniform(0.3, 0.7, (H, W, 4)).astype(np.float32)
    P = {"flow": 0.4, "push": 1.0, "speed": 1.0}
    rows = {}

    def row(label, name, inputs, dim, params):
        ms, chain, bound = stage_cost(name, inputs, dim, params)
        rows[label] = ms
        print(f"    ...  {label:34s} {ms:7.3f} ms/pass  (chain {chain}, {'GPU bound' if bound else 'UPPER BOUND, not resolved'})")

    row("hold (atlas, identity)", "hold", [atlas], (W, 2 * H), None)
    row("transport (atlas, 15 reads)", "transport", [atlas, terrain, field], (W, 2 * H), P)
    row("react (atlas, 11 reads)", "react", [atlas, terrain, field], (W, 2 * H),
        {**P, "lift": 0.9, "settle": 0.004, "dry": 0.0016})
    row("enc (1920x1080)", "enc", [atlas, terrain, field], (W, H), {"polarity": 0.0})
    total = sum(rows.values())
    print(f"    ...  TOTAL, one solver step per frame at 1920x1080: {total:.3f} ms/frame (a load stage, about hold's cost, is not in it)")
    note("total at 1080p, one step per frame (ms): recorded for Matt's call on render size (T065)", total)
    note("per extra solver step per frame (transport + react, ms)", rows["transport (atlas, 15 reads)"] + rows["react (atlas, 11 reads)"])


if __name__ == "__main__":
    sys.exit(run(globals()))
