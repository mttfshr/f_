"""spike_fc_flash.py -- a Flash (swing) control for the pulse's global flashing (Matt, 2026-10-25:
"the rgb flashing -- is there a way to control the speed or intensity?").

The flash is the internal square wave switching the whole field's excitability between 0 and Depth.
Proposed: s = depth * (0.5 + flash * (square - 0.5)) -- the MEAN stays depth/2 (a steady 0.3 at depth
0.6 lives: spike_fc_pulse_shapes.py), flash scales the swing. flash 1 = the source; 0 = steady.
Measures, parity mirror N 256, seed 1, 2000 frames: alive (late spatial E std), and FLASH INTENSITY =
the std over time of the frame-mean E over the last 600 frames (how much the whole field pulses).

Run: uv run --no-project --with numpy python3 tests/records/spike_fc_flash.py
RESULT (2026-10-25, 15 s) -- the hypothesis is WRONG:
  flash 0.00 (steady 0.3)  ALIVE 0.073   flash intensity 0.162
  flash 0.25               ALIVE 0.058   0.171
  flash 0.50               dead  0.024   0.183
  flash 0.75               weak  0.031   0.184
  flash 1.00 (source)      ALIVE 0.107   0.124   <- the LEAST global flashing
Follow-up (same day): frame-mean E swings ~0.07 <-> 0.6 in BOTH cases; with a steady s = 0.3 its period is
~80 frames, with the source square it locks to 150 (the pulse period). So the flashing is the E-I loop's
own BULK OSCILLATION (the whole field firing and recovering together); the square wave ENTRAINS it (slows
it to its period, slightly smaller swing), it does not cause it. A swing control cannot remove it and
weakens liveness in between. Not built.
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "formconstants"))

import numpy as np  # noqa: E402

N, FRAMES = 256, 2000
FLASHES = (0.0, 0.25, 0.5, 0.75, 1.0)


def go(flash):
    import fc_parity_mirror as m
    st = m.seed_state(N, np.random.default_rng(1))
    es, means = [], []
    for fr in range(FRAMES):
        sq = 1.0 if (fr / m.S_PERIOD) % 1.0 < 0.5 else 0.0
        s = np.float32(0.6 * (0.5 + flash * (sq - 0.5)))
        st = m.step(st, fr, s=s)
        es.append(float(st[..., 0].std()))
        means.append(float(st[..., 0].mean()))
    es, means = np.array(es), np.array(means)
    after = np.nonzero(es[300:] > 0.05)[0]
    return flash, es[-600:].mean(), es[-600:].min(), means[-600:].std(), (int(after[0]) + 300 if len(after) else None)


if __name__ == "__main__":
    t0 = time.time()
    with Pool(len(FLASHES)) as p:
        for flash, sm, smin, fl, em in p.map(go, FLASHES):
            print(f"flash {flash:4.2f}: {'ALIVE' if sm > 0.03 else 'dead '} late E std {sm:.3f} (min {smin:.3f})  "
                  f"emerge {em}   FLASH intensity (std of mean E over time) {fl:.4f}")
    print(f"{time.time() - t0:.0f}s")
