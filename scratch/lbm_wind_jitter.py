"""Does a Wind (inflow) that keeps changing paint a noisy band at the left edge? (mirror, 192x108, empty mask, 2026-10-21)
Run: tests/py.sh scratch/lbm_wind_jitter.py
Settles at U0 = 0.08 for 300 frames, then for 120 frames applies one of:
  steady  : U0 stays 0.08
  step    : U0 jumps to 0.06 once
  jitter  : U0 = 0.08 + random +-0.005 every frame (a control being nudged or driven by a noisy source)
  slow    : U0 drifts 0.08 -> 0.06 linearly over the 120 frames (a hand turning the dial)
Reports the deviation of the encoded field (gain 3) from its row-mean, by column band, in encoded units
(0.01 is barely visible, 0.05 clearly), and how many columns in from the left it reaches (> 0.01)."""
import numpy as np
import paths  # noqa: F401
from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, unpack, macro

W, H = 192, 108
mask = np.zeros((H, W), bool)
ripple = (0.02 * 0.08 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
base = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), 0.08, F32), ripple.astype(F32)))
rng = np.random.default_rng(1)


def run(mode):
    pl = [p.copy() for p in base]
    for n in range(300):
        pl, _ = lbm_step(pl, mask, 1.97, 0.08, 3.0)
    for n in range(120):
        u = {"steady": 0.08, "step": 0.06, "jitter": 0.08 + 0.005 * rng.uniform(-1, 1), "slow": 0.08 - 0.02 * n / 119.0}[mode]
        pl, _ = lbm_step(pl, mask, 1.97, float(u), 3.0)
    r, ux, uy = macro(unpack(pl))
    dev = 3.0 * np.hypot(ux - ux.mean(axis=0, keepdims=True), uy)            # encoded units, vs the column mean for ux
    col = dev.mean(axis=0)
    reach = int(np.max(np.nonzero(col > 0.01)[0])) + 1 if (col > 0.01).any() else 0
    print(f"{mode:<7} deviation by column (encoded units): cols 0-2 {col[:3].mean():.3f}  3-9 {col[3:10].mean():.3f}  10-24 {col[10:25].mean():.3f}  "
          f"25-60 {col[25:61].mean():.3f}  interior {col[60:W - 8].mean():.3f}  right 8 {col[W - 8:].mean():.3f}   reaches column {reach}", flush=True)


for m in ("steady", "step", "jitter", "slow"):
    run(m)
