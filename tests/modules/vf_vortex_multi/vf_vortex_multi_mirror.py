"""
vf_vortex_multi_mirror.py -- NumPy mirror of the f_vf_vortex_multi shader:
src/f_vf_vortex_multi/definition.py (inline codebox), float32, in the codebox's
own order of operations.

A generator: there is no source texture, but the four modulation textures
(in2..in5 in the gen) are explicit (H, W, 4) float32 textures, sampled at the
texel-centre norm grid through gpu_sim.sample (bilinear, texel-centre,
clamp-to-edge). The output is (H, W, 4) float32: R and G encode the summed
field with f_vecfield's (v * 0.5 + 0.5), B = 0.5, A = 1.0, and bypass mixes
that toward the neutral field (0.5, 0.5, 0.5, 1.0).

`bug` values are the mutations the tests must catch, as the vf_streak exemplar
does: "radial_source" (the convergence part points outward instead of inward),
"no_falloff" (the exp(-r * falloff) strength scale dropped),
"swap_rg" (R and G swapped when encoding), "mod_unscaled" (the mod decode
missing its * amt depth scale).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1) - t) + b * t).astype(F32)


def _mod_decode(tex, u, v, amt, bug):
    """`(sample(inN, uv).x - 0.5) * 2.0 * amt`, in that order."""
    decoded = (g.sample(tex, u, v)[..., 0] - F32(0.5)) * F32(2.0)
    if bug == "mod_unscaled":
        return decoded.astype(F32)      # forgot the modulation depth
    return (decoded * F32(amt)).astype(F32)


def _site(dx, dy, conv_eff, curl_eff, falloff_clamped, bug):
    """One site, statements in the codebox's order (the per-site block)."""
    r = np.sqrt(dx * dx + dy * dy).astype(F32)
    r_safe = np.maximum(r, F32(1e-4))
    rx = (dx / r_safe).astype(F32)
    ry = (dy / r_safe).astype(F32)
    tx = (-ry).astype(F32)
    ty = rx
    if bug == "radial_source":
        sgn = F32(-1)   # the radial part flipped: a sink becomes a source
    else:
        sgn = F32(1)
    fx = (conv_eff * (sgn * -rx) + curl_eff * tx).astype(F32)
    fy = (conv_eff * (sgn * -ry) + curl_eff * ty).astype(F32)
    if bug == "no_falloff":
        strength = np.ones_like(r)      # the exponential scale dropped
    else:
        strength = np.exp(-r * falloff_clamped).astype(F32)
    return (fx * strength).astype(F32), (fy * strength).astype(F32)


def vortex_multi(in2=None, in3=None, in4=None, in5=None, h=32, w=32,
                 s1_cx=0.3, s1_cy=0.3, s1_conv=0.5, s1_curl=0.0,
                 s2_cx=0.5, s2_cy=0.5, s2_conv=0.5, s2_curl=0.0,
                 s3_cx=0.7, s3_cy=0.7, s3_conv=0.5, s3_curl=0.0,
                 falloff=2.0, cx_amt=0.0, cy_amt=0.0, conv_amt=0.0,
                 curl_amt=0.0, bypass=0.0, bug=None):
    """One frame of the shipped gen. in2..in5 are the four global modulation
    textures (cx, cy, convergence, curl mod); a texture of None stands for the
    neutral 0.5 field, which decodes to a zero offset whatever the depth.
    Returns out1 as (H, W, 4) float32."""
    if in2 is None:
        in2 = g.texture(h, w); in2[...] = np.array([0.5, 0.5, 0.5, 1.0], F32)
    if in3 is None:
        in3 = g.texture(h, w); in3[...] = np.array([0.5, 0.5, 0.5, 1.0], F32)
    if in4 is None:
        in4 = g.texture(h, w); in4[...] = np.array([0.5, 0.5, 0.5, 1.0], F32)
    if in5 is None:
        in5 = g.texture(h, w); in5[...] = np.array([0.5, 0.5, 0.5, 1.0], F32)

    u, v, _, _ = g.grid(h, w)
    uvx, uvy = u, v                     # `uv = norm;` used through uv.x / uv.y

    cx_mod = _mod_decode(in2, uvx, uvy, cx_amt, bug)
    cy_mod = _mod_decode(in3, uvx, uvy, cy_amt, bug)
    conv_mod = _mod_decode(in4, uvx, uvy, conv_amt, bug)
    curl_mod = _mod_decode(in5, uvx, uvy, curl_amt, bug)

    falloff_clamped = F32(max(F32(falloff), F32(0.0)))   # max(falloff, 0.0)

    fx = fy = None
    for (scx, scy, sconv, scurl) in (
            (s1_cx, s1_cy, s1_conv, s1_curl),
            (s2_cx, s2_cy, s2_conv, s2_curl),
            (s3_cx, s3_cy, s3_conv, s3_curl)):
        cx_eff = (F32(scx) + cx_mod).astype(F32)
        cy_eff = (F32(scy) + cy_mod).astype(F32)
        dx = (uvx - cx_eff).astype(F32)
        dy = (uvy - cy_eff).astype(F32)
        sfx, sfy = _site(dx, dy, (F32(sconv) + conv_mod).astype(F32),
                         (F32(scurl) + curl_mod).astype(F32),
                         falloff_clamped, bug)
        fx = sfx if fx is None else (fx + sfx).astype(F32)
        fy = sfy if fy is None else (fy + sfy).astype(F32)

    e1 = np.clip(fx * F32(0.5) + F32(0.5), F32(0), F32(1)).astype(F32)
    e2 = np.clip(fy * F32(0.5) + F32(0.5), F32(0), F32(1)).astype(F32)
    if bug == "swap_rg":
        er, eg = e2, e1                 # channels swapped at the encode
    else:
        er, eg = e1, e2
    half = np.full_like(er, F32(0.5))
    one = np.ones_like(er)
    field_out = np.stack([er, eg, half, one], axis=-1).astype(F32)
    neutral = np.stack([half, half, half, one], axis=-1).astype(F32)
    out1 = _mix(field_out, neutral, F32(bypass))
    return out1.astype(F32)