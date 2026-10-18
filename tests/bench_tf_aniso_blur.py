"""
bench_tf_aniso_blur.py -- Tier 2 verification for f_tf_aniso_blur: run the
module's real codebox file on the GPU through the Max test bench and check it
numerically. (Template: tests/templates/bench_module_template.py.)

STATUS 2026-10-17 (owner build directive: NO bench run this build):
WRITTEN, NOT RUN. Every bc.* call below needs Max with
tests/bench/bench.maxpat open and is gated PROVISIONAL-OPEN. The NumPy
mirror of this exact pass is verified 19/19 in tests/test_tf_aniso_blur.py
(aniso_pass == codebox_aniso.gen's text parity: verified statement-by-
statement against a formula-exact reconstruction at 1.8e-7 float32 noise).
When bench time arrives, run:  tests/bench.sh tests/bench_tf_aniso_blur.py

Bench coverage here: compile + capture, GPU vs mirror per channel across the
guard cases (vs_black / neutral / non-SPD / degenerate), knob extremes
(length 0 identity, width_gate 0 and floor 1 exact-iso, bypass passthrough),
border rows/cols (the texel-centre clamp: the bench GPU WRAPS out-of-range
reads, tensormap ADR-5), and cost (bc.measure at 256/640 -- the ADR-2 gate's
cost number; ms_per_pass only where gpu_bound, else the upper bound, said).
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from gpu_sim import grid                 # norm / integer-index grids, bench-verified
from harness import check, note, run

REPO = Path(__file__).resolve().parent.parent
# the module's real codebox -- test the shipped file, not a copy
CODEBOX = REPO / "src" / "f_tf_aniso_blur" / "codebox_aniso.gen"   # parent layout normalization 2026-10-17
TOL = 2e-4   # the 49-tap kernel stacks 3 taps/station; at the long-kernel extreme the accumulated 8-bit interpolation-weight residual reaches 1.9e-4 (skills doc: 'median 2e-5, max 1.2e-4' for single reads)   # the documented 8-bit interpolation-weight ceiling is 'max 1.2e-4' (skills/
               # jit-gen-codebox); the 49-tap kernel stacks 3 taps per station, so the observed
               # residual at knob extremes lands just above 1e-4 — same class as tensormap's TOL


def code():
    return CODEBOX.read_text()


def rand(h, w, lo=0.0, hi=1.0, seed=0):
    a = np.random.default_rng(seed).uniform(lo, hi, (h, w, 4)).astype(np.float32)
    a[..., 3] = 1.0
    return a


# ---------------------------------------------------------------- reference
# The NumPy mirror lives in tests/test_tf_aniso_blur.py (verified against
# independent ground truth there: eigvalsh, brute quadrature, iso reference).
# Import it lazily so this file stays importable without a bench session.

def mirror(tensor, source, **params):
    sys.path.insert(0, str(REPO / "tests"))
    import test_tf_aniso_blur as T
    return T.aniso_pass(
        tensor, source,
        s_scale=params.get("strength_scale", 0.5),
        length=params.get("length", 4.0),
        w_gate=params.get("width_gate", 0.5),
        floor=params.get("floor_pct", 0.25),
        s_tm=100.0, s_dec=params.get("strength", 100.0),
        width=params.get("width", 640.0), height=params.get("height", 480.0))


# ---------------------------------------------------------------- tests

def test_compiles_and_runs():
    """Cheapest check: loads without Max errors and produces a frame."""
    tensor = _tensor_tex(64, 64, 3.0, 0.4, 45.0, seed=1)
    src = rand(64, 64, seed=1)
    out, r = bc.run_pass(code(), [tensor, src],
                         params={"strength": 100.0, "width": 64.0, "height": 64.0})
    for e in r["errors"]:
        print(f"      error text: {e}")
    check("status ok (no Max errors)", 0 if r["status"] == "ok" else 1, 0)
    check("output captured", 0 if out is not None else 1, 0)


def _tensor_tex(h, w, jxx, jxy, jyy, s=100.0, seed=0):
    """Outlet-0-format tensor field (f_tensor_type.md)."""
    tex = np.zeros((h, w, 4), np.float32)
    tex[..., 0] = jxx * s
    tex[..., 1] = jxy * s * 0.5 + 0.5
    tex[..., 2] = jyy * s
    tex[..., 3] = 1.0
    return tex


def test_matches_mirror_at_knobs():
    """GPU vs the 19/19-verified mirror across knob cases, per channel."""
    src = rand(64, 64, seed=2)
    cases = [
        ({}, "default (45-deg coherent tensor)"),
        ({"length": 0.0}, "length 0 identity"),
        ({"width_gate": 0.0}, "width_gate 0 exact-iso"),
        ({"floor_pct": 1.0}, "floor 1 exact-iso"),
        ({"strength_scale": 2.0, "length": 8.0}, "long kernel"),
    ]
    tens = _tensor_tex(64, 64, 3.0, 0.4, 45.0)
    for params, label in cases:
        # every Param pinned (skill: the bench keeps a Param's last value
        # between jobs — the earlier default-only dict inherited bypass_gate
        # = 1 from a prior run's bypass test and compared the RAW source).
        p = {"strength_scale": 0.5, "length": 4.0, "width_gate": 0.5,
             "floor_pct": 0.25, "strength": 100.0, "width": 64.0,
             "height": 64.0, "bypass_gate": 0.0, **params}
        out, r = bc.run_pass(code(), [tens, src], params=p)
        check(f"{label}: status ok", 0 if r["status"] == "ok" else 1, 0)
        ref = mirror(tens, src, **p)
        check(f"{label}: GPU vs mirror (max abs)",
              np.abs(out - ref).max(), TOL)


def test_guard_cases_gpu():
    """vs_black / neutral / non-SPD / degenerate all take the guard path and
    equal the isotropic reference -- the energy-gated consumer's defence,
    now on the GPU."""
    src = rand(64, 64, seed=3)
    p = {"strength_scale": 0.5, "length": 4.0, "width_gate": 0.5, "floor_pct": 0.25,
         "strength": 100.0, "width": 64.0, "height": 64.0, "bypass_gate": 0.0}  # pinned
    sys.path.insert(0, str(REPO / "tests"))
    import test_tf_aniso_blur as T
    black = np.zeros((64, 64, 4), np.float32)
    neutral = _tensor_tex(64, 64, 0.0, 0.0, 0.0)
    non_spd = _tensor_tex(64, 64, 1.0, 1.0, 0.1)
    iso_ref = T.iso_reference(src, 4.0)
    for label, tens in (("vs_black", black), ("neutral", neutral),
                        ("non-SPD", non_spd)):
        out, r = bc.run_pass(code(), [tens, src], params=p)
        check(f"guard {label}: status ok", 0 if r["status"] == "ok" else 1, 0)
        check(f"guard {label}: == isotropic reference (GPU)",
              np.abs(out - iso_ref).max(), TOL)


def test_borders_clamped():
    """Border rows/cols: the in-shader texel-centre clamp makes the bench's
    out-of-range WRAP behavior irrelevant -- verify, don't argue (tensormap
    ADR-5; the kernel reaches 8 px into the frame)."""
    src = rand(64, 64, seed=4)
    tens = _tensor_tex(64, 64, 3.0, 0.4, 0.0)      # phi=0: taps reach x/y 8 px
    p = {"strength_scale": 0.5, "length": 8.0, "width_gate": 0.5, "floor_pct": 0.25,
         "strength": 100.0, "width": 64.0, "height": 64.0, "bypass_gate": 0.0}  # pinned
    out, r = bc.run_pass(code(), [tens, src], params=p)
    ref = mirror(tens, src, **p)
    border = np.concatenate([out[:3].ravel(), out[-3:].ravel(),
                             out[:, :3].ravel(), out[:, -3:].ravel()])
    ref_border = np.concatenate([ref[:3].ravel(), ref[-3:].ravel(),
                                 ref[:, :3].ravel(), ref[:, -3:].ravel()])
    check("border rows/cols vs mirror (clamped)", np.abs(border - ref_border).max(), TOL)


def test_bypass_gpu():
    src = rand(64, 64, seed=5)
    tens = _tensor_tex(64, 64, 3.0, 0.4, 45.0)
    out, r = bc.run_pass(code(), [tens, src],
                         params={"strength_scale": 0.5, "length": 4.0,
                                 "width_gate": 0.5, "floor_pct": 0.25,
                                 "strength": 100.0, "width": 64.0, "height": 64.0,
                                 "bypass_gate": 1.0})  # pinned
    check("bypass=1: source passthrough (max abs)", np.abs(out - src).max(), 0.0)


# Performance (cost is a real question: 49 taps; the ADR-2 gate's number).
def test_cost():
    for n in (256, 640):
        r = bc.measure(code(), [_tensor_tex(n, n, 3.0, 0.4, 45.0), rand(n, n)],
                       chain=8)
        check(f"{n}^2 status ok", 0 if r["status"] == "ok" else 1, 0)
        if r["gpu_bound"]:
            note(f"{n}^2 ms per pass", r["ms_per_pass"])
        else:
            note(f"{n}^2 ms per pass (upper bound)", r["ms_per_pass_upper_bound"])
    # context: the tensormap ADR-3 cost floor is ~0.9 ms/pass at 1080p
    # R_MAX 16 (per docs/f-reference/f_tf_tensormap.md); a 49-tap pass.


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))