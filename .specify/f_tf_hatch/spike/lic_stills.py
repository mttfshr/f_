"""Phase-0 stills for f_tf_hatch v2 (scratch). Renders the mirror on image-derived tensors.
  uv run --no-project --with numpy --with pillow python3 .specify/f_tf_hatch/spike/lic_stills.py [out.png]
Rows: a clean-ish source, then the same source with heavy camera-like noise.
Columns: source | coherence | LIC smooth | LIC line=1 | coherence ignored (the trap)
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch")]

import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402
from tf_hatch_lic_mirror import F32, chain, stage_e1  # noqa: E402

H, W = 180, 320
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/Users/matt/Desktop/hatch_lic_stills.png")


def gauss(a, s):
    """Gaussian blur by FFT (numpy only)."""
    ky = np.fft.fftfreq(a.shape[0])[:, None]
    kx = np.fft.fftfreq(a.shape[1])[None, :]
    g = np.exp(-2 * (np.pi * s) ** 2 * (kx ** 2 + ky ** 2))
    return np.fft.ifft2(np.fft.fft2(a) * g).real


def source(noise, seed=0):
    y, x = np.mgrid[0:H, 0:W].astype(np.float64)
    r = np.hypot(x - 190, y - 95)
    img = 0.5 + 0.5 * np.cos(r * 0.55)                           # concentric rings
    stripes = 0.5 + 0.5 * np.sin((x * 0.5 + y * 0.9) * 0.7)       # diagonal stripes, left third
    wl = np.clip((90 - x) / 30.0, 0, 1)
    img = img * (1 - wl) + stripes * wl
    img = img + 0.7 * np.exp(-((x - 60) ** 2 + (y - 140) ** 2) / 200.0)   # a blob
    flat = np.clip((x - 270) / 20.0, 0, 1)                        # flat region on the right
    img = img * (1 - flat) + 0.5 * flat
    rng = np.random.default_rng(seed)
    return np.clip(img + noise * rng.standard_normal((H, W)), -1, 2)


def tensor_tex(img, window=3.0):
    """Structure tensor, Gaussian window, packed in outlet-0 format (f_tensor_type.md)."""
    gy, gx = np.gradient(gauss(img, 1.0))
    jxx, jxy, jyy = gauss(gx * gx, window), gauss(gx * gy, window), gauss(gy * gy, window)
    tr = jxx + jyy
    strength = 1.0 / max(np.percentile(tr, 75), 1e-9)             # tensormap-style calibration
    tex = np.zeros((H, W, 4), F32)
    tex[..., 0] = jxx * strength
    tex[..., 1] = jxy * strength * 0.5 + 0.5
    tex[..., 2] = jyy * strength
    tex[..., 3] = 1.0
    return tex, strength


def to_img(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


rows = []
for label, noise in (("clean", 0.05), ("noisy", 0.5)):
    img = source(noise)
    tex, strength = tensor_tex(img)
    aux = stage_e1(tex, strength, floor=0.0)
    coh = aux[..., 2]
    kw = dict(strength=strength, floor=0.08)
    smooth = chain(tex, line=0.0, **kw)[0][..., 0]
    lines = chain(tex, line=1.0, **kw)[0][..., 0]
    trap = chain(tex, line=0.0, persist="off", **kw)[0][..., 0]
    rows.append([to_img((img - img.min()) / (img.max() - img.min())), to_img(coh), to_img(smooth), to_img(lines), to_img(trap)])
    print(label, "strength", round(strength, 1), "coherence mean", round(float(coh.mean()), 3))

sheet = Image.new("L", (W * 5 + 4 * 4, H * 2 + 4), 255)
for j, row in enumerate(rows):
    for i, im in enumerate(row):
        sheet.paste(im, (i * (W + 4), j * (H + 4)))
sheet.save(OUT)
print("saved", OUT)
