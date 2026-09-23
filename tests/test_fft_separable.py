"""
test_fft_separable.py -- correctness of the separable-DFT approach to a
GL-space FFT for f_ (ideas/ceyron_simulation_scripts_notes.md, 2026-09-22).

Mirrors the planned codebox structure pass-for-pass:
  pass_dft       one pass = a full 1D DFT along x or y for every row/column,
                 as a fixed-count loop of N nearest() samples per pixel
  pass_spectral  one pass = elementwise diffusion and/or pressure projection

Complex packing (one float32 RGBA texture): R,G = Re,Im of u; B,A = Re,Im of v.
Domain: periodic unit square, so wavevector k = 2*pi*signed_index.

Covers T1-T3 of the FFT plan for *correctness only*. Compile limits, fps and
GPU trig precision are NOT covered -- those stay Max questions.

Run:  tests/run.sh tests/test_fft_separable.py
"""
import sys

import numpy as np

from gpu_sim import F32, TWOPI, grid, nearest, sample, store_float32, texture
from harness import check, note, run

SIZES = (128, 256)
TOL = 1e-4


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


def signed_k(cell, n):
    """GenExpr: idx = floor(norm.x * n); switch(idx < n*0.5, idx, idx - n)
    (not `cell` -- see gpu_sim.py)"""
    return np.where(cell < F32(n) * F32(0.5), cell, cell - F32(n)).astype(F32)


def pass_spectral(tex, nu_dt=0.0, project=False):
    """Mirror of the planned elementwise spectral codebox: optional pressure
    projection (remove the component of (u,v) parallel to k), then viscous
    diffusion as the exact decay factor exp(-nu*dt*|k|^2)."""
    h, w = tex.shape[:2]
    nx, ny, cx, cy = grid(h, w)
    kx = TWOPI * signed_k(cx, w)
    ky = TWOPI * signed_k(cy, h)
    k2 = kx * kx + ky * ky
    s = nearest(tex, nx, ny)
    ur, ui, vr, vi = s[..., 0], s[..., 1], s[..., 2], s[..., 3]
    if project:
        inv_k2 = np.where(k2 > 0, F32(1.0) / np.maximum(k2, F32(1e-30)),
                          F32(0.0))
        dr = (kx * ur + ky * vr) * inv_k2
        di = (kx * ui + ky * vi) * inv_k2
        ur, ui = ur - kx * dr, ui - kx * di
        vr, vi = vr - ky * dr, vi - ky * di
    g = np.exp(-F32(nu_dt) * k2)
    return store_float32(np.stack([ur * g, ui * g, vr * g, vi * g], -1))


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


# ---------------------------------------------------------------- tests

def test_sim_sampling_sanity():
    """The emulator itself: texel-center reads are exact, bilinear midpoint
    blends, wrap indexes around. If this fails nothing else means anything."""
    rng = np.random.default_rng(0)
    tex = rng.random((8, 8, 4)).astype(F32)
    nx, ny, _, _ = grid(8, 8)
    check("nearest @ texel centers", np.max(np.abs(nearest(tex, nx, ny) - tex)), 0)
    check("sample @ texel centers", np.max(np.abs(sample(tex, nx, ny) - tex)), 1e-6)
    mid = sample(tex, F32(1 / 8), F32(0.5 / 8))
    check("bilinear midpoint", np.max(np.abs(mid - 0.5 * (tex[0, 0] + tex[0, 1]))), 1e-6)
    wrapped = nearest(tex, F32(-0.01), F32(0.5 / 8), wrap=True)
    check("wrap to last column", np.max(np.abs(wrapped - tex[0, 7])), 0)


def test_T1_row_dft_matches_numpy():
    for n in SIZES:
        u, v = make_image(n, n, 1), make_image(n, n, 2)
        out = pass_dft(pack(u, v), "x")
        check(f"N={n} u vs np.fft.fft rows",
              rel_err(cplx(out, "u"), np.fft.fft(u.astype(np.float64), axis=1)), TOL)
        check(f"N={n} v vs np.fft.fft rows",
              rel_err(cplx(out, "v"), np.fft.fft(v.astype(np.float64), axis=1)), TOL)


def test_2d_forward_matches_fft2():
    for n in SIZES:
        u = make_image(n, n, 3)
        out = fft2_passes(pack(u))
        check(f"N={n} 2D forward vs np.fft.fft2",
              rel_err(cplx(out, "u"), np.fft.fft2(u.astype(np.float64))), TOL)


def test_T2_roundtrip_null():
    for n in SIZES:
        u, v = make_image(n, n, 4), make_image(n, n, 5)
        back = ifft2_passes(fft2_passes(pack(u, v)))
        check(f"N={n} round-trip |u' - u|", np.max(np.abs(back[..., 0] - u)), TOL)
        check(f"N={n} round-trip |v' - v|", np.max(np.abs(back[..., 2] - v)), TOL)
        check(f"N={n} round-trip residual imag",
              np.max(np.abs(back[..., [1, 3]])), TOL)


def test_T3_diffusion_single_mode():
    """A single Fourier mode must decay by exactly exp(-nu*dt*|k|^2)."""
    for n in SIZES:
        nx, ny, _, _ = grid(n, n)
        u = np.sin(TWOPI * 3 * nx).astype(F32)
        v = np.cos(TWOPI * 5 * ny).astype(F32)
        nu_dt = np.log(2.0) / (2 * np.pi * 3) ** 2      # halves mode 3
        out = ifft2_passes(pass_spectral(fft2_passes(pack(u, v)), nu_dt=nu_dt))
        gu = np.exp(-nu_dt * (2 * np.pi * 3) ** 2)
        gv = np.exp(-nu_dt * (2 * np.pi * 5) ** 2)
        check(f"N={n} u decay (expect x{gu:.3f})", np.max(np.abs(out[..., 0] - gu * u)), TOL)
        check(f"N={n} v decay (expect x{gv:.3f})", np.max(np.abs(out[..., 2] - gv * v)), TOL)


def test_T3_lowpass_separates_modes():
    """Strong viscosity keeps a low mode (scaled) and annihilates a high one --
    the honey case, which explicit real-space diffusion can't do in one pass."""
    for n in SIZES:
        nx, _, _, _ = grid(n, n)
        low = np.sin(TWOPI * 2 * nx)
        u = (low + np.sin(TWOPI * 40 * nx)).astype(F32)
        nu_dt = 0.002
        out = ifft2_passes(pass_spectral(fft2_passes(pack(u)), nu_dt=nu_dt))
        g = np.exp(-nu_dt * (2 * np.pi * 2) ** 2)
        check(f"N={n} low mode kept x{g:.3f}, high mode gone",
              np.max(np.abs(out[..., 0] - g * low)), TOL)


def test_projection_removes_gradient_keeps_curl():
    """Helmholtz split: projection must delete a pure gradient field and leave
    a pure curl (divergence-free) field untouched."""
    for n in SIZES:
        nx, ny, _, _ = grid(n, n)
        a, b = TWOPI * 2, TWOPI * 3                    # phi = sin(a x) cos(b y)
        gu = a * np.cos(a * nx) * np.cos(b * ny)
        gv = -b * np.sin(a * nx) * np.sin(b * ny)
        c, d = TWOPI * 1, TWOPI * 4                    # psi = cos(c x) sin(d y)
        cu = d * np.cos(c * nx) * np.cos(d * ny)       # u =  dpsi/dy
        cv = c * np.sin(c * nx) * np.sin(d * ny)       # v = -dpsi/dx
        tex = pack((gu + cu).astype(F32), (gv + cv).astype(F32))
        out = ifft2_passes(pass_spectral(fft2_passes(tex), project=True))
        scale = max(np.max(np.abs(cu)), np.max(np.abs(cv)))
        check(f"N={n} projected u == curl u (rel)",
              np.max(np.abs(out[..., 0] - cu)) / scale, TOL)
        check(f"N={n} projected v == curl v (rel)",
              np.max(np.abs(out[..., 2] - cv)) / scale, TOL)


def test_projection_random_field_divergence_free():
    for n in SIZES:
        u, v = make_image(n, n, 6) - 0.5, make_image(n, n, 7) - 0.5
        spec = pass_spectral(fft2_passes(pack(u, v)), project=True)
        _, _, cx, cy = grid(n, n)
        kx = 2 * np.pi * signed_k(cx, n).astype(np.float64)
        ky = 2 * np.pi * signed_k(cy, n).astype(np.float64)
        uh, vh = cplx(spec, "u"), cplx(spec, "v")
        div = np.abs(kx * uh + ky * vh)
        ref = np.max(np.sqrt(kx ** 2 + ky ** 2) * np.sqrt(np.abs(uh) ** 2 + np.abs(vh) ** 2))
        check(f"N={n} spectral divergence after projection (rel)", np.max(div) / ref, TOL)


def test_angle_reduction_precision():
    """Twiddle angle 2*pi*k*n/N: computing k*n mod N first keeps the argument
    small. Naive float32 angles reach ~2*pi*N; report the difference. NumPy's
    sin is far more accurate than GPU sin, so the naive number here is a
    best case -- the GPU will be worse."""
    n = 256
    u = make_image(n, n, 8)
    ref = np.fft.fft(u.astype(np.float64), axis=1)
    reduced = rel_err(cplx(pass_dft(pack(u), "x", reduce_angle=True), "u"), ref)
    naive = rel_err(cplx(pass_dft(pack(u), "x", reduce_angle=False), "u"), ref)
    note(f"N={n} naive angle rel err", naive)
    check(f"N={n} reduced angle rel err", reduced, TOL)


if __name__ == "__main__":
    sys.exit(run(globals()))
