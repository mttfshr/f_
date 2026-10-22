"""Live vs mirror: the left/right edge columns of the module's real output, with NO mask (2026-10-21).
Run (needs Max, tests/bench/bench_module.maxpat; close Vsynth performance patches first):
    tests/bench.sh scratch/lbm_live_edges.py
Mirror half only (no Max):  tests/py.sh scratch/lbm_live_edges.py --mirror-only

The input is a 192 x 192 black mask, so the module's output is 192 columns wide: output column = lattice column.
Captures the live output at four consecutive frame counts (each from a fresh bench session; the solver is deterministic)
and prints, for the live module and for the mirror at similar frame counts:
  - per-column profile of R and G (mean over rows) for the first 8, last 8 columns and the interior
  - the spread over rows of R and G in columns 0, 1, W-2, W-1 (a uniform column has none)
  - frame-to-frame change per band of columns (the flicker Matt sees in the edge bands)"""
import sys
import numpy as np

N = 192
W, H = 192, 108
WARM = (240, 241, 242, 243)


def mirror_frames():
    import paths  # noqa: F401
    from vf_lbm_mirror import F32, equilibrium, pack, lbm_step, encode
    ripple = (0.02 * 0.08 * np.sin(0.3 * np.arange(W)))[None, :] * np.ones((H, 1))
    pl = pack(equilibrium(np.ones((H, W), F32), np.full((H, W), 0.08, F32), ripple.astype(F32)))
    mask = np.zeros((H, W), bool)
    out = {}
    for n in range(1, max(WARM) + 1):
        pl, enc = lbm_step(pl, mask, 1.97, 0.08, 3.0)
        if n in WARM:
            out[n] = np.asarray(enc, np.float64)           # (H, W, 4): the mirror's encode at the solver size
    return [out[k] for k in WARM]


def live_frames():
    import paths  # noqa: F401
    import modulebench as mb
    black = np.zeros((N, N, 4), np.float32)
    black[..., 3] = 1.0
    frames = []
    for w in WARM:
        r, plan, info = mb.run_module("f_vf_lbm", n=N, warmup=w, settle=6, first_input=black)
        frames.append(r["arrays"]["base"][1].astype(np.float64))
    return frames


def report(tag, frames):
    f0 = frames[0]
    h, w = f0.shape[:2]
    print(f"\n=== {tag}: output {w}x{h}, frame sequence {WARM}")
    col = lambda ch: f0[..., ch].mean(axis=0)
    for ch, name in ((0, "R"), (1, "G")):
        c = col(ch)
        print(f"  {name} mean per column: first 8 {np.round(c[:8], 4).tolist()}")
        print(f"  {name} mean per column: interior mean {c[10:-10].mean():.4f}   last 8 {np.round(c[-8:], 4).tolist()}")
    for name, k in (("col 0", 0), ("col 1", 1), (f"col {w - 2}", w - 2), (f"col {w - 1}", w - 1)):
        print(f"  spread over rows, {name}: R {f0[:, k, 0].std():.5f}  G {f0[:, k, 1].std():.5f}")
    d = np.mean([np.abs(frames[i + 1][..., :2] - frames[i][..., :2]) for i in range(len(frames) - 1)], axis=0)   # (h, w, 2)
    bands = {"cols 0-2": slice(0, 3), "cols 3-6": slice(3, 7), "interior": slice(10, w - 10),
             f"cols {w - 7}-{w - 4}": slice(w - 7, w - 3), f"cols {w - 3}-{w - 1}": slice(w - 3, w)}
    print("  frame-to-frame change (mean |dR|,|dG|) per band:")
    for name, sl in bands.items():
        print(f"     {name:<12} {float(d[:, sl].mean()):.5f}")


if __name__ == "__main__":
    report("MIRROR (empty mask, omega 1.97, Wind 0.08, gain 3)", mirror_frames())
    if "--mirror-only" not in sys.argv:
        report("LIVE module, real chain, empty mask", live_frames())
