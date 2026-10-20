"""
vf_seeds_mirror.py -- NumPy mirror of the f_vf_seeds chain's Stage 1c (merge) and Stage 4
(composite), float32, in the codeboxes' own order of operations.

Sources: src/f_vf_seeds/codebox_seeds_merge.gen and codebox_seeds_composite.gen (Stage 1c
of the six-stage pix_chain, then Stage 4). The search stages (1a/1b, hash-driven candidate
grids) and the render stages (2/3) are NOT mirrored here.

All six merge reads are at exactly vec(norm.x, norm.y), so the codebox reads the pixel at
its own position; the mirror takes the textures as (H, W, 4) arrays directly (per the brief,
allowed where the codebox reads at exactly norm). Coordinate textures carry
(gx, gy, dx, dy) in x, y, z, w; priority textures carry two priorities in x, y. Composite
inputs are (H, W, 4) rank renders (mark_r, mark_g, mark_b, mark_a).

GLSL semantics used (same as the exemplar's): step(edge, x) is 1 when x >= edge else 0;
mix(a, b, t) is a * (1 - t) + b * t. In the codebox t0 = step(priA2, priA1) with
best = mix(priA1, priA2, t0): rank A's second candidate becomes best when priA1 >= priA2,
i.e. ties go to the A-pair's rank-2 slot.

`bug` values are the mutations the tests must catch:
  "swap_step_pair"    -- the A-pair selection's step arguments swapped (A1 kept instead of A2
                         on the tie/branch), a plausible slip inside the first swap line
  "skip_second_demote"-- the demoted candidate's insertion into second (the t2 lines) dropped
  "out3_carries_offsets"-- out3 packed as (gx, gy, dx, dy) instead of the zero-padded
                         (gx, gy, 0.0, 1.0) contract
  "composite_reversed"-- composite blend factor taken from rank 2's alpha: comp = mix(c1, c2, a2)
  "no_bypass_out2"    -- Stage 4's bypass blend dropped from the out2 mark-mask path
"""
import numpy as np

F32 = np.float32


def _mix(a, b, t):
    """GLSL mix: a * (1 - t) + b * t."""
    return a * (F32(1.0) - t) + b * t


def _step(edge, x):
    """GLSL step: 1 when x >= edge, else 0."""
    return (x >= edge).astype(F32)


def merge_stage(coordA1, coordA2, priA, coordB1, coordB2, priB, bypass=0.0, bug=None):
    """Stage 1c: keep the best two of four candidates by LOWER priority value.

    Returns (out1, out2, out3): rank-1 coord (gx, gy, dx, dy), rank-2 coord,
    and the seed-coord contract outlet (best gx, best gy, 0, 1), blended to
    (0, 0, 0, 1) by `bypass`.
    """
    byp = F32(bypass)
    gxA1, gyA1, dxA1, dyA1 = (coordA1[..., i] for i in range(4))
    gxA2, gyA2, dxA2, dyA2 = (coordA2[..., i] for i in range(4))
    priA1, priA2 = priA[..., 0], priA[..., 1]
    gxB1, gyB1, dxB1, dyB1 = (coordB1[..., i] for i in range(4))
    gxB2, gyB2, dxB2, dyB2 = (coordB2[..., i] for i in range(4))
    priB1, priB2 = priB[..., 0], priB[..., 1]

    if bug == "swap_step_pair":
        t0 = _step(priA1, priA2)
    else:
        t0 = _step(priA2, priA1)
    best_pri = _mix(priA1, priA2, t0)
    best_gx = _mix(gxA1, gxA2, t0)
    best_gy = _mix(gyA1, gyA2, t0)
    best_dx = _mix(dxA1, dxA2, t0)
    best_dy = _mix(dyA1, dyA2, t0)
    second_pri = _mix(priA2, priA1, t0)
    second_gx = _mix(gxA2, gxA1, t0)
    second_gy = _mix(gyA2, gyA1, t0)
    second_dx = _mix(dxA2, dxA1, t0)
    second_dy = _mix(dyA2, dyA1, t0)

    # first half candidate B1 competes at best, the loser competes at second
    t = _step(priB1, best_pri)
    demoted_pri = _mix(priB1, best_pri, t)
    demoted_gx = _mix(gxB1, best_gx, t)
    demoted_gy = _mix(gyB1, best_gy, t)
    demoted_dx = _mix(dxB1, best_dx, t)
    demoted_dy = _mix(dyB1, best_dy, t)
    best_pri = _mix(best_pri, priB1, t)
    best_gx = _mix(best_gx, gxB1, t)
    best_gy = _mix(best_gy, gyB1, t)
    best_dx = _mix(best_dx, dxB1, t)
    best_dy = _mix(best_dy, dyB1, t)
    if bug == "skip_second_demote":
        pass
    else:
        t2 = _step(demoted_pri, second_pri)
        second_pri = _mix(second_pri, demoted_pri, t2)
        second_gx = _mix(second_gx, demoted_gx, t2)
        second_gy = _mix(second_gy, demoted_gy, t2)
        second_dx = _mix(second_dx, demoted_dx, t2)
        second_dy = _mix(second_dy, demoted_dy, t2)

    # candidate B2, same insertion
    t = _step(priB2, best_pri)
    demoted_pri = _mix(priB2, best_pri, t)
    demoted_gx = _mix(gxB2, best_gx, t)
    demoted_gy = _mix(gyB2, best_gy, t)
    demoted_dx = _mix(dxB2, best_dx, t)
    demoted_dy = _mix(dyB2, best_dy, t)
    best_pri = _mix(best_pri, priB2, t)
    best_gx = _mix(best_gx, gxB2, t)
    best_gy = _mix(best_gy, gyB2, t)
    best_dx = _mix(best_dx, dxB2, t)
    best_dy = _mix(best_dy, dyB2, t)
    if bug == "skip_second_demote":
        pass
    else:
        t2 = _step(demoted_pri, second_pri)
        second_pri = _mix(second_pri, demoted_pri, t2)
        second_gx = _mix(second_gx, demoted_gx, t2)
        second_gy = _mix(second_gy, demoted_gy, t2)
        second_dx = _mix(second_dx, demoted_dx, t2)
        second_dy = _mix(second_dy, demoted_dy, t2)

    out1 = np.stack([best_gx, best_gy, best_dx, best_dy], axis=-1).astype(F32)
    out2 = np.stack([second_gx, second_gy, second_dx, second_dy], axis=-1).astype(F32)
    if bug == "out3_carries_offsets":
        pad = np.stack([best_gx, best_gy, best_dx, best_dy], axis=-1).astype(F32)
    else:
        zero = np.zeros_like(best_gx)
        one = np.ones_like(best_gx)
        pad = np.stack([best_gx, best_gy, zero, one], axis=-1).astype(F32)
    black = np.stack([np.zeros_like(best_gx)] * 3 + [np.ones_like(best_gx)], axis=-1).astype(F32)
    out3 = _mix(pad, black, byp)
    return out1, out2, out3


def composite_stage(r1, r2, bypass=0.0, bug=None):
    """Stage 4: rank-1-over-rank-2 alpha composite; out2 = composited alpha as gray.

    Returns (out1, out2).
    """
    byp = F32(bypass)
    r, g, b, a1 = r1[..., 0], r1[..., 1], r1[..., 2], r1[..., 3]
    r2_, g2_, b2_, a2 = r2[..., 0], r2[..., 1], r2[..., 2], r2[..., 3]
    if bug == "composite_reversed":
        comp_r = _mix(r, r2_, a2)
        comp_g = _mix(g, g2_, a2)
        comp_b = _mix(b, b2_, a2)
    else:
        comp_r = _mix(r2_, r, a1)
        comp_g = _mix(g2_, g, a1)
        comp_b = _mix(b2_, b, a1)
    comp_a = a1 + a2 * (F32(1.0) - a1)
    comp = np.stack([comp_r, comp_g, comp_b, comp_a], axis=-1).astype(F32)
    out1 = _mix(comp, np.zeros_like(comp), byp)
    if bug == "out2_grayscale_rgba":
        mask = _mix(comp, np.zeros_like(comp), byp)
    elif bug == "no_bypass_out2":
        mask = np.stack([comp_a, comp_a, comp_a, np.ones_like(comp_a)], axis=-1).astype(F32)
    else:
        black = np.stack([np.zeros_like(comp_a)] * 3 + [np.ones_like(comp_a)], axis=-1).astype(F32)
        mask = _mix(np.stack([comp_a, comp_a, comp_a, np.ones_like(comp_a)], axis=-1).astype(F32),
                    black, byp)
    return out1, mask


def seeds_chain(coordA1, coordA2, priA, coordB1, coordB2, priB, render1, render2,
                bypass=0.0, bug=None):
    """The merged chain order: Stage 1c feeds render stages (not mirrored) whose outputs
    feed Stage 4 with `bypass` on both mirror passes."""
    out1, out2, out3 = merge_stage(coordA1, coordA2, priA, coordB1, coordB2, priB, bypass=bypass, bug=bug)
    c1, mask = composite_stage(render1, render2, bypass=bypass, bug=bug)
    return c1, mask, out3