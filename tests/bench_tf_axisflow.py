"""
bench_tf_axisflow.py -- Tier 2 verification for f_tf_axisflow: the real codebox
(src/f_tf_axisflow/codebox_axisflow.gen) on the GPU through the Max test bench,
diffed against the NumPy mirror in tests/test_tf_axisflow.py. Task T008-T009.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/bench_tf_axisflow.py
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
import test_tf_axisflow as m           # the tier-1 mirror

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "src" / "f_tf_axisflow"
F32 = np.float32
TOL = 2e-5


def code():
    return (SRC / "codebox_axisflow.gen").read_text()


def packed(h, w, seed=0, extras=True):
    """Random valid packed tensormap outlet 1, with iso and black pixel blocks mixed in."""
    rng = np.random.default_rng(seed)
    th = rng.uniform(-np.pi, np.pi, (h, w))
    t = np.zeros((h, w, 4), F32)
    t[..., 0] = np.cos(2 * th) * 0.5 + 0.5
    t[..., 1] = np.sin(2 * th) * 0.5 + 0.5
    t[..., 2] = rng.uniform(0, 1, (h, w))
    t[..., 3] = rng.uniform(0, 1, (h, w))
    if extras:
        t[:4, :4] = np.array([0.5, 0.5, 0.0, 0.0], F32)       # tensormap iso
        t[:4, 4:8] = 0.0                                       # vs_black
    return t


def run_case(t, reference=None, **kw):
    """reference: optional in2 f_vecfield; None feeds vs_black (an unconnected inlet)."""
    h, w = t.shape[:2]
    params = {"angle": 0.0, "mode": 0.0, "gain": 1.0, "gate": 1.0,
              "width": float(w), "height": float(h), "bypass_gate": 0.0}
    params.update({k: float(v) for k, v in kw.items()})
    in2 = reference
    if in2 is None:
        in2 = np.zeros((h, w, 4), F32)
        in2[..., 3] = 1.0                                      # vs_black
    out, r = bc.run_pass(code(), [t, in2], params=params)
    check("status ok", 0 if r["status"] == "ok" else 1, 0)
    ref = m.axisflow(t, angle=params["angle"], mode=params["mode"], gain=params["gain"],
                     gate=params["gate"], width=params["width"], height=params["height"],
                     bypass=params["bypass_gate"], ref=reference)
    return out, ref


def test_matches_mirror_modes_and_angles():
    t = packed(64, 64, seed=1)
    for mode in (0, 1):
        for angle in (0, 33, 90, -140):
            for gate in (0, 1):
                out, ref = run_case(t, mode=mode, angle=angle, gate=gate)
                check(f"mode {mode} angle {angle} gate {gate} max abs err",
                      float(np.abs(out - ref).max()), TOL)


def test_iso_and_black_blocks_are_neutral():
    t = packed(64, 64, seed=2)
    out, _ = run_case(t, angle=40, gate=0)
    neutral = np.array([0.5, 0.5, 0.5, 1.0], F32)
    check("iso block neutral", float(np.abs(out[:4, :4] - neutral).max()), 1e-6)
    check("vs_black block neutral", float(np.abs(out[:4, 4:8] - neutral).max()), 1e-6)


def test_gain_clamp():
    t = packed(64, 64, seed=3)
    out, ref = run_case(t, gain=10.0, gate=0)
    check("gain 10 vs mirror (clamped)", float(np.abs(out - ref).max()), TOL)
    check("range within [0,1]", float(max(out.max() - 1.0, -out.min(), 0.0)), 0.0)


def test_aspect_16_9():
    t = packed(72, 128, seed=4)
    out, ref = run_case(t, angle=70, gate=0, width=1920.0, height=1080.0)
    check("16:9 width/height Params vs mirror", float(np.abs(out - ref).max()), TOL)


def test_bypass_gate_is_neutral():
    t = packed(32, 32, seed=5)
    out, ref = run_case(t, bypass_gate=1.0)
    neutral = np.array([0.5, 0.5, 0.5, 1.0], F32)
    check("bypass_gate -> neutral", float(np.abs(out - neutral).max()), 1e-6)


def test_negative_gain_matches_mirror():
    t = packed(64, 64, seed=6)
    for gain in (-0.5, -10.0):
        out, ref = run_case(t, gain=gain, gate=0, angle=25)
        check(f"gain {gain} vs mirror", float(np.abs(out - ref).max()), TOL)


def test_reference_inlet_matches_mirror():
    """in2 (per-pixel reference): a swirl, both modes, angle rotating it, signed gain."""
    t = packed(64, 64, seed=7)
    swirl, _, _ = m._swirl(64)
    for mode in (0, 1):
        for angle in (0, 55):
            for gain in (1.0, -0.5):
                out, ref = run_case(t, reference=swirl, mode=mode, angle=angle, gain=gain, gate=0)
                check(f"reference mode {mode} angle {angle} gain {gain} max abs err",
                      float(np.abs(out - ref).max()), TOL)


def test_black_reference_equals_the_dial():
    """An unconnected in2 (vs_black) must give the original dial behaviour exactly."""
    t = packed(48, 48, seed=8)
    out, _ = run_case(t, angle=70, gate=0)
    dial = m.axisflow(t, angle=70, gate=0.0, width=48.0, height=48.0, ref=None)
    check("vs_black in2 == dial path", float(np.abs(out - dial).max()), TOL)


def test_reference_aspect_16_9():
    t = packed(72, 128, seed=9)
    out, ref = run_case(t, reference=m.refvec(0.3, -0.4, (72, 128)), angle=20, gate=0,
                        width=1920.0, height=1080.0)
    check("16:9 reference vs mirror", float(np.abs(out - ref).max()), TOL)


if __name__ == "__main__":
    sys.exit(run(globals()))
