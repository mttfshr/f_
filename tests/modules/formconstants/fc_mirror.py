"""fc_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_formconstants module.

The RENDER-RESOLUTION sibling of f_wc (spec: .specify/f_formconstants/spec.md):
same Wilson-Cowan model class, but the coupling convolution is a real-space
separable Gaussian blur at render resolution (the webgpgpu
WC_Example_10_fullscreen pipeline) instead of f_wc's 256^2 spectral chain.

State texture (float32 end to end -- the source's 8-bit EncodeFloat quantization
is deliberately NOT mirrored): R = E, G = I, B = Ve, A = Vi (habituation carry,
pinned to 0 at habituation = 0, the f_wc G5 bit-preservation rule).

Settled constants: the Example-10 coupling set (.specify/f_formconstants Record):
  AEE=10.5 AIE=8.5 AEI=12 AII=3, HE=2 HI=3.5, TE=10 TI=20, dt0=1.
  The source's slow square-wave bias s (period ~147 frames, 0.6 half-duty,
  E-input only) is PARKED pending the T002 sustain measurement -- spike_fc_sustain
  carries it as an explicit option.

Two blur paths, deliberately:
  - blur_axis / blur_state: the EXACT discrete kernel the codebox will compute
    (radius ceil(3*sigma), normalized exp(-i^2/2 sigma^2) weights, wrap) --
    used by tests and anything verified against the GPU.
  - blur_state_fft: the continuous (untruncated) Gaussian via FFT -- the fast
    path for multi-thousand-frame soak runs; NOT the bench reference.
"""
from dataclasses import dataclass

import numpy as np

F32 = np.float32

# ------------------------------------------------------- settled constants
# T002/T003 measurements (2026-10-24, recorded in tasks.md): the Example-10
# fullscreen page's own constants (10.5/8.5/12/3, He 2, Ne=0, s square wave)
# DO NOT sustain at float32 -- they live on 8-bit quantization decorrelation
# plus the s kick. Nothing in this model class is a steady state (Psychedelic
# saturates too) -- the sustaining corner is PSYCHEDELIC COUPLINGS +
# HABITUATION (Ve/Vi subtractive adaptation, ~0.3) + Ne = 0.75, measured
# healthy past 6000 frames at fine grain.
AEE, AIE = 16.1, 14.5          # couplings into the E sigmoid (+E, -I)
AEI, AII = 13.7, 13.0          # couplings into the I sigmoid (+E, -I)
HE, HI = 3.1, 3.5              # sigmoid thresholds
TE, TI = 4.0, 12.5             # time constants (I slower than E)
DT0 = 1.0
SIG_RATIO = 1.45               # default aspect: sigma_E = sigma_I / SIG_RATIO
SIG_FLOOR = F32(0.75)          # px floor so the truncated kernel never degenerates

# Retinotopic map (f_wc FR-007; the HTML-parity corner, r_soft softened)
K_ECC = F32(1.0)
K_ANG = F32(1.0)
R0 = F32(0.003)
R_SOFT = F32(0.35)
R_MAX = F32(4.0)               # visual radius at the image corner (baked)


@dataclass(frozen=True)
class Params:
    rate: float = 1.0          # dt multiplier (dt = rate * DT0)
    grain: float = 0.00137     # sigma_I as a fraction of min(h, w)
                               #   (default: the measured fine-web corner,
                               #    sigma_I ~ 0.7 px at 512, ~1.5 px at 1080)
    aspect: float = SIG_RATIO  # sigma_E = sigma_I / aspect
    energy: float = 0.75       # per-frame noise amplitude Ne (T002: load-bearing)
    drive_gain: float = 0.0
    excite: float = 0.0        # shared offset inside both sigmoid inputs (f_wc G7)
    habituation: float = 0.3   # Ve/Vi subtractive depth -- LOAD-BEARING at fine
                               #   grain (without it the field saturates by ~3k
                               #   frames; G1: dial in v1, nonzero default)
    aie: float = AIE
    aii: float = AII

    @property
    def dt(self):
        return F32(self.rate * DT0)


def sigmas_px(h, w, P):
    """sigma_I / sigma_E in screen pixels from the frame-fraction grain dial
    (FR-002), with the degenerate-kernel floor (Edge Cases)."""
    si = max(F32(P.grain) * F32(min(h, w)), SIG_FLOOR)
    return si, si / F32(P.aspect)


def F(x):
    """Logistic sigmoid, clamped so exp() can never overflow float32."""
    return 1.0 / (1.0 + np.exp(-np.clip(x, F32(-60.0), F32(60.0))))


# ------------------------------------------------------------------ blur stage

def gauss_taps(sig):
    """The exact codebox kernel: radius ceil(3*sigma), weights
    exp(-i^2 / (2 sigma^2)), normalized. sigma=0 -> delta."""
    sig = float(sig)
    if sig <= 1e-6:
        return np.array([1.0], dtype=F32)
    r = int(np.ceil(3.0 * sig))
    i = np.arange(-r, r + 1, dtype=F32)
    w = np.exp(-(i * i) / F32(2.0 * sig * sig))
    return (w / w.sum()).astype(F32)


def blur_axis(field, sigma, axis):
    """Separable Gaussian along one axis, wrap boundary, float32: the exact
    discrete sum the blur_x / blur_y codeboxes compute (FR-002)."""
    taps = gauss_taps(sigma)
    r = (len(taps) - 1) // 2
    out = np.zeros_like(field, dtype=F32)
    for i, wgt in enumerate(taps):
        out = out + F32(wgt) * np.roll(field, i - r, axis=axis)
    return out.astype(F32)


def blur_state(state, h, w, P):
    """The blur pair on the state: R (E) at sigma_E, G (I) at sigma_I.
    Returns (2, h, w) float32: [conv E, conv I]."""
    si, se = sigmas_px(h, w, P)
    ce = blur_axis(blur_axis(state[..., 0], se, 0), se, 1)
    ci = blur_axis(blur_axis(state[..., 1], si, 0), si, 1)
    return np.stack([ce, ci]).astype(F32)


def _fft_gauss_multipliers(h, w, sigma):
    """Continuous-Gaussian Fourier gain exp(-2 pi^2 sigma^2 (fx^2+fy^2)) --
    the fast soak path, deliberately NOT the codebox reference (no truncation)."""
    if sigma <= 1e-6:
        return np.ones((h, w), dtype=F32)
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.fftfreq(w)[None, :]
    return np.exp(F32(-2.0 * np.pi * np.pi * sigma * sigma) *
                  (fx * fx + fy * fy)).astype(F32)


def blur_state_fft(state, h, w, P):
    si, se = sigmas_px(h, w, P)
    ge = _fft_gauss_multipliers(h, w, se)
    gi = _fft_gauss_multipliers(h, w, si)
    ce = np.fft.ifft2(np.fft.fft2(state[..., 0]) * ge).real
    ci = np.fft.ifft2(np.fft.fft2(state[..., 1]) * gi).real
    return np.stack([ce, ci]).astype(F32)


# ------------------------------------------------------------------ nl stage

def seed_state(h, w, seed, amp=F32(1.0)):
    """Load/reset reseed (FR-004 -- never zero, never uniform rest)."""
    rng = np.random.default_rng(seed)
    t = np.zeros((h, w, 4), dtype=F32)
    t[..., 0] = rng.random((h, w), dtype=F32) * amp
    t[..., 1] = rng.random((h, w), dtype=F32) * amp
    return t


def nonlinear_step(conv, state, dt, P, noise=None, driv=F32(0.5), s=F32(0.0)):
    """The nl update (FR-003). conv = blur_state{,_fft} output [conv E, conv I].
    noise: fresh N(0,1) per frame, sqrt(dt)-scaled, amplitude P.energy, added
    to BOTH sigmoid inputs (f_wc's load-bearing mechanism; T002 decides the
    default amplitude -- Example 10 injects none). driv = drive texture value
    (0.5 neutral when unconnected). s = the parked Example-10 square-wave bias
    (E input only) for the T002 comparison runs."""
    t = np.clip(state, F32(-1e30), F32(1e30))
    t[~np.isfinite(t)] = 0.0                         # NaN zap (f_ks precedent)
    e, i = t[..., 0], t[..., 1]
    ce, ci = conv[0], conv[1]
    nz = F32(0.0) if (noise is None or P.energy == 0.0) \
        else F32(P.energy) * noise * F32(np.sqrt(dt))
    drv = F32(P.drive_gain) * (F32(driv) - F32(0.5))
    ae = F(AEE * ce - F32(P.aie) * ci - HE + s + nz + drv
           - F32(P.habituation) * t[..., 2] + F32(P.excite))
    ai = F(AEI * ce - F32(P.aii) * ci - HI + nz
           - F32(P.habituation) * t[..., 3] + F32(P.excite))
    out = t.copy()
    out[..., 0] = e + (ae - e) * F32(dt / TE)
    out[..., 1] = i + (ai - i) * F32(dt / TI)
    if P.habituation == 0.0:
        out[..., 2] = 0.0                            # pinned: bit-preserving
        out[..., 3] = 0.0
    else:
        out[..., 2] = t[..., 2] + (out[..., 0] - t[..., 2]) * F32(dt / 50.0)
        out[..., 3] = t[..., 3] + (out[..., 1] - t[..., 3]) * F32(dt / 100.0)
    out[~np.isfinite(out)] = 0.0
    return out.astype(F32)


def fc_frame(state, P, rng=None, driv=F32(0.5), s=F32(0.0), fast_blur=False):
    """One full frame: blur pair -> nl. fast_blur picks the FFT soak path."""
    h, w = state.shape[0], state.shape[1]
    conv = (blur_state_fft if fast_blur else blur_state)(state, h, w, P)
    noise = None if rng is None else rng.standard_normal((h, w)).astype(F32)
    return nonlinear_step(conv, state, P.dt, P, noise=noise, driv=driv, s=s)


def run(state0, P, frames, seed=None, driv=F32(0.5), s_fn=None,
        fast_blur=True, trace_every=0):
    """Multi-frame run. seed=None -> deterministic (no per-frame noise), which
    is the T002 experiment's point. s_fn: frame index -> bias value (the parked
    Example-10 square wave). Returns (state, trace) where trace is a dict of
    per-frame [E-mean, E-std, I-mean] lists when trace_every > 0."""
    state = state0
    rng = np.random.default_rng(seed) if seed is not None else None
    trace = {"em": [], "es": [], "im": []}
    for fr in range(frames):
        s = F32(s_fn(fr)) if s_fn else F32(0.0)
        state = fc_frame(state, P, rng, driv=driv, s=s, fast_blur=fast_blur)
        if trace_every and (fr % trace_every == 0 or fr == frames - 1):
            trace["em"].append(float(state[..., 0].mean()))
            trace["es"].append(float(state[..., 0].std()))
            trace["im"].append(float(state[..., 1].mean()))
    return state, trace


def ex10_square_wave(fr):
    """The source's bias: s = 0.6 half-duty, period 1000/6.8 ~ 147 frames."""
    return 0.6 if np.sin(fr * np.pi * 6.8 / 500.0) > 0 else 0.0


# ------------------------------------------------------------------ enc stage

def _smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def encode(state, out_size, sharp=F32(0.5), contrast=F32(1.0),
           k_ecc=K_ECC, k_ang=K_ANG, r0=R0, r_soft=R_SOFT):
    """The retinotopic render (FR-007): bare complex log with foveal softening,
    bilinear periodic sample of the E channel (exact-enough at 1:1 res; the GPU
    uses hardware LINEAR since state grid == render grid), then f_wc's
    contrast + sharp display map. Returns (H, W, 4) float32 luma, alpha 1."""
    H, W = out_size
    ys, xs = np.mgrid[0:H, 0:W].astype(F32)
    px = (xs / W * 2 - 1) * R_MAX
    py = (ys / H * 2 - 1) * R_MAX
    r = np.hypot(px, py)
    th = np.arctan2(py, px)
    # u (eccentricity) = ROWS, v (angle) = COLUMNS (the f_wc mirror convention)
    u = k_ecc * np.log(1.0 + np.sqrt(r * r + r_soft * r_soft) / r0)
    v = k_ang * th
    cu = (u / F32(2 * np.pi)) % 1.0
    cv = (v / F32(2 * np.pi)) % 1.0
    h, w = state.shape[0], state.shape[1]
    fx = cv * w - 0.5
    fy = cu * h - 0.5
    x0 = np.floor(fx).astype(int) % w
    y0 = np.floor(fy).astype(int) % h
    x1 = (x0 + 1) % w
    y1 = (y0 + 1) % h
    tx = (fx - np.floor(fx)).astype(F32)
    ty = (fy - np.floor(fy)).astype(F32)
    e = state[..., 0]
    lum = ((1 - ty) * ((1 - tx) * e[y0, x0] + tx * e[y0, x1])
           + ty * ((1 - tx) * e[y1, x0] + tx * e[y1, x1]))
    soft = np.clip((np.clip(lum, 0, 1) - 0.5) * contrast + 0.5, 0, 1)
    crisp = _smoothstep(F32(0.46), F32(0.54), soft)
    lum = (1 - sharp) * soft + sharp * crisp
    out = np.zeros((H, W, 4), dtype=F32)
    out[..., 0] = out[..., 1] = out[..., 2] = lum.astype(F32)
    out[..., 3] = 1.0
    return out


# ------------------------------------------------------------------ metrics

def structure_factor_metrics(field):
    """Radial structure-factor summary of E: peak wavelength in pixels,
    peak prominence (peak ring energy / median ring energy), and an
    anisotropy proxy (energy concentration in the top Fourier direction).
    Used by the lambda calibration (T003) and resize invariance (T005)."""
    x = field - field.mean()
    ps = np.abs(np.fft.fftshift(np.fft.fft2(x))) ** 2
    h, w = ps.shape
    cy, cx = h // 2, w // 2
    ys, xs = np.mgrid[0:h, 0:w]
    rr = np.hypot(ys - cy, xs - cx)
    rmax = min(cy, cx)
    ring = np.zeros(rmax)
    counts = np.zeros(rmax)
    ri = rr.astype(int)
    m = ri < rmax
    np.add.at(ring, ri[m], ps[m])
    np.add.at(counts, ri[m], 1.0)
    ring /= np.maximum(counts, 1)
    if rmax < 8:
        return {"lambda_px": 0.0, "prominence": 1.0, "anisotropy": 0.0}
    lo = 3     # skip DC and the largest scales (windowing)
    peak_r = lo + int(np.argmax(ring[lo:]))
    med = np.median(ring[lo:]) + 1e-12
    prominence = float(ring[peak_r] / med)
    lambda_px = float((2.0 * min(h, w)) / 2.0 / peak_r)  # cycles -> px per wavelength
    # anisotropy: keep the angular wedge (pi/12) around the peak direction
    band = rr > lo
    yy, xx = np.nonzero(band)
    vals = ps[band]
    ang = np.arctan2(yy - cy, xx - cx)
    # top direction = weighted barycenter of the strongest 1% magnitudes
    thr = np.percentile(vals, 99)
    sel = vals > thr
    vx = float(np.sum(vals[sel] * np.cos(ang[sel])))
    vy = float(np.sum(vals[sel] * np.sin(ang[sel])))
    aniso = float(np.hypot(vx, vy) / (vals[sel].sum() + 1e-12))
    return {"lambda_px": lambda_px, "prominence": prominence,
            "anisotropy": aniso, "peak_r": int(peak_r)}


def lambda_px(field):
    """Correct wavelength-from-peak-ring: lambda = N / r_peak."""
    m = structure_factor_metrics(field)
    h = field.shape[0]
    r = m["peak_r"] if m["peak_r"] > 0 else 1
    return float(h) / float(r)
