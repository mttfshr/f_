"""spike_fc_damping.py -- T075 option 1: can a damping control tame the whole-field flashing?
(Matt, 2026-10-25 11:36: "let's try 1".)

The flash is the E-I loop's bulk oscillation (spike_fc_flash.py): inhibition lags excitation, so the
whole field fires, recovers, fires. Here the inhibition's relaxation rate dt/tau_I (page 0.05; E's is
0.1) is swept: 0.02 0.035 0.05 0.075 0.1 0.15. Parity mirror otherwise (source square pulse, 255
levels), N 256, seed 1, 2000 frames. Metrics: alive (late spatial E std), FLASH intensity (std over time
of the frame-mean E, last 600 frames), the flash period, emergence. Sheet (out_mode E): rows = rates,
columns = frames 1500 / 1750 / 2000 -> tests/logs/fc_damping.png.

Run: uv run --no-project --with numpy --with pillow python3 tests/records/spike_fc_damping.py
RESULT (2026-10-25, two passes, 13 s each) -- NO usable damping dial:
  pass 1  I rate 0.020 dead (FLASH 0.367: huge whole-field pumping, no pattern)   0.035 dead (0.342)
          0.050 (page) ALIVE 0.107, FLASH 0.124      0.075 / 0.10 / 0.15 dead (FLASH 0.09 / 0.064 / 0.059)
  pass 2  0.045 dead (0.237)   0.050 ALIVE   0.055 weak 0.049 with MORE flash (0.141) at double rate (75 f)
          0.060 dead   0.065 / 0.070 dead (FLASH ~0.09-0.10)
Reading: the page's inhibition rate sits on a knife edge. Slower = bigger whole-field flashes and the
pattern dies; faster = less flashing but the pattern dies too. The flash and the pattern come from the same
E-I balance, so the dynamics offer no knob that keeps one and removes the other. (Sheet pass 2 in
tests/logs/fc_damping.png.)
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402

N, FRAMES, SNAPS = 256, 2000, (1500, 1750, 2000)
RATES = (0.045, 0.05, 0.055, 0.06, 0.065, 0.07)   # pass 2 (pass 1: 0.02 0.035 0.05 0.075 0.1 0.15)


def go(rate):
    import wc_parity_mirror as m
    m.TI = m.DT / rate                      # wc_step uses DT / TI as inhibition's per-frame rate
    st = m.seed_state(N, np.random.default_rng(1))
    es, mu, tiles = [], [], {}
    for fr in range(FRAMES):
        st = m.step(st, fr)
        es.append(float(st[..., 0].std()))
        mu.append(float(st[..., 0].mean()))
        if fr + 1 in SNAPS:
            tiles[fr + 1] = m.encode_mode(st, 256, 256, 1)[..., 0]
    es, mu = np.array(es), np.array(mu)
    after = np.nonzero(es[300:] > 0.05)[0]
    return (rate, es[-600:].mean(), es[-600:].min(), mu[-600:].std(), m.power_peak_period(mu[-1200:]),
            (int(after[0]) + 300 if len(after) else None), tiles)


if __name__ == "__main__":
    t0 = time.time()
    with Pool(len(RATES)) as p:
        res = p.map(go, RATES)
    rows = []
    for rate, sm, smin, fl, per, em, tiles in res:
        print(f"I rate {rate:5.3f}: {'ALIVE' if sm > 0.03 else 'dead '} late E std {sm:.3f} (min {smin:.3f})  "
              f"FLASH {fl:.4f}  period {per}  emerge {em}", flush=True)
        rows.append(np.concatenate([tiles[f] for f in SNAPS], axis=1))
    from PIL import Image
    out = os.path.join(REPO, "tests", "logs", "fc_damping.png")
    Image.fromarray(np.clip(np.concatenate(rows, axis=0) * 255, 0, 255).astype(np.uint8), "L").save(out)
    print("sheet:", out, f"{time.time() - t0:.0f}s")
