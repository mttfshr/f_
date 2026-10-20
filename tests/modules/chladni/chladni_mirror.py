"""
chladni_mirror.py -- NumPy mirror of the f_chladni jit.gl.pix shader
(snapshot src/f_chladni/definition.py, shipped inline codebox), float32, in the
codebox's own order of operations. Hand translation, nothing parses the codebox.

There is no source texture: the module is a pure generator and the mirror is a
function of the texel-centre coordinates (gpu_sim.grid, exact `norm`) and the
Params only, so it reads no texture.

Faithfulness notes (all read off the shipped codebox):
  - `modal_A` and `modal_B` are the codebox's helper functions, including the
    fact that they recompute their circular coordinates from the uv they are
    handed, so view_mode influences only the inline mode-B total of the main
    body, never the helpers.
  - Mode A blends adjacent Bessel-zero windows linearly; the seven step windows
    overlap at an exact Bessel zero, so a z_pos exactly equal to a zero is
    double-counted (both neighbouring windows select the same term).
  - note=127 maps z_pos to exactly z7: the codebox clamps with min(., z7). Until
    2026-10-20 float32 rounding put z_pos just past z7 (11.086401), outside every
    step window, and mode 0's total vanished identically at note 127 (in this float32
    NumPy mirror; the old codebox was not blank on the GPU, probe P3, so the clamp is hardening).
  - out2 is a central difference (eps=0.004 in uv) of the unscaled modal total,
    unit-normalized and encoded 0.5 +- 0.5; the gradient floor is 1e-4.
  - out3 = clamp(abs(total)*gain, 0, 1); out1 = 1 - clamp(sqrt(abs(total))*
    linesharpness, 0, 1); bypass mixes each outlet to black / neutral (0.5,0.5).

`bug` values are the mutations the tests must catch:
  "drop_reflect"            the boundary-reflection term is dropped,
  "sign_flip_phase"         the phase ph0 enters with flipped sign,
  "swap_rg_vecfield"        out2's encoded R and G (gradient x/y) are swapped,
  "note_span_128"           the note -> z_pos divisor 127.0 becomes 128.0,
  "no_vecfield_normalize"   out2 omits the division by the gradient magnitude.
"""
import numpy as np

import gpu_sim as g  # noqa: E402

F32 = np.float32
PI = F32(np.pi)
TWOPI = F32(2.0 * np.pi)
Z0, Z1, Z2, Z3 = (F32(v) for v in (2.4048, 3.8317, 5.1356, 6.3802))
Z4, Z5, Z6, Z7 = (F32(v) for v in (7.5883, 8.7715, 9.9361, 11.0864))
ZEROS = (Z0, Z1, Z2, Z3, Z4, Z5, Z6, Z7)


def _mix(a, b, t):
    """GenExpr mix: a * (1 - t) + b * t, float32."""
    return (a * (F32(1.0) - t) + b * t).astype(F32)


def _step(edge, x):
    """GenExpr step(edge, x): 1 when x >= edge else 0."""
    return np.where(x >= edge, F32(1.0), F32(0.0)).astype(F32)


def _smoothstep(e0, e1, x):
    """GLSL/GenExpr smoothstep on the clamped ramp, float32."""
    t = np.clip((x - F32(e0)) / (F32(e1) - F32(e0)), F32(0.0), F32(1.0))
    return (t * t * (F32(3.0) - F32(2.0) * t)).astype(F32)


def _phase(phase, bug):
    if bug == "sign_flip_phase":
        return F32(-1.0) * F32(phase)
    return F32(phase)


def _m_term(ev, rs, zero, radius, reflect, ang_arg, msk):
    """(ev*cos(rs - z_m) + reflect*ev*cos(radius - rs - z_m)) * cos(ang) * msk,
    the codebox's per-mode contribution."""
    wave = (ev * np.cos(rs - F32(zero))
            + F32(reflect) * ev * np.cos(F32(radius) - rs - F32(zero))).astype(F32)
    return (wave * np.cos(ang_arg) * msk).astype(F32)


def modal_A(ux, uy, zp, radius, reflect, phase, bug=None):
    """Helper of the codebox: mode-A total at arbitrary uv (linear window blend).
    Recomputes circular coordinates from ux, uy; view_mode is not involved."""
    F32r = F32(radius)
    ddx = (ux - F32(0.5)).astype(F32)
    ddy = (uy - F32(0.5)).astype(F32)
    rs = np.maximum(np.sqrt(ddx * ddx + ddy * ddy) * F32(2.0) * F32r, F32(0.001)).astype(F32)
    th = np.arctan2(ddy, ddx).astype(F32)
    ph = _phase(phase, bug)
    ev = np.sqrt(F32(2.0) / (PI * rs)).astype(F32)
    msk = (F32(1.0) - _smoothstep(F32(0.8), F32(1.0), rs / np.maximum(F32r, F32(0.001)))).astype(F32)
    refl = F32(0.0) if bug == "drop_reflect" else F32(reflect)

    m = [(_m_term(ev, rs, ZEROS[k], radius, refl, F32(k) * th + ph, msk)).astype(F32)
         for k in range(8)]

    acc = None
    for k in range(7):
        lo, hi = ZEROS[k], ZEROS[k + 1]
        s_k = (_step(lo, zp) * _step(zp, hi)).astype(F32)
        t_k = ((zp - lo) / (hi - lo)).astype(F32)
        term = _mix(m[k], m[k + 1], t_k) * s_k
        acc = term if acc is None else (acc + term).astype(F32)
    return acc


def modal_B(ux, uy, zp, radius, reflect, phase, sprd, bug=None):
    """Helper of the codebox: mode-B total at arbitrary uv (Gaussian resonance
    weights, normalized by their sum). Recomputes circular coordinates."""
    F32r = F32(radius)
    ddx = (ux - F32(0.5)).astype(F32)
    ddy = (uy - F32(0.5)).astype(F32)
    rs = np.maximum(np.sqrt(ddx * ddx + ddy * ddy) * F32(2.0) * F32r, F32(0.001)).astype(F32)
    th = np.arctan2(ddy, ddx).astype(F32)
    ph = _phase(phase, bug)
    ev = np.sqrt(F32(2.0) / (PI * rs)).astype(F32)
    msk = (F32(1.0) - _smoothstep(F32(0.8), F32(1.0), rs / np.maximum(F32r, F32(0.001)))).astype(F32)
    refl = F32(0.0) if bug == "drop_reflect" else F32(reflect)

    sp2 = np.maximum(F32(sprd) * F32(sprd) * F32(2.0), F32(0.0001)).astype(F32)
    gw = [(np.exp(-(((zp - ZEROS[k]) * (zp - ZEROS[k])) / sp2))).astype(F32) for k in range(8)]
    ws = np.maximum(gw[0] + gw[1] + gw[2] + gw[3] + gw[4] + gw[5] + gw[6] + gw[7], F32(0.0001)).astype(F32)

    m = [(_m_term(ev, rs, ZEROS[k], radius, refl, F32(k) * th + ph, msk)).astype(F32)
         for k in range(8)]
    acc = gw[0] * m[0]
    for k in range(1, 8):
        acc = (acc + gw[k] * m[k]).astype(F32)
    return (acc / ws).astype(F32)


def chladni(h=64, w=64, note=60.0, amp=1.0, dishradius=1.0, reflectamt=0.0,
            linesharpness=10.0, ph0=0.0, spread=0.3, mode=0.0, view_mode=0.0,
            gain=1.0, bypass_gate=0.0, bug=None):
    """Whole module. Returns (out1 luma, out2 vecfield, out3 magnitude), each
    (h, w, 4) float32, in the codebox's own order of operations."""
    nx, ny, _, _ = g.grid(h, w)
    dx = (nx - F32(0.5)).astype(F32)
    dy = (ny - F32(0.5)).astype(F32)

    if bug == "note_span_128":
        z_pos = (Z0 + (F32(note) / F32(128.0)) * (Z7 - Z0)).astype(F32)
    else:
        z_pos = np.minimum(Z0 + (F32(note) / F32(127.0)) * (Z7 - Z0), Z7).astype(F32)

    r_circ = (np.sqrt(dx * dx + dy * dy) * F32(2.0) * F32(dishradius)).astype(F32)
    th_circ = np.arctan2(dy, dx).astype(F32)
    r_strip = (ny * F32(dishradius)).astype(F32)
    th_strip = (nx * TWOPI - PI).astype(F32)
    r = _mix(r_circ, r_strip, F32(view_mode)).astype(F32)
    th = _mix(th_circ, th_strip, F32(view_mode)).astype(F32)

    r_s = np.maximum(r, F32(0.001)).astype(F32)
    env = np.sqrt(F32(2.0) / (PI * r_s)).astype(F32)
    mask = (F32(1.0) - _smoothstep(F32(0.8), F32(1.0),
                                   r / np.maximum(F32(dishradius), F32(0.001)))).astype(F32)

    refl = F32(0.0) if bug == "drop_reflect" else F32(reflectamt)
    ph = _phase(ph0, bug)

    total_A = modal_A(nx, ny, z_pos, dishradius, refl, ph)

    sp2 = np.maximum(F32(spread) * F32(spread) * F32(2.0), F32(0.0001)).astype(F32)
    gw = [(np.exp(-(((z_pos - ZEROS[k]) * (z_pos - ZEROS[k])) / sp2))).astype(F32) for k in range(8)]
    wsum = np.maximum(gw[0] + gw[1] + gw[2] + gw[3] + gw[4] + gw[5] + gw[6] + gw[7], F32(0.0001)).astype(F32)
    m = []
    for k in range(8):
        wave = (env * np.cos(r_s - ZEROS[k])
                + refl * env * np.cos(F32(dishradius) - r_s - ZEROS[k])).astype(F32)
        m.append((wave * np.cos(F32(k) * th + ph) * mask).astype(F32))
    total_B = ((gw[0] * m[0] + gw[1] * m[1] + gw[2] * m[2] + gw[3] * m[3]
                + gw[4] * m[4] + gw[5] * m[5] + gw[6] * m[6] + gw[7] * m[7]) / wsum).astype(F32)

    md = _step(F32(0.5), F32(mode))
    if bug == "no_amp":
        total = _mix(total_A, total_B, md)
    else:
        total = (_mix(total_A, total_B, md) * F32(amp)).astype(F32)

    line = (F32(1.0) - np.clip(np.sqrt(np.abs(total)) * F32(linesharpness),
                               F32(0.0), F32(1.0))).astype(F32)
    out1 = _mix(np.stack([line, line, line, np.ones_like(line)], axis=-1),
                np.broadcast_to(F32(np.array([0.0, 0.0, 0.0, 1.0], F32)), (h, w, 4)).copy(),
                F32(bypass_gate)).astype(F32)

    eps = F32(0.004)
    t_xp = _mix(modal_A(nx + eps, ny, z_pos, dishradius, refl, ph),
                modal_B(nx + eps, ny, z_pos, dishradius, refl, ph, spread), md)
    t_xn = _mix(modal_A(nx - eps, ny, z_pos, dishradius, refl, ph),
                modal_B(nx - eps, ny, z_pos, dishradius, refl, ph, spread), md)
    t_yp = _mix(modal_A(nx, ny + eps, z_pos, dishradius, refl, ph),
                modal_B(nx, ny + eps, z_pos, dishradius, refl, ph, spread), md)
    t_yn = _mix(modal_A(nx, ny - eps, z_pos, dishradius, refl, ph),
                modal_B(nx, ny - eps, z_pos, dishradius, refl, ph, spread), md)

    gx = ((t_xp - t_xn) / (F32(2.0) * eps)).astype(F32)
    gy = ((t_yp - t_yn) / (F32(2.0) * eps)).astype(F32)
    gmag = np.maximum(np.sqrt(gx * gx + gy * gy), F32(0.0001)).astype(F32)
    if bug == "swap_rg_vecfield":
        ex, ey = gy, gx
    elif bug == "no_vecfield_normalize":
        ex, ey = gx, gy
    else:
        ex, ey = (gx / gmag).astype(F32), (gy / gmag).astype(F32)
    out2 = np.stack([ex * F32(0.5) + F32(0.5), ey * F32(0.5) + F32(0.5),
                     np.zeros_like(ex), np.ones_like(ex)], axis=-1).astype(F32)
    out2 = _mix(out2, np.broadcast_to(F32(np.array([0.5, 0.5, 0.0, 1.0], F32)), (h, w, 4)).copy(),
                F32(bypass_gate)).astype(F32)

    mag = np.clip(np.abs(total) * F32(gain), F32(0.0), F32(1.0)).astype(F32)
    out3 = _mix(np.stack([mag, mag, mag, np.ones_like(mag)], axis=-1),
                np.broadcast_to(F32(np.array([0.0, 0.0, 0.0, 1.0], F32)), (h, w, 4)).copy(),
                F32(bypass_gate)).astype(F32)

    return out1, out2, out3