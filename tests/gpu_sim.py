"""
gpu_sim.py -- NumPy emulation of the jit.gl.pix execution model, for testing
codebox *math* outside Max.

Model: a pass is a pure function of its input textures, evaluated for every
output pixel in parallel. Here "every pixel in parallel" means NumPy arrays of
shape (H, W). A texture is a float32 array of shape (H, W, 4) -- RGBA.

Conventions of this sim -- bench-verified against Max 9 jit.gl.pix on
2026-09-22 (.specify/test_bench/tasks.md T018):
  - array index is [row, col] = [y, x]; row 0 is where norm.y is smallest,
    and it maps to Jitter matrix row 0 (no flip)
  - norm = (i + 0.5) / dim  (texel centers) -- exact match with GenExpr `norm`
  - all arithmetic in float32, to surface precision problems the GPU will have

WARNING -- GenExpr's `cell` is NOT an integer pixel index on jit.gl.pix:
it is norm * (dim - 1), e.g. 0.492, 1.477, ... at dim 64. grid() returns
true integer indices (i = floor(norm * dim)), which is what a codebox must
compute explicitly when it needs one. jitter_cell() reproduces `cell`.

What this can't tell you: compile limits (loop unrolling, instruction counts),
fps, GPU trig precision, @adapt/@dim behavior. Those stay Max questions.
"""
import numpy as np

F32 = np.float32
TWOPI = F32(2.0 * np.pi)


def grid(h, w):
    """Per-pixel coordinates: returns (norm_x, norm_y, idx_x, idx_y), each
    float32 (H, W). norm matches GenExpr `norm`. idx is the INTEGER texel
    index floor(norm * dim) -- not GenExpr `cell` (see jitter_cell)."""
    cy, cx = np.meshgrid(np.arange(h, dtype=F32), np.arange(w, dtype=F32),
                         indexing="ij")
    nx = (cx + F32(0.5)) / F32(w)
    ny = (cy + F32(0.5)) / F32(h)
    return nx, ny, cx, cy


def jitter_cell(h, w):
    """GenExpr `cell` as jit.gl.pix actually computes it: norm * (dim - 1).
    Bench-verified 2026-09-22 (probe codebox, exact to float32)."""
    nx, ny, _, _ = grid(h, w)
    return nx * F32(w - 1), ny * F32(h - 1)


def texture(h, w):
    return np.zeros((h, w, 4), F32)


def store_float32(a):
    """Model writing a pass's output into a float32 texture."""
    return np.asarray(a, dtype=F32)


def store_char(a):
    """Model writing into a char (8-bit) texture: clamp to [0,1], quantize."""
    return (np.round(np.clip(a, 0.0, 1.0) * 255.0) / 255.0).astype(F32)


def _index(i, n, wrap):
    return np.mod(i, n) if wrap else np.clip(i, 0, n - 1)


def nearest(tex, u, v, wrap=False):
    """GenExpr nearest(inN, vec(u, v)). u, v scalar or broadcastable arrays.
    Default clamp; wrap=True models manual fract() wrapping of the coord."""
    h, w = tex.shape[:2]
    u = np.asarray(u, F32)
    v = np.asarray(v, F32)
    ix = _index(np.floor(u * F32(w)).astype(np.int64), w, wrap)
    iy = _index(np.floor(v * F32(h)).astype(np.int64), h, wrap)
    ix, iy = np.broadcast_arrays(ix, iy)
    return tex[iy, ix]


def sample(tex, u, v, wrap=False):
    """GenExpr sample(inN, vec(u, v)): bilinear, texel-center convention.
    Default clamp-to-edge; wrap=True models manual fract() wrapping."""
    h, w = tex.shape[:2]
    x = np.asarray(u, F32) * F32(w) - F32(0.5)
    y = np.asarray(v, F32) * F32(h) - F32(0.5)
    x0 = np.floor(x)
    y0 = np.floor(y)
    fx = (x - x0)[..., None]
    fy = (y - y0)[..., None]
    ix0 = x0.astype(np.int64)
    iy0 = y0.astype(np.int64)
    ix1 = _index(ix0 + 1, w, wrap)
    iy1 = _index(iy0 + 1, h, wrap)
    ix0 = _index(ix0, w, wrap)
    iy0 = _index(iy0, h, wrap)
    ix0, iy0, ix1, iy1 = np.broadcast_arrays(ix0, iy0, ix1, iy1)
    one = F32(1.0)
    top = tex[iy0, ix0] * (one - fx) + tex[iy0, ix1] * fx
    bot = tex[iy1, ix0] * (one - fx) + tex[iy1, ix1] * fx
    return (top * (one - fy) + bot * fy).astype(F32)
