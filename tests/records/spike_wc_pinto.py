"""
spike_wc_pinto.py -- f_wc Phase 0, task T005 (2026-10-23 redirect).

The 2026-10-22 region sweep (spike_wc_regions.py) found NO clean
rolls/hexagons in the two-field E/I sigmoid Wilson-Cowan system, and the
Wikipedia Wilson-Cowan article explains why: the documented spatial-form
mechanism is BISTABILITY + FINITE-AMPLITUDE NUCLEATION, and the variant with
documented spiral/wave solutions is the Pinto-Ermentrout ACTIVATOR-RECOVERY
system, not the E/I sigmoid system:

    du/dt = -u + ∫ w(|x-y|) H(u(y) - theta) dy  -  v  +  P
    dv/dt = eps * (beta * u  -  v)

    H = Heaviside (step firing), v = slow recovery (eps << 1),
    w(r) = A * exp(-lambda * r)  (exponential kernel, literature Ref[7]:
    A = 2.1, lambda = 1).

This spike tests the redirect: does the activator-recovery form with
finite-amplitude nucleation produce the spatial forms (target waves, spirals)
the E/I sigmoid sweep could not?

GPU carryover (the question that decides whether this helps f_wc at all):
  - the exponential kernel is diagonal in Fourier space:
    FT in 2D of A*exp(-lambda*r)  ~  A * 2*pi*lambda / (k^2 + lambda^2)^(3/2),
    so the convolution stays one spectral multiply (f_ks pattern);
  - Heaviside is a `step()` in the nonlinear codebox (CHEAPER than a
    sigmoid);
  - the recovery variable v is a third field chain (f_wc already planned
    two; the E/I split becomes a u/v split).

Seeding is the design change: not small noise (which decays to rest -- the
T005 finding), but a FINITE-AMPLITUDE BLOB that clears the Heaviside
threshold locally. A broken wavefront (a half-plane, or a blob with a piece
removed) is the classic spiral nucleation.

Offline NumPy, float32. Run: tests/run.sh tests/records/spike_wc_pinto.py
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "lib"))
sys.path.insert(0, HERE)
import harness  # noqa: E402
import wc_retinotopy as RT  # noqa: E402

# ---------------------------------------------------------------- constants
# Pinto-Ermentrout working set. The literature's point model is excitable at
# (A, lambda, theta, beta, eps) ~ (2.1, 1, 0.1-0.3, 1-3, 0.05-0.2); the
# spatial spiral papers use a domain tens of kernel widths across.
N = 256
L = 40.0                      # domain size (periodic), in kernel-width units
DX = L / N

A_K = 2.1                     # kernel amplitude (literature Ref[7])
LAMBDA = 1.0                  # kernel decay rate (kernel width ~ 1/lambda)

THETA = 0.2                   # firing threshold (Heaviside argument u - theta)
BETA = 2.0                    # recovery gain (nullcline slope)
EPS = 0.1                     # recovery slowness (eps << 1 = excitable)
P = -0.1                      # baseline drive: below threshold at rest, so the
                              #   rest state u=0, v=0 is stable (excitable)

DT = 0.05


def kgrid(n=N, dom=L):
    # ANGULAR wavenumbers (see spike_wc_solver: fftfreq is cycles, x2*pi).
    k = 2.0 * np.pi * np.fft.fftfreq(n, d=dom / n)
    kx, ky = np.meshgrid(k, k, indexing="xy")
    return kx, ky


KX, KY = kgrid()
K2 = KX**2 + KY**2


def exp_kernel_hat(n=N, dom=L, a=A_K, lam=LAMBDA):
    """FT of w(r) = a*exp(-lam*r) in 2D:  a * 2*pi*lam / (k^2 + lam^2)^(3/2).
    Normalized so the integral over the plane equals a (matches the point
    model's effective coupling)."""
    kx, ky = kgrid(n, dom)
    k2 = kx**2 + ky**2
    that = a * 2.0 * np.pi * lam / np.power(k2 + lam * lam, 1.5)
    # normalize: integral of a*exp(-lam r) over R^2 = 2*pi*a/lam^2
    that = that / (2.0 * np.pi * a / (lam * lam)) * a
    return that


K_HAT = exp_kernel_hat()


def conv(u, k_hat=K_HAT):
    return np.real(np.fft.ifft2(k_hat * np.fft.fft2(u)))


# ------------------------------------------------------------------ solver
def pe_step(u, v, dt, p=P, theta=THETA, beta=BETA, eps=EPS, a=A_K, lam=LAMBDA):
    """One frame of the Pinto-Ermentrout activator-recovery system.
    Exact linear decay on u (rate 1), explicit recovery on v; the coupling
    is the spectrally-convolved Heaviside firing of u."""
    firing = (u > theta).astype(u.dtype)         # H(u - theta)
    coupling = conv(firing, exp_kernel_hat(a=a, lam=lam))
    g = np.exp(-dt)                               # exact decay of u at rate 1
    u_new = g * u + dt * (coupling - v + p)
    v_new = v + dt * eps * (beta * u - v)
    return u_new, v_new


def run(u, v, dt, frames, **kw):
    for _ in range(frames):
        u, v = pe_step(u, v, dt, **kw)
    return u, v


def blob_seed(n=N, dom=L, radius=4.0, amp=1.0, center=None):
    """Finite-amplitude disk seed (clears theta locally). center = (x, y) in
    domain units; None = domain center."""
    if center is None:
        center = (dom / 2, dom / 2)
    x = np.arange(n) * (dom / n)
    xx, yy = np.meshgrid(x, x)
    r = np.hypot(xx - center[0], yy - center[1])
    return (amp * (r < radius)).astype(np.float32), np.zeros((n, n), np.float32)


def broken_wave_seed(n=N, dom=L, width=6.0, amp=1.0):
    """Half-plane wavefront with the top half cut away: the classic spiral
    nucleation. The cut end curls into a spiral if the medium is excitable."""
    x = np.arange(n) * (dom / n)
    xx, yy = np.meshgrid(x, x)
    wave = (xx < width) & (yy < dom / 2)
    return (amp * wave).astype(np.float32), np.zeros((n, n), np.float32)


def small_noise_seed(n=N, amp=0.05, seed=1):
    """The seeding that FAILED for the E/I system: sub-threshold noise."""
    rng = np.random.default_rng(seed)
    return (amp * rng.random((n, n))).astype(np.float32), np.zeros((n, n), np.float32)


def structure_peak(u):
    P2 = np.abs(np.fft.fft2(u - u.mean())) ** 2
    P2[0, 0] = 0.0
    idx = np.unravel_index(np.argmax(P2), P2.shape)
    return float(np.hypot(KX[idx], KY[idx]))


# -------------------------------------------------------------------- tests
def test_T005a_rest_state_stable():
    """The rest state (u=0, v=0, drive P below threshold) is stable: small
    sub-threshold noise decays back to rest. Bistability requirement #1 --
    confirmed. (This is the property that makes noise-seeding futile, matching
    the T005 E/I finding.)"""
    u, v = small_noise_seed(amp=0.05)
    u, v = run(u, v, DT, 400)
    harness.check("sub-threshold noise decays (rest is stable)", float(u.max()), 0.05)


def test_T005b_excitable_window_is_empty():
    """THE NEGATIVE RESULT. A finite blob should, in an excitable medium,
    nucleate a confined propagating pulse. Across the scanned regime it does
    NOT: the blob either collapses back to rest or ignites the whole periodic
    domain (active fraction -> 1, std -> 0). There is no localized survivor.
    Probed over P, eps, beta, a and seed radius; representative cells asserted
    here. Each cell's outcome is (active_fraction, std); 'confined' would be
    0.005 < frac < 0.9 with std > 0.03. NONE of the cells is confined."""
    cells = [  # (P, eps, seed_radius) — spread across the bistable grid
        (-0.1, 0.1, 4.0),
        (-0.3, 0.2, 4.0),
        (-0.52, 0.2, 4.0),
        (-0.6, 0.2, 4.0),
        (-0.1, 0.02, 6.0),   # slow recovery, the documented spiral regime
        (-0.45, 0.04, 6.0),
    ]
    n_confined = 0
    for P, eps, radius in cells:
        u, v = blob_seed(radius=radius, amp=1.0)
        u, v = run(u, v, DT, 2000, p=P, eps=eps)
        frac = float((u > THETA).mean())
        std = float(u.std())
        confined = (0.005 < frac < 0.9) and std > 0.03
        n_confined += confined
        harness.note(f"P={P} eps={eps} r={radius}: active={frac:.3f} std={std:.3f} "
                     f"({'CONFINED' if confined else ('all-active' if frac > 0.9 else 'collapsed')})", "")
    harness.check("confined excitable forms found across the scan (expect none)",
                  n_confined, 0)


@harness.slow
def test_T005c_no_nan_soak():
    """Bounded soak: the activator-recovery system never goes NaN (decay is
    exact, firing is bounded 0/1, recovery is linear) even at the saturating
    parameters. Structural safety carries over to a GPU port."""
    u, v = broken_wave_seed(width=6.0, amp=1.0)
    u, v = run(u, v, DT, 3000)
    harness.check("u finite after 3000 frames", bool(np.isfinite(u).all()), True)
    harness.check("v finite after 3000 frames", bool(np.isfinite(v).all()), True)


if __name__ == "__main__":
    sys.exit(harness.run(globals()))
