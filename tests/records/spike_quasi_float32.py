"""spike_quasi_float32.py -- f_quasi T002: float32 versus float64 for the potential (NF-002).

psi reaches about 1.6e3 rad at the finest octave. NumPy's float32 cos is not the GPU's cos, so
this measures the part the mirror can see: rounding in the float32 argument psi and in the sums.
GPU cos accuracy is a tier-2 question (T006 / T020 bench).

Compared on random points over a 16:9 frame (frame-height units), zoom 0.0 / 0.5 / 0.999,
density 1 / 4 / 8 / 12, envelope 0.5 / 1.0:
  A  the spec form: psi = (beta + p) s + d * 2 pi B s                       (float32)
  B  cycles form:   c = B s d + (beta + p) s / (2 pi), psi = 2 pi frac(c)    (float32)
  C  psi from float64 rounded to float32 once, cos in float64 (isolates the argument rounding)
Also: why beta must be a literal (float32 exp(4 pi) has an ulp of 0.031).

Run: uv run --no-project --with numpy python3 tests/records/spike_quasi_float32.py
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "lib"))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "quasi"))

import numpy as np  # noqa: E402

import quasi_mirror as q  # noqa: E402

F32, F64 = np.float32, np.float64
rng = np.random.default_rng(11)
X = rng.uniform(-0.889, 0.889, 20000)
Y = rng.uniform(-0.5, 0.5, 20000)


def p_variant(variant, zoom, density, env):
    _, w, s = q.octave_terms(zoom, env, F64)
    b = q.betas(F64)
    k = np.arange(5, dtype=F64)
    phi = k * np.pi / 5
    num = np.zeros_like(X)
    for i in range(7):
        for kk in range(5):
            d64 = np.cos(phi[kk]) * X + np.sin(phi[kk]) * Y
            if variant == "A":
                x, y = X.astype(F32), Y.astype(F32)
                d = F32(np.cos(phi[kk])) * x + F32(np.sin(phi[kk])) * y
                psi = (F32(b[kk]) + F32(0)) * F32(s[i]) + d * (F32(2 * np.pi * density) * F32(s[i]))
                c = np.cos(psi).astype(F64)
            elif variant == "B":
                x, y = X.astype(F32), Y.astype(F32)
                d = F32(np.cos(phi[kk])) * x + F32(np.sin(phi[kk])) * y
                cyc = F32(density) * F32(s[i]) * d + F32(b[kk] * s[i] / (2 * np.pi))
                psi = F32(2 * np.pi) * (cyc - np.floor(cyc))
                c = np.cos(psi).astype(F64)
            else:
                psi = (b[kk]) * s[i] + d64 * (2 * np.pi * density * s[i])
                c = np.cos(psi.astype(F32).astype(F64))
            num += w[i] * c
    return num / (5 * w.sum())


def main():
    print("beta literals (float64):", np.array2string(q.betas(F64), precision=6))
    e32 = F32(np.exp(F32(np.pi) * F32(4)))
    print(f"float32 exp(4 pi) = {float(e32):.3f}, ulp {float(np.spacing(e32)):.4f}; "
          f"frac float32 {float(e32 - np.floor(e32)):.4f} vs float64 {q.betas(F64)[4]:.4f}")
    print(f"max |psi| at density 12, zoom 0.999, scale 2^6.999: "
          f"{2 * np.pi * 12 * 2 ** 6.999 * 1.02:.0f} rad (frame corner)")
    print()
    print("zoom  dens  env |  max|dP|  A (spec form)   B (cycles)   C (psi rounding only)")
    worst = {"A": 0, "B": 0, "C": 0}
    for env in (0.5, 1.0):
        for zoom in (0.0, 0.5, 0.999):
            for dens in (1, 4, 8, 12):
                ref = q.field(X, Y, zoom=zoom, drift=0.0, density=dens, envelope=env, dtype=F64)["P"]
                row = []
                for v in "ABC":
                    e = float(np.abs(p_variant(v, zoom, dens, env) - ref).max())
                    worst[v] = max(worst[v], e)
                    row.append(e)
                print(f"{zoom:5.3f} {dens:4d} {env:4.1f} |   {row[0]:.2e}      {row[1]:.2e}     {row[2]:.2e}")
    print()
    lsb = 2 / 255
    print(f"worst over the sweep: A {worst['A']:.2e}  B {worst['B']:.2e}  C {worst['C']:.2e}")
    print(f"1 output LSB of P (8-bit, range 2) = {lsb:.2e}; 1e-3 = {1e-3 / lsb:.2f} LSB")
    print("Reading: the float32 error is set by rounding psi itself (C tracks A);"
          " the cycles form B does not beat the spec form A unless B < A above.")


def drift_table():
    """The drift phase multiplies s_i inside psi, so a growing accumulator costs precision.
    The same offset written as a base-octave phase phi in turns, offset_i = 2 pi phi 2^i, is
    exactly periodic in phi (2^i is an integer), so phi can wrap at 1."""
    print()
    print("drift p (accumulator)   float32 max|dP| vs float64   (density 4, zoom 0.5, env 0.5)")
    for p in (0.0, 1.0, 10.0, 100.0, 1000.0, 10000.0):
        a = q.field(X, Y, zoom=0.5, drift=p, density=4, envelope=0.5, dtype=F32)["P"].astype(F64)
        r = q.field(X, Y, zoom=0.5, drift=p, density=4, envelope=0.5, dtype=F64)["P"]
        print(f"  p = {p:9.1f}          {float(np.abs(a - r).max()):.2e}")
    print("A phase accumulator that wraps (turns, wrap at 1, integer octave multiples) keeps the"
          " first row's error for ever; an unbounded p does not.")


if __name__ == "__main__":
    main()
    drift_table()
