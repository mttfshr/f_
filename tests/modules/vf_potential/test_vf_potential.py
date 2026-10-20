"""
test_vf_potential.py -- tier-1 NumPy mirror of the f_vf_potential shader
(src/f_vf_potential/codebox_potential.gen).

Ground truth is independent of the mirror:

  - Bypass: the doc says the module outputs the neutral color (0,0,0,1), not a passthrough.
  - Zero-field decay: with the field zero (or unconnected) and strength 1, src_color 0 the
    recurrence reduces to the geometric decay p_n = p_0 * decay^n (before the clamp).
  - Uniform field, uniform frame: backward advection is a no-op, so from p_0 = 0 the plain
    (strength 1, no colour) recurrence p_n = p_{n-1}*decay + m*dt gives the geometric series
    p_n = m*dt*(1 - decay^n)/(1 - decay), whose fixed point is m*dt/(1 - decay).
  - Clamps: the potential is clamped to [0, 1] each frame, so a previous frame at 1 with any
    non-negative accumulation still clamps to exactly 1; with strength > 1 the SCALED output
    can exceed 1 (doc: "so it can exceed 1").
  - Axis blindness (the doc's 2026-10-12 audit): the codebox integrates field MAGNITUDE only,
    so a field and its 180-degree flip produce identical output.
  - Feedback carries the tinted, strength-scaled output (the brief's known fact), so with
    strength s and src_color c the per-channel recurrence in the loop is
    p_n = clamp(p_{n-1} * s * tint_c * decay + m * dt), q_n = p_n * s * tint_c -- evaluated
    here in float64 as scalar algebra from that one-sentence identity.
  - Advection direction at a non-uniform frame: with field +x the codebox samples prev at
    uv - fx*dt, i.e. to the LEFT; at dt = 1 texel the bilinear read is exact and the check is
    index arithmetic in float64.

Scope and limits: only the .x channel of in4 is ever read (the g/b of the feedback are lost,
untested, per the scalar design); the char pixel type is not modelled.
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_potential_mirror import F32, potential_stage, run_frames  # noqa: E402

N = 32


def const_tex(rgba, n=N):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def vec_tex(fx, fy, n=N):
    """Vecfield texture whose decoded flow is (fx, fy): R,G = 0.5 + f / 2 (exact for dyadic values)."""
    return const_tex((0.5 + fx / 2.0, 0.5 + fy / 2.0, 0.5, 1.0), n)


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def _blank(n=N):
    return const_tex((0.5, 0.5, 0.5, 1.0), n)  # decodes to a zero field


# --- bypass and the plain recurrence -----------------------------------------------------

def test_bypass_outputs_neutral():
    """Doc: the module "outputs the neutral (0,0,0,1), not an input passthrough"."""
    vf, col, prev = rand_tex(1), rand_tex(2), rand_tex(3)
    out = potential_stage(vf, col, prev, dt=0.02, decay=0.9, strength=1.4,
                          src_vecfield=1.0, src_color=1.0, bypass=1.0)
    err = float(np.abs(out - const_tex((0, 0, 0, 1))).max())
    check("bypass equals neutral (0,0,0,1)", err, 0.0)


def test_uniform_field_plain_series():
    """Uniform field m=0.5, p_0 = 0, strength 1, no colour, uniform frame: backward advection
    is a no-op, so p_n = m*dt*(1 - decay^n)/(1 - decay) at n = 1, 5, 30."""
    m, dt, d = 0.5, 0.02, 0.9
    vf = vec_tex(m, 0.0)
    worst = 0.0
    for n in (1, 5, 30):
        out = run_frames(vf, _blank(), n, dt=dt, decay=d, strength=1.0, src_vecfield=1.0)
        expect = m * dt * (1 - d ** n) / (1 - d)
        worst = max(worst, abs(float(out[4, 4, 0]) - expect))
    check("potential vs m*dt*(1-decay^n)/(1-decay)", worst, 1e-5)


# --- decay with a zero field -------------------------------------------------------------

def test_zero_field_geometric_decay():
    """Uniform zero field, strength 1, src_color 0: each frame p_n = p_{n-1} * decay, so from
    p_0 = 0.8, p_n = 0.8 * decay^n at n = 1, 4, 12."""
    worst = 0.0
    for d in (0.98, 0.8):
        for n in (1, 4, 12):
            s2 = const_tex((0.8, 0, 0, 1))
            for _ in range(n):
                s2 = potential_stage(_blank(), _blank(), s2, decay=d)
            worst = max(worst, abs(float(s2[4, 4, 0]) - 0.8 * d ** n))
    check("zero field decays as p*decay^n", worst, 1e-5)


def test_decay_direction_matches_the_doc():
    """Doc, parameter table: 'Frame decay -- lower = faster fade, higher = longer memory'. With a zero field
    and a previous frame of 0.8, after 10 frames a LOWER decay must leave strictly less than a higher one,
    across 0.8 < 0.9 < 0.95 < 0.98 < 1.0 (every gap positive). This is the doc's directional statement, not
    the recurrence: a doc or codebox that swapped the direction would fail it."""
    vals = []
    for d in (0.8, 0.9, 0.95, 0.98, 1.0):
        s2 = const_tex((0.8, 0, 0, 1))
        for _ in range(10):
            s2 = potential_stage(_blank(), _blank(), s2, decay=d)
        vals.append(float(s2[4, 4, 0]))
    gaps = [b - a for a, b in zip(vals, vals[1:])]
    check("higher decay always leaves more after 10 frames (every gap positive)", max(0.0, 1e-3 - min(gaps)), 0.0)


def test_unconnected_field_accumulates_nothing():
    """src_vecfield 0 zeroes the field, so a real field texture contributes nothing: the value
    follows the zero-field decay of whatever the previous frame held (_blank's r = 0.5 here),
    p_1 = 0.5 * decay and p_6 = 0.5 * decay^6 after 6 frames."""
    d = 0.9
    out = potential_stage(vec_tex(0.5, 0.0), _blank(), _blank(), decay=d, src_vecfield=0.0)
    # run_frames starts from the zero texture (the first frame's previous value is 0), so the
    # field-less decay keeps it at exactly 0 afterwards
    out2 = run_frames(vec_tex(0.5, 0.0), _blank(), 6, decay=d, src_vecfield=0.0)
    err = max(_err_scalar(out, 0.5 * d), _err_scalar(out2, 0.0))
    check("unconnected field decays, accumulating nothing", err, 1e-5)


def test_src_vecfield_threshold_at_half():
    """step(0.5, src_vecfield) at the boundary: src_vecfield = 0.5 is connected (step is 1 at
    x = 0.5), so a real field accumulates m*dt; 0.49 is not, so the value stays 0."""
    out_conn = potential_stage(vec_tex(1.0, 0.0), _blank(), _blank(), decay=0.9, src_vecfield=0.5)
    out_off = potential_stage(vec_tex(1.0, 0.0), _blank(), _blank(), decay=0.9, src_vecfield=0.49)
    # with the field connected the frame-1 value is min(0.5*decay + m*dt) = 0.46; with it off
    # the field is zeroed, so the frame-1 value is the prev decayed: 0.5 * 0.9 = 0.45
    worst = max(_err_scalar(out_conn, 0.5 * 0.9 + 0.01), _err_scalar(out_off, 0.5 * 0.9))
    check("src_vecfield gate is step(0.5, x): connected at exactly 0.5", worst, 1e-5)


def test_fixed_point():
    """The fixed point of p*decay + m*dt is m*dt/(1-decay): after 300 frames (well past the
    settling horizon) the value sits on it."""
    m, dt, d = 0.7, 0.0125, 0.85
    fp = m * dt / (1 - d)
    out = run_frames(vec_tex(m, 0.0), _blank(), 300, dt=dt, decay=d, strength=1.0,
                     src_vecfield=1.0)
    err = float(np.abs(float(out[4, 4, 0]) - fp))
    check("fixed point m*dt/(1-decay) reached", err, 1e-5)


# --- clamp and range -----------------------------------------------------------------------

def test_clamp_saturates_at_one():
    """The potential is clamped to [0, 1] per frame, so a previous frame of 1 with any
    non-negative accumulation still clamps to exactly 1 (the upper clamp is what saturates)."""
    out = potential_stage(vec_tex(1.0, 0.0), _blank(), const_tex((1.0, 0, 0, 1)),
                          dt=0.05, decay=0.99, strength=1.0, src_vecfield=1.0)
    err = float(abs(float(out[4, 4, 0]) - 1.0))
    check("upper clamp holds at exactly 1", err, 0.0)


def test_scaled_output_may_exceed_one():
    """Doc: "the internal 0-1 potential times strength, so it can exceed 1". The saturated
    internal 1 with strength 1.5 gives exactly 1.5 in r/g/b."""
    out = potential_stage(vec_tex(1.0, 0.0), _blank(), const_tex((1.0, 0, 0, 1)),
                          dt=0.05, decay=0.99, strength=1.5, src_vecfield=1.0)
    err = float(np.abs(out[4, 4, :3].astype(np.float64) - 1.5).max())
    check("strength 1.5 scales the saturated potential to 1.5", err, 1e-5)


def test_alpha_is_one_everywhere():
    """The codebox writes vec(..., 1.0): alpha is exactly 1 for the parameter settings sampled here."""
    worst = 0.0
    for kw in [dict(dt=0.01, decay=0.98, strength=1.0, src_vecfield=1.0, src_color=0.0),
               dict(dt=0.02, decay=0.9, strength=1.4, src_vecfield=1.0, src_color=1.0),
               dict(bypass=1.0)]:
        out = potential_stage(rand_tex(4), rand_tex(5), rand_tex(6), **kw)
        worst = max(worst, float(np.abs(out[..., 3] - 1.0).max()))
    check("alpha exactly 1", worst, 0.0)


# --- strength and colour scaling ------------------------------------------------------------

def test_strength_and_colour_closed_form():
    """Uniform field m=0.5, 7 frames, strength 0.6, src_color 0.3, colour (0.2, 0.65, 0.4).
    The feedback wire carries the module's OUTPUT as a scalar (in4.x): the accumulated scalar
    pot reads only the .x channel, whose tint differs per channel, so the loop gain uses the
    RED tint a = s * tint_r * decay while the displayed channel is q_c = pot * s * tint_c --
    both in float64 as scalar algebra from those one-sentence identities, not a retype of the
    mirror. No clamp is hit at these values."""
    m, dt, d, s, sc = 0.5, 0.02, 0.9, 0.6, 0.3
    col = const_tex((0.2, 0.65, 0.4, 1.0))
    out = run_frames(vec_tex(m, 0.0), col, 7, dt=dt, decay=d, strength=s,
                     src_vecfield=1.0, src_color=sc)
    worst = 0.0
    tints = [1.0 * (1 - sc) + cv * sc for cv in (0.2, 0.65, 0.4)]
    a = s * tints[0] * d
    p = 0.0
    for _ in range(7):
        p = min(1.0, p * a + m * dt)
    for c in range(3):
        expect = p * s * tints[c]
        worst = max(worst, abs(float(out[4, 4, c]) - expect))
    check("channels vs feedback recurrence (s*tint_r*decay loop, per-channel display)", worst, 1e-5)


# --- axis blindness -------------------------------------------------------------------------

def test_axis_blind_180_flip():
    """Doc 2026-10-12 audit: the codebox integrates field magnitude only, so "a field and its
    180-degree flip produce identical output" -- negating both components changes nothing. Checked on a uniform previous frame only: for a
    non-uniform previous frame the backward advection samples opposite offsets and the output could differ."""
    a = run_frames(vec_tex(0.4, -0.25), _blank(), 6, dt=0.02, decay=0.95, src_vecfield=1.0)
    b = run_frames(vec_tex(-0.4, 0.25), _blank(), 6, dt=0.02, decay=0.95, src_vecfield=1.0)
    err = float(np.abs(a - b).max())
    check("field and its 180-degree flip agree", err, 1e-5)


# --- advection ------------------------------------------------------------------------------

def _ramp_prev():
    """prev rising to the right: p(u) = 0.25 + 0.5*u."""
    u, _, _, _ = g.grid(N, N)
    s = g.texture(N, N)
    s[..., 0] = (0.25 + 0.5 * u).astype(F32)
    s[..., 3] = 1.0
    return s, u.astype(np.float64)


def test_backward_advection_left():
    """Field +x: the codebox samples prev at uv - fx*dt, i.e. to the LEFT; at dt = 1 texel the
    bilinear read is exact, so the frame-1 output is 0.25 + 0.5*(u - 1/N) + 1.0*dt away from
    the ramp's own value."""
    prev, u = _ramp_prev()
    dt = 1.0 / N
    out = potential_stage(vec_tex(1.0, 0.0), _blank(), prev, dt=dt, decay=1.0,
                          strength=1.0, src_vecfield=1.0)
    cols = slice(2, N - 2)  # advection and clamp far from the edges
    expected = 0.25 + 0.5 * (u - dt) + 1.0 * dt
    err = float(np.abs(out[:, cols, 0].astype(np.float64) - expected[:, cols]).max())
    check("backward advection reads prev at uv - f*dt (one texel)", err, 1e-5)


def test_backward_advection_down():
    """Field +y on a vertically ascending ramp: the sample sits at uv.y - fy*dt, i.e. one row
    BELOW (a ramp rising upward reads a LOWER value the other x direction is flat so an
    x-offset mutant changes nothing here); at dt = 1 texel the read is exact."""
    u, v, _, _ = g.grid(N, N)
    prev = g.texture(N, N)
    prev[..., 0] = (0.25 + 0.5 * v).astype(F32)
    prev[..., 3] = 1.0
    dt = 1.0 / N
    out = potential_stage(vec_tex(0.0, 1.0), _blank(), prev, dt=dt, decay=1.0,
                          strength=1.0, src_vecfield=1.0)
    rows = slice(2, N - 2)
    expected = 0.25 + 0.5 * (v - dt) + 1.0 * dt
    err = float(np.abs(out[rows, :, 0].astype(np.float64) - expected[rows, :]).max())
    check("backward advection reads prev at uv - f*dt vertically", err, 1e-5)


# --- generic point ---------------------------------------------------------------------------

def _generic_err(bug=None):
    """Every dial at an arbitrary non-special value (strength 0.6, src_color 0.3, decay 0.87,
    a non-dyadic field magnitude m = hypot(0.3, 0.21), 9 frames): the accumulated scalar follows
    pot_n = min(1, pot_{n-1} * s * tint_r * decay + m * dt) in float64 (in4.x is the red channel
    of the tinted, strength-scaled output), and each channel displays pot * s * tint_c -- scalar
    algebra from those identities, at a uniform field so no advection sampling enters (the
    advection itself is covered by the ramp check)."""
    dt, d, s, sc = 0.021, 0.87, 0.6, 0.3
    col = const_tex((0.2, 0.65, 0.4, 1.0))
    vf = vec_tex(0.3, 0.21)
    state = run_frames(vf, col, 9, dt=dt, decay=d, strength=s,
                       src_vecfield=1.0, src_color=sc, bug=bug)
    m = float(np.hypot(0.3, 0.21))
    worst = 0.0
    tints = [1.0 * (1 - sc) + cv * sc for cv in (0.2, 0.65, 0.4)]
    a = s * tints[0] * d
    p = 0.0
    for _ in range(9):
        p = min(1.0, p * a + m * dt)
    for c in range(3):
        expect = p * s * tints[c]
        worst = max(worst, abs(float(state[4, 4, c]) - expect))
    return worst


def test_generic_point():
    """A check at generic parameters the special cases cannot substitute for: strength and
    colour mixing at arbitrary values, a non-dyadic field magnitude, 9 frames."""
    check("generic parameters vs float64 feedback recurrence, 9 frames", _generic_err(), 1e-5)


# --- error helper -----------------------------------------------------------------------------

def _err_scalar(out, expect):
    """Error of out[..., 0] against a scalar, with non-finite counts hard (a NaN must fail)."""
    d = np.abs(out[..., 0].astype(np.float64) - expect)
    d[~np.isfinite(d)] = 1e30
    return float(d.max())


# --- mutations --------------------------------------------------------------------------------

def _series_err(bug=None, n=30):
    dt, d, m = 0.02, 0.9, 0.5
    out = run_frames(vec_tex(m, 0.0), _blank(), n, dt=dt, decay=d, strength=1.0,
                     src_vecfield=1.0, bug=bug)
    return _err_scalar(out, m * dt * (1 - d ** n) / (1 - d))


def _adv_err(bug=None):
    prev, u = _ramp_prev()
    dt = 1.0 / N
    out = potential_stage(vec_tex(1.0, 0.0), _blank(), prev, bug=bug, dt=dt, decay=1.0,
                          strength=1.0, src_vecfield=1.0)
    cols = slice(2, N - 2)
    expected = 0.25 + 0.5 * (u - dt) + dt
    return float(np.abs(out[:, cols, 0].astype(np.float64) - expected[:, cols]).max())


def test_mutations_are_caught():
    """Each declared bug must fail at least one check by a clear margin; the real mirror must
    pass the same checks."""
    real = [_series_err(), _adv_err(), _generic_err()]
    bad = {"plus_dt": max(_series_err("plus_dt"), _adv_err("plus_dt")),
           "no_decay": _series_err("no_decay"),
           "swap_rg": max(_adv_err("swap_rg"), _generic_err("swap_rg")),
           "advect_forward": _adv_err("advect_forward")}
    for k, v in bad.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-2:
            raise AssertionError(f"mutation not caught: {k} (error {v:.3e})")
    assert max(real) < 1e-5, f"the real mirror must pass the same checks: {real}"
    print("    ok   sign slip, missing decay, swapped channels and reversed advection are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))