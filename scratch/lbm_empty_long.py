"""Does an EMPTY channel stay clean over a long run? (mirror, 192x108, no mask, constant Wind, 2026-10-21)
Run: tests/py.sh scratch/lbm_empty_long.py omega [wind] [frames]
Reports every 2000 frames the deviation of the encoded field (gain 3) from uniform, by column band, and the peak speed.
A noise band that grows at the inflow edge over thousands of frames would show here."""
import sys
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

omega = float(sys.argv[1])
U0 = float(sys.argv[2]) if len(sys.argv) > 2 else 0.08
N = int(sys.argv[3]) if len(sys.argv) > 3 else 16000
W, H = 192, 108
mask = np.zeros((H, W), bool)
ripple = (0.02 * U0 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
pl = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), U0, F32), ripple.astype(F32)))
for n in range(1, N + 1):
    pl, _ = lbm_step(pl, mask, omega, U0, 3.0)
    if n % 2000 == 0 or n == 300:
        r, ux, uy = macro(unpack(pl))
        dev = 3.0 * np.hypot(ux - U0, uy)                           # encoded units: how far from the uniform stream
        col = dev.mean(axis=0)
        reach = int(np.max(np.nonzero(col > 0.01)[0])) + 1 if (col > 0.01).any() else 0
        print(f"omega {omega} Wind {U0} frame {n:>5}: deviation cols 0-2 {col[:3].mean():.4f}  3-9 {col[3:10].mean():.4f}  "
              f"10-24 {col[10:25].mean():.4f}  interior {col[25:W - 8].mean():.4f}  right8 {col[W - 8:].mean():.4f}  "
              f"reach {reach}  peak|u| {float(np.hypot(ux, uy).max()):.3f}  rho {float(r.min()):.3f}..{float(r.max()):.3f}", flush=True)
