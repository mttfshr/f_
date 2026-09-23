"""
bench_fft.py -- FFT T1 (and T2) through the Max test bench: the separable-DFT
codeboxes run on the GPU in jit.gl.pix and are diffed against NumPy
(.specify/test_bench/tasks.md T023-T026; math reference:
tests/test_fft_separable.py). One pass per job (spec decision): multi-pass
results chain job outputs into the next job's input.

Run:  tests/bench.sh tests/bench_fft.py
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
from test_fft_separable import make_image, pack, pass_dft, rel_err

CB = Path(__file__).resolve().parent / "bench" / "codeboxes"
TOL = 1e-4


def codebox(axis, n=128, naive_angle=False):
    code = (CB / f"dft_{axis}.gen").read_text()
    assert code.count("128") == 2, "N must appear exactly twice (see codebox header)"
    code = code.replace("128", str(n))
    if naive_angle:
        code = code.replace("mod(k * n, N)", "(k * n)")
    return code


def gpu_pass(tex, axis, inverse=0, n=None, naive_angle=False):
    n = n or tex.shape[1]
    out, r = bc.run_pass(codebox(axis, n, naive_angle), [tex],
                         params={"inverse": inverse}, timeout_ms=30000)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def cplx(tex, c):
    return tex[..., c].astype(np.float64) + 1j * tex[..., c + 1]


def test_T1_row_pass_128():
    """The question T1 asked: does a fixed 128-iteration loop compile on the
    GPU and produce the right numbers?"""
    u, v = make_image(128, 128, 1), make_image(128, 128, 2)
    tex = pack(u, v)
    out = gpu_pass(tex, "x")
    check("GPU vs NumPy float32 mirror (rel)", rel_err(out, pass_dft(tex, "x")), TOL)
    check("GPU u vs np.fft rows (rel)", rel_err(cplx(out, 0), np.fft.fft(u.astype(np.float64), axis=1)), TOL)
    check("GPU v vs np.fft rows (rel)", rel_err(cplx(out, 2), np.fft.fft(v.astype(np.float64), axis=1)), TOL)


def test_row_roundtrip_via_param():
    """Forward then inverse (Param inverse=1) as two jobs: also proves Param
    delivery through the bench."""
    u, v = make_image(128, 128, 3), make_image(128, 128, 4)
    back = gpu_pass(gpu_pass(pack(u, v), "x", 0), "x", 1)
    check("|u' - u|", np.abs(back[..., 0] - u).max(), TOL)
    check("|v' - v|", np.abs(back[..., 2] - v).max(), TOL)
    check("residual imag", np.abs(back[..., [1, 3]]).max(), TOL)


def test_T2_2d_forward_and_roundtrip_128():
    u, v = make_image(128, 128, 5), make_image(128, 128, 6)
    spec = gpu_pass(gpu_pass(pack(u, v), "x"), "y")
    check("2D forward u vs np.fft.fft2 (rel)", rel_err(cplx(spec, 0), np.fft.fft2(u.astype(np.float64))), TOL)
    check("2D forward v vs np.fft.fft2 (rel)", rel_err(cplx(spec, 2), np.fft.fft2(v.astype(np.float64))), TOL)
    back = gpu_pass(gpu_pass(spec, "y", 1), "x", 1)
    check("2D round trip |u' - u|", np.abs(back[..., 0] - u).max(), TOL)
    check("2D round trip |v' - v|", np.abs(back[..., 2] - v).max(), TOL)


def test_T1_row_pass_256():
    u = make_image(256, 256, 7)
    tex = pack(u)
    out = gpu_pass(tex, "x", n=256)
    check("N=256 GPU vs mirror (rel)", rel_err(out, pass_dft(tex, "x")), TOL)
    check("N=256 GPU u vs np.fft rows (rel)", rel_err(cplx(out, 0), np.fft.fft(u.astype(np.float64), axis=1)), TOL)


def test_angle_reduction_on_gpu_sin():
    """Same comparison as the NumPy test, now with the GPU's sin/cos."""
    u = make_image(256, 256, 8)
    ref = np.fft.fft(u.astype(np.float64), axis=1)
    reduced = rel_err(cplx(gpu_pass(pack(u), "x", n=256), 0), ref)
    naive = rel_err(cplx(gpu_pass(pack(u), "x", n=256, naive_angle=True), 0), ref)
    note("N=256 GPU naive-angle rel err", naive)
    note("N=256 GPU reduced-angle rel err", reduced)
    check("reduced angle within tolerance", reduced, TOL)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
