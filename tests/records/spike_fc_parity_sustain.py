"""spike_fc_parity_sustain.py -- f_formconstants Revision 2, T041/T042 record:
which ingredient of the WC_Example_10 page actually sustains the pattern?

Conditions (the parity mirror, fc_parity_mirror.py: source kernel sigma = (1, 2) px,
Example-10 constants, no per-frame noise, no habituation), crossed:
    8-bit quantization   on / off  (levels 255 / None)
    drive s square wave  on / off  (depth 0.6 / 0.0, period ~147 frames)
two seeds, N = 128 and 256, 3000-4000 frames. Tracked: spatial std of E, per
500-frame window (min-max).

RESULT (2026-10-24; the numbers the test_fc_parity sustain test asserts):
    quantized + s    sustained   E std 0.05-0.22 through the last window, both seeds
    float32  + s     sustained   E std 0.05-0.22, same band
    quantized, no s  dead        E std 0.002-0.010 after ~1000 frames
    float32, no s    dead        E std 0.001-0.012 after ~1000 frames
=> the `s` square wave is the sustain mechanism. 8-bit quantization is NOT
required at the source's kernel widths. The earlier T002 record (tasks.md:
"every float32 variant dies; only the quantized+s port breathes") used
sigma_I = 1 px / sigma_E = 0.69 px -- NOT the source's (2, 1) -- and its
quantized port was never committed, so it could not be reproduced; this
script is the reproducible replacement.

Run: uv run --no-project --with numpy python3 tests/records/spike_fc_parity_sustain.py [N] [frames]
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "formconstants"))

import numpy as np  # noqa: E402


def go(args):
    label, n, frames, levels, depth, seed = args
    import fc_parity_mirror as m
    m.S_DEPTH = depth
    st = m.seed_state(n, np.random.default_rng(seed))
    es = []
    for fr in range(frames):
        st = m.step(st, fr, levels)
        es.append(float(st[..., 0].std()))
    es = np.array(es)
    wins = " | ".join(f"{a}-{a + 500}: {es[a:a + 500].min():.3f}-{es[a:a + 500].max():.3f}"
                      for a in range(0, frames - 499, 500) if a in (0, 1000, 2000, frames - 500))
    return f"{label:18s} seed{seed} N={n} | E std {wins}"


if __name__ == "__main__":
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 128
    frames = int(sys.argv[2]) if len(sys.argv) > 2 else 3000
    jobs = [(lab, n, frames, lv, dp, sd)
            for sd in (1, 2)
            for lab, lv, dp in (("quantized + s", 255.0, 0.6), ("float + s", None, 0.6),
                                ("quantized, no s", 255.0, 0.0), ("float, no s", None, 0.0))]
    t0 = time.time()
    with Pool(min(8, len(jobs))) as p:
        for line in p.imap(go, jobs):
            print(line, flush=True)
    print(f"{time.time() - t0:.0f}s")
