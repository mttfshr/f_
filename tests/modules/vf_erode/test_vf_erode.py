"""test_vf_erode.py -- tier-1 tests for f_vf_erode, the erosion model (spec 2026-11-10, plan ADR-3, T073). Ground truth is independent of the
mirror: invariants (conservation, non-negativity, stillness, identity), a direction (bowl, constant field) and mutations.

Covers SC-101 to SC-105 and the Polarity behavior of US3. Not covered, by design: render-size scaling (FR-111, the bench decides how),
the look (SC-107, Matt), and anything about the codeboxes (tier 2).

Run:  tests/run.sh -q tests/modules/vf_erode/test_vf_erode.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from vf_erode_mirror import F32, DEFAULTS, enc, field_uv, load, new_state, run as run_steps, step, totals  # noqa: E402

H, W = 40, 56
FAST = dict(dry=0.004)       # dry in about 250 steps instead of 600


def picture(h=H, w=W, seed=1, lo=0.1, hi=0.95):
    # lo 0.1: under Darker a display value below EPS ** (1 / GAMMA), about 0.081, is lifted to it (the log is bounded), so identity holds from there up
    t = np.zeros((h, w, 4), F32)
    t[..., :3] = np.random.default_rng(seed).uniform(lo, hi, (h, w, 3)).astype(F32)
    t[..., 3] = 1
    return t


def flat(value, h=H, w=W):
    t = np.zeros((h, w, 4), F32)
    t[..., :3] = value
    t[..., 3] = 1
    return t


def bowl(h=H, w=W, depth=6.0):
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float64)
    r2 = ((xx - (w - 1) / 2) / (w / 2)) ** 2 + ((yy - (h - 1) / 2) / (h / 2)) ** 2
    return (depth * np.minimum(r2, 1.0)).astype(F32)


def const_field(fx, fy, h=H, w=W):
    t = np.zeros((h, w, 4), F32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = fx * 0.5 + 0.5, fy * 0.5 + 0.5, 0.5, 1
    return field_uv(t)


def err(a, b):
    return float(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64)).max())


def wet(img, polarity="darker", **kw):
    return load(new_state(*img.shape[:2]), img, polarity)


def test_conservation_closed_edge():
    """SC-101: with a closed edge pigment is conserved per channel, step by step, on a rough terrain with a field."""
    img = picture()
    T = bowl() + np.random.default_rng(2).uniform(0, 0.8, (H, W)).astype(F32)
    st = wet(img)
    t0 = totals(st)
    worst = 0.0
    for _ in range(300):
        st = step(st, T, const_field(0.5, -0.3), edge="closed", **FAST)
        worst = max(worst, float(np.abs(totals(st) - t0).max() / t0.max()))
    note("worst relative drift over 300 steps", worst)
    check("closed edge: pigment per channel conserved", worst, 1e-5)
    check("closed edge: nothing escaped", float(np.abs(st["escaped"]).max()), 1e-9)


def test_conservation_open_edge():
    """T066: with an open edge, pigment in the frame plus pigment that left through the edge equals what was loaded."""
    img = picture(seed=3)
    T = np.linspace(0, 4, W, dtype=F32)[None, :].repeat(H, 0)[:, ::-1].copy()     # slopes down toward x = 0
    st = wet(img)
    t0 = totals(st)
    st = run_steps(st, 400, T, const_field(-0.4, 0.0), **FAST)
    leaked = st["escaped"]
    note("pigment that left, per channel", float(leaked.max() / t0.max()))
    check("open edge: in frame + escaped = loaded", float(np.abs(totals(st) + leaked - t0).max() / t0.max()), 1e-5)
    check("open edge: nothing comes back in", float(max(st["entered"].max(), st["entered_w"]) / t0.max()), 1e-9)
    check("open edge: some pigment did leave (the test can fail)", 1.0 - float(leaked.min() > 0.001 * t0.max()), 0)


def test_bowl():
    """SC-102: a flat tone on a bowl: pigment falls at the rim and rises at the bottom."""
    img = flat(0.4)
    st = run_steps(wet(img), 500, bowl(), None, **FAST)
    p0 = wet(img)["p"].mean(axis=2)
    p1 = (st["p"] + st["s"]).mean(axis=2)
    rim = np.zeros((H, W), bool); rim[:6] = rim[-6:] = True; rim[:, :6] = rim[:, -6:] = True
    mid = np.zeros((H, W), bool); mid[H // 2 - 4:H // 2 + 4, W // 2 - 4:W // 2 + 4] = True
    note("rim: before, after", (float(p0[rim].mean()), float(p1[rim].mean())))
    note("bottom: before, after", (float(p0[mid].mean()), float(p1[mid].mean())))
    check("pigment at the rim is lower", 1.0 - float(p1[rim].mean() < p0[rim].mean()), 0)
    check("pigment at the bottom is higher", 1.0 - float(p1[mid].mean() > p0[mid].mean()), 0)


def test_flat_and_still():
    """SC-104: a flat terrain with no field returns the input once dried, and a dried wash does not change."""
    img = picture(seed=4)
    st = run_steps(wet(img), 400, None, None, **FAST)
    out, _ = enc(st, img)
    check("flat terrain, no field: output equals the input", err(out[..., :3], img[..., :3]), 1e-5)
    nxt = step(st, None, None, **FAST)
    check("dried: a further step changes nothing (paper)", err(nxt["p"], st["p"]), 0)
    check("dried: a further step changes nothing (suspension, water)", max(err(nxt["s"], st["s"]), err(nxt["w"], st["w"])), 0)
    check("dried: no water left", float(st["w"].max()), 0)
    t = bowl()
    d = wet(img)
    for _ in range(12000):                                   # a deep pool dries at a rate per cell, so it takes far longer than the flat sheet
        d = step(d, t, const_field(0.3, 0.2), dry=0.02)
        if d["w"].max() == 0:
            break
    note("steps to dry on a bowl with a field", _ + 1)
    check("the bowl dried", float(d["w"].max()), 0)
    d2 = step(d, t, const_field(0.3, 0.2), **FAST)
    check("dried on a bowl with a field: still", err(d2["p"], d["p"]), 0)


def centroid(st):
    m = (st["p"] + st["s"]).sum(axis=2).astype(np.float64)
    yy, xx = np.mgrid[0:m.shape[0], 0:m.shape[1]]
    return float((m * xx).sum() / m.sum()), float((m * yy).sum() / m.sum())


def test_field_push():
    """SC-103: on a bowl a constant field moves the pooled pigment along it; push 0 equals no field exactly."""
    img = flat(0.4)
    T = bowl()
    none = run_steps(wet(img), 500, T, None, **FAST)
    f = const_field(0.8, 0.0)
    right = run_steps(wet(img), 500, T, f, **FAST)
    left = run_steps(wet(img), 500, T, const_field(-0.8, 0.0), **FAST)
    cx0, cx1, cx2 = centroid(none)[0], centroid(right)[0], centroid(left)[0]
    note("centroid x: none, +field, -field", (cx0, cx1, cx2))
    check("a +x field moves the centroid toward +x", 1.0 - float(cx1 > cx0 + 0.2), 0)
    check("a -x field moves it toward -x", 1.0 - float(cx2 < cx0 - 0.2), 0)
    z = run_steps(wet(img), 200, T, f, push=0.0, **FAST)
    n = run_steps(wet(img), 200, T, None, **FAST)
    check("push 0 equals no field, exactly", max(err(z["p"], n["p"]), err(z["s"], n["s"]), err(z["w"], n["w"])), 0)
    # field only (no terrain): the water runs along the field
    only = run_steps(wet(picture(seed=5)), 120, None, f, **FAST)
    check("field only: the wash moves along +x", 1.0 - float(centroid(only)[0] > centroid(wet(picture(seed=5)))[0] + 0.1), 0)


def test_stability():
    """SC-105: at the extremes of every dial nothing goes negative or non-finite, and the pigment never grows."""
    img = picture(seed=6, lo=0.01, hi=1.0)
    T = np.random.default_rng(7).uniform(0, 6, (H, W)).astype(F32)
    f = const_field(1.0, -1.0)
    cases = [dict(flow=1.0, push=3.0, lift=1.0, settle=1.0, dry=0.0, speed=4.0),
             dict(flow=0.0, push=0.0, lift=0.0, settle=0.0, dry=0.05, speed=0.1),
             dict(flow=1.0, push=0.0, lift=1.0, settle=0.0, dry=0.0, speed=4.0),
             dict(flow=0.0, push=3.0, lift=1.0, settle=0.0, dry=0.0, speed=4.0)]
    for kw in cases:
        st = wet(img)
        t0 = totals(st)
        lo, hi = 0.0, 0.0
        for _ in range(150):
            st = step(st, T, f, **kw)
            lo = min(lo, float(min(st["p"].min(), st["s"].min(), st["w"].min())))
        finite = all(np.isfinite(st[k]).all() for k in ("p", "s", "w"))
        grew = float(((totals(st) + st["escaped"]) / t0).max())
        note(f"{kw}: min layer, total/loaded", (lo, grew))
        check(f"finite {kw}", 1.0 - float(finite), 0)
        check(f"no negative layer {kw}", -lo, 1e-6)
        check(f"pigment never grows {kw}", 1.0 - float(grew <= 1 + 1e-5), 0)


def test_polarity_and_unwetted():
    """US3, T075, T076: composite against a background, thickness, and the unwetted frame."""
    img = picture(seed=8, lo=0.1, hi=1.0)
    for pol in ("darker", "lighter"):
        out, th = enc(new_state(H, W), img, None, pol)
        check(f"{pol}: unwetted, no background: output equals the input", err(out[..., :3], img[..., :3]), 1e-5)
        check(f"{pol}: alpha passes through", err(out[..., 3], img[..., 3]), 0)
    bg = picture(seed=9, lo=0.2, hi=0.8)
    out, th = enc(wet(flat(1.0), "darker"), flat(1.0), bg, "darker")
    check("darker: a white picture (no pigment) shows the background", err(out[..., :3], bg[..., :3]), 1e-5)
    check("darker: thickness is 0 with no pigment", float(np.abs(th).max()), 0)
    out, th = enc(wet(flat(0.0), "lighter"), flat(0.0), bg, "lighter")
    check("lighter: a black picture (no pigment) shows the background", err(out[..., :3], bg[..., :3]), 1e-5)
    # more pigment, no brighter (Darker) and no darker (Lighter)
    st = wet(img, "darker")
    more = dict(st, p=st["p"] * F32(1.5))
    a, b = enc(st, img, bg, "darker")[0], enc(more, img, bg, "darker")[0]
    check("darker: more pigment is never brighter", float((b[..., :3] > a[..., :3] + 1e-6).sum()), 0)
    st = wet(img, "lighter")
    more = dict(st, p=st["p"] * F32(1.5))
    a, b = enc(st, img, bg, "lighter")[0], enc(more, img, bg, "lighter")[0]
    check("lighter: more pigment is never darker", float((b[..., :3] < a[..., :3] - 1e-6).sum()), 0)
    th1 = enc(wet(img), img, None, "darker")[1]
    th2 = enc(wet(img * np.array([1, 1, 1, 1], F32) * F32(0.5)), img, None, "darker")[1]
    check("thickness rises with pigment (a darker picture is thicker)", 1.0 - float(th2.mean() > th1.mean()), 0)
    # after the first wetting a moving in0 is ignored (T074, T076)
    loaded = wet(img)
    o1 = enc(loaded, img, None)[0]
    o2 = enc(loaded, picture(seed=99), None)[0]
    check("after a wetting, in0 no longer reaches the layers", err(o1, o2), 0)


def test_input_hygiene():
    """FR-110: non-finite input texels are zapped; non-square frames run; no NaN reaches a layer."""
    img = picture(h=24, w=70, seed=10)
    img[3, 4, :3] = np.nan
    img[5, 6, 0] = np.inf
    st = run_steps(wet(img), 50, None, None, **FAST)
    check("non-finite input: every layer finite", 1.0 - float(all(np.isfinite(st[k]).all() for k in ("p", "s", "w"))), 0)
    out, th = enc(st, img)
    check("non-finite input: outlets finite", 1.0 - float(np.isfinite(out).all() and np.isfinite(th).all()), 0)


def test_mutations():
    """Each bug the plan guards against must be caught by a test above."""
    img = picture(seed=11)
    T = bowl()
    f = const_field(0.8, 0.0)
    base = run_steps(wet(img), 200, T, f, **FAST)
    back = run_steps(wet(img), 200, T, f, bug="push_backward", **FAST)
    check("mutation caught: push_backward moves the centroid the other way", 1.0 - float(centroid(back)[0] < centroid(base)[0]), 0)
    st = run_steps(wet(img), 120, T, f, bug="drop_receiver", edge="closed", **FAST)
    t0 = totals(wet(img))
    check("mutation caught: drop_receiver breaks conservation", 1.0 - float(np.abs(totals(st) - t0).max() / t0.max() > 1e-3), 0)
    st = run_steps(wet(img), 60, None, f, bug="edge_reenter", **FAST)
    check("mutation caught: edge_reenter lets pigment back in at the edge", 1.0 - float(st["entered"].max() > 1e-3 * totals(wet(img)).max()), 0)
    s2 = wet(picture(seed=6, lo=0.01, hi=1.0))
    rough = np.random.default_rng(7).uniform(0, 6, (H, W)).astype(F32)
    lo = 0.0
    for _ in range(150):
        s2 = step(s2, rough, const_field(1.0, -1.0), bug="no_flux_cap", flow=1.0, push=3.0, speed=4.0, dry=0.0)
        lo = min(lo, float(np.nanmin(s2["w"])))
    bad = (not np.isfinite(s2["w"]).all()) or lo < -1e-6
    check("mutation caught: no_flux_cap goes negative or non-finite", 1.0 - float(bad), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
