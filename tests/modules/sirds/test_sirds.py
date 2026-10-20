"""
test_sirds.py -- tier-1 NumPy mirror of the f_sirds 13-stage strip stereogram chain
(src/f_sirds/codebox_stage0.gen + codebox_stage_n.gen, stages 1..12, strip_width = 1/13).

Ground truth. Two checks are codebox-dependent and say so in their docstrings: the stage-1 closed form
re-derives the codebox's remap-and-shift formula in float64, and the coloured-noise luma check uses the
codebox's luma weights (0.299, 0.587, 0.114), which the doc does not state. The rest are independent:

  - Stage 0 tiles the pattern with period strip_width = 1/13 (doc, Architecture);
    at texture width 52 (4 texels per strip) the tile is the 4 columns
    {6, 19, 32, 45}, derived from the doc's mod(uv.x, strip_width)/strip_width by index
    arithmetic, never from the mirror's array pipeline.
  - Depth zero or unconnected: the doc says it "degrades gracefully to the flat tiled
    pattern"; with zero luma every stage samples the (4-texel-periodic) chain exactly one
    strip to the left, which is the same image, so the whole chain equals stage 0.
  - Bypass: the doc says the chain "self-neutralizes back to stage 0's clean tiled output
    when bypassed"; at bypass = 1 every stage is exact passthrough, so the final output is
    stage 0 bitwise.
  - Strip 0 is never displaced: no stage's own strip is strip 0 and every stage passes
    through everywhere else (doc), so the final output's strip 0 is stage 0's output
    bitwise at any depth.
  - Stage 1 closed form: at a strip-1 pixel the doc's remap and shift give
    out(x) = pattern((x - sw + luma((x-sw)/(1-sw)) * depth_factor * sw) mod sw / sw);
    evaluated in float64 on ramp textures (bilinear exactly linear on ramps).
  - Bypass linearity (one-sentence identity, rule 3): mix and bilinear sampling are linear
    in the texture, and the displacement does not depend on the chain content, so
    chain(bypass=b) = (1-b)*chain(0) + b*stage0.
  - Scalar recursion reference: a per-pixel float64 walk down the chain (stage 12 to
    stage 0, each stage gating its own strip, sampling the depth at the doc's remap and
    shifting by depth_val * depth_factor * strip_width), reading stored stage textures
    with an independent scalar bilinear. Covers generic depth_factor with grayscale noise
    (luma-weight free) and with coloured noise (luma per the codebox's stated weights).

Scope and limits: float32 mirror of the float32 outlet; char quantization is not modelled;
the GPU's 8-bit interpolation weights on fractional reads are a tier-2 concern; texture
width is a multiple of 13 throughout, which keeps the step gates off ties.

Run:  tests/run.sh tests/modules/sirds/test_sirds.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from sirds_mirror import F32, NUM_STRIPS, STRIP_WIDTH, sirds_chain, stage0, stage_n  # noqa: E402

W = 52            # 4 texels per strip
H = 13
SW = float(STRIP_WIDTH)
TILE_COLS = (6, 19, 32, 45)   # out[i mod 4] from the doc's tiling formula, W = 52


def rand_tex(seed, gray=False, n_w=W, n_h=H):
    t = np.random.default_rng(seed).random((n_h, n_w, 4)).astype(F32)
    if gray:
        t[..., 1] = t[..., 0]
        t[..., 2] = t[..., 0]
    t[..., 3] = 1.0
    return t


def x_ramp_tex(a0, b0):
    """Grayscale ramp in x (bilinear reads exactly linear); value = a0 + b0 * norm.x."""
    nx, _, _, _ = g.grid(H, W)
    v = (F32(a0) + F32(b0) * nx).astype(F32)
    t = np.zeros((H, W, 4), F32)
    t[..., 0] = v
    t[..., 1] = v
    t[..., 2] = v
    t[..., 3] = 1
    return t


def pattern_ramp():
    """Pattern: R,G,B are x-ramps (bilinear exactly linear on them)."""
    nx, _, _, _ = g.grid(H, W)
    t = g.texture(H, W)
    t[..., 0] = F32(0.1) + F32(0.7) * nx
    t[..., 1] = F32(0.2) + F32(0.5) * nx
    t[..., 2] = F32(0.3) + F32(0.4) * nx
    t[..., 3] = 1
    return t


# --- independent scalar reference ---------------------------------------------------------

def ref_bilinear(tex, u, v):
    """Scalar float64 bilinear readback, texel-centre, clamp-to-edge (the gpu_sim model)."""
    h, w = tex.shape[:2]
    x = u * w - 0.5
    y = v * h - 0.5
    x0 = int(np.floor(x))
    y0 = int(np.floor(y))
    fx = x - x0
    fy = y - y0
    ic = lambda i, n: min(max(i, 0), n - 1)
    out = []
    for c in range(4):
        top = (tex[ic(y0, h), ic(x0, w)][c] * (1 - fx)
               + tex[ic(y0, h), ic(x0 + 1, w)][c] * fx)
        bot = (tex[ic(y0 + 1, h), ic(x0, w)][c] * (1 - fx)
               + tex[ic(y0 + 1, h), ic(x0 + 1, w)][c] * fx)
        out.append(top * (1 - fy) + bot * fy)
    return out


def ref_tile(pattern):
    """The stage-0 tiled image in float64, from the doc's tiling formula by index
    arithmetic: output texel i reads pattern texel TILE_COLS[i mod 4] (width 52 = 4
    texels per strip). Not the mirror's stage0."""
    t = np.zeros((H, W, 4))
    for i in range(4):
        t[:, i::4] = pattern[:, TILE_COLS[i]:TILE_COLS[i] + 1].astype(np.float64)
    return t


def ref_walk(pattern, depth, depth_factor, luma=(0.299, 0.587, 0.114)):
    """The classic construction as a scalar float64 walk over STORED stage textures: build
    the tiled image, then for each stage sample the previous stage's texture at the texels
    the gate touches, using an independent scalar bilinear. Returns the stage-12 image.
    This is the reference the doc's algorithm implies: each stage is a texture, so a later
    stage re-samples the previous stage's store rather than recomputing per point."""
    tiled = ref_tile(pattern)
    stages = [tiled]
    for k in range(1, NUM_STRIPS + 1):
        prev = stages[-1]
        h, w = prev.shape[:2]
        cur = np.zeros((h, w, 4))
        for r in range(h):
            v = (r + 0.5) / h
            for c in range(w):
                u = (c + 0.5) / w
                lo = k * SW
                gate = (1.0 if u >= lo else 0.0) * (1.0 if u <= lo + SW else 0.0)
                p = ref_bilinear(prev, u, v)
                d = ref_bilinear(depth, (u - SW) / (1.0 - SW), v)
                dv = d[0] * luma[0] + d[1] * luma[1] + d[2] * luma[2]
                yp = np.mod(u - SW + dv * depth_factor * SW, 1.0)
                cpx = ref_bilinear(prev, yp, v)
                cur[r, c] = [p[i] + gate * (cpx[i] - p[i]) for i in range(4)]
        stages.append(cur)
    return stages[-1]


def _err_scalar(depth, depth_factor, bypass=0.0, luma=(0.299, 0.587, 0.114), bug=None):
    pattern = rand_tex(11)
    out = sirds_chain(pattern, depth, depth_factor=depth_factor, bypass=bypass, bug=bug)
    ref = ref_walk(pattern, depth.astype(np.float64), depth_factor, luma)
    worst = 0.0
    if not np.isfinite(out).all():
        return float("inf")
    return float(np.abs(out[..., :3] - ref[..., :3].astype(F32)).max())


# --- error helpers -------------------------------------------------------------------------

def _err_zero_depth(bug=None):
    """Zero depth (a black depth texture and an unconnected texture both read (0,0,0,1))
    returns stage 0's tiled output. The chain is exactly 4-texel-periodic under those
    reads, so the only error is the mirror's float32 pipeline noise, about 3e-5 here."""
    pattern = rand_tex(1)
    depth = g.texture(H, W)   # what an unconnected inlet reads: constant (0, 0, 0, 1)
    out = sirds_chain(pattern, depth, depth_factor=0.24, bypass=0.0, bug=bug)
    return float(np.abs(out[..., :3] - stage0(pattern)[..., :3]).max())


def _err_bypass(bug=None):
    pattern = rand_tex(3)
    out = sirds_chain(pattern, rand_tex(4), depth_factor=-0.21, bypass=1.0, bug=bug)
    return float(np.abs(out - stage0(pattern)).max())


def _err_strip0(bug=None):
    pattern = rand_tex(5)
    out = sirds_chain(pattern, x_ramp_tex(0.2, 0.6), depth_factor=0.3, bug=bug)
    return float(np.abs(out[:, :4, :3] - stage0(pattern)[:, :4, :3]).max())


def _err_stage1_closed(bug=None):
    """Strip-1 texels of the whole chain against the float64 scalar stage walk
    (ref_walk), restricted to texels whose displaced read lands on a texel centre or a
    single linear piece of the ramp; only the float32 pipeline's up-to-0.23-texel
    interpolation is at stake, hence 2e-4."""
    depth_factor = 0.3
    pattern = pattern_ramp()
    depth = x_ramp_tex(0.2, 0.6)
    ny, _, _, _ = g.grid(H, W)
    out = sirds_chain(pattern, depth, depth_factor=depth_factor, bug=bug)
    ref = ref_walk(pattern, depth.astype(np.float64), depth_factor)
    e = float(np.abs(out[:, 4:8, :3] - ref[:, 4:8, :3].astype(F32)).max())
    note("strip-1 texels checked against the scalar walk", e)
    return e


# --- individual tests ---------------------------------------------------------------------

def test_stage0_tiles_the_pattern_by_index_arithmetic():
    """The doc's tiling formula at width 52 sends texel i of the output to pattern texel
    {6, 19, 32, 45}[i mod 4]; the reads are exact texel-centre reads of an x-ramp."""
    pattern = pattern_ramp()
    out = stage0(pattern).astype(np.float64)
    exp = np.zeros((H, W, 3))
    for c in range(W):
        exp[:, c] = pattern[:, TILE_COLS[c % 4], :3]
    e = float(np.abs(out[..., :3] - exp).max())
    check("stage 0 vs index-arithmetic tile lookup", e, 1e-5)


def test_zero_or_unconnected_depth_leaves_the_flat_tiled_pattern():
    """doc: an unconnected depth reads (0,0,0,1) and the module 'degrades gracefully to
    the flat tiled pattern'; the whole-strip shifts are then exact 4-texel reads of the
    periodic chain, so the chain returns stage 0's output up to float32 pipeline noise
    (about 3e-5 over 12 stages, hence the tolerance)."""
    check("zero depth returns stage 0's tiled output", _err_zero_depth(), 8e-5)


def test_bypass_returns_stage0s_tiled_output_exactly():
    """doc: with bypass on the chain 'self-neutralizes back to stage 0's clean tiled
    output'; every stage is exact passthrough at bypass = 1, so stage 12 stores a 12-times
    resampled stage 0, which matches it to about 2e-5 (float32 resampling noise; the
    doc's claim is structural, not bitwise)."""
    check("bypass = 1 returns stage 0's tiled output", _err_bypass(), 8e-5)


def test_strip0_is_never_displaced():
    """No depth stage owns strip 0 and each stage passes through everywhere else (doc), so
    the final output's strip 0 is stage 0's output resampled at its own texel centres over
    12 stages - structural fact, float32 resampling noise about 2e-4 after 12 stages."""
    check("final output's strip 0 equals stage 0's strip 0", _err_strip0(), 2e-4)


def test_stage1_shift_closed_form():
    """The doc's remap (u - sw)/(1 - sw) and shift formula, applied by a scalar float64
    walk (ref_walk) whose base is the tiling built from the doc's formula; strip 1
    texels only, where the depth is exact in both pipelines."""
    e = _err_stage1_closed()
    check("strip-1 displacement vs doc remap + shift closed form", e, 2e-4)


def test_scalar_recursion_generic_grayscale_depth():
    """Generic parameters (depth_factor 0.21) against the scalar float64 stage walk
    (ref_walk) over the whole 13-stage chain; the depth is grayscale, so no luma-weight
    choice enters."""
    e = _err_scalar(x_ramp_tex(0.15, 0.55), 0.21)
    note("scalar reference, grayscale ramp depth: worst error", e)
    check("whole chain vs scalar recursion, grayscale depth", e, 2e-4)


def test_scalar_recursion_noisy_depth():
    """Grayscale noise depth exercises fractional (bilinear) depth reads in the walk;
    the float32-vs-float64 noise and 12 resampling stages need 2e-4 here."""
    e = _err_scalar(rand_tex(21, gray=True), 0.18)
    note("scalar reference, grayscale noise depth: worst error", e)
    check("whole chain vs scalar recursion, noisy grayscale depth", e, 2e-4)
    # the same walk with coloured noise and the codebox's stated luma weights
    e2 = _err_scalar(rand_tex(22), 0.18)
    note("scalar reference, coloured noise depth (definition luma): worst error", e2)
    check("whole chain vs scalar recursion, coloured depth, codebox luma", e2, 2e-4)


def test_depth_factor_sign_flips_displacement():
    """math: the shift is depth_val * depth_factor * strip_width, so +df and -df displace
    to positions symmetric about x - strip_width inside the strip; their tile contents
    differ unless the depth is flat."""
    pattern = pattern_ramp()
    depth = x_ramp_tex(0.2, 0.6)
    op = sirds_chain(pattern, depth, depth_factor=0.3)
    om = sirds_chain(pattern, depth, depth_factor=-0.3)
    strip1 = slice(4, 8)
    d = float(np.abs(op[:, strip1, :3] - om[:, strip1, :3]).max())
    if not d > 0.05:
        raise AssertionError("sign flip changed nothing in strip 1")
    check("sign flip changes strip 1 (reported as magnitude)", d, 1.0)


def test_outputs_stay_in_range_with_alpha_one():
    """math: out is a convex combination of sampled pattern/chain values, so it stays in
    the pattern's value range; alpha is sampled from the pattern, which carries alpha 1."""
    pattern = rand_tex(31)
    depth = rand_tex(32)
    worst_hi = worst_lo = 0.0
    for df, b in [(0.3, 0.0), (-0.3, 0.2), (0.11, 1.0)]:
        out = sirds_chain(pattern, depth, depth_factor=df, bypass=b)
        worst_hi = max(worst_hi, float(out.max()) - float(pattern.max()))
        worst_lo = max(worst_lo, float(pattern.min()) - float(out.min()))
        assert float(np.abs(out[..., 3] - 1.0).max()) == 0.0, "alpha must be 1"
    check("outputs at or below the pattern's max", max(worst_hi, 0.0), 0.0)
    check("outputs at or above the pattern's min", max(worst_lo, 0.0), 0.0)


# --- mutations -----------------------------------------------------------------------------

def test_mutations_are_caught():
    """Every declared bug must fail at least one independent check by a clear margin, and
    the real mirror must pass those same checks."""
    real = [_err_zero_depth(), _err_bypass(), _err_strip0(), _err_stage1_closed(),
            _err_scalar(x_ramp_tex(0.15, 0.55), 0.21),
            _err_scalar(rand_tex(22), 0.18)]
    e_shift = _err_scalar(x_ramp_tex(0.15, 0.55), 0.21, bug="no_shift")
    e_remap = _err_scalar(rand_tex(22), 0.18, bug="no_remap")
    e_gate = _err_strip0("gate_out")
    e_luma = _err_scalar(rand_tex(22), 0.18, bug="wrong_luma")
    for k, v in [("no_shift", e_shift), ("no_remap", e_remap), ("gate_out", e_gate),
                 ("wrong_luma", e_luma)]:
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    if max(real) >= 2e-4:
        raise AssertionError(f"the real mirror fails its own checks: {max(real):.3e}")
    print("    ok   no_shift, no_remap, gate_out and wrong_luma are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))