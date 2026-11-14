"""test_bluenoise.py -- tier-1 tests for f_halftone's blue-noise pattern file (T033b; spec FR-026, gate G14; plan ADR-10).

The file package/media/f_bluenoise64.jxf must be what build/generate_bluenoise.py makes, hold every rank once, and keep the
properties the T033 spike measured (offline Claude, 2026-11-14): exact area law, low-frequency power well under white noise,
no lattice peaks, and independent plates under the preliminary plate offsets. The mirror must read the same file.

Run:  tests/run.sh -q tests/modules/halftone/test_bluenoise.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import generate_bluenoise  # noqa: E402
import jxf  # noqa: E402
from halftone_mirror import bluenoise64  # noqa: E402

N = 64
PLATE_OFF = [(0, 0), (23, 41), (47, 13)]   # preliminary (spike), the codebox will use the same


def file_array():
    return jxf.read_jxf(generate_bluenoise.OUT)


def tiled(T, n=256, off=(0, 0)):
    y, x = np.mgrid[0:n, 0:n]
    return T[(y + off[1]) % N, (x + off[0]) % N]


def test_file_matches_generator():
    a = file_array()
    check("file is one float32 plane, 64 x 64", float(a.shape != (N, N, 1) or a.dtype != np.float32), 0)
    check("file equals generate_bluenoise (regenerate if not)", float(not np.array_equal(a[..., 0], generate_bluenoise.void_and_cluster())), 0)


def test_every_rank_once():
    v = np.sort(file_array().ravel())
    check("values are (k + .5) / 4096, each once", float(np.abs(v - (np.arange(N * N) + 0.5) / (N * N)).max()), 0)


def test_area_law_exact_per_tile():
    T = file_array()[..., 0]
    err = max(abs((T < k / 4096).sum() - k) for k in range(0, 4097, 7))
    check("lit cells of a tile at tone k / 4096 equal k", float(err), 0)


def test_blue_spectrum():
    T = file_array()[..., 0]
    for g, tol in ((0.1, 0.15), (0.25, 0.15), (0.5, 0.4)):
        B = (g > tiled(T)).astype(np.float64)
        n = B.shape[0]
        P = np.abs(np.fft.fft2(B - B.mean())) ** 2 / (n * n) / (g * (1 - g))
        P[0, 0] = 0
        f = np.fft.fftfreq(n)
        R = np.sqrt(f[:, None] ** 2 + f[None, :] ** 2)
        low = float(P[(R > 0) & (R < np.sqrt(min(g, 1 - g)) / 2)].mean())
        s = np.sort(P.ravel())[::-1]
        note(f"tone {g}: low-frequency power (white noise = 1)", f"{low:.3f}")
        check(f"tone {g}: low-frequency power under {tol}", low, tol)
        check(f"tone {g}: 8 strongest frequencies hold under 5% of the energy", float(s[:8].sum() / s.sum()), 0.05)


def test_plates_independent():
    T = file_array()[..., 0]
    lit = [0.5 > tiled(T, off=o) for o in PLATE_OFF]
    for i, j in ((0, 1), (0, 2), (1, 2)):
        ov = float((lit[i] & lit[j]).mean())
        note(f"plates {i}, {j} both lit at tone .5 (independent = .25)", f"{ov:.4f}")
        check(f"plates {i}, {j} overlap within .02 of .25", abs(ov - 0.25), 0.02)


def test_mirror_reads_the_file():
    check("halftone_mirror.bluenoise64() is the file", float(not np.array_equal(bluenoise64(), file_array()[..., 0])), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
