"""Phase-0 stills 2: SPARSE input noise (impulses smeared into strokes). Scratch.
  uv run --no-project --with numpy --with pillow python3 .specify/f_tf_hatch/spike/lic_stills_sparse.py [out.png]
Rows: clean source, noisy source, synthetic coherence ramp (0 -> 1 left to right, axis 30 deg).
Columns: dense reference | fill .01 len .5 | fill .01 len .25 | fill .03 len .25 | fill .01 len .25 line=1
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch"), str(Path(__file__).parent)]

import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402
import lic_stills as S  # noqa: E402  (reuses source() and tensor_tex(); its own sheet is rewritten, harmless)
from tf_hatch_lic_mirror import F32, chain  # noqa: E402

H, W = S.H, S.W
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/Users/matt/Desktop/hatch_lic_sparse.png")


def ramp_tex():
    y, x = np.mgrid[0:H, 0:W].astype(np.float64)
    c = x / (W - 1)                                   # coherence 0 -> 1
    a = np.deg2rad(30.0)
    gx, gy = np.cos(a + np.pi / 2), np.sin(a + np.pi / 2)
    tr = 0.01
    Jxx = tr * ((1 - c) / 2 + c * gx * gx)
    Jxy = tr * (c * gx * gy)
    Jyy = tr * ((1 - c) / 2 + c * gy * gy)
    tex = np.zeros((H, W, 4), F32)
    tex[..., 0] = Jxx * 100.0
    tex[..., 1] = Jxy * 100.0 * 0.5 + 0.5
    tex[..., 2] = Jyy * 100.0
    tex[..., 3] = 1.0
    return tex, 100.0, c


variants = [
    ("dense", dict(fill=None, length=0.5, line=0.0)),
    ("f.01 L.5", dict(fill=0.01, length=0.5, line=0.0)),
    ("f.01 L.25", dict(fill=0.01, length=0.25, line=0.0)),
    ("f.03 L.25", dict(fill=0.03, length=0.25, line=0.0)),
    ("f.01 L.25 line", dict(fill=0.01, length=0.25, line=1.0)),
]


def to_img(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


rows = []
for noise in (0.05, 0.5):
    img = S.source(noise)
    tex, strength = S.tensor_tex(img)
    rows.append([chain(tex, strength=strength, floor=0.08, **kw)[0][..., 0] for _, kw in variants])
tex, strength, c = ramp_tex()
rows.append([chain(tex, strength=strength, floor=0.0, **kw)[0][..., 0] for _, kw in variants])

sheet = Image.new("L", (W * 5 + 16, H * 3 + 8), 255)
for j, row in enumerate(rows):
    for i, a in enumerate(row):
        sheet.paste(to_img(a), (i * (W + 4), j * (H + 4)))
sheet.save(OUT)
print("saved", OUT)
for j, row in enumerate(rows):
    print("row", j, "mean luma per variant:", [round(float(a.mean()), 3) for a in row])
