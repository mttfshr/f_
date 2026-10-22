"""Do the boundary columns flicker frame to frame faster than the rest? (mirror, 192x108, 2026-10-21)
Run: tests/py.sh scratch/lbm_flicker.py omega
Develops at U0 = 0.08 for 2000 frames, records the module's mac velocity (macro of the streamed state) for 120 frames and
reports per band of columns, in lattice units:
  D1 = mean |u(t+1) - u(t)|            frame-to-frame change (flicker)
  P2 = mean |u(t+1) - 2u(t) + u(t-1)| / D1   about 2 for a pure period-2 alternation, near 0 for smooth change
  and D1 after averaging each frame with the previous one (the candidate fix)."""
import sys
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

omega = float(sys.argv[1])
U1 = float(sys.argv[2]) if len(sys.argv) > 2 else 0.08     # Wind during the measurement (after developing at 0.08)
W, H = 192, 108
D = H / 6.0
cx, cy = W * 0.25, H * 0.5
yy, xx = np.mgrid[0:H, 0:W]
mask = (xx + 0.5 - cx) ** 2 + (yy + 0.5 - cy) ** 2 < (D / 2) ** 2
ripple = (0.02 * 0.08 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
pl = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), 0.08, F32), ripple.astype(F32)))
for n in range(2000):
    pl, _ = lbm_step(pl, mask, omega, 0.08, 3.0)
for n in range(2000 if U1 != 0.08 else 0):
    pl, _ = lbm_step(pl, mask, omega, U1, 3.0)
frames = []
for n in range(120):
    pl, _ = lbm_step(pl, mask, omega, U1, 3.0)
    r, ux, uy = macro(unpack(pl))
    frames.append(np.stack([ux, uy]).astype(np.float64))
f = np.array(frames)                                   # (T, 2, H, W)
d1 = np.abs(np.diff(f, axis=0))
d2 = np.abs(f[2:] - 2 * f[1:-1] + f[:-2])
avg = 0.5 * (f[1:] + f[:-1])
d1a = np.abs(np.diff(avg, axis=0))
bands = {"cols 0-2": slice(0, 3), "cols 3-6": slice(3, 7), "interior": slice(10, W - 10),
         f"cols {W - 7}-{W - 4}": slice(W - 7, W - 3), f"cols {W - 3}-{W - 1}": slice(W - 3, W)}
print(f"omega {omega} Wind {U1}: per band  D1 (flicker)   P2 (2 = alternating)   D1 after 2-frame average")
for name, sl in bands.items():
    a = float(d1[..., sl].mean())
    b = float(d2[..., sl].mean()) / max(float(d1[..., sl].mean()), 1e-12)
    c = float(d1a[..., sl].mean())
    print(f"   {name:<12} {a:.5f}          {b:.2f}                  {c:.5f}")
