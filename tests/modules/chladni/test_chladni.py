"""
test_chladni.py -- tier-1 independent checks for the f_chladni mirror.

The module is a pure generator (no texture inlet): out1 luma nodal pattern,
out2 vecfield gradient, out3 magnitude. Reference: docs/f-reference/f_chladni.md
in the snapshot. Ground truth used here:

  - the doc's outlet table and per-mode formula
    `(env*cos(r - z_m) + reflectamt*env*cos(radius - r - z_m)) * cos(m*θ + ph0)`,
    env = sqrt(2/(π*r)), evaluated in float64 (the doc's own math, not the
    codebox's transcription);
  - textbook identities: cos A + cos B = 2 cos((A+B)/2) cos((A-B)/2);
    cos(m*(th + 2*pi/m) + ph) = cos(m*th + ph) (rotational symmetry of mode m);
    linear scaling of the totals by `amp` and of out3 by `gain`;
  - exact values the doc states as formulas with clamps: out1's
    1 - clamp(sqrt(abs(total))*linesharpness, 0, 1) and out3's
    clamp(abs(total)*gain, 0, 1), at points where the clamp is provably hit or
    provably inactive from a bound on |total| alone (|total| <= env because
    |cos| <= 1 and 0 <= reflectamt <= 1 at the tested settings);
  - the unit length of the out2 vector (a math identity: the codebox claims
    gx/gmag, gy/gmag, whose modulus is 1 whenever gmag = |grad| > 0);
  - the bypass states as the doc's outlet table states them.

Every error function treats a non-finite mirror value as a hard error.
Reference literals for the generic float64 check were computed offline with
mpmath's besseljzero (embedded below, stated in the docstring of the check).
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from chladni_mirror import F32, chladni, modal_A, modal_B  # noqa: E402

N = 16
NOTE_Z2 = F32(39.947889789900486)   # float64 note whose float32 z_pos equals Z2 exactly
PI = float(np.pi)


def _total_modulus_bound(amp, gain, reflectamt):
    # |total| <= amp * env * (1 + reflectamt) since both cos factors are <= 1 in
    # modulus; used to prove a clamp provably active or inactive.
    return amp * float(np.sqrt(2.0 / (PI * 0.001))) * (1.0 + reflectamt)


def _finite_err(measured, expect, tol_override=None):
    """Worst |measured - expect| over the compared channels; non-finite mirror
    values count as an unbounded error (a plain max would keep them silent)."""
    d = np.abs(measured.astype(np.float64) - expect)
    if not np.isfinite(measured).all():
        return np.inf
    return float(d.max())


# --- bypass, neutral and exact states ---------------------------------------------------

def test_bypass_states_are_exact():
    """Doc outlet table: bypass sends out1 black, out2 neutral (0.5, 0.5), out3 black."""
    worst = 0.0
    for kw in [dict(), dict(note=100.0, mode=1.0, view_mode=1.0, reflectamt=0.8, spread=0.9)]:
        o1, o2, o3 = chladni(N, N, bypass_gate=1.0, **kw)
        expect1 = np.zeros((N, N, 4)); expect1[..., 3] = 1.0
        expect2 = np.zeros((N, N, 4)); expect2[...] = (0.5, 0.5, 0.0, 1.0)
        expect3 = np.zeros((N, N, 4)); expect3[..., 3] = 1.0
        worst = max(worst, _finite_err(o1, expect1), _finite_err(o2, expect2), _finite_err(o3, expect3))
    check("bypass: out1/out3 exactly black, out2 exactly (0.5,0.5,0,1)", worst, 0.0)


def test_mode0_note_127_gives_zero_total():
    """In float32 note=127 maps z_pos past z7 (rounding), so no step window of
    mode A contains it and the total vanishes identically; out3 is then exactly 0."""
    o1, o2, o3 = chladni(N, N, note=127.0, mode=0.0)
    assert np.isfinite(o3).all()
    check("note 127, mode 0: out3 exactly 0 (empty window)", float(np.abs(o3[..., :3]).max()), 0.0)


def test_out3_saturates_at_the_plate_pole():
    """|total| <= amp*env*(1+refl) and env at the guard r = 0.001 is about 25.2, so
    with gain 20 out3's clamp(abs(total)*gain, 0, 1) must be exactly 1 near the
    centre, an exact value from the doc's formula plus env's divergence."""
    o1, o2, o3 = chladni(N, N, gain=20.0, reflectamt=1.0, mode=0.0)
    nx, ny, _, _ = g.grid(N, N)
    r = (np.sqrt((nx - F32(0.5)) ** 2 + (ny - F32(0.5)) ** 2) * F32(2.0)).astype(F32)
    centre = r < F32(0.2)
    assert centre.any()
    check("near-centre out3 exactly 1 (gain 20, clamp active)",
          float(np.abs(o3[centre, 0] - 1.0).max()), 0.0)


def test_out3_never_exceeds_one_and_alpha_is_opaque():
    """clamp upper bound 1 from the doc's formula; alpha 1 on all three outlets."""
    worst = 0.0
    for kw in [dict(gain=20.0, reflectamt=1.0, amp=1.0, mode=0.0),
               dict(gain=20.0, reflectamt=1.0, amp=1.0, mode=1.0, spread=0.9),
               dict(note=90.0, mode=1.0, spread=1.0, view_mode=1.0, dishradius=4.0)]:
        for o in chladni(N, N, **kw):
            worst = max(worst, float(o.max()) - 1.0)
            assert float(np.abs(o[..., 3] - 1.0).max()) == 0.0, "alpha must be 1"
    check("all three outlets at or below 1; alpha 1", max(worst, 0.0), 0.0)


# --- closed forms of the per-mode formula ------------------------------------------------

def test_radial_antinode_value_mode0():
    """Doc per-mode formula, reflect 0: f = env(rs)*cos(rs - z0); at rs = z0 + pi
    the cosine is exactly -1 so f = -sqrt(2/(pi*rs))*mask. dishradius 6.5 keeps the
    probe point mask-bounded (rs/dishradius in [0.8, 1.0) at rs = 5.546), and the
    float64 mask value is part of the expected closed form."""
    rs = 2.4048 + PI                      # the codebox's radial coordinate
    radius = 6.5
    off = rs / (2.0 * radius)             # uv offset producing that rs
    th = F32(0.7)
    u = (F32(off) * np.cos(th) + F32(0.5)).astype(F32)
    v = (F32(off) * np.sin(th) + F32(0.5)).astype(F32)
    zp = (F32(2.4048) + (F32(0.0) / F32(127.0)) * (F32(11.0864) - F32(2.4048))).astype(F32)
    got = modal_A(u, v, zp, F32(radius), F32(0.0), F32(0.0))
    t = (rs / radius - 0.8) / 0.2         # smoothstep ramp value at rs/radius
    msk = 1.0 - t * t * (3.0 - 2.0 * t)
    expect = -float(np.sqrt(2.0 / (PI * rs))) * msk
    check("mode-0 antinode rs = z0 + pi equals -sqrt(2/(pi rs)) * mask",
          abs(float(got) - expect), 1e-5)


def test_reflection_standing_wave_closed_form():
    """Identity cos A + cos B = 2 cos((A+B)/2) cos((A-B)/2) with A = r - z0,
    B = radius - r - z0: at r = radius/2 the second factor is cos(0) = 1, so the
    reflected wave at that radius equals 2*env*cos(radius/2 - z0)*cos(m*th + ph)
    in float64 — checked on the mirror's own value at that radius (mode 0, m = 0
    so the angular factor is 1 for every theta)."""
    radius = F32(1.0)
    rs = F32(0.5)         # rs = radius/2, so the identity's second factor is cos(0) = 1
    th = F32(1.1)
    u = (F32(0.25) * np.cos(th) + F32(0.5)).astype(F32)   # uv offset = rs/(2*radius) = 0.25
    v = (F32(0.25) * np.sin(th) + F32(0.5)).astype(F32)
    zp = F32(2.4048)  # note = 0 exactly (window overlap gives 2x the pure mode, included below)
    got = modal_A(u, v, zp, radius, F32(1.0), F32(0.0))
    env = float(np.sqrt(2.0 / (PI * float(rs))))
    msk = float(1.0 - _ss(0.8, 1.0, float(rs) / 1.0))
    # identity: cos(rs-z0) + cos(radius-rs-z0) = 2*cos((radius-2z0)/2)*cos(rs-radius/2);
    # at rs = radius/2 the second factor is 1, so the sum is 2*cos(radius/2 - z0).
    expect = 2.0 * env * float(np.cos(0.5 - 2.4048)) * msk
    check("reflected wave at rs = radius/2 vs the cosine-identity closed form",
          abs(float(got) - expect), 1e-5)


def _ss(e0, e1, x):
    t = np.clip((np.asarray(x, np.float64) - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def test_rotational_symmetry_of_mode2():
    """cos(2*(th + pi) + ph) = cos(2*th + ph): the mode-2 field is invariant under
    a half turn about the plate centre (math identity at fixed radius)."""
    n = F32(NOTE_Z2)
    zp = (F32(2.4048) + (n / F32(127.0)) * (F32(11.0864) - F32(2.4048))).astype(F32)
    r = np.full(9, F32(0.45), F32)
    th = np.linspace(0.2, 1.3, 9).astype(F32)
    u = (r * np.cos(th) + F32(0.5)).astype(F32)
    v = (r * np.sin(th) + F32(0.5)).astype(F32)
    u2 = (r * np.cos(th + F32(PI)) + F32(0.5)).astype(F32)
    v2 = (r * np.sin(th + F32(PI)) + F32(0.5)).astype(F32)
    a = modal_A(u, v, zp, F32(1.0), F32(0.0), F32(0.0))
    b = modal_A(u2, v2, zp, F32(1.0), F32(0.0), F32(0.0))
    check("mode-2 invariance under a half turn", float(np.abs(a - b).max()), 1e-6)


def test_window_overlap_doubles_at_an_exact_zero():
    """The mode-0 step windows overlap at an exact Bessel zero, so a z_pos exactly
    equal to z2 counts both neighbouring windows and the total is exactly twice
    the pure mode-2 term (the doc's per-mode formula evaluated in float64)."""
    r = np.full(5, F32(0.45), F32)
    th = np.linspace(0.2, 1.3, 5).astype(F32)
    u = (r * np.cos(th) + F32(0.5)).astype(F32)
    v = (r * np.sin(th) + F32(0.5)).astype(F32)
    got = modal_A(u, v, F32(5.1356), F32(1.0), F32(0.0), F32(0.0))
    ref = []
    for t, rr in zip(th, r):
        q = 2.0 * float(rr)  # the codebox's rs = dist * 2 * radius
        env = np.sqrt(2.0 / (PI * q))
        msk = _ss(0.8, 1.0, q)
        ref.append(2.0 * env * np.cos(q - 5.1356) * np.cos(2.0 * float(t)) * msk)
    check("mirror total vs 2x the doc per-mode formula at an exact zero",
          float(np.abs(got - np.asarray(ref, F32)).max()), 1e-5)


def test_modeB_gaussian_resonance_snap():
    """Mode B's weights are exp(-((zp-zm)^2)/sp2) normalized by their sum (a
    weighted average of the eight doc mode terms). Reference: the doc's
    Gaussian-resonance statement evaluated in float64 against the doc's own
    per-mode terms; at weight sum 1.000262 (computed offline in float64) the
    total sits about 2.6e-4 of the way between terms, which is what the check
    expects rather than assuming a pure single mode."""
    r = np.full(5, F32(0.45), F32)
    th = np.linspace(0.2, 1.3, 5).astype(F32)
    u = (r * np.cos(th) + F32(0.5)).astype(F32)
    v = (r * np.sin(th) + F32(0.5)).astype(F32)
    zp = F32(5.1356)
    got = modal_B(u, v, zp, F32(1.0), F32(0.0), F32(0.0), F32(0.3))
    # float64 reference: weighted average of the doc's per-mode terms with the
    # doc's Gaussian weights, all evaluated at the same rs (= 2*uv offset)
    z = [2.4048, 3.8317, 5.1356, 6.3802, 7.5883, 8.7715, 9.9361, 11.0864]
    sp2 = 0.3 ** 2 * 2.0
    weights = [np.exp(-((zp - q) ** 2) / sp2) for q in z]
    ref = []
    for t, rr in zip(th, r):
        q = 2.0 * float(rr)
        env = np.sqrt(2.0 / (PI * q))
        msk = float(_ss(0.8, 1.0, q))
        terms = [env * np.cos(q - z[m]) * np.cos(float(m) * float(t)) * msk for m in range(8)]
        ref.append(sum(w * m for w, m in zip(weights, terms)) / sum(weights))
    check("mode B vs the float64 Gaussian-weighted average of the doc mode terms",
          float(np.abs(got - np.asarray(ref, F32)).max()), 1e-5)


def test_amp_and_gain_scale_linearly():
    """The doc: amp scales the total, gain scales out3 only. Linearity of each in
    its own outlet (math identity: the formulas are exactly linear in these)."""
    n = F32(NOTE_Z2) * F32(0.5)
    kw = dict(note=39.947889789900486 * 0.5, mode=0.0, reflectamt=0.3, dishradius=1.4, ph0=0.7,
              linesharpness=0.5)
    a1, a2, a3 = chladni(24, 24, amp=0.35, gain=1.0, **kw)
    b1, b2, b3 = chladni(24, 24, amp=0.7, gain=1.0, **kw)
    c1, c2, c3 = chladni(24, 24, amp=0.35, gain=4.0, **kw)
    # out1 = 1 - clamp(sqrt|t|*L, 0, 1) with t linear in amp; where BOTH luma
    # images are strictly unclamped (0 < luma < 1), doubling amp maps the luma
    # complement 1 - out1 to exactly twice
    da = 1.0 - a1[..., :3].astype(np.float64)
    db = 1.0 - b1[..., :3].astype(np.float64)
    strict = (a1[..., :3] > 0.0) & (a1[..., :3] < 1.0) & (b1[..., :3] > 0.0) & (b1[..., :3] < 1.0)
    assert strict.sum() > 100, "not enough unclamped luma pixels for the linearity check"
    # doc's encoding 1 - clamp(sqrt|total|*L, 0, 1): |total| doubling multiplies
    # the UNCLAMPED complement 1 - out1 by exactly sqrt(2)
    e1 = float(np.abs((db - np.sqrt(2.0) * da)[strict]).max())
    e3 = float(np.abs((c3[..., :3].astype(np.float64) - 4.0 * a3[..., :3].astype(np.float64))
                      [(a3[..., :3] < 1.0) & (c3[..., :3] < 1.0)]).max())
    eg = _finite_err(c2[..., :3], a2[..., :3])
    check("doubling amp scales the unclamped luma complement 1 - out1 by sqrt(2)", e1, 1e-5)
    check("out3 linear in gain on the unclamped band (out3 = |total|*gain pre-clamp)", e3, 1e-5)
    check("out2 unaffected by gain (gain scales out3 only)", eg, 0.0)


def _grid64(n):
    nx, ny, _, _ = g.grid(n, n)
    return nx.astype(np.float64), ny.astype(np.float64)


def _grad64(x, y, note=100.0, reflectamt=0.7, ph0=0.9, radius=1.0, mode=0):
    """Float64 central difference (eps 0.004 in uv) of the doc's per-mode total
    (mode A, the window blend at z_pos), used as an independent reference
    direction for out2. The blend weights come from the doc's mode-0 statement."""
    zp = 2.4048 + (note / 127.0) * (11.0864 - 2.4048)
    z = [2.4048, 3.8317, 5.1356, 6.3802, 7.5883, 8.7715, 9.9361, 11.0864]
    lo = max(i for i, q in enumerate(z) if q <= zp)
    hi = min(lo + 1, 7)
    t = (zp - z[lo]) / (z[hi] - z[lo])

    def f(u, v):
        du = u - 0.5
        dv = v - 0.5
        rs = np.maximum(np.sqrt(du * du + dv * dv) * 2.0 * radius, 0.001)
        thm = np.arctan2(dv, du)
        ev = np.sqrt(2.0 / (PI * rs))
        msk = 1.0 - _ss(0.8, 1.0, rs / radius)

        def term(m):
            return (ev * np.cos(rs - z[m]) + reflectamt * ev * np.cos(radius - rs - z[m])) \
                * np.cos(m * thm + ph0) * msk
        return (1 - t) * term(lo) + t * term(hi)

    eps = 0.004
    gx = (f(x + eps, y) - f(x - eps, y)) / (2 * eps)
    gy = (f(x, y + eps) - f(x, y - eps)) / (2 * eps)
    return gx, gy


def test_out2_unit_length_and_encoding():
    """gx/gmag and gy/gmag (gmag = max(|grad|, 1e-4)) have modulus 1 whenever the
    gradient magnitude exceeds the floor, so the encoded R,G sit exactly on the
    circle of radius 0.5 about (0.5, 0.5) away from the floor; B = 0, A = 1."""
    o1, o2, o3 = chladni(32, 32, note=100.0, reflectamt=0.7, ph0=0.9, mode=0.0, dishradius=1.2)
    enc = o2[..., :2].astype(np.float64)
    rad = np.hypot(enc[..., 0] - 0.5, enc[..., 1] - 0.5)
    assert np.isfinite(rad).all()
    # where the raw gradient magnitude is below the 1e-4 floor the vector is NOT
    # unit length (gmag floors it and the raw vector keeps its true length); the
    # unit-length claim covers the rest. The masked-out pixels are counted, not hidden.
    x, y = _grid64(32)
    grad = _grad64(x, y, note=100.0, reflectamt=0.7, ph0=0.9, radius=1.0)
    above = np.hypot(grad[0], grad[1]) > 1e-4
    # pixels with an exactly zero gradient encode (0.5, 0.5) exactly (radius 0),
    # which the unit-length claim does not cover; they are counted, not hidden.
    zero_grad = rad < 1e-12
    note("pixels above the gradient floor", int(above.sum()))
    note("pixels with an exactly zero encoded vector", int(zero_grad.sum()))
    assert (above & ~zero_grad).sum() > 200, "not enough unit-length pixels for the check"
    check("out2 vector unit length away from the floor (encoded radius 0.5 from centre)",
          float(np.abs(rad[above & ~zero_grad] - 0.5).max()), 1e-6)
    check("out2 B channel exactly 0 and alpha exactly 1",
          max(float(np.abs(o2[..., 2]).max()), float(np.abs(o2[..., 3] - 1.0).max())), 0.0)


def test_out2_matches_the_gradient_of_the_total():
    """out2 is the doc's central-difference gradient of the total with eps = 0.004
    in uv. Comparing its encoded direction against the float64 direction of the
    difference quotient of the doc's own per-mode formula at the same points
    exercises the encoding (0.5 +- 0.5) against an independent reference, not a
    retype of the mirror's internal expressions."""
    n = 32
    o1, o2, o3 = chladni(n, n, note=100.0, reflectamt=0.7, ph0=0.9,
                         dishradius=1.2, mode=0.0, view_mode=0.0)
    nx, ny, _, _ = g.grid(n, n)
    x = nx.astype(np.float64)
    y = ny.astype(np.float64)
    gx, gy = _grad64(x, y, note=100.0, reflectamt=0.7, ph0=0.9, radius=1.2)
    gm = np.hypot(gx, gy)
    use = gm > 1e-3  # away from the gmag floor and from the mask edge
    assert use.sum() > n * n // 4, "not enough usable pixels for the direction check"
    mx = np.clip(o2[..., 0].astype(np.float64) * 2.0 - 1.0, -1, 1)
    my = np.clip(o2[..., 1].astype(np.float64) * 2.0 - 1.0, -1, 1)
    dot = np.clip(mx * (gx / gm) + my * (gy / gm), -1, 1)
    ang = np.arccos(dot)
    worst = float(ang[use].max())
    note("worst angular difference of out2 direction vs float64 doc gradient (rad)", worst)
    check("out2 direction vs float64 doc gradient", worst, 5e-3)


def test_generic_all_parameters_doc_formula():
    """A generic point (note 60, reflect 0.25, dishradius 1.3, ph0 0.7, mode 0,
    view 0.2, linesharp 7): the mirror's out3/(amp*gain) equals the float64 value
    of the DOC's per-mode formula blend (the doc's mode-0 statement: two adjacent
    modes blended linearly in the Bessel-zero span). Bessel zeros were computed
    offline with mpmath's besseljzero and rounded to the codebox's printed
    constants; the blend weights come from the doc's own note-mapping statement.
    This guards terms that vanish at the special points."""
    kw = dict(note=60.0, amp=0.75, dishradius=1.3, reflectamt=0.25,
              mode=0.0, view_mode=0.2, gain=1.0, ph0=0.7)
    o1, o2, o3 = chladni(24, 24, **kw)
    got = o3[..., 0].astype(np.float64)                   # out3 already includes amp * gain
    nx, ny, _, _ = g.grid(24, 24)
    x = nx.astype(np.float64)
    y = ny.astype(np.float64)
    zp = 2.4048 + (60.0 / 127.0) * (11.0864 - 2.4048)
    z = [2.4048, 3.8317, 5.1356, 6.3802, 7.5883, 8.7715, 9.9361, 11.0864]
    lo = max(i for i, q in enumerate(z) if q <= zp)
    hi = min(lo + 1, 7)
    t = (zp - z[lo]) / (z[hi] - z[lo])
    # the codebox blends view_mode toward strip coordinates: mirror it in float64
    vm = 0.2
    dx = x - 0.5
    dy = y - 0.5
    rs_c = np.maximum(np.sqrt(dx * dx + dy * dy) * 2.0 * 1.3, 0.001)
    rmix = (1 - vm) * rs_c + vm * (y * 1.3)
    thmix = (1 - vm) * np.arctan2(dy, dx) + vm * (x * 2 * PI - PI)
    rs = np.maximum(rmix, 0.001)
    env = np.sqrt(2.0 / (PI * rs))
    msk = 1.0 - _ss(0.8, 1.0, rs / 1.3)
    refl = 0.25

    def term(m):
        # helper coordinates (circles recomputed from uv): the doc formula per mode
        return (env * np.cos(rs - z[m]) + refl * env * np.cos(1.3 - rs - z[m])) \
            * np.cos(m * thmix + 0.7) * msk

    # mode 0's total uses the helper at (x, y) with pure circular coordinates
    rsA = np.maximum(np.sqrt(dx * dx + dy * dy) * 2.0 * 1.3, 0.001)
    evA = np.sqrt(2.0 / (PI * rsA))
    mskA = 1.0 - _ss(0.8, 1.0, rsA / 1.3)
    thA = np.arctan2(dy, dx)

    def termA(m):
        return (evA * np.cos(rsA - z[m]) + refl * evA * np.cos(1.3 - rsA - z[m])) \
            * np.cos(m * thA + 0.7) * mskA

    total_ref = (1 - t) * termA(lo) + t * termA(hi)
    # out3 = clamp(|total| * amp * gain, 0, 1); the same closed form on the
    # reference reproduces both the clamp-free band and the saturation band.
    expected = np.clip(np.abs(total_ref) * 0.75 * 1.0, 0.0, 1.0)
    use = mskA > 0.0
    err = float(np.abs((got - expected)[use]).max())
    check("generic parameters vs float64 doc per-mode blend, clamped", err, 1e-5)


# --- mutations ---------------------------------------------------------------------------

BUGS = ["drop_reflect", "sign_flip_phase", "swap_rg_vecfield", "note_span_128",
        "no_vecfield_normalize"]
BUG_LABELS = ["symmetry", "generic", "vecfield", "note127", "reflection"]


def _err_symmetry(bug=None):
    r = np.full(5, F32(0.45), F32)
    th = np.linspace(0.2, 1.3, 5).astype(F32)
    u = (r * np.cos(th) + F32(0.5)).astype(F32)
    v = (r * np.sin(th) + F32(0.5)).astype(F32)
    u2 = (r * np.cos(th + F32(PI)) + F32(0.5)).astype(F32)
    v2 = (r * np.sin(th + F32(PI)) + F32(0.5)).astype(F32)
    a = modal_A(u, v, F32(5.1356), F32(1.0), F32(0.0), F32(0.0), bug=bug)
    b = modal_A(u2, v2, F32(5.1356), F32(1.0), F32(0.0), F32(0.0), bug=bug)
    e = a - b
    if not np.isfinite(e).all():
        return np.inf
    return float(np.abs(e).max())


def _err_window_double(bug=None):
    """Same closed-form pair the passing test uses: the pure mode-2 terms."""
    r = np.full(5, F32(0.45), F32)
    th = np.linspace(0.2, 1.3, 5).astype(F32)
    u = (r * np.cos(th) + F32(0.5)).astype(F32)
    v = (r * np.sin(th) + F32(0.5)).astype(F32)
    got = modal_A(u, v, F32(5.1356), F32(1.0), F32(0.0), F32(0.0), bug=bug)
    if not np.isfinite(got).all():
        return np.inf
    ref = []
    for t, rr in zip(th, r):
        q = 2.0 * float(rr)
        env = np.sqrt(2.0 / (PI * q))
        ref.append(2.0 * env * np.cos(q - 5.1356) * np.cos(2.0 * float(t)) * _ss(0.8, 1.0, q))
    return float(np.abs(got - np.asarray(ref, F32)).max())


def _err_note_zero(bug=None):
    """Run the whole chladni at the note whose float32 z_pos is exactly the zero
    Z2 under the /127 mapping, and compare out3 against the float64 doc formula:
    the 2x window overlap at the exact zero under /127, the ordinary blend under
    the /128 mutant's shifted z_pos. The note mapping lives in chladni, so the
    helper goes through chladni and reproduces the mapping in float64."""
    note_v = 39.947889789900486
    kw = dict(note=note_v, amp=1.0, dishradius=1.0, reflectamt=0.0,
              mode=0.0, view_mode=0.0, gain=1.0, ph0=0.0, linesharpness=10.0)
    o3 = chladni(24, 24, bug=bug, **kw)[2]
    if not np.isfinite(o3).all():
        return np.inf
    got = o3[..., 0].astype(np.float64)
    x, y = _grid64(24)
    z = [2.4048, 3.8317, 5.1356, 6.3802, 7.5883, 8.7715, 9.9361, 11.0864]
    zp = 2.4048 + (note_v / 127.0) * (11.0864 - 2.4048)
    # the reference ALWAYS uses the doc's /127 mapping; the mutant's z_pos is
    # compared against that fixed truth
    dx = x - 0.5
    dy = y - 0.5
    rsA = np.maximum(np.sqrt(dx * dx + dy * dy) * 2.0 * 1.0, 0.001)
    evA = np.sqrt(2.0 / (PI * rsA))
    mskA = 1.0 - _ss(0.8, 1.0, rsA / 1.0)
    thA = np.arctan2(dy, dx)
    lo = max(i for i, q in enumerate(z) if q <= zp)
    hi = min(lo + 1, 7)
    t_ = (zp - z[lo]) / (z[hi] - z[lo])
    ref = (1 - t_) * evA * np.cos(rsA - z[lo]) * np.cos(lo * thA) * mskA \
        + t_ * evA * np.cos(rsA - z[hi]) * np.cos(hi * thA) * mskA
    # at the exact zero both windows pick the same term, so the float64 blend
    # weights already give the doubled value (t_ = 0 contributes the z2 term via lo,
    # and the overlapping next window contributes it again through the mirror;
    # in float64 the blend is the straight average of the two window terms, which
    # at t_ = 0 equals the z2 term only)
    if abs(zp - 5.1356) < 1e-9 and lo == 2:
        ref = ref + evA * np.cos(rsA - z[2]) * np.cos(2 * thA) * mskA   # second window also selects z2
    expected = np.clip(np.abs(ref) * 1.0, 0.0, 1.0)
    use = mskA > 0.0
    e = np.abs((got - expected)[use])
    return float(e.max()) if np.isfinite(e).all() else np.inf


def test_note_mapping_zero_closed_form():
    """The doc maps note 0-127 linearly across the Bessel zero span: the note whose
    float32 z_pos equals Z2 evaluates mode 0 at an exact zero (the 2x window overlap
    value) — checked against the doc per-mode formula in float64 both at the zero
    and at the /128 mutant's shifted z_pos."""
    check("note -> z_pos mapping at an exact Bessel zero (doc linear span)",
          _err_note_zero(), 1e-5)


def _err_reflection(bug=None):
    radius = F32(1.0)
    r = F32(0.5)
    th = F32(1.1)
    u = ((r / (F32(2.0) * radius)) * np.cos(th) + F32(0.5)).astype(F32)
    v = ((r / (F32(2.0) * radius)) * np.sin(th) + F32(0.5)).astype(F32)
    got = modal_A(u, v, F32(2.4048), radius, F32(1.0), F32(0.0), bug=bug)
    if not np.isfinite(got).all():
        return np.inf
    env = float(np.sqrt(2.0 / (PI * float(r))))
    expect = 2.0 * env * float(np.cos(0.5 - 2.4048))
    return abs(float(got) - expect)


def _err_vecfield(bug=None):
    n = 24
    o1, o2, o3 = chladni(n, n, note=100.0, reflectamt=0.7, ph0=0.9, mode=0.0, bug=bug)
    if not np.isfinite(o2).all():
        return np.inf
    rad = np.hypot(o2[..., 0].astype(np.float64) - 0.5, o2[..., 1].astype(np.float64) - 0.5)
    # exclude exactly zero gradients (encode (0.5,0.5)) and the gmag floor region
    x, y = _grid64(o2.shape[0])
    gx, gy = _grad64(x, y, note=100.0, reflectamt=0.7, ph0=0.9, radius=1.0)
    ok = (np.hypot(gx, gy) > 1e-4) & (np.abs(rad) > 1e-12)
    e = np.abs(rad[ok] - 0.5)
    return float(e.max()) if ok.any() else np.inf


def _err_generic_pt(bug=None):
    kw = dict(note=60.0, amp=0.75, dishradius=1.3, reflectamt=0.25,
              mode=0.0, view_mode=0.2, gain=1.0, ph0=0.7)
    o1, o2, o3 = chladni(24, 24, bug=bug, **kw)
    if not np.isfinite(o3).all():
        return np.inf
    got = o3[..., 0].astype(np.float64)
    nx, ny, _, _ = g.grid(24, 24)
    x = nx.astype(np.float64)
    y = ny.astype(np.float64)
    zp = 2.4048 + (60.0 / 127.0) * (11.0864 - 2.4048)
    z = [2.4048, 3.8317, 5.1356, 6.3802, 7.5883, 8.7715, 9.9361, 11.0864]
    lo = max(i for i, q in enumerate(z) if q <= zp)
    hi = min(lo + 1, 7)
    t = (zp - z[lo]) / (z[hi] - z[lo])
    vm = 0.2
    dx = x - 0.5
    dy = y - 0.5
    rsA = np.maximum(np.sqrt(dx * dx + dy * dy) * 2.0 * 1.3, 0.001)
    evA = np.sqrt(2.0 / (PI * rsA))
    mskA = 1.0 - _ss(0.8, 1.0, rsA / 1.3)
    thA = np.arctan2(dy, dx)
    if bug == "note_span_128":
        zp = 2.4048 + (60.0 / 128.0) * (11.0864 - 2.4048)
        lo = max(i for i, q in enumerate(z) if q <= zp)
        hi = min(lo + 1, 7)
        t = (zp - z[lo]) / (z[hi] - z[lo])
    refl = 0.25

    def termA(m):
        return (evA * np.cos(rsA - z[m]) + refl * evA * np.cos(1.3 - rsA - z[m])) \
            * np.cos(m * thA + 0.7) * mskA

    total_ref = (1 - t) * termA(lo) + t * termA(hi)
    expected = np.clip(np.abs(total_ref) * 0.75 * 1.0, 0.0, 1.0)
    use = mskA > 0.0
    e = np.abs((got - expected)[use])
    return float(e.max()) if np.isfinite(e).all() else np.inf


def _ref_modeB_total64(x, y, vm, spread=0.3, note=60.0, refl=0.4, R=1.25,
                       ph=0.45, amp=1.0):
    """Float64 doc reference for the mode-B (Gaussian resonance) total at arbitrary
    uv: Gaussian weights exp(-((zp-zm)^2)/(spread^2*2)) over the eight doc per-mode
    terms, normalized by their sum, with the view-blended coordinates. Zeros are the
    textbook ones (computed offline with mpmath's besseljzero, printed in the doc)."""
    z = [2.4048, 3.8317, 5.1356, 6.3802, 7.5883, 8.7715, 9.9361, 11.0864]
    zp = 2.4048 + (note / 127.0) * (11.0864 - 2.4048)
    dx = x - 0.5
    dy = y - 0.5
    rs_c = np.maximum(np.sqrt(dx * dx + dy * dy) * 2.0 * R, 0.001)
    th_c = np.arctan2(dy, dx)
    rs_s = np.maximum(y * R, 0.001)
    th_s = x * 2 * PI - PI
    rs = np.maximum((1 - vm) * rs_c + vm * rs_s, 0.001)
    th = (1 - vm) * th_c + vm * th_s
    ev = np.sqrt(2.0 / (PI * rs))
    mask = 1.0 - _ss(0.8, 1.0, rs / R)
    sp2 = spread ** 2 * 2
    w = [np.exp(-((zp - z[m]) ** 2) / sp2) for m in range(8)]
    ws = sum(w)
    terms = [(ev * np.cos(rs - z[m]) + refl * ev * np.cos(R - rs - z[m]))
             * np.cos(m * th + ph) * mask for m in range(8)]
    return amp * sum(wi * ti for wi, ti in zip(w, terms)) / ws, mask


def _err_mode1(bug=None):
    """Module total at mode 1 (both views; two spreads) vs the float64 doc mode-B
    reference after the doc's own out3 clamp. spread 1.0 at an off-zero note makes
    several Gaussian weights comparable, so a wrong normalization or a wrong sign
    in the weighted sum is visible, not washed out by one dominant weight."""
    worst = 0.0
    for vm in (0.0, 1.0):
        for spread, note in ((0.3, 60.0), (1.0, 70.0)):
            o1, o2, o3 = chladni(24, 24, view_mode=vm, mode=1.0, bug=bug, note=note,
                                 amp=1.0, dishradius=1.25, reflectamt=0.4, ph0=0.45,
                                 spread=spread, gain=1.0)
            if not np.isfinite(o3).all():
                return np.inf
            got = o3[..., 0].astype(np.float64)
            x, y = _grid64(24)
            ref, mask = _ref_modeB_total64(x, y, vm, spread=spread, note=note)
            if bug == "note_span_128":
                ref, mask = _ref_modeB_total64(x, y, vm, spread=spread,
                                               note=note * 127.0 / 128.0)
            expected = np.clip(np.abs(ref), 0.0, 1.0)
            use = mask > 0.0
            e = np.abs((got - expected)[use])
            if not np.isfinite(e).all():
                return np.inf
            worst = max(worst, float(e.max()))
    return worst


def test_mode1_total_closed_form_both_views():
    """Mode 1's total vs the float64 doc mode-B reference in both view modes; the
    strip view changes the inline coordinates (r = y*R, th = x*2pi - pi), which the
    reference reproduces, so this also pins that the strip mapping is used there."""
    check("mode 1 total vs float64 doc mode-B reference (both views)", _err_mode1(), 2e-5)


def test_mode1_total_changes_with_view_mode():
    """The inline mode-B total reads the view-blended coordinates, so switching
    view_mode 0 -> 1 changes out3 (identity: the reference formulas above differ
    wherever the two coordinate systems disagree and the weight is not zero)."""
    kw = dict(note=60.0, amp=1.0, dishradius=1.25, reflectamt=0.4, ph0=0.45,
              spread=0.3, gain=1.0, linesharpness=10.0)
    a = chladni(24, 24, view_mode=0.0, mode=1.0, **kw)[2][..., 0]
    b = chladni(24, 24, view_mode=1.0, mode=1.0, **kw)[2][..., 0]
    d = np.abs(b.astype(np.float64) - a.astype(np.float64))
    # harness.check asserts value <= tol, so the claim is stated as a shortfall:
    # 1 - (worst difference) is 0 exactly when the views disagree somewhere
    check("out3 differs between circular and strip views at mode 1",
          1.0 - float(d.max()), 0.0)


def test_luma_encoding_closed_form():
    """out1 = 1 - clamp(sqrt(|total|) * linesharpness, 0, 1) with total the float64
    doc reference at a loud, generic setting: the doc's own encoding formula,
    including the exact saturation at large |total|."""
    kw = dict(note=110.0, amp=1.0, dishradius=1.0, reflectamt=0.5, mode=0.0,
              view_mode=0.0, linesharpness=4.0, ph0=0.3)
    o1, o2, o3 = chladni(24, 24, gain=1.0, **kw)
    got = o1[..., 0].astype(np.float64)
    x, y = _grid64(24)
    ref, mask = _ref_total64_A(x, y, note=110.0, refl=0.5, R=1.0, ph=0.3)
    expected = 1.0 - np.clip(np.sqrt(np.abs(ref)) * 4.0, 0.0, 1.0)
    use = mask > 0.0
    err = float(np.abs((got - expected)[use]).max())
    check("out1 vs 1 - clamp(sqrt(|total|)*linesharpness) on the float64 reference",
          err, 1e-5)


def _ref_total64_A(x, y, note=110.0, refl=0.5, R=1.0, ph=0.3):
    """Float64 doc reference for the mode-0 window blend total (same construction
    as _grad64's f, evaluated for the value rather than the gradient)."""
    z = [2.4048, 3.8317, 5.1356, 6.3802, 7.5883, 8.7715, 9.9361, 11.0864]
    zp = 2.4048 + (note / 127.0) * (11.0864 - 2.4048)
    dx = x - 0.5
    dy = y - 0.5
    rs = np.maximum(np.sqrt(dx * dx + dy * dy) * 2.0 * R, 0.001)
    th = np.arctan2(dy, dx)
    ev = np.sqrt(2.0 / (PI * rs))
    mask = 1.0 - _ss(0.8, 1.0, rs / R)
    lo = max(i for i, q in enumerate(z) if q <= zp)
    hi = min(lo + 1, 7)
    t = (zp - z[lo]) / (z[hi] - z[lo])

    def term(m):
        return (ev * np.cos(rs - z[m]) + refl * ev * np.cos(R - rs - z[m]))
    # at zp == z2 exactly the two windows double the z2 term; handled by noting the
    # blend weights: (1-t)*term(lo) + t*term(hi) already equals the z2 term at t=0,
    # and the overlapping window adds the same term again
    val = (1 - t) * term(lo) * np.cos(lo * th + ph) * mask \
        + t * term(hi) * np.cos(hi * th + ph) * mask
    if abs(zp - z[lo]) < 1e-9 and lo > 0:
        val = val + term(lo) * np.cos(lo * th + ph) * mask
    return val, mask


def _err_mode1_vecfield(bug=None):
    """out2's direction at mode 1 vs the float64 central difference of the doc
    mode-B reference; also guards the modal_B helper path (the gradient is built
    from the helpers), with the sum-floor and eps guards mirrored from the doc."""
    worst = 0.0
    # two settings: note 60/spread 0.3 (typical) and note 10.76/spread 0.3, where
    # the eight Gaussian weights nearly cancel in an alternating sum, so a wrong
    # window-sum sign flips the helper's gradient direction, which out2 shows
    for note_v in (60.0, 10.76271186440678):
        n = 24
        o1, o2, o3 = chladni(n, n, note=note_v, amp=1.0, dishradius=1.25, reflectamt=0.4,
                             ph0=0.45, spread=0.3, mode=1.0, gain=1.0, linesharpness=10.0,
                             view_mode=0.0, bug=bug)
        if not np.isfinite(o2).all():
            return np.inf
        x, y = _grid64(n)

        def f(u, v):
            return _ref_modeB_total64(u, v, 0.0, note=note_v)[0]

        eps = 0.004
        gx = (f(x + eps, y) - f(x - eps, y)) / (2 * eps)
        gy = (f(x, y + eps) - f(x, y - eps)) / (2 * eps)
        gm = np.hypot(gx, gy)
        rsA = np.maximum(np.hypot(x - 0.5, y - 0.5) * 2 * 1.25, 0.001)
        use = (gm > 1e-3) & (rsA < 0.95)
        mx = np.clip(o2[..., 0].astype(np.float64) * 2 - 1, -1, 1)
        my = np.clip(o2[..., 1].astype(np.float64) * 2 - 1, -1, 1)
        with np.errstate(invalid="ignore", divide="ignore"):
            dot = np.clip(mx * (gx / gm) + my * (gy / gm), -1, 1)
        ang = np.arccos(dot)
        if not np.isfinite(ang[use]).all():
            return np.inf
        worst = max(worst, float(ang[use].max()))
    return worst


def test_mode1_vecfield_direction():
    """out2's direction at mode 1 vs the float64 doc mode-B gradient direction;
    exercises the modal_B helpers (weights sum, per-mode angles, the eps grid)
    that the mode-0 checks never touch, at a typical note and at a note where the
    eight Gaussian weights nearly cancel in an alternating sum."""
    check("mode 1 out2 direction vs float64 doc mode-B gradient", _err_mode1_vecfield(), 5e-3)


def test_mutations_are_caught():
    """Every declared bug must fail at least one independent check by a clear
    margin, and the real mirror must pass the same error functions."""
    real = max(_err_symmetry(), _err_window_double(), _err_reflection(),
               _err_vecfield(), _err_generic_pt(), _err_note_zero(), _err_mode1(),
               _err_mode1_vecfield())
    note("real mirror worst error over all closure helpers", real)
    # the directional reference checks sit at about 5e-4 (float32 central
    # difference vs float64 exact), so the real-mirror bar is 1e-3 rather than 1e-5
    assert real < 1e-3, f"the real mirror must pass the same checks: {real}"
    for bug in BUGS:
        e = max(_err_symmetry(bug), _err_window_double(bug), _err_reflection(bug),
                _err_vecfield(bug), _err_generic_pt(bug), _err_note_zero(bug),
                _err_mode1(bug), _err_mode1_vecfield(bug))
        note(f"mutation '{bug}' worst error", e)
        if not e > 1e-3:
            raise AssertionError(f"mutation not detected: {bug} (error {e:.3e})")
    print("    ok   dropped reflection, flipped phase sign, swapped vecfield channels, "
          "a 128-note span and an unnormalized vecfield are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))