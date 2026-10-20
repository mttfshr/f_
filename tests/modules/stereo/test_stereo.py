"""
test_stereo.py -- tier-1 tests for the f_stereo mirror (stereo_mirror.py, a hand
translation of src/f_stereo/codebox_v1.gen).

Ground truth is independent of the mirror:

  - Unit sphere (math identity): the orthographic and stereographic inverse maps send the
    unit disk onto hemispheres of the unit sphere, so |(rx, ry, rz)| = 1 on disk pixels at
    proj 0 and 1, and the orthographic guard clamps off-disk points to the equator rim
    (rz = 0 exactly).
  - Centre pole (doc + math): the sphere point at the screen centre is the north pole for
    every proj, and the doc says "f_stereo's north pole samples at y=1"; with atan2(0,0)=0
    the centre texel reads exactly (u, v) = (0.5, 1.0).
  - Diagonal corner (math identity): at proj 0 the off-disk corner clamps to the equator rim,
    atan2(-x, -x) = -3 pi / 4, so the corner reads (u, v) = (0.125, 0.5) exactly.
  - Hard mask (doc "with a hard black mask at the unit disk boundary"): with circ on, every
    pixel with dist >= 0.5 is exactly black with alpha 1; inside, a constant source passes
    through unchanged (bilinear of a constant is exact).
  - Back hemisphere (doc "full passes the complete projected rectangle including
    back-hemisphere corners"): at proj 1 and circ 0 all four corners sample v = asin(rz)/pi+0.5
    with rz = -(r^2-1)/(1+r^2) < 0, so corner v < 0.5.
  - Bypass (doc "Passes raw unwarped texture through"): bypass=1 returns sample(in1, norm),
    which at texel centres is the source pixel exactly, mask included.
  - Radial symmetry (doc "Rings become latitude bands" + identity): concentric screen circles
    map to latitude circles (constant v), so a row-constant source yields an image that is
    exactly 90-degree rotation symmetric, at any proj.
  - Neutral rotation (math identity): with all three angles zero R is the identity, so the
    rotated field equals the projection closed form; the closed forms (classic stereographic/
    orthographic) are stated by the doc's signal chain.
  - Generic rotation (doc "R = Rz(spin) x Ry(lon) x Rx(lat)" + standard rotation matrices and
    the doc's angle mappings, composed in float64): at generic angles the ramp readback equals
    uv of the composed rotation applied to the stereographic closed form.
  - Spin is a longitude shift (math identity): Rz(psi) adds psi to the sampled longitude, so
    out(spin=psi) equals the spin-0 sampling shifted by psi/2pi in u, wherever neither u sits
    on the atan2 branch cut or the clamp edge.
  - Tissot sweep (doc "stereographic is conformal, orthographic is not" + analytic eccentricity
    closed forms): the screen-to-uv anisotropy ratio, measured on the mirror by finite
    differences, is (1+r^2)/(4r) max'ed with its reciprocal at the stereo end and
    sqrt(1-r^2)/(2r) max'ed with its reciprocal at the ortho end (the 2pi-vs-pi equirect
    axes make even a conformal map anisotropic in uv); the two formulas equal 1 at different
    radii, r = 2-sqrt(3) and r = 1/sqrt(5). Tolerance 0.01: float32 uv noise divided by the
    1e-3 difference step gives ~5e-4 jitter per Jacobian entry.

Scope and limits: NumPy-side only. GPU-specific behaviour (the atan2 +pi convention at the
branch cut, runtime atan2(0,0) = NaN, 8-bit bilinear weights, char output) is tier-2 bench
territory and deliberately not checked here. The proj=-2 dial extreme can push rz outside
asin's domain (see test_proj_minus2_leaves_asin_domain).

Run:  tests/run.sh tests/modules/stereo/test_stereo.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from stereo_mirror import F32, stereo, sphere_field  # noqa: E402

N = 64
TWOPI = 2.0 * np.pi
PI64 = np.pi


# --- textures -----------------------------------------------------------------------------

def ramp_tex(n=N):
    """R = u, G = v: a read back returns the sampling coordinate itself (bilinear is
    exact on linear ramps)."""
    t = g.texture(n, n)
    nx, ny, _, _ = g.grid(n, n)
    t[..., 0] = nx
    t[..., 1] = ny
    t[..., 2] = F32(0.5)
    t[..., 3] = F32(1.0)
    return t


def const_tex(rgba, n=N):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def row_tex(n=N):
    """Row-constant source (G channel holds v, R/B fixed): kills all u dependence."""
    t = g.texture(n, n)
    _, ny, _, _ = g.grid(n, n)
    t[..., 0] = F32(0.3)
    t[..., 1] = ny
    t[..., 2] = F32(0.7)
    t[..., 3] = F32(1.0)
    return t


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


# --- independent float64 references --------------------------------------------------------

def sphere64(zx, zy, proj):
    """The two classic inverse projections and the doc's blend between them, float64.
    Doc (signal chain): 'Inverse projection to the unit sphere (sx, sy, sz)'; the endpoint
    formulas are the classical stereographic / orthographic maps."""
    r2 = zx * zx + zy * zy
    d = 1.0 + r2
    s = np.stack([2.0 * zx / d, 2.0 * zy / d, (1.0 - r2) / d], axis=-1)
    o = np.stack([zx, zy, np.sqrt(np.maximum(1.0 - r2, 0.0))], axis=-1)
    return o * (1.0 - proj) + s * proj


def rot64(p, lon, lat, spin):
    """R = Rz(spin) x Ry(lon) x Rx(lat) built from the standard rotation matrices
    (Rx: y->z, Ry: z->x, Rz: x->y) with the doc's angle mappings:
    lon (lon-0.5)*2pi, lat (lat-0.5)*pi, spin spin*2pi."""
    lon_a = (lon - 0.5) * TWOPI
    lat_a = (lat - 0.5) * PI64
    spin_a = spin * TWOPI
    ca, sa = np.cos(lat_a), np.sin(lat_a)
    cb, sb = np.cos(lon_a), np.sin(lon_a)
    cs, ss = np.cos(spin_a), np.sin(spin_a)
    x, y, z = p[..., 0], p[..., 1], p[..., 2]
    x1, y1, z1 = x, ca * y - sa * z, sa * y + ca * z            # Rx(lat)
    x2, y2, z2 = cb * x1 + sb * z1, y1, -sb * x1 + cb * z1      # Ry(lon)
    return np.stack([cs * x2 - ss * y2, ss * x2 + cs * y2, z2], axis=-1)  # Rz(spin)


def uv64(p):
    """The doc's stated equirectangular encoding, float64:
    u = atan2(ry, rx)/2pi + 0.5, v = asin(rz)/pi + 0.5."""
    u = np.arctan2(p[..., 1], p[..., 0]) / TWOPI + 0.5
    v = np.arcsin(np.clip(p[..., 2], -1.0, 1.0)) / PI64 + 0.5
    return u, v


def bilinear64(tex, u, v):
    """Clamped bilinear read of a float32 texture in float64 (sample() semantics)."""
    h, w = tex.shape[:2]
    u = np.asarray(u, np.float64)
    v = np.asarray(v, np.float64)
    x = u * w - 0.5
    y = v * h - 0.5
    x0 = np.floor(x)
    y0 = np.floor(y)
    fx = (x - x0)[..., None]
    fy = (y - y0)[..., None]
    ix0 = np.clip(x0.astype(np.int64), 0, w - 1)
    ix1 = np.clip(x0.astype(np.int64) + 1, 0, w - 1)
    iy0 = np.clip(y0.astype(np.int64), 0, h - 1)
    iy1 = np.clip(y0.astype(np.int64) + 1, 0, h - 1)
    top = tex[iy0, ix0] * (1 - fx) + tex[iy0, ix1] * fx
    bot = tex[iy1, ix0] * (1 - fx) + tex[iy1, ix1] * fx
    return top * (1 - fy) + bot * fy


def plane64(n=N):
    """Centered plane coordinates (codebox section 1) in float64."""
    nx, ny, _, _ = g.grid(n, n)
    return (nx.astype(np.float64) - 0.5) * 2.0, (ny.astype(np.float64) - 0.5) * 2.0


def interior(u, v, n=N, margin=2e-3):
    """Pixels whose uv is away from the clamp edges (and the u=1 branch cut), so the
    bilinear stencil is fully inside and float32 rounding cannot flip an edge."""
    lo, hi = 1.5 / n + margin, 1.0 - 1.5 / n - margin
    return (u > lo) & (u < hi) & (v > lo) & (v < hi)


def away_from_texel_edge(x, n=N):
    """Float32 rounds the sampling coordinates by ~1e-8 absolute, which can flip the
    floor() of a texel position that sits within that rounding of an integer texel
    boundary (the readback then differs by up to a texel's weight, ~1.5e-5 of the texel
    span). Excludes pixels whose texel x position is that close to an integer."""
    pos = np.asarray(x, np.float64) * n - 0.5
    return (np.abs(pos - np.floor(pos + 0.5)) > 5e-6)


def _safe(errs):
    """NaN anywhere in a comparison means the check fails loudly."""
    e = np.concatenate([np.ravel(x) for x in errs]) if errs else np.array([0.0])
    if not np.isfinite(e).all():
        return 10.0
    return float(np.abs(e).max()) if e.size else 0.0


# --- error helpers, shared by the individual tests and the mutation sweep ------------------

def _err_unit(bug=None):
    """Disk pixels sit on the unit sphere at proj 0 and 1; off-disk orthographic pixels
    clamp to the equator rim (rz = 0 exactly)."""
    n = N
    zx, zy = plane64(n)
    r2 = zx * zx + zy * zy
    worst = 0.0
    for proj in (0.0, 1.0):
        rx, ry, rz = sphere_field(n, n, proj=proj, bug=bug)
        p1 = rx.astype(np.float64) ** 2 + ry.astype(np.float64) ** 2 + rz.astype(np.float64) ** 2
        worst = max(worst, float(np.abs(p1[r2 <= 1.0] - 1.0).max()))
    rx, ry, rz = sphere_field(n, n, proj=0.0, bug=bug)
    worst = max(worst, float(np.abs(rz.astype(np.float64)[r2 > 1.0]).max()))
    return worst


def _err_pole(bug=None):
    """Screen centre = north pole for every proj (sz = 1 exactly): uy = 0.5 + 0.5 = 1,
    which clamps to the TOP texel row, and ux = atan2(0, 0)/2pi + 0.5 = 0.5. So the
    centre texel of an n=65 ramp reads exactly (0.5, ny of row 64) = (0.5, 64.5/65)."""
    n = 65
    src = ramp_tex(n)
    worst = 0.0
    for proj in (0.0, 1.0, 0.37):
        out = stereo(src, proj=proj, bug=bug)
        worst = max(worst, float(np.abs(out[32, 32, :2].astype(np.float64)
                                        - np.array([0.5, 64.5 / 65.0])).max()))
    return worst


def _err_corner(bug=None):
    """Proj 0, circ 0, defaults. The (63,63) corner sits on the +x,+y diagonal (zx = zy =
    0.984375, r^2 > 1), so the orthographic max() clamps it to the equator rim (v = 0.5)
    and atan2(+x, +x) = +45 deg, u = 0.625. The (63,0) corner (+y, -x diagonal) reads
    atan2(+x, -x) = +135 deg, u = 0.875. Both exact."""
    src = ramp_tex(N)
    out = stereo(src, proj=0.0, circ=0.0, bug=bug)
    return _safe([out[63, 63, :2].astype(np.float64) - np.array([0.625, 0.5]),
                  out[63, 0, :2].astype(np.float64) - np.array([0.875, 0.5])])


def _err_mask(bug=None):
    """circ on: dist >= 0.5 pixels are exactly (0,0,0,1); inside, a constant source passes
    exactly. Classification from the float64 dist rule."""
    src = const_tex((0.25, 0.35, 0.45, 1.0))
    nx, ny, _, _ = g.grid(N, N)
    dist = np.sqrt((nx.astype(np.float64) - 0.5) ** 2 + (ny.astype(np.float64) - 0.5) ** 2)
    outside = dist >= 0.5
    worst = 0.0
    for proj in (0.0, 1.0):
        out = stereo(src, proj=proj, circ=1.0, bug=bug)
        worst = max(worst, float(np.abs(out[outside] - np.array([0.0, 0.0, 0.0, 1.0])).max()))
        worst = max(worst, float(np.abs(out[~outside] - src[0, 0]).max()))
    return worst


def _err_symmetry(bug=None):
    """Concentric screen circles sample single latitude rows, so a row-constant source
    yields a 90-degree symmetric output at any proj."""
    src = row_tex(N)
    worst = 0.0
    for proj in (0.0, 1.0, 0.4):
        out = stereo(src, proj=proj, circ=0.0, bug=bug)
        worst = max(worst, _safe([out - np.rot90(out)]))
    return worst


def _err_generic(bug=None):
    """Generic lon/lat/spin at proj 1: ramp readback vs the float64 composed rotation
    applied to the stereographic closed form."""
    n = N
    src = ramp_tex(n)
    lon, lat, spin = 0.37, 0.61, 0.23
    zx, zy = plane64(n)
    u, v = uv64(rot64(sphere64(zx, zy, 1.0), lon, lat, spin))
    out = stereo(src, lon=lon, lat=lat, spin=spin, proj=1.0, circ=0.0, bug=bug)
    m = interior(u, v, n)
    return _safe([out[..., 0].astype(np.float64)[m] - u[m],
                  out[..., 1].astype(np.float64)[m] - v[m]])


def _err_spin(bug=None):
    """spin psi shifts the sampled longitude by psi exactly: out(spin) = bilinear
    (src, u0 + psi/(2pi), v0) away from the branch cut and the clamp edges. Generic lon/lat,
    random source. Tolerance 2e-5 (docstring below); v > 0.93 excluded because near the
    pole the rows compress (dv/drow shrinks), so a one-texel uv wobble is a large v error."""
    n = N
    src = rand_tex(11, n)
    lon, lat, psi = 0.32, 0.44, 0.015
    zx, zy = plane64(n)
    u0, v0 = uv64(rot64(sphere64(zx, zy, 1.0), lon, lat, 0.0))
    out = stereo(src, lon=lon, lat=lat, spin=psi, proj=1.0, circ=0.0, bug=bug)
    m = (interior(u0 + psi, v0, n) & interior(u0, v0, n)
         & away_from_texel_edge(u0 + psi, n) & away_from_texel_edge(v0, n)
         & (v0 < 0.93))
    expect = bilinear64(src, u0 + psi, v0)
    return _safe([out[m] - expect[m]])


def _ecc_closed_stereo(r):
    """Analytic uv anisotropy at the stereo end: du/dv = (1+r^2)/(4r); the ratio is
    max(x, 1/x). Equals 1 at r = 2 - sqrt(3)."""
    x = (1.0 + r * r) / (4.0 * r)
    return max(x, 1.0 / x)


def _ecc_closed_ortho(r):
    """Analytic uv anisotropy at the ortho end: du/dv = sqrt(1-r^2)/(2r); the ratio is
    max(x, 1/x). Equals 1 at r = 1/sqrt(5)."""
    x = np.sqrt(1.0 - r * r) / (2.0 * r)
    return max(x, 1.0 / x)


def _fd_ecc(proj, r, theta=0.9):
    """Eccentricity (singular-value ratio) of the mirror's screen->uv Jacobian at plane
    radius r (z units), by central differences through sphere_field and the doc's uv
    encoding, float64 throughout after the mirror's float32 sphere point."""
    h = 1e-3
    cxn = 0.5 + r * np.cos(theta) / 2.0
    cyn = 0.5 + r * np.sin(theta) / 2.0

    def uv_at(dxn, dyn):
        nx = np.float32(cxn + dxn)[None, None]
        ny = np.float32(cyn + dyn)[None, None]
        rx, ry, rz = sphere_field(1, 1, proj=proj, nx=nx, ny=ny)
        p = np.stack([rx, ry, rz], axis=-1).astype(np.float64)[0, 0]
        return uv64(p[None, None, :])[0][0, 0], uv64(p[None, None, :])[1][0, 0]

    ux_p, vy_p = uv_at(h, 0.0)
    ux_m, vy_m = uv_at(-h, 0.0)
    ux_p2, vy_p2 = uv_at(0.0, h)
    ux_m2, vy_m2 = uv_at(0.0, -h)
    j = np.array([[(ux_p - ux_m) / (2 * h), (ux_p2 - ux_m2) / (2 * h)],
                  [(vy_p - vy_m) / (2 * h), (vy_p2 - vy_m2) / (2 * h)]])
    sv = np.linalg.svd(j, compute_uv=False)
    return float(sv[0] / sv[1])


def _err_tissot(bug=None):
    """Mirror-measured eccentricity vs the analytic closed forms at r = 0.1, 0.5, 0.9 for
    both projection ends, plus the two crossing radii where each equals 1."""
    worst = 0.0
    for r in (0.1, 0.5, 0.9):
        for proj, closed in ((1.0, _ecc_closed_stereo), (0.0, _ecc_closed_ortho)):
            e = _fd_ecc(proj, r)
            worst = max(worst, abs(e - closed(r)))
    for proj, closed, r in ((1.0, _ecc_closed_stereo, 2.0 - np.sqrt(3.0)),
                            (0.0, _ecc_closed_ortho, 1.0 / np.sqrt(5.0))):
        e = _fd_ecc(proj, r)
        worst = max(worst, abs(e - 1.0))
    return worst


def _err_range(bug=None):
    """Outputs stay finite, RGB in [0,1], alpha exactly 1, at rotation extremes at the
    projection endpoints (proj 0 and 1, where the sphere point is unit or rim-clamped, so
    |rz| <= 1 everywhere)."""
    src = rand_tex(13, n=N)
    worst = 0.0
    for kw in (dict(proj=1.0, lon=0.0, lat=1.0, spin=1.0),
               dict(proj=0.0, lon=1.0, lat=0.0, spin=0.5),
               dict(proj=1.0, lon=0.7, lat=0.9, spin=0.1)):
        out = stereo(src, circ=1.0, bug=bug, **kw)
        if not np.isfinite(out).all():
            return 10.0
        worst = max(worst, float(out[..., :3].max()) - 1.0, -float(out[..., :3].min()),
                    float(np.abs(out[..., 3] - 1.0).max()))
    return worst


# --- individual tests -----------------------------------------------------------------------

def test_sphere_point_unit_and_equator_clamp():
    """The doc says every disk pixel corresponds to exactly one point on the sphere surface:
    |p| = 1 on the disk at both projection ends (a math identity of the two classic inverse
    maps), and the orthographic max() guard clamps off-disk points to the equator rim."""
    check("sphere radius on the disk, proj 0 and 1; off-disk ortho rz = 0",
          _err_unit(), 5e-6)


def test_centre_pole_reads_uv_half_one():
    """The sphere point at the screen centre is the north pole for every proj (sz = 1
    exactly), and the doc says the north pole samples at y=1: uy = 0.5 + 0.5 = 1 clamps to
    the top texel row, and ux = atan2(0,0)/2pi + 0.5 = 0.5, so the centre texel of an n=65
    ramp reads exactly (0.5, 64.5/65)."""
    check("centre texel reads (0.5, top row) at proj 0, 1 and 0.37", _err_pole(), 1e-6)


def test_ortho_corner_clamps_to_equator_rim():
    """Proj 0, circ 0, defaults: the diagonal corners sit off the orthographic disk, so
    their sphere point clamps to the equator rim (v = 0.5 exactly) at longitude atan2 of
    their diagonal: (63,63) is the +x,+y diagonal, u = 0.625; (63,0) the +y,-x diagonal,
    u = 0.875. Both read back exactly on the ramp."""
    check("diagonal corner readbacks (0.625, 0.5) and (0.875, 0.5)", _err_corner(), 1e-6)


def test_circular_mask_is_hard_black_outside():
    """The doc's hard mask at the unit disk boundary: dist >= 0.5 is exactly (0,0,0,1),
    inside pixels pass a constant source unchanged, at both projection ends."""
    check("mask outside black with alpha 1, inside equals the constant source",
          _err_mask(), 1e-6)


def test_full_mode_shows_back_hemisphere_corners():
    """The doc says full mode passes the back-hemisphere corners: at proj 1 the corner
    sphere point has rz = -(r^2-1)/(1+r^2) < 0, so the ramp's G readback (v = asin(rz)/pi+0.5)
    is below 0.5 at all four corners."""
    src = ramp_tex(N)
    out = stereo(src, proj=1.0, circ=0.0)
    assert np.isfinite(out).all()
    corners = [out[0, 0, 1], out[0, 63, 1], out[63, 0, 1], out[63, 63, 1]]
    worst = float(max(corners))
    note("worst (highest) corner v at proj 1, circ 0", worst)
    assert worst < 0.45, f"corner v should sit clearly below the equator, got {worst}"


def test_bypass_passes_the_source():
    """The doc's bypass row: 'Passes raw unwarped texture through' -- out = sample(in1, norm),
    exact at texel centres, mask included, under an extreme in-domain warp (proj 1, generic
    rotations)."""
    src = rand_tex(12)
    out = stereo(src, lon=0.1, lat=0.9, spin=0.7, proj=1.0, circ=1.0, bypass=1.0)
    check("bypass equals the source under an extreme warp", float(np.abs(out - src).max()), 1e-6)


def test_radially_symmetric_source_stays_symmetric():
    """Rings become latitude bands: concentric screen circles sample single latitude rows,
    so a row-constant source yields an exactly 90-degree symmetric image at any proj."""
    check("output 90-degree symmetric for a row-constant source, proj 0/0.4/1",
          _err_symmetry(), 2e-6)


def test_neutral_rotation_is_identity():
    """The doc says at the defaults all three angles are zero so R is the identity; the
    rotated field must equal the projection closed form (classic stereographic/orthographic),
    float64, everywhere."""
    n = N
    zx, zy = plane64(n)
    worst = 0.0
    for proj in (0.0, 1.0):
        rx, ry, rz = sphere_field(n, n, proj=proj)
        expect = sphere64(zx, zy, proj)
        worst = max(worst, float(np.abs(np.stack([rx, ry, rz], -1).astype(np.float64)
                                        - expect).max()))
    check("neutral-rotation field vs the projection closed form", worst, 2e-6)


def test_generic_rotation_matches_composed_matrices():
    """The special-point checks cannot see a sign slip in a rotation term that vanishes at
    the defaults; this one runs generic lon/lat/spin at proj 1 against R composed from the
    standard rotation matrices and the doc's angle mappings, float64, with the ramp readback."""
    check("generic rotation vs composed Rz.Ry.Rx on the stereographic closed form",
          _err_generic(), 1e-5)


def test_spin_shifts_longitude_exactly():
    """Rz(psi) adds psi to the sampled longitude, so out(spin) is the spin-0 sampling shifted
    by psi/2pi in u -- spin stays independent of the globe orientation away from the branch
    cut and the clamp edges (generic lon/lat, random source). Tolerance 2e-5 rather than
    1e-5: a sampling coordinate that rounds to within ~3e-8 of a texel boundary can still
    flip the bilinear floor, a ~1.5e-5 texel-weight error; pixels with v > 0.93 are also
    excluded (near-pole row compression turns a one-texel wobble into a large v error)."""
    check("spin 0.015 shifts u by exactly 0.015", _err_spin(), 2e-5)


def test_tissot_eccentricities_distinguish_the_projection_ends():
    """The doc notes the ends differ in conformality; measured through the mirror, the
    screen-to-uv anisotropy is (1+r^2)/(4r)-based at the stereo end and sqrt(1-r^2)/(2r)-based
    at the ortho end (the equirect unwrap contributes a 2pi-vs-pi axis ratio), and the two
    ratios cross 1 at r = 2-sqrt(3) and r = 1/sqrt(5). Tolerance 0.01: float32 uv noise
    divided by the 1e-3 difference step gives ~5e-4 per Jacobian entry."""
    check("Tissot eccentricity vs analytic closed forms and crossing radii", _err_tissot(), 0.01)


def test_outputs_stay_in_range_at_safe_extremes():
    """At the rotation extremes, at the projection endpoints (proj 0 and 1, where the
    sphere point is unit on the disk or rim-clamped off it, so |rz| <= 1 everywhere),
    output stays finite, RGB in [0,1], alpha exactly 1. Intermediate proj with off-disk
    pixels genuinely exits asin's domain -- see the proj -2 test."""
    check("finite, in-range, opaque alpha at rotation extremes", _err_range(), 0.0)


def test_proj_minus2_leaves_asin_domain():
    """Documented extended-distortion behaviour: at proj = -2 the blended sphere point can
    push rz above 1 near the centre (3*sz_o - 2*sz_s > 1 for small r), so asin produces NaN
    and those pixels go black-with-NaN. Recorded, not fixed."""
    src = ramp_tex(N)
    out = stereo(src, proj=-2.0)
    n_nan = int((~np.isfinite(out)).sum())
    note("proj -2: non-finite output values", n_nan)
    assert n_nan > 0, "expected the proj=-2 dial extreme to leave asin's domain"


# --- mutations --------------------------------------------------------------------------------

BUGS = ["sign_flip_sz", "ortho_no_max", "swap_asin_atan", "drop_mask"]
TOLS = {"unit": (5e-6, _err_unit), "pole": (1e-6, _err_pole), "corner": (1e-6, _err_corner),
        "mask": (1e-6, _err_mask), "symmetry": (2e-6, _err_symmetry),
        "generic": (1e-5, _err_generic), "spin": (1e-5, _err_spin),
        "tissot": (0.01, _err_tissot), "range": (0.0, _err_range)}


def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin, and the real
    mirror must stay inside every tolerance."""
    real = {k: fn() for k, (tol, fn) in TOLS.items()}
    for k, e in real.items():
        assert e <= TOLS[k][0], f"real mirror exceeds tolerance on {k}: {e:.3e} > {TOLS[k][0]:.0e}"
    note("real mirror worst error over the shared checks", max(real.values()))
    for bug in BUGS:
        errs = {k: fn(bug) for k, (tol, fn) in TOLS.items()}
        caught = {k: e for k, e in errs.items() if np.isfinite(e) and e > 1e-3}
        if not caught:
            raise AssertionError(f"mutation '{bug}' survived every check")
        k = sorted(caught, key=lambda key: -caught[key])[0]
        note(f"mutation '{bug}' caught by {k}", caught[k])
    print("    ok   sz sign flip, an unguarded orthographic sqrt, a swapped asin/atan pair "
          "and a dropped mask are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))