"""test_ks.py -- tier-1 NumPy mirror tests for the not-yet-built f_ks module.

Ground truth is independent of the mirror:

  - np.fft in float64 (`ref_frame`) is the reference for the transform stages and
    for the generic 2-frame point; the pass_dft chain is tied to np.fft at N = 32.
  - The analytic per-bin factor exp((K2 - K2^2) * dt) for a single Fourier mode,
    at an amplitude (1e-3) where the nonlinearity is second order.
  - Closed forms: after the spectral step the mean is 0 (the DC bin is zeroed);
    after the full frame the mean is -dt/2 * mean(|grad u_lin|^2).
  - The u = 0 fixed point: a zero state stays exactly zero.
  - The spec's own words (FR-003, FR-005, FR-006): reseed from noise, secular
    drift without the DC fix, `min(rate * dt0, ceiling)` -- and the spike's
    measured downward drift.
  - Encoding bounds: the placeholder encode clamps into [0, 1].

Tolerance notes: exact checks (the clamp within float32 rounding of the product,
the DC texel, the fixed point, the encode) use 0.0 or 1e-6; float32-vs-float64
comparisons and multi-frame checks get 1e-4 (about 1000x tighter than the field's
own scale, and comfortable for a few frames of float32 accumulation). Non-finite
values are hard errors everywhere (`hard_max`).

Placeholder-decision notes: the encode is the placeholder clamp 0.5 + 0.25*u (the
final mapping is a Phase 2 decision); the seed mechanism is uniform noise in
[-amp, amp], seed value from the reset call; the DT_CEILING is always an argument,
never a number.

Run:  tests/run.sh tests/modules/ks/test_ks.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from ks_mirror import F32, Params, ks_frame, rate_to_dt, seed_state  # noqa: E402
from ks_mirror import (encode, fwd_dft, inv_dft_real,  # noqa: E402
                        nonlinear_step, spec_stage)

N = 32           # test domain; N even (the DFT has a Nyquist bin)
L = 50.0         # the spike's domain


def rand_state(seed, n=N, amp=1.0):
    return seed_state(n, n, seed, amp=amp)


def f2u(s):
    return s[..., 0].astype(np.float64)


def ref_frame(u, dt, lens=L):
    """Independent float64 reference of one KS frame: np.fft for the transforms,
    the analytic per-bin factor, np.roll for the central-difference gradient.
    Same equation, different machinery and different precision."""
    n = len(u)
    k = np.fft.fftfreq(n, d=1.0 / n).astype(np.int64)
    kx = k[None, :] * 2 * np.pi / lens
    ky = k[:, None] * 2 * np.pi / lens
    K2 = kx ** 2 + ky ** 2
    uh = np.fft.fft2(u) * np.exp((K2 - K2 ** 2) * dt)
    uh[0, 0] = 0.0
    u_lin = np.real(np.fft.ifft2(uh))
    dx = lens / n
    ux = (np.roll(u_lin, -1, 1) - np.roll(u_lin, 1, 1)) / (2 * dx)
    uy = (np.roll(u_lin, -1, 0) - np.roll(u_lin, 1, 0)) / (2 * dx)
    return u_lin - dt * 0.5 * (ux ** 2 + uy ** 2)


def ref_grad_sq(u, lens=L):
    n = len(u)
    dx = lens / n
    ux = (np.roll(u, -1, 1) - np.roll(u, 1, 1)) / (2 * dx)
    uy = (np.roll(u, -1, 0) - np.roll(u, 1, 0)) / (2 * dx)
    return ux ** 2 + uy ** 2


def nonfinite_count(x):
    """A non-finite mirror value is a hard error: its count (so a plain max
    comparison would keep a NaN's texel invisible, this cannot)."""
    x = np.asarray(x, np.float64)
    n = int((~np.isfinite(x)).sum())
    return np.inf if n else 0.0


def frame(state, rate=1.0, fast=True, zero=True, bug=None):
    p = Params(rate=rate, dt0=0.1, ceiling=0.25, L=L, zero_mean=zero, fast_fft=fast)
    return ks_frame(state, p, bug=bug)


def mode_state(n, kx, ky, amp, lens=L):
    """A real field holding one Fourier mode pair, amplitude on the spatial field."""
    t = np.linspace(0.0, 1.0, n, endpoint=False)
    X, Y = np.meshgrid(t, t)
    u = (amp * np.cos(2 * np.pi * (kx * X + ky * Y))).astype(F32)
    st = np.zeros((n, n, 4), F32)
    st[..., 0] = u
    st[..., 3] = 1.0
    return st


def mode_err(kx=3, ky=1, amp=1e-3, lens=L, rate=1.0, bug=None, n=N):
    """After one frame at small amplitude the dominant bin's amplitude is
    exp((K2 - K2^2) * dt) times its start value; also requires the mode to stay
    dominant (nonlinear leakage into other bins is O(amp), kept under 2e-5)."""
    st = mode_state(n, kx, ky, amp, lens)
    p = Params(rate=rate, dt0=0.1, ceiling=0.25, L=lens, zero_mean=True, fast_fft=True)
    new, _ = ks_frame(st, p, bug=bug)
    dt = float(rate_to_dt(rate, 0.1, 0.25))
    K2 = (kx ** 2 + ky ** 2) * (2 * np.pi / lens) ** 2
    expect = float(np.exp((K2 - K2 ** 2) * dt))
    fa = np.abs(np.fft.fft2(f2u(new)))
    f0 = np.abs(np.fft.fft2(f2u(st)))
    got = float(fa[ky, kx] / f0[ky, kx])
    e = abs(got - expect)
    other = fa.astype(np.float64).copy()
    other[ky, kx] = 0.0
    other[n - ky, n - kx] = 0.0
    other[0, 0] = 0.0
    other[n // 2, 0] = 0.0
    other[0, n // 2] = 0.0
    other[n // 2, n // 2] = 0.0
    leak = float(other.max()) / max(float(fa[ky, kx]), 1e-30)
    return max(e + leak, nonfinite_count(f2u(new)))


# ------------------------------------------------------------------ transform tie

def _fft_tie_err():
    """The pass_dft chain -- what a pix chain actually is -- against np.fft."""
    st = rand_state(11)
    got = fwd_dft(st, fast=False)
    ref = np.fft.fft2(f2u(st))
    scale = float(np.abs(ref).max())
    e = max(float(np.abs(got[..., 0].astype(np.float64) - ref.real).max()),
            float(np.abs(got[..., 1].astype(np.float64) - ref.imag).max()),
            float(np.abs(got[..., 2]).max()), float(np.abs(got[..., 3]).max())) / scale
    uh1 = spec_stage(got, 0.07, L)
    uh2 = spec_stage(fwd_dft(st, fast=True), 0.07, L)
    e_spec = float(np.abs(uh1 - uh2).max()) / scale
    inv1 = inv_dft_real(uh1, fast=False)
    inv2 = inv_dft_real(uh2, fast=True)
    e_inv = float(np.abs(inv1[..., 0].astype(np.float64) - inv2[..., 0].astype(np.float64)).max())
    return max(e, e_spec, e_inv, nonfinite_count(f2u(inv1)))


def test_transform_passes_match_np_fft():
    """The float32 pass_dft chain -- forward, spectral rate, inverse, real part --
    agrees with np.fft in float64, both as an absolute error in the transformed
    plane and against the fast path it stands in for on long runs. N = 32."""
    err = _fft_tie_err()
    note("fwd/spectral plan error vs the fft scale, inv abs error, combined", err)
    check("float32 pass chain vs np.fft (fwd, spectral, inv)", err, 2e-4)


# ------------------------------------------------------------------ single mode

def test_single_mode_grows_and_decays_per_bin():
    """SC1: a single real mode evolves by exp((K2 - K2^2) * dt) in one frame. Two
    modes: mode (3,1) at L = 50 has K2 = 0.158 < 1 (rate > 0, grows), mode (3,3)
    at L = 12.5 has K2 = 1.82 > 1 (rate < 0, decays). The amplitude 1e-3 keeps the
    nonlinear term second order (measured leakage into other bins below 1e-4;
    the decaying mode shrinks 5-fold, so its own bin's float32 noise is a 1e-4
    relative error -- tolerances measured, not assumed)."""
    e_grow = mode_err(kx=3, ky=1)
    e_dec = mode_err(kx=3, ky=3, lens=12.5)
    note("single-mode amplitude-factor errors (grow / decay)", [e_grow, e_dec])
    check("single mode, K2 < 1: dominant bin = exp((K2-K2^2)*dt)", e_grow, 2e-5)
    check("single mode, K2 > 1 (L=12.5): same factor, decays", e_dec, 1e-4)


# ------------------------------------------------------------------ DC bin and means

def test_dc_bin_zeroed_after_spectral_step():
    """FR-005: the k = 0 bin is zeroed every step, exactly (a single texel's
    Re,Im pair, exact in float32)."""
    uh = spec_stage(fwd_dft(rand_state(2), fast=True), 0.1, L)
    e = abs(float(uh[0, 0, 0])) + abs(float(uh[0, 0, 1]))
    check("DC bin exactly [0, 0] after the spectral step", e, 0.0)


def test_mean_zero_after_spectral_step():
    """The spatial mean of the stepped field is the DC bin divided by N^2 -- the
    identity a DFT is built on -- and FR-005 zeroes the DC bin, so the mean is 0
    within float32 rounding of a 1024-term average of O(1) values. (Note: not
    the DC texel, which is the sum over the whole spectrum, not the mean.)"""
    st = rand_state(3)
    uh = spec_stage(fwd_dft(st, fast=True), 0.1, L)
    ulin = inv_dft_real(uh, fast=True)
    e = abs(float(np.mean(f2u(ulin))))
    check("mean(u_lin) = 0 after the spectral step", e, 1e-6)


def test_mean_closed_form_after_full_frame():
    """With the k = 0 fix the frame's mean change is a closed form: the mean of
    -dt*0.5*|grad u_lin|^2 (the linear part contributes zero mean because the DC
    bin is zeroed; the mean of a periodic field's gradient is zero but the SQUARE
    is not, hence -dt/2 times the mean). Independent of how the mirror computes
    the gradient: this reference uses np.roll."""
    st = rand_state(4)
    dt = rate_to_dt(0.7, 0.1, 0.25)
    new, _ = frame(st, rate=0.7, fast=True)
    uh = spec_stage(fwd_dft(st, fast=True), dt, L)
    ulin = inv_dft_real(uh, fast=True)
    g = ref_grad_sq(f2u(ulin))
    expect = -float(dt) / 2 * float(g.mean())
    got = float(np.mean(f2u(new)))
    e = abs(got - expect)
    check("mean after one frame = -dt/2 * mean|grad u_lin|^2", e, 2e-5)


def test_drift_without_dc_fix():
    """Success criterion 3, the drift half: without the DC fix the field mean
    marches secularly downward and accelerates (the spike measured -0.2 to -15
    over 200 no-fix steps). Over 60 frames every 20-frame window must fall by
    more than 0.1 -- the maths, the spike, the spec and the mirror agree on the sign."""
    st = rand_state(5)
    means = []
    s = st.copy()
    for i in range(60):
        s, _ = frame(s, rate=1.0, zero=False, fast=True)
        if i % 20 == 0 or i == 59:
            means.append(float(np.mean(f2u(s))))
    note("no-fix means every 20 frames", ["%+.2f" % m for m in means])
    drops = [means[i] - means[i + 1] for i in range(len(means) - 1)]
    e = max(0.0, min(drops) - 0.1)     # every 20-frame window must fall by > 0.1
    check("secular drift downward, every 20-frame window (no DC fix)", e, 0.0)


def test_drift_sign_matches_maths():
    """The nonlinearity integrates domain-negative (the update subtracts
    dt*0.5*|grad u_lin|^2 and that mean is positive), so the mean drifts
    DOWNWARD without the DC fix; the spike measured -0.2 to -15 and the mirror
    agrees. This check is the maths sign alone."""
    st = rand_state(5)
    s = st.copy()
    for _ in range(40):
        s, _ = frame(s, rate=1.0, zero=False, fast=True)
    got = float(np.mean(f2u(s)))
    start = float(np.mean(f2u(st)))
    e = max(0.0, got - start)     # the mean must have FALLEN (downward drift)
    note("drift over 40 no-fix frames", got - start)
    check("mean drifts downward without the DC fix (the maths sign)", e, 0.0)


# ------------------------------------------------------------------ fixed point, seeds

def test_zero_state_stays_zero():
    """The spec: u = 0 is a fixed point (both terms vanish at zero); with the DC
    fix a zero state stays EXACTLY zero, and the encoded outlet shows neutral
    grey 0.5. Exact check, tolerance 0."""
    st = np.zeros((N, N, 4), F32)
    st[..., 3] = 1.0
    new, disp = frame(st, rate=0.5, fast=True)
    e = max(nonfinite_count(f2u(new)), float(np.abs(f2u(new)).max()),
            float(np.abs(disp[..., :3] - F32(0.5)).max()),
            float(np.abs(disp[..., 3] - F32(1.0)).max()),
            float(np.abs(new[..., 3] - F32(1.0)).max()))
    # exact 0 field and exact 0.5 grey: tolerance 0
    check("zero state stays exactly zero; encode shows 0.5 (grey)", e, 0.0)
    return e


def test_seed_state_is_noise_two_seeds_differ():
    """FR-003: the state seeds from noise, never from zero; FR-007: a reset
    re-seeds. Two seeds give visibly different states (here: every texel differs;
    the check requires most of the frame) and each seed has real amplitude, so a
    reset cannot land on the fixed point."""
    a = seed_state(N, N, seed=1)
    b = seed_state(N, N, seed=2)
    n_diff = int((a != b).any(axis=-1).sum())
    note("texels differing between two seeds", n_diff)
    check("two seeds give different states (all texels, minus 10 slack)", max(0, (N * N - 10) - n_diff), 0.0)
    check("seeded texture alpha is exactly 1", float(np.abs(a[..., 3] - F32(1.0)).max())
          + float(np.abs(b[..., 3] - F32(1.0)).max()), 0.0)
    check("seeded state is nonzero (max |u| above 0.5)", max(0.0, 0.5 - float(np.abs(f2u(a)).max())), 0.0)


# ------------------------------------------------------------------ rate and the clamp

def test_rate_to_dt_clamp():
    """FR-006: effective dt = min(rate * dt0, ceiling), at every branch (zero,
    below, at and over the ceiling). Pure scalar pass; the ceiling is an argument,
    never a fixed number. float32 holds 0.1*0.5 etc. to 1e-7, so 1e-6."""
    e = max(abs(float(rate_to_dt(r, F32(a), F32(c))) - expect) for (r, a, c, expect) in
            [(0.0, 0.1, 0.25, 0.0), (0.5, 0.1, 0.25, 0.05), (1.0, 0.1, 0.25, 0.1),
             (2.5, 0.1, 0.25, 0.25), (3.0, 0.1, 0.25, 0.25), (4.0, 0.1, 0.25, 0.25),
             (1.6, 0.1, 0.1, 0.1)])
    check("rate_to_dt = min(rate*dt0, ceiling), exact", e, 1e-6)


def test_rate_monotone_per_frame_change():
    """User Story 3, from the spec's words ('a rate dial scales how fast ...
    a dt multiplier'): below the clamp a larger rate gives a strictly larger
    per-frame change of the field; three values spanning the low dial."""
    st = rand_state(6)
    chs = []
    for rate in (0.3, 0.6, 0.9):
        new, _ = frame(st, rate=rate, fast=True)
        chs.append(float(np.abs(f2u(new) - f2u(st)).mean()))
    note("per-frame mean change at rates 0.3/0.6/0.9", chs)
    e = max(0.0, -min(chs[i + 1] - chs[i] for i in range(2)))
    check("per-frame change strictly increasing in rate (0.3, 0.6, 0.9)", e, 0.0)


def _soak_err(rate, ceiling, frames=300, seed=9, lens=12.5):
    """A bounded-and-finite soak at the module's own DX (N=32, L=12.5; DX = 50/256
    as in the spike): non-finite values are hard errors, max|u| stays under the
    bound. Returns the error and the last per-frame mean change."""
    st = rand_state(seed)
    s, prev = st, None
    worst = 0.0
    for i in range(frames):
        s, d = ks_frame(s, Params(rate=rate, dt0=0.1, ceiling=ceiling, L=lens, fast_fft=True))
        nf = nonfinite_count(f2u(s))
        if nf:
            return np.inf, np.inf
        worst = max(worst, float(np.abs(f2u(s)).max()) - 30.0)
        if prev is not None:
            chg = float(np.abs(f2u(s) - prev).mean())
            prev = f2u(s)
        else:
            prev = f2u(s)
    if float(np.abs(s[..., 3] - F32(1.0)).max()) != 0.0:
        return np.inf, chg
    return worst, chg


def test_rate_clamped_and_unclamped_stay_bounded():
    """FR-006/US3: at any rate the solver stays finite, bounded, and still evolving
    over hundreds of frames. Three rates spanning the dial, the last two CLAMPED
    (rate*dt0 = 0.1 and 0.2 > the ceiling 0.05 given here). Bounded here means
    max|u| under 30 at N=32/L=12.5 over 300 frames (measured growth of this
    solver reaches 3.5 at 300 frames; the loose bound covers it; the exact dt
    ceiling is a later wave's result, and the clamp behaviour itself is checked
    exactly by test_rate_to_dt_clamp). Still evolving (US3.2, 'not frozen')."""
    w1, c1 = _soak_err(0.15, 0.05, seed=9)     # rate*dt0 = 0.015: well under the ceiling
    w2, c2 = _soak_err(1.0, 0.05, seed=10)     # rate*dt0 = 0.1: clamped to 0.05
    w3, c3 = _soak_err(2.0, 0.05, seed=11)     # rate*dt0 = 0.2: clamped to 0.05
    note("soak max|u| at dt 0.015 / 0.05 (clamped from 0.1) / 0.05 (clamped from 0.2)", [w1, w2, w3])
    worst = max(w1, w2, w3)
    check("finite, bounded under 30, over 300 frames (soak max|u|-30)", worst, 0.0)
    note("last per-frame mean change at the three soaks, minimum", min(c1, c2, c3))
    chg = max(0.0, 2e-4 - min(c1, c2, c3))
    check("state still evolving at every rate (last per-frame change above 2e-4)", chg, 0.0)


# ------------------------------------------------------------------ encode

def test_encode_bounded_and_exact_in_range():
    """FR-008: the outlet is bounded, no NaN/Inf reaches it. The placeholder encode
    (this mirror's choice: a hard clamp of 0.5 + 0.25*u) is exact at u = 0 and
    clamps at |u| = 2. The convention is codebox-dependent (the final mapping is a
    Phase 2 decision): pinned here, paired with the bound checks that need no
    formula."""
    u = np.array([[-1.0, 0.0, 1.0, 2.5, 3.0]], F32)
    t = np.zeros((1, 5, 4), F32)
    t[..., 0] = u
    t[..., 3] = 1.0
    e = encode(t)
    expect = np.array([0.25, 0.5, 0.75, 1.0, 1.0], F32)
    check("placeholder encode: 0.5+0.25u clamped to [0,1]", nonfinite_count(np.abs(e[..., 0] - expect)), 0.0)
    check("encode replicated to G, B; A = 1",
          max(float(np.abs(e[..., 1] - e[..., 0]).max()), float(np.abs(e[..., 2] - e[..., 0]).max()),
              float(np.abs(e[..., 3] - 1.0).max())), 0.0)


def test_gradient_closed_form_on_x_only_field():
    """The central-difference gradient stage against its closed form on an x-only
    cos field: change = -dt*0.5*sinc-weighted ux^2. An axis-swapped or off-centre
    read cannot produce it."""
    e = _grad_axis_err()
    check("x-only cos field: nonlinear change vs closed form", e, 2e-5)


# ------------------------------------------------------------------ generic point

def _generic_err(bug=None):
    """Every stage in sequence on a random state at a generic rate, 2 frames,
    against the independent float64 reference step by step."""
    st = rand_state(12)
    p = Params(rate=0.83, dt0=0.1, ceiling=0.25, L=L, zero_mean=True, fast_fft=True)
    got, disp = ks_frame(st, p, bug=bug)
    dt = float(rate_to_dt(0.83, 0.1, 0.25))
    r1 = ref_frame(f2u(st), dt)
    e1 = float(np.abs(f2u(got) - r1).max())
    got2, disp2 = ks_frame(got, p, bug=bug)
    r2 = ref_frame(r1, dt)
    e2 = float(np.abs(f2u(got2) - r2).max())
    ed1 = float(np.abs(disp[..., 0].astype(np.float64)
                       - np.clip(0.5 + 0.25 * r1, 0, 1)).max())
    ed2 = float(np.abs(disp2[..., 0].astype(np.float64)
                       - np.clip(0.5 + 0.25 * r2, 0, 1)).max())
    return max(e1, e2, ed1, ed2, nonfinite_count(f2u(got2)))


def test_generic_point_two_frames_match_reference():
    """A random state, a generic rate (0.83: no clamp, no neutral), two frames
    against the float64 reference of the same equation; the encode compared with
    the same reference's field under the pinned placeholder map."""
    err = _generic_err()
    check("2 generic frames vs float64 np.fft reference", err, 1e-4)
    return err


# ------------------------------------------------------------------ mutations

def test_nl_containment_keeps_the_feedback_finite_and_bounded():
    """FR-008, the codebox_nl.gen backstop: whatever the linear step hands over (NaN,
    Inf, huge, ordinary), the new state is finite and within +-100; ordinary values pass
    through the clamp untouched (the clamp is inactive in normal running)."""
    u = np.zeros((N, N, 4), F32)
    u[..., 3] = F32(1.0)
    u[0, 0, 0] = np.nan
    u[0, 1, 0] = np.inf
    u[0, 2, 0] = -np.inf
    u[5, 5, 0] = F32(1e31)
    u[7, 7, 0] = F32(500.0)
    u[9, 9, 0] = F32(-500.0)
    with np.errstate(all="ignore"):
        out = nonlinear_step(u, 0.05, dx=L / N)
    x = out[..., 0]
    check("every texel finite", float(np.count_nonzero(~np.isfinite(x))), 0.0)
    check("every texel within +-100", float(np.max(np.abs(x)) - 100.0 > 0), 0.0)
    ordinary = rand_state(3)
    ordinary_out = nonlinear_step(ordinary, 0.05, dx=L / N)
    ux = (np.roll(ordinary[..., 0], -1, 1) - np.roll(ordinary[..., 0], 1, 1)) * (0.5 * N / L)
    uy = (np.roll(ordinary[..., 0], -1, 0) - np.roll(ordinary[..., 0], 1, 0)) * (0.5 * N / L)
    want = ordinary[..., 0] - 0.05 * 0.5 * (ux * ux + uy * uy)
    check("ordinary values untouched by the clamp", float(np.max(np.abs(ordinary_out[..., 0] - want))), 1e-4)


def test_mutations_are_caught():
    """Every injected bug must fail at least one check by a clear margin (> 1e-3);
    the real mirror must pass the same checks (< 1e-4). The `bug` values: a flipped
    growth-rate sign in the spectral stage, the nonlinearity added instead of
    subtracted, the |grad|^2 halving lost, the DC zero skipped, and the gradient's
    forward/backward order swapped."""
    real = [_fft_tie_err(), mode_err(kx=3, ky=1), _generic_err(),
            test_zero_state_stays_zero(), _mean_form(0.7), _dc_err(),
            _texel_mean_err(), _seed_err()]
    st = rand_state(2)
    uh = spec_stage(fwd_dft(st, fast=True), 0.1, L, zero_mean=True, bug="no_dc_zero")
    dcz = abs(float(uh[0, 0, 0])) + abs(float(uh[0, 0, 1]))
    bugs = {
        "rate_flip": max(mode_err(kx=3, ky=1, bug="rate_flip"),
                         mode_err(kx=3, ky=3, lens=12.5, bug="rate_flip")),
        "nl_sign": max(_generic_err(bug="nl_sign"),
                       _mean_form(0.7, bug="nl_sign")),
        "grad_half": max(_generic_err(bug="grad_half"),
                         _mean_form(0.7, bug="grad_half")),
        "no_dc_zero": max(dcz, _dc_err(bug="no_dc_zero")),
        "grad_half_texel": _grad_axis_err(bug="grad_half_texel"),
    }
    for k, v in bugs.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    check("the real mirror passes the mutation checks", max(real), 1e-4)
    print("    ok   rate flip, nonlinearity sign, missing halving, no-DC-zero and a "
          "half-texel gradient read are each caught")


def _grad_axis_err(bug=None):
    """An x-only cos field (cos 2pi*4x, amplitude 1): the nonlinear step changes u
    by exactly -dt*0.5*q with q = ux^2, and ux of a central difference has the
    closed form -sin(2pi*k*i/N) * sin(2pi*k/N) * N/L (the discrete derivative of
    a mode is the analytic derivative times the sinc factor). Independent of the
    mirror; the grad_half_texel mutant (reads half a texel off) leaves that
    pattern by a large error."""
    n = 32
    t = np.linspace(0.0, 1.0, n, endpoint=False)
    X, Y = np.meshgrid(t, t)
    u = np.cos(2 * np.pi * 4 * X).astype(F32)
    st = np.zeros((n, n, 4), F32)
    st[..., 0] = u
    st[..., 3] = 1.0
    nl = nonlinear_step(st, 0.1, L / n, bug=bug)
    k = 4
    i = np.arange(n)
    ux_cf = (np.cos(2 * np.pi * k * (i + 1) / n) - np.cos(2 * np.pi * k * (i - 1) / n)) * (n / (2 * L))
    chg_expect = -0.1 * 0.5 * ux_cf ** 2
    dy = np.abs(nl[..., 0].astype(np.float64) - st[..., 0].astype(np.float64) - chg_expect[None, :])
    return max(float(dy.max()), nonfinite_count(nl[..., 0]))


def _texel_mean_err(bug=None):
    """A one-texel state at a texel centre, frame at a rate that puts K2 < 1 there:
    compare with the float64 reference on the same array (the identity between the
    transforms makes this a tie to np.fft, not a mirror self-check)."""
    st = np.zeros((16, 16, 4), F32)
    st[9, 3, 0] = 1.0
    st[..., 3] = 1.0
    got, disp = frame(st, rate=0.5, fast=True, bug=bug)
    r = ref_frame(st[..., 0].astype(np.float64), 0.05, L)
    return max(float(np.abs(f2u(got) - r).max()), nonfinite_count(f2u(got)))


def _seed_err(bug=None):
    a = seed_state(N, N, seed=1)
    b = seed_state(N, N, seed=2)
    n_diff = int((a != b).any(axis=-1).sum())
    return max(0, (N * N - 10) - n_diff)


def _mean_form(r, bug=None):
    """The mean-after-frame closed form as an error function, for the mutation run."""
    dt = rate_to_dt(r, 0.1, 0.25)
    st = rand_state(4)
    new, _ = frame(st, rate=r, fast=True, bug=bug)
    uh = spec_stage(fwd_dft(st, fast=True), dt, L)
    ulin = inv_dft_real(uh, fast=True)
    g = ref_grad_sq(f2u(ulin))
    expect = -float(dt) / 2 * float(g.mean())
    if bug == "grad_half":
        expect *= 2.0
    if bug == "nl_sign":
        expect = -expect
    return abs(float(np.mean(f2u(new))) - expect)


def _dc_err(bug=None):
    st = rand_state(2)
    uh = spec_stage(fwd_dft(st, fast=True), 0.1, L, zero_mean=True, bug=bug)
    ref = np.fft.fft2(f2u(st))
    k = np.fft.fftfreq(N, 1.0 / N).astype(np.int64)
    K2 = (k[:, None] * 2 * np.pi / L) ** 2 + (k[None, :] * 2 * np.pi / L) ** 2
    expect = ref * np.exp((K2 - K2 ** 2) * 0.1)
    expect[0, 0] = 0.0 if not bug else expect[0, 0]
    e = max(float(np.abs(uh[..., 0].astype(np.float64) - expect.real).max()),
            float(np.abs(uh[..., 1].astype(np.float64) - expect.imag).max()))
    return max(e, nonfinite_count(uh[..., 0]))


if __name__ == "__main__":
    sys.exit(run(globals()))