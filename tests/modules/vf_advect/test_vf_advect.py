"""
test_vf_advect.py -- tier-1 NumPy mirror of the f_vf_advect advect stage (src/f_vf_advect/codebox_advect.gen;
.specify/f_vf_advect/tasks.md T147, decided 2026-10-19: tier 1 applies, build the mirror).

The ground truth is independent of the mirror: closed forms derived on paper, not the recurrence run twice.

  - Equilibrium of the feedback loop at zero flow: x* = s * injection / (1 - decay), clamped at 1 (the
    reference doc's "approximately injection / (1 - decay)" for a unit source), per channel including alpha.
  - Pure decay with no injection: x(k) = a * decay^k.
  - Fixed point with gain and wet/dry, unclamped regime:
        x = (1 - m) s + m g (d x + i s)   =>   x* = s ((1 - m) + m g i) / (1 - m g d)
  - Backward displacement of a linear ramp (bilinear sampling is exact on ramps): out = decay * ramp(uv - f dt).
  - Whole-pixel shifts by index arithmetic (dt chosen so f dt = k / width exactly): out = decay * shifted prev.
  - Unconnected vecfield (src_vecfield = 0 over vs_black's zeros) means zero flow, not a pull toward a corner.
  - Bypass passes the source on out1 and out2 and the vecfield (or neutral 0.5) on out3, and the loop then
    carries the source.
  - Outlet 3 on a luma ramp: gx = slope * 2 * 0.004 * 4, with the sign of the +x / +y taps pinned.
  - Trail (2026-10-28): a half-life in frames; exact half after `trail` frames of pure decay; the settled level of a
    static source is s * injection / 0.03 whatever the trail length; trail below 1 is the classic loop bit for bit.
  - Mutations the tests must catch: forward displacement, ignoring src_vecfield, dropping the clamp, clamping the
    advect UV to exact 0 / 1 instead of the texel-safe 0.001 / 0.999, and a trail without the injection rescale.

Scope and limits: advect stage only; the loop's pass stage is modeled as the identity (separate = 0). Edge rows
of outlet 3 are not tested (the bench GPU wraps out-of-range taps; clamp-to-edge here). Alpha follows the same
recurrence as color (the gen's vec4 arithmetic), so an opaque source settles at alpha = injection / (1 - decay),
not 1 -- noted below, to be confirmed or dismissed on the GPU by a tier-2 bench.

Run:  tests/run.sh tests/modules/vf_advect/test_vf_advect.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_advect_mirror import F32, advect_stage, run_frames  # noqa: E402

SMALL = 8     # uniform-content tests: spatial size does not matter
MID = 32      # spatial tests


def const_tex(rgba, n=SMALL):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def vec_tex(fx, fy, n=SMALL):
    """Vecfield texture whose decoded flow is (fx, fy): R,G = 0.5 + f / 2 (exact for dyadic values)."""
    return const_tex((0.5 + fx / 2.0, 0.5 + fy / 2.0, 0.5, 1.0), n)


def rand_tex(seed, n=MID):
    return np.random.default_rng(seed).random((n, n, 4)).astype(F32)


# --- equilibrium and decay -------------------------------------------------------

def test_equilibrium_matches_closed_form():
    src = (0.8, 0.5, 0.2, 1.0)
    worst = 0.0
    for decay, inj, frames in [(0.97, 0.02, 700), (0.9, 0.05, 300), (0.5, 0.1, 80), (0.97, 0.2, 700)]:
        out = run_frames(const_tex(src), vec_tex(0.0, 0.0), frames, decay=decay, injection=inj)[-1]
        expect = np.minimum(np.array(src, np.float64) * inj / (1.0 - decay), 1.0)
        err = float(np.abs(out - expect.astype(F32)).max())
        note(f"equilibrium decay={decay} inject={inj} worst error", err)
        worst = max(worst, err)
    check("equilibrium vs s*inj/(1-decay), clamped", worst, 2e-6)
    defaults = run_frames(const_tex(src), vec_tex(0.0, 0.0), 700)[-1][0, 0]
    note("alpha at the defaults after 700 frames (opaque source)", float(defaults[3]))


def test_pure_decay_is_a_power():
    a = np.array([0.9, 0.6, 0.3, 1.0], F32)
    init = const_tex(a)
    out = run_frames(const_tex((0, 0, 0, 0)), vec_tex(0.0, 0.0), 40, init=init, decay=0.9, injection=0.0)[-1]
    expect = (a.astype(np.float64) * 0.9 ** 40).astype(F32)
    check("40 frames of decay vs a * 0.9^40", float(np.abs(out[0, 0] - expect).max()), 1e-6)


def test_gain_mix_fixed_point():
    s = np.array([0.6, 0.4, 0.2, 1.0], np.float64)
    gn, m, d, i = 0.5, 0.6, 0.9, 0.05
    x_star = s * ((1 - m) + m * gn * i) / (1 - m * gn * d)
    assert (x_star * gn <= 1.0).all() and (d * x_star + i * s <= 1.0).all(), "test left the unclamped regime"
    out = run_frames(const_tex(s.astype(F32)), vec_tex(0.0, 0.0), 120,
                     decay=d, injection=i, gain=gn, mix_pct=100 * m)[-1]
    check("fixed point with gain 0.5 and mix 60%", float(np.abs(out[0, 0] - x_star.astype(F32)).max()), 2e-6)
    wet0 = run_frames(const_tex(s.astype(F32)), vec_tex(0.0, 0.0), 1, mix_pct=0.0)[0]
    check("mix 0% returns the source", float(np.abs(wet0 - const_tex(s.astype(F32))).max()), 1e-6)


# --- displacement ------------------------------------------------------------------

def _ramp_prev(n=MID):
    u, v, _, _ = g.grid(n, n)
    prev = g.texture(n, n)
    prev[..., 0] = F32(0.2) + F32(0.5) * u
    prev[..., 1] = F32(0.1) + F32(0.4) * v
    prev[..., 2] = F32(0.3) + F32(0.2) * u
    prev[..., 3] = F32(0.6) + F32(0.2) * u
    return prev, u, v


def _translation_err(bug=None):
    """Worst error of out1 against decay * ramp(uv - f dt) where the lookup stays inside the ramp."""
    fx, fy, dt, decay = 0.8, -0.6, 0.0625, 0.97
    prev, u, v = _ramp_prev()
    out1, _, _ = advect_stage(g.texture(MID, MID), vec_tex(fx, fy, MID), prev, dt=dt, decay=decay,
                              injection=0.0, bug=bug)
    su, sv = u - fx * dt, v - fy * dt
    inside = (su >= 0.5 / MID) & (su <= 1 - 0.5 / MID) & (sv >= 0.5 / MID) & (sv <= 1 - 0.5 / MID)
    assert inside.sum() > MID * MID // 2, "too little of the frame left to compare"
    expect = np.zeros_like(out1, np.float64)
    expect[..., 0] = decay * (0.2 + 0.5 * su)
    expect[..., 1] = decay * (0.1 + 0.4 * sv)
    expect[..., 2] = decay * (0.3 + 0.2 * su)
    expect[..., 3] = decay * (0.6 + 0.2 * su)
    return float(np.abs(out1 - expect.astype(F32))[inside].max())


def test_backward_displacement_of_a_ramp():
    check("ramp lookup at uv - f*dt (inside the frame)", _translation_err(), 1e-6)


def _whole_pixel_err(bug=None):
    n, decay = MID, 0.97
    prev = rand_tex(11)
    idx = np.arange(n)
    dt = 3.0 / n                                     # f dt = 3 / n for |f| = 1, exactly representable
    cases = {"+x": (1.0, 0.0), "+y": (0.0, 1.0), "diag": (1.0, -1.0)}
    worst = 0.0
    for name, (fx, fy) in cases.items():
        out1, _, _ = advect_stage(g.texture(n, n), vec_tex(fx, fy, n), prev, dt=dt, decay=decay, injection=0.0, bug=bug)
        # The codebox clamps src_uv to [0.001, 0.999] (texel-safe, 2026-10-20), so a read that leaves the frame lands in
        # its OWN edge texel on all four edges. (With exact 0 / 1 bounds the GPU read the opposite edge for x = 1.0 and
        # y = 0.0, probe P9; that is the "exact_clamp" mutation.)
        sx, sy = int(round(fx * 3)), int(round(fy * 3))
        xi = np.clip(idx - sx, 0, n - 1)
        yi = np.clip(idx - sy, 0, n - 1)
        expect = prev[np.ix_(yi, xi)] * F32(decay)
        err = float(np.abs(out1 - expect).max())
        if bug is None:
            note(f"whole-pixel shift {name} error", err)
        worst = max(worst, err)
    return worst


def test_whole_pixel_shifts_are_exact():
    check("shift by 3 texels vs index arithmetic (all four edges clamp to their own edge)", _whole_pixel_err(), 1e-6)


# --- unconnected vecfield, bypass, range --------------------------------------------

def _unconnected_err(bug=None):
    """vs_black (all zeros) over an unconnected inlet must mean zero flow."""
    prev, src, decay, inj = rand_tex(3), rand_tex(4), 0.9, 0.05
    out1, _, _ = advect_stage(src, g.texture(MID, MID), prev, decay=decay, injection=inj,
                              src_vecfield=0.0, bug=bug)
    expect = np.clip(prev * F32(decay) + src * F32(inj), 0, 1)
    return float(np.abs(out1 - expect).max())


def test_unconnected_vecfield_means_zero_flow():
    check("src_vecfield=0 over zeros vs the zero-flow closed form", _unconnected_err(), 1e-6)
    prev, src = rand_tex(5), rand_tex(6)
    a, _, _ = advect_stage(src, vec_tex(0.0, 0.0, MID), prev, src_vecfield=1.0)
    b, _, _ = advect_stage(src, g.texture(MID, MID), prev, src_vecfield=0.0)
    check("neutral connected field equals unconnected", float(np.abs(a - b).max()), 1e-7)


def test_bypass_outlets_and_loop():
    src, prev, vec = rand_tex(7), rand_tex(8), rand_tex(9)
    o1, o2, o3 = advect_stage(src, vec, prev, bypass_gate=1.0, gain=2.0, mix_pct=30.0)
    check("bypass out1 equals the source", float(np.abs(o1 - src).max()), 1e-6)
    check("bypass out2 equals the source", float(np.abs(o2 - src).max()), 1e-6)
    expect3 = np.stack([vec[..., 0], vec[..., 1], np.full(vec.shape[:2], 0.5, F32),
                        np.ones(vec.shape[:2], F32)], axis=-1)
    check("bypass out3 equals the vecfield (R,G; B=0.5; A=1)", float(np.abs(o3 - expect3).max()), 1e-6)
    _, _, o3u = advect_stage(src, vec, prev, bypass_gate=1.0, src_vecfield=0.0)
    neutral = np.broadcast_to(np.array([0.5, 0.5, 0.5, 1.0], F32), o3u.shape)
    check("bypass out3 unconnected is neutral 0.5", float(np.abs(o3u - neutral).max()), 1e-6)
    first = run_frames(src, vec, 1, init=prev, bypass_gate=1.0)[0]
    check("bypassed loop carries the source after one frame", float(np.abs(first - src).max()), 1e-6)


def _clamp_excess(bug=None):
    """Largest amount out2 (the advected result before the mix) exceeds 1 in an excitable setup."""
    prev = const_tex((0.9, 0.9, 0.9, 0.9))
    out = prev
    top = 0.0
    for _ in range(30):
        _, o2, _ = advect_stage(const_tex((0.5, 0.5, 0.5, 0.5)), vec_tex(0.0, 0.0), out,
                                decay=1.4, injection=0.2, bug=bug)
        top = max(top, float(o2.max()) - 1.0)
        out = o2
    return top


def test_excitable_regime_saturates_inside_the_range():
    frames = run_frames(const_tex((0.5, 0.5, 0.5, 0.5)), vec_tex(0.0, 0.0), 60, decay=1.2, injection=0.02)
    lo = min(float(f.min()) for f in frames)
    hi = max(float(f.max()) for f in frames)
    check("excitable run stays at or below 1", max(hi - 1.0, 0.0), 0.0)
    check("excitable run stays at or above 0", max(-lo, 0.0), 0.0)
    check("decay 1.2 saturates to exactly 1", float(abs(frames[-1] - 1.0).max()), 0.0)
    check("out2 never exceeds 1 with the clamp", max(_clamp_excess(), 0.0), 0.0)


# --- outlet 3: gradient of the accumulated flow -------------------------------------

def _gradient_case(axis, a, b, n=64):
    u, v, _, _ = g.grid(n, n)
    coord = u if axis == 0 else v
    prev = g.texture(n, n)
    prev[..., :3] = (F32(a) + F32(b) * coord)[..., None]
    prev[..., 3] = F32(1)
    _, _, o3 = advect_stage(g.texture(n, n), vec_tex(0.0, 0.0, n), prev)
    pad = 0.5 / n + 0.004 + 1e-3
    inside = (coord >= pad) & (coord <= 1 - pad)
    slope = b * 2 * 0.004 * 4
    expect = np.array([0.5, 0.5, 0.5, 1.0], np.float64)
    expect[axis] = np.clip(slope * 0.5 + 0.5, 0, 1)
    got = o3[inside]
    return float(np.abs(got - expect.astype(F32)).max()), float(o3[inside][:, axis].mean())


def test_gradient_outlet_on_ramps():
    ex, mx = _gradient_case(0, 0.2, 0.5)
    ey, my = _gradient_case(1, 0.1, 0.3)
    note("outlet 3 mean R on the +x ramp (expect 0.508)", mx)
    note("outlet 3 mean G on the +y ramp (expect 0.5048)", my)
    check("outlet 3 on an x luma ramp", ex, 2e-6)
    check("outlet 3 on a y luma ramp", ey, 2e-6)


# --- mutations ------------------------------------------------------------------------

# --- trail (2026-10-28): persistence as a half-life, density independent of it ----------------------------

def test_trail_half_life_is_exact():
    a = np.array([0.9, 0.6, 0.3, 1.0], F32)
    worst = 0.0
    for t in (20, 69, 200):
        out = run_frames(const_tex((0, 0, 0, 0)), vec_tex(0.0, 0.0), t, init=const_tex(a), trail=float(t),
                         decay=1.0, injection=0.0)[-1]
        worst = max(worst, float(np.abs(out[0, 0] - a * F32(0.5)).max()))
    check("at Decay 1.0, after `trail` frames of pure decay the field is exactly half (trails 20, 69, 200)", worst, 5e-5)


def test_decay_scales_the_trail_half_life_on_a_log_curve():
    a = np.array([0.9, 0.6, 0.3, 1.0], F32)
    worst = 0.0
    # (decay, trail) -> expected half-life trail * exp((decay - 1) * 20), clamped to [1, 1000]
    for decay, trail in [(0.97, 100.0), (1.03, 100.0), (0.9, 300.0), (1.5, 300.0), (0.8, 50.0)]:
        hl = min(max(trail * np.exp((decay - 1.0) * 20.0), 1.0), 1000.0)
        frames = int(round(hl))
        out = run_frames(const_tex((0, 0, 0, 0)), vec_tex(0.0, 0.0), frames, init=const_tex(a), trail=trail,
                         decay=decay, injection=0.0)[-1]
        want = a.astype(np.float64) * 0.5 ** (frames / hl)
        err = float(np.abs(out[0, 0] - want.astype(F32)).max())
        note(f"decay {decay} trail {trail:g}: half-life {hl:.1f} frames, worst error", err)
        worst = max(worst, err)
    check("Decay scales the half-life as trail*exp((decay-1)*20), clamped to [1, 1000]", worst, 5e-5)
    ratio = (0.5 ** (1 / 56.0))  # neutral check: Decay 1.0 leaves trail untouched
    same = run_frames(const_tex((0, 0, 0, 0)), vec_tex(0.0, 0.0), 10, init=const_tex(a), trail=56.0, decay=1.0,
                      injection=0.0)[-1][0, 0, 0]
    check("Decay 1.0 is neutral: per-frame factor 0.5^(1/trail)", abs(float(same) / 0.9 - ratio ** 10), 5e-6)


def test_trail_settled_level_does_not_depend_on_trail_length():
    src = np.array([0.8, 0.5, 0.2, 1.0], np.float64)
    want = src * 0.02 / 0.03
    worst = 0.0
    for t in (5, 23, 69, 200, 600):
        out = run_frames(const_tex(tuple(src)), vec_tex(0.0, 0.0), int(10 * t), trail=float(t))[-1]
        err = float(np.abs(out[0, 0] - want.astype(F32)).max())
        note(f"trail {t}: settled level worst error vs injection/0.03", err)
        worst = max(worst, err)
    check("settled level = source * injection / 0.03 whatever the trail (5..600 frames)", worst, 2e-3)


def test_trail_below_one_is_the_classic_loop():
    src, vec = rand_tex(3), vec_tex(0.2, -0.1, MID)
    classic = run_frames(src, vec, 30, decay=0.95, injection=0.04)[-1]
    for t in (0.0, 0.5, 0.999):
        got = run_frames(src, vec, 30, decay=0.95, injection=0.04, trail=t)[-1]
        check(f"trail {t:g}: identical to the classic loop", float(np.abs(got - classic).max()), 0.0)
    low = run_frames(src, vec, 30, decay=0.9, injection=0.04, trail=69.0)[-1]
    high = run_frames(src, vec, 30, decay=1.0, injection=0.04, trail=69.0)[-1]
    assert float(np.abs(low - high).max()) > 1e-3, "Decay must act on the trail half-life"
    print("    ok   with trail on, Decay scales the half-life (no longer ignored)")


def test_mutations_are_caught():
    def _trail_level_spread(bug=None):
        lv = []
        for t in (5, 69, 200):
            out = run_frames(const_tex((0.8, 0.5, 0.2, 1.0)), vec_tex(0.0, 0.0), 10 * t, trail=float(t), bug=bug)[-1]
            lv.append(float(out[0, 0, 0]))
        return max(lv) - min(lv)

    real = [_translation_err(), _unconnected_err(), max(_clamp_excess(), 0.0), _whole_pixel_err(), _trail_level_spread()]
    bad = {"sign_flip": _translation_err("sign_flip"),
           "no_suppress": _unconnected_err("no_suppress"),
           "no_clamp": _clamp_excess("no_clamp"),
           "exact_clamp": _whole_pixel_err("exact_clamp"),
           "no_normalize": _trail_level_spread("no_normalize")}
    for k, v in bad.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    assert max(real[:4]) < 1e-5 and real[4] < 2e-3, f"the real mirror must pass the same checks: {real}"
    print("    ok   forward displacement, ignored src_vecfield, a dropped clamp and exact 0 / 1 clamp bounds are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))
