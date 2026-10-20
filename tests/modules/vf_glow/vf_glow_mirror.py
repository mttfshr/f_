"""
vf_glow_mirror.py -- NumPy mirror of the f_vf_glow shader:
src/f_vf_glow/codebox_v1.gen, float32,
in the codebox's own order of operations: the pre-remap vs_black suppression of
the vecfield, the additively scaled radius modulation, the direction weights,
then the fixed 48-step field-aligned accumulation with per-step jitter,
normalization by the accumulated weight sum, the luma color_mix, the driven
composite and the two-stage crossfade to it, and the param bypass mixing both
outlets back to the source.

Inputs, as in the gen: in1 = source texture, in2 = vecfield texture (float32,
R,G encode (v - 0.5) * 2, (0.5, 0.5) = zero vector), in3 = radius mod texture.
All reads go through gpu_sim's bilinear, texel-centre, clamped `sample` --
the codebox clamps its own march coordinates, so the sim's clamp-to-edge never
binds beyond the shader's own clamp.

`bug` values are the mutations the tests must catch, each a plausible real
mistake:
  - "sign_flip": the y field component negated,
  - "no_normalize": the accumulation divided by the fixed step count instead
    of the accumulated weight sum,
  - "swap_rb": the red and blue accumulation channels swapped,
  - "double_falloff": the falloff applied twice over in the step weight.
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1) - t) + b * t).astype(F32)


def _step(edge, x):
    """GLSL step(edge, x): 1.0 when x >= edge, else 0.0."""
    return np.where(np.asarray(x, F32) >= F32(edge), F32(1.0), F32(0.0)).astype(F32)


def glow_stage(src, vec, mod=None, radius=0.01, falloff=0.002, gain=0.8,
               mix_pct=0.0, color_mix=0.0, direction=0.0, bypass_gate=0.0,
               bug=None):
    """One frame. src, vec, mod: (H, W, 4) float32 (mod None = unconnected
    in3, i.e. vs_black). Returns (out1 composite, out2 isolated glow layer)."""
    h, w = src.shape[:2]
    u, v, _, _ = g.grid(h, w)
    if mod is None:
        mod = g.texture(h, w)  # unconnected inlet reads vs_black
    s = g.sample(src, u, v)

    # read raw vecfield -- check for vs_black before remapping
    raw = g.sample(vec, u, v)
    raw_x, raw_y = raw[..., 0], raw[..., 1]
    field_suppress = _step(F32(0.02), raw_x + raw_y)
    fx = ((raw_x - F32(0.5)) * F32(2.0) * field_suppress).astype(F32)
    fy = ((raw_y - F32(0.5)) * F32(2.0) * field_suppress).astype(F32)
    if bug == "sign_flip":
        fy = (-fy).astype(F32)

    # radius modulation -- additive, scaled by base radius
    mod_val = g.sample(mod, u, v)[..., 0]
    f = F32(falloff)
    if bug == "double_falloff":
        f = (f * F32(2.0)).astype(F32)
    radius_eff = np.clip(F32(radius) + mod_val * F32(radius), F32(0.0), F32(0.3)).astype(F32)
    dx = (fx * radius_eff).astype(F32)
    dy = (fy * radius_eff).astype(F32)

    # direction weights (branchless)
    s15 = _step(F32(1.5), F32(direction))
    s05 = _step(F32(0.5), F32(direction))
    fwd_weight = (F32(1.0) - s15).astype(F32)
    bwd_weight = (F32(1.0) - s05 + s15).astype(F32)

    # 48-step accumulation with per-step jitter
    acc_r = np.zeros((h, w), F32)
    acc_g = np.zeros((h, w), F32)
    acc_b = np.zeros((h, w), F32)
    acc_w = np.zeros((h, w), F32)
    for i in range(1, 49):
        i_f = F32(i)
        wi = np.exp(F32(-1.0) * i_f * i_f * f).astype(F32)
        j = (np.sin(u * F32(127.1) + v * F32(311.7) + i_f * F32(43.7)) * F32(43758.5453)).astype(F32)
        jitter = ((j - np.floor(j)) - F32(0.5)).astype(F32)
        stepped = (i_f + jitter * F32(0.1)).astype(F32)
        fwd_uv_x = np.clip(u + dx * stepped, F32(0.0), F32(1.0)).astype(F32)
        fwd_uv_y = np.clip(v + dy * stepped, F32(0.0), F32(1.0)).astype(F32)
        bwd_uv_x = np.clip(u - dx * stepped, F32(0.0), F32(1.0)).astype(F32)
        bwd_uv_y = np.clip(v - dy * stepped, F32(0.0), F32(1.0)).astype(F32)
        sf = g.sample(src, fwd_uv_x, fwd_uv_y)
        sb = g.sample(src, bwd_uv_x, bwd_uv_y)
        wf = (wi * fwd_weight).astype(F32)
        wb = (wi * bwd_weight).astype(F32)
        acc_r = (acc_r + sf[..., 0] * wf).astype(F32)
        acc_g = (acc_g + sf[..., 1] * wf).astype(F32)
        acc_b = (acc_b + sf[..., 2] * wf).astype(F32)
        acc_r = (acc_r + sb[..., 0] * wb).astype(F32)
        acc_g = (acc_g + sb[..., 1] * wb).astype(F32)
        acc_b = (acc_b + sb[..., 2] * wb).astype(F32)
        if bug == "swap_rb":
            sr_, sb_ = acc_b, acc_r
        else:
            sr_, sb_ = acc_r, acc_b
        acc_w = (acc_w + wf + wb).astype(F32)

    # normalize accumulation
    denom = np.maximum(acc_w, F32(0.0001))
    if bug == "no_normalize":
        denom = F32(48.0)
    norm_r = (sr_ / denom).astype(F32)
    norm_g = (acc_g / denom).astype(F32)
    norm_b = (sb_ / denom).astype(F32)

    # color_mix: blend toward luma
    luma = (norm_r * F32(0.2126) + norm_g * F32(0.7152) + norm_b * F32(0.0722)).astype(F32)
    glow_r = _mix(norm_r, luma, F32(color_mix))
    glow_g = _mix(norm_g, luma, F32(color_mix))
    glow_b = _mix(norm_b, luma, F32(color_mix))

    # composite: driven = the complete effect-applied state (source + glow*gain);
    # mix is a plain continuous blend toward that state.
    src_r, src_g, src_b = s[..., 0], s[..., 1], s[..., 2]
    driven_r = np.clip(src_r + glow_r * F32(gain), F32(0.0), F32(1.0)).astype(F32)
    driven_g = np.clip(src_g + glow_g * F32(gain), F32(0.0), F32(1.0)).astype(F32)
    driven_b = np.clip(src_b + glow_b * F32(gain), F32(0.0), F32(1.0)).astype(F32)
    t = F32(mix_pct) / F32(100.0)
    comp_r = _mix(src_r, driven_r, t)
    comp_g = _mix(src_g, driven_g, t)
    comp_b = _mix(src_b, driven_b, t)

    src_px = np.stack([src_r, src_g, src_b, s[..., 3]], axis=-1).astype(F32)
    bg = F32(bypass_gate)
    out1 = np.stack([_mix(comp_r, src_r, bg), _mix(comp_g, src_g, bg),
                     _mix(comp_b, src_b, bg), s[..., 3]], axis=-1).astype(F32)
    out2 = np.stack([_mix(glow_r, src_r, bg), _mix(glow_g, src_g, bg),
                     _mix(glow_b, src_b, bg), _mix(F32(1.0), s[..., 3], bg)],
                    axis=-1).astype(F32)
    return out1, out2
