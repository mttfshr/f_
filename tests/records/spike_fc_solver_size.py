"""spike_fc_solver_size.py -- T064 look: the same Depth / Period / Grain at solver N 512 / 1024 / 2048
(Matt, 2026-10-25: unsure whether a load-time solver size is worth a menu; decide from stills).

Parity mirror, seed 1 at every N (same rng seed, different grid), Rate 1, Quant 255, internal pulse.
Settings: A source (0.6 / 147.06 / 1.0), B fine rolls (0.9 / 147.06 / 0.6) -- from spike_fc_presets.py.
Sheet: rows = (setting, N) in N order 512, 1024, 2048 per setting; columns = frames SNAPS;
out_mode E, retinal view, TILE^2 per tile -> tests/logs/fc_solver_size.png.
Features are pixel-scale in the solver grid, so a larger N should look FINER relative to the frame.

Run: uv run --no-project --with numpy --with pillow python3 tests/records/spike_fc_solver_size.py
(2048 is slow: expect tens of minutes; run it in the background, tests/bg.sh style.)
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "formconstants"))

import numpy as np  # noqa: E402

FRAMES, SNAPS, TILE = 1500, (700, 1100, 1500), 384
SETTINGS = [("A source", 0.6, 147.06, 1.0), ("B fine rolls", 0.9, 147.06, 0.6)]
SIZES = (512, 1024, 2048)
JOBS = [(s, n) for s in SETTINGS for n in SIZES]


def go(job):
    (name, depth, period, grain), n = job
    import fc_parity_mirror as m
    st = m.seed_state(n, np.random.default_rng(1))
    es, tiles = [], {}
    for fr in range(FRAMES):
        st = m.step(st, fr, s=m.s_pulse(fr, depth=depth, period=period), grain=grain)
        es.append(float(st[..., 0].std()))
        if fr + 1 in SNAPS:
            tiles[fr + 1] = m.encode_mode(st, TILE, TILE, 1)[..., 0]
    es = np.array(es)
    after = np.nonzero(es[300:] > 0.05)[0]
    return name, n, es[-500:].mean(), es[-500:].min(), (int(after[0]) + 300 if len(after) else None), tiles


if __name__ == "__main__":
    t0 = time.time()
    with Pool(len(JOBS)) as p:
        res = p.map(go, JOBS)
    rows = []
    for name, n, mean, mn, emerge, tiles in res:
        print(f"{name:13s} N {n:4d}: {'ALIVE' if mean > 0.03 else 'dead '} late E std {mean:.3f} "
              f"(min {mn:.3f})  emerge {emerge}", flush=True)
        rows.append(np.concatenate([tiles[f] for f in SNAPS], axis=1))
    from PIL import Image, ImageDraw
    sheet = np.clip(np.concatenate(rows, axis=0) * 255, 0, 255).astype(np.uint8)
    img = Image.fromarray(sheet, "L").convert("RGB")
    d = ImageDraw.Draw(img)
    for i, (name, n, *_rest) in enumerate(res):
        d.text((6, i * TILE + 6), f"{name} N {n}", fill=(255, 220, 80))
    out = os.path.join(REPO, "tests", "logs", "fc_solver_size.png")
    img.save(out)
    print("sheet:", out, f"{time.time() - t0:.0f}s")
