"""
bench_separate.py -- f_separate T022 (codebox half): src/f_separate/codebox_separate.gen on the GPU through the codebox bench,
diffed against separate_mirror.separate_stage. One pass per job, one input (the source on in1), all four outlets.

This is also the first time the codebox is COMPILED: a syntax error shows as a failed job (status and errors in the
message), and Matt's first Max look (2026-11-08) found black outputs that offline tests cannot explain.

Every Param is pinned in every job (the bench keeps a Param's last value). Params: the nine ink colours, n_inks, sep_mode
(0 Unmix, 1 Nearest, 2 Project), gain1-3, bypass_gate.

Tolerances:
  TOL  the codebox does the same float32 arithmetic as the mirror but in a different order (cofactors, the ridge, divisions),
       and a GPU `/` and `clamp` are not NumPy's. Measured offline between the mirror and a NumPy transcription of the codebox:
       1.2e-4 worst; 2e-3 allows the GPU's own division. A first run may need this recalibrated; the number is then recorded.
  The 1:1 read of an input texture at texel centres through sample() is exact on this path (jit-gen-codebox, bench facts).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/modules/separate/bench_separate.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 170            # integers only

import paths as _paths
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run
from separate_mirror import F32, separate_stage

CODE = (_paths.REPO / "src" / "f_separate" / "codebox_separate.gen").read_text()
N = 64
TOL = 2e-3
SPOT = np.array([[1.0, 0.25, 0.0], [0.0, 0.6, 0.6], [0.45, 0.0, 1.0]], dtype=F32)
PINNED = {"n_inks": 3.0, "sep_mode": 0.0, "gain1": 1.0, "gain2": 1.0, "gain3": 1.0, "bypass_gate": 0.0}
for _i in range(3):
    for _c, _ch in enumerate("rgb"):
        PINNED[f"ink{_i + 1}_{_ch}"] = float(SPOT[_i, _c])
MODES = {0: "unmix", 1: "nearest", 2: "project"}


def photo(seed=3, n=N):
    """Colourful, with values outside 0..1 on a few texels and a hard patch of each ink colour."""
    rng = np.random.default_rng(seed)
    t = np.zeros((n, n, 4), np.float32)
    t[..., :3] = rng.uniform(0, 1, (n, n, 3))
    t[..., 3] = rng.uniform(0.2, 1, (n, n))
    t[0, :4, :3] = 1.6
    t[1, :4, :3] = -0.3
    for i in range(3):
        t[4:8, 4 * i:4 * i + 4, :3] = SPOT[i]
        t[8:12, 4 * i:4 * i + 4, :3] = 0.5 * SPOT[i]
    t[12:16, 0:4, :3] = 0.0
    return t


def gpu(src, **deltas):
    params = dict(PINNED)
    params.update(deltas)
    outs, r = bc.run_pass(CODE, [src], dim=(src.shape[1], src.shape[0]), params=params, timeout_ms=30000,
                          all_outputs=True)
    if r["status"] != "ok" or any(o is None for o in outs):
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs


def mirror(src, **deltas):
    p = dict(PINNED)
    p.update(deltas)
    inks = np.array([[p[f"ink{i}_{c}"] for c in "rgb"] for i in (1, 2, 3)], dtype=F32)
    return separate_stage(src, inks, n_inks=int(p["n_inks"]), mode=MODES[int(p["sep_mode"])],
                          gains=(p["gain1"], p["gain2"], p["gain3"]), bypass=int(p["bypass_gate"]))


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def both(label, src, tol=TOL, **deltas):
    got, want = gpu(src, **deltas), mirror(src, **deltas)
    worst = max(mx(got[i][..., :3], want[i][..., :3]) for i in range(4))
    note(f"{label}: worst rgb error over the four outlets", worst)
    check(f"{label}: rgb vs mirror", worst, tol)
    check(f"{label}: alpha is the source's", max(mx(g_[..., 3], src[..., 3]) for g_ in got), 1e-6)
    return got


def test_compile_and_modes():
    """The first check: the codebox compiles and the three modes match the mirror."""
    t = photo()
    for m, name in MODES.items():
        both(f"{name}, three inks", t, sep_mode=float(m))


def test_fewer_inks_and_gains():
    t = photo()
    for n in (1, 2):
        for m in MODES:
            both(f"{MODES[m]}, {n} ink(s)", t, n_inks=float(n), sep_mode=float(m))
    got = both("gains 0.5, 2, 0", t, gain1=0.5, gain2=2.0, gain3=0.0)
    check("gain 0 empties plate 3", float(np.abs(got[2][..., :3]).max()), 1e-6)


def test_palettes():
    t = photo()
    both("black ink", t, ink1_r=0.0, ink1_g=0.0, ink1_b=0.0)
    both("duplicate inks", t, ink2_r=1.0, ink2_g=0.25, ink2_b=0.0)
    both("orthogonal inks", t, ink1_r=1.0, ink1_g=0.0, ink1_b=0.0, ink2_r=0.0, ink2_g=1.0, ink2_b=0.0,
         ink3_r=0.0, ink3_g=0.0, ink3_b=1.0)


def test_independence_in_project_mode():
    """Moving ink 1 must not change plates 2 and 3 in Project mode: the property Matt asked for."""
    t = photo()
    a = gpu(t, sep_mode=2.0)
    b = gpu(t, sep_mode=2.0, ink1_r=0.3, ink1_g=0.9, ink1_b=0.1)
    check("project: plate 2 unchanged when ink 1 moves", mx(a[1], b[1]), 0.0)
    check("project: plate 3 unchanged when ink 1 moves", mx(a[2], b[2]), 0.0)
    u = gpu(t, sep_mode=0.0, ink1_r=0.3, ink1_g=0.9, ink1_b=0.1)
    c = gpu(t, sep_mode=0.0)
    note("unmix: plate 2 change when ink 1 moves (expected non-zero)", mx(u[1], c[1]))


def test_bypass_and_bounds():
    t = photo()
    got = gpu(t, bypass_gate=1.0)
    check("bypass: all four outlets are the source", max(mx(g_, np.where(np.isfinite(t), t, 0)) for g_ in got), 1e-6)
    out = gpu(t)
    lo = min(float(o[..., :3].min()) for o in out)
    hi = max(float(o[..., :3].max()) for o in out)
    check("outputs within 0..1", max(-lo, hi - 1.0, 0.0), 1e-6)


if __name__ == "__main__":
    sys.exit(run(globals()))
