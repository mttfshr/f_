"""
Tier-1 NumPy tests for f_vf_glow, against the mirror in vf_glow_mirror.py.

Ground truth is independent of the codebox: the reference doc's statements
(the zero / unconnected-field passthrough; the exponential falloff; the
direction modes; radius_eff = radius + mod * radius clamped to 0.3; the
driven composite; color_mix's luma at 1; the 2026-10-05 all-outlets
bypass passthrough) and math identities of linear ramps under bilinear
sampling.

The three looser tolerances are needed because the shader jitters each march
step by +-0.05 steps: the doc fixes that amplitude, so a closed-form expected
value must tolerate its spread times the ramp slope. No check recomputes the
per-step jitter hash: the jitter-free mean, pairwise-cancellation and
same-jitter-ratio formulations make the hash drop out of every expected value.

Expected values never retype a codebox line.
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_glow_mirror import F32, glow_stage  # noqa: E402

N = 32
BIG = 64  # the ramp / mean-step frame: big enough to hold a long effective march
BUGS = ("sign_flip", "no_normalize", "swap_rb", "double_falloff")


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


def ramp_src(n=BIG):
    """Linear ramps: R linear in u, G linear in v, B constant. Bilinear sampling
    of a linear ramp reproduces the ramp exactly in float64."""
    ux, vy, _, _ = g.grid(n, n)
    t = g.texture(n, n)
    t[..., 0] = F32(0.1) + F32(0.6) * ux
    t[..., 1] = F32(0.2) + F32(0.5) * vy
    t[..., 2] = F32(0.4)
    t[..., 3] = F32(1.0)
    return t, ux.astype(np.float64), vy.astype(np.float64)


def w64(falloff, keep=None):
    """The 48 step weights in float64 from the doc's Algorithm formula
    (w = exp(-i * i * falloff)), not from the mirror. With keep set, steps
    beyond `keep` are zeroed, and the trimmed tail is asserted to carry under
    3e-5 of the total weight."""
    i = np.arange(1, 49, dtype=np.float64)
    w = np.exp(-(i * i) * falloff)
    if keep is not None:
        w[keep:] = 0.0
        assert (i[w == 0].size == 0) or w[keep:].sum() <= 3e-5 * w.sum(), \
            "w64's trimmed tail must stay negligible"
    return w


def mean_step(falloff, keep=None):
    """The weights' weighted mean step, in float64 from the doc's formula."""
    w = w64(falloff, keep)
    i = np.arange(1, 49, dtype=np.float64)
    return float((w * i).sum() / w.sum())


def ramp_mask(FX, FY, radius, ux, vy, falloff):
    """Pixels whose whole weight-bearing march (any step with weight over
    3e-5 of the total, plus the documented +-0.05-step jitter) stays inside
    the linear part of both ramps; a quarter of the frame must survive, as in
    the vf_streak exemplar."""
    lo, hi = 1.5 / BIG, 1.0 - 1.5 / BIG
    imax = np.arange(1, 49, dtype=np.float64)[w64(falloff) > 3e-5 * w64(falloff).sum()]
    reach = radius * (float(imax.max()) + 0.05) if imax.size else radius * 1.05
    inside = np.ones_like(ux, bool)
    inside &= (ux - abs(FX) * reach >= lo) & (ux + abs(FX) * reach <= hi)
    inside &= (vy - abs(FY) * reach >= lo) & (vy + abs(FY) * reach <= hi)
    assert inside.sum() > BIG * BIG // 4, "too little of the frame left to compare"
    return inside


# --- zero / unconnected field ---------------------------------------------------------

def _zero_field_err(bug=None):
    src = rand_tex(1)
    worst = 0.0
    for falloff in [0.0, 0.002, 0.01, 0.05]:
        for label, vec in [("neutral", vec_tex(0.0, 0.0)), ("unconnected", g.texture(N, N))]:
            out1, out2 = glow_stage(src, vec, falloff=falloff, direction=1.0, bug=bug)
            worst = max(worst, float(np.abs(out2[..., :3] - src[..., :3]).max()),
                        float(np.abs(out1[..., :3] - src[..., :3]).max()))
    return worst


def test_zero_field_gives_the_source():
    """Doc: with the field zeroed each step samples the source pixel itself, and
    with the default mix_pct 0 the output equals the source."""
    check("glow and composite equal the source (neutral / unconnected field, falloff 0..0.05, dir 1)",
          _zero_field_err(), 2e-6)


# --- direction modes on a ramp ----------------------------------------------------------

def _ramp_err(direction, bug=None, falloff=0.01, radius=0.01):
    FX, FY = 0.625, -0.25
    src, ux, vy = ramp_src()
    _, out2 = glow_stage(src, vec_tex(FX, FY), radius=radius, falloff=falloff,
                         direction=float(direction), bug=bug)
    dx, dy = FX * radius, FY * radius
    mm = mean_step(falloff)
    expect = np.zeros((BIG, BIG, 3))
    if direction == 1:
        ex, ey = dx * mm, dy * mm          # forward only: glow at the forward weighted mean
    elif direction == 2:
        ex, ey = -dx * mm, -dy * mm        # backward only
    else:
        ex = ey = 0.0                      # bidirectional: the +- displacements cancel on a ramp
    expect[..., 0] = 0.1 + 0.6 * (ux + ex)
    expect[..., 1] = 0.2 + 0.5 * (vy + ey)
    expect[..., 2] = 0.4
    inside = ramp_mask(FX, FY, radius, ux, vy, falloff)
    return float(np.abs(out2[..., :3] - expect.astype(F32))[inside].max())


def test_bidirectional_cancels_on_a_ramp():
    check("direction 0: glow equals the source on a ramp (march pairs cancel)", _ramp_err(0), 2e-6)


def test_forward_trail_sits_at_the_mean_step():
    """3e-4: the expected value is the jitter-free weighted mean position; the
    doc's per-step jitter shifts it by its own mean over 48 draws times the
    channel slope, which concentrates to well under this tolerance."""
    check("direction 1: glow at the mean forward position", _ramp_err(1), 3e-4)
    check("direction 2: glow at the mean backward position", _ramp_err(2), 3e-4)


# --- radius modulation -------------------------------------------------------------------

def _mod_err(radius, mod_val, frame=64):
    """Mean-step displacement with modulation vs the unmodulated displacement
    scaled by the doc's radius_eff ratio (2x normally; 1.5x when the clamped
    cap at 0.3 binds); the per-step jitter (same uv, same i) cancels in the
    ratio. The clamp case needs a big frame: radius_eff 0.3 with a falloff
    whose weight-bearing steps reach 28 is a march far beyond a 64-wide frame
    at a visible field, so it uses an fx of 0.02 (the doc's smallest
    expressive radius) on a 256-wide frame."""
    falloff = 0.01
    clamped = radius + mod_val * radius > 0.3
    radius_eff = min(radius + mod_val * radius, 0.3)
    frame, fx = (256, 0.02) if clamped else (128, 0.1)
    src, ux, vy = ramp_src(frame)
    vec = vec_tex(fx, -0.25, frame)
    _, out0 = glow_stage(src, vec, radius=radius, falloff=falloff, direction=1.0)
    _, out1 = glow_stage(src, vec, mod=const_tex((mod_val, 0, 0, 1), frame), radius=radius,
                         falloff=falloff, direction=1.0)
    d0 = out0[..., 0].astype(np.float64) - (0.1 + 0.6 * ux)   # the x ramp: displacement along fx
    d1 = out1[..., 0].astype(np.float64) - (0.1 + 0.6 * ux)
    imax = float(np.arange(1, 49, dtype=np.float64)[w64(falloff) > 3e-5 * w64(falloff).sum()].max())
    lo, hi = 1.5 / frame, 1.0 - 1.5 / frame
    reach = radius_eff * (imax + 0.05) * abs(fx)
    inside = (ux - reach >= lo) & (ux + reach <= hi) & (vy - reach >= lo) & (vy + reach <= hi)
    assert inside.sum() > frame * frame // 4, "too little of the frame left to compare"
    expect = radius_eff / radius * d0
    return float(np.abs(d1 - expect)[inside].max())


def test_radius_modulation_scales_the_displacement():
    """Doc: radius_eff = radius + mod * radius, so at full modulation (1.0) the
    effective radius doubles and the mean-step displacement doubles too."""
    check("radius mod 1.0 doubles the mean displacement", _mod_err(0.01, 1.0), 5e-5)


def test_radius_eff_is_clamped_at_03():
    """3e-4 (jitter spread at the doubled displacement): radius_eff is clamped
    at 0.3 in the doc's Algorithm, so radius 0.2 with mod 1.0 sits at the
    clamp: 1.5x the unmodulated mean-step displacement, not 2x."""
    check("radius 0.2 + full mod is clamped to 0.3 (1.5x, not 2x)", _mod_err(0.2, 1.0), 3e-4)


# --- composite at the neutral field -------------------------------------------------------

def test_composite_closed_form_at_zero_field():
    """Doc: driven = clamp(src + glow * gain); with the glow = the source at a
    zero field, the composite is mix(src, clamp(src*(1+gain)), mix_pct/100)."""
    src = rand_tex(3)
    worst = 0.0
    for gain, mp in [(0.5, 70.0), (1.5, 100.0), (0.8, 0.0)]:
        out1, _ = glow_stage(src, vec_tex(0.0, 0.0), gain=gain, mix_pct=mp)
        s = src[..., :3].astype(np.float64)
        expect = s * (1 - mp / 100) + mp / 100 * np.clip(s * (1 + gain), 0, 1)
        worst = max(worst, float(np.abs(out1[..., :3] - expect.astype(F32)).max()))
    check("composite vs mix(src, clamp(src*(1+gain)), mix_pct/100) at a zero field", worst, 2e-6)


# --- color_mix / luma ----------------------------------------------------------------------

def test_color_mix_one_is_luma_only():
    """Doc: color_mix 1 = luma-only glow. At a zero field the glow is the
    source color-mixed to luma, so a luma-only source must come back with all
    three channels identical."""
    src = rand_tex(4)
    src[..., 0] = src[..., 1] = src[..., 2]  # a luma-only source
    _, out2 = glow_stage(src, vec_tex(0.0, 0.0), color_mix=1.0)
    eq = max(float(np.abs(out2[..., 0] - out2[..., 1]).max()),
             float(np.abs(out2[..., 1] - out2[..., 2]).max()))
    check("color_mix 1: glow channels are identical for a luma-only source", eq, 0.0)


def test_color_mix_half_is_the_midpoint():
    """mix is the standard linear blend, so color_mix 0.5 must give each
    channel the midpoint of its color_mix 0 and color_mix 1 values."""
    src = rand_tex(5)
    _, o0 = glow_stage(src, vec_tex(0.0, 0.0), color_mix=0.0)
    _, o1 = glow_stage(src, vec_tex(0.0, 0.0), color_mix=1.0)
    _, oh = glow_stage(src, vec_tex(0.0, 0.0), color_mix=0.5)
    e = float(np.abs(oh[..., :3] - (o0[..., :3].astype(np.float64) + o1[..., :3]) / 2.0).max())
    check("color_mix 0.5 is the channel midpoint of 0 and 1", e, 1e-6)


# --- bypass ---------------------------------------------------------------------------------

def test_bypass_passes_the_source_on_both_outlets():
    """Doc (2026-10-05 rule): bypassed, out0 and out1 both pass through, out1's
    bypassed value being the unprocessed source."""
    src, vec, mod = rand_tex(6), rand_tex(7), rand_tex(8)
    o1, o2 = glow_stage(src, vec, mod=mod, gain=1.5, mix_pct=100.0, radius=0.2, falloff=0.05,
                        color_mix=1.0, direction=2.0, bypass_gate=1.0)
    check("bypass out1 equals the source", float(np.abs(o1 - src).max()), 1e-6)
    check("bypass out2 equals the source", float(np.abs(o2 - src).max()), 1e-6)


# --- mutations ------------------------------------------------------------------------------

def _mutation_errors(bug):
    worst = max(_ramp_err(1, bug=bug), _ramp_err(2, bug=bug), _ramp_err(0, bug=bug),
                _zero_field_err(bug=bug))
    if bug == "double_falloff":
        worst = max(worst, _mod_err(0.01, 1.0))
    return worst


def test_mutations_are_caught():
    """The real mirror must pass all the checks above, and every injected bug
    must fail them by a clear margin. double_falloff passes the ramp checks
    only in their mean-only form, so it is also run through the mod-double
    check, which is sensitive to the mean step shifting with the falloff."""
    src = rand_tex(3)
    real = [_ramp_err(0), _ramp_err(1), _ramp_err(2), _zero_field_err(),
            _mod_err(0.01, 1.0)]
    comp_out, _ = glow_stage(src, vec_tex(0.0, 0.0), gain=1.5, mix_pct=100.0)
    s = src[..., :3].astype(np.float64)
    real.append(float(np.abs(comp_out[..., :3] - np.clip(s * 2.5, 0, 1).astype(F32)).max()))
    # color_mix 1 at a zero field: the glow layer is the source's luma on every channel. Expected from the standard
    # Rec. 709 luma weights (the doc says "luma-only" without listing them), never from another mirror output.
    _, o1 = glow_stage(src, vec_tex(0.0, 0.0), color_mix=1.0)
    luma64 = (s[..., 0] * 0.2126 + s[..., 1] * 0.7152 + s[..., 2] * 0.0722)[..., None]
    real.append(float(np.abs(o1[..., :3].astype(np.float64) - luma64).max()))
    assert max(real) < 1e-3, f"the real mirror must pass the same checks: {max(real):.3e}"

    bad = {}
    for k in BUGS:
        bad[k] = _mutation_errors(k)
        note(f"mutation '{k}' worst error", bad[k])
        if not bad[k] > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {bad[k]:.3e})")
    print("    ok   sign flip, missing normalization, swapped R/B channels and doubled falloff are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))
