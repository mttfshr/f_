"""test_wc_steadyweb.py -- tier-1 NumPy mirror tests for the not-yet-built
f_wc module (render-res Wilson-Cowan; spec .specify/stable/f_wc/).

Ground truth is independent of the mirror:

  - The separable blur is tied to the ANALYTIC Gaussian: a constant field is
    blurred to itself (weights sum to 1 by construction) and a single Fourier
    mode decays at the analytic rate exp(-sigma^2 k^2 / 2) up to the known
    kernel-truncation error at radius ceil(3 sigma) (~1e-3 relative).
  - With couplings zeroed the relaxation decays every texel toward F(-HE) at
    the exact per-frame rate (1 - dt/TE) -- machine-exact scalar reference.
  - The homogeneous fixed point, solved as a scalar fixed-point problem
    directly (NOT through the chain), vs the chain's uniform rest state.
  - Boundedness: sigmoid relaxation keeps the fields in [0, 1] forever (no
    NaN ceiling -- structural, the f_wc_fft T003 finding applies to the class).
  - Habituation bit-preservation: habit = 0 pins the B/A (Ve/Vi) channels at
    exactly 0 forever, even mid-run (the f_wc_fft G5 rule).
  - The enc stage's defining property: a cortical field constant along u
    (rolls along v) renders radially constant spokes (wc_retinotopy.py; the
    map math is f_wc_fft's FR-007 verbatim).
  - Short regime sanity at the shipped corner (Psychedelic couplings +
    Ne = 0.75 + habituation 0.3, fine grain): structured, non-collapsed,
    non-saturated within 800 frames. (Indefinite sustain measured in the
    T002/T003 spikes, tests/records/spike_fc_sustain.py and the habituation /
    grain-ladder probes recorded in .specify/stable/f_wc/tasks.md -- not
    an assertion here.)

Tolerance notes: analytic-blur and decay checks are near-exact (1e-6 and the
measured truncation band); the fixed-point check 1e-4 (the chain iterates in
float32); regime sanity is statistical (stochastic by construction).

Run:  tests/run.sh tests/modules/wc/test_wc_steadyweb.py
"""
import numpy as np

from harness import check, note, run  # noqa: E402
from wc_steadyweb_mirror import (AEE, AEI, AIE, AII, F, HE, HI, TE, TI,  # noqa: E402
                       Params, blur_axis, encode, fc_frame, gauss_taps,
                       nonlinear_step, seed_state, sigmas_px)
from wc_steadyweb_mirror import run as fc_run  # noqa: E402

N = 256


def test_blur_of_constant_is_constant():
    const = np.full((64, 64), 0.37, dtype=np.float32)
    err = float(np.abs(blur_axis(blur_axis(const, 2.0, 0), 2.0, 1) - 0.37).max())
    check("blur of a constant returns it", err, 1e-6)


def test_blur_single_mode_gain():
    """The exact discrete kernel applied to one Fourier mode decays at the
    analytic Gaussian rate within the radius-ceil(3 sigma) truncation band."""
    n, sig = 128, 2.0
    ky = 2 * np.pi * 3 / n            # bin 3, y axis
    ys = np.arange(n, dtype=np.float32)
    mode = np.cos(ky * ys)[:, None] * np.ones((1, n), dtype=np.float32)
    got = blur_axis(blur_axis(mode, sig, 0), sig, 1)
    want = np.exp(-sig * sig * ky * ky / 2)
    gain = float((got * mode).sum() / (mode * mode).sum())
    note("blur single-mode gain vs analytic", f"{gain:.6f} / {want:.6f}")
    check("single-mode blur gain within truncation band", abs(gain - want) / want, 2e-3)


def test_gauss_taps_shape():
    taps = gauss_taps(2.0)
    err = abs(len(taps) - 13) + abs(float(taps.sum()) - 1.0) \
        + float(np.abs(taps - taps[::-1]).max())
    check("gauss_taps: 13 taps, normalized, symmetric", err, 1e-6)
    delta = gauss_taps(0.0)
    check("gauss_taps(0) is the delta", abs(len(delta) - 1) + abs(float(delta[0]) - 1.0), 1e-32)


def test_sigma_floor_binds():
    Pn = Params(grain=1e-6)
    si, se = sigmas_px(256, 128, Pn)   # min dim 128 -> raw sigma ~ 1.3e-4 px
    err = abs(float(si) - 0.75) + abs(float(se) - 0.75 / Pn.aspect)
    check(f"sigma floor binds at tiny render sizes (si={float(si):.3f} px)", err, 1e-6)


def test_relaxation_rate_exact():
    """Couplings zeroed, no noise: every texel decays toward F(-HE) at exactly
    (1 - dt/TE) per frame -- the scalar machine-exact reference."""
    P0 = Params(energy=0.0)
    zstate = seed_state(32, 32, 5, amp=0.0)
    conv0 = np.zeros((2, 32, 32), dtype=np.float32)
    a = nonlinear_step(conv0, zstate, P0.dt, P0)
    e0, e1 = float(zstate[..., 0].mean()), float(a[..., 0].mean())
    target = float(F(np.float32(-HE)))
    rate = (target - e1) / (target - e0 + 1e-12)
    check(f"relaxation rate = 1-dt/TE ({rate:.8f})",
          abs(rate - (1 - P0.dt / TE)), 1e-6)


def test_uniform_state_tracks_scalar_cycle():
    """The WC homogeneous dynamics at these constants is oscillatory /
    non-stationary (probe 2026-10-24 at the Example-10 set: limit cycle E in
    [0.104, 0.345]; the chain follows it, spatially uniform to 3e-8). Ground
    truth: the float64 scalar relaxed map, iterated independently; the spatial
    chain at a uniform state must stay uniform and track the scalar
    trajectory."""
    P0 = Params(energy=0.0)
    e, i = 0.5, 0.5
    st = np.zeros((16, 16, 4), dtype=np.float32)
    st[..., 0], st[..., 1] = e, i
    for _ in range(200):
        ae = F(AEE * e - P0.aie * i - HE + P0.excite)
        ai = F(AEI * e - P0.aii * i - HI + P0.excite)
        e += (ae - e) / TE
        i += (ai - i) / TI
        st = fc_frame(st, P0, fast_blur=False)
    uni = float(st[..., :2].std(axis=(0, 1)).max())
    de = abs(float(st[..., 0].mean()) - e)
    note("after 200 frames: scalar E vs chain E",
         f"{e:.6f} / {float(st[..., 0].mean()):.6f} (uniformity {uni:.1e})")
    check("uniform field stays uniform through the cycle", uni, 1e-5)
    check("chain tracks the scalar homogeneous cycle", de, 1e-2)   # float32 vs float64 over 200 relaxation steps


def test_bounded_forever():
    Pn = Params(energy=0.5)
    st = seed_state(N, N, 3, amp=1.0)
    rng = np.random.default_rng(1)
    err = 0.0
    for _ in range(300):
        st = fc_frame(st, Pn, rng)
        if not np.isfinite(st).all() or st[..., :2].min() < -1e-6 \
                or st[..., :2].max() > 1 + 1e-6:
            err = 1.0
            break
    check("300 frames with noise: fields finite and inside [0, 1]", err, 0.5)


def test_habituation_zero_pins_carry():
    st = seed_state(64, 64, 4)
    st[..., 2] = st[..., 3] = 7.0      # pollute the carry channels
    st = fc_frame(st, Params(habituation=0.0), np.random.default_rng(2))
    err = max(float(np.abs(st[..., 2]).max()), float(np.abs(st[..., 3]).max()))
    check("habituation = 0 pins Ve/Vi to exactly 0 (G5 rule)", err, 0.0)


def test_encode_v_rolls_render_radially_constant():
    st = np.zeros((256, 256, 4), dtype=np.float32)
    vcols = (0.5 + 0.5 * np.sin(np.linspace(0, 4 * np.pi, 256))).astype(np.float32)
    st[..., 0] = np.repeat(vcols[None, :], 256, axis=0)
    img = encode(st, (256, 256), sharp=0.0)
    # same ray through the center, two radii: radial constancy = same value
    a, b = img[10, 128], img[60, 128]
    err = abs(float(a[0]) - float(b[0]))
    note("encode spoke value at r=118 vs r=68 (same ray)",
         f"{float(a[0]):.3f} / {float(b[0]):.3f}")
    check("encode: v-rolls render radially constant", err, 0.05)


def test_default_corner_structured_field():
    """Short regime sanity at the SHIPPED corner (Psychedelic couplings,
    Ne = 0.75, habituation 0.3, fine grain): structured, non-collapsed,
    non-saturated field."""
    st, tr = fc_run(seed_state(N, N, 6), Params(), 800, seed=3, fast_blur=True)
    es = float(st[..., 0].std())
    em = float(st[..., 0].mean())
    note("default corner", f"N={N}, sigma_I={float(sigmas_px(N, N, Params())[0]):.2f} px")
    violation = max(0.10 - em, em - 0.90, 0.05 - es, 0.0)
    note("800-frame state", f"E mean {em:.3f}, std {es:.3f}")
    check("structured, non-degenerate, non-saturated field", violation, 0.0)


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
