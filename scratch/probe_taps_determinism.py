"""Diagnostic: is the 39% smooth-force difference between taps 1 and 8 real,
or is the harness comparing two chaotic states that drifted apart?

Arm A  same force, SAME taps, run twice  -> pure run-to-run reproducibility.
Arm B  same force, taps 1 vs 8, short warmup -> effect before nonlinearity bites.
Arm C  same force, taps 1 vs 8, long warmup  -> what the failing test measured.

If A is as large as C, the settled state is not reproducible and comparing
settled states is the wrong method, whatever taps does.
"""
import sys
sys.path.insert(0, "tests")

import numpy as np
import benchclient as bc
import bench_fluid_module as m

RB = {"taps": ["fluid_adv"], "viscosity": ["fluid_spec"]}
clean = m.smooth_force()


def rel(a, b):
    return float(np.sqrt(np.mean((a - b) ** 2))) / max(float(np.sqrt(np.mean(b ** 2))), 1e-12)


bc.require_bench(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
for warmup in (12, 48):
    a1 = m.solve(clean, 8, RB, warmup=warmup)
    a2 = m.solve(clean, 8, RB, warmup=warmup)
    t1 = m.solve(clean, 1, RB, warmup=warmup)
    print(f"warmup {warmup}: repeat(taps 8 vs taps 8) = {rel(a1, a2):.4f}   "
          f"taps 1 vs taps 8 = {rel(t1, a2):.4f}   "
          f"field rms = {float(np.sqrt(np.mean(a2 ** 2))):.4f}")
