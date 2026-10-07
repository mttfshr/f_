"""Diagnostic for glass_vs_fieldmap.py: is the fieldmap-vs-analytic difference the UV inset or the finite difference?"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import numpy as np
import glass_vs_fieldmap as gv
cf, F32, W = gv.cf, gv.F32, gv.W
c = (np.arange(W) + 0.5) / W
X, Y = np.meshgrid(c, c)
h = gv.height(X, Y); hmin, hmax = float(h.min()), float(h.max())
L01 = ((h - hmin) / (hmax - hmin)).astype(F32)
ax, ay = cf.field(X, Y)[:2]
A = gv.to_tex(ax, ay); dstar = cf.first_fold_distance()
s = 0.012; gain = (hmax - hmin) / (2 * s)
for inset in (True, False):
    Bx, By = gv.fieldmap(gv.luma_tex(L01), gain, s, inset=inset)
    B = gv.to_tex(Bx, By)
    inner = (slice(40, W - 40), slice(40, W - 40))      # skip the border where an un-inset sample would clamp
    err = gv.rms_rel(np.stack([Bx[inner], By[inner]]), np.stack([ax[inner], ay[inner]]))
    print(f"s={s} inset={inset}: field error vs analytic (interior) {err:.4f}")
    for fr in (1.0, 3.5):
        d = fr * dstar; m = cf.interior(d)
        ia, ib = gv.caustic(A, d), gv.caustic(B, d)
        print(f"   d={fr} d*: caustic r vs analytic {cf.pearson(ib[m], ia[m]):.4f}  IoU {cf.top_iou(ib[m], ia[m]):.3f}")
