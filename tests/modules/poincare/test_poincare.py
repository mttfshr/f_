"""test_poincare.py -- tier-1 float64 mirror tests for f_poincare (spec: .specify/stable/f_poincare/spec.md, task T002).

Ground truth is independent of the mirror's own construction:

  - Hyperbolic trigonometry. The edge circle's hyperbolic distance from the origin is l = 2 atanh(d - rho)
    and must satisfy cosh(l) = cos(pi/q) / sin(pi/p) (the defining right triangle). The tile's vertex,
    found by intersecting the edge circle with the ray at pi/p, must sit at hyperbolic distance R with
    cosh(R) = cot(pi/p) cot(pi/q) (the same triangle's other leg). Neither uses the mirror's formula path.
  - Orthogonality to the unit circle: d^2 - rho^2 = 1. The q -> infinity limit is f_apollonian's ring,
    d = 1/cos(pi/p), rho = tan(pi/p). The {4,5} values are the scratch patch's hand-entered defaults.
  - Settled points obey the domain's own inequalities (outside every edge circle in mode A; inside the
    wedge [0, pi/p] and outside the +x edge circle in mode B).
  - The two modes must agree: for p = 4 (where their circle layouts coincide), folding mode A's settled
    point into the wedge must give mode B's settled point. The (2,p,q) triangle is a strict fundamental
    domain, so the representative is unique; this is a check neither mode can pass by sharing a bug.
  - Camera: zero camera is the identity, the translation sends a to 0, and rotation plus translation
    preserves the Poincare-disk distance acosh(1 + 2|u-v|^2 / ((1-|u|^2)(1-|v|^2))).
  - Inversion is an involution and fixes its own circle.
  - Mutations (a wrong r2, mode B's angle never mirrored, a camera denominator without the conjugate) must
    each be caught by at least one check; the real mirror must pass all of them.

Float64 only: GPU float32 behavior near the rim is task T032, and the mirror is parameterised later.
Tolerances are stated here and not loosened to pass.

Run:  tests/run.sh tests/modules/poincare/test_poincare.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import poincare_mirror as m  # noqa: E402

PAIRS = [(4, 5), (4, 6), (4, 7), (5, 4), (3, 7), (6, 4), (3, 8), (5, 5)]
rng = np.random.default_rng(20261106)


def disk_points(n, rmax):
    r = rmax * np.sqrt(rng.random(n))
    a = rng.random(n) * 2 * np.pi
    return r * np.cos(a), r * np.sin(a)


def hdist(u, v):
    """Poincare-disk distance between complex arrays."""
    return np.arccosh(1 + 2 * np.abs(u - v) ** 2 / ((1 - np.abs(u) ** 2) * (1 - np.abs(v) ** 2)))


# ---- error functions (each returns a measured error; `bug` selects a mutation) ----

def geom_err(bug=None):
    worst = 0.0
    for p, q in PAIRS:
        d, r2 = m.geometry(p, q, bug)
        s = d - np.sqrt(r2)
        cosh_l = (1 + s * s) / (1 - s * s)              # cosh(2 atanh s)
        want = np.cos(np.pi / q) / np.sin(np.pi / p)
        worst = max(worst, abs(cosh_l - want), abs(d * d - r2 - 1))
    return worst


def vertex_err(bug=None):
    worst = 0.0
    for p, q in PAIRS:
        d, r2 = m.geometry(p, q, bug)
        c = np.cos(np.pi / p)
        disc = d * d * c * c - (d * d - r2)             # r^2 - 2 d c r + (d^2 - r2) = 0
        r = d * c - np.sqrt(disc)
        big_r = 2 * np.arctanh(r)
        want = 1 / (np.tan(np.pi / p) * np.tan(np.pi / q))
        worst = max(worst, abs(np.cosh(big_r) - want))
    return worst


def settle_a_err(p=4, q=5, n=4000):
    zx, zy = disk_points(n, 0.85)
    ox, oy, ok, _ = m.fold_a(zx, zy, p, q, iters=40)
    d, r2 = m.geometry(p, q)
    th = np.pi / p
    viol = 0.0
    for i in range(p):
        cx, cy = d * np.sin(2 * i * th), d * np.cos(2 * i * th)
        viol = max(viol, np.max(np.where(ok, r2 - ((ox - cx) ** 2 + (oy - cy) ** 2), 0.0)))
    return max(viol, 0.0), ok.mean(), np.max(np.hypot(ox, oy))


def settle_b_err(p=4, q=5, n=4000, bug=None):
    zx, zy = disk_points(n, 0.85)
    ox, oy, ok, _ = m.fold_b(zx, zy, p, q, iters=40, bug=bug)
    d, r2 = m.geometry(p, q)
    a = np.arctan2(oy, ox)
    ang = max(np.max(np.where(ok, -a, 0.0)), np.max(np.where(ok, a - np.pi / p, 0.0)), 0.0)
    circ = np.max(np.where(ok, r2 - ((ox - d) ** 2 + oy ** 2), 0.0))
    return max(ang, circ, 0.0), ok.mean()


def cross_err(p, q, n=6000):
    zx, zy = disk_points(n, 0.8)
    ax, ay, oka, _ = m.fold_a(zx, zy, p, q, iters=40)
    bx, by, okb, _ = m.fold_b(zx, zy, p, q, iters=40)
    wx, wy = m.wedge(ax, ay, p)
    both = oka & okb
    return float(np.max(np.where(both, np.hypot(wx - bx, wy - by), 0.0))), float(both.mean())


def camera_err(bug=None):
    zx, zy = disk_points(500, 0.9)
    u = zx + 1j * zy
    ident = np.max(np.abs(np.array(m.camera(zx, zy, 0.0, 0.0, 0.0)) - np.array([zx, zy])))
    ax, ay = 0.31, -0.22
    cx, cy = m.camera(np.array([ax]), np.array([ay]), ax, ay, 0.0, bug)
    to_zero = float(np.hypot(cx[0], cy[0]))
    wx, wy = m.camera(zx, zy, ax, ay, 0.7, bug)
    w = wx + 1j * wy
    in_disk = float(max(np.max(np.abs(w)) - 1.0, 0.0))
    i, j = np.arange(250), np.arange(250, 500)
    iso = float(np.max(np.abs(hdist(w[i], w[j]) - hdist(u[i], u[j]))))
    return max(ident, to_zero, in_disk, iso)


# ---- the tests ----

def test_geometry_closed_forms():
    e = geom_err()
    check("edge-circle distance and orthogonality, 8 pairs", e, 1e-12)
    d, r2 = m.geometry(4, 5)
    check("{4,5} d vs the scratch patch default", abs(d - 2.0581710272714915), 1e-12)
    check("{4,5} r2 vs the scratch patch default", abs(r2 - 3.2360679774997867), 1e-12)
    d, r2 = m.geometry(4, 10 ** 9)
    p = 4
    check("q -> inf: d vs 1/cos(pi/p)", abs(d - 1 / np.cos(np.pi / p)), 1e-6)
    check("q -> inf: rho vs tan(pi/p)", abs(np.sqrt(r2) - np.tan(np.pi / p)), 1e-6)


def test_vertex_distance():
    check("tile vertex at cosh R = cot(pi/p) cot(pi/q), 8 pairs", vertex_err(), 1e-9)


def test_validity_guard():
    for p, q in [(4, 4), (3, 6), (5, 3), (3, 3)]:
        try:
            m.geometry(p, q)
        except ValueError:
            continue
        raise AssertionError(f"{{{p},{q}}} should be rejected")
    m.geometry(3, 7)
    m.geometry(4, 5)
    print("    ok   {4,4}, {3,6}, {5,3}, {3,3} rejected; {3,7}, {4,5} accepted (1/p + 1/q < 1/2)")


def test_inversion_involution_and_fixed_circle():
    d, r2 = m.geometry(4, 5)
    zx, zy = rng.random(200) * 2 - 1, rng.random(200) * 2 - 1
    x1, y1 = m.invert(zx, zy, d, 0.0, r2)
    x2, y2 = m.invert(x1, y1, d, 0.0, r2)
    check("inversion twice returns the point", np.max(np.hypot(x2 - zx, y2 - zy)), 1e-9)
    a = rng.random(100) * 2 * np.pi
    cx, cy = d + np.sqrt(r2) * np.cos(a), np.sqrt(r2) * np.sin(a)
    fx, fy = m.invert(cx, cy, d, 0.0, r2)
    check("points on the circle are fixed (seam continuity)", np.max(np.hypot(fx - cx, fy - cy)), 1e-9)


def test_mode_a_settles_into_the_tile():
    viol, frac, rmax = settle_a_err()
    note("fraction settled at 40 iterations, r < 0.85, {4,5}", frac)
    check("settled points lie outside all 4 edge circles", viol, 1e-12)
    assert frac > 0.9, f"most points below r=0.85 should settle by 40 iterations: {frac}"
    assert rmax < 1.0, "inversion must keep points in the disk"
    print("    ok   settled fraction > 0.9, output stays inside the unit disk")


def test_mode_b_settles_into_the_triangle():
    for p, q in [(4, 5), (5, 4), (3, 7)]:
        err, frac = settle_b_err(p, q)
        note(f"{{{p},{q}}} fraction settled", frac)
        check(f"{{{p},{q}}} settled points inside the wedge and outside the edge circle", err, 1e-12)
        assert frac > 0.9, f"{{{p},{q}}} settled fraction {frac}"
    print("    ok   settled fraction > 0.9 at {4,5}, {5,4}, {3,7}")


def test_modes_agree_at_p4():
    for q in (5, 6, 7):
        err, frac = cross_err(4, q)
        note(f"{{4,{q}}} fraction both settled", frac)
        check(f"{{4,{q}}} wedge(mode A) equals mode B", err, 1e-7)
        assert frac > 0.85, f"too few comparable points: {frac}"


def test_mode_a_priority_order_is_part_of_the_definition():
    """Measured, then pinned: lowest-index-wins and highest-index-wins settle to DIFFERENT points, because the
    tile is not a strict fundamental domain of the edge-reflection group (at {4,5} the vertex angle is 2pi/5, not
    pi/n, so the group contains the tile's own symmetries; reason inferred). The scratch patch's order (lowest wins)
    is therefore part of mode A's definition, and the mirror reproduces it."""
    zx, zy = disk_points(3000, 0.8)
    ax, ay, oka, _ = m.fold_a(zx, zy, 4, 5, iters=40)
    bx, by, okb, _ = m.fold_a(zx, zy, 4, 5, iters=40, bug="a_highest_wins")
    both = oka & okb
    diff = np.where(both, np.hypot(ax - bx, ay - by), 0.0)
    note("both orders settled", float(both.mean()))
    note("fraction of points where the two orders disagree by > 0.01", float((diff > 0.01).mean()))
    assert (diff > 0.01).mean() > 0.05, "expected the order to matter; if it no longer does, the spec note can go"
    # the two orders still agree once folded into the wedge (same orbit, same triangle representative)
    wa = m.wedge(ax, ay, 4)
    wb = m.wedge(bx, by, 4)
    check("wedge(lowest-wins) vs wedge(highest-wins)", np.max(np.where(both, np.hypot(wa[0] - wb[0], wa[1] - wb[1]), 0.0)), 1e-7)


def seam_jumps(fold, p, q, n=100000, eps=2e-3, thresh=0.05):
    """Fraction of nearby point pairs (separation eps) whose settled positions differ by more than thresh.
    A continuous fold gives ~eps * local scale (a few 1e-3 here); a seam gives an O(1) jump."""
    zx, zy = disk_points(n, 0.6)
    b = rng.random(n) * 2 * np.pi
    s1 = fold(zx, zy, p, q, iters=60)
    s2 = fold(zx + eps * np.cos(b), zy + eps * np.sin(b), p, q, iters=60)
    ok = s1[2] & s2[2]
    dd = np.hypot(s1[0] - s2[0], s1[1] - s2[1])[ok]
    return float((dd > thresh).sum()), float(np.median(dd)), int(ok.sum())


def test_no_seams():
    for name, fold, pairs in (("A", m.fold_a, [(4, 5), (4, 6)]),
                              ("B", m.fold_b, [(4, 5), (5, 4), (3, 7)])):
        for p, q in pairs:
            jumps, med, n_ok = seam_jumps(fold, p, q)
            note(f"mode {name} {{{p},{q}}} median pair difference", med)
            check(f"mode {name} {{{p},{q}}} pairs with a jump > 0.05 (of {n_ok})", jumps, 0)


def test_camera_is_an_isometry():
    check("camera: identity at zero, a -> 0, disk preserved, hyperbolic distance preserved", camera_err(), 1e-9)


def test_mutations_are_caught():
    real = [geom_err(), vertex_err(), settle_b_err()[0], camera_err()]
    bad = {"r2_is_rho": max(geom_err("r2_is_rho"), vertex_err("r2_is_rho")),
           "b_no_reflect": settle_b_err(bug="b_no_reflect")[0],
           "cam_conj_dropped": camera_err("cam_conj_dropped")}
    for name, v in bad.items():
        note(f"mutation '{name}' worst error", v)
        if not (v > 1e-6 or np.isnan(v)):    # NaN counts as detected (the mutant left the disk)
            raise AssertionError(f"mutation not detected: {name} (error {v:.3e})")
    assert max(real) < 1e-9, f"the real mirror must pass the same checks: {max(real):.3e}"
    print("    ok   a wrong r2, an unmirrored mode-B angle and a conjugate-free camera are each caught")


# ---- mode A as the codebox runs it (T010): the 3-nearest-circles variant, the guard, float32 ----

def test_k3_matches_the_chain():
    """T005's result pinned: the 3 nearest circles by angle give the p-circle chain's settled point on every pixel both settle."""
    ry, rx = np.mgrid[0:160, 0:160]
    zx, zy = (rx + 0.5) / 160 * 2 - 1, (ry + 0.5) / 160 * 2 - 1
    sel = zx ** 2 + zy ** 2 < 0.998 ** 2
    zx, zy = zx[sel], zy[sel]
    for p, q in [(4, 5), (4, 6), (5, 4), (6, 4), (8, 3), (3, 7), (10, 3)]:
        rx_, ry_, rok, _ = m.fold_a(zx, zy, p, q, iters=40)
        kx, ky, kok = m.fold_a_k3(zx, zy, p, q, iters=40)
        both = rok & kok
        note(f"{{{p},{q}}} both settled", float(both.mean()))
        check(f"{{{p},{q}}} k3 settled position equals the chain", float(np.max(np.where(both, np.hypot(kx - rx_, ky - ry_), 0.0))), 1e-9)
        assert both.mean() > 0.99, f"{{{p},{q}}} too few pixels settled by 40 iterations: {both.mean()}"


def test_guard_rounds_and_clamps():
    assert m.clamp_pq(4, 3) == (4, 5) and m.clamp_pq(4.4, 5.4) == (4, 5)
    assert m.clamp_pq(2, 7) == (3, 7) and m.clamp_pq(3, 3) == (3, 7)
    assert m.clamp_pq(5, 3) == (5, 4) and m.clamp_pq(8, 2) == (8, 3) and m.clamp_pq(11, 3) == (10, 3)
    for p in range(3, 11):                       # every guarded pair is hyperbolic
        for q in (1, 3, 5, 12):
            assert m.valid(*m.clamp_pq(p, q)), (p, q)
    print("    ok   p rounded and clamped to 3..10, q raised to the smallest hyperbolic integer")


def test_render_a_float32_tracks_float64_and_the_disk_is_empty():
    nx, ny = m.norm_grid(192, 192)
    a, _, rr = m.render_a(nx, ny, 4, 5, 0.26)
    b, _, _ = m.render_a(nx, ny, 4, 5, 0.26, dt=np.float32)
    dif = np.abs(a - b.astype(np.float64)).max(-1)
    note("float32 vs float64, worst at r < 0.9", float(dif[rr < 0.9].max()))
    check("float32 render equals float64 to 1e-4 at r < 0.9", float(dif[rr < 0.9].max()), 1e-4)
    check("outside the unit disk is exactly black", float(np.abs(a[rr >= 1.0]).max()), 0.0)
    assert (a[rr < 0.5].sum(-1) > 0).mean() > 0.5, "the central region should show the texture"


# ---- mode B as the codebox runs it, and the combined codebox's size (T020, T021) ----

def test_mode_b_coded_matches_the_settled_domain_and_float32():
    """fold_b_k is mode B with the codebox's atan2 bias and (a + 2 pi) mod sector fold: its settled points obey the
    domain's inequalities, it matches the unbiased fold_b where both settle (the bias moves the angle by ~1e-7 / r, amplified
    by the fold), and float32 equals float64 away from the rim."""
    ry, rx = np.mgrid[0:200, 0:200]
    zx, zy = (rx + 0.5) / 200 * 2 - 1, (ry + 0.5) / 200 * 2 - 1
    sel = zx ** 2 + zy ** 2 < 0.998 ** 2
    zx, zy = zx[sel], zy[sel]
    for p, q in [(4, 5), (5, 4), (3, 7), (6, 4), (8, 3)]:
        ax, ay, aok, _ = m.fold_b(zx, zy, p, q, iters=40)
        bx, by, bok = m.fold_b_k(zx, zy, p, q, iters=40)
        both = aok & bok
        check(f"{{{p},{q}}} coded mode B equals fold_b where both settle", float(np.max(np.where(both, np.hypot(ax - bx, ay - by), 0.0))), 1e-3)
        d, r2 = m.geometry(p, q)
        a = np.arctan2(by, bx)
        viol = max(float(np.max(np.where(bok, -a, 0.0))), float(np.max(np.where(bok, a - np.pi / p, 0.0))), 0.0)
        check(f"{{{p},{q}}} settled points inside the wedge", viol, 1e-6)
        circ = float(np.max(np.where(bok, r2 - ((bx - d) ** 2 + by ** 2), 0.0)))
        check(f"{{{p},{q}}} settled points outside the circle up to SETTLE_TOL", circ, m.SETTLE_TOL * 1.01)
    nx, ny = m.norm_grid(160, 160)
    for p, q, ts in [(4, 5, 0.4), (5, 4, 0.4), (3, 7, 0.3)]:
        a, _, rr = m.render(nx, ny, 1, p, q, ts)
        b, _, _ = m.render(nx, ny, 1, p, q, ts, dt=np.float32)
        dif = np.abs(a - b.astype(np.float64)).max(-1)
        check(f"B {{{p},{q}}} float32 render equals float64 at r < 0.9 (fraction of pixels off by > 1e-3)", float((dif[rr < 0.9] > 1e-3).mean()), 0.0)


def test_settle_tolerance_covers_the_mirror_line_knife_edge():
    """Found 2026-11-06: at p = 4 on a square frame the pixel diagonal is a mirror line of the group, so those pixels land
    exactly on the edge circle; strict `>= r2` called them unsettled in float64 and settled in float32. With SETTLE_TOL they settle in both."""
    nx, ny = m.norm_grid(128, 128)
    _, s64, rr = m.render(nx, ny, 1, 4, 5, 0.4)
    _, s32, _ = m.render(nx, ny, 1, 4, 5, 0.4, dt=np.float32)
    sel = rr < 0.9
    note("B {4,5} fraction settled, r < 0.9: float64 / float32", (float(s64[sel].mean()), float(s32[sel].mean())))
    assert s64[sel].all() and s32[sel].all(), "every pixel below r = 0.9 settles in both precisions"
    _, a64, _ = m.render(nx, ny, 0, 4, 5, 0.26)
    assert a64[sel].all(), "mode A as well"


def test_combined_codebox_fits_the_parser_budget():
    """T021: one codebox for both modes. The parser budget is about 250 statements per function body or top level and about
    450 for the whole program (jit-gen-codebox, 2026-10-06). A statement is counted here as one terminating semicolon, the two
    inside a `for (...)` header excluded: a rough upper bound on the real count."""
    import re
    from pathlib import Path
    code = (Path(__file__).resolve().parents[3] / "src" / "f_poincare" / "codebox_poincare.gen").read_text()
    body = "\n".join(l for l in code.splitlines() if not l.strip().startswith("//"))
    total = body.count(";") - 2 * len(re.findall(r"\bfor\s*\(", body))
    top = re.sub(r"\w+\([^)]*\)\s*\{[^}]*\}", "", body)         # functions removed
    top_n = top.count(";") - 2 * len(re.findall(r"\bfor\s*\(", top))
    note("statements (semicolons), whole program / top level", (total, top_n))
    assert total < 300 and top_n < 150, (total, top_n)
    assert re.search(r"\bfold_mode\b", body) and "fold_step_b" in body


# ---- the camera as the codebox runs it (T030, T031) ----

def _screen(n, dt, aspect=1.0):
    nx, ny = m.norm_grid(n, int(n * aspect), dt)
    ax, ay = dt(max(aspect, 1.0)), dt(max(1.0 / aspect, 1.0))
    zx, zy = (nx * dt(2) - dt(1)) * ax, (ny * dt(2) - dt(1)) * ay
    return nx, ny, zx, zy, np.sqrt(zx * zx + zy * zy)


def test_zero_camera_is_bit_exact_with_static():
    """T030: cam_x = cam_y = rot = 0 returns the screen point itself (not merely close), in both precisions, and the whole
    render equals the render without camera arguments, in both modes, for every pixel."""
    for dt in (np.float64, np.float32):
        nx, ny, zx, zy, rr = _screen(257, dt)
        wx, wy = m.camera_dt(zx, zy, rr, 0.0, 0.0, 0.0, dt)
        inside = rr < 0.9999
        assert np.array_equal(wx[inside], zx[inside]) and np.array_equal(wy[inside], zy[inside]), dt
        for mode in (0, 1):
            a, _, _ = m.render(nx, ny, mode, 4, 5, 0.26, 32, 0.99, 1.0, dt)
            b, _, _ = m.render(nx, ny, mode, 4, 5, 0.26, 32, 0.99, 1.0, dt, cam_x=0.0, cam_y=0.0, rot=0.0)
            assert np.array_equal(a, b), (dt, mode)
    print("    ok   zero camera: identical points (r < 0.9999) and identical frames, modes A and B, float64 and float32")


def test_camera_dt_matches_the_complex_camera():
    zx, zy = disk_points(400, 0.95)
    rr = np.hypot(zx, zy)
    for ax, ay, rot in ((0.31, -0.22, 0.7), (0.0, 0.0, 1.3), (-0.5, 0.4, -2.0)):
        want = np.array(m.camera(zx, zy, ax, ay, rot))
        got = np.array(m.camera_dt(zx, zy, rr, ax, ay, rot, np.float64))
        check(f"camera_dt equals the complex camera, a=({ax},{ay}) rot={rot}", float(np.max(np.abs(got - want))), 1e-12)


def test_camera_clamp_and_no_nan_at_the_rim():
    """T031: |a| pushed far past 1 is clamped to 0.99; the whole frame, corner pixels outside the disk included, is finite
    in both modes and both precisions, and outside the disk stays exactly black."""
    for dt in (np.float64, np.float32):
        for aspect in (1.0, 16 / 9):
            nx, ny, zx, zy, rr = _screen(180, dt, aspect)
            for cx, cy in ((5.0, 0.0), (0.0, -3.0), (0.7, 0.7), (0.99, 0.0), (-0.99, 0.0)):
                for mode in (0, 1):
                    img, _, rr2 = m.render(nx, ny, mode, 3 + 2 * mode, 7, 0.3, 32, 0.99, aspect, dt, cam_x=cx, cam_y=cy, rot=0.4)
                    assert np.isfinite(img).all(), (dt, aspect, cx, cy, mode)
                    assert (img[rr2 >= 1.0] == 0).all()
    zx, zy = np.array([0.5]), np.array([0.0])
    w = m.camera_dt(zx, zy, np.abs(zx), 5.0, 0.0, 0.0, np.float64)
    ref = m.camera(zx, zy, 0.99, 0.0, 0.0)
    check("|a| = 5 behaves as |a| = 0.99", abs(w[0][0] - ref[0][0]), 1e-12)
    print("    ok   camera at and past the clamp: finite everywhere (corners too), black outside the disk")


def test_rim_fade_start_tracks_the_float32_drift():
    """T032: with the camera, float32 leaves float64 near the rim sooner; the fade start moves in by 0.04 (|a|/0.99)^2.
    Where the fade has not yet begun (r < start) float32 and float64 colours differ by more than 4e-3 on at most 0.2% of pixels,
    at the four pairs and |a| = 0.5, 0.9, 0.99 (measured offline 2026-11-06, scratch/t032_rim.py, 512 grid)."""
    check("fade start at zero camera is rim_fade", float(m.rim_start(0.99, 0.0, 0.0)), 0.99 - 0.0)
    check("fade start at |a| = 0.99 is 0.95", abs(float(m.rim_start(0.99, 0.99, 0.0)) - 0.95), 1e-12)
    check("fade start at |a| = 5 (clamped) is 0.95", abs(float(m.rim_start(0.99, 5.0, 0.0)) - 0.95), 1e-12)
    n = 512
    worst = 0.0
    for cam in (0.5, 0.9, 0.99):
        for mode, p, q, ts in ((0, 4, 5, 0.26), (0, 4, 6, 0.3178), (1, 5, 4, 0.4), (1, 3, 7, 0.3)):
            img = {}
            for dt in (np.float64, np.float32):
                nx, ny = m.norm_grid(n, n, dt)
                img[dt], _, rr = m.render(nx, ny, mode, p, q, ts, 32, 0.99, 1.0, dt, cam_x=cam, cam_y=0.0, rot=0.3)
            sel = rr < float(m.rim_start(0.99, cam, 0.0))
            bad = (np.abs(img[np.float32].astype(np.float64) - img[np.float64]).max(-1) > 4e-3)[sel].mean()
            worst = max(worst, float(bad))
    note("worst fraction of pixels (r < fade start) with a float32 colour error > 4e-3", worst)
    assert worst <= 0.002, worst


if __name__ == "__main__":
    sys.exit(run(globals()))
