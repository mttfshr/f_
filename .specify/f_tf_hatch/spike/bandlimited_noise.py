"""Scratch: band-limited impulses (rotated value noise, thresholded) vs the shipped lit lattice cells.
Mirror only, half 1080p. B's noise gain is matched so mean raw march value equals A's (fair brightness).
  uv run --no-project --with numpy --with pillow python3 .specify/f_tf_hatch/spike/bandlimited_noise.py [out.png]
Columns: source | coherence | A shipped (lit cells) | B band-limited blobs
Gentle settings: contrast .5, line .5 (soft), reach .4; density/grain vary per row.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch")]

import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402
import tf_hatch_mirror as M  # noqa: E402
from tf_hatch_mirror import F32, fill_from_density, stage_e1, stage_e2, stage_e3  # noqa: E402

H, W = 270, 480
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/Users/matt/Desktop/hatch_bandlimited2.png")
ROT = 0.61     # lattice rotation (rad): keeps the blobs off the pixel axes
SOFT = 0.35    # threshold ramp half-width, in std of the noise
KSCALE = [1.0]  # B's brightness match (set per row)


def gauss(a, s):
    ky = np.fft.fftfreq(a.shape[0])[:, None]
    kx = np.fft.fftfreq(a.shape[1])[None, :]
    return np.fft.ifft2(np.fft.fft2(a) * np.exp(-2 * (np.pi * s) ** 2 * (kx ** 2 + ky ** 2))).real


def source(noise, seed=0):
    y, x = np.mgrid[0:H, 0:W].astype(np.float64)
    img = 0.5 + 0.5 * np.cos(np.hypot(x - 190, y - 95) * 0.55)
    stripes = 0.5 + 0.5 * np.sin((x * 0.5 + y * 0.9) * 0.7)
    wl = np.clip((90 - x) / 30.0, 0, 1)
    img = img * (1 - wl) + stripes * wl
    img = img + 0.7 * np.exp(-((x - 60) ** 2 + (y - 140) ** 2) / 200.0)
    flat = np.clip((x - 270) / 20.0, 0, 1)
    img = img * (1 - flat) + 0.5 * flat
    return np.clip(img + noise * np.random.default_rng(seed).standard_normal((H, W)), -1, 2)


def tensor_tex(img, window=1.26):
    gy, gx = np.gradient(gauss(img, 1.0))
    jxx, jxy, jyy = gauss(gx * gx, window), gauss(gx * gy, window), gauss(gy * gy, window)
    strength = 1.0 / max(np.percentile(jxx + jyy, 75), 1e-9)
    tex = np.zeros((H, W, 4), F32)
    tex[..., 0], tex[..., 1], tex[..., 2], tex[..., 3] = jxx * strength, jxy * strength * 0.5 + 0.5, jyy * strength, 1.0
    return tex, strength


def _fade(t):
    return t * t * t * (t * (t * 6 - 15) + 10)


def value_noise(px, py, cell_px, seed=0):
    """Quintic value noise on a ROTATED lattice, world coords. Offset keeps indices positive."""
    c, s = F32(np.cos(ROT)), F32(np.sin(ROT))
    off = F32((W + H) / cell_px)
    u = (c * px - s * py) / F32(cell_px) + off + F32(17.3 * seed)
    v = (s * px + c * py) / F32(cell_px) + off + F32(9.1 * seed)
    iu, iv = np.floor(u), np.floor(v)
    fu, fv = _fade(u - iu), _fade(v - iv)
    h = M.hash12
    return ((h(iu, iv) * (1 - fu) + h(iu + 1, iv) * fu) * (1 - fv)
            + (h(iu, iv + 1) * (1 - fu) + h(iu + 1, iv + 1) * fu) * fv).astype(F32)


_CAL = {}


def calibrate(fill):
    key = round(float(fill), 5)
    if key not in _CAL:
        yy, xx = np.mgrid[0:600, 0:600].astype(F32)
        n = value_noise(xx + 0.5, yy + 0.5, 12.0)
        thr, w = float(np.quantile(n, 1 - fill)), SOFT * float(n.std())
        _CAL[key] = (thr, w, float(fill / M._smoothstep(thr - w, thr + w, n).mean()))
    return _CAL[key]


def blob_noise(px, py, cell_px, seed=0, fill=None):
    thr, w, k = calibrate(fill)
    return (F32(k * KSCALE[0]) * M._smoothstep(thr - w, thr + w, value_noise(px, py, cell_px, seed))).astype(F32)


def run(aux, blobs, grain, fill, reach, contrast, line):
    orig = M.noise_at
    if blobs:
        M.noise_at = blob_noise
    try:
        aux2 = stage_e2(aux, 16, reach, grain, "mix", M.PERSIST_POW, "unsigned_nearest", fill=fill)
    finally:
        M.noise_at = orig
    return aux2, stage_e3(aux2, 16, contrast, line, 0.0, fill=fill)[0][..., 0]


def im(a):
    return np.clip(a, 0, 1)


CONTRAST, LINE = 0.5, 0.5
rows = []
for label, noise, grain, dens, reach in [("clean g.62 d.4", 0.08, 0.62, 0.4, 0.4), ("noisy g.62 d.4", 0.5, 0.62, 0.4, 0.4),
                                          ("noisy g.50 d.3", 0.5, 0.50, 0.3, 0.4), ("noisy g.70 d.5 reach.6", 0.5, 0.70, 0.5, 0.6)]:
    img = source(noise)
    tex, strength = tensor_tex(img)
    aux = stage_e1(tex, strength, 0.0, 0.08, "unsigned_nearest")
    coh = aux[..., 2]
    fill = float(fill_from_density(dens))
    KSCALE[0] = 1.0
    a2, a = run(aux, False, grain, fill, reach, CONTRAST, LINE)
    b2, _ = run(aux, True, grain, fill, reach, CONTRAST, LINE)
    KSCALE[0] = float(a2[..., 0].mean() / max(b2[..., 0].mean(), 1e-9))
    b2, b = run(aux, True, grain, fill, reach, CONTRAST, LINE)
    print("%-24s coh %.2f | raw A %.3f B %.3f (k %.2f) | out A %.3f B %.3f" % (
        label, coh.mean(), a2[..., 0].mean(), b2[..., 0].mean(), KSCALE[0], a.mean(), b.mean()))
    rows.append([im((img - img.min()) / (img.max() - img.min())), coh, a, b])

sep = 4
sheet = np.full((len(rows) * (H + sep), 4 * (W + sep)), 0.5, np.float32)
for j, r in enumerate(rows):
    for i, a in enumerate(r):
        sheet[j * (H + sep):j * (H + sep) + H, i * (W + sep):i * (W + sep) + W] = a
Image.fromarray((sheet * 255).astype(np.uint8)).save(OUT)
print("saved", OUT)
