"""
tf_smooth_mirror.py -- NumPy mirror of the tf_smooth shader: the functions (and the constants and
fixtures they need) that tests/modules/tf_smooth/bench_tf_smooth.py imports. Extracted
from test_tf_smooth.py in Phase C, 2026-10-18; the tests stay there.
"""
import numpy as np

F32 = np.float32
H = W = 8


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
