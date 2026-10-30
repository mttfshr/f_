"""
tf_aniso_blur_mirror.py -- NumPy mirror of the tf_aniso_blur shader: the functions (and the constants and
fixtures they need) that tests/modules/tf_aniso_blur/bench_tf_aniso_blur.py imports. Extracted
from test_tf_aniso_blur.py in Phase C, 2026-10-18; the tests stay there.
"""
import numpy as np
import gpu_sim as g  # noqa: E402

F32 = np.float32
H = W = 64

TAPS_STATIONS = 8            # per side; total taps = 1 + 2*8*3 = 49 = TAPS_MAX
SPACING_DIV = F32(8.0)       # station spacing = max(1, L / 8) px (2026-10-30): the reach grows with the same 49 taps
EPS_TRACE = F32(1e-6)
EPS_SPD = F32(1e-4)
EPS_ROOT = F32(1e-6)

# Provisional knobs (spec Parameters table; tier-3 confirms -- gates open).
S_SCALE = F32(0.5)
LENGTH = F32(4.0)
W_GATE = F32(0.5)
FLOOR = F32(0.25)
S_TMAP = F32(100.0)          # tensormap's strength dial (the G-channel echo)
S_DEC = F32(100.0)           # this module's matching decode gain (spec OQ3)

W_T0 = F32(0.5)              # discrete-Gaussian transverse rule: centre
W_T1 = F32(0.25)             # side taps (each); w0 + 2*w1 = 1


def _nxny(tex):
    return g.grid(*tex.shape[:2])[:2]


# --- mirror: the exact codebox pass --------------------------------------

def decode_raw(t_tex, s_dec):
    """Glyph plan ADR-2 decode (f_tensor_type.md outlet-0 contract), evaluated
    at own texel centres. All in DELIVERED units until /s_dec."""
    nx, ny = _nxny(t_tex)
    Jxx = g.nearest(t_tex, nx, ny)[..., 0] / F32(s_dec)
    Jxy = (g.nearest(t_tex, nx, ny)[..., 1] - F32(0.5)) * F32(2.0) / F32(s_dec)
    Jyy = g.nearest(t_tex, nx, ny)[..., 2] / F32(s_dec)
    trace = Jxx + Jyy
    diff = Jxx - Jyy
    root = np.sqrt(np.maximum(diff * diff + F32(4.0) * Jxy * Jxy, F32(0.0)))
    lam1 = F32(0.5) * (trace + root)
    lam2 = F32(0.5) * (trace - root)
    coh = np.clip(root / np.maximum(trace, EPS_TRACE), 0.0, 1.0).astype(F32)
    return Jxx, Jxy, Jyy, trace, diff, root, lam1, lam2, coh


def gates(Jxx, Jxy, Jyy, trace, root, lam1, lam2, coh,
          s_scale=S_SCALE, length=LENGTH, w_gate=W_GATE, floor=FLOOR,
          mutation=None):
    """ADR-3 gate model + the SPD/trace guard. Returns L_f, D_f, circ."""
    bad_spd = lam2 < -EPS_SPD
    if mutation == "drop_spd_guard":
        bad_spd = np.zeros_like(bad_spd)
    guard = bad_spd | (trace < EPS_TRACE)
    dir_undef = root < EPS_ROOT
    if mutation == "ratio_width":
        coh_eff = np.clip(lam2 / np.maximum(lam1, EPS_TRACE), 0.0, 1.0)
    else:
        coh_eff = coh
    w_en = np.minimum(F32(1.0), lam1 * F32(s_scale))
    l_len = F32(length) * w_en
    l_f = np.where(guard, F32(length), l_len).astype(F32)
    d_calc = (l_f * np.maximum(F32(floor), F32(1.0) - F32(w_gate) * coh_eff)).astype(F32)
    d_f = np.where(guard | dir_undef, l_f, d_calc).astype(F32)
    s_frac = np.minimum(F32(1.0), d_f / np.maximum(l_f, F32(1e-6)))
    circ = s_frac >= F32(0.999999)
    return l_f, d_f, circ


def aniso_pass(tensor, source, *, s_scale=S_SCALE, length=LENGTH, w_gate=W_GATE,
               floor=FLOOR, s_tm=S_TMAP, s_dec=S_DEC, width=F32(W), height=F32(H),
               density=1.0, flip_axis=False, mutation=None):
    """The single codebox pass, mirrored. Returns RGBA float32 (H, W, 4).

    density>1 densifies the station lattice (a mirror-side convergence
    instrument for the brute check; the shipped codebox is density 1, TAPS_MAX
    unchanged by the density -- each densified variant is a different kernel).
    """
    Hh, Ww = source.shape[:2]
    nx, ny = _nxny(source)
    if mutation == "flip_g_offset":
        t_g = g.nearest(tensor, nx, ny)[..., 1]
        Jxy = t_g * F32(2.0) / F32(s_dec)        # missing the 0.5 offset
        Jxx = g.nearest(tensor, nx, ny)[..., 0] / F32(s_dec)
        Jyy = g.nearest(tensor, nx, ny)[..., 2] / F32(s_dec)
        trace = Jxx + Jyy
        diff = Jxx - Jyy
        root = np.sqrt(np.maximum(diff * diff + F32(4.0) * Jxy * Jxy, F32(0.0)))
        lam1 = F32(0.5) * (trace + root)
        lam2 = F32(0.5) * (trace - root)
        coh = np.clip(root / np.maximum(trace, EPS_TRACE), 0.0, 1.0)
        # a flipped-offset G is not 0.5-centred: the decode goes non-SPD
        # wherever G > 0.5 -- exactly the guard-vs-trap class of failure.
    else:
        Jxx, Jxy, Jyy, trace, diff, root, lam1, lam2, coh = decode_raw(
            tensor, s_dec)

    l_f, d_f, circ = gates(Jxx, Jxy, Jyy, trace, root, lam1, lam2, coh,
                           s_scale=s_scale, length=length, w_gate=w_gate,
                           floor=floor, mutation=mutation)

    inv_root = F32(1.0) / np.maximum(root, EPS_ROOT)
    # Axis direction, half-angle WITHOUT atan2 (the doubled-angle terms give
    # (cos 2theta, sin 2theta) = (diff, 2*Jxy)/root; half them via the standard
    # identities, with the theta+180-gauge's sign(0) read as +):
    #   cos(theta) = sqrt((1 + diff/root)/2)
    #   sin(theta) = sign(2*Jxy) * sqrt((1 - diff/root)/2)
    # (verified against atan2-decode to ~1e-7 over a 3000-tensor sample and on
    # analytic axes at 0/20/45/70/90/110/135/160 deg; the sign(2*Jxy) uses
    # 2*step(0, x) - 1 so the (2*Jxy == 0) doubled-zero reads +1.)
    s_sign = F32(2.0) * ((F32(2.0) * Jxy) >= F32(0.0)).astype(F32) - F32(1.0)
    ax_x = np.sqrt(np.maximum(F32(1.0) + diff * inv_root, F32(0.0)) * F32(0.5))
    ax_y = (s_sign * np.sqrt(np.maximum(
        F32(1.0) - diff * inv_root, F32(0.0)) * F32(0.5))).astype(F32)
    vl_x = -ax_y                                  # along-edge = perpendicular
    vl_y = ax_x
    if flip_axis:                                 # gauge hook: (v, a)->(-v, -a)
        vl_x, vl_y, ax_x, ax_y = -vl_x, -vl_y, -ax_x, -ax_y
    ux = np.where(circ, F32(1.0), vl_x).astype(F32)
    uy = np.where(circ, F32(0.0), vl_y).astype(F32)
    tx = np.where(circ, F32(0.0), ax_x).astype(F32)
    ty = np.where(circ, F32(1.0), ax_y).astype(F32)

    inv_ll2 = F32(2.0) / np.maximum(l_f * l_f, F32(1e-12))   # 2/L^2
    sig_d = np.maximum(F32(0.5) * d_f, F32(1e-6)).astype(F32)  # D/2 px
    step_mass = F32(1.0 / density)                # quadrature per-step mass
    # Station spacing (2026-10-30), from the pixel's own semi-length: 1 px up to L = 8 (the kernel as shipped before),
    # then L/8 px so the 49 taps keep a constant quarter-sigma step and the reach grows with Length (up to 48).
    spacing = (np.ones_like(l_f) if mutation == "no_spacing"
               else np.maximum(F32(1.0), l_f / SPACING_DIV)).astype(F32)

    acc = np.zeros((Hh, Ww, 4), F32)
    wsum = np.zeros((Hh, Ww), F32)

    # centre tap
    acc += g.sample(source, np.clip(nx, F32(0.5) / width, F32(1.0) - F32(0.5) / width),
                    np.clip(ny, F32(0.5) / height, F32(1.0) - F32(0.5) / height))
    wsum += F32(1.0)

    n_station = int(round(TAPS_STATIONS * density))
    for k in range(1, n_station + 1):
        umag = (F32(k - 0.5) / F32(density) * spacing).astype(F32)
        for sgn in (F32(1.0), F32(-1.0)):
            u = sgn * umag
            g_u = (np.exp(-(u * u) * inv_ll2) * step_mass).astype(F32)
            for tsign in (F32(0.0), F32(1.0), F32(-1.0)):
                t = tsign * sig_d                 # 0, +D/2, -D/2 px
                wgt = (g_u * np.where(tsign == F32(0.0), F32(W_T0),
                                      F32(W_T1))).astype(F32)
                ox = (u * ux + t * tx) / width
                oy = (u * uy + t * ty) / height
                cu = np.clip(nx + ox, F32(0.5) / width,
                             F32(1.0) - F32(0.5) / width).astype(F32)
                cv = np.clip(ny + oy, F32(0.5) / height,
                             F32(1.0) - F32(0.5) / height).astype(F32)
                smp = g.sample(source, cu, cv)
                acc += (wgt[..., None] * smp).astype(F32)
                wsum += wgt
    if mutation == "skip_norm":                    # plausible bug: never divide
        return g.store_float32(acc)
    out = acc / np.maximum(wsum, F32(1e-6))[..., None]
    return g.store_float32(out)


# --- independent ground truths ------------------------------------------

def iso_reference(source, radius, width=F32(W), height=F32(H)):
    """INDEPENDENT isotropic reference. Same DELIVERED discrete structure
    (centre + 8 half-integer stations per side with transverse 0/+-R/2 at the
    discrete-Gaussian rule) written standalone: transverse loop OUTSIDE the
    station loop, per-station along weights in a precomputed dict, no shared
    helpers with aniso_pass."""
    h, w = source.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    R = F32(radius)
    sig = np.maximum(F32(0.5) * R, F32(1e-6))
    g_along = {}
    for k in range(1, 9):
        u_k = F32(k) - F32(0.5)
        g_along[k] = np.exp(-(u_k * u_k) * F32(2.0) / np.maximum(
            R * R, F32(1e-12))).astype(F32)
    wts = {F32(0.0): F32(W_T0), F32(1.0): F32(W_T1), F32(-1.0): F32(W_T1)}
    acc = np.zeros((h, w, 4), F32)
    wsum = np.zeros((h, w), F32)
    centre_u = np.clip(nx, F32(0.5) / width, F32(1.0) - F32(0.5) / width)
    centre_v = np.clip(ny, F32(0.5) / height, F32(1.0) - F32(0.5) / height)
    acc += g.sample(source, centre_u, centre_v)
    wsum += F32(1.0)
    for tsign in (F32(1.0), F32(0.0), F32(-1.0)):          # transverse OUTER
        for k in range(1, 9):                              # station INNER
            u_k = F32(k) - F32(0.5)
            for sgn in (F32(1.0), F32(-1.0)):
                wt = (g_along[k] * wts[tsign]).astype(F32)
                ox = sgn * u_k / width
                oy = tsign * sig / height
                cu = np.clip(nx + ox, F32(0.5) / width,
                             F32(1.0) - F32(0.5) / width).astype(F32)
                cv = np.clip(ny + oy, F32(0.5) / height,
                             F32(1.0) - F32(0.5) / height).astype(F32)
                acc += (wt[..., None] * g.sample(source, cu, cv)).astype(F32)
                wsum += wt
    out = acc / np.maximum(wsum, F32(1e-6))[..., None]
    return g.store_float32(out)
