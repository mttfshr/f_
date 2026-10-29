"""
test_tf_hatch.py -- Tier-1 for f_tf_hatch v2 (streamline renderer), Phase 0.
Spec .specify/f_tf_hatch/spec.md, acceptance criteria 1-8.

Synthetic encoded-tensor fields with KNOWN coherence and axis; the module is only
worth building if these pass in the mirror. Metrics are autocorrelation lengths of
the rendered field: a streak is long along its axis and short across it, grain is
short both ways. Where a strip holds only a few independent streaks the metric is
averaged over several noise realisations (the mirror's `seed` test hook).

Run:  tests/run.sh tests/modules/tf_hatch/test_tf_hatch.py -q
"""
import sys

import numpy as np

from harness import check, run  # noqa: E402
from harness import note as _note  # noqa: E402
from tf_hatch_mirror import (F32, blob_noise, chain, fill_from_density, noise_at,  # noqa: E402
                             texture_coord, texture_impulse)


def note(msg):
    """One-string note: the harness's note() takes (label, value)."""
    _note("measured", msg)


H = W = 128
STRENGTH = 100.0
TR = 0.01                       # tensor trace in J units -> encoded trace = 1.0 at strength 100
THRESH = float(np.exp(-1.0))    # autocorrelation 1/e
SEEDS = range(6)


# ------------------------------------------------------------- fixtures ---

def _tex_from_J(Jxx, Jxy, Jyy, strength=STRENGTH):
    tex = np.zeros(Jxx.shape + (4,), F32)
    tex[..., 0] = (Jxx * strength).astype(F32)
    tex[..., 1] = (Jxy * strength * F32(0.5) + F32(0.5)).astype(F32)
    tex[..., 2] = (Jyy * strength).astype(F32)
    tex[..., 3] = F32(1.0)
    return tex


def field(along_deg, coh, tr=TR):
    """Tensor texture whose ALONG axis is `along_deg` (degrees, scalar or (H, W))
    and whose coherence is `coh` (scalar or (H, W)): J = tr [ (1-c)/2 I + c g g^T ],
    g = the gradient direction = along + 90 deg."""
    a = np.deg2rad(np.broadcast_to(np.asarray(along_deg, np.float64), (H, W)))
    c = np.broadcast_to(np.asarray(coh, np.float64), (H, W))
    t = np.broadcast_to(np.asarray(tr, np.float64), (H, W))
    gx, gy = np.cos(a + np.pi / 2), np.sin(a + np.pi / 2)
    Jxx = t * ((1 - c) / 2 + c * gx * gx)
    Jxy = t * (c * gx * gy)
    Jyy = t * ((1 - c) / 2 + c * gy * gy)
    return _tex_from_J(Jxx.astype(F32), Jxy.astype(F32), Jyy.astype(F32))


def _xy():
    cy, cx = np.meshgrid(np.arange(H, dtype=np.float64), np.arange(W, dtype=np.float64), indexing="ij")
    return cx + 0.5, cy + 0.5


# -------------------------------------------------------------- metrics ---

def _autocorr(img, rows, cols):
    a = np.asarray(img, np.float64)[rows, cols]
    a = a - a.mean()
    h, w = a.shape
    F = np.fft.rfft2(a, s=(2 * h, 2 * w))
    ac = np.fft.irfft2(F * np.conj(F), s=(2 * h, 2 * w))
    return ac / ac[0, 0], h, w


def _cross(profile, thresh=THRESH):
    """Lag at which a decaying profile (profile[0] = 1) first drops below thresh,
    linearly interpolated; the profile length if it never does."""
    below = np.where(profile < thresh)[0]
    if len(below) == 0:
        return float(len(profile))
    i = below[0]
    if i == 0:
        return 0.0
    y0, y1 = profile[i - 1], profile[i]
    return float(i - 1 + (y0 - thresh) / max(y0 - y1, 1e-12))


def autocorr_lengths(img, rows=slice(24, H - 24), cols=slice(24, W - 24)):
    """(L_x, L_y): 1/e autocorrelation lengths along x and y (pixels)."""
    ac, h, w = _autocorr(img, rows, cols)
    return _cross(ac[0, :w]), _cross(ac[:h, 0])


def integral_length(img, rows, cols):
    """(Lx, Ly): integral of the autocorrelation up to its first zero crossing,
    along x and y. Steadier than the 1/e crossing on small strips."""
    ac, h, w = _autocorr(img, rows, cols)
    out = []
    for prof in (ac[0, :w], ac[:h, 0]):
        neg = np.where(prof < 0)[0]
        out.append(float(prof[: neg[0] if len(neg) else len(prof)].sum()))
    return out[0], out[1]


def lum(out):
    return np.asarray(out[0][..., 0], np.float64)


def raw_field(out):
    """Normalized unstyled field (outlet 1)."""
    return np.asarray(out[1][..., 0], np.float64)


def _box(a, r):
    k = np.ones(2 * r + 1) / (2 * r + 1)
    a = np.apply_along_axis(lambda v: np.convolve(v, k, "same"), 0, a)
    return np.apply_along_axis(lambda v: np.convolve(v, k, "same"), 1, a)


def ridge_angle(out):
    """Local streak direction (deg, mod 180) of an image: structure tensor of the
    output, window 9, rotated 90 deg (the gradient is across the streak)."""
    gy0 = np.roll(out, -1, 0) - np.roll(out, 1, 0)
    gx0 = np.roll(out, -1, 1) - np.roll(out, 1, 1)
    jxx, jxy, jyy = _box(gx0 * gx0, 4), _box(gx0 * gy0, 4), _box(gy0 * gy0, 4)
    return np.rad2deg(0.5 * np.arctan2(2 * jxy, jxx - jyy)) + 90.0


def ridge_error(out, along_deg, mask):
    """Absolute angle error (deg, 0..90) between the render's ridge direction and
    the field's along-axis, over `mask`."""
    return np.abs((ridge_angle(out) - along_deg + 90.0) % 180.0 - 90.0)[mask]


# ------------------------------------------------------------ the tests ---

def test_1_coherent_straight_is_streaks():
    """Coherence 1, axis horizontal: long along x, short along y."""
    out = chain(field(0.0, 1.0))
    lx, ly = autocorr_lengths(raw_field(out))
    note(f"coherent straight: L_along={lx:.1f}px  L_across={ly:.1f}px  ratio={lx / max(ly, 1e-9):.1f}")
    check("streaks: along >= 4x across", 0.0 if lx >= 4.0 * ly else 1.0, 0.0)


def test_2_isotropic_is_grain():
    """Equal eigenvalues, coherence 0, trace above the floor. The atan2(0,0) trap:
    the decode hands back a FIXED axis here (theta = 0, so along = vertical), and a
    march that trusted it would render clean vertical streaks. Output must be grain:
    isotropic and short."""
    out = chain(field(0.0, 0.0))
    lx, ly = autocorr_lengths(raw_field(out))
    lx_c, _ = autocorr_lengths(raw_field(chain(field(0.0, 1.0))))
    ratio = lx / max(ly, 1e-9)
    note(f"isotropic: L_x={lx:.1f}  L_y={ly:.1f}  ratio={ratio:.2f}  (coherent L_along={lx_c:.1f})")
    check("isotropic: |L_x/L_y - 1| <= 0.35", abs(ratio - 1.0), 0.35)
    check("isotropic: correlation length < half the coherent streak", 0.0 if lx < 0.5 * lx_c else 1.0, 0.0)


def test_3_coherence_ramp_is_monotone():
    """Axis fixed horizontal, coherence 0 -> 1 down the frame. Streak length along
    the axis must rise monotonically with coherence (6 horizontal strips, mean of
    6 noise realisations)."""
    coh = np.broadcast_to(np.linspace(0.0, 1.0, H)[:, None], (H, W))
    tex = field(0.0, coh)
    strips = [(4 + 20 * i, 4 + 20 * (i + 1)) for i in range(6)]
    per = np.array([[integral_length(raw_field(chain(tex, seed=sd)), slice(y0, y1), slice(16, W - 16))[0]
                     for (y0, y1) in strips] for sd in SEEDS])
    ls = per.mean(0)
    cs = [float(np.linspace(0, 1, H)[(y0 + y1) // 2]) for (y0, y1) in strips]
    note("coherence ramp, streak length (px): " + "  ".join(f"c={c:.2f}:{v:.1f}" for c, v in zip(cs, ls)))
    span = ls.max() - ls.min()
    worst_drop = max(max(ls[i] - ls[i + 1] for i in range(len(ls) - 1)), 0.0)
    rho = float(np.corrcoef(np.argsort(np.argsort(cs)), np.argsort(np.argsort(ls)))[0, 1])
    note(f"  rank correlation {rho:.3f}; worst drop {worst_drop:.2f} of span {span:.2f}")
    check("ramp: length rises with coherence (rank corr >= 0.85)", 0.0 if rho >= 0.85 else 1.0, 0.0)
    check("ramp: no big reversals (worst drop <= 25% of span)", 0.0 if worst_drop <= 0.25 * span else 1.0, 0.0)
    check("ramp: top at least 4x the bottom", 0.0 if ls[-1] >= 4.0 * ls[0] else 1.0, 0.0)


def test_4_streaks_follow_the_field():
    """The v1 regression. v1's lattice was anchored at the frame origin, so smooth or
    noisy axis fields drew rings that did not follow the field at all. Here the local
    streak direction must match the field's axis on (a) concentric rings, (b) a sweep
    that is NOT rings, (c) a low-frequency random angle field."""
    x, y = _xy()
    # (a) rings, axis tangent, annulus away from the centre
    cx0, cy0 = W / 2 + 0.5, H / 2 + 0.5
    along = np.rad2deg(np.arctan2(y - cy0, x - cx0)) + 90.0
    r = np.hypot(x - cx0, y - cy0)
    err = ridge_error(raw_field(chain(field(along, 1.0))), along, (r > 25) & (r < 50))
    note(f"(a) rings: ridge-vs-axis error median {np.median(err):.1f} deg, 90th pct {np.percentile(err, 90):.1f}")
    check("rings: median ridge error <= 15 deg", 0.0 if np.median(err) <= 15.0 else 1.0, 0.0)
    # (b) a sweep 0 -> 40 deg across x (no circle anywhere)
    sweep = np.broadcast_to(np.linspace(0.0, 40.0, W)[None, :], (H, W))
    inner = np.zeros((H, W), bool)
    inner[24:-24, 24:-24] = True
    err = ridge_error(raw_field(chain(field(sweep, 1.0))), sweep, inner)
    note(f"(b) sweep: ridge-vs-axis error median {np.median(err):.1f} deg, 90th pct {np.percentile(err, 90):.1f}")
    check("sweep: median ridge error <= 15 deg", 0.0 if np.median(err) <= 15.0 else 1.0, 0.0)
    # (c) low-frequency random angle field, +-35 deg around 90
    rng = np.random.default_rng(3)
    lf = _box(_box(rng.standard_normal((H, W)), 14), 14)
    lf = 90.0 + 35.0 * lf / np.abs(lf).max()
    err = ridge_error(raw_field(chain(field(lf, 1.0))), lf, inner)
    note(f"(c) random field: ridge-vs-axis error median {np.median(err):.1f} deg, 90th pct {np.percentile(err, 90):.1f}")
    check("random field: median ridge error <= 20 deg", 0.0 if np.median(err) <= 20.0 else 1.0, 0.0)


def test_5_branch_cut_has_no_seam():
    """Axis sweeping 170 -> 190 deg across x, crossing the decode's wrap (along-axis
    angles live in (0, 180], so the unsigned pair flips sign there). Streak length in
    a strip straddling the cut must stay within 80% of a strip away from it, for the
    doubled-angle and the unsigned aux layouts alike (OQ2 evidence)."""
    sweep = np.broadcast_to(np.linspace(170.0, 190.0, W)[None, :], (H, W))
    for mode in ("doubled", "unsigned_bilinear", "unsigned_nearest"):
        near, away = [], []
        for sd in SEEDS:
            out = raw_field(chain(field(sweep, 1.0), aux_mode=mode, seed=sd))
            near.append(integral_length(out, slice(24, H - 24), slice(W // 2 - 14, W // 2 + 14))[0])
            away.append(integral_length(out, slice(24, H - 24), slice(20, 48))[0])
        n, a = float(np.mean(near)), float(np.mean(away))
        note(f"branch cut [{mode}]: streak length near the cut {n:.1f}px, away {a:.1f}px, ratio {n / a:.2f}")
        check(f"branch cut ({mode}): near >= 0.8 * away", 0.0 if n >= 0.8 * a else 1.0, 0.0)


def test_6_degenerate_point_is_grain_around_streaks():
    """A radial field whose coherence goes to 0 at the centre (a degenerate point):
    grain AT the point, streaks around it. Measured as tangential/radial gradient
    energy (radial streaks have gradient across them, i.e. tangential)."""
    cx0, cy0 = W / 2 + 0.5, H / 2 + 0.5
    x, y = _xy()
    r = np.hypot(x - cx0, y - cy0)
    along = np.rad2deg(np.arctan2(y - cy0, x - cx0))
    coh = np.clip(r / 30.0, 0.0, 1.0)
    out = raw_field(chain(field(along, coh)))
    gy0 = np.roll(out, -1, 0) - np.roll(out, 1, 0)
    gx0 = np.roll(out, -1, 1) - np.roll(out, 1, 1)
    gr = (gx0 * (x - cx0) + gy0 * (y - cy0)) / np.maximum(r, 1e-6)
    gt = (-gx0 * (y - cy0) + gy0 * (x - cx0)) / np.maximum(r, 1e-6)

    def tan_over_rad(mask):
        return float(np.sqrt((gt[mask] ** 2).sum() / max((gr[mask] ** 2).sum(), 1e-12)))
    ti, to = tan_over_rad(r < 8), tan_over_rad((r > 40) & (r < 56))
    note(f"degenerate point: tangential/radial gradient energy  centre {ti:.2f}   annulus {to:.2f}")
    check("degenerate point: grain at centre (ratio ~1)", abs(ti - 1.0), 0.4)
    check("degenerate point: annulus clearly streaky (tangential >= 2x radial)", 0.0 if to >= 2.0 * ti else 1.0, 0.0)


def test_7_presence_blanks_weak_trace_only():
    """Left half weak trace, right half strong, floor 0.5: the weak half is black,
    the strong half is identical to the floor-0 render (geometry unchanged)."""
    tr = np.where(np.arange(W)[None, :] < W // 2, 0.0004, TR) * np.ones((H, 1))
    tex = field(20.0, 0.9, tr=tr)
    o_floor = lum(chain(tex, floor=0.5))
    o_free = lum(chain(tex, floor=0.0))
    left = o_floor[:, : W // 2 - 2]
    right_diff = np.abs(o_floor[:, W // 2 + 2:] - o_free[:, W // 2 + 2:]).max()
    check("floor: weak half black", float(np.abs(left).max()), 1e-7)
    check("floor: strong half unchanged by the floor", float(right_diff), 1e-6)
    check("floor 0: weak half is drawn", 0.0 if np.abs(o_free[:, : W // 2 - 2]).max() > 0.2 else 1.0, 0.0)


def test_8_neutral_and_bypass():
    neutral = np.zeros((H, W, 4), F32)
    neutral[..., 1] = 0.5
    neutral[..., 3] = 1.0
    o = chain(neutral)
    check("neutral tensor -> black", float(np.abs(o[0][..., :3]).max()), 1e-7)
    check("outlet alpha is 1", float(np.abs(o[0][..., 3] - 1.0).max()), 0.0)
    ob = chain(field(0.0, 1.0), bypass=1.0)
    check("bypass -> black (outlet 0)", float(np.abs(ob[0][..., :3]).max()), 1e-7)
    check("bypass -> black (outlet 1)", float(np.abs(ob[1][..., :3]).max()), 1e-7)
    check("bypass keeps A=1", float(np.abs(ob[0][..., 3] - 1.0).max()), 0.0)


def test_mutation_coherence_ignored_gives_false_streaks():
    """Inject the atan2(0,0) trap: persistence off (coherence ignored). The isotropic
    field must then render streaks along the decode's fixed (vertical) axis -- test 2
    would fail."""
    out = raw_field(chain(field(0.0, 0.0), persist="off"))
    lx, ly = autocorr_lengths(out)
    aniso = max(lx / max(ly, 1e-9), ly / max(lx, 1e-9))
    note(f"mutation (persist off), isotropic field: L_x={lx:.1f} L_y={ly:.1f}, anisotropy {aniso:.1f}")
    check("mutation: false streaks appear (caught by test 2)", 0.0 if aniso > 2.0 else 1.0, 0.0)


def test_line_style_is_hard_and_smooth_is_not():
    smooth = lum(chain(field(0.0, 1.0), line=0.0))
    hard = lum(chain(field(0.0, 1.0), line=1.0))
    mid_s = float(((smooth > 0.15) & (smooth < 0.85)).mean())
    mid_h = float(((hard > 0.15) & (hard < 0.85)).mean())
    note(f"mid-tone fraction: smooth {mid_s:.2f}, line=1 {mid_h:.2f}")
    check("line=1 is mostly binary", 0.0 if mid_h < 0.25 else 1.0, 0.0)
    check("line=0 is graded", 0.0 if mid_s > 0.4 else 1.0, 0.0)


def test_9_sparse_impulses_keep_the_coherence_response():
    """The shipping input noise is SPARSE (a few lit cells smeared into strokes), not dense
    white noise (Phase 0 stills, 2026-10-28: dense reads as contour-streaked noise, sparse
    reads as hatching). Re-check the headline behaviours in sparse mode, fill 3%, length 0.25:
    coherent -> long strokes; isotropic -> isolated dots (short, isotropic); coherence ramp
    -> stroke length rises; strokes follow the field on rings."""
    kw = dict(fill=0.03, length=0.25)
    # (a) coherent straight: long along the axis
    lx, ly = np.mean([autocorr_lengths(raw_field(chain(field(0.0, 1.0), seed=s, **kw))) for s in SEEDS], 0)
    note(f"sparse coherent: L_along={lx:.1f}px L_across={ly:.1f}px")
    check("sparse: coherent along >= 4x across", 0.0 if lx >= 4.0 * ly else 1.0, 0.0)
    # (b) isotropic: dots
    lxi, lyi = np.mean([autocorr_lengths(raw_field(chain(field(0.0, 0.0), seed=s, **kw))) for s in SEEDS], 0)
    note(f"sparse isotropic: L_x={lxi:.1f}px L_y={lyi:.1f}px ratio {lxi / max(lyi, 1e-9):.2f}")
    check("sparse isotropic: |L_x/L_y - 1| <= 0.5", abs(lxi / max(lyi, 1e-9) - 1.0), 0.5)
    check("sparse isotropic: shorter than half the coherent stroke", 0.0 if lxi < 0.5 * lx else 1.0, 0.0)
    # (c) ramp
    coh = np.broadcast_to(np.linspace(0.0, 1.0, H)[:, None], (H, W))
    tex = field(0.0, coh)
    strips = [(4 + 20 * i, 4 + 20 * (i + 1)) for i in range(6)]
    ls = np.mean([[integral_length(raw_field(chain(tex, seed=s, **kw)), slice(y0, y1), slice(16, W - 16))[0]
                   for (y0, y1) in strips] for s in SEEDS], 0)
    cs = [float(np.linspace(0, 1, H)[(y0 + y1) // 2]) for (y0, y1) in strips]
    note("sparse coherence ramp, stroke length (px): " + "  ".join(f"c={c:.2f}:{v:.1f}" for c, v in zip(cs, ls)))
    # the response SATURATES at the kernel's cap (a full stroke is 2 x half-length; ~9.5 px
    # at length 0.25), so test the rise over the first half and that the top stays on the plateau
    rises = all(ls[i + 1] >= 1.25 * ls[i] for i in range(2)) and all(ls[i + 1] >= ls[i] for i in range(2, 4))
    check("sparse ramp: rises >= 25% per strip below coherence 0.45, then still non-decreasing", 0.0 if rises else 1.0, 0.0)
    check("sparse ramp: top stays on the plateau (>= 75% of the max)", 0.0 if ls[-1] >= 0.75 * ls.max() else 1.0, 0.0)
    check("sparse ramp: top at least 2.5x the bottom", 0.0 if ls[-1] >= 2.5 * ls[0] else 1.0, 0.0)
    # (d) strokes follow the rings
    x, y = _xy()
    cx0, cy0 = W / 2 + 0.5, H / 2 + 0.5
    along = np.rad2deg(np.arctan2(y - cy0, x - cx0)) + 90.0
    r = np.hypot(x - cx0, y - cy0)
    img = raw_field(chain(field(along, 1.0), fill=0.03, length=0.25))
    gy0, gx0 = np.roll(img, -1, 0) - np.roll(img, 1, 0), np.roll(img, -1, 1) - np.roll(img, 1, 1)
    jxx, jxy, jyy = _box(gx0 * gx0, 6), _box(gx0 * gy0, 6), _box(gy0 * gy0, 6)
    ridge = np.rad2deg(0.5 * np.arctan2(2 * jxy, jxx - jyy)) + 90.0
    lit = _box(img, 6) > 0.05                      # where there is any stroke to measure
    mask = (r > 25) & (r < 50) & lit
    err = np.abs((ridge - along + 90.0) % 180.0 - 90.0)[mask]
    note(f"sparse rings: ridge-vs-axis error median {np.median(err):.1f} deg ({mask.sum()} px measured)")
    check("sparse rings: median ridge error <= 20 deg", 0.0 if np.median(err) <= 20.0 else 1.0, 0.0)


def _noise_patch(n, cell, fill, seed, kind):
    """The sparse impulse source on an n x n pixel patch (kind 'blobs' or 'cells')."""
    yy, xx = np.mgrid[0:n, 0:n].astype(F32)
    xx, yy = xx + F32(0.5), yy + F32(0.5)
    if kind == "blobs":
        return np.asarray(blob_noise(xx, yy, cell, seed, fill, 2.0 * n), np.float64)
    return np.asarray(noise_at(xx, yy, cell, seed, fill), np.float64)


def test_10_blob_coverage_matches_fill():
    """The closed-form threshold (a cubic in density) must make the soft-ramped blob coverage
    equal the lit probability `fill`, so Density means the same thing as with lit cells."""
    worst = 0.0
    for d in (0.25, 0.5, 0.75, 1.0):
        fill = float(fill_from_density(d))
        cov = float(np.mean([_noise_patch(1024, 6.0, fill, s, "blobs").mean() for s in (0, 3)]))
        rel = abs(cov - fill) / fill
        worst = max(worst, rel)
        note(f"blob coverage at density {d:.2f}: {cov:.4f} vs fill {fill:.4f} ({100 * (cov - fill) / fill:+.1f}%)")
    check("blob coverage within 10% of fill (density 0.25..1)", worst, 0.10)


def test_11_blobs_have_no_axis_bias():
    """Why the blobs exist: lit cells are squares, so their autocorrelation is longer along the
    pixel diagonals than the axes and strokes crossing them paint rectangles. The blob lattice is
    rotated 22.5 deg: the 1/e correlation length along x and along the 45 deg diagonal must match."""
    def lengths(kind):
        lx, ld = [], []
        for s in (0, 3, 5):
            ac, h, w = _autocorr(_noise_patch(1024, 8.0, 0.08, s, kind), slice(0, 1024), slice(0, 1024))
            lx.append(_cross(ac[0, :w]))
            ld.append(_cross(np.array([ac[i, i] for i in range(min(h, w))])) * np.sqrt(2.0))
        return float(np.mean(lx)), float(np.mean(ld))
    lxb, ldb = lengths("blobs")
    lxc, ldc = lengths("cells")
    note(f"1/e correlation length (px): blobs x {lxb:.2f} diag {ldb:.2f} (ratio {ldb / lxb:.3f}); "
         f"cells x {lxc:.2f} diag {ldc:.2f} (ratio {ldc / lxc:.3f})")
    check("blobs: |L_diag / L_x - 1| <= 0.08", abs(ldb / lxb - 1.0), 0.08)


# ---- the optional stroke-texture inlet (2026-10-29): the marks are the texture, streaked along the axis

def _noise_tex(seed, n=H, smooth=0.0):
    """RGBA texture, R=G=B=luma: uniform white noise, optionally Gaussian-smoothed (sigma px) and
    re-stretched to 0..1 so its features have a size."""
    a = np.random.default_rng(100 + seed).random((n, n))
    if smooth > 0.0:
        k = np.fft.fftfreq(n)
        a = np.fft.ifft2(np.fft.fft2(a) * np.exp(-2 * (np.pi * smooth) ** 2 * (k[:, None] ** 2 + k[None, :] ** 2))).real
        a = (a - a.min()) / (a.max() - a.min())
    t = np.zeros((n, n, 4), F32)
    t[..., 0] = t[..., 1] = t[..., 2] = a.astype(F32)
    t[..., 3] = F32(1.0)
    return t


def test_12_texture_strokes_follow_the_axis_and_coherence_still_matters():
    """With a stroke texture, the marks are the texture streaked along the contours: the same headline
    behaviours as the blobs. White-noise texture, density 0.3 (soft threshold at luma ~0.74), grain 1
    (the identity map), length 0.25: coherent -> long strokes along the axis; isotropic -> short,
    isotropic dots; strokes follow the rings."""
    fill = float(fill_from_density(0.3))
    kw = dict(fill=fill, length=0.25, grain=1.0)
    lx, ly = np.mean([autocorr_lengths(raw_field(chain(field(0.0, 1.0), texture=_noise_tex(s), **kw))) for s in range(4)], 0)
    note(f"texture coherent: L_along={lx:.1f}px L_across={ly:.1f}px")
    check("texture: coherent along >= 4x across", 0.0 if lx >= 4.0 * ly else 1.0, 0.0)
    lxi, lyi = np.mean([autocorr_lengths(raw_field(chain(field(0.0, 0.0), texture=_noise_tex(s), **kw))) for s in range(4)], 0)
    note(f"texture isotropic: L_x={lxi:.1f}px L_y={lyi:.1f}px ratio {lxi / max(lyi, 1e-9):.2f}")
    check("texture isotropic: |L_x/L_y - 1| <= 0.5", abs(lxi / max(lyi, 1e-9) - 1.0), 0.5)
    check("texture isotropic: shorter than half the coherent stroke", 0.0 if lxi < 0.5 * lx else 1.0, 0.0)
    x, y = _xy()
    cx0, cy0 = W / 2 + 0.5, H / 2 + 0.5
    along = np.rad2deg(np.arctan2(y - cy0, x - cx0)) + 90.0
    r = np.hypot(x - cx0, y - cy0)
    img = raw_field(chain(field(along, 1.0), texture=_noise_tex(0), **kw))
    gy0, gx0 = np.roll(img, -1, 0) - np.roll(img, 1, 0), np.roll(img, -1, 1) - np.roll(img, 1, 1)
    jxx, jxy, jyy = _box(gx0 * gx0, 6), _box(gx0 * gy0, 6), _box(gy0 * gy0, 6)
    ridge = np.rad2deg(0.5 * np.arctan2(2 * jxy, jxx - jyy)) + 90.0
    mask = (r > 25) & (r < 50) & (_box(img, 6) > 0.02)
    err = np.abs((ridge - along + 90.0) % 180.0 - 90.0)[mask]
    note(f"texture rings: ridge-vs-axis error median {np.median(err):.1f} deg ({mask.sum()} px measured)")
    check("texture rings: median ridge error <= 20 deg", 0.0 if np.median(err) <= 20.0 else 1.0, 0.0)


def test_13_texture_grain_is_zoom():
    """Grain tiles the texture T = 2^((1-grain)*6) times across the frame: grain 1 is the identity map
    (one copy), grain 0.5 is 8 tiles, grain 0 is 64; a lower grain makes smaller marks. The map is
    checked exactly, then the direction on a smooth texture (an isotropic field, so only the
    texture sets the mark size)."""
    px = np.array([10.5, 40.5, 100.5], F32)
    for grain, t in ((1.0, 1), (0.5, 8), (0.0, 64)):
        u, v = texture_coord(px, px, W, H, grain)
        want = (t * px / W) % 1.0
        check(f"texture_coord grain {grain}: u = fract({t} x/W)", float(np.abs(u - want).max()), 1e-5)
        check(f"texture_coord grain {grain}: v = fract({t} y/H)", float(np.abs(v - want).max()), 1e-5)
    tex = _noise_tex(0, smooth=6.0)
    kw = dict(fill=float(fill_from_density(0.4)), length=0.25)
    big = np.mean([autocorr_lengths(raw_field(chain(field(0.0, 0.0), texture=_noise_tex(s, smooth=6.0), grain=1.0, **kw)))[0] for s in range(3)])
    small = np.mean([autocorr_lengths(raw_field(chain(field(0.0, 0.0), texture=_noise_tex(s, smooth=6.0), grain=0.6, **kw)))[0] for s in range(3)])
    note(f"texture mark size (1/e length, px): grain 1.0 -> {big:.1f}, grain 0.6 -> {small:.1f}")
    check("texture: grain 0.6 marks are <= 70% of grain 1.0 marks", 0.0 if small <= 0.7 * big else 1.0, 0.0)


def test_14_texture_density_is_a_soft_threshold():
    """Density is smoothstep(thr - w, thr + w, luma), thr = (1 + w) - density (1 + 2w), w = 0.1.
    On a constant luma-0.5 texture: density 0 lights nothing, 0.5 sits exactly mid-ramp, 1 lights
    everything; monotone in between. A stroke texture needs `fill`."""
    tex = np.full((16, 16, 4), 0.5, F32)
    p = np.array([8.0], F32)
    vals = [float(texture_impulse(tex, p, p, W, H, 1.0, d)[0]) for d in (0.0, 0.25, 0.5, 0.75, 1.0)]
    note("constant luma 0.5, impulse at density 0 .25 .5 .75 1: " + " ".join(f"{v:.3f}" for v in vals))
    check("density 0 lights nothing", vals[0], 1e-6)
    check("density 0.5 is mid-ramp (0.5)", abs(vals[2] - 0.5), 1e-5)
    check("density 1 lights everything", abs(vals[4] - 1.0), 1e-6)
    check("monotone in density", 0.0 if all(a <= b for a, b in zip(vals, vals[1:])) else 1.0, 0.0)
    # luma, not red: a pure-green texel is lit as 0.7152, a pure-blue one as 0.0722
    g_tex, b_tex = np.zeros((4, 4, 4), F32), np.zeros((4, 4, 4), F32)
    g_tex[..., 1], b_tex[..., 2] = 1.0, 1.0
    lg = float(texture_impulse(g_tex, p, p, W, H, 1.0, 0.2858)[0])    # thr = 1.1 - 0.2858*1.2 = 0.7570: luma 0.7152 -> below
    lb = float(texture_impulse(b_tex, p, p, W, H, 1.0, 0.2858)[0])
    check("a green texel (luma 0.715) is lit more than a blue one (0.072)", 0.0 if lg > lb else 1.0, 0.0)
    try:
        chain(field(0.0, 1.0), texture=tex)
        raised = False
    except ValueError:
        raised = True
    check("a stroke texture without `fill` is loud", 0.0 if raised else 1.0, 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
