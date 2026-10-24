"""wc_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_wc module
(spec: .specify/f_wc/spec.md, settled model from the Phase-0 records
tests/records/spike_wc_noise_regions.py / spike_wc_regions.py / wc_retinotopy.py).
float32, stage by stage, the way a pix chain will compute it.

The settled model (Phase 0, 2026-10-23, from Michael Rule's working webgpgpu
Wilson-Cowan port; the noise-ablation is in tests.md T005):

    E += (F(AEE*(K_E conv E) - AIE*(K_I conv I) - HE + Ne*noise
            + drive_gain*(drive - 0.5)) - E) * dt / TE
    I += (F(AEI*(K_E conv E) - AII*(K_I conv I) - HI + Ne*noise) - I) * dt / TI

F logistic sigmoid; K_E, K_I Gaussians in PIXEL units (spectrally
exp(-sigma^2 k^2 / 2) per Fourier bin, no DC zeroing, no separate decay term --
the relaxation toward F carries the decay); `noise` is FRESH Gaussian noise
EVERY FRAME (Box-Muller * sqrt(dt), one field shared by both sigmoid inputs --
the load-bearing mechanism; without it the pattern collapses to uniform).
The drive term is E-only (T007: adding to I is identical but unnecessary).

Pass chain (one function = one future codebox pass; every texture read inside a
stage goes through gpu_sim.nearest / sample, never an array index):

    seed_state -> [frame loop]  fwd_dft -> spec_stage -> inv_dft_real
                             -> nonlinear_step -> (state feeds back)
                             -> encode (display outlet)
    rate_to_dt computes the frame's dt before the passes.

Texture packing (float32 RGBA) -- the f_vf_fluid two-complex-field packing, so
ONE separable DFT chain carries BOTH WC fields:

    state        R = E (real), B = I (real), G = A = 0
    spectral     R,G = Re,Im of E-hat; B,A = Re,Im of I-hat
    convolved    R = K_E conv E, B = K_I conv I (real parts, residue zapped)
    display      R = G = B = mapped E (placeholder until gate G4), A = 1

Domain: periodic N x N sheet; wavenumbers are ANGULAR per texel
(k = 2*pi*signed_index / N; the Nyquist bin is unambiguous because the kernel
gains depend on k^2). sigma in PIXELS: sigma_E = sigma_I / 1.45 (the Psychedelic
2/2.9 aspect ratio), sigma_I = the `texture` dial (default 1.4, the
G3-verified corner: Ne = 1.0, sigma_I = 1.4).
"""
from dataclasses import dataclass, replace

import numpy as np

from dft_mirror import fft2_passes, ifft2_passes
from gpu_sim import F32, TWOPI, grid, nearest, store_float32, texture

# ------------------------------------------------------- settled constants
AEE, AIE = 16.1, 14.5          # couplings into the E sigmoid (+E, -I)
AEI, AII = 13.7, 13.0          # couplings into the I sigmoid (+E, -I)
HE, HI = 3.1, 3.5              # sigmoid thresholds (load-bearing)
TE, TI = 4.0, 12.5             # time constants (I slower than E)
SIG_RATIO = 1.45               # sigma_E = sigma_I / SIG_RATIO (2 / 2.9)

# Retinotopic map constants (wc_retinotopy.py defaults; provisional per T006 --
# the foveal/edge handling and any user exposure is T033)
R0 = F32(0.5)                  # foveal regularization radius
K_ECC = F32(8.0)               # eccentricity gain (cortical units per log-ecc)
K_ANG = F32(5.0)               # angular gain (cortical units per radian)
R_MAX = F32(4.0)               # visual radius at the image corner


@dataclass(frozen=True)
class Params:
    rate: float = 0.5          # dial 0..1: scales the per-frame dt (dt = rate * dt0)
    dt0: float = 1.0           # per-frame dt at rate = 1 (the spikes' run unit)
    texture: float = 1.4       # sigma_I in pixels (the grain dial; FR-010)
    ne: float = 1.0            # per-frame noise amplitude (the drive; G3 corner)
    drive_gain: float = 0.0    # scene strength; 0 = free US-1 labyrinth (G3)
    zero_mean: bool = False    # NOT a property of this model (KS-specific);
                               #   kept as an explicit False for tests only
    fast_fft: bool = False     # False = the pass_dft chain (what the GPU will
                               #   do); True = np.fft (long runs only)

    def with_(self, **kw):
        return replace(self, **kw)

    @property
    def sig_i(self):
        return self.texture

    @property
    def sig_e(self):
        return self.texture / SIG_RATIO


def _fft2(tex, fast):
    """Forward 2D transform of the packed state: R,G = Re,Im of E-hat AND
    B,A = Re,Im of I-hat (one chain, both fields -- the template handles two
    complex fields per pass). fast=False: two pass_dft passes (the GPU's
    per-pixel O(N) loop); fast=True: np.fft (float64 inside)."""
    if fast:
        out = np.zeros_like(tex)
        for c in (0, 2):
            z = np.fft.fft2(tex[..., c].astype(np.float64)
                            + 1j * tex[..., c + 1])
            out[..., c], out[..., c + 1] = z.real, z.imag
        return out
    return fft2_passes(tex)


def _ifft2(tex, fast):
    if fast:
        out = np.zeros_like(tex)
        for c in (0, 2):
            z = np.fft.ifft2(tex[..., c].astype(np.float64)
                             + 1j * tex[..., c + 1])
            out[..., c], out[..., c + 1] = z.real, z.imag
        return out
    return ifft2_passes(tex)


def F(x):
    """Logistic sigmoid, clamped so exp() can never overflow float32 (the
    settled form; with it + the relaxation step no NaN ceiling exists)."""
    return 1.0 / (1.0 + np.exp(-np.clip(x, F32(-60.0), F32(60.0))))


# ------------------------------------------------------------------ small passes

def seed_state(h, w, seed, amp=F32(1.0)):
    """Pass (runs on load/reset only, not per frame; FR-004/FR-009): fill the
    state with fresh INDEPENDENT uniform noise in R = E and B = I (two hash
    channels of the noise stage); G = A = 0 (the imaginary parts stay zero).
    Range [0, amp]: the settled seed (uniform 0..1 in the records); never from
    zero, never from uniform rest (it is a fixed point of the whole update)."""
    rng = np.random.default_rng(seed)
    t = texture(h, w)
    t[..., 0] = (rng.random((h, w), dtype=F32) * amp)
    t[..., 2] = (rng.random((h, w), dtype=F32) * amp)
    return store_float32(t)


def rate_to_dt(rate, dt0):
    """Pure scalar pass: effective dt = rate * dt0. NO clamp/ceiling: unlike KS
    there is no NaN ceiling (exact relaxation + bounded sigmoid); the rate
    ceiling is pattern-preservation and is a tier-3 tuning decision (T030)."""
    return F32(rate) * F32(dt0)


def signed_bins(h, w):
    """This texel's signed bin index along x and y (index - N on the upper
    half), per texel: what a codebox computes from floor(norm * dim)."""
    _, _, cx, cy = grid(h, w)
    mx = np.where(cx < F32(0.5) * F32(w), cx, cx - F32(w)).astype(F32)
    my = np.where(cy < F32(0.5) * F32(h), cy, cy - F32(h)).astype(F32)
    return mx, my


def k2_tex(h, w):
    """Per-texel K2 = kx^2 + ky^2 in ANGULAR per-texel wavenumbers
    (k = 2*pi*signed_index / N). sigma is in pixels, so the domain IS texels;
    angular units are the load-bearing part (a cycles-unit k2 under-smooths the
    kernels by (2*pi)^2 -- the spike's 2026-10-22 bug)."""
    mx, my = signed_bins(h, w)
    kx = TWOPI * mx / F32(w)
    ky = TWOPI * my / F32(h)
    return (kx * kx + ky * ky).astype(F32)


# ------------------------------------------------------------------ frame passes

def fwd_dft(state, fast=False):
    """Stages 1-2, two passes. Forward separable DFT of the state, one pass
    along x and one along y; writes Re,Im of E-hat to R,G and of I-hat to B,A
    (both fields in one chain)."""
    return _fft2(state, fast)


def spec_stage(uh, sig_e, sig_i):
    """Stage 3. Per-bin Gaussian kernel gains, REAL per field:
    KE = exp(-sig_e^2 k^2 / 2) multiplies the E pair (R,G), KI =
    exp(-sig_i^2 k^2 / 2) the I pair (B,A). NO other multiplier (no decay
    term, no KS k=0 zeroing): the conv step IS the linear step."""
    k2 = k2_tex(*uh.shape[:2])
    ge = np.exp(F32(-0.5) * F32(sig_e) * F32(sig_e) * k2).astype(F32)
    gi = np.exp(F32(-0.5) * F32(sig_i) * F32(sig_i) * k2).astype(F32)
    g = np.stack([ge, ge, gi, gi], axis=-1)
    return store_float32(uh * g)


def inv_dft_real(uh, fast=False):
    """Stages 4-5, two passes. Inverse separable DFT, then KEEP THE REAL PARTS:
    R = K_E conv E, B = K_I conv I, imaginary residue zeroed, non-finite values
    zapped to 0 (the f_vf_fluid ix-cleanup precedent: a NaN in a feedback loop
    is forever)."""
    tex = _ifft2(uh, fast)
    out = np.zeros_like(tex)
    for c in (0, 2):
        x = tex[..., c]
        out[..., c] = np.where(np.isfinite(x), x, F32(0.0))
    return store_float32(out)


def noise_tex(h, w, rng, dt):
    """Noise stage (runs EVERY frame -- salt increments per draw, not just on
    reset; the per-frame drive is the load-bearing mechanism, T005). One fresh
    Gaussian field in R, shared by both sigmoid inputs: Box-Muller *
    sqrt(dt), the scaling that makes dt a pure relaxation step."""
    na = rng.random((h, w), dtype=F32) * F32(0.999) + F32(0.0001)
    nb = rng.random((h, w), dtype=F32) * F32(0.999) + F32(0.0001)
    nx = (np.sqrt(F32(-2.0) * np.log(na)) * np.cos(TWOPI * nb)
          * np.sqrt(F32(dt)))
    t = texture(h, w)
    t[..., 0] = nx
    return store_float32(t)


def drive_tex(h, w, value=F32(0.5)):
    """The drive inlet texture. Unconnected = the library's mid-gray read 0.5,
    which makes drive_gain*(value - 0.5) = 0 for free (G3: no special-casing).
    Tests pass a real scene (uniform or structured) in R."""
    t = texture(h, w)
    t[..., 0] = value
    return store_float32(t)


def nonlinear_step(conv, state, noise, driv, dt, ne, drive_gain):
    """Stage 6 (the heart, `nl`, 4 inlets on the bench: in1 = convolved fields
    R = cE, B = cI; in2 = raw state R = E, B = I; in3 = the per-frame noise;
    in4 = the drive). Exact relaxation toward the sigmoid of the coupled
    drive; the drive term is E-only (T007), the noise term goes into BOTH
    sigmoid inputs (same field, the Rule form)."""
    ce, ci = conv[..., 0], conv[..., 2]
    e, i_ = state[..., 0], state[..., 2]
    nx, drv = noise[..., 0], driv[..., 0]
    fdt_e = F32(dt) / F32(TE)
    fdt_i = F32(dt) / F32(TI)
    ae = F(F32(AEE) * ce - F32(AIE) * ci - F32(HE)
           + F32(ne) * nx + F32(drive_gain) * (drv - F32(0.5)))
    ai = F(F32(AEI) * ce - F32(AII) * ci - F32(HI) + F32(ne) * nx)
    out = np.zeros_like(state)
    out[..., 0] = e + (ae - e) * fdt_e
    out[..., 2] = i_ + (ai - i_) * fdt_i
    for c in (0, 2):
        x = out[..., c]
        out[..., c] = np.where(np.isfinite(x), x, F32(0.0))
    return store_float32(out)


# ------------------------------------------------------------------ frame loop

def wc_frame(state, rng, P, driv=None):
    """One full frame of the chain at Params P. driv: an (h, w, 4) texture or
    None (None = the unconnected inlet's mid-gray: zero net drive)."""
    h, w = state.shape[:2]
    dt = rate_to_dt(P.rate, P.dt0)
    if driv is None:
        driv = drive_tex(h, w)
    nz = noise_tex(h, w, rng, dt)
    conv = inv_dft_real(spec_stage(fwd_dft(state, P.fast_fft),
                                   P.sig_e, P.sig_i), P.fast_fft)
    return nonlinear_step(conv, state, nz, driv, dt, P.ne, P.drive_gain)


def run_temporal(state0, P, frames, seed=1, driv=None):
    """Deterministic per-frame-noise run: the rng is seeded per RUN so a test
    is reproducible while the field itself is stochastic (the mechanism)."""
    rng = np.random.default_rng(seed)
    state = state0.copy()
    for _ in range(frames):
        state = wc_frame(state, rng, P, driv=driv)
    return state


# ------------------------------------------------------------------ encode

def _tap4(tex, cxu, cyu):
    """Manual periodic 4-tap bilinear of tex[..., 0] at texel-fraction coords
    (cxu, cyu) (the f_ks enc sampling shape; exact at any output size where
    hardware sample() would snap, and the periodic wrap IS the cortical sheet
    in both axes)."""
    n = tex.shape[0]
    x0 = np.floor(cxu).astype(F32)
    y0 = np.floor(cyu).astype(F32)
    tx = (cxu - x0).astype(F32)
    ty = (cyu - y0).astype(F32)
    xa = np.mod(x0, n)
    xb = np.mod(x0 + 1.0, n)
    ya = np.mod(y0, n)
    yb = np.mod(y0 + 1.0, n)
    def at(x, y):
        return tex[y.astype(int) % n, x.astype(int) % n, 0]
    p00 = at(xa, ya)
    p10 = at(xb, ya)
    p01 = at(xa, yb)
    p11 = at(xb, yb)
    return ((p00 * (1.0 - tx) + p10 * tx) * (1.0 - ty)
            + (p01 * (1.0 - tx) + p11 * tx) * ty).astype(F32)


def encode(state, out_size, sharp=F32(0.0), h=None, w=None):
    """Stage 7 (`enc`, runs at RENDER resolution, @adapt 0): the inverse
    retinotopic map. Each output pixel's visual-field polar coords (r, theta)
    map to cortical (u, v) = (K_ECC*log1p(r/R0), K_ANG*theta), and the E field
    is 4-tap sampled there (periodic both axes). Display mapping PLACEHOLDER
    until gate G4: E is already a 0..1 rate, soft = clamp(E, 0, 1); `sharp`
    blends toward the f_ks crisp S-curve. Non-finite E maps to 0 (the codebox
    zaps it upstream; belt and braces)."""
    o = out_size
    h = h or state.shape[0]
    w = w or state.shape[1]
    n = state.shape[0]
    nx, ny, _, _ = grid(o, o)
    px = (nx * F32(2.0) - F32(1.0)) * R_MAX
    py = (ny * F32(2.0) - F32(1.0)) * R_MAX
    r = np.hypot(px, py).astype(F32)
    theta = np.arctan2(py, px).astype(F32)
    u = (K_ECC * np.log1p(r / R0)).astype(F32)             # log(1 + r / r0)
    v = (K_ANG * theta).astype(F32)
    cu = np.mod(u / TWOPI, F32(1.0)) * n
    cv = np.mod(v / TWOPI, F32(1.0)) * n
    # record convention (wc_retinotopy.render): u (eccentricity) = cortical
    # ROWS, v (angle) = cortical COLUMNS
    e = _tap4(state, cv, cu)
    e = np.where(np.isfinite(e), e, F32(0.0))
    soft = np.clip(e, F32(0.0), F32(1.0))
    crisp = _smoothstep(F32(0.46), F32(0.54), soft)
    lum = (soft * (F32(1.0) - F32(sharp)) + crisp * F32(sharp)).astype(F32)
    out = texture(o, o)
    out[..., 0] = out[..., 1] = out[..., 2] = lum
    out[..., 3] = F32(1.0)
    return store_float32(out)


def _smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return (t * t * (3.0 - 2.0 * t)).astype(F32)
