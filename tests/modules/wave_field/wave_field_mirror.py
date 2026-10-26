"""wave_field_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_wave_field module
(spec: .specify/f_wave_field/spec.md, tasks T001-T002). Float32, stage by stage, the way a
pix chain would compute it; every texture read inside a stage goes through gpu_sim.sample.

Model (spec "Model"): u (position) and v = du/dt (velocity), real fields on a periodic unit
square (L = 1 frame width, k = 2*pi*signed bin index). Per Fourier bin the linear step is the
exact solution of  u_tt + 2 beta u_t + omega^2 u = 0  over one step dt:

    omega^2 = ring^2 + (speed * kref * (|k| / kref)^dispersion)^2
    beta    = damping + nu * |k|^2
    wd^2    = omega^2 - beta^2
    u' = E [ u cos(wd dt) + (v + beta u) sin(wd dt)/wd ]
    v' = E [ v cos(wd dt) - (omega^2 u + beta v) sin(wd dt)/wd ]        E = exp(-beta dt)

Branch-free in all three damping regimes (FR-003). With x = wd^2 dt^2 (signed):
    x > T    underdamped:   E cos(a), E sin(a)/wd,             a = sqrt(x)
    x < -T   overdamped:    the cosh / sinh forms with E FOLDED IN as exp(-(beta dt -/+ a)),
                            so float32 never forms cosh(a) of a large a (inf * 0 = NaN)
    |x| <= T critical:      Taylor series (1 - x/2 + x^2/24, dt (1 - x/6 + x^2/120)), no 0/0
The three are selected by np.where with SAFE arguments in the unused branches. The codebox
transcribes this arithmetic line by line (no function refactoring in GenExpr).

Texture packing (float32 RGBA), the f_ks chain's two complex fields:
    state     R = u, G = 0, B = v, A = 1
    spectral  R,G = Re,Im of u-hat; B,A = Re,Im of v-hat
    luma out  R = G = B = bounded map of u, A = 1
    vec out   R,G = grad u * scale * 0.5 + 0.5, B = 0.5, A = 1   (f_vecfield_type)

Per frame (spec): fwd DFT -> spectral step (DC bin of u and v zeroed, FR-005) -> inverse DFT
(real part kept) -> real-space stage: forcing into v (v += F dt), exciter, strike, edge sponge
on u and v, containment -> encode (gradient of u for the vecfield).

PROVISIONAL CONSTANTS (to be set by T003 / T004 / T005; each is a module-level name so the
later tasks change one line): KREF, NU, EX_SIGMA, EX_GAIN, STRIKE_AMP, SPONGE_WIDTH,
SPONGE_RATE, U_CAP, GRAD_SCALE, LUMA_SCALE. The time unit is seconds with dt = 1/60 per frame
by default; whether that is the shipped unit is gate G3.
"""
from dataclasses import dataclass, replace

import numpy as np

from dft_mirror import fft2_passes, ifft2_passes
from gpu_sim import F32, TWOPI, grid, sample, store_float32, texture

# ---- provisional constants (T003/T004/T005 set these) ----
KREF = F32(TWOPI * 8.0)        # reference wavenumber: mode 8 across the frame (T004)
NU = F32(1e-5)                 # fixed viscosity on |k|^2 (T004: damping time 0.15 s at the N = 256 Nyquist bin, 40 s at mode 8)
DAMPING_FLOOR = 1e-3           # lowest `damping` the dial reaches, per time unit (T003: worst float32 coefficient gain 3.3e-7/frame needs 1e-5; x100 margin)
EX_SIGMA = F32(0.02)           # exciter / strike Gaussian sigma, in frame widths (T004)
EX_GAIN = F32(165.0)           # exciter force per unit `amplitude` (T004: max|u| ~ 1 at amplitude 1, 2 Hz, speed 0.25, damping 0.3, edge 0.5)
STRIKE_AMP = F32(4.0)          # strike impulse height in u (T004: the ring is ~0.4 after 1 s; independent of `amplitude`, so amplitude 0 can still strike)
SPONGE_WIDTH = F32(0.12)       # sponge band width, in frame widths (T004: 0.12 reflects ~0.1% and absorbs ~99.5% at rate 10)
SPONGE_RATE = F32(20.0)        # peak sponge damping rate at edge = 1, per time unit (T004: edge 0.5 lands on the rate-10 optimum; stronger reflects more)
U_CAP = F32(100.0)             # containment bound on u and v (T003)
GRAD_SCALE = F32(0.05)         # vecfield tanh argument scale (G2: tanh; default gain tuned in Phase 2)
LUMA_SCALE = F32(0.5)          # luma tanh argument scale (G2: tanh; default gain tuned in Phase 2)
TAYLOR_X = F32(1e-4)           # |wd^2 dt^2| below this uses the series (critical regime)


@dataclass(frozen=True)
class Params:
    speed: float = 0.25         # phase velocity at KREF, frame widths per time unit
    damping: float = 0.0        # beta base rate (the FR-006 floor is applied by the caller / T003)
    dispersion: float = 1.0     # 1 wave, 2 plate, 0.5 deep-water-like
    ring: float = 0.0           # omega at k = 0 (resonator)
    edge: float = 0.0           # sponge strength 0..1; 0 = pure periodic wrap
    dt: float = 1.0 / 60.0      # model step per frame (time unit seconds; gate G3)
    force: float = 1.0          # gain on the force inlet
    x: float = 0.5              # exciter position
    y: float = 0.5
    frequency: float = 2.0      # exciter frequency (cycles per time unit)
    amplitude: float = 0.0      # exciter strength; 0 = free ringing
    gain: float = 1.0           # output mapping strength (G2: tanh), before the tanh
    fast_fft: bool = False      # False = the pass_dft chain; True = np.fft (long runs only)
    nu: float = float(NU)
    kref: float = float(KREF)

    def with_(self, **kw):
        return replace(self, **kw)


# ------------------------------------------------------------------ transforms

def _fft2(tex, fast, inverse=False):
    """Transform both packed complex fields (R,G) and (B,A). fast=True is np.fft in float64,
    tied to the pass chain at small N by the tests before any long run uses it."""
    if not fast:
        return ifft2_passes(tex) if inverse else fft2_passes(tex)
    out = np.zeros_like(tex)
    f = np.fft.ifft2 if inverse else np.fft.fft2
    for a, b in ((0, 1), (2, 3)):
        z = f(tex[..., a].astype(np.float64) + 1j * tex[..., b].astype(np.float64))
        out[..., a], out[..., b] = z.real, z.imag
    return store_float32(out)


def signed_k(h, w):
    """Per-texel angular wavenumbers (kx, ky) on the unit square, from this texel's own
    signed bin indices (index - N on the upper half; the Nyquist bin is negative)."""
    _, _, cx, cy = grid(h, w)
    mx = np.where(cx < F32(0.5) * F32(w), cx, cx - F32(w)).astype(F32)
    my = np.where(cy < F32(0.5) * F32(h), cy, cy - F32(h)).astype(F32)
    return (F32(TWOPI) * mx).astype(F32), (F32(TWOPI) * my).astype(F32)


# ------------------------------------------------------------------ spectral step

def step_coeffs(kmag, p):
    """The per-bin 2x2 propagator. Returns (Cc, Cs, om2, beta) where, per bin,
        u' = Cc u + Cs (v + beta u)
        v' = Cc v - Cs (om2 u + beta v)
    with Cc = E cos(wd dt) and Cs = E sin(wd dt)/wd in all three regimes."""
    dt = F32(p.dt)
    k = kmag.astype(F32)
    kref = F32(p.kref)
    c = F32(p.speed) * kref * np.power(k / kref, F32(p.dispersion)).astype(F32)
    om2 = (F32(p.ring) ** 2 + c * c).astype(F32)
    beta = (F32(max(p.damping, 0.0)) + F32(p.nu) * k * k).astype(F32)
    wd2 = (om2 - beta * beta).astype(F32)
    x = (wd2 * dt * dt).astype(F32)
    bdt = (beta * dt).astype(F32)

    under = x > TAYLOR_X
    over = x < -TAYLOR_X
    a_u = np.sqrt(np.where(under, x, F32(1.0))).astype(F32)           # safe in unused lanes
    a_o = np.sqrt(np.where(over, -x, F32(1.0))).astype(F32)
    E = np.exp(-bdt).astype(F32)

    cc_u = E * np.cos(a_u)
    cs_u = E * dt * np.sin(a_u) / a_u
    em = np.exp(-(bdt - a_o))                                          # a_o < bdt in the overdamped band
    ep = np.exp(-(bdt + a_o))
    cc_o = F32(0.5) * (em + ep)
    cs_o = dt * F32(0.5) * (em - ep) / a_o
    cc_c = E * (F32(1.0) - x * F32(0.5) + x * x * F32(1.0 / 24.0))
    cs_c = E * dt * (F32(1.0) - x * F32(1.0 / 6.0) + x * x * F32(1.0 / 120.0))

    cc = np.where(under, cc_u, np.where(over, cc_o, cc_c)).astype(F32)
    cs = np.where(under, cs_u, np.where(over, cs_o, cs_c)).astype(F32)
    return cc, cs, om2, beta


def spec_stage(sh, p):
    """Stage 3. Apply the exact per-bin step to (u-hat, v-hat), then zero the k = 0 bin of
    both (FR-005). Real and imaginary parts take the same real coefficients."""
    h, w = sh.shape[:2]
    kx, ky = signed_k(h, w)
    kmag = np.sqrt(kx * kx + ky * ky).astype(F32)
    cc, cs, om2, beta = step_coeffs(kmag, p)
    out = np.zeros_like(sh)
    for part in (0, 1):                       # 0 = real parts (R, B), 1 = imaginary (G, A)
        u, v = sh[..., part], sh[..., 2 + part]
        out[..., part] = cc * u + cs * (v + beta * u)
        out[..., 2 + part] = cc * v - cs * (om2 * u + beta * v)
    out[0, 0, :] = F32(0.0)
    return store_float32(out)


# ------------------------------------------------------------------ real-space stage

def _gauss(h, w, x, y, sigma):
    """Gaussian profile centred at (x, y) on the periodic unit square (wrapped distance)."""
    nx, ny, _, _ = grid(h, w)
    dx = nx - F32(x)
    dy = ny - F32(y)
    dx = dx - np.round(dx)
    dy = dy - np.round(dy)
    return np.exp(-(dx * dx + dy * dy) / (F32(2.0) * F32(sigma) ** 2)).astype(F32)


def sponge_rate(h, w, edge):
    """Per-texel damping rate (per time unit): zero in the interior, smoothstep up to
    edge * SPONGE_RATE at the border. Never negative, so it cannot add energy (FR-010)."""
    nx, ny, _, _ = grid(h, w)
    d = np.minimum(np.minimum(nx, F32(1.0) - nx), np.minimum(ny, F32(1.0) - ny))
    s = np.clip(F32(1.0) - d / SPONGE_WIDTH, 0.0, 1.0).astype(F32)
    return (F32(edge) * SPONGE_RATE * s * s * (F32(3.0) - F32(2.0) * s)).astype(F32)


def real_stage(state, p, force_tex=None, phase=0.0, strike=False):
    """Stage 6. state R = u, B = v from the inverse DFT. Adds forcing to v (v += F dt):
    the force inlet F = force * 2 (tex - 0.5) (FR-007, neutral at 0.5) plus the point exciter
    amplitude * EX_GAIN * sin(phase) * gaussian (FR-008); adds the strike impulse to u
    (FR-009); applies the edge sponge to u and v (FR-010); contains (zap non-finite, clamp)."""
    h, w = state.shape[:2]
    dt = F32(p.dt)
    u, v = state[..., 0].copy(), state[..., 2].copy()
    prof = _gauss(h, w, p.x, p.y, EX_SIGMA)
    f = np.zeros((h, w), F32)
    if force_tex is not None:
        f = f + F32(p.force) * F32(2.0) * (force_tex[..., 0] - F32(0.5))
    f = f + F32(p.amplitude) * EX_GAIN * F32(np.sin(phase)) * prof
    v = v + f * dt
    if strike:
        u = u + STRIKE_AMP * prof
    g = np.exp(-sponge_rate(h, w, p.edge) * dt).astype(F32)
    u, v = u * g, v * g
    out = texture(h, w)
    for ch, x in ((0, u), (2, v)):
        x = np.where(np.abs(x) < F32(1e30), x, F32(0.0))            # zap non-finite / huge
        out[..., ch] = np.clip(x, -U_CAP, U_CAP).astype(F32)
    out[..., 3] = F32(1.0)
    return store_float32(out)


def gradient(u_tex, L=1.0):
    """Central-difference gradient of u (R), four sample() reads at one texel either side;
    out-of-range reads go through the pix-to-pix coordinate wrap, which IS the periodic domain."""
    h, w = u_tex.shape[:2]
    nx, ny, _, _ = grid(h, w)
    sx, sy = F32(1.0) / F32(w), F32(1.0) / F32(h)
    inv_2dx = F32(0.5) * F32(w) / F32(L)
    inv_2dy = F32(0.5) * F32(h) / F32(L)
    ux = (sample(u_tex, nx + sx, ny, oob="wrap_coord")[..., 0]
          - sample(u_tex, nx - sx, ny, oob="wrap_coord")[..., 0]) * inv_2dx
    uy = (sample(u_tex, nx, ny + sy, oob="wrap_coord")[..., 0]
          - sample(u_tex, nx, ny - sy, oob="wrap_coord")[..., 0]) * inv_2dy
    return ux.astype(F32), uy.astype(F32)


def encode_luma(u_tex, gain=1.0):
    """G2 (Matt, 2026-10-25): tanh compression, 0.5 + 0.5 tanh(gain LUMA_SCALE u). Never clips; near
    mid-grey the slope is 0.5 gain LUMA_SCALE (the old hard clamp's 0.25 at the default)."""
    e = texture(*u_tex.shape[:2])
    e[..., 0] = F32(0.5) + F32(0.5) * np.tanh(F32(gain) * LUMA_SCALE * u_tex[..., 0])
    e[..., 1] = e[..., 0]
    e[..., 2] = e[..., 0]
    e[..., 3] = F32(1.0)
    return store_float32(e)


def encode_vec(u_tex, gain=1.0):
    """Gradient vecfield (G2: tanh): R,G = 0.5 + 0.5 tanh(gain GRAD_SCALE grad u), B = 0.5, A = 1."""
    ux, uy = gradient(u_tex)
    e = texture(*u_tex.shape[:2])
    e[..., 0] = F32(0.5) + F32(0.5) * np.tanh(F32(gain) * GRAD_SCALE * ux)
    e[..., 1] = F32(0.5) + F32(0.5) * np.tanh(F32(gain) * GRAD_SCALE * uy)
    e[..., 2] = F32(0.5)
    e[..., 3] = F32(1.0)
    return store_float32(e)


# ------------------------------------------------------------------ frame and helpers

def new_state(h, w):
    """reset: zero field (FR-009)."""
    t = texture(h, w)
    t[..., 3] = F32(1.0)
    return t


def struck_state(h, w, p, amp=1.0):
    """reset then strike on the same frame: the impulse at the exciter position, in u."""
    t = new_state(h, w)
    t[..., 0] = F32(amp) * STRIKE_AMP * _gauss(h, w, p.x, p.y, EX_SIGMA)
    return store_float32(t)


def wave_frame(state, p, force_tex=None, phase=0.0, strike=False):
    """One full frame. Returns (new_state, luma, vec, new_phase). The exciter phase
    accumulates 2 pi frequency dt per frame in the real-space stage (FR-008)."""
    tex = texture(*state.shape[:2])
    tex[..., 0] = state[..., 0]
    tex[..., 2] = state[..., 2]
    sh = spec_stage(_fft2(tex, p.fast_fft), p)
    lin = _fft2(sh, p.fast_fft, inverse=True)
    st = texture(*state.shape[:2])
    st[..., 0] = lin[..., 0]
    st[..., 2] = lin[..., 2]
    st[..., 3] = F32(1.0)
    new = real_stage(st, p, force_tex, phase, strike)
    new_phase = (phase + float(TWOPI) * p.frequency * p.dt) % float(TWOPI)
    return new, encode_luma(new, p.gain), encode_vec(new, p.gain), new_phase


def energy(state, p):
    """Real-space sum of 0.5 v^2 + 0.5 omega^2 |u|^2 evaluated per Fourier bin (Parseval), in
    float64: the conserved quantity of the undamped step."""
    h, w = state.shape[:2]
    uh = np.fft.fft2(state[..., 0].astype(np.float64))
    vh = np.fft.fft2(state[..., 2].astype(np.float64))
    kx, ky = signed_k(h, w)
    kmag = np.sqrt(kx.astype(np.float64) ** 2 + ky.astype(np.float64) ** 2)
    c = p.speed * p.kref * np.power(kmag / p.kref, p.dispersion)
    om2 = p.ring ** 2 + c * c
    return float(np.sum(0.5 * np.abs(vh) ** 2 + 0.5 * om2 * np.abs(uh) ** 2) / (h * w))
