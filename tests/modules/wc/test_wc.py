"""test_wc.py -- tier-1 NumPy mirror tests for the not-yet-built f_wc module.

Ground truth is independent of the mirror:

  - np.fft in float64 (the mirror's fast path) is the reference for the
    transform stages; the pass_dft chain is tied to it at N = 32.
  - The analytic per-bin kernel gain exp(-sigma^2 k^2 / 2) for a single
    spectral bin (machine-exact), E pair vs I pair.
  - The homogeneous fixed point, solved as a scalar fixed-point problem in
    float64 (NOT through the chain), vs the chain's uniform rest state.
  - The settled model's own load-bearing mechanism (the Phase-0 ablation,
    tasks.md T005): per-frame noise sustains the labyrinth; NO per-frame noise
    collapses it to uniform.
  - The T007 drive-coupling crossover, as an ORDERING: scene-tracking
    correlation rises with drive_gain (weak = hallucinate, strong = see),
    with amplitude held high either way (Success Criterion 4).
  - Boundedness: the sigmoid relaxation keeps the fields in [0, 1] forever
    (no NaN ceiling exists -- the spec's NF-003 is structural).
  - The retinotopic encode's defining property: a cortical pattern constant
    along u rolls along v) renders radially constant (spokes / cobweb),
    whatever the radius (wc_retinotopy.py, T006).

Tolerance notes: single-bin and scalar-fixed-point checks are near-exact
(1e-6); pass-chain-vs-np.fft gets float32-comfortable 1e-4; collapse amplitude
gives 0.02. The sustained-pattern and drive-correlation checks are statistical
(the state is stochastic per run BY CONSTRUCTION -- fresh noise per frame);
their thresholds sit an order of magnitude from the failure side of the
measured Phase-0 values (std ~0.3 sustained vs ~0.01 collapsed; corr 0.17
weak vs 0.77+ strong, T007 at N = 256). Tests run the G3-verified corner
(Ne = 1.0, sigma_I = 1.4) at N = 128 (8 pattern wavelengths across; the
mechanism is pixel-scale and scale-free).

Run:  tests/run.sh tests/modules/wc/test_wc.py
"""
import numpy as np

from gpu_sim import F32, texture  # noqa: E402
from harness import check, note, run  # noqa: E402
from wc_mirror import (AEE, AEI, AIE, AII, F, HE, HI,  # noqa: E402
                       Params, encode, k2_tex, run_temporal, seed_state,
                       fwd_dft, inv_dft_real, spec_stage, wc_frame)

N = 128          # test domain (np.fft fast path; the pass chain is checked at 32)


def state_at(n, seed=3, amp=1.0):
    return seed_state(n, n, seed, amp=F32(amp))


def corr2d(a, b):
    a = a.ravel().astype(np.float64) - a.mean()
    b = b.ravel().astype(np.float64) - b.mean()
    return float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12))


# ---------------------------------------------------------- transform stages

def test_pass_chain_matches_fft():
    """The four-pass separable DFT (what the GPU does per pixel, two complex
    fields in one chain) equals np.fft (the fast path) at N = 32 -- the f_ks /
    dft_mirror precedent, here proving the E/I pair packing too."""
    s = state_at(32, seed=5)
    a = fwd_dft(s, fast=False)
    b = fwd_dft(s, fast=True)
    err = float(np.abs(a - b).max()) / float(np.abs(b).max())
    check("fwd_dft pass chain vs np.fft (4 channels)", err, 1e-4)
    ca = inv_dft_real(spec_stage(a, 0.9, 1.4), fast=False)
    cb = inv_dft_real(spec_stage(b, 0.9, 1.4), fast=True)
    err = float(np.abs(ca - cb).max()) / max(float(np.abs(cb).max()), 1e-12)
    check("round trip pass chain vs np.fft", err, 1e-4)
    check("imaginary channels zeroed after round trip",
          float(np.abs(ca[..., [1, 3]]).max()), 0.0)


def test_single_bin_kernel_gain():
    """spec_stage multiplies a lone spectral bin by exactly exp(-sigma^2 k^2/2)
    for its own field's sigma (E pair vs I pair), gains 1 on the empty bins,
    and does NOT zero DC (DC zeroing is KS-specific)."""
    n = 32
    uh = texture(n, n)
    binx, biny = 5, 3
    uh[biny, binx, :] = (1.0, 0.7, 0.4, -0.3)     # E pair 1+0.7j, I pair 0.4-0.3j
    uh[0, 0, :] = (2.0, 0.0, 1.0, 0.0)            # DC in both fields
    mask = np.ones((n, n), bool)
    mask[0, 0] = False
    mask[biny, binx] = False
    sig_e, sig_i = 0.9, 1.4
    out = spec_stage(uh, sig_e, sig_i)
    k2 = float(k2_tex(n, n)[biny, binx])
    ge = np.exp(-0.5 * sig_e * sig_e * k2)
    gi = np.exp(-0.5 * sig_i * sig_i * k2)
    expect = np.array([ge * 1.0, ge * 0.7, gi * 0.4, gi * -0.3], dtype=F32)
    check("E/I per-bin kernel gain",
          float(np.abs(out[biny, binx] - expect).max()), 1e-6)
    check("DC bin NOT zeroed",
          float(np.abs(out[0, 0] - uh[0, 0]).max()), 0.0)
    check("empty bins stay 0 (gain applied but harmless)",
          float(np.abs(out[mask]).max()), 0.0)


# ---------------------------------------------------------- the mechanism

def test_rest_state_uniform():
    """With noise and drive off, a uniform state relaxes to the homogeneous
    fixed point -- solved independently below as a scalar iteration of the
    same equations in float64 -- and a SEEDED field decays toward uniform
    (the Phase-0 ablation: per-frame noise is the load-bearing mechanism)."""
    e = i_ = 0.0                                                # scalar truth
    for _ in range(2000):
        e, i_ = F(AEE * e - AIE * i_ - HE), F(AEI * e - AII * i_ - HI)
    P = Params(ne=0.0, drive_gain=0.0, rate=1.0, fast_fft=True)
    u = state_at(N, seed=7, amp=0.0)
    for _ in range(200):
        u = wc_frame(u, np.random.default_rng(0), P)
    note("uniform rest (chain vs scalar fixpoint)",
         (float(u[..., 0].mean()), float(u[..., 2].mean()), float(e), float(i_)))
    check("uniform field stays uniform", float(u.std(axis=(0, 1)).max()), 1e-5)
    check("chain rest E == scalar fixed point",
          float(abs(u[..., 0].mean() - e)), 1e-3)
    check("chain rest I == scalar fixed point",
          float(abs(u[..., 2].mean() - i_)), 1e-3)

    s = run_temporal(state_at(N, seed=9), P, 300, seed=9)
    note("no-noise late std", float(s[..., 0].std()))
    check("seeded field collapses without per-frame noise",
          float(s[..., 0].std()), 0.02)


def test_noise_sustains_pattern():
    """THE mechanism (tasks.md T005): with Ne = 1.0 fresh noise per frame the
    pattern has real contrast for the whole run (Phase 0: std ~0.3 sustained
    vs ~0.01 collapsed; threshold sits an order above the collapse side)."""
    P = Params(ne=1.0, drive_gain=0.0, rate=1.0, fast_fft=True)
    s = run_temporal(state_at(N, seed=11), P, 400, seed=11)
    note("noise-driven late std (E)", float(s[..., 0].std()))
    check("per-frame noise sustains contrast",
          -float(s[..., 0].std()), -0.03)


def test_drive_coupling_ordering():
    """T007 / G3: raw additive drive on E only. Weak drive = hallucinate (low
    correlation with the scene), strong drive = see (high correlation);
    amplitude stays high either way. Ordering with a wide margin (T007 at
    N = 256: corr 0.17 at dg = 0.2, 0.77+ at dg >= 1.0)."""
    n = N
    rng = np.random.default_rng(13)
    raw = rng.random((n, n))
    z = np.fft.fft2(raw)
    k2 = k2_tex(n, n).astype(np.float64)
    raw = np.real(np.fft.ifft2(z * np.exp(-0.5 * 3.0 * 3.0 * k2)))   # smooth to pattern scale
    raw = (raw - raw.min()) / (raw.max() - raw.min() + 1e-12)
    scene = texture(n, n)
    scene[..., 0] = raw.astype(F32)
    s_lo = run_temporal(state_at(n, seed=17), Params(ne=1.0, drive_gain=0.2, fast_fft=True), 400,
                        seed=17, driv=scene)
    s_hi = run_temporal(state_at(n, seed=17), Params(ne=1.0, drive_gain=1.5, fast_fft=True), 400,
                        seed=17, driv=scene)
    c_lo = corr2d(s_lo[..., 0], raw)
    c_hi = corr2d(s_hi[..., 0], raw)
    note("corr drive_gain 0.2 / 1.5", (c_lo, c_hi))
    note("std drive_gain 0.2 / 1.5",
         (float(s_lo[..., 0].std()), float(s_hi[..., 0].std())))
    check("strong drive tracks the scene better than weak", c_lo - c_hi, -0.2)
    check("amplitude stays high (weak drive, hallucinating)",
          -float(s_lo[..., 0].std()), -0.05)


def test_bounded_forever():
    """No NaN ceiling exists by construction: relaxation toward a [0, 1]
    sigmoid output with dt/TE <= 0.25 keeps every value in [0, 1]. Run at the
    hardest settings (max rate, max drive, max noise) and check."""
    P = Params(ne=1.5, drive_gain=2.0, rate=1.0, fast_fft=True)
    s = state_at(N, seed=19)
    rng = np.random.default_rng(19)
    for _ in range(300):
        s = wc_frame(s, rng, P)
        assert np.isfinite(s).all(), "non-finite state"
    check("fields stay within [0, 1]",
          max(0.0, float(s[..., [0, 2]].max() - 1.0), -float(s[..., [0, 2]].min())), 1e-5)


# ---------------------------------------------------------- encode

def test_encode_rolls_along_v_render_radially_constant():
    """The retinotopic map's defining transform (T006): a cortical pattern
    constant along u -- rolls along v -- maps to visual-field spokes/cobweb
    (constant per angle). Checked as radial constancy: three radii at the
    same angle agree. Sampled bilinearly in the output; the tolerance (0.05)
    absorbs the one remaining discretization (a ~1-pixel angular quantization
    costs ~1/30 of the 4-period pattern's cycle at the steepest slope) while
    staying well below the axis-swap / wrong-axis failure signatures measured
    while writing this test (0.2-0.7)."""
    n = 128
    s = texture(n, n)
    j = np.arange(n, dtype=F32)[None, :]
    s[..., 0] = 0.5 + 0.4 * np.cos(2.0 * np.pi * j * 4.0 / n)   # pattern in v (columns)
    out = encode(s, 256)
    o = out.shape[0]

    def bilerp(img, y, x):
        y0, x0 = int(np.floor(y)), int(np.floor(x))
        ty, tx = y - y0, x - x0
        return float(img[y0, x0] * (1 - tx) * (1 - ty) + img[y0, x0 + 1] * tx * (1 - ty)
                     + img[y0 + 1, x0] * (1 - tx) * ty + img[y0 + 1, x0 + 1] * tx * ty)

    for theta in (0.37, 1.9, -0.8, 2.9):
        vals = []
        for r_frac in (0.45, 0.75, 0.95):
            x = o / 2 + r_frac * (o / 2) * np.cos(theta)
            y = o / 2 + r_frac * (o / 2) * np.sin(theta)
            vals.append(bilerp(out[..., 0], y, x))
        check(f"radially constant at theta={theta}", float(np.ptp(vals)), 0.05)
    check("encode output in [0, 1]", max(float(out[..., 0].max() - 1.0),
                                         -float(out[..., 0].min())), 0.0)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
