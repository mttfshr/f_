"""spike_cmap_room.py -- f_cmap look study 3 (2026-10-27): the SHIPPED forward map on a camera-like source.

Matt's first look in Max (a dim, low-saturation room with a head in front of it) gave a flat gray scalloped blob
(decay 1.0, inject 0.16, radius 0.47, sweep 0.81, rate 0.01, power 4, scale 1.86). The T005 sheets used a
saturated synthetic source and showed rich detail at similar settings, so the question is which of the source and
the settings makes the difference. This script runs the forward map (bilinear, bounds Source) on a low-contrast
room-like source (warm gray gradient, two lamps, soft curtain stripes, a swaying dark head) with:
  - his exact settings,
  - the same with a slow rate and no sweep,
  - power 2 and 4, a range of radius, a higher inject.

Run: tests/py.sh tests/records/spike_cmap_room.py [outdir]    (writes G_room_forward.png, prints the stats table)
"""
import os
import sys

import numpy as np

import cmap_mirror as m
import spike_cmap_look as look
import spike_cmap_inverse as inv

H, W, NF, DT = look.H, look.W, look.NF, look.DT
A = W / H
PX, PY = m.centred_p(H, W, DT)
X, Y = (PX - DT(0.5)) * DT(A), PY - DT(0.5)


def room(k):
    t = k / NF
    base = 0.30 + 0.10 * (0.5 - Y)                                   # warm gray, brighter at the top
    rgb = np.stack([base * 1.10, base * 1.00, base * 0.88], axis=-1)
    stripes = 0.5 + 0.5 * np.cos(2 * np.pi * 9.0 * X)                # soft curtain on the right third
    curtain = look.smooth(0.15, 0.30, X)[..., None] * (0.12 * stripes)[..., None] * np.array([0.9, 1.0, 0.95])
    rgb = rgb + curtain
    for lx, ly in ((-0.25, -0.43), (0.38, -0.46)):                  # two lamps
        rgb = rgb + 0.9 * np.exp(-((X - lx) ** 2 + (Y - ly) ** 2) / 0.0006)[..., None] * np.array([1.0, 0.95, 0.8])
    rgb = rgb * (1 - 0.55 * look.smooth(-0.45, -0.38, X) * (1 - look.smooth(-0.38, -0.34, X)))[..., None]  # dark door frame
    hx, hy = 0.05 * np.sin(2 * np.pi * 1.2 * t), 0.12 + 0.02 * np.cos(2 * np.pi * 2.4 * t)   # the swaying head
    head = 1 - look.smooth(0.9, 1.0, np.sqrt(((X - hx) / 0.17) ** 2 + ((Y - hy) / 0.24) ** 2))
    rgb = rgb * (1 - 0.7 * head)[..., None]
    out = np.ones((H, W, 4), DT)
    out[..., :3] = np.clip(rgb, 0, 1)
    return out


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "/tmp/cmap_look"
    os.makedirs(outdir, exist_ok=True)
    look.source = room                      # run_case reads the module-level `source`
    look.write_png(os.path.join(outdir, "room_frame150.png"), (np.clip(room(NF)[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8))
    cases = [
        ("Matt: n4 r.47 sw.81 rate.01 sc1.86 inj.16", dict(n=4, radius=0.47, sweep=0.81, rate=0.01, decay=1.0, inject=0.16), 1.86),
        ("same, rate 0.0016", dict(n=4, radius=0.47, sweep=0.81, rate=0.0016, decay=1.0, inject=0.16), 1.86),
        ("same, rate 0.0016, no sweep", dict(n=4, radius=0.47, sweep=0.0, rate=0.0016, decay=1.0, inject=0.16), 1.86),
        ("n2 r.5 rate.0016 inj.15 decay 1", dict(n=2, radius=0.5, rate=0.0016, decay=1.0, inject=0.15), 1.75),
        ("n2 r.5 rate.0016 inj.4 decay 1", dict(n=2, radius=0.5, rate=0.0016, decay=1.0, inject=0.4), 1.75),
        ("n2 r.15 (default) inj.05 decay .97", dict(n=2, radius=0.15, rate=0.0016, decay=0.97, inject=0.05), 1.75),
        ("n2 r.8 rate.0016 inj.15 decay 1", dict(n=2, radius=0.8, rate=0.0016, decay=1.0, inject=0.15), 1.75),
        ("n3 r.5 rate.0016 inj.15 decay 1", dict(n=3, radius=0.5, rate=0.0016, decay=1.0, inject=0.15), 1.75),
        ("n2 r.5 rate.0016 inj.15 decay 1 scale 1.2", dict(n=2, radius=0.5, rate=0.0016, decay=1.0, inject=0.15), 1.2),
    ]
    flat = [(lab, "forward", dict(sampler="bilinear", **kw), sc) for lab, kw, sc in cases]
    tiles, gap = [], 4
    print("\n== G_room_forward.png ==")
    for i, (label, _, kw, sc) in enumerate(flat):
        m.L = sc
        out, s = look.run_case(**kw)
        m.L = 1.75
        print(f"  [{i}] {label:46s} mean {s['mean']:.3f}  std {s['std']:.3f}  motion {s['motion']:.4f}  wander {s['wander']:.3f}")
        tiles.append((np.clip(out[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8))
    ncols, nrows = 3, 3
    canvas = np.full((nrows * (H + gap) - gap, ncols * (W + gap) - gap, 3), 40, np.uint8)
    for i, t in enumerate(tiles):
        r, c = divmod(i, ncols)
        canvas[r * (H + gap):r * (H + gap) + H, c * (W + gap):c * (W + gap) + W] = t
    look.write_png(os.path.join(outdir, "G_room_forward.png"), canvas)
    print(f"\nPNGs in {outdir}")


if __name__ == "__main__":
    main()
