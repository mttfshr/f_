"""generate_bluenoise.py -- writes package/media/f_bluenoise64.jxf, the blue-noise threshold pattern f_halftone's Blue screen
reads (spec FR-026, gate G14 decided by Matt 2026-11-14; plan ADR-10 "Blue texture load"; task T033b).

The pattern is a 64 x 64 void-and-cluster array (Ulichney 1993; Gaussian energy, sigma 1.5, toroidal), the reference from the
T033 spike (`scratch/halftone_bluenoise/spike.py`). Each cell holds (rank + .5) / 4096, so every value occurs once and a flat
tone t lights exactly round(4096 t) cells of a tile. One float32 plane, row index = y (Jitter row 0 is the smallest norm.y,
so no flip; `tests/lib/jxf.py`). Deterministic: a fixed seed, and ties go to the first index (NumPy argmax).

Needs NumPy, so not build/py.sh:
  uv run --no-project --with numpy python3 build/generate_bluenoise.py           write the file
  uv run --no-project --with numpy python3 build/generate_bluenoise.py --check   exit 1 if the file is missing or stale
"""
import os
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tests", "lib"))
import jxf  # noqa: E402

OUT = os.path.join(ROOT, "package", "media", "f_bluenoise64.jxf")
N, SIGMA, SEED = 64, 1.5, 0


def void_and_cluster(n=N, sigma=SIGMA, seed=SEED):
    """(n, n) float32 thresholds (rank + .5) / n^2, indexed [y, x]."""
    rng = np.random.default_rng(seed)
    total = n * n
    d = np.minimum(np.arange(n), n - np.arange(n)).astype(np.float64)
    K = np.exp(-(d[:, None] ** 2 + d[None, :] ** 2) / (2 * sigma * sigma))
    FK = np.fft.fft2(K)

    def energy(B):
        return np.real(np.fft.ifft2(np.fft.fft2(B) * FK))

    def add(E, c, s):
        E += s * np.roll(np.roll(K, c[0], 0), c[1], 1)

    def tightest(B, E):
        return np.unravel_index(np.argmax(np.where(B == 1, E, -np.inf)), B.shape)

    def largest_void(B, E):
        return np.unravel_index(np.argmin(np.where(B == 0, E, np.inf)), B.shape)

    # the initial pattern: about 10% ones, relaxed by moving the tightest cluster into the largest void until stable
    B = np.zeros((n, n))
    B.flat[rng.choice(total, total // 10, replace=False)] = 1
    E = energy(B)
    while True:
        c = tightest(B, E)
        B[c] = 0; add(E, c, -1)
        v = largest_void(B, E)
        if v == c:
            B[c] = 1; add(E, c, 1)
            break
        B[v] = 1; add(E, v, 1)
    proto, ones = B.copy(), int(B.sum())
    rank = np.zeros((n, n), dtype=np.int64)
    B = proto.copy(); E = energy(B)                     # phase 1: remove tightest clusters, ranks ones-1 .. 0
    for r in range(ones - 1, -1, -1):
        c = tightest(B, E); B[c] = 0; add(E, c, -1); rank[c] = r
    B = proto.copy(); E = energy(B)                     # phase 2: fill the largest voids up to half
    for r in range(ones, total // 2):
        v = largest_void(B, E); B[v] = 1; add(E, v, 1); rank[v] = r
    Z = 1 - B; E = energy(Z)                            # phase 3: the tightest clusters of the remaining zeros
    for r in range(total // 2, total):
        c = tightest(Z, E); Z[c] = 0; add(E, c, -1); rank[c] = r
    return ((rank + 0.5) / total).astype(np.float32)


def main(argv):
    want = void_and_cluster()[..., None]
    if "--check" in argv:
        if not os.path.exists(OUT):
            print(f"missing: {OUT}"); return 1
        have = jxf.read_jxf(OUT)
        if have.shape != want.shape or have.dtype != np.float32 or not np.array_equal(have, want):
            print(f"stale: {OUT}"); return 1
        print(f"up to date: {OUT}"); return 0
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    jxf.write_jxf(OUT, want)
    print(f"wrote {OUT} ({os.path.getsize(OUT)} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
