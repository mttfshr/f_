"""
bench_vf_advect.py -- f_vf_advect advect stage on the GPU vs its NumPy mirror (tier 2), added with the
Trail control (2026-10-28).  Scope: codebox_advect.gen only, zero flow (a neutral vecfield), so every read is
at a texel centre and the comparison is exact to float32 rounding; flow, edge and gradient behavior stay with
the tier-1 mirror and the module bench.

Needs Max with tests/bench/bench.maxpat open.  Run:  tests/bench.sh tests/modules/vf_advect/bench_vf_advect.py
Every Param is pinned in every job (the bench keeps the last value between jobs).
"""
GROUP = "regression"
ORDER = 66

import numpy as np

import paths as _paths
import benchclient as bc
from gpu_sim import F32
from harness import check, note, run
from vf_advect_mirror import advect_stage

SRC = _paths.REPO / "src" / "f_vf_advect"
N = 64
CODE = (SRC / "codebox_advect.gen").read_text()
PINNED = {"dt": 0.01, "decay": 0.97, "injection": 0.02, "trail": 0.0, "gain": 1.0, "mix_pct": 100.0,
          "bypass_gate": 0.0, "src_vecfield": 1.0}


def gpu(src, vec, prev, **params):
    p = dict(PINNED)
    p.update(params)
    outs, r = bc.run_pass(CODE, [src, vec, prev], dim=(N, N), params=p, all_outputs=True)
    if r["status"] != "ok" or outs is None:
        raise AssertionError(f"advect bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs


def inputs(seed=5):
    rng = np.random.default_rng(seed)
    src = rng.random((N, N, 4)).astype(F32)
    prev = (0.6 * rng.random((N, N, 4))).astype(F32)
    vec = np.zeros((N, N, 4), F32)
    vec[..., :3], vec[..., 3] = 0.5, 1.0
    return src, vec, prev


def test_advect_matches_mirror_with_and_without_trail():
    src, vec, prev = inputs()
    cases = [(0.0, 0.97, 0.02), (0.0, 0.9, 0.05), (0.5, 0.95, 0.04), (1.0, 0.97, 0.02), (23.0, 0.97, 0.02),
             (69.0, 0.5, 0.02), (600.0, 0.5, 0.1), (1000.0, 1.2, 0.2),
             # Decay x Trail: log half-life scale, neutral at 1.0, floor 1 and cap 1000 (exp() on the GPU)
             (100.0, 1.0, 0.02), (100.0, 0.97, 0.02), (100.0, 1.03, 0.02), (300.0, 1.5, 0.02), (50.0, 0.8, 0.02)]
    for trail, decay, inj in cases:
        outs = gpu(src, vec, prev, trail=trail, decay=decay, injection=inj)
        w1, w2, _ = advect_stage(src, vec, prev, decay=decay, injection=inj, trail=trail)
        e1 = float(np.abs(outs[0] - w1).max())
        e2 = float(np.abs(outs[1] - w2).max())
        check(f"trail {trail:g} decay {decay:g} inject {inj:g}: out1 max err vs mirror", e1, 2e-5)
        check(f"trail {trail:g} decay {decay:g} inject {inj:g}: out2 max err vs mirror", e2, 2e-5)


def test_trail_half_life_on_the_gpu():
    src = np.zeros((N, N, 4), F32)
    _, vec, _ = inputs()
    prev = np.full((N, N, 4), 0.8, F32)
    t = 12.0
    state = prev
    for _ in range(int(t)):
        state = gpu(src, vec, state, trail=t, decay=1.0, injection=0.0)[0].astype(F32)
    note("after 12 frames at trail 12, mean of a field that started at 0.8", float(state.mean()))
    check("half after `trail` frames (0.8 -> 0.4)", abs(float(state.mean()) - 0.4), 2e-4)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
