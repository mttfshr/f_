"""spike_quasi_wrap.py -- f_quasi T004: zoom-wrap residual versus `envelope` (SC-001, FR-010).

The wrap residual is the max |P| difference between the unwrapped zoom = 1 evaluation (scales
2^1 .. 2^7) and zoom = 0 (scales 2^0 .. 2^6): the octave that leaves (scale 128, weight
exp(-8/sigma^2)) and the one that enters (scale 1, weight exp(-4.5/sigma^2)), after the
normalisation by sum w. Measured over random points in float64, for envelope 0.25 .. 1.5, and
converted to output levels: the scalar outlet is P*0.5+0.5 (255 levels over range 2), the banded
texture amplifies P by up to 1.1 * bands (slope of the triangle fold), so its half-LSB bound on P
is tighter.

Run: uv run --no-project --with numpy python3 tests/records/spike_quasi_wrap.py
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "lib"))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "quasi"))

import numpy as np  # noqa: E402

import quasi_mirror as q  # noqa: E402

F64 = np.float64


def main():
    rng = np.random.default_rng(31)
    X = rng.uniform(-0.889, 0.889, 6000)
    Y = rng.uniform(-0.5, 0.5, 6000)
    print(" sigma | max|dP|     predicted    scalar LSBs   band-5 LSBs   band-12 LSBs")
    caps = {}
    for sig in (0.25, 0.35, 0.5, 0.6, 0.65, 0.7, 0.75, 0.8, 0.9, 1.0, 1.25, 1.5):
        a = q.field(X, Y, zoom=1.0, envelope=sig, drift=0.0, dtype=F64, wrap_zoom=False)["P"]
        b = q.field(X, Y, zoom=0.0, envelope=sig, drift=0.0, dtype=F64, wrap_zoom=False)["P"]
        res = float(np.abs(a - b).max())
        _, w0, _ = q.octave_terms(0.0, sig, F64, wrap=False)
        _, w1, _ = q.octave_terms(1.0, sig, F64, wrap=False)
        pred = (w0[0] + w1[6]) / w0.sum()     # leaving + entering weight over the normaliser
        # output levels: scalar = P*0.5+0.5 -> *255; banded texture slope <= 1.1 * bands * 1 (per unit P*0.5 * 2)
        scalar_lsb = res * 0.5 * 255
        b5_lsb = res * 1.1 * 5 * 255      # d look / dP <= 1.1 * bands (fold slope 2 * bands/2, pow 1.1)
        b12_lsb = res * 1.1 * 12 * 255
        print(f" {sig:5.2f} | {res:.3e}  {pred:.3e}   {scalar_lsb:10.4f}   {b5_lsb:10.4f}   {b12_lsb:11.4f}")
        for name, lsb in (("scalar", scalar_lsb), ("band5", b5_lsb), ("band12", b12_lsb)):
            if lsb <= 0.5:
                caps[name] = sig
    print()
    print("largest tested envelope with the residual at or below half an output LSB:")
    for k, v in caps.items():
        print(f"  {k}: {v}")
    print("(banded texture LSBs = residual * 1.1 * bands * 255, the worst case at the steepest part of the fold;"
          " scalar LSBs = residual * 0.5 * 255)")


if __name__ == "__main__":
    main()
