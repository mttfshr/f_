"""
bench_vf_erode.py -- f_vf_erode tier 2 (tasks.md T082): every stage codebox under src/f_vf_erode/ run on the GPU through the codebox
bench and diffed against the NumPy mirror in vf_erode_mirror.py, then a short host-sequenced chain.

State atlas: (2H, W, 4) float32, plane A = rows 0..H-1 (R water, GBA suspension), plane B = rows H..2H-1 (RGB paper pigment, A the load
flag: 2 * loaded + the wet gate as last seen). Every atlas stage's Params width and height are pinned to W and H, and the job's `dim`
is (W, 2H); `enc` outputs (W, H). Stage inputs (never more than four, the harness limit):
    prep       in1 bang stand-in, in2 terrain, in3 vecfield
    load       in1 state atlas, in2 picture
    transport  in1 state atlas, in2 prep atlas            react  in1 state atlas, in2 prep atlas
    enc        in1 bang stand-in, in2 state atlas, in3 picture, in4 background
    hold       NOT benched: an identity; the module bench covers it

The mirror is split with its `only` argument ("transport" / "react") so each codebox is compared on its own. The 2H atlas size is not
square (W 64, H 48), so a swapped axis shows. Tolerances are first guesses (nothing in this file has run): arithmetic that samples
nothing but nearest taps should agree near 1e-5; pow / exp / log (enc, load) are looser. Re-set them from the first live run.
Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/vf_erode/bench_vf_erode.py
"""
GROUP = "regression"
ORDER = 58

import paths as _paths
import sys

import numpy as np

import benchclient as bc
import vf_erode_mirror as em
from vf_erode_mirror import F32
from harness import check, note, run

SRC = _paths.REPO / "src" / "f_vf_erode"
W, H = 64, 48
BANG = np.zeros((4, 4, 4), np.float32)
KR = H / em.REF_H        # the render-size scaling factor the codeboxes derive from the height Param (T083): 48 / 1920
SIZE = {"width": float(W), "height": float(H)}
# The bench keeps a Param's last value between jobs: every job pins every Param its codebox declares.
PINNED = {
    "prep": dict(SIZE, flow=0.4, push=1.0, speed=1.0, src_terrain=1.0, src_field=1.0),
    "load": dict(SIZE, polar_sw=0.0, flood=1.0, feed=0.0, fade=0.0, wet_gate=0.0),
    "transport": dict(SIZE, flow=0.4, speed=1.0, dry=0.0016),
    "react": dict(SIZE, flow=0.4, speed=1.0, lift=0.7, settle=0.19),
    "enc": dict(polar_sw=0.0, src_bg=0.0, bypass_gate=0.0),
}
TOL_PREP = 2e-5         # float32 products and sums of values up to about 6 (terrain relief)
TOL_STAGE = 1e-5        # transport and react: nearest taps and float32 arithmetic only
TOL_POW = 2e-4          # load and enc: pow, log and exp on the GPU
TOL_CHAIN = 2e-4        # ten solver steps


def code(stage):
    return (SRC / f"codebox_{stage}.gen").read_text()


def gpu(stage, inputs, dim, outs=False, **deltas):
    params = dict(PINNED[stage])
    params.update(deltas)
    out, r = bc.run_pass(code(stage), inputs, dim=dim, params=params, timeout_ms=30000, all_outputs=outs)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"{stage}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def mx(a, b, where=None):
    d = np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))
    return float(np.max(d if where is None else d[where]))


# ----------------------------------------------------------------- the atlas

def to_atlas(st, flag):
    a = np.zeros((2 * H, W, 4), F32)
    a[:H, :, 0] = st["w"]
    a[:H, :, 1:4] = st["s"]
    a[H:, :, :3] = st["p"]
    a[H:, :, 3] = flag
    return a


def from_atlas(a, loaded=True):
    return dict(w=a[:H, :, 0].copy(), s=a[:H, :, 1:4].copy(), p=a[H:, :, :3].copy(), loaded=loaded,
                escaped=np.zeros(3), escaped_w=0.0, entered=np.zeros(3), entered_w=0.0)


def smooth(rng, shape, lo, hi, k=5):
    """A smooth random field in lo..hi (box blurred noise), so slopes are modest and the clipped faces are the exception."""
    a = rng.uniform(0, 1, shape).astype(np.float64)
    for ax in (0, 1):
        a = sum(np.roll(a, s, axis=ax) for s in range(-k, k + 1)) / (2 * k + 1)
    a = (a - a.min()) / (a.max() - a.min())
    return (lo + (hi - lo) * a).astype(F32)


def textures(seed):
    rng = np.random.default_rng(seed)
    terrain = np.ones((H, W, 4), F32)
    terrain[..., :3] = smooth(rng, (H, W, 3), 0.0, 1.0)
    field = np.ones((H, W, 4), F32)
    field[..., 0] = smooth(rng, (H, W), 0.15, 0.85)
    field[..., 1] = smooth(rng, (H, W), 0.15, 0.85)
    return terrain, field


def picture(seed, lo=0.1, hi=1.0):
    rng = np.random.default_rng(seed)
    img = np.ones((H, W, 4), F32)
    img[..., :3] = rng.uniform(lo, hi, (H, W, 3)).astype(F32)
    img[..., 3] = rng.uniform(0.2, 1.0, (H, W)).astype(F32)
    return img


def random_state(seed, wlo=0.3, whi=1.0, zeros=False):
    rng = np.random.default_rng(seed)
    w = smooth(rng, (H, W), wlo, whi)
    if zeros:
        w[rng.uniform(0, 1, (H, W)) < 0.2] = 0
    s = (rng.uniform(0, 1, (H, W, 3)) * 0.5).astype(F32)
    p = (rng.uniform(0, 1, (H, W, 3)) * 2.0).astype(F32)
    return dict(w=w, s=s, p=p, loaded=True, escaped=np.zeros(3), escaped_w=0.0, entered=np.zeros(3), entered_w=0.0)


def prep_gpu(terrain, field, **deltas):
    return gpu("prep", [BANG, terrain, field], (W, 2 * H), **deltas)


def prep_expected(terrain, field, flow, push, speed):
    """The static face velocities and drive, written from the mirror's own definitions (T, Tp odd reflection, edge-replicated field)."""
    T = em.terrain_height(terrain).astype(np.float64)
    fx, fy = em.field_uv(field)
    fe, kc = flow * KR * min(KR, em.K_CAP), min(KR, em.K_CAP)           # T083: the codeboxes scale `flow` by kr * kc and the field by kc
    flow = fe
    fx, fy = fx.astype(np.float64) * push * em.FIELD_SCALE * kc, fy.astype(np.float64) * push * em.FIELD_SCALE * kc
    Tp = np.pad(T, 1, mode="reflect", reflect_type="odd")
    Fxp, Fyp = np.pad(fx, 1, mode="edge"), np.pad(fy, 1, mode="edge")
    vl = speed * (-flow * (T - Tp[1:-1, :-2]) + 0.5 * (Fxp[1:-1, :-2] + fx))
    vr = speed * (-flow * (Tp[1:-1, 2:] - T) + 0.5 * (fx + Fxp[1:-1, 2:]))
    vu = speed * (-flow * (T - Tp[:-2, 1:-1]) + 0.5 * (Fyp[:-2, 1:-1] + fy))
    vd = speed * (-flow * (Tp[2:, 1:-1] - T) + 0.5 * (fy + Fyp[2:, 1:-1]))
    gy, gx = np.gradient(T)
    return np.stack([vl, vr, vu, vd], -1), np.stack([fx - flow * gx, fy - flow * gy], -1)


# ----------------------------------------------------------------- compile

def test_every_stage_compiles_and_runs():
    st = random_state(1)
    terrain, field = textures(1)
    pa = prep_gpu(terrain, field)
    atl = to_atlas(st, 3.0)
    pic = picture(1)
    runs = {
        "prep": lambda: pa,
        "load": lambda: gpu("load", [atl, pic], (W, 2 * H)),
        "transport": lambda: gpu("transport", [atl, pa], (W, 2 * H)),
        "react": lambda: gpu("react", [atl, pa], (W, 2 * H)),
        "enc": lambda: gpu("enc", [BANG, atl, pic, pic], (W, H)),
    }
    for name, fn in runs.items():
        out = fn()
        assert np.isfinite(out).all(), f"{name}: non-finite output"
        print(f"    ok   {name}: compiles, runs, output {out.shape[:2]} finite")


# ----------------------------------------------------------------- prep

def test_prep_matches_the_static_formulas():
    terrain, field = textures(2)
    for flow, push, speed in ((0.4, 1.0, 1.0), (1.3, 2.5, 1.7)):
        got = prep_gpu(terrain, field, flow=flow, push=push, speed=speed)
        faces, drive = prep_expected(terrain, field, flow, push, speed)
        check(f"prep faces (flow {flow}, push {push}, speed {speed}): left, right, up, down vs the formulas",
              mx(got[:H], faces), TOL_PREP)
        check("prep drive: field minus flow * the terrain gradient", mx(got[H:, :, :2], drive), TOL_PREP)
        # a face is stored by both of its cells: right of x equals left of x + 1, down of y equals up of y + 1
        check("prep: the right face of a cell is the left face of its neighbor, bit for bit",
              mx(got[:H, :-1, 1], got[:H, 1:, 0]), 0.0)
        check("prep: the down face of a cell is the up face of the cell below, bit for bit",
              mx(got[:H - 1, :, 3], got[1:H, :, 2]), 0.0)


def test_prep_unconnected_inlets_are_zero():
    terrain, field = textures(3)
    got = prep_gpu(terrain, field, src_terrain=0.0, src_field=0.0)
    check("prep: both inlets unconnected (flags 0): every face and the drive are exactly zero", mx(got[:H], 0) + mx(got[H:, :, :2], 0), 0.0)
    only_t = prep_gpu(terrain, field, src_field=0.0)
    faces, drive = prep_expected(terrain, field, 0.4, 0.0, 1.0)
    check("prep: terrain only (the vecfield's value is ignored: the flag decides)", mx(only_t[:H], faces), TOL_PREP)


# ----------------------------------------------------------------- transport

def test_transport_matches_the_mirror():
    terrain, field = textures(4)
    pa = prep_gpu(terrain, field, push=2.0)
    T, F = em.terrain_height(terrain), em.field_uv(field)
    st = random_state(4)
    atl = to_atlas(st, 3.0)
    for flow, speed, dry in ((0.4, 1.0, 0.0016), (0.9, 1.6, 0.01)):
        pa = prep_gpu(terrain, field, push=2.0, flow=flow, speed=speed)
        got = gpu("transport", [atl, pa], (W, 2 * H), flow=flow, speed=speed, dry=dry)
        want = em.step(st, T, F, only="transport", flow=flow, speed=speed, dry=dry, push=2.0, edge="open", k=KR)
        check(f"transport (flow {flow}, speed {speed}, dry {dry}): water", mx(got[:H, :, 0], want["w"]), TOL_STAGE)
        check("transport: suspension", mx(got[:H, :, 1:4], want["s"]), TOL_STAGE)
        check("transport: the paper pigment and the flag pass unchanged", mx(got[H:], atl[H:]), 0.0)


def test_transport_flat_still_water_does_not_move():
    # a constant suspension: a varying one is smoothed by the diffusion term, which is correct behaviour and not stillness
    st = dict(random_state(5), w=np.full((H, W), 0.5, F32), s=np.full((H, W, 3), 0.2, F32))
    z = np.zeros((H, W, 4), F32)
    z[..., 3] = 1
    pa = prep_gpu(z, z, src_terrain=0.0, src_field=0.0)
    got = gpu("transport", [to_atlas(st, 3.0), pa], (W, 2 * H), dry=0.0)
    check("transport: flat terrain, no field, dry 0: the water is unchanged", mx(got[:H, :, 0], st["w"]), 1e-6)
    check("transport: and so is the suspension", mx(got[:H, :, 1:4], st["s"]), 1e-6)


def test_transport_conserves_water_in_the_interior():
    """With the whole depth far from the frame edge, the water sum must not change (a scatter of the same faces in a different order)."""
    terrain, field = textures(6)
    pa = prep_gpu(terrain, field)
    w = np.zeros((H, W), F32)
    w[16:32, 20:44] = 0.8
    st = dict(random_state(6), w=w, s=np.zeros((H, W, 3), F32))
    got = gpu("transport", [to_atlas(st, 3.0), pa], (W, 2 * H), dry=0.0)
    check("transport: water sum before and after (relative), a wash that stays off the edge", abs(float(got[:H, :, 0].sum(dtype=np.float64)) / float(w.sum(dtype=np.float64)) - 1), 1e-6)


# ----------------------------------------------------------------- react

def test_react_matches_the_mirror():
    terrain, field = textures(7)
    T, F = em.terrain_height(terrain), em.field_uv(field)
    st = random_state(7, wlo=0.0, whi=1.0, zeros=True)
    atl = to_atlas(st, 3.0)
    for flow, speed, lift, settle in ((0.4, 1.0, 0.7, 0.19), (1.0, 2.0, 1.0, 0.5)):       # the DIAL values; the mirror takes the curves
        pa = prep_gpu(terrain, field, push=2.0, flow=flow, speed=speed)
        got = gpu("react", [atl, pa], (W, 2 * H), flow=flow, speed=speed, lift=lift, settle=settle)
        want = em.step(st, T, F, only="react", flow=flow, speed=speed, lift=em.lift_from_dial(lift), settle=em.settle_from_dial(settle), push=2.0, k=KR)
        check(f"react (flow {flow}, speed {speed}, lift {lift}, settle {settle}): the water is unchanged", mx(got[:H, :, 0], st["w"]), 0.0)
        check("react: suspension", mx(got[:H, :, 1:4], want["s"]), TOL_STAGE)
        check("react: paper pigment", mx(got[H:, :, :3], want["p"]), TOL_STAGE)
        check("react: the flag passes", mx(got[H:, :, 3], atl[H:, :, 3]), 0.0)
        check("react: pigment is conserved cell by cell (p + s before and after)", mx(got[:H, :, 1:4] + got[H:, :, :3], st["s"] + st["p"]), 1e-5)


def test_react_sanitizes_the_state():
    st = random_state(8)
    atl = to_atlas(st, 3.0)
    atl[5, 5, 0] = np.nan
    atl[7, 9, 1] = np.inf
    atl[H + 3, 4, 2] = -np.inf
    atl[10, 10, 0] = -0.3
    terrain, field = textures(8)
    got = gpu("react", [atl, prep_gpu(terrain, field)], (W, 2 * H))
    assert np.isfinite(got).all(), "react let a non-finite value through"
    assert got[:H, :, 0].min() >= 0 and got[:H, :, 1:4].min() >= 0 and got[H:, :, :3].min() >= 0, "react let a negative layer through"
    print("    ok   react: NaN, Inf and negative inputs come out finite and non-negative")


# ----------------------------------------------------------------- load

def test_load_wets_on_the_press_edge_only():
    st = random_state(9)
    pic = picture(9)
    for pol, name in ((0.0, "Darker"), (1.0, "Lighter")):
        base = em.new_state(H, W)
        base["w"] = st["w"]
        want = em.load(base, pic, "darker" if pol == 0 else "lighter", flood=1.5)
        got = gpu("load", [to_atlas(base, 0.0), pic], (W, 2 * H), polar_sw=pol, flood=1.5, wet_gate=1.0)
        check(f"load {name}: a press wets: water + flood", mx(got[:H, :, 0], want["w"]), 1e-6)
        check(f"load {name}: the suspension is emptied", mx(got[:H, :, 1:4], 0), 0.0)
        check(f"load {name}: the picture becomes the paper pigment", mx(got[H:, :, :3], want["p"]), TOL_POW)
        check(f"load {name}: flag 0 -> 3 (loaded, gate seen)", mx(got[H:, :, 3], 3.0), 0.0)
    loaded = to_atlas(st, 3.0)
    held = gpu("load", [loaded, pic], (W, 2 * H), wet_gate=1.0)
    check("load: a held press (flag 3, gate 1) does not wet again", mx(held, loaded), 0.0)
    rel = gpu("load", [loaded, pic], (W, 2 * H), wet_gate=0.0)
    check("load: a release (flag 3, gate 0) changes only the flag, to 2", mx(rel[:, :, :3], loaded[:, :, :3]) + mx(rel[:H, :, 3], loaded[:H, :, 3]) + mx(rel[H:, :, 3], 2.0), 0.0)
    again = gpu("load", [to_atlas(st, 2.0), pic], (W, 2 * H), wet_gate=1.0, flood=1.0)
    check("load: a second press (flag 2, gate 1) wets again, flag 3", mx(again[H:, :, 3], 3.0), 0.0)
    check("load: the second wetting keeps the water and adds the flood", mx(again[:H, :, 0], st["w"] + 1.0), 1e-6)
    fresh = gpu("load", [to_atlas(st, 1.0), pic], (W, 2 * H), wet_gate=0.0)
    empty = to_atlas(st, 0.0)[:H].copy()
    empty[..., 1:4] = 0.0           # not loaded = no pigment: a never-written texture reads (0, 0, 0, 1), so the suspension would be 1
    check("load: a never-written texture (flag 1, gate 0) is not loaded: flag 0, nothing wets, no suspension carried", mx(fresh[H:, :, 3], 0.0) + mx(fresh[:H], empty), 0.0)
    unl = gpu("load", [to_atlas(st, 0.0), pic], (W, 2 * H), feed=0.5)
    check("load: feeding from a never-loaded state ignores its old pigment (paper = 0.5 * the picture's)", mx(unl[H:, :, :3], 0.5 * em.pigment_from_picture(pic, "darker")), TOL_POW)


def test_load_feed_matches_the_mirror():
    """Feed (US5): after the wetting test, a fraction of the pigment shortfall is deposited and the water relaxes toward flood."""
    st = random_state(15)
    pic = picture(15)
    for pol, name in ((0.0, "darker"), (1.0, "lighter")):
        for rate in (0.0, 0.3, 1.0):
            want = em.feed(st, pic, name, rate, flood=1.5)
            got = gpu("load", [to_atlas(st, 3.0), pic], (W, 2 * H), polar_sw=pol, flood=1.5, feed=rate)
            lab = f"load feed {rate} {name}"
            check(f"{lab}: water", mx(got[:H, :, 0], want["w"]), TOL_POW)
            check(f"{lab}: the paper pigment", mx(got[H:, :, :3], want["p"]), TOL_POW)
            check(f"{lab}: the suspension is untouched", mx(got[:H, :, 1:4], st["s"]), 0.0)
            check(f"{lab}: the flag is 2 (loaded, gate 0)", mx(got[H:, :, 3], 2.0), 0.0)
    got = gpu("load", [to_atlas(st, 0.0), pic], (W, 2 * H), feed=0.3)
    check("load: feeding counts as loaded: flag 0 -> 2 with no press", mx(got[H:, :, 3], 2.0), 0.0)
    got = gpu("load", [to_atlas(st, 0.0), pic], (W, 2 * H), feed=0.0)
    check("load: feed 0 with no press leaves the flag at 0", mx(got[H:, :, 3], 0.0), 0.0)


def test_load_fade_matches_the_mirror():
    """Fade: with feed above 0, paper pigment above the picture's returns toward it; with feed 0 it does nothing."""
    st = random_state(17)
    pic = picture(17)
    for pol, name in ((0.0, "darker"), (1.0, "lighter")):
        for rate, fade in ((0.3, 0.1), (0.3, 1.0), (0.0, 1.0)):
            want = em.feed(st, pic, name, rate, flood=1.0, fade=fade)
            got = gpu("load", [to_atlas(st, 3.0), pic], (W, 2 * H), polar_sw=pol, feed=rate, fade=fade)
            check(f"load fade {fade} with feed {rate} {name}: the paper pigment", mx(got[H:, :, :3], want["p"]), TOL_POW)
            check(f"load fade {fade} with feed {rate} {name}: the water", mx(got[:H, :, 0], want["w"]), TOL_POW)


def test_load_picture_extremes_and_non_finite():
    base = em.new_state(H, W)
    pic = picture(10)
    pic[2, 2, :3] = (0.0, 5.0, np.nan)
    pic[3, 3, :3] = (np.inf, -1.0, 1.0)
    got = gpu("load", [to_atlas(base, 0.0), pic], (W, 2 * H), wet_gate=1.0)
    want = em.load(base, np.where(np.isfinite(pic), pic, 0).astype(F32), "darker")
    assert np.isfinite(got).all(), "load let a non-finite value through"
    check("load Darker: black, above 1, NaN, Inf and negative picture texels (zapped to 0, the log bounded)", mx(got[H:, :, :3], want["p"]), TOL_POW)


# ----------------------------------------------------------------- enc

def test_enc_matches_the_mirror():
    st = random_state(11)
    pic, bg = picture(11), picture(12, 0.2, 1.0)
    for loaded in (True, False):
        for pol, name in ((0.0, "darker"), (1.0, "lighter")):
            for use_bg in (0.0, 1.0):
                atl = to_atlas(st, 3.0 if loaded else 0.0)
                a, th = gpu("enc", [BANG, atl, pic, bg], (W, H), outs=True, polar_sw=pol, src_bg=use_bg)[:2]
                want, wth = em.enc(dict(st, loaded=loaded), pic, bg if use_bg else None, name)
                lab = f"enc {name}, {'wet' if loaded else 'before the first wetting'}, background {'on' if use_bg else 'off'}"
                check(f"{lab}: the composite", mx(a, want), TOL_POW)
                check(f"{lab}: the thickness", mx(th[..., 0], wth), TOL_POW)
                check(f"{lab}: the thickness outlet's alpha is the picture's", mx(th[..., 3], pic[..., 3]), 0.0)


def test_enc_unwetted_is_the_input_and_bypass_is_the_picture():
    pic = picture(13, 0.1, 0.95)
    pic[..., 3] = 1.0
    atl = to_atlas(random_state(13), 0.0)
    a = gpu("enc", [BANG, atl, pic, pic], (W, H))
    check("enc Darker, not yet wetted, no background: the output is the input (US3.4), within the log round trip", mx(a[..., :3], pic[..., :3]), 1e-3)
    a, th = gpu("enc", [BANG, to_atlas(random_state(13), 3.0), pic, pic], (W, H), outs=True, bypass_gate=1.0)[:2]
    check("enc bypass: outlet 1 is the picture", mx(a, pic), 0.0)
    check("enc bypass: outlet 2 is the picture too", mx(th, pic), 0.0)


# ----------------------------------------------------------------- the chain

def test_chain_fed_still_picture_converges_like_the_mirror():
    """Host-sequenced: feed 0.2 and no press; the load stage then transport and react, 30 steps, on a flat frame, against the mirror."""
    pic = picture(16, 0.15, 0.95)
    z = np.zeros((H, W, 4), F32)
    z[..., 3] = 1
    pa = prep_gpu(z, z, src_terrain=0.0, src_field=0.0)
    atl = to_atlas(em.new_state(H, W), 0.0)
    st = em.new_state(H, W)
    for i in range(30):
        atl = gpu("load", [atl, pic], (W, 2 * H), feed=0.2)
        atl = gpu("transport", [atl, pa], (W, 2 * H), dry=0.004)
        atl = gpu("react", [atl, pa], (W, 2 * H))
        st = em.step(em.feed(st, pic, "darker", 0.2), None, None, edge="open", dry=0.004, k=KR)
    check("fed chain, 30 steps: water vs the mirror", mx(atl[:H, :, 0], st["w"]), TOL_CHAIN)
    check("fed chain: paper pigment vs the mirror", mx(atl[H:, :, :3], st["p"]), TOL_CHAIN)
    pig = em.pigment_from_picture(pic, "darker")
    check("fed chain: the paper has converged on the picture (shortfall under 2e-3 of its peak (0.8 ** 30 is 1.2e-3))", mx(atl[H:, :, :3], pig) / float(pig.max()), 2e-3)


def test_chain_dark_then_light_picture_is_followed():
    """Host-sequenced, flat frame, feed 0.2 and fade 0.1: a dark picture for 40 steps, then a light one for 60, against the mirror;
    the paper must come back UP to the light picture (the black-out Fade exists to prevent)."""
    a, b = picture(18, 0.1, 0.5), picture(19, 0.6, 0.95)
    z = np.zeros((H, W, 4), F32)
    z[..., 3] = 1
    pa = prep_gpu(z, z, src_terrain=0.0, src_field=0.0)
    atl = to_atlas(em.new_state(H, W), 0.0)
    st = em.new_state(H, W)
    for i in range(100):
        pic = a if i < 40 else b
        atl = gpu("load", [atl, pic], (W, 2 * H), feed=0.2, fade=0.1)
        atl = gpu("transport", [atl, pa], (W, 2 * H), dry=0.004)
        atl = gpu("react", [atl, pa], (W, 2 * H))
        st = em.step(em.feed(st, pic, "darker", 0.2, fade=0.1), None, None, edge="open", dry=0.004, k=KR)
    check("dark then light chain, 100 steps: paper pigment vs the mirror", mx(atl[H:, :, :3], st["p"]), TOL_CHAIN)
    pb = em.pigment_from_picture(b, "darker")
    check("the paper has followed the light picture up (shortfall under 3e-3 of the dark peak)", mx(atl[H:, :, :3], pb) / float(em.pigment_from_picture(a, "darker").max()), 3e-3)


def test_chain_load_then_ten_steps_matches_the_mirror():
    """Host-sequenced: prep once, load once, then transport and react ten times, each job fed the last job's atlas."""
    terrain, field = textures(14)
    T, F = em.terrain_height(terrain), em.field_uv(field)
    pic = picture(14, 0.15, 0.95)
    kw = dict(flow=0.6, speed=1.2, lift=0.7, settle=0.19, dry=0.0016)          # DIAL values for the GPU; the mirror takes the curves
    pa = prep_gpu(terrain, field, push=1.5, flow=kw["flow"], speed=kw["speed"])
    atl = gpu("load", [to_atlas(em.new_state(H, W), 0.0), pic], (W, 2 * H), wet_gate=1.0, flood=1.0)
    st = em.load(em.new_state(H, W), pic, "darker", flood=1.0)
    for i in range(10):
        atl = gpu("transport", [atl, pa], (W, 2 * H), flow=kw["flow"], speed=kw["speed"], dry=kw["dry"])
        atl = gpu("react", [atl, pa], (W, 2 * H), flow=kw["flow"], speed=kw["speed"], lift=kw["lift"], settle=kw["settle"])
        st = em.step(st, T, F, push=1.5, edge="open", **dict(kw, lift=em.lift_from_dial(kw["lift"]), settle=em.settle_from_dial(kw["settle"])), k=KR)
    check("chain, 10 steps: water vs the mirror", mx(atl[:H, :, 0], st["w"]), TOL_CHAIN)
    check("chain, 10 steps: suspension", mx(atl[:H, :, 1:4], st["s"]), TOL_CHAIN)
    check("chain, 10 steps: paper pigment", mx(atl[H:, :, :3], st["p"]), TOL_CHAIN)
    tot = lambda a: a[:H, :, 1:4].sum(axis=(0, 1), dtype=np.float64) + a[H:, :, :3].sum(axis=(0, 1), dtype=np.float64)
    note("pigment per channel in the frame after 10 steps, GPU vs mirror (the open edge lets some out)", f"{tot(atl)} vs {em.totals(st)}")


if __name__ == "__main__":
    sys.exit(run(globals()))
