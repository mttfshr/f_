"""
dft_mirror.py -- the separable-DFT mirror and its helpers, shared by the f_vf_fluid
mirror and benches (extracted 2026-10-18 from the Phase 0 record
tests/records/fft_separable.py).

  pass_dft       one pass = a full 1D DFT along x or y for every row/column,
                 as a fixed-count loop of N nearest() samples per pixel
  fft2_passes / ifft2_passes   the four-pass 2D transform
  pack / make_image / cplx / rel_err   texture packing and comparison helpers
  dft_codebox    the bench's dft_x / dft_y test codebox at size N

Complex packing (one float32 RGBA texture): R,G = Re,Im of u; B,A = Re,Im of v.
Domain: periodic unit square, so wavevector k = 2*pi*signed_index.
"""
import numpy as np

import paths as _paths
from gpu_sim import F32, TWOPI, grid, nearest, store_float32, texture


# ---------------------------------------------------------------- shader mirrors

def pass_dft(tex, axis, inverse=False, reduce_angle=True):
    """Mirror of the planned DFT codebox (axis would be a Param or a constant
    per stage). Each output pixel computes one bin along `axis` for its own
    row/column by looping over all N input texels on that line."""
    h, w = tex.shape[:2]
    nx, ny, cx, cy = grid(h, w)
    n_len = w if axis == "x" else h
    # this pixel's integer bin index. In the codebox: floor(norm.x * N) --
    # NOT `cell`, which jit.gl.pix defines as norm*(dim-1) (bench-verified
    # 2026-09-22, see gpu_sim.py).
    k = cx if axis == "x" else cy
    sgn = F32(1.0) if inverse else F32(-1.0)
    acc = np.zeros((h, w, 4), F32)
    for n in range(n_len):                        # for (n = 0; n < N; n += 1)
        t = F32((n + 0.5) / n_len)                # texel center of input n
        s = nearest(tex, t, ny) if axis == "x" else nearest(tex, nx, t)
        idx = k * F32(n)
        if reduce_angle:
            idx = np.mod(idx, F32(n_len))         # exact while k*n < 2^24
        ang = sgn * TWOPI * idx / F32(n_len)
        c = np.cos(ang)
        sn = np.sin(ang)
        # complex multiply-accumulate: (a + ib)(c + is)
        acc[..., 0] += s[..., 0] * c - s[..., 1] * sn
        acc[..., 1] += s[..., 0] * sn + s[..., 1] * c
        acc[..., 2] += s[..., 2] * c - s[..., 3] * sn
        acc[..., 3] += s[..., 2] * sn + s[..., 3] * c
    if inverse:
        acc /= F32(n_len)
    return store_float32(acc)


def fft2_passes(tex, **kw):
    return pass_dft(pass_dft(tex, "x", **kw), "y", **kw)


def ifft2_passes(tex, **kw):
    return pass_dft(pass_dft(tex, "y", inverse=True, **kw), "x",
                    inverse=True, **kw)


# ---------------------------------------------------------------- helpers

def pack(u, v=None):
    tex = texture(*u.shape)
    tex[..., 0] = u
    if v is not None:
        tex[..., 2] = v
    return tex


def make_image(h, w, seed=1):
    rng = np.random.default_rng(seed)
    nx, ny, _, _ = grid(h, w)
    img = (0.5 + 0.25 * np.sin(TWOPI * 3 * nx) * np.cos(TWOPI * 5 * ny)
           + 0.2 * rng.random((h, w)))
    return img.astype(F32)


def cplx(tex, which):
    c = 0 if which == "u" else 2
    return tex[..., c].astype(np.float64) + 1j * tex[..., c + 1]


def rel_err(a, ref):
    return np.max(np.abs(a - ref)) / np.max(np.abs(ref))


def dft_codebox(axis, n=128, naive_angle=False):
    """Text of tests/bench/codeboxes/dft_<axis>.gen with N substituted; with
    naive_angle the mod(k * n, N) twiddle reduction is removed."""
    code = (_paths.BENCH / "codeboxes" / f"dft_{axis}.gen").read_text()
    assert code.count("128") == 2, "N must appear exactly twice (see codebox header)"
    code = code.replace("128", str(n))
    if naive_angle:
        code = code.replace("mod(k * n, N)", "(k * n)")
    return code
