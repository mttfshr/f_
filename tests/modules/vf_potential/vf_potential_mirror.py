"""
vf_potential_mirror.py -- NumPy mirror of the f_vf_potential shader:
src/f_vf_potential/codebox_potential.gen, float32, in the
codebox's own order of operations.

One pass. The bpatcher runs the pass once per frame and feeds out0 back into inlet 4 (previous frame);
the test iterates frames by feeding the output back.

Codebox (verbatim order):
  uv = norm
  fx = (sample(in2, uv).x - 0.5) * 2.0;  fy = (sample(in2, uv).y - 0.5) * 2.0
  connected = step(0.5, src_vecfield);   fx *= connected; fy *= connected
  field_mag = sqrt(fx*fx + fy*fy)
  src_uv = vec(clamp(uv.x - fx*dt, 0, 1), clamp(uv.y - fy*dt, 0, 1))
  prev = sample(in4, src_uv).x            (bilinear, clamp-to-edge)
  potential = clamp(prev * decay + field_mag * dt, 0, 1)
  potential_scaled = potential * strength
  color = sample(in3, uv);  r/g/b = mix(1.0, color.c, src_color)
  result = vec(r*p, g*p, b*p, 1.0)
  out1 = mix(result, vec(0,0,0,1), bypass)

`bug` values are the mutations the tests must catch:
  "plus_dt"     (accumulate prev*decay - field_mag*dt, a sign slip on the field term),
  "no_decay"    (prev added undecayed: prev + field_mag*dt),
  "swap_rg"     (decode the field from .y/.x instead of .x/.y),
  "advect_forward" (sample at uv + f*dt instead of uv - f*dt).
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32


def _mix(a, b, t):
    """GenExpr / GLSL mix: a * (1 - t) + b * t."""
    t = F32(t) if np.isscalar(t) else t
    return (a * (F32(1) - t) + b * t).astype(F32)


def potential_stage(vf, color, prev, dt=0.01, decay=0.98, strength=1.0,
                    src_vecfield=0.0, src_color=0.0, bypass=0.0, bug=None):
    """One frame. vf, color, prev: (H, W, 4) float32; prev is the previous frame (zeros on frame 1).
    Returns (H, W, 4) float32, the module's out0 (which the patcher feeds back into in4)."""
    h, w = vf.shape[:2]
    u, v, _, _ = g.grid(h, w)
    connected = F32(1.0) if F32(src_vecfield) >= F32(0.5) else F32(0.0)
    fx = ((vf[..., 0] - F32(0.5)) * F32(2.0) * connected).astype(F32)
    fy = ((vf[..., 1] - F32(0.5)) * F32(2.0) * connected).astype(F32)
    if bug == "swap_rg":
        fx, fy = fy, fx
    field_mag = np.sqrt(fx * fx + fy * fy).astype(F32)
    if bug == "advect_forward":
        sx, sy = (u + fx * F32(dt)).astype(F32), (v + fy * F32(dt)).astype(F32)
    else:
        sx, sy = (u - fx * F32(dt)).astype(F32), (v - fy * F32(dt)).astype(F32)
    pv = g.sample(prev, sx, sy)[..., 0]
    if bug == "no_decay":
        p = pv + field_mag * F32(dt)
    elif bug == "plus_dt":
        p = pv * F32(decay) - field_mag * F32(dt)
    else:
        p = pv * F32(decay) + field_mag * F32(dt)
    p = np.clip(p, F32(0), F32(1)).astype(F32)
    ps = (p * F32(strength)).astype(F32)
    c = g.sample(color, u, v)
    r = _mix(F32(1.0), c[..., 0], F32(src_color))
    gg = _mix(F32(1.0), c[..., 1], F32(src_color))
    b = _mix(F32(1.0), c[..., 2], F32(src_color))
    result = np.stack([r * ps, gg * ps, b * ps, np.ones_like(ps)], axis=-1).astype(F32)
    neutral = g.texture(h, w)
    neutral[...] = np.array((0.0, 0.0, 0.0, 1.0), F32)
    return _mix(result, neutral, F32(bypass))


def feedback_frame(vf, color, dt=0.01, decay=0.98, strength=1.0, src_vecfield=1.0,
                   src_color=0.0, bypass=0.0, bug=None):
    """The patcher's next(vf, color, prev) = pass(vf, color, previous output) mapping.
    The first frame's previous value is 0."""
    h, w = vf.shape[:2]
    prev = g.texture(h, w)
    return potential_stage(vf, color, prev, dt=dt, decay=decay, strength=strength,
                           src_vecfield=src_vecfield, src_color=src_color,
                           bypass=bypass, bug=bug)


def run_frames(vf, color, n, **kw):
    """Feed the pass back on itself n times, as the patcher's ping-pong does."""
    h, w = vf.shape[:2]
    state = g.texture(h, w)
    for _ in range(n):
        state = potential_stage(vf, color, state, **kw)
    return state