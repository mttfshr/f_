"""
vf_advect_mirror.py -- NumPy mirror of the f_vf_advect ADVECT stage: src/f_vf_advect/codebox_advect.gen,
float32, pass for pass (all four channels, as the codebox's vec4 arithmetic does).

Scope: the advect stage only. The feedback loop in the module is advect out1 -> pass stage
(`codebox_advect_pass.gen`, chroma `separate` / `mode`) -> advect in3. `run_frames` models the loop with the
pass stage as the identity, which is what `separate = 0` is in every mode by that codebox's own comment; the
pass stage itself has no mirror (it is marked CANDIDATE / UNVERIFIED in its source).

Inputs, as in the gen: in1 = source texture, in2 = vecfield texture (R,G encode (v - 0.5) * 2), in3 = previous
frame. Sampling is gpu_sim's bilinear, texel-centre, clamp-to-edge `sample`. NOTE: on the GPU the bench wraps
out-of-range reads (docs: "bench GPU wraps out-of-range reads, codeboxes clamp in-shader"); the advect UV is
clamped in the shader, but the gradient taps (outlet 3) are not, so edge rows of outlet 3 are a tier-2 question,
not a tier-1 one.

`bug` values are the mutations the tests must catch: "sign_flip" (forward instead of backward displacement),
"no_suppress" (ignore src_vecfield), "no_clamp" (no clamp on the accumulated result).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32
GRAD_SCALE = F32(0.004)
GRAD_GAIN = F32(4.0)


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1) - t) + b * t).astype(F32)


def advect_stage(src, vec, prev, dt=0.01, decay=0.97, injection=0.02, gain=1.0, mix_pct=100.0,
                 bypass_gate=0.0, src_vecfield=1.0, bug=None):
    """One frame of the advect gen. src, vec, prev: (H, W, 4) float32. Returns (out1, out2, out3).

    out1 composite (gain, wet/dry, bypass) -- the loop state; out2 the advected result before the mix;
    out3 the vecfield gradient of the accumulated flow (or the passed-through vecfield when bypassed).
    """
    dt, decay, injection, gain = F32(dt), F32(decay), F32(injection), F32(gain)
    h, w = src.shape[:2]
    u, v, _, _ = g.grid(h, w)

    s_here = g.sample(src, u, v)
    v_here = g.sample(vec, u, v)
    fx = (v_here[..., 0] - F32(0.5)) * F32(2)
    fy = (v_here[..., 1] - F32(0.5)) * F32(2)

    connected = F32(1.0) if (bug == "no_suppress" or F32(src_vecfield) >= F32(0.5)) else F32(0.0)
    fx = fx * connected
    fy = fy * connected

    sgn = F32(-1) if bug == "sign_flip" else F32(1)
    su = np.clip(u - sgn * fx * dt, F32(0), F32(1)).astype(F32)
    sv = np.clip(v - sgn * fy * dt, F32(0), F32(1)).astype(F32)

    advected = g.sample(prev, su, sv) * decay
    result = advected + s_here * injection
    if bug != "no_clamp":
        result = np.clip(result, F32(0), F32(1))
    result = result.astype(F32)

    driven = np.clip(result * gain, F32(0), F32(1)).astype(F32)
    mixed = _mix(s_here, driven, F32(mix_pct) / F32(100))
    out1 = _mix(mixed, s_here, F32(bypass_gate))
    out2 = _mix(result, s_here, F32(bypass_gate))

    def luma(x, y):
        c = g.sample(prev, x, y)
        return c[..., 0] * F32(0.299) + c[..., 1] * F32(0.587) + c[..., 2] * F32(0.114)

    gx = (luma(u + GRAD_SCALE, v) - luma(u - GRAD_SCALE, v)) * GRAD_GAIN
    gy = (luma(u, v + GRAD_SCALE) - luma(u, v - GRAD_SCALE)) * GRAD_GAIN
    half = np.full_like(gx, F32(0.5))
    one = np.ones_like(gx)
    field = np.stack([np.clip(gx * F32(0.5) + F32(0.5), F32(0), F32(1)),
                      np.clip(gy * F32(0.5) + F32(0.5), F32(0), F32(1)), half, one], axis=-1).astype(F32)
    passthrough = np.stack([_mix(half, v_here[..., 0], connected),
                            _mix(half, v_here[..., 1], connected), half, one], axis=-1).astype(F32)
    out3 = _mix(field, passthrough, F32(bypass_gate))
    return out1.astype(F32), out2.astype(F32), out3.astype(F32)


def run_frames(src, vec, n, init=None, **params):
    """n frames of the feedback loop (advect out1 -> identity pass stage -> in3). src, vec: one
    (H, W, 4) texture each, held constant. Returns the list of out1 frames; out1[k] is the state after
    frame k + 1."""
    prev = g.texture(*src.shape[:2]) if init is None else init
    frames = []
    for _ in range(n):
        out1, _, _ = advect_stage(src, vec, prev, **params)
        frames.append(out1)
        prev = g.store_float32(out1)
    return frames
