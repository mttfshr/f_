"""
ngon_mirror.py -- NumPy mirror of the f_ngon shader: the shipped inline codebox
(inline in src/f_ngon/definition.py),
float32, in the codebox's own order of operations.

The codebox folds each pixel's `snorm` coordinate (norm mapped to [-1, 1]) by up to 32
alternating reflections across two mirror lines at angle 0 and theta = pi/n_mirrors
(branchless `step`/`mix` per iteration), after rotating by -rotation and scaling by
1/scale. It then samples in1 at uv = z * 0.5 + 0.5 (clamped to [0.001, 0.999] texel-centre bounds,
bilinear, clamp-to-edge) and blends against an unwarped read of in1 by `bypass`.

The fold loop's branch choice is step(zy, 0.0) => reflect across the x-axis when
zy <= 0, and step(crossTheta, 0.0) => reflect across the theta-line when
crossTheta <= 0 (GenExpr step follows GLSL step(edge, x): 0 if x < edge, else 1).
Ties (a pixel exactly on a mirror line) sit on a comparison edge and are avoided by
the tests, per the brief.

`bug` values are the mutations the tests must catch:
  "exact_clamp" -- the pre-2026-10-20 clamp to exactly [0, 1]: a read at exactly x = 1.0
    lands on the seam and returns the FIRST column on the GPU (y = 0.0 the last row),
    so a fold past the right edge showed the wrong edge (caught by its own test only),
  "rot_sign"   -- rotate by +rotation instead of -rotation (sign flip in the trig),
  "no_scale"   -- forget to divide by scale (missing normalization),
  "theta_2pi"  -- wrong constant: theta = 2*pi/n_mirrors instead of pi/n_mirrors,
  "step_swap"  -- the historical bug from ideas/f_ngon.md: the theta containment test
                  written step(0.0, crossTheta) instead of step(crossTheta, 0.0).
"""
import math

import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1) - t) + b * t).astype(F32)


def _step(edge, x):
    """GenExpr step(edge, x) = 0 if x < edge else 1, elementwise, float32."""
    return np.where(x < edge, F32(0), F32(1)).astype(F32)


def ngon(src, n_mirrors=6.0, rotation=0.0, scale=1.0, bypass=0.0, bug=None):
    """One pass. src: (H, W, 4) float32. Returns (H, W, 4) float32."""
    h, w = src.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    theta = F32(np.pi) / F32(n_mirrors)
    if bug == "theta_2pi":
        theta = F32(2 * np.pi) / F32(n_mirrors)

    snx = (nx * F32(2) - F32(1)).astype(F32)
    sny = (ny * F32(2) - F32(1)).astype(F32)
    if bug == "no_scale":
        inv = F32(1.0)
    else:
        inv = F32(1.0) / F32(scale)
    zx0 = (snx * inv).astype(F32)
    zy0 = (sny * inv).astype(F32)

    rot = F32(rotation)
    if bug == "rot_sign":
        rot = -rot
    cr = F32(math.cos(F32(0.0) - rot))
    sr = F32(math.sin(F32(0.0) - rot))
    zx = (zx0 * cr - zy0 * sr).astype(F32)
    zy = (zx0 * sr + zy0 * cr).astype(F32)

    for i in range(32):
        sin_t = F32(math.sin(theta))
        cos_t = F32(math.cos(theta))
        test0 = _step(zy, F32(0.0))
        cross_theta = (zx * sin_t - zy * cos_t).astype(F32)
        if bug == "step_swap":
            test1 = _step(F32(0.0), cross_theta)
        else:
            test1 = _step(cross_theta, F32(0.0))

        ct = F32(math.cos(F32(2.0) * theta))
        st = F32(math.sin(F32(2.0) * theta))

        newzx0 = zx
        newzy0 = F32(0.0) - zy
        newzx1 = (ct * zx + st * zy).astype(F32)
        newzy1 = (st * zx - ct * zy).astype(F32)

        zx = _mix(_mix(zx, newzx1, test1), newzx0, test0)
        zy = _mix(_mix(zy, newzy1, test1), newzy0, test0)

    if bug == "uv_sign":
        uv_x = (zx * F32(0.5) - F32(0.5)).astype(F32)
        uv_y = (zy * F32(0.5) - F32(0.5)).astype(F32)
    else:
        uv_x = (zx * F32(0.5) + F32(0.5)).astype(F32)
        uv_y = (zy * F32(0.5) + F32(0.5)).astype(F32)
    lo, hi = (F32(0.0), F32(1.0)) if bug == "exact_clamp" else (F32(0.001), F32(0.999))
    uv_x = np.clip(uv_x, lo, hi).astype(F32)
    uv_y = np.clip(uv_y, lo, hi).astype(F32)

    effect_out = g.sample(src, uv_x, uv_y)
    base = g.sample(src, nx, ny)
    return _mix(effect_out, base, F32(bypass))