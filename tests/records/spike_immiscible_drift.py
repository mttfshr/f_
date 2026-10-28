"""spike_immiscible_drift.py -- the G7 condition set by Matt on 2026-10-27 (tasks.md T017): does the mean of
phi keep climbing under stirring? T006b measured 0.0264 after 600 frames against a pre-registered 0.02.
This runs the same recipe (spike_immiscible_stirring_b: stripes, drops, noise at coarsen 0.3 and 1.0, plus
the plain-advection baselines) for 3600 frames and prints mean(phi) every 300 frames.

Offline mirror, ~5 min. Run (needs the test import path):
  . tests/_log.sh >/dev/null; export PYTHONPATH
  uv run --no-project --with numpy python3 tests/records/spike_immiscible_drift.py
Reading it: a bounded wander (|drift| stops growing, returns toward 0) means accept; a steady climb means
add the k = 0 pull toward `fill` in the spec stage (a slow mean-restore) and re-test.
"""
import numpy as np

import fluid_mirror as fm
import immiscible_mirror as im
from immiscible_mirror import Params
from spike_immiscible_stirring import WARM, advance, fluid_warm, force_tex, packed
from spike_immiscible_stirring_b import starts

N = 256
FRAMES, EVERY = 3600, 300


def main():
    fp, fst = fluid_warm()
    p = Params(iface=4.0, coarsen=0.3, inject=0.0)
    states, params, kind = {}, {}, {}
    for k, v in starts().items():
        for a in ("ch", "plain"):
            states[(k, a)], params[(k, a)], kind[(k, a)] = im.phi_state(v), p, a
    for c in (0.3, 1.0):
        key = ("noise", f"ch@{c}")
        states[key], params[key], kind[key] = im.seed(N, p, 3), p.with_(coarsen=c), "ch"
    mean0 = {k: float(s[..., 0].mean()) for k, s in states.items()}
    rec = {k: [] for k in states}
    for t in range(1, FRAMES + 1):
        fst = fm.step(fst, force_tex(WARM + t - 1), fp)
        uab = packed(fst)
        for key in states:
            states[key] = advance(kind[key], states[key], uab, params[key])
            if t % EVERY == 0:
                rec[key].append(float(states[key][..., 0].mean()) - mean0[key])
    print("mean(phi) - mean(0), every", EVERY, "frames up to", FRAMES)
    print(" " * 18, " ".join(f"{t:>7d}" for t in range(EVERY, FRAMES + 1, EVERY)))
    for key, r in rec.items():
        print(f"{key[0]:<8}{key[1]:<10}", " ".join(f"{x:+7.4f}" for x in r))
    print("\nfinite:", all(np.isfinite(s).all() for s in states.values()))


if __name__ == "__main__":
    main()
