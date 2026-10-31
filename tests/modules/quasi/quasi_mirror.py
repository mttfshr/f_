"""
quasi_mirror.py -- NumPy mirror of the settled f_quasi model (.specify/stable/f_quasi/spec.md,
"Settled model"), written BEFORE the codebox exists. The mirror is the spec in executable
form; T020 writes the codebox against it and the bench diffs the GPU against it.

The module is a stateless pure generator: every output is a function of the texel-centre
coordinates (gpu_sim.grid) and the Params only. No texture is read.

Model (N = 5 orientations, M = 7 octaves, q = frame-height units, centred):
    e_i    = zoom + i                            i = 0 .. M-1,  zoom wrapped to [0, 1)
    s_i    = exp(e_i * ln 2)                     (GenExpr has exp, no exp2)
    w_i    = exp(-0.5 * ((e_i - 3) / envelope)^2)
    phi_k  = k * pi / N + angle
    beta_k = frac(exp(pi * k))                   LITERALS in the codebox (see below)
    psi_ik = beta_k * s_i + 2 pi dw + (cos phi_k * x + sin phi_k * y) * 2 pi B s_i
                                                 dw = frac(drift): ONE phase in TURNS shared by every octave
                                                 (T002), so the offset is exactly periodic in drift. It used to be
                                                 scaled by 2^i (the octave's slot in the loop); the zoom wrap
                                                 re-indexes the octaves, so that jumped the pattern at every wrap
                                                 while drift was non-zero (fixed 2026-10-30)
    P      = sum_i w_i sum_k cos(psi_ik) / (N * sum_i w_i)               in [-1, 1]
    grad P = -2 pi B sum_i w_i s_i sum_k sin(psi_ik) dir_k / (N * sum_i w_i)
    v      = -sum_i w_i s_i sum_k sin(psi_ik) dir_k / (N * sum_i w_i s_i)  |v| <= 1 (gate G2)

Conventions fixed here (open in the spec, decided at T001; see tasks.md record):
  - Unit: FRAME HEIGHT. x = (norm_x - 0.5) * aspect, y = norm_y - 0.5 (isotropic, FR-011),
    so `density` B is cycles per frame HEIGHT at scale 1 (the spec table said width).
  - y is not flipped (texture rows run down); only the orientation set's handedness depends
    on it, and the set is symmetric under reflection up to the fixed betas.
  - beta_k must be float64 literals: float32 exp(4 pi) = 2.9e5 has an ulp of 0.031.

Nyquist hook (T005 decides the shape): `fade=dict(px=H, start=cpp0, end=0.5, mode="smooth"|"hard",
renorm=True|False)` multiplies octave i's weight by a factor of its cycles per pixel
cpp_i = B * s_i / px (the octave's spatial frequency in cycles per output pixel). `renorm`
keeps the denominators over the faded weights (contrast preserved); otherwise they stay over
the unfaded weights (amplitude falls with the fade).

`bug` values are the mutations the tests must catch:
  "grad_no_freq_factor"  the gradient omits 2 pi B s (the webgpgpu Example_31 shape),
  "source_aspect"        render scales x by aspect and divides y by aspect (not isometric),
  "vec_norm_by_w"        the vecfield divides by sum w instead of sum w s (unbounded),
  "mu_off"               the envelope centre is 2 instead of 3,
  "drift_scaled"         the drift phase is scaled by 2^i again (the pre-2026-10-30 form: it jumps at the zoom wrap).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

N_WAVES = 5
N_OCT = 7
MU = 3.0
LN2 = 0.6931471805599453
TWOPI = 2.0 * np.pi
BUGS = ("grad_no_freq_factor", "source_aspect", "vec_norm_by_w", "mu_off", "drift_scaled")


def betas(dtype=np.float64):
    """frac(exp(pi k)), k = 0..4, computed in float64 and rounded: the codebox literals."""
    k = np.arange(N_WAVES, dtype=np.float64)
    b = np.exp(np.pi * k)
    return (b - np.floor(b)).astype(dtype)


def octave_terms(zoom, envelope, dtype=np.float64, wrap=True, mu=MU):
    """Per-octave exponent e_i, weight w_i and scale s_i."""
    z = dtype(zoom)
    if wrap:
        z = z - np.floor(z)
    e = z + np.arange(N_OCT, dtype=dtype)
    w = np.exp(dtype(-0.5) * ((e - dtype(mu)) / dtype(envelope)) ** 2)
    s = np.exp(e * dtype(LN2))
    return e, w, s


def fade_factors(s, density, fade, dtype=np.float64):
    """Per-octave fade by cycles per pixel (see the module docstring)."""
    cpp = dtype(density) * s / dtype(fade["px"])
    start, end = dtype(fade.get("start", 0.25)), dtype(fade.get("end", 0.5))
    if fade.get("mode", "smooth") == "hard":
        return (cpp < start).astype(dtype)
    t = np.clip((cpp - start) / (end - start), dtype(0), dtype(1))
    return dtype(1) - t * t * (dtype(3) - dtype(2) * t)


def field(x, y, *, zoom=0.0, drift=0.0, density=4.0, envelope=0.5, angle=0.0,
          dtype=np.float32, fade=None, wrap_zoom=True, bug=None, legacy_drift=None):
    """Potential P, exact gradient (gx, gy) and bounded vecfield numerators (vx, vy) at the
    coordinates x, y (frame-height units). Returns a dict of arrays shaped like x."""
    x = np.asarray(x, dtype)
    y = np.asarray(y, dtype)
    mu = 2.0 if bug == "mu_off" else MU
    _, w, s = octave_terms(zoom, envelope, dtype, wrap=wrap_zoom, mu=mu)
    f = fade_factors(s, density, fade, dtype) if fade else np.ones(N_OCT, dtype)
    wf = w * f
    wnorm = wf.sum() if (not fade or fade.get("renorm", True)) else w.sum()
    wsnorm = (wf * s).sum() if (not fade or fade.get("renorm", True)) else (w * s).sum()
    b = betas(dtype)
    dw = dtype(drift) - np.floor(dtype(drift))           # wrapped phase in turns
    # one drift phase for every octave; the "drift_scaled" mutation restores the old 2^i scaling (exact in float32)
    pw = dtype(2) ** np.arange(N_OCT, dtype=dtype) if bug == "drift_scaled" else np.ones(N_OCT, dtype)
    twopib = dtype(TWOPI) * dtype(density)
    k = np.arange(N_WAVES, dtype=dtype)
    phi = k * dtype(np.pi / N_WAVES) + dtype(angle)
    ck, sk = np.cos(phi), np.sin(phi)
    acc_p = np.zeros_like(x)
    acc_x = np.zeros_like(x)   # sum w s sum_k sin(psi) cos(phi_k)
    acc_y = np.zeros_like(x)
    acc_wx = np.zeros_like(x)  # sum w   sum_k sin(psi) cos(phi_k)   (bug shapes only)
    acc_wy = np.zeros_like(x)
    for i in range(N_OCT):
        si, wi = s[i], wf[i]
        sum_cos = np.zeros_like(x)
        sx = np.zeros_like(x)
        sy = np.zeros_like(x)
        for kk in range(N_WAVES):
            d = ck[kk] * x + sk[kk] * y
            if legacy_drift is None:
                psi = b[kk] * si + dtype(TWOPI) * dw * pw[i] + d * (twopib * si)
            else:    # the pre-T002 form (unbounded phase scaled by s_i), kept for spike_quasi_float32's drift table
                psi = (b[kk] + dtype(legacy_drift)) * si + d * (twopib * si)
            sn = np.sin(psi)
            sum_cos += np.cos(psi)
            sx += sn * ck[kk]
            sy += sn * sk[kk]
        acc_p += wi * sum_cos
        acc_x += wi * si * sx
        acc_y += wi * si * sy
        acc_wx += wi * sx
        acc_wy += wi * sy
    n = dtype(N_WAVES)
    out = {"P": acc_p / (n * wnorm)}
    if bug == "grad_no_freq_factor":
        out["gx"] = -acc_wx / (n * wnorm)
        out["gy"] = -acc_wy / (n * wnorm)
    else:
        out["gx"] = -twopib * acc_x / (n * wnorm)
        out["gy"] = -twopib * acc_y / (n * wnorm)
    if bug == "vec_norm_by_w":
        out["vx"] = -acc_x / (n * wnorm)
        out["vy"] = -acc_y / (n * wnorm)
    else:
        out["vx"] = -acc_x / (n * wsnorm)
        out["vy"] = -acc_y / (n * wsnorm)
    return out


def banded(P, bands=5.0, dtype=np.float32):
    """FR-008: triangle fold of frac((P*0.5 + 1) * bands), raised to 1.1."""
    s = (np.asarray(P, dtype) * dtype(0.5) + dtype(1.0)) * dtype(bands)
    fr = s - np.floor(s)
    tri = np.abs(fr * dtype(2.0) - dtype(1.0))
    return np.power(tri, dtype(1.1))


def encode_vec(vx, vy, gain=1.0, dtype=np.float32):
    """f_vecfield encoding: v*gain*0.5 + 0.5, B = 0.5, A = 1 (clamped to [0, 1])."""
    r = np.clip(np.asarray(vx, dtype) * dtype(gain) * dtype(0.5) + dtype(0.5), 0, 1)
    gch = np.clip(np.asarray(vy, dtype) * dtype(gain) * dtype(0.5) + dtype(0.5), 0, 1)
    return np.stack([r, gch, np.full_like(r, 0.5), np.ones_like(r)], axis=-1).astype(dtype)


def coords(h, w, bug=None):
    """Texel-centre isotropic coordinates in frame-height units (float32)."""
    nx, ny, _, _ = g.grid(h, w)
    aspect = np.float32(w) / np.float32(h)
    x = (nx - np.float32(0.5)) * aspect
    y = ny - np.float32(0.5)
    if bug == "source_aspect":
        y = (ny - np.float32(0.5)) / aspect
    return x, y


def render(h, w, *, bands=5.0, gain=1.0, fade=None, bug=None, **params):
    """The three outlets at (h, w): returns (texture, vecfield, scalar), each (h, w, 4) float32."""
    x, y = coords(h, w, bug)
    f = field(x, y, dtype=np.float32, fade=fade, bug=bug, **params)
    look = banded(f["P"], bands)
    one = np.ones_like(look)
    tex = np.stack([look, look, look, one], axis=-1).astype(np.float32)
    sc = f["P"] * np.float32(0.5) + np.float32(0.5)
    scal = np.stack([sc, sc, sc, one], axis=-1).astype(np.float32)
    return tex, encode_vec(f["vx"], f["vy"], gain), scal
