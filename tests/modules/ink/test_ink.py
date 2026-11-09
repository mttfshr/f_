"""test_ink.py -- tier-1 tests for the not-yet-built f_ink module (T016, T017; SC-001 to SC-006, P1 effects).

Ground truth is independent of the mirror: invariants and closed forms from the spec (identity at zero, kernel support, a flat
field stays flat, 0 stays 0, monotone amounts, ratios of feature sizes). Measurements that settle open numbers are printed as
notes, and land in the full log.

Run:  tests/run.sh -q tests/modules/ink/test_ink.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from ink_mirror import F32, SPREAD_CAP_H, TENT, blur2, blur_pass, ink, tap_offsets  # noqa: E402


def frame(h, w, value=0.0):
    t = np.zeros((h, w, 4), dtype=F32)
    t[..., :3] = value
    t[..., 3] = 1
    return t


def disc(h=540, w=540, radius=0.2):
    y, x = np.mgrid[0:h, 0:w]
    t = frame(h, w)
    t[((x + 0.5 - w / 2) ** 2 + (y + 0.5 - h / 2) ** 2) <= (radius * h) ** 2, :3] = 1
    return t


def err(a, b):
    return float(np.abs(np.asarray(a, dtype=np.float64) - np.asarray(b, dtype=np.float64)).max())


def half_lag(f, axis=1, limit=240):
    """First lag at which the autocorrelation along the axis falls below 0.5."""
    a = f - f.mean()
    v = float((a * a).mean())
    for lag in range(1, limit):
        p = np.take(a, range(a.shape[axis] - lag), axis=axis)
        q = np.take(a, range(lag, a.shape[axis]), axis=axis)
        if float((p * q).mean()) / v < 0.5:
            return lag
    return limit


def test_identity_at_zero():
    """SC-001: exact, including values outside 0..1, and with the optional amounts' other dials moved."""
    rng = np.random.default_rng(1)
    x = rng.uniform(-0.5, 2.0, (64, 96, 4)).astype(F32)
    check("every amount 0: output equals input", err(ink(x), x), 0)
    check("dials without an amount do nothing", err(ink(x, bias=0.4, soften=0.7, pool_width=0.03, mottle_scale=0.02, tooth_scale=0.05, seed=9), x), 0)


def test_blur_kernel():
    check("tent weights sum to 1", abs(float(TENT.sum(dtype=np.float64)) - 1), 1e-7)
    check("offsets are symmetric", max(abs(a + b) for a, b in zip(tap_offsets(9.3), reversed(tap_offsets(9.3)))), 0)
    check("radius 0 reads one texel", max(abs(o) for o in tap_offsets(0)), 0)
    x = frame(40, 40, 0.7)[..., :3]
    check("a flat field stays flat, borders included", err(blur2(x, 10), x), 1e-6)


def test_spread_disc():
    """SC-002 and T017: area under neutral bias; bias moves the edge."""
    d = disc()
    a0 = float(d[..., 0].mean())
    o = ink(d, spread=1.0, soften=0.2)
    shift = (float(o[..., 0].mean()) - a0) / a0
    note("T017: disc area change at spread 1, neutral bias (fraction)", f"{shift:.5f}")
    check("area preserved within 2% at neutral bias", abs(shift), 0.02)
    soft = int(((o[..., 0] > 0.01) & (o[..., 0] < 0.99)).sum())
    check("the edge is softened (texels between 0 and 1 exist)", float(soft == 0), 0)
    areas = [float(ink(d, spread=1.0, bias=b)[..., 0].mean()) for b in (-0.2, -0.05, 0.0, 0.05, 0.2)]
    note("disc mean at bias -0.2, -0.05, 0, 0.05, 0.2", [round(a, 5) for a in areas])
    check("area is monotone in bias", float(any(q <= p for p, q in zip(areas, areas[1:]))), 0)
    check("loss shrinks, gain fattens", float(not (areas[0] < a0 < areas[-1])), 0)


def test_spread_merge():
    """SC-002: a gap under the radius fills, a wide one does not. Rows, at 1080, spread 1 (radius 14 texels)."""
    t = frame(1080, 32)
    t[500:508, :, :3] = 1
    t[512:520, :, :3] = 1      # gap of 4 at rows 508..511
    t[620:628, :, :3] = 1      # gap of 100 from the pair
    o = ink(t, spread=1.0)[..., 0]
    check("a 4-texel gap fills", 1 - float(o[508:512, 16].min()), 0.05)
    check("a 100-texel gap stays empty", float(o[560:600, 16].max()), 0)


def test_stride_comb():
    """T009, offline half: a 1-texel line through taps with a stride. Measured, the decision is Matt's."""
    def comb(h):
        t = frame(h, 8)[..., :1]
        t[h // 2, :, 0] = 1
        b = blur_pass(t, 0, 1.0 * SPREAD_CAP_H * h)[:, 4, 0]
        near = b[h // 2 - 8: h // 2 + 8]
        return float(np.abs(np.diff(near)).max() / near.max()), tap_offsets(SPREAD_CAP_H * h)
    for h in (540, 720, 1080, 2160):
        c, off = comb(h)
        note(f"T009: H={h}: largest step between neighbors / peak, offsets {off[7:]}", f"{c:.3f}")
    check("stride 1 (H=540): a line's blur has no comb", comb(540)[0], 0.2)
    note("T009: at H=2160 the stride limit holds the radius at 14 texels, half its size in frame heights", tap_offsets(SPREAD_CAP_H * 2160)[-1])


def test_continuous_tone_through_spread():
    """Measured for Matt: the re-threshold assumes two-valued marks; FR-004 and 'any texture in' meet here."""
    for v in (0.2, 0.3, 0.5, 0.7, 0.8):
        a = [float(ink(frame(32, 32, v), spread=s)[0, 0, 0]) for s in (0.25, 0.5, 1.0)]
        note(f"flat {v} through spread 0.25, 0.5, 1", [round(q, 4) for q in a])


def test_mottle():
    """SC-003 and T017."""
    h = 512
    flat = frame(h, h, 0.8)
    stds = [float(ink(flat, mottle=m)[..., 0].std()) for m in (0.0, 0.25, 0.5, 1.0)]
    note("mottle std at 0, 0.25, 0.5, 1", [round(s, 5) for s in stds])
    check("std is monotone in the amount", float(any(q <= p for p, q in zip(stds, stds[1:]))), 0)
    shifts = [float(ink(flat, mottle=1.0, seed=s)[..., 0].mean()) - 0.8 for s in range(1, 13)]
    note("T017: mottle mean shift on flat 0.8, amount 1, 12 seeds: worst, mean", (round(max(map(abs, shifts)), 5), round(float(np.mean(shifts)), 5)))
    check("mean stays near the input (worst of 12 seeds)", max(map(abs, shifts)), 0.08)
    check("coverage 0 stays 0", float(np.abs(ink(frame(64, 64), mottle=1.0)[..., :3]).max()), 0)
    field = lambda sc, s: ink(frame(h, h, 1.0), mottle=1.0, mottle_scale=sc, seed=s)[..., 0]
    a = np.mean([half_lag(field(0.05, s)) for s in (1, 2, 3, 4)])
    b = np.mean([half_lag(field(0.10, s)) for s in (1, 2, 3, 4)])
    note("mottle half-lag in texels at scale 0.05, 0.10", (a, b))
    check("correlation length tracks the scale (ratio near 2)", abs(b / a - 2), 0.6)


def test_dropout():
    """SC-004."""
    h = 512
    def lost(v, d, sc=0.01, seed=1):
        return float((ink(frame(h, h, v), dropout=d, tooth_scale=sc, seed=seed)[..., 0] == 0).mean())
    for v in (0.3, 0.6):
        f = [lost(v, d) for d in (0, 0.4, 0.7, 1.0)]
        note(f"dropped fraction of flat {v} at dropout 0, 0.4, 0.7, 1", [round(q, 4) for q in f])
        check(f"flat {v}: monotone in the amount", float(any(q < p for p, q in zip(f, f[1:]))), 0)
    check("lighter loses more than midtone", float(not lost(0.3, 0.8) > lost(0.6, 0.8)), 0)
    check("a solid holds at dropout 1", lost(1.0, 1.0), 0)
    def edges(sc):
        m = ink(frame(h, h, 0.5), dropout=1.0, tooth_scale=sc)[..., 0] == 0
        return float((m[:, 1:] != m[:, :-1]).sum())
    r = edges(0.01) / edges(0.02)
    note("tooth transitions, scale 0.01 / 0.02", round(r, 3))
    check("specks grow with tooth_scale (ratio near 2)", abs(r - 2), 0.6)


def test_edge_pool():
    """SC-005, FR-007."""
    d = disc(512, 512, 0.25)
    base = ink(d)[..., 0]
    o = ink(d, edge_pool=1.0, pool_width=0.01)[..., 0]
    delta = o - base
    check("the rim rises above the interior", float(not o.max() > 1.5), 0)
    y, x = np.mgrid[0:512, 0:512]
    r = np.hypot(x + 0.5 - 256, y + 0.5 - 256) - 128
    check("interior unchanged beyond the kernel", float(np.abs(delta[r < -24]).max()), 1e-6)
    check("exterior stays 0", float(np.abs(o[r > 1]).max()), 0)
    for v in (0.0, 0.25, 0.5, 0.8, 1.0, 1.7):
        check(f"a flat {v} field is unchanged", err(ink(frame(48, 48, v), edge_pool=1.0)[..., :3], np.full((48, 48, 3), v, F32)), 1e-6)
    def width(pw):
        q = ink(d, edge_pool=1.0, pool_width=pw)[..., 0][256] - base[256]
        return int((q[256:] > 0.5 * q.max()).sum())
    a, b = width(0.01), width(0.02)
    note("rim width in texels at pool_width 0.01, 0.02", (a, b))
    check("rim width tracks pool_width (ratio near 2)", abs(b / a - 2), 0.7)


def test_pool_follows_spread():
    """FR-008: pooling comes after spread, so the rim sits on the moved edge."""
    t = frame(1080, 8)
    t[540:, :, :3] = 1
    kw = dict(spread=1.0, bias=0.35)
    s = ink(t, **kw)[:, 4, 0]
    q = ink(t, edge_pool=1.0, pool_width=0.003, **kw)[:, 4, 0] - s
    edge = int(np.argmax(s > 0.5))
    peak = int(np.argmax(q))
    note("original edge, moved edge, rim peak (rows)", (540, edge, peak))
    check("the spread moved the edge far enough for this test to mean something", float(not 540 - edge >= 6), 0)
    check("the rim peak is at the moved edge", abs(peak - edge), 3)


def test_stability_and_seed():
    """SC-006."""
    x = disc(128, 128)
    kw = dict(spread=0.5, edge_pool=0.5, mottle=0.5, dropout=0.5)
    check("two evaluations are identical", err(ink(x, **kw), ink(x, **kw)), 0)
    check("another seed differs", float(err(ink(x, seed=2, **kw), ink(x, seed=3, **kw)) == 0), 0)


def test_render_size_and_aspect():
    """SC-006, FR-011: lengths are frame-relative, and square on a non-square frame."""
    field = lambda h, w: ink(frame(h, w, 1.0), mottle=1.0, mottle_scale=0.1)[..., 0]
    a, b = half_lag(field(256, 256)), half_lag(field(512, 512))
    note("mottle half-lag at 256 and 512", (a, b))
    check("pattern scales with the frame (ratio near 2)", abs(b / a - 2), 0.4)
    wide = field(540, 960)
    ax, ay = half_lag(wide, 1), half_lag(wide, 0)
    note("mottle half-lag on 960 x 540, along x and y", (ax, ay))
    check("features are square on a wide frame", abs(ax / ay - 1), 0.35)
    width = lambda h: int(((lambda o: (o > 0.01) & (o < 0.99))(ink(disc(h, h), spread=1.0, soften=1.0)[..., 0][h // 2])).sum()) / h
    note("spread edge width in frame heights at 270 and 540 (soften 1, so the whole blur shows)", (width(270), width(540)))
    check("edge width follows the frame", abs(width(540) / width(270) - 1), 0.25)


def test_border():
    """G7: no wrap at the frame border."""
    t = frame(128, 128)
    t[:3, :, :3] = 1
    o = ink(t, spread=1.0, edge_pool=1.0)[..., 0]
    check("ink on the top rows does not reach the bottom rows", float(o[-3:].max()), 0)
    t = frame(128, 128)
    t[:, :3, :3] = 1
    o = ink(t, spread=1.0, edge_pool=1.0)[..., 0]
    check("ink on the left columns does not reach the right columns", float(o[:, -3:].max()), 0)


def test_nonfinite_channels_alpha_bypass():
    x = frame(64, 64, 0.5)
    x[32, 32, :3] = np.nan
    x[10, 10, 1] = np.inf
    y = x.copy()
    y[32, 32, :3] = 0
    y[10, 10, 1] = 0
    kw = dict(spread=1.0, edge_pool=0.5, mottle=0.5, dropout=0.3)
    o = ink(x, **kw)
    check("no NaN or Inf reaches the output", float(not np.isfinite(o).all()), 0)
    check("a non-finite texel behaves as 0, neighbors included", err(o, ink(y, **kw)), 0)
    check("bypass passes the zapped source", err(ink(x, bypass=1.0, **kw), y), 0)
    a = np.random.default_rng(2).uniform(0, 1, (64, 64, 4)).astype(F32)
    b = a.copy()
    b[..., 1] = 1 - b[..., 1]
    kw = dict(spread=0.7, edge_pool=0.4, mottle=0.3, dropout=0.2)
    p, q = ink(a, **kw), ink(b, **kw)
    check("channels are independent (R and B unchanged when G changes)", max(err(p[..., 0], q[..., 0]), err(p[..., 2], q[..., 2])), 0)
    check("alpha passes through", err(p[..., 3], a[..., 3]), 0)
    z = ink(frame(32, 32, 0.5), spread=1.0, soften=0.0)
    check("soften 0 stays finite on a blur of exactly 0.5", float(not np.isfinite(z).all()), 0)


def test_mutations():
    """Each plausible mistake changes what the checks above look at, including the plan's two forms."""
    d = disc(128, 128)
    nan = frame(64, 64, 0.5)
    nan[32, 32, :3] = np.nan
    cases = {
        "plan_pool": (frame(32, 32, 0.5), dict(edge_pool=1.0)),
        "zap_late": (nan, dict(spread=1.0)),
        "no_soften_guard": (frame(32, 32, 0.5), dict(spread=1.0, soften=0.0)),
        "dropout_negative": (frame(32, 32, -0.5), dict()),
        "pool_no_s": (d, dict(edge_pool=1.0)),
        "mottle_additive": (frame(32, 32), dict(mottle=1.0)),
        "pool_from_source": (d, dict(spread=1.0, bias=0.2, edge_pool=1.0)),
    }
    for bug, (src, kw) in cases.items():
        a, b = ink(src, **kw), ink(src, bug=bug, **kw)
        bad = not np.isfinite(b).all()
        e = 1.0 if bad else err(a, b)
        note(f"mutation '{bug}' worst error", e)
        check(f"mutation caught: {bug}", float(e <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
