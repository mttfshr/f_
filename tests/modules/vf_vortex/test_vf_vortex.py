"""
test_vf_vortex.py -- tier-1 NumPy tests for the f_vf_vortex codebox.

Ground truth is independent of the mirror: the reference doc's topology table
(sink for convergence > 0, source for < 0, pure rotation at convergence 0,
CCW for curl > 0), its encoding contract (R = fx * 0.5 + 0.5, 0.5 = zero
vector, B = 0.5, A = 1.0), its bypass statement ("Outputs neutral field (all
0.5)"), its "0 = uniform field" falloff statement, the modulation decode
identity, and math identities stated in one sentence (at the fixed point
dx = dy = 0 so both unit vectors are zero). Expected values are computed in
float64 at texel-centre coordinates, never by calling the mirror.

Caveat (review 2026-10-19): test_whole_frame_matches_float_true_reference and test_defaults_are_the_definition_values
re-derive the codebox's expressions in float32 / float64, so they guard dtype and operation order, not the algebra.
The falloff law is pinned independently by test_falloff_law_matches_the_doc; the topology, encoding, fixed-point,
modulation and bypass checks are independent of the codebox.

Run:  tests/run.sh tests/modules/vf_vortex/test_vf_vortex.py
"""
import math
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_vortex_mirror import F32, vortex  # noqa: E402

N = 32


def const_tex(rgba, n=N):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def decode(o):
    """Consumer-side decode of the f_vecfield encoding: (sample - 0.5) * 2."""
    return (o[..., 0] - F32(0.5)) * F32(2.0), (o[..., 1] - F32(0.5)) * F32(2.0)


def texel(i, j):
    """Texel-centre coordinates of grid cell (row j, col i): norm = (i + 0.5) / N."""
    return (F32(i) + F32(0.5)) / F32(N), (F32(j) + F32(0.5)) / F32(N)


def field64(cx, cy, conv, curl, fo):
    """Float64 reference at texel centres, with the falloff strength supplied
    explicitly by the caller as s(r): no falloff law is assumed here."""
    def core(cx_eff, cy_eff, conv_eff, curl_eff, strength):
        ii, jj = np.meshgrid(np.arange(N), np.arange(N), indexing="ij")
        dx = (jj + 0.5) / N - cx_eff
        dy = (ii + 0.5) / N - cy_eff
        r = np.sqrt(dx * dx + dy * dy)
        r_safe = np.maximum(r, 1e-4)
        fx = conv_eff * (-dx / r_safe) + curl_eff * (-dy / r_safe)
        fy = conv_eff * (-dy / r_safe) + curl_eff * (dx / r_safe)
        return fx * strength(r), fy * strength(r)
    return core(cx, cy, conv, curl, fo)


def ref_f32_true(cx, cy, conv, curl, fo):
    """Whole-frame reference in exactly the shader's arithmetic (np.float32
    intermediates, texel-centre norms, params in float32), to expose dtype and
    order-of-operations drift in the mirror rather than float32 rounding."""
    ii, jj = np.meshgrid(np.arange(N), np.arange(N), indexing="ij")
    nx = ((jj.astype(F32) + F32(0.5)) / F32(N)).astype(F32)
    ny = ((ii.astype(F32) + F32(0.5)) / F32(N)).astype(F32)
    dx = (nx - F32(cx)).astype(F32)
    dy = (ny - F32(cy)).astype(F32)
    r = np.sqrt(dx * dx + dy * dy).astype(F32)
    r_safe = np.maximum(r, F32(1e-4)).astype(F32)
    fx = F32(conv) * (-dx / r_safe) + F32(curl) * (-dy / r_safe)
    fy = F32(conv) * (-dy / r_safe) + F32(curl) * (dx / r_safe)
    s = np.exp(-r * np.maximum(F32(fo), F32(0))).astype(F32)
    return (fx * s).astype(F32), (fy * s).astype(F32)


# --- the encoding contract -----------------------------------------------------------

def test_encoding_contract_on_rgb_and_alpha():
    """Doc, Field Encoding: 'R = fx * 0.5 + 0.5, G = fy * 0.5 + 0.5, B = 0.5,
    A = 1.0'. B and A are constants, so they are pinned directly."""
    out = vortex(N, N)
    check("B is 0.5 everywhere (encoding)", float(np.abs(out[..., 2] - F32(0.5)).max()), 1e-7)
    check("A is 1.0 everywhere (encoding)", float(np.abs(out[..., 3] - F32(1.0)).max()), 0.0)


def test_bypass_is_neutral_field():
    """Doc parameter table: bypass 'Outputs neutral field (all 0.5)'. RGB goes
    to 0.5; the neutral vector's alpha is 1.0."""
    out = vortex(N, N, convergence=-0.9, curl=0.8, falloff=0.0, bypass=1.0)
    check("bypass gives all-0.5 RGB", float(np.abs(out[..., :3] - F32(0.5)).max()), 1e-7)
    check("bypass keeps alpha 1", float(np.abs(out[..., 3] - F32(1.0)).max()), 0.0)


def test_outputs_stay_in_range():
    """The encoding clamps to [0, 1], so no decoded value can exceed 1 in
    magnitude even at conv = curl = 1 with falloff 0 (field magnitude up to
    sqrt(2) where radial and tangential parts align). A dropped clamp would
    leave every unclamped value at magnitude sqrt(2), visible immediately."""
    out = vortex(N, N, convergence=1.0, curl=1.0, falloff=0.0)
    mag = np.abs(out[..., :2] - F32(0.5)) * F32(2.0)
    check("decoded magnitude stays at or below 1", max(float((mag - F32(1.0)).max()), 0.0), 0.0)
    note("unclamped magnitude would be exactly", float(math.sqrt(2.0)))
    check("decoded magnitude reaches exactly 1 somewhere (clamp binds)",
          max(float(mag.min()), 0.0), 2e-6)


def test_uniform_field_falloff_zero():
    """Doc parameter table: falloff '0 = uniform field'. With the fixed point
    on a texel centre, strength is exp(0) = 1 everywhere and on the row dy = 0
    the radial unit vector is (±1, 0): the field is exactly (-conv, 0) at the
    SAME magnitude left and right of centre."""
    cx, cy = texel(8, 16)
    out = vortex(N, N, cx=float(cx), cy=float(cy), convergence=-0.8, curl=0.0, falloff=0.0)
    fx_r, fy_r = decode(out[16, 24])
    fx_l, fy_l = decode(out[16, 2])
    check("falloff 0: uniform = same magnitude left and right of centre",
          max(abs(float(fx_r) + float(fx_l)), abs(float(fy_r) - float(fy_l))), 1e-6)
    check("falloff 0, source: outward magnitude 0.8 at +x to the right of centre",
          abs(float(fx_r) - 0.8), 1e-6)
    check("falloff 0, source: no tangential part", abs(float(fy_r)), 1e-6)
    # at every corner the field is the unit radial direction (math identity:
    # a radial direction always has magnitude 1), so the decoded magnitude is
    # exactly 0.8 at all four frame corners
    worst = 0.0
    for (ci, cj) in [(0, 0), (0, N - 1), (N - 1, 0), (N - 1, N - 1)]:
        mag = math.hypot(float(out[cj, ci, 0]) - 0.5, float(out[cj, ci, 1]) - 0.5) * 2
        worst = max(worst, abs(mag - 0.8))
    check("falloff 0: corner magnitude equals conv (unit radial, uniform)", worst, 1e-6)


# --- the topology table ---------------------------------------------------------------

def test_topology_sink_source_center():
    """Doc's topology table at falloff 0 (so magnitudes are exact) with the
    fixed point on a texel centre: right of centre a sink points inward (-x),
    a source outward (+x), pure rotation is +y (CCW), a spiral sink has both."""
    cx, cy = texel(8, 8)
    def at(conv, curl):
        return decode(vortex(N, N, cx=float(cx), cy=float(cy), convergence=conv,
                             curl=curl, falloff=0.0)[8, 24])
    fx, fy = at(0.8, 0.0)
    check("sink points inward at -x", abs(fx[()] + 0.8), 1e-6)
    check("sink has no tangential part", abs(fy[()]), 1e-6)
    fx, fy = at(-0.8, 0.0)
    check("source points outward at +x", abs(fx[()] - 0.8), 1e-6)
    fx, fy = at(0.0, 0.8)
    check("pure rotation: CCW = +y to the right of centre", abs(fy[()] - 0.8), 1e-6)
    check("pure rotation: no radial part", abs(fx[()]), 1e-6)
    fx, fy = at(0.5, 0.5)
    check("spiral sink: inward x-component", abs(fx[()] + 0.5), 1e-6)
    check("spiral sink: CCW y-component", abs(fy[()] - 0.5), 1e-6)


def test_curl_below_zero_is_clockwise():
    """Definition hint: 'Rotation. 0=none, >0=CCW, <0=CW'. CW at a point to
    the right of centre points in -y; the mirror must give the tangent, not
    its negation."""
    cx, cy = texel(8, 8)
    fx, fy = decode(vortex(N, N, cx=float(cx), cy=float(cy), convergence=0.0,
                           curl=-0.8, falloff=0.0)[8, 24])
    check("negative curl is CW: -y to the right of centre", abs(fy[()] + 0.8), 1e-6)


def test_offcentre_row_closed_forms():
    """Math identity, stated in one sentence: on the row through a texel-centre
    fixed point (dy = 0) the radial unit vector is (sign(dx), 0) and the
    tangential unit vector is (0, 0), so every decoded value there is
    (-conv * s, 0) with s the falloff strength; the strength profile itself is
    pinned by the doc-law check below, this check pins the sign and the
    tangential zero and the exact unit magnitude at falloff 0."""
    cx, cy = texel(10, 16)
    out = vortex(N, N, cx=float(cx), cy=float(cy), convergence=0.35, curl=0.0, falloff=0.0)
    worst = 0.0
    for i in range(N):
        if i == 10:
            continue
        sgn = 1.0 if i > 10 else -1.0
        worst = max(worst, abs(float(out[16, i, 0]) - (0.5 - sgn * 0.35 / 2.0)),
                    abs(float(out[16, i, 1]) - 0.5))
    check("dy = 0 row under falloff 0: exact inward/outward unit magnitude, tangential zero",
          worst, 1e-6)


# --- the fixed point -------------------------------------------------------------------

def test_fixed_point_is_the_zero_vector_at_any_convergence_or_curl():
    """Math identity: at the fixed point dx = dy = 0, so both unit vectors are
    exactly zero whatever the guard constant is; the field there is the zero
    vector, encoding 0.5 on both channels. The fixed point must sit on a texel
    centre so the codebox reaches r = 0 exactly."""
    j = 16
    cx, cy = texel(j, j)
    worst = 0.0
    for conv, curl in [(0.5, 0.0), (-0.7, 0.0), (0.0, 1.0), (0.6, 0.4), (-1.0, -1.0)]:
        out = vortex(N, N, cx=float(cx), cy=float(cy), convergence=conv, curl=curl, falloff=2.0)
        fx, fy = decode(out[j, j])
        worst = max(worst, abs(float(fx[()])), abs(float(fy[()])))
    check("fixed point decodes to the zero vector (0.5, 0.5) for any conv/curl", worst, 1e-7)


# --- modulation -----------------------------------------------------------------------

def test_modulation_black_offsets_to_zero_at_any_amt():
    """Doc, Field Encoding: '(sample.x - 0.5) * 2.0 * amt added to the base
    param value. At vs_black (0.5), offset is zero regardless of amt.'"""
    cfg = dict(convergence=0.0, curl=0.6, falloff=2.0)
    base = vortex(N, N, **cfg)
    black = const_tex((0.5, 0.5, 0.5, 1.0))
    worst = 0.0
    for amt in (0.3, 1.0):
        m = vortex(N, N, **cfg, convergence_amt=amt, mod_conv=black)
        worst = max(worst, float(np.abs(m - base).max()))
    check("mod texture 0.5 leaves the field unchanged at any amt", worst, 1e-6)


def test_modulation_extremes_decode_to_base_minus_plus_amt():
    """Same decode identity: a mod texel at 0 shifts the base convergence by
    -amt, a texel at 1 by +amt. Both frames are compared against the same
    float32-true whole-frame evaluation (centre parameters in float32, as the
    shader receives them), which the whole-frame test pins separately."""
    cfg0 = dict(convergence=0.0, curl=0.6, falloff=2.0)
    lo = vortex(N, N, **cfg0, convergence_amt=0.7, mod_conv=const_tex((0.0, 0.0, 0.0, 1.0)))
    hi = vortex(N, N, **cfg0, convergence_amt=0.7, mod_conv=const_tex((1.0, 1.0, 1.0, 1.0)))
    check("mod texel 0 with amt 0.7 equals convergence -0.7 directly",
          float(np.abs(lo - vortex(N, N, **dict(cfg0, convergence=-0.7))).max()), 1e-6)
    check("mod texel 1 with amt 0.7 equals convergence +0.7 directly",
          float(np.abs(hi - vortex(N, N, **dict(cfg0, convergence=0.7))).max()), 1e-6)


def test_unconnected_mod_inlet_reads_the_zero_color():
    """skill/jit-gen-codebox/SKILL.md: an inlet nothing is cabled to reads
    (0, 0, 0, 1), so the decode gives (-1) * amt, NOT zero -- the field at amt
    0.4 with no texture equals the field with conv shifted by -0.4."""
    cfg = dict(convergence=0.0, curl=0.6, falloff=2.0)
    none = vortex(N, N, **cfg, convergence_amt=0.4)          # unconnected inlet
    shifted = vortex(N, N, **dict(cfg, convergence=-0.4))    # base - amt
    check("unconnected modulation inlet decodes the (0,0,0,1) color",
          float(np.abs(none - shifted).max()), 1e-6)


# --- the doc's falloff law ------------------------------------------------------------

def test_falloff_law_matches_the_doc():
    """Doc Notes: 'Falloff uses `exp(-r * falloff)`', linear in r. At an on-axis point exactly r = 0.5 from
    the centre with falloff 2 the strength must be exp(-1) = 0.3679; a Gaussian exp(-r * r * falloff) would
    give exp(-0.5) = 0.6065. The expected value comes from the doc's law, not from the codebox."""
    cx, cy = texel(10, 16)          # fixed point on a texel centre
    out = vortex(N, N, cx=float(cx), cy=float(cy), convergence=0.35, curl=0.0, falloff=2.0)
    r = 0.5                          # column 26: (26.5 - 10.5) / 32 = 0.5 exactly
    doc_mag = float(np.exp(-r * 2.0))
    check("on-axis strength at r = 0.5 equals the doc's exp(-r * falloff)",
          abs(float(out[16, 26, 0]) - (0.5 - 0.35 * doc_mag / 2.0)), 1e-5)


# --- float64 whole-frame reference ---------------------------------------------------

def test_whole_frame_matches_float_true_reference():
    """Math source: the whole-frame reference re-evaluates the same decode and
    unit-vector expressions at texel-centre norms with parameters converted to
    float32 exactly as the shader receives them, so any dtype, order or
    convention mistake shows as a large residual (float32 rounding alone is
    ~1e-7). Cases include the centre, a spiral sink and an off-centre
    configuration whose unclamped field magnitude exceeds 1 (sqrt(0.25+0.81)),
    which is why the encoded comparison also covers the clamp."""
    worst = 0.0
    for cx, cy, conv, curl, fo in [(0.5, 0.5, 0.5, 0.0, 2.0), (0.5, 0.5, 0.6, 0.4, 2.0),
                                   (0.3, 0.7, -0.5, -0.9, 1.5)]:
        out = vortex(N, N, cx=cx, cy=cy, convergence=conv, curl=curl, falloff=fo)
        fx, fy = ref_f32_true(cx, cy, conv, curl, fo)
        R = np.clip(fx * F32(0.5) + F32(0.5), F32(0), F32(1))
        G = np.clip(fy * F32(0.5) + F32(0.5), F32(0), F32(1))
        worst = max(worst, float(np.abs(out[..., 0] - R).max()),
                    float(np.abs(out[..., 1] - G).max()))
    check("mirror vs re-derived reference over three parameter sets", worst, 1e-6)


def test_defaults_are_the_definition_values():
    """The definition's shipped defaults are the neutral params above; the
    frame the mirror produces with no explicit args must equal the frame at
    the defaults typed out, so a flipped or doubled default constant breaks
    the test. Source: definition.py's Param defaults."""
    check("no-arg call equals the explicit default call",
          float(np.abs(vortex(N, N) - vortex(N, N, cx=0.5, cy=0.5, convergence=0.5,
                                             curl=0.0, falloff=2.0)).max()), 0.0)
    # the actual default frame must be a NON-degenerate sink: at the row-8,
    # col-30 texel (norm (30.5/32, 8.5/32)) the texel-centre offset from
    # (0.5, 0.5) is dx = 0.484375, dy = -0.234375, r = hypot = 0.51015..., so
    # the decoded magnitude is 0.5 * exp(-r * 2) (the doc's law)
    fx, fy = decode(vortex(N, N)[8, 30])
    r = math.hypot(30.5 / 32 - 0.5, 8.5 / 32 - 0.5)
    check("default dial setting decodes to 0.5 * exp(-r * 2) at that texel",
          abs(float(np.hypot(fx[()], fy[()])) - 0.5 * math.exp(-r * 2.0)), 1e-6)


# --- mutations ------------------------------------------------------------------------

def _frame_err(bug=None):
    worst = 0.0
    for cx, cy, conv, curl, fo in [(0.3, 0.7, -0.5, -0.9, 1.5), (0.5, 0.5, 1.0, 1.0, 0.0)]:
        out = vortex(N, N, cx=cx, cy=cy, convergence=conv, curl=curl, falloff=fo, bug=bug)
        fx, fy = ref_f32_true(cx, cy, conv, curl, fo)
        R = np.clip(fx * F32(0.5) + F32(0.5), F32(0), F32(1))
        G = np.clip(fy * F32(0.5) + F32(0.5), F32(0), F32(1))
        worst = max(worst, float(np.abs(out[..., 0] - R).max()),
                    float(np.abs(out[..., 1] - G).max()))
    return worst


def _fixed_point_err(bug=None):
    out = vortex(N, N, convergence=0.6, curl=0.5, falloff=1.0,
                 cx=float(texel(16, 16)[0]), cy=float(texel(16, 16)[1]), bug=bug)
    fx, fy = decode(out[16, 16])
    return max(abs(float(fx[()])), abs(float(fy[()])))


def _vertical_line_err(bug=None):
    """On the vertical line through a texel-centre fixed point (dx = 0) the
    radial unit vector is (0, sign(dy)) and the tangential x-component is
    -sign(dy): fy is conv-only with a sign, fx is curl-only with the opposite
    sign, so a division instead of a multiplication, a dropped negation on the
    fy line, or a flipped additive sign all break the closed forms."""
    cx, cy = texel(13, 13)
    worst = 0.0
    for conv, curl in [(0.4, 0.6), (-0.4, 0.6)]:
        out = vortex(N, N, cx=float(cx), cy=float(cy), convergence=conv,
                     curl=curl, falloff=0.0, bug=bug)
        for i in range(N):
            if i == 13:
                continue
            sgn = 1.0 if i > 13 else -1.0
            worst = max(worst, abs(float(out[i, 13, 0]) - (0.5 - sgn * curl / 2.0)),
                        abs(float(out[i, 13, 1]) - (0.5 - sgn * conv / 2.0)))
    return worst


def test_vertical_line_tangential_closed_form():
    check("dx = 0 column: fx = -sign(dy)*curl, fy = -sign(dy)*conv (CCW tangent)",
          _vertical_line_err(), 1e-6)


def test_mutations_are_caught():
    real = [_frame_err(), _fixed_point_err(), _vertical_line_err()]
    bad = {"sign_flip": max(_frame_err("sign_flip"),
                            _vertical_line_err("sign_flip")),
           "wrong_guard": max(_fixed_point_err("wrong_guard"), _frame_err("wrong_guard")),
           "swap_rg": max(_frame_err("swap_rg"), _fixed_point_err("swap_rg")),
           "no_clamp": max(_frame_err("no_clamp"), _vertical_line_err("no_clamp")),
           "gaussian_falloff": _frame_err("gaussian_falloff")}
    for k, v in bad.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 0.001:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    assert max(real) < 1e-6, f"the real mirror must pass the same checks: {real}"
    print("    ok   sign flip, wrong guard, swapped R/G, a missing clamp and a Gaussian falloff are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))