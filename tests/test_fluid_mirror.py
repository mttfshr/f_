"""
test_fluid_mirror.py -- tier 1 for f_vf_fluid: the NumPy mirror in
fluid_mirror.py checked against INDEPENDENT ground truth (analytic decay
rates, Helmholtz projection identities, exact shifts), plus mutation checks
proving the tests bite (tasks.md T008-T010; spec success criteria 1-3, 5, 6).

Run:  tests/run.sh tests/test_fluid_mirror.py
"""
import contextlib
import io
import sys

import numpy as np

import fluid_mirror as fm
import test_fft_separable as tf
from fluid_mirror import Params
from gpu_sim import F32, TWOPI, grid
from harness import check, note, run

TOL = 1e-5


# ---------------------------------------------------------------- helpers

def rand_state(n, seed=0, amp=0.5):
    rng = np.random.default_rng(seed)
    s = np.zeros((n, n, 4), F32)
    s[..., 0] = rng.uniform(-amp, amp, (n, n))
    s[..., 2] = rng.uniform(-amp, amp, (n, n))
    return s


def smooth_state(n, seed=0, kmax=4, amp=0.5):
    """Random field with only low modes -- what a physical flow looks like."""
    rng = np.random.default_rng(seed)
    s = np.zeros((n, n, 4), F32)
    for c in (0, 2):
        f = np.fft.fft2(rng.standard_normal((n, n)))
        m = np.fft.fftfreq(n, 1.0 / n)
        mask = (np.abs(m)[:, None] <= kmax) & (np.abs(m)[None, :] <= kmax)
        g = np.real(np.fft.ifft2(f * mask))
        s[..., c] = amp * g / np.max(np.abs(g))
    return s


def taylor_green(n, m=1):
    nx, ny, _, _ = grid(n, n)
    s = np.zeros((n, n, 4), F32)
    s[..., 0] = np.sin(TWOPI * m * nx) * np.cos(TWOPI * m * ny)
    s[..., 2] = -np.cos(TWOPI * m * nx) * np.sin(TWOPI * m * ny)
    return s


def rand_force(h, w, seed=1):
    """A render-res f_vecfield texture with random RG."""
    rng = np.random.default_rng(seed)
    t = np.zeros((h, w, 4), F32)
    t[..., 0] = rng.uniform(0, 1, (h, w))
    t[..., 1] = rng.uniform(0, 1, (h, w))
    t[..., 2] = 0.5
    t[..., 3] = 1.0
    return t


def spectral_roundtrip(state, viscosity, project, drag, dt):
    """spec stage only, between the fast FFTs (isolates stage 4)."""
    s = fm.spec(fm.fft2_np(state), viscosity, project, drag, dt)
    return fm.ifft2_np(s)


def amp_along(state, ref):
    num = np.sum(state[..., 0].astype(np.float64) * ref[..., 0]
                 + state[..., 2].astype(np.float64) * ref[..., 2])
    den = np.sum(ref[..., 0].astype(np.float64) ** 2
                 + ref[..., 2].astype(np.float64) ** 2)
    return num / den


@contextlib.contextmanager
def patched(**kw):
    old = {k: getattr(fm, k) for k in kw}
    for k, v in kw.items():
        setattr(fm, k, v)
    try:
        yield
    finally:
        for k, v in old.items():
            setattr(fm, k, v)


# ---------------------------------------------------------------- tests

def test_fast_fft_path_matches_pass_dft():
    """The np.fft fast path (used for long runs) must equal the real
    pass_dft mirror over a few full frames, force included."""
    n = 32
    force = rand_force(48, 40)
    p = Params(dt=0.02, force=0.1, viscosity=0.05, project=0.7, drag=0.1)
    a = b = rand_state(n, 3)
    for _ in range(3):
        a = fm.step(a, force, p, fft="np")
        b = fm.step(b, force, p, fft="passes")
    check("3 frames: |np path - pass_dft path|", np.max(np.abs(a - b)), 1e-4)


def test_single_mode_decay():
    """SC1: a single Fourier mode decays by exactly exp(-(nu*|k|^2 + mu)*dt)."""
    dt, mu = 0.01, 0.5
    for n in (64, 256):
        nx, ny, _, _ = grid(n, n)
        u = np.sin(TWOPI * 3 * ny).astype(F32)          # k = (0, 3): divergence-free
        v = np.cos(TWOPI * 5 * nx).astype(F32)          # k = (5, 0): divergence-free
        st = np.zeros((n, n, 4), F32)
        st[..., 0], st[..., 2] = u, v
        nu = np.log(2.0) / (dt * (TWOPI * 3) ** 2)      # mode 3 loses half its amplitude
        for proj in (0.0, 1.0):
            out = spectral_roundtrip(st, nu, proj, mu, dt)
            gu = np.exp(-(nu * (TWOPI * 3) ** 2 + mu) * dt)
            gv = np.exp(-(nu * (TWOPI * 5) ** 2 + mu) * dt)
            check(f"N={n} project={proj:g} u decay (x{gu:.3f})",
                  np.max(np.abs(out[..., 0] - gu * u)), TOL)
            check(f"N={n} project={proj:g} v decay (x{gv:.3f})",
                  np.max(np.abs(out[..., 2] - gv * v)), TOL)


def test_drag_acts_on_mean_flow():
    """The k = 0 bin only gets the drag term (viscosity and projection
    leave it alone)."""
    n, dt, mu = 64, 0.02, 1.3
    st = np.zeros((n, n, 4), F32)
    st[..., 0], st[..., 2] = 0.4, -0.25
    out = spectral_roundtrip(st, viscosity=5.0, project=1.0, drag=mu, dt=dt)
    g = np.exp(-mu * dt)
    check("mean u x exp(-mu dt)", np.max(np.abs(out[..., 0] - g * 0.4)), TOL)
    check("mean v x exp(-mu dt)", np.max(np.abs(out[..., 2] - g * -0.25)), TOL)


def gradient_curl_case(n):
    nx, ny, _, _ = grid(n, n)
    a, b = TWOPI * 2, TWOPI * 3                    # phi = sin(a x) cos(b y)
    gu = a * np.cos(a * nx) * np.cos(b * ny)
    gv = -b * np.sin(a * nx) * np.sin(b * ny)
    c, d = TWOPI * 1, TWOPI * 4                    # psi = cos(c x) sin(d y)
    cu = d * np.cos(c * nx) * np.cos(d * ny)
    cv = c * np.sin(c * nx) * np.sin(d * ny)
    st = np.zeros((n, n, 4), F32)
    st[..., 0], st[..., 2] = gu + cu, gv + cv
    return st, cu, cv


def test_projection_removes_gradient_keeps_curl():
    """SC2: projection deletes a pure-gradient field, leaves a pure-curl
    field untouched (checked on the sum)."""
    for n in (64, 256):
        st, cu, cv = gradient_curl_case(n)
        out = spectral_roundtrip(st, 0.0, 1.0, 0.0, 0.01)
        scale = max(np.max(np.abs(cu)), np.max(np.abs(cv)))
        check(f"N={n} u == curl u (rel)", np.max(np.abs(out[..., 0] - cu)) / scale, TOL)
        check(f"N={n} v == curl v (rel)", np.max(np.abs(out[..., 2] - cv)) / scale, TOL)


def test_project_blend_is_linear():
    n = 64
    st = rand_state(n, 5)
    o0 = spectral_roundtrip(st, 0.0, 0.0, 0.0, 0.01)
    o1 = spectral_roundtrip(st, 0.0, 1.0, 0.0, 0.01)
    oh = spectral_roundtrip(st, 0.0, 0.5, 0.0, 0.01)
    check("project=0 is the identity", np.max(np.abs(o0 - st)), TOL)
    check("project=0.5 == mean of 0 and 1", np.max(np.abs(oh - 0.5 * (o0 + o1))), TOL)


def test_projection_random_field_divergence_free():
    """SC2: after project=1 the spectral divergence (with the same operator
    the codebox uses) is at numerical zero -- white noise included, so the
    Nyquist bins are exercised."""
    for n in (64, 128):
        s = fm.spec(fm.fft2_np(rand_state(n, 6)), 0.0, 1.0, 0.0, 0.01)
        _, _, _, kxo, kyo = fm.wavenumbers(n, n)
        uh = s[..., 0].astype(np.float64) + 1j * s[..., 1]
        vh = s[..., 2].astype(np.float64) + 1j * s[..., 3]
        div = np.abs(kxo * uh + kyo * vh)
        ref = np.max(np.sqrt(kxo.astype(np.float64) ** 2 + kyo ** 2)
                     * np.sqrt(np.abs(uh) ** 2 + np.abs(vh) ** 2))
        check(f"N={n} spectral divergence after projection (rel)", np.max(div) / ref, TOL)


def nyquist_case():
    n = 64
    st = rand_state(n, 7)                     # white noise: has Nyquist energy
    out = spectral_roundtrip_raw(st)
    return np.max(np.abs(out[..., [1, 3]])) / np.max(np.abs(out[..., [0, 2]]))


def spectral_roundtrip_raw(state):
    s = fm.spec(fm.fft2_np(state), 0.01, 1.0, 0.0, 0.01)
    return fm.ifft2_np(s)


def test_nyquist_keeps_field_real():
    """ADR-5: with the Nyquist bin zeroed in the projection operator, a real
    field stays real (no imaginary residue) after the spectral pass."""
    check("max |Im| / max |Re| after projection", nyquist_case(), TOL)


def test_taylor_green_decay():
    """SC3: a 2D Taylor-Green vortex decays as exp(-nu*|k|^2*t), |k|^2 =
    2*(2*pi*m)^2, through the WHOLE step (semi-Lagrangian advection +
    projection + viscosity). Bounds the numerical dissipation of bilinear
    advection. dt is small so a frame moves the flow < 0.2 texel at N=64."""
    dt, nu = 0.003, 0.084
    p = Params(dt=dt, viscosity=nu, project=1.0, force=0.0, src_vecfield=0.0)
    for n in (64, 256):
        st0 = taylor_green(n)
        st = st0
        for f in range(1, 101):
            st = fm.step(st, None, p)
            if f in (10, 50, 100):
                expect = np.exp(-nu * 2 * TWOPI ** 2 * dt * f)
                got = amp_along(st, st0)
                check(f"N={n} frame {f}: amplitude {got:.4f} vs analytic {expect:.4f} (rel)",
                      abs(got - expect) / expect, 0.05)


def test_energy_never_grows_without_force():
    """Spec US2 scenario 3: with nu = 0, drag = 0, no force, energy does not
    increase between frames beyond numerical tolerance (interpolation and
    projection are dissipative)."""
    n = 64
    p = Params(dt=0.01, viscosity=0.0, project=1.0, force=0.0, src_vecfield=0.0)
    st = smooth_state(n, 2)
    e_prev, worst = fm.energy(st), -np.inf
    for _ in range(100):
        st = fm.step(st, None, p)
        e = fm.energy(st)
        worst = max(worst, (e - e_prev) / e_prev)
        e_prev = e
    note("largest relative energy change in one frame (nu=0; <0 = always dropping)", worst)
    check("max relative energy increase per frame (nu=0)", max(worst, 0.0), 1e-4)
    p2 = p.with_(viscosity=0.05, drag=0.2)
    st, e_prev = smooth_state(n, 2), None
    e_prev = fm.energy(st)
    for _ in range(50):
        st = fm.step(st, None, p2)
        e = fm.energy(st)
        assert e < e_prev, "energy must strictly decrease with viscosity and drag"
        e_prev = e


def test_zero_in_zero_out():
    """SC6/FR-009: zero state and zero force -> exactly zero state and an
    exactly neutral outlet, every frame, however the inlet is presented."""
    n = 64
    neutral = fm.neutral(40, 48)
    for label, force, src in (("unconnected", None, 0.0),
                              ("black texture, src=0", np.zeros((40, 48, 4), F32), 0.0),
                              ("random texture, src=0", rand_force(40, 48), 0.0),
                              ("neutral texture, src=1", neutral, 1.0)):
        p = Params(force=0.3, src_vecfield=src, viscosity=0.1, drag=0.1)
        st = fm.zero_state(n)
        for _ in range(20):
            st = fm.step(st, force, p)
            out = fm.enc(force, st, p.gain, 0.0, src, size=(40, 48))
            assert np.max(np.abs(st)) == 0.0, f"{label}: state left zero"
            assert np.array_equal(out, neutral), f"{label}: outlet not exactly neutral"
        print(f"    ok   {label}: state == 0 and outlet == (0.5, 0.5, 0.5, 1) for 20 frames")


def seam_shift_error():
    """Advection across the periodic seam is an exact gather with wrap when
    every displacement is a whole number of texels: u takes values 0.25, 0.5,
    0.75 along x (v = 0), dt = 0.25 -> 4, 8 or 12 texels at N = 64, all exact
    in float32, so out[x] = u[(x - shift[x]) mod N] with no interpolation."""
    n = 64
    rng = np.random.default_rng(9)
    ucol = rng.choice(np.array([0.25, 0.5, 0.75], F32), n)
    st = np.zeros((n, n, 4), F32)
    st[..., 0] = ucol[None, :]
    out = fm.adv(st, None, 0.25, 0.0, 0.0)
    shift = np.rint(ucol * 0.25 * n).astype(int)          # 4, 8, 12 texels
    src = (np.arange(n) - shift) % n
    want = ucol[src]
    return np.max(np.abs(out[..., 0] - want[None, :]))


def test_advection_is_periodic():
    check("integer-texel advection == circular shift", seam_shift_error(), 0)


def test_force_injection():
    n = 32
    force = np.zeros((20, 24, 4), F32)
    force[..., 0], force[..., 1], force[..., 2], force[..., 3] = 0.75, 0.25, 0.5, 1.0
    out = fm.adv(fm.zero_state(n), force, 0.01, 0.4, 1.0)
    check("u = force * (+0.5)", np.max(np.abs(out[..., 0] - 0.4 * 0.5)), 1e-7)
    check("v = force * (-0.5)", np.max(np.abs(out[..., 2] + 0.4 * 0.5)), 1e-7)
    off = fm.adv(fm.zero_state(n), force, 0.01, 0.4, 0.0)
    check("src_vecfield = 0 adds exactly nothing", np.max(np.abs(off)), 0)


def test_encode_and_bypass_gate():
    n, h, w = 32, 20, 24
    force = rand_force(h, w, 4)
    vel = np.zeros((n, n, 4), F32)
    vel[..., 0], vel[..., 2] = 0.3, -0.2
    e = fm.enc(force, vel, 1.5, 0.0, 1.0)
    check("R = 0.5 + 0.5*gain*u", np.max(np.abs(e[..., 0] - (0.5 + 0.5 * 1.5 * 0.3))), 1e-6)
    check("G = 0.5 + 0.5*gain*v", np.max(np.abs(e[..., 1] - (0.5 + 0.5 * 1.5 * -0.2))), 1e-6)
    check("B = 0.5, A = 1", max(np.max(np.abs(e[..., 2] - 0.5)), np.max(np.abs(e[..., 3] - 1))), 0)
    big = fm.enc(force, vel * 100, 10.0, 0.0, 1.0)
    check("clamped to [0, 1]", max(float(big.max()) - 1.0, -float(big.min())), 0)
    byp = fm.enc(force, vel, 1.5, 1.0, 1.0)
    check("bypass, connected: force exactly", np.max(np.abs(byp - force)), 0)
    unc = fm.enc(None, vel, 1.5, 1.0, 0.0, size=(h, w))
    check("bypass, unconnected: exactly neutral", np.max(np.abs(unc - fm.neutral(h, w))), 0)
    unc2 = fm.enc(force, vel, 1.5, 1.0, 0.0)
    check("bypass, src_vecfield=0: exactly neutral", np.max(np.abs(unc2 - fm.neutral(h, w))), 0)


def test_encode_upsample_is_periodic_and_smooth():
    n, h, w = 32, 45, 64
    nx, ny, _, _ = grid(n, n)
    vel = np.zeros((n, n, 4), F32)
    vel[..., 0] = 0.5 * np.sin(TWOPI * nx)         # a smooth periodic field
    e = fm.enc(None, vel, 1.0, 0.0, 1.0, size=(h, w))
    ox, _, _, _ = grid(h, w)
    want = 0.5 + 0.25 * np.sin(TWOPI * ox)
    # linear interpolation error of a sampled sine: (theta^2 / 8) * amplitude
    bound = 0.25 * (TWOPI / n) ** 2 / 8 * 1.05
    check("upsample matches analytic within the interpolation bound",
          np.max(np.abs(e[..., 0] - want)), bound)
    ex = e[:, 0, 0]
    ey = e[:, -1, 0]
    check("left and right edge columns are continuous across the seam",
          abs(float(ex.mean()) - float(ey.mean())), 0.03)


def test_stability_at_extremes_10k_frames():
    """SC5 (tier 1): 10^4 frames at parameter extremes under sustained force
    stay finite; the encoded outlet stays in [0, 1]."""
    n, frames = 32, 10_000
    rand = rand_force(24, 24, 11)
    uniform = np.zeros((24, 24, 4), F32)
    uniform[..., 0], uniform[..., 1], uniform[..., 2], uniform[..., 3] = 1.0, 0.0, 0.5, 1.0
    cases = {
        "thick honey, big dt": (Params(dt=0.05, force=0.5, viscosity=50.0, drag=5.0, project=1.0), rand),
        "inviscid, no drag, big dt": (Params(dt=0.05, force=0.5, viscosity=0.0, drag=0.0, project=1.0), rand),
        "unprojected shocks": (Params(dt=0.05, force=0.5, viscosity=0.0, drag=0.0, project=0.0), rand),
        "uniform force, no drag": (Params(dt=0.05, force=0.5, viscosity=0.0, drag=0.0, project=1.0), uniform),
        "tiny dt": (Params(dt=0.0005, force=0.5, viscosity=0.5, drag=0.1, project=0.5), rand),
    }
    for label, (p, force) in cases.items():
        st = fm.zero_state(n)
        for f in range(frames):
            st = fm.step(st, force, p)
            if f % 500 == 499:
                out = fm.enc(force, st, 1.0, 0.0, 1.0)
                assert np.isfinite(st).all(), f"{label}: non-finite state at frame {f}"
                assert np.isfinite(out).all() and out.min() >= 0.0 and out.max() <= 1.0, \
                    f"{label}: outlet out of range at frame {f}"
        print(f"    ok   {label}: finite for {frames} frames, |u|max = {np.abs(st).max():.3g}")


# --------------------------------------------------- mutations (T010)

def expect_fail(label, fn):
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf):
            fn()
    except AssertionError:
        print(f"    ok   mutation caught: {label}")
        return
    raise AssertionError(f"mutation SURVIVED: {label}")


def test_mutations_are_caught():
    """Break each rule once; the named test must fail (proves the tests bite)."""
    def wavenumbers_no_nyquist(h, w):
        kx, ky, k2, _, _ = orig_wavenumbers(h, w)
        return kx, ky, k2, kx, ky                    # operator not zeroed at Nyquist

    def project_wrong_sign(ur, ui, vr, vi, kxo, kyo):
        k2o = kxo * kxo + kyo * kyo
        inv = np.where(k2o > 0, F32(1.0) / np.maximum(k2o, F32(1e-30)), F32(0.0))
        dr = (kxo * ur + kyo * vr) * inv
        di = (kxo * ui + kyo * vi) * inv
        return ur + kxo * dr, ui + kxo * di, vr + kyo * dr, vi + kyo * di

    def decay_wrong(k2, nu, mu, dt):
        return np.exp(-(F32(nu) * np.sqrt(k2) + F32(mu)) * F32(dt)).astype(F32)

    def decay_no_drag(k2, nu, mu, dt):
        return np.exp(-(F32(nu) * k2) * F32(dt)).astype(F32)

    orig_wavenumbers = fm.wavenumbers
    with patched(wavenumbers=wavenumbers_no_nyquist):
        expect_fail("Nyquist bin not zeroed -> field gains an imaginary part",
                    test_nyquist_keeps_field_real)
    with patched(project_vec=project_wrong_sign):
        expect_fail("projection sign flipped", test_projection_removes_gradient_keeps_curl)
    with patched(decay=decay_wrong):
        expect_fail("decay exponent wrong (|k| instead of |k|^2)", test_single_mode_decay)
    with patched(decay=decay_no_drag):
        expect_fail("drag dropped from the decay factor", test_drag_acts_on_mean_flow)
    with patched(PERIODIC=False):
        expect_fail("advection clamps instead of wrapping", test_advection_is_periodic)


if __name__ == "__main__":
    sys.exit(run(globals()))
