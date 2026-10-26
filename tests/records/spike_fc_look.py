"""spike_fc_look.py -- f_wc Phase 0, T004: retinotopic look stills
from the mirror at the fine web scale, judged offline BEFORE any Max session.

Renders the sustained Example-10 field through the shared enc map at several
corners to scratch/fc_enc/ (gitignored): parity map (zoom 1 / twist 1 /
fovea 0.003) and the closer corner (5 / 3 / 1.0), each at r_soft {0.35, 0.0}
and sharp {0.5, 1.0}. PPM written by the mirror path, PNG via sips.

ENERGY should track the T002 verdict.

Run from the repo root: uv run --no-project --with numpy python3 tests/records/spike_fc_look.py
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(REPO, "tests", "lib"))
sys.path.insert(0, os.path.join(REPO, "tests", "modules", "wc"))

import numpy as np  # noqa: E402
from wc_steadyweb_mirror import F32, Params, encode, run, seed_state  # noqa: E402

ENERGY = 0.0        # <-- set from the T002 verdict
N = 512
FRAMES = 700
OUT = os.path.join(REPO, "scratch", "fc_enc")


def write_ppm(path, img):
    h, w = img.shape[0], img.shape[1]
    rgb = (np.clip(img[..., :3], 0, 1) * 255).astype(np.uint8)
    with open(path, "wb") as f:
        f.write(f"P6 {w} {h} 255\n".encode())
        f.write(rgb.tobytes())


def main():
    os.makedirs(OUT, exist_ok=True)
    P = Params(grain=1.0 / N, energy=0.75, habituation=0.9)
    st, _ = run(seed_state(N, N, 1), P, FRAMES,
                seed=(7 if ENERGY > 0 else None), fast_blur=True)
    e = st[..., 0]
    print(f"field after {FRAMES} frames: E mean {float(e.mean()):.3f} "
          f"std {float(e.std()):.3f}")

    corners = [("parity", 1.0, 1.0, 0.003), ("closer", 5.0, 3.0, 1.0)]
    for name, ke, ka, r0 in corners:
        for rs in (0.35, 0.0):
            for sharp in (0.5, 1.0):
                img = encode(st, (512, 512), sharp=F32(sharp),
                             k_ecc=F32(ke), k_ang=F32(ka), r0=F32(r0),
                             r_soft=F32(rs))
                stem = os.path.join(
                    OUT, f"{name}_rs{int(rs * 100):03d}_sh{int(sharp * 10):02d}")
                write_ppm(stem + ".ppm", img)
                subprocess.run(["sips", "-s", "format", "png",
                                stem + ".ppm", "--out", stem + ".png"],
                               check=True, capture_output=True)
                print(f"wrote {stem}.png")


if __name__ == "__main__":
    main()
