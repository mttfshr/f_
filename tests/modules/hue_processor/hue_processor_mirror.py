"""
hue_processor_mirror.py -- NumPy mirror of the f_hue_processor shader:
src/f_hue_processor/codebox_hue_processor.gen, float32, in the codebox's own order
of operations (RGB -> HSV decode, flat-top hue-band mask with saturation gate,
HSV re-encode, bypass blend).

The single pass samples in1 at the pixel's own texel centre (uv = norm), so every
texture read is exact -- no interpolation error anywhere in this module.

`bug` values are the mutations the tests must catch:
  "swap_band_sides"  -- hue_lower applied to the above-centre side and hue_upper to
                        the below-centre side (the sides swapped),
  "no_sat_gate"      -- the saturation gate is missing (mask not suppressed near gray),
  "swap_rg"          -- the R and G channels of the HSV re-encode swapped.
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _step(edge, x):
    """GenExpr step(edge, x): 0 when x < edge, else 1."""
    return (np.asarray(x, F32) >= np.asarray(edge, F32)).astype(F32)


def _smoothstep(e0, e1, x):
    """GenExpr smoothstep: standard Hermitian 3t^2 - 2t^3 on the clamped ramp."""
    t = np.clip((x - e0) / (e1 - e0), F32(0), F32(1)).astype(F32)
    return (t * t * (F32(3.0) - F32(2.0) * t)).astype(F32)


def hue_processor(src, hue_center=120.0, hue_lower=36.0, hue_upper=156.0,
                  edge_falloff=10.0, sat_amt=0.0, lum_shift=0.0, hue_shift=0.0,
                  bypass=0.0, bug=None):
    """One pass. src: (H, W, 4) float32. Returns (H, W, 4) float32."""
    h, w = src.shape[:2]
    u, v, _, _ = g.grid(h, w)
    s = g.sample(src, u, v)
    rg, gg, bg = s[..., 0], s[..., 1], s[..., 2]

    # RGB -> HSV
    cmax = np.maximum(rg, np.maximum(gg, bg)).astype(F32)
    cmin = np.minimum(rg, np.minimum(gg, bg)).astype(F32)
    delta = (cmax - cmin).astype(F32)
    safe_delta = np.maximum(delta, F32(0.001)).astype(F32)
    safe_cmax = np.maximum(cmax, F32(0.001)).astype(F32)

    hue_r = (np.mod((gg - bg) / safe_delta, F32(6.0)) / F32(6.0)).astype(F32)
    hue_g = (((bg - rg) / safe_delta + F32(2.0)) / F32(6.0)).astype(F32)
    hue_b = (((rg - gg) / safe_delta + F32(4.0)) / F32(6.0)).astype(F32)

    r_is_max = (_step(gg, rg) * _step(bg, rg)).astype(F32)
    g_is_max = (_step(bg, gg) * (F32(1.0) - r_is_max)).astype(F32)

    hue = (_mix3(_mix3(hue_b, hue_g, g_is_max), hue_r, r_is_max)).astype(F32)
    hue = np.mod(hue + F32(1.0), F32(1.0)).astype(F32)  # fract(hue + 1.0)

    S = (delta / safe_cmax).astype(F32)
    V = cmax

    # Hue band mask
    hue_c = F32(hue_center / 360.0)
    lower_n = F32(hue_lower / 360.0)
    upper_n = F32(hue_upper / 360.0)
    fall_n = np.maximum(F32(edge_falloff / 360.0), F32(0.00001)).astype(F32)

    signed_dist = np.mod(hue - hue_c + F32(0.5), F32(1.0)).astype(F32) - F32(0.5)

    if bug == "swap_band_sides":
        upper_mask = F32(1.0) - _smoothstep(lower_n, lower_n + fall_n,
                                            np.maximum(signed_dist, F32(0)).astype(F32))
        lower_mask = F32(1.0) - _smoothstep(upper_n, upper_n + fall_n,
                                            np.maximum(-signed_dist, F32(0)).astype(F32))
    else:
        upper_mask = F32(1.0) - _smoothstep(upper_n, upper_n + fall_n,
                                            np.maximum(signed_dist, F32(0)).astype(F32))
        lower_mask = F32(1.0) - _smoothstep(lower_n, lower_n + fall_n,
                                            np.maximum(-signed_dist, F32(0)).astype(F32))

    # Saturation gate
    if bug == "no_sat_gate":
        sat_gate = np.ones_like(S)
    else:
        sat_gate = _smoothstep(F32(0.05), F32(0.15), S)

    hue_mask = (upper_mask * lower_mask * sat_gate).astype(F32)

    # Blend HSV components with mask before reconstruction
    blended_H = np.mod(hue + F32(hue_shift / 360.0) * hue_mask, F32(1.0)).astype(F32)
    blended_S = np.clip(S + F32(sat_amt) * hue_mask, F32(0), F32(1)).astype(F32)
    blended_V = np.clip(V + F32(lum_shift) * hue_mask, F32(0), F32(1)).astype(F32)

    # HSV -> RGB (branch-free)
    h6 = (blended_H * F32(6.0)).astype(F32)
    r_hsv = np.clip(np.abs(h6 - F32(3.0)) - F32(1.0), F32(0), F32(1)).astype(F32)
    g_hsv = np.clip(F32(2.0) - np.abs(h6 - F32(2.0)), F32(0), F32(1)).astype(F32)
    b_hsv = np.clip(F32(2.0) - np.abs(h6 - F32(4.0)), F32(0), F32(1)).astype(F32)
    if bug == "swap_rg":
        r_hsv, g_hsv = g_hsv, r_hsv

    ro = (blended_V * _mix3(np.ones_like(blended_V), r_hsv, blended_S)).astype(F32)
    go = (blended_V * _mix3(np.ones_like(blended_V), g_hsv, blended_S)).astype(F32)
    bo = (blended_V * _mix3(np.ones_like(blended_V), b_hsv, blended_S)).astype(F32)

    effective = F32(1.0) - F32(bypass)
    out = np.empty_like(src)
    out[..., 0] = _mix3(rg, ro, effective)
    out[..., 1] = _mix3(gg, go, effective)
    out[..., 2] = _mix3(bg, bo, effective)
    out[..., 3] = s[..., 3]
    return out


def _mix3(a, b, t):
    """GenExpr mix: a * (1 - t) + b * t."""
    return (a * (F32(1) - t) + b * t).astype(F32)