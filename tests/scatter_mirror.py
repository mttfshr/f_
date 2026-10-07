"""
scatter_mirror.py -- NumPy mirror of the f_caustic sheets mode's pieces (.specify/f_caustic_scatter/spec.md).
Promoted on 2026-10-07 from tests/spike_scatter.py (ref_scatter and the resampling helpers) plus the tone curve
of src/f_caustic/codebox_sheets.gen. NumPy only; no Max.

  ref_scatter     what the shader does: a lattice displaced through the field and tent-splatted, additively
  box_down        2D block-mean down-sampling (the comparison resolution)
  upscale         bilinear upscale by an integer factor, pixel centres aligned
  resize_bilinear bilinear resize to any size (what sample(in, norm) does when magnifying)
  tone            the sheets composite's tone curve: t = v / (1 + v), out = t ** 0.7
"""
import numpy as np

import gpu_sim as g

F32 = np.float32
R = 256                      # default node capture size of the spike bpatcher
TEX = 512                    # input texture size of the tests


def flip(a, on):
    return a[::-1] if on else a


def ref_scatter(src, field, d, n, w, up_flip=False, out_flip=False, r=R, fy=1.0):
    """What the shader should do. Lattice u_i = i/(n-1) (a plane gridshape spans [-1, 1] inclusive), textures
    sampled bilinear/clamp, each point splatted with a bilinear (tent) footprint, additive. (A plain size-1 GL
    point is round and deposits only if its centre is within 0.5 px of a pixel centre: it aliased against the
    lattice and lost ~21% of the energy, spike S1; the corner-snapped size-2 point of the module equals the
    tent exactly, spike S5.)
    up_flip: texture memory = flipud(matrix); out_flip: matrix = flipud(framebuffer).
    fy multiplies the field's Y (the shader's baked flip is -1 under both flips)."""
    t = (np.arange(n, dtype=np.float64) / (n - 1)).astype(F32)
    U, V = np.meshgrid(t, t)
    f = (g.sample(flip(field, up_flip), U, V)[..., :2] - F32(0.5)) * F32(2.0)
    X = U + F32(d) * f[..., 0]
    Y = V + F32(d) * f[..., 1] * F32(fy)
    # tent (bilinear) splat, as the fragment shader does: pixel k gets 1 - |k + 0.5 - x*r| (if > 0)
    # a point whose CENTRE is outside the viewport is clipped whole (GL clips a point by its centre)
    centre_in = (X >= 0) & (X <= 1) & (Y >= 0) & (Y <= 1)
    fx, fyy = X * F32(r) - F32(0.5), Y * F32(r) - F32(0.5)
    x0, y0 = np.floor(fx), np.floor(fyy)
    tx, ty = fx - x0, fyy - y0
    x0, y0 = x0.astype(np.int64), y0.astype(np.int64)
    val = g.sample(flip(src, up_flip), U, V) * F32(w)
    img = np.zeros((r, r, 4))
    for ox, oy, wt in ((0, 0, (1 - tx) * (1 - ty)), (1, 0, tx * (1 - ty)),
                       (0, 1, (1 - tx) * ty), (1, 1, tx * ty)):
        px, py = x0 + ox, y0 + oy
        ok = centre_in & (px >= 0) & (px < r) & (py >= 0) & (py < r)
        flat = (py * r + px)[ok]
        for c in range(4):
            img[..., c] += np.bincount(flat, weights=(val[..., c] * wt)[ok].astype(np.float64),
                                       minlength=r * r).reshape(r, r)
    return flip(img, out_flip).astype(F32)


def rel_err(a, b, ch=slice(0, 3)):
    a, b = a[..., ch].astype(np.float64), b[..., ch].astype(np.float64)
    return float(np.abs(a - b).mean() / max(np.abs(b).mean(), 1e-12))


# ------------------------------------------------------- resampling and tone
def box_down(img, f):
    h, w = img.shape
    return img.reshape(h // f, f, w // f, f).mean(axis=(1, 3))


def upscale(img, s):
    """Bilinear upscale by an integer factor, pixel centres aligned (output i <-> capture (i+.5)/s-.5)."""
    if s == 1:
        return img
    h = img.shape[0]
    x = np.clip((np.arange(h * s) + 0.5) / s - 0.5, 0, h - 1)
    i0 = np.floor(x).astype(int)
    i1 = np.minimum(i0 + 1, h - 1)
    t = x - i0
    a = img[i0] * (1 - t)[:, None] + img[i1] * t[:, None]
    return a[:, i0] * (1 - t)[None, :] + a[:, i1] * t[None, :]


def resize_bilinear(img, H, W):
    """Bilinear resize of an (h, w, c) array to (H, W, c), pixel centres aligned (what sample(in1, norm) does
    when magnifying)."""
    h, w = img.shape[:2]
    ys = np.clip((np.arange(H) + 0.5) * h / H - 0.5, 0, h - 1)
    xs = np.clip((np.arange(W) + 0.5) * w / W - 0.5, 0, w - 1)
    y0, x0 = np.floor(ys).astype(int), np.floor(xs).astype(int)
    y1, x1 = np.minimum(y0 + 1, h - 1), np.minimum(x0 + 1, w - 1)
    ty, tx = (ys - y0)[:, None, None], (xs - x0)[None, :, None]
    a = img[y0][:, x0] * (1 - tx) + img[y0][:, x1] * tx
    b = img[y1][:, x0] * (1 - tx) + img[y1][:, x1] * tx
    return a * (1 - ty) + b * ty


def tone(v, lev=1.0, expo=0.7):
    """The sheets composite's tone curve (look-patch default, never tuned): t = v*lev / (1 + v*lev), t ** expo."""
    x = np.asarray(v, np.float64) * lev
    return (x / (1.0 + x)) ** expo


# ------------------------------------------------------------------ test inputs
def gradient_src(n=TEX):
    nx, ny, _, _ = g.grid(n, n)
    a = np.zeros((n, n, 4), F32)
    a[..., 0], a[..., 1], a[..., 2], a[..., 3] = nx, ny, nx * ny, 1.0
    return a


def uniform_field(fx, fy, n=TEX):
    a = np.zeros((n, n, 4), F32)
    a[..., 0], a[..., 1], a[..., 3] = fx / 2 + 0.5, fy / 2 + 0.5, 1.0
    return a


def point_field(tx, ty, d=1.0, n=TEX):
    """A field that sends every lattice point to (tx, ty) when the distance is d: F = ((t - u) / d), which is
    linear in u, so bilinear sampling reproduces it exactly away from the edge texels."""
    nx, ny, _, _ = g.grid(n, n)
    a = np.zeros((n, n, 4), F32)
    a[..., 0] = ((tx - nx) / d) / 2 + 0.5
    a[..., 1] = ((ty - ny) / d) / 2 + 0.5
    a[..., 3] = 1.0
    return a


def white(n=TEX):
    return np.ones((n, n, 4), F32)
