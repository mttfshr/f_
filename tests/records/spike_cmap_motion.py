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


def scene_orbit(k):
    """Room plus an orbiting bright disc and a sweeping bar, as T005's source: motion that never leaves."""
    out = rm.room(0)
    t = k / 150.0
    cx, cy = 0.45 * np.cos(2 * np.pi * t), 0.28 * np.sin(2 * np.pi * t)
    d = 1 - look.smooth(0.05, 0.07, np.hypot(X - cx, Y - cy))
    x0 = 0.7 * np.sin(2 * np.pi * 1.3 * t)
    bar = 1 - look.smooth(0.012, 0.02, np.abs(X - x0))
    rgb = out[..., :3] * (1 - d[..., None]) + d[..., None] * np.array([1.0, 0.9, 0.5])
    rgb = rgb * (1 - bar[..., None]) + bar[..., None] * np.array([0.3, 0.8, 1.0])
    out[..., :3] = np.clip(rgb, 0, 1)
    return out


def run_long(label, nf=450, every=50, n=2, radius=0.15, sweep=1.5, decay=1.0, inject=0.1, rate=m.RATE_SOURCE, scale=1.75):
    """The doc's animation: |w| = radius + sweep cos(phase) at the source rate, a full sweep cycle."""
    m.L = scale
    prev = scene_orbit(0)
    tiles = []
    for k in range(1, nf + 1):
        prev = m.frame(prev, scene_orbit(k), n=n, w=m.offset(k, rate=rate, radius=radius, sweep=sweep), decay=decay,
                       inject=inject, bounds="source", sampler="bilinear")
        if k % every == 0:
            tiles.append((np.clip(prev[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8))
    m.L = 1.75
    print(f"  {label}: {len(tiles)} frames")
    return tiles


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
    outdir = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] != "long" else "/tmp/cmap_look"
    os.makedirs(outdir, exist_ok=True)
    if "long" in sys.argv:
        sheet(os.path.join(outdir, "I_doc_animation_inj01.png"), run_long("doc animation inject 0.1"))
        sheet(os.path.join(outdir, "I_doc_animation_inj03.png"), run_long("doc animation inject 0.3", inject=0.3))
        print(f"PNGs in {outdir}")
        return
    sheet(os.path.join(outdir, "H_motion_n2_r06.png"), run("n2 radius 0.6 inject 0.3"))
    sheet(os.path.join(outdir, "H_motion_n2_r06_sc3.png"), run("n2 radius 0.6 inject 0.3 scale 3.0", scale=3.0))
    print(f"PNGs in {outdir}")


if __name__ == "__main__":
    main()
