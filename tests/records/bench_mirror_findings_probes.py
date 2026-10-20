"""
bench_mirror_findings_probes.py -- GPU probes for four questions the tier-1 mirror work
(omp runs mirror-build-1 to mirror-build-3, 2026-10-19/20) could not answer offline.
These answer OPEN QUESTIONS, so most tests print measured facts (note) and assert only
what the design already depends on; the answers belong in the modules' tasks.md "Findings"
and in HANDOFF. Kept as a record of bench-verified facts, not as a regression gate.

  P1 stereo pole     the mirror folds atan2(0, 0) to 0, so the exact-centre texel shows the
                     pole; the GPU's atan2(0, 0) is NaN. What does the centre texel render?
  P2 sirds shift     what does GenExpr sample() do for a uv below 0 (and above 1): clamp to
                     the edge, or wrap? (f_sirds strip 1 reads x - strip_width + shift < 0.)
  P3 chladni 127     with z_pos clamped to z7 (2026-10-20), does mode 0 at note 127 on the GPU
                     equal the pure mode-7 pattern? And did the old, unclamped code really
                     blank mode 0 on the GPU, or only in float32 NumPy?
  P4 luma gray       a gray texel (r = g = b) gives hue 1/3 in the mirror (green, not
                     colorsys' hue 0). Does the GPU agree, and what does it render?
  P5 atan2(0, 0)     what does the GPU return for atan2(0, 0) (and for a zero y with a tiny x)?
                     (P1 showed the stereo pole texel is finite but not the mirror's value.)
  P6 exact seam      sample() at exactly u = 1.0 and u = 0.0, as a literal and as a runtime
                     value: edge texel (clamp) or the 50/50 seam blend (wrap)? (Follow-up to P2.)

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/records/bench_mirror_findings_probes.py
"""
GROUP = "record"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group

import importlib.util
import sys

import numpy as np

import benchclient as bc
from gpu_sim import grid
from harness import check, note, run
from paths import REPO

from chladni_mirror import chladni as chladni_mirror
from luma_processor_mirror import luma_processor as luma_mirror
from stereo_mirror import stereo as stereo_mirror

F32 = np.float32


def _read(rel):
    return (REPO / rel).read_text()


def _ramp(h, w):
    """R = x, G = y at texel centres, B = 0, A = 1: a sampled value is its own coordinate."""
    nx, ny, _, _ = grid(h, w)
    t = np.zeros((h, w, 4), F32)
    t[..., 0], t[..., 1], t[..., 3] = nx, ny, 1.0
    return t


def _status(r):
    for e in r["errors"]:
        print(f"      error text: {e}")
    return 0 if r["status"] == "ok" else 1


# ------------------------------------------------------------------ P1: stereo pole

def test_p1_stereo_pole_texel():
    """An odd texture puts a texel exactly at norm = 0.5. Default dials on a ramp: report the GPU
    and mirror values at that texel, and the worst GPU-vs-mirror difference everywhere else."""
    n = 33
    src = _ramp(n, n)
    out, r = bc.run_pass(_read("src/f_stereo/codebox_v1.gen"), [src])
    check("status ok", _status(r), 0)
    ref = stereo_mirror(src)
    c = n // 2
    note("GPU centre texel RGBA", [float(v) for v in out[c, c]])
    note("mirror centre texel RGBA", [float(v) for v in ref[c, c]])
    note("GPU centre texel finite", bool(np.isfinite(out[c, c]).all()))
    mask = np.ones((n, n), bool)
    mask[c - 1:c + 2, c - 1:c + 2] = False
    both = np.isfinite(out).all(-1) & np.isfinite(ref).all(-1) & mask
    note("worst GPU-vs-mirror difference away from the centre (finite texels)", float(np.abs(out - ref)[both].max()))
    note("non-finite GPU texels anywhere", int((~np.isfinite(out).all(-1)).sum()))


# ------------------------------------------------------------------ P2: sample() outside [0, 1]

def test_p2_sample_below_zero_clamps_or_wraps():
    """out1 = sample(in1, vec(norm.x - 0.25, norm.y, 0)) on an x-ramp: the first quarter of the columns
    reads uv.x < 0. Clamp-to-edge returns the first texel centre (0.5 / W); wrap returns x + 0.75."""
    h, w = 8, 64
    src = _ramp(h, w)
    code = "out1 = sample(in1, vec(norm.x - 0.25, norm.y, 0));\n"
    out, r = bc.run_pass(code, [src])
    check("status ok", _status(r), 0)
    nx = src[0, :, 0]
    below = nx < 0.25
    clamp_expect = np.full(below.sum(), 0.5 / w)
    wrap_expect = nx[below] + 0.75
    got = out[0, below, 0]
    e_clamp = float(np.abs(got - clamp_expect).max())
    e_wrap = float(np.abs(got - wrap_expect).max())
    note("below 0: worst |GPU - clamp-to-edge|", e_clamp)
    note("below 0: worst |GPU - wrap|", e_wrap)
    note("verdict for uv < 0", "CLAMP" if e_clamp < 1e-3 < e_wrap else "WRAP" if e_wrap < 1e-3 < e_clamp else "NEITHER (read the numbers)")
    code_hi = "out1 = sample(in1, vec(norm.x + 0.25, norm.y, 0));\n"
    out2, r2 = bc.run_pass(code_hi, [src])
    check("status ok (uv > 1)", _status(r2), 0)
    above = nx > 0.75
    e_clamp_hi = float(np.abs(out2[0, above, 0] - (1.0 - 0.5 / w)).max())
    e_wrap_hi = float(np.abs(out2[0, above, 0] - (nx[above] - 0.75)).max())
    note("above 1: worst |GPU - clamp-to-edge|", e_clamp_hi)
    note("above 1: worst |GPU - wrap|", e_wrap_hi)


# ------------------------------------------------------------------ P3: chladni note 127

def _chladni_code():
    spec = importlib.util.spec_from_file_location("_def_chladni", REPO / "src" / "f_chladni" / "definition.py")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m.patcher["codebox"]


def _run_chladni(code, params, n=64):
    outs, r = bc.run_pass(code, [np.zeros((n, n, 4), F32)], params=params, all_outputs=True)
    return outs, r


def test_p3_chladni_note_127_fixed_on_the_gpu():
    """Shipped (clamped) codebox: mode 0 at note 127 must equal the pure mode-7 pattern, which mode 1
    with the narrowest spread gives. The unclamped expression is also run, to see whether the GPU
    ever showed the dead zone (a note, not an assert)."""
    code = _chladni_code()
    a, ra = _run_chladni(code, {"note": 127.0, "mode": 0.0})
    b, rb = _run_chladni(code, {"note": 127.0, "mode": 1.0, "spread": 0.1})
    check("status ok (mode 0)", _status(ra), 0)
    check("status ok (mode 1)", _status(rb), 0)
    a3, b3 = a[2], b[2]
    check("GPU note 127: mode 0 equals the pure mode-7 pattern (out3)", float(np.abs(a3 - b3).max()), 1e-4)
    check("GPU note 127, mode 0 is not blank (out3 reaches at least 0.05)", max(0.0, 0.05 - float(a3[..., :3].max())), 0.0)
    clamped = "z_pos = min(z0 + (note / 127.0) * (z7 - z0), z7);"
    unclamped = "z_pos = z0 + (note / 127.0) * (z7 - z0);"
    assert clamped in code, "the shipped codebox no longer contains the clamp line this probe replaces"
    old, ro = _run_chladni(code.replace(clamped, unclamped), {"note": 127.0, "mode": 0.0})
    check("status ok (unclamped)", _status(ro), 0)
    peak = float(old[2][..., :3].max())
    note("UNCLAMPED codebox, note 127, mode 0: out3 peak on the GPU", peak)
    note("verdict for the old code on the GPU", "BLANK (the dead zone was real on the GPU)" if peak < 1e-6 else "NOT BLANK (only float32 NumPy showed the dead zone)")


# ------------------------------------------------------------------ P4: luma gray texel

def test_p4_luma_gray_texel_hue():
    """Gray 0.6 everywhere, sat_amt 0.6, a generic band. The mirror gives (0.24, 0.6, 0.24) (hue 1/3);
    colorsys' hue 0 would give (0.6, 0.24, 0.24). Report what the GPU renders."""
    n = 24
    src = np.zeros((n, n, 4), F32)
    src[..., :3], src[..., 3] = 0.6, 1.0
    params = {"low_mid": 0.2, "mid_high": 0.8, "edge_falloff": 0.05, "sat_amt": 0.6}
    out, r = bc.run_pass(_read("src/f_luma_processor/codebox_luma_processor.gen"), [src], params=params)
    check("status ok", _status(r), 0)
    ref = luma_mirror(src, 0.2, 0.8, 0.05, sat_amt=0.6)
    px = [float(v) for v in out[n // 2, n // 2]]
    note("GPU gray texel RGBA", px)
    note("mirror gray texel RGBA", [float(v) for v in ref[n // 2, n // 2]])
    note("worst |GPU - mirror| over the frame", float(np.abs(out - ref).max()))
    e_green = float(np.abs(np.array(px[:3]) - np.array([0.24, 0.6, 0.24])).max())
    e_red = float(np.abs(np.array(px[:3]) - np.array([0.6, 0.24, 0.24])).max())
    note("verdict", "GREEN (hue 1/3, as the mirror)" if e_green < 1e-3 else "RED (hue 0, colorsys)" if e_red < 1e-3 else "OTHER (read the numbers)")


# ------------------------------------------------------------------ P5: atan2(0, 0)

def test_p5_atan2_zero_zero():
    """An odd texture puts a texel at norm = 0.5 exactly, so dx = dy = 0 there at run time (not folded at
    compile time). The angle is encoded as a / (2 pi) + 0.5; report the decoded value at the centre texel
    and at its horizontal neighbours (dy = 0, dx = -/+ 1/66, where atan2 is 0 or pi)."""
    n = 33
    code = ("dx = norm.x - 0.5;\n"
            "dy = norm.y - 0.5;\n"
            "a = atan2(dy, dx);\n"
            "out1 = vec(a * 0.15915494 + 0.5, 0.0, 0.0, 1.0);\n")
    out, r = bc.run_pass(code, [np.zeros((n, n, 4), F32)])
    check("status ok", _status(r), 0)
    c = n // 2
    two_pi = 2.0 * np.pi
    for label, (y, x) in (("centre (dx = 0, dy = 0)", (c, c)), ("left neighbour (dx < 0, dy = 0)", (c, c - 1)),
                          ("right neighbour (dx > 0, dy = 0)", (c, c + 1))):
        v = float(out[y, x, 0])
        note(f"{label}: raw encoded value", v)
        if np.isfinite(v):
            note(f"{label}: decoded angle (radians)", (v - 0.5) * two_pi)
        else:
            note(f"{label}: NON-FINITE (NaN or Inf)", True)


# ------------------------------------------------------------------ P6: sample() exactly at the seam

def test_p6_sample_at_exact_seam():
    """x-ramp, 64 wide. u = 1.0 exactly: clamp gives the last texel centre (1 - 0.5/W = 0.9922), wrap gives
    the blend of the last and first texels (0.5). u = 0.0 exactly: clamp gives 0.5/W = 0.0078, wrap 0.5.
    Run with a literal (the SKILL warns about stored variables) and with a run-time value."""
    h, w = 8, 64
    src = _ramp(h, w)
    cases = {
        "u = 1.0 literal": "out1 = sample(in1, vec(1.0, norm.y, 0));\n",
        "u = 0.0 literal": "out1 = sample(in1, vec(0.0, norm.y, 0));\n",
        "u = 1.0 run-time (norm.x * 0 + 1)": "out1 = sample(in1, vec(norm.x * 0.0 + 1.0, norm.y, 0));\n",
        "u = 0.0 run-time (norm.x * 0)": "out1 = sample(in1, vec(norm.x * 0.0, norm.y, 0));\n",
    }
    for label, code in cases.items():
        out, r = bc.run_pass(code, [src])
        check(f"status ok ({label})", _status(r), 0)
        v = float(out[0, w // 2, 0])
        edge = 1.0 - 0.5 / w if "1.0" in label else 0.5 / w
        kind = "CLAMP (edge texel)" if abs(v - edge) < 1e-3 else "WRAP (seam blend)" if abs(v - 0.5) < 1e-3 else "OTHER (read the value)"
        note(f"{label}: value {v:.5f}; clamp would be {edge:.5f}, wrap 0.50000", kind)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
