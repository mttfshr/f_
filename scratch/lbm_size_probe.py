"""Quick mirror probe (2026-10-21): does a 16:9 lattice hold and shed at the target regime?
Run: tests/py.sh scratch/lbm_size_probe.py W H frames
Prints finite/NaN, max speed, and the probe uy swing over the last third."""
import sys
import numpy as np
import paths  # noqa: F401  (tests/lib on the path via tests/py.sh)
import gpu_sim as g
from vf_lbm_mirror import F32, W9, equilibrium, pack, lbm_step, unpack, macro

W, H, N = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
omega, U0 = 1.975, 0.08
D = H / 6.0
cx, cy = W * 0.25, H * 0.5
yy, xx = np.mgrid[0:H, 0:W]
mask = (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 < (D / 2) ** 2
rho = np.ones((H, W), F32)
ux = np.full((H, W), U0, F32)
uy = (0.002 * np.sin(np.arange(W) * 0.3)[None, :] * np.ones((H, 1))).astype(F32)   # startup perturbation
planes = pack(equilibrium(rho, ux, uy))
px, py = int(cx + 2.5 * D), int(cy + 0.3 * D)
probe = []
for n in range(N):
    planes, enc = lbm_step(planes, mask, omega, U0, 3.0)
    if n % 10 == 0:
        f = unpack(planes)
        r, a, b = macro(f)
        probe.append(float(b[py, px]))
        if not np.isfinite(r).all():
            print(f"NaN at frame {n}")
            break
tail = np.array(probe[-(len(probe) // 3):])
print(f"{W}x{H} D={D:.1f} frames={n + 1} finite={np.isfinite(macro(unpack(planes))[0]).all()} "
      f"probe uy swing (last third) = {tail.max() - tail.min():.4f}")
