"""poincare_mirror.py -- tier-1 NumPy mirror of the f_poincare folds (spec: .specify/f_poincare/spec.md).

Float64 first (the float32 pass-for-pass mirror comes after the float64 one is trusted; every function
takes `dt` so the same code runs at either precision). Pure functions on coordinate arrays, no texture
sampling: the module's output is "sample the input at the settled position", so the position is what
is tested.

Geometry (spec "Geometry", derived and hand-checked in plan.md Phase 3 Step 3):

    cosh(l) = cos(pi/q) / sin(pi/p)          valid iff 1/p + 1/q < 1/2
    t = sqrt((cosh(l) - 1) / (cosh(l) + 1));  d = (t + 1/t) / 2;  rho = (1/t - t) / 2;  r2 = rho^2

Mode A (whole tile): p edge circles, centre i = (d sin(2 i th), d cos(2 i th)), th = pi/p (the scratch
patch's layout, angle measured from +y). Each iteration finds the circles containing the point, takes
the LOWEST index (the scratch patch's nested mix() gives ins0 the top priority), inverts once in it.
Mode B (sliver): reflect the angle into [0, pi/p], then invert in the single circle on the +x axis if
the point is inside it; repeat. The two modes use different edge-circle orientations for general p
(A from +y, B on +x); at p = 4 they coincide.

Camera: rotate by `rot`, then the disk translation z -> (z - a) / (1 - conj(a) z), |a| clamped to A_MAX.

`bug` values are the mutations the tests must catch: "r2_is_rho" (r2 = rho instead of rho^2),
"b_no_reflect" (mode B wraps the angle but never mirrors it), "a_highest_wins" (mode A priority
reversed -- NOT expected to change the settled point; the test records that it is order-independent),
"cam_conj_dropped" (the camera denominator loses its conj).
"""
import numpy as np

A_MAX = 0.99            # camera |a| clamp; spec says "below 1", the value is open (tasks T030)
INV_FLOOR = 1e-4        # the scratch patch's floor on |z - c|^2


def valid(p, q):
    return 1.0 / p + 1.0 / q < 0.5


def geometry(p, q, bug=None):
    """(d, r2). Raises ValueError outside 1/p + 1/q < 1/2 (the module's guard is a later task)."""
    if not valid(p, q):
        raise ValueError(f"{{{p},{q}}} is not hyperbolic")
    ch = np.cos(np.pi / q) / np.sin(np.pi / p)
    t = np.sqrt((ch - 1.0) / (ch + 1.0))
    d = (t + 1.0 / t) / 2.0
    rho = (1.0 / t - t) / 2.0
    return d, (rho if bug == "r2_is_rho" else rho * rho)


def invert(zx, zy, cx, cy, r2):
    dx, dy = zx - cx, zy - cy
    p2 = np.maximum(dx * dx + dy * dy, INV_FLOOR)
    return dx * (r2 / p2) + cx, dy * (r2 / p2) + cy


def camera(zx, zy, ax=0.0, ay=0.0, rot=0.0, bug=None):
    """Rotation by rot, then the disk translation by a = (ax, ay), |a| clamped to A_MAX."""
    z = (zx + 1j * zy) * np.exp(1j * rot)
    a = complex(ax, ay)
    if abs(a) > A_MAX:
        a = a / abs(a) * A_MAX
    den = (1 - (a.conjugate() if bug != "cam_conj_dropped" else a) * z)
    w = (z - a) / den
    return w.real, w.imag


def fold_a(zx, zy, p, q, iters=24, bug=None):
    """Mode A. Returns (zx, zy, settled, depth); settled = outside every edge circle after the last iteration."""
    d, r2 = geometry(p, q)
    th = np.pi / p
    cs = [(d * np.sin(2 * i * th), d * np.cos(2 * i * th)) for i in range(p)]
    zx, zy = np.array(zx, float), np.array(zy, float)
    depth = np.zeros_like(zx)
    order = range(p - 1, -1, -1) if bug == "a_highest_wins" else range(p)

    def winner(zx, zy):
        win = np.full(zx.shape, -1)
        # iterate so the FIRST circle in `order` ends up the winner (last write wins, so write in reverse)
        for i in reversed(list(order)):
            cx, cy = cs[i]
            win = np.where((zx - cx) ** 2 + (zy - cy) ** 2 < r2, i, win)
        return win

    for _ in range(iters):
        win = winner(zx, zy)
        for i, (cx, cy) in enumerate(cs):
            m = win == i
            nx, ny = invert(zx, zy, cx, cy, r2)
            zx, zy = np.where(m, nx, zx), np.where(m, ny, zy)
        depth = depth + (win >= 0)
    settled = winner(zx, zy) < 0
    return zx, zy, settled, depth


def wedge(zx, zy, p, bug=None):
    """Reflect the angle into [0, pi/p] about the origin (|z| unchanged)."""
    sector = 2 * np.pi / p
    rr = np.hypot(zx, zy)
    a = np.mod(np.arctan2(zy, zx), sector)
    if bug != "b_no_reflect":
        a = np.minimum(a, sector - a)
    return rr * np.cos(a), rr * np.sin(a)


def fold_b(zx, zy, p, q, iters=24, bug=None):
    """Mode B. Returns (zx, zy, settled, depth); settled = inside the wedge (always) and outside the edge circle."""
    d, r2 = geometry(p, q)
    zx, zy = np.array(zx, float), np.array(zy, float)
    depth = np.zeros_like(zx)
    for _ in range(iters):
        zx, zy = wedge(zx, zy, p, bug)
        inside = (zx - d) ** 2 + zy ** 2 < r2
        nx, ny = invert(zx, zy, d, 0.0, r2)
        zx, zy = np.where(inside, nx, zx), np.where(inside, ny, zy)
        depth = depth + inside
    zx, zy = wedge(zx, zy, p, bug)
    settled = (zx - d) ** 2 + zy ** 2 >= r2
    return zx, zy, settled, depth


def grid(n):
    """n x n pixel-centre grid over [-1, 1]^2, y up (the module's snorm)."""
    y, x = np.mgrid[0:n, 0:n]
    return (x + 0.5) / n * 2 - 1, 1 - (y + 0.5) / n * 2
