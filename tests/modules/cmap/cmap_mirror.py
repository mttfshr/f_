"""
cmap_mirror.py -- NumPy mirror of the settled f_cmap model (.specify/f_cmap/spec.md, "Settled
model"), written BEFORE the codebox exists. The mirror is the spec in executable form; T020 writes
the codebox against it and the bench diffs the GPU against it.

One frame is a pure function of the previous frame, the live source and the Params:

    p        texel-centre norm coordinate of the output pixel (gpu_sim convention: (i + 0.5) / dim)
    q        = ((p.x - 0.5) * aspect, p.y - 0.5)       isometric, centred, frame-HEIGHT units
    z        = 2 L q                                    L = 1.75 (the webgpgpu SCALE)
    z'       = z^n + w                                  complex, n by repeated multiplication
    q'       = z' / (2 L)
    p'       = (q'.x / aspect + 0.5, q'.y + 0.5)        where to read the previous frame
    inside   = 0 <= p'.x <= 1 and 0 <= p'.y <= 1        the frame RECTANGLE (gate G2, proposed)
    hist     = prev(p') if inside else the bounds rule:
                 "source"  the live source at this pixel (the replacement for the webgpgpu checker)
                 "black"   0
                 "wrap"    prev(fract(p')), taps wrapped too (a torus)
    out      = decay * hist * (1 - inject) + src * inject          RGB; alpha = 1

Offset (spec: patcher clock, `rate` 0 freezes it exactly), per FRAME:
    theta = 2 pi (angle + rate * f),  phase = 2 pi sqrt(2) rate * f,  |w| = radius + sweep cos(phase)
    w     = |w| (cos theta, sin theta)
The webgpgpu source steps theta and phase by 0.01 rad and 0.01 sqrt(2) rad per frame, so its
`rate` is 0.01 / (2 pi) turns per frame; `radius` 0.15, `sweep` 1.5.

Conventions decided here (open in the spec; see tasks.md record):
  - The inside test is the closed rectangle on the NORMALISED sample position, so a pulled position
    exactly on an edge is inside (a knife edge: the tests avoid it).
  - "wrap" taps are periodic. On the GPU a bare sample() wraps the COORDINATE but clamps its taps
    (gpu_sim docstring), so at the seam a texel's worth of difference is possible unless the codebox
    fetches its own taps: a T020 decision, not made here.
  - Catmull-Rom is the standard a = 0.5 form, 16 taps, unclamped (it can overshoot the input range).
  - All textures are (H, W, 4); RGB is processed, alpha is forced to 1.

`bug` values are the mutations the tests must catch:
  "aspect_not_undone"  p' = q' + 0.5 (the aspect applied going in and not undone coming out),
  "n_off"              z^(n+1),
  "swap_xy"            p' = (q'.y / aspect + 0.5, q'.x + 0.5),
  "centre_off"         norm = i / dim (no texel-centre half step, GenExpr `cell`-style),
  "w_sign"             the offset is subtracted.
"""
import numpy as np

L = 1.75
SQRT2 = 1.4142135623730951
TWOPI = 2.0 * np.pi
RATE_SOURCE = 0.01 / TWOPI            # turns per frame in the webgpgpu examples
BUGS = ("aspect_not_undone", "n_off", "swap_xy", "centre_off", "w_sign")
SAMPLERS = ("nearest", "bilinear", "catmull")
BOUNDS = ("source", "black", "wrap")


# --- the offset ----------------------------------------------------------------------------

def offset(f, rate=RATE_SOURCE, angle=0.0, radius=0.15, sweep=0.0):
    """w at frame f (float or int): rate in turns per frame, angle in turns."""
    theta = TWOPI * (angle + rate * f)
    phase = TWOPI * SQRT2 * rate * f
    m = radius + sweep * np.cos(phase)
    return (float(m * np.cos(theta)), float(m * np.sin(theta)))


# --- the map -------------------------------------------------------------------------------

def centred_p(h, w, dtype=np.float64, bug=None):
    """Texel-centre norm coordinates, arrays (h, w): x varies along axis 1."""
    c = np.dtype(dtype).type
    half = c(0.0) if bug == "centre_off" else c(0.5)
    px = (np.arange(w, dtype=c) + half) / c(w)
    py = (np.arange(h, dtype=c) + half) / c(h)
    return np.meshgrid(px, py)


def pull_point(px, py, aspect, n=2, w=(0.15, 0.0), bug=None):
    """Where the pull reads: the sample position p' for norm coordinates p (arrays or scalars)."""
    px = np.asarray(px)
    py = np.asarray(py)
    c = px.dtype.type
    A = c(aspect)
    two_l = c(2.0 * L)
    qx = (px - c(0.5)) * A
    qy = py - c(0.5)
    zx, zy = qx * two_l, qy * two_l
    rx, ry = zx, zy
    for _ in range((n + 1 if bug == "n_off" else n) - 1):
        rx, ry = rx * zx - ry * zy, rx * zy + ry * zx
    wx, wy = (-w[0], -w[1]) if bug == "w_sign" else w
    qpx = (rx + c(wx)) / two_l
    qpy = (ry + c(wy)) / two_l
    if bug == "swap_xy":
        return qpy / A + c(0.5), qpx + c(0.5)
    if bug == "aspect_not_undone":
        return qpx + c(0.5), qpy + c(0.5)
    return qpx / A + c(0.5), qpy + c(0.5)


def inside(ppx, ppy):
    return (ppx >= 0) & (ppx <= 1) & (ppy >= 0) & (ppy <= 1)


# --- samplers (texel-centre convention, as gpu_sim) ----------------------------------------

def _fetch(tex, ix, iy, wrap):
    h, w = tex.shape[:2]
    if wrap:
        return tex[np.mod(iy, h), np.mod(ix, w)]
    return tex[np.clip(iy, 0, h - 1), np.clip(ix, 0, w - 1)]


def nearest(tex, u, v, wrap=False):
    h, w = tex.shape[:2]
    return _fetch(tex, np.floor(u * w).astype(np.int64), np.floor(v * h).astype(np.int64), wrap)


def bilinear(tex, u, v, wrap=False):
    h, w = tex.shape[:2]
    x = u * w - 0.5
    y = v * h - 0.5
    x0, y0 = np.floor(x), np.floor(y)
    fx, fy = (x - x0)[..., None], (y - y0)[..., None]
    ix, iy = x0.astype(np.int64), y0.astype(np.int64)
    top = _fetch(tex, ix, iy, wrap) * (1 - fx) + _fetch(tex, ix + 1, iy, wrap) * fx
    bot = _fetch(tex, ix, iy + 1, wrap) * (1 - fx) + _fetch(tex, ix + 1, iy + 1, wrap) * fx
    return top * (1 - fy) + bot * fy


def _cr_weights(t):
    t2 = t * t
    t3 = t2 * t
    return (-0.5 * t3 + t2 - 0.5 * t, 1.5 * t3 - 2.5 * t2 + 1.0,
            -1.5 * t3 + 2.0 * t2 + 0.5 * t, 0.5 * t3 - 0.5 * t2)


def catmull(tex, u, v, wrap=False):
    h, w = tex.shape[:2]
    x = u * w - 0.5
    y = v * h - 0.5
    x0, y0 = np.floor(x), np.floor(y)
    wx = _cr_weights(x - x0)
    wy = _cr_weights(y - y0)
    ix, iy = x0.astype(np.int64), y0.astype(np.int64)
    out = 0.0
    for j in range(4):
        row = 0.0
        for i in range(4):
            row = row + _fetch(tex, ix + (i - 1), iy + (j - 1), wrap) * wx[i][..., None]
        out = out + row * wy[j][..., None]
    return out


_SAMPLER = {"nearest": nearest, "bilinear": bilinear, "catmull": catmull}


# --- one frame and a run -------------------------------------------------------------------

def frame(prev, src, n=2, w=(0.15, 0.0), decay=0.97, inject=0.05, bounds="source",
          sampler="bilinear", bug=None, detail=False):
    """One ping-pong step. prev, src: (H, W, 4) of the same float dtype."""
    h, wd = prev.shape[:2]
    c = prev.dtype.type
    px, py = centred_p(h, wd, prev.dtype, bug)
    ppx, ppy = pull_point(px, py, wd / h, n, w, bug)
    ins = inside(ppx, ppy)
    fn = _SAMPLER[sampler]
    if bounds == "wrap":
        hist = fn(prev, ppx - np.floor(ppx), ppy - np.floor(ppy), wrap=True)
    else:
        hist = fn(prev, np.clip(ppx, 0, 1), np.clip(ppy, 0, 1), wrap=False)
        fill = src if bounds == "source" else np.zeros_like(src)
        hist = np.where(ins[..., None], hist, fill)
    out = hist * c(decay) * c(1.0 - inject) + src * c(inject)
    out[..., 3] = 1.0
    if detail:
        return out, ins, ppx, ppy
    return out


def run_temporal(src_fn, nframes, wpath, sampler="bilinear", keep=False, **params):
    """Ping-pong nframes steps. src_fn(k) is the source at frame k (k = 0 seeds the history, as a
    reset does); wpath(k) is w at frame k. Returns the last frame, or the list of all frames."""
    prev = np.array(src_fn(0))
    outs = [prev]
    for k in range(1, nframes + 1):
        prev = frame(prev, np.array(src_fn(k)), w=wpath(k), sampler=sampler, **params)
        outs.append(prev)
    return outs if keep else prev


def noise_image(h, w, seed=1, dtype=np.float64):
    rng = np.random.default_rng(seed)
    t = rng.uniform(0.0, 1.0, (h, w, 4)).astype(dtype)
    t[..., 3] = 1.0
    return t
