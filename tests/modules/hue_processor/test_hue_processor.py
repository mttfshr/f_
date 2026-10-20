"""
Tests for the f_hue_processor mirror, against independent ground truth:
the reference doc (docs/f-reference/f_hue_processor.md), Python's colorsys as an
independent HSV reference, and stated math identities (HSV round trip is the
identity at neutral params; bypass blends linearly; alpha passes through).

Band sides: hue_lower extends below the centre and hue_upper above, as the doc says
(test_band_extents_match_the_doc).
"""
import colorsys
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from hue_processor_mirror import F32, hue_processor  # noqa: E402

N = 32


def const_tex(rgb, n=N, a=1.0):
    t = g.texture(n, n)
    t[..., 0], t[..., 1], t[..., 2] = rgb
    t[..., 3] = a
    return t


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def hue_tex(hue_deg, s, v, n=N):
    """Uniform texture at hue_deg (float64 via colorsys); the codebox decode
    recovers the hue to float32 precision for s=1 (delta large)."""
    rgb = colorsys.hsv_to_rgb(hue_deg / 360.0, s, v)
    return const_tex(rgb, n)


def _run(params, src, bug=None):
    return hue_processor(src, bug=bug, **params)


def _maxabs(a, b):
    return float(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64)).max())


# --- identity at the neutral setting -------------------------------------------------------

def test_neutral_params_round_trip_to_the_source():
    """With sat_amt = lum_shift = hue_shift = 0 and bypass = 0 the mask changes nothing
    (all three blends add zero / shift by zero), so the HSV decode/encode round trip
    must recover the input exactly -- a math identity, checked on a random texture."""
    src = rand_tex(1)
    out = _run(dict(), src)
    check("neutral params recover the source (random texture)", _maxabs(out, src), 1e-5)


def test_bypass_passes_the_source_untouched():
    """Doc: bypass is a toggle 'Bypass processing'; the codebox mixes by (1 - bypass),
    so at bypass = 1 every channel including alpha equals the source exactly."""
    src = rand_tex(2)
    out = _run(dict(bypass=1.0), src)
    check("bypass=1 output equals the source", _maxabs(out, src), 1e-6)


def test_bypass_blends_linearly_generic_params():
    """Identity: bypass mixes the source and the fully processed frame by (1 - bypass),
    so at any generic parameter set out(bypass=t) = src*(1-t) + out(bypass=0)*t."""
    params = dict(hue_center=200.0, hue_lower=50.0, hue_upper=50.0, edge_falloff=15.0,
                  sat_amt=0.6, lum_shift=-0.2, hue_shift=37.0)
    src = rand_tex(3)
    full = _run(params, src)
    part = _run(dict(params, bypass=0.37), src)
    expect = src * F32(0.37) + full * F32(1.0 - 0.37)  # effective = 1 - bypass is the mix toward processed
    check("bypass=0.37 vs linear blend identity (generic params)", _maxabs(part, expect), 2e-5)


def test_alpha_passes_through_untouched():
    """Identity: the pass rewrites only RGB (src.a is copied), so alpha must equal the
    input alpha for every parameter value."""
    src = rand_tex(4)
    src[..., 3] = np.linspace(0.1, 0.9, N, dtype=F32)[:, None]
    out = _run(dict(sat_amt=-0.3, lum_shift=0.5, hue_shift=90.0,
                   hue_center=120.0, hue_lower=36.0, hue_upper=156.0, edge_falloff=10.0), src)
    check("alpha equals the input alpha at non-neutral params", _maxabs(out[..., 3], src[..., 3]), 1e-6)


# --- closed forms inside the band ----------------------------------------------------------

def test_full_desaturate_in_band_gives_flat_gray():
    """Doc: sat_amt '-1=full desaturate, 0=unchanged, 1=full boost, within the band'.
    A fully saturated in-band pixel with sat_amt=-1 has blended_S clamped to 0, so the
    re-encode collapses every channel to V (its cmax)."""
    src = hue_tex(120.0, 1.0, 0.7)
    out = _run(dict(sat_amt=-1.0), src)
    expect = np.full((N, N, 3), 0.7, F32)
    check("sat_amt=-1 at hue 120 gives flat V = 0.7", _maxabs(out[..., :3], expect), 1e-6)


def test_hue_rotation_red_becomes_green():
    """Doc: hue_shift is 'Hue rotation within the band, in degrees'. Pure red has hue 0
    (band centred at 0), and rotating by +120 degrees must land it on pure green."""
    src = hue_tex(0.0, 1.0, 1.0)
    out = _run(dict(hue_center=360.0 - 0.0, hue_shift=120.0), src)  # centre 360 == hue 0
    expect = np.zeros((N, N, 4), F32)
    expect[..., 1] = 1.0
    expect[..., 3] = 1.0
    check("pure red rotated by 120 degrees in-band gives pure green", _maxabs(out, expect), 1e-6)


def test_lum_shift_scales_channels_in_band():
    """Doc: lum_shift is 'additive to V within band'. Inside the flat top the mask is 1,
    so the output is the source scaled by (V + lum) / V: additive shift on V multiplies
    every channel by the same factor."""
    src = hue_tex(120.0, 0.8, 0.5)
    lum = 0.4
    out = _run(dict(lum_shift=lum), src)
    expect = src[..., :3].astype(np.float64) * (0.5 + lum) / 0.5
    err = _maxabs(out[..., :3], expect.astype(F32))
    check("in-band lum_shift scales each channel by (V+lum)/V", err, 1e-5)


def test_flat_top_band_edges_symmetric_bounds():
    """Doc/Concept: a flat-topped band 'centered on hue_center' with equal extents
    (both 36 degrees) and a hard edge (falloff 0). At +/-32 degrees the mask is 1
    (lum shift applies) and at +/-40 degrees it is 0 (output = source)."""
    for deg, inside in [(32.0, True), (-32.0, True), (40.0, False), (-40.0, False)]:
        src = hue_tex(120.0 + deg, 0.9, 0.6)
        out = _run(dict(hue_center=120.0, hue_lower=36.0, hue_upper=36.0,
                        edge_falloff=0.0, lum_shift=0.4), src)
        if inside:
            expect = src[..., :3].astype(np.float64) * 1.0 / 0.6
            err = _maxabs(out[..., :3], expect.astype(F32))
            check(f"{deg:+.0f} deg from centre is inside the flat top (scaled)", err, 1e-5)
        else:
            err = _maxabs(out[..., :3], src[..., :3])
            check(f"{deg:+.0f} deg from centre is outside the flat top (unchanged)", err, 1e-5)


# --- saturation gate ------------------------------------------------------------------------

def test_sat_gate_suppresses_full_gray():
    """Doc: 'a saturation gate ... suppresses the effect on near-gray pixels regardless of
    hue'. A fully gray pixel has S = 0, gate 0, mask 0: with lum_shift set the output must
    still equal the source."""
    src = const_tex((0.5, 0.5, 0.5))
    out = _run(dict(hue_center=0.0, hue_lower=36.0, hue_upper=36.0, lum_shift=0.5), src)
    check("gray pixel unaffected despite hue inside the band", _maxabs(out, src), 1e-6)


def test_sat_gate_half_at_documented_midpoint():
    """Doc states the gate is `smoothstep(0.05, 0.15, S)`; the standard smoothstep is 0.5
    at the midpoint S = 0.1. So lum_shift=0.5 must move V from 0.5 to 0.75 while hue and
    S are unchanged -- the expected RGB is colorsys's own HSV encode of (0, S=0.1, V=0.75)."""
    src = const_tex((0.5, 0.45, 0.45))  # S = 0.05/0.5 = 0.1, hue 0 = band centre
    out = _run(dict(hue_center=0.0, hue_lower=36.0, hue_upper=36.0, lum_shift=0.5), src)
    expect = np.zeros((N, N, 4), F32)
    expect[..., :3] = colorsys.hsv_to_rgb(0.0, 0.1, 0.75)
    expect[..., 3] = 1.0
    err = _maxabs(out, expect)
    check("S=0.1 gate midpoint: V moved by half of lum_shift (colorsys re-encode)", err, 1e-6)


def test_sat_gate_full_past_documented_upper_edge():
    """Doc states the gate is `smoothstep(0.05, 0.15, S)`; at S = 0.2 (above the upper
    edge) the gate is 1, so a chromatic in-band pixel gets the full lum_shift scaling."""
    src = hue_tex(120.0, 0.8, 0.5)  # S = 0.8
    out = _run(dict(lum_shift=0.4), src)
    expect = src[..., :3].astype(np.float64) * 0.9 / 0.5
    err = _maxabs(out[..., :3], expect.astype(F32))
    check("S above the gate's upper edge: full shift", err, 1e-5)


# --- band sides (the doc) ----------------------------------------------------------------

def test_band_extents_match_the_doc():
    """Doc: the band is 'centered on hue_center, extending hue_lower degrees below and hue_upper
    degrees above'. With lower = 36, upper = 156 (the shipped defaults), edge_falloff 1 and
    lum_shift 0.4, a pixel 90 degrees ABOVE the centre lies inside the flat top and must change,
    while one 90 degrees BELOW (outside lower + falloff) must be untouched."""
    params = dict(hue_center=120.0, hue_lower=36.0, hue_upper=156.0, edge_falloff=1.0, lum_shift=0.4)
    above = hue_tex(210.0, 1.0, 0.5)   # exactly +90 degrees above centre 120
    below = hue_tex(30.0, 1.0, 0.5)    # exactly -90 degrees below centre 120
    e_above = _maxabs(_run(params, above)[..., :3], above[..., :3])
    e_below = _maxabs(_run(params, below)[..., :3], below[..., :3])
    check("90 deg above centre is inside the band (changes by at least 0.2)", max(0.2 - e_above, 0.0), 0.0)
    check("90 deg below centre is outside the band (untouched)", e_below, 1e-5)


# --- outputs stay in range -------------------------------------------------------------------

def test_outputs_in_range_generic_params():
    """Everything is a mix/clip of values in [0, 1] at every stage the doc describes
    (clamped S, clamped V, branch-free encode clamped to [0,1]), so all outputs lie in
    [0, 1] at any parameter value."""
    src = rand_tex(5)
    worst = 0.0
    for params in [dict(sat_amt=1.0, lum_shift=1.0, hue_shift=180.0),
                   dict(sat_amt=-1.0, lum_shift=-1.0, hue_shift=-180.0)]:
        out = _run(dict(params, hue_center=200.0, hue_lower=50.0,
                       hue_upper=50.0, edge_falloff=15.0), src)
        worst = max(worst, float(np.minimum(out, 0.0).max()),
                    float(np.maximum(out - 1.0, 0.0).min() * -1.0))
    check("outputs stay inside [0, 1] at parameter extremes", worst, 1e-6)


# --- mutations --------------------------------------------------------------------------------

BUGS = ["no_sat_gate", "swap_rg", "swap_band_sides"]


def _err_gate_midpoint(bug=None):
    """V shift at the documented gate midpoint S = 0.1, judged against colorsys's
    re-encode of (hue 0, S = 0.1, V = 0.75)."""
    src = const_tex((0.5, 0.45, 0.45))
    out = _run(dict(hue_center=0.0, hue_lower=36.0, hue_upper=36.0, lum_shift=0.5), src,
              bug=bug)
    expect = np.zeros((N, N, 4), F32)
    expect[..., :3] = colorsys.hsv_to_rgb(0.0, 0.1, 0.75)
    expect[..., 3] = 1.0
    return _maxabs(out, expect)


def _err_gray_suppressed(bug=None):
    """Full gray in-band with lum_shift must be untouched; a missing gate would shift V."""
    src = const_tex((0.5, 0.5, 0.5))
    out = _run(dict(hue_center=0.0, hue_lower=36.0, hue_upper=36.0, lum_shift=0.5), src,
              bug=bug)
    return _maxabs(out, src)


def _err_red_to_green(bug=None):
    """Pure red rotated 120 degrees in-band must become pure green; a swapped R/G encode
    keeps it red."""
    src = hue_tex(0.0, 1.0, 1.0)
    out = _run(dict(hue_center=360.0, hue_shift=120.0), src, bug=bug)
    expect = np.zeros((N, N, 4), F32)
    expect[..., 1] = 1.0
    expect[..., 3] = 1.0
    return _maxabs(out, expect)


def _err_band_side(bug=None):
    """Doc: the band extends 'hue_lower degrees above and hue_upper degrees below' the
    centre, so with lower=36, upper=156 a pixel 100 degrees BELOW centre must be shifted;
    the codebox covers only hue_lower below, so the real mirror leaves it untouched and
    the swap bug (which follows the doc's mapping) changes it."""
    src = hue_tex(20.0, 1.0, 0.5)
    out = _run(dict(hue_center=120.0, hue_lower=36.0, hue_upper=156.0, lum_shift=0.4),
               src, bug=bug)
    return _maxabs(out[..., :3], src[..., :3])


def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin, and the real
    mirror must stay inside every tolerance it is run against."""
    real = [_err_gate_midpoint(), _err_gray_suppressed(), _err_red_to_green(),
            _err_band_side()]
    tol = [1e-6, 1e-6, 1e-6, 1e-5]
    for r, t in zip(real, tol):
        assert r <= t, f"real mirror drifted: {r:.3e} > {t:.0e}"
    caught = {}
    for bug in BUGS:
        errs = [_err_gate_midpoint(bug), _err_gray_suppressed(bug), _err_red_to_green(bug),
                _err_band_side(bug)]
        margin = max(e / t for e, t in zip(errs, tol) if e > t)
        caught[bug] = (max(errs), margin)
        assert margin > 10.0, f"bug {bug!r} not caught by a clear margin: {errs}"
        print(f"    ...  {bug}: worst error {max(errs):.3e}, caught with margin {margin:.0f}x")
    check("all three mutations caught (no gate, R/G swapped, band sides swapped)", 0.0, 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))