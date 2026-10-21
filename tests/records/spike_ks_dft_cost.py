"""
spike_ks_dft_cost.py -- f_ks DFT cost spike (2026-10-21). Measurement only, no new codebox.

Question: what does the per-pixel O(N) DFT chain cost per frame at N = 64 / 128 / 256 on the GPU?
f_ks needs the same four passes per frame as f_vf_fluid (forward x, forward y, inverse y, inverse x);
the f_vf_fluid codeboxes already carry two complex fields per pass in RGBA, so one scalar field is
no more work. The only change to each shipped codebox here is the size constant (N and the loop
bound), substituted in text; the spec stage and the nonlinear step are NOT timed.

Method: tests/lib/benchclient.measure per pass (chain raised 8 -> 16 -> 32 until GPU bound), the
same method as bench_fluid.py T021. The bench keeps Params between jobs, but these codeboxes have none.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/records/spike_ks_dft_cost.py
"""
GROUP = "record"   # a Phase 0 measurement, not a regression gate
ORDER = 90

import paths as _paths
import re
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import note, run

SRC = _paths.REPO / "src" / "f_vf_fluid"
STAGES = ["codebox_dft_fx.gen", "codebox_dft_fy.gen", "codebox_dft_iy.gen", "codebox_dft_ix.gen"]


def sized(text, n):
    """The shipped codebox at size n: `N = 256;` and the loop bound `n < 256`, nothing else."""
    out, c1 = re.subn(r"^N = 256;", f"N = {n};", text, flags=re.M)
    out, c2 = re.subn(r"n < 256;", f"n < {n};", out)
    assert c1 == 1 and c2 == 1, f"size substitution hit {c1}/{c2} places"
    return out


def pass_cost(code, n):
    rng = np.random.default_rng(n)
    tex = rng.standard_normal((n, n, 4)).astype(np.float32)
    r = None
    for chain in (8, 16, 32, 64):
        r = bc.measure(code, [tex], dim=(n, n), chain=chain)
        if r.get("gpu_bound"):
            return r["ms_per_pass"], chain, True
    return r.get("ms_per_pass_upper_bound", float("nan")), chain, False


def test_ks_dft_cost_by_size():
    """Report ms per pass for each of the four DFT passes at N = 64, 128, 256, and the 4-pass frame total."""
    for n in (64, 128, 256):
        total, resolved = 0.0, True
        for name in STAGES:
            ms, chain, bound = pass_cost(sized((SRC / name).read_text(), n), n)
            total += ms
            resolved &= bound
            print(f"    ...  N={n:3d} {name[8:-4]:7s} {ms:7.3f} ms/pass  (chain {chain}, {'GPU bound' if bound else 'UPPER BOUND'})")
        note(f"N={n}: four DFT passes, ms/frame{'' if resolved else ' (some upper bounds)'}", total)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
