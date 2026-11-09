"""
bench_ink.py -- f_ink (narrowed 2026-11-09, T052): each stage's real codebox on the GPU through the codebox bench, diffed against
ink_mirror.py stage by stage.

Every Param is pinned in every job (the bench keeps a Param's last value). width and height are Params, set to the job's real size.

Tolerances (written before the first run):
  EXACT  0.0: a factor of exactly 0, the identity the spec asks for.
  TOL    1e-5: float32 differences and a manual bilinear, in a different order from the mirror's.

Cost is @slow, run with --slow, and noted only.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/modules/ink/bench_ink.py       (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 172            # integers only

import paths as _paths
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run, slow
from ink_mirror import F32, bulge_stage, extent_stage, field_uv, zap as mirror_zap
from test_ink import smooth, swirl_field

SRC = _paths.REPO / "src" / "f_ink"
ZAP = (SRC / "codebox_zap.gen").read_text()
BULGE = (SRC / "codebox_bulge.gen").read_text()
EXTENT = (SRC / "codebox_extent.gen").read_text()
EXACT = 0.0
TOL = 1e-5
H, W = 96, 160


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


def noisy(seed=3):
    """Hard edges and values outside 0..1, on top of the smooth tone."""
    rng = np.random.default_rng(seed)
    t = smooth(H, W).copy()
    t[..., :3] += rng.uniform(-0.3, 0.6, (H, W, 3)).astype(F32) * (rng.uniform(0, 1, (H, W, 1)) > 0.8)
    t[..., 3] = rng.uniform(0.2, 1, (H, W))
    return t.astype(F32)


def test_zap():
    t = noisy()
    t[2, 3, 0] = np.nan
    t[4, 5, 1] = np.inf
    t[6, 7, 2] = -np.inf
    t[8, 9, 3] = np.nan
    got = gpu(ZAP, [t], {})
    check("zap: every component matches the mirror", mx(got, mirror_zap(t)), EXACT)


def bulge_gpu(t, f, travel, bulge, flag=1.0):
    return gpu(BULGE, [t, f], {**size(t), "travel": travel, "bulge": bulge, "src_field": flag})


def extent_gpu(t, f, src, travel, extent, flag=1.0, bypass=0.0):
    return gpu(EXTENT, [t, f, src], {**size(t), "travel": travel, "extent": extent, "src_field": flag, "bypass_gate": bypass})


def test_bulge():
    t, f = noisy(), swirl_field(H, W)
    fx, fy = field_uv(f, H, W)
    for travel, amt in ((0.25, 0.5), (0.5, 1.0), (1.0, 2.0)):
        got = bulge_gpu(t, f, travel, amt)[..., :3]
        worst = mx(got, bulge_stage(t[..., :3], fx, fy, travel, amt))
        note(f"bulge, travel {travel}, amount {amt}: max error", worst)
        check(f"bulge, travel {travel}, amount {amt}: vs mirror", worst, TOL)
    check("bulge 0: exactly the input", mx(bulge_gpu(t, f, 1.0, 0.0)[..., :3], t[..., :3]), EXACT)
    check("no field flag: exactly the input", mx(bulge_gpu(t, f, 1.0, 2.0, flag=0.0)[..., :3], t[..., :3]), EXACT)


def test_extent():
    t, f, src = noisy(), swirl_field(H, W), noisy(seed=5)
    fx, fy = field_uv(f, H, W)
    for travel, amt in ((0.25, 0.5), (0.5, 1.0), (1.0, 2.0)):
        got = extent_gpu(t, f, src, travel, amt)[..., :3]
        worst = mx(got, extent_stage(t[..., :3], fx, fy, travel, amt))
        note(f"extent, travel {travel}, amount {amt}: max error", worst)
        check(f"extent, travel {travel}, amount {amt}: vs mirror", worst, TOL)
    out = extent_gpu(t, f, src, 0.5, 0.0)
    check("extent 0: exactly the input", mx(out[..., :3], t[..., :3]), EXACT)
    check("alpha is the source's", mx(out[..., 3], src[..., 3]), EXACT)
    check("no field flag: exactly the input", mx(extent_gpu(t, f, src, 1.0, 2.0, flag=0.0)[..., :3], t[..., :3]), EXACT)
    check("bypass: exactly the source, with the effect on", mx(extent_gpu(t, f, src, 1.0, 2.0, bypass=1.0), src), EXACT)


def test_nonfinite_field():
    t, f, src = noisy(), swirl_field(H, W), noisy(seed=5)
    f[10, 11, :2] = np.nan
    f[20, 21, 0] = np.inf
    check("bulge: no NaN from the field", float(not np.isfinite(bulge_gpu(t, f, 0.5, 1.0)).all()), 0.0)
    check("extent: no NaN from the field", float(not np.isfinite(extent_gpu(t, f, src, 0.5, 1.0)).all()), 0.0)


@slow       # a timing measurement (tests/bench.sh --slow); nothing is asserted
def test_cost_at_1080p():
    """ms per stage at 1920x1080, as in bench_separate. Width and height stay 1080p when 4K is run to get above the bench's floor."""
    t, f = noisy(), swirl_field(H, W)
    hd = {"width": 1920.0, "height": 1080.0, "travel": 0.5, "src_field": 1.0}
    stages = [("zap", ZAP, [t], {}),
              ("bulge", BULGE, [t, f], {**hd, "bulge": 1.0}),
              ("extent", EXTENT, [t, f, t], {**hd, "extent": 1.0, "bypass_gate": 0.0})]
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
