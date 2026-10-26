"""spike_fc_quant_levels.py -- f_wc Phase D, T062 pre-look: what does the
quantization level do to the field? (tasks.md T062: "A/B the texture difference first".)

Parity mirror (source kernel, Example-10 constants, internal square wave), N 256, seed 1,
1500 frames, the same seed at levels float (None), 255 (the source), 63, 31, 15, 7.
Per level: late (last 500 frames) mean / min E std, the frame structure emerges (E std > 0.05
after frame 300), and the fraction of texels whose E changed over the last frame (a freeze
measure: each frame E moves by (target - E) / 10, so a coarse grid rounds small moves to 0).
Contact sheet: rows = levels, columns = frames 1000 / 1250 / 1500, encoded 256^2, out_mode E.

Run: uv run --no-project --with numpy --with pillow python3 tests/records/spike_fc_quant_levels.py
Writes tests/logs/fc_quant_ab.png.
RESULT (2026-10-25, 9 s; 511 / 1023 / 4095 run afterwards the same way, sequentially):
  levels  float: late E std 0.078 (min 0.017)  emerges 927   texels moving 100%
  levels   4095: 0.089 (0.019)  emerges 925   98.7%
  levels   1023: 0.102 (0.031)  emerges 920   96.1%
  levels    511: 0.105 (0.039)  emerges 771   99.2%
  levels    255: 0.075 (0.024)  emerges 619   92.6%   <- the source
  levels 63 / 31 / 15 / 7: FROZEN -- 0% of texels move in the last frame; never structures
    (63, 31: near-uniform; 15, 7: the seed noise frozen in place, hence their high std)
Reading: every level >= 255 lives; everything tried below freezes, because E moves by
(target - E)/10 per frame and a 1/levels grid rounds those moves to 0. So a levels DIAL is
mostly a freeze switch; the useful span is 255 .. float. By eye (sheet): 255 gives crisper
spots and a spot lattice, float softer and larger domains; float emerges ~300 frames later.
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402

N, FRAMES, SNAPS = 256, 1500, (1000, 1250, 1500)
LEVELS = (None, 255.0, 63.0, 31.0, 15.0, 7.0)


def go(levels):
    import wc_parity_mirror as m
    st = m.seed_state(N, np.random.default_rng(1))
    es, tiles, moved = [], {}, 0.0
    for fr in range(FRAMES):
        prev = st[..., 0].copy()
        st = m.step(st, fr, levels)
        es.append(float(st[..., 0].std()))
        if fr + 1 in SNAPS:
            tiles[fr + 1] = m.encode_mode(st, 256, 256, 1)[..., 0]
        if fr == FRAMES - 1:
            moved = float((st[..., 0] != prev).mean())
    es = np.array(es)
    after = np.nonzero(es[300:] > 0.05)[0]
    return levels, es[-500:].mean(), es[-500:].min(), (int(after[0]) + 300 if len(after) else None), moved, tiles


if __name__ == "__main__":
    t0 = time.time()
    with Pool(6) as p:
        res = p.map(go, LEVELS)
    rows = []
    for levels, mean, mn, emerge, moved, tiles in res:
        name = "float" if levels is None else f"{int(levels)}"
        print(f"levels {name:>5}: late E std mean {mean:.3f} min {mn:.3f}  emerge {emerge}  "
              f"texels moving in the last frame {moved:.1%}")
        rows.append(np.concatenate([tiles[f] for f in SNAPS], axis=1))
    sheet = np.clip(np.concatenate(rows, axis=0) * 255, 0, 255).astype(np.uint8)
    from PIL import Image
    out = os.path.join(REPO, "tests", "logs", "fc_quant_ab.png")
    Image.fromarray(sheet, "L").save(out)
    print("sheet:", out, " rows:", ["float" if l is None else int(l) for l in LEVELS], " cols:", SNAPS)
    print(f"{time.time() - t0:.0f}s")
