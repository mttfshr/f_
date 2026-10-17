"""
spike_structure_tensor_range.py -- what's the actual numeric range of
Jxx/Jxy/Jyy (and the eigenvalues/anisotropy derived from them) for the
f_tf_tensormap producer (.specify/f_tf_tensormap/spec.md), across a few
representative input regimes? This is open question 1 in that spec:
gradient energy is unbounded and scales with input contrast and smoothing
radius -- same category of problem f_vf_fieldmap solved with its `strength`
param, but that precedent's default (4.0) was tuned for its own pipeline
(signed gradient straight into an f_vecfield texture) and doesn't tell us
what a structure tensor's squared-gradient terms need.

Gradient operator: the project's own verified Sobel kernel
(.specify/stable/f_vf_sobel/spec.md, bench-confirmed in Max 9 on
2026-06-18), reused here rather than introducing Scharr untested. This
partially answers open question 3 (gradient operator) by removing one
reason to prefer something unverified -- Sobel already has a working,
checked codebox in this library. A numeric Scharr-vs-Sobel comparison would
still be worth doing later if Sobel turns out insufficiently sharp for fine
grain/weave-scale structure, but it isn't blocking this question.

Test content (synthetic, built from gpu_sim primitives -- no live Jitter
needed):
  - flat: constant value, zero gradient everywhere. Sanity floor.
  - edge: a single step edge at a few contrast levels. Proxy for
    f_weave/f_grain-scale boundaries.
  - noise: smooth value noise (coarse white noise, bilinearly upsampled via
    gpu_sim.sample -- literally the sim's own texture-fetch model used as a
    smooth-noise generator). Proxy for jit.gl.bfg Perlin, the input
    f_vf_fieldmap's own spec treats as its representative case.

For each, computes Jxx/Jxy/Jyy at a few smoothing radii, then trace
(= Jxx+Jyy, "how much structure") and anisotropy ((lambda1-lambda2)/trace,
"how directional") -- the two outlet-3 candidates from the spec's open
question 2, reported alongside each other since they're the natural axes
to check range on regardless of which representation outlet 3 lands on.

Run:
  uv run --no-project --with numpy --with matplotlib python3 tests/spike_structure_tensor_range.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import gpu_sim as g  # noqa: E402

F32 = np.float32


def sobel_gradient(luma):
    """Verified 3x3 Sobel kernel from .specify/stable/f_vf_sobel/spec.md,
    vectorized over the whole (H, W) array via edge-clamp padding + slicing
    instead of per-pixel sample() calls. Same kernel, same clamp-to-edge
    boundary behavior, just applied to every pixel at once."""
    p = np.pad(luma, 1, mode="edge")
    tl, tc, tr = p[0:-2, 0:-2], p[0:-2, 1:-1], p[0:-2, 2:]
    ml, mr = p[1:-1, 0:-2], p[1:-1, 2:]
    bl, bc, br = p[2:, 0:-2], p[2:, 1:-1], p[2:, 2:]

    gx = (-tl + tr) + F32(-2.0) * ml + F32(2.0) * mr + (-bl + br)
    gy = (-tl - F32(2.0) * tc - tr) + (bl + F32(2.0) * bc + br)
    return gx.astype(F32), gy.astype(F32)


def _box_1d(a, radius, axis):
    if radius <= 0:
        return a
    k = 2 * radius + 1
    pad_width = [(0, 0)] * a.ndim
    pad_width[axis] = (radius, radius)
    p = np.pad(a, pad_width, mode="edge")
    csum = np.cumsum(p, axis=axis)
    zero_shape = list(csum.shape)
    zero_shape[axis] = 1
    csum = np.concatenate([np.zeros(zero_shape, F32), csum], axis=axis)
    sl_hi = [slice(None)] * a.ndim
    sl_lo = [slice(None)] * a.ndim
    sl_hi[axis] = slice(k, None)
    sl_lo[axis] = slice(None, -k)
    window_sum = csum[tuple(sl_hi)] - csum[tuple(sl_lo)]
    return (window_sum / F32(k)).astype(F32)


def box_smooth(a, radius):
    """Separable box blur, edge-clamped, radius in pixels (0 = no smoothing).
    This is the `radius` param from the spec's Field Architecture section --
    what turns per-pixel gradient energy into local structure-tensor energy
    over a neighborhood."""
    return _box_1d(_box_1d(a, radius, axis=1), radius, axis=0)


def structure_tensor(luma, radius):
    gx, gy = sobel_gradient(luma)
    Jxx = box_smooth(gx * gx, radius)
    Jxy = box_smooth(gx * gy, radius)
    Jyy = box_smooth(gy * gy, radius)
    return Jxx, Jxy, Jyy


def eigen(Jxx, Jxy, Jyy):
    trace = Jxx + Jyy
    diff = Jxx - Jyy
    disc = np.sqrt(np.maximum(diff * diff + F32(4.0) * Jxy * Jxy, F32(0.0)))
    lambda1 = F32(0.5) * (trace + disc)
    lambda2 = F32(0.5) * (trace - disc)
    aniso = np.where(trace > F32(1e-8),
                      (lambda1 - lambda2) / np.maximum(trace, F32(1e-8)),
                      F32(0.0))
    return trace, lambda1, lambda2, aniso


# --- test content -----------------------------------------------------

def flat_content(h=192, w=192, value=0.5):
    return np.full((h, w), F32(value), F32)


def edge_content(h=192, w=192, contrast=1.0):
    luma = np.zeros((h, w), F32)
    luma[:, w // 2:] = F32(contrast)
    return luma


def noise_content(h=192, w=192, coarse=8, seed=0):
    """Smooth value noise: coarse white noise bilinearly upsampled via
    gpu_sim.sample -- a cheap stand-in for jit.gl.bfg Perlin at medium
    frequency (f_vf_fieldmap's own reference case for 'typical' content)."""
    rng = np.random.default_rng(seed)
    coarse_tex = g.texture(coarse, coarse)
    coarse_tex[..., 0] = rng.uniform(0.0, 1.0, (coarse, coarse)).astype(F32)
    nx, ny, _, _ = g.grid(h, w)
    sampled = g.sample(coarse_tex, nx, ny)
    return sampled[..., 0]


def summarize(label, luma, radii=(0, 1, 3, 6)):
    print(f"--- {label} ---")
    for r in radii:
        Jxx, Jxy, Jyy = structure_tensor(luma, r)
        trace, l1, l2, aniso = eigen(Jxx, Jxy, Jyy)
        print(f"  radius={r:>2}  trace: {trace.min():.5f}..{trace.max():.5f} "
              f"(p50={np.percentile(trace, 50):.5f}, p95={np.percentile(trace, 95):.5f})  "
              f"Jxy: {Jxy.min():+.5f}..{Jxy.max():+.5f}  "
              f"aniso: {aniso.min():.3f}..{aniso.max():.3f}")


def main():
    summarize("flat", flat_content())
    for contrast in (0.1, 0.5, 1.0):
        summarize(f"edge (contrast={contrast})", edge_content(contrast=contrast))
    for seed in (0, 1, 2):
        summarize(f"noise (seed={seed})", noise_content(seed=seed))

    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("\nmatplotlib not available -- numeric summary only")
        return

    out_dir = HERE.parent / "scratch"
    out_dir.mkdir(exist_ok=True)

    luma = noise_content(seed=0)
    Jxx, Jxy, Jyy = structure_tensor(luma, radius=3)
    trace, l1, l2, aniso = eigen(Jxx, Jxy, Jyy)
    theta = 0.5 * np.arctan2(2 * Jxy, Jxx - Jyy)

    fig, ax = plt.subplots(1, 3, figsize=(15, 5))
    ax[0].imshow(luma, cmap="gray")
    ax[0].set_title("source (noise, seed=0)")
    im1 = ax[1].imshow(trace, cmap="viridis")
    ax[1].set_title("trace (structure strength), radius=3")
    fig.colorbar(im1, ax=ax[1], fraction=0.046)
    im2 = ax[2].imshow(aniso, cmap="magma", vmin=0, vmax=1)
    ax[2].set_title("anisotropy, radius=3")
    fig.colorbar(im2, ax=ax[2], fraction=0.046)

    step = 10
    h, w = theta.shape
    yy, xx = np.mgrid[0:h:step, 0:w:step]
    u = np.cos(theta[yy, xx])
    v = np.sin(theta[yy, xx])
    ax[1].quiver(xx, yy, u, v, color="white", scale=30, width=0.003, headwidth=0)

    for a in ax:
        a.set_xticks([])
        a.set_yticks([])

    fig.tight_layout()
    fp = out_dir / "structure_tensor_range.png"
    fig.savefig(fp, dpi=110)
    print(f"\nfigure: {fp}")


if __name__ == "__main__":
    main()
