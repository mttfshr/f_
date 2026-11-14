"""
bench_boundmode_probes.py -- GPU probes for the out-of-range questions bench_mirror_findings_probes.py (P2, P6, P7,
P9) left open, written 2026-11-14 to settle jit-gen-codebox's conflicting boundmode entries before the skill is
shared. Record, not a regression gate: tests print measured facts (note) and assert only that the bench ran.

  B1 boundmode=      does sample()/nearest() accept a boundmode keyword ("clamp", "wrap", "mirror", and a bogus
                     value as a control), and does it change what an out-of-range coordinate reads, on x and on y?
  B2 nearest() OOB   what a bare nearest() reads below 0, above 1 and at exactly 0.0 / 1.0, on both axes (never
                     probed; gpu_sim assumes clamp).

Inputs reach the codebox the way the bench feeds every probe: as a pix-to-pix texture (see gpu_sim.py). A
matrix-fed input (jit.matrix / jit.movie into the pix) is NOT covered here.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/records/bench_boundmode_probes.py -q
"""
GROUP = "record"

import sys

import numpy as np

import benchclient as bc
from gpu_sim import grid
from harness import check, note, run

F32 = np.float32
N = 64


def _ramp(h, w):
    """R = x, G = y at texel centres, B = 0, A = 1: a sampled value is its own coordinate."""
    nx, ny, _, _ = grid(h, w)
    t = np.zeros((h, w, 4), F32)
    t[..., 0], t[..., 1], t[..., 3] = nx, ny, 1.0
    return t


def _centre(c):
    """The texel centre nearest() should return for coordinate c (inside [0, 1))."""
    return (np.floor(c * N) + 0.5) / N


def _classify(got, expectations, tol):
    errs = {k: float(np.abs(got - v).max()) for k, v in expectations.items()}
    hits = [k for k, e in errs.items() if e < tol]
    return (hits[0].upper() if len(hits) == 1 else "AMBIGUOUS " + "/".join(hits) if hits else "NEITHER"), errs


def _pass(code, src, label):
    """Run one job; on a compile failure note the error and re-probe the bench (a failed compile can wedge it)."""
    out, r = bc.run_pass(code, [src])
    if r["status"] != "ok":
        note(f"{label}: DID NOT COMPILE", "; ".join(r["errors"]) or r["status"])
        bc.ensure_healthy()
        return None
    return out


# ------------------------------------------------------------------ B1: the boundmode keyword

def _expect(op, c):
    """Expected reads for coordinate c in (-0.2, -0.05), per behaviour, for a ramp whose value is its coordinate."""
    f = _centre if op == "nearest" else (lambda v: v)
    return {"clamp": np.full_like(c, 0.5 / N), "wrap": f(c + 1.0), "mirror": f(-c)}


def test_b1_boundmode_keyword():
    """Coordinate norm - 0.25 on one axis; read the texels whose coordinate lands in (-0.2, -0.05), well away
    from any seam or edge texel, so clamp, wrap and mirror give clearly different values."""
    x_src, y_src = _ramp(8, N), _ramp(N, 8)
    nx = x_src[0, :, 0]
    sel = (nx - 0.25 > -0.2) & (nx - 0.25 < -0.05)
    c = nx[sel] - 0.25
    for op in ("sample", "nearest"):
        for mode in (None, "clamp", "wrap", "mirror", "bogus"):
            arg = "" if mode is None else f', boundmode="{mode}"'
            label = f"{op}{'' if mode is None else ' boundmode=' + mode}"
            for axis in ("x", "y"):
                coord = "vec(norm.x - 0.25, norm.y, 0)" if axis == "x" else "vec(norm.x, norm.y - 0.25, 0)"
                out = _pass(f"out1 = {op}(in1, {coord}{arg});\n", x_src if axis == "x" else y_src, f"{label} ({axis})")
                if out is None:
                    continue
                got = out[0, sel, 0] if axis == "x" else out[sel, 0, 1]
                verdict, errs = _classify(got, _expect(op, c), 2e-3)
                note(f"{label} ({axis}, coord < 0): {verdict}", {k: round(v, 5) for k, v in errs.items()})
    check("bench reachable after the run", 0 if bc.ping() else 1, 0)


# ------------------------------------------------------------------ B2: nearest() out of range and at the seams

def test_b2_nearest_out_of_range():
    """Bare nearest() on an x-ramp and a y-ramp: coordinate -0.2, 1.3, exactly 0.0, exactly 1.0, as literals."""
    first, last = 0.5 / N, 1.0 - 0.5 / N
    for axis, src, chan in (("x", _ramp(8, N), 0), ("y", _ramp(N, 8), 1)):
        for lit, clamp_v, wrap_v in (("-0.2", first, _centre(0.8)), ("1.3", last, _centre(0.3)),
                                     ("0.0", first, first), ("1.0", last, first)):
            coord = f"vec({lit}, norm.y, 0)" if axis == "x" else f"vec(norm.x, {lit}, 0)"
            out = _pass(f"out1 = nearest(in1, {coord});\n", src, f"nearest {axis} = {lit}")
            if out is None:
                continue
            v = float(out[N // 2, 4, chan]) if axis == "y" else float(out[4, N // 2, chan])
            exp = {"clamp (edge)": clamp_v, "wrap": wrap_v}
            if lit in ("0.0", "1.0"):
                exp = {"first texel": first, "last texel": last}
            hits = [k for k, e in exp.items() if abs(v - e) < 1e-3]
            note(f"nearest {axis} = {lit}: value {v:.5f}", hits[0].upper() if len(hits) == 1 else "OTHER")


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
