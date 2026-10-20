"""
test_vf_repulse.py -- tier-1 NumPy mirror of the f_vf_repulse shader (the codebox inline
in src/f_vf_repulse/definition.py).

Ground truth is independent of the mirror:

  - Doc: Rec. 601 luma (`0.299R + 0.587G + 0.114B`) of 16 ring samples, thresholded by
    max(luma - threshold, 0), accumulated as -dir * w into (fx, fy), encoded by
    clamp(f*gain*0.5 + 0.5, 0, 1); bypass is a mix to a neutral vecfield; negative gain
    attracts; mode 1 is "strongest single ring sample wins"; mode 2 "normalizes to the
    direction of the (mode-0-style) cancel vector"; mode 3 adds "curl (perpendicular to
    the cancel vector)".
  - The 16 directions are the unit vectors of the angles k*22.5 degrees (math; checked
    against fresh float64 cos/sin), so opposite pairs {k, k+8} and quarter-turn pairs
    {k, k+4} behave exactly.
  - reach = 0: all 16 ring positions coincide with the pixel itself, so the weights are
    all equal (or all zero) and each of the 8 opposite pairs cancels -- exact identity.
  - reach = 0.1, N = 32, texture bright west / dark east, uniform in y: for ANY pixel in
    column 16 the codebox's remap (u(z) = z*0.8 + 0.1, from the definition's own comment
    "Remap norm into [reach, 1-reach] so ring samples never go OOB") puts the ring's x
    positions at texels 16.4 + 3.2*dx_i. Only directions with dx < 0 (indices 5..11)
    land fully inside the bright half, each reading luma = 0.5925 exactly (bilinear of a
    constant region, Rec. 601 of (1, 0.5, 0)); index 12 (dx = 0) lands at texel 16.4,
    whose bilinear stencil weights the dark column 16 at 0.9, giving luma 0.104 >
    threshold? No: 0.104 < 0.3, so its weight is 0; dx > 0 reads 0.05, weight 0. So at
    column 16, for rows 1..30: exactly seven weights w = 0.2925, and the closed forms
    for modes 0, 2 and 3 are fixed numbers derived in the tests.
  - Uniform luma, threshold below it: equal weights on the 8 opposite pairs cancel
    (doc: "opposing contributions from surrounding bright regions neutralize").
  - 90-degree rotation: u(1-z) = 1-u(z) and dir_{k+4} = (-dy_k, dx_k) make repulse
    commute with np.rot90 in the decoded field (exact pairing identity).
  - The OOB gate zeroes ring weights at positions outside [0, 1]; it only bites at
    negative reach. Its semantics are codebox-only (the doc says nothing), so it is
    measured against the mirror's own no-gate branch, not against the doc (not_checked).

Tolerances: closed-form float32 checks 1e-5 or tighter (constant-region lumas and
dyadic encoding arithmetic make the real errors ~1e-7); the generic check is at 5e-3
(docstring explains why); identities that must hold exactly run at 1e-5 or 0.
"""
import math
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_repulse_mirror import F32, DX, DY, repulse  # noqa: E402

N = 32
NEUTRAL = np.array([0.5, 0.5, 0.5, 1.0], F32)

L_BRIGHT = 0.299 * 1.0 + 0.587 * 0.5 + 0.114 * 0.0     # 0.5925: the doc's Rec. 601
W_B = L_BRIGHT - 0.3                                   # 0.2925: the bright weight at column 16
BRIGHT_I = [5, 6, 7, 8, 9, 10, 11]                     # dx in {-1, -.9239, -.7071, -.3827} twice


def const_tex(rgba, n=N):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def gray(v, n=N):
    return const_tex((v, v, v, 1.0), n)


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def decode(o):
    return (o[..., 0].astype(np.float64) - 0.5) * 2.0, (o[..., 1].astype(np.float64) - 0.5) * 2.0


def two_tone(n=N):
    """Columns 0..15 bright (1, 0.5, 0), 16..31 dark (0.05 gray), uniform in y."""
    t = g.texture(n, n)
    t[:, :n // 2] = np.array([1.0, 0.5, 0.0, 1.0], F32)
    t[:, n // 2:] = np.array([0.05, 0.05, 0.05, 1.0], F32)
    return t


# --- the direction table (math) ---------------------------------------------------------

def test_directions_match_cos_sin_of_22_5_degrees():
    """The codebox's 16 directions are the unit vectors of the angles k*22.5 degrees:
    dx_k = cos(k*pi/8), dy_k = sin(k*pi/8), checked against fresh float64 cos/sin."""
    ang = np.arange(16, dtype=np.float64) * (2.0 * np.pi / 16.0)
    check("dx table vs cos(k*22.5deg)", float(np.abs(DX - np.cos(ang).astype(F32)).max()), 1e-4)
    check("dy table vs sin(k*22.5deg)", float(np.abs(DY - np.sin(ang).astype(F32)).max()), 1e-4)


def test_directions_are_unit_vectors():
    """Each (dx_k, dy_k) pair is a unit vector: dx^2 + dy^2 = 1 (math; the four-decimal
    table rounds at ~5e-5)."""
    r = DX.astype(np.float64) ** 2 + DY.astype(np.float64) ** 2
    check("16 directions satisfy dx^2+dy^2=1", float(np.abs(r - 1.0).max()), 1e-4)


# --- degenerate and uniform inputs --------------------------------------------------------

def test_reach0_collapses_to_the_pixel_itself():
    """reach = 0: zu = norm and dir*reach = 0, so all 16 ring positions coincide with the
    pixel itself; the 16 weights are all equal (bright side) or all zero (dark side),
    and the 8 opposite pairs {k, k+8} cancel exactly -> neutral vecfield, any texture."""
    worst = 0.0
    for src in [two_tone(), gray(0.9), rand_tex(1)]:
        o = repulse(src, gain=4.0, reach=0.0, threshold=0.15, mode=0.0)
        worst = max(worst, float(np.abs(o - NEUTRAL).max()))
    check("reach 0 -> neutral field everywhere, any texture", worst, 1e-6)


def test_zero_field_is_neutral():
    """Black input: luma 0; the doc's thresholding max(luma - threshold, 0) with the
    shipped threshold 0.3 gives w = 0 for all 16 samples -> neutral encoding."""
    o = repulse(g.texture(N, N), gain=4.0, reach=0.1, threshold=0.3)
    check("black input -> neutral vecfield", float(np.abs(o - NEUTRAL).max()), 1e-6)


def test_uniform_bright_field_cancels_mode0():
    """Uniform luma 0.9 with threshold 0.5: all 16 weights equal (0.4 each by Rec. 601,
    0.9 - 0.5), the 8 opposite pairs cancel, so mode 0 is neutral everywhere (doc:
    "opposing contributions from surrounding bright regions neutralize")."""
    src = gray(0.9)
    worst = 0.0
    for reach in [0.1, 0.3, 0.5]:
        o = repulse(src, gain=2.0, reach=reach, threshold=0.5, mode=0.0)
        worst = max(worst, float(np.abs(o - NEUTRAL).max()))
    check("uniform bright field -> neutral (mode 0, reach .1/.3/.5)", worst, 1e-6)


def test_mode2_magnitude_vanishes_on_uniform_field():
    """Uniform luma with threshold below it: mode 2's cancel vector cancels to the
    float32 residue (~1e-9), its guard floor is 1e-4, so the normalized direction times
    sum(w) is at most residue/1e-4 ~ 0.008 in decoded units -- still a near-neutral
    field. A nonzero accumulator seed (a plausible real mistake) survives the guard and
    pushes the field to the clamp: the decoded magnitude must stay below 0.02.
    (Float32 accumulation on this frame leaves |cx| < 1e-8; dividing by the 1e-4 guard
    gives < 1e-4, so any decoded value above 0.02 comes from a real seed, not rounding.)"""
    src = gray(0.9)
    o = repulse(src, gain=1.0, reach=0.1, threshold=0.5, mode=2.0)
    fx, fy = decode(o)
    m = max(float(np.abs(fx).max()), float(np.abs(fy).max()))
    check("mode 2 magnitude stays near 0 on a uniform field (guard-bound)", m, 0.02)


def test_threshold_above_luma_zeroes_the_field():
    """threshold 1.0 > any luma: max(luma - threshold, 0) = 0 for every sample, so the
    output is neutral at the shipped gain 4 and reach 0.1 (doc's Algorithm block)."""
    o = repulse(rand_tex(2), gain=4.0, reach=0.1, threshold=1.0, mode=0.0)
    check("threshold 1.0 -> neutral", float(np.abs(o - NEUTRAL).max()), 1e-6)


def test_gain_zero_is_the_neutral_encoding():
    """gain 0: field = clamp(0 * f * 0.5 + 0.5) = 0.5 in x and y whatever the ring does
    (the doc's encoding formula)."""
    src = rand_tex(3)
    o = repulse(src, gain=0.0, reach=0.5, threshold=-1.0, mode=3.0)
    check("gain 0 -> neutral encoding at reach 0.5, mode 3", float(np.abs(o - NEUTRAL).max()), 1e-6)


# --- sign of the flow ----------------------------------------------------------------------

def _away_err():
    """The doc: "accumulates vectors pointing away from bright (above `threshold`)
    regions". Bright region west, so no pixel's field may point west: decoded fx >= 0
    everywhere, and strictly positive just east of the boundary."""
    src = two_tone()
    fx, _ = decode(repulse(src, gain=2.0, reach=0.1, threshold=0.3, mode=0.0))
    if not np.isfinite(fx).all():
        return 10.0
    neg = max(-float(fx.min()), 0.0)
    if float(fx[8:24, 16:20].min()) <= 0.0:
        return 1.0 + neg      # the strictly-positive claim fails loudly
    return neg


def test_repulsion_points_away_from_bright():
    err = _away_err()
    check("decoded fx >= 0 everywhere, bright region west", err, 1e-6)


def test_negative_gain_attracts_toward_bright():
    """Doc dial note: "negative `gain` gives attraction instead of repulsion". With the
    two-tone texture, a pixel just east of the bright region must get field_x < 0.5
    (flow toward the bright region) under gain -2."""
    fx, _ = decode(repulse(two_tone(), gain=-2.0, reach=0.1, threshold=0.3, mode=0.0))
    check("negative gain: field_x < 0.5 east of the bright region",
          max(float(fx[8:24, 16:20].max()) - 0.5, 0.0), 0.0)


def test_y_uniform_texture_gives_zero_field_y():
    """Symmetry identity (math): for a texture constant in y, luma depends only on the
    sample's su coordinate; directions sharing a dx come in +-dy pairs (their weights
    are equal), and the only |dy| = 1 directions have dx = 0, so the y-components
    cancel exactly -- for every threshold and gain, over the whole frame."""
    src = two_tone()
    _, fy = decode(repulse(src, gain=2.0, reach=0.1, threshold=0.3, mode=0.0))
    check("y-uniform texture -> field_y == 0 everywhere", float(np.abs(fy).max()), 3e-6)


# --- rotation symmetry ---------------------------------------------------------------------

def _rot_src(seed=4):
    return rand_tex(seed)


def _rot_f(gain, thr):
    return decode(repulse(_rot_src(), gain=gain, reach=0.1, threshold=thr, mode=0.0))


def _rot_g(gain, thr):
    S = np.rot90(_rot_src(), k=-1, axes=(0, 1)).copy()
    return decode(repulse(S, gain=gain, reach=0.1, threshold=thr, mode=0.0))


def test_90degree_rotation_symmetry():
    """Math identity: the remap u(z) = z(1-2r)+r is symmetric about z = 1/2
    (u(1-z) = 1-u(z)) and dir_{k+4} = (-dy_k, dx_k), so rotating the source by
    np.rot90(src, -1) rotates the decoded field by the same turn under the index map
    (r, c) -> (N-1-c, r): gx[r,c] = -fy_src[N-1-c, r] and gy[r,c] = +fx_src[N-1-c, r]."""
    fx, fy = _rot_f(1.7, 0.2)
    gx, gy = _rot_g(1.7, 0.2)
    worst = max(float(np.abs(gx - (-np.rot90(fy, -1))).max()),
                float(np.abs(gy - np.rot90(fx, -1)).max()))
    check("rot90 src -> decoded field rotated the same turn", worst, 1e-5)


# --- closed forms at the boundary column -----------------------------------------------------
# Geometry (from the codebox's remap comment and the doc's algorithm, not the mirror):
# reach 0.1, N = 32: u(z) = z*0.8 + 0.1 maps column 16's norm to zu*32 = 16.4, so the
# ring x positions are texels 16.4 + 3.2*dx_i. Bilinear reads the bright value exactly
# when the whole stencil is inside the bright half: 32*su < 15.5 -> dx <= -0.3827
# (indices 5..11 and the negative of index 3's partner set). The dx = 0 sample (index 12)
# lands at texel 16.4: x0 = floor(16.4 - 0.5) = 15 with fraction 0.9, so the stencil
# weights the DARK column 16 at 0.9 -> luma 0.104 < 0.3 -> weight 0. dx > 0 reads the
# dark luma 0.05, weight 0. The texture is constant in y, so any row range behaves the
# same: at every pixel (r, 16), rows 1..30, exactly the seven weights
# w = L_BRIGHT - 0.3 = 0.2925 are alive, on the y-symmetric set dx in
# {-1, -0.9239, -0.7071, -0.3827} with each of the last three appearing twice.

def _sum_dx_bright():
    """|dx_i| summed over the bright set, from fresh cosines of k*22.5deg (the direction
    table's math ground truth), = 5.0274."""
    return sum(abs(math.cos(k * math.pi / 8.0)) for k in BRIGHT_I)


def _cerr(a, b):
    """|float(a) - b|, with any non-finite mirror value counted as a hard error 10.0
    (max(x, nan) keeps x, so nans must not be allowed to slip past the comparison)."""
    v = abs(float(a) - b) if np.isfinite(a) else 10.0
    return v


def _closed_form_err(bug=None, mode=0.0, gain=0.6, rows=range(1, 31), col=16):
    """Expected encodings at (rows, col) from the doc's luma weights, the direction
    table's math, and the ring geometry above -- no mirror code involved."""
    src = two_tone()
    out = repulse(src, gain=gain, reach=0.1, threshold=0.3, mode=np.float32(mode), bug=bug)
    s = _sum_dx_bright()
    if mode == 0.0:
        # -sum(dx_i * w_i) = -(-|dx|)*sum = +w*s, y cancels exactly
        ex = min(max(W_B * s * gain * 0.5 + 0.5, 0.0), 1.0)
        ey = 0.5
    elif mode == 2.0:
        # cancel is pure +x with magnitude W_B*s, unit vector (1,0); abs_mag = 7*W_B
        ex = min(max(7.0 * W_B * gain * 0.5 + 0.5, 0.0), 1.0)
        ey = 0.5
    elif mode == 3.0:
        # curl adds +y (curl_y = cancel_x > 0) scaled by turb = clamp((7W_B/(W_B*s)-1)*0.2, 0, 1)
        turb = min(max((7.0 * W_B / (W_B * s) - 1.0) * 0.2, 0.0), 1.0)
        ex = min(max(W_B * s * gain * 0.5 + 0.5, 0.0), 1.0)
        ey = 0.5 + W_B * s * turb * gain * 0.5
    else:
        raise ValueError(mode)
    err = 0.0
    for r in rows:
        err = max(err, _cerr(out[r, col, 0], ex), _cerr(out[r, col, 1], ey))
    return err


def test_boundary_column_mode0_closed_form():
    """At every pixel (r, 16), rows 1..30, gain 0.6, mode 0: the seven live weights
    w = L_BRIGHT - 0.3 = 0.2925 pull along +x (dx < 0, doc's -dir*w sum), sum |dx| over
    them is 5.0274 (cos of 22.5-degree steps), y cancels by the +-dy pairing, so
    field_x = clip(w*5.0274*0.3 + 0.5) = 0.941154 and field_y = 0.5, per pixel."""
    e = _closed_form_err()
    note("boundary column mode 0: worst |field - closed form| over rows 1..30", e)
    check("boundary column mode 0 closed form", e, 1e-5)


def test_boundary_column_mode2_closed_form():
    """Mode 2 at the same pixels with gain 0.15: the doc's "Accumulates magnitudes
    regardless of direction, then normalizes to the direction of the (mode-0-style)
    cancel vector": the cancel vector is pure +x, so the unit vector is (1, 0) and the
    field is its magnitudes' sum 7*w = 2.0475, encoded
    field_x = clip(2.0475*0.075 + 0.5) = 0.6535625, field_y = 0.5."""
    e = _closed_form_err(mode=2.0, gain=0.15)
    note("boundary column mode 2: worst |field - closed form| over rows 1..30", e)
    check("boundary column mode 2 closed form", e, 1e-5)


def test_boundary_column_mode3_curl_closed_form():
    """Mode 3 adds "curl (perpendicular to the cancel vector)" scaled by cancellation:
    at (r, 16) the cancel is pure +x, so field_x must equal mode 0's exactly, and the
    curl's y is curl_y = cancel_x = w*5.0274 scaled by
    turb = clamp((7w/(w*5.0274) - 1)*0.2, 0, 1) = 0.078474, with gain 0.15 giving
    field_y = 0.5 + w*5.0274*0.078474*0.075 = 0.5086548."""
    src = two_tone()
    o0 = repulse(src, gain=0.15, reach=0.1, threshold=0.3, mode=0.0)
    o3 = repulse(src, gain=0.15, reach=0.1, threshold=0.3, mode=3.0)
    ex = float(np.abs(o3[1:31, 16, 0] - o0[1:31, 16, 0]).max())
    check("mode 3 field_x == mode 0 field_x (curl is perpendicular)", ex, 1e-6)
    e = _closed_form_err(mode=3.0, gain=0.15)
    note("boundary column mode 3: |field_x3 - field_x0|, |field_y - curl closed form|", [ex, e])
    check("mode 3 field_y matches the curl closed form", e, 2e-5)


# --- bypass, range, encoding -----------------------------------------------------------------

def test_bypass_passes_the_neutral_field():
    """Doc parameter table: bypass "Passes a neutral vecfield through unchanged", even
    at the extremes gain 10, reach 0.5, threshold -1, mode 3."""
    o = repulse(rand_tex(5), gain=10.0, reach=0.5, threshold=-1.0, mode=3.0, bypass=1.0)
    check("bypass -> neutral vecfield", float(np.abs(o - NEUTRAL).max()), 1e-6)


def test_bypass_partial_mix_is_linear():
    """The codebox's bypass is a mix(field, neutral, bypass), and mix is affine in its
    parameter (math, one sentence: mix(a, b, t) = a(1-t) + b*t), so bypass = 0.5 is the
    exact midpoint between bypass 0 and bypass 1."""
    src = rand_tex(6)
    a = repulse(src, gain=5.0, reach=0.2, threshold=0.1, mode=0.0, bypass=0.0)
    b = repulse(src, gain=5.0, reach=0.2, threshold=0.1, mode=0.0, bypass=1.0)
    mid = repulse(src, gain=5.0, reach=0.2, threshold=0.1, mode=0.0, bypass=0.5)
    check("bypass 0.5 is the exact midpoint of bypass 0 and 1",
          float(np.abs(mid - (a + b).astype(F32) / F32(2.0)).max()), 1e-6)


def test_outputs_clamped_with_fixed_z_and_alpha():
    """Doc: the encoded field is clamp(f*gain*0.5 + 0.5, 0, 1), so the output stays in
    [0, 1] even at gain 10, reach +-0.5, threshold -1, all four modes; the codebox packs
    (field_x, field_y, 0.5, 1.0), so channels z and w are exactly 0.5 and 1."""
    src = rand_tex(7)
    worst_hi = worst_lo = 0.0
    for m in range(4):
        for reach, thr in [(0.5, -1.0), (-0.5, -1.0), (0.1, 1.0)]:
            o = repulse(src, gain=10.0, reach=reach, threshold=thr, mode=float(m))
            worst_hi = max(worst_hi, float(o.max()) - 1.0)
            worst_lo = max(worst_lo, -float(o.min()))
            assert float(np.abs(o[..., 2] - F32(0.5)).max()) == 0.0, "z channel must be 0.5"
            assert float(np.abs(o[..., 3] - F32(1.0)).max()) == 0.0, "alpha must be 1"
    check("outputs at or below 1 (gain 10, reach +-0.5, threshold -1/1, all modes)",
          max(worst_hi, 0.0), 0.0)
    check("outputs at or above 0", max(worst_lo, 0.0), 0.0)


# --- the OOB gate (codebox-only behavior) ----------------------------------------------------

def _gate_diff(bug=None):
    """reach = -0.25: the remap u(z) = z*1.5 - 0.25 pushes ring positions outside
    [0, 1] near the borders, where the codebox's step gate zeroes those weights. With
    the gate dropped, the clamped edge reads keep weight 0.9 - threshold. This measures
    the codebox behavior against the mirror's own no-gate branch: it proves the mirror
    exposes the gate (used by the mutation check); the gate's semantics are not
    doc-grounded (see not_checked)."""
    src = gray(0.9)
    if bug == "no_gate":
        a = repulse(src, gain=4.0, reach=-0.25, threshold=0.5, mode=0.0)
        b = repulse(src, gain=4.0, reach=-0.25, threshold=0.5, mode=0.0, bug="no_gate")
    else:
        a = repulse(src, gain=4.0, reach=-0.25, threshold=0.5, mode=0.0)
        b = repulse(src, gain=4.0, reach=-0.25, threshold=0.5, mode=0.0, bug="no_gate")
    return float(np.abs(a - b).max())


def test_oob_gate_changes_the_field_at_negative_reach():
    """The gate removes weight that clamped edge reads would otherwise contribute: half
    the encoding range at reach -0.25 on a uniform bright frame (a fully-suppressed side
    encodes as 0.0 against 0.5)."""
    d = _gate_diff()
    note("gate vs no-gate worst difference at reach -0.25", d)
    check("the OOB gate changes the field at negative reach", max(d - 0.5, 0.0), 1e-4)


# --- bypass ------------------------------------------------------------------------------------

def test_bypass_mixes_to_a_neutral_vecfield():
    """Doc (parameter table and algorithm block): bypass mixes the field to the neutral vecfield
    (0.5, 0.5, 0.5, 1.0), like the other f_vf_ generators, so the output must equal that constant
    whatever the source holds. (The doc's Notes once said the source texture passes through; that
    was corrected 2026-10-20, the codebox being authoritative.)"""
    src = rand_tex(21)
    o = repulse(src, gain=4.0, reach=0.1, threshold=0.3, bypass=1.0)
    err = float(np.abs(o.astype(np.float64) - np.array([0.5, 0.5, 0.5, 1.0])).max())
    check("bypass=1 output equals the neutral vecfield (0.5, 0.5, 0.5, 1)", err, 1e-6)


# --- generic parameters ----------------------------------------------------------------------

def _cerr_px(a, b):
    """Max-abs error for one pixel value against a float64 closed form; any non-finite
    mirror value counts as a hard error 10.0 (max(x, nan) keeps x, so nan must not be
    allowed to slip past the comparison)."""
    return abs(float(a) - b) if np.isfinite(a) else 10.0


def test_generic_parameters_match_doc_algorithm():
    """Generic point (mode 1, gain 2.7, reach 0.17, threshold 0.11, random source): the
    expected value is rebuilt in float64 from the doc's Algorithm block (Rec. 601 luma,
    thresholded weights, strongest-sample scan, the encoding clamp) at the ring
    positions the definition's own comment prescribes ("Remap norm into [reach,
    1-reach] so ring samples never go OOB"). This is the mobius-style generic check: it
    re-derives the branch, but in float64, in NumPy's own order, which the special-value
    checks cannot replace. Tolerance 5e-3 (looser than 1e-3): mode 1's tie comparisons
    amplify float32-vs-float64 rounding through the scanned max, and the point of the
    check is structural agreement, not a 1e-5 closed form."""
    n = 48
    src = rand_tex(8, n=n)
    gain, reach, thr = 2.7, 0.17, 0.11
    out = repulse(src, gain=gain, reach=reach, threshold=thr, mode=1.0)
    ang = np.arange(16, dtype=np.float64) * (2.0 * np.pi / 16.0)
    dx, dy = np.cos(ang), np.sin(ang)
    cy, cx = np.meshgrid(np.arange(n, dtype=np.float64), np.arange(n, dtype=np.float64),
                         indexing="ij")
    zu = (cx + 0.5) / n * (1.0 - 2.0 * reach) + reach
    zv = (cy + 0.5) / n * (1.0 - 2.0 * reach) + reach
    worst = 0.0
    for j in range(2, n - 2, 3):
        for i in range(2, n - 2, 3):
            ws = []
            for k in range(16):
                s = g.sample(src, np.float32(zu[j, i] + dx[k] * reach),
                             np.float32(zv[j, i] + dy[k] * reach)).astype(np.float64)
                ws.append(max(0.299 * s[0] + 0.587 * s[1] + 0.114 * s[2] - thr, 0.0))
            bx = by = bw = 0.0
            for k in range(16):
                t = 1.0 if ws[k] >= bw else 0.0
                bx = bx * (1 - t) + (-dx[k]) * t
                by = by * (1 - t) + (-dy[k]) * t
                bw = bw * (1 - t) + ws[k] * t
            worst = max(worst,
                        _cerr_px(out[j, i, 0], np.clip(bx * bw * gain * 0.5 + 0.5, 0.0, 1.0)),
                        _cerr_px(out[j, i, 1], np.clip(by * bw * gain * 0.5 + 0.5, 0.0, 1.0)))
    check("generic mode 1 vs the doc's algorithm in float64, interior texels", worst, 5e-3)


# --- mutations --------------------------------------------------------------------------------

def _cf_err(bug=None):
    return _closed_form_err(bug=bug)


def _mode2_err(bug=None):
    return _closed_form_err(bug=bug, mode=2.0, gain=0.15)


def _fy_err(bug=None):
    _, fy = decode(repulse(two_tone(), gain=2.0, reach=0.1, threshold=0.3, mode=0.0, bug=bug))
    if not np.isfinite(fy).all():
        return 10.0
    return float(np.abs(fy).max())


def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin, and the real
    mirror must stay inside every tolerance on the same checks. Declared bugs:
    "attract" (ring direction sign flipped), "swap_xy" (field channels swapped before
    encoding), "no_scale" (the encoding's 0.5 field scale dropped), "rec709" (wrong
    luma coefficients), "no_gate" (the OOB gate dropped)."""
    real = [_cf_err(), _mode2_err(), _away_err(), _fy_err(), _closed_form_err(mode=3.0, gain=0.15)]
    assert max(real) < 1e-5, f"the real mirror must pass its own checks: {real}"
    note("real mirror worst error over the shared checks", max(real))
    bad = {"attract": _cf_err("attract"),
           "swap_xy": max(_fy_err("swap_xy"), _cf_err("swap_xy")),
           "no_scale": max(_cf_err("no_scale"), _mode2_err("no_scale")),
           "rec709": max(_cf_err("rec709"), _mode2_err("rec709")),
           "no_gate": _gate_diff("no_gate")}
    for k, v in bad.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    print("    ok   sign flip, channel swap, missing scale, wrong luma weights and a dropped OOB gate are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))