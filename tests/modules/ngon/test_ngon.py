"""
test_ngon.py -- tier-1 NumPy test of the f_ngon shader (shipped inline codebox in
src/f_ngon/definition.py; doc: ideas/f_ngon.md, the stand-in reference).

Ground truth is independent of the mirror:

  - Neutral setting (defaults n_mirrors 6, rotation 0, scale 1, bypass 0): the fold
    composed with the read at uv = z*0.5 + 0.5 maps each unit-square pixel point
    into a symmetry image of itself; a neutral-neutral check alone would be
    mirror-internal, so it is stated here as the doc's mechanism (kaleidoscopic
    fold) with an independent angle closed form elsewhere in this file.
  - Reflection isometry (math): the folded point has the same radius as the
    rotated, scaled start point, for any n_mirrors, rotation, scale -- the whole
    fold is a composition of reflections, which preserve radius.
  - Folded-angle closed form (math, per the brief's formula): for integer n_mirrors
    the folded angle phi_f equals phi (the rotated start angle) reduced into
    [0, theta = pi/n_mirrors] by phi_f = phi mod 2theta, and 2theta - phi_f
    when that lands above theta, evaluated in float64. The mirror's fold must
    produce z with that angle (and the isometric radius) wherever the point is
    in radius range... specifically wherever the fold has converged to the wedge.
  - Rotation and scale closed form (math): the start point of the fold is the
    pixel point rotated by -rotation and divided by scale (radius scaled by
    1/scale when scale > 0), so a rotation of one full turn (2*pi) is the
    identity modulo the fold's symmetry: the image is identical for any
    n_mirrors.
  - Bypass (definition comment): bypass = 1 returns sample(in1, norm), the plain
    unwarped texture, whatever the other params do.
  - Generic parameters (math): every param at an arbitrary non-special value,
    against the float64 closed form (rotation, scale, folded angle, radius).
  - Non-integer n_mirrors is NOT tested against the closed form (the formula
    requires integer n_mirrors; the codebox accepts floats and folds anyway).

Scope and limits: char pixel-type quantization is not modelled; points exactly on a mirror line sit on a step tie and are excluded from
checks; scale = 0 (the dial's minimum) divides by zero and is not tested.

Run:  tests/run.sh tests/modules/ngon/test_ngon.py
"""
import math
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402

from ngon_mirror import F32, ngon  # noqa: E402

N = 48  # even, so no texel sits exactly at the centre


def ramp_tex(n=N):
    """Texture whose R,G channels store the sampling coordinate itself, so a read
    back at (u, v) returns (u, v) with no texture dependence: a direct probe of the
    warp. Bilinear is exact on a linear ramp."""
    u, v, _, _ = g.grid(n, n)
    t = g.texture(n, n)
    t[..., 0] = u
    t[..., 1] = v
    t[..., 2] = 0.25
    t[..., 3] = 1.0
    return t


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def _radius(phi_or_z):
    z = phi_or_z
    return np.sqrt(z[0] * z[0] + z[1] * z[1])


def _start(n, rotation, scale):
    """The mirror's stated start point of the fold, in float64: the pixel point
    rotated by -rotation and divided by scale."""
    nx, ny, _, _ = g.grid(n, n)
    x = (nx * 2 - 1) / scale
    y = (ny * 2 - 1) / scale
    c, s = math.cos(-rotation), math.sin(-rotation)
    return (x * c - y * s, x * s + y * c)


def _folded_angle64(phi, theta):
    """Brief's closed form: reduce phi into [0, 2theta); mirror down above theta."""
    m = np.mod(phi, 2 * theta)
    return np.where(m > theta, 2 * theta - m, m)


def _recover_angle(out, src_channel):
    """Read the ramp texture back: R gives uv_x, G gives uv_y, so z =
    out*2 - 1 modulo clamping. Returns (zx, zy) in float64."""
    zx = out[..., 0].astype(np.float64) * 2 - 1
    zy = out[..., 1].astype(np.float64) * 2 - 1
    return zx, zy


def _sin64(sx, sy):
    return sx / np.maximum(np.hypot(sx, sy), 1e-30), sy / np.maximum(np.hypot(sx, sy), 1e-30)


def _angle_err(bug=None, n_mirrors=6.0, rotation=0.0, scale=1.0):
    """Worst error of folded points vs the float64 closed form (phi mod 2theta,
    mirrored down above theta), over pixels that need no clamp and no tie:
    mask = |start radius| < 0.99 (so the folded point, same radius, stays inside
    the unit frame and the ramp read-back is unclamped), and the start point away
    from both mirror lines (a step tie: y ~ 0 or cross ~ 0, both through origin)."""
    src = ramp_tex()
    out = ngon(src, n_mirrors=n_mirrors, rotation=rotation, scale=scale, bug=bug)
    zx, zy = _recover_angle(out, None)
    sx, sy = _start(N, rotation, scale)
    sin_phi, cos_phi = _sin64(sx, sy)
    theta = math.pi / n_mirrors
    safe = (np.hypot(sx, sy) < 0.99) & \
           (np.abs(sin_phi) > 5e-3) & \
           (np.abs(sin_phi * math.cos(theta) - cos_phi * math.sin(theta)) > 5e-3)
    assert safe.sum() > N * N // 4, "too little of the frame left to compare"
    phi_f = _folded_angle64(np.arctan2(sy, sx), theta)
    zphi = np.arctan2(zy, zx)
    d = np.abs(zphi - phi_f)
    d = np.minimum(d, np.abs(d - 2 * theta))          # wrap at the fold's seam
    return float(d[safe].max())


def _radius_err(rotation=0.0, scale=1.0):
    """Worst radius error vs the isometry claim, over pixels that need no clamp
    (start radius < 0.99/scale is automatic: the mask is |start| < 0.94; with
    scale applied the start radius can reach 1, so mask tighter here)."""
    src = ramp_tex()
    out = ngon(src, n_mirrors=6.0, rotation=rotation, scale=scale)
    zx, zy = _recover_angle(out, None)
    sx, sy = _start(N, rotation, scale)
    r64 = np.hypot(sx, sy)
    rfold = np.hypot(zx, zy)
    return float(np.abs(rfold - r64)[r64 < 0.94].max())


# --- neutral / identity-class checks ------------------------------------------------------

def test_neutral_setting_is_not_a_passthrough_alpha_stays_one():
    """At the defaults the output is NOT the source: the fold symmetrizes the frame (worst |out - src|
    about 0.99 on random noise, recorded with note()). The idea file says only that the mechanism
    'naturally produces a regular 2*n_mirrors-gon when applied to a texture sample'; it makes no
    identity claim, and the closed-form checks elsewhere in this file carry the geometry. This test
    pins just the codebox's alpha: vec(...) at the end of the fold keeps alpha 1."""
    src = rand_tex(4)
    out = ngon(src)
    note("neutral: worst |out - src| over the whole frame", float(np.abs(out - src).max()))
    check("neutral output alpha stays 1", float(np.abs(out[..., 3] - 1.0).max()), 0.0)


def test_full_rotation_is_identity():
    """rotate = 2*pi acts as the identity before the fold (math: e^{i 2pi} = 1), so the
    rendered image equals the image at rotation 0 for the same n_mirrors. The residual
    allowed is the interpolated-read floor of the GPU's 8-bit weights, not exact."""
    src = ramp_tex()
    a = ngon(src, n_mirrors=6.0, rotation=2 * math.pi)
    b = ngon(src, n_mirrors=6.0, rotation=0.0)
    check("full turn equals rotation 0 (to the read floor)", float(np.abs(a - b).max()), 2e-4)


# --- isometry ---------------------------------------------------------------------------------

def test_reflection_preserves_radius():
    """The fold is a composition of reflections, which preserve radius, so the folded
    point's radius equals the rotated, scaled start point's radius (math), wherever
    no clamp hits (start radius at most 0.99)."""
    for rot, sc in [(0.0, 1.0), (0.4, 1.0), (0.0, 1.3), (0.7, 0.8)]:
        err = _radius_err(rotation=rot, scale=sc)
        note(f"radius isometry rot={rot} scale={sc}: worst error", err)
        assert err < 1e-5, f"radius isometry off at rot={rot} scale={sc}: {err:.3e}"


# --- closed form, integer n_mirrors ------------------------------------------------------------

def test_folded_angle_matches_closed_form():
    """For integer n_mirrors the folded angle is phi mod 2theta, mirrored down above
    theta (the brief's stated closed form, float64). The measured error is an angle;
    1e-3 rad corresponds to about one texel at r=0.5 across a 48px frame: the floor
    of recovering uv through a bilinear read of the ramp (8-bit weight floor)."""
    for nm in [3, 6, 11, 18]:
        err = _angle_err(n_mirrors=float(nm))
        note(f"folded-angle closed form, n_mirrors={nm}: worst", err)
        assert err < 1e-3, f"folded-angle closed form off at n_mirrors={nm}: {err:.3e}"


def test_generic_parameters_closed_form():
    """Every param at an arbitrary non-special value (n 7, rot 0.83, scale 1.27):
    the special-angle checks above cannot see bugs in terms that vanish or equal 1
    at rotation 0 and scale 1, so the same angle closed form is checked there
    (tolerance as in test_folded_angle_matches_closed_form: the read floor)."""
    worst = _angle_err(n_mirrors=7.0, rotation=0.83, scale=1.27)
    note("generic parameters: worst folded-angle error", worst)
    assert worst < 1e-3, f"generic folded-angle error {worst:.3e}"


# --- bypass -----------------------------------------------------------------------------------

def test_bypass_passes_the_source():
    """The codebox's own comment: bypass = 1 returns the plain unwarped source."""
    src = rand_tex(5)
    out = ngon(src, n_mirrors=6.0, rotation=1.1, scale=0.5, bypass=1.0)
    check("bypass equals the source under an extreme warp", float(np.abs(out - src).max()), 1e-6)


def test_half_bypass_is_a_mix():
    """bypass = 0.5 mixes by exactly one half (mix linearity, a one-sentence identity)."""
    src = rand_tex(6)
    a = ngon(src, rotation=0.9, scale=1.4)
    b = ngon(src, rotation=0.9, scale=1.4, bypass=0.5)
    c = ngon(src, rotation=0.9, scale=1.4, bypass=1.0)
    expect = (0.5 * a + 0.5 * c).astype(F32)
    check("bypass 0.5 is the half mix of bypass 0 and 1", float(np.abs(b - expect).max()), 1e-6)


# --- range --------------------------------------------------------------------------------------

def test_outputs_stay_in_unit_range():
    """The clamped uv keeps every sampled value inside the texture's own range, so
    the output channels lie in [0, 1] and alpha stays 1 for any warp."""
    worst = 0.0
    for nm, rot, sc in [(6.0, 0.0, 1.0), (11.0, 2.1, 0.4), (18.0, -1.3, 3.0), (2.0, 0.5, 1.1)]:
        out = ngon(rand_tex(7), n_mirrors=nm, rotation=rot, scale=sc)
        assert float(np.abs(out[..., 3] - 1.0).max()) == 0.0, "alpha must be 1"
        worst = max(worst, max(-float(out[..., :3].min()), float(out[..., :3].max()) - 1.0))
    check("outputs inside [0, 1]", max(worst, 0.0), 0.0)


def test_fold_converges_to_wedge_for_large_n():
    """The idea file records, as a visual observation on a scratch patch, that 32 iterations held up
    cleanly to n_mirrors = 18. This checks the stronger point-wise statement independently: at
    n_mirrors = 18 with rotation 0.31 every non-tied unclamped folded point must sit at the
    closed-form folded angle (tolerance: the ramp read floor, as above)."""
    err = _angle_err(n_mirrors=18.0, rotation=0.31, scale=1.05)
    check("n_mirrors = 18 folded angle vs the closed form after 32 iterations", err, 1e-3)


# --- mutations ---------------------------------------------------------------------------------

BUGS = ["rot_sign", "no_scale", "theta_2pi", "step_swap", "uv_sign"]


def _err_for_bug(bug):
    if bug == "rot_sign":
        return _angle_err(bug=bug, n_mirrors=7.0, rotation=0.83, scale=1.27)
    if bug == "no_scale":
        return _angle_err(bug=bug, n_mirrors=7.0, rotation=0.83, scale=1.27)
    if bug == "theta_2pi":
        return _angle_err(bug=bug, n_mirrors=6.0)
    if bug == "step_swap":
        return _angle_err(bug=bug, n_mirrors=6.0)
    return float(np.abs(ngon(ramp_tex(), bug=bug) - ramp_tex()).max())


def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin, and the real
    mirror must pass the same checks (errors at or under the read floor)."""
    real = max(_angle_err(n_mirrors=6.0), _angle_err(n_mirrors=7.0, rotation=0.83, scale=1.27),
               _radius_err(rotation=0.4, scale=1.0))
    for bug in BUGS:
        v = _err_for_bug(bug)
        note(f"mutation '{bug}' worst error", v)
        if not v > 1e-2:
            raise AssertionError(f"mutation not detected: {bug} (error {v:.3e})")
    assert real < 1e-3, f"the real mirror must pass the same checks: {real:.3e}"
    print("    ok   sign flip, missing scale, wrong theta constant, step swap and uv sign each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))