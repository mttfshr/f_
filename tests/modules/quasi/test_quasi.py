"""
test_quasi.py -- tier-1 independent checks for the f_quasi mirror (T001).

Ground truth is the spec's settled model (.specify/stable/f_quasi/spec.md) evaluated by a plain
scalar float64 loop written here with `math` (no NumPy, no shared code with the mirror), plus
closed forms:
  - the potential is a normalised sum of cosines, so |P| <= 1;
  - the octave set shifts by one when zoom advances by one (w_i(z+1) = w_{i+1}(z));
  - the analytic gradient equals a central finite difference of P (float64);
  - the bounded vecfield has |v| <= 1, and with a single octave carrying all the weight
    v = grad P / (2 pi B s) exactly;
  - rotating the orientation set by `angle` equals rotating the point by -angle;
  - the zoom-wrap residual follows the spec's weights (exp(-32) leaving, exp(-18) entering
    at envelope 0.5);
  - the banded look is |frac(s)*2 - 1|^1.1 with s = (P/2 + 1) * bands.
Mutations in quasi_mirror.BUGS must each fail at least one check by a clear margin.
"""
import math
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
import quasi_mirror as q  # noqa: E402

DEF = dict(zoom=0.3, drift=0.17, density=4.0, envelope=0.5, angle=0.0)
RNG = np.random.default_rng(7)
XS = RNG.uniform(-0.9, 0.9, 60)
YS = RNG.uniform(-0.5, 0.5, 60)


def ref_point(x, y, zoom=0.3, drift=0.0, density=4.0, envelope=0.5, angle=0.0,
              mu=3.0, wrap=True):
    """Independent scalar float64 evaluation of the spec: (P, gx, gy, vx, vy)."""
    if wrap:
        zoom -= math.floor(zoom)
    betas = [math.exp(math.pi * k) % 1.0 for k in range(5)]
    tpb = 2.0 * math.pi * density
    P = gx = gy = vx = vy = wsum = wssum = 0.0
    for i in range(7):
        e = zoom + i
        w = math.exp(-0.5 * ((e - mu) / envelope) ** 2)
        s = 2.0 ** e
        wsum += w
        wssum += w * s
        for k in range(5):
            phi = k * math.pi / 5 + angle
            psi = (betas[k] * s + 2.0 * math.pi * (drift - math.floor(drift))
                   + (math.cos(phi) * x + math.sin(phi) * y) * tpb * s)
            c, sn = math.cos(psi), math.sin(psi)
            P += w * c
            gx -= w * sn * math.cos(phi) * tpb * s
            gy -= w * sn * math.sin(phi) * tpb * s
            vx -= w * s * sn * math.cos(phi)
            vy -= w * s * sn * math.sin(phi)
    return P / (5 * wsum), gx / (5 * wsum), gy / (5 * wsum), vx / (5 * wssum), vy / (5 * wssum)


def ref_arrays(xs, ys, **kw):
    return np.array([ref_point(float(a), float(b), **kw) for a, b in zip(xs, ys)]).T


def _worst(a, b):
    a = np.asarray(a, np.float64)
    if not np.isfinite(a).all():
        return np.inf
    return float(np.abs(a - b).max())


# --- error functions shared by the real checks and the mutation test -----------------------

def _errs(bug=None):
    """Worst error per quantity against the independent reference (mirror in float32)."""
    ref = ref_arrays(XS, YS, **{k: v for k, v in DEF.items()})
    f = q.field(XS, YS, dtype=np.float32, bug=bug, **DEF)
    gscale = float(np.abs(ref[1:3]).max())
    out = {
        "P": _worst(f["P"], ref[0]),
        "grad": max(_worst(f["gx"], ref[1]), _worst(f["gy"], ref[2])) / gscale,
        "vec": max(_worst(f["vx"], ref[3]), _worst(f["vy"], ref[4])),
    }
    # aspect convention: the render must sample the reference at x = (nx-.5)*aspect, y = ny-.5
    h, w = 24, 48
    nx, ny, _, _ = g.grid(h, w)
    xr = ((nx.astype(np.float64) - 0.5) * (w / h)).ravel()
    yr = (ny.astype(np.float64) - 0.5).ravel()
    rr = ref_arrays(xr, yr, **DEF)
    _, _, scal = q.render(h, w, bug=bug, **DEF)
    out["render"] = _worst(scal[..., 0].ravel(), rr[0] * 0.5 + 0.5)
    return out


# --- potential -----------------------------------------------------------------------------

def test_float64_mirror_equals_independent_scalar_reference():
    ref = ref_arrays(XS, YS, **DEF)
    f = q.field(XS, YS, dtype=np.float64, **DEF)
    for name, i in (("P", 0), ("gx", 1), ("gy", 2), ("vx", 3), ("vy", 4)):
        check(f"float64 mirror {name} vs scalar reference", _worst(f[name], ref[i]) / max(1.0, float(np.abs(ref[i]).max())), 1e-12)


def test_float32_mirror_within_tier1_tolerance():
    e = _errs()
    check("float32 P vs float64 reference (NF-002 tolerance 1e-3)", e["P"], 1e-3)
    check("float32 gradient, relative to its peak", e["grad"], 2e-3)
    check("float32 vecfield numerator", e["vec"], 1e-3)
    check("render scalar outlet vs reference at texel centres", e["render"], 1e-3)


def test_potential_is_bounded():
    worst = 0.0
    rng = np.random.default_rng(3)
    for _ in range(40):
        kw = dict(zoom=rng.uniform(-2, 3), drift=rng.uniform(-2, 2), density=rng.uniform(1, 12),
                  envelope=rng.uniform(0.25, 1.5), angle=rng.uniform(0, np.pi))
        f = q.field(rng.uniform(-1, 1, 400), rng.uniform(-.5, .5, 400), dtype=np.float32, **kw)
        worst = max(worst, float(np.abs(f["P"]).max()) - 1.0)
    check("max |P| - 1 over a parameter sweep (<= float32 slack)", max(worst, 0.0), 1e-6)


def test_octave_set_shifts_by_one_when_zoom_advances():
    _, w0, s0 = q.octave_terms(0.37, 0.5, np.float64, wrap=False)
    _, w1, s1 = q.octave_terms(1.37, 0.5, np.float64, wrap=False)
    check("w_i(z+1) == w_{i+1}(z), i = 0..5", np.abs(w1[:6] - w0[1:]).max(), 1e-12)
    check("s_i(z+1) == s_{i+1}(z) (relative)", np.abs(s1[:6] / s0[1:] - 1).max(), 1e-12)


def test_wrap_residual_matches_spec_weights():
    """At envelope 0.5 the leaving octave (scale 128) has weight exp(-32) and the entering one
    (scale 1) exp(-18); the unwrapped zoom = 1 pattern equals zoom = 0 up to those."""
    _, w_end, _ = q.octave_terms(1.0, 0.5, np.float64, wrap=False)
    _, w_start, _ = q.octave_terms(0.0, 0.5, np.float64, wrap=False)
    check("weight of the leaving octave vs exp(-32), relative", abs(w_end[6] / math.exp(-32) - 1), 1e-9)
    check("weight of the entering octave vs exp(-18), relative", abs(w_start[0] / math.exp(-18) - 1), 1e-9)
    res = {}
    for sig in (0.5, 1.0):
        a = q.field(XS, YS, dtype=np.float64, zoom=1.0, envelope=sig, wrap_zoom=False, drift=0.0)["P"]
        b = q.field(XS, YS, dtype=np.float64, zoom=0.0, envelope=sig, wrap_zoom=False, drift=0.0)["P"]
        res[sig] = float(np.abs(a - b).max())
        note(f"wrap residual max|dP| at envelope {sig}", f"{res[sig]:.3e}")
    check("wrap residual at envelope 0.5 (spec: about 1e-8)", res[0.5], 1e-6)
    assert res[1.0] > 1e-3, f"at envelope 1.0 the residual should be visible, got {res[1.0]:.2e}"
    # and the wrapped parameter really is the same frame at zoom 1 and 0
    a = q.field(XS, YS, dtype=np.float64, zoom=1.0, **{k: v for k, v in DEF.items() if k != "zoom"})["P"]
    b = q.field(XS, YS, dtype=np.float64, zoom=0.0, **{k: v for k, v in DEF.items() if k != "zoom"})["P"]
    check("zoom 1 wraps to zoom 0 exactly", np.abs(a - b).max(), 0.0)


def test_drift_is_a_wrapped_phase_in_turns():
    """T002: the offset is one phase 2 pi frac(drift) shared by every octave (2026-10-30; was scaled by 2^i), so one
    whole turn of drift is the identical frame (exactly) and an unbounded accumulator costs nothing."""
    base = {k: v for k, v in DEF.items() if k != "drift"}
    a = q.field(XS, YS, dtype=np.float64, drift=0.37, **base)["P"]
    b = q.field(XS, YS, dtype=np.float64, drift=1.37, **base)["P"]
    c = q.field(XS, YS, dtype=np.float64, drift=-0.63, **base)["P"]
    check("drift 0.37 == 1.37 (one turn)", np.abs(a - b).max(), 1e-9)
    check("drift 0.37 == -0.63", np.abs(a - c).max(), 1e-9)
    zero = q.field(XS, YS, dtype=np.float64, drift=0.0, **base)["P"]
    assert np.abs(a - zero).max() > 0.05, "a 0.37-turn drift must change the pattern"
    # float32: a drift of 10001.37 turns wraps to the same phase as 0.37 up to the float32 rounding of the input
    big = q.field(XS, YS, dtype=np.float32, drift=1.5 + 4096.0, **base)["P"]
    small = q.field(XS, YS, dtype=np.float32, drift=1.5, **base)["P"]
    check("float32 drift 4097.5 == 1.5 (exact wrap)", np.abs(big - small).max(), 1e-6)


def test_zoom_wrap_is_seamless_with_drift_running():
    """2026-10-30 regression: the drift phase was scaled by 2^i (the octave's slot in the loop), and the zoom wrap
    re-indexes the octaves, so with a non-zero drift the whole pattern jumped (|dP| up to 1.5) at every zoom wrap.
    The earlier wrap checks ran at drift 0 (or at one fixed zoom), so none could see it. The unwrapped zoom = 1 frame
    must equal the zoom = 0 frame at any drift, in the potential and the vecfield numerators."""
    base = {k: v for k, v in DEF.items() if k not in ("zoom", "drift")}
    for env in (0.5, 0.7):
        for drift in (0.05, 0.37, 0.8):
            a = q.field(XS, YS, dtype=np.float64, zoom=1.0, drift=drift, wrap_zoom=False, **{**base, "envelope": env})
            b = q.field(XS, YS, dtype=np.float64, zoom=0.0, drift=drift, **{**base, "envelope": env})
            tol = 1e-6 if env == 0.5 else 2e-3     # the leaving / entering octave weights (spec: ~1e-8 at 0.5, 7.6e-5 at 0.7)
            check(f"envelope {env}, drift {drift}: P(zoom 1) == P(zoom 0)", np.abs(a["P"] - b["P"]).max(), tol)
            check(f"envelope {env}, drift {drift}: vx, vy (zoom 1) == (zoom 0)",
                  max(np.abs(a["vx"] - b["vx"]).max(), np.abs(a["vy"] - b["vy"]).max()), tol)
    # the mutation (the old 2^i scaling) must jump here, so this test can tell the two apart
    a = q.field(XS, YS, dtype=np.float64, zoom=1.0, drift=0.37, wrap_zoom=False, bug="drift_scaled", **base)["P"]
    b = q.field(XS, YS, dtype=np.float64, zoom=0.0, drift=0.37, bug="drift_scaled", **base)["P"]
    jump = float(np.abs(a - b).max())
    note("old 2^i scaling: jump of P at the zoom wrap (drift 0.37)", f"{jump:.3f}")
    assert jump > 0.5, f"the drift_scaled mutation should jump at the zoom wrap, got {jump:.3e}"


def test_rotation_covariance():
    a = 0.7
    ca, sa = math.cos(a), math.sin(a)
    xr = ca * XS + sa * YS
    yr = -sa * XS + ca * YS
    p_rot_param = q.field(XS, YS, dtype=np.float64, **{**DEF, "angle": a})["P"]
    p_rot_point = q.field(xr, yr, dtype=np.float64, **DEF)["P"]
    check("P(angle=a)(q) == P(angle=0)(R(-a) q)", np.abs(p_rot_param - p_rot_point).max(), 1e-9)


# --- gradient and vecfield -----------------------------------------------------------------

def test_gradient_matches_central_finite_difference():
    h = 1e-6
    kw = dict(zoom=0.3, drift=0.17, density=2.0, envelope=0.5)
    xs, ys = XS[:30], YS[:30]
    gx = np.array([(ref_point(x + h, y, **kw)[0] - ref_point(x - h, y, **kw)[0]) / (2 * h) for x, y in zip(xs, ys)])
    gy = np.array([(ref_point(x, y + h, **kw)[0] - ref_point(x, y - h, **kw)[0]) / (2 * h) for x, y in zip(xs, ys)])
    ana = ref_arrays(xs, ys, **kw)
    scale = float(np.abs(ana[1:3]).max())
    check("analytic gradient vs finite difference (reference), relative", max(_worst(gx, ana[1]), _worst(gy, ana[2])) / scale, 1e-6)
    f = q.field(xs, ys, dtype=np.float64, **kw)
    check("mirror gradient vs finite difference, relative", max(_worst(f["gx"], gx), _worst(f["gy"], gy)) / scale, 1e-6)


def test_vecfield_is_bounded_and_single_octave_identity():
    worst = 0.0
    rng = np.random.default_rng(5)
    for _ in range(40):
        kw = dict(zoom=rng.uniform(0, 1), drift=rng.uniform(-2, 2), density=rng.uniform(1, 12),
                  envelope=rng.uniform(0.25, 1.5), angle=rng.uniform(0, np.pi))
        f = q.field(rng.uniform(-1, 1, 400), rng.uniform(-.5, .5, 400), dtype=np.float32, **kw)
        worst = max(worst, float(np.hypot(f["vx"], f["vy"]).max()) - 1.0)
    check("max |v| - 1 over a parameter sweep (<= float32 slack)", max(worst, 0.0), 1e-6)
    # envelope 0.05 at zoom 0: only octave 3 (scale 8) has weight; v = grad P / (2 pi B s)
    kw = dict(zoom=0.0, drift=0.0, density=3.0, envelope=0.05)
    f = q.field(XS, YS, dtype=np.float64, **kw)
    d = 2 * math.pi * 3.0 * 8.0
    check("single-octave v == grad P / (2 pi B s)", max(_worst(f["vx"], f["gx"] / d), _worst(f["vy"], f["gy"] / d)), 1e-12)


def test_gain_zero_gives_the_neutral_field():
    _, vec, _ = q.render(12, 20, gain=0.0, **DEF)
    check("gain 0: R, G exactly 0.5", float(np.abs(vec[..., :2] - 0.5).max()), 0.0)
    check("B = 0.5, A = 1", float(max(np.abs(vec[..., 2] - 0.5).max(), np.abs(vec[..., 3] - 1.0).max())), 0.0)
    _, vec1, _ = q.render(12, 20, gain=1.0, **DEF)
    assert vec1[..., :2].min() > 0.0 and vec1[..., :2].max() < 1.0, "gain 1 must encode without clipping"


# --- look ----------------------------------------------------------------------------------

def test_banded_look_closed_form():
    P = np.linspace(-1, 1, 41, dtype=np.float64)
    bands = 5.0
    s = (P * 0.5 + 1.0) * bands
    expect = np.abs((s - np.floor(s)) * 2 - 1) ** 1.1
    check("banded look vs the closed form", _worst(q.banded(P.astype(np.float32), bands), expect), 2e-6)
    # fold edges: a whole number of bands is the bright edge (frac 0 -> |0*2-1| = 1)
    edge = (np.array([2.0]) / bands - 1.0) * 2.0   # (P*0.5 + 1)*bands == 2
    check("a whole-number s sits on a fold edge (value 1)", abs(float(q.banded(edge, bands)[0]) - 1.0), 1e-6)


# --- mutations -----------------------------------------------------------------------------

def test_mutations_are_caught():
    real = _errs()
    note("real mirror worst errors", {k: f"{v:.2e}" for k, v in real.items()})
    assert max(real.values()) < 2e-3, f"the real mirror must pass the same checks: {real}"
    for bug in q.BUGS:
        e = _errs(bug)
        worst = max(e.values())
        note(f"mutation '{bug}' worst error", f"{worst:.3e}")
        if not worst > 1e-2:
            raise AssertionError(f"mutation not detected: {bug} ({e})")
    print("    ok   a gradient without 2 pi B s, the source aspect, a vecfield normalised by sum w, "
          "a shifted envelope centre and a 2^i-scaled drift phase are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))
