"""test_wave_field.py -- tier-1 tests for the not-yet-built f_wave_field module (T001 + T002).

Ground truth is independent of the mirror:

  - `expm2` is a float64 scaling-and-squaring Taylor matrix exponential of the 2x2 system
    [[0, 1], [-omega^2, -2 beta]]. It shares no arithmetic with the mirror's cos / sin /
    cosh / sinh branches, so it checks all three damping regimes and the Taylor switch
    near critical damping (spec SC-001).
  - np.fft in float64 ties the pass_dft chain at N = 32; the single-mode and long runs then
    use fast_fft=True.
  - Closed forms from the spec: energy conservation at zero damping (SC-002), omega scaling
    with dispersion and the kref calibration (FR-004, SC-003), superposition (SC-004),
    periodic translation invariance and wrap (SC-005), DC zeroing (FR-005).

Tolerance notes: float32-vs-float64 single steps get 2e-6 to 1e-5 (a few float32 ulps of the
amplitude); multi-frame linear checks 1e-5; energy over 1,000 frames 1e-4 (the SC-002 target).
The ring-radius check (a physical pulse, not a closed form) gets a generous 0.04 frame widths.

Recorded, not asserted (printed with note()): the resonator's per-pixel independence is exact
except for the DC bin (zeroing removes mean/N^2 per frame); the sponge scales u and v by a
pointwise g <= 1, so the plain L2 norms never grow, but the spectral energy (which weights
|grad u|^2) is not guaranteed monotone: the largest frame-to-frame energy increase is printed
for T004.

Run:  tests/run.sh tests/modules/wave_field/test_wave_field.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from wave_field_mirror import (F32, TWOPI, encode_luma, encode_vec, energy,  # noqa: E402
                               gradient, new_state, real_stage, sponge_rate, spec_stage,
                               step_coeffs, struck_state, wave_frame, _fft2, _gauss, signed_k)
import wave_field_mirror as wfm  # noqa: E402

N = 32


def Params(**kw):
    """Pure-physics tests run with viscosity off (nu = 0) so the closed forms hold exactly; the
    shipped NU has its own tests below. Everything else is the mirror's Params."""
    kw.setdefault("nu", 0.0)
    return wfm.Params(**kw)


# ------------------------------------------------------------------ references

def expm2(om2, beta, dt):
    """float64 matrix exponential of M = [[0, 1], [-om2, -2 beta]] * dt by Taylor with
    scaling and squaring. Returns (a, b, c, d) with [u', v'] = [[a, b], [c, d]] [u, v]."""
    om2, beta = np.asarray(om2, np.float64), np.asarray(beta, np.float64)
    m = np.zeros(om2.shape + (2, 2))
    m[..., 0, 1] = 1.0
    m[..., 1, 0] = -om2
    m[..., 1, 1] = -2.0 * beta
    m = m * dt
    norm = float(np.abs(m).sum(-1).max())
    s = max(0, int(np.ceil(np.log2(max(norm, 1e-30)))) + 1)
    m = m / (2.0 ** s)
    e = np.broadcast_to(np.eye(2), m.shape).copy()
    term = e.copy()
    for n in range(1, 24):
        term = term @ m / n
        e = e + term
    for _ in range(s):
        e = e @ e
    return e[..., 0, 0], e[..., 0, 1], e[..., 1, 0], e[..., 1, 1]


def mode_state(n, m_idx, a, b):
    """u = a cos(2 pi m x), v = b cos(2 pi m x) on the n x n grid (x along columns)."""
    x = (np.arange(n, dtype=np.float64) + 0.5) / n
    prof = np.cos(2 * np.pi * m_idx * x)[None, :] * np.ones((n, 1))
    t = new_state(n, n)
    t[..., 0] = (a * prof).astype(F32)
    t[..., 2] = (b * prof).astype(F32)
    return t, prof


def omega_of(k, p):
    return p.speed * p.kref * (k / p.kref) ** p.dispersion


def single_mode_error(p, m_idx=4, a=1.0, b=0.3, frames=1):
    """Run `frames` frames of a single cosine mode through the full mirror frame (no force,
    no exciter, edge 0) and return the max error against the float64 expm of its own
    (omega^2, beta). Returns (error, omega, beta)."""
    k = 2 * np.pi * m_idx
    om = float(omega_of(k, p))
    om2, beta = om ** 2 + p.ring ** 2, p.damping + p.nu * k * k
    aa, bb, cc, dd = expm2(np.float64(om2), np.float64(beta), p.dt)
    st, prof = mode_state(N, m_idx, a, b)
    ua, va = a, b
    for _ in range(frames):
        st, _, _, _ = wave_frame(st, p.with_(fast_fft=True))
        ua, va = aa * ua + bb * va, cc * ua + dd * va
    err = max(float(np.abs(st[..., 0] - ua * prof).max()), float(np.abs(st[..., 2] - va * prof).max()))
    return err, om, beta


# ------------------------------------------------------------------ the transform tie

def test_pass_chain_matches_npfft_for_one_frame():
    """The pass_dft chain (what the GPU computes) and np.fft agree on a full frame at N = 32,
    so the long runs below may use fast_fft=True."""
    rng = np.random.default_rng(3)
    st = new_state(N, N)
    st[..., 0] = rng.uniform(-1, 1, (N, N))
    st[..., 2] = rng.uniform(-1, 1, (N, N))
    p = Params(speed=0.25, damping=0.4, dt=0.02)
    a, _, _, _ = wave_frame(st, p.with_(fast_fft=False))
    b, _, _, _ = wave_frame(st, p.with_(fast_fft=True))
    err = max(float(np.abs(a[..., 0] - b[..., 0]).max()), float(np.abs(a[..., 2] - b[..., 2]).max()))
    check("one frame: pass chain vs np.fft", err, 1e-5)


# ------------------------------------------------------------------ SC-001: the three regimes

def test_underdamped_single_mode_matches_matrix_exponential():
    p = Params(speed=0.25, damping=0.5, dt=0.1)
    err, om, beta = single_mode_error(p, frames=1)
    assert beta < om, "test point must be underdamped"
    check(f"underdamped (omega {om:.2f}, beta {beta:.2f}), 1 frame", err, 2e-6)
    err5, _, _ = single_mode_error(p, frames=5)
    check("underdamped, 5 frames", err5, 1e-5)


def test_overdamped_single_mode_matches_matrix_exponential():
    p = Params(speed=0.25, damping=20.0, dt=0.1)
    err, om, beta = single_mode_error(p, frames=1)
    assert beta > om, "test point must be overdamped"
    check(f"overdamped (omega {om:.2f}, beta {beta:.2f}), 1 frame", err, 2e-6)
    err5, _, _ = single_mode_error(p, frames=5)
    check("overdamped, 5 frames", err5, 1e-5)


def test_critically_damped_single_mode_matches_matrix_exponential():
    k = 2 * np.pi * 4
    om = 0.25 * k
    p = Params(speed=0.25, damping=om, dt=0.1)         # beta == omega: wd^2 rounds to ~0
    err, _, beta = single_mode_error(p, frames=1)
    check("critical (beta = omega), 1 frame", err, 2e-6)
    assert abs(beta - om) < 1e-5
    err5, _, _ = single_mode_error(p, frames=5)
    check("critical, 5 frames", err5, 1e-5)


def test_coefficients_are_continuous_through_the_taylor_switch():
    """Sweep wd^2 dt^2 from -4e-4 to +4e-4 (both sides of the 1e-4 series threshold) at fixed
    beta; Cc and Cs must match the matrix exponential everywhere, with no step at the switch."""
    beta = 6.0
    dt = 0.1
    delta = np.linspace(-4e-2, 4e-2, 401)               # wd^2 = delta, x = delta dt^2 in +-4e-4
    omega = np.sqrt(beta ** 2 + delta)
    p = Params(speed=1.0, damping=beta, dispersion=1.0, dt=dt)
    kmag = (omega).astype(F32)[None, :]
    cc, cs, om2, bt = step_coeffs(kmag, p)
    a, b, c, d = expm2(om2.astype(np.float64), bt.astype(np.float64), dt)
    cs_ref = b
    cc_ref = a - bt.astype(np.float64) * b
    check("Cs vs expm across the switch", float(np.abs(cs - cs_ref).max()), 2e-6)
    check("Cc vs expm across the switch", float(np.abs(cc - cc_ref).max()), 2e-6)
    check("Cs has no jump at the switch", float(np.abs(np.diff(cs[0])).max()), 1e-6)


def test_extreme_overdamping_is_finite_and_exact():
    """beta dt = 1000 would overflow a naive cosh in float32; the folded exp form must stay finite.
    With omega = 0 the closed form is u' = u + v / (2 beta), v' = 0 (the fast mode has died)."""
    beta, dt = 1.0e4, 0.1
    p = Params(speed=0.0, ring=0.0, damping=beta, dt=dt)
    kmag = np.array([[10.0, 50.0, 100.0]], F32)
    cc, cs, om2, bt = step_coeffs(kmag, p)
    assert np.isfinite(cc).all() and np.isfinite(cs).all()
    u, v = 1.0, 0.5
    u_new = float(cc[0, 0]) * u + float(cs[0, 0]) * (v + beta * u)
    check("u' = u + v/(2 beta)", abs(u_new - (u + v / (2 * beta))), 1e-6)
    v_new = float(cc[0, 0]) * v - float(cs[0, 0]) * (0.0 * u + beta * v)
    check("v' = 0 for a dead fast mode", abs(v_new), 1e-6)


# ------------------------------------------------------------------ SC-002: energy

def test_energy_is_conserved_at_zero_damping_over_1000_frames():
    rng = np.random.default_rng(5)
    st = new_state(N, N)
    u = rng.uniform(-1, 1, (N, N))
    v = rng.uniform(-1, 1, (N, N))
    st[..., 0] = (u - u.mean()).astype(F32)
    st[..., 2] = (v - v.mean()).astype(F32)
    p = Params(speed=0.25, damping=0.0, fast_fft=True)
    e0 = energy(st, p)
    emax = e0
    for _ in range(1000):
        st, _, _, _ = wave_frame(st, p)
        emax = max(emax, energy(st, p))
    e1 = energy(st, p)
    check("relative energy drift after 1,000 frames (SC-002 target 1e-4)", abs(e1 - e0) / e0, 1e-4)
    note("worst excursion over the run", f"{(emax - e0) / e0:.2e}")


def test_damping_removes_energy_and_never_adds_it():
    rng = np.random.default_rng(6)
    st = new_state(N, N)
    st[..., 0] = rng.uniform(-1, 1, (N, N)) - 0.0
    st[..., 2] = rng.uniform(-1, 1, (N, N))
    for ch in (0, 2):
        st[..., ch] -= st[..., ch].mean()
    p = Params(speed=0.25, damping=0.8, fast_fft=True)
    e = [energy(st, p)]
    for _ in range(60):
        st, _, _, _ = wave_frame(st, p)
        e.append(energy(st, p))
    worst_rise = max(b / a - 1.0 for a, b in zip(e[:-1], e[1:]))
    check("largest frame-to-frame energy rise with damping", max(worst_rise, 0.0), 1e-6)
    check("energy decays (final below half of initial)", float(e[-1] > 0.5 * e[0]), 0.0)


# ------------------------------------------------------------------ FR-004 / SC-003: dispersion

def _omega_from_motion(p, m_idx, frames):
    """Measure omega from a free-ringing single mode started at rest: u(t) = A cos(omega t)."""
    st, prof = mode_state(N, m_idx, 1.0, 0.0)
    for _ in range(frames):
        st, _, _, _ = wave_frame(st, p.with_(fast_fft=True))
    ratio = float(st[N // 2, 0, 0] / prof[N // 2, 0])
    return np.arccos(np.clip(ratio, -1, 1)) / (frames * p.dt)


def test_omega_follows_the_dispersion_relation_and_kref_calibration():
    for disp in (0.5, 1.0, 2.0):
        p = Params(speed=0.02, dispersion=disp, dt=0.01)
        for m_idx in (4, 8):
            k = 2 * np.pi * m_idx
            want = float(omega_of(k, p))
            frames = max(1, int(round(0.5 / (want * p.dt))))     # omega t about 0.5 rad: acos stays accurate
            got = _omega_from_motion(p, m_idx, frames)
            check(f"dispersion {disp:g}, mode {m_idx}: omega (relative)", abs(got - want) / want, 1e-3)
    # calibration (FR-004): at k = kref (mode 8) omega = speed * kref for EVERY dispersion
    for disp in (0.5, 1.0, 2.0):
        p = Params(speed=0.02, dispersion=disp, dt=0.01)
        check(f"omega(kref) = speed * kref at dispersion {disp:g}",
              abs(float(omega_of(p.kref, p)) - p.speed * p.kref), 1e-9)
    # plate waves: dispersion 2 gives omega proportional to k^2, so mode 8 is 4x mode 4
    p2 = Params(speed=0.02, dispersion=2.0)
    check("dispersion 2: omega(8) / omega(4) = 4",
          abs(omega_of(2 * np.pi * 8, p2) / omega_of(2 * np.pi * 4, p2) - 4.0), 1e-9)


def test_struck_pulse_ring_grows_at_the_phase_velocity():
    """SC-003 / User Story 2: at dispersion 1 the struck ring's radius grows at `speed`."""
    n = 96
    p = Params(speed=0.25, dispersion=1.0, damping=0.0, dt=1.0 / 60.0, fast_fft=True)
    st = struck_state(n, n, p)
    frames = 60                                         # 1 time unit: radius should be about 0.25
    for _ in range(frames):
        st, _, _, _ = wave_frame(st, p)
    nx = (np.arange(n) + 0.5) / n
    xx, yy = np.meshgrid(nx, nx)
    r = np.sqrt((xx - 0.5) ** 2 + (yy - 0.5) ** 2)
    bins = np.linspace(0.0, 0.5, 51)
    prof = np.array([np.abs(st[..., 0][(r >= lo) & (r < hi)]).mean() for lo, hi in zip(bins[:-1], bins[1:])])
    r_peak = 0.5 * (bins[np.argmax(prof)] + bins[np.argmax(prof) + 1])
    note("ring radius (peak of mean |u| by radius)", f"{r_peak:.3f} (expected 0.25)")
    check("ring radius vs speed * t", abs(r_peak - 0.25), 0.04)


# ------------------------------------------------------------------ SC-004: superposition

def test_forced_response_is_linear():
    rng = np.random.default_rng(8)
    p = Params(speed=0.25, damping=0.3, force=1.0, fast_fft=True)

    def run_with(tex, k=1.0, n=30):
        st = new_state(N, N)
        for _ in range(n):
            st, _, _, _ = wave_frame(st, p.with_(force=k), force_tex=tex)
        return st
    f1 = new_state(N, N); f1[..., 0] = 0.5 + 0.2 * rng.uniform(-1, 1, (N, N))
    f2 = new_state(N, N); f2[..., 0] = 0.5 + 0.2 * rng.uniform(-1, 1, (N, N))
    mix = new_state(N, N); mix[..., 0] = 0.5 + 2.0 * (f1[..., 0] - 0.5) + 3.0 * (f2[..., 0] - 0.5)
    a, b, ab = run_with(f1), run_with(f2), run_with(mix)
    err = max(float(np.abs(ab[..., ch] - (2.0 * a[..., ch] + 3.0 * b[..., ch])).max()) for ch in (0, 2))
    scale = float(np.abs(ab[..., 0]).max())
    check("field(2 F1 + 3 F2) = 2 field(F1) + 3 field(F2) (relative)", err / scale, 1e-5)
    twice = run_with(f1, k=2.0)
    check("twice the force, twice the field (relative)",
          float(np.abs(twice[..., 0] - 2.0 * a[..., 0]).max()) / scale, 1e-5)


def test_unconnected_force_is_neutral():
    """User Story 3 AS1: a 0.5 texture (the unconnected inlet) applies no force."""
    p = Params(speed=0.25, force=1.0, fast_fft=True)
    flat = new_state(N, N); flat[..., 0] = 0.5
    st, _, _, _ = wave_frame(new_state(N, N), p, force_tex=flat)
    check("0.5 force texture leaves a zero field zero", float(np.abs(st[..., :3]).max()), 0.0)


# ------------------------------------------------------------------ FR-005: DC bin

def test_mean_force_does_not_accelerate_a_mean_offset():
    """A uniform force has a non-zero mean. With the DC bin zeroed every step the mean of u
    stays 0 and v's mean stays bounded at one force step, instead of growing without bound."""
    p = Params(speed=0.25, damping=0.0, force=1.0, fast_fft=True)
    tex = new_state(N, N); tex[..., 0] = 0.7
    st = new_state(N, N)
    for _ in range(300):
        st, _, _, _ = wave_frame(st, p, force_tex=tex)
    check("mean(u) after 300 frames of uniform force", abs(float(st[..., 0].mean())), 1e-6)
    check("max |v| stays at one force step (F dt)", float(np.abs(st[..., 2]).max()) - 0.4 * p.dt, 1e-6)


# ------------------------------------------------------------------ SC-005: edges

def test_periodic_wrap_is_translation_invariant_across_the_seam():
    n = 64
    p = Params(speed=0.25, damping=0.0, fast_fft=True)
    a = struck_state(n, n, p.with_(x=0.875))
    b = struck_state(n, n, p.with_(x=0.625))
    for _ in range(30):                                 # the front reaches x > 1 and wraps to the left
        a, _, _, _ = wave_frame(a, p.with_(x=0.875))
        b, _, _, _ = wave_frame(b, p.with_(x=0.625))
    shifted = np.roll(b[..., 0], 16, axis=1)            # 16 texels = 0.25 of the frame
    check("pulse across the seam = rolled copy (relative)",
          float(np.abs(a[..., 0] - shifted).max()) / float(np.abs(a[..., 0]).max()), 1e-5)


def test_pulse_leaving_one_border_reappears_at_the_opposite_one():
    n = 64
    p = Params(speed=0.25, damping=0.0, fast_fft=True, x=0.95)
    st = struck_state(n, n, p)
    lo, hi = int(0.12 * n), int(0.20 * n)               # a strip beyond the pulse's own tail across the seam
    left_before = float(np.abs(st[:, lo:hi, 0]).max())
    for _ in range(48):                                 # radius 0.2: the front reaches x = 1.15 -> 0.15
        st, _, _, _ = wave_frame(st, p)
    left_after = float(np.abs(st[:, lo:hi, 0]).max())
    note("strip x in [0.12, 0.20): |u| before / after", f"{left_before:.2e} / {left_after:.2e}")
    check("strip is empty before the pulse crosses", left_before, 1e-6)
    check("the pulse arrives in the strip after crossing the seam", float(left_after < 1e-2), 0.0)


def test_sponge_never_adds_to_u_or_v_norms_and_is_zero_inside():
    n = 64
    rate = sponge_rate(n, n, 1.0)
    check("sponge rate is never negative", float(rate.min() < 0), 0.0)
    check("sponge rate is zero in the interior", float(np.abs(rate[n // 4: 3 * n // 4, n // 4: 3 * n // 4]).max()), 0.0)
    check("sponge rate at the corner reaches edge * peak", abs(float(rate[0, 0]) - float(wfm.SPONGE_RATE)) / float(wfm.SPONGE_RATE), 0.15)
    check("edge = 0 gives no sponge at all", float(np.abs(sponge_rate(n, n, 0.0)).max()), 0.0)
    rng = np.random.default_rng(9)
    st = new_state(n, n)
    st[..., 0] = rng.uniform(-1, 1, (n, n))
    st[..., 2] = rng.uniform(-1, 1, (n, n))
    out = real_stage(st, Params(edge=1.0))
    check("sum u^2 does not grow", float((out[..., 0] ** 2).sum() > (st[..., 0] ** 2).sum()), 0.0)
    check("sum v^2 does not grow", float((out[..., 2] ** 2).sum() > (st[..., 2] ** 2).sum()), 0.0)


def test_sponge_removes_energy_after_the_pulse_crosses_the_border():
    n = 64
    base = Params(speed=0.25, damping=0.0, fast_fft=True, x=0.9)
    es = {}
    worst = {}
    for edge in (0.0, 1.0):
        p = base.with_(edge=edge)
        st = struck_state(n, n, p)
        e_prev = energy(st, p)
        worst[edge] = 0.0
        for _ in range(60):
            st, _, _, _ = wave_frame(st, p)
            e = energy(st, p)
            worst[edge] = max(worst[edge], e / e_prev - 1.0)
            e_prev = e
        es[edge] = e_prev
    note("worst frame-to-frame energy rise, edge 1", f"{worst[1.0]:.2e} (spectral energy weights |grad u|^2: not guaranteed monotone; T004)")
    check("edge 0: energy conserved by the wrap", abs(es[0.0] / energy(struck_state(n, n, base), base) - 1.0), 1e-3)
    check("edge 1: energy after crossing is below the wrapping run's", float(es[1.0] > 0.7 * es[0.0]), 0.0)


# ------------------------------------------------------------------ User Story 2: resonator

def test_resonator_rings_per_pixel_without_spreading():
    """speed 0, ring > 0: each pixel rings independently at `ring`. Exact except for the DC bin
    (zeroing removes mean/N^2 per frame), which is recorded."""
    n = 32
    ring = 3.0
    p = Params(speed=0.0, ring=ring, damping=0.0, dt=0.01, fast_fft=True)
    st = new_state(n, n)
    st[8, 8, 0] = 1.0
    frames = 40
    for _ in range(frames):
        st, _, _, _ = wave_frame(st, p)
    want = np.cos(ring * frames * p.dt)
    got = float(st[8, 8, 0])
    note("peak pixel vs cos(ring t)", f"{got:.4f} vs {want:.4f}")
    check("peak pixel follows cos(ring t) (DC removal costs ~1/N^2 per frame)", abs(got - want), 0.05)
    off = np.abs(st[..., 0].copy())
    off[8, 8] = 0.0
    check("no spatial spread: every other pixel stays near zero", float(off.max()), 0.05)


def test_zero_speed_zero_ring_is_stable_and_static():
    st = new_state(N, N)
    rng = np.random.default_rng(11)
    st[..., 0] = rng.uniform(-1, 1, (N, N))
    st[..., 0] -= st[..., 0].mean()
    p = Params(speed=0.0, ring=0.0, damping=0.0, fast_fft=True)
    out = st
    for _ in range(100):
        out, _, _, _ = wave_frame(out, p)
    check("speed 0, ring 0, v = 0: the field does not move", float(np.abs(out[..., 0] - st[..., 0]).max()), 1e-5)


# ------------------------------------------------------------------ strike, reset, exciter

def test_strike_and_reset():
    p = Params(speed=0.25, x=0.3, y=0.6)
    s = struck_state(64, 64, p)
    iy, ix = np.unravel_index(np.argmax(s[..., 0]), s[..., 0].shape)
    check("strike peaks at the exciter position (x)", abs((ix + 0.5) / 64 - 0.3), 1 / 64)
    check("strike peaks at the exciter position (y)", abs((iy + 0.5) / 64 - 0.6), 1 / 64)
    check("strike puts nothing in v", float(np.abs(s[..., 2]).max()), 0.0)
    z = new_state(64, 64)
    check("reset zeroes u and v", float(np.abs(z[..., [0, 1, 2]]).max()), 0.0)
    out, _, _, _ = wave_frame(z, p.with_(fast_fft=True), strike=True)
    check("a strike frame on a reset field puts a positive peak in u",
          float(out[..., 0].max() <= 0), 0.0)


def test_exciter_with_nothing_connected_makes_rings():
    """User Story 1: with amplitude > 0 and no inlet the field becomes non-trivial and stays bounded."""
    p = Params(speed=0.25, damping=0.2, amplitude=1.0, frequency=3.0, edge=0.5, fast_fft=True)
    st = new_state(64, 64)
    phase = 0.0
    for _ in range(120):
        st, luma, vec, phase = wave_frame(st, p, phase=phase)
    check("field has left zero", float(np.abs(st[..., 0]).max() < 1e-3), 0.0)
    check("field stays bounded", float(np.abs(st[..., 0]).max() > float(wfm.U_CAP)), 0.0)
    check("luma stays in [0, 1]", float(luma[..., 0].min() < 0 or luma[..., 0].max() > 1), 0.0)


def test_amplitude_zero_means_free_ringing_and_decay():
    """User Story 1 AS2: amplitude 0 plus a strike rings freely at the damping rate and never grows."""
    p = Params(speed=0.25, damping=0.8, amplitude=0.0, fast_fft=True)
    st = struck_state(64, 64, p)
    e = [energy(st, p)]
    for _ in range(90):
        st, _, _, _ = wave_frame(st, p)
        e.append(energy(st, p))
    check("never grows", max(max(b / a - 1.0 for a, b in zip(e[:-1], e[1:])), 0.0), 1e-6)
    decay = e[-1] / e[0]
    # u_tt + 2 beta u_t + omega^2 u = 0: energy of an underdamped mode decays as exp(-2 beta t)
    note("energy ratio after 1.5 time units vs exp(-2 beta t)", f"{decay:.3f} vs {np.exp(-2 * 0.8 * 1.5):.3f}")
    check("energy ratio close to exp(-2 beta t)", abs(np.log(decay) + 2 * 0.8 * 1.5), 0.15)


# ------------------------------------------------------------------ outlets and containment

def test_vecfield_is_neutral_on_a_flat_field_and_follows_the_gradient():
    flat = new_state(N, N)
    vec = encode_vec(flat)
    check("flat field: vecfield R = 0.5", float(np.abs(vec[..., 0] - 0.5).max()), 0.0)
    check("flat field: vecfield G = 0.5", float(np.abs(vec[..., 1] - 0.5).max()), 0.0)
    check("vecfield B = 0.5, A = 1", float(max(np.abs(vec[..., 2] - 0.5).max(), np.abs(vec[..., 3] - 1.0).max())), 0.0)
    n = 64
    p = Params(x=0.5, y=0.5)
    bump = new_state(n, n)
    bump[..., 0] = _gauss(n, n, 0.5, 0.5, 0.1)
    ux, uy = gradient(bump)
    nx = (np.arange(n) + 0.5) / n
    xx, yy = np.meshgrid(nx, nx)
    ref_ux = np.gradient(bump[..., 0].astype(np.float64), 1.0 / n, axis=1)
    ref_uy = np.gradient(bump[..., 0].astype(np.float64), 1.0 / n, axis=0)
    inner = (slice(2, -2), slice(2, -2))                # np.gradient is one-sided on the edge; the seam is periodic here
    check("gradient vs np.gradient (interior, relative)",
          max(float(np.abs(ux - ref_ux)[inner].max()), float(np.abs(uy - ref_uy)[inner].max())) / float(np.abs(ref_ux).max()), 1e-4)
    vec = encode_vec(bump)
    sign_ok = np.sign(vec[..., 0] - 0.5)[inner] * np.sign(ux)[inner]
    check("vecfield R points along grad u wherever it is non-zero", float((sign_ok < 0).any()), 0.0)


def test_gradient_is_periodic_across_the_seam():
    n = 32
    u = new_state(n, n)
    u[..., 0] = np.sin(2 * np.pi * (np.arange(n) + 0.5) / n)[None, :]
    ux, _ = gradient(u)
    ref = (2 * np.pi * np.cos(2 * np.pi * (np.arange(n) + 0.5) / n))[None, :] * np.sin(2 * np.pi / n) / (2 * np.pi / n)
    check("periodic central difference incl. the seam columns", float(np.abs(ux - ref).max()) / (2 * np.pi), 1e-5)


def test_containment_never_lets_nan_or_inf_through():
    p = Params(speed=0.25, damping=0.0, fast_fft=True)
    st = new_state(N, N)
    st[3, 4, 0] = np.nan
    st[5, 6, 2] = np.inf
    out, luma, vec, _ = wave_frame(st, p)
    check("state finite after a NaN / Inf input", float((~np.isfinite(out)).sum()), 0.0)
    check("luma finite", float((~np.isfinite(luma)).sum()), 0.0)
    check("vecfield finite", float((~np.isfinite(vec)).sum()), 0.0)
    big = new_state(N, N)
    big[..., 0] = 1.0e6
    out, _, _, _ = wave_frame(big, p)
    check("huge input clamped to U_CAP", float(np.abs(out[..., [0, 2]]).max() > float(wfm.U_CAP)), 0.0)


def test_luma_is_bounded_and_opaque():
    t = new_state(N, N)
    t[..., 0] = np.linspace(-1000, 1000, N * N).reshape(N, N)
    e = encode_luma(t)
    check("luma inside [0, 1]", float(e[..., :3].min() < 0 or e[..., :3].max() > 1), 0.0)
    check("luma A = 1", float(np.abs(e[..., 3] - 1.0).max()), 0.0)
    check("u = 0 maps to mid-grey", abs(float(encode_luma(new_state(N, N))[0, 0, 0]) - 0.5), 0.0)


# ------------------------------------------------------------------ Phase 0 constants (T003, T004, T007)

def test_damping_floor_means_no_energy_growth_over_10000_frames():
    """T003: at the dial's lowest damping the energy only falls, and falls at exp(-2 floor t)."""
    rng = np.random.default_rng(31)
    st = new_state(N, N)
    for ch in (0, 2):
        a = rng.uniform(-1, 1, (N, N))
        st[..., ch] = (a - a.mean()).astype(F32)
    p = Params(speed=0.25, damping=wfm.DAMPING_FLOOR, fast_fft=True)
    e0 = energy(st, p)
    es = [e0]
    for i in range(1, 10001):
        st, _, _, _ = wave_frame(st, p)
        if i % 100 == 0:
            es.append(energy(st, p))
    worst_rise = max(max(b / a - 1.0 for a, b in zip(es[:-1], es[1:])), 0.0)
    check("largest 100-frame energy rise at the damping floor", worst_rise, 1e-6)
    want = np.exp(-2.0 * wfm.DAMPING_FLOOR * 10000 * p.dt)
    check("energy after 10,000 frames vs exp(-2 floor t) (relative)", abs(es[-1] / e0 / want - 1.0), 2e-3)


def test_viscosity_tames_the_top_bins_and_leaves_mid_scale_alone():
    """T004: nu damps the N = 256 Nyquist bin within ~0.2 s and leaves mode 8 alone for ~40 s."""
    p = wfm.Params(speed=0.25, damping=0.0)
    mags = np.array([[TWOPI * 8, TWOPI * 128]], F32)
    _, _, _, beta = step_coeffs(mags, p)
    tau8, tau128 = 1.0 / float(beta[0, 0]), 1.0 / float(beta[0, 1])
    note("damping time at mode 8 / the N = 256 Nyquist bin", f"{tau8:.1f} s / {tau128:.3f} s")
    check("mode 8 damping time is at least 30 s", float(tau8 < 30.0), 0.0)
    check("Nyquist bin damping time is at most 0.2 s", float(tau128 > 0.2), 0.0)


def test_default_sponge_absorbs_the_pulse_without_reflecting_it():
    """T004: struck pulse, default constants, edge 0.5 (the dial default). `reflect` is the inner-disc
    energy that comes back in the window where a reflection would arrive; `left` what survives 4 s."""
    n = 64
    p = Params(speed=0.25, damping=0.001, nu=float(wfm.NU), edge=0.5, fast_fft=True)
    nx = (np.arange(n) + 0.5) / n
    xx, yy = np.meshgrid(nx, nx)
    inner = (xx - 0.5) ** 2 + (yy - 0.5) ** 2 < 0.2 ** 2

    def edens(s):
        u, v = s[..., 0].astype(np.float64), s[..., 2].astype(np.float64)
        ux = (np.roll(u, -1, 1) - np.roll(u, 1, 1)) * (n / 2)
        uy = (np.roll(u, -1, 0) - np.roll(u, 1, 0)) * (n / 2)
        return 0.5 * v * v + 0.5 * p.speed ** 2 * (ux * ux + uy * uy)
    st = struck_state(n, n, p)
    e0 = float(edens(st).sum())
    refl = 0.0
    for i in range(1, 241):
        st, _, _, _ = wave_frame(st, p)
        if 114 <= i <= 186:
            refl = max(refl, float(edens(st)[inner].sum()) / e0)
    left = float(edens(st).sum()) / e0
    note("reflect / left", f"{refl:.4f} / {left:.4f}")
    check("reflected energy back in the inner disc (T004 measured 0.001 at N = 96)", refl, 1e-2)
    check("energy left at 4 s (T004 measured 0.005 at N = 96)", left, 2e-2)


def test_exciter_gain_gives_unit_amplitude_at_the_default_settings():
    n = 64
    p = Params(speed=0.25, damping=0.3, nu=float(wfm.NU), edge=0.5, amplitude=1.0, frequency=2.0, fast_fft=True)
    st, phase, peak = new_state(n, n), 0.0, 0.0
    for i in range(1, 361):
        st, _, _, phase = wave_frame(st, p, phase=phase)
        if i >= 240:
            peak = max(peak, float(np.abs(st[..., 0]).max()))
    note("max |u| over t in [4, 6] s at amplitude 1", f"{peak:.3f}")
    check("max |u| is within 30% of 1", abs(peak - 1.0), 0.3)


def test_force_kick_amplitude_error_follows_the_discrete_model():
    """T007: a static force cos(2 pi m x) is delivered as a kick per frame. The mirror's steady state
    must equal the exact fixed point of the discrete map (linear algebra, independent), and that
    fixed point differs from the continuous F/omega^2 by about -(omega dt)^2 / 12, whatever beta is."""
    m_idx, dt = 4, 1.0 / 60.0
    p = Params(speed=0.25, damping=5.0, dt=dt, force=1.0, fast_fft=True)
    om = float(wfm.omega_of(2 * np.pi * m_idx, p)) if hasattr(wfm, "omega_of") else p.speed * 2 * np.pi * m_idx
    x = (np.arange(N, dtype=np.float64) + 0.5) / N
    tex = new_state(N, N)
    tex[..., 0] = (0.5 + 0.5 * np.cos(2 * np.pi * m_idx * x))[None, :] * np.ones((N, 1))
    st = new_state(N, N)
    for _ in range(300):                                     # beta = 5: transients gone to 1e-11
        st, _, _, _ = wave_frame(st, p, force_tex=tex)
    a, b, c, d = expm2(np.float64(om ** 2), np.float64(5.0), dt)
    P = np.array([[a, b], [c, d]])
    X = np.linalg.solve(np.eye(2) - P, np.array([0.0, dt]))
    prof = np.cos(2 * np.pi * m_idx * x)[None, :] * np.ones((N, 1))
    check("mirror steady state vs the discrete fixed point (relative)",
          float(np.abs(st[..., 0] - X[0] * prof).max()) / abs(X[0]), 1e-4)
    err = X[0] * om ** 2 - 1.0
    pred = -(om * dt) ** 2 / 12.0
    note("static amplitude error vs -(omega dt)^2/12", f"{100 * err:.3f}% vs {100 * pred:.3f}%")
    check("error is -(omega dt)^2/12 within 20%", abs(err - pred) / abs(pred), 0.2)


if __name__ == "__main__":
    sys.exit(run(globals()))
