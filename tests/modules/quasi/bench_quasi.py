"""
bench_quasi.py -- f_quasi tier 2 (tasks.md T006a): the real codebox file src/f_quasi/codebox_quasi.gen run on the GPU
through the codebox bench and diffed against the NumPy mirror (quasi_mirror.render), plus the invariants a mirror
that shares the code's conventions could not catch.

The codebox is a stateless generator, one pass, three outlets: banded look, bounded gradient vecfield, potential.
Every job pins every Param (the bench keeps a Param's last value between jobs: bench-test-authoring #2).

The first input is a render-sized blank, so that the `dim` global is the render's: the T006 scratch shader read `dim`
as square with a 4x4 stand-in first input (tasks.md T006), so test_dim_probe records what `dim` follows both ways
(informational, no pass/fail) and every other test uses the render-sized input.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/quasi/bench_quasi.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 61             # integers only; 60 is bench_caustic_codebox, 70 is bench_modules

import paths as _paths
import math
import sys

import numpy as np

import benchclient as bc
import gpu_sim as g
from harness import check, note, run

import quasi_mirror as q

CODE = (_paths.REPO / "src" / "f_quasi" / "codebox_quasi.gen").read_text()
H, W = 144, 256
BLANK = np.zeros((H, W, 4), np.float32)        # first input as large as the render: `dim` is the render's
STAND_IN = np.zeros((4, 4, 4), np.float32)     # the bench's usual bang stand-in (4x4)
PINNED = dict(zoom=0.0, drift=0.0, density=4.0, envelope=0.5, bands=5.0, angle=0.0, gain=1.0, bypass_gate=0.0)
CASES = {
    "defaults": {},
    "dense, zoomed, capped envelope": dict(zoom=0.5, density=12.0, envelope=0.7),
    "rotated, drifted, banded, gained": dict(angle=33.0, drift=0.37, bands=8.0, gain=2.5),
    "just below the zoom wrap": dict(zoom=0.999, density=8.0),
}
# Tolerances, per mechanism (bench-test-authoring #7). The GPU potential matched the float64 mirror to 3.7e-5 over 12
# cases (T006), the NumPy float32 mirror to 2.6e-5; each outlet sees that error through its own gain:
TOL_SCALAR = 1e-4     # P / 2 + 0.5: half the potential error
TOL_VEC = 5e-4        # the gradient numerators carry the same relative trig error; encoded 0.5 * gain (<= 2.5)
TOL_LOOK = 1e-3       # the banded fold's slope is 1.1 * bands (<= 8.8) times the potential error: <= 3.3e-4


def gpu(params, inputs=None):
    p = {**PINNED, **params}
    outs, r = bc.run_pass(CODE, inputs or [BLANK], dim=(W, H), params=p, timeout_ms=30000, all_outputs=True)
    if r["status"] != "ok" or outs[0] is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs


def mirror(params):
    p = {**PINNED, **params}
    return q.render(H, W, zoom=p["zoom"], drift=p["drift"], density=p["density"], envelope=p["envelope"],
                    angle=math.radians(p["angle"]), bands=p["bands"], gain=p["gain"])


def worst(a, b):
    a = np.asarray(a, np.float64)
    if not np.isfinite(a).all():
        return float("inf")
    return float(np.abs(a - np.asarray(b, np.float64)).max())


# ---------------------------------------------------------------- tests

def test_compiles_and_runs_all_three_outlets():
    outs = gpu({})
    for i, name in enumerate(("look", "vecfield", "scalar")):
        assert outs[i] is not None, f"outlet {i + 1} ({name}) is silent"
        check(f"{name} outlet finite", 0 if np.isfinite(outs[i]).all() else 1, 0)
        assert float(outs[i][..., :2].std()) > 1e-3, f"{name} outlet is flat"
        print(f"    ok   outlet {i + 1} ({name}): finite, std {float(outs[i][..., :2].std()):.3f}")


def test_outlets_match_mirror():
    for label, params in CASES.items():
        outs = gpu(params)
        tex, vec, sca = mirror(params)
        check(f"[{label}] look RGB vs mirror", worst(outs[0][..., :3], tex[..., :3]), TOL_LOOK)
        check(f"[{label}] look alpha is 1", worst(outs[0][..., 3], 1.0), 0.0)
        check(f"[{label}] vecfield R, G vs mirror", worst(outs[1][..., :2], vec[..., :2]), TOL_VEC)
        check(f"[{label}] vecfield B is 0.5, A is 1", max(worst(outs[1][..., 2], 0.5), worst(outs[1][..., 3], 1.0)), 1e-6)
        check(f"[{label}] scalar RGB vs mirror", worst(outs[2][..., :3], sca[..., :3]), TOL_SCALAR)
        check(f"[{label}] scalar alpha is 1", worst(outs[2][..., 3], 1.0), 0.0)


def test_bypass_states_are_exact():
    """bypass_gate = 1 (never the native @bypass): look and scalar black with alpha 1, vecfield neutral (FR-012;
    the scalar's neutral is black, as f_chladni's magnitude outlet)."""
    outs = gpu(dict(bypass_gate=1.0))
    check("bypass: look is black, A = 1", worst(outs[0], np.array([0, 0, 0, 1.0])), 1e-6)
    check("bypass: vecfield is 0.5 / 0.5 / 0.5 / 1", worst(outs[1], np.array([0.5, 0.5, 0.5, 1.0])), 1e-6)
    check("bypass: scalar is black, A = 1", worst(outs[2], np.array([0, 0, 0, 1.0])), 1e-6)


def test_gain_zero_is_the_neutral_field():
    outs = gpu(dict(gain=0.0))
    check("gain 0: vecfield R, G exactly 0.5", worst(outs[1][..., :2], 0.5), 1e-6)


def test_zoom_and_drift_wrap_on_the_gpu():
    """FR-004 and the wrapped drift phase: a whole cycle of either is the identical frame. Binary fractions, so the
    wrapped parameter is exact in float32 and the frames must agree to rounding."""
    for label, a, b in (("zoom 0.25 vs 1.25", dict(zoom=0.25), dict(zoom=1.25)),
                        ("zoom 0.25 vs -0.75", dict(zoom=0.25), dict(zoom=-0.75)),
                        ("drift 0.5 vs 1.5", dict(drift=0.5), dict(drift=1.5)),
                        ("drift 0.5 vs -0.5", dict(drift=0.5), dict(drift=-0.5))):
        oa, ob = gpu(a), gpu(b)
        check(f"{label}: all three outlets identical", max(worst(oa[i], ob[i]) for i in range(3)), 1e-6)


def test_dim_probe():
    """Informational. What does the `dim` global follow in the bench: the render size (256x144) or the first input's
    size? Compares the scalar outlet with the mirror at the 16:9 aspect and at aspect 1. Closes the T006 open question."""
    nx, ny, _, _ = g.grid(H, W)
    sq = q.field(nx - np.float32(0.5), ny - np.float32(0.5), dtype=np.float32, zoom=0.0, drift=0.0, density=4.0,
                 envelope=0.5)["P"] * np.float32(0.5) + np.float32(0.5)
    wide = mirror({})[2][..., 0]
    for label, inp in (("render-sized first input (256x144)", BLANK), ("4x4 stand-in first input", STAND_IN)):
        out = gpu({}, inputs=[inp])[2][..., 0]
        e_wide, e_sq = worst(out, wide), worst(out, sq)
        verdict = "16:9, the render's" if e_wide < e_sq else "square, the input's (or a default)"
        note(f"dim with {label}", f"aspect read as {verdict} (error vs 16:9 {e_wide:.2e}, vs square {e_sq:.2e})")


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
