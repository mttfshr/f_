"""
test_immiscible.py -- tier 1 for f_vf_immiscible: the NumPy mirror in
immiscible_mirror.py checked against INDEPENDENT ground truth (exact mean
conservation, analytic single-mode rates, the tanh interface profile, free-energy
decay, blend identities, the divergence of a blend), plus mutation checks proving
the tests bite (tasks.md T003; spec success criteria 1-5, FR-004, FR-010, FR-014).

Constants in the mirror are PROVISIONAL until T004; these tests pin behaviour that
must hold for any constants, with the tolerances stated in each check.

Run:  tests/run.sh -q tests/modules/immiscible/test_immiscible.py
"""
import contextlib
import io
import sys

import numpy as np

import fluid_mirror as fm
import immiscible_mirror as im
from gpu_sim import F32, grid
from harness import check, note, run
from immiscible_mirror import Params

TWOPI = 2.0 * np.pi


# ---------------------------------------------------------------- helpers

def vecfield(ux, uy):
    """A render-res f_vecfield texture from two arrays of decoded velocity."""
    h, w = ux.shape
    t = np.zeros((h, w, 4), F32)
    t[..., 0] = 0.5 + 0.5 * ux
    t[..., 1] = 0.5 + 0.5 * uy
    t[..., 2] = 0.5
    t[..., 3] = 1.0
    return t


def uniform_vecfield(h, w, ux, uy):
    return vecfield(np.full((h, w), ux), np.full((h, w), uy))


def rand_vecfield(h, w, seed, amp=1.0):
    rng = np.random.default_rng(seed)
    return vecfield(rng.uniform(-amp, amp, (h, w)), rng.uniform(-amp, amp, (h, w)))


def coords64(n):
    nx, ny, _, _ = grid(n, n)
    return nx.astype(np.float64), ny.astype(np.float64)


def mode_amp(phi, m):
    """Amplitude of cos(2 pi m x) in phi (x = axis 1)."""
    n = phi.shape[0]
    return float(abs(np.fft.fft2(phi.astype(np.float64))[0, m]) * 2.0 / (n * n))


def spec_div(ux, uy, mmax=None):
    """Spectral divergence in float64 (Nyquist zeroed). mmax low-passes the derivative
    to |mode| <= mmax: the test fields are band-limited, so everything above is float32
    rounding noise, which the derivative would otherwise amplify by k (about 1e-5 at
    the top of a 64^2 grid)."""
    n = ux.shape[0]
    k = TWOPI * np.fft.fftfreq(n, 1.0 / n)
    k[n // 2] = 0.0
    if mmax is not None:
        k = np.where(np.abs(np.fft.fftfreq(n, 1.0 / n)) <= mmax, k, 0.0)
    dx = np.real(np.fft.ifft2(1j * k[None, :] * np.fft.fft2(ux.astype(np.float64))))
    dy = np.real(np.fft.ifft2(1j * k[:, None] * np.fft.fft2(uy.astype(np.float64))))
    return dx + dy


def taylor_green(n, m, amp):
    nx, ny = coords64(n)
    ux = amp * np.sin(TWOPI * m * nx) * np.cos(TWOPI * m * ny)
    uy = -amp * np.cos(TWOPI * m * nx) * np.sin(TWOPI * m * ny)
    return np.stack([ux, uy], -1).astype(F32)


# ------------------------------------------------------- phase separation

def test_mean_conserved_no_flow():
    """SC1: with no flow and no injection the mean of phi changes by float32 summation
    error only. Checked on the spec stage alone and on the whole step."""
    n = 64
    rng = np.random.default_rng(3)
    phi0 = np.clip(0.1 + 0.15 * rng.standard_normal((n, n)), -0.9, 0.9)
    m0 = float(np.mean(phi0.astype(F32).astype(np.float64)))
    p = Params(coarsen=1.0, inject=0.0, pull=0.0)
    s = im.phi_state(phi0)
    for _ in range(40):
        s = im.spectral_step(s, p)
    check("mean drift, spec stage, 40 frames", abs(float(np.mean(s[..., 0].astype(np.float64))) - m0), 1e-6)
    s = im.phi_state(phi0)
    for _ in range(40):
        s = im.step(s, None, None, None, p)
    check("mean drift, whole step, 40 frames", abs(float(np.mean(s[..., 0].astype(np.float64))) - m0), 1e-6)


def test_single_mode_rate():
    """SC3: one small-amplitude mode on a uniform background grows or decays at the
    analytic Cahn-Hilliard rate, lambda*dt = -mdt k^2 (3 phi0^2 - 1 + kappa k^2),
    within 2% (small step, so the scheme's O(x^2) error is far below the tolerance)."""
    n, steps, delta = 64, 200, 1e-2
    mdt = 1e-6
    p = Params(coarsen=im.mdt_to_coarsen(mdt), inject=0.0, pull=0.0)
    nx, _ = coords64(n)
    for phi0, m in ((0.0, 2), (0.3, 1), (0.0, 6)):
        s = im.phi_state(phi0 + delta * np.cos(TWOPI * m * nx))
        a0 = mode_amp(s[..., 0], m)
        for _ in range(steps):
            s = im.spectral_step(s, p)
        measured = np.log(mode_amp(s[..., 0], m) / a0) / steps
        k2 = (TWOPI * m) ** 2
        expected = -mdt * k2 * (3.0 * phi0 ** 2 - 1.0 + im.kappa_of(p.iface, n) * k2)
        note(f"phi0 {phi0} mode {m}", f"measured {measured:.4e}  analytic {expected:.4e}")
        check(f"rate error, phi0 {phi0} mode {m}", abs(measured - expected) / abs(expected), 0.02)


def test_flat_interface_relaxes_to_tanh():
    """SC4: a periodic top-hat relaxes to the tanh profile whose width iface predicts,
    phi = tanh((x - x0) / (sqrt(2) eps)), within 10% (profile and peak gradient)."""
    n = 128
    p = Params(coarsen=im.mdt_to_coarsen(5e-4), iface=4.0, inject=0.0, pull=0.0)
    nx, _ = coords64(n)
    row = np.where((nx[0] > 0.25) & (nx[0] < 0.75), 1.0, -1.0)
    s = im.phi_state(np.tile(row, (n, 1)))
    for _ in range(400):
        s = im.spectral_step(s, p)
    prof = s[0, :, 0].astype(np.float64)
    assert np.all(np.isfinite(prof)), "profile went non-finite"
    eps = p.iface / n
    xs = nx[0]
    i = int(np.argmax((prof[:-1] < 0) & (prof[1:] >= 0)))          # the rising crossing near x = 0.25
    x0 = xs[i] + (0.0 - prof[i]) * (xs[i + 1] - xs[i]) / (prof[i + 1] - prof[i])
    win = np.abs(xs - x0) < 3.0 * np.sqrt(2.0) * eps
    exact = np.tanh((xs[win] - x0) / (np.sqrt(2.0) * eps))
    err = float(np.max(np.abs(prof[win] - exact)))
    peak = float(np.max(np.gradient(prof, xs)))
    note("interface centre", f"{x0:.4f}  (initial 0.25)")
    note("peak gradient", f"{peak:.3f}  expected {1.0 / (np.sqrt(2.0) * eps):.3f}")
    check("profile max error vs tanh", err, 0.10)
    check("peak gradient relative error", abs(peak * np.sqrt(2.0) * eps - 1.0), 0.10)


def test_free_energy_nonincreasing_without_flow():
    """SC2: with no flow and no injection the free energy never increases from one
    frame to the next (beyond 1e-7), at the dial maximum and at ten times that step,
    for a start with |phi| < 1 (the stabiliser's regime)."""
    n = 64
    rng = np.random.default_rng(5)
    phi0 = 0.1 * rng.uniform(-1, 1, (n, n)) + 0.05
    for mdt in (2e-4, 2e-3):
        p = Params(coarsen=im.mdt_to_coarsen(mdt), inject=0.0, pull=0.0)
        s = im.phi_state(phi0)
        e = [im.free_energy(s[..., 0], p.iface)]
        for _ in range(150):
            s = im.spectral_step(s, p)
            e.append(im.free_energy(s[..., 0], p.iface))
        rise = max(b - a for a, b in zip(e[:-1], e[1:]))
        note(f"mdt {mdt:g}", f"F {e[0]:.5f} -> {e[-1]:.5f}")
        assert e[-1] < e[0], f"energy did not fall at mdt {mdt:g}"
        check(f"largest per-frame energy rise, mdt {mdt:g}", max(rise, 0.0), 1e-7)


# ------------------------------------------------------------------ blend

def test_blend_identities():
    """FR-004: phi = -1 gives A exactly, phi = +1 gives B exactly, plain is a convex
    combination, and swapping A and B with phi -> -phi gives the same output (both rules)."""
    n = 48
    rng = np.random.default_rng(7)
    uA = rng.uniform(-1, 1, (n, n, 2)).astype(F32)
    uB = rng.uniform(-1, 1, (n, n, 2)).astype(F32)
    for mode in (0.0, 1.0):
        lo, hi = np.full((n, n), -1.0, F32), np.full((n, n), 1.0, F32)
        check(f"phi=-1 gives A, mode {mode:g}", np.max(np.abs(im.blend_vel(uA, uB, lo, 4.0, mode) - uA)), 1e-7)
        check(f"phi=+1 gives B, mode {mode:g}", np.max(np.abs(im.blend_vel(uA, uB, hi, 4.0, mode) - uB)), 1e-7)
    nx, ny = coords64(n)
    phi = (0.8 * np.sin(TWOPI * nx + 0.4) * np.cos(TWOPI * ny)).astype(F32)
    up = im.blend_vel(uA, uB, phi, 4.0, 0.0)
    lo_b, hi_b = np.minimum(uA, uB), np.maximum(uA, uB)
    check("plain blend below the convex hull", np.max(np.maximum(lo_b - up, 0.0)), 1e-6)
    check("plain blend above the convex hull", np.max(np.maximum(up - hi_b, 0.0)), 1e-6)
    for mode in (0.0, 1.0):
        a = im.blend_vel(uA, uB, phi, 4.0, mode)
        b = im.blend_vel(uB, uA, -phi, 4.0, mode)
        check(f"swap symmetry, mode {mode:g}", np.max(np.abs(a - b)), 1e-6)


def test_plain_blend_divergence():
    """SC5: for divergence-free A and B, div of the plain blend equals grad(w) . (uB - uA)
    (here w = (phi + 1)/2), to 1e-5."""
    n = 64
    nx, ny = coords64(n)
    uA = taylor_green(n, 1, 1.0)
    uB = taylor_green(n, 2, 0.7)
    phi = 0.9 * np.sin(TWOPI * nx + 0.3) * np.cos(TWOPI * ny) + 0.1
    u = im.blend_vel(uA, uB, phi.astype(F32), 4.0, 0.0)
    div = spec_div(u[..., 0], u[..., 1], mmax=8)       # products of modes 1 x 2 reach mode 3
    gwx = 0.5 * 0.9 * TWOPI * np.cos(TWOPI * nx + 0.3) * np.cos(TWOPI * ny)
    gwy = -0.5 * 0.9 * TWOPI * np.sin(TWOPI * nx + 0.3) * np.sin(TWOPI * ny)
    d = uB.astype(np.float64) - uA.astype(np.float64)
    check("div(blend) - grad(w).(uB - uA)", np.max(np.abs(div - (gwx * d[..., 0] + gwy * d[..., 1]))), 1e-5)


def test_divergence_integral_equals_normal_jump():
    """SC5: across a straight interface the divergence integrated over a window equals
    the normal jump u_x(B) - u_x(A) for EVERY rule (an output-side rule can only spread
    it, spec Settled model); the tangential component of the interface-aware rule is
    untouched. The two peak |div| values are recorded (note) for G2, not asserted."""
    n = 256
    nx, _ = coords64(n)
    eps = 4.0 / n
    d = np.sqrt(2.0) * eps
    row = np.tanh((nx[0] - 0.25) / d) - np.tanh((nx[0] - 0.75) / d) - 1.0      # A | B | A
    phi = np.tile(row, (n, 1)).astype(F32)
    uA = np.zeros((n, n, 2), F32)
    uB = np.zeros((n, n, 2), F32)
    uA[..., 0], uA[..., 1] = 0.2, 0.1
    uB[..., 0], uB[..., 1] = -0.2, 0.3
    dx = 1.0 / n
    plain = im.blend_vel(uA, uB, phi, 4.0, 0.0)
    for mode in (0.0, 1.0):
        u = im.blend_vel(uA, uB, phi, 4.0, mode)
        ux = u[0, :, 0].astype(np.float64)
        div = np.zeros(n)
        div[1:-1] = (ux[2:] - ux[:-2]) / (2.0 * dx)
        lo1, hi1 = int(0.1 * n), int(0.4 * n)
        lo2, hi2 = int(0.6 * n), int(0.9 * n)
        j1 = float(np.sum(div[lo1:hi1]) * dx)
        j2 = float(np.sum(div[lo2:hi2]) * dx)
        check(f"integral over interface 1 minus jump (B-A), mode {mode:g}", abs(j1 - (-0.2 - 0.2)), 1e-4)
        check(f"integral over interface 2 minus jump (A-B), mode {mode:g}", abs(j2 - (0.2 + 0.2)), 1e-4)
        note(f"peak |div| mode {mode:g}", f"{float(np.max(np.abs(div[lo1:hi1]))):.3f}")
        check(f"tangential untouched, mode {mode:g}", np.max(np.abs(u[..., 1] - plain[..., 1])), 1e-6)


# --------------------------------------------------------------- the stages

def test_advection_is_periodic():
    """adv translates phi exactly across the seam: a uniform velocity of 8 texels per
    frame moves every texel 8 columns with wrap (no spec step: coarsen 0)."""
    n = 32
    rng = np.random.default_rng(11)
    phi0 = rng.uniform(-0.9, 0.9, (n, n))
    A = uniform_vecfield(n, n, 0.5, 0.0)
    p = Params(dt=0.5, coarsen=0.0, inject=0.0, pull=0.0, taps=1.0)
    s = im.step(im.phi_state(phi0), A, A, None, p)
    expected = np.roll(phi0.astype(F32), 8, axis=1)
    check("periodic shift error", np.max(np.abs(s[..., 0] - expected)), 1e-6)


def test_injection_only_where_bright():
    """FR-008: a bright disc raises phi toward +1 inside it and nowhere else; a black or
    absent source, or src_phi 0, deposits nothing."""
    n, r = 64, 128
    ry, rx = np.mgrid[0:r, 0:r]
    disc = ((rx + 0.5) / r - 0.5) ** 2 + ((ry + 0.5) / r - 0.5) ** 2 < 0.2 ** 2
    src = np.zeros((r, r, 4), F32)
    src[..., :3] = disc[..., None].astype(F32)
    src[..., 3] = 1.0
    uab = np.zeros((n, n, 4), F32)
    p = Params(inject=0.2, taps=2.0)
    out = im.adv(im.phi_state(np.zeros((n, n))), uab, src, p)[..., 0]
    check("centre deposit minus inject^3 (bright disc, luma 1 above thresh + width)", abs(float(out[n // 2, n // 2]) - 0.2 ** 3), 1e-6)
    check("corner deposit", abs(float(out[0, 0])), 0.0)
    black = np.zeros((r, r, 4), F32)
    black[..., 3] = 1.0
    for label, s, pp in (("black source", black, p), ("no source", None, p), ("src_phi 0", src, p.with_(src_phi=0.0))):
        o = im.adv(im.phi_state(np.zeros((n, n))), uab, s, pp)[..., 0]
        check(f"deposit, {label}", float(np.max(np.abs(o))), 0.0)
    o = im.adv(im.phi_state(np.ones((n, n))), uab, src, p)[..., 0]
    check("deposit cannot exceed +1", float(max(np.max(o) - 1.0, 0.0)), 1e-6)


def test_unconnected_inputs_read_zero_velocity():
    """FR-001: an unconnected inlet, a vs_black texture (B = 0) or a cleared flag reads
    as zero velocity, never as vs_black's decoded -1; a valid uniform field decodes exactly."""
    n = 32
    A = uniform_vecfield(40, 40, 0.3, -0.2)
    black = np.zeros((1, 1, 4), F32)
    u = im.inab(A, None, 2.0, n=n)
    check("A decode", float(np.max(np.abs(u[..., 0] - 0.3)) + np.max(np.abs(u[..., 1] + 0.2))), 1e-6)
    check("unconnected B reads zero", float(np.max(np.abs(u[..., 2:]))), 0.0)
    check("vs_black A reads zero", float(np.max(np.abs(im.inab(black, A, 2.0, n=n)[..., 0:2]))), 0.0)
    check("cleared flag reads zero", float(np.max(np.abs(im.inab(A, A, 2.0, src_a=0.0, n=n)[..., 0:2]))), 0.0)


def test_reseed_hold_and_uniform_states():
    """FR-009 / FR-010: reseed gives fill plus small noise (mean fill, bounded, new salt
    gives a new field); hold keeps a state; a uniform phi = +-1 is NOT reseeded and
    stays put under the whole step; non-finite values are healed."""
    n = 64
    p = Params(fill=0.2)
    s = im.seed(n, p, salt=1)
    phi = s[..., 0].astype(np.float64)
    check("reseed mean minus fill", abs(float(np.mean(phi)) - 0.2), 5e-3)
    check("reseed noise beyond amp", float(max(np.max(np.abs(phi - 0.2)) - im.RESEED_AMP, 0.0)), 1e-6)
    assert not np.array_equal(s, im.seed(n, p, salt=2)), "salt did not change the seed"
    assert np.array_equal(im.pass_stage(s, 0.0, 9, 0.2), s), "hold changed the state"
    for v in (1.0, -1.0):
        u = im.phi_state(np.full((n, n), v))
        assert np.array_equal(im.pass_stage(u, 0.0, 3, 0.0), u), f"uniform {v} was reseeded"
        out = im.step(u, None, None, None, Params(coarsen=1.0, inject=0.0, pull=0.0))
        check(f"uniform {v} stays", float(np.max(np.abs(out[..., 0] - v))), 1e-6)
    bad = s.copy()
    bad[5, 5, 0] = np.nan
    bad[6, 6, 0] = np.inf
    healed = im.pass_stage(bad, 0.0, 4, 0.2)[..., 0]
    assert np.all(np.isfinite(healed)), "non-finite survived pass"
    check("untouched texels preserved", float(np.max(np.abs(np.delete(healed.ravel(), [5 * n + 5, 6 * n + 6]) - np.delete(phi.ravel(), [5 * n + 5, 6 * n + 6])))), 1e-7)


def test_freeze_drift_and_determinism():
    """FR-009 freeze: phi held through 100 frames drifts only by DFT round-trip rounding
    (measured here); FR-014: identical inputs, parameters and seed give identical frames."""
    n = 32
    p = Params(freeze=1.0, inject=0.5)
    s0 = im.seed(n, Params(fill=0.0), salt=3)
    A, B = rand_vecfield(48, 48, 1), rand_vecfield(48, 48, 2)
    s = s0
    for _ in range(100):
        s = im.step(s, A, B, None, p)
    drift = float(np.max(np.abs(s[..., 0] - s0[..., 0])))
    note("freeze drift, 100 frames", f"{drift:.2e}")
    check("freeze drift", drift, 1e-5)

    def run_n():
        t = im.seed(n, Params(), salt=7)
        for _ in range(15):
            t = im.step(t, A, B, None, Params(coarsen=1.0, blend=1.0))
        return t
    assert np.array_equal(run_n(), run_n()), "two identical runs differ"


def test_no_nan_at_extremes():
    """NF-003 (tier 1 scale: 32^2, 400 frames per extreme; the 10^4-frame run is the
    bench's, T016): strong +-1 stirring and a bright source at the ends of every dial
    give finite phi inside the clamp."""
    n = 32
    A, B = rand_vecfield(64, 64, 4), rand_vecfield(64, 64, 5)
    rng = np.random.default_rng(6)
    src = np.zeros((64, 64, 4), F32)
    src[..., :3] = rng.uniform(0, 1, (64, 64, 1))
    src[..., 3] = 1.0
    cfgs = (Params(coarsen=1.0, iface=2.0, dt=0.05, inject=1.0, blend=1.0, fill=0.6),
            Params(coarsen=1.0, iface=12.0, dt=0.05, inject=1.0, blend=0.0, fill=-0.6),
            Params(coarsen=0.0, iface=4.0, dt=0.05, inject=0.0, pull=0.0, blend=1.0))
    for i, p in enumerate(cfgs):
        s = im.seed(n, p, salt=i)
        s[..., 0] = np.sign(rng.standard_normal((n, n))).astype(F32)
        for _ in range(400):
            s = im.step(s, A, B, src, p)
            assert np.all(np.isfinite(s)), f"non-finite phi in config {i}"
        check(f"phi beyond clamp, config {i}", float(max(np.max(np.abs(s[..., 0])) - im.PHI_CLAMP, 0.0)), 1e-6)


def test_injection_threshold_ramp():
    """Only the bright part of the source deposits: below `thresh` nothing, at thresh + THRESH_W the full
    inject^3, between them the smoothstep. A uniform mid-grey source below thresh never floods phi."""
    n, r = 32, 64
    uab = np.zeros((n, n, 4), F32)
    p = Params(inject=0.5, thresh=0.5, taps=1.0, pull=0.0)
    def dep(luma):
        src = np.full((r, r, 4), luma, F32)
        src[..., 3] = 1.0
        return float(im.adv(im.phi_state(np.zeros((n, n))), uab, src, p)[n // 2, n // 2, 0])
    full = 0.5 ** 3
    check("luma 0.40 (below thresh) deposits nothing", dep(0.40), 0.0)
    check("luma 0.50 (at thresh) deposits nothing", dep(0.50), 1e-9)
    check("luma 0.575 (half ramp: smoothstep 0.5)", abs(dep(0.575) - 0.5 * full), 1e-6)
    check("luma 0.65 (thresh + width) deposits inject^3", abs(dep(0.65) - full), 1e-6)
    check("luma 1.0 deposits inject^3, not more", abs(dep(1.0) - full), 1e-6)
    s = im.phi_state(np.full((n, n), -1.0))
    src = np.full((r, r, 4), 0.45, F32)
    src[..., 3] = 1.0
    for _ in range(300):
        s = im.step(s, None, None, src, Params(inject=1.0, thresh=0.5, pull=0.0, coarsen=0.0))
    check("300 frames of inject 1 under a below-threshold source: phi still -1", abs(float(s[..., 0].mean()) + 1.0), 1e-6)


def test_pull_relaxes_only_the_mean_toward_fill():
    """spec's pull: phi-hat(0) relaxes toward fill*N^2 at rate PULL_MAX*pull^3 per frame; every other bin is
    untouched; pull 0 and freeze both leave the mean exactly alone."""
    n = 32
    rng = np.random.default_rng(3)
    phi0 = (0.4 + 0.3 * rng.standard_normal((n, n))).astype(F32)
    st = im.phi_state(phi0)
    for pull in (0.0, 0.5, 1.0):
        p = Params(coarsen=0.0, pull=pull, fill=-0.2)
        s = st
        frames = 20
        for _ in range(frames):
            s = im.spectral_step(s, p)
        rate = im.PULL_MAX * pull ** 3
        want = -0.2 + (float(phi0.mean()) + 0.2) * (1 - rate) ** frames
        check(f"pull {pull}: mean after {frames} frames vs closed form", abs(float(s[..., 0].mean()) - want), 2e-6)
        dev0 = phi0 - phi0.mean()
        dev1 = s[..., 0] - s[..., 0].mean()
        check(f"pull {pull}: deviation from the mean unchanged (coarsen 0)", float(np.max(np.abs(dev1 - dev0))), 2e-6)
    s = im.spectral_step(st, Params(coarsen=0.0, pull=1.0, fill=-0.2, freeze=1.0))
    check("freeze: mean untouched even with pull 1", abs(float(s[..., 0].mean()) - float(phi0.mean())), 2e-6)


def test_held_source_settles_with_pull():
    """The reason for pull: a held bright source with pull off drives the mean to +1; with pull on the mean
    stops short and the field stays two-phase."""
    n = 32
    r = 64
    src = np.zeros((r, r, 4), F32)
    src[24:40, 24:40, :3] = 1.0
    src[..., 3] = 1.0
    out = {}
    for pull in (0.0, 1.0):
        p = Params(inject=0.6, thresh=0.5, pull=pull, fill=0.0, coarsen=0.5, dt=0.0)
        s = im.seed(n, p, salt=1)
        for _ in range(1500):
            s = im.step(s, None, None, src, p)
        out[pull] = float(s[..., 0].mean())
    note("mean phi after 1500 frames of a held source, pull 0 / pull 1", f"{out[0.0]:.3f} / {out[1.0]:.3f}")
    check("pull 0: the held source floods phi to +1 (mean >= 0.95)", max(0.95 - out[0.0], 0.0), 0.0)
    check("pull 1: the mean settles below 0.5 (measured 0.064)", max(out[1.0] - 0.5, 0.0), 0.0)


def test_mix_biases_velocity_weight_only():
    """Mix (mix_pct, 50 neutral): 0 = pure A motion, 100 = pure B motion, monotone and convex in between;
    50 changes nothing; swapping A and B with phi -> -phi and mix -> 100 - mix gives the same velocity.
    The phi grey outlet does not move with it."""
    rng = np.random.default_rng(11)
    uA = rng.uniform(-0.5, 0.5, (16, 16, 2)).astype(F32)
    uB = rng.uniform(-0.5, 0.5, (16, 16, 2)).astype(F32)
    phi = rng.uniform(-1, 1, (16, 16)).astype(F32)
    base = im.blend_vel(uA, uB, phi, 4.0, 0.0)
    check("mix 50 is the identity", float(np.max(np.abs(im.blend_vel(uA, uB, phi, 4.0, 0.0, mix_pct=50.0) - base))), 0.0)
    check("mix 0 gives pure A", float(np.max(np.abs(im.blend_vel(uA, uB, phi, 4.0, 0.0, mix_pct=0.0) - uA))), 1e-7)
    check("mix 100 gives pure B", float(np.max(np.abs(im.blend_vel(uA, uB, phi, 4.0, 0.0, mix_pct=100.0) - uB))), 1e-7)
    w = im.blend_weight(phi)
    prev = None
    worst = 0.0
    for m in (0, 10, 25, 40, 50, 60, 75, 90, 100):
        wm = im.mix_bias(w, m)
        worst = max(worst, float(np.max(np.maximum(-wm, wm - 1))))
        if prev is not None:
            worst = max(worst, float(np.max(prev - wm)))
        prev = wm
    check("weight stays in [0, 1] and never falls as mix rises", worst, 1e-7)
    for m in (0.0, 20.0, 70.0, 100.0):
        a = im.blend_vel(uA, uB, phi, 4.0, 0.0, mix_pct=m)
        b = im.blend_vel(uB, uA, -phi, 4.0, 0.0, mix_pct=100.0 - m)
        check(f"swap A/B, phi -> -phi, mix {m:g} -> {100 - m:g}", float(np.max(np.abs(a - b))), 1e-6)
    st = im.phi_state(phi)
    A = np.zeros((16, 16, 4), F32)
    o0a, _ = im.outputs(st, A, A, Params(mix_pct=0.0), (16, 16))
    o0b, _ = im.outputs(st, A, A, Params(mix_pct=100.0), (16, 16))
    check("phi grey outlet is the same at mix 0 and mix 100", float(np.max(np.abs(o0a - o0b))), 0.0)


# ------------------------------------------------------------- mutations

@contextlib.contextmanager
def patched(module, **kw):
    old = {k: getattr(module, k) for k in kw}
    for k, v in kw.items():
        setattr(module, k, v)
    try:
        yield
    finally:
        for k, v in old.items():
            setattr(module, k, v)


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
    orig = im.spec_factor

    def no_nonlinear_term(k2, mdt, kappa, a):
        fa, fn = orig(k2, mdt, kappa, a)
        return fa, fn * F32(0.0)

    def kappa_sign_flipped(k2, mdt, kappa, a):
        return orig(k2, mdt, -kappa, a)

    def mean_not_conserved(k2, mdt, kappa, a):
        fa, fn = orig(k2, mdt, kappa, a)
        fa = fa.copy()
        fa[0, 0] = F32(1.001)
        return fa, fn

    def weight_squared(phi):
        w = np.clip((phi + F32(1.0)) * F32(0.5), 0, 1).astype(F32)
        return (w * w).astype(F32)

    def weight_inverted(phi):
        return (F32(1.0) - np.clip((phi + F32(1.0)) * F32(0.5), 0, 1)).astype(F32)

    with patched(im, spec_factor=no_nonlinear_term):
        expect_fail("cubic (nonlinear) term dropped", test_single_mode_rate)
    with patched(im, spec_factor=kappa_sign_flipped):
        expect_fail("gradient-energy sign flipped", test_single_mode_rate)
    with patched(im, spec_factor=mean_not_conserved):
        expect_fail("k = 0 bin scaled", test_mean_conserved_no_flow)
    with patched(im, blend_weight=weight_inverted):
        expect_fail("blend weight inverted", test_blend_identities)
    with patched(im, blend_weight=weight_squared):
        expect_fail("blend weight not linear in phi", test_plain_blend_divergence)
    with patched(fm, PERIODIC=False):
        expect_fail("advection clamps instead of wrapping", test_advection_is_periodic)


if __name__ == "__main__":
    sys.exit(run(globals()))
