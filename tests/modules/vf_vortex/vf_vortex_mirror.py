"""
vf_vortex_mirror.py -- NumPy mirror of the f_vf_vortex codebox (inline in
src/f_vf_vortex/definition.py), float32, in the codebox's own order of
operations: param modulation first, then offset / distance / unit radial /
unit tangential (90 deg CCW), then convergence (negated radial) plus curl
(tangential), then strength = exp(-r * f_safe), then the [0,1] encoding
and the bypass mix. Every modulation read goes through gpu_sim.sample at
`norm`; an unconnected inlet reads (0, 0, 0, 1).

`bug` values are the mutations the tests must catch: "sign_flip" (convergence
does not negate the radial unit vector, so a sink becomes a source),
"wrong_guard" (the div-by-zero guard constant is 0.5 instead of 0.0001),
"swap_rg" (the encoded R and G channels swapped), "no_clamp" (the encoding
leaves out the clamp to [0, 1]), "gaussian_falloff" (the falloff written as
exp(-r * r * falloff), a Gaussian, instead of the doc's exp(-r * falloff)).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1.0) - t) + b * t).astype(F32)


def vortex(h, w, cx=0.5, cy=0.5, convergence=0.5, curl=0.0, falloff=2.0,
           cx_amt=0.0, cy_amt=0.0, convergence_amt=0.0, curl_amt=0.0,
           bypass=0.0, mod_cx=None, mod_cy=None, mod_conv=None, mod_curl=None,
           bug=None):
    """One pass of vortex_pix. mod_* are (H, W, 4) float32 textures or None
    (unconnected inlet reads (0, 0, 0, 1)). Returns the encoded field texture
    (H, W, 4) float32, RG in [0, 1], 0.5 = zero vector."""
    nx, ny, _, _ = g.grid(h, w)

    def decode(tex, amt, base):
        if tex is None:
            v = np.full((h, w), F32(0.0), dtype=F32)
        else:
            v = g.sample(tex, nx, ny)[..., 0]
        return (base + (v - F32(0.5)) * F32(2.0) * F32(amt)).astype(F32)

    cx_eff = decode(mod_cx, cx_amt, F32(cx))
    cy_eff = decode(mod_cy, cy_amt, F32(cy))
    conv_eff = decode(mod_conv, convergence_amt, F32(convergence))
    curl_eff = decode(mod_curl, curl_amt, F32(curl))

    # offset from center
    dx = (nx - cx_eff).astype(F32)
    dy = (ny - cy_eff).astype(F32)

    # distance -- guard div-by-zero
    r = np.sqrt(dx * dx + dy * dy).astype(F32)
    guard = F32(0.5) if bug == "wrong_guard" else F32(0.0001)
    r_safe = np.maximum(r, guard).astype(F32)

    # unit radial (pointing away from center)
    rx = (dx / r_safe).astype(F32)
    ry = (dy / r_safe).astype(F32)

    # unit tangential (90 deg CCW of radial)
    tx, ty = -ry, rx

    # field: convergence pulls toward center (negate radial), curl rotates
    if bug == "sign_flip":
        fx = (conv_eff * rx + curl_eff * tx).astype(F32)
        fy = (conv_eff * ry + curl_eff * ty).astype(F32)
    else:
        fx = (conv_eff * (-rx) + curl_eff * tx).astype(F32)
        fy = (conv_eff * (-ry) + curl_eff * ty).astype(F32)

    # exponential falloff -- clamp to positive, no ring artifact
    f_safe = np.maximum(F32(falloff), F32(0.0))
    if bug == "gaussian_falloff":
        strength = np.exp(-r * r * f_safe).astype(F32)
    else:
        strength = np.exp(-r * f_safe).astype(F32)
    fx = (fx * strength).astype(F32)
    fy = (fy * strength).astype(F32)

    # encode signed [-1,1] to [0,1] range
    R = (fx * F32(0.5) + F32(0.5)).astype(F32)
    G = (fy * F32(0.5) + F32(0.5)).astype(F32)
    if bug != "no_clamp":
        R = np.clip(R, F32(0.0), F32(1.0))
        G = np.clip(G, F32(0.0), F32(1.0))
    if bug == "swap_rg":
        R, G = G, R

    field_out = np.stack([R, G, np.full((h, w), F32(0.5)), np.ones((h, w), F32)], axis=-1)
    neutral = np.empty((h, w, 4), F32)
    neutral[...] = (0.5, 0.5, 0.5, 1.0)
    return _mix(field_out, neutral, F32(bypass))