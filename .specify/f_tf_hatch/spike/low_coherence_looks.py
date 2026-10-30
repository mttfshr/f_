"""
SPIKE (mirror only, nothing shipped): three looks for the LOW-COHERENCE regions of f_tf_hatch.
  Clouds     today: coherence only straightens the march (random walk where incoherent -> soft smudge)
  Dark       strokes fade out as the pixel's OWN coherence drops: out * smoothstep(lo, hi, coh)
             (exactly what gating E1's presence would do: E3 multiplies by presence, E2 passes it through)
  Terminate  the march stops contributing where the coherence along the path is low: alive *= smoothstep(lo, hi, coh)
             (a patched copy of the mirror's stage_e2, `term=(lo, hi)`): undirected regions keep only the
             pixel's own impulse -- dots (blobs) or the texture showing through unstreaked
Rows: blobs / noisy scene | texture / noisy scene | blobs / clean scene.  Columns: source | coherence | Clouds | Dark | Terminate.
  uv run --no-project --with numpy --with pillow python3 .specify/f_tf_hatch/spike/low_coherence_looks.py [out.png]
"""
import inspect
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch")]

import numpy as np  # noqa: E402
from PIL import Image  # noqa: E402
import tf_hatch_mirror as M  # noqa: E402
from tf_hatch_mirror import F32, fill_from_density  # noqa: E402

H, W = 270, 480
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/Users/matt/Desktop/hatch_low_coherence.png")
LO, HI = 0.4, 0.6          # the coherence ramp (both Dark and Terminate), a first guess

# a patched copy of stage_e2 with an optional coherence-termination term
_src = inspect.getsource(M.stage_e2)
_old = "            alive = alive * ((nx_ >= 0) & (nx_ <= W) & (ny_ >= 0) & (ny_ <= H)).astype(F32)\n"
assert _old in _src
_src = _src.replace(_old, _old + "            if term is not None:\n"
                    "                alive = alive * _smoothstep(F32(term[0]), F32(term[1]), samp[..., 2]).astype(F32)\n")
assert "texture=None):" in _src
_src = _src.replace("texture=None):", "texture=None, term=None):", 1)
_ns = dict(M.__dict__)
exec(_src, _ns)
stage_e2_term = _ns["stage_e2"]


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
    return tex


def stroke_texture(seed=4):
    t = np.zeros((H, W, 4), F32)
    t[..., 0] = t[..., 1] = t[..., 2] = np.random.default_rng(seed).random((H, W)).astype(F32)
    t[..., 3] = 1.0
    return t


def looks(tex, coh, mode):
    """(clouds, dark, terminate) images for one scene. mode: 'blobs' or 'texture'."""
    if mode == "blobs":
        p = dict(reach=0.4, grain=0.62, density=0.5, contrast=0.6, line=0.5)
        kw = dict(noise="blobs")
    else:
        p = dict(reach=0.4, grain=1.0, density=0.3, contrast=0.6, line=0.5)
        kw = dict(texture=stroke_texture())
    fill = float(fill_from_density(p["density"]))
    aux = M.stage_e1(tex, 0.0, 0.08, "unsigned_nearest")
    out = []
    for term in (None, None, (LO, HI)):
        aux2 = stage_e2_term(aux, 16, p["reach"], p["grain"], "mix", M.PERSIST_POW, "unsigned_nearest", fill=fill, term=term, **kw)
        out.append(M.stage_e3(aux2, 16, p["contrast"], p["line"], 0.0, fill=fill)[0][..., 0])
    out[1] = out[1] * M._smoothstep(F32(LO), F32(HI), coh).astype(F32)       # Dark = clouds x coherence gate
    return [np.clip(o, 0, 1) for o in out]


rows = []
for label, noise, mode in (("blobs, noisy scene", 0.5, "blobs"), ("texture, noisy scene", 0.5, "texture"), ("blobs, clean scene", 0.08, "blobs")):
    img = source(noise)
    tex = tensor_tex(img)
    coh = M.stage_e1(tex, 0.0, 0.08, "unsigned_nearest")[..., 2]
    cl, dk, tm = looks(tex, coh, mode)
    print("%-22s coh mean %.2f | mean out: clouds %.3f dark %.3f terminate %.3f" % (label, coh.mean(), cl.mean(), dk.mean(), tm.mean()))
    rows.append([(img - img.min()) / (img.max() - img.min()), coh, cl, dk, tm])

sep = 4
sheet = np.full((len(rows) * (H + sep), 5 * (W + sep)), 0.5, np.float32)
for j, r in enumerate(rows):
    for i, a in enumerate(r):
        sheet[j * (H + sep):j * (H + sep) + H, i * (W + sep):i * (W + sep) + W] = a
Image.fromarray((np.clip(sheet, 0, 1) * 255).astype(np.uint8)).save(OUT)
print("saved", OUT)
