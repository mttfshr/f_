"""
test_scatter_mirror.py -- tier 1 (NumPy only, offline) for the f_caustic sheets mode
(.specify/f_caustic_scatter/spec.md, Acceptance criteria 2; tasks T005, T006).

Checks the mirror of the scatter against invariants and against the independent photon-counting truth:
tent weights sum to 1; energy is conserved; with d = 0 and a fine lattice the image is the source; N points
sent to one pixel sum to N; agreement with the truth at 4 points per pixel (the spike measured r 0.9985 at 1 d*
and 0.9937 at 3.5 d*); the tone curve; the bilinear resize.

Run:  tests/run.sh tests/modules/caustic/test_scatter_mirror.py
"""
import sys

import numpy as np

import gpu_sim as g
import scatter_mirror as sm
import scatter_truth as st
from harness import check, note, run

F32 = np.float32


def test_tent_weights_sum_to_one():
    rng = np.random.default_rng(0)
    tx, ty = rng.random(20000), rng.random(20000)
    s = (1 - tx) * (1 - ty) + tx * (1 - ty) + (1 - tx) * ty + tx * ty
    check("max |sum of the four tent weights - 1|", np.abs(s - 1).max(), 1e-12)


def test_energy_conserved():
    """Every in-viewport point deposits its whole weight*source: the image sums to the in-viewport sum.
    (A point whose tent straddles the right/top edge loses the part that falls off the capture, which is why the
    tolerance is not tighter.)"""
    src, fld = sm.gradient_src(), sm.uniform_field(0.05, -0.03)
    n, r, d, w = 300, 256, 1.0, 0.7
    t = (np.arange(n, dtype=np.float64) / (n - 1)).astype(F32)
    U, V = np.meshgrid(t, t)
    X, Y = U + F32(0.05), V - F32(0.03)
    inside = (X >= 0) & (X <= 1) & (Y >= 0) & (Y <= 1)
    expect = (g.sample(src, U, V) * F32(w))[inside].sum(axis=0).astype(np.float64)
    got = sm.ref_scatter(src, fld, d, n, w, r=r).sum(axis=(0, 1)).astype(np.float64)
    rel = np.abs(got - expect)[:3].max() / expect[:3].max()
    note("energy: image sum / expected sum (R)", got[0] / expect[0])
    check("energy: |image sum - in-viewport sum| / sum", rel, 5e-3)


def test_identity_at_zero_distance():
    """d = 0 with a lattice 4x finer than the capture: the image is the source resampled at the capture's pixel
    centres (a smooth source, border pixels excluded)."""
    src, r, n = sm.gradient_src(), 256, 1024
    img = sm.ref_scatter(src, sm.uniform_field(0.0, 0.0), 0.0, n, (r / n) ** 2, r=r)
    nx, ny, _, _ = g.grid(r, r)
    expect = g.sample(src, nx, ny)
    m = slice(3, -3)
    err = np.abs(img[m, m, :3].astype(np.float64) - expect[m, m, :3].astype(np.float64)).max()
    check("identity at d = 0: max |image - source| (interior)", err, 3e-3)


def test_points_on_one_pixel():
    """64 x 64 = 4096 points, all sent to (0.5, 0.5): they sum to 4096 and sit within a 3 x 3 pixel block."""
    n, r = 64, 256
    img = sm.ref_scatter(sm.white(), sm.point_field(0.5, 0.5), 1.0, n, 1.0, r=r)
    total = float(img[..., 0].sum())
    c = r // 2
    block = float(img[c - 2:c + 2, c - 2:c + 2, 0].sum())
    note("sum of all points", total)
    check("N points on one pixel: |sum - N| / N", abs(total - n * n) / (n * n), 1e-3)
    check("share of the energy outside a 4 x 4 pixel block", 1.0 - block / total, 1e-3)


def test_truth_agreement_at_4_points_per_pixel():
    """The physical convention (no flips, fy = +1) against photon counting, n = 4 * capture, capture 256."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    r, n = 256, 1024
    w = (r / n) ** 2
    for frac, floor in ((1.0, 0.99), (3.5, 0.98)):
        d = frac * dstar
        a = sm.ref_scatter(sm.white(), tex, d, n, w, r=r)[..., 0].astype(np.float64)
        tr, mask = st.truth(d, m=2048), st.interior(d)
        rr = st.pearson(a[mask], tr[mask])
        note(f"r vs truth at {frac} d*", rr)
        check(f"1 - r vs truth at {frac} d* (spike measured {'0.9985' if frac == 1.0 else '0.9937'})",
              1.0 - rr, 1.0 - floor)


def test_tone_curve():
    check("tone(0) = 0", abs(float(sm.tone(0.0))), 1e-12)
    v = np.linspace(0, 200, 4001)
    t = sm.tone(v)
    check("monotone: largest decrease", max(0.0, float(-np.diff(t).min())), 1e-12)
    check("bounded below 1 for v = 200", max(0.0, float(t.max()) - 1.0), 0.0)
    check("closed form at v = 1: |tone - 0.5 ** 0.7|", abs(float(sm.tone(1.0)) - 0.5 ** 0.7), 1e-12)


def test_resize_matches_integer_upscale():
    rng = np.random.default_rng(1)
    a = rng.random((16, 16, 1))
    err = np.abs(sm.resize_bilinear(a, 64, 64)[..., 0] - sm.upscale(a[..., 0], 4)).max()
    check("resize_bilinear == upscale x4", err, 1e-12)
    c = np.full((8, 8, 4), 0.37)
    check("a constant stays constant", np.abs(sm.resize_bilinear(c, 30, 50) - 0.37).max(), 1e-12)


# --- edge mode (2026-10-17) --------------------------------------------

def test_edge_remap_matches_hand_tabulated_values():
    """Tabulated by hand, not through the function: wrap = fract, mirror = reflect with period 2, clamp = half a
    pixel inside the frame (so the whole splat stays in it), off = unchanged."""
    r = 100
    h = 0.5 / r
    x = np.array([-1.3, -0.25, 0.0, 0.4, 1.0, 1.25, 2.7], F32)
    expect = {0: list(x),
              1: [0.7, 0.75, 0.0, 0.4, 0.0, 0.25, 0.7],
              2: [0.7, 0.25, 0.0, 0.4, 1.0, 0.75, 0.7],
              3: [h, h, h, 0.4, 1 - h, 1 - h, 1 - h]}
    for e, want in expect.items():
        err = np.abs(sm.edge_remap(x, e, r) - np.array(want, F32)).max()
        check(f"edge {e}: remap vs hand-tabulated values (max abs)", float(err), 2e-6)


def test_edge_modes_keep_the_light_and_off_loses_it():
    """A uniform push of +0.4 sends the last 40% of the lattice out of the frame. Off loses their light; wrap,
    mirror and clamp keep it. (The first and last lattice rows sit exactly on the frame's top and bottom edges, so
    every mode loses about 0.3% to those half tents: the tolerance covers it.)"""
    n, r, w = 300, 256, 0.7
    fld, total = sm.uniform_field(1.0, 0.0), n * n * w
    share = {}
    for e in (0, 1, 2, 3):
        img = sm.ref_scatter(sm.white(), fld, 0.4, n, w, r=r, edge=e)
        share[e] = float(img[..., 0].sum()) / total
        note(f"edge {e}: image sum / lattice energy", share[e])
    check("off keeps about 60% of the light", abs(share[0] - 0.6), 0.02)
    for e, name in ((1, "wrap"), (2, "mirror"), (3, "clamp")):
        check(f"{name} loses (fraction of the light)", 1.0 - share[e], 0.02)


def test_edge_modes_put_the_light_where_they_say():
    """Same push. Off leaves the left 38% of the frame empty (nothing lands there). Wrap fills it with the 40% that
    left on the right. Mirror folds it back instead, doubling the density near the right edge. Clamp piles it onto
    the last pixel column."""
    n, r, w = 300, 256, 0.7
    fld, total = sm.uniform_field(1.0, 0.0), n * n * w
    img = {e: sm.ref_scatter(sm.white(), fld, 0.4, n, w, r=r, edge=e)[..., 0] for e in (0, 1, 2, 3)}
    left = lambda a: float(a[:, : int(0.38 * r)].sum()) / total
    near_right = lambda a: float(a[:, int(0.65 * r): int(0.95 * r)].mean())
    check("off: share of light in the left 38% of the frame", left(img[0]), 0.01)
    check("wrap: left 38% holds the light that left on the right (|share - 0.38|)", abs(left(img[1]) - 0.38), 0.02)
    check("mirror: left 38% stays empty", left(img[2]), 0.01)
    ratio = near_right(img[2]) / near_right(img[0])
    note("mirror / off density in the right strip", ratio)
    check("mirror doubles the density near the right edge (|ratio - 2|)", abs(ratio - 2.0), 0.1)
    check("clamp: left 38% stays empty", left(img[3]), 0.01)
    col = float(img[3][:, -1].sum()) / total
    note("clamp: share of all light in the last pixel column", col)
    check("clamp: the last column holds the 40% that left (|share - 0.4|)", abs(col - 0.4), 0.02)


if __name__ == "__main__":
    sys.exit(run(globals()))
