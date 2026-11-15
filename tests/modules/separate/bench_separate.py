"""
bench_separate.py -- f_separate T022 (codebox half): src/f_separate/codebox_separate.gen on the GPU through the codebox bench,
diffed against separate_mirror.separate_stage. One pass per job, one input (the source on in1), all four outlets.

This is also the first time the codebox is COMPILED: a syntax error shows as a failed job (status and errors in the
message), and Matt's first Max look (2026-11-08) found black outputs that offline tests cannot explain.

Every Param is pinned in every job (the bench keeps a Param's last value). Params: the nine ink colors as H (degrees), S, L
(inkN_h/s/l, 2026-11-14; RGB before), n_inks, sep_mode (0 Unmix, 1 Nearest, 2 Project), gain1-3, bypass_gate. The tests
think in RGB: `ink(n, rgb)` turns a color into its three Params, and the mirror turns them back (separate_mirror.hsl_to_rgb),
so the GPU's hsl2rgb is checked against the standard model on every row.

Outlets (2026-11-14): the module's outlet 0 (gen out1) is the composite, 1 to 3 the plates; gpu() reorders them to the
mirror's (plates 1 to 3, composite).

Tolerances:
  TOL  the codebox does the same float32 arithmetic as the mirror but in a different order (cofactors, the ridge, divisions),
       and a GPU `/` and `clamp` are not NumPy's. Measured offline between the mirror and a NumPy transcription of the codebox:
       1.2e-4 worst; 2e-3 allows the GPU's own division. A first run may need this recalibrated; the number is then recorded.
  The 1:1 read of an input texture at texel centers through sample() is exact on this path (jit-gen-codebox, bench facts).

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/modules/separate/bench_separate.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 170            # integers only

import paths as _paths
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run, slow
from separate_mirror import F32, hsl_to_rgb, rgb_to_hsl, separate_stage

CODE = (_paths.REPO / "src" / "f_separate" / "codebox_separate.gen").read_text()
N = 64
TOL = 2e-3
SPOT = np.array([[1.0, 0.25, 0.0], [0.0, 0.6, 0.6], [0.45, 0.0, 1.0]], dtype=F32)
PINNED = {"n_inks": 3.0, "sep_mode": 0.0, "gain1": 1.0, "gain2": 1.0, "gain3": 1.0, "bypass_gate": 0.0}


def ink(n, rgb):
    """The three Params of ink n for an RGB color."""
    return dict(zip((f"ink{n}_h", f"ink{n}_s", f"ink{n}_l"), rgb_to_hsl(*rgb)))


for _i in range(3):
    PINNED.update(ink(_i + 1, SPOT[_i]))
MODES = {0: "unmix", 1: "nearest", 2: "project"}


def photo(seed=3, n=N):
    """Colorful, with values outside 0..1 on a few texels and a hard patch of each ink color."""
    rng = np.random.default_rng(seed)
    t = np.zeros((n, n, 4), np.float32)
    t[..., :3] = rng.uniform(0, 1, (n, n, 3))
    t[..., 3] = rng.uniform(0.2, 1, (n, n))
    t[0, :4, :3] = 1.6
    t[1, :4, :3] = -0.3
    for i in range(3):
        t[4:8, 4 * i:4 * i + 4, :3] = SPOT[i]
        # 0.55, not 0.5: half an ink is an exact Nearest tie between the ink and black, and since the inks come through
        # hsl2rgb (2026-11-14) the GPU's ink differs from the mirror's by about 6e-7, enough to flip the tie (measured:
        # the 0.5 x ink 3 patch was the only mismatch, tests/logs/20261114-215347-bench.log). The tie rule itself is
        # test_separate.py's (offline, exact inks).
        t[8:12, 4 * i:4 * i + 4, :3] = 0.55 * SPOT[i]
    t[12:16, 0:4, :3] = 0.0
    return t


def gpu(src, **deltas):
    params = dict(PINNED)
    params.update(deltas)
    outs, r = bc.run_pass(CODE, [src], dim=(src.shape[1], src.shape[0]), params=params, timeout_ms=30000,
                          all_outputs=True)
    if r["status"] != "ok" or any(o is None for o in outs):
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs[1:] + outs[:1]          # outlets (composite, plates) -> the mirror's (plates, composite)


def mirror(src, **deltas):
    p = dict(PINNED)
    p.update(deltas)
    inks = np.array([hsl_to_rgb(p[f"ink{i}_h"], p[f"ink{i}_s"], p[f"ink{i}_l"]) for i in (1, 2, 3)], dtype=F32)
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
    both("black ink", t, **ink(1, (0.0, 0.0, 0.0)))
    both("duplicate inks", t, **ink(2, (1.0, 0.25, 0.0)))
    both("orthogonal inks", t, **ink(1, (1.0, 0.0, 0.0)), **ink(2, (0.0, 1.0, 0.0)), **ink(3, (0.0, 0.0, 1.0)))
    both("pastel and gray inks", t, **ink(1, (0.6, 0.5, 0.4)), **ink(2, (0.5, 0.5, 0.5)))


def test_hsl_params():
    """The codebox's hsl2rgb against the standard model: every 30 degrees of hue at two lightnings, read back from a white
    patch in Project mode (coverage clamps to 1, so plate 1 is the ink). Hue wraps: 360 is 0, -30 is 330."""
    t = np.ones((4, 4, 4), np.float32)
    worst = 0.0
    for h in range(0, 361, 30):
        for s_, l_ in ((1.0, 0.5), (0.4, 0.7)):
            got = gpu(t, sep_mode=2.0, ink1_h=float(h), ink1_s=s_, ink1_l=l_)[0][0, 0, :3]
            worst = max(worst, mx(got, hsl_to_rgb(h, s_, l_)))
    note("hsl2rgb vs the standard model, worst over hues and two S, L", worst)
    check("ink colors follow the standard HSL model", worst, TOL)
    check("hue wraps: -30 is 330", mx(gpu(t, sep_mode=2.0, ink1_h=-30.0)[0], gpu(t, sep_mode=2.0, ink1_h=330.0)[0]), 1e-5)


def test_independence_in_project_mode():
    """Moving ink 1 must not change plates 2 and 3 in Project mode: the property Matt asked for."""
    t = photo()
    a = gpu(t, sep_mode=2.0)
    b = gpu(t, sep_mode=2.0, **ink(1, (0.3, 0.9, 0.1)))
    check("project: plate 2 unchanged when ink 1 moves", mx(a[1], b[1]), 0.0)
    check("project: plate 3 unchanged when ink 1 moves", mx(a[2], b[2]), 0.0)
    u = gpu(t, sep_mode=0.0, **ink(1, (0.3, 0.9, 0.1)))
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


@slow       # a timing measurement (tests/bench.sh --slow); NF-001 records it, nothing is asserted
def test_cost_at_1080p():
    """ms per pass for each mode at 1920x1080, three inks, all four outlets. The bench clamps the chain to 8 slots. When the
    pass hides inside the bench's own per-frame work, 4K is run instead (4x the pixels): its figure / 4 is the 1080p
    equivalent. A small input is enough: the cost follows the output size. Each later slot reads the previous slot's out1, so
    the input is only representative for the first; the codebox has no per-pixel loop, so this should not change the cost
    (inferred)."""
    src = photo()
    for mode, name in MODES.items():
        params = {**PINNED, "sep_mode": float(mode)}
        r = bc.measure(CODE, [src], dim=(1920, 1080), chain=8, params=params)
        k = int(r.get("chain") or 8)
        if r.get("gpu_bound"):
            note(f"{name}: 1920x1080 ms per pass (chain {k})", f"{r['ms_per_pass']:.3f}")
            continue
        r = bc.measure(CODE, [src], dim=(3840, 2160), chain=8, params=params)
        k = int(r.get("chain") or 8)
        if r.get("gpu_bound"):
            note(f"{name}: 1080p-equivalent ms per pass, from 4K (chain {k})", f"{r['ms_per_pass'] / 4:.3f}")
        else:
            note(f"{name}: NOT resolved at 4K, 1080p-equivalent upper bound ms per pass", f"{r['ms_per_pass_upper_bound'] / 4:.3f}")


if __name__ == "__main__":
    sys.exit(run(globals()))
