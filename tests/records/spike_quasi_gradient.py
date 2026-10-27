"""spike_quasi_gradient.py -- f_quasi T003: the analytic gradient against a central finite
difference of P, and the bounded vecfield, over a parameter sweep (SC-002, SC-003).

Per random parameter set (zoom, density, envelope, angle, drift):
  - float64 analytic gradient vs a float64 central difference of P (h scaled to the frequency),
    relative to the gradient's peak;
  - float32 analytic gradient vs the float64 one, relative to the peak;
  - max |v| of the bounded vecfield (must be <= 1) and how close it comes to 1;
  - the encoded R, G range at gain 1 (must stay inside [0, 1] unclipped).
The gradient's magnitude scales with density * zoom scale (printed), which is why the vecfield
is normalised by the weighted total frequency (gate G2).

Run: uv run --no-project --with numpy python3 tests/records/spike_quasi_gradient.py
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "lib"))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "quasi"))

import numpy as np  # noqa: E402

import quasi_mirror as q  # noqa: E402

F32, F64 = np.float32, np.float64


def main():
    rng = np.random.default_rng(21)
    X = rng.uniform(-0.889, 0.889, 4000)
    Y = rng.uniform(-0.5, 0.5, 4000)
    rows = []
    for n in range(60):
        kw = dict(zoom=float(rng.uniform(0, 1)), drift=float(rng.uniform(0, 1)),
                  density=float(rng.uniform(1, 12)), envelope=float(rng.uniform(0.25, 1.5)),
                  angle=float(rng.uniform(0, np.pi)))
        f = q.field(X, Y, dtype=F64, **kw)
        _, w, s = q.octave_terms(kw["zoom"], kw["envelope"], F64)
        fmax = 2 * np.pi * kw["density"] * float((w * s).sum() / w.sum())   # weighted mean freq
        h = 1e-3 / max(fmax, 1.0)
        fx = (q.field(X + h, Y, dtype=F64, **kw)["P"] - q.field(X - h, Y, dtype=F64, **kw)["P"]) / (2 * h)
        fy = (q.field(X, Y + h, dtype=F64, **kw)["P"] - q.field(X, Y - h, dtype=F64, **kw)["P"]) / (2 * h)
        peak = float(max(np.abs(f["gx"]).max(), np.abs(f["gy"]).max()))
        fd_err = float(max(np.abs(fx - f["gx"]).max(), np.abs(fy - f["gy"]).max())) / peak
        f32 = q.field(X, Y, dtype=F32, **kw)
        e32 = float(max(np.abs(f32["gx"] - f["gx"]).max(), np.abs(f32["gy"] - f["gy"]).max())) / peak
        vmag = float(np.hypot(f32["vx"], f32["vy"]).max())
        enc = q.encode_vec(f32["vx"], f32["vy"], 1.0)
        rows.append((fd_err, e32, vmag, float(enc[..., :2].min()), float(enc[..., :2].max()), peak))
    r = np.array(rows)
    print(f"60 parameter sets x 4000 points")
    print(f"  float64 gradient vs central difference (relative to peak): max {r[:, 0].max():.2e}")
    print(f"  float32 gradient vs float64 (relative to peak):            max {r[:, 1].max():.2e}")
    print(f"  max |v| (bounded vecfield, bound 1):                        max {r[:, 2].max():.6f}")
    print(f"  encoded R, G at gain 1:                                    min {r[:, 3].min():.4f}, max {r[:, 4].max():.4f}")
    print(f"  gradient peak |grad P| across the sweep:                    {r[:, 5].min():.1f} .. {r[:, 5].max():.1f}"
          f"  (a fixed scale cannot serve both ends)")
    mag = np.hypot(*(lambda f: (f['vx'], f['vy']))(q.field(X, Y, dtype=F64, zoom=0.3, drift=0.2, density=4, envelope=0.5)))
    print(f"  at the defaults the typical |v| is {np.median(mag):.3f} (median), "
          f"p99 {np.percentile(mag, 99):.3f}, max {mag.max():.3f}: the bound is loose in practice,"
          f" so `gain` > 1 is the useful direction")


if __name__ == "__main__":
    main()
