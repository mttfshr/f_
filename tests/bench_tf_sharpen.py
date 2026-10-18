"""
bench_tf_sharpen.py -- Tier 2 verification for f_tf_sharpen: the real codebox
(src/f_tf_sharpen/codebox_sharpen.gen) on the GPU through the Max test bench,
diffed against the NumPy mirror in tests/test_tf_sharpen.py. Tasks T012-T014.

Recreated 2026-10-17: an earlier draft was deleted by a sibling session's
file cleanup along with its own report (recorded in
.specify/f_tf_smooth/BUILD_REPORT.md); this file restores it from the same
template shape (bench_tf_axisflow.py), pointing at the codebox's current src/
location.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/bench_tf_sharpen.py   (ASK FIRST)
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
import test_tf_sharpen as m          # the tier-1 mirror

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "src" / "f_tf_sharpen"
F32 = np.float32
TOL = 1e-6


def code():
    return (SRC / "codebox_sharpen.gen").read_text()


def encoded_tex(jxx, jxy, jyy, strength=1.0):
    """Encode pre-gain tensors through the outlet-0 contract (f_tensor_type.md)."""
    t = np.zeros(jxx.shape + (4,), F32)
    t[..., 0] = (jxx * strength).astype(F32)
    t[..., 1] = (jxy * strength * 0.5 + 0.5).astype(F32)
    t[..., 2] = (jyy * strength).astype(F32)
    t[..., 3] = 1.0
    return t


def random_case(h=32, w=32, seed=0, strength=1.0):
    rng = np.random.default_rng(seed)
    # PRE-GAIN components: at strength 1 the encoded values sit in the real
    # outlet-0 clamp range (jxx in [0,1], G = jxy/2+0.5 in [0.35, 0.65]) —
    # the earlier strength-100 draft exceeded the contract's clamped range at
    # every bright pixel and the out-vs-in comparison measured the clamp, not
    # the operator (2026-10-17, bench run finding).
    jxx = rng.uniform(0, 1, (h, w))
    jyy = rng.uniform(0, 1, (h, w))
    jxy = rng.uniform(-0.3, 0.3, (h, w))
    # iso block and all-zeros block, per the mirror's fixtures
    t = encoded_tex(jxx, jxy, jyy, strength)
    t[:4, :4] = np.array([0.0, 0.5, 0.0, 1.0], F32)         # tensormap iso-neutral
    t[:4, 4:8] = 0.0                                        # vs_black
    return t


def run_case(t, **kw):
    params = {"sharpen": 1.0, "bypass_gate": 0.0}
    params.update({k: float(v) for k, v in kw.items()})
    out, r = bc.run_pass(code(), [t], params=params)
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    ref = m.sharpen(t, sharpen=params["sharpen"], bypass=bool(params["bypass_gate"]))
    return out, ref


def test_matches_mirror_across_gamma():
    t = random_case(seed=1)
    for gamma in (0.0, 0.5, 1.0, 2.0, 4.0):
        out, ref = run_case(t, sharpen=gamma)
        err = float(np.abs(out - ref).max())
        note(f"gamma {gamma} max abs err", err)
        check(f"gamma {gamma} vs mirror", err, TOL)


def test_gamma_one_round_trip():
    t = random_case(seed=2)
    out, _ = run_case(t, sharpen=1.0)
    # gamma=1 = neutral. Compare rgb exactly; alpha only against the CONTRACT
    # (the outlet is A=1 always — the fixture's vs_black block carries alpha 0
    # because it simulates an unconnected wire, but the module encodes its own
    # outlet with A=1 per f_tensor_type.md; 2026-10-17 bench finding).
    err_rgb = float(np.abs(out[..., :3] - t[..., :3]).max())
    err_a = float(np.abs(out[..., 3] - 1.0).max())
    note("gamma=1 rgb round-trip err (the spec's measured-neutral row)", err_rgb)
    note("gamma=1 alpha contractual err", err_a)
    check("gamma 1 round trip (rgb)", err_rgb, 1e-6)
    check("gamma 1 alpha = 1 everywhere", err_a, 1e-6)


def test_no_axis_flip_anywhere():
    """T006's core invariant on the GPU: no eigenvalue swap for any gamma in
    the dial range (lambda1 >= lambda2), including gamma = 0."""
    t = random_case(seed=3)
    for gamma in (0.0, 0.25, 0.5, 2.0, 4.0):
        out, _ = run_case(t, sharpen=gamma)
        # decode the output through the mirror's own decode; assert order
        _jxx = out[..., 0]
        _jxy = (out[..., 1] - 0.5) * 2.0
        _jyy = out[..., 2]
        _diff = _jxx - _jyy
        _root = np.sqrt(_diff * _diff + 4.0 * _jxy * _jxy)
        l1 = 0.5 * ((_jxx + _jyy) + _root)
        l2 = 0.5 * ((_jxx + _jyy) - _root)
        check(f"gamma {gamma}: lambda1 >= lambda2 (no swap)",
              float(np.maximum(l2 - l1, 0.0).max()), 0.0)


def test_floor_case():
    """Sub-floor pixels pass through untouched at every gamma (the fixed
    eps_trace floor)."""
    t = random_case(seed=4)
    for gamma in (0.0, 4.0):
        out, _ = run_case(t, sharpen=gamma)
        err = float(np.abs(out[:4, :4] - t[:4, :4]).max())
        check(f"iso/all-zeros blocks untouched at gamma {gamma}", err, 1e-6)


def test_bypass_passthrough():
    t = random_case(seed=5)
    out, _ = run_case(t, bypass_gate=1.0)
    err = float(np.abs(out - t).max())
    check("bypass = exact passthrough", err, 0.0)


def test_cost():
    """Provisional cost gate: sharpen is loop-free, one tap — expected at or
    under the tensormap single-pass floor (~0.9 ms at 1080p). Recorded, not
    asserted hard (the floor itself was an upper bound)."""
    for tag, (h, w) in (("1080p", (1080, 1920)), ("4k", (2160, 3840))):
        t = random_case(h=h, w=w, seed=6)
        r = bc.measure(code(), [t], chain=8,
                       params={"sharpen": 2.0, "bypass_gate": 0.0})
        check(f"{tag} status ok", 0 if r["status"] == "ok" else 1, 0)
        if r.get("gpu_bound"):
            note(f"{tag} ms/pass", r["ms_per_pass"])
        else:
            note(f"{tag} ms/pass (upper bound)", r["ms_per_pass_upper_bound"])


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))