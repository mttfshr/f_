"""test_vf_erode.py -- tier-1 tests for f_vf_erode as narrowed 2026-11-09 (spec "Narrowed", plan ADR-9, T050). Ground truth is independent of the
mirror: closed forms (a linear ramp under a uniform field, a converging field on flat tone), invariants (identity, conservation, a flat
interior holds still, render-size scaling) and mutations.

Run:  tests/run.sh -q tests/modules/vf_erode/test_vf_erode.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from vf_erode_mirror import EDGE_G0, F32, TRAVEL_MAX, ink, span_tx  # noqa: E402


def frame(h, w, value=0.0):
    t = np.zeros((h, w, 4), dtype=F32)
    t[..., :3] = value
    t[..., 3] = 1
    return t


def uniform_field(h, w, fx=0.0, fy=0.0):
    t = np.zeros((h, w, 4), dtype=F32)
    t[..., 0] = fx * 0.5 + 0.5
    t[..., 1] = fy * 0.5 + 0.5
    t[..., 2] = 0.5
    t[..., 3] = 1
    return t


def smooth(h, w, seed=1):
    """A smooth tone, in frame-relative coordinates, the kind of frame Matt tested on."""
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    u, v = (xx + 0.5) / h, (yy + 0.5) / h
    t = frame(h, w)
    for i in range(3):
        a = 0.5 + 0.22 * np.sin(5.1 * u + 1.3 * seed + i) * np.cos(6.3 * v + i * 2) + 0.15 * np.sin(11.0 * u + 7.0 * v + seed)
        t[..., i] = a.astype(F32)
    return t


def swirl_field(h, w, seed=2):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    u, v = (xx + 0.5) / h, (yy + 0.5) / h
    fx = 0.6 * np.sin(7.0 * v + seed) * np.cos(4.0 * u)
    fy = 0.6 * np.cos(6.0 * u + seed) * np.sin(5.0 * v)
    t = uniform_field(h, w)
    t[..., 0], t[..., 1] = (fx * 0.5 + 0.5).astype(F32), (fy * 0.5 + 0.5).astype(F32)
    return t


def err(a, b):
    return float(np.abs(np.asarray(a, dtype=np.float64) - np.asarray(b, dtype=np.float64)).max())


def test_identity():
    x = np.random.default_rng(1).uniform(-0.5, 2.0, (64, 96, 4)).astype(F32)
    f = swirl_field(64, 96)
    check("amounts 0: exactly the input", err(ink(x, f), x), 0)
    check("travel alone does nothing", err(ink(x, f, travel=1.0), x), 0)
    check("no field: exactly the input, amounts up", err(ink(x, None, extent=2.0, bulge=2.0), x), 0)
    check("travel 0: exactly the input, amounts up", err(ink(x, f, travel=0.0, extent=2.0, bulge=2.0), x), 0)


def test_flat_field_cases():
    flat = frame(64, 64, 0.6)
    check("a flat tone in a uniform field stays flat", err(ink(flat, uniform_field(64, 64, 0.8, -0.4), extent=2.0, bulge=2.0), flat), 1e-6)


def test_extent_closed_form():
    """c = b * x under a uniform Fx: P = c * exp(-a * T * Fx * b / c), away from the border."""
    h, w = 256, 256
    b = 0.002
    t = frame(h, w)
    t[..., :3] = (0.2 + b * np.arange(w, dtype=np.float64))[None, :, None].astype(F32)
    o = ink(t, uniform_field(h, w, 0.5), travel=0.4, extent=1.5)
    T = 0.4 * TRAVEL_MAX * h
    c = np.asarray(t[..., :3], np.float64)
    want = c * np.exp(-1.5 * T * 0.5 * b / c)
    check("ramp under a uniform field: the closed form", err(o[8:-8, 8:-8, :3], want[8:-8, 8:-8]), 1e-5)


def test_extent_converging_field_gathers():
    h, w = 128, 128
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    sink = uniform_field(h, w)
    sink[..., 0] = (((64.0 - xx) / 128.0) * 0.5 + 0.5).astype(F32)
    sink[..., 1] = (((64.0 - yy) / 128.0) * 0.5 + 0.5).astype(F32)
    o = ink(frame(h, w, 0.5), sink, travel=0.5, extent=1.0)[..., 0]
    T = 0.5 * TRAVEL_MAX * h
    want = 0.5 * np.exp(1.0 * T * (2.0 / 128.0))
    note("flat 0.5 in a sink: center, expected", (round(float(o[64, 64]), 5), round(want, 5)))
    check("a converging field gathers ink", abs(float(o[64, 64]) - want), 1e-4)
    source = uniform_field(h, w)
    source[..., 0] = 1.0 - sink[..., 0]
    source[..., 1] = 1.0 - sink[..., 1]
    check("a diverging field starves it", float(not ink(frame(h, w, 0.5), source, travel=0.5, extent=1.0)[64, 64, 0] < 0.5), 0)


def test_extent_conserves_ink():
    """Transport moves ink rather than dimming it: the failure of the last design."""
    h, w = 512, 512
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    r2 = (xx - 256) ** 2 + (yy - 256) ** 2
    bump = frame(h, w)
    bump[..., :3] = (0.8 * np.exp(-r2 / (2 * 40.0 ** 2)))[..., None].astype(F32)
    env = np.exp(-r2 / (2 * 120.0 ** 2))
    f = uniform_field(h, w)
    f[..., 0] = (env * np.sin((xx + yy) / 30.0) * 0.5 * 0.6 + 0.5).astype(F32)
    f[..., 1] = (env * np.cos((xx - yy) / 30.0) * 0.5 * 0.6 + 0.5).astype(F32)
    o = ink(bump, f, travel=0.5, extent=1.0)[..., 0]
    a, b = float(bump[..., 0].mean()), float(o.mean())
    note("mean before, after", (round(a, 6), round(b, 6)))
    # 2% with the additive step (0.003% measured); the gain form measures 4.2%, the price of keeping the color and staying above 0.
    check("the total of ink is roughly conserved (within 6%)", abs(b / a - 1), 0.06)
    check("while it did move", float(not err(o, bump[..., 0]) > 0.05), 0)


def test_extent_keeps_the_color_of_the_ink():
    """Matt, 2026-11-09: accumulation is the same color as the ink, more intense. One gain for the three channels, never below 0."""
    h, w = 256, 256
    x = smooth(h, w)
    x[..., 0] = np.clip(x[..., 0] + 0.2, 0.05, 2)
    x[..., 1] = np.clip(x[..., 1], 0.05, 2)
    x[..., 2] = np.clip(x[..., 2] - 0.2, 0.05, 2)
    o = ink(x, swirl_field(h, w), travel=1.0, extent=2.0)
    g = o[..., :3] / x[..., :3]
    check("every channel takes the same gain", float((g.max(-1) - g.min(-1)).max()), 1e-5)
    check("the gain reaches both sides of 1", float(not (g.min() < 0.8 and g.max() > 1.25)), 0)
    strong = frame(h, w, 0.5)
    strong[:, 128:, :3] = 0.9
    s = ink(strong, uniform_field(h, w, 1.0), travel=1.0, extent=2.0)
    check("nothing goes below 0, however strong the flow", float(-min(float(s[..., :3].min()), 0.0)), 0)


def test_bulge_moves_only_edges():
    h, w = 256, 256
    t = frame(h, w)
    t[:, 128:, :3] = 1
    f = uniform_field(h, w, 1.0)
    o = ink(t, f, travel=0.5, bulge=1.0)[..., 0]
    d = 0.5 * TRAVEL_MAX * h
    note("step edge at x = 128, travel distance in texels", d)
    s = int(span_tx(h))
    check("flat ink beyond the span holds still", err(o[:, 128 + s + 1:], np.ones((h, w - 129 - s), F32)), 1e-6)
    check("flat paper beyond the span holds still", err(o[:, :128 - s - 1], np.zeros((h, 127 - s), F32)), 1e-6)
    check("the edge moved", float(err(o, t[..., 0]) < 0.1), 0)
    tone = smooth(256, 256)
    g = swirl_field(256, 256)
    a = ink(tone, g, travel=0.5, bulge=0.5)
    b = ink(tone, g, travel=0.5, bulge=1.5)
    c = ink(tone, g, travel=0.5, bulge=1.0)
    check("more bulge moves it further", float(not err(b, tone) > err(c, tone) > err(a, tone)), 0)


def test_bulge_follows_the_field():
    """A soft ramp under a +x field: ink moves toward +x, so at any texel the value read comes from smaller x."""
    h, w = 256, 256
    t = frame(h, w)
    t[..., :3] = (np.arange(w, dtype=np.float64) / (w - 1.0) * 0.5 + 0.25)[None, :, None].astype(F32)
    slope = 0.5 / (w - 1.0) * h
    e = min(slope / EDGE_G0, 1.0)
    o = ink(t, uniform_field(h, w, 1.0), travel=0.5, bulge=1.0)[..., 0]
    d = 0.5 * TRAVEL_MAX * h * 1.0 * e
    check("the ramp shifts along the field by travel * edge weight", err(o[32:-32, 32:-32], t[32:-32, 32:-32, 0] - F32(d * 0.5 / (w - 1.0))), 1e-5)


def test_render_size():
    """FR-011: travel is frame-relative, so the picture scales with the frame."""
    a = ink(smooth(256, 256), swirl_field(256, 256), travel=0.5, extent=1.0, bulge=1.0)
    b = ink(smooth(512, 512), swirl_field(512, 512), travel=0.5, extent=1.0, bulge=1.0)
    e = err(a[16:-16:4, 16:-16:4, :3], (b[32:-32:8, 32:-32:8, :3] + b[33:-31:8, 33:-31:8, :3]) * 0.5)
    note("256 against 512, worst difference", e)
    check("the result follows the frame", e, 0.02)
    wide = ink(smooth(256, 512), swirl_field(256, 512), travel=0.5, extent=1.0)
    check("a wide frame computes", float(not np.isfinite(wide).all()), 0)


def test_border_nonfinite_channels_alpha_bypass():
    t = frame(128, 128)
    t[:3, :, :3] = 1
    o = ink(t, uniform_field(128, 128, 0.0, -1.0), travel=1.0, bulge=1.0, extent=1.0)[..., 0]
    check("ink at the top does not wrap to the bottom", float(np.abs(o[-3:]).max()), 0)
    x = smooth(64, 64)
    x[20, 20, :3] = np.nan
    x[30, 30, 1] = np.inf
    f = swirl_field(64, 64)
    f[10, 10, :2] = np.nan
    kw = dict(travel=0.5, extent=1.0, bulge=1.0)
    o = ink(x, f, **kw)
    check("no NaN or Inf reaches the output", float(not np.isfinite(o).all()), 0)
    z = x.copy()
    z[20, 20, :3] = 0
    z[30, 30, 1] = 0
    check("bypass passes the zapped source", err(ink(x, f, bypass=1.0, **kw), z), 0)
    a = np.random.default_rng(2).uniform(0, 1, (64, 64, 4)).astype(F32)
    b = a.copy()
    b[..., 1] = 1 - b[..., 1]
    p, q = ink(a, f, travel=0.5, bulge=1.0), ink(b, f, travel=0.5, bulge=1.0)
    check("bulge keeps channels independent", max(err(p[..., 0], q[..., 0]), err(p[..., 2], q[..., 2])), 0)
    p = ink(a, f, **kw)
    check("alpha passes through", err(p[..., 3], a[..., 3]), 0)
    check("output is not clamped: a value above 1 survives", err(ink(frame(32, 32, 1.7), uniform_field(32, 32)), frame(32, 32, 1.7)), 0)
    check("a neutral field changes nothing", err(ink(frame(64, 64, 1.0), uniform_field(64, 64), extent=2.0), frame(64, 64, 1.0)), 0)


def test_mutations():
    h, w = 128, 128
    tone, f = smooth(h, w), swirl_field(h, w)
    bad = f.copy()
    bad[9, 9, :2] = np.nan
    cases = {
        "extent_sign": (tone, f, dict(extent=1.0)),
        "no_div": (tone, f, dict(extent=1.0)),
        "no_edge_weight": (tone, f, dict(bulge=1.0)),
        "bulge_backward": (tone, f, dict(bulge=1.0)),
        "travel_in_texels": (tone, f, dict(extent=1.0)),
        "no_field_zap": (tone, bad, dict(extent=1.0)),
        "per_channel": (tone, f, dict(extent=1.0)),
    }
    for bug, (src, fld, kw) in cases.items():
        a, b = ink(src, fld, **kw), ink(src, fld, bug=bug, **kw)
        e = 1.0 if not np.isfinite(b).all() else err(a, b)
        note(f"mutation '{bug}' worst error", e)
        check(f"mutation caught: {bug}", float(e <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
