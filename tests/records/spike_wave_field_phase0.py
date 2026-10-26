"""spike_wave_field_phase0.py -- f_wave_field Phase 0 measurements (2026-10-25): T003, T004, T005, T007.

A record, not a test: it prints the numbers the Phase 0 decisions rest on (tasks.md records the
choices). Run one section at a time:

    tests/py.sh tests/records/spike_wave_field_phase0.py t003     # float32 vs float64, damping floor
    tests/py.sh tests/records/spike_wave_field_phase0.py t007     # operator-splitting accuracy
    tests/py.sh tests/records/spike_wave_field_phase0.py t004     # nu, sponge, exciter gain
    tests/py.sh tests/records/spike_wave_field_phase0.py t005     # output mappings + stills

Everything runs on the tier-1 mirror (tests/modules/wave_field/wave_field_mirror.py), which reads
its provisional constants from module level, so editing them there changes these runs.
"""
import os
import struct
import sys
import time
import zlib

import numpy as np

import wave_field_mirror as wfm
from wave_field_mirror import F32, Params, new_state, struck_state, step_coeffs

TESTS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(TESTS, "logs", "wave_field")
F64 = np.float64
TWO_PI = 2 * np.pi


def fast_frame(st, p, phase=0.0, strike=False, force_tex=None):
    """One mirror frame without the encode passes (long runs only; fast_fft)."""
    tex = np.zeros_like(st)
    tex[..., 0], tex[..., 2] = st[..., 0], st[..., 2]
    sh = wfm.spec_stage(wfm._fft2(tex, True), p)
    lin = wfm._fft2(sh, True, inverse=True)
    s = np.zeros_like(st)
    s[..., 0], s[..., 2], s[..., 3] = lin[..., 0], lin[..., 2], F32(1.0)
    new = wfm.real_stage(s, p, force_tex, phase, strike)
    return new, (phase + TWO_PI * p.frequency * p.dt) % TWO_PI


def zero_mean(a):
    return a - a.mean()


def rand_state(n, seed):
    rng = np.random.default_rng(seed)
    st = new_state(n, n)
    st[..., 0] = zero_mean(rng.uniform(-1, 1, (n, n))).astype(F32)
    st[..., 2] = zero_mean(rng.uniform(-1, 1, (n, n))).astype(F32)
    return st


# =============================================================== T003
def t003():
    print("== T003: float32 versus float64, damping floor")
    # (a) per-frame energy gain of the float32 step coefficients at zero damping, per bin
    print("\n(a) worst per-frame gain |lambda|^2 - 1 of the FLOAT32 coefficients (beta = 0), from float64 arithmetic on them")
    print("    useful = bins with omega*dt <= pi (no temporal aliasing); all = every bin")
    worst_useful = worst_all = 0.0
    for n in (128, 256):
        kx, ky = wfm.signed_k(n, n)
        kmag = np.sqrt(kx * kx + ky * ky).astype(F32)
        for speed in (0.05, 0.25, 1.0):
            for disp in (0.5, 1.0, 2.0):
                for dt in (1 / 120, 1 / 60, 1 / 30):
                    p = Params(speed=speed, dispersion=disp, dt=dt)
                    cc, cs, om2, _ = step_coeffs(kmag, p)
                    cc, cs, om2 = cc.astype(F64), cs.astype(F64), om2.astype(F64)
                    g = cc * cc + om2 * cs * cs - 1.0
                    g[0, 0] = 0.0
                    useful = np.sqrt(om2) * dt <= np.pi
                    gu = float(g[useful].max()) if useful.any() else 0.0
                    ga = float(g.max())
                    worst_useful, worst_all = max(worst_useful, gu), max(worst_all, ga)
                    if gu > 5e-7 or ga > 1e-5:
                        print(f"    N {n} speed {speed:<5g} disp {disp:g} dt 1/{round(1 / dt)}: useful {gu:+.2e}  all {ga:+.2e}")
    print(f"    WORST useful-band gain per frame: {worst_useful:+.3e}   worst over all bins: {worst_all:+.3e}")

    # (b) trajectories against the float64 closed form (rotation by n steps), damping 0
    print("\n(b) float32 mirror vs float64 closed form, N = 32, speed 0.25, dt 1/60 (store-to-float32 every frame)")
    n, p = 32, Params(speed=0.25, damping=0.0, fast_fft=True)
    st0 = rand_state(n, 21)
    kx, ky = wfm.signed_k(n, n)
    k = np.sqrt(kx.astype(F64) ** 2 + ky.astype(F64) ** 2)
    om = p.speed * p.kref * (k / p.kref) ** p.dispersion
    uh0, vh0 = np.fft.fft2(st0[..., 0].astype(F64)), np.fft.fft2(st0[..., 2].astype(F64))
    uh0[0, 0] = vh0[0, 0] = 0.0
    e0 = wfm.energy(st0, p)
    st, phase, t0 = st0.copy(), 0.0, time.time()
    checkpoints = {100, 1000, 10000}
    for i in range(1, 10001):
        st, phase = fast_frame(st, p, phase)
        if i in checkpoints:
            ang = om * i * p.dt
            c = np.cos(ang)
            s = np.where(om > 0, np.sin(ang) / np.where(om > 0, om, 1.0), i * p.dt)
            u_ref = np.real(np.fft.ifft2(c * uh0 + s * vh0))
            v_ref = np.real(np.fft.ifft2(c * vh0 - om ** 2 * s * uh0))
            eu = np.linalg.norm(st[..., 0] - u_ref) / np.linalg.norm(u_ref)
            ev = np.linalg.norm(st[..., 2] - v_ref) / np.linalg.norm(v_ref)
            print(f"    frame {i:>6}: rel L2 error u {eu:.2e}  v {ev:.2e}   energy drift {(wfm.energy(st, p) - e0) / e0:+.2e}")
    print(f"    ({time.time() - t0:.1f} s)")

    # (c) the pass_dft chain (what the GPU computes): per-frame energy bias
    print("\n(c) the pass_dft chain, N = 32, 120 frames, zero damping: per-frame relative energy change")
    st = rand_state(32, 22)
    p = Params(speed=0.25, damping=0.0, fast_fft=False)
    e_a, t0 = wfm.energy(st, p), time.time()
    es = [e_a]
    for _ in range(120):
        st, _, _, _ = wfm.wave_frame(st, p)
        es.append(wfm.energy(st, p))
    d = np.diff(es) / np.array(es[:-1])
    print(f"    mean {d.mean():+.2e}  std {d.std():.2e}  max {d.max():+.2e}   ({time.time() - t0:.1f} s)")
    bias = max(float(d.max()), worst_useful, 0.0)
    need = bias / (2 * (1 / 60))
    print("\nFloor: energy decays as exp(-2 beta dt) per frame, so beta must exceed (worst gain)/(2 dt):")
    print(f"    worst gain used {bias:.2e} per frame -> beta >= {need:.2e} /s;  x100 for GPU transcendental error and margin: {100 * need:.2e} /s")


# =============================================================== T007
def expm2(om2, beta, dt):
    m = np.array([[0.0, 1.0], [-om2, -2.0 * beta]]) * dt
    s = max(0, int(np.ceil(np.log2(max(np.abs(m).sum(1).max(), 1e-30)))) + 1)
    m = m / 2.0 ** s
    e, term = np.eye(2), np.eye(2)
    for n in range(1, 24):
        term = term @ m / n
        e = e + term
    for _ in range(s):
        e = e @ e
    return e


def t007():
    print("== T007: operator-splitting accuracy of the real-space force (kick after the exact step)")
    print("Steady-state response of u to F sin(Omega t_n) kicked into v each frame, discrete vs exact continuous.")
    print("amp err = |Ud|/|Ue| - 1; phase resid = arg(Ud/Ue) + Omega*dt (a one-frame delay is inherent: force sampled at the frame start).")
    dt = 1 / 60
    print(f"\ndt = 1/60.  rows: Omega (Hz, Omega*dt);  columns: omega rad/s;  beta = 0.3.   cell: amp err % / phase resid mrad")
    omegas = (6.0, 25.0, 100.0, 300.0)
    print("            " + "".join(f"{'omega ' + format(o, 'g'):>22}" for o in omegas))
    worst = {}
    for f_hz in (0.5, 1, 2, 4, 8, 15):
        Om = TWO_PI * f_hz
        cells = []
        for om in omegas:
            beta = 0.3
            P = expm2(om * om, beta, dt)
            X = np.linalg.solve(np.exp(1j * Om * dt) * np.eye(2) - P, np.array([0.0, dt]))
            ud = X[0]
            ue = 1.0 / (om * om - Om * Om + 2j * beta * Om)
            amp = abs(ud) / abs(ue) - 1.0
            ph = np.angle(ud / ue) + Om * dt
            worst[f_hz] = max(worst.get(f_hz, 0.0), abs(amp))
            cells.append(f"{100 * amp:+8.2f}% /{1000 * ph:+8.1f}")
        print(f"  {f_hz:>5g} Hz ({Om * dt:.3f}) " + "".join(f"{c:>22}" for c in cells))
    print("\nworst |amp err| over the omega columns, by exciter frequency:")
    for f_hz, w in worst.items():
        print(f"    {f_hz:>5g} Hz (Omega*dt {TWO_PI * f_hz * dt:.3f}): {100 * w:.2f} %")
    print("\nKick placement: end-of-step kick (Lie, as the mirror does now) vs half-kick before + half after (Strang).")
    print("Amplitude error % of the steady response, beta = 0.3, by mode omega*dt (columns) and exciter Omega (rows); omega*dt <= pi only.")
    wdts = (0.1, 0.2, 0.4, 0.6, 0.8, 1.0, 1.5, 2.0, 3.0)
    print(f"{'':>14}" + "".join(f"{w:>9g}" for w in wdts))
    for f_hz in (0.5, 4.0, 10.0):
        Om = TWO_PI * f_hz
        for label in ("Lie", "Strang"):
            cells = []
            for wdt in wdts:
                om = wdt / dt
                P = expm2(om * om, 0.3, dt)
                b = np.array([0.0, dt])
                e = np.exp(1j * Om * dt)
                if label == "Lie":
                    X = np.linalg.solve(e * np.eye(2) - P, b)
                else:
                    X = np.linalg.solve(e * np.eye(2) - P, P @ (b / 2) + (b / 2) * e)
                ue = 1.0 / (om * om - Om * Om + 2j * 0.3 * Om)
                cells.append(100 * (abs(X[0]) / abs(ue) - 1.0))
            print(f"{f_hz:>5g} Hz {label:<7}" + "".join(f"{c:>+9.2f}" for c in cells))
    print("\nA uniform sponge (a scalar on u and v) commutes with the exact step, so splitting it costs nothing;")
    print("the sponge's error is only spatial (reflection), measured in t004.")
    kmax_corner = TWO_PI * 128 * np.sqrt(2)
    print(f"\nTemporal aliasing (omega*dt > pi) at the N = 256 corner bin, dispersion 1: speed limit pi/(dt*kmax) = {np.pi / (dt * kmax_corner):.3f} frame widths/s.")
    print("Above that the top bins alias in time (the step stays exact and stable); nu damps them (see t004).")


# =============================================================== T004
def edens(st, speed):
    """Local energy density 0.5 v^2 + 0.5 speed^2 |grad u|^2 (dispersion 1), float64, periodic."""
    u, v = st[..., 0].astype(F64), st[..., 2].astype(F64)
    n = u.shape[0]
    ux = (np.roll(u, -1, 1) - np.roll(u, 1, 1)) * (n / 2)
    uy = (np.roll(u, -1, 0) - np.roll(u, 1, 0)) * (n / 2)
    return 0.5 * v * v + 0.5 * speed ** 2 * (ux * ux + uy * uy)


def run_sponge(width, rate, edge, n=96):
    """Struck pulse at the centre; returns (reflect, left): the max inner-disc (r < 0.2) energy over
    t in [1.9, 3.1] s / E0, and the total energy at 4 s / E0. width and rate are set on the mirror module."""
    nx = (np.arange(n) + 0.5) / n
    xx, yy = np.meshgrid(nx, nx)
    inner = (xx - 0.5) ** 2 + (yy - 0.5) ** 2 < 0.2 ** 2
    wfm.SPONGE_WIDTH, wfm.SPONGE_RATE = F32(width), F32(rate)
    p = Params(speed=0.25, damping=0.001, nu=float(wfm.NU), edge=edge, fast_fft=True)
    st = struck_state(n, n, p)
    e0 = float(edens(st, p.speed).sum())
    refl = 0.0
    for i in range(1, 241):
        st, _ = fast_frame(st, p)
        if 114 <= i <= 186:
            refl = max(refl, float(edens(st, p.speed)[inner].sum()) / e0)
    return refl, float(edens(st, p.speed).sum()) / e0


def t004():
    print("== T004: kref, nu, sponge, exciter gain")
    print(f"\nkref = {float(wfm.KREF):.3f} = 2 pi * 8: mode 8 across the frame, wavelength 1/8 frame (32 texels at N = 256).")
    print("omega(kref) = speed * kref for every dispersion (pinned by test_wave_field); resolution-independent (frame widths).")

    print("\n(a) viscosity nu: beta(k) = nu k^2 at mode m (damping time 1/beta, seconds); struck pulse at N = 128, speed 0.25, damping 0.001")
    modes = (8, 16, 32, 64)
    print(f"{'nu':>9}" + "".join(f"{'  tau(mode ' + str(m) + ')':>16}" for m in modes) + "   energy kept at 0.5 s / 1 s / 3 s")
    n = 128
    for nu in (0.0, 1e-5, 3e-5, 1e-4, 3e-4):
        taus = [("inf" if nu == 0 else f"{1.0 / (nu * (TWO_PI * m) ** 2):.3g}") for m in modes]
        p = Params(speed=0.25, damping=0.001, nu=nu, fast_fft=True)
        st = struck_state(n, n, p)
        e0, kept = wfm.energy(st, p), []
        for i in range(1, 181):
            st, _ = fast_frame(st, p)
            if i in (30, 60, 180):
                kept.append(wfm.energy(st, p) / e0)
        print(f"{nu:>9.0e}" + "".join(f"{t:>16}" for t in taus) + "   " + " / ".join(f"{k:.3f}" for k in kept))

    print(f"\n(b) sponge: struck pulse at the centre, N = 96, speed 0.25, edge 1, nu {float(wfm.NU):g} (the mirror's NU), damping 0.001.")
    n = 96
    print("    reflect = max inner-disc (r < 0.2) energy over t in [1.9, 3.1] s / E0   (a reflection returns at ~2.2 s)")
    print("    left = total energy at 4 s / E0 (what the sponge did not absorb; edge 0 is the periodic reference)")
    keep = (wfm.SPONGE_WIDTH, wfm.SPONGE_RATE)
    r0, l0 = run_sponge(0.12, 30.0, 0.0)
    print(f"    edge 0 reference: reflect {r0:.4f}   left {l0:.3f}")
    print(f"    {'width':>7}{'rate':>7}{'reflect':>10}{'left':>9}")
    for width in (0.06, 0.12, 0.20):
        for rate in (1.0, 3.0, 10.0, 20.0, 30.0, 100.0):
            r, l = run_sponge(width, rate, 1.0)
            print(f"    {width:>7.2f}{rate:>7.0f}{r:>10.4f}{l:>9.3f}")
    wfm.SPONGE_WIDTH, wfm.SPONGE_RATE = keep

    print("\n(c) exciter gain: amplitude 1, 2 Hz, speed 0.25, damping 0.3, edge 0.5, the mirror's NU, N = 96, 6 s;")
    print("    max |u| over t in [4, 6] s with EX_GAIN as set; u is linear in EX_GAIN (no containment hit).")
    p = Params(speed=0.25, damping=0.3, nu=float(wfm.NU), edge=0.5, amplitude=1.0, frequency=2.0, fast_fft=True)
    st, phase, peak = new_state(n, n), 0.0, 0.0
    for i in range(1, 361):
        st, phase = fast_frame(st, p, phase)
        if i >= 240:
            peak = max(peak, float(np.abs(st[..., 0]).max()))
    print(f"    EX_GAIN {float(wfm.EX_GAIN):g}: max|u| {peak:.4g}  ->  EX_GAIN for max|u| = 1: {float(wfm.EX_GAIN) / peak:.4g}")
    p = Params(speed=0.25, damping=0.0, nu=0.0, fast_fft=True)
    st = struck_state(n, n, p)
    for _ in range(60):
        st, _ = fast_frame(st, p)
    print(f"    strike (u peak {float(wfm.STRIKE_AMP):g}) after 1 s: max|u| {float(np.abs(st[..., 0]).max()):.3f} (the ring, spreading as ~1/sqrt(r))")


# =============================================================== T005
def png(path, img):
    img = np.ascontiguousarray(np.clip(img, 0, 255).astype(np.uint8))
    h, w, _ = img.shape
    raw = b"".join(b"\x00" + img[y].tobytes() for y in range(h))

    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    data = (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))
    with open(path, "wb") as f:
        f.write(data)


def warmed_states(n=128):
    """Three states: driven steady state, struck ring mid-flight, plate waves (dispersion 2) mid-flight."""
    out = {}
    p = Params(speed=0.25, damping=0.3, nu=float(wfm.NU), edge=0.5, amplitude=1.0, frequency=2.0, fast_fft=True)
    st, phase, maxes = new_state(n, n), 0.0, []
    for i in range(1, 361):
        st, phase = fast_frame(st, p, phase)
        if i > 180:
            maxes.append(float(np.abs(st[..., 0]).max()))
    out["driven"] = (st, p, maxes)
    p = Params(speed=0.25, damping=0.05, nu=float(wfm.NU), edge=0.5, fast_fft=True)
    st = struck_state(n, n, p)
    for _ in range(60):
        st, _ = fast_frame(st, p)
    out["ring"] = (st, p, None)
    p = Params(speed=0.25, dispersion=2.0, damping=0.05, nu=float(wfm.NU), edge=0.5, fast_fft=True)
    st = struck_state(n, n, p)
    for _ in range(90):
        st, _ = fast_frame(st, p)
    out["plate"] = (st, p, None)
    return out


def map_luma(u, kind, g=0.5):
    if kind == "hard":
        return np.clip(0.5 + g * u, 0, 1)
    if kind == "tanh":
        return 0.5 + 0.5 * np.tanh(g * 2.0 * u)
    m = max(float(np.abs(u).max()), 1e-6)
    return 0.5 + 0.5 * u / m


def map_vec(ux, uy, kind, s=0.01):
    if kind == "hard":
        return np.clip(0.5 + 0.5 * s * ux, 0, 1), np.clip(0.5 + 0.5 * s * uy, 0, 1)
    if kind == "tanh":
        return 0.5 + 0.5 * np.tanh(s * ux), 0.5 + 0.5 * np.tanh(s * uy)
    m = max(float(max(np.abs(ux).max(), np.abs(uy).max())), 1e-6)
    return 0.5 + 0.5 * ux / m, 0.5 + 0.5 * uy / m


def t005():
    print("== T005: output mappings on warmed-up states (hard clamp / tanh / auto-range)")
    os.makedirs(OUT, exist_ok=True)
    states = warmed_states()
    tiles = {}
    for name, (st, p, maxes) in states.items():
        u = st[..., 0].astype(F64)
        ux, uy = (g.astype(F64) for g in wfm.gradient(st))
        print(f"\n[{name}]  max|u| {np.abs(u).max():.3f}  rms {u.std():.3f}   max|grad| {max(np.abs(ux).max(), np.abs(uy).max()):.2f}  p99|grad| {np.percentile(np.hypot(ux, uy), 99):.2f}")
        if maxes:
            print(f"   per-frame max|u| over the last 3 s: min {min(maxes):.3f} max {max(maxes):.3f}  (auto-range gain pumping x{max(maxes) / min(maxes):.2f})")
        for kind in ("hard", "tanh", "auto"):
            y = map_luma(u, kind)
            clipped = float(((y <= 0.001) | (y >= 0.999)).mean())
            sat = float((np.abs(y - 0.5) > 0.45).mean())
            print(f"   luma {kind:<5}: clipped {100 * clipped:5.2f}%  near-end (>0.45 from mid) {100 * sat:5.2f}%  p1 {np.percentile(y, 1):.3f}  p99 {np.percentile(y, 99):.3f}  std {y.std():.3f}")
            tiles[(name, "luma " + kind)] = np.stack([y, y, y], -1)
        for s in (0.002, 0.005, 0.01, 0.02, float(wfm.GRAD_SCALE)):
            rx, ry = map_vec(ux, uy, "hard", s)
            c = float(((rx <= 0.001) | (rx >= 0.999) | (ry <= 0.001) | (ry >= 0.999)).mean())
            print(f"   vec hard s={s:<6g}: clipped {100 * c:5.2f}%   range R [{rx.min():.3f}, {rx.max():.3f}]")
        for kind, s in (("hard", 0.01), ("tanh", 0.01), ("auto", 0.0)):
            rx, ry = map_vec(ux, uy, kind, s)
            tiles[(name, "vec " + kind)] = np.stack([rx, ry, np.full_like(rx, 0.5)], -1)
        rx, ry = map_vec(ux, uy, "tanh", 0.01)
        print(f"   vec tanh s=0.01: range R [{rx.min():.3f}, {rx.max():.3f}]  (never clips; saturation = |s*grad| > 2: {100 * float((np.abs(0.01 * ux) > 2).mean()):.2f}%)")
    cols = ["luma hard", "luma tanh", "luma auto", "vec hard", "vec tanh", "vec auto"]
    rows = list(states)
    n = 128
    sheet = np.zeros((len(rows) * n, len(cols) * n, 3))
    for r, nm in enumerate(rows):
        for c, col in enumerate(cols):
            sheet[r * n:(r + 1) * n, c * n:(c + 1) * n] = tiles[(nm, col)] * 255
    sheet = np.kron(sheet, np.ones((2, 2, 1)))
    path = os.path.join(OUT, "T005_mappings.png")
    png(path, sheet)
    print(f"\ncontact sheet: {path}")
    print("   rows: " + ", ".join(rows) + ";  columns: " + ", ".join(cols))


if __name__ == "__main__":
    sections = {"t003": t003, "t004": t004, "t005": t005, "t007": t007}
    for a in sys.argv[1:] or ["t003", "t007", "t004", "t005"]:
        sections[a]()
