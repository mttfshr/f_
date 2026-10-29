"""Scratch: how much does each dial change the mirror's output on a structured scene?
  uv run --no-project --with numpy --with pillow python3 .specify/f_tf_hatch/spike/dial_effects.py"""
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
sys.path[:0] = [str(ROOT / "tests/lib"), str(ROOT / "tests/modules/tf_hatch"), str(Path(__file__).parent)]
import numpy as np
import lic_stills as S
from tf_hatch_mirror import chain, fill_from_density
tex, strength = S.tensor_tex(S.source(0.05))
base = dict(strength=strength, floor=0.1, aux_mode="unsigned_nearest", n_steps=16, length=0.5, grain=0.5,
            contrast=0.5, line=0.0, angle_offset=0.0, fill=float(fill_from_density(0.7)))
def run(**kw):
    p = dict(base); p.update(kw)
    return chain(tex, **p)[0][..., 0]
ref = run()
print("ref mean %.4f  frac>0.5 %.4f  frac in (0.05,0.95) %.4f" % (ref.mean(), (ref > .5).mean(), ((ref > .05) & (ref < .95)).mean()))
for name, kw in [("contrast 0", dict(contrast=0.0)), ("contrast 1", dict(contrast=1.0)), ("line 1", dict(line=1.0)),
                 ("offset +1", dict(angle_offset=1.0)), ("offset +.5", dict(angle_offset=0.5)), ("strength x4", dict(strength=strength * 4)),
                 ("grain .42", dict(grain=.42)), ("grain .57", dict(grain=.57)), ("grain .69", dict(grain=.69))]:
    o = run(**kw)
    print("%-12s mean %.4f  mean|diff| %.4f  frac pixels changed>0.1: %.3f" % (name, o.mean(), np.abs(o - ref).mean(), (np.abs(o - ref) > .1).mean()))
