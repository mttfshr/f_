"""Phase-0 exploration 2 (scratch). Seed-averaged ramp, v1-vs-LIC ringness, branch cut.
  uv run --no-project --with numpy python3 .specify/f_tf_hatch/spike/lic_explore2.py
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch")]

import numpy as np  # noqa: E402
import test_tf_hatch_lic as T  # noqa: E402
import test_tf_hatch as V1  # noqa: E402
from tf_hatch_lic_mirror import chain  # noqa: E402

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
    return out


print("== ramp: integral Lx (along the axis), mean of 6 noise seeds, 6 strips of 20 rows")
coh = np.broadcast_to(np.linspace(0.0, 1.0, H)[:, None], (H, W))
tex = T.field(0.0, coh)
for pw in (0.5, 1.0):
    per_seed = []
    for sd in range(6):
        out = T.raw_field(chain(tex, persist_pow=pw, seed=sd))
        per_seed.append([integral_len(out, slice(4 + 20 * i, 4 + 20 * (i + 1)), slice(16, W - 16))[0] for i in range(6)])
    m = np.mean(per_seed, 0)
    s = np.std(per_seed, 0)
    cs = [np.linspace(0, 1, H)[4 + 20 * i + 10] for i in range(6)]
    print(f"  pow {pw}: " + "  ".join(f"c={c:.2f}:{a:5.1f}±{b:3.1f}" for c, a, b in zip(cs, m, s)))

print("== ringness about the frame ORIGIN vs other centres, field = sweep 0->40 deg")
sweep = np.broadcast_to(np.linspace(0, 40, W)[None, :], (H, W))
tex = T.field(sweep, 1.0)


def ringness(img, cx, cy):
    y, x = np.mgrid[0:H, 0:W]
    r = np.hypot(x + 0.5 - cx, y + 0.5 - cy).astype(int)
    a = img - img.mean()
    sums = np.bincount(r.ravel(), a.ravel())
    cnt = np.bincount(r.ravel())
    ok = cnt >= 40
    means = sums[ok] / cnt[ok]
    return float(np.sqrt((means ** 2).mean()) / img.std())


others = [(200, -80), (-60, 150), (190, 210), (64, 300)]
for name, img in (("LIC v2", T.raw_field(chain(tex))),
                  ("v1 lattice", np.asarray(V1.chain(tex)[0][..., 0], np.float64))):
    ro = ringness(img, 0.0, 0.0)
    rs = [ringness(img, cx, cy) for cx, cy in others]
    print(f"  {name:10s}: origin {ro:.3f}  others {np.mean(rs):.3f} (min {min(rs):.3f} max {max(rs):.3f})  origin/others {ro/np.mean(rs):.2f}")

print("== branch cut, sweep 170->190 (axis crosses the decode's wrap), Lx near vs away, 6 seeds")
sweep = np.broadcast_to(np.linspace(170.0, 190.0, W)[None, :], (H, W))
for mode in ("doubled", "unsigned_bilinear", "unsigned_nearest"):
    nears, aways = [], []
    for sd in range(6):
        out = T.raw_field(chain(T.field(sweep, 1.0), aux_mode=mode, seed=sd))
        nears.append(integral_len(out, slice(24, H - 24), slice(W // 2 - 14, W // 2 + 14))[0])
        aways.append(integral_len(out, slice(24, H - 24), slice(20, 48))[0])
    print(f"  {mode:18s}: near {np.mean(nears):5.1f}  away {np.mean(aways):5.1f}  ratio {np.mean(nears)/np.mean(aways):.2f}")
