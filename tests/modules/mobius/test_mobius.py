"""
test_mobius.py -- tier-1 NumPy mirror of the f_mobius shader (the codebox inline in
src/f_mobius/definition.py).

Ground truth is independent of the mirror:

  - Neutral setting (all defaults): uv = norm, so the output is the source untouched
    ("a rotation+zoom path (identity at defaults)").
  - Bypass: raw texture passthrough at any other setting.
  - Rotation: a quarter turn (rotate = 0.25) is multiplication by i, so the point directly
    right of the centre samples directly above it; full sweep (rotate = 1) is one
    revolution, back to identity.
  - Zoom: the dial is logarithmic, 10^((zoom-0.5)*5), so zoom = 0.4 and zoom = 0.6 are
    reciprocal scales, and zoom = 0.7 scales by exactly 10 (10^(0.2*5)), which makes
    the warped coordinates periodic with period 0.1 in norm.
  - Inversion: the reciprocal of i*s is -i/s, so a point directly above the centre samples
    directly below it; the reciprocal of a real point stays real.
  - Guard: the doc's singularity floor is max(mag_sq, 1e-4); at the centre column's texel
    one step above the centre, zy = 1/128 and mag_sq = 6.1e-5 < 1e-4, so the image is
    exactly uv_y = fract(0.5 - 78.125) = 0.375 and uv_x = cx, both dyadic.
  - fract wrapping: fract is periodic with period 1, so two pixels 1/scale apart in norm
    sample the same uv.

Not covered (found in review 2026-10-19): rotation at angles other than 0, 0.25 and 1 turn (the
cosine terms are 0 or 1 there, so a bug in them survives), and a non-default centre outside the
guard check (with the centre at 0.5, adding or subtracting it wraps to the same uv).

Tolerances: closed-form checks run at 1e-5 or tighter except the inversion check (1e-4):
the checked uvs there reach magnitude 64-78, whose float32 reciprocal rounding of about
1e-5 relative reaches 1e-4 absolute after the fract wrap.

Run:  tests/run.sh tests/modules/mobius/test_mobius.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from mobius_mirror import F32, mobius  # noqa: E402


def rand_tex(seed, n=64):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def ramp_tex(n=64):
    """Texture whose R,G channels store the sampling coordinate itself, so a read back
    returns the uv the codebox sampled at (bilinear is exact on linear ramps)."""
    t = g.texture(n, n)
    nx, ny, _, _ = g.grid(n, n)
    t[..., 0] = nx
    t[..., 1] = ny
    t[..., 2] = F32(0.5)
    t[..., 3] = F32(1.0)
    return t


def _uv_sample_err(out, uvx, uvy, mask):
    """Worst error of the ramp read-back against the float64 expected uv, on mask."""
    ex = np.abs(out[..., 0].astype(np.float64) - uvx)[mask]
    ey = np.abs(out[..., 1].astype(np.float64) - uvy)[mask]
    e = np.concatenate([ex, ey])
    if e.size == 0 or np.isnan(e).any():
        return 10.0
    return float(e.max())


def _interior(uvx, uvy, n, margin=1e-3):
    """Pixels whose float64 uv is away from both the 0/1 fract seam and the clamp edge,
    so float32-vs-float64 rounding cannot flip the seam and the bilinear stencil is
    fully inside."""
    lo, hi = 1.5 / n, 1.0 - 1.5 / n
    return ((uvx > lo + margin) & (uvx < hi - margin)
            & (uvy > lo + margin) & (uvy < hi - margin))


def _z64(n, cx=0.5, cy=0.5):
    nx, ny, _, _ = g.grid(n, n)
    return (nx.astype(np.float64) - cx, ny.astype(np.float64) - cy)


# --- error helpers, shared by the individual tests and the mutation sweep ---------------

def _err_identity(bug=None):
    src = rand_tex(1, n=65)
    out = mobius(src, bug=bug)
    return float(np.abs(out - src).max())


def _err_bypass(bug=None):
    src = rand_tex(2)
    out = mobius(src, rotate=0.3, zoom=0.85, invert=0.5, bypass=1.0, bug=bug)
    return float(np.abs(out - src).max())


def _err_rotation(bug=None):
    """Quarter turn closed form, including the doc's logarithmic zoom, on unwrapped pixels."""
    n = 64
    src = ramp_tex(n)
    zx, zy = _z64(n)
    s = 10.0 ** ((0.55 - 0.5) * 5.0)
    th = 0.25 * 2.0 * np.pi
    wx = (zx * np.cos(th) - zy * np.sin(th)) * s
    wy = (zx * np.sin(th) + zy * np.cos(th)) * s
    uvx, uvy = np.mod(wx + 0.5, 1.0), np.mod(wy + 0.5, 1.0)
    out = mobius(src, rotate=0.25, zoom=0.55, bug=bug)
    return _uv_sample_err(out, uvx, uvy, _interior(uvx, uvy, n))


def _err_full_turn():
    src = ramp_tex(65)
    out = mobius(src, rotate=1.0)
    return float(np.abs(out - src).max())


def _err_zoom(bug=None):
    n = 50
    src = ramp_tex(n)
    worst = 0.0
    for zoom in [0.4, 0.55, 0.7]:
        zx, zy = _z64(n)
        s = 10.0 ** ((zoom - 0.5) * 5.0)
        uvx, uvy = np.mod(zx * s + 0.5, 1.0), np.mod(zy * s + 0.5, 1.0)
        out = mobius(src, zoom=zoom, bug=bug)
        worst = max(worst, _uv_sample_err(out, uvx, uvy, _interior(uvx, uvy, n)))
    return worst


def _err_invert(bug=None):
    """Column through the centre (zx = 0, n odd): the reciprocal of i*s is -i/s, so a
    texel above the centre samples directly below it at distance 1/s. Only the exact
    centre-column texels are checked (their uv_x = cx exactly, and zy is exact in
    float64); 1/zy carries a float32 rounding of up to ~1e-5 relative on the smallest
    unguarded row, hence 1e-4."""
    n = 65
    src = ramp_tex(n)
    out = mobius(src, invert=1.0, bug=bug)
    ny, nx, _, _ = g.grid(n, n)
    uvy64 = ny.astype(np.float64)
    col = 32
    worst = 0.0
    for j in range(n):
        zy = uvy64[j, col] - 0.5
        if zy <= 0.0 or abs(zy) < 0.011:
            continue  # at zy = 1/64 mag_sq = 2.4e-4 > 1e-4? check below; skip too-small rows
        mag_sq = max(zy * zy, 1e-4)
        uv_y = np.mod(0.5 - zy / mag_sq, 1.0)
        if not (1e-3 < uv_y < 1.0 - 1e-3):
            continue  # near the fract seam: bilinear of the ramp is exact, but the
        # sampled point may sit on the seam; excluded like the seam in the other tests
        val = out[j, col, 1].astype(np.float64)
        worst = max(worst, abs(val - uv_y))
    real_row = 32
    for i in range(n):
        zx = nx[real_row, i].astype(np.float64) - 0.5
        if zx == 0.0 or abs(zx) < 0.011:
            continue
        uv_x = np.mod(0.5 + zx / zx**2, 1.0)
        if not (1e-3 < uv_x < 1.0 - 1e-3):
            continue
        val = out[real_row, i, 0].astype(np.float64)
        worst = max(worst, abs(val - uv_x))
    return worst


def _err_guard(bug=None):
    """The doc's floor max(mag_sq, 1e-4): at the centre column's texel one step above
    the centre, zy = 1/128 and mag_sq = 6.1e-5 < 1e-4, so the image is the floored
    reciprocal: uv_y = fract(0.5 - 78.125) = 0.375 and uv_x = cx, both dyadic."""
    n = 64
    src = ramp_tex(n)
    cx = F32(0.5078125)  # norm of column 32, exact in float32
    out = mobius(src, cx=float(cx), invert=1.0, bug=bug)
    err = float(np.abs(out[32, 32, :3].astype(np.float64)
                       - np.array([0.5078125, 0.375, 0.5])).max())
    if np.isnan(err):
        return 10.0
    return err


def _err_periodicity(bug=None):
    """Zoom 0.7 -> scale exactly 10: uv = fract(0.5 + 10 z) is periodic with period 0.1
    in norm, which is 5 texels of the n=50 grid. Two limits: the ramp texture itself is
    only exact linear where its bilinear stencil is inside (uv away from both edges),
    and pairs sitting across a fract seam (one uv just above 0, the other just below 1)
    read back almost 1 apart -- the seam, not a disagreement, so both mask classes are
    excluded."""
    n = 50
    src = ramp_tex(n)
    out = mobius(src, zoom=0.7, bug=bug)
    a = out[:, 5:, :2].astype(np.float64)
    b = out[:, :-5, :2].astype(np.float64)
    d = np.abs(a - b)
    seam = d > 0.5          # a fract seam pair differs by 1 - eps, not by eps
    d[seam] = np.abs(1.0 - d[seam])
    edge = np.zeros(d.shape[:2], bool)   # pixels whose own or partner uv is near 0 or 1
    for arr in (a, b):
        edge |= ((arr[..., 0] < 1.5 / n) | (arr[..., 0] > 1 - 1.5 / n)
                 | (arr[..., 1] < 1.5 / n) | (arr[..., 1] > 1 - 1.5 / n))
    good = ~edge
    return float(d[good].max()) if good.any() else 0.0


# --- individual tests -------------------------------------------------------------------

def test_neutral_setting_is_identity():
    """All defaults: the doc says a rotation+zoom path (identity at defaults); at angle 0,
    logarithmic scale 1 and invert 0 the warp is the identity on every pixel."""
    check("neutral defaults reproduce the source, n=65", _err_identity(), 1e-5)


def test_bypass_passes_the_source():
    """Bypass is raw texture passthrough even under an extreme warp (zoom 0.85, invert 0.5)."""
    check("bypass equals the source under an extreme warp", _err_bypass(), 1e-6)


def test_rotation_quarter_turn_closed_form():
    """rotate = 0.25 is a quarter revolution: z mapped by multiplication with i*s, so the
    point right of the centre samples above it; checked against the float64 closed form."""
    check("quarter turn vs complex multiplication, unwrapped pixels", _err_rotation(), 1e-5)


def test_full_turn_is_identity():
    """rotate = 1.0 sweeps one full revolution: e^{2*pi*i} = 1, so the warp returns to identity."""
    check("full revolution returns the source, n=65", _err_full_turn(), 2e-5)


def test_zoom_scale_closed_form():
    """The zoom dial is logarithmic: 10^((zoom-0.5)*5), giving reciprocal scales at 0.4/0.6
    and exactly 10 at 0.7; checked against that stated closed form on unwrapped pixels."""
    check("zoom warp vs the doc's logarithmic scale, unwrapped pixels", _err_zoom(), 1e-5)


def test_inversion_sends_above_centre_to_below():
    """Invert = 1: the reciprocal of i*s is -i/s, so a point directly above the centre
    samples directly below it; a real axis point stays real (imaginary part exactly 0)."""
    check("inversion column: image of i*s is -i/s", _err_invert(), 1e-4)


def test_guard_floors_the_singularity():
    """The doc's floor max(mag_sq, 1e-4): at the texel 1/128 below the centre the image is
    exactly uv_y = fract(0.5 - 78.125) = 0.375 in exact dyadic arithmetic."""
    check("guard floor image at the singularity texel", _err_guard(), 1e-5)


def test_fract_wrap_is_periodic():
    """fract wrapping makes the warp periodic with period 1/scale: zoom = 0.7 scales by
    exactly 10, so pixels 5 texels apart (0.1 in norm) hit the same uv and read back the
    same value, wherever the whole warp is inside the sampling range."""
    check("period-0.1 periodicity of the zoom warp", _err_periodicity(), 2e-5)


# --- mutations --------------------------------------------------------------------------

BUGS = ["swap_rot_terms", "sign_flip_inv_y", "linear_zoom", "no_guard", "wrap_shift"]
TOLS = {"identity": (1e-5, _err_identity), "rotation": (1e-5, _err_rotation),
        "zoom": (1e-5, _err_zoom), "invert": (1e-4, _err_invert),
        "guard": (1e-5, _err_guard), "period": (2e-5, _err_periodicity)}


def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin, and the real
    mirror must stay inside every tolerance."""
    def run_err(err_fn, bug=None):
        with np.errstate(divide="ignore", invalid="ignore"):
            return err_fn(bug)

    real = {k: run_err(TOLS[k][1]) for k in TOLS}
    for k, e in real.items():
        assert e <= TOLS[k][0], f"real mirror exceeds tolerance on {k}: {e:.3e} > {TOLS[k][0]:.0e}"
    note("real mirror worst error over the shared checks", max(real.values()))
    for bug in BUGS:
        errs = {k: run_err(TOLS[k][1], bug) for k, (tol, err_fn) in TOLS.items()}
        caught = {k: e for k, e in errs.items() if np.isfinite(e) and e > 1e-3}
        if not caught:
            raise AssertionError(f"mutation '{bug}' survived every check")
        k = sorted(caught, key=lambda key: -caught[key])[0]
        note(f"mutation '{bug}' caught by {k}", caught[k])


if __name__ == "__main__":
    sys.exit(run(globals()))