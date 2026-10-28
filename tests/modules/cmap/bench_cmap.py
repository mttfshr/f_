"""
bench_cmap.py -- f_cmap tier 2 (tasks.md T022): the real codeboxes src/f_cmap/codebox_cmap.gen (primary) and
codebox_cmap_pass.gen run on the GPU through the codebox bench, diffed against the NumPy float32 mirror
(cmap_mirror.frame), plus the invariants a mirror that shares the code's conventions could not catch.

in1 = the source, in2 = the previous frame; both are render-sized, so the `dim` global is the render's (the first
input sets it in the bench: tasks.md T006). Every job pins every Param (the bench keeps a Param's last value between
jobs: bench-test-authoring #2).

Tolerances. The mirror and the GPU agree to float32 rounding except on isolated pixels where the inside / outside
decision or a tap index flips (T006 Part 1: mean error 0.0002, 0.1% of pixels above 0.01, max 0.07), so a frame is
judged by its mean error and by the FRACTION of pixels off by more than 2e-3, not by its worst pixel.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/cmap/bench_cmap.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 64             # integers only; 63 is taken, 70 is bench_modules

import paths as _paths
import math

import numpy as np

import benchclient as bc
from harness import check, note, run

import cmap_mirror as m

CODE = (_paths.REPO / "src" / "f_cmap" / "codebox_cmap.gen").read_text()
PASS_CODE = (_paths.REPO / "src" / "f_cmap" / "codebox_cmap_pass.gen").read_text()
H, W = 144, 256
PINNED = dict(decay=0.97, inject=0.05, radius=0.15, sweep=0.0, angle=0.0, pwr=2.0, edge=0.0, lscale=1.75,
              freeze_on=0.0, reseed=0.0, bypass_gate=0.0, theta_clk=0.0, phase_clk=0.0)
MEAN_TOL = 1e-4
FRAC_TOL = 0.001       # share of pixels allowed to differ by more than BAD
BAD = 2e-3


def smooth(phase, h=H, w=W):
    """A smooth RGBA image (alpha 1): the pull samples it, so it must not alias in the check itself."""
    x = ((np.arange(w, dtype=np.float32) + 0.5) / w)[None, :]
    y = ((np.arange(h, dtype=np.float32) + 0.5) / h)[:, None]
    img = np.empty((h, w, 4), np.float32)
    img[..., 0] = 0.5 + 0.4 * np.sin(6.0 * x + phase) * np.cos(5.0 * y)
    img[..., 1] = 0.5 + 0.4 * np.cos(4.0 * x - 2.0 * y + phase)
    img[..., 2] = 0.5 + 0.4 * np.sin(3.0 * (x + y) + 2.0 * phase)
    img[..., 3] = 1.0
    return img


SRC = smooth(0.0)
PREV = smooth(1.7)


def gpu(params, src=SRC, prev=PREV, code=CODE):
    p = {**PINNED, **params}
    out, r = bc.run_pass(code, [src, prev], dim=(W, H), params=p, timeout_ms=30000)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def w_of(p):
    """w from the codebox's Params, by hand (the mirror's offset() derives both phases from one rate)."""
    th = 2.0 * math.pi * (p["angle"] + p["theta_clk"])
    mag = p["radius"] + p["sweep"] * math.cos(2.0 * math.pi * p["phase_clk"])
    return (mag * math.cos(th), mag * math.sin(th))


def mirror(params, src=SRC, prev=PREV):
    p = {**PINNED, **params}
    keep = m.L
    m.L = p["lscale"]
    try:
        return m.frame(prev, src, n=int(p["pwr"]), w=w_of(p), decay=p["decay"], inject=p["inject"],
                       bounds="wrap" if p["edge"] >= 0.5 else "source", sampler="bilinear")
    finally:
        m.L = keep


def stats(a, b):
    d = np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))
    if not np.isfinite(d).all():
        return float("inf"), float("inf"), 1.0
    return float(d.max()), float(d.mean()), float((d.max(axis=-1) > BAD).mean())


def worst(a, b):
    a = np.asarray(a, np.float64)
    if not np.isfinite(a).all():
        return float("inf")
    return float(np.abs(a - np.asarray(b, np.float64)).max())


CASES = {
    "defaults": {},
    "cubed": dict(pwr=3.0),
    "fourth power": dict(pwr=4.0),
    "wrap bounds": dict(edge=1.0),
    "wrap, cubed": dict(edge=1.0, pwr=3.0),
    "scale 1.2": dict(lscale=1.2),
    "scale 2.6, fourth power": dict(lscale=2.6, pwr=4.0),
    "clocked offset": dict(angle=0.3, theta_clk=0.2, sweep=0.5, phase_clk=0.15, radius=0.4),
    "strong decay, heavy inject": dict(decay=0.8, inject=0.4),
    "large offset": dict(radius=1.2, sweep=0.4, phase_clk=0.5),
}


# ---------------------------------------------------------------- tests

def test_matches_mirror():
    for label, params in CASES.items():
        out = gpu(params)
        ref = mirror(params)
        mx, mean, frac = stats(out, ref)
        note(f"[{label}]", f"max {mx:.4f}  mean {mean:.2e}  frac>{BAD:g} {frac:.4f}")
        check(f"[{label}] mean error vs mirror", mean, MEAN_TOL)
        check(f"[{label}] share of pixels off", frac, FRAC_TOL)


def test_parameters_have_effect():
    """The GPU result for a parameter value must be the mirror's for THAT value and not the default's: catches a
    Param that is accepted and never applied (the `t` trap; a token that jit.gl.pix owns)."""
    base = gpu({})
    for label, params in (("pwr 3", dict(pwr=3.0)), ("lscale 1.2", dict(lscale=1.2)), ("edge 1", dict(edge=1.0)),
                          ("radius 0.5", dict(radius=0.5)), ("angle 0.25", dict(angle=0.25)),
                          ("theta_clk 0.25", dict(theta_clk=0.25)), ("sweep 0.6 + phase_clk 0", dict(sweep=0.6)),
                          ("decay 0.7", dict(decay=0.7)), ("inject 0.5", dict(inject=0.5))):
        out = gpu(params)
        moved = stats(out, base)[1]
        wrong = stats(out, mirror({}))[1]
        got = stats(out, mirror(params))[1]
        note(f"[{label}]", f"moved {moved:.3f} from the default; mean vs its mirror {got:.1e}")
        check(f"[{label}] matches its own mirror", got, MEAN_TOL)
        assert moved > 5 * MEAN_TOL, f"{label}: no visible effect (the Param may not be applied)"
        assert wrong > 5 * MEAN_TOL


def test_alpha_is_one():
    src = SRC.copy()
    src[..., 3] = 0.25                     # a source with alpha must not leak into the loop
    prev = PREV.copy()
    prev[..., 3] = 0.0
    out = gpu({}, src=src, prev=prev)
    check("alpha is exactly 1 (source alpha 0.25, history alpha 0)", worst(out[..., 3], 1.0), 0.0)
    check("reseed: alpha is 1", worst(gpu(dict(reseed=1.0), src=src)[..., 3], 1.0), 0.0)
    check("bypass: alpha is 1", worst(gpu(dict(bypass_gate=1.0), src=src)[..., 3], 1.0), 0.0)


def test_inject_one_is_the_source():
    check("inject 1: the source, exactly", worst(gpu(dict(inject=1.0)), SRC), 1e-6)


def test_freeze_holds_the_previous_frame_exactly():
    """FR-007 and the float32 identity-drift finding: a frozen frame is the previous frame bit for bit (texel-centre
    reads, never a resample), whatever the pull would have done."""
    rng = np.random.default_rng(3)
    prev = rng.uniform(0.0, 1.0, (H, W, 4)).astype(np.float32)
    prev[..., 3] = 1.0
    for label, params in (("defaults", {}), ("cubed, wrap, offset", dict(pwr=3.0, edge=1.0, radius=0.7))):
        out = gpu(dict(freeze_on=1.0, **params), prev=prev)
        check(f"freeze [{label}]: identical to the previous frame", worst(out, prev), 0.0)


def test_reseed_and_bypass_take_the_source():
    check("reseed 1: the source, exactly", worst(gpu(dict(reseed=1.0)), SRC), 0.0)
    check("bypass 1: the source, exactly", worst(gpu(dict(bypass_gate=1.0)), SRC), 0.0)
    check("reseed beats freeze", worst(gpu(dict(reseed=1.0, freeze_on=1.0)), SRC), 0.0)


def test_nonfinite_source_is_guarded():
    src = SRC.copy()
    src[10, 20] = (np.nan, 1.0, 0.5, 1.0)
    src[30, 40] = (np.inf, -np.inf, 0.5, 1.0)
    out = gpu({}, src=src)
    check("NaN / Inf source: output finite", 0 if np.isfinite(out).all() else 1, 0)
    outf = gpu(dict(freeze_on=1.0), src=src)
    check("NaN / Inf source while frozen: the previous frame still, exactly", worst(outf, PREV), 0.0)


def test_pass_stage_copies_and_guards():
    """codebox_cmap_pass.gen: an exact copy of finite values; NaN / Inf channels read 0 (NF-003)."""
    rng = np.random.default_rng(5)
    img = rng.uniform(-3.0, 3.0, (H, W, 4)).astype(np.float32)
    out, r = bc.run_pass(PASS_CODE, [img], dim=(W, H), params={}, timeout_ms=30000)
    assert r["status"] == "ok", r
    check("pass: finite values copied exactly", worst(out, img), 0.0)
    bad = img.copy()
    bad[5, 6, 0] = np.nan
    bad[7, 8, 1] = np.inf
    bad[9, 10, 2] = -np.inf
    bad[11, 12, 3] = np.nan
    out, r = bc.run_pass(PASS_CODE, [bad], dim=(W, H), params={}, timeout_ms=30000)
    assert r["status"] == "ok", r
    want = bad.copy()
    want[5, 6, 0] = want[7, 8, 1] = want[9, 10, 2] = want[11, 12, 3] = 0.0
    check("pass: non-finite channels read 0, the rest exact", worst(out, want), 0.0)


def test_five_frames_follow_the_mirror():
    """Ping-pong through the bench: each frame's output is the next frame's history, w moves with the clock phases."""
    src_seq = [smooth(0.3 * k) for k in range(6)]
    g_prev = m_prev = src_seq[0]
    for k in range(1, 6):
        p = dict(theta_clk=0.04 * k, phase_clk=0.057 * k, angle=0.1, sweep=0.3, radius=0.35, inject=0.1, decay=0.98)
        g_prev = gpu(p, src=src_seq[k], prev=g_prev)
        m_prev = mirror(p, src=src_seq[k], prev=m_prev)
        mx, mean, frac = stats(g_prev, m_prev)
        note(f"frame {k}", f"max {mx:.4f}  mean {mean:.2e}  frac {frac:.4f}")
    check("frame 5: mean error vs the mirror", mean, 4 * MEAN_TOL)
    check("frame 5: share of pixels off", frac, 4 * FRAC_TOL)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
