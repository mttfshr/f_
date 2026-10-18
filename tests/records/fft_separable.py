"""
fft_separable.py -- correctness of the separable-DFT approach to a
GL-space FFT for f_ (ideas/ceyron_simulation_scripts_notes.md, 2026-09-22).

Mirrors the planned codebox structure pass-for-pass:
  pass_dft       one pass = a full 1D DFT along x or y for every row/column,
                 as a fixed-count loop of N nearest() samples per pixel
  pass_spectral  one pass = elementwise diffusion and/or pressure projection

Complex packing (one float32 RGBA texture): R,G = Re,Im of u; B,A = Re,Im of v.
Domain: periodic unit square, so wavevector k = 2*pi*signed_index.

Covers T1-T3 of the FFT plan for *correctness only*. Compile limits, fps and
GPU trig precision are NOT covered -- those stay Max questions.

RECORD (2026-10-18): Phase 0 of f_vf_fluid, no longer in the offline suite (the file is not
test_*-named). The mirror and helpers moved to tests/lib/dft_mirror.py; the sampling check
became tests/toolchain/test_gpu_sim.py and the angle-reduction check lives in
tests/modules/fluid/test_fluid_mirror.py. pass_spectral / signed_k stay here.

Run:  tests/py.sh tests/records/fft_separable.py
"""
import sys

import numpy as np

from dft_mirror import cplx, fft2_passes, ifft2_passes, make_image, pack, pass_dft, rel_err
from gpu_sim import F32, TWOPI, grid, nearest, store_float32
from harness import check, run

SIZES = (128, 256)
TOL = 1e-4


# ---------------------------------------------------------------- shader mirrors

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

# ---------------------------------------------------------------- tests

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


if __name__ == "__main__":
    sys.exit(run(globals()))
