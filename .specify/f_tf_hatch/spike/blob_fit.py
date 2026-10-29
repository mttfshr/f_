"""Scratch: fit the blob-noise threshold as a closed-form cubic in `density`.
For each density d the lit probability is fill = 0.0025 * 2^(5 d). Find the threshold whose SOFT-ramped
coverage (mean of smoothstep(thr-w, thr+w, noise)) equals fill, fit thr(d) as a cubic, and check the
coverage the cubic gives on an independent noise patch.
  uv run --no-project --with numpy python3 .specify/f_tf_hatch/spike/blob_fit.py
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch")]

import numpy as np  # noqa: E402
import tf_hatch_mirror as M  # noqa: E402

N, CELL, EXTENT = 1600, 8.0, 4800.0
yy, xx = np.mgrid[0:N, 0:N].astype(np.float32)
fit_n = M.value_noise(xx + 0.5, yy + 0.5, CELL, 0, EXTENT)
chk_n = M.value_noise(xx + 0.5, yy + 0.5, CELL, 7, EXTENT)      # independent patch
std = float(fit_n.std())
w = np.float32(M.BLOB_SOFT * std)
print("value noise: mean %.4f std %.5f (chk std %.5f)" % (fit_n.mean(), std, chk_n.std()))


def coverage(n, thr):
    return float(M._smoothstep(np.float32(thr) - w, np.float32(thr) + w, n).mean())


ds = np.linspace(0, 1, 21)
fills = M.FILL_BASE * 2.0 ** (M.FILL_SPAN * ds)
thr = []
for f in fills:
    lo, hi = 0.0, 1.0
    for _ in range(24):
        mid = 0.5 * (lo + hi)
        if coverage(fit_n, mid) > f:
            lo = mid        # too much coverage: raise the threshold
        else:
            hi = mid
    thr.append(0.5 * (lo + hi))
thr = np.array(thr)
c = np.polyfit(ds, thr, 3)[::-1]        # c0 + c1 d + c2 d^2 + c3 d^3
print("BLOB_STD = %.4f" % std)
print("BLOB_THR = (%.6f, %.6f, %.6f, %.6f)" % tuple(c))
print("max |poly - exact thr| = %.5f" % np.abs(np.polyval(c[::-1], ds) - thr).max())
print(" d     fill    cov(fit patch)  cov(indep patch)   rel err (indep)")
worst = 0.0
for d, f in zip(ds, fills):
    t = np.polyval(c[::-1], d)
    a, b = coverage(fit_n, t), coverage(chk_n, t)
    worst = max(worst, abs(b - f) / f)
    print("%.2f  %.4f   %.4f          %.4f             %+.1f%%" % (d, f, a, b, 100 * (b - f) / f))
print("worst relative coverage error on the independent patch: %.1f%%" % (100 * worst))
