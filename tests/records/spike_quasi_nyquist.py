"""spike_quasi_nyquist.py -- f_quasi T005: Nyquist handling for the finest octaves (FR-009, SC-004).

Octave i has B * s_i cycles per frame height, i.e. cpp_i = B * s_i / H cycles per output pixel.
Above 0.5 cpp it aliases. Reference = the unfaded float64 potential box-averaged over 4 x 4
sub-samples per pixel (an ideal pre-filtered pixel). Candidates are point-sampled, one sample per
pixel, in float64:
  none           no fade (the spec model)
  hard@C         octave dropped when cpp >= C          (C = 0.5, 0.35)
  smooth S->0.5  per-octave smoothstep fade from cpp = S to 0.5, renormalised over the faded
                 weights (S = 0.15, 0.25, 0.35)
  smooth 0.25 nr the same fade WITHOUT renormalising (amplitude falls with the fade)
  global         ONE factor, the smooth fade of the highest octave that carries weight (>= 1e-3 of
                 the peak), applied to P as a whole: the alternative to per-octave fading
Crops: 128 x 128 pixels at the frame centre at H = 1080 and H = 270 (the 270 case puts the same
density at 4x the cycles per pixel, standing in for a small render size), density 4 / 8 / 12,
zoom 0 / 0.5 / 0.9, envelope 0.5 and 0.7 (the T004 cap). Metric: RMS error of P against the
reference, and the contrast kept (std of the candidate / std of the reference).

Run: uv run --no-project --with numpy python3 tests/records/spike_quasi_nyquist.py
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "lib"))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "quasi"))

import numpy as np  # noqa: E402

import quasi_mirror as q  # noqa: E402

F64 = np.float64
N, SS = 128, 4


def crop(H, ss):
    off = (np.arange(N * ss) + 0.5) / ss - N / 2
    x, y = np.meshgrid(off / H, off / H, indexing="xy")
    return x, y


def box(a):
    return a.reshape(N, SS, N, SS).mean(axis=(1, 3))


CANDS = [
    ("none", None, False),
    ("hard@0.5", dict(mode="hard", start=0.5), False),
    ("hard@0.35", dict(mode="hard", start=0.35), False),
    ("smooth .15", dict(start=0.15, end=0.5, renorm=True), False),
    ("smooth .25", dict(start=0.25, end=0.5, renorm=True), False),
    ("smooth .35", dict(start=0.35, end=0.5, renorm=True), False),
    ("sm .25 norenorm", dict(start=0.25, end=0.5, renorm=False), False),
    ("global", None, True),
]


def main():
    names = [c[0] for c in CANDS]
    agg = {n: [] for n in names}
    cont = {n: [] for n in names}
    print("H     B  zoom  env |  RMS error x1e3 per candidate: " + "  ".join(f"{n:>15}" for n in names))
    for H in (1080, 270):
        xs, ys = crop(H, 1)
        xr, yr = crop(H, SS)
        for env in (0.5, 0.7):
            for dens in (4, 8, 12):
                for zoom in (0.0, 0.5, 0.9):
                    kw = dict(zoom=zoom, drift=0.0, density=dens, envelope=env, dtype=F64)
                    ref = box(q.field(xr, yr, **kw)["P"])
                    _, w, s = q.octave_terms(zoom, env, F64)
                    top = max(i for i in range(7) if w[i] >= 1e-3 * w.max())
                    cpp_top = dens * s[top] / H
                    t = np.clip((cpp_top - 0.25) / 0.25, 0, 1)
                    f_top = 1 - t * t * (3 - 2 * t)
                    cells = []
                    for name, fade, glob in CANDS:
                        fd = dict(fade, px=H) if fade else None
                        p = q.field(xs, ys, fade=fd, **kw)["P"]
                        if glob:
                            p = p * f_top
                        e = float(np.sqrt(np.mean((p - ref) ** 2)))
                        agg[name].append(e)
                        cont[name].append(float(p.std() / ref.std()))
                        cells.append(e * 1e3)
                    print(f"{H:4d} {dens:3d} {zoom:5.1f} {env:4.1f} |  " + "  ".join(f"{c:15.1f}" for c in cells)
                          + f"   (top octave cpp {cpp_top:.2f})")
    print()
    print(f"{'candidate':>16} | mean RMS x1e3   worst RMS x1e3   mean contrast kept   min contrast kept")
    for n in names:
        a, c = np.array(agg[n]), np.array(cont[n])
        print(f"{n:>16} | {a.mean() * 1e3:12.1f}   {a.max() * 1e3:13.1f}   {c.mean():18.3f}   {c.min():17.3f}")
    print()
    print("Reading: lower RMS = less aliasing against the pre-filtered reference; contrast kept near"
          " 1 = the pattern is not dimmed. `global` cannot remove an aliasing octave, it only dims the"
          " whole pattern; with renormalisation a global factor would cancel entirely.")


if __name__ == "__main__":
    main()
