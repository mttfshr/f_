"""Scratch: the mirror at Matt's live settings on a camera-like tensor (small window), half 1080p.
  uv run --no-project --with numpy --with pillow python3 .specify/f_tf_hatch/spike/camera_like.py"""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch"), str(Path(__file__).parent)]
import numpy as np
from PIL import Image
import lic_stills as S
from tf_hatch_mirror import chain, fill_from_density, stage_e1
S.H, S.W = 270, 480
img = S.source(0.08)
tex, strength = S.tensor_tex(img, window=1.26)
aux = stage_e1(tex, strength, 0.0, 0.13, "unsigned_nearest")
print("coherence: mean %.2f  p25 %.2f  p50 %.2f  p75 %.2f   presence mean %.2f" % (aux[..., 2].mean(), *np.percentile(aux[..., 2], [25, 50, 75]), aux[..., 3].mean()))
outs = []
for label, kw in [("A: as shipped (mix pow .5), offset .76", dict()), ("B: persist OFF (strict LIC), offset .76", dict(persist="off")),
                  ("C: as shipped, offset 0", dict(angle_offset=0.0))]:
    p = dict(strength=strength, floor=0.13, aux_mode="unsigned_nearest", n_steps=16, length=0.63, grain=0.62,
             contrast=0.95, line=1.0, angle_offset=0.76, fill=float(fill_from_density(1.0)))
    p.update(kw)
    o = chain(tex, **p)[0][..., 0]
    print(label, "mean %.3f" % o.mean())
    outs.append(o)
sheet = np.concatenate([np.concatenate([o, np.full((S.H, 4), 0.5)], 1) for o in outs] + [img[:, :, None][..., 0] * 0 + np.clip(img, 0, 1)], 1)
Image.fromarray((np.clip(sheet, 0, 1) * 255).astype(np.uint8)).save("/Users/matt/Desktop/hatch_camera_like.png")
print("saved")
