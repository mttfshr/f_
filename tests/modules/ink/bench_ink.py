"""
bench_ink.py -- f_ink T024 (codebox half): each stage's real codebox on the GPU through the codebox bench, diffed against
ink_mirror.py stage by stage (the constitution says whole chains are not covered by this bench). This is also the first time
these codeboxes are COMPILED: a syntax error shows as a failed job.

The blur is run as definition.py renders it for each of its four stages, since that is what ships.

The hash multiplier magnifies a GPU sin's low bits, so mottle and tooth are compared by statistics, never texel by texel; the
arithmetic around them is exact and has its own rows (amount 0 is exact identity, bypass is exact).

Every Param is pinned in every job (the bench keeps a Param's last value). width and height are Params, because a codebox cannot
trust `dim`; they are set to the job's real size.

Tolerances (written before the first run):
  EXACT       0.0: a blend factor or weight of exactly 0, the identity the spec asks for (SC-001).
  TOL         1e-5: float32 sums of up to 15 taps, where the mirror normalizes the weights first and the codebox last.
  TOL_SHARP   5e-4: smoothstep at soften 0, width 0.001: float32 rounding near the edge is multiplied by about 1500.

Measurements for the record, not gates:
  T008 (G4)   what sample() returns at a texel corner and at a quarter texel. Matrix-fed input only; a pix-to-pix read is not
              reachable from this bench (the module bench exercises nearest() on that path).
  T009 (G5)   the cost of each stage at 1920x1080, run with --slow.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/modules/ink/bench_ink.py       (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 172            # integers only

import paths as _paths
import importlib.util
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run, slow
from ink_mirror import F32, SPREAD_CAP_H, blur_pass, coords, fx_b as mirror_fx_b, pool as mirror_pool, threshold, zap as mirror_zap

SRC = _paths.REPO / "src" / "f_ink"
_spec = importlib.util.spec_from_file_location("ink_definition", SRC / "definition.py")
DEFN = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(DEFN)

ZAP = (SRC / "codebox_zap.gen").read_text()
THRESH = (SRC / "codebox_thresh.gen").read_text()
POOL = (SRC / "codebox_pool.gen").read_text()
FX_B = (SRC / "codebox_fx_b.gen").read_text()

EXACT = 0.0
TOL = 1e-5
TOL_SHARP = 5e-4
PIN_THRESH = {"spread": 0.0, "snap": 1.0, "bias": 0.0, "soften": 0.2}
PIN_FX = {"mottle": 0.0, "mottle_scale": 0.15, "dropout": 0.0, "tooth_scale": 0.004, "seed": 1.0, "bypass_gate": 0.0}


def noisy(h=64, w=64, seed=3, lo=0.0, hi=1.0):
    rng = np.random.default_rng(seed)
    t = np.zeros((h, w, 4), np.float32)
    t[..., :3] = rng.uniform(lo, hi, (h, w, 3))
    t[..., 3] = rng.uniform(0.2, 1, (h, w))
    return t


def flat(value, h=256, w=256):
    t = np.full((h, w, 4), value, np.float32)
    t[..., 3] = 1.0
    return t


def gpu(code, inputs, params):
    h, w = inputs[0].shape[:2]
    out, r = bc.run_pass(code, inputs, dim=(w, h), params=params, timeout_ms=30000)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def size(t):
    return {"width": float(t.shape[1]), "height": float(t.shape[0])}


# ---- measurements first: T008 ----------------------------------------------------------------------------------------------

def test_sample_interpolation_probe():
    """T008 (G4): noted, not asserted. The design uses nearest() only, so nothing here depends on the answer."""
    n = 64
    t = noisy(n, n)
    x = t[..., 0].astype(np.float64)
    for label, frac in (("texel corner", 0.5), ("quarter texel", 0.25)):
        got = gpu(f"out1 = sample(in1, vec(norm.x + {frac} / {n}.0, norm.y));", [t], {})[..., 0]
        inner_got, a, b = got[:, :-1], x[:, :-1], x[:, 1:]
        note(f"sample() at a {label}: max error against bilinear", mx(inner_got, a * (1 - frac) + b * frac))
        note(f"sample() at a {label}: max error against the left texel", mx(inner_got, a))
        note(f"sample() at a {label}: max error against the right texel", mx(inner_got, b))


# ---- the stages ------------------------------------------------------------------------------------------------------------

def test_zap():
    t = noisy()
    t[2, 3, 0] = np.nan
    t[4, 5, 1] = np.inf
    t[6, 7, 2] = -np.inf
    t[8, 9, 3] = np.nan
    t[10, 11, :3] = -0.3
    t[12, 13, :3] = 1.6
    got = gpu(ZAP, [t], {})
    check("zap: every component matches the mirror", mx(got, mirror_zap(t)), EXACT)
    check("zap: nothing non-finite is left", float(not np.isfinite(got).all()), 0.0)


def blur_case(label, axis, role, value, src, radius_tx, tol=TOL):
    params = {("spread" if role == "spread" else "pool_width"): value, **size(src)}
    got = gpu(DEFN._blur(axis, role), [src], params)
    want = blur_pass(src, 1 if axis == 0 else 0, radius_tx)     # codebox axis 0 is horizontal, NumPy axis 1 is a row
    worst = mx(got[..., :3], want[..., :3])
    note(f"{label}: max error", worst)
    check(f"{label}: vs mirror", worst, tol)


def test_blur_stages_as_shipped():
    """Both roles, both axes, a fractional radius and the 7-texel cap, on a non-square frame, so the border is exercised."""
    t = noisy(48, 96)
    for axis in (0, 1):
        for pw in (0.04, 0.1, 0.5):         # 1.92 and 4.8 texels; 24 is held at 7
            blur_case(f"pool blur, axis {axis}, width {pw}", axis, "pool", pw, t, pw * 48)
    tall = noisy(1080, 128)                 # spread 1 is 7 texels only at 1080
    for axis in (0, 1):
        for sp in (0.3, 1.0):
            blur_case(f"spread blur, axis {axis}, spread {sp}", axis, "spread", sp, tall, sp * SPREAD_CAP_H * 1080)


def test_blur_radius_zero_is_exact():
    t = noisy(48, 96)
    for axis in (0, 1):
        check(f"spread 0, axis {axis}: exactly the input", mx(gpu(DEFN._blur(axis, "spread"), [t], {"spread": 0.0, **size(t)})[..., :3], t[..., :3]), EXACT)
        check(f"pool width 0, axis {axis}: exactly the input", mx(gpu(DEFN._blur(axis, "pool"), [t], {"pool_width": 0.0, **size(t)})[..., :3], t[..., :3]), EXACT)


def test_threshold():
    t = noisy(64, 64, lo=-0.2, hi=1.3)
    for spread, snap, bias, soften, tol in ((0.5, 1.0, 0.0, 0.2, TOL), (1.0, 1.0, 0.2, 0.2, TOL), (1.0, 1.0, -0.2, 0.6, TOL),
                                            (0.06, 1.0, 0.0, 0.2, TOL), (1.0, 0.5, 0.1, 0.2, TOL), (1.0, 1.0, 0.0, 0.0, TOL_SHARP)):
        p = {"spread": spread, "snap": snap, "bias": bias, "soften": soften}
        worst = mx(gpu(THRESH, [t], p)[..., :3], threshold(t[..., :3], spread, snap, bias, soften))
        note(f"threshold {p}: max error", worst)
        check(f"threshold {p}: vs mirror", worst, tol)
    check("spread 0: exactly the input", mx(gpu(THRESH, [t], PIN_THRESH)[..., :3], t[..., :3]), EXACT)
    check("snap 0: exactly the input", mx(gpu(THRESH, [t], {**PIN_THRESH, "spread": 1.0, "snap": 0.0})[..., :3], t[..., :3]), EXACT)


def test_pool():
    bp, s = noisy(64, 64, seed=4), noisy(64, 64, seed=5)
    for a in (0.3, 1.0):
        worst = mx(gpu(POOL, [bp, s], {"edge_pool": a})[..., :3], mirror_pool(s[..., :3], bp[..., :3], a))
        note(f"pool {a}: max error", worst)
        check(f"pool {a}: vs mirror (left input is the blur, right is S)", worst, TOL)
    check("edge_pool 0: exactly S", mx(gpu(POOL, [bp, s], {"edge_pool": 0.0})[..., :3], s[..., :3]), EXACT)


def fx(pooled, src, **deltas):
    return gpu(FX_B, [pooled, src], {**PIN_FX, **size(pooled), **deltas})


def mirror_fx(c, **kw):
    h, w = c.shape[:2]
    px, py = coords(h, w)
    args = {**PIN_FX, **kw}
    return mirror_fx_b(c[..., :3], px, py, args["mottle"], args["mottle_scale"], args["dropout"], args["tooth_scale"], args["seed"])


def test_fx_identity_bypass_alpha():
    a, b = noisy(64, 96, seed=6, lo=-0.2, hi=1.3), noisy(64, 96, seed=7)
    got = fx(a, b)
    check("amounts 0: exactly the first input", mx(got[..., :3], a[..., :3]), EXACT)
    check("alpha is the source's", mx(got[..., 3], b[..., 3]), EXACT)
    byp = fx(a, b, mottle=1.0, dropout=1.0, bypass_gate=1.0)
    check("bypass: exactly the source, with the effects on", mx(byp, b), EXACT)


def test_fx_mottle_statistics():
    c = flat(0.8)
    stds = []
    for amt in (0.25, 0.5, 1.0):
        got, want = fx(c, c, mottle=amt)[..., 0], mirror_fx(c, mottle=amt)[..., 0]
        stds.append(float(got.std()))
        note(f"mottle {amt}: std GPU, mirror; mean GPU, mirror", f"{got.std():.4f} {want.std():.4f}; {got.mean():.4f} {want.mean():.4f}")
        check(f"mottle {amt}: std within 25% of the mirror's", abs(float(got.std()) / float(want.std()) - 1.0), 0.25)
        check(f"mottle {amt}: mean near the input", abs(float(got.mean()) - 0.8), 0.12)
    check("mottle: std grows with the amount", float(not (stds[0] < stds[1] < stds[2])), 0.0)
    check("mottle: black stays black", float(np.abs(fx(flat(0.0), c, mottle=1.0)[..., :3]).max()), EXACT)


def lost(t):
    return float((t[..., 0] == 0).mean())


def test_fx_dropout_statistics():
    sc = 0.02
    for v in (0.3, 0.6):
        c = flat(v)
        got, want = lost(fx(c, c, dropout=1.0, tooth_scale=sc)), lost(mirror_fx(c, dropout=1.0, tooth_scale=sc))
        note(f"dropout 1 on {v}: fraction lost GPU, mirror", f"{got:.4f} {want:.4f}")
        check(f"dropout 1 on {v}: fraction within 0.1 of the mirror's", abs(got - want), 0.1)
    c = flat(0.3)
    fr = [lost(fx(c, c, dropout=d, tooth_scale=sc)) for d in (0.3, 0.6, 1.0)]
    note("dropout 0.3, 0.6, 1 on 0.3: fraction lost", fr)
    check("dropout: the loss grows with the amount", float(not (fr[0] <= fr[1] <= fr[2] and fr[0] < fr[2])), 0.0)
    light, mid, solid = (lost(fx(flat(v), flat(v), dropout=1.0, tooth_scale=sc)) for v in (0.3, 0.6, 1.0))
    check("dropout: light loses more than mid", float(not light > mid), 0.0)
    check("dropout: a solid loses nothing", solid, EXACT)


def roughness(a):
    """Mean absolute step between neighbors along x and along y: it falls as the features grow."""
    return float(np.abs(np.diff(a, axis=1)).mean()), float(np.abs(np.diff(a, axis=0)).mean())


def test_fx_scale_and_aspect():
    c = flat(0.8)
    fine = roughness(fx(c, c, mottle=1.0, mottle_scale=0.05)[..., 0])[0]
    coarse = roughness(fx(c, c, mottle=1.0, mottle_scale=0.2)[..., 0])[0]
    note("mottle roughness at scale 0.05, 0.2", f"{fine:.5f} {coarse:.5f}")
    check("mottle: a larger scale is smoother", float(not coarse < fine), 0.0)
    wide = flat(0.8, 128, 256)              # features square on a 2:1 frame (ADR-7)
    rx, ry = roughness(fx(wide, wide, mottle=1.0, mottle_scale=0.05)[..., 0])
    note("2:1 frame: roughness along x, along y", f"{rx:.5f} {ry:.5f}")
    check("2:1 frame: square features (x and y roughness within 35%)", abs(rx / ry - 1.0), 0.35)
    a, b = fx(c, c, mottle=1.0, seed=1.0), fx(c, c, mottle=1.0, seed=2.0)
    check("seed changes the pattern", float(mx(a, b) < 0.01), 0.0)
    check("same seed, same pattern, bit for bit", mx(a, fx(c, c, mottle=1.0, seed=1.0)), EXACT)


# ---- T009 ------------------------------------------------------------------------------------------------------------------

@slow       # a timing measurement (tests/bench.sh --slow); NF-001 and T009 record it, nothing is asserted
def test_cost_at_1080p():
    """ms per stage at 1920x1080 with the blurs at their widest (every tap read regardless, the weights only change). The bench
    clamps the chain to 8 slots. When a pass hides inside the bench's own per-frame work, 4K is run instead, with width and height
    still 1080p so the tap offsets are unchanged: its figure / 4 is the 1080p equivalent."""
    t = noisy(64, 64)
    hd = {"width": 1920.0, "height": 1080.0}
    stages = [("zap", ZAP, [t], {}),
              ("blur (spread 1)", DEFN._blur(0, "spread"), [t], {"spread": 1.0, **hd}),
              ("thresh", THRESH, [t], {**PIN_THRESH, "spread": 1.0}),
              ("pool", POOL, [t, t], {"edge_pool": 1.0}),
              ("fx_b (mottle, dropout)", FX_B, [t, t], {**PIN_FX, **hd, "mottle": 1.0, "dropout": 1.0})]
    for name, code, inputs, params in stages:
        r = bc.measure(code, inputs, dim=(1920, 1080), chain=8, params=params)
        k = int(r.get("chain") or 8)
        if r.get("gpu_bound"):
            note(f"{name}: 1920x1080 ms per pass (chain {k})", f"{r['ms_per_pass']:.3f}")
            continue
        r = bc.measure(code, inputs, dim=(3840, 2160), chain=8, params=params)
        k = int(r.get("chain") or 8)
        if r.get("gpu_bound"):
            note(f"{name}: 1080p-equivalent ms per pass, from 4K (chain {k})", f"{r['ms_per_pass'] / 4:.3f}")
        else:
            note(f"{name}: NOT resolved at 4K, 1080p-equivalent upper bound ms per pass", f"{r['ms_per_pass_upper_bound'] / 4:.3f}")


if __name__ == "__main__":
    sys.exit(run(globals()))
