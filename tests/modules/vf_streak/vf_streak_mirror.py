"""
vf_streak_mirror.py -- NumPy mirror of the f_vf_streak shader: src/f_vf_streak/codebox_v1.gen, float32, in the
codebox's own order of operations (the 8 unrolled marching steps, the left-to-right weighted sums).

Inputs, as in the gen: in1 = source texture, in2 = vecfield texture (R,G encode (v - 0.5) * 2). Sampling is
gpu_sim's bilinear, texel-centre `sample` with its measured out-of-range behaviour (x: the coordinate wraps modulo 1,
taps clamp; y clamps until probe P7). The march positions are not clamped in the shader, so out-of-frame reads are the
texture's own addressing: on the GPU they WRAP in x (probes P2 and P6 and the pix-to-pix scratch patch, 2026-10-20),
and so does this mirror now. The test whose reference is index arithmetic wraps its indices with mod.

`bug` values are the mutations the tests must catch: "forward" (march along +field instead of -field),
"no_normalize" (divide the weighted sum by 8 instead of by the weight sum), "swap_rb" (the chromatic offset
signs swapped).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1) - t) + b * t).astype(F32)


def weights(falloff):
    """The eight step weights, as the gen computes them: w_n = mix(1, 1 - n/7, falloff); w_0 = 1, w_7 = mix(1, 0, falloff)."""
    f = F32(falloff)
    ws = [F32(1.0)]
    for n in range(1, 7):
        ws.append(_mix(F32(1.0), F32(1.0) - F32(n) / F32(7.0), f))
    ws.append(_mix(F32(1.0), F32(0.0), f))
    return ws


def streak_stage(src, vec, gain=0.3, mix_pct=0.0, length=0.15, falloff=0.0, color_shift=0.0,
                 src_vecfield=1.0, bypass_gate=0.0, bug=None):
    """One frame. src, vec: (H, W, 4) float32. Returns (out1 composite, out2 isolated streak layer)."""
    h, w = src.shape[:2]
    u, v, _, _ = g.grid(h, w)
    step_size = F32(length) / F32(8.0)
    cs = F32(color_shift) * step_size
    connected = F32(1.0) if F32(src_vecfield) >= F32(0.5) else F32(0.0)
    ws = weights(falloff)
    w_sum = ws[0]
    for wn in ws[1:]:
        w_sum = w_sum + wn
    if bug == "forward":
        march = F32(-1)
    else:
        march = F32(1)
    r_sign = F32(-1) if bug == "swap_rb" else F32(1)

    px, py = u, v
    fx = fy = None
    acc_r = acc_g = acc_b = None
    for n in range(8):
        if n > 0:
            px = (px - march * fx * step_size).astype(F32)
            py = (py - march * fy * step_size).astype(F32)
        fs = g.sample(vec, px, py)
        fx = ((fs[..., 0] - F32(0.5)) * F32(2.0) * connected).astype(F32)
        fy = ((fs[..., 1] - F32(0.5)) * F32(2.0) * connected).astype(F32)
        sr = g.sample(src, (px + r_sign * fx * cs).astype(F32), py)[..., 0]
        sg = g.sample(src, px, py)[..., 1]
        sb = g.sample(src, (px - r_sign * fx * cs).astype(F32), py)[..., 2]
        if n == 0:
            acc_r, acc_g, acc_b = ws[0] * sr, ws[0] * sg, ws[0] * sb
        else:
            acc_r, acc_g, acc_b = acc_r + ws[n] * sr, acc_g + ws[n] * sg, acc_b + ws[n] * sb
    div = F32(8.0) if bug == "no_normalize" else w_sum
    with np.errstate(divide="ignore", invalid="ignore"):
        sr_, sg_, sb_ = (acc_r / div).astype(F32), (acc_g / div).astype(F32), (acc_b / div).astype(F32)
    lo, hi = F32(0), F32(1)
    streak = np.stack([np.clip(sr_, lo, hi), np.clip(sg_, lo, hi), np.clip(sb_, lo, hi),
                       np.ones_like(sr_)], axis=-1).astype(F32)

    s = g.sample(src, u, v)
    src_px = np.stack([s[..., 0], s[..., 1], s[..., 2], np.ones_like(sr_)], axis=-1).astype(F32)
    out2 = _mix(streak, src_px, F32(bypass_gate))

    t = F32(mix_pct) / F32(100.0)
    comp = []
    for c, streak_c in zip(range(3), (sr_, sg_, sb_)):
        driven = np.clip(s[..., c] + streak_c * F32(gain), lo, hi)
        comp.append(_mix(s[..., c], driven, t))
    composite = np.stack(comp + [np.ones_like(sr_)], axis=-1).astype(F32)
    out1 = _mix(composite, src_px, F32(bypass_gate))
    return out1, out2
