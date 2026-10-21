"""Offline transcription check (2026-10-21): the collide and stream GenExpr logic, line by line in NumPy,
diffed against the verified mirror. Catches transcription slips (channel picks, outflow neighbour reads, the
bounce-back opposite map, seeding). It cannot catch GenExpr compile or GPU behaviour: that is the bench's job.
Run: tests/py.sh scratch/lbm_port_check.py"""
import numpy as np
import paths  # noqa: F401
import vf_lbm_mirror as lm
from vf_lbm_mirror import F32

W, H = 192, 108
rng = np.random.default_rng(3)
yy, xx = np.mgrid[0:H, 0:W]


def valid(noise=0.003):
    rho = (1 + 0.02 * rng.standard_normal((H, W))).astype(F32)
    ux = (0.08 + 0.02 * rng.standard_normal((H, W))).astype(F32)
    uy = (0.02 * rng.standard_normal((H, W))).astype(F32)
    f = lm.equilibrium(rho, ux, uy)
    return lm.pack([(fi + F32(noise) * rng.standard_normal((H, W)).astype(F32)).astype(F32) for fi in f])


def fe(wt, lx, ly, r0, vx, vy):
    eu = lx * vx + ly * vy
    return wt * r0 * (1 + 3 * eu + 4.5 * eu * eu - 1.5 * (vx * vx + vy * vy))


def port_collide(p0, p1, p2m, omega, inflow):
    """The collide codebox, statement for statement. p0/p1/p2m are (H, W, 4)."""
    px = xx.astype(np.float64)
    py = yy.astype(np.float64)
    om = min(max(omega, 0.5), 1.98)
    u0 = min(max(inflow, 0.0), 0.1)
    is_in = (px < 0.5).astype(float)
    is_out = (px > W - 1.5).astype(float)
    is_row = (py > 0.5).astype(float) * (py < H - 1.5).astype(float)
    b = [p0[..., 0], p0[..., 1], p0[..., 2], p0[..., 3], p1[..., 0], p1[..., 1], p1[..., 2], p1[..., 3], p2m[..., 0]]
    b = [x.astype(np.float64) for x in b]
    allfin = np.ones((H, W))
    for x in b:
        allfin = allfin * (np.abs(x) < 1e30)
    rb = sum(b)
    valid_ = allfin * (rb > 0.2) * (rb < 5) * (b[0] > 0.05)
    use_seed = (valid_ < 0.5).astype(float)
    ripple = 0.02 * u0 * np.sin(0.3 * px)
    wts = [4 / 9] + [1 / 9] * 4 + [1 / 36] * 4
    ex = [0, 1, 0, -1, 0, 1, -1, -1, 1]
    ey = [0, 0, 1, 0, -1, 1, 1, -1, -1]
    a = [np.where(use_seed >= 0.5, fe(wts[i], ex[i], ey[i], 1.0, u0, ripple), b[i]) for i in range(9)]
    # outflow: neighbour at x - 1, plane/channel as in the codebox (in1.w, in2.z, in2.w)
    nb3 = np.roll(p0[..., 3], 1, axis=1)
    nb6 = np.roll(p1[..., 2], 1, axis=1)
    nb7 = np.roll(p1[..., 3], 1, axis=1)
    cp = is_out * (1 - use_seed)
    f = list(a)
    f[3] = np.where(cp >= 0.5, nb3, a[3])
    f[6] = np.where(cp >= 0.5, nb6, a[6])
    f[7] = np.where(cp >= 0.5, nb7, a[7])
    rho = sum(f)
    ux = (f[1] - f[3] + f[5] - f[6] - f[7] + f[8]) / rho
    uy = (f[2] - f[4] + f[5] + f[6] - f[7] - f[8]) / rho
    set_u = is_in * is_row
    ux2 = np.where(set_u >= 0.5, u0, ux)
    uy2 = np.where(set_u >= 0.5, 0.0, uy)
    rho_in = (f[0] + f[2] + f[4] + 2 * (f[3] + f[6] + f[7])) / (1 - ux2)
    rho2 = np.where(is_in >= 0.5, rho_in, rho)
    q = [fe(wts[i], ex[i], ey[i], rho2, ux2, uy2) for i in range(9)]
    g = list(f)
    for i in (1, 5, 8):
        g[i] = np.where(is_in >= 0.5, q[i], f[i])
    c = [g[i] + om * (q[i] - g[i]) for i in range(9)]
    m = p2m[..., 1] >= 0.5
    opp = [0, 3, 4, 1, 2, 7, 8, 5, 6]            # the codebox's n_i = a_opp(i) when inside
    n = [np.where(m, a[opp[i]], c[i]) for i in range(9)]
    z = np.zeros((H, W))
    return [np.stack(n[0:4], -1), np.stack(n[4:8], -1), np.stack([n[8], z, z, z], -1)]


def port_stream(p0, p1, p2):
    """The stream codebox: plane/channel and (dx, dy) of the SOURCE texel exactly as written there."""
    src = [(0, 0), (-1, 0), (0, -1), (1, 0), (0, 1), (-1, -1), (1, -1), (1, 1), (-1, 1)]   # (dx, dy) of the read
    planes = [(p0, 0), (p0, 1), (p0, 2), (p0, 3), (p1, 0), (p1, 1), (p1, 2), (p1, 3), (p2, 0)]
    n = []
    for (dx, dy), (pl, ch) in zip(src, planes):
        n.append(np.roll(np.roll(pl[..., ch], -dy, axis=0), -dx, axis=1))
    z = np.zeros((H, W))
    return [np.stack(n[0:4], -1), np.stack(n[4:8], -1), np.stack([n[8], z, z, z], -1)]


def err(a, b):
    return max(float(np.abs(np.asarray(x, np.float64) - np.asarray(y, np.float64)).max()) for x, y in zip(a, b))


flag = ((xx + 0.5 - 48) ** 2 + (yy + 0.5 - 54) ** 2 < 81)
flag[20:30, 120:150] = True
flag[40:44, 0] = True
flag[60:64, W - 1] = True
pl = valid()
p2m = pl[2].copy()
p2m[..., 1] = flag.astype(F32)
for om, u0 in ((1.97, 0.08), (1.5, 0.04), (1.98, 0.1), (2.5, 0.3)):
    got = port_collide(pl[0], pl[1], p2m, om, u0)
    want = lm.fuse_local([p.copy() for p in pl], flag, min(max(om, 0.5), 1.98), min(max(u0, 0.0), 0.1))
    g3 = [got[0], got[1], got[2][..., :1]]
    w3 = [want[0], want[1], want[2][..., :1]]
    print(f"collide omega {om} inflow {u0}: max |port - mirror| = {err(g3, w3):.2e}")

zero = [np.zeros((H, W, 4), F32) for _ in range(3)]
got = port_collide(zero[0], zero[1], zero[2], 1.97, 0.08)
want = lm.fuse_local(
    lm.pack(lm.equilibrium(np.ones((H, W), F32), np.full((H, W), 0.08, F32),
                           ((0.02 * 0.08 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))).astype(F32))),
    np.zeros((H, W), bool), 1.97, 0.08)
print(f"seeding (last column excluded): {err([got[0][:, :-1], got[1][:, :-1]], [want[0][:, :-1], want[1][:, :-1]]):.2e}")

pl = valid()
got = port_stream(pl[0], pl[1], pl[2])
want = lm.stream([p.copy() for p in pl])
print(f"stream: max |port - mirror| = {err([got[0], got[1], got[2][..., :1]], [want[0], want[1], want[2][..., :1]]):.2e}")
