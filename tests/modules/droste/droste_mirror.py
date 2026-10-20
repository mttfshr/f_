"""
droste_mirror.py -- NumPy mirror of the f_droste shader: the codebox inline in src/f_droste/definition.py, float32, in the codebox's own order of operations:

    dx = norm.x - 0.5;  dy = norm.y - 0.5
    r = sqrt(dx*dx + dy*dy);  theta = atan2(dy, dx)
    log_zoom = log(max(zoom, 1.001))
    s = log(max(r, 0.00001)) / log_zoom
    t = (theta / TWO_PI) + rotation
    s = s + time_s
    s_sp = s - t * twist;  t_sp = t + s * twist
    droste_out = sample(in1, vec(fract(t_sp * n_arms), fract(s_sp), 0))
    out1 = mix(droste_out, sample(in1, norm), bypass)

Sampling is gpu_sim's bilinear, texel-centre, clamp-to-edge `sample`; the codebox applies fract() itself,
so the wrapped coordinates go in pre-wrapped. The pass evaluates the same pure function on an (H, W)
grid (default) or at explicit nx, ny coordinate arrays, so tests can probe the identical function at
points the closed forms choose.

`bug` values are the mutations the tests must catch: "angle_radius_swap" (the U and V sample coordinates
swapped), "twist_sign" (the symmetric-shear signs flipped), "no_time_shift" (the `s = s + time_s` step
dropped), "no_arms" (the n_arms scaling of the angle channel dropped) and "zoom_clamp_dropped" (the
`max(zoom, 1.001)` floor removed, which changes the radial scale below the floor).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32

TWO_PI = F32(6.28318530717959)


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1) - t) + b * t).astype(F32)


def droste_pass(src, zoom=2.0, n_arms=1.0, time_s=0.0, twist=0.0, rotation=0.0, bypass=0.0,
                bug=None, nx=None, ny=None):
    """One pass. src: (H, W, 4) float32; nx, ny: broadcastable float coordinate arrays (default the
    sim grid). Returns out1 as (H, W, 4) float32 (the module's only outlet)."""
    h, w = src.shape[:2]
    if nx is None:
        nx, ny, _, _ = g.grid(h, w)
    nx = np.asarray(nx, F32)
    ny = np.asarray(ny, F32)

    dx = nx - F32(0.5)
    dy = ny - F32(0.5)

    r = np.sqrt(dx * dx + dy * dy).astype(F32)
    theta = np.arctan2(dy, dx).astype(F32)

    if bug == "zoom_clamp_dropped":
        log_zoom = np.log(F32(zoom)).astype(F32)
    else:
        log_zoom = np.log(F32(max(F32(zoom), F32(1.001)))).astype(F32)

    s = (np.log(np.maximum(r, F32(1e-5))) / log_zoom).astype(F32)
    t = ((theta / TWO_PI) + F32(rotation)).astype(F32)

    if bug == "no_time_shift":
        pass
    else:
        s = (s + F32(time_s)).astype(F32)

    if bug == "twist_sign":
        s_sp = (s + t * F32(twist)).astype(F32)
        t_sp = (t - s * F32(twist)).astype(F32)
    else:
        s_sp = (s - t * F32(twist)).astype(F32)
        t_sp = (t + s * F32(twist)).astype(F32)

    if bug == "angle_radius_swap":
        u, v = _fract(s_sp), _fract(t_sp * F32(n_arms))
    elif bug == "no_arms":
        u, v = _fract(t_sp), _fract(s_sp)
    else:
        u, v = _fract(t_sp * F32(n_arms)), _fract(s_sp)

    droste_out = g.sample(src, u, v)
    base = g.sample(src, nx, ny)
    return _mix(droste_out, base, F32(bypass))


def _fract(x):
    """GenExpr fract: x - floor(x)."""
    return (x - np.floor(x)).astype(F32)