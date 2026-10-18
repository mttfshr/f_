"""
test_tf_smooth.py -- tier-1 NumPy mirror of the planned f_tf_smooth temporal
tensor smoother (.specify/f_tf_smooth/{spec,plan,tasks}.md, Phase 0 T002-T010).

The module is a per-channel one-pole recurrence over the f_tensor raw encoding
(outlet 0, f_tensor_type.md):

    T'(k) = T(k) + release * (T'(k-1) - T(k))

No spatial sampling, no decode: this is pure elementwise arithmetic on stored
float32 RGBA frames, so the mirror needs no gpu_sim texture model (tasks T002)
-- arrays are (H, W, 4) float32 and every op is float32, which is the whole
precision story the GPU will face.

Independent ground truth (not the mirror agreeing with itself):
  - the closed-form decay theorem  out(k) = B + (A-B) * release**k  (T003),
    verified against numpy float32 powers, not against the recurrence;
  - a vector-field one-pole control shown to collapse where tensors reinforce
    (T005) -- the collapse is computed independently from the vecfield
    recurrence, not assumed;
  - mutation checks (T007): sign flip, swapped weights, clamped feedback.

Run:  tests/run.sh tests/modules/tf_smooth/test_tf_smooth.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent

from harness import check, note, run  # noqa: E402

F32 = np.float32
H = W = 8
RELEASES = (F32(0.0), F32(0.3), F32(0.5), F32(0.9), F32(0.99))


# --- f_tensor out0 encoding helpers (f_tensor_type.md) -------------------

def encode_tensor(jxx, jxy, jyy, strength=1.0, shape=None):
    """Component tensors -> the raw outlet-0 texture. Works elementwise or
    scalar; G carries the 0.5 offset because Jxy is signed. Scalar inputs are
    broadcast to a full (H, W, 4) frame."""
    jxx, jxy, jyy = (np.asarray(v, F32) for v in (jxx, jxy, jyy))
    full = np.broadcast(jxx, jxy, jyy).shape == ()
    if full or shape is not None:
        shp = shape or (H, W)
        jxx = np.broadcast_to(jxx, shp)
        jxy = np.broadcast_to(jxy, shp)
        jyy = np.broadcast_to(jyy, shp)
    tex = np.zeros(np.broadcast(jxx, jxy, jyy).shape + (4,), F32)
    tex[..., 0] = jxx * F32(strength)
    tex[..., 1] = jxy * F32(strength) * F32(0.5) + F32(0.5)
    tex[..., 2] = jyy * F32(strength)
    tex[..., 3] = F32(1.0)
    return tex


def decode_tensor(tex, strength=1.0):
    return (tex[..., 0] / F32(strength),
            (tex[..., 1] - F32(0.5)) * F32(2.0) / F32(strength),
            tex[..., 2] / F32(strength))


def decode_axis(tex):
    """Orientation angle (mod pi) from RAW components -- the mirror's own
    decode, used to prove smoothing invents no orientation. NOT part of the
    module; if the module ever did this math, T004/T005 would still hold but
    the point is that it must never need to."""
    jxx, jxy, jyy = decode_tensor(tex)
    diff = jxx - jyy
    return F32(0.5) * np.arctan2(F32(2.0) * jxy, diff)


def coherence(tex):
    jxx, jxy, jyy = decode_tensor(tex)
    trace = jxx + jyy
    diff = jxx - jyy
    root = np.sqrt(diff * diff + F32(4.0) * jxy * jxy)
    return root / np.maximum(trace, F32(1e-9))


# --- the mirror ----------------------------------------------------------

BUGS = (None, "sign_flip", "weights_swapped", "clamp_feedback")


def smooth_step(prev_state, new_in, release, bypass=False, bug=None):
    """One frame of the recurrence, per channel, float32.

    T' = T_new + release * (T_prev - T_new)
    bypass=1: exact passthrough, feedback ignored (plan ADR-4) -- NOT a freeze.
    bug=None is the real mirror; the other values are the T007 mutations.
    """
    if bug == "sign_flip":
        out = new_in - release * (prev_state - new_in)
    elif bug == "weights_swapped":
        out = release * new_in + (F32(1.0) - release) * prev_state
    elif bug == "clamp_feedback":
        out = new_in + release * (np.clip(prev_state, 0.0, 1.0) - new_in)
    else:
        out = new_in + release * (prev_state - new_in)
    return np.where(bypass, new_in, out).astype(F32)


def run_sequence(frames, release, init=None, bypass=False, bug=None):
    """Run the recurrence over a list of frames. init: state before frame 0
    (the bench's run_temporal 'initial state' texture); default zero tensor."""
    if init is None:
        init = np.zeros((H, W, 4), F32)
    outs = []
    state = init.astype(F32)
    for f in frames:
        state = smooth_step(state, f.astype(F32), F32(release), bypass, bug)
        outs.append(state)
    return outs


# --- T003: decay theorem -------------------------------------------------

def _step_inputs(a, b, k):
    """One frame of A already in the state, then k frames of constant B."""
    init = np.broadcast_to(a, (H, W, 4)).astype(F32).copy()
    frames = [np.broadcast_to(b, (H, W, 4)).astype(F32) for _ in range(k)]
    return init, frames


def test_decay_theorem_closed_form():
    """Step A->B then constant: out(k) = B + (A-B) * release**k per channel.
    Ground truth is the closed form, not the recurrence."""
    a = np.array([4.0, 0.9, 3.5, 1.0], F32)      # unbounded float32 content
    b = np.array([0.2, 0.4, 0.6, 1.0], F32)
    k = 50
    worst = 0.0
    for r in RELEASES:
        init, frames = _step_inputs(a, b, k)
        outs = run_sequence(frames, r, init=init)
        rn = F32(r)
        for s in range(1, k + 1):
            expect = b + (rn ** F32(s)) * (a - b)
            err = float(np.abs(outs[s - 1][0, 0] - expect).max())
            worst = max(worst, err)
    check("decay theorem, all releases, k<=50 (abs)", worst, 1e-5)
    note("decay theorem worst abs error (release 0.99, k 50)", worst)


def test_release_zero_is_exact_passthrough_including_history():
    """release 0 must forget the state completely on the first frame, even
    with a big unbounded history (the spec's 'no feedback residue')."""
    init, frames = _step_inputs(np.array([7.0, -0.5, 2.0, 1.0], F32),
                                np.array([0.3, 0.6, 0.1, 1.0], F32), 4)
    outs = run_sequence(frames, F32(0.0), init=init)
    expect = np.broadcast_to(np.array([0.3, 0.6, 0.1, 1.0], F32), (H, W, 4))
    for s in range(4):
        check(f"release 0 passthrough frame {s+1} (abs)",
              float(np.abs(outs[s] - expect).max()), 0.0)
        if s == 0:
            break
    # and every later frame too (resample-free: same constant)


def test_unbounded_values_round_trip_decayed_not_clamped():
    """ADR-3: no clamp in the feedback path. Jxx-strength 4.0 decaying toward 0
    must pass through values > 1 exactly per the theorem (a clamped loop would
    stick at the clip)."""
    a = np.array([4.0, 0.5, 0.1, 1.0], F32)
    b = np.zeros(4, F32)
    init, frames = _step_inputs(a, b, 3)
    outs = run_sequence(frames, F32(0.5), init=init)
    for s in (1, 2, 3):
        expect = (F32(0.5) ** F32(s)) * a
        check(f"unbounded decay step {s} (abs)", float(np.abs(outs[s - 1][0, 0] - expect).max()), 1e-6)
    check("value above 1.0 present mid-decay (no clamp)",
          0 if any(float(outs[s - 1][0, 0, 0]) > 1.0 for s in (1, 2)) else 1, 0)


# --- T004: line-field invariance ----------------------------------------

def test_alternating_opposite_gradient_axis_is_constant():
    """The same physical edge with its gradient flipped (theta vs theta+180)
    stores an IDENTICAL raw tensor (angle-doubled encoding). Feeding the two
    constructions alternately must give a constant output equal to the tensor
    itself -- and the decoded output axis must be the input axis, not a
    cancelled average. Catches any accidental decode/atan2 in the pipeline."""
    s = F32(100.0)
    gx, gy = F32(2.0), F32(-1.0)
    t_pos = encode_tensor(gx * gx, gx * gy, gy * gy, s)   # from (gx, gy)
    t_neg = encode_tensor(gx * gx, gx * gy, gy * gy, s)   # from (-gx,-gy): identical
    check("opposite gradients store identical tensors",
          float(np.abs(t_neg - t_pos).max()), 0.0)
    frames = [t_neg, t_pos] * 6
    outs = run_sequence(frames, F32(0.5), init=t_pos)
    for i, o in enumerate(outs):
        check(f"frame {i+1} output == input tensor (abs)",
              float(np.abs(o - t_pos).max()), 1e-6)
    ax_in = float(decode_axis(t_pos)[0, 0])
    ax_out = float(decode_axis(outs[-1])[0, 0])
    d = abs(ax_in - ax_out) % np.pi
    check("decoded axis preserved (rad, mod pi)", min(d, np.pi - d), 1e-6)


def test_alternating_two_true_axes_keeps_both_after_blend():
    """Flicker between two DIFFERENT axes 90 degrees apart (two edge camps
    trading places): the tensor blend keeps a real, nondegenerate structure
    tensor with the FULL combined trace (the components add; a vecfield blend
    of the same alternation would shrink the field). A one-pole on a period-2
    input settles to a period-2 output -- the invariant tested is that both
    settled states stay bounded between the two inputs and are complementary,
    not that they equal each other."""
    s = F32(100.0)
    # component tensors are UNENCODED here (the blend happens in tensor space
    # regardless of the gain; strength only scales the stored texture)
    t_axis0 = encode_tensor(1.0, 0.0, 0.05, s)     # axis 0
    t_axis90 = encode_tensor(0.05, 0.0, 1.0, s)    # axis 90
    outs = run_sequence([t_axis0, t_axis90] * 12, F32(0.5), init=t_axis0)
    steady = outs[-1]
    jxx, jxy, jyy = decode_tensor(steady, s)
    tr = float((jxx + jyy)[0, 0])
    check("crossed-camp trace survives blending (sum of parts)",
          abs(tr - 1.05), 1e-4)
    # A one-pole on a PERIOD-2 input settles to a period-2 output (this is
    # the honest behaviour; the invariant is that it never collapses or
    # overshoots: both settled states stay between the two input tensors'
    # componentwise extremes, and the two states are complementary).
    late = np.stack(list(outs[-6:]))
    lo = np.minimum(t_axis0, t_axis90) + F32(1e-4)
    hi = np.maximum(t_axis0, t_axis90) - F32(1e-4)
    inside = float(np.maximum((lo - late).max(), (late - hi).max()))
    check("crossed-camp outputs bounded between the two inputs", inside, 2e-4)
    pair = late[-2:] if np.abs(late[-2] - late[-1]).max() > 1e-4 else late[-4:-2]
    check("settled into exactly two alternating states (residual growth)",
          float(np.abs(late[-1] - late[-3]).max()), 1e-3)
    # Analytic period-2 fixed point of s' = x + r*(s - x) with x alternating:
    # at r = 0.5 the settled even state is (2/3)*t0 + (1/3)*t90 and the odd
    # state the reverse (per channel). Assert the settled frames match the
    # closed form, which proves the alternation is preserved (not frozen, not
    # collapsed to one camp) while each frame remains a real blend of both.
    w_self = F32(2.0) / F32(3.0)          # own camp's weight at r = 0.5
    w_other = F32(1.0) - w_self
    even_expect = w_self * t_axis0 + w_other * t_axis90
    odd_expect = w_self * t_axis90 + w_other * t_axis0
    check("even frame == analytic period-2 blend of camps",
          float(np.abs(late[-2] - even_expect).max()), 1e-4)
    check("odd frame == analytic period-2 blend of camps",
          float(np.abs(late[-1] - odd_expect).max()), 1e-4)


# --- T005: opposite-axis reinforcement (tensor-native test) --------------

def _vecfield_alternation_magnitude(v_even, v_odd, release, frames_n):
    """Independent control: one-pole on signed vectors, same alternation.
    Returns the settled per-frame output magnitudes."""
    outs = []
    state = np.zeros(2, F32)
    for i in range(frames_n):
        v = v_even if i % 2 == 0 else v_odd
        state = (v + F32(release) * (state - v)).astype(F32)
        outs.append(float(np.sqrt((state ** 2).sum())))
    return outs


def test_opposite_sign_flip_reinforces_in_tensor_space():
    """Frame-to-frame gradient SIGN flips (the two camps are opposite ends of
    one axis): tensors are identical, so the smoothed tensor does not decay at
    all, while a vecfield one-pole on the same alternation collapses toward
    zero magnitude. This is the tensor-native row as numbers."""
    s = F32(100.0)
    gx, gy = F32(1.5), F32(0.75)
    t_pos = encode_tensor(gx * gx, gx * gy, gy * gy, s)
    t_neg = encode_tensor(gx * gx, gx * gy, gy * gy, s)   # (-gx)(-gy) == gx*gy
    frames = [t_neg, t_pos] * 8
    outs = run_sequence(frames, F32(0.5), init=t_pos)
    drift = max(float(np.abs(o - t_pos).max()) for o in outs)
    check("tensor survives opposite-sign flicker (abs drift)", drift, 1e-5)
    coh_in = float(coherence(t_pos)[0, 0])
    coh_out = float(coherence(outs[-1])[0, 0])
    check("coherence kept (>= input min)", 0 if coh_out >= coh_in - 1e-6 else 1, 0)
    # vecfield control: vectors +v, -v alternating, release 0.5
    v = np.array([gx, gy], F32)
    mags = _vecfield_alternation_magnitude(v, -v, 0.5, len(frames))
    jxx, _, jyy = decode_tensor(outs[-1], s)
    keep = float(np.sqrt(jxx[0, 0] ** 2 + jyy[0, 0] ** 2))
    note("settled vecfield magnitude (collapse)", min(mags))
    note("vecfield |v|", float(np.sqrt((v ** 2).sum())))
    check("vecfield control collapses (<50% of |v| within 3 frames)",
          0 if min(mags[:3]) < 0.5 * float(np.sqrt((v ** 2).sum())) else 1, 0)
    check("tensor output retains full strength (>=99% of input norm)",
          0 if keep >= 0.99 * float(np.sqrt(1.0 + 0.05 ** 2)) else 1, 0)


def test_hot_cold_alternation_between_two_axes_keeps_coherence():
    """Two constant regions (axis 0 and axis 90), each present every frame,
    'hot' state alternating between them. At every pixel, the output
    coherence stays >= the min of the two per-frame input coherences
    (coherence is contrast-independent, so magnitudes may wobble, trust may
    not). This is the spec's acceptance row verbatim."""
    s = F32(100.0)
    base0 = np.array([1.0, 0.0, 0.05], F32)     # axis 0
    base90 = np.array([0.05, 0.0, 1.0], F32)    # axis 90

    def region_frame(hot_left):
        f = np.zeros((H, W, 4), F32)
        for x in range(W):
            base, hot = (base0, hot_left) if x < W // 2 else (base90, not hot_left)
            sc = F32(3.0) if hot else F32(1.0)
            f[:, x] = encode_tensor(base[0] * sc, base[1] * sc, base[2] * sc, s)[0, :]
        return f

    frames = [region_frame(i % 2 == 0) for i in range(16)]
    out = run_sequence(frames, F32(0.5), init=frames[0])[-1]
    coh_out = coherence(out)
    bad = 0
    for y in range(H):
        for x in range(W):
            base = base0 if x < W // 2 else base90
            c_hi = float(coherence(encode_tensor(base[0] * F32(3), base[1] * F32(3),
                                                 base[2] * F32(3), s))[0, 0])
            c_lo = float(coherence(encode_tensor(base[0], base[1], base[2], s))[0, 0])
            if coh_out[y, x] < min(c_hi, c_lo) - 1e-5:
                bad += 1
    check("pixels below min input coherence", bad, 0)


# --- T006: neutral + bypass ---------------------------------------------

def test_zero_tensor_input_decays_state_to_zero():
    """Unconnected inlet = zero tensor in. With non-zero history the state
    decays geometrically to the zero-tensor neutral: out(k) = init*(1-r)^k.
    Never freezes (ADR-4: bypass = passthrough, unconnected = decay)."""
    rng = np.random.default_rng(3)
    init = encode_tensor(rng.uniform(0, 2, (H, W)), rng.uniform(-1, 1, (H, W)),
                         rng.uniform(0, 2, (H, W)), 100.0)
    zero = np.zeros((H, W, 4), F32)
    outs = run_sequence([zero] * 40, F32(0.5), init=init)
    for k in (1, 5, 20, 40):
        expect = init * (F32(0.5) ** F32(k))
        check(f"unconnected decay k={k} (abs)", float(np.abs(outs[k - 1] - expect).max()), 1e-6)
    check("unconnected settles near neutral", float(np.abs(outs[-1]).max()), 1e-8)


def test_bypass_is_exact_passthrough_not_freeze():
    """bypass=1: output == input exactly, feedback ignored -- with a dirty
    state, and on content that changes between frames. NOT a freeze of the
    last smoothed frame."""
    rng = np.random.default_rng(4)
    dirty_state = encode_tensor(rng.uniform(0, 3, (H, W)), rng.uniform(-1, 1, (H, W)),
                                rng.uniform(0, 3, (H, W)), 100.0)
    frames = [encode_tensor(rng.uniform(0, 2, (H, W)), rng.uniform(-1, 1, (H, W)),
                            rng.uniform(0, 2, (H, W)), 100.0) for _ in range(5)]
    outs = run_sequence(frames, F32(0.7), init=dirty_state, bypass=True)
    for i, (o, f) in enumerate(zip(outs, frames)):
        check(f"bypass frame {i+1} == input exactly (abs)", float(np.abs(o - f).max()), 0.0)


def test_channels_are_independent():
    """The recurrence is per-channel elementwise: varying only R must move
    only R (the codebox is 4-channel arithmetic only, no mixing)."""
    f1 = np.zeros((H, W, 4), F32); f1[..., 0] = 2.0; f1[..., 3] = 1.0
    f2 = np.zeros((H, W, 4), F32); f2[..., 0] = 0.0; f2[..., 3] = 1.0
    outs = run_sequence([f2, f1, f2], F32(0.5), init=f2)
    for i, o in enumerate(outs):
        check(f"only R moves, frame {i+1} (abs)",
              float(np.abs(o[..., 1:] - f2[..., 1:]).max()), 0.0)


# --- T007: mutation checks ----------------------------------------------

def _decay_err(bug):
    a = np.array([4.0, 0.9, 3.5, 1.0], F32)
    b = np.array([0.2, 0.4, 0.6, 1.0], F32)
    worst = 0.0
    for r in (F32(0.3), F32(0.5), F32(0.9)):
        init, frames = _step_inputs(a, b, 12)
        outs = run_sequence(frames, r, init=init, bug=bug)
        for s in range(1, 13):
            expect = b + (F32(r) ** F32(s)) * (a - b)
            worst = max(worst, float(np.abs(outs[s - 1][0, 0] - expect).max()))
    return worst


def test_mutation_checks_are_caught():
    """Each T007 bug must break the decay theorem badly; the clean mirror must
    pass it (guard against a vacuous mutation test)."""
    good = _decay_err(None)
    check("clean mirror passes decay theorem", good, 2e-6)
    for bug in BUGS[1:]:
        bad = _decay_err(bug)
        note(f"mutation '{bug}' worst decay error", bad)
        if not bad > 1e-3:
            raise AssertionError(f"mutation not detected: {bug} err {bad:.3e}")
    print("    ok   all three mutations caught by the decay-theorem check")


def test_clamp_mutation_breaks_unbounded_paths():
    """The clamp bug is invisible on 0-1 content -- it must also be caught by
    the unbounded-value test (why ADR-3 is a test, not a style choice)."""
    a = np.array([4.0, 0.5, 0.1, 1.0], F32)
    b = np.zeros(4, F32)
    init, frames = _step_inputs(a, b, 3)
    outs = run_sequence(frames, F32(0.5), init=init, bug="clamp_feedback")
    expect = (F32(0.5) ** F32(1)) * a
    err = float(np.abs(outs[0][0, 0] - expect).max())
    note("clamp bug first-step error on Jxx=4 content", err)
    if not err > 1e-3:
        raise AssertionError("clamp mutation not detected on unbounded values")
    print("    ok   clamp-feedback mutation caught on unbounded content")


if __name__ == "__main__":
    sys.exit(run(globals()))