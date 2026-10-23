"""Tilted wind on an EMPTY channel (mirror, 192x108, 2026-10-22). Does the interior settle to (U0 cos t, U0 sin t)?
Run: tests/py.sh scratch/lbm_tilt_probe.py tilt_deg [wind] [omega] [frames]
Prints the mean velocity by column band at a few frame counts, with the target, and the peak speed / density range."""
import sys
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

tilt = float(sys.argv[1])
U0 = float(sys.argv[2]) if len(sys.argv) > 2 else 0.08
omega = float(sys.argv[3]) if len(sys.argv) > 3 else 1.97
N = int(sys.argv[4]) if len(sys.argv) > 4 else 3000
W, H = 192, 108
mask = np.zeros((H, W), bool)
th = np.deg2rad(tilt)
ripple = (0.02 * U0 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
pl = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), U0, F32), ripple.astype(F32)))
print(f"tilt {tilt} deg, Wind {U0}, omega {omega}: target ux {U0 * np.cos(th):.4f}  uy {U0 * np.sin(th):.4f}")
for n in range(1, N + 1):
    pl, _ = lbm_step(pl, mask, omega, U0, 3.0, tilt=tilt)
    if n in (100, 300, 1000) or n % 1000 == 0 or n == N:
        r, ux, uy = macro(unpack(pl))
        b = lambda a, lo, hi: float(a[1:-1, lo:hi].mean())
        print(f"  frame {n:>5}: cols 0-2 ux {b(ux,0,3):.4f} uy {b(uy,0,3):.4f} | 10-60 ux {b(ux,10,60):.4f} uy {b(uy,10,60):.4f} | "
              f"60-180 ux {b(ux,60,180):.4f} uy {b(uy,60,180):.4f} | peak|u| {float(np.hypot(ux, uy).max()):.3f} "
              f"rho {float(r.min()):.3f}..{float(r.max()):.3f} finite {bool(np.isfinite(ux).all())}", flush=True)
