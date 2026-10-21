"""
bench_vf_lbm.py -- f_vf_lbm Phase 1 (tasks.md T008, T020): every stage codebox under src/f_vf_lbm/ run on the GPU
through the codebox bench and diffed against the NumPy mirror in vf_lbm_mirror.py, then the solver chain
host-sequenced over many frames (the bench drives one codebox per job; the f_vf_fluid ADR-10 method).

Stage jobs (every stage but hold has at most three inlets, the most the bench can drive):
    mrg      in1 = third state plane (R = population 8), in2 = obstacle mask at any size
    collide  in1, in2, in3 = state planes 1..3; the third carries the obstacle flag in G
    stream   in1, in2, in3 = state planes 1..3
    mac      in1, in2, in3 = state planes 1..3
    enc      in1 = bang stand-in, in2 = macro texture (R = ux, G = uy)
    hold     NOT benched: four inlets, an identity; the live module bench (bench_vf_lbm_module.py) covers it

TOLERANCES ARE NOT MEASURED YET. Every tolerance below is a guess with headroom, written before the first live
run. After the first green run, replace each with a value ~10x the measured error and say so in the comment (the
bench_ks.py convention), so the check can catch a regression instead of sitting 1000x loose.

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
FILES = {"mrg": "codebox_mrg.gen", "collide": "codebox_collide.gen", "stream": "codebox_stream.gen",
         "mac": "codebox_mac.gen", "enc": "codebox_enc.gen"}
BANG = np.zeros((4, 4, 4), np.float32)          # stand-in for the `r draw` bang inlet
# The bench keeps a Param's last value between jobs: every job pins every Param its codebox declares.
PINNED = {"collide": {"omega": 1.97, "inflow": 0.08}, "enc": {"gain": 3.0, "bypass_gate": 0.0}}
TOL_STAGE = 1e-5        # one frame, one stage vs the mirror (guess: float32 op order differs between GPU and NumPy)
TOL_EXACT = 0.0         # pure gathers and copies


def code(stage):
    return (SRC / FILES[stage]).read_text()


def gpu(stage, inputs, dim=None, all_outputs=False, **deltas):
    params = dict(PINNED.get(stage, {}))
    params.update(deltas)
    out, r = bc.run_pass(code(stage), inputs, dim=dim, params=params, all_outputs=all_outputs, timeout_ms=30000)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"{stage}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def planes_err(a, b):
    """Largest difference over three planes; plane 3 is compared in R only (the others are 0 by design)."""
    return max(mx(a[0], b[0]), mx(a[1], b[1]), mx(a[2][..., 0], b[2][..., 0]))


# ----------------------------------------------------------------- inputs

YY, XX = np.mgrid[0:H, 0:W]
DISC = (XX + 0.5 - 48) ** 2 + (YY + 0.5 - 54) ** 2 < 9 ** 2


def flag_mask():
    """An obstacle flag: a disc, a bar, and cells ON the edge columns (collide must treat the flag as given)."""
    m = DISC.copy()
    m[20:30, 120:150] = True
    m[40:44, 0] = True
    m[60:64, W - 1] = True
    return m


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
    """What the collide stage seeds a texel with: equilibrium at rho = 1, u = (u0, ripple)."""
    ripple = (0.02 * u0 * np.sin(0.3 * np.arange(W, dtype=np.float64)))[None, :] * np.ones((H, 1))
    one = np.ones((H, W), F32)
    return lm.pack(lm.equilibrium(one, np.full((H, W), u0, F32), ripple.astype(F32)))


def with_flag(planes, flag):
    """The collide stage's third input: plane 3 with the obstacle flag in G."""
    p2 = planes[2].copy()
    p2[..., 1] = flag.astype(F32)
    return p2


def collide_gpu(planes, flag, **deltas):
    outs = gpu("collide", [planes[0], planes[1], with_flag(planes, flag)], all_outputs=True, **deltas)
    return [outs[0], outs[1], outs[2]]


# ----------------------------------------------------------------- compile

def test_every_stage_compiles_and_runs():
    pl = valid_planes(1)
    flag = flag_mask()
    macro_tex = np.zeros((H, W, 4), F32)
    macro_tex[..., 3] = 1.0
    runs = {
        "mrg": lambda: gpu("mrg", [pl[2], np.zeros((H, W, 4), F32)]),
        "collide": lambda: gpu("collide", [pl[0], pl[1], with_flag(pl, flag)]),
        "stream": lambda: gpu("stream", [pl[0], pl[1], pl[2]]),
        "mac": lambda: gpu("mac", [pl[0], pl[1], pl[2]]),
        "enc": lambda: gpu("enc", [BANG, macro_tex], dim=(160, 90)),
    }
    for name, fn in runs.items():
        out = fn()
        assert np.isfinite(out).all(), f"{name}: non-finite output"
        print(f"    ok   {name}: compiles, runs, output {out.shape[:2]} finite")


# ----------------------------------------------------------------- mrg (the obstacle flag)

def test_mrg_mask_at_solver_size_is_exact():
    """1:1: the flag is the luma threshold of the mask, with the first and last columns never obstacle; R passes
    population 8 through unchanged."""
    pl = valid_planes(2)
    mask = np.zeros((H, W, 4), F32)
    mask[..., :3] = DISC[..., None].astype(F32)            # white disc on black
    mask[..., 3] = 1.0
    mask[40:44, 0, :3] = 1.0                               # an obstacle painted over the inflow column
    mask[60:64, W - 1, :3] = 1.0                           # and over the outflow column
    out = gpu("mrg", [pl[2], mask])
    want = DISC.astype(F32)
    check("mrg 1:1: flag equals the disc, edge columns zero", mx(out[..., 1], want), TOL_EXACT)
    check("mrg 1:1: population 8 passes through", mx(out[..., 0], pl[2][..., 0]), TOL_EXACT)
    check("mrg: B and A are 0", float(np.abs(out[..., 2:]).max()), TOL_EXACT)
    dark = np.zeros((H, W, 4), F32)
    dark[..., 3] = 1.0
    check("mrg: a black mask is no obstacle", float(np.abs(gpu("mrg", [pl[2], dark])[..., 1]).max()), TOL_EXACT)
    red = mask.copy()
    red[..., 1:3] = 0.0                                    # a pure red disc has luma 0.299, below the threshold
    check("mrg: luma, not one channel (a pure red disc is below 0.5)",
          float(np.abs(gpu("mrg", [pl[2], red])[..., 1]).max()), TOL_EXACT)


def test_mrg_larger_mask_is_a_box_average():
    """A 2x larger mask: each solver texel averages a 2 x 2 block (4 taps per axis, each source texel hit twice)."""
    pl = valid_planes(3)
    big = np.zeros((2 * H, 2 * W, 4), F32)
    yy, xx = np.mgrid[0:2 * H, 0:2 * W]
    disc = (xx + 0.5 - 96) ** 2 + (yy + 0.5 - 108) ** 2 < 17.3 ** 2
    big[..., :3] = disc[..., None].astype(F32)
    big[..., 3] = 1.0
    out = gpu("mrg", [pl[2], big])
    block = disc.reshape(H, 2, W, 2).mean(axis=(1, 3))
    want = (block > 0.5).astype(F32)
    want[:, 0] = 0.0
    want[:, -1] = 0.0
    tie = np.isclose(block, 0.5, atol=1e-4)               # an exactly half-covered texel: either side is right
    bad = (out[..., 1] != want) & ~tie
    note("mrg 2:1: texels on an exact tie (excluded)", float(tie.sum()))
    check("mrg 2:1: flag equals the thresholded 2 x 2 block mean (ties excluded)", float(bad.sum()), 0.0)


# ----------------------------------------------------------------- collide

def test_collide_matches_mirror_with_obstacle():
    pl = valid_planes(4)
    flag = flag_mask()
    got = collide_gpu(pl, flag)
    want = lm.fuse_local([p.copy() for p in pl], flag, 1.97, 0.08)
    check("collide vs mirror (obstacle, edges, omega 1.97, inflow 0.08), max over three planes",
          planes_err(got, want), TOL_STAGE)
    inside = flag
    check("collide: inside the obstacle the output is the pre-collision OPPOSITE population (exact)",
          max(mx(got[0][..., 1][inside], pl[0][..., 3][inside]), mx(got[0][..., 3][inside], pl[0][..., 1][inside])),
          TOL_EXACT)


def test_collide_bounce_back_uses_pre_collision_values():
    """The spike's trap #2, on the GPU: the mirror with the post-collision mutant differs a lot inside the mask,
    the correct mirror does not."""
    pl = valid_planes(5, noise=0.004)                     # far from equilibrium, so pre and post differ clearly
    flag = DISC
    got = collide_gpu(pl, flag)
    good = lm.fuse_local([p.copy() for p in pl], flag, 1.97, 0.08)
    bad = lm.fuse_local([p.copy() for p in pl], flag, 1.97, 0.08, bug="bounce_post")
    e_good = planes_err(got, good)
    e_bad = planes_err(got, bad)
    note("bounce-back: error vs the correct mirror / vs the post-collision mutant", f"{e_good:.2e} / {e_bad:.2e}")
    check("bounce-back reads pre-collision values (GPU matches the correct mirror)", e_good, TOL_STAGE)
    check("... and is NOT the post-collision mutant (that differs by more than 1e-3)", float(e_bad < 1e-3), 0.0)


def test_collide_omega_and_inflow_clamps():
    pl = valid_planes(6)
    flag = DISC
    hi = collide_gpu(pl, flag, omega=2.5)
    want = lm.fuse_local([p.copy() for p in pl], flag, 1.98, 0.08)
    check("omega 2.5 is clamped to 1.98", planes_err(hi, want), TOL_STAGE)
    lo = collide_gpu(pl, flag, omega=0.1)
    want = lm.fuse_local([p.copy() for p in pl], flag, 0.5, 0.08)
    check("omega 0.1 is clamped to 0.5", planes_err(lo, want), TOL_STAGE)
    big = collide_gpu(pl, flag, inflow=0.3)
    want = lm.fuse_local([p.copy() for p in pl], flag, 1.97, 0.1)
    check("inflow 0.3 is clamped to 0.1", planes_err(big, want), TOL_STAGE)
    for om in (1.0, 1.5, 1.9):
        got = collide_gpu(pl, flag, omega=om)
        want = lm.fuse_local([p.copy() for p in pl], flag, om, 0.08)
        check(f"omega {om}: vs mirror", planes_err(got, want), TOL_STAGE)
    for u0 in (0.0, 0.04):
        got = collide_gpu(pl, flag, inflow=u0)
        want = lm.fuse_local([p.copy() for p in pl], flag, 1.97, u0)
        check(f"inflow {u0}: vs mirror (the inflow dial direction)", planes_err(got, want), TOL_STAGE)


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
    # the mirror's outflow copy reads the neighbour texel's seeded values, which differ from this texel's by the
    # ripple, so the last column is excluded; everything else is the same arithmetic
    want = lm.fuse_local([p.copy() for p in seed_pl], none, 1.97, 0.08)
    def interior(a):
        return a[:, :-1]
    zero = [np.zeros((H, W, 4), F32) for _ in range(3)]
    got = collide_gpu(zero, none)
    check("all-zero state: reseeded, then one frame, vs the mirror (last column excluded)",
          max(mx(interior(got[0]), interior(want[0])), mx(interior(got[1]), interior(want[1])),
              mx(interior(got[2][..., 0]), interior(want[2][..., 0]))), TOL_STAGE)
    empty = [np.zeros((H, W, 4), F32) for _ in range(3)]
    for p in empty:
        p[..., 3] = 1.0                                    # what an empty inlet reads: (0, 0, 0, 1)
    got2 = collide_gpu(empty, none)
    check("an empty inlet (0, 0, 0, 1) is not mistaken for a state: reseeded the same way",
          max(mx(interior(got2[0]), interior(want[0])), mx(interior(got2[1]), interior(want[1]))), TOL_STAGE)
    pl = valid_planes(8)
    poisoned = [p.copy() for p in pl]
    poisoned[0][10, 10, 0] = np.nan
    poisoned[1][11, 11, 2] = np.inf
    poisoned[0][12, 12, 1] = 40.0                          # a blown-up density
    got3 = collide_gpu(poisoned, none)
    check("a NaN, an Inf and a blown-up texel: nothing non-finite survives",
          float(np.count_nonzero(~np.isfinite(np.concatenate([g.ravel() for g in got3])))), 0.0)
    ref = lm.fuse_local([p.copy() for p in pl], none, 1.97, 0.08)
    away = np.ones((H, W), bool)
    for (r, c) in ((10, 10), (11, 11), (12, 12)):
        away[max(r - 1, 0):r + 2, max(c - 1, 0):c + 2] = False       # the poisoned texels and their gather neighbours
    check("the untouched texels away from the poison are unchanged",
          mx(got3[0][away], ref[0][away]), TOL_STAGE)


# ----------------------------------------------------------------- stream

def roll_stream(pl):
    """An exact reference for the gather: new[x] = old[x - e_i] is np.roll by +e_i on both periodic axes.
    (The mirror's own stream goes through gpu_sim.sample, which leaves ~4e-7 of float noise at texel centres.)"""
    f = lm.unpack([p.copy() for p in pl])
    new = [np.roll(f[i], (int(lm.E[i, 1]), int(lm.E[i, 0])), axis=(0, 1)) for i in range(9)]
    return lm.pack(new)


def test_stream_matches_exact_roll_and_mirror():
    pl = valid_planes(9)
    got = gpu("stream", [pl[0], pl[1], pl[2]], all_outputs=True)
    check("stream vs np.roll by +e_i (a pure gather: bitwise)", planes_err(got, roll_stream(pl)), TOL_EXACT)
    check("stream vs the mirror's stream", planes_err(got, lm.stream([p.copy() for p in pl])), 1e-6)


def test_stream_direction_one_cell_along_e_i():
    """The spike's trap #1, on the GPU: a mark in population i moves exactly one texel along e_i per frame
    (new[x] = old[x - e_i]). A sign flip would move it the other way. Includes the periodic seam in x and y."""
    x0, y0 = 50, 40
    for i in range(9):
        f = [np.zeros((H, W), F32) for _ in range(9)]
        f[i][y0, x0] = 1.0
        pl = lm.pack(f)
        out = gpu("stream", [pl[0], pl[1], pl[2]], all_outputs=True)
        nf = lm.unpack([out[0], out[1], out[2]])
        ex, ey = int(lm.E[i, 0]), int(lm.E[i, 1])
        ys, xs = np.nonzero(nf[i])
        ok = len(ys) == 1 and (ys[0], xs[0]) == (y0 + ey, x0 + ex) and abs(nf[i][ys[0], xs[0]] - 1.0) == 0.0
        check(f"population {i} (e = {ex},{ey}): the mark lands at x + e_i and nowhere else", float(not ok), 0.0)
    for (i, xs0, ys0) in ((1, W - 1, 40), (3, 0, 40), (2, 50, H - 1), (4, 50, 0), (6, 0, H - 1)):
        f = [np.zeros((H, W), F32) for _ in range(9)]
        f[i][ys0, xs0] = 1.0
        pl = lm.pack(f)
        out = gpu("stream", [pl[0], pl[1], pl[2]], all_outputs=True)
        nf = lm.unpack([out[0], out[1], out[2]])
        ex, ey = int(lm.E[i, 0]), int(lm.E[i, 1])
        ys, xs = np.nonzero(nf[i])
        want = ((ys0 + ey) % H, (xs0 + ex) % W)
        ok = len(ys) == 1 and (ys[0], xs[0]) == want
        check(f"population {i} at the seam ({xs0},{ys0}): wraps to {want[::-1]}", float(not ok), 0.0)


# ----------------------------------------------------------------- mac

def test_mac_matches_mirror():
    pl = valid_planes(10)
    got = gpu("mac", [pl[0], pl[1], pl[2]])
    rho, ux, uy = lm.macro(lm.unpack(pl))
    check("mac: ux vs mirror", mx(got[..., 0], ux), TOL_STAGE)
    check("mac: uy vs mirror", mx(got[..., 1], uy), TOL_STAGE)
    check("mac: rho vs mirror", mx(got[..., 2], rho), TOL_STAGE)
    check("mac: A = 1", mx(got[..., 3], 1.0), 0.0)
    bad = [p.copy() for p in pl]
    bad[0][5, 5, 0] = np.nan
    bad[1][6, 6, 1] = np.inf
    out = gpu("mac", [bad[0], bad[1], bad[2]])
    check("mac: non-finite populations never reach the output", float(np.count_nonzero(~np.isfinite(out))), 0.0)
    zero = [np.zeros((H, W, 4), F32) for _ in range(3)]
    check("mac: an all-zero state gives finite zero velocity",
          float(np.count_nonzero(~np.isfinite(gpu("mac", zero))) + np.abs(gpu("mac", zero)[..., :2]).max()), 0.0)


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
    check("enc at 192x108 vs the mirror's encode, max over RGBA", mx(got, want), TOL_STAGE)
    for gain in (0.0, 1.0, 10.0):
        g = gpu("enc", [BANG, tex], dim=(W, H), gain=gain)
        w = lm.encode(pl, gain)
        check(f"enc gain {gain:g} vs the mirror", mx(g, w), TOL_STAGE)
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
        check(f"enc {w}x{h}: R vs y-periodic, x-clamped bilinear", mx(out[..., 0], r), 2e-6)
        check(f"enc {w}x{h}: G vs the same", mx(out[..., 1], g), 2e-6)
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
    check("enc: ... it encodes as zero velocity there",
          max(mx(out[20, 20, :2], 0.5), mx(out[21, 21, :2], 0.5)), 0.0)


# ----------------------------------------------------------------- chain

def g_frame(planes, flag):
    """One solver frame from real GPU passes: collide -> stream (hold is an identity; mrg's flag is given)."""
    c = collide_gpu(planes, flag)
    s = gpu("stream", [c[0], c[1], c[2]], all_outputs=True)
    return [s[0], s[1], s[2]]


def chain_vs_mirror(frames, omega, marks, tag):
    flag = DISC
    mask_render = np.zeros((H, W, 4), F32)
    mask_render[..., :3] = DISC[..., None].astype(F32)
    mask_render[..., 3] = 1.0
    start = seeded_planes(0.08)
    # the real mrg stage supplies the flag the chain uses
    flag_gpu = gpu("mrg", [start[2], mask_render])[..., 1] > 0.5
    check(f"{tag}: the chain's flag from the real mrg stage equals the disc", float(np.count_nonzero(flag_gpu != DISC)), 0.0)
    g = [p.copy() for p in start]
    m = [p.copy() for p in start]
    errs = {}
    t0 = time.time()
    for f in range(1, frames + 1):
        c = collide_gpu(g, flag_gpu, omega=omega)
        s = gpu("stream", [c[0], c[1], c[2]], all_outputs=True)
        g = [s[0], s[1], s[2]]
        m, _ = lm.lbm_step(m, flag, omega, 0.08, 3.0)
        if f in marks:
            errs[f] = planes_err(g, m)
    print(f"    ...  {frames} frames x 2 jobs in {time.time() - t0:.0f}s (omega {omega})")
    return errs, m, g


def test_chain_30_frames_matches_mirror():
    errs, m, g = chain_vs_mirror(30, 1.97, (1, 5, 10, 30), "chain 30")
    for f, e in errs.items():
        note(f"omega 1.97, frame {f}: max |GPU - mirror|", e)
    # tolerance is a guess (float32 op order, amplified by the flow): replace with ~10x the first measurement
    check("30 frames at omega 1.97: max |GPU - mirror|", errs[30], 1e-4)
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
