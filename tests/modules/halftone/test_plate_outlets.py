"""test_plate_outlets.py -- tier-1 tests for f_halftone's plate outlets (spec User Story 12, FR-028 to FR-030, task T037).

Outlet 0 is the combined output, outlets 1-3 the plates, Gray (default) or Color. Ground truth: outlet 0 is halftone_stage
unchanged; Color outlets sum to outlet 0 where it is not clipped; Gray is r = g = b; one plate's settings move only its
own outlet; Single uses outlet 3; an unconnected plate is black with alpha 0; bypass splits the source.

Run:  tests/run.sh -q tests/modules/halftone/test_plate_outlets.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from halftone_mirror import F32, halftone_outlets, halftone_stage  # noqa: E402


def pic(W=128, H=96, seed=21, a=None):
    rng = np.random.default_rng(seed)
    t = rng.uniform(0, 1, (H, W, 4)).astype(F32)
    if a is not None:
        t[..., 3] = a
    return t


def err(a, b):
    return float(np.abs(np.asarray(a, dtype=np.float64) - np.asarray(b, dtype=np.float64)).max())


KW = dict(pitch=0.09, softness=0.05)
SCREENS = ("dot", "line", "bayer", "blue")


def test_outlet0_unchanged():
    src = pic()
    for screen in SCREENS:
        for mode in ("channels", "single"):
            for po in ("gray", "color"):
                o = halftone_outlets(src, plate_out=po, screen=screen, plate_mode=mode, **KW)
                check(f"{screen} {mode} {po}: outlet 0 = halftone_stage", err(o[0], halftone_stage(src, screen=screen, plate_mode=mode, **KW)), 0)


def test_color_sums_to_outlet0():
    src = pic()
    for screen in SCREENS:
        for jit in ((0.0, 1.0) if screen == "dot" else (0.0,)):
            for mode in ("channels", "single"):
                o = halftone_outlets(src, plate_out="color", screen=screen, plate_mode=mode, jitter=jit, **KW)
                s = o[1][..., :3] + o[2][..., :3] + o[3][..., :3]
                check(f"{screen} jitter {jit} {mode}: Color outlets sum to outlet 0", err(np.clip(s, 0, 1), o[0][..., :3]), 1e-6)
    plates = (pic(seed=1), pic(seed=2), pic(seed=3))
    o = halftone_outlets(None, plate_out="color", plate_mode="plates", plates=plates, **KW)
    s = o[1][..., :3] + o[2][..., :3] + o[3][..., :3]
    clipped = float((s > 1).mean())
    note("plates: fraction of values the sum clips", clipped)
    check("plates: Color outlets sum to outlet 0 where not clipped", err(np.clip(s, 0, 1), o[0][..., :3]), 1e-6)
    check("plates: the clip case is exercised", float(clipped == 0), 0)


def test_channels_color_is_pure():
    o = halftone_outlets(pic(), plate_out="color", **KW)
    for k in range(3):
        other = [c for c in range(3) if c != k]
        check(f"channels Color: outlet {k + 1} has only channel {k}", float(np.abs(o[k + 1][..., other]).max()), 0)
        check(f"channels Color: outlet {k + 1} carries plate {k}", err(o[k + 1][..., k], o[0][..., k]), 0)


def test_gray():
    for mode, src, kw in (("channels", pic(), {}), ("single", pic(), {}),
                          ("plates", None, dict(plates=(pic(seed=1), pic(seed=2), pic(seed=3))))):
        g = halftone_outlets(src, plate_out="gray", plate_mode=mode, **kw, **KW)
        c = halftone_outlets(src, plate_out="color", plate_mode=mode, **kw, **KW)
        for k in (1, 2, 3):
            check(f"{mode} Gray outlet {k}: r = g = b", err(g[k][..., 0], g[k][..., 1]) + err(g[k][..., 0], g[k][..., 2]), 0)
            check(f"{mode} Gray outlet {k}: the brightest channel of Color", err(g[k][..., 0], c[k][..., :3].max(-1)), 0)
            check(f"{mode} Gray outlet {k}: alpha as Color", err(g[k][..., 3], c[k][..., 3]), 0)
    # Single: Gray is the plate's coverage, so a flat teal (0, .3, .6) gives the coverage of tone .6
    teal = np.zeros((96, 128, 4), F32)
    teal[..., 1], teal[..., 2], teal[..., 3] = 0.3, 0.6, 1
    g = halftone_outlets(teal, plate_mode="single", **KW)
    ref = halftone_stage(np.dstack([np.full((96, 128, 3), 0.6, F32), np.ones((96, 128, 1), F32)]), **KW)[..., 2]
    check("single Gray: teal's outlet 3 is the coverage of tone 0.6", err(g[3][..., 0], ref), 1e-6)


def test_single_uses_outlet3():
    src = pic(a=0.4)
    o = halftone_outlets(src, plate_out="color", plate_mode="single", **KW)
    for k in (1, 2):
        check(f"single: outlet {k} is black, alpha 0", float(np.abs(o[k]).max()), 0)
    check("single: outlet 3 is outlet 0's colour", err(o[3][..., :3], o[0][..., :3]), 0)
    check("single: outlet 3 alpha is the source's", err(o[3][..., 3], 0.4), 1e-6)


def test_plates_alpha_and_unconnected():
    p1, p3 = pic(seed=1, a=0.3), pic(seed=3, a=0.8)
    o = halftone_outlets(pic(a=0.5), plate_mode="plates", plates=(p1, None, p3), **KW)
    check("plates: outlet 2 (unconnected) is black, alpha 0", float(np.abs(o[2]).max()), 0)
    check("plates: outlet 1 alpha is plate 1's", err(o[1][..., 3], 0.3), 1e-6)
    check("plates: outlet 3 alpha is plate 3's", err(o[3][..., 3], 0.8), 1e-6)


def test_settings_reach_their_own_outlet():
    src = pic()
    a = halftone_outlets(src, angles=(15, 75, 45), **KW)
    b = halftone_outlets(src, angles=(40, 75, 45), **KW)
    check("angle R moves outlet 1", float(err(a[1], b[1]) == 0), 0)
    check("angle R leaves outlets 2 and 3", err(a[2], b[2]) + err(a[3], b[3]), 0)


def test_bypass():
    src = pic(a=0.6)
    for po in ("gray", "color"):
        o = halftone_outlets(src, plate_out=po, bypass=True, **KW)
        check(f"bypass {po}: outlet 0 is the source", err(o[0], src), 0)
        for k in range(3):
            want = src[..., k]
            check(f"bypass channels {po}: outlet {k + 1} carries channel {k}", err(o[k + 1][..., k], want), 0)
            check(f"bypass channels {po}: outlet {k + 1} alpha", err(o[k + 1][..., 3], 0.6), 1e-6)
        s = halftone_outlets(src, plate_out=po, bypass=True, plate_mode="single", **KW)
        want = src[..., :3] if po == "color" else src[..., :3].max(-1, keepdims=True).repeat(3, -1)
        check(f"bypass single {po}: outlet 3 is the source", err(s[3][..., :3], want), 0)
        check(f"bypass single {po}: outlets 1 and 2 black", float(np.abs(s[1]).max() + np.abs(s[2]).max()), 0)
    p2 = pic(seed=2, a=0.7)
    o = halftone_outlets(src, plate_out="color", bypass=True, plate_mode="plates", plates=(None, p2, None), **KW)
    check("bypass plates: outlet 2 is plate 2's input", err(o[2], p2), 0)
    check("bypass plates: outlets 1 and 3 black", float(np.abs(o[1]).max() + np.abs(o[3]).max()), 0)


def test_mutations():
    src = pic(a=0.5)
    plates = (pic(seed=1, a=0.3), None, None)
    cases = {
        "gray_from_r": (pic(), dict(plate_mode="single")),
        "single_on_out1": (pic(), dict(plate_mode="single")),
        "plate_alpha_src": (src, dict(plate_mode="plates", plates=plates)),
    }
    for bug, (s, kw) in cases.items():
        a = halftone_outlets(s, **kw, **KW)
        b = halftone_outlets(s, bug=bug, **kw, **KW)
        e = max(err(x, y) for x, y in zip(a, b))
        note(f"mutation '{bug}' worst error", e)
        check(f"mutation caught: {bug}", float(e <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
