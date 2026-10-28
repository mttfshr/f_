"""spike_cmap_motion.py -- f_cmap look study 4 (2026-10-27): does MOTION wind into filaments? (spec goal)

The shipped forward map on the room-like source plus a bright disc that sweeps across the frame, through the edge
of the Julia window. Tiles show the frame every 8 frames, so the wake of the disc can be followed.

Run: tests/py.sh tests/records/spike_cmap_motion.py [outdir]    (writes H_motion_*.png)
"""
import os
import sys

import numpy as np

import cmap_mirror as m
import spike_cmap_look as look
import spike_cmap_room as rm

H, W, DT = look.H, look.W, look.DT
X, Y = rm.X, rm.Y
NF = 72


def scene(k):
    out = rm.room(0)
    t = k / NF
    cx, cy = -0.9 + 1.8 * t, 0.05 * np.sin(2 * np.pi * 2 * t)
    d = 1 - look.smooth(0.05, 0.07, np.hypot(X - cx, Y - cy))
    out[..., :3] = np.clip(out[..., :3] * (1 - d[..., None]) + d[..., None] * np.array([1.0, 0.9, 0.5]), 0, 1)
    return out


def run(label, n=2, radius=0.6, decay=1.0, inject=0.3, rate=0.002, scale=1.75, sweep=0.0, every=8):
    m.L = scale
    prev = scene(0)
    tiles = []
    for k in range(1, NF + 1):
        prev = m.frame(prev, scene(k), n=n, w=m.offset(k, rate=rate, radius=radius, sweep=sweep), decay=decay,
                       inject=inject, bounds="source", sampler="bilinear")
        if k % every == 0:
            tiles.append((np.clip(prev[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8))
    m.L = 1.75
    print(f"  {label}: {len(tiles)} frames")
    return tiles


def sheet(path, tiles, ncols=3):
    gap = 4
    nrows = (len(tiles) + ncols - 1) // ncols
    canvas = np.full((nrows * (H + gap) - gap, ncols * (W + gap) - gap, 3), 40, np.uint8)
    for i, t in enumerate(tiles):
        r, c = divmod(i, ncols)
        canvas[r * (H + gap):r * (H + gap) + H, c * (W + gap):c * (W + gap) + W] = t
    look.write_png(path, canvas)


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "/tmp/cmap_look"
    os.makedirs(outdir, exist_ok=True)
    sheet(os.path.join(outdir, "H_motion_n2_r06.png"), run("n2 radius 0.6 inject 0.3"))
    sheet(os.path.join(outdir, "H_motion_n2_r06_sc3.png"), run("n2 radius 0.6 inject 0.3 scale 3.0", scale=3.0))
    print(f"PNGs in {outdir}")


if __name__ == "__main__":
    main()
