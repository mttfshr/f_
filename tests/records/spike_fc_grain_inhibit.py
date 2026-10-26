"""spike_fc_grain_inhibit.py -- f_wc Phase D: candidate CHARACTER dials (Matt,
2026-10-25: "formconstants might want an additional dial or two that modifies the character";
the f_wc comparison put Grain and Inhibit first).

  GRAIN   = scale the blur footprint: the page's 13 taps (E sigma 1, I sigma 2 -- the fixed
            E/I ratio 2) sampled at k * g texels (bilinear, wrap) with the same weights. This is
            how a dial would be built (same tap count, cheap). g = 0.5 0.75 1 1.5 2.
  INHIBIT = the I -> E coupling AIE (page 8.5): 6 7 8.5 10 12 14.
Parity mirror otherwise (Example-10 constants, 255 levels, internal square wave), N 256, seed 1,
2000 frames. Metrics: late (last 500) mean / min E std, emergence (E std > 0.05 after frame 300),
texels moving in the last frame. Sheets (out_mode E, 256^2): rows = values, columns = frames
1000 / 1500 / 2000 -> tests/logs/fc_grain.png, tests/logs/fc_inhibit.png.
Note: features are sized in solver texels, so the module's N 1024 shows ~4x more of them across
the screen than these N 256 sheets; compare the rows with each other, not with the live module.

Run: uv run --no-project --with numpy --with pillow python3 tests/records/spike_fc_grain_inhibit.py
RESULT (2026-10-25, 29 s):
  grain 0.50  ALIVE 0.072 (min 0.029)   0.75  ALIVE 0.082   1.00 (source)  ALIVE 0.114
        1.50  ALIVE 0.097               2.00  ALIVE 0.112 -- but see the sheet
  inhibit 6.0  dead (uniform; washes to white)   7.0  marginal 0.046 (mostly dark/blank)
          8.5 (source) ALIVE 0.114   10.0 ALIVE but faint 0.032 (low-contrast wavy labyrinth)
          12.0 dead-ish 0.026 (dim blobs)   14.0 dead (dark, frozen)
Sheet reading (by eye): GRAIN changes character for real -- 0.5 / 0.75 finer and wormier, with
radiating rolls/stripes at 0.75; 1.0 the source spot lattice; 1.5 bigger, softer spots. At 2.0 the
13 taps spaced 2 texels apart ALIAS: a checkerboard moire grid over everything -- an artifact of the
cheap spacing method, not the dynamics (a true wider kernel would need more taps). Usable span of
the cheap method: 0.5 - 1.5. INHIBIT has one narrow living band around 7.5 - 10: below, the field
washes out to a uniform; above, it dims and dies. 10 gives a faint labyrinth variant that only reads
with a contrast stretch.
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402

N, FRAMES, SNAPS = 256, 2000, (1000, 1500, 2000)
GRAINS = (0.5, 0.75, 1.0, 1.5, 2.0)
INHIBITS = (6.0, 7.0, 8.5, 10.0, 12.0, 14.0)


def shifted(a, d, axis):
    """a sampled at x + d along axis (wrap, linear interpolation)."""
    f0 = int(np.floor(d))
    fr = np.float32(d - f0)
    return (np.float32(1) - fr) * np.roll(a, -f0, axis=axis) + fr * np.roll(a, -(f0 + 1), axis=axis)


def make_blur_pass(m, g):
    def blur_pass(state, axis, levels=m.LEVELS):
        w = m.half_kernel()
        acc = state * w[0]
        ssum = w[0].copy()
        for i in range(1, m.RADIUS + 1):
            acc = acc + (shifted(state, i * g, axis) + shifted(state, -i * g, axis)) * w[i]
            ssum = ssum + np.float32(2.0) * w[i]
        return m.q(acc / ssum, levels)
    return blur_pass


def go(job):
    kind, val = job
    import wc_parity_mirror as m
    if kind == "grain":
        m.blur_pass = make_blur_pass(m, val)
    else:
        m.AIE = val
    st = m.seed_state(N, np.random.default_rng(1))
    es, tiles, moved = [], {}, 0.0
    for fr in range(FRAMES):
        prev = st[..., 0].copy()
        st = m.step(st, fr)
        es.append(float(st[..., 0].std()))
        if fr + 1 in SNAPS:
            tiles[fr + 1] = m.encode_mode(st, 256, 256, 1)[..., 0]
        if fr == FRAMES - 1:
            moved = float((st[..., 0] != prev).mean())
    es = np.array(es)
    after = np.nonzero(es[300:] > 0.05)[0]
    return kind, val, es[-500:].mean(), es[-500:].min(), (int(after[0]) + 300 if len(after) else None), moved, tiles


if __name__ == "__main__":
    t0 = time.time()
    jobs = [("grain", g) for g in GRAINS] + [("inhibit", a) for a in INHIBITS]
    with Pool(8) as p:
        res = p.map(go, jobs)
    from PIL import Image
    for kind in ("grain", "inhibit"):
        rows = []
        for k, val, mean, mn, emerge, moved, tiles in res:
            if k != kind:
                continue
            print(f"{kind:7s} {val:5.2f}: {'ALIVE' if mean > 0.03 else 'dead '} late E std mean {mean:.3f} "
                  f"min {mn:.3f}  emerge {emerge}  moving {moved:.1%}")
            rows.append(np.concatenate([tiles[f] for f in SNAPS], axis=1))
        sheet = np.clip(np.concatenate(rows, axis=0) * 255, 0, 255).astype(np.uint8)
        out = os.path.join(REPO, "tests", "logs", f"fc_{kind}.png")
        Image.fromarray(sheet, "L").save(out)
        print("sheet:", out)
    print(f"{time.time() - t0:.0f}s")
