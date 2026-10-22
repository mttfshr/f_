"""
bench_vf_lbm.py -- f_vf_lbm Phase 1 (tasks.md T008, T020): every stage codebox under src/f_vf_lbm/ run on the GPU
through the codebox bench and diffed against the NumPy mirror in vf_lbm_mirror.py, then the solver chain
host-sequenced over many frames (the bench drives one codebox per job; the f_vf_fluid ADR-10 method).

The solver state is one 192 x 324 float32 texture, the three RGBA state planes stacked vertically (the "state
atlas": plane 1 = rows 0..107, plane 2 = rows 108..215, plane 3 = rows 216..323). `atlas()` and `planes_of()`
convert to and from the mirror's list of three (108, 192, 4) planes.

Stage jobs (no stage has more than three inlets, the most the bench can drive):
    collide  in1 = state atlas, in2 = obstacle mask at any size (the mask is box-averaged inside collide)
    stream   in1 = state atlas
    mac      in1 = state atlas (output 192 x 108)
    enc      in1 = bang stand-in, in2 = macro texture (R = ux, G = uy), in3 = the previous step's macro texture
    mprev    in1 = bang stand-in, in2 = macro texture
    hold     NOT benched: an identity; the live module bench (bench_vf_lbm_module.py) covers it

Tolerances come from the first live runs (2026-10-21): one-frame stage errors were about 3e-7 (3e-6 here), the encode
error scales with gain, and the 30-frame chain was 4.3e-6. The atlas version has not been run yet: re-check them.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/vf_lbm/bench_vf_lbm.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 57

import paths as _paths
import sys
import time

import numpy as np

import benchclient as bc
import vf_lbm_mirror as lm
from vf_lbm_mirror import F32
from harness import check, note, run, slow

SRC = _paths.REPO / "src" / "f_vf_lbm"
W, H = 192, 108
FILES = {"collide": "codebox_collide.gen", "stream": "codebox_stream.gen", "mac": "codebox_mac.gen",
         "enc": "codebox_enc.gen", "mprev": "codebox_mprev.gen"}
BANG = np.zeros((4, 4, 4), np.float32)          # stand-in for a bang inlet
# The bench keeps a Param's last value between jobs: every job pins every Param its codebox declares.
PINNED = {"collide": {"omega": 1.97, "inflow": 0.08}, "enc": {"gain": 3.0, "bypass_gate": 0.0, "phase": 1.0, "nsteps": 1.0}}
TOL_STAGE = 3e-6        # one frame, one stage vs the mirror (measured 2026-10-21 on the three-texture version: worst 3.3e-7)
TOL_EXACT = 0.0         # pure gathers and copies


def tol_enc(gain):      # the encode error scales with gain (measured 1.8e-6 at gain 1, 5.4e-6 at 3, 1.8e-5 at 10)
    return max(1e-5, 3e-6 * gain)


def code(stage):
    return (SRC / FILES[stage]).read_text()


def gpu(stage, inputs, dim=None, **deltas):
    params = dict(PINNED.get(stage, {}))
    params.update(deltas)
    out, r = bc.run_pass(code(stage), inputs, dim=dim, params=params, timeout_ms=30000)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"{stage}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def planes_err(a, b, where=None):
    """Largest difference over three planes; plane 3 is compared in R only (the others are 0 by design).
    `where` (a bool (H, W) array) restricts the comparison to those cells."""
    if where is None:
        where = np.ones((H, W), bool)
    return max(mx(a[0][where], b[0][where]), mx(a[1][where], b[1][where]), mx(a[2][..., 0][where], b[2][..., 0][where]))


# ----------------------------------------------------------------- the state atlas

def atlas(planes):
    return np.concatenate([np.asarray(p, F32) for p in planes], axis=0)          # (324, 192, 4)


def planes_of(a):
    return [a[:H].copy(), a[H:2 * H].copy(), a[2 * H:].copy()]


# ----------------------------------------------------------------- inputs

YY, XX = np.mgrid[0:H, 0:W]
DISC = (XX + 0.5 - 48) ** 2 + (YY + 0.5 - 54) ** 2 < 9 ** 2


def flag_mask():
    """An obstacle flag: a disc, a bar, and cells ON the edge columns (the stage shields those)."""
    m = DISC.copy()
    m[20:30, 120:150] = True
    m[40:44, 0] = True
    m[60:64, W - 1] = True
    return m


def shielded(flag):
    """The mask the solver actually uses: the first and last columns are never obstacle."""
    m = flag.copy()
    m[:, 0] = False
    m[:, W - 1] = False
    return m


def mask_img(flag, size=None):
    """A white-on-black mask texture for the collide stage's second inlet (solver size unless `size` = (h, w))."""
    img = np.zeros((H, W, 4), F32)
    img[..., :3] = flag[..., None].astype(F32)
    img[..., 3] = 1.0
    return img


def valid_planes(seed, noise=0.001):
    """A valid, non-equilibrium state: rho near 1, u near the inflow, populations perturbed (so pre- and
    post-collision values differ, which the bounce-back timing check needs)."""
    rng = np.random.default_rng(seed)
    rho = (1 + 0.02 * rng.standard_normal((H, W))).astype(F32)
    ux = (0.08 + 0.02 * rng.standard_normal((H, W))).astype(F32)
    uy = (0.02 * rng.standard_normal((H, W))).astype(F32)
    f = lm.equilibrium(rho, ux, uy)
    f = [(fi + F32(noise) * rng.standard_normal((H, W)).astype(F32)).astype(F32) for fi in f]
    return lm.pack(f)


def seeded_planes(u0):
    """What the collide stage seeds a cell with: equilibrium at rho = 1, u = (u0, ripple)."""
    ripple = (0.02 * u0 * np.sin(0.3 * np.arange(W, dtype=np.float64)))[None, :] * np.ones((H, 1))
    one = np.ones((H, W), F32)
    return lm.pack(lm.equilibrium(one, np.full((H, W), u0, F32), ripple.astype(F32)))


def collide_gpu(planes, flag, mask=None, **deltas):
    """One collide frame on the GPU: the state atlas and the mask in, three planes out."""
    out = gpu("collide", [atlas(planes), mask if mask is not None else mask_img(flag)], **deltas)
    assert out.shape[:2] == (3 * H, W), out.shape
    return planes_of(out)


def stream_gpu(planes):
    return planes_of(gpu("stream", [atlas(planes)]))


# ----------------------------------------------------------------- compile

def test_every_stage_compiles_and_runs():
    pl = valid_planes(1)
    flag = flag_mask()
    macro_tex = np.zeros((H, W, 4), F32)
    macro_tex[..., 3] = 1.0
    runs = {
        "collide": lambda: gpu("collide", [atlas(pl), mask_img(flag)]),
        "stream": lambda: gpu("stream", [atlas(pl)]),
        "mac": lambda: gpu("mac", [atlas(pl)], dim=(W, H)),
        "enc": lambda: gpu("enc", [BANG, macro_tex], dim=(160, 90)),
        "mprev": lambda: gpu("mprev", [BANG, macro_tex], dim=(W, H)),
    }
    for name, fn in runs.items():
        out = fn()
        assert np.isfinite(out).all(), f"{name}: non-finite output"
        print(f"    ok   {name}: compiles, runs, output {out.shape[:2]} finite")


# ----------------------------------------------------------------- collide: the mask

def test_collide_mask_at_solver_size_is_exact():
    """1:1: the obstacle is the luma threshold of the mask, with the first and last columns never obstacle."""
    pl = valid_planes(2)
    want = lm.fuse_local([p.copy() for p in pl], DISC, 1.97, 0.08)
    painted = DISC.copy()
    painted[40:44, 0] = True                                  # an obstacle painted over the inflow column
    painted[60:64, W - 1] = True                              # and over the outflow column
    got = collide_gpu(pl, painted)
    check("mask 1:1: the disc is the obstacle, the edge columns are ignored (vs the mirror)", planes_err(got, want), TOL_STAGE)
    got0 = collide_gpu(pl, np.zeros((H, W), bool))
    want0 = lm.fuse_local([p.copy() for p in pl], np.zeros((H, W), bool), 1.97, 0.08)
    check("mask: a black mask is no obstacle", planes_err(got0, want0), TOL_STAGE)
    red = mask_img(DISC)
    red[..., 1:3] = 0.0                                       # a pure red disc has luma 0.299, below the threshold
    got_r = collide_gpu(pl, DISC, mask=red)
    check("mask: luma, not one channel (a pure red disc is below 0.5: no obstacle)", planes_err(got_r, want0), TOL_STAGE)


def test_collide_larger_mask_is_a_box_average():
    """A 2x larger mask: each lattice cell averages a 2 x 2 block (4 taps per axis, each source texel hit twice)."""
    pl = valid_planes(3)
    big = np.zeros((2 * H, 2 * W, 4), F32)
    yy, xx = np.mgrid[0:2 * H, 0:2 * W]
    disc = (xx + 0.5 - 96) ** 2 + (yy + 0.5 - 108) ** 2 < 17.3 ** 2
    big[..., :3] = disc[..., None].astype(F32)
    big[..., 3] = 1.0
    got = collide_gpu(pl, DISC, mask=big)
    block = disc.reshape(H, 2, W, 2).mean(axis=(1, 3))
    flag = shielded(block > 0.5)
    want = lm.fuse_local([p.copy() for p in pl], flag, 1.97, 0.08)
    tie = np.isclose(block, 0.5, atol=1e-4)                  # an exactly half-covered cell: either side is right
    note("mask 2:1: cells on an exact tie (excluded)", float(tie.sum()))
    check("mask 2:1: the obstacle is the thresholded 2 x 2 block mean (ties excluded), vs the mirror",
          planes_err(got, want, where=~tie), TOL_STAGE)


# ----------------------------------------------------------------- collide: the physics

def test_collide_matches_mirror_with_obstacle():
    pl = valid_planes(4)
    flag = flag_mask()
    got = collide_gpu(pl, flag)
    sh = shielded(flag)
    want = lm.fuse_local([p.copy() for p in pl], sh, 1.97, 0.08)
    check("collide vs mirror (obstacle, omega 1.97, inflow 0.08), max over three planes", planes_err(got, want), TOL_STAGE)
    check("collide: inside the obstacle the output is the pre-collision OPPOSITE population (exact)",
          max(mx(got[0][..., 1][sh], pl[0][..., 3][sh]), mx(got[0][..., 3][sh], pl[0][..., 1][sh])), TOL_EXACT)


def test_collide_bounce_back_uses_pre_collision_values():
    """The spike's trap #2, on the GPU: the mirror with the post-collision mutant differs a lot inside the mask,
    the correct mirror does not."""
    pl = valid_planes(5, noise=0.004)                     # far from equilibrium, so pre and post differ clearly
    got = collide_gpu(pl, DISC)
    good = lm.fuse_local([p.copy() for p in pl], DISC, 1.97, 0.08)
    bad = lm.fuse_local([p.copy() for p in pl], DISC, 1.97, 0.08, bug="bounce_post")
    e_good = planes_err(got, good)
    e_bad = planes_err(got, bad)
    note("bounce-back: error vs the correct mirror / vs the post-collision mutant", f"{e_good:.2e} / {e_bad:.2e}")
    check("bounce-back reads pre-collision values (GPU matches the correct mirror)", e_good, TOL_STAGE)
    check("... and is NOT the post-collision mutant (that differs by more than 1e-3)", float(e_bad < 1e-3), 0.0)


def test_collide_omega_and_inflow_clamps():
    pl = valid_planes(6)
    hi = collide_gpu(pl, DISC, omega=2.5)
    check("omega 2.5 is clamped to 1.98", planes_err(hi, lm.fuse_local([p.copy() for p in pl], DISC, 1.98, 0.08)), TOL_STAGE)
    lo = collide_gpu(pl, DISC, omega=0.1)
    check("omega 0.1 is clamped to 0.5", planes_err(lo, lm.fuse_local([p.copy() for p in pl], DISC, 0.5, 0.08)), TOL_STAGE)
    big = collide_gpu(pl, DISC, inflow=0.3)
    check("inflow 0.3 is clamped to 0.1", planes_err(big, lm.fuse_local([p.copy() for p in pl], DISC, 1.97, 0.1)), TOL_STAGE)
    for om in (1.0, 1.5, 1.9):
        got = collide_gpu(pl, DISC, omega=om)
        check(f"omega {om}: vs mirror", planes_err(got, lm.fuse_local([p.copy() for p in pl], DISC, om, 0.08)), TOL_STAGE)
    for u0 in (0.0, 0.04):
        got = collide_gpu(pl, DISC, inflow=u0)
        check(f"inflow {u0}: vs mirror (the inflow dial direction)",
              planes_err(got, lm.fuse_local([p.copy() for p in pl], DISC, 1.97, u0)), TOL_STAGE)


def test_collide_channel_edges():
    """Inflow column: ux forced to the inflow on the interior rows, rightward populations at equilibrium.
    Outflow column: the leftward populations copy from the column to the left."""
    pl = valid_planes(7)
    none = np.zeros((H, W), bool)
    got = collide_gpu(pl, none)
    want = lm.fuse_local([p.copy() for p in pl], none, 1.97, 0.08)
    check("collide, empty mask: whole frame vs mirror", planes_err(got, want), TOL_STAGE)
    check("collide, empty mask: inflow column vs mirror",
          max(mx(got[0][:, 0], want[0][:, 0]), mx(got[1][:, 0], want[1][:, 0])), TOL_STAGE)
    check("collide, empty mask: outflow column vs mirror",
          max(mx(got[0][:, -1], want[0][:, -1]), mx(got[1][:, -1], want[1][:, -1])), TOL_STAGE)


def test_collide_seeds_an_empty_or_poisoned_state():
    none = np.zeros((H, W), bool)
    seed_pl = seeded_planes(0.08)
    # the mirror's outflow copy reads the neighbour cell's seeded values, which differ from this cell's by the
    # ripple, so the last column is excluded; everything else is the same arithmetic
    want = lm.fuse_local([p.copy() for p in seed_pl], none, 1.97, 0.08)
    interior = np.ones((H, W), bool)
    interior[:, -1] = False
    zero = [np.zeros((H, W, 4), F32) for _ in range(3)]
    got = collide_gpu(zero, none)
    check("all-zero state: reseeded, then one frame, vs the mirror (last column excluded)",
          planes_err(got, want, where=interior), TOL_STAGE)
    empty = [np.zeros((H, W, 4), F32) for _ in range(3)]
    for p in empty:
        p[..., 3] = 1.0                                    # what an empty inlet reads: (0, 0, 0, 1)
    got2 = collide_gpu(empty, none)
    check("an empty inlet (0, 0, 0, 1) is not mistaken for a state: reseeded the same way",
          planes_err(got2, want, where=interior), TOL_STAGE)
    pl = valid_planes(8)
    poisoned = [p.copy() for p in pl]
    poisoned[0][10, 10, 0] = np.nan
    poisoned[1][11, 11, 2] = np.inf
    poisoned[0][12, 12, 1] = 40.0                          # a blown-up density
    got3 = collide_gpu(poisoned, none)
    check("a NaN, an Inf and a blown-up cell: nothing non-finite survives",
          float(np.count_nonzero(~np.isfinite(np.concatenate([g.ravel() for g in got3])))), 0.0)
    ref = lm.fuse_local([p.copy() for p in pl], none, 1.97, 0.08)
    away = np.ones((H, W), bool)
    for (r, c) in ((10, 10), (11, 11), (12, 12)):
        away[max(r - 1, 0):r + 2, max(c - 1, 0):c + 2] = False       # the poisoned cells and their neighbours
    check("the untouched cells away from the poison are unchanged", planes_err(got3, ref, where=away), TOL_STAGE)


# ----------------------------------------------------------------- stream

def roll_stream(pl):
    """An exact reference for the gather: new[x] = old[x - e_i] is np.roll by +e_i on both periodic axes.
    (The mirror's own stream goes through gpu_sim.sample, which leaves ~4e-7 of float noise at texel centres.)"""
    f = lm.unpack([p.copy() for p in pl])
    new = [np.roll(f[i], (int(lm.E[i, 1]), int(lm.E[i, 0])), axis=(0, 1)) for i in range(9)]
    return lm.pack(new)


def test_stream_matches_exact_roll_and_mirror():
    pl = valid_planes(9)
    got = stream_gpu(pl)
    check("stream vs np.roll by +e_i (a pure gather: bitwise)", planes_err(got, roll_stream(pl)), TOL_EXACT)
    check("stream vs the mirror's stream", planes_err(got, lm.stream([p.copy() for p in pl])), 1e-6)


def test_stream_direction_one_cell_along_e_i():
    """The spike's trap #1, on the GPU: a mark in population i moves exactly one cell along e_i per frame
    (new[x] = old[x - e_i]). A sign flip would move it the other way. Includes the periodic seams in x and y."""
    x0, y0 = 50, 40
    for i in range(9):
        f = [np.zeros((H, W), F32) for _ in range(9)]
        f[i][y0, x0] = 1.0
        nf = lm.unpack(stream_gpu(lm.pack(f)))
        ex, ey = int(lm.E[i, 0]), int(lm.E[i, 1])
        ys, xs = np.nonzero(nf[i])
        ok = len(ys) == 1 and (ys[0], xs[0]) == (y0 + ey, x0 + ex) and abs(nf[i][ys[0], xs[0]] - 1.0) == 0.0
        check(f"population {i} (e = {ex},{ey}): the mark lands at x + e_i and nowhere else", float(not ok), 0.0)
    for (i, xs0, ys0) in ((1, W - 1, 40), (3, 0, 40), (2, 50, H - 1), (4, 50, 0), (6, 0, H - 1)):
        f = [np.zeros((H, W), F32) for _ in range(9)]
        f[i][ys0, xs0] = 1.0
        nf = lm.unpack(stream_gpu(lm.pack(f)))
        ex, ey = int(lm.E[i, 0]), int(lm.E[i, 1])
        ys, xs = np.nonzero(nf[i])
        want = ((ys0 + ey) % H, (xs0 + ex) % W)
        ok = len(ys) == 1 and (ys[0], xs[0]) == want
        check(f"population {i} at the seam ({xs0},{ys0}): wraps to {want[::-1]}", float(not ok), 0.0)


# ----------------------------------------------------------------- mac

def test_mac_matches_mirror():
    pl = valid_planes(10)
    got = gpu("mac", [atlas(pl)], dim=(W, H))
    rho, ux, uy = lm.macro(lm.unpack(pl))
    check("mac: ux vs mirror", mx(got[..., 0], ux), TOL_STAGE)
    check("mac: uy vs mirror", mx(got[..., 1], uy), TOL_STAGE)
    check("mac: rho vs mirror", mx(got[..., 2], rho), TOL_STAGE)
    check("mac: A = 1", mx(got[..., 3], 1.0), 0.0)
    bad = [p.copy() for p in pl]
    bad[0][5, 5, 0] = np.nan
    bad[1][6, 6, 1] = np.inf
    out = gpu("mac", [atlas(bad)], dim=(W, H))
    check("mac: non-finite populations never reach the output", float(np.count_nonzero(~np.isfinite(out))), 0.0)
    zero = atlas([np.zeros((H, W, 4), F32) for _ in range(3)])
    z = gpu("mac", [zero], dim=(W, H))
    check("mac: an all-zero state gives finite zero velocity",
          float(np.count_nonzero(~np.isfinite(z)) + np.abs(z[..., :2]).max()), 0.0)


# ----------------------------------------------------------------- enc

def up_bilinear(a, h, w):
    """(H, W) -> (h, w): texel-centre bilinear, y periodic, x clamped (the encode stage's upsample)."""
    fx = (np.arange(w, dtype=np.float64) + 0.5) * W / w - 0.5
    fy = (np.arange(h, dtype=np.float64) + 0.5) * H / h - 0.5
    x0 = np.floor(fx).astype(int)
    y0 = np.floor(fy).astype(int)
    tx = (fx - x0)[None, :]
    ty = (fy - y0)[:, None]
    xa, xb = np.clip(x0, 0, W - 1), np.clip(x0 + 1, 0, W - 1)
    ya, yb = y0 % H, (y0 + 1) % H
    top = a[ya][:, xa] * (1 - tx) + a[ya][:, xb] * tx
    bot = a[yb][:, xa] * (1 - tx) + a[yb][:, xb] * tx
    return top * (1 - ty) + bot * ty


def macro_tex(pl):
    rho, ux, uy = lm.macro(lm.unpack(pl))
    t = np.zeros((H, W, 4), F32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = ux, uy, rho, 1.0
    return t, ux, uy


def test_enc_at_solver_size_matches_mirror():
    pl = valid_planes(11)
    tex, ux, uy = macro_tex(pl)
    got = gpu("enc", [BANG, tex], dim=(W, H))
    want = lm.encode(pl, 3.0)
    check("enc at 192x108 vs the mirror's encode, max over RGBA", mx(got, want), tol_enc(3.0))
    for gain in (0.0, 1.0, 10.0):
        g = gpu("enc", [BANG, tex], dim=(W, H), gain=gain)
        w = lm.encode(pl, gain)
        check(f"enc gain {gain:g} vs the mirror", mx(g, w), tol_enc(gain))
    check("enc gain 0: exactly neutral", mx(gpu("enc", [BANG, tex], dim=(W, H), gain=0.0)[..., :3], 0.5), 0.0)
    byp = gpu("enc", [BANG, tex], dim=(W, H), bypass_gate=1.0)
    check("bypass_gate 1: an exactly neutral vecfield (0.5, 0.5, 0.5, 1)",
          max(mx(byp[..., 0], 0.5), mx(byp[..., 1], 0.5), mx(byp[..., 2], 0.5), mx(byp[..., 3], 1.0)), 0.0)
    check("enc: B = 0.5 and A = 1 always", max(mx(got[..., 2], 0.5), mx(got[..., 3], 1.0)), 0.0)


def test_enc_upsample_at_other_sizes():
    pl = valid_planes(12)
    tex, ux, uy = macro_tex(pl)
    for (h, w) in ((90, 160), (216, 384), (720, 1280)):
        out = gpu("enc", [BANG, tex], dim=(w, h))
        r = np.clip(0.5 + 3.0 * up_bilinear(ux.astype(np.float64), h, w), 0.0, 1.0)
        g = np.clip(0.5 + 3.0 * up_bilinear(uy.astype(np.float64), h, w), 0.0, 1.0)
        check(f"enc {w}x{h}: R vs y-periodic, x-clamped bilinear", mx(out[..., 0], r), tol_enc(3.0))
        check(f"enc {w}x{h}: G vs the same", mx(out[..., 1], g), tol_enc(3.0))
    wide = np.zeros((H, W, 4), F32)
    wide[..., 0] = 40.0
    wide[..., 3] = 1.0
    check("enc: a huge velocity clamps to 1 (no overflow past the range)",
          mx(gpu("enc", [BANG, wide], dim=(32, 32))[..., 0], 1.0), 0.0)
    bad = tex.copy()
    bad[20, 20, 0] = np.nan
    bad[21, 21, 1] = np.inf
    out = gpu("enc", [BANG, bad], dim=(W, H))
    check("enc: non-finite velocity never reaches the outlet", float(np.count_nonzero(~np.isfinite(out))), 0.0)
    # only the poisoned channel is zeroed (R at 20,20 and G at 21,21); the other channel keeps its real value
    check("enc: ... the poisoned channel encodes as zero velocity there",
          max(mx(out[20, 20, 0], 0.5), mx(out[21, 21, 1], 0.5)), 0.0)


def test_mprev_is_an_identity_copy():
    pl = valid_planes(13)
    tex, ux, uy = macro_tex(pl)
    check("mprev copies the macro texture exactly", mx(gpu("mprev", [BANG, tex], dim=(W, H)), tex), TOL_EXACT)


def test_enc_speed_blend():
    """The Speed blend: the velocity shown is mix(previous, current, phase / nsteps). Previous is the third inlet."""
    cur, ux_c, uy_c = macro_tex(valid_planes(14))
    prev, ux_p, uy_p = macro_tex(valid_planes(15))
    for (ph, ns) in ((1, 1), (1, 2), (2, 2), (1, 4), (3, 4), (4, 4)):
        w = ph / ns
        out = gpu("enc", [BANG, cur, prev], dim=(W, H), phase=float(ph), nsteps=float(ns))
        ux = ux_p.astype(np.float64) + (ux_c.astype(np.float64) - ux_p) * w
        uy = uy_p.astype(np.float64) + (uy_c.astype(np.float64) - uy_p) * w
        want_r = np.clip(0.5 + 3.0 * ux, 0, 1)
        want_g = np.clip(0.5 + 3.0 * uy, 0, 1)
        check(f"enc blend phase {ph} of {ns} (weight {w:.2f}): R", mx(out[..., 0], want_r), tol_enc(3.0))
        check(f"enc blend phase {ph} of {ns}: G", mx(out[..., 1], want_g), tol_enc(3.0))
    full = gpu("enc", [BANG, cur, prev], dim=(W, H), phase=4.0, nsteps=4.0)
    check("phase = nsteps shows the current velocity exactly (no smoothing lag at the end of a step)",
          mx(full[..., 0], np.clip(0.5 + 3.0 * ux_c.astype(np.float64), 0, 1)), tol_enc(3.0))


# ----------------------------------------------------------------- chain

def chain_vs_mirror(frames, omega, marks, tag):
    flag = DISC
    start = seeded_planes(0.08)
    g = [p.copy() for p in start]
    m = [p.copy() for p in start]
    errs = {}
    t0 = time.time()
    for f in range(1, frames + 1):
        c = collide_gpu(g, flag, omega=omega)
        g = stream_gpu(c)
        m, _ = lm.lbm_step(m, flag, omega, 0.08, 3.0)
        if f in marks:
            errs[f] = planes_err(g, m)
    print(f"    ...  {frames} frames x 2 jobs in {time.time() - t0:.0f}s (omega {omega})")
    return errs, m, g


def test_chain_30_frames_matches_mirror():
    errs, m, g = chain_vs_mirror(30, 1.97, (1, 5, 10, 30), "chain 30")
    for f, e in errs.items():
        note(f"omega 1.97, frame {f}: max |GPU - mirror|", e)
    check("30 frames at omega 1.97: max |GPU - mirror|", errs[30], 4e-5)   # measured 4.3e-6 on the three-texture version
    moved = planes_err(m, seeded_planes(0.08))
    note("how far the state moved from the seed in 30 frames (so the test is not vacuous)", moved)
    check("the state moved (max change from the seed above 0.01)", float(moved < 0.01), 0.0)


@slow       # 100 frames x 2 bench jobs
def test_chain_100_frames_matches_mirror():
    errs, m, g = chain_vs_mirror(100, 1.8, (10, 30, 60, 100), "chain 100")
    for f, e in errs.items():
        note(f"omega 1.8, frame {f}: max |GPU - mirror|", e)
    check("100 frames at omega 1.8: max |GPU - mirror|", errs[100], 2e-4)
    check("state finite after 100 frames", float(np.count_nonzero(~np.isfinite(np.concatenate([p.ravel() for p in g])))), 0.0)
    rho = lm.macro(lm.unpack(g))[0]
    note("GPU density range after 100 frames (min / max)", f"{float(rho.min()):.4f} / {float(rho.max()):.4f}")
    check("density stays near 1 (within 0.2) after 100 frames", float(np.abs(rho - 1).max() > 0.2), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
