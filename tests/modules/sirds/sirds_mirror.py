"""
sirds_mirror.py -- NumPy mirror of the f_sirds 13-stage strip stereogram chain:
src/f_sirds/codebox_stage0.gen (stage 0, the reference tile) and
src/f_sirds/codebox_stage_n.gen (stages 1..12, identical apart from the baked
stage_index), rendered with strip_width = 1/13.

float32 throughout, in the codebox's own order of operations. Stage 0 reads
in2 nowhere; each depth stage reads the previous stage's output at in1 (the
chain wiring) and the depth texture at in2. Sampling is gpu_sim's bilinear
texel-centre clamp-to-edge `sample`; strip boundaries never pass through a
texel centre when the texture width is a multiple of 13, so the `step` gates
never tie. The shift coordinate is wrapped with mod(., 1) before the sample: the codebox has no
mod, but a GPU sample() wraps its coordinate modulo 1 (probes P2 and P6 and the pix-to-pix
scratch patch, 2026-10-20), so negative shift_x reads (strip 1 at negative depth_factor) come from
the right-hand side. (The author wrote this; a review removed it as 'not in the codebox' and
was wrong; test_negative_shift_reads_wrap_like_the_gpu now needs it.)

`bug` values are the mutations the tests must catch:
  - "no_shift": every depth stage passes the previous stage through (the
    strip gate is applied to a copy of the undisplaced sample instead of the
    displaced one - a plausible transcription slip).
  - "no_remap": the depth stage reads the depth map at raw uv.x instead of the
    remapped coordinate (uv.x - strip_width) / (1 - strip_width).
  - "wrong_luma": the B and G luma weights are swapped (0.299, 0.114, 0.587).
  - "gate_out": in_strip is inverted - the stage displaces everywhere except its own
    strip instead of only inside it (the gate branch, not the gate inputs).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32

NUM_STRIPS = 12
STRIP_WIDTH = F32(1.0) / F32(NUM_STRIPS + 1)   # 1/13

LUMA = (F32(0.299), F32(0.587), F32(0.114))


def stage0(pattern, bug=None):
    """codebox_stage0: uv = norm; local_x = mod(uv.x, w)/w; sample in1 at (local_x, uv.y)."""
    h, w = pattern.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    local_x = np.mod(nx, STRIP_WIDTH) / STRIP_WIDTH
    return g.sample(pattern, local_x.astype(F32), ny)


def stage_n(chain, depth, stage_index, depth_factor=0.0, bypass=0.0, bug=None):
    """codebox_stage_n at baked stage_index (1..12). in1 = previous stage's output,
    in2 = depth texture. Returns the stage's out1."""
    h, w = chain.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    sw = STRIP_WIDTH
    strip_lo = F32(stage_index) * sw
    strip_hi = strip_lo + sw

    in_strip = (step(strip_lo, nx) * step(nx, strip_hi) * (F32(1.0) - F32(bypass))).astype(F32)

    if bug == "no_remap":
        depth_u = nx
    else:
        depth_u = (nx - sw) / (F32(1.0) - sw)
    d = g.sample(depth, depth_u.astype(F32), ny)
    if bug == "wrong_luma":
        depth_val = d[..., 0] * LUMA[0] + d[..., 2] * LUMA[1] + d[..., 1] * LUMA[2]
    else:
        depth_val = d[..., 0] * LUMA[0] + d[..., 1] * LUMA[1] + d[..., 2] * LUMA[2]
    shift_x = (nx - sw + depth_val * F32(depth_factor) * sw)

    if bug == "no_shift":
        computed = g.sample(chain, nx, ny)
    else:
        computed = g.sample(chain, np.mod(shift_x, F32(1.0)).astype(F32), ny)
    passthrough = g.sample(chain, nx, ny)

    gate = (F32(1.0) - in_strip) if bug == "gate_out" else in_strip
    return mix(passthrough, computed, gate[..., None])


def step(edge, x):
    """GLSL step: 0.0 when x < edge, else 1.0."""
    return np.where(np.asarray(x, dtype=F32) < np.asarray(edge, dtype=F32), F32(0.0), F32(1.0))


def mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    return (a * (F32(1.0) - t) + b * t).astype(F32)


def sirds_chain(pattern, depth, depth_factor=0.0, bypass=0.0, bug=None):
    """The whole 13-stage chain: stage 0, then stages 1..12 in order.
    pattern: (H, W, 4) float32 (inlet 0). depth: (H, W, 4) float32 (inlet 2;
    an unconnected inlet reads (0, 0, 0, 1) as g.texture does). Returns the
    stage-12 output."""
    out = stage0(pattern, bug=bug).astype(F32)
    for i in range(1, NUM_STRIPS + 1):
        out = stage_n(out, depth, i, depth_factor=depth_factor, bypass=bypass, bug=bug)
    return out.astype(F32)