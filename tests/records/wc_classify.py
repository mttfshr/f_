"""
wc_classify.py -- pattern morphology classifier for the f_wc region sweep.

Classifies a 2D field into the Ermentrout-Cowan-relevant categories:
  'uniform'    no spatial structure (collapsed to rest or saturated flat)
  'rolls'      stripe pattern: Fourier power concentrated in one direction pair
  'hexagons'   6-fold symmetry: power concentrated at 3 direction pairs 60 deg apart
  'dots'       localized high-wavenumber blobs (isolated spots)
  'chaos'      broadband structure with no dominant symmetry

Method: ring-integrate the 2D power spectrum to find the dominant wavenumber
k*, then look at the angular distribution of power on the k* ring.
  - uniform: total non-DC power below floor
  - rolls: angular power has 2 peaks 180 deg apart, one dominant
  - hexagons: angular power has 6 peaks (3 pairs), roughly equal
  - dots: high k*, low angular anisotropy but high real-space sparsity
  - chaos: everything else (broadband)
"""
import numpy as np


def _power(u):
    F = np.fft.fft2(u - u.mean())
    return np.abs(np.fft.fftshift(F)) ** 2


def _ring_angular(u, n_ang=72):
    """Return (k_star, angular_power) where angular_power is the power on the
    dominant-wavenumber ring as a function of angle (n_ang bins, 0..pi, since
    the spectrum is centrosymmetric)."""
    n = u.shape[0]
    P = _power(u)
    c = n // 2
    ky, kx = np.mgrid[0:n, 0:n]
    kr = np.hypot(kx - c, ky - c)
    ang = np.arctan2(ky - c, kx - c)  # -pi..pi
    ang01 = np.mod(ang, np.pi)        # 0..pi (centrosymmetric)

    # radial profile to find k*
    r_max = c
    radial = np.zeros(r_max)
    counts = np.zeros(r_max)
    ri = kr.astype(int)
    valid = ri < r_max
    np.add.at(radial, ri[valid], P[valid])
    np.add.at(counts, ri[valid], 1)
    counts[counts == 0] = 1
    radial /= counts
    radial[0] = 0.0  # DC
    k_star = int(np.argmax(radial))
    if radial[k_star] <= 0:
        return 0, np.zeros(n_ang)

    # angular distribution on the ring k in [k_star-1, k_star+1]
    ring = (ri >= max(1, k_star - 1)) & (ri <= k_star + 1) & valid
    ap = np.zeros(n_ang)
    bins = (ang01[ring] / np.pi * n_ang).astype(int) % n_ang
    np.add.at(ap, bins, P[ring])
    if ap.sum() > 0:
        ap /= ap.sum()
    return k_star, ap


def _fold_peaks(ap, fold):
    """Power of the `fold`-fold symmetric component of the angular
    distribution (Fourier coefficient at harmonic `fold`)."""
    n = len(ap)
    th = np.arange(n) / n * np.pi
    # fold-fold symmetry in 0..pi means period pi/(fold/2) for even folds
    coeff = np.abs(np.sum(ap * np.exp(-1j * fold * th))) / (ap.sum() + 1e-30)
    return coeff


def classify(u, n_ang=72):
    """Return (label, k_star, detail dict)."""
    n = u.shape[0]
    std = float(u.std())
    k_star, ap = _ring_angular(u, n_ang)
    total_pow = float(_power(u).sum())

    detail = {"std": std, "k_star": int(k_star), "total_pow": total_pow}

    # uniform: essentially no variance AND no spectral concentration.
    # A low-contrast but spatially coherent pattern (near-threshold Turing)
    # has low std yet a sharp spectral peak -- do NOT call that uniform.
    # Use the coefficient of variation of the radially-averaged power as the
    # coherence signal instead of raw std alone.
    n = u.shape[0]
    if std < 1e-6:
        return "uniform", int(k_star), detail

    # fold powers: 2-fold (rolls) and 6-fold (hexagons)
    f2 = _fold_peaks(ap, 2)
    f6 = _fold_peaks(ap, 6)
    f4 = _fold_peaks(ap, 4)
    detail.update({"f2": f2, "f4": f4, "f6": f6,
                   "lambda_px": (n / k_star if k_star > 0 else float("inf"))})

    # sparsity: fraction of pixels near max (dots have small fill fraction)
    frac_high = float((u > u.mean() + u.std()).mean())
    detail["frac_high"] = frac_high

    # classification
    if f6 > 0.35 and f6 > 1.3 * f2:
        return "hexagons", int(k_star), detail
    if f2 > 0.30:
        return "rolls", int(k_star), detail
    if frac_high < 0.18 and k_star > 0:
        # sparse bright spots
        return "dots", int(k_star), detail
    return "chaos", int(k_star), detail
