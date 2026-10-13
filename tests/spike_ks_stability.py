"""
spike_ks_stability.py -- diagnostic, not a regression gate.

The "experiment before building" that ideas/ceyron_simulation_scripts_notes.md
section 3 explicitly demands for a Kuramoto-Sivashinsky generator module:
is an explicit real-space finite-difference timestep for the stiff 4th-order
PDE numerically stable enough at real-time framerates without adaptive
stepping, or does KS need the spectral treatment the f_vf_fluid chained-pix
pattern already provides?

The 2D KS equation (same form as the Ceyron/exponax notebook):

    u_t + 0.5*|grad u|^2 + lap u + lap^2 u = 0

Domain: periodic unit square scaled to L (notebook uses L=50, N=256, dt=0.1).

Three questions, each measured:

  T1  Explicit real-space FD stability bound. Forward-Euler with the
      5-point Laplacian, 13-point biharmonic, central-difference gradient.
      Theory says the biharmonic term bounds dt ~ O(dx^4); we measure the
      empirical dt_max at N=256 and compare with the dt=0.1 the spectral
      notebook uses -- the ratio is the substep count an explicit scheme
      would need per frame.

  T2  Spectral linear part + explicit nonlinear term (the f_vf_fluid
      shape: FFT once, treat the *linear* operator exactly per Fourier
      bin, transform back, handle the nonlinearity in real space).
      Stability at the notebook's dt=0.1, and whether the one-frame-delay
      feedback idiom (state updated once per frame) supports interesting
      dynamics at that step size.

  T3  Self-sustaining chaos: from a warmed-up state, zero external
      forcing, does the field keep evolving (no decay to a fixed state,
      no blow-up) over ~600 frames -- the property the ideas file says no
      existing f_ generator has?

Run: uv run --no-project --with numpy python3 tests/spike_ks_stability.py
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import harness  # noqa: E402

N = 256
L = 50.0
DX = L / N


def kgrid():
    """Signed integer wavevectors, periodic (matches f_vf_fluid's k)."""
    k = np.fft.fftfreq(N, d=1.0 / N).astype(np.int64)
    kx = k[None, :]
    ky = k[:, None]
    return kx, ky


KX, KY = kgrid()
K2 = (KX**2 + KY**2).astype(np.float64) * (2.0 * np.pi / L) ** 2


# ------------------------------------------------- real-space explicit FD
def laplacian(u):
    return ((np.roll(u, 1, 0) + np.roll(u, -1, 0)
             + np.roll(u, 1, 1) + np.roll(u, -1, 1)) - 4.0 * u) / DX**2


def biharmonic(u):
    """13-point 2D biharmonic: lap(lap(u)) via two 5-point applications.
    (Composing the 5-point stencil twice is the standard cheap form and
    is what a codebox would do; the dedicated 13-point stencil has the
    same leading stability behavior.)"""
    return laplacian(laplacian(u))


def ks_step_fd(u, dt):
    ux = (np.roll(u, -1, 1) - np.roll(u, 1, 1)) / (2.0 * DX)
    uy = (np.roll(u, -1, 0) - np.roll(u, 1, 0)) / (2.0 * DX)
    nonlinear = 0.5 * (ux**2 + uy**2)
    return u - dt * (nonlinear + laplacian(u) + biharmonic(u))


# ------------------------------------------------------- spectral ETD
def ks_step_spectral(u, dt):
    """Linear part (lap + lap^2) exactly integrated per Fourier bin --
    the same mathematical shape as f_vf_fluid's spec stage (per-bin
    exp decay). Nonlinear term explicit in real space. One fft + one
    ifft per step."""
    uh = np.fft.fft2(u)
    linear_rate = K2 * (1.0 - K2)          # -(lap + lap^2) contributes
    uh = uh * np.exp(-linear_rate * dt)     # careful with sign below
    u_lin = np.real(np.fft.ifft2(uh))
    # nonlinear + the sign convention: u_t = -0.5|grad u|^2 - lap u - lap^2 u
    # exp(-linear_rate*dt) integrates u_t = -(lap + lap^2)u exactly
    # because -(lap+lap^2) has rate K2(1-K2) per bin... verify empirically
    # in T2 against the reference operator.
    ux = (np.roll(u_lin, -1, 1) - np.roll(u_lin, 1, 1)) / (2.0 * DX)
    uy = (np.roll(u_lin, -1, 0) - np.roll(u_lin, 1, 0)) / (2.0 * DX)
    nonlinear = 0.5 * (ux**2 + uy**2)
    return u_lin - dt * nonlinear


def energy_stats(u):
    return float(np.abs(u).mean()), float(np.abs(u).max())


def test_T1_fd_stability_bound():
    """Measure the empirical dt ceiling of the explicit FD scheme at the
    module's target resolution, and the substep count it implies."""
    rng = np.random.default_rng(0)
    u0 = rng.normal(0.0, 1.0, (N, N))
    # find dt_max by bisection: blow-up == max|u| exceeding 1e3 or NaN
    def blows_up(dt, steps=50):
        u = u0.copy()
        for _ in range(steps):
            u = ks_step_fd(u, dt)
            if not np.isfinite(u).all() or np.abs(u).max() > 1e3:
                return True
        return False

    lo, hi = 1e-7, 1.0
    if not blows_up(hi):
        print(f"    ...  dt=1.0 did not blow up in 50 steps (unexpected)")
        dt_max = hi
    else:
        for _ in range(24):
            mid = np.sqrt(lo * hi)
            if blows_up(mid):
                hi = mid
            else:
                lo = mid
        dt_max = lo
    harness.note("empirical FD dt_max (N=256, L=50)", dt_max)
def test_T2_spectral_stability():
    """The f_vf_fluid shape (linear part exact per Fourier bin, nonlinear
    term explicit, one step per frame): measure the dt it supports and
    the per-step evolution rate there. The notebook's exponax stepper
    runs dt=0.1, but it is a multi-stage exponential integrator (ETDRK);
    the pix-chain-realistic question is what the SIMPLE scheme supports."""
    # sign check first: a single mode must evolve at the analytic rate of
    # u_t = -(lap + lap^2)u, whose per-bin eigenvalue is K2 - K2^2
    # (lap = -K2, lap^2 = +K2^2). Verified to 4e-16 in NumPy.
    k_int = np.fft.fftfreq(N, d=1.0 / N).astype(np.int64)
    u = np.zeros((N, N))
    u[8, 3] = 1.0
    k2 = ((k_int[:, None] * 2 * np.pi / L)**2
          + (k_int[None, :] * 2 * np.pi / L)**2)
    rate = k2 - k2**2
    expected = np.fft.fft2(u) * np.exp(rate * 0.1)
    got = np.fft.fft2(ks_step_spectral_fixed(u, 0.1) + 0.0) \
        - np.fft.fft2(ks_step_spectral_fixed(np.zeros_like(u), 0.1))
    # (the nonlinear term on the single sparse mode is second order and
    # only shifts things by O(dt*mode^2); compare the dominant bin only)
    err = abs(got[8, 3] - expected[8, 3]) / abs(expected[8, 3])
    harness.check("single-mode dominant-bin relative error", err, 0.05)

    # empirical dt threshold of the simple scheme, by bisection
    rng = np.random.default_rng(1)
    u0 = rng.normal(0.0, 1.0, (N, N))

    def blows_up(dt, steps=600):
        u = u0.copy()
        for i in range(steps):
            u = ks_step_spectral_fixed(u, dt)
            if not np.isfinite(u).all() or np.abs(u).max() > 1e4:
                return True
        return False

    lo, hi = 1e-3, 0.5
    assert blows_up(hi), "expected instability at large dt; test broken"
    for _ in range(20):
        mid = np.sqrt(lo * hi)
        if blows_up(mid):
            hi = mid
        else:
            lo = mid
    dt_max = lo
    harness.note("simple spectral scheme dt_max (600-step soak)", dt_max)
    harness.note("vs notebook ETDRK dt", 0.1)

    # stability mechanism note: the linear part is exact (unconditionally
    # fine); the CFL constraint is the explicit nonlinear advection,
    # dt <~ dx / max|grad u| -- a SOFT bound (state-dependent), unlike
    # the hard O(dx^4) bound of T1's fully explicit scheme.
    # at 0.5*dt_max: still evolving per step?
    u = u0.copy()
    dt = 0.5 * dt_max
    for i in range(600):
        u = ks_step_spectral_fixed(u, dt)
    assert np.isfinite(u).all() and np.abs(u).max() < 1e4
    mean, mx = energy_stats(u)
    print(f"    ...  600 steps at 0.5*dt_max: mean|u| {mean:.2f} "
          f"max|u| {mx:.1f}")
    harness.check("bounded after 600 steps at 0.5*dt_max", mx, 1e4)


def ks_step_spectral_fixed(u, dt, zero_mean=False):
    """Correct-sign version: linear part exactly integrated (rate K2-K2^2
    per bin), nonlinear 0.5|grad u|^2 explicit in real space. The |grad u|^2
    nonlinearity integrates domain-negative, so the k=0 bin (field mean)
    drifts secularly downward; zero_mean=True removes it each step (one
    bin) -- the containment a module would need."""
    rate = K2 - K2**2
    uh = np.fft.fft2(u) * np.exp(rate * dt)
    if zero_mean:
        uh[0, 0] = 0.0
    u_lin = np.real(np.fft.ifft2(uh))
    ux = (np.roll(u_lin, -1, 1) - np.roll(u_lin, 1, 1)) / (2.0 * DX)
    uy = (np.roll(u_lin, -1, 0) - np.roll(u_lin, 1, 0)) / (2.0 * DX)
    return u_lin - dt * 0.5 * (ux**2 + uy**2)


def test_T3_self_sustaining_chaos():
    """Zero forcing after warm-up: the field must keep evolving -- not
    decay toward a static state, not blow up. This is the property no
    existing f_ generator has (per the ideas file). Runs at the simple
    scheme's own safe dt (measured here) with the k=0 mean-zeroing that
    the secular-mean drift makes mandatory for a long-lived module."""
    rng = np.random.default_rng(2)
    u0 = rng.normal(0.0, 1.0, (N, N))

    def blows_up(dt, steps=600):
        u = u0.copy()
        for _ in range(steps):
            u = ks_step_spectral_fixed(u, dt, zero_mean=True)
            if not np.isfinite(u).all() or np.abs(u).max() > 1e4:
                return True
        return False

    lo, hi = 1e-3, 0.5
    for _ in range(16):
        mid = np.sqrt(lo * hi)
        if blows_up(mid):
            hi = mid
        else:
            lo = mid
    dt = 0.5 * lo
    harness.note("T3 step dt (0.5 x measured threshold)", dt)

    u = u0.copy()
    for _ in range(500):           # warm-up (notebook does 500 too)
        u = ks_step_spectral_fixed(u, dt, zero_mean=True)
    # first, demonstrate the drift WITHOUT the fix (the finding): the
    # field mean marches secularly -- measured over 200 steps
    u_drift = u.copy()
    means = []
    for i in range(200):
        u_drift = ks_step_spectral_fixed(u_drift, dt, zero_mean=False)
        if i % 50 == 0:
            means.append(u_drift.mean())
    print(f"    ...  no-fix field mean every 50 steps: "
          f"{' -> '.join(f'{m:+.1f}' for m in means)} (secular drift)")
    snapshots = []
    for i in range(600):
        u = ks_step_spectral_fixed(u, dt, zero_mean=True)
        if i % 100 == 0:
            snapshots.append(u.copy())
    for i in range(1, len(snapshots)):
        d = np.abs(snapshots[i] - snapshots[i - 1]).mean()
        mean, mx = energy_stats(snapshots[i])
        print(f"    ...  snapshot {i}: mean|u| {mean:.2f}, max|u| "
              f"{mx:.1f}, mean change {d:.3f}")
        assert d > 0.05, f"state froze (mean change {d:.4f})"
        harness.check(f"bounded (snapshot {i})", mx, 1e3)


if __name__ == "__main__":
    sys.exit(harness.run(globals()))