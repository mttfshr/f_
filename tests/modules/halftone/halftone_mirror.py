"""halftone_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_halftone module (spec:
.specify/f_halftone/spec.md, plan ADR-1 to ADR-7, tasks T017 and T016c). Float32, per pixel, stateless, in the order a codebox
would compute it. Written 2026-11-13 (Claude, offline); nothing here has been run on a bench, and the preliminary
decisions it follows (P1 per-cell tone, G2 frame-height units, G6 centre rotation) are the spec's.

Conventions of THIS mirror (the codebox must match them; tier 2 checks):
  texel (i, j) has uv = ((i + .5) / W, (j + .5) / H); v grows with the row index j.
  position p = ((u - .5) * aspect, v - .5), aspect = W / H, in frame heights (G2, P10).
  lattice q = R(-theta) p / pitch - phase   (theta = the plate's angle; phase in pitches, FR-016: the plate's marks move by +phase)
  cell c = floor(q + .5), local f = q - c in [-.5, .5]^2; the cell's centre in q is c (plus jitter).
Spot functions (ADR-2): Dot T = A(r) (area of the radius-r circle inside the unit cell; exact above r = .5), Line T = 2|f_y|,
  Square T = (2 max(|f_x|, |f_y|))^2, shape morph mix(T_round, T_square, shape). A pixel is inked where T < tone.
Soft edge (ADR-3): coverage = clamp(.5 + (tone - T) / w, 0, 1), w = max(softness / 2, aa) * |dT/dd|, aa = 1 / (pitch in texels);
  then tone <= 0 gives exactly 0 and tone >= 1 exactly 1.
Tone (ADR-4, P1): Dot reads once at the cell centre (nearest texel), `tone_mode="avg"` is the G4 alternative (a 4 x 4 average
  over the cell, 16 taps); Line reads at the pixel's own position along its centreline row.
Jitter (ADR-5): each cell centre moves by jitter * .25 * 2 * (hash - .5) cells; nine cells are tested and the maximum coverage
  wins; jitter 0 tests one cell. (Dot only; a Line has no jitter.)
Threshold (ADR-6): smoothstep(level - w, level + w, tone), w = softness / 2, per pixel, no lattice. Bayer: 8 x 8 ordered matrix by texel,
  lit where tone > (M + .5) / 64; bayer_scale (Matt, 2026-11-14) rounds to whole pixels per matrix cell, the tone stays per pixel.
plate "channels": each of R, G, B is its own plate with its own angle and phase; the output channel is its coverage.
plate "single" (Matt, 2026-11-08, T016a): one plate with angle_b and phase_b; tone t = max(r, g, b) at the read texel, the colour
  rgb / t, output = colour * coverage; t <= 0 gives black.
Alpha is the source's. Non-finite input is zapped to 0 first (FR-011). Bypass passes the zapped source. src = None (nothing
connected) returns None: the build supplies black with alpha 0 (vs_black), which then screens to black.

`bug` values are mutations the tests must catch: "no_extremes", "no_zap", "wrong_area" ((2r)^2 instead of A(r)), "per_pixel_tone",
"ignore_phase", "shared_phase", "ignore_alpha", "single_reads_r", "line_centre_tone".
"""
import numpy as np

F32 = np.float32
SQRT_HALF = F32(np.sqrt(0.5))


def zap(x):
    return np.where(np.isfinite(x), x, F32(0)).astype(F32)


def smoothstep(a, b, x):
    t = np.clip((x - a) / np.maximum(b - a, F32(1e-12)), 0, 1).astype(F32)
    return (t * t * (F32(3) - F32(2) * t)).astype(F32)


def area_round(r):
    """A(r): the area of a radius-r circle inside the unit square centred on it (ADR-2). 1 beyond r = sqrt(1/2)."""
    r = np.asarray(r, dtype=F32)
    rc = np.minimum(r, SQRT_HALF)
    inner = F32(np.pi) * rc * rc
    over = rc > F32(0.5)
    ac = np.arccos(np.clip(F32(1) / (F32(2) * np.maximum(rc, F32(1e-6))), 0, 1))
    seg = rc * rc * ac - F32(0.5) * np.sqrt(np.maximum(rc * rc - F32(0.25), 0))
    a = np.where(over, inner - F32(4) * seg, inner)
    return np.where(r >= SQRT_HALF, F32(1), a).astype(F32)


def area_round_slope(r):
    """dA/dr: the circle's perimeter inside the cell (ADR-2)."""
    r = np.asarray(r, dtype=F32)
    rc = np.minimum(r, SQRT_HALF)
    ac = np.arccos(np.clip(F32(1) / (F32(2) * np.maximum(rc, F32(1e-6))), 0, 1))
    d = np.where(rc <= F32(0.5), F32(2 * np.pi) * rc, rc * (F32(2 * np.pi) - F32(8) * ac))
    return np.where(r >= SQRT_HALF, F32(0), d).astype(F32)


def bayer8_recursive():
    m = np.zeros((1, 1), dtype=np.int64)
    d = np.array([[0, 2], [3, 1]], dtype=np.int64)
    for _ in range(3):
        m = np.block([[4 * m + d[0, 0], 4 * m + d[0, 1]], [4 * m + d[1, 0], 4 * m + d[1, 1]]])
    return m


def bayer8_bits(x, y):
    """The bit-interleave form the codebox will use: M = sum over b of 4^(2-b) * (2 (bx xor by) + by)."""
    x = np.asarray(x, dtype=np.int64) & 7
    y = np.asarray(y, dtype=np.int64) & 7
    m = np.zeros(np.broadcast(x, y).shape, dtype=np.int64)
    for b in range(3):
        bx = (x >> b) & 1
        by = (y >> b) & 1
        m = m + (4 ** (2 - b)) * (2 * (bx ^ by) + by)
    return m


def hash2(nx, ny, seed):
    """Two hashes in 0..1 from a cell (the sin hash: noise() is black on this path)."""
    def h(a, b, c):
        s = np.sin((nx * F32(a) + ny * F32(b) + F32(seed) * F32(c)).astype(F32)) * F32(43758.5453)
        return (s - np.floor(s)).astype(F32)
    return h(127.1, 311.7, 74.7), h(269.5, 183.3, 246.1)


def _cs(theta_deg):
    k = round(theta_deg / 90.0)
    if abs(theta_deg - 90.0 * k) < 1e-9:   # exact at multiples of 90 (G6)
        return F32([1, 0, -1, 0][k % 4] ), F32([0, 1, 0, -1][k % 4])
    t = F32(np.deg2rad(theta_deg))
    return F32(np.cos(t)), F32(np.sin(t))


def _grid(W, H):
    u = ((np.arange(W, dtype=F32) + F32(0.5)) / F32(W))[None, :] * np.ones((H, 1), dtype=F32)
    v = ((np.arange(H, dtype=F32) + F32(0.5)) / F32(H))[:, None] * np.ones((1, W), dtype=F32)
    asp = F32(W) / F32(H)
    return ((u - F32(0.5)) * asp).astype(F32), (v - F32(0.5)).astype(F32), asp


def _spot(fx, fy, shape, kind):
    """(T, dT/dd) of the spot function at local lattice coordinates."""
    if kind == "line":
        return (F32(2) * np.abs(fy)).astype(F32), np.full(fx.shape, F32(2), dtype=F32)
    r = np.sqrt(fx * fx + fy * fy).astype(F32)
    tr, dr = area_round(r), area_round_slope(r)
    if shape <= 0:
        return tr, dr
    m = np.maximum(np.abs(fx), np.abs(fy))
    ts = ((F32(2) * m) ** 2).astype(F32)
    ds = (F32(8) * m).astype(F32)
    s = F32(shape)
    return (tr + (ts - tr) * s).astype(F32), (dr + (ds - dr) * s).astype(F32)


def _cover(T, dT, tone, softness, aa, extremes=True):
    w = np.maximum(F32(softness) * F32(0.5), F32(aa)) * np.maximum(np.abs(dT), F32(1e-6))
    c = np.clip(F32(0.5) + (tone - T) / w, 0, 1).astype(F32)
    if extremes:
        c = np.where(tone <= 0, F32(0), np.where(tone >= 1, F32(1), c))
    return c.astype(F32)


def plate(read, W, H, *, kind, pitch, theta, phase, softness, shape, jitter, seed, level, tone_mode, bayer_scale=1.0, bug=None):
    """One plate. read(i, j) -> tone at texel indices. Returns (coverage, i_read, j_read): the texel the tone came from."""
    if bug == "ignore_phase":
        phase = (0.0, 0.0)
    px, py, asp = _grid(W, H)
    ii, jj = np.meshgrid(np.arange(W), np.arange(H))
    if kind == "bayer":
        sc = max(np.floor(F32(bayer_scale) + F32(0.5)), 1)   # whole pixels per matrix cell (Matt, 2026-11-14); the tone stays per pixel
        m = bayer8_bits(np.floor(ii / sc).astype(np.int64), np.floor(jj / sc).astype(np.int64))
        tone = read(ii, jj)
        return (tone > (m.astype(F32) + F32(0.5)) / F32(64)).astype(F32), ii, jj
    if kind == "threshold":
        tone = read(ii, jj)
        w = F32(softness) * F32(0.5)
        c = smoothstep(F32(level) - w, F32(level) + w, tone) if w > 0 else (tone > F32(level)).astype(F32)
        return c.astype(F32), ii, jj
    c, s = _cs(theta)
    pitch = F32(pitch)
    qx = ((c * px + s * py) / pitch - F32(phase[0])).astype(F32)
    qy = ((-s * px + c * py) / pitch - F32(phase[1])).astype(F32)
    aa = F32(1) / (pitch * F32(H))

    def texel(x, y):
        xx, yy = x + F32(phase[0]), y + F32(phase[1])
        ppx = (c * xx - s * yy) * pitch
        ppy = (s * xx + c * yy) * pitch
        u = ppx / asp + F32(0.5)
        v = ppy + F32(0.5)
        return (np.clip(np.floor(u * F32(W)), 0, W - 1).astype(int), np.clip(np.floor(v * F32(H)), 0, H - 1).astype(int))

    cx, cy = np.floor(qx + F32(0.5)).astype(F32), np.floor(qy + F32(0.5)).astype(F32)
    if kind == "line":
        fy = (qy - cy).astype(F32)
        if bug == "line_centre_tone":
            ti, tj = texel(cx, cy)
        else:
            ti, tj = texel(qx, cy)              # the pixel's own position along the line, on its centreline row
        tone = read(ti, tj)
        T, dT = _spot(np.zeros_like(fy), fy, 0, "line")
        return _cover(T, dT, tone, softness, aa, bug != "no_extremes"), ti, tj
    # dot
    best = np.zeros((H, W), dtype=F32)
    out_i, out_j = None, None
    rng = (-1, 0, 1) if jitter > 0 else (0,)
    for dy in rng:
        for dx in rng:
            nx, ny = cx + F32(dx), cy + F32(dy)
            if jitter > 0:
                hx, hy = hash2(nx, ny, seed)
                gx = nx + F32(jitter) * F32(0.25) * F32(2) * (hx - F32(0.5))
                gy = ny + F32(jitter) * F32(0.25) * F32(2) * (hy - F32(0.5))
            else:
                gx, gy = nx, ny
            fx, fy = (qx - gx).astype(F32), (qy - gy).astype(F32)
            ti, tj = texel(gx, gy)
            if bug == "per_pixel_tone":
                ti, tj = ii, jj
            if tone_mode == "avg":
                k = 4
                acc = np.zeros((H, W), dtype=F32)
                for a in range(k):
                    for b in range(k):
                        ai, aj = texel(gx + F32((a + 0.5) / k - 0.5), gy + F32((b + 0.5) / k - 0.5))
                        acc = acc + read(ai, aj)
                tone = (acc / F32(k * k)).astype(F32)
            else:
                tone = read(ti, tj)
            T, dT = _spot(fx, fy, shape, "dot")
            if bug == "wrong_area":
                T = ((F32(2) * np.sqrt(fx * fx + fy * fy)) ** 2).astype(F32)
                dT = (F32(8) * np.sqrt(fx * fx + fy * fy)).astype(F32)
            cov = _cover(T, dT, tone, softness, aa, bug != "no_extremes")
            if out_i is None:
                out_i, out_j = ti, tj
            take = cov > best
            best = np.where(take, cov, best)
            if dx == 0 and dy == 0:
                out_i, out_j = ti, tj
    return best.astype(F32), out_i, out_j


def halftone_stage(src, *, screen="dot", pitch=0.012, angles=(15.0, 75.0, 45.0), phases=((0, 0), (0, 0), (0, 0)),
                   softness=0.1, shape=0.0, jitter=0.0, seed=1, level=0.5, bayer_scale=1.0, plate_mode="channels",
                   tone_mode="center", bypass=False, bug=None):
    """src: (H, W, 4) float32 (R, G, B, A) or None. Returns (H, W, 4) float32."""
    if src is None:
        return None
    src = np.asarray(src, dtype=F32)
    H, W = src.shape[:2]
    z = src if bug == "no_zap" else zap(src)
    if bypass:
        return z.astype(F32)
    out = np.zeros((H, W, 4), dtype=F32)
    kind = {"dot": "dot", "line": "line", "threshold": "threshold", "bayer": "bayer"}[screen]
    kw = dict(kind=kind, pitch=pitch, softness=softness, shape=shape, jitter=jitter, seed=seed, level=level, bayer_scale=bayer_scale,
              tone_mode=tone_mode, bug=bug)
    if plate_mode == "single":
        ch = 0 if bug == "single_reads_r" else 2
        th, ph = angles[ch], phases[ch]
        read = lambda i, j: np.max(z[j, i, :3], axis=-1)   # noqa: E731
        cov, ti, tj = plate(read, W, H, theta=th, phase=ph, **kw)
        t = np.max(z[tj, ti, :3], axis=-1)
        col = np.where(t[..., None] > 0, z[tj, ti, :3] / np.maximum(t, F32(1e-12))[..., None], F32(0))
        out[..., :3] = (col * cov[..., None]).astype(F32)
    else:
        for ch in range(3):
            ph = phases[0] if bug == "shared_phase" else phases[ch]
            read = lambda i, j, ch=ch: z[j, i, ch]   # noqa: E731
            cov, _, _ = plate(read, W, H, theta=angles[ch], phase=ph, **kw)
            out[..., ch] = cov
    out[..., 3] = F32(1) if bug == "ignore_alpha" else z[..., 3]
    return out.astype(F32)
