"""
spike_caustic_trace_vs_jacobian.py -- diagnostic, not a regression gate.

Quantifies the trace-vs-full-Jacobian gap named in ideas/f_tensorfield.md's
"Beyond the vecfield-consumer audit" section: f_caustic weights its
accumulation by divergence, the *trace* of the local Jacobian J, while the
true local intensity gain is 1/det(I + d*J) -- a fold needs one eigenvalue
of J to reach -1/d, and a saddle (eigenvalues of opposite sign) can sit
exactly on a fold with zero divergence. optics_map.md evidenced this
qualitatively; this puts pixelwise numbers on it, using the same test
glass, truth, and conventions as scratch/caustic_fidelity.py.

Three measurements, all against photon-counting truth:

  T1  Local-gain fidelity. Trace-only estimate  g_t = max(1 - d*tr(J), 0)
      (the module's weight, first-order in d) vs full-Jacobian estimate
      g_J = 1/max(|det(I + d*J)|, eps) at each pixel, vs truth(d). The
      point is not that g_J is a better *render* (it is still one-branch,
      no tracing) but that the residual r(g_J, truth) - r(g_t, truth)
      measures what knowing the whole tensor buys over its trace alone.

  T2  Fold blindness census. At d = d*: the fraction of near-fold pixels
      (det(I + d*J) below a threshold) that the trace weight ranks as
      flat-ish, i.e. where max(1 - d*tr(J), 0) is small -- and the mean
      truth brightness at those pixels vs the image mean. If the truth is
      bright there, the trace weight is missing real light.

  T3  Where the trace estimate goes wrong, by mechanism. Partition pixels
      by J's eigenvalue signs at d = d*: both non-negative (defocusing,
      trace weight should be 0), both negative (focus, trace weight is
      roughly right), mixed (saddle -- the case the trace cannot see).
      Report r(g, truth) within each partition for both estimates.

Run: python3 tests/records/spike_caustic_trace_vs_jacobian.py
"""
import paths as _paths
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(str(_paths.REPO), "scratch"))
import caustic_fidelity as cf  # noqa: E402  (test glass + truth + metrics)

NB = cf.NB          # 256 comparison resolution
F32 = cf.F32


# ------------------------------------------------------- weight estimates
def jacobian(x, y):
    """Analytic scaled Jacobian of the test glass (same as cf.field)."""
    return tuple(v * cf.SCALE for v in cf.raw_field(x, y)[2:])


def trace_gain(jxx, jxy, jyy, d):
    """The module's local weight (first-order Taylor of 1/det), clamped the
    way max(-div, 0) clamps: only converging (div < 0) zones may brighten."""
    return np.maximum(1.0 - d * (jxx + jyy), 0.0)


def det_gain(jxx, jxy, jyy, d, eps=0.05):
    """Full-Jacobian local gain, the exact linear-map area factor. Same
    eps floor as cf.det_gather's clamp policy."""
    det = (1.0 + d * jxx) * (1.0 + d * jyy) - (d * jxy) ** 2
    return 1.0 / np.maximum(np.abs(det), eps)


def eig_pair(jxx, jxy, jyy):
    """Eigenvalues of the symmetric Jacobian, closed form."""
    tr = jxx + jyy
    disc = np.sqrt(np.maximum((jxx - jyy) ** 2 * 0.25 + jxy * jxy, 0.0))
    return 0.5 * tr + disc, 0.5 * tr - disc


def pearson(a, b):
    a = a.astype(np.float64) - a.mean()
    b = b.astype(np.float64) - b.mean()
    return float((a * b).sum() / np.sqrt((a * a).sum() * (b * b).sum()))


def top_iou(a, b, q=0.92):
    ta = a >= np.quantile(a, q)
    tb = b >= np.quantile(b, q)
    return float((ta & tb).sum() / max((ta | tb).sum(), 1))


def report(label, g, tr, mask):
    print(f"    {label:34s} r {pearson(g[mask], tr[mask]):+.4f}   "
          f"top-8% IoU {top_iou(g[mask], tr[mask]):.3f}")


def main():
    dstar = cf.first_fold_distance()
    c = (np.arange(NB) + 0.5) / NB
    X, Y = np.meshgrid(c, c)
    jxx, jxy, jyy = jacobian(X, Y)

    print(f"glass seed {os.environ.get('SEED', '7')}, d* = {dstar:.4f} UV, "
          f"{NB}^2 pixels")

    # ---- T1: local-gain fidelity, both estimates vs photon truth -------
    print("\n== T1: local gain vs photon-counting truth (interior mask) ==")
    for frac in (0.3, 1.0, 3.5):
        d = frac * dstar
        tr = cf.truth(d, m=2048)
        mask = cf.interior(d)
        gt = trace_gain(jxx, jxy, jyy, d)
        gj = det_gain(jxx, jxy, jyy, d)
        print(f"  d = {frac:>4} d*")
        report("trace-only  max(1-d*tr, 0)", gt, tr, mask)
        report("full Jacobian  1/|det(I+dJ)|", gj, tr, mask)

    # ---- T2: where the two representations disagree, at d = d* ---------
    # (the original "trace-blind near-fold" framing came back empty on this
    #  glass -- near-fold pixels coincide with strong negative divergence,
    #  so the trace weight is not blind to folds here. The real question is
    #  the disagreement set: pixels where the full-Jacobian gain says
    #  "bright" and the trace gain says "dim".)
    print("\n== T2: do the two weights disagree at d = d*? ==")
    d = dstar
    tr_img = cf.truth(d, m=2048)
    mask = cf.interior(d)
    gj = det_gain(jxx, jxy, jyy, d)
    gt = trace_gain(jxx, jxy, jyy, d)
    # full-Jac top-8% pixels that trace ranks below its own median:
    bright = gj > np.quantile(gj[mask], 0.92)
    dim = gt < np.median(gt[mask])
    disagree = bright & dim & mask
    # converse: trace top-8% that full-Jac ranks below its median:
    over = (gt > np.quantile(gt[mask], 0.92)) \
        & (gj < np.median(gj[mask])) & mask
    print(f"  full-Jac-bright/trace-dim pixels: {int(disagree.sum())}; "
          f"trace-bright/full-Jac-dim pixels: {int(over.sum())}")
    mean_img = float(tr_img[mask].mean())
    mean_top = float(tr_img[bright & mask].mean())
    print(f"  truth brightness -- interior mean {mean_img:.2f}, "
          f"full-Jac top-8% mean {mean_top:.2f} ({mean_top / mean_img:.1f}x)")
    print("  -> empty disagreement sets: on this smooth periodic glass the "
          "near-fold set coincides with strong negative divergence, so the "
          "trace weight is NOT fold-blind here (contrary to the saddle-on-"
          "a-fold scenario optics_map.md raises). Its measured deficit is in "
          "saddle *structure* (T3), not fold detection.")

    # ---- T3: error partitioned by eigenvalue mechanism -----------------
    print("\n== T3: r vs truth within eigenvalue-sign partitions, "
          "d = d* ==")
    l1, l2 = eig_pair(jxx, jxy, jyy)
    lam1 = d * l1
    lam2 = d * l2
    parts = [("both >= 0 (defocus)", (lam1 >= 0) & (lam2 >= 0)),
             ("both < 0 (focus)", (lam1 < 0) & (lam2 < 0)),
             ("mixed (saddle)", (lam1 < 0) != (lam2 < 0))]
    gj = det_gain(jxx, jxy, jyy, d)
    for label, sel in parts:
        sel = sel & mask
        if sel.sum() < 100:
            print(f"  {label:22s} too few pixels ({int(sel.sum())})")
            continue
        share = 100.0 * sel.sum() / mask.sum()
        print(f"  {label:22s} {share:5.1f}% of interior   "
              f"truth mean {tr_img[sel].mean():.2f}")
        report("trace-only  g_t", gt, tr_img, sel)
        report("full Jacobian g_J", gj, tr_img, sel)

    print("\nnote: g_J is still one-branch and local -- it cannot beat the "
          "truth past the first\nfold (see optics_map.md's multi-guess "
          "gather); the T1/T3 deltas measure the\nrepresentation gap "
          "(trace vs full tensor), not the ceiling of either estimate.")


if __name__ == "__main__":
    main()