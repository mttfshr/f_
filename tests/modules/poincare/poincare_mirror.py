"""poincare_mirror.py -- tier-1 NumPy mirror of the f_poincare folds (spec: .specify/stable/f_poincare/spec.md).

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


# ---------------------------------------------------------------------------------------------------------
# Mode A as the codebox runs it (T010, src/f_poincare/codebox_poincare.gen): live p by testing only the 3 nearest
# circles by angle (T005: matches the p-circle chain on every pixel both settle, 56 pairs p, q in 3..10). Written so
# the same code runs at float32 (`dt`): every constant and intermediate is cast, as the GPU computes in float32.
# ---------------------------------------------------------------------------------------------------------

P_MIN, P_MAX = 3, 10        # the codebox clamps the rounded `p_sides` here (mirror sweep covers 3..10)
SEAM_BIAS = 1e-7            # added to the atan2 y-argument so (0, 0) never reaches atan2 (skills/jit-gen-codebox)
SETTLE_TOL = 1e-5           # a final point within this of an edge circle's boundary (squared-distance units) counts as settled:
                            # a pixel on a mirror line of the group lands exactly on the circle (knife-edge; 2026-11-06, mode B p=4)
BIG_KEY = 1000.0            # sentinel index added to a circle the point is not inside


def clamp_pq(p, q):
    """The codebox's guard: p rounded and clamped to [P_MIN, P_MAX]; q rounded and raised to the smallest integer
    with 1/p + 1/q < 1/2 (qmin = floor(2p / (p - 2)) + 1: {3,7} {4,5} {5,4} {6,4} {7,4} {8,3}...)."""
    pr = min(max(int(np.floor(p + 0.5)), P_MIN), P_MAX)
    qmin = int(np.floor(2.0 * pr / (pr - 2.0))) + 1
    return pr, max(int(np.floor(q + 0.5)), qmin)


def geometry_dt(pr, qr, dt):
    ch = np.cos(dt(np.pi) / dt(qr)) / np.sin(dt(np.pi) / dt(pr))
    tt = np.sqrt((ch - dt(1)) / (ch + dt(1)))
    d = (tt + dt(1) / tt) / dt(2)
    rho = (dt(1) / tt - tt) / dt(2)
    return d, rho * rho


def _inside(zx, zy, idx, d, th, r2, dt):
    ang = dt(2) * idx * th
    dx = zx - d * np.sin(ang)
    dy = zy - d * np.cos(ang)
    return (dx * dx + dy * dy < r2).astype(dt)


def fold_step_k3(zx, zy, pr, d, th, r2, dt):
    p = dt(pr)
    i0 = np.floor(np.arctan2(zx, zy + dt(SEAM_BIAS)) / (dt(2) * th) + dt(0.5))
    off = dt(2) * p + i0
    ia, ib, ic = np.mod(off, p), np.mod(off - dt(1), p), np.mod(off + dt(1), p)
    fa, fb, fc = (_inside(zx, zy, i, d, th, r2, dt) for i in (ia, ib, ic))
    big = dt(BIG_KEY)
    w = np.minimum(ia + (dt(1) - fa) * big, np.minimum(ib + (dt(1) - fb) * big, ic + (dt(1) - fc) * big))
    has = dt(1) - (w >= dt(500)).astype(dt)
    ang = dt(2) * w * th
    cx, cy = d * np.sin(ang), d * np.cos(ang)
    dx, dy = zx - cx, zy - cy
    s = r2 / np.maximum(dx * dx + dy * dy, dt(INV_FLOOR))
    nx, ny = cx + dx * s, cy + dy * s
    return zx + (nx - zx) * has, zy + (ny - zy) * has


def fold_a_k3(zx, zy, p, q, iters=32, dt=np.float64):
    """Returns (zx, zy, settled) after `iters` steps; settled = inside none of the 3 nearest circles at the end."""
    pr, qr = clamp_pq(p, q)
    d, r2 = geometry_dt(pr, qr, dt)
    th = dt(np.pi) / dt(pr)
    zx, zy = np.asarray(zx, dt).copy(), np.asarray(zy, dt).copy()
    for _ in range(int(iters)):
        zx, zy = fold_step_k3(zx, zy, pr, d, th, r2, dt)
    p_ = dt(pr)
    i0 = np.floor(np.arctan2(zx, zy + dt(SEAM_BIAS)) / (dt(2) * th) + dt(0.5))
    off = dt(2) * p_ + i0
    r2t = r2 - dt(SETTLE_TOL)
    hit = np.maximum(_inside(zx, zy, np.mod(off, p_), d, th, r2t, dt),
                     np.maximum(_inside(zx, zy, np.mod(off - dt(1), p_), d, th, r2t, dt),
                                _inside(zx, zy, np.mod(off + dt(1), p_), d, th, r2t, dt)))
    return zx, zy, hit == 0


def _smoothstep(e0, e1, x, dt):
    t = np.clip((x - e0) / (e1 - e0), dt(0), dt(1))
    return t * t * (dt(3) - dt(2) * t)


def render_a(nx, ny, p=4, q=5, tile_scale=0.26, iters=32, rim_fade=0.99, aspect=1.0, dt=np.float64):
    """The codebox's whole pipeline for the ramp test texture (R = u, G = v, B = u v, A = 1), no camera.
    nx, ny are `norm` (texel centres, row 0 smallest). Returns (rgb, settled, screen radius)."""
    nx, ny = np.asarray(nx, dt), np.asarray(ny, dt)
    asp_x, asp_y = dt(max(aspect, 1.0)), dt(max(1.0 / aspect, 1.0))
    zx, zy = (nx * dt(2) - dt(1)) * asp_x, (ny * dt(2) - dt(1)) * asp_y
    rr = np.sqrt(zx * zx + zy * zy)
    sx, sy, settled = fold_a_k3(zx, zy, p, q, iters, dt)
    u = sx / (dt(2) * dt(tile_scale)) + dt(0.5)
    v = sy / (dt(2) * dt(tile_scale)) + dt(0.5)
    inb = (u >= 0) * (u < 1) * (v >= 0) * (v < 1)
    uc, vc = np.clip(u, dt(0.001), dt(0.999)), np.clip(v, dt(0.001), dt(0.999))
    fade = settled.astype(dt) * inb * (rr < 1) * (dt(1) - _smoothstep(dt(rim_fade), dt(1), rr, dt))
    rgb = np.stack([uc * fade, vc * fade, uc * vc * fade], -1)
    return rgb, settled, rr


def norm_grid(h, w, dt=np.float64):
    """`norm` per pixel as the bench reads it: texel centres, row 0 where norm.y is smallest."""
    ry, rx = np.mgrid[0:h, 0:w]
    return (rx + dt(0.5)) / dt(w), (ry + dt(0.5)) / dt(h)


# ---------------------------------------------------------------------------------------------------------
# Mode B as the codebox runs it (T020): angle fold into [0, pi/p] (about the origin), then one inversion in the edge circle
# on the +x axis, repeated; one more fold after the loop. The same guard as mode A (clamp_pq). `fold_mode` 0 = A, 1 = B.
# ---------------------------------------------------------------------------------------------------------

def wedge_dt(zx, zy, pr, dt):
    """The codebox's fold: angle from atan2(y, x + bias), taken as (a + 2 pi) mod (2 pi / p), mirrored about the half sector."""
    sector = dt(2) * dt(np.pi) / dt(pr)
    rr = np.sqrt(zx * zx + zy * zy)
    a = np.arctan2(zy, zx + dt(SEAM_BIAS))
    am = np.mod(a + dt(2) * dt(np.pi), sector)
    am = np.minimum(am, sector - am)
    return rr * np.cos(am), rr * np.sin(am)


def fold_b_k(zx, zy, p, q, iters=32, dt=np.float64):
    """Mode B as coded. Returns (zx, zy, settled); settled = outside the edge circle after the final fold."""
    pr, qr = clamp_pq(p, q)
    d, r2 = geometry_dt(pr, qr, dt)
    zx, zy = np.asarray(zx, dt).copy(), np.asarray(zy, dt).copy()
    for _ in range(int(iters)):
        zx, zy = wedge_dt(zx, zy, pr, dt)
        dx, dy = zx - d, zy
        inside = (dx * dx + dy * dy < r2).astype(dt)
        s = r2 / np.maximum(dx * dx + dy * dy, dt(INV_FLOOR))
        zx, zy = zx + (d + dx * s - zx) * inside, zy + (dy * s - zy) * inside
    zx, zy = wedge_dt(zx, zy, pr, dt)
    dx, dy = zx - d, zy
    return zx, zy, dx * dx + dy * dy >= r2 - dt(SETTLE_TOL)


def camera_dt(zx, zy, rr, cam_x, cam_y, rot, dt):
    """The codebox's camera (T030), written as the GPU computes it (real arithmetic, no complex type, dt precision).
    rr is the screen radius. The point is first scaled into the disk by min(1, 0.9999 / rr) (exactly 1 below 0.9999)."""
    cam_x, cam_y, rot = dt(cam_x), dt(cam_y), dt(rot)
    ln = np.sqrt(cam_x * cam_x + cam_y * cam_y)
    k = min(dt(1), dt(A_MAX) / max(ln, dt(1e-6)))
    ax, ay = cam_x * k, cam_y * k
    cin = np.minimum(dt(1), dt(0.9999) / np.maximum(rr, dt(1e-4)))
    rx = (zx * np.cos(rot) - zy * np.sin(rot)) * cin
    ry = (zx * np.sin(rot) + zy * np.cos(rot)) * cin
    dre = dt(1) - (ax * rx + ay * ry)
    dim = ax * ry - ay * rx
    den = np.maximum(dre * dre + dim * dim, dt(1e-6))
    nx_, ny_ = rx - ax, ry - ay
    return (nx_ * dre - ny_ * dim) / den, (nx_ * dim + ny_ * dre) / den


def rim_start(rim_fade, cam_x, cam_y, dt=np.float64):
    """The codebox's rim_eff: the fade starts 0.04 (|a| / 0.99)^2 earlier, |a| clamped to A_MAX (T032)."""
    ln = np.sqrt(dt(cam_x) * dt(cam_x) + dt(cam_y) * dt(cam_y))
    k = min(dt(1), dt(A_MAX) / max(ln, dt(1e-6)))
    ce = ln * k / dt(0.99)
    return dt(rim_fade) - dt(0.04) * ce * ce


def render(nx, ny, mode=0, p=4, q=5, tile_scale=0.26, iters=32, rim_fade=0.99, aspect=1.0, dt=np.float64,
           cam_x=0.0, cam_y=0.0, rot=0.0):
    """The codebox's whole pipeline for the ramp test texture, both modes (mode 0 = A, 1 = B), with the camera (default: none)."""
    nx, ny = np.asarray(nx, dt), np.asarray(ny, dt)
    asp_x, asp_y = dt(max(aspect, 1.0)), dt(max(1.0 / aspect, 1.0))
    zx, zy = (nx * dt(2) - dt(1)) * asp_x, (ny * dt(2) - dt(1)) * asp_y
    rr = np.sqrt(zx * zx + zy * zy)
    zx, zy = camera_dt(zx, zy, rr, cam_x, cam_y, rot, dt)
    fold = fold_b_k if mode else fold_a_k3
    sx, sy, settled = fold(zx, zy, p, q, iters, dt)
    u = sx / (dt(2) * dt(tile_scale)) + dt(0.5)
    v = sy / (dt(2) * dt(tile_scale)) + dt(0.5)
    inb = (u >= 0) * (u < 1) * (v >= 0) * (v < 1)
    uc, vc = np.clip(u, dt(0.001), dt(0.999)), np.clip(v, dt(0.001), dt(0.999))
    fade = settled.astype(dt) * inb * (rr < 1) * (dt(1) - _smoothstep(rim_start(rim_fade, cam_x, cam_y, dt), dt(1), rr, dt))
    return np.stack([uc * fade, vc * fade, uc * vc * fade], -1), settled, rr


def render_a(nx, ny, p=4, q=5, tile_scale=0.26, iters=32, rim_fade=0.99, aspect=1.0, dt=np.float64):
    return render(nx, ny, 0, p, q, tile_scale, iters, rim_fade, aspect, dt)
