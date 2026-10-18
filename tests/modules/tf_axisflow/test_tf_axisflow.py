"""
test_tf_axisflow.py -- tier-1 NumPy mirror of the planned f_tf_axisflow bridge
(.specify/f_tf_axisflow/{spec,plan,tasks}.md, Phase 0 T001-T006).

Input is f_tf_tensormap outlet 1 (R,G = cos2t, sin2t packed, B = trace, A = coherence),
where theta is the dominant GRADIENT direction (across the edge). Output is a signed
vecfield: the reference direction r projected onto the EDGE line (mode 0, "along") or onto
the gradient axis (mode 1, "across"). No atan2, no sign choice.

Ground truth is independent of the mirror: brute-force vectors r - (g.r)g built from the
unpacked angle, analytic ramp directions, invariants, and a mutation check (along/across
swapped) that the chain test must catch.

Run:  tests/run.sh tests/modules/tf_axisflow/test_tf_axisflow.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
import test_tf_tensormap as tm  # noqa: E402
from tf_axisflow_mirror import (
    F32,
    _swirl,
    axisflow,
    refvec,
)


def pack(theta_deg, coh=1.0, trace=0.5, shape=(4, 4)):
    """Packed outlet-1 texture with constant axis theta (radians from degrees)."""
    th = np.deg2rad(theta_deg)
    t = g.texture(*shape)
    t[..., 0] = F32(np.cos(2 * th) * 0.5 + 0.5)
    t[..., 1] = F32(np.sin(2 * th) * 0.5 + 0.5)
    t[..., 2] = F32(trace)
    t[..., 3] = F32(coh)
    return g.store_float32(t)


def dec(o):
    return (o[..., 0] - F32(0.5)) * F32(2), (o[..., 1] - F32(0.5)) * F32(2)


def brute(theta_deg, phi_deg, mode):
    """Reference: unit vectors, no packing. mode 0 = r - (g.r)g, mode 1 = (g.r)g."""
    th, ph = np.deg2rad(theta_deg), np.deg2rad(phi_deg)
    gv = np.array([np.cos(th), np.sin(th)])
    r = np.array([np.cos(ph), np.sin(ph)])
    across = (gv @ r) * gv
    return (r - across) if mode == 0 else across


ANGLES = range(-180, 180, 15)


# --- T001/T002 properties vs brute force -------------------------------

def test_matches_bruteforce_both_modes():
    worst = 0.0
    for th in ANGLES:
        for ph in ANGLES:
            for mode in (0, 1):
                o = axisflow(pack(th), angle=ph, mode=mode, gate=0.0)
                vx, vy = dec(o)
                ref = brute(th, ph, mode)
                worst = max(worst, abs(float(vx[0, 0]) - ref[0]), abs(float(vy[0, 0]) - ref[1]))
    check("v vs brute force (all theta, phi, modes)", worst, 1e-5)


def test_axis_sign_invariance():
    """theta and theta+180 are the same axis: identical packed input, identical output."""
    worst = 0.0
    for th in ANGLES:
        a = axisflow(pack(th), angle=37, mode=0, gate=0.0)
        b = axisflow(pack(th + 180), angle=37, mode=0, gate=0.0)
        worst = max(worst, float(np.abs(a - b).max()))
    check("theta vs theta+180 output", worst, 2e-6)


def test_magnitudes_sin_and_cos():
    worst = 0.0
    for th in ANGLES:
        for ph in ANGLES:
            for mode, fn in ((0, np.sin), (1, np.cos)):
                vx, vy = dec(axisflow(pack(th), angle=ph, mode=mode, gate=0.0))
                mag = float(np.hypot(vx[0, 0], vy[0, 0]))
                worst = max(worst, abs(mag - abs(fn(np.deg2rad(th - ph)))))
    check("|v_along|=|sin(t-p)|, |v_across|=|cos(t-p)|", worst, 1e-5)


def test_along_plus_across_is_r():
    worst = 0.0
    for th in ANGLES:
        for ph in (0, 33, 90, 200):
            ax_, ay_ = dec(axisflow(pack(th), angle=ph, mode=0, gate=0.0))
            bx_, by_ = dec(axisflow(pack(th), angle=ph, mode=1, gate=0.0))
            r = np.array([np.cos(np.deg2rad(ph)), np.sin(np.deg2rad(ph))])
            worst = max(worst, abs(float(ax_[0, 0] + bx_[0, 0]) - r[0]),
                        abs(float(ay_[0, 0] + by_[0, 0]) - r[1]))
    check("along + across == r", worst, 1e-5)


def test_along_is_perpendicular_to_gradient():
    worst = 0.0
    for th in ANGLES:
        vx, vy = dec(axisflow(pack(th), angle=11, mode=0, gate=0.0))
        gx, gy = np.cos(np.deg2rad(th)), np.sin(np.deg2rad(th))
        worst = max(worst, abs(float(vx[0, 0]) * gx + float(vy[0, 0]) * gy))
    check("v_along . gradient axis", worst, 1e-5)


# --- T003 edge cases ---------------------------------------------------

def test_iso_is_neutral():
    t = g.texture(4, 4)
    t[...] = np.array([0.5, 0.5, 0.0, 0.0], F32)       # tensormap iso pixel
    for mode in (0, 1):
        o = axisflow(t, angle=40, mode=mode, gate=0.0)
        check(f"iso -> neutral (mode {mode})", float(np.abs(o - np.array([.5, .5, .5, 1], F32)).max()), 1e-6)


def test_black_input_is_neutral():
    t = g.texture(4, 4)
    t[...] = 0.0                                        # vs_black (unconnected)
    o = axisflow(t, angle=40, mode=0, gate=0.0)
    check("vs_black -> neutral", float(np.abs(o - np.array([.5, .5, .5, 1], F32)).max()), 1e-6)


def test_gate_scales_by_coherence():
    for coh in (0.0, 0.25, 1.0):
        v1x, v1y = dec(axisflow(pack(30, coh=coh), angle=70, gate=1.0))
        v0x, v0y = dec(axisflow(pack(30, coh=coh), angle=70, gate=0.0))
        check(f"gate=1 magnitude = coh ({coh})",
              abs(float(np.hypot(v1x[0, 0], v1y[0, 0])) - coh * float(np.hypot(v0x[0, 0], v0y[0, 0]))), 1e-6)
    v0x, v0y = dec(axisflow(pack(30, coh=0.0), angle=70, gate=0.0))
    check("gate=0 ignores coherence (|v| stays at |sin(t-p)|)",
          abs(float(np.hypot(v0x[0, 0], v0y[0, 0])) - abs(np.sin(np.deg2rad(30 - 70)))), 1e-6)


def test_gain_and_clamp():
    vx, vy = dec(axisflow(pack(90), angle=0, gate=0.0, gain=0.5))      # g=(0,1), r=(1,0): along=r
    check("gain 0.5 -> |v|=0.5", abs(float(vx[0, 0]) - 0.5), 1e-6)
    o = axisflow(pack(90), angle=0, gate=0.0, gain=10.0)
    check("clamped to [0,1]", float(max(o[..., 0].max() - 1.0, 0.0 - o[..., 0].min(), 0.0)), 0.0)


def test_bypass_is_neutral():
    o = axisflow(pack(30), angle=70, bypass=1.0)
    check("bypass -> neutral", float(np.abs(o - np.array([.5, .5, .5, 1], F32)).max()), 1e-6)


# --- T004 aspect -------------------------------------------------------

def test_aspect_identity_on_square():
    a = axisflow(pack(25), angle=70, width=480.0, height=480.0, gate=0.0)
    b = axisflow(pack(25), angle=70, width=64.0, height=64.0, gate=0.0)
    check("square frame, any size: same output", float(np.abs(a - b).max()), 1e-6)


def test_aspect_preserves_pixel_direction():
    worst = 0.0
    for W, H in ((1920.0, 1080.0), (1080.0, 1920.0), (640.0, 480.0)):
        for th in (0, 20, 45, 70, 110, 160):
            vx, vy = dec(axisflow(pack(th), angle=90, mode=0, gate=0.0, width=W, height=H))
            want = brute(th, 90, 0)
            if np.hypot(*want) < 1e-6:
                continue
            got = np.array([float(vx[0, 0]) * W, float(vy[0, 0]) * H])    # uv -> pixels
            cosang = (got @ want) / (np.hypot(*got) * np.hypot(*want))
            worst = max(worst, 1.0 - cosang)
    check("pixel-space direction preserved (1 - cos)", worst, 1e-5)


def test_aspect_unaligned_would_skew():
    """Why the correction exists: 45-degree edge on 16:9 without it is ~29 degrees in pixels."""
    W, H = 1920.0, 1080.0
    uv = np.array([1.0, 1.0]) / np.sqrt(2)
    ang = np.degrees(np.arctan2(uv[1] * H, uv[0] * W))
    note("uncorrected 45-degree edge on 16:9 lands at (deg)", float(ang))
    if not 28.0 < ang < 31.0:
        raise AssertionError(f"expected ~29.6, got {ang}")
    print("    ok   documents the skew the aspect correction removes")


# --- T005 chain with the tensormap mirror ------------------------------

def _chain_along(phi_ramp, ref_angle, swap=False):
    nx, ny, _, _ = g.grid(tm.H, tm.W)
    ph = np.deg2rad(phi_ramp)
    luma = (F32(0.5) + F32(0.3) * (np.cos(ph) * nx + np.sin(ph) * ny)).astype(F32)
    _, (_, o1) = tm.chain(tm._rgba_from_luma(luma), 3)
    out = axisflow(o1, angle=ref_angle, mode=0, gate=0.0, swap=swap)
    vx, vy = dec(out)
    return vx[tm.INTERIOR], vy[tm.INTERIOR]


def _chain_err(swap=False):
    worst = 0.0
    for phi in (0, 20, 45, 70, 90, 110, 135, 160):
        for ref in (0, 90, 45):
            vx, vy = _chain_along(phi, ref, swap)
            want = brute(phi, ref, 0)           # gradient axis = ramp direction
            worst = max(worst, float(np.abs(vx - want[0]).max()), float(np.abs(vy - want[1]).max()))
    return worst


def test_chain_ramps_follow_the_edge():
    err = _chain_err()
    check("tensormap->axisflow on ramps vs analytic (max abs)", err, 5e-3)


def test_chain_stripes_vertical_edges():
    """Vertical stripes: gradient is horizontal, edges vertical. Reference up -> flows up."""
    vx, vy = _chain_along(0, 90)
    check("vertical edge, r up: vy ~ 1", float(np.abs(vy - 1.0).max()), 5e-3)
    check("vertical edge, r up: vx ~ 0", float(np.abs(vx).max()), 5e-3)
    vx, vy = _chain_along(0, 0)
    check("vertical edge, r right: v ~ 0 (fade)", float(np.hypot(vx, vy).max()), 5e-3)


def test_mutation_swapped_modes_is_detected():
    good = _chain_err(False)
    bad = _chain_err(True)
    note("good worst error", good)
    note("mutated (along/across swapped) worst error", bad)
    if not (bad > 0.3 and good < 5e-3):
        raise AssertionError(f"mutation not detected: good={good:.3e}, swapped={bad:.3e}")
    print("    ok   along/across swap is caught by the ramp check")


# --- signed gain (2026-10-17) ------------------------------------------

def test_negative_gain_reverses_the_flow():
    worst = 0.0
    for gain in (0.25, 0.5, 1.0, 3.0):                  # 3.0 clamps: the clamp is symmetric
        px, py = dec(axisflow(pack(70), angle=20, gate=0.0, gain=gain))
        nx, ny = dec(axisflow(pack(70), angle=20, gate=0.0, gain=-gain))
        worst = max(worst, abs(float(px[0, 0] + nx[0, 0])), abs(float(py[0, 0] + ny[0, 0])))
    check("gain -g == minus gain +g (incl. clamped)", worst, 1e-6)
    vx, vy = dec(axisflow(pack(70), angle=20, gate=0.0, gain=0.0))
    check("gain 0 -> neutral", abs(float(vx[0, 0])) + abs(float(vy[0, 0])), 1e-6)


def test_constant_reference_equals_the_dial():
    """Square frame: a constant reference (cos a, sin a) with angle 0 is the dial at angle a."""
    worst = 0.0
    for th in ANGLES:
        for a in range(-180, 180, 30):
            for mode in (0, 1):
                dial = axisflow(pack(th), angle=a, mode=mode, gate=0.0)
                ref = axisflow(pack(th), angle=0, mode=mode, gate=0.0,
                               ref=refvec(np.cos(np.deg2rad(a)), np.sin(np.deg2rad(a))))
                worst = max(worst, float(np.abs(dial - ref).max()))
    check("constant reference == dial (square frame)", worst, 5e-6)


def test_angle_rotates_the_reference():
    worst = 0.0
    for th in ANGLES:
        for a in range(-180, 180, 30):
            dial = axisflow(pack(th), angle=a, gate=0.0)
            rot = axisflow(pack(th), angle=a, gate=0.0, ref=refvec(1.0, 0.0))
            worst = max(worst, float(np.abs(dial - rot).max()))
    check("angle rotates a (1,0) reference onto the dial direction", worst, 5e-6)


def test_reference_magnitude_scales_the_flow():
    fx, fy = dec(axisflow(pack(30), angle=0, gate=0.0, gain=0.5, ref=refvec(1.0, 0.0)))
    hx, hy = dec(axisflow(pack(30), angle=0, gate=0.0, gain=0.5, ref=refvec(0.5, 0.0)))
    check("half-length reference -> half the flow",
          abs(float(hx[0, 0] - fx[0, 0] / 2)) + abs(float(hy[0, 0] - fy[0, 0] / 2)), 5e-6)
    zx, zy = dec(axisflow(pack(30), angle=0, gate=0.0, ref=refvec(0.0, 0.0)))
    check("zero reference -> no flow", abs(float(zx[0, 0])) + abs(float(zy[0, 0])), 1e-6)


def test_absent_reference_falls_back_to_the_dial():
    black = g.texture(4, 4)
    black[...] = np.array([0, 0, 0, 1], F32)            # vs_black: an unconnected inlet
    worst = 0.0
    for th in ANGLES:
        for a in (0, 40, -120):
            for mode in (0, 1):
                a0 = axisflow(pack(th), angle=a, mode=mode, gate=0.0)
                a1 = axisflow(pack(th), angle=a, mode=mode, gate=0.0, ref=black)
                worst = max(worst, float(np.abs(a0 - a1).max()))
    check("vs_black reference == no reference", worst, 1e-7)


def test_per_pixel_reference_matches_bruteforce():
    """Every pixel: r - (g.r) g with that pixel's own r and own axis, built without packing."""
    n = 32
    y, x = np.mgrid[0:n, 0:n]
    th = np.deg2rad((x * 7 + y * 13) % 180)
    t = g.texture(n, n)
    t[..., 0] = (np.cos(2 * th) * 0.5 + 0.5).astype(F32)
    t[..., 1] = (np.sin(2 * th) * 0.5 + 0.5).astype(F32)
    t[..., 2] = F32(0.5)
    t[..., 3] = F32(1.0)
    ref, rvx, rvy = _swirl(n)
    out = axisflow(g.store_float32(t), gate=0.0, width=float(n), height=float(n), ref=ref)
    vx, vy = dec(out)
    gx, gy = np.cos(th), np.sin(th)
    dot = gx * rvx + gy * rvy
    worst = max(float(np.abs(vx - (rvx - dot * gx)).max()), float(np.abs(vy - (rvy - dot * gy)).max()))
    check("per-pixel r and axis vs brute force (max abs)", worst, 5e-6)


def test_reference_flow_is_seamless():
    """The projection is a contraction, so the output is never rougher than the reference:
    adjacent-pixel jumps in v are bounded by those in r (no seam is introduced)."""
    n = 32
    ref, _, _ = _swirl(n)
    for th in (0, 33, 90, 150):
        t = pack(th, shape=(n, n))
        vx, vy = dec(axisflow(t, gate=0.0, width=float(n), height=float(n), ref=ref))
        rx, ry = dec(ref)
        dv = max(float(np.hypot(np.diff(vx, axis=1), np.diff(vy, axis=1)).max()),
                 float(np.hypot(np.diff(vx, axis=0), np.diff(vy, axis=0)).max()))
        dr = max(float(np.hypot(np.diff(rx, axis=1), np.diff(ry, axis=1)).max()),
                 float(np.hypot(np.diff(rx, axis=0), np.diff(ry, axis=0)).max()))
        check(f"max neighbor jump in v <= in r (axis {th})", max(dv - dr, 0.0), 1e-5)


def test_reference_passes_through_when_the_edge_is_parallel():
    """16:9: where the edge runs along the reference, the reference comes back unchanged."""
    W, H = 1920.0, 1080.0
    worst = 0.0
    for vx, vy in ((0.3, 0.4), (-0.5, 0.2), (0.0, 0.7), (0.6, 0.0)):
        rpx, rpy = vx * W / H, vy                     # pixel-space direction (short side = H)
        th = np.degrees(np.arctan2(rpy, rpx)) + 90.0  # gradient axis perpendicular to it
        o = axisflow(pack(th), angle=0, gate=0.0, width=W, height=H, ref=refvec(vx, vy))
        dx, dy = dec(o)
        worst = max(worst, abs(float(dx[0, 0]) - vx), abs(float(dy[0, 0]) - vy))
    check("parallel edge returns the reference (16:9)", worst, 1e-5)


if __name__ == "__main__":
    sys.exit(run(globals()))
