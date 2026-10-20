"""
Tier-1 tests for f_vf_optical_flow Stage C (closed-form 2x2 Lucas-Kanade solve).
Mirror: vf_optical_flow_mirror.stage_c, a hand translation of the shipped codebox
(src/f_vf_optical_flow/codebox_stage_c.gen). Ground truth is independent:

  - recovery of a known translation (u0, v0) from sums built, per the brief, as
    Sxx = sum Ix^2, Sxy = sum Ix Iy, Sxt = sum Ix It with It = -(Ix u0 + Iy v0):
    the closed-form Cramer result is then exactly (u0, v0) by construction
    (checkable in float64 by hand: with (Ix,Iy)=(3,1),(1,4), u0=0.3125, v0=-0.25
    the sums are sxx=10, syy=17, sxy=7, sxt=-1.375, syt=2.0625, det=121,
    u=(1.375*17+7*2.0625)/121=0.3125, v=(-10*2.0625+7*(-1.375))/121=-0.25).
  - Lagrange's identity for per-pixel two-sample sums: det = (Ix1*Iy2 - Iy1*Ix2)^2,
    so a proportional-gradient (aperture-problem) tensor has det exactly 0.
  - np.linalg.solve for the 2x2 system and np.linalg.eigh for the axis (allowed
    reference library, rule 3c).
  - the textbook smoothstep(0,1,x) = 3t^2-2t^3 with t = clamp((x-lo)/(hi-lo)), and
    mix as a linear blend, both evaluated in float64.
  - the doc's encoding statements (0.5 = zero vector, out1.x unclamped raw det,
    bypass reads neutral / zero confidence), quoted in each test's docstring.

The doc's out0/out1 are the codebox's out1/out2; the mirror returns (out1, out2)
in the codebox's naming. Stages A, B, D, E are NOT covered here (not this unit).

Note: two generic-pipeline comparisons use tolerance 1e-4 (not 1e-5): the expected
value chains a float32-textured Cramer solve into smoothstep and mix in float64, and
float32 rounding of an O(1) Cramer quotient contributes up to a few 1e-5 absolute.
Exact-structure checks (translation, neutral, bypass, aperture, raw det) use 0.0.
Tests do not open files; all reference values are stated or derived inline.
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_optical_flow_mirror import F32, stage_c  # noqa: E402

N = 16


def _worst(measured, expect, mask=None):
    """Worst |measured - expect| over mask, float64. Any non-finite mirror value is a
    hard error (a plain max would keep a finite neighbour and let a NaN slip past)."""
    m_ = np.ones(measured.shape[:2], bool) if mask is None else mask
    md = measured.astype(np.float64)
    bad = (~np.isfinite(md)).any(axis=-1) & m_
    d = np.abs(md - expect)
    d = d[m_ & np.isfinite(d).all(axis=-1)]
    if bad.any() or d.size == 0:
        return 10.0
    return float(d.max())


def _rng(seed):
    return np.random.default_rng(seed)


def _sums(a, b, c, d, p, q):
    """Build Stage B's five sums from two gradient samples (Ix,Iy)=(a,b),(c,d) per pixel
    (each an (N,N) float32 array), with It_i = -(Ix_i p + Iy_i q). The normal equations'
    solution is then exactly (p, q): sxx*p + sxy*q = -sxt and sxy*p + syy*q = -syt.
    All values dyadic, so the float32 sums are exact."""
    a, b, c, d, p, q = (np.asarray(x, F32) for x in (a, b, c, d, p, q))
    sxx = (a * a + c * c).astype(F32)
    syy = (b * b + d * d).astype(F32)
    sxy = (a * b + c * d).astype(F32)
    sxt = (-(p * sxx + q * sxy)).astype(F32)
    syt = (-(p * sxy + q * syy)).astype(F32)
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], axis=-1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], axis=-1).astype(F32)
    return in1, in2, sxx, syy, sxy, sxt, syt


def _field64(u, v, gain, bypass=0.0):
    """The doc's encoding in float64: 0.5-centred vecfield, clamped to [0,1]."""
    r = np.clip(u * gain * 0.5 + 0.5, 0.0, 1.0)
    gr = np.clip(v * gain * 0.5 + 0.5, 0.0, 1.0)
    return np.stack([r, gr, np.full_like(r, 0.5), np.ones_like(r)], axis=-1)


def _smoothstep64(lo, hi, x):
    t = np.clip((x - lo) / (hi - lo), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def _generic_inputs(seed):
    """Per-pixel two gradient pairs with dyadic values, and per-pixel true flows (p, q).
    Returns (in1, in2, dict of per-pixel floats). det = (a*d - b*c)^2 >= 0 (Lagrange)."""
    r = _rng(seed)
    k = (r.integers(-8, 9, (N, N)) / 8.0).astype(np.float64)
    a, b, c, d = [k + (r.integers(-2, 3, (N, N)) / 8.0) for _ in range(4)]
    p = (r.integers(-2, 3, (N, N)) / 8.0).astype(np.float64)
    q = (r.integers(-2, 3, (N, N)) / 8.0).astype(np.float64)
    in1, in2, sxx, syy, sxy, sxt, syt = _sums(a, b, c, d, p, q)
    det = (sxx * syy - sxy * sxy)
    return in1, in2, dict(a=a, b=b, c=c, d=d, p=p, q=q, sxx=sxx, syy=syy, sxy=sxy,
                          sxt=sxt, syt=syt, det=det)


def _small_inputs(seed):
    """Like _generic_inputs but with small gradient values (~1e-2), so the per-pixel
    determinants land in and around the 1e-4 divisor-floor band. Sums built in float64
    from dyadic values, exact in float32."""
    r = _rng(seed)
    k = (r.integers(-4, 5, (N, N)) / 80.0).astype(np.float64)
    a, b, c, d = [k + (r.integers(-2, 3, (N, N)) / 80.0) for _ in range(4)]
    p = (r.integers(-2, 3, (N, N)) / 8.0).astype(np.float64)
    q = (r.integers(-2, 3, (N, N)) / 8.0).astype(np.float64)
    aa, bb, cc, dd, pp, qq = (np.asarray(x, F32).astype(np.float64) for x in (a, b, c, d, p, q))
    sxx = (aa * aa + cc * cc)
    syy = (bb * bb + dd * dd)
    sxy = (aa * bb + cc * dd)
    sxt = -(pp * sxx + qq * sxy)
    syt = -(pp * sxy + qq * syy)
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], axis=-1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], axis=-1).astype(F32)
    return in1, in2, dict(a=a, b=b, c=c, d=d, p=p, q=q, sxx=sxx, syy=syy, sxy=sxy,
                          sxt=sxt, syt=syt, det=sxx * syy - sxy * sxy)


def _flat(rgba, n=N):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


# --- neutral, bypass, encoding -----------------------------------------------------------------

def test_neutral_on_zero_sums():
    """No data at all (all sums zero): the flow is the zero vector, so the field
    reads 0.5-centred neutral (doc: "standard f_vecfield, (u,v) encoded 0.5-centered"),
    the raw det is exactly 0 and the axis remap reads exactly 0.5."""
    out1, out2 = stage_c(_flat((0, 0, 0, 1)), _flat((0, 0, 0, 1)))
    expect1 = np.zeros((N, N, 4)); expect1[...] = (0.5, 0.5, 0.5, 1.0)
    expect2 = np.zeros((N, N, 4)); expect2[...] = (0.0, 0.5, 0.5, 1.0)
    check("zero sums: out1 exactly neutral", _worst(out1, expect1), 0.0)
    check("zero sums: out2 exactly (0, 0.5, 0.5, 1)", _worst(out2, expect2), 0.0)


def test_bypass_neutral_and_zeroed_confidence():
    """bypass = 1: "Outputs pass through neutral (out0) / zero confidence (out1)" --
    out1 exactly neutral and out2 exactly (0, 0.5, 0.5, 1) whatever the sums say."""
    in1, in2, s = _generic_inputs(1)
    out1, out2 = stage_c(in1, in2, bypass=1.0)
    expect1 = np.zeros((N, N, 4)); expect1[...] = (0.5, 0.5, 0.5, 1.0)
    expect2 = np.zeros((N, N, 4)); expect2[...] = (0.0, 0.5, 0.5, 1.0)
    check("bypass: out1 exactly neutral", _worst(out1, expect1), 0.0)
    check("bypass: out2 exactly (0, 0.5, 0.5, 1)", _worst(out2, expect2), 0.0)


# --- LK solve ----------------------------------------------------------------------------------

def test_known_translation_recovered_closed_form():
    """With sums built from It = -(Ix u0 + Iy v0) the Cramer solve must return exactly
    (u0, v0): by hand, u = (1.375*17 + 7*2.0625)/121 = 37.8125/121 = 0.3125 and
    v = -30.25/121 = -0.25, both dyadic, so float32 is exact (tolerance 0.0)."""
    a = np.full((N, N), 3.0); b = np.full((N, N), 1.0)
    c = np.full((N, N), 1.0); d = np.full((N, N), 4.0)
    p = np.full((N, N), 0.3125); q = np.full((N, N), -0.25)
    in1, in2, *_ = _sums(a, b, c, d, p, q)
    out1, out2 = stage_c(in1, in2)
    expect1 = np.zeros((N, N, 4)); expect1[...] = (0.65625, 0.375, 0.5, 1.0)
    check("translation (0.3125, -0.25) encoded exactly", _worst(out1, expect1), 0.0)
    check("raw det exactly 121 (Lagrange: (3*4-1*1)^2)", _worst(out2[..., :1], 121.0), 0.0)
    out1b, _ = stage_c(in1, in2, gain=0.7)
    check("gain scales the encode linearly (gain 0.35)", _worst(out1b[..., 0], 0.5 + 0.3125 * 0.35), 1e-5)
    out1c, _ = stage_c(in1, in2, gain=-2.0)
    check("gain -2 inverts flow: encode 0.5 + u*(-1)", _worst(out1c[..., 0], 0.1875), 0.0)


def test_solve_matches_numpy_linalg():
    """np.linalg.solve([[sxx, sxy], [sxy, syy]], [-sxt, -syt]) is the independent
    reference for the Cramer result; where det > 1e-4 and the mask is effectively full
    (det near or above mask_hi) the field must equal the solved (u, v) encoded. Pixels
    with det just above the floor are excluded: there the divisor's floor itself changes
    the value by up to 0.5, which np.linalg.solve does not model."""
    in1, in2, s = _generic_inputs(2)
    det64 = s["sxx"].astype(np.float64) * s["syy"] - s["sxy"].astype(np.float64) ** 2
    good = det64 > 1e-4
    lo, hi = np.float64(0.0), np.float64(1.0)
    out1, _ = stage_c(in1, in2, mask_lo=0.0, mask_hi=1.0)
    T = np.stack([np.stack([s["sxx"], s["sxy"]], -1), np.stack([s["sxy"], s["syy"]], -1)], -2)
    rhs = np.stack([-s["sxt"], -s["syt"]], -1)
    Ti, ri = T.reshape(-1, 2, 2)[good.reshape(-1)], rhs.reshape(-1, 2, 1)[good.reshape(-1)]
    uv = np.linalg.solve(Ti, ri)[..., 0].reshape(-1, 2)
    uvfull = np.zeros((N * N, 2)); uvfull[good.reshape(-1)] = uv
    uv = uvfull.reshape(N, N, 2)
    mask64 = _smoothstep64(lo, hi, det64)
    expect = (1 - mask64)[..., None] * 0.5 + mask64[..., None] * _field64(uv[..., 0], uv[..., 1], 1.0)
    strong = good & (det64 > 0.5)     # mask effectively 1: smoothstep(0,1,det) > 1-1e-6
    check("out1 rg vs np.linalg.solve where the mask is effectively full",
          _worst(out1[..., :2], expect[..., :2], strong), 1e-4)


def test_divisor_floor_over_writes_near_singular_pixels():
    """Where raw det is between 0 and the 1e-4 divisor floor, the field must equal the
    Cramer solve with det_safe = 1e-4 -- the floor's whole visible effect, checked
    pixel-for-pixel against np.linalg.solve of the floored tensor (a reference solve,
    not a mirror retyping). The alpha channel is NOT part of the solve: it must be
    exactly 1, which the mixed pipeline check above cannot see."""
    in1, in2, s = _small_inputs(7)
    det64 = s["sxx"].astype(np.float64) * s["syy"] - s["sxy"].astype(np.float64) ** 2
    # pixels whose field the divisor's floor modifies but which still pass the mask
    zone = (det64 > 0.0) & (det64 < 1e-4)
    assert zone.sum() > 0, "need pixels between 0 and the divisor floor"
    out1, out2 = stage_c(in1, in2, mask_lo=1e-9, mask_hi=1e-2)
    T = np.stack([np.stack([s["sxx"], s["sxy"]], -1), np.stack([s["sxy"], s["syy"]], -1)], -2)
    rhs = np.stack([-s["sxt"], -s["syt"]], -1)
    # the codebox divides by max(det, 1e-4) but keeps the raw numerator, so the solved
    # value is exactly solve(T, rhs) * (det / max(det, 1e-4)), in float64
    Ti, ri = T.reshape(-1, 2, 2)[zone.reshape(-1)], rhs.reshape(-1, 2, 1)[zone.reshape(-1)]
    uv = np.linalg.solve(Ti, ri)[..., 0]
    scale = (det64[zone] / np.maximum(det64[zone], 1e-4))
    uvfull = np.zeros((N * N, 2)); uvfull[zone.reshape(-1)] = uv * scale[:, None]
    uv = uvfull.reshape(N, N, 2)
    t = np.clip((det64 - 1e-9) / (1e-2 - 1e-9), 0, 1)
    mask64 = t * t * (3.0 - 2.0 * t)
    expect = (1 - mask64)[..., None] * 0.5 + mask64[..., None] * _field64(uv[..., 0], uv[..., 1], 1.0)
    check("floor-band pixels vs solve(T, rhs) scaled by det/max(det, floor)",
          _worst(out1[..., :2], expect[..., :2], zone), 2e-4)
    check("alpha exactly 1 on out1 and out2 everywhere",
          max(_worst(out1[..., 3:], 1.0), _worst(out2[..., 3:], 1.0)), 0.0)


# --- confidence gate and raw determinant -------------------------------------------------------

def test_mask_gate_at_thresholds():
    """Doc: "det at or below this reads as no-flow (neutral)" and "det at or above this
    passes at full strength". At det = mask_lo exactly the output is exactly neutral; at
    det >= mask_hi exactly the unmasked field."""
    a = np.full((N, N), 3.0); b = np.full((N, N), 1.0)
    c = np.full((N, N), 1.0); d = np.full((N, N), 4.0)
    p = np.full((N, N), 0.3125); q = np.full((N, N), -0.25)
    in1, in2, *_ = _sums(a, b, c, d, p, q)
    neutral = np.zeros((N, N, 4)); neutral[...] = (0.5, 0.5, 0.5, 1.0)
    field = np.zeros((N, N, 4)); field[...] = (0.65625, 0.375, 0.5, 1.0)
    o_lo, _ = stage_c(in1, in2, mask_lo=121.0, mask_hi=200.0)
    check("det == mask_lo: out1 exactly neutral", _worst(o_lo, neutral), 0.0)
    o_hi, _ = stage_c(in1, in2, mask_lo=50.0, mask_hi=121.0)
    check("det == mask_hi: out1 exactly the field", _worst(o_hi, field), 0.0)


def test_neg_det_zero_axis_and_floor_division():
    """The floor max(det, 1e-4) is used ONLY in the divisor: out2.x reports the raw
    (doc: "raw determinant ... unclamped") determinant, and the mask gates on raw det.
    (a) Inconsistent sums (sxx=1, syy=1, sxy=2 by Cauchy-Schwarz: det = -3) with a tiny
    mask_hi: out1 exactly neutral; out2.x = -3 exactly, and the axis exactly 0.5 because
    sxx = syy makes dx = 0 while 2sxy / mag_safe = 0 (both components exactly 0, the
    isotropic floor case the code comments call arbitrary-but-harmless).
    (b) Tiny positive det (9e-8 < 1e-4): the divisor's own floor engages.
    (c) The aperture zero-LS case: with sxx=20, syy=5, sxy=10 the solve's exact answer is
    u = v = 0 (right side proportional to the tensor's columns: -sxt = -(sxx,sxy)*0.075,
    -syt = -(sxy,syy)*0.075), so the field must be exactly neutral there as well."""
    sxx = np.full((N, N), 1.0); syy = np.full((N, N), 1.0)
    sxy = np.full((N, N), 2.0)                       # det = 1 - 4 = -3
    sxt = np.full((N, N), 2e-4); syt = np.full((N, N), -1e-4)
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], -1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], -1).astype(F32)
    out1, out2 = stage_c(in1, in2, mask_lo=0.0, mask_hi=2e-5)
    neutral = np.zeros((N, N, 4)); neutral[...] = (0.5, 0.5, 0.5, 1.0)
    check("det < 0: out1 exactly neutral (mask gates on raw det)", _worst(out1, neutral), 0.0)
    check("det < 0: out2.x raw det, unclamped", _worst(out2[..., :1], -3.0), 0.0)
    zaxis = np.zeros((N, N, 2)); zaxis[..., 0] = 0.5; zaxis[..., 1] = 1.0
    check("det < 0: out2.y/z exactly (cos=0, sin=1): pure-diagonal texel, dx/mag = 0",
          _worst(out2[..., 1:3], zaxis), 0.0)
    # (b) 0 < det = 9e-8 < 1e-4: the divisor's floor engages. The field u is tiny
    # (0.02% of the range), so the smoothstep gate over (0, 1e-7) dominates the value.
    sxx = np.full((N, N), 3e-4); syy = np.full((N, N), 3e-4); sxy = np.zeros((N, N))
    sxt = np.full((N, N), -2e-4); syt = np.full((N, N), F32(-2e-4 / 3.0))
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], -1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], -1).astype(F32)
    out1, _ = stage_c(in1, in2, mask_lo=0.0, mask_hi=1e-7)
    # Cramer with the syy factor through the floor: u = 3e-4 * 2e-4 / 1e-4 = 6e-4;
    # v = 3e-4 * (2e-4/3) / 1e-4 = 2e-4 (float32, from the probe: 0.00059999997, 0.0002);
    # textbook smoothstep of the RAW det = 9e-8 against (0, 1e-7): t = 0.9, smooth 0.972.
    # The mixed value is (1-0.972)*0.5 + 0.972*0.0006 = 0.01458 (the neutral part of the
    # mix dominates: the gated field itself is only 0.0006 off neutral).
    t64 = _smoothstep64(0.0, 1e-7, 9e-8)
    expect_u = (1 - t64) * 0.5 + t64 * np.full((N, N), float(F32(0.00059999997) * F32(0.5) + F32(0.5)), dtype=np.float64)
    expect_v = (1 - t64) * 0.5 + t64 * np.full((N, N), float(F32(0.00020000002) * F32(0.5) + F32(0.5)), dtype=np.float64)
    e = np.zeros((N, N, 2)); e[..., 0] = expect_u; e[..., 1] = expect_v
    check("tiny raw det: divisor floor only, mask on raw det", _worst(out1[..., :2], e), 1e-5)
    # (c) aperture singular but with a right side that is exactly in the column space:
    # sxx=20, syy=5, sxy=10, sxt=-1.5, syt=-0.75 -> exact solution u = v = 0.075.
    sxx = np.full((N, N), 20.0); syy = np.full((N, N), 5.0); sxy = np.full((N, N), 10.0)
    sxt = np.full((N, N), -1.5); syt = np.full((N, N), -0.75)
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], -1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], -1).astype(F32)
    out1, _ = stage_c(in1, in2, mask_lo=0.0, mask_hi=0.5)   # det 0 -> exactly neutral anyway
    # smoothstep with lo == hi is degenerate (0/0): the meaningful pinned value is the
    # shipped default gate on a det-0 tensor: exactly neutral.
    out1b, _ = stage_c(in1, in2)
    neutral0 = np.zeros((N, N, 4)); neutral0[...] = (0.5, 0.5, 0.5, 1.0)
    check("singular aperture sums: out1 exactly neutral at the default gate",
          _worst(out1b, neutral0), 0.0)


def test_aperture_problem_det_is_exactly_zero():
    """Proportional gradients ((Ix,Iy) = (2,1) and (4,2)) are Cauchy-Schwarz equality:
    det = 20*5 - 10*10 = 0 exactly, and the doc says this content "makes the local 2x2
    LK solve exactly singular". out2.x must be exactly 0 and the masked field exactly
    neutral at the shipped default gate smoothstep(0, 1, 0) = 0; the axis is NOT
    degenerate here (sxx != syy, sxy != 0)."""
    sxx = np.full((N, N), 20.0); syy = np.full((N, N), 5.0)
    sxy = np.full((N, N), 10.0)
    sxt = np.full((N, N), 1.5); syt = np.full((N, N), 0.75)
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], -1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], -1).astype(F32)
    out1, out2 = stage_c(in1, in2)
    neutral = np.zeros((N, N, 4)); neutral[...] = (0.5, 0.5, 0.5, 1.0)
    check("aperture problem: out2.x exactly 0", _worst(out2[..., :1], 0.0), 0.0)
    check("aperture problem: out1 exactly neutral at the default gate", _worst(out1, neutral), 0.0)


# --- axis signal --------------------------------------------------------------------------------

def test_axis_is_the_dominant_eigenvector_doubled_angle():
    """The stored pair decodes (v - 0.5) * 2 to (cos 2t, sin 2t) of the DOMINANT
    eigenvector of [[sxx, sxy], [sxy, syy]] (larger eigh eigenvalue); an eigenvector's
    sign does not change the doubled angle. Reference: np.linalg.eigh, per pixel."""
    in1, in2, s = _generic_inputs(3)
    out1, out2 = stage_c(in1, in2)
    T = np.stack([np.stack([s["sxx"], s["sxy"]], -1), np.stack([s["sxy"], s["syy"]], -1)], -2).astype(np.float64)
    w, vv = np.linalg.eigh(T.reshape(-1, 2, 2))
    dom = vv[np.arange(w.shape[0]), :, np.argmax(w, axis=-1)]      # (N*N, 2), unit
    ang = np.arctan2(dom[:, 1], dom[:, 0]).reshape(N, N)
    dec = (out2[..., 1].astype(np.float64) - 0.5) * 2.0, (out2[..., 2].astype(np.float64) - 0.5) * 2.0
    expect = np.stack([np.cos(2 * ang), np.sin(2 * ang)], -1)
    got = np.stack(dec, -1)
    mag = np.hypot(s["sxx"].astype(np.float64) - s["syy"].astype(np.float64),
                   2 * s["sxy"].astype(np.float64))
    e = _worst(got, expect, mag > 1e-3)
    check("out2 y/z vs eigh dominant eigenvector, doubled angle", e, 1e-4)


def test_stored_pair_is_the_negated_minor_axis_pair():
    """Pinned codebox behaviour (the codebox is authoritative; the doc's wording was corrected to
    match, 2026-10-20): out2's y/z hold the doubled-angle pair of the DOMINANT gradient direction.
    The locally-ambiguous axis is the perpendicular (the minor eigenvector); doubling turns a
    90-degree rotation into 180 degrees, which NEGATES the pair, so the stored pair equals the
    negated doubled-angle pair of the minor eigenvector (np.linalg.eigh). The codebox comment
    saying the ambiguous axis stores 'the SAME pair' is wrong; Stage E adds the perpendicular
    offset itself."""
    in1, in2, s = _generic_inputs(4)
    _, out2 = stage_c(in1, in2)
    T = np.stack([np.stack([s["sxx"], s["sxy"]], -1), np.stack([s["sxy"], s["syy"]], -1)], -2).astype(np.float64)
    w, vv = np.linalg.eigh(T.reshape(-1, 2, 2))
    minor = vv[np.arange(w.shape[0]), :, np.argmin(w, axis=-1)]
    ang = np.arctan2(minor[:, 1], minor[:, 0]).reshape(N, N)
    got = np.stack([(out2[..., 1].astype(np.float64) - 0.5) * 2.0,
                    (out2[..., 2].astype(np.float64) - 0.5) * 2.0], -1)
    expect = -np.stack([np.cos(2 * ang), np.sin(2 * ang)], -1)
    mag = np.hypot(s["sxx"].astype(np.float64) - s["syy"].astype(np.float64),
                   2 * s["sxy"].astype(np.float64))
    e = _worst(got, expect, mag > 1e-3)
    check("out2 y/z equals the negated doubled-angle pair of the minor (ambiguous) axis", e, 1e-4)


# --- generic point ------------------------------------------------------------------------------

def test_generic_parameters_full_pipeline():
    """Every dial at an arbitrary non-special value (gain 0.7, mask 0.3..1.9, bypass 0),
    per-pixel varied sums whose exact LS solution is the constructed (p, q): the whole
    out1/out2 pipeline must match the float64 composition of Cramer's rule, the textbook
    smoothstep and the doc's encoding. Tolerance 1e-4, not 1e-5: the float32 Cramer
    quotient of O(1) values contributes up to a few 1e-5 before smoothstep, and the
    generic point is what special values cannot replace."""
    in1, in2, s = _generic_inputs(5)
    gain, lo, hi = 0.7, 0.3, 1.9
    out1, out2 = stage_c(in1, in2, gain=gain, mask_lo=lo, mask_hi=hi)
    det64 = s["sxx"].astype(np.float64) * s["syy"] - s["sxy"].astype(np.float64) ** 2
    t64 = _smoothstep64(lo, hi, det64)
    uv = np.stack([s["p"], s["q"]], -1)     # exact LS solution of the constructed sums
    expect1 = ((1 - t64) * 0.5 + t64 * np.clip(uv[..., 0] * gain * 0.5 + 0.5, 0, 1))
    expect1v = ((1 - t64) * 0.5 + t64 * np.clip(uv[..., 1] * gain * 0.5 + 0.5, 0, 1))
    e1 = np.zeros((N, N, 2)); e1[..., 0] = expect1; e1[..., 1] = expect1v
    check("generic dials: out1 rg vs float64 Cramer + smoothstep + encode", _worst(out1[..., :2], e1), 1e-4)
    cos2t = ((s["sxx"] - s["syy"]).astype(np.float64)
             / np.maximum(np.hypot((s["sxx"] - s["syy"]).astype(np.float64),
                                   (2 * s["sxy"]).astype(np.float64)), 1e-4))
    sin2t = ((2 * s["sxy"]).astype(np.float64)
             / np.maximum(np.hypot((s["sxx"] - s["syy"]).astype(np.float64),
                                   (2 * s["sxy"]).astype(np.float64)), 1e-4))
    e2 = np.zeros((N, N, 4))
    e2[..., 0] = det64
    e2[..., 1] = 0.5 + 0.5 * cos2t
    e2[..., 2] = 0.5 + 0.5 * sin2t
    e2[..., 3] = 1.0
    check("generic dials: out2 vs raw det + textbook double angle", _worst(out2, e2), 1e-4)
    check("alpha channels exactly 1 on both outlets",
          max(_worst(out1[..., 3:], 1.0), _worst(out2[..., 3:], 1.0)), 0.0)


# --- mutations ----------------------------------------------------------------------------------

def _err_translation(bug=None):
    a = np.full((N, N), 3.0); b = np.full((N, N), 1.0)
    c = np.full((N, N), 1.0); d = np.full((N, N), 4.0)
    p = np.full((N, N), 0.3125); q = np.full((N, N), -0.25)
    in1, in2, *_ = _sums(a, b, c, d, p, q)
    out1, out2 = stage_c(in1, in2, bug=bug)
    expect1 = np.zeros((N, N, 4)); expect1[...] = (0.65625, 0.375, 0.5, 1.0)
    return max(_worst(out1, expect1), _worst(out2[..., :1], 121.0))


def _err_gate(bug=None):
    sxx = np.full((N, N), 1.0); syy = np.full((N, N), 1.0); sxy = np.full((N, N), 2.0)
    sxt = np.full((N, N), 2e-4); syt = np.full((N, N), -1e-4)
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], -1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], -1).astype(F32)
    out1, out2 = stage_c(in1, in2, mask_lo=0.0, mask_hi=2e-5, bug=bug)
    neutral = np.zeros((N, N, 4)); neutral[...] = (0.5, 0.5, 0.5, 1.0)
    zaxis = np.zeros((N, N, 2)); zaxis[..., 0] = 0.5; zaxis[..., 1] = 1.0
    return max(_worst(out1, neutral), _worst(out2[..., :1], -3.0),
               _worst(out2[..., 1:3], zaxis))


def _err_tiny_det(bug=None):
    sxx = np.full((N, N), 3e-4); syy = np.full((N, N), 3e-4); sxy = np.zeros((N, N))
    sxt = np.full((N, N), -2e-4); syt = np.full((N, N), F32(-2e-4 / 3.0))
    in1 = np.stack([sxx, syy, sxy, np.ones_like(sxx)], -1).astype(F32)
    in2 = np.stack([sxt, syt, np.zeros_like(sxx), np.ones_like(sxx)], -1).astype(F32)
    out1, _ = stage_c(in1, in2, mask_lo=0.0, mask_hi=1e-7, bug=bug)
    t64 = _smoothstep64(0.0, 1e-7, 9e-8)
    e = np.zeros((N, N, 2))
    e[..., 0] = (1 - t64) * 0.5 + t64 * float(F32(0.00059999997) * F32(0.5) + F32(0.5))
    e[..., 1] = (1 - t64) * 0.5 + t64 * float(F32(0.00020000002) * F32(0.5) + F32(0.5))
    err = _worst(out1[..., :2], e)
    # a raw (no-floor) division here gives u = 2000, far off; and a floored-mask bug gives
    # mask 1 instead of 0.972, both caught here
    return err


def _err_axis(bug=None):
    in1, in2, s = _generic_inputs(6)
    _, out2 = stage_c(in1, in2, bug=bug)
    T = np.stack([np.stack([s["sxx"], s["sxy"]], -1), np.stack([s["sxy"], s["syy"]], -1)], -2).astype(np.float64)
    w, vv = np.linalg.eigh(T.reshape(-1, 2, 2))
    dom = vv[np.arange(w.shape[0]), :, np.argmax(w, axis=-1)]
    ang = np.arctan2(dom[:, 1], dom[:, 0]).reshape(N, N)
    got = np.stack([(out2[..., 1].astype(np.float64) - 0.5) * 2.0,
                    (out2[..., 2].astype(np.float64) - 0.5) * 2.0], -1)
    expect = np.stack([np.cos(2 * ang), np.sin(2 * ang)], -1)
    mag = np.hypot(s["sxx"].astype(np.float64) - s["syy"].astype(np.float64),
                   2 * s["sxy"].astype(np.float64))
    return _worst(got, expect, mag > 1e-3)


def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin (> 1e-3), and
    the real mirror must stay inside every tolerance it is checked against."""
    real = [_err_translation(), _err_gate(), _err_tiny_det(), _err_axis()]
    note("real mirror worst error over the shared mutation checks", max(real))
    assert max(real) < 2e-4, f"the real mirror must pass the same checks: {real}"
    bad = {"flip_u": max(_err_translation("flip_u"), _err_gate("flip_u")),
           "no_floor": max(_err_tiny_det("no_floor"), _err_gate("no_floor")),
           "floor_mask": max(_err_gate("floor_mask"), _err_tiny_det("floor_mask")),
           "axis_minor": _err_axis("axis_minor")}
    for k, v in bad.items():
        note(f"mutation '{k}' worst error", v)
        if not (np.isfinite(v) and v > 1e-3):
            raise AssertionError(f"mutation not detected: {k} (error {v})")
    print("    ok   sign flip, missing floor, floored mask and negated axis are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))