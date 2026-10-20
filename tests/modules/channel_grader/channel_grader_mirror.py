"""
channel_grader_mirror.py -- NumPy mirror of the f_channel_grader shader
(src/f_channel_grader/codebox_channel_grader.gen), float32, in the codebox's own
order of operations: one bilinear read of in1 at norm, a per-channel
lift/gamma/gain map (add lift, clamp to [0,1], gamma power, multiply gain), then
a master lift/gamma/gain map on top of the per-channel result, then the bypass mix.
The alpha channel is passed through untouched.

The shipped pix is `@type char`, whose output quantizes to 8 bits; like the
exemplar mirrors this mirror models the float32 outlet (gpu_sim.store_float32),
so every error here is an algorithm error, not a quantization artifact.

`bug` values are the mutations the tests must catch:
  - "linear_gain": gain applied as a multiplier of the dial value instead of 2^stops
  - "gamma_times_instead_of_div": the gamma power taken as 2^gamma rather than
    1/2^gamma (the two conventions the standard model is confused under)
  - "no_master_clamp": the master stage applied without clamping between the
    per-channel and master stages
  - "swap_rg": the red and green parameter sets swapped
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def grade(v, lift, gamma, gain, bug=None):
    """The grade map of one band: gain * (clamp(v + lift))^(1 / 2^gamma) in the
    codebox's order (add, clamp, pow, multiply)."""
    lift = F32(lift)
    gain_stops = F32(gain)
    gamma_stops = F32(gamma)
    if bug == "swap_rg":
        pass  # the swap happens at the caller (the per-channel assignments); nothing here
    base = (v + lift).astype(F32)
    base = np.clip(base, F32(0.0), F32(1.0)).astype(F32)
    if bug == "gamma_times_instead_of_div":
        ex = np.maximum(np.power(F32(2.0), gamma_stops), F32(0.001))
    else:
        ex = F32(1.0) / np.maximum(np.power(F32(2.0), gamma_stops), F32(0.001))
    powered = np.power(base.astype(np.float64), np.float64(ex)).astype(F32)
    if bug == "linear_gain":
        return (powered * F32(gain)).astype(F32)
    return (np.power(F32(2.0), gain_stops) * powered).astype(F32)


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    return (a * (F32(1.0) - t) + b * t).astype(F32)


def channel_grader(src=None, r_lift=0.0, r_gamma=0.0, r_gain=0.0,
                   g_lift=0.0, g_gamma=0.0, g_gain=0.0,
                   b_lift=0.0, b_gamma=0.0, b_gain=0.0,
                   m_lift=0.0, m_gamma=0.0, m_gain=0.0,
                   bypass=0.0, bug=None):
    """One frame. src: (H, W, 4) float32; returns out1, (H, W, 4) float32."""
    h, w = src.shape[:2]
    u, v, _, _ = g.grid(h, w)
    s = g.sample(src, u, v)
    r, gr, b = s[..., 0], s[..., 1], s[..., 2]

    if bug == "swap_rg":
        rg = grade(r, g_lift, g_gamma, g_gain, bug)
        gg = grade(gr, r_lift, r_gamma, r_gain, bug)
    else:
        rg = grade(r, r_lift, r_gamma, r_gain, bug)
        gg = grade(gr, g_lift, g_gamma, g_gain, bug)
    bg = grade(b, b_lift, b_gamma, b_gain, bug)

    mg = np.power(F32(2.0), F32(m_gain))
    if bug == "gamma_times_instead_of_div":
        me = np.maximum(np.power(F32(2.0), F32(m_gamma)), F32(0.001))
    else:
        me = F32(1.0) / np.maximum(np.power(F32(2.0), F32(m_gamma)), F32(0.001))
    base_r = np.clip(rg + F32(m_lift), F32(0.0), F32(1.0)).astype(F32) \
        if bug != "no_master_clamp" else (rg + F32(m_lift)).astype(F32)
    base_g = np.clip(gg + F32(m_lift), F32(0.0), F32(1.0)).astype(F32) \
        if bug != "no_master_clamp" else (gg + F32(m_lift)).astype(F32)
    base_b = np.clip(bg + F32(m_lift), F32(0.0), F32(1.0)).astype(F32) \
        if bug != "no_master_clamp" else (bg + F32(m_lift)).astype(F32)
    ro = (mg * np.power(base_r.astype(np.float64), np.float64(me))).astype(F32)
    go = (mg * np.power(base_g.astype(np.float64), np.float64(me))).astype(F32)
    bo = (mg * np.power(base_b.astype(np.float64), np.float64(me))).astype(F32)

    effective = F32(1.0) - F32(bypass)
    out1 = np.stack([_mix(r, ro, effective),
                     _mix(gr, go, effective),
                     _mix(b, bo, effective),
                     s[..., 3]], axis=-1).astype(F32)
    return out1