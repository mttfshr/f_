"""
test_gpu_sim.py -- the emulator itself (tests/lib/gpu_sim.py): texel-center reads are exact,
the bilinear midpoint blends, wrap indexes around. If this fails nothing else means anything.
Moved here 2026-10-18 from the Phase 0 record tests/records/fft_separable.py.

Run:  tests/run.sh tests/toolchain/test_gpu_sim.py
"""
import sys

import numpy as np

from gpu_sim import F32, grid, nearest, sample
from harness import check, run


def test_sim_sampling_sanity():
    rng = np.random.default_rng(0)
    tex = rng.random((8, 8, 4)).astype(F32)
    nx, ny, _, _ = grid(8, 8)
    check("nearest @ texel centers", np.max(np.abs(nearest(tex, nx, ny) - tex)), 0)
    check("sample @ texel centers", np.max(np.abs(sample(tex, nx, ny) - tex)), 1e-6)
    mid = sample(tex, F32(1 / 8), F32(0.5 / 8))
    check("bilinear midpoint", np.max(np.abs(mid - 0.5 * (tex[0, 0] + tex[0, 1]))), 1e-6)
    wrapped = nearest(tex, F32(-0.01), F32(0.5 / 8), wrap=True)
    check("wrap to last column", np.max(np.abs(wrapped - tex[0, 7])), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
