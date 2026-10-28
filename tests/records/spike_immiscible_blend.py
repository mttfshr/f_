"""spike_immiscible_blend.py -- T007 / experiment 2 (decides G2): how large is the divergence the
blend adds, and does the interface-aware rule lower its peak?

Two fluid_mirror Fluids driven by the SAME stirring force (the T006 recipe), A calm and B viscous, in
two flavours: both divergence-free (project 1, project 1) and mixed (project 1, project 0.3).
phi is advected by the plain blend of the two velocities and evolved by the module's Cahn-Hilliard
step (the coupled stage-1 loop, no stage-2 feedback) from noise, 500 frames (coarsen 1.0, fill 0).
Also measured on a fixed half-and-half phi (two straight tanh interfaces) with the same velocities.
Measured on frames 400..500 every 20 and averaged:
  rms(div), p99|div|, max|div| of the blended velocity, divided by the sources' rms |grad u|;
  the normal jump |(uB - uA).n| at interface texels, p50/p90/p99 over rms|u|.
Rules: plain, and interface-aware with three smoothstep bands (S_LO, S_HI).

Run (needs the test import path):  . tests/_log.sh >/dev/null; export PYTHONPATH
  uv run --no-project --with numpy python3 tests/records/spike_immiscible_blend.py
"""
import numpy as np

import fluid_mirror as fm
import immiscible_mirror as im
from gpu_sim import F32
from immiscible_mirror import Params
from spike_immiscible_stirring import force_tex, packed, tanh_phi

N = 256
WARM, FRAMES = 200, 500
SAMPLE = list(range(400, 501, 20))
BANDS = {"plain": None, "aware .05-.35": (0.05, 0.35), "aware .02-.15": (0.02, 0.15), "aware .10-.60": (0.10, 0.60)}


def ddx(f):
    return (np.roll(f, -1, 1) - np.roll(f, 1, 1)) * (N / 2.0)


def ddy(f):
    return (np.roll(f, -1, 0) - np.roll(f, 1, 0)) * (N / 2.0)


def div(u):
    return ddx(u[..., 0]) + ddy(u[..., 1])


def rms(x):
    return float(np.sqrt(np.mean(np.asarray(x, np.float64) ** 2)))


def vel(st):
    return np.stack([st[..., 0], st[..., 2]], -1)


def gradnorm(u):
    return rms(np.stack([ddx(u[..., 0]), ddy(u[..., 0]), ddx(u[..., 1]), ddy(u[..., 1])]))


def measure(uA, uB, phi, iface):
    out = {}
    gsrc = 0.5 * (gradnorm(uA) + gradnorm(uB))
    gx, gy = ddx(phi) / N, ddy(phi) / N          # per texel
    mag = np.hypot(gx, gy)
    mask = mag > 0.3 / (np.sqrt(2.0) * iface)
    n = np.stack([gx, gy], -1) / np.maximum(mag, 1e-9)[..., None]
    jump = np.abs(((uB - uA) * n).sum(-1))[mask]
    for name, band in BANDS.items():
        if band is not None:
            im.S_LO, im.S_HI = band
        u = im.blend_vel(uA, uB, phi.astype(F32), iface, 0.0 if band is None else 1.0)
        d = np.abs(div(u))
        out[name] = (rms(d) / gsrc, float(np.percentile(d, 99)) / gsrc, float(d.max()) / gsrc)
    im.S_LO, im.S_HI = 0.05, 0.35
    u0 = 0.5 * (uA + uB)
    ru = rms(u0)
    out["jump"] = (float(np.percentile(jump, 50)) / ru, float(np.percentile(jump, 90)) / ru,
                   float(np.percentile(jump, 99)) / ru, float(mask.mean()))
    return out


def run_pair(label, pa, pb):
    p = Params(iface=4.0, coarsen=1.0, inject=0.0)
    fa, fb = fm.zero_state(N), fm.zero_state(N)
    for t in range(WARM):
        f = force_tex(t)
        fa, fb = fm.step(fa, f, pa), fm.step(fb, f, pb)
    phi_st = im.seed(N, p, 3)
    xs = (np.arange(N) + 0.5)[None, :] * np.ones((N, 1))
    half = tanh_phi(64.0 - np.abs(xs - 128.0))        # phase B for |x - 128| < 64: two straight interfaces
    acc = {"stirred": [], "half": []}
    for t in range(1, FRAMES + 1):
        f = force_tex(WARM + t - 1)
        fa, fb = fm.step(fa, f, pa), fm.step(fb, f, pb)
        uA, uB = vel(fa), vel(fb)
        uab = np.zeros((N, N, 4), F32)
        uab[..., 0:2], uab[..., 2:4] = uA, uB
        a = im.adv(phi_st, uab, None, p)
        phi_st = im.ix_cleanup(fm.ifft2_np(im.spec(fm.fft2_np(a), p)))
        if t in SAMPLE:
            acc["stirred"].append(measure(uA, uB, phi_st[..., 0], 4.0))
            acc["half"].append(measure(uA, uB, half, 4.0))
    print(f"\n=== {label}: rms|uA| {rms(uA):.3f}  rms|uB| {rms(uB):.3f}  rms|grad uA| {gradnorm(uA):.1f}  "
          f"rms|grad uB| {gradnorm(uB):.1f}  (div of sources: A {rms(div(uA)):.2f}, B {rms(div(uB)):.2f})")
    print("phi case  rule             rms(div)/g  p99/g   max/g")
    for case, rows in acc.items():
        for name in BANDS:
            m = np.mean([r[name] for r in rows], axis=0)
            print(f"{case:<9} {name:<16} {m[0]:<11.3f} {m[1]:<7.3f} {m[2]:.3f}")
        j = np.mean([r["jump"] for r in rows], axis=0)
        print(f"{case:<9} normal jump/rms|u|: p50 {j[0]:.3f}  p90 {j[1]:.3f}  p99 {j[2]:.3f}   interface area {j[3] * 100:.1f}%")


if __name__ == "__main__":
    import sys
    if "mild" in sys.argv[1:]:      # a milder contrast, so the viscous Fluid still moves
        run_pair("A visc 0.0 proj 1  |  B visc 0.3 proj 1",
                 fm.Params(viscosity=0.0, project=1.0), fm.Params(viscosity=0.3, project=1.0))
        sys.exit(0)
    run_pair("A visc 0.0 proj 1  |  B visc 0.7 proj 1",
             fm.Params(viscosity=0.0, project=1.0), fm.Params(viscosity=0.7, project=1.0))
    run_pair("A visc 0.0 proj 1  |  B visc 0.7 proj 0.3",
             fm.Params(viscosity=0.0, project=1.0), fm.Params(viscosity=0.7, project=0.3))
