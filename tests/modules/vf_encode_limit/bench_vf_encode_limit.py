"""
bench_vf_encode_limit.py -- Tier 2: the direction-preserving encode limit (2026-11-16) on the GPU for the modules
that had no encode bench: f_vf_repulse, f_vf_vortex_multi, f_vf_fieldmap and f_vf_lk stage_c / stage_d. Each case drives the
real codebox far past the f_vecfield range, so the old per-channel clamp and the new rescale differ, and diffs it against
the module's NumPy mirror (stage_d and f_vf_fieldmap have none: their references are inline). Each case also proves it is not vacuous: some
pixels sit on the limit.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh -q tests/modules/vf_encode_limit/bench_vf_encode_limit.py
"""
GROUP = "regression"
ORDER = 120

import paths as _paths
import sys

import numpy as np

import benchclient as bc
from harness import check, note, run

REPO = _paths.REPO
for _m in ("vf_repulse", "vf_vortex_multi", "vf_lk"):
    sys.path.insert(0, str(REPO / "tests" / "modules" / _m))
from vf_repulse_mirror import repulse                 # noqa: E402
from vf_vortex_multi_mirror import vortex_multi       # noqa: E402
from vf_lk_mirror import stage_c            # noqa: E402
import gpu_sim as g                                    # noqa: E402

F32 = np.float32
H = W = 64


def inline_code(module):
    import runpy
    return runpy.run_path(str(REPO / "src" / module / "definition.py"))["patcher"]["codebox"]


def span(out):
    """Largest |encoded - 0.5| per pixel."""
    return np.abs(out[..., :2].astype(np.float64) - 0.5).max(axis=-1)


def on_limit(out, cap=0.5):
    """How many pixels sit on the limit (not vacuous: the case must saturate)."""
    return int((span(out) > cap - 1e-4).sum())


def test_repulse_high_gain():
    # TOL: ring reads are off-texel, so the hardware's 8-bit interpolation weights apply (about 1e-4 per read, many reads)
    # times gain 10; measured 1.6e-2 at mode 0 on the first run (2026-11-16), so 3.5e-2. The limit's own effect is O(0.1).
    TOL = 3.5e-2
    rng = np.random.default_rng(21)
    src = rng.uniform(0, 1, (H, W, 4)).astype(F32)
    src[..., 3] = 1.0
    for mode in (0, 1, 2, 3):
        params = {"gain": 10.0, "reach": 0.1, "threshold": 0.3, "mode": float(mode), "bypass": 0.0}
        out, r = bc.run_pass(inline_code("f_vf_repulse"), [src], params=params)
        check(f"repulse mode {mode}: status ok", 0 if r["status"] == "ok" else 1, 0)
        ref = repulse(src, gain=10.0, reach=0.1, threshold=0.3, mode=float(mode))
        err = np.abs(out - ref).max(axis=-1)
        frac = float((err > TOL).mean())
        note(f"repulse mode {mode}: max |GPU - mirror| / fraction of pixels over TOL", f"{float(err.max()):.3e} / {frac:.4f}")
        check(f"repulse mode {mode}: fraction of pixels over TOL", frac, 0.0 if mode == 0 else 0.01)
        n = on_limit(out)
        note(f"repulse mode {mode}: pixels on the limit", n)
        check(f"repulse mode {mode}: some pixels saturate (not vacuous)", float(n == 0), 0.0)
        check(f"repulse mode {mode}: nothing past the range", float(max(span(out).max() - 0.5, 0.0)), 1e-6)


def test_vortex_multi_overlapping_sites():
    # three sites on one point, convergence and curl at 1, no falloff: |f| = 3 * sqrt(2) before the limit
    TOL = 2e-5
    code = inline_code("f_vf_vortex_multi")
    # the bench drives 4 inputs; the global curl modulation texture is in5 and is unused at curl_amt 0
    code = code.replace("sample(in5, uv)", "vec(0.5, 0.5, 0.5, 1.0)")
    neutral = np.full((H, W, 4), 0.5, F32)
    neutral[..., 3] = 1.0
    params = {f"s{i}_{k}": v for i in (1, 2, 3) for k, v in (("cx", 0.5), ("cy", 0.5), ("conv", 1.0), ("curl", 1.0))}
    params.update({"falloff": 0.0, "cx_amt": 0.0, "cy_amt": 0.0, "conv_amt": 0.0, "curl_amt": 0.0, "bypass": 0.0})
    out, r = bc.run_pass(code, [neutral] * 4, params=params)
    check("vortex_multi: status ok", 0 if r["status"] == "ok" else 1, 0)
    ref = vortex_multi(h=H, w=W, falloff=0.0,
                       **{k: v for k, v in params.items() if k.startswith("s")})
    check("vortex_multi: max |GPU - mirror|", float(np.abs(out - ref).max()), TOL)
    n = on_limit(out)
    note("vortex_multi: pixels on the limit", n)
    check("vortex_multi: some pixels saturate (not vacuous)", float(n == 0), 0.0)
    # direction kept: the encoded vector is parallel to the unclamped sum (an angle check the per-channel clamp fails)
    d = out[..., :2].astype(np.float64) - 0.5
    rd = ref[..., :2].astype(np.float64) - 0.5
    cross = np.abs(d[..., 0] * rd[..., 1] - d[..., 1] * rd[..., 0])
    check("vortex_multi: output parallel to the mirror's direction", float(cross.max()), 1e-4)


def test_optical_flow_stage_c_gain():
    TOL = 2e-5
    rng = np.random.default_rng(22)
    in1 = np.zeros((H, W, 4), F32)
    in1[..., 0] = rng.uniform(1.0, 2.0, (H, W))           # Sxx
    in1[..., 1] = rng.uniform(1.0, 2.0, (H, W))           # Syy
    in1[..., 2] = rng.uniform(-0.2, 0.2, (H, W))          # Sxy
    in1[..., 3] = 1.0
    in2 = np.zeros((H, W, 4), F32)
    in2[..., 0] = rng.uniform(-2.0, 2.0, (H, W))          # Sxt
    in2[..., 1] = rng.uniform(-2.0, 2.0, (H, W))          # Syt
    in2[..., 3] = 1.0
    code = (REPO / "src" / "f_vf_lk" / "codebox_stage_c.gen").read_text()
    params = {"gain": 10.0, "mask_lo": 0.0, "mask_hi": 0.001, "bypass_gate": 0.0}
    out, r = bc.run_pass(code, [in1, in2], params=params)
    check("stage_c: status ok", 0 if r["status"] == "ok" else 1, 0)
    ref, _ = stage_c(in1, in2, gain=10.0, mask_lo=0.0, mask_hi=0.001, bypass=0.0)
    check("stage_c: max |GPU - mirror|", float(np.abs(out - ref).max()), TOL)
    n = on_limit(out)
    note("stage_c: pixels on the limit", n)
    check("stage_c: some pixels saturate (not vacuous)", float(n == 0), 0.0)


def test_optical_flow_stage_d_accumulator():
    TOL = 2e-5
    rng = np.random.default_rng(23)
    raw = np.zeros((H, W, 4), F32)
    prev = np.zeros((H, W, 4), F32)
    raw[..., :2] = rng.uniform(0.0, 1.0, (H, W, 2))       # decoded +-1
    prev[..., :2] = rng.uniform(0.0, 1.0, (H, W, 2))
    raw[..., 3] = prev[..., 3] = 1.0
    src = np.zeros((H, W, 4), F32)
    src[..., 3] = 1.0
    decay, inj = 1.4, 1.0                                  # decay above 1 (excitable regime) pushes the sum past +-1
    code = (REPO / "src" / "f_vf_lk" / "codebox_stage_d.gen").read_text()
    out, r = bc.run_pass(code, [raw, prev, src], params={"decay": decay, "injection": inj, "bypass_gate": 0.0})
    check("stage_d: status ok", 0 if r["status"] == "ok" else 1, 0)
    au = (prev[..., 0].astype(np.float64) - 0.5) * 2 * decay + (raw[..., 0].astype(np.float64) - 0.5) * 2 * inj
    av = (prev[..., 1].astype(np.float64) - 0.5) * 2 * decay + (raw[..., 1].astype(np.float64) - 0.5) * 2 * inj
    kk = 1.0 / np.maximum(np.maximum(np.abs(au), np.abs(av)), 1.0)
    want = np.stack([au * kk * 0.5 + 0.5, av * kk * 0.5 + 0.5], axis=-1)
    check("stage_d: max |GPU - reference|", float(np.abs(out[..., :2] - want).max()), TOL)
    n = on_limit(out)
    note("stage_d: pixels on the limit", n)
    check("stage_d: some pixels saturate (not vacuous)", float(n == 0), 0.0)


def test_fieldmap_high_gain():
    # TOL: taps are off-texel, so 8-bit interpolation weights apply, times gain 40; measured 3.6e-3 on the first run
    # (2026-11-16), so 8e-3. A per-channel clamp differs from the limit by far more (checked below).
    TOL = 8e-3
    rng = np.random.default_rng(24)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
    lum = 0.5 + 0.3 * np.sin(xx / 7.0) * np.cos(yy / 5.0) + 0.02 * rng.standard_normal((H, W))
    src = np.zeros((H, W, 4), F32)
    src[..., :3] = np.clip(lum, 0, 1)[..., None]
    src[..., 3] = 1.0
    gain, scale, rot = 40.0, 0.03, 30.0
    params = {"gain": gain, "scale": scale, "rotate": rot, "thresh": 0.0, "bypass_gate": 0.0}
    out, r = bc.run_pass(inline_code("f_vf_fieldmap"), [src], params=params)
    check("fieldmap: status ok", 0 if r["status"] == "ok" else 1, 0)
    nx, ny, _, _ = g.grid(H, W)
    sx = (nx * (1.0 - 2.0 * scale) + scale).astype(F32)
    sy = (ny * (1.0 - 2.0 * scale) + scale).astype(F32)

    def luma(dx, dy):
        t = g.sample(src, (sx + F32(dx)).astype(F32), (sy + F32(dy)).astype(F32))
        return (t[..., 0] * F32(0.299) + t[..., 1] * F32(0.587) + t[..., 2] * F32(0.114)).astype(np.float64)

    gx = (luma(scale, 0) - luma(-scale, 0)) * gain
    gy = (luma(0, scale) - luma(0, -scale)) * gain
    a = rot * np.pi / 180.0
    gx2 = gx * np.cos(a) - gy * np.sin(a)
    gy2 = gx * np.sin(a) + gy * np.cos(a)
    kk = 1.0 / np.maximum(np.maximum(np.abs(gx2), np.abs(gy2)), 1.0)
    want = np.stack([gx2 * kk * 0.5 + 0.5, gy2 * kk * 0.5 + 0.5], axis=-1)
    check("fieldmap: max |GPU - reference|", float(np.abs(out[..., :2] - want).max()), TOL)
    old = np.clip(np.stack([gx2, gy2], axis=-1) * 0.5 + 0.5, 0, 1)
    gap = float(np.abs(out[..., :2] - old).max())
    note("fieldmap: GPU vs the old per-channel clamp (must be well above TOL)", gap)
    check("fieldmap: the tolerance tells the old clamp from the limit", float(gap < 10 * TOL), 0.0)
    n = on_limit(out)
    note("fieldmap: pixels on the limit", n)
    check("fieldmap: some pixels saturate (not vacuous)", float(n == 0), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
