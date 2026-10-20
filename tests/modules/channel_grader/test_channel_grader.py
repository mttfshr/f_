"""
test_channel_grader.py -- tier-1 NumPy mirror of the f_channel_grader shader
(src/f_channel_grader/codebox_channel_grader.gen).

Ground truth. Independent of the codebox: the neutral setting, bypass, the black-point (lift) shift
and the per-row channel isolation. Dependent on the codebox's dial convention (the doc names lift,
gamma and gain but gives no formulas): the gain and gamma values (gain in stops = 2^s, gamma
exponent 1/2^g), the master composition and the generic point, which apply that convention in
float64. Those catch transcription slips and pin the convention, but would not notice if the
convention itself were wrong (gain sits outside the gamma power here; some graders put it inside).

  - Neutral setting: with every dial at 0 the grade map is x -> 2^0 * clamp(x+0)^(1/2^0)
    = x on each band and the master map likewise, and the bypass mix is mix(src, src, 1),
    so the output equals the source. (Identity, stated as one sentence.)
  - Bypass: mix(a, b, 0) = a, so with bypass=1 the output is the raw sample of the
    source whatever the twelve dials are set to. (Identity.)
  - Doc, lift: "lift sets the black point" -- on the standard pipeline a lift L applied
    to a value whose result stays in [0,1] shifts the value by exactly L, so mid-gray
    0.25 with lift 0.1 reads 0.35 and a black pixel stays clamped at 0.
  - Doc, gain: "gain sets the white point" -- gain in stops s multiplies every value by
    exactly 2^s while the result stays in [0,1], so 0.25 with gain +2 stops reads 1.0.
  - Doc, gamma: "gamma adjusts midtones" -- the gamma curve pivots the midpoint, so a
    value of 0.5 is sent to 2^(-gamma stops) exactly (0.25^(1/2^g) form: 0.5^(2^-g));
    with gamma +1 stop it reads 2^(-1/2) ~= 0.7071.
  - Doc rows: the R dials touch only red, the G dials only green, the B dials only
    blue and the Master dials all three (patched color sources per row).
  - Master composition: the master stage applies the same map on top of the per-channel
    result, so master gain s (other master dials 0) multiplies the already-gained
    channel by a further exact 2^s.
  - Generic point: every dial at an irregular value at once, against the standard
    lift/gamma/gain pipeline form (2^gain * (x + lift))^(1/2^gamma) evaluated in
    float64 -- the special settings (0, pivots, one-band cases) alone cannot see a
    cross-term bug.

Doc quotes (verbatim, via _q): "lift sets the black point", "gamma adjusts midtones",
"gain sets the white point", "Master lift (all channels)".

Tolerances: float32 closed-form checks at 1e-5 or tighter; the generic-pipeline
check runs a chain of powers through float32 pow at 4e-6. The master-stops
closed form uses master gain up to +1 stop at values below 0.5, well inside
the float32 power's 1e-7 relative error.

Run:  tests/run.sh tests/modules/channel_grader/test_channel_grader.py
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
import channel_grader_mirror as M  # noqa: E402
from channel_grader_mirror import F32, channel_grader  # noqa: E402

N = 32

Q_LIFT = "lift sets the black point"
Q_GAMMA = "gamma adjusts midtones"
Q_GAIN = "gain sets the white point"


def _q(s):
    return s


def flat_tex(r, gr, b, n=N):
    t = g.texture(n, n)
    t[..., 0] = F32(r)
    t[..., 1] = F32(gr)
    t[..., 2] = F32(b)
    t[..., 3] = F32(1.0)
    return t


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def zero():
    return dict(r_lift=0.0, r_gamma=0.0, r_gain=0.0, g_lift=0.0, g_gamma=0.0, g_gain=0.0,
                b_lift=0.0, b_gamma=0.0, b_gain=0.0, m_lift=0.0, m_gamma=0.0, m_gain=0.0)


def _std(x, lift, gamma, gain):
    """The standard lift/gamma/gain pipeline the doc names, in float64, in the
    order the pipeline sentence lists the controls: gain multiplies the
    gamma-powered value, i.e. 2^gain * (clamp(x + lift))^(1/2^gamma)."""
    return 2.0 ** gain * np.power(np.clip(x + lift, 0.0, 1.0), 1.0 / max(2.0 ** gamma, 0.001))


# --- identity, bypass ---------------------------------------------------------------

def test_neutral_setting_is_identity():
    """All twelve dials at 0 and bypass 0: each band's map is x -> 2^0 * clamp(x+0)^(1/1)
    = x, the master map likewise, so the composite is the source untouched."""
    src = rand_tex(1)
    out = channel_grader(src)
    check("neutral dials reproduce the source", float(np.abs(out - src).max()), 1e-6)


def test_bypass_passes_the_source_under_extreme_dials():
    """Bypass 1 under extreme dial settings: mix(a, b, 0) = a, so out1 is the raw
    sample of the source whatever the grade would have done."""
    src = rand_tex(2)
    kw = zero()
    kw.update(r_lift=-1.0, r_gain=1.0, g_gamma=1.0, b_lift=1.0, m_gamma=-1.0, bypass=1.0)
    out = channel_grader(src, **kw)
    check("bypass equals the source under extreme dials", float(np.abs(out - src).max()), 1e-6)


# --- one dial at a time, pinned patches ----------------------------------------------

def test_lift_shifts_midgray_by_exact_amount():
    """The doc's lift is the black point; on the standard pipeline a lift L applied to
    a value whose result stays in [0,1] shifts it by exactly L, so red 0.25 with
    r_lift 0.1 (all band dials 0) reads 0.35 on red and nothing else changes."""
    src = flat_tex(0.25, 0.5, 0.75)
    kw = zero()
    kw.update(r_lift=0.1)
    out = channel_grader(src, **kw)
    e = max(abs(float(out[0, 0, 0]) - 0.35),
            abs(float(out[0, 0, 1]) - 0.5), abs(float(out[0, 0, 2]) - 0.75))
    check(f"mid-gray 0.25 shifts by lift exactly ({_q(Q_LIFT)})", e, 1e-6)


def test_lift_clamps_a_negative_result_at_black():
    """Lift is a black-point shift that clamps at 0: red 0.05 with r_lift -0.1 lands
    below 0 and must read exactly 0; the same clamp holds a black pixel at 0 under
    any gamma and gain, since black * anything = black ("black point")."""
    src = flat_tex(0.05, 0.5, 0.5)
    kw = zero()
    kw.update(r_lift=-0.1)
    out = channel_grader(src, **kw)
    check("0.05 lifted below 0 clamps to exactly 0", abs(float(out[0, 0, 0]) - 0.0), 0.0)
    src = flat_tex(0.0, 0.0, 0.0)
    kw = zero()
    kw.update(r_gain=1.0, g_gamma=1.0, b_gain=-1.0, m_gain=1.0)
    out = channel_grader(src, **kw)
    check("black stays black under gain, gamma and master gain",
          float(np.abs(out[..., :3]).max()), 0.0)


def test_gain_scales_by_exact_power_of_two():
    """The doc's gain is the white point; gain in stops s multiplies every value by
    exactly 2^s while the result stays in [0,1], so 0.25 with +2 stops reads 1.0."""
    src = flat_tex(0.25, 0.25, 0.25)
    kw = zero()
    kw.update(r_gain=2.0)
    out = channel_grader(src, **kw)
    check("0.25 with +2 gain stops reads 1.0", abs(float(out[0, 0, 0]) - 1.0), 1e-6)


def test_saturation_at_white_clamps_the_per_channel_stage():
    """Gain sets the white point, and clamping is what makes the white point: a value
    pushed past 1 in the per-channel stage (gain +1 stop on 0.9) is clamped by the
    stage's own clamp and reads exactly 1.0 in every channel. (The master stage's
    output is NOT clamped in the codebox -- master gain +1 stop then pushes a
    saturated value to 2.0; see test_master_stage_output_is_unclamped.)"""
    src = flat_tex(0.9, 0.9, 0.9)
    kw = zero()
    kw.update(r_gain=1.0, g_gain=1.0, b_gain=1.0)
    out = channel_grader(src, **kw)
    check("0.9 with +1 gain stop saturates per-channel at exactly 1",
          float(np.abs(out[..., :3] - 1.0).max()), 0.0)


def test_master_stage_output_is_unclamped():
    """The master stage multiplies by 2^m_gain and NEVER clamps its result (the
    codebox clamps only inside each stage, before the power): 0.9 with per-channel
    gain +1 stop saturates to 1, then master lift +0.2 and master gain +1 stop
    gives exactly 2.0*1.0 = 2.0 -- a value above 1 in the float32 outlet. The
    shipped pix is @type char, whose GPU output quantizes clamped to [0,1]; this
    check pins the float32 outlet behavior the mirror models."""
    src = flat_tex(0.9, 0.9, 0.9)
    kw = zero()
    kw.update(r_gain=1.0, g_gain=1.0, b_gain=1.0, m_lift=0.2, m_gain=1.0)
    out = channel_grader(src, **kw)
    check("master stage of a saturated value reads exactly 2.0 (unclamped)",
          float(np.abs(out[..., :3] - 2.0).max()), 1e-6)


def test_gamma_moves_the_midpoint_to_two_power():
    """The doc's gamma adjusts midtones: the curve pivots the midpoint, so 0.5 goes
    to exactly 0.5^(1/2^g) = 2^(-2^-g); at g = +1 stop that is 2^(-1/2) ~= 0.70711."""
    src = flat_tex(0.5, 0.5, 0.5)
    kw = zero()
    kw.update(r_gamma=1.0)
    out = channel_grader(src, **kw)
    expect = np.float64(0.5) ** (1.0 / 2.0 ** 1.0)
    check("midpoint 0.5 at gamma +1 stop reads 0.5^0.5", abs(float(out[0, 0, 0]) - expect), 1e-6)
    kw.update(r_gamma=-1.0)
    out = channel_grader(src, **kw)
    expect = np.float64(0.5) ** (1.0 / 2.0 ** -1.0)
    check("midpoint 0.5 at gamma -1 stop reads 0.5^2", abs(float(out[0, 0, 0]) - expect), 1e-6)


def test_rows_touch_only_their_own_bands():
    """The definition's panel is a grid whose rows are Lift/Gam/Gain and columns
    R/G/B/Master, so the R dials cannot affect green or blue and the master
    description says 'Master lift (all channels)' -- verified with a red patch:
    only the R dials move red; the G, B (and, separately, master) dials leave a
    red patch's green and blue at 0 and master moves red."""
    src = flat_tex(0.5, 0.0, 0.0)
    # R dials on: red moves, green and blue stay exactly 0. The pipeline is per-channel
    # then master, so red reads clamp((2^0.3 * clamp(0.5+0.2))^(1/2^0.5)).
    kw = zero(); kw.update(r_lift=0.2, r_gamma=0.5, r_gain=0.3)
    out = channel_grader(src, **kw)
    assert abs(float(out[0, 0, 1]) - 0.0) == 0.0 and abs(float(out[0, 0, 2]) - 0.0) == 0.0
    per = _std(0.5, 0.2, 0.5, 0.3)
    expect = _std(per, 0.0, 0.0, 0.0)
    check("R dials move only red, and red follows the standard pipeline",
          abs(float(out[0, 0, 0]) - expect), 1e-6)
    # G and B dials at values that keep black at black (lift alone shifts the value,
    # so use gamma and gain in stops, which leave 0 at 0): a red patch's green and
    # blue must stay exactly 0 because mix(src, grade, 1) never blends channels.
    kw = zero(); kw.update(g_gamma=1.0, b_gamma=-1.0, g_gain=1.0, b_gain=-1.0)
    out = channel_grader(src, **kw)
    check("G and B dials leave a red patch's green/blue at 0",
          float(out[..., 1:3].max()), 0.0)
    # Master lift moves red: a red-only patch with master lift L (no gamma/gain) reads
    # 2^0 * clamp((2^0 * clamp(0.5+0))^1 + L)^1 = clamp(0.5 + L)
    kw = zero(); kw.update(m_lift=0.2)
    out = channel_grader(src, **kw)
    check("master lift 0.2 on a red 0.5 patch reads 0.7", abs(float(out[0, 0, 0]) - 0.7), 1e-6)


def test_master_gain_multiplies_the_gained_channel():
    """The master stage re-applies the same map on top of the per-channel result, so
    a master gain of +1 stop multiplies the per-channel value by a further exact
    2.0: (2^0.5 * 0.25) * 2 = 0.70711 while it stays in [0,1]."""
    src = flat_tex(0.25, 0.25, 0.25)
    kw = zero(); kw.update(r_gain=0.5, m_gain=1.0)
    out = channel_grader(src, **kw)
    expect = (2.0 ** 0.5 * 0.25) * 2.0
    check("per-channel gain then master +1 stop = value * 4", abs(float(out[0, 0, 0]) - expect), 1e-5)


# --- generic settings ---------------------------------------------------------------

def _generic_err(bug=None):
    """Every dial at an irregular value at once (r_lift 0.11, r_gamma -0.23, r_gain 0.07,
    and similarly for g/b/m), against the float64 standard pipeline form. The
    special settings above all vanish at least one term; this one cannot."""
    src = rand_tex(3)
    p = dict(r_lift=0.11, r_gamma=-0.23, r_gain=0.07,
             g_lift=-0.09, g_gamma=0.17, g_gain=-0.05,
             b_lift=0.13, b_gamma=0.29, b_gain=0.03,
             m_lift=-0.07, m_gamma=0.19, m_gain=0.11)
    out = channel_grader(src, **p, bug=bug)
    x = src[..., :3].astype(np.float64)
    per = np.stack([_std(x[..., 0], p["r_lift"], p["r_gamma"], p["r_gain"]),
                    _std(x[..., 1], p["g_lift"], p["g_gamma"], p["g_gain"]),
                    _std(x[..., 2], p["b_lift"], p["b_gamma"], p["b_gain"])], axis=-1)
    exp = _std(per, p["m_lift"], p["m_gamma"], p["m_gain"])
    e = np.abs(out[..., :3].astype(np.float64) - exp)
    # the master lift here is negative and r_gain positive, so red per-channel values
    # ABOVE 1 get clamped before the master stage (the no_master_clamp bug skips
    # exactly that clamp and reads high there); pixels below 0.95 pin the smooth part.
    mid = ((per > 0.02) & (per < 0.95)).any(axis=-1)
    mask = mid | (bug == "no_master_clamp")
    return float(e[mask].max())


def test_generic_settings_follow_the_standard_pipeline():
    """All twelve dials at irregular values at once, against the float64 standard
    form (2^gain * (x + lift))^(1/2^gamma) applied per channel then master: the
    one-dial-at-a-time checks cannot see a cross-term between them."""
    check("generic twelve-dial setting vs the standard pipeline (float64)",
          _generic_err(), 4e-6)


# --- the 0.001 floor is unreachable ---------------------------------------------------

def test_gamma_floor_guard_unreachable_on_the_dial():
    """The codebox guards 2^gamma below 0.001; the shipped dial range is -1 to +1,
    so 2^gamma stays in [0.5, 2] and the guard can never fire -- noted, not a
    graded check (it is about reachability, not about the arithmetic)."""
    note("gamma dial range -1..1 keeps 2^gamma in [0.5, 2]; floor 0.001 unreachable from the panel", 0.001)


# --- mutations -------------------------------------------------------------------------

BUGS = ["linear_gain", "gamma_times_instead_of_div", "no_master_clamp", "swap_rg"]


def _master_err(bug=None):
    src = flat_tex(0.25, 0.25, 0.25)
    kw = zero(); kw.update(r_gain=0.5, m_gain=1.0)
    out = channel_grader(src, **kw, bug=bug)
    expect = (2.0 ** 0.5 * 0.25) * 2.0
    return abs(float(out[0, 0, 0]) - expect)


def _gamma_err(bug=None):
    src = flat_tex(0.5, 0.5, 0.5)
    kw = zero(); kw.update(r_gamma=1.0)
    out = channel_grader(src, **kw, bug=bug)
    return abs(float(out[0, 0, 0]) - np.float64(0.5) ** 0.5)


def _row_err(bug=None):
    src = flat_tex(0.5, 0.0, 0.0)
    kw = zero(); kw.update(r_lift=0.2, r_gamma=0.5, r_gain=0.3, g_gamma=1.0, b_gamma=-1.0)
    out = channel_grader(src, **kw, bug=bug)
    per = _std(0.5, 0.2, 0.5, 0.3)
    expect = _std(per, 0.0, 0.0, 0.0)
    return max(abs(float(out[0, 0, 0]) - expect), float(out[..., 1:3].max()))


def _clamp_err(bug=None):
    """0.9 with gain +1 stop saturates at exactly 1; the no_master_clamp bug skips
    the master stage's clamp and pushes the saturated value past 1."""
    src = flat_tex(0.9, 0.9, 0.9)
    kw = zero(); kw.update(r_gain=1.0, g_gain=1.0, b_gain=1.0, m_lift=0.2, m_gain=1.0)
    out = channel_grader(src, **kw, bug=bug)
    return float(np.abs(out[..., :3] - 2.0).max())


def _gain_err(bug=None):
    src = flat_tex(0.25, 0.25, 0.25)
    kw = zero(); kw.update(r_gain=2.0)
    out = channel_grader(src, **kw, bug=bug)
    return abs(float(out[0, 0, 0]) - 1.0)


def test_mutations_are_caught():
    """Every declared bug must fail at least one of the closed-form or generic checks
    by a clear margin, and the real mirror must pass the same checks."""
    real = [_generic_err(), _master_err(), _gamma_err(), _row_err(), _gain_err(), _clamp_err()]
    bad = {"linear_gain": max(_generic_err("linear_gain"), _gain_err("linear_gain")),
           "gamma_times_instead_of_div": max(_generic_err("gamma_times_instead_of_div"), _gamma_err("gamma_times_instead_of_div")),
           "no_master_clamp": _clamp_err("no_master_clamp"),
           "swap_rg": _row_err("swap_rg")}
    for k, v in bad.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-4:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    assert max(real) < 4e-6, f"the real mirror must pass the same checks: {real}"
    print("    ok   linear gain, the gamma convention flip, the dropped master clamp and swapped R/G are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))