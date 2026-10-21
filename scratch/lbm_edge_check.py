"""Where does the motion / noise live? Edge columns vs interior (mirror, 192x108, 2026-10-21).
Run: tests/py.sh scratch/lbm_edge_check.py omega scenario   (scenario: steady | drop)
steady: U0 = 0.08 for 3000 frames.   drop: develop at 0.08 for 3000, then U0 = 0 for 1000 more.
Reports, per band of columns (left edge 0-3, interior, right edge W-4..W-1): mean |u|, peak |u|, and a roughness
measure (mean |second difference in y| of ux and uy: high-frequency noise), plus where the peak speed is."""
import sys
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

omega = float(sys.argv[1])
scenario = sys.argv[2]
W, H = 192, 108
D = H / 6.0
cx, cy = W * 0.25, H * 0.5
yy, xx = np.mgrid[0:H, 0:W]
mask = (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 < (D / 2) ** 2
ripple = (0.02 * 0.08 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
pl = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), 0.08, F32), ripple.astype(F32)))


def report(tag):
    r, ux, uy = macro(unpack(pl))
    sp = np.hypot(ux, uy)
    rough = np.abs(ux[2:] - 2 * ux[1:-1] + ux[:-2]).__add__(np.abs(uy[2:] - 2 * uy[1:-1] + uy[:-2]))   # (H-2, W)
    bands = {"left  0-2 (hidden)": slice(0, 3), "left  3-6 (shown)": slice(3, 7), "interior": slice(8, W - 8),
             "right W-7..W-4 (shown)": slice(W - 7, W - 3), "right W-3.. (hidden)": slice(W - 3, W)}
    print(f"[{tag}] omega {omega}", flush=True)
    for name, sl in bands.items():
        m = ~mask[:, sl]
        print(f"   {name:<12} mean|u| {float(sp[:, sl].mean()):.4f}  peak|u| {float(sp[:, sl].max()):.4f}  "
              f"roughness {float(rough[:, sl].mean()):.5f}", flush=True)
    j, i = np.unravel_index(np.argmax(np.where(mask, 0, sp)), sp.shape)
    print(f"   peak speed {float(sp[j, i]):.4f} at x={i} (of {W}), y={j} (of {H}); density range {float(r.min()):.3f}..{float(r.max()):.3f}", flush=True)


for n in range(3000):
    pl, _ = lbm_step(pl, mask, omega, 0.08, 3.0)
report("U0 = 0.08, frame 3000")
if scenario == "sweep":          # Wind swept 0.08 -> 0.02 -> 0.08 over 900 frames, like turning the dial
    for n in range(900):
        u = 0.08 - 0.06 * (1 - abs(n - 450) / 450.0)
        pl, _ = lbm_step(pl, mask, omega, float(u), 3.0)
        if n in (299, 449, 600):
            report(f"sweep, frame {n + 1}, U0 {u:.3f}")
    for n in range(300):
        pl, _ = lbm_step(pl, mask, omega, 0.08, 3.0)
    report("sweep done, back at 0.08, +300")
if scenario == "drop":
    for n in range(1000):
        pl, _ = lbm_step(pl, mask, omega, 0.0, 3.0)
    report("U0 -> 0, +1000 frames")
