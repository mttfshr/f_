"""spike_fc_presets.py -- candidate settings groups (Depth / Period / Grain) at the module's REAL
solver size, N 1024, from a reset (Matt, 2026-10-25: "Grain doesn't seem to really be doing much --
recommend some settings groups"). The Grain sweep ran at N 256, where features are 4x larger on screen.

Each group runs 2000 frames from seed 1 (parity mirror; Rate 1, Quant 255, internal pulse).
Sheet: rows = groups, columns = frames 1000 / 1500 / 2000, out_mode E, 384^2 per tile
-> tests/logs/fc_presets.png. Metrics as the other spikes.

Run: uv run --no-project --with numpy --with pillow python3 tests/records/spike_fc_presets.py
RESULT (2026-10-25, 437 s):
  A source        0.60 / 147 / 1.0   ALIVE 0.111 (min 0.054)  emerges  620
  B fine rolls    0.90 / 147 / 0.6   ALIVE 0.091 (min 0.024)  emerges  330  (fastest to form)
  C big cells     0.60 / 294 / 1.6   ALIVE 0.078 (min 0.025)  emerges 1198  (~20 s at 60 fps)
  D slow breath   0.40 / 450 / 1.0   "dead" by the late-std metric (0.019, min 0.002) but it forms
                                     (988) and fades between breaths -- the intended in/out breathing
  E moire         0.80 / 147 / 2.0   ALIVE 0.115 (min 0.046)  emerges  482
  F edge flicker  1.25 / 110 / 1.0   DEAD at once (0.000) -- overdrive plus a fast period
Matt, live (10:12): A-E look distinctive; F dies almost immediately (matches the mirror).
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402

N, FRAMES, SNAPS, TILE = 1024, 2000, (1000, 1500, 2000), 384
GROUPS = [  # name, depth, period, grain
    ("A source", 0.6, 147.06, 1.0),
    ("B fine rolls", 0.9, 147.06, 0.6),
    ("C big cells", 0.6, 294.0, 1.6),
    ("D slow breath", 0.4, 450.0, 1.0),
    ("E moire", 0.8, 147.06, 2.0),
    ("F edge flicker", 1.25, 110.0, 1.0),
]


def go(g):
    name, depth, period, grain = g
    import wc_parity_mirror as m
    st = m.seed_state(N, np.random.default_rng(1))
    es, tiles = [], {}
    for fr in range(FRAMES):
        st = m.step(st, fr, s=m.s_pulse(fr, depth=depth, period=period), grain=grain)
        es.append(float(st[..., 0].std()))
        if fr + 1 in SNAPS:
            tiles[fr + 1] = m.encode_mode(st, TILE, TILE, 1)[..., 0]
    es = np.array(es)
    after = np.nonzero(es[300:] > 0.05)[0]
    return name, es[-500:].mean(), es[-500:].min(), (int(after[0]) + 300 if len(after) else None), tiles


if __name__ == "__main__":
    t0 = time.time()
    with Pool(len(GROUPS)) as p:
        res = p.map(go, GROUPS)
    rows = []
    for (name, mean, mn, emerge, tiles), g in zip(res, GROUPS):
        print(f"{name:15s} depth {g[1]:.2f} period {g[2]:6.1f} grain {g[3]:.2f}: "
              f"{'ALIVE' if mean > 0.03 else 'dead '} late E std {mean:.3f} (min {mn:.3f})  emerge {emerge}", flush=True)
        rows.append(np.concatenate([tiles[f] for f in SNAPS], axis=1))
    from PIL import Image
    sheet = np.clip(np.concatenate(rows, axis=0) * 255, 0, 255).astype(np.uint8)
    out = os.path.join(REPO, "tests", "logs", "fc_presets.png")
    Image.fromarray(sheet, "L").save(out)
    print("sheet:", out, f"{time.time() - t0:.0f}s")
