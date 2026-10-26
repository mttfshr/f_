"""spike_fc_pulse_shapes.py -- f_wc Phase D, T061 pre-measurement:
what pulse (the `s` drive) keeps the parity field alive, so that "plug a Vsynth WFG in"
is a sound design?

Decided before this run (Matt, 2026-10-24): the pulse input REPLACES the internal square
wave (s = depth * input, the internal wave being the unplugged default) and is read in
CORTICAL space (on the solver grid). This script measures, in the parity mirror
(wc_parity_mirror.py: source kernel, Example-10 constants, quantized), N 256, seed 1:
  A  waveform at depth 0.6, period 147: square (source), sine, triangle, saw, DC 0.3, DC 0.6
  B  square depth sweep 0.2 - 1.5
  C  square period sweep 37 - 588 frames
  D  kill and revive: square 0.6, then depth 0 for 600 frames, then back on
  E  spatial: square gated by 8 cortical bands; a travelling-sine WFG across x
Metric: spatial E std of the state. "alive" = mean E std over the last 600 frames > 0.03.

Run: uv run --no-project --with numpy python3 tests/records/spike_fc_pulse_shapes.py [frames]
RESULT (2026-10-24, 2400 frames, 68 s; late = last 600 frames, mean E std):
  A square d0.6 (source)  ALIVE 0.117      sine d0.6   dead  0.026 (pulses, decays)
    triangle d0.6         ALIVE 0.037 (weak)   saw d0.6    ALIVE 0.119
    DC 0.3                ALIVE 0.084  <-- a CONSTANT offset sustains
    DC 0.6                dead  0.008
  B square depth 0.2/0.4/0.8/1.0  ALIVE 0.058/0.089/0.120/0.128;  1.5  dead 0.001 (overdrive kills)
  C square period 37 / 74  dead 0.012 / 0.019;  294 ALIVE 0.098;  588 ALIVE but weak 0.030
  D depth 0 for frames 1500-2100: NOT dead after 600 frames (std 0.037 at kill end, still decaying);
    revives in 3 frames when the square returns.  Depth 0 is a slow fade (T042: dead after ~1000)
  E square gated by 8 cortical bands  ALIVE; late E std in on-bands 0.104, off-bands 0.051
    travelling sine WFG (4 cycles across x, period 147)  ALIVE 0.105 (spatial variation sustains
    where the global sine does not)
Reading: `s` acts as an EXCITABILITY LEVEL with a viable window, not only as a clock: a DC
0.3 lives, DC 0.6 and depth 1.5 die, 0 fades out. The square wave's 0 / 0.6 alternation (mean
0.3) sits in the window. Pulses faster than ~100 frames die (at 60 fps: WFGs faster than about
0.6 Hz). Matt (2026-10-24): smooth-vs-square does not matter for the design, since every
Vsynth WFG can output a square; the A row is kept as information only.
"""
import os
import sys
import time
from multiprocessing import Pool

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402

N = 256
F32 = np.float32


def phase(t, period):
    return (t / period) % 1.0


def wave(kind, t, period, depth):
    p = phase(t, period)
    if kind == "square":
        return depth * (p < 0.5)
    if kind == "sine":
        return depth * (0.5 + 0.5 * np.sin(2 * np.pi * p))
    if kind == "triangle":
        return depth * (1.0 - abs(2.0 * p - 1.0))
    if kind == "saw":
        return depth * p
    if kind == "dc":
        return depth
    raise ValueError(kind)


def s_fn(spec):
    kind = spec[0]
    if kind == "kill":                                   # ("kill", off_start, off_end)
        _, a, b = spec
        return lambda t: F32(0.0) if a <= t < b else F32(wave("square", t, 147.06, 0.6))
    if kind == "bands":                                  # square gated by 8 cortical row bands
        mask = ((np.arange(N) // (N // 8)) % 2 == 0).astype(F32)[:, None] * np.ones((1, N), F32)
        return lambda t: (mask * F32(wave("square", t, 147.06, 0.6))).astype(F32)
    if kind == "travel":                                 # a WFG-like travelling sine across x
        x = (np.arange(N, dtype=np.float64) / N)[None, :] * np.ones((N, 1))
        return lambda t: (0.6 * (0.5 + 0.5 * np.sin(2 * np.pi * (4 * x - t / 147.06)))).astype(F32)
    _, period, depth = spec                              # (kind, period, depth)
    return lambda t: F32(wave(kind, t, period, depth))


def go(args):
    label, spec, frames = args
    import wc_parity_mirror as m
    m.s_of_t = s_fn(spec)
    st = m.seed_state(N, np.random.default_rng(1))
    es, on_std, off_std = [], [], []
    band = ((np.arange(N) // (N // 8)) % 2 == 0)
    for fr in range(frames):
        st = m.step(st, fr)
        e = st[..., 0]
        es.append(float(e.std()))
        if spec[0] == "bands" and fr >= frames - 600 and fr % 10 == 0:
            on_std.append(float(e[band].std()))
            off_std.append(float(e[~band].std()))
    es = np.array(es)
    late = es[-600:]
    after = np.nonzero(es[300:] > 0.05)[0]
    emerge = int(after[0] + 300) if len(after) else None
    line = (f"{label:24s} {'ALIVE' if late.mean() > 0.03 else 'dead '}  late std mean {late.mean():.3f} "
            f"min {late.min():.3f} max {late.max():.3f}  emerge {emerge}")
    if spec[0] == "kill":
        _, a, b = spec
        rev = np.nonzero(es[b:] > 0.05)[0]
        line += (f"  | std at kill end {es[b - 1]:.4f}, max during kill-last-200 {es[b - 200:b].max():.4f}, "
                 f"revive +{int(rev[0]) if len(rev) else None} frames")
    if spec[0] == "bands":
        line += f"  | late band std on {np.mean(on_std):.3f} / off {np.mean(off_std):.3f}"
    return line


if __name__ == "__main__":
    frames = int(sys.argv[1]) if len(sys.argv) > 1 else 2400
    P = 147.06
    jobs = [(f"A square d0.6", ("square", P, 0.6), frames),
            (f"A sine d0.6", ("sine", P, 0.6), frames),
            (f"A triangle d0.6", ("triangle", P, 0.6), frames),
            (f"A saw d0.6", ("saw", P, 0.6), frames),
            (f"A dc 0.3", ("dc", P, 0.3), frames),
            (f"A dc 0.6", ("dc", P, 0.6), frames)]
    jobs += [(f"B square d{d}", ("square", P, d), frames) for d in (0.2, 0.4, 0.8, 1.0, 1.5)]
    jobs += [(f"C square p{p}", ("square", float(p), 0.6), frames) for p in (37, 74, 294, 588)]
    jobs += [("D kill 1500-2100", ("kill", 1500, 2100), 3600),
             ("E bands x8", ("bands",), frames),
             ("E travelling sine", ("travel",), frames)]
    t0 = time.time()
    with Pool(8) as p:
        for line in p.imap(go, jobs):
            print(line, flush=True)
    print(f"{time.time() - t0:.0f}s")
