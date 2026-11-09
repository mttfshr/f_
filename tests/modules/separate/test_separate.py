"""test_separate.py -- tier-1 tests for the not-yet-built f_separate module (T014, T015; SC-001 to SC-006).

Ground truth is independent of the mirror: closed forms from the spec (an ink's own colour gives
its plate, sums of orthogonal inks, black gives black, the round trip x = K c, the one-ink
projection k.x / k.k) and a float64 least-squares reference (np.linalg.lstsq, clamped).

Run:  tests/run.sh -q tests/modules/separate/test_separate.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from separate_mirror import F32, inv_cofactor, separate_stage  # noqa: E402

RGB3 = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]], dtype=F32)
SPOT = np.array([[1.0, 0.25, 0.0], [0.0, 0.6, 0.6], [0.45, 0.0, 1.0]], dtype=F32)   # warm, teal, violet


def px(*rgb, a=1.0):
    t = np.zeros((1, 1, 4), dtype=F32)
    t[0, 0, :3] = rgb
    t[0, 0, 3] = a
    return t


def img(rows):
    a = np.zeros((1, len(rows), 4), dtype=F32)
    a[0, :, :3] = np.asarray(rows, dtype=F32)
    a[0, :, 3] = 1
    return a


def err(a, b):
    return float(np.abs(np.asarray(a, dtype=np.float64) - np.asarray(b, dtype=np.float64)).max())


def test_cofactor_inverse():
    rng = np.random.default_rng(1)
    worst = 0.0
    for n in (1, 2, 3):
        for _ in range(50):
            a = rng.uniform(-1, 1, (n, n)).astype(F32)
            m = (a @ a.T + 0.5 * np.eye(n, dtype=F32)).astype(F32)
            worst = max(worst, err(inv_cofactor(m), np.linalg.inv(m.astype(np.float64))))
    check("cofactor inverse vs float64 inverse", worst, 1e-4)


def test_ink_patches():
    """SC-001: a patch exactly an ink's colour gives that plate exactly that colour, the others black."""
    worst = 0.0
    for inks in (RGB3, SPOT):
        for i in range(3):
            out = separate_stage(img([inks[i]]), inks)
            for j in range(3):
                want = inks[i] if j == i else np.zeros(3)
                worst = max(worst, err(out[j][0, 0, :3], want))
            worst = max(worst, err(out[3][0, 0, :3], inks[i]))
    note("worst plate error", worst)
    check("ink patches", worst, 2e-3)


def test_overlaps_and_black():
    """Overlap of orthogonal inks is the sum; half coverage gives half plates; black gives black."""
    out = separate_stage(img([[1, 1, 0]]), RGB3)
    check("red+green plates", err([out[0][0, 0, :3], out[1][0, 0, :3], out[2][0, 0, :3]], [[1, 0, 0], [0, 1, 0], [0, 0, 0]]), 1e-3)
    check("red+green preview", err(out[3][0, 0, :3], [1, 1, 0]), 1e-3)
    half = separate_stage(img([0.5 * SPOT[0] + 0.5 * SPOT[1]]), SPOT)
    check("half coverage plate 0", err(half[0][0, 0, :3], 0.5 * SPOT[0]), 2e-3)
    check("half coverage plate 1", err(half[1][0, 0, :3], 0.5 * SPOT[1]), 2e-3)
    blk = separate_stage(img([[0, 0, 0]]), SPOT)
    check("black gives black", max(float(np.abs(o[0, 0, :3]).max()) for o in blk), 1e-6)


def test_round_trip():
    """SC-002: in the palette's gamut the preview equals the source; outside it equals a float64 ridge solve (and is within the ridge's bias of the plain LS)."""
    rng = np.random.default_rng(7)
    worst_in = worst_out = worst_bias = 0.0
    done = 0
    while done < 60:
        k = rng.uniform(0.1, 1, (3, 3)).astype(F32)
        if np.linalg.cond(k.astype(np.float64)) > 12:
            continue
        done += 1
        c = rng.uniform(0, 1, (8, 3)).astype(F32)
        x = c @ k                                    # rows: sum_i c_i k_i
        inside = x.max(-1) <= 1.0
        out = separate_stage(img(x), k)
        if inside.any():
            worst_in = max(worst_in, err(out[3][0, inside, :3], x[inside]))
        y = rng.uniform(0, 1, (8, 3)).astype(F32)   # arbitrary colours, mostly outside the gamut
        out = separate_stage(img(y), k)
        kd, yd = k.T.astype(np.float64), y.astype(np.float64).T          # kd = K (3 x N)
        c_ls = np.clip(np.linalg.lstsq(kd, yd, rcond=None)[0].T, 0, 1)    # unregularised, clamped
        ktk = kd.T @ kd
        lam = float(F32(1e-4)) * np.trace(ktk) / 3 + 1e-8
        c_rg = np.clip(np.linalg.solve(ktk + lam * np.eye(3), kd.T @ yd).T, 0, 1)   # the mirror's ridge, float64
        worst_out = max(worst_out, err(out[3][0, :, :3], np.clip(c_rg @ k.astype(np.float64), 0, 1)))
        worst_bias = max(worst_bias, err(out[3][0, :, :3], np.clip(c_ls @ k.astype(np.float64), 0, 1)))
    note("in-gamut round trip worst", worst_in)
    note("out-of-gamut vs float64 ridge solve worst (float32 rounding)", worst_out)
    note("out-of-gamut vs unregularised float64 LS worst (the ridge's bias, palettes with cond <= 12)", worst_bias)
    check("round trip in gamut", worst_in, 3e-3)
    check("out of gamut matches the float64 ridge solve", worst_out, 1e-3)
    check("ridge bias against the unregularised LS stays small", worst_bias, 1e-2)


def test_bounds_and_nonfinite():
    """SC-003 / FR-010: every output in 0..1 and finite for any input."""
    bad = [[5, 5, 5], [-3, -3, -3], [np.nan, 1, 0], [np.inf, -np.inf, 0.5], [0.2, np.nan, np.nan]]
    out = separate_stage(img(bad), SPOT)
    worst_range = 0.0
    finite = 1.0
    for o in out:
        finite = min(finite, float(np.isfinite(o).all()))
        worst_range = max(worst_range, float(o[..., :3].max() - 1), float(-o[..., :3].min()))
    check("all outputs finite", 1 - finite, 0)
    check("all outputs within 0..1", max(worst_range, 0), 0)


def test_degenerate_palettes():
    """SC-004: black ink, duplicate inks, collinear inks give no NaN/Inf and a defined result."""
    pal_black = np.array([[0, 0, 0], [0, 0.6, 0.6], [0.45, 0, 1]], dtype=F32)
    pal_dup = np.array([[1, 0.2, 0], [1, 0.2, 0], [0, 0, 1]], dtype=F32)
    pal_col = np.array([[1, 0.2, 0], [0.5, 0.1, 0.0005], [0, 0, 1]], dtype=F32)
    rng = np.random.default_rng(3)
    x = rng.uniform(0, 1, (32, 3)).astype(F32)
    for name, pal in (("black", pal_black), ("duplicate", pal_dup), ("collinear", pal_col)):
        out = separate_stage(img(x), pal)
        ok = all(np.isfinite(o).all() and o[..., :3].min() >= 0 and o[..., :3].max() <= 1 for o in out)
        check(f"{name} palette finite and bounded", 0 if ok else 1, 0)
    out = separate_stage(img([0.5 * pal_dup[0]]), pal_dup)
    note("duplicate-ink preview error for a reproducible colour", err(out[3][0, 0, :3], 0.5 * pal_dup[0]))
    check("duplicate inks still reproduce a reproducible colour", err(out[3][0, 0, :3], 0.5 * pal_dup[0]), 3e-3)
    out = separate_stage(img([[0, 0.6, 0.6]]), pal_black)
    check("black ink gets no coverage", float(np.abs(out[0][0, 0, :3]).max()), 1e-6)


def test_fewer_inks():
    """P4, User Story 3: unused plates are exactly black; one ink is the projection k.x / k.k."""
    x = np.array([0.3, 0.9, 0.5], dtype=F32)
    ink = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]], dtype=F32)
    out = separate_stage(img([x]), ink, n_inks=1)
    check("one ink: plate is the projection", err(out[0][0, 0, :3], [0.3, 0, 0]), 1e-3)
    check("one ink: unused plates black", float(max(np.abs(out[1][..., :3]).max(), np.abs(out[2][..., :3]).max())), 0)
    out = separate_stage(img([x]), SPOT, n_inks=2)
    check("two inks: plate 3 exactly black", float(np.abs(out[2][..., :3]).max()), 0)
    grey = np.array([[0.8, 0.8, 0.8]] * 3, dtype=F32)
    ramp = [[v, v, v] for v in np.linspace(0, 1, 17)]
    out = separate_stage(img(ramp), grey, n_inks=1)
    p = out[0][0, :, 0]
    check("one grey ink: plate monotone in brightness", float(np.maximum(0, p[:-1] - p[1:]).max()), 1e-6)


def test_nearest():
    """P6, FR-008, SC-006: at most one plate non-black, equal to its ink colour; black is a candidate."""
    rng = np.random.default_rng(5)
    x = rng.uniform(0, 1, (200, 3)).astype(F32)
    out = separate_stage(img(x), SPOT, mode="nearest")
    nz = sum((o[0, :, :3].max(-1) > 0).astype(int) for o in out[:3])
    check("at most one plate per pixel", float(max(nz.max() - 1, 0)), 0)
    worst = 0.0
    for i in range(3):
        o = separate_stage(img([SPOT[i]]), SPOT, mode="nearest")
        worst = max(worst, err(o[i][0, 0, :3], SPOT[i]))
    check("exact ink colours map to their plate", worst, 1e-6)
    dark = separate_stage(img([[0.01, 0.01, 0.01]]), SPOT, mode="nearest")
    check("near-black goes to no plate", max(float(np.abs(o[..., :3]).max()) for o in dark), 0)


def test_project_mode():
    """P12: each plate depends only on the source and its own ink; orthogonal inks equal the joint solve."""
    rng = np.random.default_rng(13)
    x = rng.uniform(0, 1, (64, 3)).astype(F32)
    base = separate_stage(img(x), SPOT, mode="project")
    worst = 0.0
    for j in (0, 1, 2):                                      # move ink j: the other plates must not change at all
        moved = SPOT.copy()
        moved[j] = rng.uniform(0, 1, 3).astype(F32)
        out = separate_stage(img(x), moved, mode="project")
        for i in (0, 1, 2):
            if i != j:
                worst = max(worst, err(out[i], base[i]))
    note("worst change of an untouched plate", worst)
    check("project: an ink's plate does not depend on the other inks", worst, 0)
    a = separate_stage(img(x), RGB3, mode="project")
    b = separate_stage(img(x), RGB3, mode="unmix")
    check("project equals unmix for orthogonal inks", max(err(a[i], b[i]) for i in range(4)), 2e-3)
    ink1 = separate_stage(img([SPOT[1]]), SPOT, mode="project")
    check("project: an ink's own colour gives its plate in full", err(ink1[1][0, 0, :3], SPOT[1]), 1e-3)
    note("project bleed into plate 3 from the teal patch (shared blue)", float(np.abs(ink1[2][0, 0, :3]).max()))
    grey = np.array([[0.8, 0.8, 0.8]] * 3, dtype=F32)
    ramp = img([[v, v, v] for v in np.linspace(0, 1, 17)])
    p = separate_stage(ramp, grey, n_inks=1, mode="project")[0][0, :, 0]
    u = separate_stage(ramp, grey, n_inks=1, mode="unmix")[0][0, :, 0]
    check("one ink: project equals unmix", err(p, u), 2e-3)
    black = np.array([[0, 0, 0], [0, 0.6, 0.6], [0.45, 0, 1]], dtype=F32)
    o = separate_stage(img(x), black, mode="project")
    check("project with a black ink: finite and the black ink's plate is black",
          float(np.abs(o[0][..., :3]).max()) + (0.0 if all(np.isfinite(q).all() for q in o) else 1.0), 1e-6)


def test_gains():
    """User Story 5: gain before the clamp; a plate never exceeds its ink colour; gain 0 empties a plate."""
    k = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]], dtype=F32)
    a = separate_stage(img([[0.4, 0, 0]]), k, gains=(2, 1, 1))
    check("gain 2 on coverage 0.4 gives 0.8", err(a[0][0, 0, 0], 0.8), 1e-3)
    b = separate_stage(img([[0.7, 0, 0]]), k, gains=(2, 1, 1))
    check("gain 2 on coverage 0.7 saturates at the ink colour", err(b[0][0, 0, 0], 1.0), 1e-3)
    c = separate_stage(img([[0.7, 0.7, 0]]), k, gains=(0, 1, 1))
    check("gain 0 empties plate 0", float(np.abs(c[0][..., :3]).max()), 1e-6)
    check("gain 0 leaves other plates", err(c[1][0, 0, 1], 0.7), 1e-3)


def test_preview_is_sum_of_plates():
    rng = np.random.default_rng(11)
    x = rng.uniform(0, 1.5, (64, 3)).astype(F32)
    out = separate_stage(img(x), SPOT, gains=(1.5, 1, 0.5))
    tot = np.clip(out[0][..., :3] + out[1][..., :3] + out[2][..., :3], 0, 1)
    check("preview equals clamped sum of plates", err(out[3][..., :3], tot), 1e-6)


def test_bypass_alpha_unconnected():
    """FR-001, FR-009, FR-012."""
    x = img([[0.2, 0.9, 0.4], [np.nan, 0.1, 0.1]])
    x[0, 0, 3] = 0.3
    byp = separate_stage(x, SPOT, bypass=1)
    zapped = np.where(np.isfinite(x), x, 0)
    check("bypass passes the (zapped) source on all four", max(err(o, zapped) for o in byp), 0)
    out = separate_stage(x, SPOT)
    check("alpha passes through on all four", max(err(o[0, 0, 3], 0.3) for o in out), 1e-7)
    none = separate_stage(None, SPOT)
    check("nothing connected: black and alpha 0 on all four", max(float(np.abs(o).max()) for o in none), 0)


def test_mutations():
    """Each plausible mistake changes the output the checks above look at."""
    k = np.array([[1, 0, 0], [0.8, 0, 0], [0, 0, 1]], dtype=F32)
    cases = {
        "no_clamp": (img([[2, 0, 0]]), RGB3, dict()),
        "gain_after_clamp": (img([[0.7, 0, 0]]), RGB3, dict(gains=(2, 1, 1))),
        "preview_no_clamp": (img([[1.6, 0, 0]]), k, dict()),
        "nearest_no_black": (img([[0.01, 0.01, 0.01]]), SPOT, dict(mode="nearest")),
        "skip_zap": (img([[np.nan, 0.5, 0.5]]), SPOT, dict()),
        "ignore_alpha": (img([[0.5, 0.5, 0.5]]) * np.array([1, 1, 1, 0.3], dtype=F32), SPOT, dict()),
        "pack_rgb": (img([[0.2, 0.8, 0.1]]), SPOT, dict()),
        "project_joint": (img([[0.3, 0.6, 0.7]]), SPOT, dict(mode="project")),
    }
    for bug, (src, pal, kw) in cases.items():
        a = separate_stage(src, pal, **kw)
        b = separate_stage(src, pal, bug=bug, **kw)
        e = max(float(np.nanmax(np.abs(x - y))) if np.isfinite(x - y).any() else 1.0 for x, y in zip(a, b))
        if not all(np.isfinite(y).all() for y in b):
            e = 1.0
        note(f"mutation '{bug}' worst error", e)
        check(f"mutation caught: {bug}", float(e <= 1e-3), 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
