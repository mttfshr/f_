"""spike_cmap_look.py -- f_cmap T005: contact sheets from the mirror on a synthetic live-like source,
to find the usable decay / inject / radius / sweep / bounds / n region before building (spec G3, G4, G6).

Source: a dark drifting colour gradient, a bright disc on an orbit and a sweeping bar (edges and
motion, as a camera on a performer would give; NOT the checker). The loop runs 150 frames at 192 x 108,
float32, from a reset (history seeded with the source), and the LAST frame of each case is tiled.

Writes PNGs to the directory given as argv[1] (default /tmp/cmap_look) and prints, per case, mean
luma, luma std, the fraction of near-black pixels, the mean |frame 150 - frame 149| (motion) and the
mean |output - source| (how far the history has wandered from the live image).

Run: tests/py.sh tests/records/spike_cmap_look.py [outdir]
"""
import os
import struct
import sys
import zlib

import numpy as np

import cmap_mirror as m

H, W = 192 // 16 * 9, 192
A = W / H
NF = 150
DT = np.float32


def write_png(path, rgb):
    """rgb: (h, w, 3) uint8."""
    h, w, _ = rgb.shape
    raw = b"".join(b"\x00" + rgb[j].tobytes() for j in range(h))

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(png)


PX, PY = m.centred_p(H, W, DT)
X, Y = (PX - DT(0.5)) * DT(A), PY - DT(0.5)


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def source(k):
    t = k / NF
    bg = 0.10 + 0.08 * np.stack([np.cos(2 * np.pi * (0.7 * X + 0.3 * Y + t)),
                                 np.cos(2 * np.pi * (0.5 * Y - 0.4 * X + t) + 2.0),
                                 np.cos(2 * np.pi * (0.6 * (X + Y) - t) + 4.0)], axis=-1)
    cx, cy = 0.45 * np.cos(2 * np.pi * 1.5 * t), 0.28 * np.sin(2 * np.pi * 1.5 * t)
    disc = 1 - smooth(0.085, 0.10, np.hypot(X - cx, Y - cy))
    x0 = 0.7 * np.sin(2 * np.pi * 2.0 * t)
    bar = 1 - smooth(0.015, 0.025, np.abs(X - x0))
    rgb = bg + disc[..., None] * np.array([0.95, 0.85, 0.4]) + bar[..., None] * np.array([0.2, 0.8, 0.95])
    out = np.ones((H, W, 4), DT)
    out[..., :3] = np.clip(rgb, 0, 1)
    return out


def run_case(decay=0.97, inject=0.08, radius=0.15, sweep=0.0, rate=m.RATE_SOURCE, n=2, bounds="source",
             sampler="catmull"):
    prev = source(0)
    last = prev
    for k in range(1, NF + 1):
        src = source(k)
        last = prev
        prev = m.frame(prev, src, n=n, w=m.offset(k, rate=rate, radius=radius, sweep=sweep), decay=decay,
                       inject=inject, bounds=bounds, sampler=sampler)
    out, src = prev, source(NF)
    luma = out[..., :3].mean(axis=2)
    stats = dict(mean=float(luma.mean()), std=float(luma.std()), black=float((luma < 0.03).mean()),
                 motion=float(np.abs(out[..., :3] - last[..., :3]).mean()),
                 wander=float(np.abs(out[..., :3] - src[..., :3]).mean()))
    return out, stats


def sheet(path, cases, ncols):
    """cases: list of (label, kwargs). Tiles the final frames; prints the stats table."""
    tiles, gap = [], 4
    print(f"\n== {os.path.basename(path)} ==")
    for i, (label, kw) in enumerate(cases):
        out, s = run_case(**kw)
        print(f"  [{i}] {label:40s} mean {s['mean']:.3f}  std {s['std']:.3f}  black {s['black']:.2f}  "
              f"motion {s['motion']:.4f}  wander {s['wander']:.3f}")
        tiles.append((np.clip(out[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8))
    nrows = (len(tiles) + ncols - 1) // ncols
    canvas = np.full((nrows * (H + gap) - gap, ncols * (W + gap) - gap, 3), 40, np.uint8)
    for i, t in enumerate(tiles):
        r, c = divmod(i, ncols)
        canvas[r * (H + gap):r * (H + gap) + H, c * (W + gap):c * (W + gap) + W] = t
    write_png(path, canvas)


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "/tmp/cmap_look"
    os.makedirs(outdir, exist_ok=True)
    src = (np.clip(source(NF)[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8)
    write_png(os.path.join(outdir, "source_frame150.png"), src)
    print("source frame 150 written (the live input at the last frame)")

    sheet(os.path.join(outdir, "A_decay_inject.png"),
          [(f"decay {d} inject {i}", dict(decay=d, inject=i)) for d in (0.90, 0.97, 1.00) for i in (0.02, 0.08, 0.30)], 3)
    sheet(os.path.join(outdir, "B_radius_sweep.png"),
          [(f"radius {r} sweep {s}", dict(radius=r, sweep=s)) for s in (0.0, 1.5) for r in (0.0, 0.15, 0.6, 1.5)], 4)
    sheet(os.path.join(outdir, "C_bounds_sampler.png"),
          [(f"bounds {b} sampler {s}", dict(radius=0.6, bounds=b, sampler=s))
           for s in ("bilinear", "catmull") for b in ("source", "black", "wrap")], 3)
    sheet(os.path.join(outdir, "D_power.png"),
          [(f"n {n}", dict(n=n, radius=0.3)) for n in (1, 2, 3, 4)], 4)
    print(f"\nPNGs in {outdir}")


if __name__ == "__main__":
    main()
