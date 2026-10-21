"""Wind sweep on the mirror (2026-10-21): what does the Wind dial (inflow U0) do at 192x108, omega 1.97?
Run: tests/py.sh scratch/lbm_wind_sweep.py U0 [omega] [frames]
Reports: finite, steady mean speed, wake swing in the last third, first frame the wake swing passes 30% of the final, period."""
import sys
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

U0 = float(sys.argv[1])
omega = float(sys.argv[2]) if len(sys.argv) > 2 else 1.97
N = int(sys.argv[3]) if len(sys.argv) > 3 else 8000
W, H = 192, 108
D = H / 6.0
cx, cy = W * 0.25, H * 0.5
yy, xx = np.mgrid[0:H, 0:W]
mask = (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 < (D / 2) ** 2
ripple = (0.02 * U0 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))      # the module's seed
planes = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), U0, F32), ripple.astype(F32)))
px, py = int(cx + 2.5 * D), int(cy + 0.3 * D)
t, probe = [], []
for n in range(N):
    planes, _ = lbm_step(planes, mask, omega, U0, 3.0)
    if n % 10 == 0:
        r, a, b = macro(unpack(planes))
        if not np.isfinite(r).all():
            print(f"U0={U0}: NaN at frame {n}")
            sys.exit()
        t.append(n)
        probe.append(float(b[py, px]))
pr = np.array(probe)
env = np.abs(pr - pr[-len(pr) // 3:].mean())
swing = float(pr[-len(pr) // 3:].max() - pr[-len(pr) // 3:].min())
onset = next((t[i] for i in range(len(pr)) if np.abs(pr[i]) > 0.3 * (swing / 2)), None) if swing > 1e-3 else None
# period from zero crossings of the last half
tail = pr[len(pr) // 2:] - pr[len(pr) // 2:].mean()
zc = np.nonzero(np.diff(np.sign(tail)) > 0)[0]
period = float(np.mean(np.diff(zc)) * 10) if len(zc) > 2 and swing > 1e-3 else None
r, ux, uy = macro(unpack(planes))
print(f"U0={U0:<5} omega={omega}: finite, wake swing {swing:.4f} (lattice units; x gain 3 = {3 * swing:.3f} of the 0..1 range), "
      f"onset ~frame {onset}, period {period} frames, peak |u| {float(np.hypot(ux, uy).max()):.3f}")
