"""spike_cmap_inverse.py -- f_cmap look study 2 (2026-10-27): the INVERSE map, offline on the mirror.

Why: the shipped pull reads prev(z^n + w). Inside the Julia basin that contracts everything toward the fixed
point, so the interior goes flat and only a thin scalloped border carries detail (Matt's look in Max, 2026-10-27:
"just a scalloped gray shape"). Here the pixel at z reads prev(g(z)) with g = +/- sqrt(z - w), the inverse of
z -> z^2 + w. The Julia set is repelling under f, so it ATTRACTS under g: content is dragged along the filled-in
fractal instead of collapsing to a point, and angles are halved (content at angle phi appears at 2 phi).

The two-branch sqrt needs a choice per pixel. Variants:
  principal  s = +1 everywhere (principal sqrt: a seam on the negative real axis of z - w)
  alt_frame  s flips every frame
  checker    s by pixel parity (ix + iy), fixed in time
  hash       s a fresh pseudo-random sign per pixel per frame (the 'chaos game': fills the Julia set evenly, noisy)
Everything else as the module: isometric centred coordinates, L = 1.75, bilinear read, bounds = Source for a
read outside the frame, out = hist * decay * (1 - inject) + src * inject, w = radius e^(2 pi i angle) with the
clock (no sweep unless given). Source: the T005 synthetic (drifting gradient, orbiting disc, sweeping bar).

Run: tests/py.sh tests/records/spike_cmap_inverse.py [outdir]     (writes sheets E and F, prints the stats table)
"""
import os
import sys

import numpy as np

import cmap_mirror as m
import spike_cmap_look as look

H, W, NF, DT = look.H, look.W, look.NF, look.DT
A = W / H
PX, PY = m.centred_p(H, W, DT)
IX, IY = np.meshgrid(np.arange(W), np.arange(H))
CHECK = ((IX + IY) % 2 == 0)


def inverse_point(w, sign):
    """The read position for every pixel: p' of z' = sign * sqrt(z - w); sign is an array of +/-1."""
    qx = (PX.astype(np.float64) - 0.5) * A
    qy = PY.astype(np.float64) - 0.5
    z = 2.0 * m.L * (qx + 1j * qy) - (w[0] + 1j * w[1])
    g = sign * np.sqrt(z)
    qpx, qpy = g.real / (2.0 * m.L), g.imag / (2.0 * m.L)
    return (qpx / A + 0.5).astype(DT), (qpy + 0.5).astype(DT)


def signs(branch, k, rng):
    if branch == "principal":
        return np.ones((H, W))
    if branch == "alt_frame":
        return np.full((H, W), 1.0 if k % 2 == 0 else -1.0)
    if branch == "checker":
        return np.where(CHECK, 1.0, -1.0)
    if branch == "hash":
        return np.where(rng.random((H, W)) < 0.5, 1.0, -1.0)
    raise ValueError(branch)


def run_inverse(branch="principal", decay=1.0, inject=0.15, radius=0.3, sweep=0.0, rate=0.004, angle=0.0):
    rng = np.random.default_rng(7)
    prev = look.source(0)
    last = prev
    for k in range(1, NF + 1):
        src = look.source(k)
        last = prev
        ppx, ppy = inverse_point(m.offset(k, rate=rate, angle=angle, radius=radius, sweep=sweep), signs(branch, k, rng))
        ins = m.inside(ppx, ppy)
        hist = m.bilinear(prev, np.clip(ppx, 0, 1), np.clip(ppy, 0, 1))
        hist = np.where(ins[..., None], hist, src)
        prev = hist * DT(decay * (1 - inject)) + src * DT(inject)
        prev[..., 3] = 1.0
    out, src = prev, look.source(NF)
    luma = out[..., :3].mean(axis=2)
    return out, dict(mean=float(luma.mean()), std=float(luma.std()), black=float((luma < 0.03).mean()),
                     motion=float(np.abs(out[..., :3] - last[..., :3]).mean()),
                     wander=float(np.abs(out[..., :3] - src[..., :3]).mean()))


def sheet(path, cases, ncols):
    import spike_cmap_look as L
    tiles, gap = [], 4
    print(f"\n== {os.path.basename(path)} ==")
    for i, (label, kind, kw) in enumerate(cases):
        if kind == "forward":
            out, s = L.run_case(sampler="bilinear", **kw)
        else:
            out, s = run_inverse(**kw)
        print(f"  [{i}] {label:44s} mean {s['mean']:.3f}  std {s['std']:.3f}  black {s['black']:.2f}  "
              f"motion {s['motion']:.4f}  wander {s['wander']:.3f}")
        tiles.append((np.clip(out[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8))
    nrows = (len(tiles) + ncols - 1) // ncols
    canvas = np.full((nrows * (H + gap) - gap, ncols * (W + gap) - gap, 3), 40, np.uint8)
    for i, t in enumerate(tiles):
        r, c = divmod(i, ncols)
        canvas[r * (H + gap):r * (H + gap) + H, c * (W + gap):c * (W + gap) + W] = t
    L.write_png(path, canvas)


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "/tmp/cmap_look"
    os.makedirs(outdir, exist_ok=True)
    cases = [("forward z^2+w, radius 0.5 (the shipped look)", "forward", dict(decay=1.0, inject=0.15, radius=0.5))]
    for branch in ("principal", "alt_frame", "checker", "hash"):
        for radius in (0.15, 0.6):
            cases.append((f"{branch} radius {radius}", "inverse", dict(branch=branch, radius=radius)))
    sheet(os.path.join(outdir, "E_inverse_branches.png"), cases, 3)
    cases = []
    for inject in (0.05, 0.15, 0.4):
        for decay in (0.97, 1.0):
            cases.append((f"principal inject {inject} decay {decay}", "inverse",
                          dict(branch="principal", radius=0.4, inject=inject, decay=decay)))
    sheet(os.path.join(outdir, "F_inverse_principal_inject.png"), cases, 3)
    print(f"\nPNGs in {outdir}")


if __name__ == "__main__":
    main()
