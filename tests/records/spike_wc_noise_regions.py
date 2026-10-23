"""
spike_wc_noise_regions.py -- f_wc Phase 0, task T005 (2026-10-23, reframed).

The reframing (see tasks.md T005 "2026-10-23 (later) -- CORRECTED"): the
mechanism is NOISE-SUSTAINED pattern formation. A two-field kernel-coupled
sigmoid Wilson-Cowan system produces the Ermentrout-Cowan labyrinth/stripe
hallucination texture ONLY when driven every frame by persistent stochastic
forcing; seed-once runs always collapse. Confirmed against Michael Rule's
working webgpgpu implementation (headless readback + NumPy reproduction).

This sweep maps the (noise x drive) regime to find the rolls / hexagon /
spiral sub-regions within the labyrinth -- the four `form` parameter sets
(gate G1) and the autonomous-generator defaults.

Model (Rule's Psychedelic lineage, spectral Gaussian coupling as in
spike_wc_solver.py but with per-frame drive):

    Ue += ( F(Aee.(Ke*E) - Aie.(Ki*I) - He - be.Ve + Ne.noise) - Ue ).dt/Te
    Ui += ( F(Aei.(Ke*E) - Aii.(Ki*I) - Hi - bi.Vi + Ni.noise) - Ui ).dt/Ti
    Ve += (E - Ve).dt/ae          (adaptation, be=bi=0 in Psychedelic)

    Ke, Ki Gaussian (spectral exp(-sigma^2 k^2/2)), sigma_E < sigma_I
    (classic lateral-inhibition shape). F = logistic sigmoid.

Sweep axes:
  Ne      noise/drive level (the load-bearing new axis)
  sig_i   inhibitory kernel width (pattern wavelength; sigma_E = sig_i/1.45)
  Aee     self-excitation strength (moves across the labyrinth <-> uniform
          boundary)

Fixed (Psychedelic): Aie=14.5 Aei=13.7 Aii=13, He=3.1 Hi=3.5, Te=4 Ti=12.5,
dt=1, ae=50 ai=100, be=bi=0, Ni=Ne (noise on both like the demo), N=256,
1500 frames.

Usage: tests/run.sh tests/records/spike_wc_noise_regions.py
CSV rows to stdout: Ne,sig_i,Aee,label,k_star,std,lambda_px,f2,f6
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "lib"))
sys.path.insert(0, HERE)
import wc_classify as C  # noqa: E402

N = 256
FRAMES = 1500
DT = 1.0


def kgrid(n=N):
    k = 2.0 * np.pi * np.fft.fftfreq(n, d=1.0)
    kx, ky = np.meshgrid(k, k, indexing="xy")
    return kx, ky


KX, KY = kgrid()
K2 = KX**2 + KY**2
KXf, KYf = np.fft.fftshift(KX), np.fft.fftshift(KY)


def gkernel(sigma):
    return np.exp(-0.5 * sigma * sigma * K2)


def conv(u, K):
    return np.real(np.fft.ifft2(K * np.fft.fft2(u)))


def F(x):
    return 1.0 / (1.0 + np.exp(-np.clip(x, -60.0, 60.0)))


# Psychedelic base constants
AIE, AEI, AII = 14.5, 13.7, 13.0
HE, HI = 3.1, 3.5
TE, TI = 4.0, 12.5
AE_ADAPT, AI_ADAPT = 50.0, 100.0


def run_cell(Ne, sig_i, aee, n=N, frames=FRAMES, dt=DT, seed=1,
             aie=AIE, aei=AEI, aii=AII, he=HE, hi=HI, te=TE, ti=TI):
    """Run one (Ne, sig_i, Aee) cell with per-frame noise. Returns final E."""
    sig_e = sig_i / 1.45           # keep the Psychedelic 2/2.9 aspect ratio
    KE, KI = gkernel(sig_e), gkernel(sig_i)
    rng = np.random.default_rng(seed)
    E = rng.random((n, n)).astype(np.float32)
    I = rng.random((n, n)).astype(np.float32)
    for _ in range(frames):
        # Box-Muller like the demo (any Gaussian works; see ablation in tasks)
        na = rng.random((n, n)).astype(np.float32) * .999 + 0.0001
        nb = rng.random((n, n)).astype(np.float32) * .999 + 0.0001
        Nx = np.sqrt(-2.0 * np.log(na)) * np.cos(2.0 * np.pi * nb) * np.sqrt(dt)
        E = E + (F(aee * conv(E, KE) - aie * conv(I, KI) - he + Ne * Nx) - E) * (dt / te)
        I = I + (F(aei * conv(E, KE) - aii * conv(I, KI) - hi + Ne * Nx) - I) * (dt / ti)
    return E


def sweep_row(Ne, sig_i, aee):
    E = run_cell(Ne, sig_i, aee)
    label, k_star, d = C.classify(E)
    return dict(Ne=Ne, sig_i=sig_i, Aee=aee, label=label, k_star=k_star,
                std=d["std"], lambda_px=d.get("lambda_px", 0.0),
                f2=d.get("f2", 0.0), f6=d.get("f6", 0.0))


def row_csv(r):
    return (f"{r['Ne']},{r['sig_i']},{r['Aee']},{r['label']},{r['k_star']},"
            f"{r['std']:.4f},{r['lambda_px']:.1f},{r['f2']:.3f},{r['f6']:.3f}")


NE_VALUES = [0.1, 0.3, 0.5, 0.75, 1.0, 1.5]
SIGI_VALUES = [1.5, 2.9, 4.0, 6.0]
AEE_VALUES = [14.0, 16.1, 18.0, 20.0]


def main():
    slice_idx = None
    for a in sys.argv[1:]:
        if a.startswith("--slice="):
            lo, hi = a.split("=")[1].split(":")
            slice_idx = (int(lo), int(hi))
    cells = [(ne, si, ae) for ne in NE_VALUES for si in SIGI_VALUES for ae in AEE_VALUES]
    if slice_idx is not None:
        cells = cells[slice_idx[0]:slice_idx[1]]
    print("Ne,sig_i,Aee,label,k_star,std,lambda_px,f2,f6")
    for ne, si, ae in cells:
        print(row_csv(sweep_row(ne, si, ae)), flush=True)


if __name__ == "__main__":
    main()
