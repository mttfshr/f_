"""test_halftone.py -- tier-1 tests for the not-yet-built f_halftone module (T017, T016c, T016a, T018 in part; SC-001 to SC-007).

Ground truth is independent of the mirror where it can be: the area law (mean coverage of a flat patch = its tone), a
Monte Carlo area for the round-dot function A(r), the recursive Bayer matrix, the FFT of the output for the lattice's
period and orientation, and symmetries (a 90 degree turn, a whole-pitch phase shift).

Measurements with no pass mark (G4 staircase, G5 smallest pitch, jitter at high tone) are printed with note().

Run:  tests/run.sh -q tests/modules/halftone/test_halftone.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from halftone_mirror import (F32, area_round, area_round_slope, bayer8_bits, bayer8_recursive,  # noqa: E402
                             halftone_stage)


def flat(tone, W=384, H=384, a=1.0):
    t = np.zeros((H, W, 4), dtype=F32)
    t[..., :3] = np.asarray(tone, dtype=F32)
    t[..., 3] = a
    return t


def ramp(W=512, H=256):
    t = np.zeros((H, W, 4), dtype=F32)
    t[..., :3] = ((np.arange(W, dtype=F32) + 0.5) / W)[None, :, None]
    t[..., 3] = 1
    return t


def err(a, b):
    return float(np.abs(np.asarray(a, dtype=np.float64) - np.asarray(b, dtype=np.float64)).max())


def test_round_area_function():
    """G3: A(r) against a Monte Carlo area of a circle inside the unit cell; ends exact; slope against a finite difference."""
    rng = np.random.default_rng(3)
    pts = rng.uniform(-0.5, 0.5, (400000, 2))
    d = np.hypot(pts[:, 0], pts[:, 1])
    worst = 0.0
    for r in (0.1, 0.3, 0.5, 0.55, 0.6, 0.65, 0.7):
        worst = max(worst, abs(float(area_round(F32(r))) - float((d < r).mean())))
    check("A(r) vs Monte Carlo (400k points)", worst, 4e-3)
    check("A(0) = 0", abs(float(area_round(F32(0)))), 0)
    check("A(sqrt(1/2)) = 1", abs(float(area_round(F32(np.sqrt(0.5)))) - 1), 1e-6)
    check("A(1/2) = pi/4", abs(float(area_round(F32(0.5))) - np.pi / 4), 1e-6)
    rs = np.linspace(0.02, 0.69, 60).astype(F32)
    h = F32(1e-3)
    fd = (area_round(rs + h).astype(np.float64) - area_round(rs - h)) / (2 * float(h))
    check("dA/dr vs finite difference", err(area_round_slope(rs), fd), 2e-2)
    a = area_round(np.linspace(0, 0.75, 500).astype(F32))
    check("A(r) monotone", float(max(0.0, -np.diff(a.astype(np.float64)).min())), 1e-6)


def test_area_law_flat():
    """SC-001 (P3): mean coverage of a flat patch equals its tone, for Dot, Line and Square, several tones, pitches, angles."""
    # A 768 px frame, so the cells cut by the frame edge are a small share (at 384 px they alone gave up to 0.017).
    # Coarse pitch (24 texels) is the area law proper. Fine pitch (10 texels) is looser ON PURPOSE: the ADR-3 edge ramp is
    # cut off at the cell boundary, so gaps thinner than a texel (a square at tone 0.95, a dot above 0.8) lose ink. That
    # is a finding for G5 (measured 2026-11-13, mirror only), not a tolerance to tighten by tuning.
    for texels, tol in ((24, 0.015), (10, 0.03)):
        worst = {"dot": 0.0, "line": 0.0, "square": 0.0}
        for tone in (0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95):
            for ang in (0.0, 15.0, 45.0, 75.0):
                for name, kw in (("dot", dict(screen="dot")), ("line", dict(screen="line")),
                                 ("square", dict(screen="dot", shape=1.0))):
                    o = halftone_stage(flat(tone, 768, 768), pitch=texels / 768, angles=(ang, ang, ang), softness=0.0, **kw)
                    worst[name] = max(worst[name], abs(float(o[..., 0].mean()) - tone))
        for name, w in worst.items():
            note(f"area law, {name}, pitch {texels} texels: worst error", w)
            check(f"area law, {name}, softness 0, pitch {texels} texels", w, tol)
    w = 0.0
    for tone in (0.2, 0.5, 0.8):
        o = halftone_stage(flat(tone), pitch=0.05, softness=0.5)
        w = max(w, abs(float(o[..., 0].mean()) - tone))
    note("area law, dot, softness 0.5 (measured; the spec says 'within tolerance')", w)
    check("area law, dot, softness 0.5", w, 0.05)
    w = 0.0
    for sh in (0.25, 0.5, 0.75):
        for tone in (0.2, 0.5, 0.8):
            o = halftone_stage(flat(tone), pitch=0.05, softness=0.0, shape=sh)
            w = max(w, abs(float(o[..., 0].mean()) - tone))
    note("area law, shape morph 0.25 to 0.75 (inferred to hold within tolerance, ADR-2)", w)
    check("area law, shape morph", w, 0.05)


def test_extremes_and_bounds():
    """FR-008, FR-011: tone 0 is exactly 0, tone 1 exactly 1, above 1 saturates, below 0 gives none; output in 0..1."""
    for scr in ("dot", "line"):
        for sf in (0.0, 0.6):
            check(f"tone 0 -> 0 ({scr}, softness {sf})", err(halftone_stage(flat(0.0), screen=scr, softness=sf)[..., :3], 0), 0)
            check(f"tone 1 -> 1 ({scr}, softness {sf})", err(halftone_stage(flat(1.0), screen=scr, softness=sf)[..., :3], 1), 0)
    check("tone 3 -> 1", err(halftone_stage(flat(3.0))[..., :3], 1), 0)
    check("tone -2 -> 0", err(halftone_stage(flat(-2.0))[..., :3], 0), 0)
    rng = np.random.default_rng(5)
    src = rng.uniform(-0.5, 1.5, (96, 128, 4)).astype(F32)
    for scr in ("dot", "line", "threshold", "bayer"):
        o = halftone_stage(src, screen=scr, pitch=0.07, jitter=0.5 if scr == "dot" else 0.0)
        check(f"output in 0..1 and finite ({scr})", float(not (np.isfinite(o).all() and o[..., :3].min() >= 0 and o[..., :3].max() <= 1)), 0)


def test_zap_alpha_bypass():
    src = flat(0.5, 64, 48, a=0.3)
    src[0:24, 0:32, 0] = np.nan      # patches, not single texels: a Dot reads only the texel at each cell centre
    src[24:48, 0:32, 1] = np.inf
    src[0:24, 32:64, 2] = -np.inf
    src[..., 3] = np.linspace(0, 1, 64, dtype=F32)[None, :]
    o = halftone_stage(src, pitch=0.1)
    check("non-finite input: output finite", float(not np.isfinite(o).all()), 0)
    check("alpha passes through", err(o[..., 3], src[..., 3]), 0)
    b = halftone_stage(src, bypass=True)
    ok = np.isfinite(src)
    check("bypass passes the source (finite texels)", err(b[ok], src[ok]), 0)
    check("bypass zaps non-finite texels", err(b[~ok], 0), 0)
    check("nothing connected -> None (the build supplies black, alpha 0)", float(halftone_stage(None) is not None), 0)


def test_monotone_ramp():
    """SC-003: along a ramp, the mean coverage of each band rises with tone and follows it."""
    src = ramp()
    for scr, tol in (("dot", 0.04), ("line", 0.04)):
        o = halftone_stage(src, screen=scr, pitch=0.05, softness=0.0)[..., 0]
        bands = o.reshape(256, 8, 64).mean(axis=(0, 2))
        ideal = src[..., 0].reshape(256, 8, 64).mean(axis=(0, 2))
        check(f"ramp bands monotone ({scr})", float(max(0.0, -np.diff(bands).min())), 0)
        check(f"ramp bands follow tone ({scr})", err(bands, ideal), tol)


def test_staircase_measurement():
    """G4 / T006 MEASUREMENT (mirror only): centre tap versus a 4 x 4 cell average on a ramp, by pitch."""
    src = ramp(768, 256)
    for pt in (0.03, 0.08, 0.16):
        res = {}
        for mode in ("center", "avg"):
            o = halftone_stage(src, pitch=pt, softness=0.0, angles=(15.0, 15.0, 15.0), tone_mode=mode)[..., 0]
            bands = o.reshape(256, 12, 64).mean(axis=(0, 2))
            ideal = src[..., 0].reshape(256, 12, 64).mean(axis=(0, 2))
            res[mode] = err(bands, ideal)
        note(f"ramp band error, pitch {pt} ({pt * 256:.1f} texels): centre tap", res["center"])
        note(f"ramp band error, pitch {pt} ({pt * 256:.1f} texels): 4x4 average", res["avg"])
    # hard edge: how far does the dot nearest the edge spill past it? (fraction of ink on the dark side)
    edge = flat(0.0, 256, 256)
    edge[:, 128:, :3] = 0.8
    for mode in ("center", "avg"):
        o = halftone_stage(edge, pitch=0.08, softness=0.0, tone_mode=mode)[..., 0]
        note(f"hard edge 0 | 0.8, pitch 20 texels: mean ink on the dark half ({mode})", float(o[:, :128].mean()))
    check("measurement ran", 0, 0)


def test_smallest_pitch_measurement():
    """G5 / T007 MEASUREMENT (mirror only; the bench must repeat it): area-law error against the pitch in texels."""
    for texels in (1.5, 2, 3, 4, 6, 8, 12):
        w = 0.0
        for tone in (0.1, 0.3, 0.5, 0.7, 0.9):
            for ang in (15.0, 45.0):
                o = halftone_stage(flat(tone, 256, 256), pitch=texels / 256, angles=(ang, ang, ang), softness=0.0)
                w = max(w, abs(float(o[..., 0].mean()) - tone))
        note(f"area-law error at pitch {texels} texels (worst of 5 tones, 2 angles)", w)
    check("measurement ran", 0, 0)


def _peak(img):
    """(|k| in cycles per frame, angle in degrees mod 180) of the strongest non-DC Fourier component of a square image."""
    n = img.shape[0]
    f = np.abs(np.fft.fftshift(np.fft.fft2(img - img.mean())))
    j, i = np.unravel_index(np.argmax(f), f.shape)
    kx, ky = i - n // 2, j - n // 2
    return float(np.hypot(kx, ky)), float(np.degrees(np.arctan2(ky, kx)) % 180.0)


def test_lattice_period_and_orientation():
    """SC-004: the output's period is `pitch` and it turns with the angle (FFT peak of a flat mid-tone)."""
    pitch = 1 / 16
    k0, a0 = _peak(halftone_stage(flat(0.5, 256, 256), screen="line", pitch=pitch, angles=(0, 0, 0), softness=0.0)[..., 0])
    check("line, angle 0: 16 cycles per frame", abs(k0 - 16), 0)
    worst_k, worst_a = 0.0, 0.0
    for ang in (15.0, 30.0, 45.0, 75.0, 90.0):
        k, a = _peak(halftone_stage(flat(0.5, 256, 256), screen="line", pitch=pitch, angles=(ang,) * 3, softness=0.0)[..., 0])
        worst_k = max(worst_k, abs(k - 16))
        d = abs(((a - a0) - ang + 90.0) % 180.0 - 90.0)
        worst_a = max(worst_a, d)
    check("line: period within one frequency bin at 15 to 90 degrees", worst_k, 1.0)
    check("line: the pattern turns by the angle (degrees)", worst_a, 3.0)
    for ang in (0.0, 45.0):
        k, a = _peak(halftone_stage(flat(0.3, 256, 256), screen="dot", pitch=pitch, angles=(ang,) * 3, softness=0.0)[..., 0])
        check(f"dot, angle {ang}: period within one bin", abs(k - 16), 1.0)
        check(f"dot, angle {ang}: a lattice axis (degrees, mod 90)", abs(((a - ang) + 45.0) % 90.0 - 45.0), 3.0)


def test_rotation_exactness():
    """G6: on a square frame a 90 degree angle is the 0 degree output turned a quarter, and 45 is its own quarter turn."""
    kw = dict(pitch=0.07, softness=0.0)
    for scr in ("dot", "line"):
        o0 = halftone_stage(flat(0.4, 200, 200), screen=scr, angles=(0, 0, 0), **kw)[..., 0]
        o90 = halftone_stage(flat(0.4, 200, 200), screen=scr, angles=(90, 90, 90), **kw)[..., 0]
        check(f"90 degrees = quarter turn of 0 ({scr})", min(err(o90, np.rot90(o0, 1)), err(o90, np.rot90(o0, 3))), 1e-4)
    o45 = halftone_stage(flat(0.4, 200, 200), angles=(45, 45, 45), **kw)[..., 0]
    check("dot at 45 is its own quarter turn", float(np.abs(o45 - np.rot90(o45)).mean()), 1e-3)
    # non-square: at angle 0 the cells are square in texels (pitch * H texels in both directions)
    o = halftone_stage(flat(0.3, 400, 200), pitch=0.1, angles=(0, 0, 0), softness=0.0)[..., 0]
    kx = np.argmax(np.abs(np.fft.rfft(o.mean(axis=0) - o.mean()))) / 400.0
    ky = np.argmax(np.abs(np.fft.rfft(o.mean(axis=1) - o.mean()))) / 200.0
    check("non-square frame: same period in texels along x and y", abs(1 / kx - 1 / ky), 1e-6)
    check("non-square frame: the period is pitch * H texels", abs(1 / ky - 20.0), 1e-6)


def test_render_size_scaling():
    """SC-006: the lattice follows the render size: the same picture at twice the size, block-averaged, is the same picture."""
    kw = dict(pitch=0.08, softness=0.3)
    a = halftone_stage(flat(0.45, 160, 120), **kw)[..., :3]
    b = halftone_stage(flat(0.45, 320, 240), **kw)[..., :3].reshape(120, 2, 160, 2, 3).mean(axis=(1, 3))
    check("2x render size, averaged down: mean abs difference", float(np.abs(a - b).mean()), 0.02)
    check("2x render size: same mean coverage", abs(float(a.mean()) - float(b.mean())), 0.01)


def test_plate_independence():
    """SC-005: changing one channel's tone, angle or phase leaves the other channels unchanged."""
    rng = np.random.default_rng(7)
    src = rng.uniform(0, 1, (96, 128, 4)).astype(F32)
    base = halftone_stage(src, pitch=0.09)
    s2 = src.copy()
    s2[..., 0] = 1 - s2[..., 0]
    o = halftone_stage(s2, pitch=0.09, angles=(33.0, 75.0, 45.0), phases=((0.3, 0.2), (0, 0), (0, 0)))
    check("G and B unchanged when R's tone, angle and phase change", err(o[..., 1:3], base[..., 1:3]), 0)
    check("R did change", float(err(o[..., 0], base[..., 0]) < 0.5), 0)


def test_phase():
    """FR-016, T016c: zero phase is the default; a whole-pitch shift returns the original; marks stay whole and sharp."""
    src = flat(0.4, 256, 256)
    kw = dict(pitch=0.06, softness=0.0)
    base = halftone_stage(src, **kw)
    check("phase 0 = default", err(halftone_stage(src, phases=((0, 0),) * 3, **kw), base), 0)
    for ph in ((1, 0), (0, 1), (-1, 1)):
        o = halftone_stage(src, phases=(ph,) * 3, **kw)
        check(f"whole-pitch shift {ph} returns the original (mean abs)", float(np.abs(o - base).mean()), 1e-4)
    sh = halftone_stage(src, phases=((0.37, 0.21),) * 3, **kw)
    check("a fractional shift changes the picture", float(np.abs(sh - base).mean() < 0.05), 0)
    check("shifted: same mean coverage", abs(float(sh[..., 0].mean()) - float(base[..., 0].mean())), 0.01)
    hard = lambda x: float(((x < 0.02) | (x > 0.98)).mean())   # noqa: E731
    check("shifted: marks as sharp (fraction of fully on or off texels)", abs(hard(sh[..., 0]) - hard(base[..., 0])), 0.01)
    # the shift is a translation: at angle 0, phase (a, 0) with a * pitch a whole number of texels is the picture rolled
    o0 = halftone_stage(src, pitch=16 / 256, angles=(0, 0, 0), softness=0.0)[..., 0]
    o1 = halftone_stage(src, pitch=16 / 256, angles=(0, 0, 0), softness=0.0, phases=((0.25, 0), (0, 0), (0, 0)))[..., 0]
    check("phase 0.25 at a 16 texel pitch = the plate moved 4 texels in +x", err(o1[:, 8:-8], np.roll(o0, 4, axis=1)[:, 8:-8]), 1e-4)
    line0 = halftone_stage(flat(0.5, 256, 256), screen="line", **kw)[..., 0]
    line5 = halftone_stage(flat(0.5, 256, 256), screen="line", phases=((0, 0.5),) * 3, **kw)[..., 0]
    check("line at tone 0.5: a half-pitch shift is the complement", err(line0 + line5, 1), 1e-3)


def test_single_plate():
    """T016a: Single reads the texture as one plate: one set of marks, in the plate's colour at full brightness."""
    teal = flat((0.0, 0.3, 0.6), 192, 192)
    o = halftone_stage(teal, plate_mode="single", pitch=0.07, softness=0.0)
    check("red stays 0", err(o[..., 0], 0), 0)
    check("green = half of blue everywhere (one set of marks, colour normalised)", err(o[..., 1], 0.5 * o[..., 2]), 1e-6)
    ref = halftone_stage(flat(0.6, 192, 192), pitch=0.07, softness=0.0)[..., 2]
    check("blue = the Channels blue plate of the tone max(r, g, b) (angle_b)", err(o[..., 2], ref), 1e-6)
    check("black stays black", err(halftone_stage(flat(0.0, 64, 64), plate_mode="single")[..., :3], 0), 0)
    grey = flat(0.5, 96, 96)
    ch = halftone_stage(grey, pitch=0.07)
    check("Channels: three angles give three different patterns", float(err(ch[..., 0], ch[..., 1]) < 0.5), 0)
    a = teal.copy()
    a[..., 3] = 0.25
    check("Single: alpha passes through", err(halftone_stage(a, plate_mode="single")[..., 3], 0.25), 0)


def test_jitter():
    """T018 / SC for US6: jitter 0 is exactly the regular lattice; with jitter the mean is measured (pass mark at low tone only)."""
    src = flat(0.3, 256, 256)
    kw = dict(pitch=0.06, softness=0.0)
    check("jitter 0 = no jitter", err(halftone_stage(src, jitter=0.0, **kw), halftone_stage(src, **kw)), 0)
    j1 = halftone_stage(src, jitter=1.0, **kw)
    check("jitter 1 changes the picture", float(np.abs(j1 - halftone_stage(src, **kw)).mean() < 0.02), 0)
    check("a different seed changes it again", float(np.abs(j1 - halftone_stage(src, jitter=1.0, seed=2, **kw)).mean() < 0.02), 0)
    for tone in (0.1, 0.3, 0.5, 0.7, 0.9):
        o = halftone_stage(flat(tone, 256, 256), jitter=1.0, **kw)
        note(f"jitter 1, tone {tone}: mean coverage minus tone (MEASURED; overlap and clipped cells lose ink)",
             float(o[..., 0].mean()) - tone)
    o = halftone_stage(flat(0.1, 256, 256), jitter=1.0, **kw)
    check("jitter 1, tone 0.1: mean within 0.02", abs(float(o[..., 0].mean()) - 0.1), 0.02)


def test_threshold_and_bayer():
    """T018 / US7: Threshold cuts at the level; Bayer lights the fraction of texels equal to the tone (to 1/64)."""
    check("bit-interleave Bayer = the recursive 8 x 8 matrix",
          float(np.abs(bayer8_bits(*np.meshgrid(np.arange(8), np.arange(8))) - bayer8_recursive()).max()), 0)
    check("Bayer matrix is a permutation of 0..63", float(sorted(bayer8_recursive().ravel()) != list(range(64))), 0)
    worst = 0.0
    for tone in np.linspace(0, 1, 23):
        o = halftone_stage(flat(float(tone), 64, 64), screen="bayer")[..., 0]
        worst = max(worst, abs(float(o.mean()) - float(tone)))
    check("Bayer: lit fraction = tone within 1/64", worst, 1 / 64)
    # Bayer follows pitch (Matt, 2026-11-14): the 8 x 8 matrix repeats once per pitch, a cell rounded to whole pixels
    t = flat(0.37, 96, 96)
    o1 = halftone_stage(t, screen="bayer", pitch=8.0 / 96)[..., 0]
    check("Bayer: a pitch under 8 pixels (and of 10) gives 1-pixel cells",
          max(err(halftone_stage(t, screen="bayer", pitch=0.01)[..., 0], o1),
              err(halftone_stage(t, screen="bayer", pitch=10.0 / 96)[..., 0], o1)), 0)
    o3 = halftone_stage(t, screen="bayer", pitch=24.0 / 96)[..., 0]
    check("Bayer: a pitch of 24 pixels gives 3 x 3-pixel cells", err(o3, np.repeat(np.repeat(o1[:32, :32], 3, 0), 3, 1)), 0)
    worst = max(abs(float(halftone_stage(flat(float(tn), 96, 96), screen="bayer", pitch=24.0 / 96)[..., 0].mean()) - float(tn))
                for tn in np.linspace(0, 1, 23))
    check("Bayer at 3-pixel cells: lit fraction = tone within 1/64", worst, 1 / 64)
    src = ramp(256, 8)
    o = halftone_stage(src, screen="threshold", level=0.4, softness=0.0)[..., 0]
    check("Threshold, hard: 1 above the level, 0 below", err(o, (src[..., 0] > 0.4).astype(F32)), 0)
    o = halftone_stage(src, screen="threshold", level=0.4, softness=0.2)[..., 0]
    t = src[..., 0]
    check("Threshold, soft: 0 below level - w, 1 above level + w, 0.5 at the level",
          max(err(o[t < 0.3], 0), err(o[t > 0.5], 1), abs(float(o[0, np.argmin(np.abs(t[0] - 0.4))]) - 0.5)), 0.02)
    check("Threshold, soft: monotone", float(max(0.0, -np.diff(o[0].astype(np.float64)).min())), 0)


def test_mutations():
    """Each plausible mistake changes an output the checks above look at."""
    nan = flat(0.5, 64, 64)
    nan[:32, :32, 0] = np.nan
    al = flat(0.5, 64, 64, a=0.3)
    cases = {
        "no_extremes": (flat(0.0, 64, 64), dict(pitch=0.1, softness=0.5)),
        "no_zap": (nan, dict(pitch=0.1, screen="line")),   # Line: the Dot path's running maximum drops a NaN by itself
        "wrong_area": (flat(0.6, 128, 128), dict(pitch=0.1, softness=0.0)),
        "per_pixel_tone": (ramp(256, 64), dict(pitch=0.4, softness=0.0)),
        "ignore_phase": (flat(0.4, 64, 64), dict(pitch=0.1, phases=((0.4, 0.3),) * 3)),
        "shared_phase": (flat(0.4, 64, 64), dict(pitch=0.1, phases=((0.4, 0.3), (0, 0), (0.1, 0.6)))),
        "ignore_alpha": (al, dict(pitch=0.1)),
        "single_reads_r": (flat((0.0, 0.3, 0.6), 64, 64), dict(pitch=0.1, plate_mode="single")),
        "line_centre_tone": (ramp(256, 64), dict(pitch=0.3, screen="line", angles=(0, 0, 0), softness=0.0)),
    }
    for bug, (src, kw) in cases.items():
        a = halftone_stage(src, **kw)
        b = halftone_stage(src, bug=bug, **kw)
        e = 1.0 if not np.isfinite(b).all() else float(np.abs(a - b).max())
        note(f"mutation '{bug}' worst error", e)
        check(f"mutation caught: {bug}", float(e <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
