"""Offline transcription check of the ATLAS collide and stream codeboxes (2026-10-21): the new indexing (vv offsets, the
kp/py arithmetic, the per-plane output selection, the outflow neighbour reads) in NumPy over the 324 x 192 atlas grid,
diffed against the verified mirror. Catches transcription slips; it cannot catch GenExpr compile problems or GPU behaviour.
Run: tests/py.sh scratch/lbm_port_check_atlas.py"""
import numpy as np
import paths  # noqa: F401
import vf_lbm_mirror as lm
from vf_lbm_mirror import F32

W, H, AH = 192, 108, 324
rng = np.random.default_rng(5)
YT, XT = np.mgrid[0:AH, 0:W]                       # output texel (row, column) of the atlas
KP = np.floor(YT / 108.0)
PY = YT - KP * 108
PX = XT.astype(np.float64)
WTS = [4 / 9] + [1 / 9] * 4 + [1 / 36] * 4
EX = [0, 1, 0, -1, 0, 1, -1, -1, 1]
EY = [0, 0, 1, 0, -1, 1, 1, -1, -1]


def valid(noise=0.003):
    rho = (1 + 0.02 * rng.standard_normal((H, W))).astype(F32)
    ux = (0.08 + 0.02 * rng.standard_normal((H, W))).astype(F32)
    uy = (0.02 * rng.standard_normal((H, W))).astype(F32)
    f = lm.equilibrium(rho, ux, uy)
    return lm.pack([(fi + F32(noise) * rng.standard_normal((H, W)).astype(F32)).astype(F32) for fi in f])


def read(atlas, j, ch, xcell, ycell):
    """nearest(in1, vec((x+0.5)/W, vv(j, y))).ch with vv(j, y) = (j*108 + y + 0.5)/324: the texel at row j*108+y."""
    return atlas[(j * 108 + ycell).astype(int), xcell.astype(int), ch].astype(np.float64)


def select(kp, n):
    o0 = np.where(kp < 0.5, n[0], np.where(kp < 1.5, n[4], n[8]))
    o1 = np.where(kp < 0.5, n[1], np.where(kp < 1.5, n[5], 0.0))
    o2 = np.where(kp < 0.5, n[2], np.where(kp < 1.5, n[6], 0.0))
    o3 = np.where(kp < 0.5, n[3], np.where(kp < 1.5, n[7], 0.0))
    return np.stack([o0, o1, o2, o3], -1)


def fe(wt, lx, ly, r0, vx, vy):
    eu = lx * vx + ly * vy
    return wt * r0 * (1 + 3 * eu + 4.5 * eu * eu - 1.5 * (vx * vx + vy * vy))


def port_stream(atlas):
    xm, xp = (PX - 1) % W, (PX + 1) % W
    ym, yp = (PY - 1) % H, (PY + 1) % H
    n = [read(atlas, 0, 0, PX, PY), read(atlas, 0, 1, xm, PY), read(atlas, 0, 2, PX, ym), read(atlas, 0, 3, xp, PY),
         read(atlas, 1, 0, PX, yp), read(atlas, 1, 1, xm, ym), read(atlas, 1, 2, xp, ym), read(atlas, 1, 3, xp, yp),
         read(atlas, 2, 0, xm, yp)]
    return select(KP, n)


def port_collide(atlas, flag, omega, inflow):
    om, u0 = min(max(omega, 0.5), 1.98), min(max(inflow, 0.0), 0.1)
    is_in, is_out = (PX < 0.5).astype(float), (PX > W - 1.5).astype(float)
    is_row = (PY > 0.5).astype(float) * (PY < H - 1.5).astype(float)
    b = [read(atlas, 0, 0, PX, PY), read(atlas, 0, 1, PX, PY), read(atlas, 0, 2, PX, PY), read(atlas, 0, 3, PX, PY),
         read(atlas, 1, 0, PX, PY), read(atlas, 1, 1, PX, PY), read(atlas, 1, 2, PX, PY), read(atlas, 1, 3, PX, PY),
         read(atlas, 2, 0, PX, PY)]
    allfin = np.ones(PX.shape)
    for x in b:
        allfin = allfin * (np.abs(x) < 1e30)
    rb = sum(b)
    use_seed = (allfin * (rb > 0.2) * (rb < 5) * (b[0] > 0.05) < 0.5).astype(float)
    ripple = 0.02 * u0 * np.sin(0.3 * PX)
    a = [np.where(use_seed >= 0.5, fe(WTS[i], EX[i], EY[i], 1.0, u0, ripple), b[i]) for i in range(9)]
    um = (PX - 1) % W                                   # pm = (px - 0.5)/W is the centre of cell x-1
    cp = is_out * (1 - use_seed)
    f = list(a)
    f[3] = np.where(cp >= 0.5, read(atlas, 0, 3, um, PY), a[3])
    f[6] = np.where(cp >= 0.5, read(atlas, 1, 2, um, PY), a[6])
    f[7] = np.where(cp >= 0.5, read(atlas, 1, 3, um, PY), a[7])
    rho = sum(f)
    ux = (f[1] - f[3] + f[5] - f[6] - f[7] + f[8]) / rho
    uy = (f[2] - f[4] + f[5] + f[6] - f[7] - f[8]) / rho
    set_u = is_in * is_row
    ux2, uy2 = np.where(set_u >= 0.5, u0, ux), np.where(set_u >= 0.5, 0.0, uy)
    rho_in = (f[0] + f[2] + f[4] + 2 * (f[3] + f[6] + f[7])) / (1 - ux2)
    rho2 = np.where(is_in >= 0.5, rho_in, rho)
    q = [fe(WTS[i], EX[i], EY[i], rho2, ux2, uy2) for i in range(9)]
    g = list(f)
    for i in (1, 5, 8):
        g[i] = np.where(is_in >= 0.5, q[i], f[i])
    c = [g[i] + om * (q[i] - g[i]) for i in range(9)]
    m = flag[PY.astype(int), XT] * (1 - is_in) * (1 - is_out) >= 0.5      # the mask flag for this cell (shielded)
    opp = [0, 3, 4, 1, 2, 7, 8, 5, 6]
    n = [np.where(m, a[opp[i]], c[i]) for i in range(9)]
    return select(KP, n)


def err(a, b):
    return float(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64)).max())


def atlas_of(pl):
    return np.concatenate(pl, axis=0)


def cmp3(got_atlas, want_planes, tag):
    g = [got_atlas[:H], got_atlas[H:2 * H], got_atlas[2 * H:, :, :1]]
    w = [want_planes[0], want_planes[1], want_planes[2][..., :1]]
    print(f"{tag}: max |port - reference| = {max(err(x, y) for x, y in zip(g, w)):.2e}")
    pad = got_atlas[2 * H:, :, 1:]
    print(f"   plane 3 channels G, B, A are zero: {float(np.abs(pad).max()) == 0.0}")


pl = valid()
cmp3(port_stream(atlas_of(pl)), lm.stream([p.copy() for p in pl]), "stream (vs the mirror)")
f = [np.zeros((H, W), F32) for _ in range(9)]
roll = lm.pack([np.roll(x, (int(lm.E[i, 1]), int(lm.E[i, 0])), axis=(0, 1)) for i, x in enumerate(lm.unpack(pl))])
cmp3(port_stream(atlas_of(pl)), roll, "stream (vs the exact np.roll)")

yy, xx = np.mgrid[0:H, 0:W]
flag = ((xx + 0.5 - 48) ** 2 + (yy + 0.5 - 54) ** 2 < 81)
flag[20:30, 120:150] = True
for om, u0 in ((1.97, 0.08), (1.5, 0.04), (1.98, 0.1), (2.5, 0.3)):
    want = lm.fuse_local([p.copy() for p in pl], flag, min(max(om, 0.5), 1.98), min(max(u0, 0.0), 0.1))
    cmp3(port_collide(atlas_of(pl), flag, om, u0), want, f"collide omega {om} inflow {u0}")
zero = atlas_of([np.zeros((H, W, 4), F32) for _ in range(3)])
want = lm.fuse_local(lm.pack(lm.equilibrium(np.ones((H, W), F32), np.full((H, W), 0.08, F32),
                     ((0.02 * 0.08 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))).astype(F32))),
                     np.zeros((H, W), bool), 1.97, 0.08)
got = port_collide(zero, np.zeros((H, W), bool), 1.97, 0.08)
print(f"seeding (last column excluded): {max(err(got[:H, :-1], want[0][:, :-1]), err(got[H:2 * H, :-1], want[1][:, :-1])):.2e}")
