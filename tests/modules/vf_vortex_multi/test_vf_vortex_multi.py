"""
test_vf_vortex_multi.py -- tier-1 NumPy mirror of the f_vf_vortex_multi generator
(src/f_vf_vortex_multi/definition.py, inline codebox).

Ground truth is independent of the mirror. It comes from the module's reference
doc (docs/f-reference/f_vf_vortex_multi.md), from the f_vecfield encoding
contract (docs/f-reference/f_vecfield_type.md), and from math identities stated
in one sentence each. What the doc and the identities force:

  - Encoding: R = fx * 0.5 + 0.5, G = fy * 0.5 + 0.5, B = 0.5, A = 1.0; the
    decoded vector has magnitude half the distance of (R, G) from 0.5.
  - Per-site field (doc Algorithm block): radial part along -(rx, ry), the
    tangent (tx, ty) = (-ry, rx), scaled by exp(-r * falloff). On the pixel
    axis through a site the radial/tangent unit vectors are exactly (sign, 0)
    / (0, sign), so the field there is closed form; at the site's OWN texel
    r = 0 exactly and the unit vectors are 0, so the field is exactly the zero
    vector and the encode is exactly (0.5, 0.5) for either sign of conv.
  - exp decay law: the decoded magnitude at radius r over the value at the
    centre is exp(-r * falloff); at falloff = 0 the factor is 1 everywhere
    (uniform field).
  - Modulation: the four global textures decode via (sample - 0.5) * 2.0 * amt
    and offset all three sites simultaneously; a neutral (0.5) texture
    therefore does nothing whatever the depth, and an unconnected one
    (vs_black, all zeros) decodes to -1.
  - Superposition: the decoded three-site field equals the sum of the decoded
    single-site fields, wherever the encode does not clamp.
  - Co-located equal sites triple the magnitude (until the encode clamps).
  - Bypass outputs the neutral field exactly; the encode clamps at 0 and 1.

Mutations the tests must catch: flipped radial sign, dropped exponential
falloff scale, swapped R/G at the encode, modulation depth dropped.

Scope and limits: the clamp-to-edge sampling model with uniform (constant)
mod textures, whose samples are exact whatever the coordinate; only the texel
centre axes are claimed exact for the geometric closed forms (other pixels mix
interpolation error into the unit vectors). Falloff below 0 is outside the
dial's range and is not exercised. The exp() precision on a real GPU is a
tier-2 question.

Run:  tests/run.sh tests/modules/vf_vortex_multi/test_vf_vortex_multi.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_vortex_multi_mirror import F32, vortex_multi  # noqa: E402

N = 64          # geometric tests (site on a texel centre)
SMALL = 16      # uniform-content tests

SITE = 0.5078125        # (32 + 0.5) / 64: a texel centre at n = 64
C = 32                  # its texel index


def neutral_tex(n=SMALL):
    t = g.texture(n, n)
    t[...] = np.array([0.5, 0.5, 0.5, 1.0], F32)
    return t


def black_tex(n=SMALL):
    return g.texture(n, n)     # vs_black: all zeros, decodes to -1


def ramp_tex(axis, a, b, n=SMALL):
    """A linear ramp in channel 0 along axis (0 -> x, 1 -> y): a + b * coord."""
    u, v, _, _ = g.grid(n, n)
    t = g.texture(n, n)
    t[..., 0] = F32(a) + F32(b) * (u if axis == 0 else v)
    t[..., 1] = F32(0.5)
    t[..., 2] = F32(0.5)
    t[..., 3] = F32(1.0)
    return t


def dec(tex):
    """Decode f_vecfield's R,G back to (fx, fy) in float64."""
    return (tex[..., 0].astype(np.float64) - 0.5) * 2.0, \
           (tex[..., 1].astype(np.float64) - 0.5) * 2.0


def gen(**kw):
    h = w = kw.pop("n", N)
    return vortex_multi(h=h, w=w, **kw)


def only_site2(**kw):
    """Zero the other two sites so site 2's field is the whole output."""
    base = dict(s1_conv=0.0, s1_curl=0.0, s3_conv=0.0, s3_curl=0.0)
    base.update(kw)
    return gen(**base)


# --- encoding contract and neutral channels ---------------------------------------------

def test_b_and_a_channels_are_contract():
    out = gen(n=SMALL, in4=ramp_tex(0, 0.1, 0.9), conv_amt=0.5)
    b = float(np.abs(out[..., 2] - 0.5).max())
    a = float(np.abs(out[..., 3] - 1.0).max())
    check("B = 0.5 and A = 1.0 at every pixel", max(b, a), 0.0)


def test_centre_pixel_is_the_zero_vector():
    """At the site's own texel r = 0 exactly, so the radial and tangent unit
    vectors are both 0 and the summed field is exactly zero: encode
    (0.5, 0.5, 0.5, 1.0) to float32 rounding."""
    out = only_site2(n=N, s2_cx=SITE, s2_cy=SITE, s2_conv=0.6, s2_curl=0.4, falloff=2.0)
    p = out[C, C]
    err = float(np.abs(np.asarray(p, np.float64) - np.array([0.5, 0.5, 0.5, 1.0])).max())
    note("centre-texel encode (expect exactly 0.5, 0.5)", err)
    check("site centre texel encodes the zero vector exactly", err, 1e-7)


# --- closed forms on the pixel axes ------------------------------------------------------

def _err(bug=None):
    """Worst closed-form error of the decoded field across the three exact
    configs: the pixel-axis closed form, the co-located triple and the uniform
    zero-falloff field (each exact in its own regime)."""
    return max(_axis_err(bug), _coLoc_err(bug), _unif_err(bug))


def _axis_err(bug=None):
    """Closed-form error of the site-2 field on the two pixel axes through the
    site's texel. On a horizontal/vertical axis the radial unit vector is
    (+/-1, 0) or (0, +/-1) exactly and the tangent is its +90-degree rotation,
    so the field is (fx, fy) = (radial part, tangential part) in closed form
    with the exp decay factor."""
    n = N
    conv, curl, fo = 0.6, 0.4, 2.0
    out = only_site2(n=n, s2_cx=SITE, s2_cy=SITE, s2_conv=conv, s2_curl=curl,
                     falloff=fo, bug=bug)
    fx, fy = dec(out)
    u, v, _, _ = g.grid(n, n)
    expf = lambda r: np.exp(-np.asarray(r, np.float64) * fo)
    worst = 0.0
    for row in (C - 16, C + 16):                    # vertical axis, r = 0.25
        dy = float(v[row, C] - SITE)
        ry = np.sign(dy)
        r = abs(dy)
        ex_f = curl * (-ry) * expf(r)               # tx = -ry
        ey_f = -conv * ry * expf(r)
        worst = max(worst,
                    abs(float(fx[row, C]) - ex_f), abs(float(fy[row, C]) - ey_f))
    for col in (C - 16, C + 16):                    # horizontal axis, r = 0.25
        dx = float(u[C, col] - SITE)
        rx = np.sign(dx)
        r = abs(dx)
        ex_f = -conv * rx * expf(r)
        ey_f = curl * rx * expf(r)                  # ty = rx
        worst = max(worst,
                    abs(float(fx[C, col]) - ex_f), abs(float(fy[C, col]) - ey_f))
    return worst


def test_axis_closed_form():
    e = _axis_err()
    note("pixel-axis closed form (r = 0.25 either way), worst error", e)
    check("field on the pixel axes vs (-conv*rx, curl*rx)*exp(-r*fo)", e, 2e-5)


def _unif_err(bug=None):
    """Worst error of the uniform zero-falloff field: the decoded MAGNITUDE
    (fx, fy) = conv * (-rx, -ry) has constant size conv everywhere, whatever
    the pixel; only the direction rotates."""
    conv = 0.3
    out = only_site2(n=SMALL, s2_cx=SITE, s2_cy=SITE, s2_conv=conv, falloff=0.0, bug=bug)
    fx, fy = dec(out)
    return float(np.abs(np.hypot(fx, fy) - conv).max())


def test_uniform_field_at_zero_falloff():
    """exp(-r * 0) = 1 everywhere: a conv-only single site then has the same
    magnitude at every pixel — the whole texture is one constant value."""
    check("falloff 0: uniform field, magnitude conv everywhere", _unif_err(), 1e-7)


# --- modulation --------------------------------------------------------------------------

def test_uniform_cx_mod_shifts_the_field():
    """A uniform 0.75 cx texture at depth 0.5 decodes to +0.25, which at n = 64
    is exactly 16 texels: the shifted field equals the unshifted one moved by
    16 texels, texel for texel (all sites offset together)."""
    n = N
    m = neutral_tex(n)
    m[...] = np.array([0.75, 0.5, 0.5, 1.0], F32)   # decodes to +0.25
    off = 16                                        # 0.25 * n texels
    a = gen(n=n, cx_amt=0.5, in2=m)
    b = gen(n=n)
    worst = 0.0
    for ch in (0, 1):
        worst = max(worst, float(np.abs(a[:, off:, ch] - b[:, :-off, ch]).max()))
    check("uniform cx mod shifts every site by +0.25", worst, 1e-6)


def test_neutral_mod_textures_do_nothing_at_full_depth():
    worst = 0.0
    for amt in (0.5, 1.0):
        ne = neutral_tex(N)
        a = gen(n=N, cx_amt=amt, cy_amt=amt, conv_amt=amt, curl_amt=amt,
                in2=ne, in3=ne, in4=ne, in5=ne)
        b = gen(n=N)
        worst = max(worst, float(np.abs(a - b).max()))
    check("all-0.5 mod textures equal no mod at full depth", worst, 1e-7)


def _vs_black_peak_err(bug=None):
    """Largest decoded pull of a conv-only site along the horizontal row
    through it: conv > 0 is a sink, so the pull points toward the site centre
    and |pull| peaks at the texel on each side of it. vs_black over the cx mod
    inlet decodes to -1 (the vecfield contract's decode), so the centre sits at
    SITE - amt and the peak is the texel just right of that."""
    n = N
    conv, fo, amt = 0.8, 2.0, 0.3
    out = only_site2(n=n, cx_amt=amt, in2=black_tex(n), s2_cx=SITE, s2_cy=SITE,
                     s2_conv=conv, falloff=fo, bug=bug)
    fx, fy = dec(out)
    row = C
    u, _, _, _ = g.grid(n, n)
    peak = float(u[row][int(np.argmax(np.abs(fx[row])))])
    return abs(peak - (SITE - amt))


def test_vs_black_pulls_all_sites_by_minus_amt():
    # conv-only site: at r = 0 the decode is exactly zero, so the pull peaks on
    # the ring around the centre, not at the centre itself; measure instead the
    # field at a fixed offset: it must equal the un-shifted field at that
    # offset in magnitude, with the site moved by -amt -- done via the peak of
    # |pull| on the horizontal axis, which sits one texel to each side of the
    # centre; the check below uses the coarse peak position and 1 texel of slack.
    e = _vs_black_peak_err()
    note("pull-peak texel after the -amt cx shift (expect x = 0.2109375, one texel right of the shifted centre)", e)
    check("vs_black over cx moves the site by -amt", e, 1.5 / N)


# --- superposition -----------------------------------------------------------------------

def test_superposition_adds_decoded_fields():
    n = N
    kw = dict(s1_cx=0.3, s1_cy=0.4, s2_cx=0.6, s2_cy=0.6, s3_cx=0.7, s3_cy=0.3,
              s1_conv=0.4, s2_conv=0.3, s3_conv=0.2,
              s1_curl=0.2, s2_curl=-0.3, s3_curl=0.4, falloff=2.0)
    singles = []
    for k in range(3):
        z = {f"s{i}_conv": 0.0 for i in (1, 2, 3)}
        z.update({f"s{i}_curl": 0.0 for i in (1, 2, 3)})
        site = (1, 2, 3)[k]
        z[f"s{site}_conv"] = kw[f"s{site}_conv"]
        z[f"s{site}_curl"] = kw[f"s{site}_curl"]
        singles.append(gen(n=n, **{**kw, **z}))
    all3 = gen(n=n, **kw)
    sx = sum(dec(o)[0] for o in singles)
    sy = sum(dec(o)[1] for o in singles)
    inside = (np.abs(sx) <= 0.9) & (np.abs(sy) <= 0.9)
    assert inside.sum() > n * n // 4, "too little unsaturated area to compare"
    fx3, fy3 = dec(all3)
    err = max(float(np.abs(fx3[inside] - sx[inside]).max()),
              float(np.abs(fy3[inside] - sy[inside]).max()))
    check("three-site decoded field = sum of the single-site fields", err, 2e-6)


def _coLoc_err(bug=None):
    """Worst error of the co-located triple against 3x the single site."""
    conv, fo, n = 0.3, 2.0, N
    one = gen(n=n, s1_cx=SITE, s1_cy=SITE, s2_cx=SITE, s2_cy=SITE, s3_cx=SITE,
              s3_cy=SITE, s1_conv=0.0, s2_conv=conv, s3_conv=0.0, falloff=fo, bug=bug)
    three = gen(n=n, s1_cx=SITE, s1_cy=SITE, s2_cx=SITE, s2_cy=SITE, s3_cx=SITE,
                s3_cy=SITE, s1_conv=conv, s2_conv=conv, s3_conv=conv, falloff=fo, bug=bug)
    f1, _ = dec(one)
    f3, _ = dec(three)
    return float(np.abs(f3 - 3.0 * f1).max())


def test_coLocated_sites_triple_the_magnitude():
    e = _coLoc_err()
    note("co-located sites: worst |field - 3x single| (max single 0.3, never clamps)", e)
    check("three co-located equal sites = 3x one site (unclamped)", e, 2e-5)


# --- bypass, clamping, extremes ----------------------------------------------------------

def test_bypass_outputs_the_neutral_field():
    m = np.random.default_rng(13).random((N, N, 4)).astype(F32)
    out = gen(n=N, bypass=1.0, in2=m, in3=m, in4=m, in5=m,
              cx_amt=1.0, cy_amt=1.0, conv_amt=1.0, curl_amt=1.0,
              s1_curl=0.9, s2_curl=-0.9, s3_curl=0.9)
    check("bypass over full-strength modulation is exactly neutral",
          float(np.abs(out - np.array([0.5, 0.5, 0.5, 1.0], F32)).max()), 0.0)


def test_encode_clamps_both_sides():
    out = gen(n=SMALL, s1_cx=SITE, s1_cy=SITE, s2_cx=SITE, s2_cy=SITE, s3_cx=SITE,
              s3_cy=SITE, s1_conv=1.0, s2_conv=1.0, s3_conv=1.0,
              s1_curl=1.0, s2_curl=1.0, s3_curl=1.0, falloff=0.5)
    check("encode never below 0", max(-float(out[..., :2].min()), 0.0), 0.0)
    check("encode never above 1", max(float(out[..., :2].max()) - 1.0, 0.0), 0.0)
    sat = float(np.mean(np.isclose(out[..., 0], 0.0) | np.isclose(out[..., 0], 1.0)))
    note("fraction of R texels saturated in the overlapped strong-site case", sat)
    check("encode actually clamps to the rails somewhere", float(sat > 0.05), 1.0)


# --- mutations ----------------------------------------------------------------------------

def _shift_err(bug=None):
    """The 16-texel uniform cx_mod shift, recomputed for the mutation harness."""
    n = N
    m = neutral_tex(n)
    m[...] = np.array([0.75, 0.5, 0.5, 1.0], F32)
    a = gen(n=n, cx_amt=0.5, in2=m, bug=bug)
    b = gen(n=n, bug=bug)
    return max(float(np.abs(a[:, 16:, ch] - b[:, :-16, ch]).max()) for ch in (0, 1))


def _shift_err(bug=None):
    """The 16-texel uniform cx_mod shift, recomputed for the mutation harness."""
    n = N
    m = neutral_tex(n)
    m[...] = np.array([0.75, 0.5, 0.5, 1.0], F32)
    a = gen(n=n, cx_amt=0.5, in2=m, bug=bug)
    b = gen(n=n, bug=bug)
    return max(float(np.abs(a[:, 16:, ch] - b[:, :-16, ch]).max()) for ch in (0, 1))


def test_mutations_are_caught():
    bad = {"radial_source": _err("radial_source"),
           "no_falloff": _axis_err("no_falloff"),
           "swap_rg": _axis_err("swap_rg"),
           "mod_unscaled": max(_shift_err("mod_unscaled"), _vs_black_peak_err("mod_unscaled"))}
    for k, val in bad.items():
        note(f"mutation '{k}' worst error", val)
        if not val > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {val:.3e})")
    assert max(_shift_err(), 0.0) <= 1e-6 and _vs_black_peak_err() <= 1.5 / N and _coLoc_err() <= 2e-5, \
        f"the real mirror must pass the same checks: {_shift_err()}, {_vs_black_peak_err()}, {_coLoc_err()}"
    print("    ok   flipped radial sign, dropped falloff, swapped R/G and unscaled mod are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))