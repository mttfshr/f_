"""halftone_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_halftone module (spec:
.specify/stable/f_halftone/spec.md, plan ADR-1 to ADR-7, tasks T017 and T016c). Float32, per pixel, stateless, in the order a codebox
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
  wins; jitter 0 tests one cell. (Dot only; a Line has no jitter.) Each jittered mark is clipped to its own displaced unit square
  (Matt, 2026-11-14, fix A): unclipped, a cell at tone >= 1 inked all nine cells around it, and near-full marks spilled over.
Threshold (ADR-6): smoothstep(level - w, level + w, tone), w = softness / 2, per pixel, no lattice. Bayer: 8 x 8 ordered matrix by texel,
  lit where tone > (M + .5) / 64; the 8 x 8 matrix repeats once per pitch (Matt, 2026-11-14): a cell is
  pitch / 8 frame heights, rounded to whole pixels, at least 1. bayer_read "cell" (default) reads one tone per cell at its
  centre pixel; "pixel" reads it per pixel (Matt, 2026-11-14: a toggle).
plate "channels": each of R, G, B is its own plate with its own angle and phase; the output channel is its coverage.
plate "single" (Matt, 2026-11-08, T016a): one plate with angle_b and phase_b; tone t = max(r, g, b) at the read texel, the colour
  rgb / t, output = colour * coverage; t <= 0 gives black.
Alpha is the source's. Non-finite input is zapped to 0 first (FR-011). Bypass passes the zapped source. src = None (nothing
connected) returns None: the build supplies black with alpha 0 (vs_black), which then screens to black.

`bug` values are mutations the tests must catch: "no_extremes", "no_zap", "wrong_area" ((2r)^2 instead of A(r)), "per_pixel_tone",
"ignore_phase", "shared_phase", "ignore_alpha", "single_reads_r", "line_centre_tone", "ignore_scale", "shared_scale",
"plates_shared_angle", "plates_no_clamp", "plates_read_src", "plates_alpha_src", "no_jitter_clip", "no_pitch_floor", and for Blue / Random /
Levels (T034): "levels_one_bit", "dither_shared_plate", "dither_ignore_phase", "blue_transposed",
"random_ignore_seed".

Blue and Random (Matt, 2026-11-14; spec US10, FR-023 to FR-026, ADR-10; T034, offline Claude, not built): Bayer's grain cell and
Read, the threshold from the shipped void-and-cluster file (Blue, 64 x 64, tiled) or the sin hash (Random) of the cell index
shifted by the plate offset, the seed and the phase in whole grain cells. Levels (US11, FR-027, ADR-11) quantize Bayer, Blue and
Random to L values; Dot, Line and Threshold ignore it.

Per-plate pitch scale (Matt, 2026-11-14; spec FR-022, T029a): each plate's pitch is pitch * scale (scales R, G, B; Single uses
scale B), formed in float32 as the codebox does; everything that follows the pitch (lattice, phase, edge ramp, jitter, Bayer
cell) follows the plate's own pitch.

plate "plates" (Matt, 2026-11-14; spec US9, FR-017 to FR-021, T027; offline Claude, not benched): `plates` holds inlets 1-3;
each is screened as Single at angle / phase / scale k (plate 1 the R set, 2 the G set, 3 the B set), the three summed and
clamped to 0..1; alpha the largest of the connected plates'; inlet 0 ignored except by bypass; None (unconnected) adds nothing.
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


_BLUE = None
DITHERS = ("bayer", "blue", "random")
PLATE_OFF = [(0, 0), (23, 41), (47, 13)]   # Blue / Random per-plate cell offsets (T033 spike; preliminary, Claude)
BLUE_SEED_STEP = (61, 29)                  # Blue: cells the pattern moves per seed step (preliminary, Claude)
SCREENS = {"dot": "dot", "line": "line", "threshold": "threshold", "bayer": "bayer", "blue": "blue", "random": "random"}


def bluenoise64():
    """The Blue screen's thresholds, (64, 64) float32 indexed [y, x], read from the shipped file (T033b; G14 decided by Matt
    2026-11-14). Made by build/generate_bluenoise.py; the module reads the same file through codebox input 5 (plan ADR-10)."""
    global _BLUE
    if _BLUE is None:
        import os
        import jxf
        root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
        _BLUE = jxf.read_jxf(os.path.join(root, "package", "media", "f_bluenoise64.jxf"))[..., 0]
    return _BLUE


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


def _quantize(tone, thr, levels, bug=None):
    """Levels (FR-027, ADR-11): q = tone (L - 1); out = (floor(q) + [fract(q) > thr]) / (L - 1), clamped, extremes exact.
    At L = 2 and tone < 1 this is tone > thr, today's one-bit dither, bit for bit (float32: q = tone * 1 exactly)."""
    L1 = F32(2 - 1) if bug == "levels_one_bit" else F32(int(levels) - 1)
    q = (tone * L1).astype(F32)
    fq = np.floor(q).astype(F32)
    out = np.clip((fq + ((q - fq) > thr).astype(F32)) / L1, 0, 1).astype(F32)
    # the clamp already gives exact extremes for thresholds in [0, 1) (tone <= 0: q <= 0; tone >= 1: q >= L - 1), so no
    # mutation can tell this line from its absence; kept because FR-027 names the rule and the codebox writes it out
    out = np.where(tone <= 0, F32(0), np.where(tone >= 1, F32(1), out))
    return out.astype(F32)


def dither_threshold(kind, ci, cj, *, plate_ix, seed, phase, bug=None):
    """The threshold of grain cell (ci, cj) for Bayer, Blue or Random (ADR-10). Bayer is unchanged from before Blue and Random
    (no plate offset, no phase, no seed). Blue and Random (FR-025; offsets preliminary, Claude, from the T033 spike): the cell
    index is shifted by the plate's offset, by the seed, and by the plate phase in whole grain cells (8 per pitch, rounded),
    so the marks move by +phase as the lattice screens' do."""
    if kind == "bayer":
        return ((bayer8_bits(ci, cj).astype(F32) + F32(0.5)) / F32(64)).astype(F32)
    ox, oy = (0, 0) if bug == "dither_shared_plate" else PLATE_OFF[plate_ix]
    if bug != "dither_ignore_phase":
        ox -= int(np.floor(F32(phase[0]) * F32(8) + F32(0.5)))
        oy -= int(np.floor(F32(phase[1]) * F32(8) + F32(0.5)))
    x, y = ci + ox, cj + oy
    if kind == "blue":
        sx, sy = BLUE_SEED_STEP
        x, y = x + sx * int(seed), y + sy * int(seed)
        B = bluenoise64()
        return (B.T if bug == "blue_transposed" else B)[np.mod(y, 64), np.mod(x, 64)].astype(F32)
    s = 0 if bug == "random_ignore_seed" else seed
    return hash2(x.astype(F32), y.astype(F32), s)[0]


def plate(read, W, H, *, kind, pitch, theta, phase, softness, shape, jitter, seed, level, tone_mode, bayer_read="cell", levels=2,
          plate_ix=0, bug=None):
    """One plate. read(i, j) -> tone at texel indices. Returns (coverage, i_read, j_read): the texel the tone came from."""
    if bug == "ignore_phase":
        phase = (0.0, 0.0)
    px, py, asp = _grid(W, H)
    ii, jj = np.meshgrid(np.arange(W), np.arange(H))
    if kind in DITHERS:
        sc = max(np.floor(F32(pitch) * F32(H) / F32(8) + F32(0.5)), 1)   # the matrix repeats once per pitch (Matt, 2026-11-14)
        ci, cj = np.floor(ii / sc).astype(np.int64), np.floor(jj / sc).astype(np.int64)
        thr = dither_threshold(kind, ci, cj, plate_ix=plate_ix, seed=seed, phase=phase, bug=bug)
        if bayer_read == "cell":      # Matt, 2026-11-14: one tone per cell, at its centre pixel (a true ordered dither)
            ri = np.minimum(ci * int(sc) + int(sc) // 2, W - 1)
            rj = np.minimum(cj * int(sc) + int(sc) // 2, H - 1)
        else:                         # "pixel": the tone per pixel, a threshold at each cell's level
            ri, rj = ii, jj
        tone = read(ri, rj)
        return _quantize(tone, thr, levels, bug), ri, rj
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
            if jitter > 0 and bug != "no_jitter_clip":
                # each mark lives only in its own (displaced) unit square, the square A(r) is defined on (Matt, 2026-11-14:
                # a full-tone neighbour inked the whole 3 x 3 block under jitter)
                cov = np.where(np.maximum(np.abs(fx), np.abs(fy)) > F32(0.5), F32(0), cov).astype(F32)
            if out_i is None:
                out_i, out_j = ti, tj
            take = cov > best
            best = np.where(take, cov, best)
            if dx == 0 and dy == 0:
                out_i, out_j = ti, tj
    return best.astype(F32), out_i, out_j


PITCH_FLOOR = 0.009   # T032 (Matt, 2026-11-14): Dot and Line only, frame heights (about 10 texels at 1080p)
LATTICE_SCREENS = ("dot", "line")


def _plate_pitch(pitch, scales, ch, bug=None, screen="dot"):
    """The plate's own pitch (FR-022): pitch * scale in float32, as the codebox forms it; Dot and Line floor it at
    PITCH_FLOOR (T032), the dithers are exact at any pitch."""
    if bug == "ignore_scale":
        return F32(pitch)
    sc = scales[0] if bug == "shared_scale" else scales[ch]
    p = F32(F32(pitch) * F32(sc))
    if screen in LATTICE_SCREENS and bug != "no_pitch_floor":
        p = max(p, F32(PITCH_FLOOR))
    return F32(p)


def _single(z, W, H, theta, phase, pitch, kw, plate_ix=2):
    """The Single path (T016a) on one texture: tone the brightest channel, colour normalised, output colour * coverage."""
    read = lambda i, j: np.max(z[j, i, :3], axis=-1)   # noqa: E731
    cov, ti, tj = plate(read, W, H, theta=theta, phase=phase, pitch=pitch, plate_ix=plate_ix, **kw)
    t = np.max(z[tj, ti, :3], axis=-1)
    col = np.where(t[..., None] > 0, z[tj, ti, :3] / np.maximum(t, F32(1e-12))[..., None], F32(0))
    return (col * cov[..., None]).astype(F32)


def halftone_stage(src, *, screen="dot", pitch=0.012, angles=(15.0, 75.0, 45.0), phases=((0, 0), (0, 0), (0, 0)), scales=(1.0, 1.0, 1.0),
                   softness=0.1, shape=0.0, jitter=0.0, seed=1, level=0.5, bayer_read="cell", plate_mode="channels",
                   levels=2, tone_mode="center", bypass=False, plates=(None, None, None), bug=None, collect=None):
    """src: (H, W, 4) float32 (R, G, B, A) or None (inlet 0). plates: three (H, W, 4) textures or None (inlets 1-3; read
    only in plate_mode "plates", None = unconnected). Returns (H, W, 4) float32, or None where the build supplies black.
    collect: a list of three, filled with each plate's (rgb term, alpha) as summed into the output, or None for a plate
    that is off (Single's R and G rows, an unconnected plate); used by halftone_outlets (US12)."""
    if plate_mode == "plates":
        return _plates_stage(src, plates, screen=screen, pitch=pitch, angles=angles, phases=phases, scales=scales,
                             softness=softness, shape=shape, jitter=jitter, seed=seed, level=level, bayer_read=bayer_read,
                             levels=levels, tone_mode=tone_mode, bypass=bypass, bug=bug, collect=collect)
    if src is None:
        return None
    src = np.asarray(src, dtype=F32)
    H, W = src.shape[:2]
    z = src if bug == "no_zap" else zap(src)
    if bypass:
        return z.astype(F32)
    out = np.zeros((H, W, 4), dtype=F32)
    kind = SCREENS[screen]
    kw = dict(kind=kind, softness=softness, shape=shape, jitter=jitter, seed=seed, level=level, bayer_read=bayer_read,
              tone_mode=tone_mode, levels=levels, bug=bug)
    if plate_mode == "single":
        ch = 0 if bug == "single_reads_r" else 2
        out[..., :3] = _single(z, W, H, angles[ch], phases[ch], _plate_pitch(pitch, scales, ch, bug, screen), kw, ch)
        if collect is not None:
            collect[2] = (out[..., :3].copy(), z[..., 3].copy())
    else:
        for ch in range(3):
            ph = phases[0] if bug == "shared_phase" else phases[ch]
            read = lambda i, j, ch=ch: z[j, i, ch]   # noqa: E731
            cov, _, _ = plate(read, W, H, theta=angles[ch], phase=ph, pitch=_plate_pitch(pitch, scales, ch, bug, screen), plate_ix=ch, **kw)
            out[..., ch] = cov
            if collect is not None:
                term = np.zeros((H, W, 3), F32)
                term[..., ch] = cov
                collect[ch] = (term, z[..., 3].copy())
    out[..., 3] = F32(1) if bug == "ignore_alpha" else z[..., 3]
    return out.astype(F32)


def _plates_stage(src, plates, *, screen, pitch, angles, phases, scales, softness, shape, jitter, seed, level, bayer_read,
                  levels, tone_mode, bypass, bug, collect=None):
    """Plates mode (spec US9, FR-017 to FR-021, plan ADR-8): plate k (inlet k + 1) is screened as Single at angle k, phase k
    and scale k; the three are summed and clamped to 0..1 (FR-019); alpha is the largest of the connected plates' alphas
    (FR-021); inlet 0 is ignored except by bypass, which passes it (P12; None, so the build's black, when it is empty).
    An unconnected plate (None) contributes nothing, colour or alpha (FR-020; the codebox skips it by its connected flag)."""
    if bypass:
        if src is None:
            return None
        z0 = np.asarray(src, dtype=F32)
        return (z0 if bug == "no_zap" else zap(z0)).astype(F32)
    plates = list(plates)
    if bug == "plates_read_src":
        plates[0] = src
    shapes = [np.asarray(p).shape[:2] for p in plates if p is not None]
    if not shapes:
        if src is None:
            return None
        shapes = [np.asarray(src).shape[:2]]
    H, W = shapes[0]
    out = np.zeros((H, W, 4), dtype=F32)
    kind = SCREENS[screen]
    kw = dict(kind=kind, softness=softness, shape=shape, jitter=jitter, seed=seed, level=level, bayer_read=bayer_read,
              tone_mode=tone_mode, levels=levels, bug=bug)
    for k, p in enumerate(plates):
        if p is None:
            continue
        p = np.asarray(p, dtype=F32)
        z = p if bug == "no_zap" else zap(p)
        ch = 2 if bug == "plates_shared_angle" else k
        term = _single(z, W, H, angles[ch], phases[ch], _plate_pitch(pitch, scales, ch, bug, screen), kw, ch)
        out[..., :3] += term
        out[..., 3] = np.maximum(out[..., 3], z[..., 3])
        if collect is not None:
            collect[k] = (term, z[..., 3].copy())
    if bug != "plates_no_clamp":
        out[..., :3] = np.clip(out[..., :3], 0, 1)
    if bug == "plates_alpha_src" and src is not None:
        out[..., 3] = zap(np.asarray(src, dtype=F32))[..., 3]
    return out.astype(F32)


def halftone_outlets(src, *, plate_out="gray", **kw):
    """Spec US12, FR-028 to FR-030: [outlet 0, plate outlet 1, 2, 3]. Outlet 0 is halftone_stage. Plate outlet k carries
    plate k's term as summed into outlet 0 (Color, unclamped) or (m, m, m) with m its brightest channel, the plate's
    coverage (Gray, default). Alpha: the source's (Channels, Single) or plate k's input (Plates). A plate that is off
    (Single's R and G rows, an unconnected plate) is black with alpha 0. Bypass: each plate outlet passes the part of the
    source that plate would screen (Channels: its channel; Single: the source on outlet 3; Plates: that plate's input).
    Extra mutations: "gray_from_r" (Gray from the red channel), "single_on_out1", "plate_alpha_src"."""
    bug = kw.get("bug")
    mode = kw.get("plate_mode", "channels")
    out0 = halftone_stage(src, **kw)
    terms = [None, None, None]
    if kw.get("bypass"):
        if mode == "plates":
            for k, p in enumerate(kw.get("plates", (None, None, None))):
                if p is not None:   # rgb not zapped, as the codebox (its capture budget, 2026-11-14); alpha zapped
                    z = np.asarray(p, dtype=F32)
                    terms[k] = (z[..., :3].copy(), zap(z)[..., 3].copy())
        elif src is not None:
            z = zap(np.asarray(src, dtype=F32))
            if mode == "single":
                terms[2] = (z[..., :3].copy(), z[..., 3].copy())
            else:
                for ch in range(3):
                    t = np.zeros(z.shape[:2] + (3,), F32)
                    t[..., ch] = z[..., ch]
                    terms[ch] = (t, z[..., 3].copy())
    else:
        halftone_stage(src, **{**kw, "collect": terms})
    if bug == "single_on_out1" and mode == "single":
        terms = [terms[2], None, None]
    if bug == "plate_alpha_src" and mode == "plates" and src is not None:
        za = zap(np.asarray(src, dtype=F32))[..., 3]
        terms = [None if t is None else (t[0], za) for t in terms]
    shape = next((t[0].shape[:2] for t in terms if t is not None), None)
    if shape is None:
        ref = out0 if out0 is not None else next((np.asarray(p) for p in kw.get("plates", ()) if p is not None), None)
        shape = ref.shape[:2] if ref is not None else (1, 1)
    outs = [out0]
    for t in terms:
        o = np.zeros(shape + (4,), F32)
        if t is not None:
            rgb, a = t
            if plate_out == "gray":
                m = rgb[..., 0] if bug == "gray_from_r" else np.max(rgb, axis=-1)
                o[..., :3] = m[..., None]
            else:
                o[..., :3] = rgb
            o[..., 3] = a
        outs.append(o.astype(F32))
    return outs

