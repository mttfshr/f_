"""What does Wind = 0 look like on a flow that is already moving? (mirror, 192x108, 2026-10-21)
Run: tests/py.sh scratch/lbm_wind_zero.py omega [develop_frames] [after_frames]
(a) fresh start at U0 = 0: is it static?  (b) develop at U0 = 0.08, then set U0 = 0 and watch the peak speed and
the probe swing decay. Reports peak |u|, mean |u|, and the encoded swing at gain 3 and gain 10."""
import sys
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

omega = float(sys.argv[1])
DEV = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
AFTER = int(sys.argv[3]) if len(sys.argv) > 3 else 3000
W, H = 192, 108
D = H / 6.0
cx, cy = W * 0.25, H * 0.5
yy, xx = np.mgrid[0:H, 0:W]
mask = (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 < (D / 2) ** 2


def seed(u0):
    ripple = (0.02 * u0 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
    return pack(equilibrium(np.ones((H, W), F32), np.full((H, W), u0, F32), ripple.astype(F32)))


def stats(planes, tag):
    r, ux, uy = macro(unpack(planes))
    sp = np.hypot(ux, uy)
    fluid = ~mask
    print(f"  {tag:<22} peak |u| {float(sp[fluid].max()):.4f}  mean |u| {float(sp[fluid].mean()):.4f}  "
          f"mean |uy| {float(np.abs(uy[fluid]).mean()):.4f}  -> at gain 3 peak {3 * float(sp[fluid].max()):.2f}, at gain 10 peak {10 * float(sp[fluid].max()):.2f}",
          flush=True)


print(f"omega {omega}")
pl = seed(0.0)
for n in range(2000):
    pl, _ = lbm_step(pl, mask, omega, 0.0, 3.0)
stats(pl, "(a) fresh, U0=0, +2000")

pl = seed(0.08)
for n in range(DEV):
    pl, _ = lbm_step(pl, mask, omega, 0.08, 3.0)
stats(pl, f"(b) developed ({DEV} fr)")
marks = {1, 100, 250, 500, 1000, 2000, AFTER}
for n in range(1, AFTER + 1):
    pl, _ = lbm_step(pl, mask, omega, 0.0, 3.0)
    if n in marks:
        stats(pl, f"U0 -> 0, +{n} frames")
