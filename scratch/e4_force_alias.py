"""E4 study: force aliasing when a render-size force is read into the 256^2 solver grid.

Read-only analysis, no module changes. Run:
    uv run --no-project --with numpy python3 scratch/e4_force_alias.py

Models (all read a render-size WxH single-channel force at the 256^2 texel centres):
  tapK   = mean of KxK hardware-style bilinear taps spread across the target texel
           footprint. Offsets are in NORMALISED coordinates, so the codebox needs no
           knowledge of the source size. tap1 = what codebox_adv.gen does today.
  area   = exact area average of the source block (the ideal box prefilter; reference)
Hardware sample() is modelled as a plain bilinear tap with clamped edges (Phase 0 found
it nearest-like when minifying, which a single bilinear tap at a texel centre is).
"""
import numpy as np

G = 256  # solver grid
import sys
MODE = sys.argv[1] if len(sys.argv) > 1 else "bilinear"  # "bilinear" (optimistic) | "nearest" (Phase 0: hardware is nearest-like when minifying)
SIZES = [(512, 512), (1920, 1080), (3840, 2160)] if MODE == "bilinear" else [(1920, 1080), (3840, 2160)]


def tap_axes(n_src, k):
    """Per-axis tap sample coords (norm) for every target texel: shape (G, k)."""
    i = (np.arange(G) + 0.5) / G
    o = ((np.arange(k) + 0.5) / k - 0.5) / G
    return i[:, None] + o[None, :]


def bilinear_sep(S, u, v):
    """Bilinear tap of S[H,W] at norm coords u (len M) x v (len M) -> (M,M), clamped."""
    H, W = S.shape
    if MODE == "nearest":
        jx = np.clip(np.floor(u * W).astype(int), 0, W - 1)
        jy = np.clip(np.floor(v * H).astype(int), 0, H - 1)
        return S[np.ix_(jy, jx)]
    sx = u * W - 0.5
    sy = v * H - 0.5
    x0 = np.floor(sx).astype(int); tx = sx - x0
    y0 = np.floor(sy).astype(int); ty = sy - y0
    x1 = np.clip(x0 + 1, 0, W - 1); x0 = np.clip(x0, 0, W - 1)
    y1 = np.clip(y0 + 1, 0, H - 1); y0 = np.clip(y0, 0, H - 1)
    a = S[np.ix_(y0, x0)]; b = S[np.ix_(y0, x1)]
    c = S[np.ix_(y1, x0)]; d = S[np.ix_(y1, x1)]
    tx = tx[None, :]; ty = ty[:, None]
    return (1 - ty) * ((1 - tx) * a + tx * b) + ty * ((1 - tx) * c + tx * d)


def tapK(S, k):
    ux = tap_axes(S.shape[1], k)
    vy = tap_axes(S.shape[0], k)
    acc = np.zeros((G, G))
    for a in range(k):
        for b in range(k):
            acc += bilinear_sep(S, ux[:, a], vy[:, b])
    return acc / (k * k)


def area_matrix(n_src):
    bs = n_src / G
    lo = (np.arange(G) * bs)[:, None]
    hi = lo + bs
    j = np.arange(n_src)[None, :]
    ov = np.clip(np.minimum(hi, j + 1) - np.maximum(lo, j), 0, None)
    return ov / bs


def area(S):
    H, W = S.shape
    return area_matrix(H) @ S @ area_matrix(W).T


METHODS = [("tap1 (today)", lambda S: tapK(S, 1)), ("tap2", lambda S: tapK(S, 2)),
           ("tap4", lambda S: tapK(S, 4)), ("tap8", lambda S: tapK(S, 8)),
           ("tap16", lambda S: tapK(S, 16)), ("area (ideal)", area)]


def study(W, H, rng):
    print(f"\n=== render {W}x{H}  -> {G}^2   block = {W/G:.2f} x {H/G:.2f} source px per target texel")

    # 1. white noise: how much per-pixel noise reaches the solver, relative to the ideal box average
    S = rng.standard_normal((H, W))
    ideal = area(S).std()
    print("-- white noise (sigma=1 per source pixel): std of what the solver sees; 'x ideal' = noise gain")
    for name, f in METHODS:
        s = f(S).std()
        print(f"   {name:14s} std {s:7.4f}   x ideal {s/ideal:6.2f}")

    # 2. above-Nyquist sinusoids: amplitude that aliases into the solver grid (input rms = 0.707)
    freqs = np.linspace(G / 2 + 12, 0.45 * W, 60)  # cycles across width, all above the grid Nyquist (128)
    x = (np.arange(W) + 0.5) / W
    rows = {n: [] for n, _ in METHODS}
    Sy = np.ones((H, 1))
    for fc in freqs:
        S = Sy * np.sin(2 * np.pi * fc * x)[None, :]
        for name, f in METHODS:
            rows[name].append(f(S).std() / 0.7071)
    print(f"-- sinusoid {freqs[0]:.0f}..{freqs[-1]:.0f} cycles (all unrepresentable on the grid): output rms / input rms")
    for name, _ in METHODS:
        r = np.array(rows[name])
        print(f"   {name:14s} mean {r.mean():6.3f}   worst {r.max():6.3f}")

    # 3. flow-like force: smooth blobs + per-pixel sensor noise; error vs the noise-free field on the grid
    lo = rng.standard_normal((24, 24))
    up = np.kron(lo, np.ones((int(np.ceil(H / 24)), int(np.ceil(W / 24)))))[:H, :W]
    k = np.ones(31) / 31  # smooth the blocky field so it is a plausible band-limited flow
    up = np.apply_along_axis(lambda r: np.convolve(r, k, "same"), 1, up)
    up = np.apply_along_axis(lambda c: np.convolve(c, k, "same"), 0, up)
    up /= up.std()
    truth = area(up)
    noisy = up + 0.5 * rng.standard_normal((H, W))
    print("-- smooth flow (sigma 1) + 0.5 sigma pixel noise: rms error vs the noise-free flow on the grid (flow rms = 1)")
    for name, f in METHODS:
        e = f(noisy) - truth
        print(f"   {name:14s} rms err {np.sqrt((e**2).mean()):7.4f}")


if __name__ == "__main__":
    rng = np.random.default_rng(0)
    print(f"### tap model: {MODE}")
    for W, H in SIZES:
        study(W, H, rng)
