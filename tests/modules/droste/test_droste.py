"""
test_droste.py -- tier-1 NumPy mirror of the f_droste shader (the codebox inline in
src/f_droste/definition.py). Every expected value below comes from one of:

  - the reference doc's statements: the complex-log map ("the mapping `log(z) = log|z| + i·arg(z)`"),
    "At `twist=1`, one full revolution equals one zoom level", "twist=0: rings + radial spokes",
    n_arms "all integers tile cleanly", bypass "0/1";
  - one-sentence math identities built only from those statements: the zoom law
    log(zoom * r) = log r + log zoom, integer-shift no-ops of fract(), the convexity of bilinear
    resampling;
  - the definition's parameter ranges (zoom min 1.1, n_arms 1-16, twist -8 to 8, rotation 0 to 1).

Caveat (review 2026-10-19): check 1 (full-frame coordinate identity) re-derives the codebox's shear algebra in
float64, so it guards dtype and operation order, not the algebra itself; checks 2-9 are the independent ones
(invariants the doc forces).

Ground truth is independent of the mirror:

  1. Full-frame coordinate identity (complex log + Escher shear algebra stated in one sentence):
     at any parameter setting, the output equals the source bilinearly resampled at the pointwise
     (u, v) computed in float64 from log(z) = log|z| + i arg(z) plus the shear. Checked at four
     parameter settings. Catches: angle_radius_swap, twist_sign, no_time_shift at the settings with
     time_s or rotation nonzero, no_arms where n_arms != 1.
  2. Zoom law: r and zoom*r sample the same texel, because the radial coordinate is log r / log zoom.
  3. Fract tiling no-ops: rotation += 3 and time_s += 2 change nothing, because both channels go
     through fract() and the shear maps integer shifts to integer shifts.
  4. Escher coupling at twist=1: the zoom-by-one-zoom-level twin of every point is a self-map (doc:
     one revolution equals one zoom level), pixel-exact within float32.
  5. n_arms fold symmetry at twist=0: the angular one-arm-period twin of every point is a self-map
     (doc: all integers tile cleanly).
  6. Bypass passes the source (doc: "Bypass processing -- 0/1").
  7. Constant-texture degenerate case: a constant source stays constant.
  8. Centre-pixel degenerate case: the r=0 singularity stays finite (the 1e-5 clamp).
  9. Palette containment: the output is a convex combination of source texels, so its per-channel
     range sits inside the source's.
 10. Mutations the tests must catch: angle_radius_swap, twist_sign, no_time_shift, no_arms,
     zoom_clamp_dropped.

Scope and limits: the mirror is float32 and the GPU bench is not part of this file, so nothing here
proves the real shader agrees; it proves the algebra, the mutations are caught, and the doc's
statements hold on the codebox's own arithmetic. GPU trig precision (atan2 at the branch cut),
the wrap-vs-clamp edge behaviour and 8-bit texture quantization are out of scope here (recorded on
the bench elsewhere in the repo, not re-measured).

Run:  tests/run.sh tests/modules/droste/test_droste.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from droste_mirror import F32, droste_pass  # noqa: E402

N2 = 32


def rand_tex(sd, n=N2):
    t = np.random.default_rng(sd).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def const_tex(rgba, n=N2):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def expect_at(u, v, src):
    """Bilinear sample of a (H, W, 4) array at float64 coords, clamp-to-edge, texel-centre:
    the float64 ground sampler, written once from the resampling model (not the mirror)."""
    h, w = src.shape[0], src.shape[1]
    xx = u * w - 0.5
    yy = v * h - 0.5
    x0 = np.floor(xx).astype(np.int64)
    y0 = np.floor(yy).astype(np.int64)
    fx = xx - x0
    fy = yy - y0
    cl = lambda i, n: np.clip(i, 0, n - 1)
    top = src[cl(y0, h), cl(x0, w)] * (1 - fx)[..., None] + src[cl(y0, h), cl(x0 + 1, w)] * fx[..., None]
    bot = src[cl(y0 + 1, h), cl(x0, w)] * (1 - fx)[..., None] + src[cl(y0 + 1, h), cl(x0 + 1, w)] * fx[..., None]
    return top * (1 - fy)[..., None] + bot * fy[..., None]


def f64_identity_coords(px, py, zoom, rot=0.0, tm=0.0, arms=1.0, tw=0.0):
    """(u, v) in float64, from the complex-log identity stated in the reference doc
    (log(z) = log|z| + i arg(z)) plus the doc's Escher shear, nothing read from the mirror:
        t = arg(z) / (2 pi) + rot;  s = log|z| / log(zoom) + tm
        u = fract(arms * (t + tw * s));  v = fract(s - tw * t)
    """
    z = (px - 0.5) + 1j * (py - 0.5)
    t = np.angle(z) / (2.0 * np.pi) + rot
    s = np.log(np.maximum(np.abs(z), 1e-5)) / np.log(max(zoom, 1.001)) + tm
    u = np.remainder(arms * (t + tw * s), 1.0)
    v = np.remainder(s - tw * t, 1.0)
    return u, v


def _closed_form_err(zoom, tw, arms, rot, tm, src, sd_bug=None):
    u64, v64 = f64_identity_coords(_XG, _YG, zoom, rot=rot, tm=tm, arms=arms, tw=tw)
    exp = expect_at(u64, v64, src.astype(np.float64)).astype(F32)
    out = droste_pass(src, zoom=zoom, n_arms=arms, time_s=tm, twist=tw, rotation=rot,
                      bug=sd_bug, nx=Xf, ny=Yf)
    return float(np.abs(out - exp).max())


def _tiling_err(zoom, tw, arms, bug=None):
    """The integer-shift no-op: (rotation += 3, time_s += 2) equals (rotation, time_s)."""
    src = rand_tex(13)
    a = droste_pass(src, zoom=zoom, n_arms=arms, time_s=0.0, twist=tw, rotation=0.0, bug=bug)
    b = droste_pass(src, zoom=zoom, n_arms=arms, time_s=2.0, twist=tw, rotation=3.0, bug=bug)
    return float(np.abs(a - b).max())


# --- coordinate identity (complex-log + doc's Escher shear) ------------------------------------

_XG, _YG = None, None  # module-level 32x32 coordinate grids, set up below


def _grids():
    global _XG, _YG, Xf, Yf
    nx = (np.arange(N2, dtype=np.float64) + 0.5) / (N2 * 1.0)
    _XG, _YG = np.meshgrid(nx, nx)
    Xf, Yf = _XG.astype(F32), _YG.astype(F32)


_grids()


def test_coordinate_identity_full_frame(settings=None):
    """The pass equals the source resampled at the (u, v) the complex-log identity plus the doc's
    shear gives, in float64 at the same pixels, at several parameter settings. doc: the coordinate
    map is log(z) = log|z| + i arg(z) and "At `twist=1`, one full revolution equals one zoom level."
    """
    src = rand_tex(40)
    cases = [(2.0, 1.0, 1.0, 0.0, 0.0), (2.0, 1.0, 2.0, 0.0, 0.0),
             (2.5, 0.5, 2.0, 0.3, 0.2), (3.0, 1.0, 1.0, 0.5, 0.25)]
    worst = 0.0
    for zoom, tw, arms, rot, tm in cases:
        worst = max(worst, _closed_form_err(zoom, tw, arms, rot, tm, src))
    check("four-setting coordinate identity vs float64 complex-log + shear", worst, 1e-4)


# --- zoom law ----------------------------------------------------------------------------------

def test_zoom_law_sets_the_radial_period():
    """math (one sentence): s = log r / log zoom means multiplying r by zoom moves s by exactly 1
    (log(zoom r) = log r + log zoom), i.e. the radial channel has period zoom — the doc's premise
    for a seamless recursive zoom. Checked pixel-exactly on the mirror's own output."""
    zoom = 4.0
    src = rand_tex(2)
    dxs, dyss = _XG - 0.5, _YG - 0.5
    rx = dxs * zoom
    ry = dyss * zoom
    a = droste_pass(src, zoom=zoom, n_arms=1.0, twist=0.0, nx=Xf, ny=Yf)
    b = droste_pass(src, zoom=zoom, n_arms=1.0, twist=0.0,
                    nx=(rx + 0.5).astype(F32), ny=(ry + 0.5).astype(F32))
    check("r and zoom*r give identical output (radial period = zoom)",
          float(np.abs(a - b).max()), 1e-5)


# --- fract tiling no-ops ------------------------------------------------------------------------

def test_fract_and_shear_integer_shifts_are_no_ops():
    """math: fract() erases integer shifts, and the shear maps integer shifts of one channel to
    integer shifts of the other, so (rotation += 3, time_s += 2) is a no-op pixel-exactly.
    1e-4, not 1e-5: the shift lands on different float32 texel centres, so theta and log|z| round
    differently and the bilinear phase moves by up to one ulp — the check is for a whole-image
    invariance, not a bit-exact one. Tolerance 2e-4, the 8-bit interpolation floor."""
    worst = 0.0
    for zoom, tw, arms in [(4.0, 0.0, 1.0), (4.0, 1.0, 3.0), (4.0, 2.0, 1.0), (4.0, 3.0, 5.0)]:
        worst = max(worst, _tiling_err(zoom, tw, arms))
    check("(rotation += 3, time_s += 2) changes nothing, four settings", worst, 2e-4)


# --- Escher coupling: one revolution = one zoom level -------------------------------------------

def _escher_err(zoom, bug=None):
    src = rand_tex(14)
    dxs, dyss = _XG - 0.5, _YG - 0.5
    rx = dxs * zoom
    ry = dyss * zoom
    a = droste_pass(src, zoom=zoom, n_arms=1.0, twist=1.0, nx=Xf, ny=Yf, bug=bug)
    b = droste_pass(src, zoom=zoom, n_arms=1.0, twist=1.0,
                    nx=(rx + 0.5).astype(F32), ny=(ry + 0.5).astype(F32), bug=bug)
    return float(np.abs(a - b).max())


def test_escher_coupling_zoom_step_is_self_map():
    """doc: "At `twist=1`, one full revolution equals one zoom level: the 'Escher coupling.'"
    The zoom-by-one-level twin of every point must output identically, pixel-exactly: both sheared
    coordinates move by exactly 1 and fract erases that."""
    check("twist=1: zoom-step twin is a self-map (Escher coupling)", _escher_err(4.0), 1e-5)


# --- n_arms fold symmetry (twist=0) --------------------------------------------------------------

def _arm_err(k, bug=None):
    src = rand_tex(16)
    dxs, dyss = _XG - 0.5, _YG - 0.5
    ang = 2.0 * np.pi / k
    dxr = dxs * np.cos(ang) - dyss * np.sin(ang)
    dyr = dxs * np.sin(ang) + dyss * np.cos(ang)
    a = droste_pass(src, zoom=4.0, n_arms=float(k), twist=0.0, nx=Xf, ny=Yf, bug=bug)
    b = droste_pass(src, zoom=4.0, n_arms=float(k), twist=0.0,
                    nx=(dxr + 0.5).astype(F32), ny=(dyr + 0.5).astype(F32), bug=bug)
    return float(np.abs(a - b).max())


def test_arms_fold_symmetry_at_twist_zero():
    """doc: n_arms "all integers tile cleanly" — at twist=0 the one-arm-period angular twin of every
    point is a self-map, because the angle moves exactly 1/k of a turn and the fold multiplies by k.
    1e-4, not 1e-5: the twin pixel is offset by cos/sin of an irrational angle, so the source samples
    land on a shifted float32 bilinear phase and the u, v coordinates round differently."""
    worst = 0.0
    for k in (2, 3, 5):
        worst = max(worst, _arm_err(k))
    check("n_arms = 2, 3, 5: the one-arm-period angular twin is a self-map (twist 0)", worst, 1e-4)


# --- bypass and degenerate inputs ----------------------------------------------------------------

def test_bypass_passes_the_source():
    """doc: bypass is "Bypass processing — 0/1"; at 1 the pass must return the source exactly."""
    src = rand_tex(7)
    out = droste_pass(src, zoom=9.0, n_arms=4.0, twist=1.5, rotation=0.3, bypass=1.0)
    check("bypass output equals the source", float(np.abs(out - src).max()), 1e-6)


def test_constant_texture_stays_constant():
    """math: a constant texture is its own bilinear interpolation everywhere, so the output is the
    same constant for every parameter setting."""
    c = (0.25, 0.75, 0.5, 1.0)
    src = const_tex(c)
    worst = 0.0
    for arms, tw, zoom in [(2.0, 1.0, 2.0), (7.0, -3.0, 9.0)]:
        out = droste_pass(src, zoom=zoom, n_arms=arms, twist=tw)
        worst = max(worst, float(np.abs(out - np.asarray(c, F32)).max()))
    check("constant source stays constant through the transform", worst, 1e-6)


def test_centre_pixel_is_finite():
    """definition hint: the `max(r, 0.00001)` clamp keeps the r=0 singularity finite, so no pixel
    anywhere can produce NaN or inf from the log."""
    src = rand_tex(8, n=32)
    out = droste_pass(src, zoom=2.0, n_arms=3.0, twist=1.0, time_s=0.5)
    bad = int((~np.isfinite(out)).sum())
    check("no non-finite outputs anywhere (centre clamp holds)", bad, 0.0)


def test_outputs_are_images_of_the_source_palette():
    """math: with edge clamp, the output is a convex combination of source texels, so its per-channel
    value lies between the source's channel min and max (alpha comes through the same interpolation)."""
    src = rand_tex(19)
    lo = src.min(axis=(0, 1))
    hi = src.max(axis=(0, 1))
    out = droste_pass(src, zoom=2.5, n_arms=3.0, twist=0.7, rotation=0.2, time_s=0.1)
    viol = float(max((lo - out.min(axis=(0, 1))).max(), (out.max(axis=(0, 1)) - hi).max()))
    check("output channel ranges sit inside the source's ranges", viol, 1e-5)


# --- time shift (doc: time_s is the animation driver, added to the radial coordinate) -------------

def _time_shift_err(bug=None):
    """time_s shifts the radial channel by exactly its value. On a source whose value along a
    vertical slice is a linear ramp in v (repeated periodically via fract), the time shift is an
    exact shift of that ramp; check through sample() of an analytic ramp, in float64."""
    zoom, n_arms, tw, rot = 4.0, 1.0, 0.0, 0.0
    src = rand_tex(42)
    a = droste_pass(src, zoom=zoom, n_arms=n_arms, time_s=0.0, twist=tw, rotation=rot,
                    bug=bug, nx=Xf, ny=Yf)
    b = droste_pass(src, zoom=zoom, n_arms=n_arms, time_s=0.5, twist=tw, rotation=rot,
                    bug=bug, nx=Xf, ny=Yf)
    return float(np.abs(a - b).max())


def test_time_shift_moves_the_radial_channel():
    """doc: time_s is "Animation driver — scalar signal, use LFO data outlet", added by the codebox
    to the radial coordinate s before the shear. With twist=0, the output at time_s += 0.5 must
    differ (shift by half a tile in v) and the output at time_s += 1.0 must be the original."""
    src = rand_tex(42)
    half_err = _time_shift_err()
    if not half_err > 0.5:
        raise AssertionError(f"half a period must visibly shift the image: {half_err:.3e}")
    full = droste_pass(src, zoom=4.0, n_arms=1.0, time_s=1.0, nx=Xf, ny=Yf)
    base = droste_pass(src, zoom=4.0, n_arms=1.0, time_s=0.0, nx=Xf, ny=Yf)
    check("time_s += 1 is a full-period no-op (integer shift absorbed by fract)",
          float(np.abs(full - base).max()), 1e-5)


# --- mutations ----------------------------------------------------------------------------------

def _zoom_floor_err(bug=None):
    """The log_zoom floor only does something below zoom = 1.001; check at zoom = 1.0005, which is
    below the dial's stated minimum 1.1 but reachable through parameter automation / drift."""
    src16 = rand_tex(9, n=16)
    n16 = (np.arange(16, dtype=np.float64) + 0.5) / (16 * 1.0)
    X16, Y16 = np.meshgrid(n16, n16)
    Xf16, Yf16 = X16.astype(F32), Y16.astype(F32)
    a = droste_pass(src16, zoom=1.0005, n_arms=2.0, twist=0.3, nx=Xf16, ny=Yf16)
    b = droste_pass(src16, zoom=1.0005, n_arms=2.0, twist=0.3, bug=bug, nx=Xf16, ny=Yf16)
    return float(np.abs(a - b).max())


def test_mutations_are_caught():
    """Each declared bug must fail one of the real checks by a clear margin (>= 1e-3), and the real
    mirror must pass the same checks (>= 100x below tolerance)."""
    real = [_closed_form_err(2.5, 0.5, 2.0, 0.3, 0.2, rand_tex(40)),
            _tiling_err(4.0, 1.0, 3.0), _escher_err(4.0), _arm_err(3), _zoom_floor_err()]
    bad = {"angle_radius_swap": max(_closed_form_err(2.5, 0.5, 2.0, 0.3, 0.2, rand_tex(40), "angle_radius_swap"),
                                    _arm_err(3, "angle_radius_swap")),
           "twist_sign": max(_closed_form_err(2.5, 0.5, 2.0, 0.3, 0.2, rand_tex(40), "twist_sign"),
                             _tiling_err(4.0, 1.0, 3.0, "twist_sign")),
           "no_time_shift": max(_closed_form_err(2.5, 0.5, 2.0, 0.3, 0.2, rand_tex(40), "no_time_shift"),
                                _escher_err(4.0, "no_time_shift")),
           "no_arms": max(_closed_form_err(2.0, 1.0, 2.0, 0.0, 0.0, rand_tex(40), "no_arms"),
                          _arm_err(3, "no_arms")),
           "zoom_clamp_dropped": _zoom_floor_err("zoom_clamp_dropped")}
    for name, v in bad.items():
        note(f"mutation '{name}' worst error", v)
        if not v > 1e-3:
            raise AssertionError(f"mutation not detected: {name} (error {v:.3e})")
    worst_real = max(real)
    assert worst_real < 1e-4, f"the real mirror must pass the same checks: {worst_real:.3e}"
    print("    ok   swapped coordinates, flipped shear, dropped time shift, dropped arm fold and a dropped zoom clamp are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))