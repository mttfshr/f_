"""ink_mirror.py -- tier-1 float32 NumPy mirror of the f_ink module (spec .specify/f_ink/spec.md, plan ADR-1 to ADR-8, tasks T016,
T017, T033, T034). P1 effects only: spread, edge pooling, mottle, dropout. Flecks, banding, channel gains and the two driver inlets
are P2 (T025-T027) and are added with their stages. Stateless, stage for stage, in the fixed order of FR-008.

Stages (each a codebox, so bench_ink.py can diff them one by one):
    zap         non-finite input components to 0, BEFORE any blur (a NaN in a tap poisons a whole kernel).
    blur_pass   one separable pass: 15 taps at nearest texels, tent weights set by the radius, border by index clamp (G7).
    threshold   spread's re-threshold: H = smoothstep(0.5 - w/2 - bias, 0.5 + w/2 - bias, B), w = max(soften, SOFT_MIN),
                then S = mix(B, H, snap * min(spread / SNAP_GATE, 1)). Snap 0 is a pure blur, which keeps continuous tone;
                snap 1 hardens the blur back into a mark (Matt, 2026-11-08). At spread 0 the blur is one tap, so S = x exactly.
    pool_blur   the blur of S that edge pooling reads: two H,V pairs, the second with taps 2 texels apart.
    pool        edge pooling (Matt, 2026-11-09, candidate C): the rim stays full and the body of the mark thins.
                rim = clamp(2 * max(S - Bp, 0) / max(S, 1e-3), 0, 1); P = S * ((1 - a) + a * rim).
                A rim that rose above 1 clipped on a screen, so it could not show on a full-value mark.
    fx_b        mottle (ink only thins, most where it is dense), then dropout (soft edges), then bypass.

Mottle and tooth read a field: the luma of an incoming texture when one is connected (Matt, 2026-11-09, FR-017), otherwise the
built-in noise (mottle candidate C, dropout candidate B, Claude, provisional).

Matt, 2026-11-08: the spread blur's taps are one texel apart (a spacing of 2 combs a 1-texel line). The pool blur may use 2 in its
second pair, because the first pair has already smoothed what would comb.

Inferred choices the plan leaves open: SNAP_GATE; SOFT_MIN guards smoothstep at soften 0; every noise constant here (tuned at T032).

The hash is float32 sin, as the codebox is, but a GPU sin differs from NumPy's in the low bits and the multiplier magnifies
that, so a bench can compare the patterns' statistics only, never their texels.

Coordinates: texel centers, p = ((i + 0.5) / W * aspect, (j + 0.5) / H), one unit = one frame height.

`bug` values are mutations the tests must catch: "pool_additive", "pool_no_norm", "zap_late", "no_soften_guard", "mottle_additive",
"pool_from_source", "snap_ignored", "field_ignored", "dropout_hard".
"""
import numpy as np

F32 = np.float32
SPREAD_CAP_H = 7.0 / 1080.0     # spread = 1, in frame heights: 7 texels at 1080 (Matt, 2026-11-08, stride 1)
MAX_RADIUS = 7.0                # the tent's largest radius, in tap spacings
POOL_STRIDE = 2                 # taps of the second pool pair, in texels
SOFT_MIN = 1e-3
SNAP_GATE = 0.125               # spread at which snap reaches full strength: a radius near 1 texel at 1080 (inferred)
HALF = 7
LUMA = (0.2126, 0.7152, 0.0722)
DROP_REACH = 1.35               # tooth at 1 and dropout at 1 reach above a solid, so solids can take pinholes
DROP_EDGE = 0.10                # half-width of the soft edge
DROP_GATE = 0.05                # dropout below this fades the whole effect in, so dropout 0 is exact identity


def zap(x):
    return np.where(np.isfinite(x), x, F32(0)).astype(F32)


def tap_weights(radius_tx):
    """Taps at the fixed offsets -7..7; the radius only changes the weights: a tent of half-width r + 1, normalized. r = 0 is one
    tap of weight 1, and the weights move continuously with the dial."""
    r = min(float(radius_tx), MAX_RADIUS)
    w = np.array([max(0.0, 1.0 - abs(k) / (r + 1.0)) for k in range(-HALF, HALF + 1)], dtype=np.float64)
    return (w / w.sum()).astype(F32)


def blur_pass(x, axis, radius_tx, stride=1):
    n = x.shape[axis]
    out = np.zeros_like(x)
    for w, off in zip(tap_weights(radius_tx), range(-HALF, HALF + 1)):
        if w == 0:
            continue
        idx = np.clip(np.arange(n) + off * stride, 0, n - 1)
        out += w * np.take(x, idx, axis=axis)
    return out.astype(F32)


def blur2(x, radius_tx, stride=1):
    return blur_pass(blur_pass(x, 1, radius_tx, stride), 0, radius_tx, stride)


def pool_blur(s, width_tx):
    """Two H,V pairs. The dial's width in texels is shared out as q + 2q, so the reach is 21 texels at most."""
    q = float(width_tx) / 3.0
    return blur2(blur2(s, q), q, POOL_STRIDE)


def sstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0, 1)
    return (t * t * (3 - 2 * t)).astype(F32)


def threshold(b, spread, snap, bias, soften, bug=None):
    w = F32(soften if bug == "no_soften_guard" else max(soften, SOFT_MIN))
    e0, e1 = F32(0.5) - w / 2 - F32(bias), F32(0.5) + w / 2 - F32(bias)
    with np.errstate(divide="ignore", invalid="ignore"):
        t = np.clip((b - e0) / (e1 - e0), 0, 1)
    s = t * t * (3 - 2 * t)
    amount = F32(1) if bug == "snap_ignored" else F32(snap)
    gate = F32(min(float(spread) / SNAP_GATE, 1.0))
    return (b * (F32(1) - amount * gate) + s * (amount * gate)).astype(F32)


def pool(s, bp, edge_pool, bug=None):
    a = F32(edge_pool)
    if bug == "pool_additive":
        return (s + a * s * 2 * np.maximum(s - bp, 0)).astype(F32)
    band = np.maximum(s - bp, 0)
    rim = np.clip(2 * band if bug == "pool_no_norm" else 2 * band / np.maximum(s, F32(1e-3)), 0, 1)
    return (s * ((F32(1) - a) + a * rim)).astype(F32)


def coords(h, w):
    aspect = F32(w) / F32(h)
    px = ((np.arange(w, dtype=F32) + F32(0.5)) / F32(w) * aspect)
    py = (np.arange(h, dtype=F32) + F32(0.5)) / F32(h)
    return np.meshgrid(px, py)


def hash2(ix, iy, seed):
    v = np.sin(ix.astype(F32) * F32(127.1) + iy.astype(F32) * F32(311.7) + F32(seed)) * F32(43758.5453)
    return (v - np.floor(v)).astype(F32)


def value_noise(px, py, scale, seed):
    s = F32(max(scale, 1e-5))
    gx, gy = px / s, py / s
    ix, iy = np.floor(gx), np.floor(gy)
    fx, fy = gx - ix, gy - iy
    ux, uy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy, seed), hash2(ix + 1, iy, seed)
    c, d = hash2(ix, iy + 1, seed), hash2(ix + 1, iy + 1, seed)
    return ((a + (b - a) * ux) + ((c + (d - c) * ux) - (a + (b - a) * ux)) * uy).astype(F32)


def fbm(px, py, scale, seed, octaves, gain):
    """Octaves on rotated lattices (0.7, 1.8, 2.9 radians), so no octave's grid lines up with the frame or with another's."""
    total, amp, norm = np.zeros_like(px), 1.0, 0.0
    for i in range(octaves):
        ang = 0.7 + 1.1 * i
        c, n = F32(np.cos(ang)), F32(np.sin(ang))
        total += F32(amp) * value_noise((px * c - py * n).astype(F32), (px * n + py * c).astype(F32), F32(scale) / F32(2 ** i), F32(seed) + F32(i) * F32(17.0))
        norm += amp
        amp *= gain
    return (total / F32(norm)).astype(F32)


def stretch(n, k):
    return np.clip((n - F32(0.5)) * F32(k) + F32(0.5), 0, 1).astype(F32)


def builtin_mottle(px, py, scale, seed):
    """Fine speckle at a tenth of the scale, in slow patches at the scale."""
    speck = stretch(fbm(px, py, F32(scale) * F32(0.1), seed, 3, 0.6), 1.9)
    broad = stretch(fbm(px, py, scale, F32(seed) + F32(200.0), 2, 0.5), 1.8)
    return np.clip(speck * F32(0.6) + broad * F32(0.55) - F32(0.05), 0, 1).astype(F32)


def builtin_tooth(px, py, scale, seed):
    """Two rotated octaves plus a cell hash at a third of the scale: fine grain with no lattice to see."""
    cell = F32(max(scale, 1e-5)) / F32(3.0)
    white = hash2(np.floor(px / cell), np.floor(py / cell), F32(seed) + F32(300.0))
    n = fbm(px, py, scale, F32(seed) + F32(101.0), 2, 0.7)
    return stretch(n * F32(0.7) + white * F32(0.3), 2.6)


def field_luma(t):
    """An incoming field: non-finite values zapped, luma of RGB, held to 0..1."""
    z = zap(t[..., :3])
    return np.clip(z[..., 0] * F32(LUMA[0]) + z[..., 1] * F32(LUMA[1]) + z[..., 2] * F32(LUMA[2]), 0, 1).astype(F32)


def fx_b(c, px, py, mottle, mottle_scale, dropout, tooth_scale, seed, mottle_field=None, tooth_field=None, bug=None):
    use_m = mottle_field is not None and bug != "field_ignored"
    n = field_luma(mottle_field) if use_m else builtin_mottle(px, py, mottle_scale, seed)
    n = n[..., None]
    if bug == "mottle_additive":
        thinned = (c + F32(mottle) * (n - F32(0.5)) * 2).astype(F32)
    else:
        thinned = (c * (F32(1) - F32(mottle) * n * sstep(F32(0.15), F32(0.9), c))).astype(F32)
    t = (field_luma(tooth_field) if tooth_field is not None else builtin_tooth(px, py, tooth_scale, seed))[..., None]
    gate = F32(min(float(dropout) / DROP_GATE, 1.0))
    th = F32(DROP_REACH) * F32(dropout) * t
    w = max(float(DROP_EDGE) * float(gate), 1e-4)
    probe = np.maximum(thinned, 0)
    keep = (probe >= th).astype(F32) if bug == "dropout_hard" else sstep(th - F32(w), th + F32(w), probe)
    return (thinned * (F32(1) - (F32(1) - keep) * gate)).astype(F32)


def ink(x, spread=0.0, snap=1.0, bias=0.0, soften=0.2, edge_pool=0.0, pool_width=0.014, mottle=0.0, mottle_scale=0.045, dropout=0.0,
        tooth_scale=0.003, seed=1.0, bypass=0.0, mottle_field=None, tooth_field=None, bug=None):
    """x: H x W x 4 float32; the fields are H x W x 4 when given. Returns H x W x 4; RGB processed per channel, alpha from the source."""
    h, w = x.shape[:2]
    a = x[..., 3:].astype(F32)
    src = zap(x[..., :3]) if bug != "zap_late" else x[..., :3].astype(F32)
    with np.errstate(invalid="ignore"):
        b = blur2(src, float(spread) * SPREAD_CAP_H * h)
        s = threshold(b, spread, snap, bias, soften, bug)
        bp = pool_blur(src if bug == "pool_from_source" else s, float(pool_width) * h)
        p = pool(s, bp, edge_pool, bug)
    px, py = coords(h, w)
    out = fx_b(p, px, py, mottle, mottle_scale, dropout, tooth_scale, seed, mottle_field, tooth_field, bug)
    if bug == "zap_late":
        out, src = zap(out), zap(src)
    g = F32(bypass)
    out = (out * (F32(1) - g) + src * g).astype(F32)
    return np.concatenate([out, zap(a)], axis=-1).astype(F32)
