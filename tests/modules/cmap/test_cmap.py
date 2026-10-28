"""
test_cmap.py -- tier-1 independent checks for the f_cmap mirror (T001-T003).

Ground truth is the spec's settled model (.specify/f_cmap/spec.md) evaluated by plain scalar
Python complex arithmetic written here (no NumPy in the references, no shared code with the
mirror), plus closed forms:
  - identity-map invariance: n = 1, w = 0, decay 1, inject 0 leaves the image unchanged (FR-010);
  - the pull's Jacobian in height units is dz'/dz = n z^(n-1): a scaled rotation (SC-002), at
    aspect 1, 16:9 and 9:16;
  - fixed points of z^2 + w (closed form) and of z^n at w = 0 (0 and the (n-1)th roots of unity);
  - composition (SC-003): nearest sampling, decay 1, inject 0, after k frames the image at a pixel
    is the original at F^k(pixel) (F = the nearest-index pull), for the wrap, black and source
    bounds rules;
  - the bounds region is exactly the pulled-outside-frame set (SC-004);
  - the mix out = decay * hist * (1 - inject) + src * inject, and the offset clock (`rate` 0 freezes
    w, the sqrt(2) phase, the webgpgpu |w| sweep, the 0.01 rad per frame source step);
  - the samplers: bilinear and nearest equal gpu_sim's, Catmull-Rom is interpolating and reproduces
    linear ramps exactly.
Mutations in cmap_mirror.BUGS must each fail at least one check by a clear margin.
"""
import cmath
import math
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
import cmap_mirror as m  # noqa: E402

TWO_L = 2.0 * m.L


# --- independent scalar references ----------------------------------------------------------

def ref_pull(i, j, h, w, n, wc):
    """Sample position p' for pixel (i, j) of an h x w frame, scalar complex arithmetic."""
    A = w / h
    px, py = (i + 0.5) / w, (j + 0.5) / h
    z = complex((px - 0.5) * A, py - 0.5) * TWO_L
    q = (z ** n + complex(wc[0], wc[1])) / TWO_L
    return q.real / A + 0.5, q.imag + 0.5


def ref_inside(px, py):
    return 0.0 <= px <= 1.0 and 0.0 <= py <= 1.0


def ref_compose(S, k, n, wc, bounds):
    """out_k for the static source S under nearest sampling, decay 1, inject 0 (RGB only)."""
    h, w = S.shape[:2]
    out = np.zeros((h, w, 3))
    for j in range(h):
        for i in range(w):
            a, b = i, j
            dead = False
            for _ in range(k):
                px, py = ref_pull(a, b, h, w, n, wc)
                if bounds == "wrap":
                    px, py = px - math.floor(px), py - math.floor(py)
                    a, b = int(math.floor(px * w)) % w, int(math.floor(py * h)) % h
                elif not ref_inside(px, py):
                    dead = True
                    break
                else:
                    a, b = min(int(math.floor(px * w)), w - 1), min(int(math.floor(py * h)), h - 1)
            out[j, i] = 0.0 if (dead and bounds == "black") else S[b, a, :3]
    return out


# --- the error functions (used by the tests and by the mutation check) ----------------------

def identity_err(dtype, sampler, bug=None, nframes=50, h=27, w=48):
    img = m.noise_image(h, w, seed=3, dtype=dtype)
    out = m.run_temporal(lambda k: img, nframes, lambda k: (0.0, 0.0), sampler=sampler, n=1,
                         decay=1.0, inject=0.0, bounds="source", bug=bug)
    return float(np.abs(out[..., :3].astype(np.float64) - img[..., :3]).max())


def _qprime(A, px, py, n, wc, bug, dqx=0.0, dqy=0.0):
    """q' at the point displaced by (dqx, dqy) in height units (so the step in norm x is dqx / A)."""
    ppx, ppy = m.pull_point(np.float64(px + dqx / A), np.float64(py + dqy), A, n, wc, bug)
    return complex((float(ppx) - 0.5) * A, float(ppy) - 0.5)


def isometry_err(bug=None, seed=11):
    """Worst relative difference between the finite-difference Jacobian of the pipeline (in height
    units) and the analytic scaled rotation dz'/dz = n z^(n-1)."""
    rng = np.random.default_rng(seed)
    worst = 0.0
    eps = 1e-6
    for A in (1.0, 16.0 / 9.0, 9.0 / 16.0):
        for n in (2, 3, 4):
            for _ in range(6):
                px, py = rng.uniform(0.15, 0.85, 2)
                wc = (rng.uniform(-0.4, 0.4), rng.uniform(-0.4, 0.4))
                fx_p, fx_m = _qprime(A, px, py, n, wc, bug, eps, 0), _qprime(A, px, py, n, wc, bug, -eps, 0)
                fy_p, fy_m = _qprime(A, px, py, n, wc, bug, 0, eps), _qprime(A, px, py, n, wc, bug, 0, -eps)
                dqdx, dqdy = (fx_p - fx_m) / (2 * eps), (fy_p - fy_m) / (2 * eps)   # columns of J
                z = complex((px - 0.5) * A, py - 0.5) * TWO_L
                d = n * z ** (n - 1)                  # dz'/dz = dq'/dq (the 2L cancels)
                err = abs(dqdx - d) + abs(dqdy - 1j * d)    # J e_x = d, J e_y = i d for a conformal map
                worst = max(worst, err / max(1.0, abs(d)))
    return worst


def fixed_point_err(bug=None):
    """|p' - p| at the closed-form fixed points of z^2 + w (and of z^n at w = 0)."""
    worst = 0.0
    for A in (1.0, 16.0 / 9.0, 9.0 / 16.0):
        def p_of(z):
            q = z / TWO_L
            return q.real / A + 0.5, q.imag + 0.5

        def resid(z, n, wc):
            px, py = p_of(z)
            ppx, ppy = m.pull_point(np.float64(px), np.float64(py), A, n, wc, bug)
            return abs(float(ppx) - px) + abs(float(ppy) - py)

        for wv in (0.2 - 0.1j, -0.3 + 0.25j, 0.1 + 0.5j):
            for sgn in (1, -1):
                worst = max(worst, resid((1 + sgn * cmath.sqrt(1 - 4 * wv)) / 2, 2, (wv.real, wv.imag)))
        for n in (2, 3, 4):
            for z in [0j] + [cmath.exp(2j * math.pi * k / (n - 1)) for k in range(n - 1)]:
                worst = max(worst, resid(z, n, (0.0, 0.0)))
    return worst


def compose_err(bug=None):
    """Fraction of (pixel, channel) values where the mirror differs from the scalar reference."""
    h, w = 20, 36
    S = m.noise_image(h, w, seed=5)
    bad = tot = 0
    for bounds in ("wrap", "black", "source"):
        for n, wc in ((2, (0.3, 0.2)), (3, (-0.4, 0.1))):
            prev = S.copy()
            for k in range(1, 6):
                prev = m.frame(prev, S, n=n, w=wc, decay=1.0, inject=0.0, bounds=bounds,
                               sampler="nearest", bug=bug)
                if k in (1, 3, 5):
                    ref = ref_compose(S, k, n, wc, bounds)
                    bad += int((np.abs(prev[..., :3] - ref).max(axis=2) > 0).sum())
                    tot += h * w
    return bad / tot


def bounds_err(bug=None):
    """Mask mismatch fraction against the scalar test, plus the largest value error per rule."""
    h, w = 18, 32
    wc = (0.45, 0.1)
    prev = np.full((h, w, 4), 0.2)
    src = np.full((h, w, 4), 0.8)
    prev[..., 3] = src[..., 3] = 1.0
    ref = np.array([[ref_inside(*ref_pull(i, j, h, w, 2, wc)) for i in range(w)] for j in range(h)])
    worst = 0.0
    for bounds in ("source", "black", "wrap"):
        for sampler in ("nearest", "bilinear"):
            out, ins, _, _ = m.frame(prev, src, n=2, w=wc, decay=1.0, inject=0.0, bounds=bounds,
                                     sampler=sampler, bug=bug, detail=True)
            worst = max(worst, float((ins != ref).mean()))
            hole = {"source": 0.8, "black": 0.0, "wrap": 0.2}[bounds]
            expect = np.where(ref, 0.2, hole)
            worst = max(worst, float(np.abs(out[..., 0] - expect).max()))
    return worst


# --- tests ---------------------------------------------------------------------------------

def test_identity_map_invariance():
    for sampler in m.SAMPLERS:
        check(f"identity map, 50 frames, float64, {sampler}: max |out - src|",
              identity_err(np.float64, sampler), 1e-9)
    for sampler in m.SAMPLERS:
        check(f"identity map, 50 frames, float32, {sampler}: max |out - src|",
              identity_err(np.float32, sampler), 5e-4)


def test_pull_is_a_scaled_rotation():
    check("Jacobian vs n z^(n-1), aspect 1 / 16:9 / 9:16, n 2..4 (relative)", isometry_err(), 1e-6)


def test_fixed_points():
    check("|p' - p| at closed-form fixed points", fixed_point_err(), 1e-12)


def test_composition_after_k_frames():
    check("mirror vs scalar F^k composition, wrap / black / source, n 2 and 3 (mismatch fraction)",
          compose_err(), 0.0)


def test_bounds_region_and_rules():
    check("bounds mask vs scalar test, and hole values per rule (worst error)", bounds_err(), 1e-12)


def test_mix_closed_form():
    prev = np.full((10, 16, 4), 0.5)
    src = np.full((10, 16, 4), 0.9)
    prev[..., 3] = src[..., 3] = 1.0
    worst = 0.0
    for sampler in m.SAMPLERS:
        out = m.frame(prev, src, n=1, w=(0.0, 0.0), decay=0.93, inject=0.3, sampler=sampler)
        worst = max(worst, float(np.abs(out[..., :3] - (0.93 * 0.5 * 0.7 + 0.9 * 0.3)).max()),
                    float(np.abs(out[..., 3] - 1.0).max()))
        one = m.frame(prev, src, n=1, w=(0.0, 0.0), decay=0.5, inject=1.0, sampler=sampler)
        zero = m.frame(prev, src, n=1, w=(0.0, 0.0), decay=0.0, inject=0.0, sampler=sampler)
        worst = max(worst, float(np.abs(one[..., :3] - 0.9).max()), float(np.abs(zero[..., :3]).max()))
    check("out = decay*hist*(1-inject) + src*inject (inject 1 -> src, decay 0 -> 0), all samplers", worst, 1e-12)


# --- the offset clock ----------------------------------------------------------------------

def test_offset_clock():
    a = m.offset(0, rate=0.0, angle=0.25, radius=0.3, sweep=1.0)
    b = m.offset(12345, rate=0.0, angle=0.25, radius=0.3, sweep=1.0)
    check("rate 0: w identical at frame 0 and 12345 (exact freeze)", max(abs(a[0] - b[0]), abs(a[1] - b[1])), 0.0)
    w1 = m.offset(1, radius=0.15, sweep=0.0)
    check("source rate: theta advances 0.01 rad per frame", abs(math.atan2(w1[1], w1[0]) - 0.01), 1e-12)
    f = np.arange(4000)
    mags = np.array([math.hypot(*m.offset(float(k), rate=0.001, radius=0.15, sweep=1.5)) for k in f])
    check("source sweep: max |w| = radius + sweep = 1.65", abs(float(mags.max()) - 1.65), 1e-3)
    note("min |w| over the sweep (passes through zero)", f"{float(mags.min()):.4f}")
    assert float(mags.min()) < 0.02, "the sweep must pass through (or very near) zero"
    rate = 0.002
    f0 = 0.25 / (math.sqrt(2.0) * rate)           # the sqrt(2) phase reaches pi/2 here: cos = 0
    check("second phase advances sqrt(2) faster (|w| = |cos(phase)| is 0 at phase pi/2)",
          math.hypot(*m.offset(f0, rate=rate, radius=0.0, sweep=1.0)), 1e-12)


# --- samplers ------------------------------------------------------------------------------

def test_samplers_match_gpu_sim_and_closed_forms():
    rng = np.random.default_rng(2)
    img = rng.uniform(0, 1, (24, 40, 4)).astype(np.float32)
    u = rng.uniform(0.02, 0.98, 600).astype(np.float32)
    v = rng.uniform(0.02, 0.98, 600).astype(np.float32)
    check("bilinear vs gpu_sim.sample (clamp taps), float32", float(np.abs(
        m.bilinear(img, u, v) - g.sample(img, u, v, oob="clamp")).max()), 2e-6)
    check("nearest vs gpu_sim.nearest", float(np.abs(m.nearest(img, u, v) - g.nearest(img, u, v)).max()), 0.0)
    h, w = 24, 40
    yy, xx = np.meshgrid(np.arange(h), np.arange(w), indexing="ij")
    a, b, c0 = 0.37, -0.21, 1.5
    ramp = np.stack([a * xx + b * yy + c0] * 4, axis=-1).astype(np.float64)
    uu = rng.uniform(3.0 / w, 1 - 3.0 / w, 400)
    vv = rng.uniform(3.0 / h, 1 - 3.0 / h, 400)
    expect = a * (uu * w - 0.5) + b * (vv * h - 0.5) + c0
    for name in ("bilinear", "catmull"):
        got = getattr(m, name)(ramp, uu, vv)[..., 0]
        check(f"{name} reproduces a linear ramp exactly (interior)", float(np.abs(got - expect).max()), 1e-11)
    cu, cv = (np.arange(6, 30) + 0.5) / w, np.full(24, 10.5 / h)
    check("catmull is interpolating at texel centres", float(np.abs(
        m.catmull(img.astype(np.float64), cu, cv)[..., 0] - img[10, 6:30, 0]).max()), 1e-12)
    wrapped = m.catmull(ramp * 0 + 1.0, np.array([0.001, 0.999]), np.array([0.5, 0.5]), wrap=True)
    check("catmull with wrapped taps preserves a constant across the seam", float(np.abs(wrapped - 1.0).max()), 1e-12)


# --- mutations -----------------------------------------------------------------------------

def _errs(bug=None):
    return {"identity": identity_err(np.float64, "bilinear", bug), "isometry": isometry_err(bug),
            "fixed": fixed_point_err(bug), "compose": compose_err(bug), "bounds": bounds_err(bug)}


def test_mutations_are_caught():
    real = _errs()
    note("real mirror worst errors", {k: f"{v:.2e}" for k, v in real.items()})
    assert max(real.values()) < 2e-3, f"the real mirror must pass the same checks: {real}"
    for bug in m.BUGS:
        e = _errs(bug)
        worst = max(e.values())
        note(f"mutation '{bug}' worst error", f"{worst:.3e}")
        if not worst > 1e-2:
            raise AssertionError(f"mutation not detected: {bug} ({e})")
    print("    ok   an aspect not undone, z^(n+1), swapped x/y, a missing texel-centre half step and a "
          "subtracted offset are each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))
