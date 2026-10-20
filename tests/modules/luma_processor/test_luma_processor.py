"""
test_luma_processor.py -- tier-1 NumPy tests for the f_luma_processor codebox.

Ground truth is independent of the mirror: Python colorsys outputs (computed
offline, embedded as literals) and the smoothstep mirror-symmetry identity
(smoothstep(e0, e1, e0 + d) = 1 - smoothstep(e0, e1, e0 - d), because its
normalized argument t mirrors to 1 - t). The expected values are never derived
from the codebox's own expressions.

Key colorsys-anchored facts used:
  - RGB -> HSV -> RGB with unchanged S, V is the identity.
  - Hue rotation by a whole turn is the identity (period 1 in the [0,1) hue encoding).
  - Shifting S by a, V by b, H by h at fixed H, S, V equals the colorsys literal
    hsv_to_rgb(H + h/360, S + a, V + b) with S and V clamped to [0, 1] as the codebox clamps
    (the literals include the clamp: colors 6 and 10 clamp S under sat_amt 0.3, color 6 clamps V
    under lum_shift 0.25).

Degenerate coverage: the neutral defaults, bypass on under extreme settings,
clamping at S = 1, mask support at the band edges, gray/black/white texels, and
one generic configuration with every parameter off its default.

Tolerances: the color set is exact in binary fractions so float32 error sits
around 1e-6..2e-6; all checks run at 2e-5 or tighter.

Run:  tests/run.sh tests/modules/luma_processor/test_luma_processor.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from luma_processor_mirror import F32, luma_processor  # noqa: E402

N = 24
LM, MH, EF = 0.2, 0.8, 0.05          # generic band: every color's luma sits strictly inside

# 12 unique saturated colors, no two equal channels (the codebox's hue branch
# needs a unique maximum channel), lumas all inside (lm + ef, mh - ef), S and V
# mostly low enough that the up-shifts do not clamp; colors 6 and 10 clamp S under
# sat_amt 0.3 and color 6 clamps V under lum_shift 0.25, and their literals are clamped.
COLORS = [
    (0.5, 0.25, 0.75),   # 0.75 hue, violet
    (0.75, 0.25, 0.5),   # 0.917
    (0.25, 0.5, 0.75),   # 0.583
    (0.5, 0.75, 0.25),   # 0.25
    (0.25, 0.25, 0.75),  # 0.667
    (0.75, 0.5, 0.25),   # 0.083
    (0.85, 0.45, 0.25),  # 0.056
    (0.75, 0.5, 0.75),   # 0.833
    (0.25, 0.75, 0.5),   # 0.417
    (0.5, 0.25, 0.25),   # 0.0
    (0.7, 0.45, 0.2),    # 0.083 region r
    (0.25, 0.75, 0.75),  # 0.5
]


def band_src():
    """Rows 2i and 2i+1 hold COLORS[i]; columns 0/8/16 hold black, gray 0.6, white
    for every row (gray texels are the chroma-free degenerate case)."""
    t = g.texture(N, N)
    for row in range(N):
        c = COLORS[(row // 2) % len(COLORS)]
        t[row, :, 0], t[row, :, 1], t[row, :, 2] = c[0], c[1], c[2]
    for col, gray in ((0, 0.0), (8, 0.6), (16, 1.0)):
        t[:, col, :3] = gray
    t[..., 3] = F32(1.0)
    return t


# --- embedded colorsys literals, one tuple per COLORS entry, in order ---------------------

EXP_HUE47 = [   # sat 0, lum 0, hue_shift 47 degrees
    (0.75, 0.25, 0.6083333), (0.75, 0.3916667, 0.25), (0.3916667, 0.25, 0.75),
    (0.25, 0.75, 0.3916667), (0.6416667, 0.25, 0.75), (0.6083333, 0.75, 0.25),
    (0.78, 0.85, 0.25), (0.75, 0.5, 0.5541667), (0.25, 0.6083333, 0.75),
    (0.5, 0.4458333, 0.25), (0.5583333, 0.7, 0.2), (0.25, 0.3583333, 0.75),
]
EXP_HUE200 = [  # hue_shift 200 (past the 120-degree branch seams)
    (0.3333333, 0.75, 0.25), (0.25, 0.75, 0.6666667), (0.75, 0.6666667, 0.25),
    (0.6666667, 0.25, 0.75), (0.5833333, 0.75, 0.25), (0.25, 0.3333333, 0.75),
    (0.25, 0.45, 0.85), (0.5, 0.75, 0.5833333), (0.75, 0.25, 0.3333333),
    (0.25, 0.4166667, 0.5), (0.2, 0.2833333, 0.7), (0.75, 0.4166667, 0.25),
]
EXP_SAT03 = [   # sat_amt 0.3 (colors 6 and 10 hit the S <= 1 clamp: their literals are clamped)
    (0.3875, 0.025, 0.75), (0.75, 0.025, 0.3875), (0.025, 0.3875, 0.75),
    (0.3875, 0.75, 0.025), (0.025, 0.025, 0.75), (0.75, 0.3875, 0.025),
    (0.85, 0.2833333, 0.0), (0.75, 0.275, 0.75), (0.025, 0.75, 0.3875),
    (0.5, 0.1, 0.1), (0.7, 0.35, 0.0), (0.025, 0.75, 0.75),
]
EXP_SATNEG2 = [  # sat_amt -0.2 (S - 0.2 >= 0 for every color)
    (0.575, 0.4, 0.75), (0.75, 0.4, 0.575), (0.4, 0.575, 0.75),
    (0.575, 0.75, 0.4), (0.4, 0.4, 0.75), (0.75, 0.575, 0.4),
    (0.85, 0.5633333, 0.42), (0.75, 0.65, 0.75), (0.4, 0.75, 0.575),
    (0.5, 0.35, 0.35), (0.7, 0.52, 0.34), (0.4, 0.75, 0.75),
]
EXP_LUM06 = [   # lum_shift 0.25 (color 6 hits the V <= 1 clamp: its literal is clamped)
    (0.6666667, 0.3333333, 1.0), (1.0, 0.3333333, 0.6666667), (0.3333333, 0.6666667, 1.0),
    (0.6666667, 1.0, 0.3333333), (0.3333333, 0.3333333, 1.0), (1.0, 0.6666667, 0.3333333),
    (1.0, 0.5294118, 0.2941176), (1.0, 0.6666667, 1.0), (0.3333333, 1.0, 0.6666667),
    (0.75, 0.375, 0.375), (0.95, 0.6107143, 0.2714286), (0.3333333, 1.0, 1.0),
]
EXP_LUMNEG04 = [  # lum_shift -0.35 (V - 0.35 >= 0 for every color)
    (0.2666667, 0.1333333, 0.4), (0.4, 0.1333333, 0.2666667), (0.1333333, 0.2666667, 0.4),
    (0.2666667, 0.4, 0.1333333), (0.1333333, 0.1333333, 0.4), (0.4, 0.2666667, 0.1333333),
    (0.5, 0.2647059, 0.1470588), (0.4, 0.2666667, 0.4), (0.1333333, 0.4, 0.2666667),
    (0.15, 0.075, 0.075), (0.35, 0.225, 0.1), (0.1333333, 0.4, 0.4),
]
EXP_GENERIC = [  # sat_amt 0.35, lum_shift -0.2, hue_shift 47
    (0.55, 0.0, 0.3941667), (0.55, 0.1558333, 0.0), (0.1558333, 0.0, 0.55),
    (0.0, 0.55, 0.1558333), (0.4308333, 0.0, 0.55), (0.3941667, 0.55, 0.0),
    (0.5741667, 0.65, 0.0), (0.55, 0.1741667, 0.2555972), (0.0, 0.3941667, 0.55),
    (0.3, 0.24475, 0.045), (0.3583333, 0.5, 0.0), (0.0, 0.1191667, 0.55),
]


def _unique_row_err(exp, sat_amt=0.0, lum_shift=0.0, hue_shift=0.0, bug=None):
    """Worst error over the 12 unique color rows (row 2i and 2i+1, column 5, away
    from the gray columns)."""
    out = luma_processor(band_src(), LM, MH, EF, sat_amt, lum_shift, hue_shift, bug=bug)
    worst = 0.0
    for i, e in enumerate(exp):
        v = out[i * 2, 5, :3].astype(np.float64)
        worst = max(worst, float(np.abs(np.array(e) - v).max()))
    return worst


# --- bypass and neutral identity ----------------------------------------------------------

def test_bypass_passes_the_source():
    """bypass = 1 (toggle on) is raw texture passthrough: the codebox mixes the
    HSV pipeline result toward the source with weight (1 - bypass), leaving only
    the source RGB, even under extreme settings on every other parameter."""
    src = band_src()
    out = luma_processor(src, 0.1, 0.9, 0.02, 1.0, 0.5, 200.0, bypass=1.0)
    e = float(np.abs(out - src).max())
    check("bypass returns the source under extreme settings", e, 1e-6)


def test_neutral_defaults_are_identity():
    """sat_amt = lum_shift = hue_shift = 0: the pipeline computes unchanged S, V,
    H and HSV -> RGB round-trips a color back to itself, at all 12 colors and
    the gray columns."""
    src = band_src()
    out = luma_processor(src)
    e = float(np.abs(out[..., :3] - src[..., :3]).max())
    check("neutral defaults reproduce the source", e, 2e-5)


# --- hue shift vs colorsys literals ---------------------------------------------------------

def test_hue_rotation_47_matches_colorsys():
    """A 47-degree hue rotation at unchanged S, V matches the embedded colorsys
    hsv_to_rgb literals for all 12 colors."""
    e = _unique_row_err(EXP_HUE47, hue_shift=47.0)
    check("hue shift 47 degrees vs colorsys literals", e, 2e-5)


def test_hue_rotation_200_crosses_every_branch():
    """A 200-degree rotation pushes every color's hue past the codebox's 120- and
    240-degree branch seams; the colorsys literals must still hold, so the branch
    choice cannot bias the hue."""
    e = _unique_row_err(EXP_HUE200, hue_shift=200.0)
    check("hue shift 200 degrees vs colorsys literals", e, 2e-5)


def test_hue_rotation_by_a_full_turn_is_identity():
    """The hue encoding has period 1, so hue_shift = 360 (a whole turn at mask 1)
    wraps back to the source hue and the output is the source itself."""
    src = band_src()
    out = luma_processor(src, LM, MH, EF, hue_shift=360.0)
    e = float(np.abs(out[..., :3] - src[..., :3]).max())
    check("hue_shift 360 returns the source", e, 2e-5)


# --- saturation and luma shift vs colorsys literals ------------------------------------------

def test_saturation_up_matches_colorsys():
    """sat_amt = 0.3 moves S to min(S + 0.3, 1) at fixed H, V (colors 6 and 10 clamp): the
    embedded colorsys literals expect exactly that."""
    e = _unique_row_err(EXP_SAT03, sat_amt=0.3)
    check("sat_amt 0.3 vs colorsys literals", e, 2e-5)


def test_saturation_down_matches_colorsys():
    """sat_amt = -0.2 with no clamp hit moves S to S - 0.2 at fixed H, V: the
    embedded colorsys literals expect exactly that."""
    e = _unique_row_err(EXP_SATNEG2, sat_amt=-0.2)
    check("sat_amt -0.2 vs colorsys literals", e, 2e-5)


def test_luma_shift_up_matches_colorsys():
    """lum_shift = 0.25 moves V to min(V + 0.25, 1) at fixed H, S (color 6 clamps): the
    embedded colorsys literals expect exactly that."""
    e = _unique_row_err(EXP_LUM06, lum_shift=0.25)
    check("lum_shift 0.25 vs colorsys literals", e, 2e-5)


def test_luma_shift_down_matches_colorsys():
    """lum_shift = -0.35 with no clamp hit moves V to V - 0.35 at fixed H, S: the
    embedded colorsys literals expect exactly that."""
    e = _unique_row_err(EXP_LUMNEG04, lum_shift=-0.35)
    check("lum_shift -0.35 vs colorsys literals", e, 2e-5)


def test_saturation_clamps_at_one():
    """A texel with S = 1 sits at saturation's maximum, so a positive sat_amt is
    clamped away and the fully saturated texel reproduces itself exactly."""
    t = g.texture(N, N)
    t[:, :, 0], t[:, :, 1], t[:, :, 2] = 1.0, 0.0, 0.5
    src = t.copy()
    out = luma_processor(t, LM, MH, EF, sat_amt=0.7)
    e = float(np.abs(out[0, :, :3] - src[0, :, :3]).max())
    check("sat_amt 0.7 clamps S = 1 sources to themselves", e, 2e-5)


def test_luma_shift_clamps():
    """Gray 0.5 inside the band with lum_shift 1 has clamped V = 1 and unchanged
    S = 0, so the output is exactly white; a color row pushed with lum_shift -1
    has clamped V = 0 and therefore zero output on every channel."""
    t = g.texture(N, N)
    t[:, :, :3] = 0.5
    out = luma_processor(t, LM, MH, EF, lum_shift=1.0)
    e_up = float(np.abs(out[0, :, :3].astype(np.float64) - 1.0).max())
    check("gray 0.5 + lum_shift 1 clamps to white", max(e_up, 0.0), 2e-5)
    src = band_src()
    out2 = luma_processor(src, LM, MH, EF, lum_shift=-1.0)
    e_dn = float(np.abs(out2[0, 5, :3]).max())   # row 0 is (0.5, 0.25, 0.75), V = 0.75
    check("lum_shift -1 clamps V = 0.75 to black", max(e_dn, 0.0), 2e-5)


def test_gray_texel_hue_pinned_codebox_quirk():
    """Pinned codebox behaviour, not a doc statement: a gray texel has r = g = b, so both the
    r-branch and g-branch hue terms fire and the hue lands at 1/3 (green), where
    colorsys.rgb_to_hsv puts gray at hue 0. With sat_amt 0.6 on gray 0.6 the output is therefore
    the colorsys literal hsv_to_rgb(1/3, 0.6, 0.6) = (0.24, 0.6, 0.24) and not
    hsv_to_rgb(0, 0.6, 0.6) = (0.6, 0.24, 0.24). Pinned 2026-10-20 as the codebox's current
    behaviour (review pending): it is only visible if saturation is applied to exact grays. If
    the codebox changes, update this literal deliberately."""
    t = g.texture(N, N)
    t[:, :, :3] = 0.6
    out = luma_processor(t, LM, MH, EF, sat_amt=0.6)
    e = float(np.abs(out[0, :, :3].astype(np.float64) - np.array([0.24, 0.6, 0.24])).max())
    check("gray 0.6 with sat_amt 0.6 vs colorsys literal (h=1/3, s=0.6, v=0.6)", e, 2e-5)


# --- the mask --------------------------------------------------------------------------------

def test_mask_is_half_at_the_band_edges():
    """smoothstep(e0, e1, e1) = 1 and the kernel's midpoint is 0.5, so a texel
    whose luma sits exactly on lm or mh has mask = 0.5; with lum_shift 0.4 the
    gray shows edge + 0.2 (0.4 keeps both clamps inactive)."""
    t = g.texture(N, N)
    t[:, :N // 2, :3] = LM
    t[:, N // 2:, :3] = MH
    out = luma_processor(t, LM, MH, EF, lum_shift=0.4)
    e_lo = abs(out[0, 5, 0].astype(np.float64) - (LM + 0.5 * 0.4))
    e_hi = abs(out[0, N // 2 + 5, 0].astype(np.float64) - (MH + 0.5 * 0.4))
    check("mask = 0.5 at lm and mh (smoothstep midpoint)", max(e_lo, e_hi, 0.0), 2e-5)


def test_mask_is_zero_outside_the_band():
    """A texel below lm - ef and one above mh + ef are fully outside the smoothstep
    ramps, so mask = 0 and even lum_shift = 1 leaves them untouched."""
    t = g.texture(N, N)
    t[:, 0, :3] = 0.0
    t[:, 10, :3] = 1.0
    out = luma_processor(t, LM, MH, EF, lum_shift=1.0, sat_amt=0.5, hue_shift=90.0)
    e = max(float(np.abs(out[5, 0, :3] - t[5, 0, :3]).max()),
            float(np.abs(out[5, 10, :3] - t[5, 10, :3]).max()))
    check("mask = 0 outside [lm - ef, mh + ef]", e, 2e-5)


def test_mask_mirror_symmetry_about_the_edges():
    """smoothstep's normalized argument mirrors under the edge (t -> 1 - t), so
    mask(edge - d) + mask(edge + d) = 1 at both edges; two gray rows equidistant
    around each edge shift by the mask amount, so with lum_shift 0.2 (inactive
    clamps) the paired shifts sum to exactly 0.2."""
    d = 0.02
    for edge in (LM, MH):
        t = g.texture(N, N)
        t[:, 0, :3] = edge - d
        t[:, 5, :3] = edge + d
        out = luma_processor(t, LM, MH, EF, lum_shift=0.2)
        lo = out[0, 0, 0].astype(np.float64) - (edge - d)
        hi = out[0, 5, 0].astype(np.float64) - (edge + d)
        e = abs(lo + hi - 0.2)
        check(f"mirror symmetry about edge {edge}: mask(x-d) + mask(x+d) = 1", max(e, 0.0), 2e-5)


def test_mask_respects_a_swapped_band():
    """min/max fold lm <= mh, so low_mid 0.8 with mid_high 0.2 selects the same
    [0.2, 0.8] band as the sorted pair: the shifted color row and the untouched
    outside grays come out identical either way."""
    a = luma_processor(band_src(), 0.2, 0.8, EF, lum_shift=0.25)
    b = luma_processor(band_src(), 0.8, 0.2, EF, lum_shift=0.25)
    e = float(np.abs(a[..., :3] - b[..., :3]).max())
    check("swapped low_mid/mid_high selects the same band", e, 1e-6)


# --- generic ---------------------------------------------------------------------------------

def test_generic_parameters_match_colorsys():
    """Every parameter at a generic off-default value (sat_amt 0.35, lum_shift
    -0.2, hue_shift 47 against the band 0.2/0.8, falloff 0.05) matches the
    embedded colorsys literals for all 12 unique colors -- the generic check the
    special-angle checks cannot replace."""
    e = _unique_row_err(EXP_GENERIC, sat_amt=0.35, lum_shift=-0.2, hue_shift=47.0)
    check("generic parameters vs colorsys literals", e, 2e-5)


def test_alpha_passes_through():
    """The output alpha is the source alpha directly: the codebox writes src.a
    untouched by the HSV pipeline, checked at a generic setting."""
    src = band_src()
    src[..., 3] = 0.75
    out = luma_processor(src, LM, MH, EF, 0.35, -0.2, 47.0)
    e = float(np.abs(out[..., 3] - src[..., 3]).max())
    check("alpha copies the source alpha", e, 1e-6)


# --- mutations --------------------------------------------------------------------------------

TOL = {"bypass": 1e-6, "hue47": 2e-5, "hue200": 2e-5, "sat03": 2e-5, "satneg": 2e-5,
       "lum06": 2e-5, "lumneg": 2e-5, "generic": 2e-5}
EXP = {"hue47": (EXP_HUE47, {"hue_shift": 47.0}), "hue200": (EXP_HUE200, {"hue_shift": 200.0}),
       "sat03": (EXP_SAT03, {"sat_amt": 0.3}), "satneg": (EXP_SATNEG2, {"sat_amt": -0.2}),
       "lum06": (EXP_LUM06, {"lum_shift": 0.25}), "lumneg": (EXP_LUMNEG04, {"lum_shift": -0.35}),
       "generic": (EXP_GENERIC, {"sat_amt": 0.35, "lum_shift": -0.2, "hue_shift": 47.0})}


def _errs(bug=None, **kw):
    """Error on bypass passthrough (kw ignored except bug) or on one literal set."""
    if "literal" in kw:
        exp, params = EXP[kw["literal"]]
        return _unique_row_err(exp, bug=bug, **params)
    src = band_src()
    out = luma_processor(src, 0.1, 0.9, 0.02, 1.0, 0.5, 200.0, bypass=1.0, bug=bug)
    return float(np.abs(out - src).max())


def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin, and the
    real mirror must stay inside every tolerance."""
    real = {}
    for k in EXP:
        exp, params = EXP[k]
        real[k] = _unique_row_err(exp, **params)
    real["bypass"] = _errs()
    for k, e in real.items():
        assert e <= TOL.get(k, 1e-6), f"real mirror exceeds tolerance on {k}: {e:.3e}"
    note("real mirror worst error over the shared checks", max(real.values()))
    for bug in ("swap_rg", "no_clamp", "mask_off"):
        be = {}
        be["bypass"] = _errs(bug=bug)
        for k in EXP:
            exp, params = EXP[k]
            be[k] = _unique_row_err(exp, bug=bug, **params)
        caught = {k: e for k, e in be.items() if np.isfinite(e) and e > 1e-3}
        if not caught:
            raise AssertionError(f"mutation '{bug}' survived every check")
        k = sorted(caught, key=lambda key: -caught[key])[0]
        note(f"mutation '{bug}' caught by {k}", caught[k])


if __name__ == "__main__":
    sys.exit(run(globals()))