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


def _x_ramp(w=64, h=8):
    """R = x at texel centres (the bench's ramp), G = y, A = 1."""
    nx, ny, _, _ = grid(h, w)
    t = np.zeros((h, w, 4), F32)
    t[..., 0], t[..., 1], t[..., 3] = nx, ny, 1.0
    return t


def test_sample_default_wraps_x_and_clamps_taps_as_measured_on_the_gpu():
    """Measured 2026-10-20 (bench probes P2 and P6, and the pix-to-pix scratch patch): a bare sample() wraps its x
    coordinate modulo 1, then interpolates with edge-clamped taps. 1.3 reads 0.3, -0.2 reads 0.8, and exactly
    1.0 or 0.0 reads the first texel (0.5 / W) with no seam blend. The expected values are the measured GPU
    numbers (0.299988, 0.799988, 0.007812 in the scratch patch), not gpu_sim's own output."""
    w = 64
    t = _x_ramp(w)
    v = F32(0.5)
    got = lambda u: float(sample(t, F32(u), v)[..., 0])
    check("u = 1.3 reads 0.3", abs(got(1.3) - 0.3), 2e-4)
    check("u = -0.2 reads 0.8", abs(got(-0.2) - 0.8), 2e-4)
    check("u = exactly 1.0 reads the first texel", abs(got(1.0) - 0.5 / w), 1e-6)
    check("u = exactly 0.0 reads the first texel", abs(got(0.0) - 0.5 / w), 1e-6)
    check("in-range u is untouched (0.5)", abs(got(0.5) - 0.5), 1e-6)


def test_sample_y_clamps_by_default_until_probe_p7_and_oob_overrides():
    """Vertical out-of-range behaviour is NOT measured yet (probe P7), so y keeps clamping by default; the oob
    argument sets either axis: a string for both, or an (x, y) pair."""
    t = _x_ramp(8, 8)
    top = float(sample(t, F32(0.5), F32(1.0))[..., 1])
    check("default: v = 1.0 clamps to the last row (G = 15/16)", abs(top - 15.0 / 16.0), 1e-6)
    wrapped = float(sample(t, F32(0.5), F32(1.0), oob=("clamp", "wrap_coord"))[..., 1])
    check("oob y wrap_coord: v = 1.0 reads the first row (G = 1/16)", abs(wrapped - 1.0 / 16.0), 1e-6)
    clamped = float(sample(t, F32(1.3), F32(0.5), oob="clamp")[..., 0])
    check("oob clamp: u = 1.3 reads the last column (R = 15/16)", abs(clamped - 15.0 / 16.0), 1e-6)
    manual = float(sample(t, F32(1.3), F32(0.5), wrap=True)[..., 0])
    check("wrap=True is the manual periodic form and ignores oob (u = 1.3 reads 0.3 by periodic taps)", abs(manual - 0.3), 0.07)


if __name__ == "__main__":
    sys.exit(run(globals()))
