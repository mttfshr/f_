"""test_ink.py -- tier-1 tests for the f_ink module (T016, T017, T033, T034; SC-001 to SC-006, P1 effects).

Ground truth is independent of the mirror: invariants and closed forms from the spec (identity at zero, kernel support, a flat
field stays flat, 0 stays 0, monotone amounts, ratios of feature sizes). Measurements that settle open numbers are printed as
notes, and land in the full log.

Run:  tests/run.sh -q tests/modules/ink/test_ink.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from ink_mirror import F32, SPREAD_CAP_H, blur2, blur_pass, ink, pool_blur, tap_weights  # noqa: E402


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
    check("dials without an amount do nothing", err(ink(x, snap=0.3, bias=0.4, soften=0.7, pool_width=0.03, mottle_scale=0.02, tooth_scale=0.05, seed=9), x), 0)


def test_blur_kernel():
    radii = (0.0, 0.4, 2.5, 4.67, 7.0, 30.0)
    check("weights sum to 1 at any radius", max(abs(float(tap_weights(r).sum(dtype=np.float64)) - 1) for r in radii), 1e-6)
    check("weights are symmetric", max(float(np.abs(tap_weights(r) - tap_weights(r)[::-1]).max()) for r in radii), 0)
    check("weights fall away from the center (no lumps)", float(any((np.diff(tap_weights(r)[7:]) > 0).any() for r in radii)), 0)
    w0 = tap_weights(0.0)
    check("radius 0 is one tap of weight 1", max(abs(float(w0[7]) - 1), float(np.abs(np.delete(w0, 7)).max())), 0)
    check("the weights move continuously with the radius", float(np.abs(tap_weights(3.0) - tap_weights(3.01)).max()), 2e-3)
    check("reach stops at 7 texels", float(np.abs(tap_weights(30.0) - tap_weights(7.0)).max()), 0)
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
    """SC-002: a gap under the radius fills, a wide one does not. Rows, at 1080, spread 1 (radius 7 texels)."""
    t = frame(1080, 32)
    t[500:508, :, :3] = 1
    t[510:518, :, :3] = 1      # gap of 2 at rows 508..509
    t[620:628, :, :3] = 1      # gap of 100 from the pair
    o = ink(t, spread=1.0)[..., 0]
    check("a 2-texel gap fills", 1 - float(o[508:510, 16].min()), 0.05)
    check("a 100-texel gap stays empty", float(o[560:600, 16].max()), 0)


def test_stride_comb():
    """T009, offline half: a 1-texel line through the taps. Stride 1 (Matt, 2026-11-08) keeps it smooth at every size."""
    def comb(h):
        t = frame(h, 8)[..., :1]
        t[h // 2, :, 0] = 1
        b = blur_pass(t, 0, 1.0 * SPREAD_CAP_H * h)[:, 4, 0]
        near = b[h // 2 - 8: h // 2 + 8]
        return float(np.abs(np.diff(near)).max() / near.max())
    for h in (540, 720, 1080, 2160):
        c = comb(h)
        note(f"T009: H={h}: largest step between neighbors / peak", f"{c:.3f}")
        check(f"H={h}: a line's blur has no comb", c, 0.25)
    note("T009: effective radius in texels at H=1080 and H=2160 (2160 is held at 7: half its size in frame heights)",
         (round(SPREAD_CAP_H * 1080, 3), min(round(SPREAD_CAP_H * 2160, 3), 7.0)))


def test_continuous_tone_through_spread():
    """The snap dial (Matt, 2026-11-08): 0 keeps tone, 1 hardens toward a mark, between is a blend."""
    for v in (0.2, 0.3, 0.5, 0.7, 0.8):
        flat = frame(32, 32, v)
        a = [float(ink(flat, spread=1.0, snap=q)[0, 0, 0]) for q in (0.0, 0.25, 0.5, 1.0)]
        note(f"flat {v} at spread 1 through snap 0, 0.25, 0.5, 1", [round(q, 4) for q in a])
        check(f"flat {v}: snap 0 keeps the tone", err(ink(flat, spread=1.0, snap=0.0)[..., :3], flat[..., :3]), 1e-6)
    d = disc(128, 128)
    check("snap 0 is exactly the blur", err(ink(d, spread=1.0, snap=0.0)[..., :3], blur2(d[..., :3], SPREAD_CAP_H * 128)), 0)
    hard = [int(((lambda o: (o > 0.01) & (o < 0.99))(ink(disc(540, 540), spread=1.0, snap=q)[..., 0])).sum()) for q in (0.0, 0.5, 1.0)]
    note("disc: texels between 0 and 1 at snap 0, 0.5, 1", hard)
    a = float(ink(frame(32, 32, 0.3), spread=1.0, snap=0.5)[0, 0, 0])
    check("snap blends between the blur and the mark", abs(a - 0.15), 1e-6)
    check("snap has full strength by spread 0.125", abs(float(ink(frame(32, 32, 0.3), spread=0.125, snap=1.0)[0, 0, 0])), 1e-6)
    low = float(ink(frame(32, 32, 0.3), spread=0.0625, snap=1.0)[0, 0, 0])
    note("flat 0.3 at spread 0.0625, snap 1 (half the gate)", round(low, 4))
    check("snap fades in below the gate, continuously", abs(low - 0.15), 1e-6)


def test_mottle():
    """SC-003 and FR-005 (revised 2026-11-09): ink only thins, most where it is dense."""
    h = 512
    flat = frame(h, h, 1.0)
    stds = [float(ink(flat, mottle=m)[..., 0].std()) for m in (0.0, 0.25, 0.5, 1.0)]
    note("mottle std at 0, 0.25, 0.5, 1", [round(s, 5) for s in stds])
    check("std is monotone in the amount", float(any(q <= p for p, q in zip(stds, stds[1:]))), 0)
    means = [float(ink(flat, mottle=m)[..., 0].mean()) for m in (0.0, 0.25, 0.5, 1.0)]
    note("mottle mean on flat 1 at 0, 0.25, 0.5, 1", [round(s, 5) for s in means])
    check("the mean falls with the amount", float(any(q >= p for p, q in zip(means, means[1:]))), 0)
    check("mottle never adds ink", float(ink(flat, mottle=1.0)[..., 0].max()) - 1.0, 0)
    check("coverage 0 stays 0", float(np.abs(ink(frame(64, 64), mottle=1.0)[..., :3]).max()), 0)
    low = float(np.abs(ink(frame(64, 64, 0.1), mottle=1.0)[..., 0] - 0.1).max())
    check("light tones are left alone (below the density weight)", low, 1e-6)
    field = lambda sc, s: ink(flat, mottle=1.0, mottle_scale=sc, seed=s)[..., 0]
    a = np.mean([half_lag(field(0.1, s)) for s in (1, 2, 3, 4)])
    b = np.mean([half_lag(field(0.2, s)) for s in (1, 2, 3, 4)])
    note("mottle half-lag in texels at scale 0.1, 0.2", (a, b))
    check("correlation length tracks the scale (ratio near 2)", abs(b / a - 2), 0.7)



def test_dropout():
    """SC-004 and FR-006 (revised 2026-11-09): soft edges, light first, pinholes reach solids only at high amounts."""
    h = 512
    def lost(v, d, sc=0.01, seed=1):
        return float((ink(frame(h, h, v), dropout=d, tooth_scale=sc, seed=seed)[..., 0] == 0).mean())
    for v in (0.3, 0.6):
        f = [lost(v, d) for d in (0, 0.4, 0.7, 1.0)]
        note(f"dropped fraction of flat {v} at dropout 0, 0.4, 0.7, 1", [round(q, 4) for q in f])
        check(f"flat {v}: monotone in the amount", float(any(q < p for p, q in zip(f, f[1:]))), 0)
    check("lighter loses more than midtone", float(not lost(0.3, 0.8) > lost(0.6, 0.8)), 0)
    check("a solid holds at dropout 0.5", lost(1.0, 0.5), 0)
    pin = lost(1.0, 1.0)
    note("fraction of a solid lost at dropout 1", round(pin, 4))
    check("a solid takes some pinholes at dropout 1", float(not 0 < pin < 0.5), 0)
    o = ink(frame(h, h, 0.5), dropout=0.7, tooth_scale=0.02)[..., 0]
    check("edges are soft (values between 0 and the input exist)", float(not ((o > 0.01) & (o < 0.49)).any()), 0)
    def edges(sc):
        m = ink(frame(h, h, 0.5), dropout=1.0, tooth_scale=sc)[..., 0] == 0
        return float((m[:, 1:] != m[:, :-1]).sum())
    r = edges(0.02) / edges(0.04)
    note("tooth transitions, scale 0.02 / 0.04", round(r, 3))
    check("specks grow with tooth_scale (ratio near 2)", abs(r - 2), 0.6)



def test_edge_pool():
    """SC-005, FR-007 (reversed 2026-11-09): the rim stays full and the body of the mark thins."""
    d = disc(512, 512, 0.25)
    a = 0.4
    o = ink(d, edge_pool=a)[..., 0]
    y, x = np.mgrid[0:512, 0:512]
    r = np.hypot(x + 0.5 - 256, y + 0.5 - 256) - 128
    check("deep inside, the mark is at 1 - amount", float(np.abs(o[r < -32] - (1 - a)).max()), 1e-5)
    check("the rim is brighter than the body", float(not o[(r < 0) & (r > -3)].max() > (1 - a) + 0.3), 0)
    check("nothing exceeds the input (visible on a full-value mark)", float(o.max()) - 1.0, 1e-5)
    check("exterior stays 0", float(np.abs(o[r > 1]).max()), 0)
    for v in (0.0, 0.25, 0.5, 0.8, 1.0, 1.7):
        check(f"a flat {v} field thins to {v} * (1 - amount)", err(ink(frame(48, 48, v), edge_pool=a)[..., :3], np.full((48, 48, 3), v * (1 - a), F32)), 1e-5)
    half = frame(256, 8, 0.0)
    half[128:, :, :3] = 0.5
    p = ink(half, edge_pool=a)[:, 4, 0]
    check("a partial tone gets the same rim, in proportion", abs(float(p[128:131].max()) / 0.5 - float(ink(half * 2, edge_pool=a)[:, 4, 0][128:131].max())), 0.02)
    t = frame(1080, 8)
    t[540:, :, :3] = 1
    def width(pw):
        """Summed rim height / peak, so the width is not quantized to whole texels."""
        q = ink(t, edge_pool=1.0, pool_width=pw)[:, 4, 0]
        return float(q.sum() / q.max())
    b, c = width(0.007), width(0.014)
    note("rim width in texels at pool_width 0.007, 0.014 (7.6 and 15 texels at 1080)", (round(b, 3), round(c, 3)))
    check("rim width tracks pool_width (ratio between 1.4 and 2.2)", float(not 1.4 < c / b < 2.2), 0)
    line = frame(1080, 8)[..., :1]
    line[540, :, 0] = 1
    for w_tx in (3.0, 9.0, 15.0, 21.0):
        q = pool_blur(line, w_tx)[:, 4, 0]
        near = q[540 - 30: 540 + 30]
        c_ = float(np.abs(np.diff(near)).max() / near.max())
        note(f"pool blur of a 1-texel line, width {w_tx}: largest step / peak", round(c_, 3))
        check(f"pool blur width {w_tx}: no comb", c_, 0.6)



def test_pool_follows_spread():
    """FR-008: pooling comes after spread, so the rim sits on the moved edge."""
    t = frame(1080, 8)
    t[540:, :, :3] = 1
    kw = dict(spread=1.0, bias=0.45)
    o = ink(t, edge_pool=0.6, pool_width=0.004, **kw)[:, 4, 0]
    edge = int(np.argmax(ink(t, **kw)[:, 4, 0] > 0.5))
    peak = int(np.argmax(o))
    note("original edge, moved edge, rim peak (rows)", (540, edge, peak))
    check("the spread moved the edge far enough for this test to mean something", float(not 540 - edge >= 4), 0)
    check("the rim peak is nearer the moved edge than the original", float(not abs(peak - edge) < abs(peak - 540)), 0)
    check("the rim peak is at the moved edge", abs(peak - edge), 3)



def test_stability_and_seed():
    """SC-006."""
    x = disc(128, 128)
    kw = dict(spread=0.5, edge_pool=0.5, mottle=0.5, dropout=0.5)
    check("two evaluations are identical", err(ink(x, **kw), ink(x, **kw)), 0)
    check("another seed differs", float(err(ink(x, seed=2, **kw), ink(x, seed=3, **kw)) == 0), 0)


def test_render_size_and_aspect():
    """SC-006, FR-011: lengths are frame-relative, and square on a non-square frame."""
    field = lambda h, w: ink(frame(h, w, 1.0), mottle=1.0, mottle_scale=0.2)[..., 0]
    a, b = half_lag(field(256, 256)), half_lag(field(512, 512))
    note("mottle half-lag at 256 and 512", (a, b))
    check("pattern scales with the frame (ratio near 2)", abs(b / a - 2), 0.4)
    wide = field(540, 960)
    ax, ay = half_lag(wide, 1), half_lag(wide, 0)
    note("mottle half-lag on 960 x 540, along x and y", (ax, ay))
    check("features are square on a wide frame", abs(ax / ay - 1), 0.35)
    width = lambda h: int(((lambda o: (o > 0.01) & (o < 0.99))(ink(disc(h, h), spread=1.0, soften=1.0)[..., 0][h // 2])).sum()) / h
    note("spread edge width in frame heights at 540 and 1080 (soften 1, so the whole blur shows)", (width(540), width(1080)))
    check("edge width follows the frame", abs(width(1080) / width(540) - 1), 0.25)


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


def test_fields():
    """FR-017: a connected field replaces the built-in noise; its luma is what counts."""
    rng = np.random.default_rng(5)
    f = frame(64, 64)
    f[..., :3] = rng.uniform(0, 1, (64, 64, 1))
    o = ink(frame(64, 64, 1.0), mottle=0.6, mottle_field=f)[..., 0]
    check("mottle field on flat 1: out = 1 - amount * field", err(o, 1 - 0.6 * f[..., 0]), 1e-5)
    check("the seed and scale do nothing once a field is patched", err(o, ink(frame(64, 64, 1.0), mottle=0.6, mottle_field=f, seed=9, mottle_scale=0.3)[..., 0]), 0)
    g = frame(64, 64)
    g[..., 1] = 1.0
    o = ink(frame(64, 64, 1.0), mottle=1.0, mottle_field=g)[..., 0]
    check("a green field reads as its luma (0.7152)", err(o, np.full((64, 64), 1 - 0.7152, F32)), 1e-5)
    half = frame(64, 64)
    half[:, 32:, :3] = 1.0
    o = ink(frame(64, 64, 0.5), dropout=0.8, tooth_field=half)[..., 0]
    check("tooth 0 keeps the ink", err(o[:, :32], np.full((64, 32), 0.5, F32)), 1e-6)
    check("tooth 1 removes it", float(np.abs(o[:, 32:]).max()), 1e-6)
    bad = frame(64, 64, 0.5)
    bad[3, 3, :3] = np.nan
    check("a non-finite field cannot reach the output", float(not np.isfinite(ink(frame(64, 64, 1.0), mottle=1.0, mottle_field=bad, dropout=0.5, tooth_field=bad)).all()), 0)
    check("fields do nothing at amount 0", err(ink(frame(64, 64, 0.7), mottle_field=f, tooth_field=f), frame(64, 64, 0.7)), 0)


def test_mutations():
    """Each plausible mistake changes what the checks above look at."""
    d = disc(128, 128)
    nan = frame(64, 64, 0.5)
    nan[32, 32, :3] = np.nan
    g = frame(64, 64, 0.3)
    cases = {
        "pool_additive": (d, dict(edge_pool=1.0)),
        "zap_late": (nan, dict(spread=1.0)),
        "no_soften_guard": (frame(32, 32, 0.5), dict(spread=1.0, soften=0.0)),
        "mottle_additive": (frame(32, 32), dict(mottle=1.0)),
        "pool_from_source": (d, dict(spread=1.0, bias=0.2, edge_pool=1.0)),
        "snap_ignored": (frame(32, 32, 0.3), dict(spread=1.0, snap=0.0)),
        "field_ignored": (frame(64, 64, 1.0), dict(mottle=1.0, mottle_field=g)),
        "dropout_hard": (frame(128, 128, 0.5), dict(dropout=0.7, tooth_scale=0.05)),
    }
    half = frame(128, 8)
    half[64:, :, :3] = 0.5
    cases["pool_no_norm"] = (half, dict(edge_pool=1.0))     # a partial tone: the band alone would under-read its rim
    for bug, (src, kw) in cases.items():
        a, b = ink(src, **kw), ink(src, bug=bug, **kw)
        bad = not np.isfinite(b).all()
        e = 1.0 if bad else err(a, b)
        note(f"mutation '{bug}' worst error", e)
        check(f"mutation caught: {bug}", float(e <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
