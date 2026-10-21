"""
test_vf_streak.py -- tier-1 NumPy mirror of the f_vf_streak shader (src/f_vf_streak/codebox_v1.gen;
.specify/f_vf_streak/tasks.md T056, decided 2026-10-19: mirror by choice -- the codebox is a fixed 8-step
unrolled march whose checks are invariants and closed forms, so the constitution rule alone would allow a skip).

Ground truth is independent of the mirror:

  - Zero or unconnected field: every march step samples the current pixel, so the streak layer equals the source
    for any falloff the weights normalize over, and the composite is mix(src, clamp(src * (1 + gain)), mix_pct).
  - Weight sum in closed form: sum_n (1 - falloff * n / 7) = 8 - 4 * falloff. It is ZERO at falloff = 2.0, which is
    inside the dial's 0-2.5 range (noted below, not asserted away).
  - Uniform field over a linear ramp (bilinear is exact on ramps): the streak layer is the ramp evaluated at the
    weighted mean position u - f * step * (sum w_n n / sum w_n), with the chromatic offsets +-f * cs on R and B.
  - Whole-texel marches (length and color_shift chosen so every offset is a whole number of texels): the streak
    layer is a weighted mean of shifted source columns, by index arithmetic.
  - Bypass passes the source on both outlets.
  - Mutations the tests must catch: marching forward, not normalizing by the weight sum, swapped R/B offsets.

Scope and limits: the clamp-to-edge sampling model; the bench GPU wraps out-of-range reads, so tests use pixels
whose march stays inside the frame, or whole-texel cases (a tier-2 bench would settle the edge). Non-uniform
fields are covered by the zero-field and uniform-field cases only.

Run:  tests/run.sh tests/modules/vf_streak/test_vf_streak.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_streak_mirror import F32, streak_stage, weights  # noqa: E402

N = 32


def const_tex(rgba, n=N):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def vec_tex(fx, fy, n=N):
    """Vecfield texture whose decoded flow is (fx, fy): R,G = 0.5 + f / 2 (exact for dyadic values)."""
    return const_tex((0.5 + fx / 2.0, 0.5 + fy / 2.0, 0.5, 1.0), n)


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def w64(falloff):
    """Step weights in float64, from the formula, not from the mirror."""
    return np.array([1.0 - falloff * n / 7.0 for n in range(8)])


# --- weights and zero field -----------------------------------------------------------

def test_weight_sum_closed_form():
    worst = 0.0
    for fo in [0.0, 0.5, 1.0, 1.5, 2.4, 2.5]:
        worst = max(worst, abs(float(sum(weights(fo))) - (8.0 - 4.0 * fo)))
    check("weights sum vs 8 - 4*falloff", worst, 1e-5)
    at2 = abs(float(sum(weights(2.0))))
    note("weight sum at falloff = 2.0 (the dial range is 0 to 2.5)", at2)
    src = rand_tex(1)
    out1, out2 = streak_stage(src, vec_tex(0.0, 0.0), falloff=2.0)
    bad = int((~np.isfinite(out2)).sum())
    err = float(np.nanmax(np.abs(out2[..., :3] - src[..., :3])))
    note("falloff 2.0, zero field: non-finite streak values", bad)
    note("falloff 2.0, zero field: worst |streak - source| over finite values", err)
    if at2 > 1e-5:
        raise AssertionError("expected the weights to cancel at falloff 2.0")


def test_zero_and_unconnected_field_gives_the_source():
    src = rand_tex(2)
    worst = 0.0
    for fo in [0.0, 0.5, 1.0, 1.5, 2.4]:
        for label, vec, conn in [("neutral", vec_tex(0.0, 0.0), 1.0), ("unconnected", g.texture(N, N), 0.0)]:
            out1, out2 = streak_stage(src, vec, falloff=fo, length=0.3, color_shift=3.0, src_vecfield=conn)
            worst = max(worst, float(np.abs(out2[..., :3] - src[..., :3]).max()))
    check("streak layer equals the source (zero / unconnected field, falloff 0..2.4)", worst, 2e-6)


def test_composite_closed_form():
    src = rand_tex(3)
    worst = 0.0
    for gain, m in [(0.5, 70.0), (1.5, 100.0), (0.3, 0.0)]:
        out1, _ = streak_stage(src, vec_tex(0.0, 0.0), gain=gain, mix_pct=m)
        s = src[..., :3].astype(np.float64)
        expect = s * (1 - m / 100) + m / 100 * np.clip(s + s * gain, 0, 1)
        worst = max(worst, float(np.abs(out1[..., :3] - expect.astype(F32)).max()))
        assert float(np.abs(out1[..., 3] - 1.0).max()) == 0.0
    check("composite vs mix(src, clamp(src*(1+gain)), mix_pct)", worst, 2e-6)


# --- uniform field ----------------------------------------------------------------------

def _ramp_src():
    u, v, _, _ = g.grid(N, N)
    s = g.texture(N, N)
    s[..., 0] = F32(0.1) + F32(0.6) * u
    s[..., 1] = F32(0.2) + F32(0.5) * v
    s[..., 2] = F32(0.3) + F32(0.4) * u
    s[..., 3] = F32(1)
    return s, u.astype(np.float64), v.astype(np.float64)


def _ramp_err(falloff, bug=None):
    fx, fy, length, color_shift = 0.5, -0.25, 0.2, 1.5
    src, u, v = _ramp_src()
    _, out2 = streak_stage(src, vec_tex(fx, fy), length=length, falloff=falloff, color_shift=color_shift, bug=bug)
    step = length / 8.0
    cs = color_shift * step
    wn = w64(falloff)
    mn = float((wn * np.arange(8)).sum() / wn.sum())
    lo, hi = 0.5 / N, 1 - 0.5 / N
    inside = np.ones_like(u, bool)
    for n in range(8):
        for sx in (-cs * fx, 0.0, cs * fx):
            px = u - n * fx * step + sx
            inside &= (px >= lo) & (px <= hi)
        py = v - n * fy * step
        inside &= (py >= lo) & (py <= hi)
    assert inside.sum() > N * N // 4, "too little of the frame left to compare"
    expect = np.zeros(u.shape + (3,))
    expect[..., 0] = 0.1 + 0.6 * (u - fx * step * mn + fx * cs)
    expect[..., 1] = 0.2 + 0.5 * (v - fy * step * mn)
    expect[..., 2] = 0.3 + 0.4 * (u - fx * step * mn - fx * cs)
    return float(np.abs(out2[..., :3] - expect.astype(F32))[inside].max())


def test_uniform_field_on_a_ramp():
    for fo in [0.0, 0.6]:
        check(f"ramp at the weighted mean position, falloff {fo}", _ramp_err(fo), 2e-6)


# --- whole-texel marches -------------------------------------------------------------------

def _texel_err(bug=None):
    falloff = 0.5
    src = rand_tex(4)
    # length 0.25 -> step 1/32; color_shift 2 -> cs = 2/32; field +x at full scale: every offset is whole texels
    _, out2 = streak_stage(src, vec_tex(1.0, 0.0), length=0.25, falloff=falloff, color_shift=2.0, bug=bug)
    wn = w64(falloff)
    idx = np.arange(N)
    expect = np.zeros((N, N, 3))
    for c, shift in enumerate((+2, 0, -2)):       # R samples +cs, G the centre, B -cs along +field x
        acc = np.zeros((N, N))
        for n in range(8):
            xi = np.mod(idx - n + shift, N)      # the shader does not clamp its march: the GPU wraps x (2026-10-20 probes)
            acc += wn[n] * src[:, xi, c].astype(np.float64)
        expect[..., c] = acc / wn.sum()
    return float(np.abs(out2[..., :3] - np.clip(expect, 0, 1).astype(F32)).max())


def test_whole_texel_march_by_index_arithmetic():
    check("8-step march with chromatic offsets vs index arithmetic", _texel_err(), 2e-6)


# --- bypass and range -----------------------------------------------------------------------

def test_bypass_passes_the_source_on_both_outlets():
    src, vec = rand_tex(5), rand_tex(6)
    o1, o2 = streak_stage(src, vec, gain=1.2, mix_pct=80.0, length=0.5, falloff=1.0, color_shift=4.0, bypass_gate=1.0)
    check("bypass out1 equals the source", float(np.abs(o1 - src).max()), 1e-6)
    check("bypass out2 equals the source", float(np.abs(o2 - src).max()), 1e-6)


def test_outputs_stay_in_range_with_opaque_alpha():
    src, vec = rand_tex(7), rand_tex(8)
    worst_hi = worst_lo = 0.0
    for gain, m, length, fo, cs in [(1.5, 100.0, 2.0, 1.5, 3.0), (0.3, 50.0, 0.15, 0.0, 0.0), (1.0, 100.0, 20.0, 1.0, 20.0)]:
        for o in streak_stage(src, vec, gain=gain, mix_pct=m, length=length, falloff=fo, color_shift=cs):
            worst_hi = max(worst_hi, float(o.max()) - 1.0)
            worst_lo = max(worst_lo, -float(o.min()))
            assert float(np.abs(o[..., 3] - 1.0).max()) == 0.0, "alpha must be 1"
    check("outputs at or below 1", max(worst_hi, 0.0), 0.0)
    check("outputs at or above 0", max(worst_lo, 0.0), 0.0)


# --- mutations ----------------------------------------------------------------------------------

def _normalize_err(bug=None):
    src = rand_tex(9)
    _, out2 = streak_stage(src, vec_tex(0.0, 0.0), falloff=1.0, bug=bug)
    return float(np.abs(out2[..., :3] - src[..., :3]).max())


def test_mutations_are_caught():
    real = [_ramp_err(0.0), _texel_err(), _normalize_err()]
    bad = {"forward": max(_texel_err("forward"), _ramp_err(0.0, "forward")),
           "no_normalize": _normalize_err("no_normalize"),
           "swap_rb": _texel_err("swap_rb")}
    for k, v in bad.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    assert max(real) < 1e-5, f"the real mirror must pass the same checks: {real}"
    print("    ok   forward march, a missing normalization and swapped R/B offsets are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))
