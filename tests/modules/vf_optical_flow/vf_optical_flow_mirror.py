"""
vf_optical_flow_mirror.py -- NumPy mirror of f_vf_optical_flow's Stage C, a hand translation
of src/f_vf_optical_flow/codebox_stage_c.gen (the shipped codebox), float32, in the
codebox's own order of operations.

Stage C is a pure per-pixel function: the codebox samples in1 (Sxx, Syy, Sxy) and in2
(Sxt, Syt) at exactly `norm`, so the mirror may index the arrays directly at the texel
(the arrays are already arranged [row = y, col = x], matching texel [iy, ix] there is no
interpolation or coordinate arithmetic to model -- gpu_sim.sample at norm reduces to the
identity read at every texel centre).

Mirror of the codebox, in its order:
    sxx, syy, sxy = in1 at norm (x, y, z); sxt, syt = in2 at norm (x, y)
    det = sxx*syy - sxy*sxy
    det_safe = max(det, 0.0001)          # floor used ONLY for the division
    mag = sqrt((sxx-syy)^2 + (2*sxy)^2);  mag_safe = max(mag, 0.0001)
    cos2t = (sxx-syy)/mag_safe;  sin2t = (2*sxy)/mag_safe
    u = (-sxt*syy + sxy*syt)/det_safe;   v = (-sxx*syt + sxy*sxt)/det_safe
    field = vec(clamp(u*gain*0.5 + 0.5, 0, 1), clamp(v*gain*0.5 + 0.5, 0, 1), 0.5, 1)
    mask = smoothstep(mask_lo, mask_hi, det)
    field_masked = mix(neutral (0.5, 0.5, 0.5, 1), field, mask)
    out1 = mix(field_masked, neutral, bypass)
    out2 = mix(vec(det, cos2t*0.5+0.5, sin2t*0.5+0.5, 1), vec(0, 0.5, 0.5, 1), bypass)

`bug` values are the deliberate mutations the tests must catch:
    "flip_u"      -- the u Cramer term's sign flipped (+sxt*syy instead of -sxt*syy)
    "floor_mask"  -- the mask uses det_safe (the floored det) instead of raw det (out2.x stays raw)
    "no_floor"    -- det divided raw, with no 1e-4 floor
    "axis_minor"  -- the axis sign flipped: sin2t stored as -(2*sxy)/mag_safe
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32
FLOOR = F32(0.0001)


def _mix(a, b, t):
    """GenExpr / GLSL mix, elementwise with the mask broadcast over RGBA:
    a * (1 - t) + b * t."""
    if t.ndim == a.ndim - 1:
        t = t[..., None]
    return (a * (F32(1.0) - t) + b * t).astype(F32)


def _smoothstep(lo, hi, x):
    t = np.clip((x - lo) / (hi - lo), F32(0.0), F32(1.0)).astype(F32)
    return (t * t * (F32(3.0) - F32(2.0) * t)).astype(F32)


def stage_c(in1, in2, gain=1.0, mask_lo=0.0, mask_hi=1.0, bypass=0.0, bug=None):
    """in1, in2: (H, W, 4) float32 textures, read at norm (texel centres, clamp irrelevant
    at norm). Returns (out1, out2)."""
    h, w = in1.shape[:2]
    _, _, _, _ = g.grid(h, w)  # norm == texel centres; the read below is exactly sample(in, norm)
    sxx = in1[..., 0]
    syy = in1[..., 1]
    sxy = in1[..., 2]
    sxt = in2[..., 0]
    syt = in2[..., 1]

    det = (sxx * syy - sxy * sxy).astype(F32)
    det_safe = np.maximum(det, FLOOR).astype(F32)

    dx = (sxx - syy).astype(F32)
    sy2 = (F32(2.0) * sxy).astype(F32)
    mag = np.sqrt(dx * dx + sy2 * sy2).astype(F32)
    mag_safe = np.maximum(mag, FLOOR).astype(F32)
    if bug == "axis_minor":
        sin2t = (-sy2 / mag_safe).astype(F32)
    else:
        sin2t = (sy2 / mag_safe).astype(F32)
    cos2t = (dx / mag_safe).astype(F32)

    if bug == "flip_u":
        u = ((sxt * syy + sxy * syt) / det_safe).astype(F32)
        v = (-sxx * syt + sxy * sxt) / det_safe
        v = v.astype(F32)
    elif bug == "no_floor":
        with np.errstate(divide="ignore", invalid="ignore"):
            u = (-sxt * syy + sxy * syt) / det
            v = (-sxx * syt + sxy * sxt) / det
        u, v = u.astype(F32), v.astype(F32)
    else:
        u = (-sxt * syy + sxy * syt) / det_safe
        v = (-sxx * syt + sxy * sxt) / det_safe
        u, v = u.astype(F32), v.astype(F32)

    field = np.stack([
        np.clip(u * F32(gain) * F32(0.5) + F32(0.5), F32(0.0), F32(1.0)).astype(F32),
        np.clip(v * F32(gain) * F32(0.5) + F32(0.5), F32(0.0), F32(1.0)).astype(F32),
        np.full((h, w), F32(0.5)),
        np.ones((h, w), F32),
        ], axis=-1).astype(F32)
    neutral = np.stack([np.full((h, w), F32(0.5)), np.full((h, w), F32(0.5)),
                        np.full((h, w), F32(0.5)), np.ones((h, w), F32)], axis=-1).astype(F32)

    if bug == "floor_mask":
        mask = _smoothstep(F32(mask_lo), F32(mask_hi), det_safe)
    else:
        mask = _smoothstep(F32(mask_lo), F32(mask_hi), det)
    field_masked = _mix(neutral, field, mask)

    out1 = _mix(field_masked, neutral, F32(bypass))
    raw2 = np.stack([det,
                     (cos2t * F32(0.5) + F32(0.5)).astype(F32),
                     (sin2t * F32(0.5) + F32(0.5)).astype(F32),
                     np.ones((h, w), F32)], axis=-1).astype(F32)
    zero2 = np.stack([np.zeros((h, w), F32), np.full((h, w), F32(0.5)),
                      np.full((h, w), F32(0.5)), np.ones((h, w), F32)], axis=-1).astype(F32)
    out2 = _mix(raw2, zero2, F32(bypass))
    return out1, out2