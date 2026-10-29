"""Phase-0 exploration for f_tf_hatch v2 (scratch, not a test). Run:
  uv run --no-project --with numpy python3 .specify/f_tf_hatch/spike/lic_explore.py
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch")]

import numpy as np  # noqa: E402
import test_tf_hatch_lic as T  # noqa: E402
from tf_hatch_mirror import chain  # noqa: E402

H = W = T.H


def integral_len(img, rows, cols):
    a = np.asarray(img, np.float64)[rows, cols]
    a = a - a.mean()
    h, w = a.shape
    F = np.fft.rfft2(a, s=(2 * h, 2 * w))
    ac = np.fft.irfft2(F * np.conj(F), s=(2 * h, 2 * w))
    ac /= ac[0, 0]
    out = []
    for prof in (ac[0, :w], ac[:h, 0]):
        neg = np.where(prof < 0)[0]
        n = neg[0] if len(neg) else len(prof)
        out.append(float(prof[:n].sum()))
    return out  # integral length along x, along y


print("== ramp, integral-length ratio, by persist_pow (8 strips of 15 rows)")
coh = np.broadcast_to(np.linspace(0.0, 1.0, H)[:, None], (H, W))
for pw in (0.5, 1.0, 2.0):
    out = T.raw_field(chain(T.field(0.0, coh), persist_pow=pw))
    row = []
    for i in range(8):
        y0, y1 = 4 + 15 * i, 4 + 15 * (i + 1)
        lx, ly = integral_len(out, slice(y0, y1), slice(16, W - 16))
        row.append(f"c={np.linspace(0,1,H)[(y0+y1)//2]:.2f}:Lx={lx:5.1f}/Ly={ly:3.1f}")
    print(f"  pow {pw}: " + "  ".join(row))

print("== non-concentric sweep (0 -> 40 deg across x) vs constant 0 deg: slow/fast std, ridge error")
def box(a, r):
    k = np.ones(2 * r + 1) / (2 * r + 1)
    a = np.apply_along_axis(lambda v: np.convolve(v, k, "same"), 0, a)
    return np.apply_along_axis(lambda v: np.convolve(v, k, "same"), 1, a)

for name, ang in (("const 0", 0.0), ("const 30", 30.0), ("sweep 0-40", np.broadcast_to(np.linspace(0, 40, W)[None, :], (H, W)))):
    out = T.raw_field(chain(T.field(ang, 1.0)))
    slow = box(out - out.mean(), 10)[24:-24, 24:-24]
    fast = (out - out.mean())[24:-24, 24:-24]
    print(f"  {name:11s}: slow/fast = {slow.std()/fast.std():.3f}")

print("== branch cut: sweep 155 -> 205 deg (axis crosses horizontal, the decode's wrap)")
sweep = np.broadcast_to(np.linspace(155.0, 205.0, W)[None, :], (H, W))
for mode in ("doubled", "unsigned_bilinear", "unsigned_nearest"):
    out = T.raw_field(chain(T.field(sweep, 1.0), aux_mode=mode))
    near = integral_len(out, slice(24, H - 24), slice(W // 2 - 12, W // 2 + 12))
    away = integral_len(out, slice(24, H - 24), slice(24, 48))
    print(f"  {mode:18s}: Lx near cut {near[0]:5.1f}  away {away[0]:5.1f}")

print("== mutation: persist off on isotropic (decode of atan2(0,0))")
out = T.raw_field(chain(T.field(0.0, 0.0), persist="off"))
print("  integral (Lx, Ly) =", [round(v, 1) for v in integral_len(out, slice(24, H - 24), slice(24, W - 24))])
