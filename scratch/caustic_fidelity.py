"""
caustic_fidelity.py -- does f_caustic's brightness weight track a physical caustic?

Scratch research script for ideas/optics_map.md research item 1. It changes
nothing in the module; it mirrors src/f_caustic/codebox_v2.gen in NumPy and
compares it with an independent ground truth.

Physical model (the module's own convention: the field is the direction light
is displaced):  a ray leaving glass point u lands at x = u + d * F(u).  With a
uniform source the illuminance at x is  sum over preimages u of 1/|det(I+d*J)|,
J = dF/du.  Ground truth here does NOT use that formula: it forward-splats a
fine grid of glass points and histograms where they land (photon counting).

Run:
  uv run --no-project --with numpy --with matplotlib python3 scratch/caustic_fidelity.py
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "tests"))
import gpu_sim as g  # noqa: E402

F32 = np.float32
W = 512      # field / render resolution of the mirror (module hardcodes h = 1/512)
NB = 256     # comparison resolution (2x2 block mean of the 512 renders)
M = 3072     # fine glass samples per axis for the ground truth
PEAK = 0.9   # max |F| of the test field, in the module's [-1, 1] field units
TAU = 2.0 * np.pi

# ---------------------------------------------------------------- test glass
rng = np.random.default_rng(int(os.environ.get("SEED", "7")))
MODES = []
for _ in range(5):
    kx, ky = (int(v) for v in rng.integers(-3, 4, size=2))
    if kx == 0 and ky == 0:
        kx = 1
    MODES.append((kx, ky, float(rng.uniform(0.5, 1.0)), float(rng.uniform(0, TAU))))


def raw_field(x, y):
    """F = grad h for periodic h = sum a cos(2pi(kx x + ky y) + phi), plus
    the analytic Jacobian entries. Unscaled."""
    z = np.zeros_like(x)
    fx, fy, jxx, jxy, jyy = z.copy(), z.copy(), z.copy(), z.copy(), z.copy()
    for kx, ky, a, phi in MODES:
        arg = TAU * (kx * x + ky * y) + phi
        s, c = np.sin(arg), np.cos(arg)
        fx += -a * TAU * kx * s
        fy += -a * TAU * ky * s
        jxx += -a * TAU ** 2 * kx * kx * c
        jxy += -a * TAU ** 2 * kx * ky * c
        jyy += -a * TAU ** 2 * ky * ky * c
    return fx, fy, jxx, jxy, jyy


_cx = (np.arange(W) + 0.5) / W
_X, _Y = np.meshgrid(_cx, _cx)
_RF = raw_field(_X, _Y)
SCALE = PEAK / np.max(np.hypot(_RF[0], _RF[1]))


def field(x, y):
    return tuple(SCALE * v for v in raw_field(x, y))


def first_fold_distance():
    """d* = 1 / (most negative Hessian eigenvalue): where the first fold forms."""
    fx, fy, jxx, jxy, jyy = field(_X, _Y)
    lam = (jxx + jyy) / 2 - np.sqrt(((jxx - jyy) / 2) ** 2 + jxy ** 2)
    return 1.0 / np.max(-lam)


def field_texture():
    nx, ny, _, _ = g.grid(W, W)
    fx, fy = field(nx.astype(np.float64), ny.astype(np.float64))[:2]
    tex = np.zeros((W, W, 4), F32)
    tex[..., 0] = (fx / 2 + 0.5).astype(F32)   # decode in codebox: (v - 0.5) * 2
    tex[..., 1] = (fy / 2 + 0.5).astype(F32)
    tex[..., 3] = 1.0
    return tex


def white():
    t = np.ones((W, W, 4), F32)
    return t


# ------------------------------------------------------------- ground truth
def truth(d, m=M):
    """Photon-counting illuminance on an NB x NB screen, mean 1 (periodic).
    m = glass samples per axis (changing it gives an independent noise draw)."""
    edges = np.linspace(0, 1, NB + 1)
    hist = np.zeros((NB, NB))
    u = (np.arange(m) + 0.5) / m
    for r0 in range(0, m, 192):
        y = np.repeat(u[r0:r0 + 192][:, None], m, axis=1)
        x = np.repeat(u[None, :], y.shape[0], axis=0)
        fx, fy = field(x, y)[:2]
        sx = np.mod(x + d * fx, 1.0)
        sy = np.mod(y + d * fy, 1.0)
        hh, _, _ = np.histogram2d(sy.ravel(), sx.ravel(), bins=[edges, edges])
        hist += hh
    return hist * (NB * NB) / (m * m)


# ------------------------------------------------- mirror of codebox_v2.gen
def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def module_caustic(tex, src, scale, gain=1.0, softness=0.0):
    """Mirror of the isolated caustic layer (green channel; color_shift = 0).
    Returns the UNCLAMPED layer, so structure is comparable."""
    nx, ny, _, _ = g.grid(W, W)
    h = F32(1.0 / 512.0)
    step = F32(scale / 8.0)
    px, py = nx.copy(), ny.copy()
    acc = np.zeros((W, W), F32)
    for _ in range(8):
        f = (g.sample(tex, px, py) - F32(0.5)) * F32(2.0)
        div = ((g.sample(tex, px + h, py)[..., 0] - g.sample(tex, px - h, py)[..., 0])
               * F32(2.0) / (F32(2.0) * h)
               + (g.sample(tex, px, py + h)[..., 1] - g.sample(tex, px, py - h)[..., 1])
               * F32(2.0) / (F32(2.0) * h))
        w = np.maximum(-div, F32(0.0))
        acc += w * g.sample(src, px, py)[..., 1]
        px = px - f[..., 0] * step
        py = py - f[..., 1] * step
    layer = acc * F32(1.0 / 8.0) * F32(gain)
    return layer * smoothstep(F32(0.0), F32(softness + 0.001), layer)


def det_gather(tex, d, iters=3, eps=0.05):
    """Candidate: find an approximate preimage u by fixed-point iteration
    u <- x - d F(u), then intensity = 1 / max(|det(I + d J(u))|, eps)."""
    nx, ny, _, _ = g.grid(W, W)
    h = F32(1.0 / 512.0)
    ux, uy = nx.copy(), ny.copy()
    for _ in range(iters):
        f = (g.sample(tex, ux, uy) - F32(0.5)) * F32(2.0)
        ux = nx - F32(d) * f[..., 0]
        uy = ny - F32(d) * f[..., 1]

    def dd(c, dx, dy):  # d(channel c)/d(axis) by central difference, field units
        return ((g.sample(tex, ux + dx, uy + dy)[..., c]
                 - g.sample(tex, ux - dx, uy - dy)[..., c]) * F32(2.0) / F32(2.0 * h))

    zero = F32(0.0)
    jxx = dd(0, h, zero)
    jxy = dd(0, zero, h)   # dFx/dy
    jyx = dd(1, h, zero)   # dFy/dx
    jyy = dd(1, zero, h)
    det = (1 + d * jxx) * (1 + d * jyy) - d * d * jxy * jyx
    return 1.0 / np.maximum(np.abs(det), eps)


# ------------------------------------------------------------------ metrics
def down(a):
    a = np.asarray(a, np.float64)
    return a.reshape(NB, 2, NB, 2).mean(axis=(1, 3))


def interior(d):
    m = d * PEAK + 0.02
    c = (np.arange(NB) + 0.5) / NB
    ok = (c > m) & (c < 1 - m)
    return ok[:, None] & ok[None, :]


def pearson(a, b):
    a = a - a.mean()
    b = b - b.mean()
    return float((a * b).sum() / np.sqrt((a * a).sum() * (b * b).sum()))


def top_iou(a, b, q=0.92):
    ta = a >= np.quantile(a, q)
    tb = b >= np.quantile(b, q)
    return float((ta & tb).sum() / max((ta | tb).sum(), 1))


def main():
    tex = field_texture()
    src = white()
    dstar = first_fold_distance()
    print(f"test field: peak |F| = {PEAK}, first fold distance d* = {dstar:.4f} (UV)")
    print(f"module `scale` is the trace distance d; the sweep below is in units of d*\n")

    # --- sanity: ground truth vs first-order theory at tiny d ---------------
    d0 = 0.05 * dstar
    t0 = truth(d0)
    cxs = (np.arange(NB) + 0.5) / NB
    gx, gy = np.meshgrid(cxs, cxs)
    fx, fy, jxx, jxy, jyy = field(gx, gy)
    first_order = -d0 * (jxx + jyy)
    m0 = interior(d0)
    t0b = truth(d0, m=2560)   # independent noise draw of the same physical truth
    print("SANITY (ground truth vs theory, d = 0.05 d*; signal is only a few % here):")
    print(f"  noise ceiling  r(truth A, truth B)            = {pearson(t0[m0], t0b[m0]):.3f}")
    print(f"  r( I_true - 1 , -d * div F )                  = {pearson((t0 - 1)[m0], first_order[m0]):.3f}")
    print(f"  r( truth B - 1 , -d * div F )                 = {pearson((t0b - 1)[m0], first_order[m0]):.3f}")
    print("  (a perfect theory scores about sqrt(noise ceiling) against one noisy truth draw)")
    print(f"  expected for a perfect theory: ~{np.sqrt(max(pearson(t0[m0], t0b[m0]), 0)):.3f}\n")

    # --- scale = 0 claim ------------------------------------------------------
    c0 = module_caustic(tex, src, 0.0)
    nx, ny, _, _ = g.grid(W, W)
    jf = field(nx.astype(np.float64), ny.astype(np.float64))
    w_only = np.maximum(-(jf[2] + jf[4]), 0.0)
    inner = (slice(8, -8), slice(8, -8))
    print("DOC CHECK: f_caustic.md says scale = 0 gives 'no trace, no caustic'.")
    print(f"  module layer at scale=0: mean {c0[inner].mean():.3f}, max {c0[inner].max():.3f}"
          f"  (max(-div,0) mean {w_only[inner].mean():.3f})")
    print(f"  r(layer@scale=0, max(-div,0)) = "
          f"{pearson(c0[inner].astype(np.float64), w_only[inner]):.4f}\n")

    # --- sweep ------------------------------------------------------------------
    fracs = [float(v) for v in os.environ.get("FRACS", "0.3,0.6,1.0,1.5").split(",")]
    rows = {"truth": [], "module": [], "first-order (scale=0)": [], "det gather": []}
    print(f"{'d/d*':>5} | {'method':<22} | {'r vs truth':>10} | {'top-8% IoU':>10}")
    print("-" * 56)
    for fr in fracs:
        d = fr * dstar
        t = truth(d)
        m = interior(d)
        est = {
            "module": down(module_caustic(tex, src, d)),
            "first-order (scale=0)": down(module_caustic(tex, src, 0.0)),
            "det gather": down(det_gather(tex, d)),
        }
        rows["truth"].append(t)
        for name, a in est.items():
            rows[name].append(a)
            print(f"{fr:5.2f} | {name:<22} | {pearson(a[m], t[m]):10.3f} | "
                  f"{top_iou(a[m], t[m]):10.3f}")
        print("-" * 56)

    # --- does the module's output depend on d the way light does? ---------------
    mods = rows["module"]
    m_all = interior(max(fracs) * dstar)
    print("module output vs distance (should CHANGE shape as d grows, like real light):")
    for i in range(1, len(fracs)):
        print(f"  r(module@{fracs[0]:.1f}d*, module@{fracs[i]:.1f}d*) = "
              f"{pearson(mods[0][m_all], mods[i][m_all]):.3f}   |   "
              f"r(truth@{fracs[0]:.1f}d*, truth@{fracs[i]:.1f}d*) = "
              f"{pearson(rows['truth'][0][m_all], rows['truth'][i][m_all]):.3f}")

    # --- figure -------------------------------------------------------------------
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("\n(matplotlib missing: no figure)")
        return
    names = list(rows)
    fig, axes = plt.subplots(len(names), len(fracs), figsize=(2.2 * len(fracs), 2.2 * len(names)))
    for r, name in enumerate(names):
        for c, fr in enumerate(fracs):
            a = rows[name][c]
            ax = axes[r, c]
            ax.imshow(a, cmap="inferno", vmin=0, vmax=np.percentile(a, 99.5))
            ax.set_xticks([])
            ax.set_yticks([])
            if r == 0:
                ax.set_title(f"d = {fr:.1f} d*")
            if c == 0:
                ax.set_ylabel(name, fontsize=9)
    fig.tight_layout()
    tag = "_far" if "FRACS" in os.environ else ""
    out = os.path.join(HERE, f"caustic_fidelity_seed{os.environ.get('SEED', '7')}{tag}.png")
    fig.savefig(out, dpi=70)
    print(f"\nfigure: {out}")


if __name__ == "__main__":
    main()
