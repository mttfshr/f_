"""ks_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_ks module
(spec: .specify/f_ks/spec.md; reference experiment: tests/records/spike_ks_stability.py,
copied to inputs/f_ks/. The experiment is prior art, not ground truth: it runs float64
with np.fft and np.roll; this mirror is float32, stage by stage, the way a pix chain
would compute it).

PDE (spec/FR-004, the Ceyron/exponax convention):
    u_t + 0.5*|grad u|^2 + lap u + lap^2 u = 0   on a periodic L x L square.
Linear part integrated exactly per Fourier bin (rate = K2 - K2^2), the 0.5|grad u|^2
nonlinearity applied explicitly in real space on the stepped field (FR-004), the k = 0
bin zeroed every step (FR-005), effective dt clamped by rate (FR-006), state seeded
from noise (FR-003), output bounded (FR-008).

Pass chain (one function = one future codebox pass; every texture read inside a stage
goes through gpu_sim.nearest / sample, never an array index):

    seed_state -> [frame loop]  fwd_dft -> spec_stage -> inv_dft_real
                             -> nonlinear_step -> (state feeds back)
                             -> encode (display outlet)
    rate_to_dt computes the frame's dt before the passes.

Texture packing (float32 RGBA):
    state / linear field   R = u, G = B = 0, A = 1
    spectral                R,G = Re,Im of u-hat
    display                 R = G = B = clamped encode of u, A = 1

Domain: periodic; wavevectors are signed bin indices times 2*pi/L. The spectral rate
K2 - K2^2 is a function of the signed index squared, so the Nyquist bin is unambiguous.
Real/imaginary residue after the inverse DFT and the non-finite cleanup follow the
f_vf_fluid ix-cleanup precedent (keep the real part, zap non-finite values).
"""
from dataclasses import dataclass, replace

import numpy as np

from dft_mirror import fft2_passes, ifft2_passes
from gpu_sim import F32, TWOPI, grid, nearest, sample, store_float32, texture


U_CAP = F32(100.0)             # state containment bound in the nl stage (codebox_nl.gen); far above the measured |u|


@dataclass(frozen=True)
class Params:
    rate: float = 0.5           # dial 0..1: scales the effective per-frame dt (FR-006)
    dt0: float = 0.05           # per-frame dt at rate = 1 (Matt, 2026-10-21; the notebook's 0.1 is above the measured ceiling)
    ceiling: float = 0.0625     # backstop: largest dt that survived at N = 128 and 256, L = 50 (ks-lbm-3); passed in, never a fixed fact (FR-006)
    L: float = 50.0             # domain size; DX = L / N
    amp: float = 1.0            # seed noise amplitude (FR-003)
    zero_mean: bool = True      # the k = 0 fix (FR-005); mandatory, exposed for tests only
    fast_fft: bool = False      # False = the pass_dft chain (what the GPU will do); True = np.fft (long runs only)

    def with_(self, **kw):
        return replace(self, **kw)


def _fft2(u_re_im, fast):
    """Forward 2D transform of the packed state. fast=False: two pass_dft passes
    (the GPU's per-pixel O(N) loop). fast=True: np.fft (float64 inside), which the
    tests prove equal to the pass chain at N = 32 before any long run uses it."""
    if fast:
        out = np.zeros_like(u_re_im)
        z = np.fft.fft2(u_re_im[..., 0].astype(np.float64) + 1j * u_re_im[..., 1])
        out[..., 0], out[..., 1] = z.real, z.imag
        return out
    return fft2_passes(u_re_im)


def _ifft2(u_re_im, fast):
    if fast:
        out = np.zeros_like(u_re_im)
        z = np.fft.ifft2(u_re_im[..., 0].astype(np.float64) + 1j * u_re_im[..., 1])
        out[..., 0], out[..., 1] = z.real, z.imag
        return out
    return ifft2_passes(u_re_im)


# ------------------------------------------------------------------ small passes

def seed_state(h, w, seed, amp=1.0):
    """Pass (runs on load/reset only, not per frame; FR-003): fill the state texture
    with fresh noise; never from zero, because u = 0 is a fixed point. Uniform noise
    in [-amp, amp] in R, A = 1."""
    rng = np.random.default_rng(seed)
    t = texture(h, w)
    t[..., 0] = (rng.uniform(-1.0, 1.0, (h, w)) * amp).astype(F32)
    t[..., 3] = F32(1.0)
    return store_float32(t)


def rate_to_dt(rate, dt0, ceiling):
    """Pure scalar pass: effective dt = min(rate * dt0, ceiling) (FR-006). The
    ceiling is an argument, not a constant: measuring it is a later wave."""
    return min(F32(rate) * F32(dt0), F32(ceiling))


def signed_bins(h, w):
    """This texel's signed bin index along x and y (index - N on the upper half),
    per texel: what a codebox computes from floor(norm * dim) — not `cell`."""
    _, _, cx, cy = grid(h, w)
    mx = np.where(cx < F32(0.5) * F32(w), cx, cx - F32(w)).astype(F32)
    my = np.where(cy < F32(0.5) * F32(h), cy, cy - F32(h)).astype(F32)
    return mx, my


def k2_tex(h, w, L):
    """Per-texel K2 = kx^2 + ky^2 with kx = 2*pi*kx_index/L, assembled from this
    texel's own bin indices."""
    mx, my = signed_bins(h, w)
    kx = TWOPI / F32(L) * mx
    ky = TWOPI / F32(L) * my
    return (kx * kx + ky * ky).astype(F32)


# ------------------------------------------------------------------ frame passes

def fwd_dft(state, fast=False, bug=None):
    """Stages 1-2, two passes. Forward separable DFT of the state, one pass along x
    and one along y (reads every input texel once per pass); writes Re,Im of u-hat
    to R,G."""
    tex = texture(*state.shape[:2])
    tex[..., 0] = state[..., 0]
    return _fft2(tex, fast)


def spec_stage(uh, dt, L, zero_mean=True, bug=None):
    """Stage 3. Multiply each texel by exp((K2 - K2^2) * dt), using this texel's own
    bin indices, and zero the k = 0 bin (FR-005; not a toggle, exposed for tests)."""
    k2 = k2_tex(*uh.shape[:2], L)
    rate = k2 * (F32(1.0) - k2)                    # K2 - K2^2, from the bin indices
    if bug == "rate_flip":
        rate = -rate
    g = np.exp(rate * F32(dt)).astype(F32)
    if zero_mean:
        g[0, 0] = F32(0.0)                         # the DC bin ONLY (bin 0, 0)
    return store_float32(uh * g[..., None])


def inv_dft_real(uh, fast=False):
    """Stages 4-5, two passes. Inverse separable DFT, then KEEP THE REAL PART in R,
    zero the imaginary residue, and replace any non-finite value by 0 (the
    f_vf_fluid ix-cleanup precedent: a NaN in a feedback loop is forever)."""
    tex = _ifft2(uh, fast)
    out = np.zeros_like(tex)
    x = tex[..., 0]
    out[..., 0] = np.where(np.isfinite(x), x, F32(0.0))
    out[..., 3] = F32(1.0)
    return store_float32(out)


def grad_squares(u, dx, bug=None):
    """Stage 6a. Central-difference gradient of the field in R: four sample() reads
    per pixel at the texel centres one texel away on each side. Out-of-range reads
    go through the pix-to-pix coordinate wrap, which IS the periodic domain (a texel
    centre is never on a seam). Returns (ux, uy), not squared."""
    h, w = u.shape[:2]
    nx, ny, _, _ = grid(h, w)
    inv_dx = F32(1.0) / F32(dx)
    sx = F32(1.0) / F32(w)                      # one texel along x
    sy = F32(1.0) / F32(h)                      # one texel along y
    ux = (sample(u, nx + sx, ny, oob="wrap_coord")[..., 0]
          - sample(u, nx - sx, ny, oob="wrap_coord")[..., 0]) * (F32(0.5) * inv_dx)
    uy = (sample(u, nx, ny + sy, oob="wrap_coord")[..., 0]
          - sample(u, nx, ny - sy, oob="wrap_coord")[..., 0]) * (F32(0.5) * inv_dx)
    if bug == "grad_half_texel":
        # a plausible transcription slip: the reads land half a texel off, so the
        # coordinate is the texel EDGE, not the centre
        ux = (sample(u, nx + F32(0.5) * sx, ny)[..., 0]
              - sample(u, nx - F32(0.5) * sx, ny)[..., 0]) * (F32(0.5) * inv_dx)
        uy = (sample(u, nx, ny + F32(0.5) * sy)[..., 0]
              - sample(u, nx, ny - F32(0.5) * sy)[..., 0]) * (F32(0.5) * inv_dx)
    return ux, uy


def nonlinear_step(u_lin, dt, dx, bug=None):
    """Stage 6. u_new = u_lin - dt * 0.5 * (ux^2 + uy^2), the 0.5*|grad u|^2
    nonlinearity applied explicitly in real space on the linear-step result
    (central-difference gradient; FR-004)."""
    ux, uy = grad_squares(u_lin, dx, bug=bug)
    q = ux * ux + uy * uy
    out = np.zeros_like(u_lin)
    out[..., 0] = u_lin[..., 0] - F32(dt) * F32(0.5) * q
    out[..., 3] = F32(1.0)
    if bug == "nl_sign":
        out[..., 0] = u_lin[..., 0] + F32(dt) * F32(0.5) * q
    if bug == "grad_half":
        out[..., 0] = u_lin[..., 0] - F32(dt) * q
    # containment (FR-008; codebox_nl.gen): zap non-finite / |x| >= 1e30 to 0, then clamp to +-U_CAP.
    # Inactive in normal running (|u| is 15 to 20 at the dt ceiling); a backstop for the feedback loop.
    x = out[..., 0]
    x = np.where(np.abs(x) < F32(1e30), x, F32(0.0))
    out[..., 0] = np.clip(x, -U_CAP, U_CAP).astype(F32)
    return store_float32(out)


def encode(u, bug=None):
    """Stage 7 (display outlet). Bounded placeholder encode, chosen here because the
    final mapping is a Phase 2 tier-3 decision (FR-008): a hard clamp of the
    half-range map R = clamp(0.5 + 0.25*u, 0, 1), replicated to G and B, A = 1. The
    solver state itself never goes through this clamp."""
    e = texture(*u.shape[:2])
    e[..., 0] = np.clip(F32(0.5) + F32(0.25) * u[..., 0], 0.0, 1.0)
    e[..., 1] = e[..., 0]
    e[..., 2] = e[..., 0]
    e[..., 3] = F32(1.0)
    return store_float32(e)


def ks_frame(state, p, bug=None):
    """One full frame: rate_to_dt, forward DFT, spectral step (DC zeroed), inverse
    DFT, real-space nonlinearity. Returns (new_state, display). The new state feeds
    the next frame; dx = L / N from the state's own width."""
    dt = rate_to_dt(p.rate, p.dt0, p.ceiling)
    h, w = state.shape[:2]
    uh = spec_stage(fwd_dft(state, p.fast_fft, bug=bug), dt, p.L, p.zero_mean, bug=bug)
    u_lin = inv_dft_real(uh, p.fast_fft)
    u_new = nonlinear_step(u_lin, dt, dx=p.L / w, bug=bug)
    return store_float32(u_new), encode(u_new)