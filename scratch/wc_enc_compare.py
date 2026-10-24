"""scratch render: enc foveal-softening comparison (2026-10-24, Matt: 'theirs looks better').

Renders ONE mirror-simulated cortical field (shipped corner, 300 frames) through
encode() variants — foveal soften s in {0.05, 0.15, 0.35} x {4-tap, 2x2 supersample} —
zoom 5 / twist 3 / fovea 1.0 (the shipped defaults), 768x768, to PPMs in scratch/wc_enc/.
Convert to PNG with sips and eyeball.
"""
import os, sys
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests", "lib"))
sys.path.insert(0, os.path.join(HERE, "..", "tests", "modules", "wc"))
from gpu_sim import F32  # noqa: E402
import wc_mirror as km  # noqa: E402

OUT = os.path.join(HERE, "wc_enc")
os.makedirs(OUT, exist_ok=True)
SZ = 768

P = km.Params(rate=1.0, texture=1.4, ne=1.0, fast_fft=True)
rng = np.random.default_rng(7)
state = km.seed_state(256, 256, 7)
for _ in range(300):
    state = km.wc_frame(state, rng, P)

E = state[..., 0].astype(np.float64)
N = E.shape[0]

ny, nx = np.meshgrid((np.arange(SZ) + 0.5) / SZ, (np.arange(SZ) + 0.5) / SZ, indexing="xy")
px = (nx * 2 - 1) * 4
py = (ny * 2 - 1) * 4
r0 = np.hypot(px, py)
th = np.arctan2(py, px)


def bilinear(fx, fy):
    x0 = np.mod(np.floor(fx), N); x1 = np.mod(x0 + 1, N)
    y0 = np.mod(np.floor(fy), N); y1 = np.mod(y0 + 1, N)
    tx = fx - np.floor(fx); ty = fy - np.floor(fy)
    x0i, x1i, y0i, y1i = x0.astype(int), x1.astype(int), y0.astype(int), y1.astype(int)
    return ((E[y0i, x0i] * (1 - tx) + E[y0i, x1i] * tx) * (1 - ty)
            + (E[y1i, x0i] * (1 - tx) + E[y1i, x1i] * tx) * ty)


ZOOM, TWIST, FOVEA = 5, 3, 1.0   # map dials; render() varies only soft s

def render(s, ss):
    u_all = np.zeros((SZ * ss, SZ * ss) if ss > 1 else ())
    if ss > 1:
        offs = [( (a + 0.5) / ss - 0.5, (b + 0.5) / ss - 0.5)
                 for a in range(ss) for b in range(ss)]
        acc = np.zeros((SZ, SZ))
        for ox, oy in offs:
            sx, sy = ox / SZ * 8, oy / SZ * 8
            rr = np.hypot(px + sx, py + sy)
            u = ZOOM * np.log1p(np.sqrt(rr * rr + s * s) / FOVEA)
            v = TWIST * np.arctan2(py + sy, px + sx)
            cu = np.mod(u / (2 * np.pi), 1.0) * N - 0.5
            cv = np.mod(v / (2 * np.pi), 1.0) * N - 0.5
            acc += bilinear(cv, cu)
        return acc / (ss * ss)
    u = ZOOM * np.log1p(np.sqrt(r0 * r0 + s * s) / FOVEA)
    v = TWIST * th
    cu = np.mod(u / (2 * np.pi), 1.0) * N - 0.5
    cv = np.mod(v / (2 * np.pi), 1.0) * N - 0.5
    return bilinear(cv, cu)


import sys as _sys
ZOOM_, TWIST_, FOVEA_ = (float(x) for x in _sys.argv[1:4]) if len(_sys.argv) > 3 else (ZOOM, TWIST, FOVEA)
ZOOM, TWIST, FOVEA = ZOOM_, TWIST_, FOVEA_

def sm(x, e0, e1):
    t = np.clip((x - e0) / (e1 - e0), 0, 1); return t * t * (3 - 2 * t)

for s, ss, tag in [(0.0, 1, 's000'), (0.05, 1, 's005'), (0.15, 1, 's015'), (0.35, 1, 's035'), (0.0, 2, 's000ss'), (0.15, 2, 's015ss')]:
    img = render(s, ss)
    soft = np.clip(img, 0, 1)
    lum = soft * 0.5 + sm(soft, 0.46, 0.54) * 0.5
    q = (np.clip(lum, 0, 1) * 255).astype(np.uint8)
    with open(os.path.join(OUT, f"{tag}_sharp.ppm"), "wb") as f:
        f.write(f"P6\n{SZ} {SZ}\n255\n".encode()); f.write(np.dstack([q, q, q]).tobytes())
print("wrote", [x for x in sorted(os.listdir(OUT)) if x.endswith('sharp.ppm')])
