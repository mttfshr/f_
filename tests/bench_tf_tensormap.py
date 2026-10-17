"""
bench_tf_tensormap.py -- Tier 2 verification for f_tf_tensormap: the real
stage codeboxes (src/f_tf_tensormap/codebox_*.gen) run on the GPU through the
Max test bench and are diffed against the NumPy mirror in
tests/test_tf_tensormap.py, one stage per job (multi-stage modules are
benched stage by stage). Tasks T012-T016, T018-T021.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/bench_tf_tensormap.py
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
import test_tf_tensormap as m          # the tier-1 mirror

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "src" / "f_tf_tensormap"
F32 = np.float32
R_MAX = 16                              # must match the loops in stage_b_*.gen
TOL = 1e-4


def code(name):
    return (SRC / f"codebox_stage_{name}.gen").read_text()


def rand_rgba(h, w, seed=0):
    x = np.random.default_rng(seed).uniform(0, 1, (h, w, 4)).astype(F32)
    x[..., 3] = 1.0
    return x


def rel(a, b):
    return float(np.abs(a - b).max() / max(np.abs(b).max(), 1e-12))


def border_err(a, b, k=2):
    """Max abs error restricted to the outermost k rows/columns."""
    d = np.abs(a - b)
    m_ = np.zeros(d.shape[:2], bool)
    m_[:k, :] = m_[-k:, :] = True
    m_[:, :k] = m_[:, -k:] = True
    return float(d[m_].max())


def tx(h, w, stage="a"):
    """width/height Params for an (h, w) frame (live `dim` reads 1; see codebox_stage_a).
    Each stage declares only what it uses: a both, b_h width, b_v height (an undeclared
    Param is a jit.gl.pix 'invalid message')."""
    full = {"width": float(w), "height": float(h)}
    return {"a": full, "b_h": {"width": full["width"]}, "b_v": {"height": full["height"]}}[stage]


def ok(r):
    check("status ok", 0 if r["status"] == "ok" else 1, 0)


# ------------------------------------------------------------- stage A (T012)

def test_stage_a_compiles_and_matches():
    x = rand_rgba(64, 64, seed=1)
    out, r = bc.run_pass(code("a"), [x], params=tx(64, 64))
    ok(r)
    ref = m.stage_a(x)
    check("A vs mirror (rel, RGB)", rel(out[..., :3], ref[..., :3]), TOL)
    check("A border rows/cols abs err (clamp-to-edge)", border_err(out[..., :3], ref[..., :3]), 1e-4)
    check("A gx*gy has negative values (signed case exercised)",
          0 if (ref[..., 1] < 0).any() else 1, 0)


# ------------------------------------------------------------- stage B (T015)

def test_stage_b_h_and_v_match():
    t = rand_rgba(64, 64, seed=2)
    t[..., :3] *= 4.0                      # unbounded float32 content
    for radius in (0, 1, 3, 6, R_MAX):
        out_h, r = bc.run_pass(code("b_h"), [t], params={"radius": float(radius), **tx(64, 64, "b_h")})
        ok(r)
        ref_h = m.stage_b(t, radius, 0, r_max=R_MAX)
        check(f"B_h radius {radius} (rel)", rel(out_h[..., :3], ref_h[..., :3]), TOL)
        check(f"B_h radius {radius} borders", border_err(out_h[..., :3], ref_h[..., :3]), 1e-3)
        out_v, r = bc.run_pass(code("b_v"), [t], params={"radius": float(radius), **tx(64, 64, "b_v")})
        ok(r)
        ref_v = m.stage_b(t, radius, 1, r_max=R_MAX)
        check(f"B_v radius {radius} (rel)", rel(out_v[..., :3], ref_v[..., :3]), TOL)
        check(f"B_v radius {radius} borders", border_err(out_v[..., :3], ref_v[..., :3]), 1e-3)


def test_stage_b_radius_zero_is_identity():
    t = rand_rgba(64, 64, seed=3)
    out, _ = bc.run_pass(code("b_h"), [t], params={"radius": 0.0, **tx(64, 64, "b_h")})
    check("B_h radius 0 identity", float(np.abs(out[..., :3] - t[..., :3]).max()), 1e-6)


# ------------------------------------------------------------- stage C (T020)

def _tensor_input(h=32, w=32, seed=4):
    rng = np.random.default_rng(seed)
    v = rng.normal(size=(h, w, 2, 2)).astype(F32)
    t = np.zeros((h, w, 4), F32)
    t[..., 0] = v[..., 0, 0] ** 2 + v[..., 0, 1] ** 2
    t[..., 1] = v[..., 0, 0] * v[..., 1, 0] + v[..., 0, 1] * v[..., 1, 1]
    t[..., 2] = v[..., 1, 0] ** 2 + v[..., 1, 1] ** 2
    t[..., 3] = 1.0
    t[0, 0, :3] = 0.0                      # exactly isotropic
    t[0, 1, :3] = (0.5, 0.0, 0.5)          # isotropic-ish, nonzero trace
    t[0, 2, :3] = (1.0, 0.0, 0.0)          # axis-aligned, branch-cut-ish (diff>0, Jxy=0)
    t[0, 3, :3] = (0.0, 0.0, 1.0)          # diff<0, Jxy=0 -> atan2(0,-d) = pi
    return t


def test_stage_c_matches_mirror_both_outlets():
    t = _tensor_input()
    outs, r = bc.run_pass(code("c"), [t], params={"strength": 12.0}, all_outputs=True)
    ok(r)
    ref0, ref1 = m.stage_c(t, strength=F32(12.0))
    check("C outlet0 (rel)", rel(outs[0][..., :4], ref0), TOL)
    for ch, name in enumerate("RGBA"):
        e = float(np.abs(outs[1][..., ch] - ref1[..., ch]).max())
        note(f"C outlet1 {name} max abs err", e)
    # branch-cut pixels: cos2t/sin2t are continuous across +-pi after doubling
    dR = np.abs(outs[1][..., 0] - ref1[..., 0])
    for (yy, xx) in zip(*np.where(dR > 1e-3)):
        print(f"      R mismatch at ({yy},{xx}): tensor={t[yy,xx,:3].tolist()} gpu={outs[1][yy,xx].tolist()} mirror={ref1[yy,xx].tolist()}")
    check("C outlet1 R,G (incl. branch cut)", float(np.abs(outs[1][..., :2] - ref1[..., :2]).max()), 1e-3)
    check("C outlet1 B,A", float(np.abs(outs[1][..., 2:] - ref1[..., 2:]).max()), 1e-3)


def test_stage_c_isotropic_is_neutral():
    t = _tensor_input()
    outs, _ = bc.run_pass(code("c"), [t], params={"strength": 12.0}, all_outputs=True)
    check("iso pixel R,G == .5", float(np.abs(outs[1][0, 0, :2] - 0.5).max()), 1e-6)
    check("iso pixel A == 0", float(abs(outs[1][0, 0, 3])), 1e-6)


def test_stage_c_strength_zero_and_bypass():
    t = _tensor_input()
    outs, _ = bc.run_pass(code("c"), [t], params={"strength": 0.0}, all_outputs=True)
    check("strength 0 -> outlet0 R == 0", float(np.abs(outs[0][..., 0]).max()), 1e-6)
    check("strength 0 -> outlet0 G == .5", float(np.abs(outs[0][..., 1] - 0.5).max()), 1e-6)
    outs, _ = bc.run_pass(code("c"), [t], params={"bypass_gate": 1.0}, all_outputs=True)
    check("bypass_gate outlet0 == (0,.5,0,1)",
          float(np.abs(outs[0] - np.array([0, .5, 0, 1], F32)).max()), 1e-6)
    check("bypass_gate outlet1 == (.5,.5,0,0)",
          float(np.abs(outs[1] - np.array([.5, .5, 0, 0], F32)).max()), 1e-6)


# ------------------------------------------------------------- cost (T016)
# M3 Max numbers; the M1 is unmeasured. R_MAX variants via text substitution.

def _with_rmax(src, r):
    return src.replace("-16", f"-{r}").replace("<= 16", f"<= {r}")


def test_cost_by_rmax():
    t = rand_rgba(1080, 1920, seed=5)
    for rm in (8, 16, 32):
        for stage in ("b_h", "b_v"):
            r = bc.measure(_with_rmax(code(stage), rm), [t], chain=4,
                           params={"radius": float(rm), **tx(1080, 1920, stage)})
            check(f"{stage} R_MAX {rm} status ok", 0 if r["status"] == "ok" else 1, 0)
            if r["gpu_bound"]:
                note(f"{stage} R_MAX {rm} 1080p ms/pass", r["ms_per_pass"])
            else:
                note(f"{stage} R_MAX {rm} 1080p ms/pass (upper bound)", r["ms_per_pass_upper_bound"])


def test_cost_per_stage_1080p_and_4k():
    """Per-stage cost at R_MAX 16, radius 16 (worst case), 1080p and 4K.
    The 4-stage chain cost is the sum of these (codeboxes repeat per slot)."""
    for label, (h, w) in (("1080p", (1080, 1920)), ("4K", (2160, 3840))):
        t = rand_rgba(h, w, seed=6)
        total = 0.0
        for stage, params in (("a", tx(h, w)), ("b_h", {"radius": 16.0, **tx(h, w, "b_h")}),
                              ("b_v", {"radius": 16.0, **tx(h, w, "b_v")}), ("c", {})):
            r = bc.measure(code(stage), [t], chain=4, params=params)
            check(f"{label} {stage} status ok", 0 if r["status"] == "ok" else 1, 0)
            if r["gpu_bound"]:
                v, tag = r["ms_per_pass"], ""
            else:
                v, tag = r["ms_per_pass_upper_bound"], " (upper bound)"
            note(f"{label} stage {stage} ms/pass{tag}", v)
            total += v
        note(f"{label} chain total ms (sum of stages)", total)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
