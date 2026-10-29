"""spike_immiscible_constants.py -- T004: stability sweep that fixes the provisional constants of
immiscible_mirror.py (A_STAB, MDT_MAX, MDT_EXP, PHI_CLAMP, RESEED_AMP, smallest iface).

Offline NumPy only, spectral stage (no flow), 256 x 256 float32, periodic.

Sections (run one at a time; each prints a table):
  s1  stabiliser a x coarsen x iface: energy rise, NaN, max |phi| over 150 frames from noise
  s2  coarsening law: frames for the length scale to double after separation, per coarsen
  s3  smallest usable iface: stripe pair relaxed to steady state vs the tanh profile
  s4  reset noise: frames until separation (std(phi) > 0.5) per amplitude and fill

Run: tests/py.sh tests/records/spike_immiscible_constants.py s1     (then s2 s3 s4)
RESULT: recorded in .specify/stable/f_vf_immiscible/tasks.md Record (T004).
"""
import sys
import time
from multiprocessing import Pool

import numpy as np

import immiscible_mirror as im
from gpu_sim import F32
from immiscible_mirror import Params

N = 256

import os
if os.environ.get("IMM_MDT_MAX"):      # top level so spawned Pool workers see it too
    im.MDT_MAX = float(os.environ["IMM_MDT_MAX"])
if os.environ.get("IMM_A"):
    im.A_STAB = float(os.environ["IMM_A"])


def length_scale(phi):
    """Domain size ~ 1 / (interface density) = 1 / mean|grad phi| (per unit domain length).
    The structure-factor first moment was tried first and is dominated by the interface tail."""
    p = phi.astype(np.float64)
    gx = (np.roll(p, -1, 1) - np.roll(p, 1, 1)) * (N / 2.0)
    gy = (np.roll(p, -1, 0) - np.roll(p, 1, 0)) * (N / 2.0)
    m = float(np.sqrt(gx * gx + gy * gy).mean())
    return 1.0 / m if m > 0 else float("inf")


# ------------------------------------------------------------------ s1
def s1_job(args):
    a, c, iface, amp = args
    im.A_STAB = a
    p = Params(iface=iface, coarsen=c)
    st = im.pass_stage(np.zeros((N, N, 4), F32), 1.0, 3, 0.0, amp)
    e_prev = im.free_energy(st[..., 0], iface)
    worst, nbad, pmax, nan = 0.0, 0, 0.0, False
    for _ in range(150):
        st = im.spectral_step(st, p)
        phi = st[..., 0]
        if not np.isfinite(phi).all():
            nan = True
            break
        pmax = max(pmax, float(np.abs(phi).max()))
        e = im.free_energy(phi, iface)
        rise = e - e_prev
        worst = max(worst, rise)
        nbad += rise > 1e-6
        e_prev = e
    return (a, c, iface, amp, worst, nbad, pmax, nan)


def s1():
    jobs = [(a, c, i, amp) for a in (0.5, 1.0, 1.5, 2.0) for c in (0.3, 1, 2, 4, 8)
            for i in (2, 4, 8) for amp in (0.05,)]
    jobs += [(a, 8, 4, 0.9) for a in (0.5, 1.0, 1.5, 2.0)]    # stress start: huge noise
    print("a    coarsen mdt       iface amp   worst_rise   n_rise>1e-6  max|phi|  nan")
    with Pool() as pool:
        for a, c, i, amp, worst, nbad, pmax, nan in pool.imap(s1_job, jobs):
            print(f"{a:<4} {c:<7} {im.MDT_MAX * c ** im.MDT_EXP:<9.2e} {i:<5} {amp:<5} {worst:<12.2e} {nbad:<12} {pmax:<9.4f} {nan}")


# ------------------------------------------------------------------ s2
def s2_job(c):
    p = Params(iface=4.0, coarsen=c)
    st = im.pass_stage(np.zeros((N, N, 4), F32), 1.0, 3, 0.0, 0.05)
    t_sep, L0, tdbl = None, None, None
    marks = (100, 300, 1000, 3000, 7000)
    hist = {}
    for t in range(1, 12001):
        st = im.spectral_step(st, p)
        if t % 10:
            continue
        phi = st[..., 0]
        if t_sep is None and phi.std() > 0.9:
            t_sep, L0 = t, length_scale(phi)
        if t_sep is not None:
            L = length_scale(phi)
            if tdbl is None and L >= 2 * L0:
                tdbl = t - t_sep
            for m in marks:
                if t - t_sep == m:
                    hist[m] = L
    return (c, t_sep, L0, tdbl, hist)


def s2():
    print("coarsen mdt        t_sep   L0      frames_to_double   L at +100 +300 +1000 +3000 +7000 frames")
    with Pool() as pool:
        for c, t_sep, L0, tdbl, hist in pool.imap(s2_job, (0.1, 0.2, 0.3, 0.5, 0.7, 1.0)):
            hs = " ".join(f"{hist.get(m, float('nan')):.3f}" for m in (100, 300, 1000, 3000, 7000))
            print(f"{c:<7} {im.MDT_MAX * c ** im.MDT_EXP:<11.2e} {t_sep!s:<7} {L0:<7.3f} {tdbl!s:<18} {hs}")


# ------------------------------------------------------------------ s3
def s3_job(iface):
    p = Params(iface=iface, coarsen=2.0)
    x = np.arange(N)
    phi0 = np.tile(0.98 * np.sign(np.sin(2 * np.pi * 2 * (x + 0.5) / N)), (N, 1))
    st = im.phi_state(phi0)
    for t in range(1, 4001):
        new = im.spectral_step(st, p)
        d = float(np.abs(new[..., 0] - st[..., 0]).max())
        st = new
        if d < 1e-6:
            break
    row = st[0, :, 0].astype(np.float64)
    # first rising zero crossing, linear interpolation
    j = next(i for i in range(N - 1) if row[i] < 0 <= row[i + 1])
    x0 = j + (-row[j]) / (row[j + 1] - row[j])
    sel = np.arange(j - 3 * int(np.ceil(iface)), j + 3 * int(np.ceil(iface)) + 2)
    err = float(np.abs(row[sel] - np.tanh((sel - x0) / (np.sqrt(2) * iface))).max())
    return (iface, t, d, err, float(row.max()), float(row.min()))


def s3():
    print("iface  frames  last_delta  max_err_vs_tanh  phi_max  phi_min")
    with Pool() as pool:
        for iface, t, d, err, hi, lo in pool.imap(s3_job, (1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0)):
            print(f"{iface:<6} {t:<7} {d:<11.1e} {err:<16.4f} {hi:<8.4f} {lo:.4f}")


# ------------------------------------------------------------------ s4
def s4_job(args):
    amp, fill = args
    p = Params(iface=4.0, coarsen=0.3, fill=fill)
    st = im.pass_stage(np.zeros((N, N, 4), F32), 1.0, 3, fill, amp)
    for t in range(1, 3001):
        st = im.spectral_step(st, p)
        if st[..., 0].std() > 0.5:
            return (amp, fill, t, float(st[..., 0].mean()))
    return (amp, fill, None, float(st[..., 0].mean()))


def s4():
    jobs = [(amp, fill) for amp in (0.005, 0.01, 0.05, 0.1, 0.3) for fill in (0.0, 0.3)]
    print("amp    fill  frames_to_std>0.5  final_mean")
    with Pool() as pool:
        for amp, fill, t, m in pool.imap(s4_job, jobs):
            print(f"{amp:<6} {fill:<5} {t!s:<18} {m:.5f}")


if __name__ == "__main__":
    t0 = time.time()
    for name in sys.argv[1:]:
        print(f"--- {name}")
        globals()[name]()
    print(f"({time.time() - t0:.0f} s)")
