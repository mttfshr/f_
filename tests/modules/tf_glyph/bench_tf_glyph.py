"""
bench_tf_glyph.py -- Tier 2 verification for f_tf_glyph: the real codebox
(src/f_tf_glyph/codebox_glyph.gen) on the GPU through the Max test bench,
diffed against the NumPy mirror in tests/modules/tf_glyph/test_tf_glyph.py. Tasks TG012-TG014.

Recreated 2026-10-17: an earlier draft was deleted by a sibling session's
file cleanup along with its own report (recorded in
.specify/f_tf_smooth/BUILD_REPORT.md); this file restores it from the same
template shape (bench_tf_axisflow.py), pointing at the codebox's current src/
location.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/tf_glyph/bench_tf_glyph.py   (ASK FIRST)
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 130

import paths as _paths
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
import test_tf_glyph as m           # the tier-1 mirror

REPO = _paths.REPO
SRC = REPO / "src" / "f_tf_glyph"
F32 = np.float32
TOL = 1.5e-4   # the hardware's own interpolation weights are 8-bit (skills/jit-gen-codebox: 'error median 2e-5, max 1.2e-4'); the four-tap nearest() reads are exact but the ink multiply chain rounds at that scale on ring edges


def code():
    return (SRC / "codebox_glyph.gen").read_text()


def run_case(t, source=None, **kw):
    h, w = t.shape[:2]
    params = {"grid": 8.0, "glyph_scale": 0.8, "thickness": 0.15,
              "softness": 0.1, "gate": 0.05, "max_aspect": 8.0,
              "width": float(w), "height": float(h), "bypass_gate": 0.0}
    params.update({k: float(v) for k, v in kw.items()})
    ins = [t] + ([source] if source is not None else [])
    out, r = bc.run_pass(code(), ins, params=params)
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    ref = m.glyph(t, source=source, grid=params["grid"],
                  scale=params["glyph_scale"], thickness=params["thickness"],
                  softness=params["softness"], gate=params["gate"],
                  max_aspect=params["max_aspect"],
                  bypass_gate=params["bypass_gate"], tex_w=w, tex_h=h)
    return out, ref


def random_tensor(h=64, w=64, seed=0):
    rng = np.random.default_rng(seed)
    jxx = rng.uniform(0, 1, (h, w))
    jyy = rng.uniform(0, 1, (h, w))
    jxy = rng.uniform(-0.4, 0.4, (h, w))
    s = F32(100.0)
    t = np.zeros((h, w, 4), F32)
    t[..., 0] = (jxx * s).astype(F32)
    t[..., 1] = (jxy * s * 0.5 + 0.5).astype(F32)
    t[..., 2] = (jyy * s).astype(F32)
    t[..., 3] = 1.0
    # iso block and all-zeros block, per the mirror's fixtures
    t[:4, :4] = np.array([0.0, 0.5, 0.0, 1.0], F32)
    t[:4, 4:8] = 0.0                                        # vs_black
    return t


def test_matches_mirror():
    t = random_tensor(seed=1)
    src = np.random.default_rng(2).uniform(0, 1, (64, 64, 4)).astype(F32)
    out, ref = run_case(t, source=src)
    err = float(np.abs(out - ref).max())
    note("max abs err vs mirror", err)
    check("glyph vs mirror max abs err", err, TOL)


def test_borders_and_lattice_grids():
    t = random_tensor(64, 97, seed=3)                       # non-square
    src = np.random.default_rng(4).uniform(0, 1, (64, 97, 4)).astype(F32)
    for grid in (2, 7, 16):
        out, ref = run_case(t, source=src, grid=float(grid))
        err = float(np.abs(out - ref).max())
        note(f"grid {grid} max abs err", err)
        check(f"grid {grid} vs mirror (border cells included)", err, TOL)


def test_all_zeros_renders_empty_even_at_gate_zero():
    t = np.zeros((16, 16, 4), F32)
    src = np.ones((16, 16, 4), F32)
    out, ref = run_case(t, source=src, gate=0.0)
    err = float(np.abs(out - ref).max())
    check("all-zeros unconnected tensor vs mirror at gate 0", err, TOL)


def test_gain_free_identity():
    # gain-free identity: draw must be invariant under the ENCODING gain.
    # The x10 case must be a RE-ENCODE at 10x strength (G's +0.5 offset is
    # absolute: naively multiplying the encoded texture by 10 turns it into
    # +5.0 and changes the decoded Jxy -- the fixture bug this test used to
    # have, 2026-10-17), not a raw multiply of the encoded texture.
    srng = np.random.default_rng(6)
    src = srng.uniform(0, 1, (64, 64, 4)).astype(F32)
    rng = np.random.default_rng(51)
    jxx = rng.uniform(0, 1, (64, 64)) * 0.01     # pre-gain; keep trace small
    jyy = rng.uniform(0, 1, (64, 64)) * 0.01     # so x10 stays inside sane range
    jxy = rng.uniform(-0.1, 0.1, (64, 64)) * 0.01

    def enc(jxx, jxy, jyy, s):
        t = np.zeros((64, 64, 4), F32)
        t[..., 0] = (jxx * s).astype(F32)
        t[..., 1] = (jxy * s * 0.5 + 0.5).astype(F32)
        t[..., 2] = (jyy * s).astype(F32)
        t[..., 3] = 1.0
        return t

    t1 = enc(jxx, jxy, jyy, 100.0)
    t2 = enc(jxx, jxy, jyy, 1000.0)
    out1, _ = run_case(t1, source=src)
    out2, _ = run_case(t2, source=src)
    err = float(np.abs(out1 - out2).max())
    note("re-encoded x10 identity err", err)
    check("gain-free identity on GPU", err, TOL)


def test_bypass_passthrough():
    t = random_tensor(seed=7)
    src = np.random.default_rng(8).uniform(0, 1, (64, 64, 4)).astype(F32)
    out, ref = run_case(t, source=src, bypass_gate=1.0)
    err = float(np.abs(out - ref).max())
    check("bypass = source passthrough", err, TOL)


def test_cost_1080p_and_4k():
    """TG013's resolving experiment (the kernel-family/cost gate closes with
    these numbers). Chain=1; report ms per pass, GPU-bound or upper bound."""
    t = random_tensor(1080, 1920, seed=9)
    src = np.random.default_rng(10).uniform(0, 1, (1080, 1920, 4)).astype(F32)
    for tag, (h, wn) in (("1080p", (1080, 1920)), ("4k", (2160, 3840))):
        tt = random_tensor(h, wn, seed=11)
        ss = np.random.default_rng(12).uniform(0, 1, (h, wn, 4)).astype(F32)
        r = bc.measure(code(), [tt, ss],
                       params={"grid": 24.0, "glyph_scale": 0.8, "thickness": 0.15,
                               "softness": 0.1, "gate": 0.05, "max_aspect": 8.0,
                               "width": float(wn), "height": float(h),
                               "bypass_gate": 0.0})
        check(f"{tag} status ok", 0 if r["status"] == "ok" else 1, 0)
        if r.get("gpu_bound"):
            note(f"{tag} ms/pass", r["ms_per_pass"])
        else:
            note(f"{tag} ms/pass (upper bound)", r["ms_per_pass_upper_bound"])


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))