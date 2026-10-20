"""
mobius_mirror.py -- NumPy mirror of the f_mobius shader, float32, in the codebox's own order
of operations (offset to the transform centre, the rotate+zoom path, the 1/z inversion path
guarded by a mag_sq floor, the invert blend, the fract wrap, then bypass).

in1 = source texture, (H, W, 4) float32, read through gpu_sim's bilinear clamp-to-edge
`sample` at texel centres. Params are Python floats, converted to float32 exactly where the
codebox reads them: cx, cy (transform centre), rotate (0-1, full sweep = one revolution),
zoom (0.5 = identity, logarithmic), invert (blend from rotate+zoom toward 1/z), bypass.

`bug` values are the mutations the tests must catch, each a plausible real mistake:
  "swap_rot_terms"  -- the rotation block written as the inverse (cos*zx + sin*zy, ...)
  "sign_flip_inv_y" -- the imaginary part of 1/z with the wrong sign (zy instead of -zy)
  "linear_zoom"     -- the logarithmic dial misread as a linear one
  "no_guard"        -- the singularity floor max(mag_sq, 0.0001) dropped
  "wrap_shift"      -- the fract wrap applied before the centre is added back
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32
TWO_PI = F32(6.28318530717959)

GUARD = F32(0.0001)


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    return (a * (F32(1.0) - t) + b * t).astype(F32)


def _fract(x):
    return (x - np.floor(x)).astype(F32)


def mobius(src, cx=0.5, cy=0.5, rotate=0.0, zoom=0.5, invert=0.0, bypass=0.0, bug=None):
    """One pass, whole frame. src: (H, W, 4) float32. Returns out1: (H, W, 4) float32."""
    h, w = src.shape[:2]
    norm_x, norm_y, _, _ = g.grid(h, w)
    cx, cy = F32(cx), F32(cy)
    rotate, zoom, invert, bypass = F32(rotate), F32(zoom), F32(invert), F32(bypass)

    # offset to transformation center
    if bug == "swap_rot_terms":
        zx, zy = norm_y - cy, norm_x - cx
    else:
        zx, zy = norm_x - cx, norm_y - cy

    # identity path: rotate + zoom
    angle = rotate * TWO_PI
    if bug == "linear_zoom":
        scale = (zoom - F32(0.5)) * F32(4.0)
    else:
        scale = F32(10.0) ** ((zoom - F32(0.5)) * F32(5.0))
    cos_a = np.cos(angle).astype(F32)
    sin_a = np.sin(angle).astype(F32)
    if bug == "swap_rot_terms":
        rot_x = (cos_a * zx + sin_a * zy) * scale
        rot_y = (-sin_a * zx + cos_a * zy) * scale
    else:
        rot_x = (cos_a * zx - sin_a * zy) * scale
        rot_y = (sin_a * zx + cos_a * zy) * scale

    # inversion path: 1/z = conjugate(z) / |z|^2, singularity guarded
    if bug == "no_guard":
        mag_sq = zx * zx + zy * zy
    else:
        mag_sq = np.maximum(zx * zx + zy * zy, GUARD)
    inv_x = zx / mag_sq
    inv_y = (-zy / mag_sq) if bug != "sign_flip_inv_y" else (zy / mag_sq)

    # blend
    out_x = _mix(rot_x, inv_x, invert)
    out_y = _mix(rot_y, inv_y, invert)

    # offset back + repeat wrap
    if bug == "wrap_shift":
        uv_x = _fract(out_x) + cx
        uv_y = _fract(out_y) + cy
    else:
        uv_x = _fract(out_x + cx)
        uv_y = _fract(out_y + cy)

    # sample + bypass
    effect_out = g.sample(src, uv_x, uv_y)
    out1 = _mix(effect_out, g.sample(src, norm_x, norm_y), bypass)
    return out1