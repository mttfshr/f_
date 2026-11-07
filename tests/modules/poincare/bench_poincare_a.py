"""
bench_poincare_a.py -- f_poincare mode A, tier 2 (tasks.md T011): the real codebox src/f_poincare/codebox_poincare_a.gen run on
the GPU through the codebox bench and diffed against the NumPy mirror (poincare_mirror.render_a), plus the invariants a mirror
that shares the code's conventions could not catch (guards, outside the disk, bypass).

The first input is a ramp, R = u, G = v, B = u v (u, v = norm of the input), so the sampled colour IS the settled position and one
comparison checks the settled position and the sampled colour together.

THRESHOLDS, written before the first run and not to be loosened to make a failure pass (spec acceptance; the old debug_ok passed
only after 0.01 -> 0.3). Mechanism of the tolerance: the fold makes the sample coordinate jump between neighbouring pixels, and
the hardware sample() then reads nearest-like (jit-gen-codebox, 2026-10-06), so the colour can be off by up to half a texel of the
256-wide ramp (0.002) plus 8-bit interpolation weights; one texel (1/256 = 3.9e-3) is the colour tolerance. The float32 NumPy mirror
agreed with the float64 one to 2.4e-5 at r < 0.97 (offline, 2026-11-06), so arithmetic is not the budget. A pixel within float
rounding of a mirror circle can take the other branch on the GPU and land a whole cell away: that is why the criterion is a
FRACTION of pixels, and the fractions are:
    r < 0.30 : >= 99.9% of pixels within TOL_COLOR      r < 0.90 : >= 99.9%      r < 0.97 : >= 99%
Pixels at r >= 0.97 are not compared (the float32 rim is T032); r >= 1 must be exactly black.

Every job pins every Param (the bench keeps a Param's last value between jobs: bench-test-authoring #2).
Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/poincare/bench_poincare_a.py        (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 67             # integers only; 66 is bench_vf_stamp_module, 70 is bench_modules

import paths as _paths
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run

import poincare_mirror as m

CODE = (_paths.REPO / "src" / "f_poincare" / "codebox_poincare_a.gen").read_text()
PINNED = dict(p_sides=4.0, q_vertex=5.0, tile_scale=0.26, iterations=32.0, rim_fade=0.99,
              width=256.0, height=256.0, bypass_gate=0.0)
CASES = {                     # label: (params, (H, W))
    "{4,5} defaults": ({}, (256, 256)),
    "{4,6}": (dict(q_vertex=6.0, tile_scale=0.3178), (256, 256)),
    "{4,7}": (dict(q_vertex=7.0, tile_scale=0.4), (256, 256)),
    "{5,4} live p": (dict(p_sides=5.0, q_vertex=4.0, tile_scale=0.3), (256, 256)),
    "{3,7} live p": (dict(p_sides=3.0, q_vertex=7.0, tile_scale=0.3), (256, 256)),
    "{4,5} at 16 iterations": (dict(iterations=16.0), (256, 256)),
    "{4,5} wide frame 256x144": (dict(width=256.0, height=144.0), (144, 256)),
}
TOL_COLOR = 1.0 / 256.0
FRACTIONS = ((0.30, 0.999), (0.90, 0.999), (0.97, 0.99))


def ramp(h, w):
    nx, ny = m.norm_grid(h, w, np.float32)
    return np.stack([nx, ny, nx * ny, np.ones_like(nx)], -1).astype(np.float32)


def gpu(params, hw=(256, 256)):
    h, w = hw
    p = {**PINNED, **params}
    if hw != (256, 256):
        p.update(width=float(w), height=float(h))
    outs, r = bc.run_pass(CODE, [ramp(h, w)], dim=(w, h), params=p, timeout_ms=30000, all_outputs=True)
    if r["status"] != "ok" or outs[0] is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs[0]


def mirror(params, hw=(256, 256)):
    h, w = hw
    p = {**PINNED, **params}
    nx, ny = m.norm_grid(h, w)
    return m.render_a(nx, ny, p["p_sides"], p["q_vertex"], p["tile_scale"], p["iterations"], p["rim_fade"], aspect=w / h)


def test_compiles_and_runs():
    out = gpu({})
    check("output finite", 0 if np.isfinite(out).all() else 1, 0)
    assert float(out[..., :3].std()) > 1e-2, "output is flat"
    check("alpha is 1 everywhere", float(np.abs(out[..., 3] - 1.0).max()), 0.0)
    print(f"    ok   finite, std {float(out[..., :3].std()):.3f}, alpha 1")


def test_matches_mirror():
    for label, (params, hw) in CASES.items():
        out = gpu(params, hw)
        want, _, rr = mirror(params, hw)
        err = np.abs(out[..., :3].astype(np.float64) - want).max(-1)
        for rmax, need in FRACTIONS:
            sel = rr < rmax
            frac = float((err[sel] <= TOL_COLOR).mean())
            note(f"[{label}] r<{rmax}: fraction within {TOL_COLOR:.1e}", frac)
            assert frac >= need, f"[{label}] r<{rmax}: {frac:.5f} of pixels within tolerance, need {need}"
        print(f"    ok   [{label}] fractions within tolerance meet {FRACTIONS}")


def test_outside_the_disk_is_black():
    out = gpu({})
    _, _, rr = mirror({})
    check("r >= 1 is exactly black", float(np.abs(out[rr >= 1.0][:, :3]).max()), 0.0)


def test_guards_round_and_clamp():
    ref = gpu(dict(q_vertex=5.0))
    check("q = 3 is raised to q = 5 at p = 4", float(np.abs(gpu(dict(q_vertex=3.0)) - ref).max()), 0.0)
    check("q = 5.4 rounds to 5", float(np.abs(gpu(dict(q_vertex=5.4)) - ref).max()), 0.0)
    check("p = 4.4 rounds to 4", float(np.abs(gpu(dict(p_sides=4.4)) - ref).max()), 0.0)
    p3 = gpu(dict(p_sides=3.0, q_vertex=7.0, tile_scale=0.3))
    check("p = 2 clamps to p = 3", float(np.abs(gpu(dict(p_sides=2.0, q_vertex=7.0, tile_scale=0.3)) - p3).max()), 0.0)


def test_bypass_is_the_first_inlet_exactly():
    out = gpu(dict(bypass_gate=1.0))
    check("bypass_gate 1 equals the first inlet", float(np.abs(out - ramp(256, 256)).max()), 1e-6)


if __name__ == "__main__":
    sys.exit(run(globals()))
