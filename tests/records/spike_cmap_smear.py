"""spike_cmap_smear.py -- f_cmap T004: how much does repeated resampling damage the image, and which
sampler (nearest, bilinear, Catmull-Rom) is least bad? Decides gate G4.

Method: a band-limited, FRAME-PERIODIC analytic image I(p) (integer cycles across the frame, so the
"wrap" bounds rule is a true torus) is ping-ponged through the pull with decay 1 and inject 0. Its
exact k-frame composition is known in closed form, I_k(p) = I(fract f(fract f(... p))), so each
sampler's error is measured against ground truth, not against another sampler. Reported per annulus
of |q| (height units; the pull's local scale is |f'| = n |z|^(n-1) = 7 |q| for n = 2, L = 1.75):
  rel err   rms(out - exact) / rms(exact - mean)
  amp       std(out) / std(exact)       < 1 smear (blur), > 1 aliasing noise
Two images: a 24 px and an 8 px wavelength component (at 192 x 108; the wavelengths in texels are
what matter, so the verdict carries to 1080p only for features of the same size in texels).
Also the float32 drift of the identity map (the float64 mirror holds 4e-13 over 50 frames).

Run: tests/py.sh tests/records/spike_cmap_smear.py
"""
import numpy as np

import cmap_mirror as m

H, W = 108, 192
A = W / H
WC = (0.15, 0.0)
N = 2
BINS = [(0.0, 0.08), (0.08, 0.20), (0.20, 0.35), (0.35, 0.50), (0.50, 0.95)]
KS = (1, 3, 10)


def make_image(cycles):
    """RGB-style band-limited periodic image I(px, py); cycles = ((fx, fy), (gx, gy)) integers."""
    (fx, fy), (gx, gy) = cycles
    ph = np.array([[0.3, 1.7], [2.2, 0.4], [4.1, 5.0]])

    def img(px, py):
        out = np.empty(px.shape + (4,))
        for c in range(3):
            out[..., c] = (0.5 + 0.25 * np.cos(2 * np.pi * (fx * px + fy * py) + ph[c, 0])
                           + 0.25 * np.cos(2 * np.pi * (gx * px + gy * py) + ph[c, 1]))
        out[..., 3] = 1.0
        return out
    return img


def exact(img, k, n=N, wc=WC):
    px, py = m.centred_p(H, W)
    for _ in range(k):
        ppx, ppy = m.pull_point(px, py, A, n, wc)
        px, py = ppx - np.floor(ppx), ppy - np.floor(ppy)
    return img(px, py)


def annuli():
    px, py = m.centred_p(H, W)
    r = np.hypot((px - 0.5) * A, py - 0.5)
    return r, [(r >= lo) & (r < hi) for lo, hi in BINS]


def run_case(img, sampler, kmax=max(KS)):
    outs = m.run_temporal(lambda k: img(*m.centred_p(H, W)), kmax, lambda k: WC, sampler=sampler, keep=True,
                          n=N, decay=1.0, inject=0.0, bounds="wrap")
    return outs


def main():
    r, masks = annuli()
    fprime = 7.0 * r
    print("f_cmap T004: sampler error against the exact composition  (n = 2, w = (0.15, 0), wrap bounds,"
          " decay 1, inject 0, float64)")
    print("annulus |q|          " + "  ".join(f"{lo:.2f}-{hi:.2f}" for lo, hi in BINS))
    print("mean |f'|            " + "  ".join(f"{float(fprime[mk].mean()):9.2f}" for mk in masks))
    images = {"24 px wavelength": make_image(((8, 4), (8, 4))), "8 px wavelength": make_image(((24, 13), (24, 13)))}
    for name, img in images.items():
        print(f"\n--- image: {name} ---   cells: rel err / amp")
        refs = {k: exact(img, k) for k in KS}
        for sampler in m.SAMPLERS:
            outs = run_case(img, sampler)
            for k in KS:
                row = []
                for mk in masks:
                    d = outs[k][..., :3][mk] - refs[k][..., :3][mk]
                    e = refs[k][..., :3][mk]
                    rel = np.sqrt((d ** 2).mean()) / max(np.sqrt(((e - e.mean()) ** 2).mean()), 1e-12)
                    amp = outs[k][..., :3][mk].std() / max(e.std(), 1e-12)
                    row.append(f"{rel:5.2f}/{amp:4.2f}")
                print(f"{sampler:9s} k={k:<3d}      " + "  ".join(f"{c:>9s}" for c in row))
    print("\n--- float32 identity-map drift (n = 1, w = 0, decay 1, inject 0, noise 96x54), max |out - src| ---")
    img0 = m.noise_image(54, 96, seed=3, dtype=np.float32)
    for sampler in ("bilinear", "catmull"):
        prev = img0.copy()
        marks = {50, 500, 3000}
        res = []
        for k in range(1, 3001):
            prev = m.frame(prev, img0, n=1, w=(0.0, 0.0), decay=1.0, inject=0.0, sampler=sampler)
            if k in marks:
                res.append(f"{k} frames: {float(np.abs(prev[..., :3] - img0[..., :3]).max()):.2e}")
        print(f"{sampler:9s}  " + "   ".join(res))


if __name__ == "__main__":
    main()
