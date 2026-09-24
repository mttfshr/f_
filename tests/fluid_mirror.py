"""
fluid_mirror.py -- NumPy mirror of every f_vf_fluid stage, pass for pass, in
float32 (plan ADR-1/-5/-6, .specify/f_vf_fluid/).

Chain:   pass -> adv -> fx -> fy -> spec -> iy -> ix -> enc      (ix -> pass)
  adv   self-advect the velocity state (PERIODIC bilinear) and add force
  fx/fy forward separable DFT            (test_fft_separable.pass_dft)
  spec  projection blend + exact viscosity/drag decay
  iy/ix inverse DFT; ix keeps only the real part and zaps non-finite values
  enc   periodic bilinear upsample, gain, clamp, f_vecfield encode, bypass gate

Texture packing (float32 RGBA):
  velocity state   R = u, G = 0, B = v, A = 0      (decoded f_vecfield units)
  spectral         R,G = Re,Im of u-hat;  B,A = Re,Im of v-hat
  force / outlet   f_vecfield: RG = 0.5 + 0.5 * value, B = 0.5, A = 1

Domain: periodic unit square; wavevector k = 2*pi*signed_index.

Mutation hooks: the helpers wavenumbers(), decay(), project_vec() and the
module flag PERIODIC are looked up at call time so tests can patch them to
prove the tests bite (tasks.md T010).

Run the tests:  tests/run.sh tests/test_fluid_mirror.py
"""
from dataclasses import dataclass, replace

import numpy as np

from gpu_sim import F32, TWOPI, grid, sample, store_float32
from test_fft_separable import fft2_passes, ifft2_passes

PERIODIC = True          # mutation hook: False = clamp-to-edge interpolation


@dataclass(frozen=True)
class Params:
    dt: float = 0.01            # self-advection step and decay exponent
    force: float = 0.02         # velocity gained per frame at full-scale force
    viscosity: float = 0.0      # physical nu
    project: float = 1.0        # 0 = compressible, 1 = divergence-free
    drag: float = 0.0           # linear damping mu
    gain: float = 1.0           # output scale before encoding
    src_vecfield: float = 1.0   # 1 = force inlet connected
    bypass_gate: float = 0.0    # 1 = pass the force through

    def with_(self, **kw):
        return replace(self, **kw)


def mix(a, b, t):
    """GenExpr mix(): exact at t = 0 and t = 1 (bench-verified for
    f_vf_warp's bypass)."""
    t = F32(t)
    return a * (F32(1.0) - t) + b * t


# ------------------------------------------------------------------ helpers

def wavenumbers(h, w):
    """(kx, ky, k2, kxo, kyo). kx, ky, k2 are the full wavenumbers (used for
    the decay). kxo, kyo are the OPERATOR wavenumbers used by projection:
    odd functions of the bin index, so they must vanish at the Nyquist bin
    (|idx| = N/2), otherwise real-field (Hermitian) symmetry breaks and the
    output gains an imaginary part (plan ADR-5)."""
    _, _, cx, cy = grid(h, w)
    mx = np.where(cx < F32(w) * F32(0.5), cx, cx - F32(w)).astype(F32)
    my = np.where(cy < F32(h) * F32(0.5), cy, cy - F32(h)).astype(F32)
    kx, ky = TWOPI * mx, TWOPI * my
    k2 = kx * kx + ky * ky
    kxo = np.where(np.abs(mx) == F32(w) * F32(0.5), F32(0), kx).astype(F32)
    kyo = np.where(np.abs(my) == F32(h) * F32(0.5), F32(0), ky).astype(F32)
    return kx, ky, k2, kxo, kyo


def decay(k2, nu, mu, dt):
    """Exact viscous decay and linear drag in one factor."""
    return np.exp(-(F32(nu) * k2 + F32(mu)) * F32(dt)).astype(F32)


def project_vec(ur, ui, vr, vi, kxo, kyo):
    """Helmholtz projection: remove the component of (u, v) parallel to k."""
    k2o = kxo * kxo + kyo * kyo
    inv = np.where(k2o > 0, F32(1.0) / np.maximum(k2o, F32(1e-30)), F32(0.0))
    dr = (kxo * ur + kyo * vr) * inv
    di = (kxo * ui + kyo * vi) * inv
    return ur - kxo * dr, ui - kxo * di, vr - kyo * dr, vi - kyo * di


def interp(tex, u, v):
    """Bilinear sample, periodic (the flow domain is a torus)."""
    return sample(tex, u, v, wrap=PERIODIC)


def energy(state):
    return float(np.mean(state[..., 0].astype(np.float64) ** 2
                         + state[..., 2].astype(np.float64) ** 2))


def neutral(h, w):
    t = np.zeros((h, w, 4), F32)
    t[..., :3] = F32(0.5)
    t[..., 3] = F32(1.0)
    return t


# ------------------------------------------------------------------- stages

def adv(state, force, dt, force_gain, src_vecfield):
    """Stage 1. Backward self-advection (semi-Lagrangian) then add force.
    `force` is a render-res f_vecfield texture, or None (unconnected)."""
    h, w = state.shape[:2]
    nx, ny, _, _ = grid(h, w)
    u, v = state[..., 0], state[..., 2]
    a = interp(state, nx - u * F32(dt), ny - v * F32(dt))
    out = np.zeros((h, w, 4), F32)
    out[..., 0], out[..., 2] = a[..., 0], a[..., 2]
    if force is not None and src_vecfield >= 0.5:
        f = sample(force, nx, ny)
        out[..., 0] += F32(force_gain) * ((f[..., 0] - F32(0.5)) * F32(2.0))
        out[..., 2] += F32(force_gain) * ((f[..., 1] - F32(0.5)) * F32(2.0))
    return store_float32(out)


def spec(tex, viscosity, project, drag, dt):
    """Stage 4. Projection blend, then decay exp(-(nu*|k|^2 + mu)*dt)."""
    h, w = tex.shape[:2]
    _, _, k2, kxo, kyo = wavenumbers(h, w)
    ur, ui, vr, vi = tex[..., 0], tex[..., 1], tex[..., 2], tex[..., 3]
    pr, pi_, qr, qi = project_vec(ur, ui, vr, vi, kxo, kyo)
    ur, ui, vr, vi = (mix(ur, pr, project), mix(ui, pi_, project),
                      mix(vr, qr, project), mix(vi, qi, project))
    g = decay(k2, viscosity, drag, dt)
    return store_float32(np.stack([ur * g, ui * g, vr * g, vi * g], -1))


def ix_cleanup(tex):
    """Stage 6 tail. Keep the real parts, drop numerical imaginary residue,
    replace non-finite values by 0 (a NaN in the feedback loop is forever)."""
    out = np.zeros_like(tex)
    for src, dst in ((0, 0), (2, 2)):
        x = tex[..., src]
        out[..., dst] = np.where(np.isfinite(x), x, F32(0.0))
    return store_float32(out)


def enc(force, velocity, gain, bypass_gate, src_vecfield, size=None):
    """Stage 7 (render resolution). `force` = render-res f_vecfield or None;
    `size` = (h, w) of the output when force is None."""
    h, w = force.shape[:2] if force is not None else size
    nx, ny, _, _ = grid(h, w)
    vel = interp(velocity, nx, ny)
    half = F32(0.5)
    e = np.zeros((h, w, 4), F32)
    e[..., 0] = half + half * np.clip(F32(gain) * vel[..., 0], -1, 1)
    e[..., 1] = half + half * np.clip(F32(gain) * vel[..., 2], -1, 1)
    e[..., 2] = half
    e[..., 3] = F32(1.0)
    neut = neutral(h, w)
    gated = force if (force is not None and src_vecfield >= 0.5) else neut
    return store_float32(mix(e, gated, bypass_gate))


# --------------------------------------------------------------------- FFT

def fft2_np(tex):
    """Fast forward 2D FFT in the spectral packing (float64 inside, float32
    out). Asserted equal to fft2_passes in the tests."""
    out = np.zeros_like(tex)
    for c in (0, 2):
        z = np.fft.fft2(tex[..., c].astype(np.float64) + 1j * tex[..., c + 1])
        out[..., c], out[..., c + 1] = z.real, z.imag
    return out


def ifft2_np(tex):
    out = np.zeros_like(tex)
    for c in (0, 2):
        z = np.fft.ifft2(tex[..., c].astype(np.float64) + 1j * tex[..., c + 1])
        out[..., c], out[..., c + 1] = z.real, z.imag
    return out


# -------------------------------------------------------------------- step

def step(state, force, p, fft="np"):
    """One frame of the solver: pass -> adv -> fx -> fy -> spec -> iy -> ix.
    Returns the new velocity state. `fft` = "np" (fast) or "passes" (the
    real pass_dft mirror)."""
    fwd, inv = (fft2_np, ifft2_np) if fft == "np" else (fft2_passes, ifft2_passes)
    a = adv(state, force, p.dt, p.force, p.src_vecfield)
    s = spec(fwd(a), p.viscosity, p.project, p.drag, p.dt)
    return ix_cleanup(inv(s))


def zero_state(n):
    return np.zeros((n, n, 4), F32)
