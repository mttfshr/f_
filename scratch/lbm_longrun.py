"""Does the flow degrade into noise over a long run at low Wind? (mirror, 192x108, 2026-10-21)
Run: tests/py.sh scratch/lbm_longrun.py omega U0_after after_frames
Develops at U0 = 0.08 for 3000 frames, then holds U0 = U0_after and reports every 2000 frames:
roughness (mean |second difference| in y and in x of ux+uy) for the whole field, the right 16 columns, the left 16;
peak |u|, density range."""
import sys
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

omega, U1, AFTER = float(sys.argv[1]), float(sys.argv[2]), int(sys.argv[3])
W, H = 192, 108
D = H / 6.0
cx, cy = W * 0.25, H * 0.5
yy, xx = np.mgrid[0:H, 0:W]
mask = (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 < (D / 2) ** 2
ripple = (0.02 * 0.08 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
pl = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), 0.08, F32), ripple.astype(F32)))


def report(tag):
    r, ux, uy = macro(unpack(pl))
    s = ux + uy
    ry = np.abs(s[2:] - 2 * s[1:-1] + s[:-2])                  # (H-2, W)
    rx = np.abs(s[:, 2:] - 2 * s[:, 1:-1] + s[:, :-2])         # (H, W-2)
    sp = np.hypot(ux, uy)
    print(f"[{tag}] rough_y all {float(ry.mean()):.5f} right16 {float(ry[:, W - 16:].mean()):.5f} left16 {float(ry[:, :16].mean()):.5f} | "
          f"rough_x all {float(rx.mean()):.5f} right16 {float(rx[:, W - 18:].mean()):.5f} | peak|u| {float(sp.max()):.3f} "
          f"rho {float(r.min()):.3f}..{float(r.max()):.3f}", flush=True)


for n in range(3000):
    pl, _ = lbm_step(pl, mask, omega, 0.08, 3.0)
report("developed at 0.08, frame 3000")
for n in range(1, AFTER + 1):
    pl, _ = lbm_step(pl, mask, omega, U1, 3.0)
    if n % 2000 == 0:
        report(f"U0 = {U1}, +{n}")
