"""
spike_four_module_cost.py -- diagnostic, not a regression test
(.specify/maintenance/tasks.md "highest-value single session": f_vf_glow,
f_vf_prism, f_vf_streak, f_chladni never had a GPU cost measurement).

All four are bypass_mode "param": the jsui bypass toggle drives a codebox
Param `bypass_gate` that only mixes the OUTPUT toward a passthrough/neutral
value at the very end of the codebox -- it never gates the heavy per-pixel
loop itself. This measures whether that's actually costing real frame time
while "bypassed", using each module's real, shipped codebox text (read
straight from its src/<name>/codebox_*.gen, the same file definition.py
loads), at 512^2 (bench_perf.py's convention), bypass_gate 0.0 and 1.0.

Measurement only -- no codebox is modified or written back.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/spike_four_module_cost.py
"""
import statistics
import sys
from pathlib import Path

import numpy as np

import benchclient as bc

REPO = Path(__file__).resolve().parent.parent
REPEATS = 3          # median of several -- a single measure() sample is noisy
CHAIN = 128
SIZE = 512


def rand(n, seed=0):
    return np.random.default_rng(seed).uniform(0.0, 1.0, (n, n, 4)).astype(np.float32)


MODULES = {
    "f_vf_glow": {
        "codebox": REPO / "src" / "f_vf_glow" / "codebox_v1.gen",
        "n_inputs": 3,  # in1 source, in2 vecfield, in3 radius mod
        "params": {"radius": 0.01, "falloff": 0.002, "gain": 0.8, "mix_pct": 0.0,
                   "color_mix": 0.0, "direction": 0.0},
    },
    "f_vf_prism": {
        "codebox": REPO / "src" / "f_vf_prism" / "codebox_v17.gen",
        "n_inputs": 3,  # in1 source, in2 vecfield, in3 reach mod (in4 spread mod unwired -- bench caps at 3 inputs)
        "params": {"reach": 0.05, "spread": 0.1, "threshold": 0.7, "threshold_width": 0.1,
                   "feather": 0.1, "gain": 1.0, "mix_pct": 100.0, "src_vecfield": 1.0,
                   "src_length_mod": 0.0, "src_width_mod": 0.0},
    },
    "f_vf_streak": {
        "codebox": REPO / "src" / "f_vf_streak" / "codebox_v1.gen",
        "n_inputs": 2,  # in1 source, in2 vecfield
        "params": {"gain": 0.3, "mix_pct": 0.0, "length": 0.15, "falloff": 0.0,
                   "color_shift": 0.0, "src_vecfield": 1.0},
    },
    "f_chladni": {
        "codebox": REPO / "src" / "f_chladni" / "definition.py",  # CODEBOX is inline, not a .gen
        "n_inputs": 1,  # generator -- no texture inputs referenced; one input only for sizing
        "params": {"note": 60.0, "amp": 1.0, "dishradius": 1.0, "reflectamt": 0.0,
                   "linesharpness": 10.0, "ph0": 0.0, "spread": 0.3, "mode": 0.0,
                   "view_mode": 0.0, "gain": 1.0},
    },
}


def load_codebox(name, spec):
    if name == "f_chladni":
        # codebox lives inline as CODEBOX = """...""" in definition.py
        ns = {}
        exec(compile(spec["codebox"].read_text(), str(spec["codebox"]), "exec"), ns)
        return ns["CODEBOX"]
    return spec["codebox"].read_text()


def measure_one(code, n_inputs, params, bypass_gate):
    inputs = [rand(SIZE, seed=i) for i in range(n_inputs)]
    samples = []
    bound = None
    for _ in range(REPEATS):
        p = dict(params)
        p["bypass_gate"] = float(bypass_gate)
        r = bc.measure(code, inputs, chain=CHAIN, params=p)
        if r["status"] != "ok":
            raise RuntimeError(f"bench job failed: {r}")
        bound = r["gpu_bound"]
        samples.append(r["ms_per_pass"] if bound else r["ms_per_pass_upper_bound"])
    return statistics.median(samples), bound


def main():
    bc.require_bench()
    results = {}
    for name, spec in MODULES.items():
        code = load_codebox(name, spec)
        print(f"=== {name} (512x512, chain={CHAIN}) ===")
        for bg in (0.0, 1.0):
            ms, bound = measure_one(code, spec["n_inputs"], spec["params"], bg)
            flag = "" if bound else "  (upper bound -- cheaper than CPU-overhead floor)"
            label = "active (bypass=0)" if bg == 0.0 else "bypassed (bypass=1)"
            print(f"  {label:<22} {ms:7.4f} ms/pass{flag}")
            results[(name, bg)] = (ms, bound)
        active_ms, _ = results[(name, 0.0)]
        bypass_ms, _ = results[(name, 1.0)]
        delta = active_ms - bypass_ms
        pct = (delta / active_ms * 100.0) if active_ms else 0.0
        print(f"  -> bypass saves {delta:7.4f} ms/pass ({pct:5.1f}% of active cost)")
        print()

    print(f"{'module':<14} {'active ms/pass':>16} {'bypassed ms/pass':>18} {'bypass saves':>14}")
    for name in MODULES:
        a, _ = results[(name, 0.0)]
        b, _ = results[(name, 1.0)]
        print(f"{name:<14} {a:>16.4f} {b:>18.4f} {a - b:>14.4f}")


if __name__ == "__main__":
    sys.exit(main())
