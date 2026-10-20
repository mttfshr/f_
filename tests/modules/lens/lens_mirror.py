"""
lens_mirror.py -- NumPy mirror of f_lens: two jit.gl.pix stages in series, float32,
in each codebox's own order of operations.

Stage 1 (lens_pix; the inline codebox in src/f_lens/definition.py, = codebox_lens.gen): in1 source, in2 aberration
modulation, in3 distortion modulation, in4 transmission modulation, in5 surface
gradient. All four modulation textures are read as .x; an unconnected inlet reads
the constant (0,0,0,1) (skill: "An unconnected jit.gl.pix inlet reads a constant"),
so every modulation is 0 for an unconnected inlet at any *_mod dial. The codebox
samples in2/in3/in4 at plain uv and in5 at uv, uv+(eps,0), uv+(0,eps).
Stage 2 (lens_halation; src/f_lens/codebox_halation.gen): its in1 is stage 1's
output (pix_chain in src/f_lens/definition.py: lens_pix -> lens_halation -> outlet).
Sampling everywhere is gpu_sim's bilinear texel-centre `sample`, clamp-to-edge.

`bug` values are the mutations the tests must catch ("ghost_ab_off", which swaps the sign of the ghost taps'
aberration, is a documented branch the tests' BUGS list does not exercise):
- "pincushion": the distortion warp factor's sign flipped ((1 - k*r2) instead of (1 + k*r2)).
- "swap_ab": the red and blue aberration offsets swapped ((1-ab) for red, (1+ab) for blue).
- "no_vignette": the vignette factor made smoothstep(dist_v) instead of 1 - smoothstep(dist_v).
- "no_ghost_norm": the ghost taps are not divided by the weight sum.
- "ghost_w_doc": the fourth ghost weight is the doc's 0.6^(n-1) = 0.216 instead of the codebox's 0.22.
- "ghost_floor_doc": ghost_count is floor()'d as the doc says instead of the codebox's floor(gc + 0.5).
- "halation_no_norm": the halation ring sum divided by 1 instead of wsum.
- "halation_radius": the outer ring radius is 0.02 instead of the codebox's 0.03.
"""
import numpy as np

import gpu_sim as g

F32 = np.float32


def _mix(a, b, t):
    """GenExpr mix(a, b, t): a * (1 - t) + b * t."""
    return (a * (F32(1.0) - t) + b * t).astype(F32)


def _clamp(x, lo, hi):
    return np.clip(x, F32(lo), F32(hi)).astype(F32)


def _smoothstep(e0, e1, x):
    """GenExpr smoothstep(e0, e1, x): t = clamp((x - e0)/(e1 - e0), 0, 1); t*t*(3 - 2*t)."""
    t = _clamp((x - F32(e0)) / (F32(e1) - F32(e0)), 0.0, 1.0)
    return (t * t * (F32(3.0) - F32(2.0) * t)).astype(F32)


def _gc(ghost_count):
    """The codebox's tap count: floor(ghost_count + 0.5) -- a round, not the doc's floor()."""
    return int(np.floor(F32(ghost_count) + F32(0.5)))


def lens_stage(src, aberr_tex=None, dist_tex=None, trans_tex=None, surf_tex=None,
               aberration=0.0, distortion=0.0, transmission=0.0,
               aberration_mod=0.0, distortion_mod=0.0, transmission_mod=0.0,
               surface_mod=0.0, ghost=0.0, ghost_count=3.0, ghost_spacing=0.3,
               bypass=0.0, bug=None):
    """The lens_pix pass. src and each modulation texture: (H, W, 4) float32;
    None models an unconnected inlet (the constant (0,0,0,1))."""
    h, w = src.shape[:2]
    nx, ny, _, _ = g.grid(h, w)

    def tex(t):
        if t is None:
            z = g.texture(h, w)
            z[..., 3] = F32(1.0)
            return z
        return t

    uvx, uvy = nx, ny
    cx = (uvx - F32(0.5)).astype(F32)
    cy = (uvy - F32(0.5)).astype(F32)
    dist = np.sqrt(cx * cx + cy * cy).astype(F32)

    ab_tex = g.sample(tex(aberr_tex), uvx, uvy)[..., 0]
    di_tex = g.sample(tex(dist_tex), uvx, uvy)[..., 0]
    tr_tex = g.sample(tex(trans_tex), uvx, uvy)[..., 0]

    eps = F32(0.002)
    surf_c = g.sample(tex(surf_tex), uvx, uvy)[..., 0]
    surf_r = g.sample(tex(surf_tex), (uvx + eps).astype(F32), uvy)[..., 0]
    surf_u = g.sample(tex(surf_tex), uvx, (uvy + eps).astype(F32))[..., 0]

    k = (F32(distortion) * (F32(1.0) + di_tex * F32(distortion_mod))).astype(F32)
    if bug == "pincushion":
        k = (-k).astype(F32)
    r2 = (cx * cx + cy * cy).astype(F32)
    warp_cx = (cx * (F32(1.0) + k * r2)).astype(F32)
    warp_cy = (cy * (F32(1.0) + k * r2)).astype(F32)
    warp_uv_x = (F32(0.5) + warp_cx).astype(F32)
    warp_uv_y = (F32(0.5) + warp_cy).astype(F32)

    surf_dx = ((surf_r - surf_c) * F32(surface_mod)).astype(F32)
    surf_dy = ((surf_u - surf_c) * F32(surface_mod)).astype(F32)
    warp_uv_x = (warp_uv_x + surf_dx).astype(F32)
    warp_uv_y = (warp_uv_y + surf_dy).astype(F32)
    warp_cx = (warp_uv_x - F32(0.5)).astype(F32)
    warp_cy = (warp_uv_y - F32(0.5)).astype(F32)

    ab = (F32(aberration) * dist * (F32(1.0) + ab_tex * F32(aberration_mod))).astype(F32)
    ab_p = (F32(1.0) + ab).astype(F32)
    ab_m = (F32(1.0) - ab).astype(F32)
    if bug == "swap_ab":
        ab_p, ab_m = ab_m, ab_p
    r_uv_x = (F32(0.5) + warp_cx * ab_p).astype(F32)
    r_uv_y = (F32(0.5) + warp_cy * ab_p).astype(F32)
    b_uv_x = (F32(0.5) + warp_cx * ab_m).astype(F32)
    b_uv_y = (F32(0.5) + warp_cy * ab_m).astype(F32)
    r_val = g.sample(src, r_uv_x, r_uv_y)[..., 0]
    g_val = g.sample(src, warp_uv_x, warp_uv_y)[..., 1]
    b_val = g.sample(src, b_uv_x, b_uv_y)[..., 2]
    effect_out = np.stack([r_val, g_val, b_val, np.ones_like(r_val)], axis=-1).astype(F32)

    dist_v = (dist * (F32(1.0) + tr_tex * F32(transmission_mod))).astype(F32)
    if bug == "no_vignette":
        vignette = _smoothstep(F32(0.3), F32(0.7), dist_v)
    else:
        vignette = (F32(1.0) - _smoothstep(F32(0.3), F32(0.7), dist_v)).astype(F32)
    warm_shift = np.stack([np.full(dist.shape, F32(1.05)), np.ones(dist.shape, F32),
                           np.full(dist.shape, F32(0.92)), np.ones(dist.shape, F32)],
                          axis=-1).astype(F32)
    t = (F32(1.0) - F32(transmission)).astype(F32)
    tinted = (effect_out * warm_shift * vignette[..., None]).astype(F32)
    effect_out = _mix(tinted, effect_out, t)

    gc = _gc(ghost_count) if bug != "ghost_floor_doc" else int(np.floor(F32(ghost_count)))
    gate2 = F32(1.0) if gc >= 2 else F32(0.0)
    gate3 = F32(1.0) if gc >= 3 else F32(0.0)
    gate4 = F32(1.0) if gc >= 4 else F32(0.0)
    atten1 = F32(1.0)
    atten2 = (F32(0.6) * gate2).astype(F32)
    atten3 = (F32(0.36) * gate3).astype(F32)
    atten4 = (F32(0.216) * gate4 if bug == "ghost_w_doc" else F32(0.22) * gate4).astype(F32)
    w_sum = (atten1 + atten2 + atten3 + atten4).astype(F32)
    attens = [atten1, atten2, atten3, atten4]

    ghost_r = ghost_g = ghost_b = None
    for i in range(4):
        osi = (F32(1.0) + F32(ghost_spacing) * F32(i + 1)).astype(F32)
        ar = (ab_p if bug != "ghost_ab_off" else ab_m)
        br = (ab_m if bug != "ghost_ab_off" else ab_p)
        gx = (F32(0.5) + warp_cx * osi).astype(F32)
        gy = (F32(0.5) + warp_cy * osi).astype(F32)
        rx = (F32(0.5) + warp_cx * osi * ar).astype(F32)
        ry = (F32(0.5) + warp_cy * osi * ar).astype(F32)
        bx = (F32(0.5) + warp_cx * osi * br).astype(F32)
        by = (F32(0.5) + warp_cy * osi * br).astype(F32)
        tr_ = g.sample(src, rx, ry)[..., 0] * attens[i]
        tg_ = g.sample(src, gx, gy)[..., 1] * attens[i]
        tb_ = g.sample(src, bx, by)[..., 2] * attens[i]
        if i == 0:
            ghost_r, ghost_g, ghost_b = tr_, tg_, tb_
        else:
            ghost_r = (ghost_r + tr_).astype(F32)
            ghost_g = (ghost_g + tg_).astype(F32)
            ghost_b = (ghost_b + tb_).astype(F32)

    div = F32(1.0) if bug == "no_ghost_norm" else w_sum
    ghost_r, ghost_g, ghost_b = (ghost_r / div).astype(F32), (ghost_g / div).astype(F32), \
        (ghost_b / div).astype(F32)
    ghost_vec = np.stack([ghost_r, ghost_g, ghost_b, np.zeros_like(ghost_r)], axis=-1).astype(F32)
    effect_out = (effect_out + ghost_vec * F32(ghost)).astype(F32)

    s0 = g.sample(src, uvx, uvy)
    t2 = F32(bypass)
    out1 = np.stack([_mix(effect_out[..., 0], s0[..., 0], t2),
                     _mix(effect_out[..., 1], s0[..., 1], t2),
                     _mix(effect_out[..., 2], s0[..., 2], t2),
                     _mix(effect_out[..., 3], s0[..., 3], t2)], axis=-1).astype(F32)
    return out1


def halation_stage(src, halation=0.0, halation_threshold=0.7, bypass=0.0, bug=None):
    """The lens_halation pass. src is the lens stage's output, (H, W, 4) float32."""
    h, w = src.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    w1, w2 = F32(1.0), F32(0.5)

    dirs = [(1.0, 0.0), (0.7071, 0.7071), (0.0, 1.0), (-0.7071, 0.7071),
            (-1.0, 0.0), (-0.7071, -0.7071), (0.0, -1.0), (0.7071, -0.7071)]
    radius2 = F32(0.02) if bug == "halation_radius" else F32(0.03)
    radius1 = F32(0.015)

    denom = np.maximum(F32(1.0) - F32(halation_threshold), F32(0.0001)).astype(F32)
    wsum = (F32(1.0) + F32(0.5)) * F32(8.0) if bug != "halation_no_norm" else F32(1.0)

    src_px = g.sample(src, nx, ny)
    src_r, src_g, src_b, src_a = src_px[..., 0], src_px[..., 1], src_px[..., 2], src_px[..., 3]

    acc_r = acc_g = acc_b = F32(0.0)
    for dx, dy in dirs:
        for radius, wt in ((radius1, w1), (radius2, w2)):
            c = g.sample(src, (nx + F32(dx) * radius).astype(F32),
                         (ny + F32(dy) * radius).astype(F32))
            lm = (c[..., 0] * F32(0.2126) + c[..., 1] * F32(0.7152) + c[..., 2] * F32(0.0722)).astype(F32)
            br = _clamp((lm - F32(halation_threshold)) / denom, 0.0, 1.0)
            acc_r = (acc_r + c[..., 0] * br * wt).astype(F32)
            acc_g = (acc_g + c[..., 1] * br * wt).astype(F32)
            acc_b = (acc_b + c[..., 2] * br * wt).astype(F32)

    glow_r, glow_g, glow_b = (acc_r / wsum).astype(F32), (acc_g / wsum).astype(F32), \
        (acc_b / wsum).astype(F32)
    t_h = F32(halation)
    comp_r = _clamp(src_r + glow_r * F32(1.1) * t_h, 0.0, 1.0)
    comp_g = _clamp(src_g + glow_g * F32(1.0) * t_h, 0.0, 1.0)
    comp_b = _clamp(src_b + glow_b * F32(0.85) * t_h, 0.0, 1.0)

    t2 = F32(bypass)
    out1 = np.stack([_mix(comp_r, src_r, t2), _mix(comp_g, src_g, t2),
                     _mix(comp_b, src_b, t2), _mix(src_a, src_a, t2)], axis=-1).astype(F32)
    return out1


def lens_chain(src, halation=0.0, halation_threshold=0.7, halation_bypass=0.0,
               bug=None, **kw):
    """The whole module: lens_pix, then lens_halation on its output (pix_chain in
    src/f_lens/definition.py; stage order lens_pix -> lens_halation -> outlet0)."""
    mid = lens_stage(src, bug=bug, **kw)
    return halation_stage(mid, halation=halation, halation_threshold=halation_threshold,
                          bypass=halation_bypass, bug=bug)