"""ink_mirror.py -- tier-1 float32 NumPy mirror of the not-yet-built f_ink module (spec .specify/f_ink/spec.md, plan ADR-1 to
ADR-7, tasks T016-T017). P1 effects only: spread, edge pooling, mottle, dropout. Flecks, banding, channel gains and the two
driver inlets are P2 (T025-T027) and are added with their stages. Stateless, stage for stage, in the fixed order of FR-008.

Stages (each a codebox later, so bench_ink.py can diff them one by one):
    zap         non-finite input components to 0, BEFORE any blur (a NaN in a tap poisons a whole kernel).
    blur_pass   one separable pass: 15 tent taps at nearest texels, border by index clamp (G7).
    threshold   spread's re-threshold: S = smoothstep(0.5 - w/2 - bias, 0.5 + w/2 - bias, B), w = max(soften, SOFT_MIN),
                then mix(x, S, spread), so spread 0 is exact identity.
    pool        edge pooling, from a blur of S at pool_width: P = S + edge_pool * S * 2 * max(S - Bp, 0).
    fx_b        mottle, then dropout, then bypass.

Two departures from plan.md, both because the plan's text contradicts the spec (2026-11-08, offline; recorded in tasks.md):
  1. ADR-3's band 4 * Bp * (1 - Bp) is 1 on a flat 0.5 field, against FR-007 ("MUST leave flat areas unchanged"). The band
     here is S - Bp, which is 0 on any flat field. bug="plan_pool" is the plan's form.
  2. Zap at the source, not in fx_b (T022), because the blurs run first. bug="zap_late" is the plan's order.
  And the pool blur reads S, not in0, because FR-008 puts spread before pooling, so the rim follows the moved edge. That adds
  a stage (blur, blur, threshold, blur, blur, pool, fx_b = 7, plan said 6) and rules out reusing the spread blur (ADR-3 open).

Inferred choices the plan leaves open: the blend weight is `spread` itself; the offset of tap k is sign(k) * floor(|k| * stride
+ 0.5), symmetric, so a kernel has no drift; SOFT_MIN guards smoothstep at soften 0.

The hash is float32 sin, as the codebox will be, but a GPU sin differs from NumPy's in the low bits and the multiplier magnifies
that, so a bench can compare the patterns' statistics only, never their texels (inferred from the size of the multiplier).

Coordinates: texel centers, p = ((i + 0.5) / W * aspect, (j + 0.5) / H), one unit = one frame height. Row 0 is j = 0; which way
up that is on the GPU is for bench_ink.py to establish.

`bug` values are mutations the tests must catch: "plan_pool", "zap_late", "no_soften_guard", "dropout_negative", "pool_no_s",
"mottle_additive", "pool_from_source".
"""
import numpy as np

F32 = np.float32
SPREAD_CAP_H = 14.0 / 1080.0    # spread = 1, in frame heights (plan ADR-2; G5 / T009 still to settle it)
MAX_STRIDE = 2.0                # plan ADR-2; texels between taps
SOFT_MIN = 1e-3
HALF = 7
TENT = np.array([(HALF + 1 - abs(k)) / float((HALF + 1) ** 2) for k in range(-HALF, HALF + 1)], dtype=F32)
OCTAVE_WEIGHTS = (1.0, 0.5, 0.25)


def zap(x):
    return np.where(np.isfinite(x), x, F32(0)).astype(F32)


def tap_offsets(radius_tx):
    stride = min(float(radius_tx) / HALF, MAX_STRIDE)
    return [int(np.sign(k) * np.floor(abs(k) * stride + 0.5)) for k in range(-HALF, HALF + 1)]


def blur_pass(x, axis, radius_tx):
    n = x.shape[axis]
    out = np.zeros_like(x)
    for w, off in zip(TENT, tap_offsets(radius_tx)):
        idx = np.clip(np.arange(n) + off, 0, n - 1)
        out += w * np.take(x, idx, axis=axis)
    return out.astype(F32)


def blur2(x, radius_tx):
    return blur_pass(blur_pass(x, 1, radius_tx), 0, radius_tx)


def threshold(x, b, spread, bias, soften, bug=None):
    w = F32(soften if bug == "no_soften_guard" else max(soften, SOFT_MIN))
    e0, e1 = F32(0.5) - w / 2 - F32(bias), F32(0.5) + w / 2 - F32(bias)
    with np.errstate(divide="ignore", invalid="ignore"):
        t = np.clip((b - e0) / (e1 - e0), 0, 1)
    s = t * t * (3 - 2 * t)
    return (x * (F32(1) - F32(spread)) + s * F32(spread)).astype(F32)


def pool(s, bp, edge_pool, bug=None):
    a = F32(edge_pool)
    if bug == "plan_pool":
        c = np.clip(bp, 0, 1)
        return (s + a * s * 4 * c * (1 - c)).astype(F32)
    band = np.maximum(s - bp, 0)
    if bug == "pool_no_s":
        return (s + a * 2 * band + a * np.maximum(bp - s, 0)).astype(F32)
    return (s + a * s * 2 * band).astype(F32)


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


def mottle_field(px, py, scale, seed):
    total = np.zeros_like(px)
    for i, w in enumerate(OCTAVE_WEIGHTS):
        total += F32(w) * value_noise(px, py, F32(scale) / F32(2 ** i), F32(seed) + F32(i) * F32(17.0))
    return (total / F32(sum(OCTAVE_WEIGHTS))).astype(F32)


def fx_b(c, px, py, mottle, mottle_scale, dropout, tooth_scale, seed, bug=None):
    m = mottle_field(px, py, mottle_scale, seed)[..., None]
    if bug == "mottle_additive":
        c = (c + F32(mottle) * (m - F32(0.5)) * 2).astype(F32)
    else:
        c = (c * (F32(1) + F32(mottle) * (m - F32(0.5)) * 2)).astype(F32)
    tooth = value_noise(px, py, tooth_scale, F32(seed) + F32(101.0))[..., None]
    probe = c if bug == "dropout_negative" else np.maximum(c, 0)
    return np.where(probe < F32(dropout) * tooth, F32(0), c).astype(F32)


def ink(x, spread=0.0, bias=0.0, soften=0.2, edge_pool=0.0, pool_width=0.01, mottle=0.0, mottle_scale=0.15, dropout=0.0,
        tooth_scale=0.004, seed=1.0, bypass=0.0, bug=None):
    """x: H x W x 4 float32. Returns H x W x 4; RGB processed per channel, alpha from the source."""
    h, w = x.shape[:2]
    a = x[..., 3:].astype(F32)
    src = zap(x[..., :3]) if bug != "zap_late" else x[..., :3].astype(F32)
    with np.errstate(invalid="ignore"):
        b = blur2(src, float(spread) * SPREAD_CAP_H * h)
        s = threshold(src, b, spread, bias, soften, bug)
        bp = blur2(src if bug == "pool_from_source" else s, float(pool_width) * h)
        p = pool(s, bp, edge_pool, bug)
    px, py = coords(h, w)
    out = fx_b(p, px, py, mottle, mottle_scale, dropout, tooth_scale, seed, bug)
    if bug == "zap_late":
        out, src = zap(out), zap(src)
    g = F32(bypass)
    out = (out * (F32(1) - g) + src * g).astype(F32)
    return np.concatenate([out, zap(a)], axis=-1).astype(F32)
