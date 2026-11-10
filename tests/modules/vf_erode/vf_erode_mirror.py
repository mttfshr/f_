"""vf_erode_mirror.py -- tier-1 float32 NumPy mirror of f_vf_erode as narrowed 2026-11-09 (spec "Narrowed", plan ADR-9, tasks T050-T054).

Ink moves along a vecfield. Three stages, stateless (bulge per channel, extent one gain from luma):
    zap     non-finite components to 0.
    bulge   only the edges move: each channel is read back along the field by T * bulge * e, where e rises with the local slope,
            so a flat interior stays put. T = travel * TRAVEL_MAX * H texels. Read by manual bilinear from exact texels.
    extent  one step of mass transport, on luma: flux = -(u . grad L) - Lavg * T * div F, u = F * T. Ink carried into a slope piles up
            there, ink carried away from one starves it, and a converging field gathers ink. It is applied as a gain,
            P = c * exp(clamp(a * flux / max(Lavg, 0.02), -2.5, 1.6)), so ink keeps its own color and only its intensity changes, and
            it cannot go below 0 (Matt, 2026-11-09: the first form, per channel and additive, showed as black). Bypass and alpha end here.

Slopes are central differences over `span` texels (about 3 at 1080), so both effects work on smooth tone, where there are no marks.
With no field connected F is 0, and the module is exact identity. Output is unclamped (FR-010).

Constants are inferred from one frame of Matt's (plan ADR-9), tuned live: TRAVEL_MAX, EDGE_G0, SPAN_H.

`bug` values are mutations the tests must catch: "extent_sign", "no_div", "no_edge_weight", "bulge_backward", "travel_in_texels",
"no_field_zap", "per_channel".
"""
import numpy as np

F32 = np.float32
TRAVEL_MAX = 0.05       # travel = 1, in frame heights
EDGE_G0 = 7.0           # slope, per frame height, at which an edge counts as fully an edge
SPAN_H = 0.003          # the slope's half-span, in frame heights
LUMA = (0.2126, 0.7152, 0.0722)
LUMA_MIN = 0.02         # the gain's denominator never falls below this, so near-black cannot blow up
GAIN_LO, GAIN_HI = -2.5, 1.6    # exponent limits: at most about 12x thinner and 5x denser


def zap(x):
    return np.where(np.isfinite(x), x, F32(0)).astype(F32)


def span_tx(h):
    return float(max(1.0, np.floor(SPAN_H * h + 0.5)))


def field_uv(field, h, w, bug=None):
    """Signed (Fx, Fy) from an RG-encoded vecfield. None means unconnected: F = 0."""
    if field is None:
        z = np.zeros((h, w), F32)
        return z, z.copy()
    f = field[..., :2].astype(F32) if bug == "no_field_zap" else zap(field[..., :2])
    return ((f[..., 0] - F32(0.5)) * 2).astype(F32), ((f[..., 1] - F32(0.5)) * 2).astype(F32)


def tap(a, ix, iy, dx, dy):
    h, w = a.shape[:2]
    return a[np.clip(iy + dy, 0, h - 1), np.clip(ix + dx, 0, w - 1)]


def index_grid(h, w):
    iy, ix = np.mgrid[0:h, 0:w]
    return ix, iy


def slopes(c, ix, iy, s_int):
    """Central differences over the span, and the four taps' mean."""
    l, r = tap(c, ix, iy, -s_int, 0), tap(c, ix, iy, s_int, 0)
    d, u = tap(c, ix, iy, 0, -s_int), tap(c, ix, iy, 0, s_int)
    two = F32(2 * s_int)
    return ((r - l) / two).astype(F32), ((u - d) / two).astype(F32), ((l + r + d + u) * F32(0.25)).astype(F32)


def bilinear(c, x_c, y_c):
    """Read at continuous texel coordinates (texel centers at i + 0.5), clamped to the frame."""
    h, w = c.shape[:2]
    tx, ty = np.clip(x_c - F32(0.5), 0, w - 1).astype(F32), np.clip(y_c - F32(0.5), 0, h - 1).astype(F32)
    i0, j0 = np.floor(tx).astype(int), np.floor(ty).astype(int)
    ax, ay = (tx - i0).astype(F32), (ty - j0).astype(F32)
    i1, j1 = np.minimum(i0 + 1, w - 1), np.minimum(j0 + 1, h - 1)
    near = c[j0, i0] * (F32(1) - ax) + c[j0, i1] * ax
    far = c[j1, i0] * (F32(1) - ax) + c[j1, i1] * ax
    return (near * (F32(1) - ay) + far * ay).astype(F32)


def travel_tx(travel, h, bug=None):
    return F32(float(travel) * TRAVEL_MAX * (1080.0 if bug == "travel_in_texels" else h))


def bulge_stage(x, fx, fy, travel, bulge, bug=None):
    """x: H x W x 3."""
    h, w = x.shape[:2]
    ix, iy = index_grid(h, w)
    s = int(span_tx(h))
    d = travel_tx(travel, h, bug) * F32(bulge)
    if bug == "bulge_backward":
        d = -d
    out = np.zeros_like(x)
    for i in range(3):
        gx, gy, _ = slopes(x[..., i], ix, iy, s)
        e = F32(1) if bug == "no_edge_weight" else np.clip(np.sqrt(gx * gx + gy * gy) * F32(h) / F32(EDGE_G0), 0, 1).astype(F32)
        out[..., i] = bilinear(x[..., i], (ix + F32(0.5) - fx * d * e).astype(F32), (iy + F32(0.5) - fy * d * e).astype(F32))
    return out.astype(F32)


def extent_gain(c, fx, fy, t, tdiv, amount, s, ix, iy, bug=None):
    gx, gy, cavg = slopes(c, ix, iy, s)
    flux = F32(0) - (fx * t * gx + fy * t * gy) - cavg * tdiv
    expo = F32(amount) * flux / np.maximum(cavg, F32(LUMA_MIN))
    if bug == "extent_sign":
        expo = -expo
    return np.exp(np.clip(expo, F32(GAIN_LO), F32(GAIN_HI))).astype(F32)


def extent_stage(x, fx, fy, travel, amount, bug=None):
    """x: H x W x 3."""
    h, w = x.shape[:2]
    ix, iy = index_grid(h, w)
    s = int(span_tx(h))
    t = travel_tx(travel, h, bug)
    two = F32(2 * s)
    dfx = (tap(fx, ix, iy, s, 0) - tap(fx, ix, iy, -s, 0)) / two
    dfy = (tap(fy, ix, iy, 0, s) - tap(fy, ix, iy, 0, -s)) / two
    tdiv = t * (dfx + dfy) * (F32(0) if bug == "no_div" else F32(1))
    if bug == "per_channel":
        return np.stack([x[..., i] * extent_gain(x[..., i], fx, fy, t, tdiv, amount, s, ix, iy, bug) for i in range(3)], -1).astype(F32)
    luma = (x[..., 0] * F32(LUMA[0]) + x[..., 1] * F32(LUMA[1]) + x[..., 2] * F32(LUMA[2])).astype(F32)
    return (x * extent_gain(luma, fx, fy, t, tdiv, amount, s, ix, iy, bug)[..., None]).astype(F32)


def ink(x, field=None, travel=0.5, extent=0.0, bulge=0.0, bypass=0.0, bug=None):
    """x and field: H x W x 4 float32. Returns H x W x 4; RGB per channel, alpha from the source."""
    h, w = x.shape[:2]
    src = zap(x)
    fx, fy = field_uv(field, h, w, bug)
    moved = bulge_stage(src[..., :3], fx, fy, travel, bulge, bug)
    out = extent_stage(moved, fx, fy, travel, extent, bug)
    g = F32(bypass)
    return np.concatenate([(out * (F32(1) - g) + src[..., :3] * g).astype(F32), src[..., 3:]], axis=-1).astype(F32)
