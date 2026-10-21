"""
luma_processor_mirror.py -- NumPy mirror of the f_luma_processor codebox
(src/f_luma_processor/codebox_luma_processor.gen), float32, in the codebox's
own order of operations: RGB -> HSV -> luma-band mask -> sat/val/hue shift ->
HSV -> RGB -> bypass mix. The single texture read goes through gpu_sim.sample.

`bug` values are the mutations the tests must catch:
  "swap_rg"     -- the hue branch terms use the wrong channel difference in hr/hg
                   (channels g and b swapped: (b-g) instead of (g-b), (r-b) not (b-r))
  "no_clamp"    -- sat_out / val_out lose their clamp to [0, 1]
  "mask_off"    -- the mask multiplies the shifts with lm/mh swapped (band inverted),
                   so the mask opens outside [low_mid, mid_high] instead of inside
  "additive_tie" -- the pre-2026-10-20 hue expression, where the green term is not exclusive of
                   the red term, so a red = green tie for the maximum (gray, yellow) adds both
                   and lands at hue 1/3 (green)
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _smoothstep(e0, e1, x):
    """GLSL smoothstep(e0, e1, x)."""
    e0, e1 = F32(e0), F32(e1)
    t = np.clip((x - e0) / (e1 - e0), F32(0), F32(1))
    return (t * t * (F32(3) - F32(2) * t)).astype(F32)


def _step(edge, x):
    """GLSL step(edge, x): 1 when x >= edge."""
    return (np.asarray(x) >= F32(edge)).astype(F32)


def luma_processor(src, low_mid=0.33, mid_high=0.66, edge_falloff=0.1, sat_amt=0.0,
                   lum_shift=0.0, hue_shift=0.0, bypass=0.0, bug=None):
    """src: (H, W, 4) float32 texture. Returns (H, W, 4) float32 output."""
    r, gg, b = src[..., 0], src[..., 1], src[..., 2]

    if bug == "swap_rg":
        d1, d2, d3, d4 = b, gg, r, b      # channels swapped in the hue branch terms
    else:
        d1, d2, d3, d4 = gg, b, b, r      # hr=(g-b), hg=2+(b-r)

    # RGB -> HSV
    cmax = np.maximum(np.maximum(r, gg), b)
    cmin = np.minimum(np.minimum(r, gg), b)
    delta = (cmax - cmin).astype(F32)
    s1 = _step(F32(0.00001), delta)
    dmax = np.maximum(delta, F32(0.00001))
    hr = (d1 - d2) / dmax                 # same expression as the codebox, bug may retarget it
    hg = F32(2.0) + (d3 - d4) / dmax
    hb = F32(4.0) + (r - gg) / dmax
    sr = _step(cmax, r + F32(0.00001))
    sg = _step(cmax, gg + F32(0.00001))
    if bug == "additive_tie":
        hue = sr * hr + sg * hg + (F32(1) - sr) * (F32(1) - sg) * hb   # the pre-2026-10-20 codebox
    else:
        hue = sr * hr + (F32(1) - sr) * sg * hg + (F32(1) - sr) * (F32(1) - sg) * hb
    hue = ((hue / F32(6.0) + F32(1.0)) - np.floor(hue / F32(6.0) + F32(1.0))).astype(F32)

    sat = (s1 * delta / np.maximum(cmax, F32(0.00001))).astype(F32)
    val = cmax

    lum = (F32(0.299) * r + F32(0.587) * gg + F32(0.114) * b).astype(F32)

    lm, mh = np.minimum(low_mid, mid_high).astype(F32), np.maximum(low_mid, mid_high).astype(F32)
    ef = F32(edge_falloff)
    if bug == "mask_off":
        lm, mh = mh, lm                   # band inverted: openings swap
    mask = (_smoothstep(lm - ef, lm + ef, lum) * (F32(1) - _smoothstep(mh - ef, mh + ef, lum))).astype(F32)

    if bug == "no_clamp":
        sat_out = (sat + sat_amt * mask).astype(F32)
        val_out = (val + lum_shift * mask).astype(F32)
    else:
        sat_out = np.clip(sat + F32(sat_amt) * mask, F32(0), F32(1)).astype(F32)
        val_out = np.clip(val + F32(lum_shift) * mask, F32(0), F32(1)).astype(F32)
    hue_out = (hue + (F32(hue_shift) / F32(360.0)) * mask).astype(F32)
    hue_out = (hue_out - np.floor(hue_out)).astype(F32)

    # HSV -> RGB (branch-free)
    h6 = hue_out * F32(6.0)
    kr = np.abs(h6 - F32(3.0)) - F32(1.0)
    kg = F32(2.0) - np.abs(h6 - F32(2.0))
    kb = F32(2.0) - np.abs(h6 - F32(4.0))
    ro = (val_out * _mix(F32(1.0), np.clip(kr, F32(0), F32(1)), sat_out)).astype(F32)
    go = (val_out * _mix(F32(1.0), np.clip(kg, F32(0), F32(1)), sat_out)).astype(F32)
    bo = (val_out * _mix(F32(1.0), np.clip(kb, F32(0), F32(1)), sat_out)).astype(F32)

    eff = F32(1.0) - F32(bypass)
    out = np.stack([_mix(r, ro, eff), _mix(gg, go, eff), _mix(b, bo, eff),
                    src[..., 3].copy()], axis=-1).astype(F32)
    return out


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    return (a * (F32(1) - t) + b * t).astype(F32)