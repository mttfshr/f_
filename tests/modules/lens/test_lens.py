"""
test_lens.py -- independent checks for the f_lens mirror (two stages: lens_pix, lens_halation).

Ground truth rules: every expected value here comes from the reference doc
(docs/f-reference/f_lens.md), from a closed form in float64 stated in the test's
docstring, from the shared input texture (a ramp whose value equals its
coordinate, or a uniform field), or from an identity at the neutral setting.
Nothing is retyped from the codebox except where marked codebox-dependent.

Constants the doc does NOT state (codebox-only, so checks that use them pin the codebox and are
codebox-dependent): the halation ring radii 0.015 and 0.03 and the 0.7071 diagonal components, the
surface finite-difference step eps = 0.002, the ghost tap offset formula 1 + ghost_spacing*n, and the
lens warm-shift factors. The doc does state: the vignette edges 0.3/0.7, the halation tint 1.1/1.0/0.85,
8 directions x 2 rings weighted 1.0/0.5, and (corrected 2026-10-20) the ghost weights 1, 0.6, 0.36, 0.22.

Run:  tests/run.sh tests/modules/lens/test_lens.py

All expected positions are computed in float64 from the doc's geometry and then
compared through gpu_sim.sample reads of the ramp (so the check exercises the
sample positions the mirror computed, not the value it returned).

Tolerances: 2e-4 at interpolated ramp reads (the README's 8-bit weight floor on
the GPU side is not present here but float32 bilinear accumulation over 16-48
stacked taps sits near this), 1e-5 for closed forms evaluated once per pixel,
0.0 for exact-value checks (clamps, alpha, unconnected-mod contributions).
"""
import sys

import numpy as np

from harness import check, note, run
import gpu_sim as g
from lens_mirror import F32, lens_stage, halation_stage, lens_chain, _gc, _smoothstep

N = 32


def const_tex(rgba, n=N):
    t = g.texture(n, n)
    t[...] = np.array(rgba, F32)
    return t


def rand_tex(seed, n=N):
    t = np.random.default_rng(seed).random((n, n, 4)).astype(F32)
    t[..., 3] = 1.0
    return t


def ramp_tex(n=N):
    u, v, _, _ = g.grid(n, n)
    s = g.texture(n, n)
    s[..., 0] = u.astype(F32)
    s[..., 1] = v.astype(F32)
    s[..., 2] = (u * 0.7 + v * 0.3).astype(F32)
    s[..., 3] = 1.0
    return s


def _inside_mask(H, W, margin=0.02):
    u = (np.arange(W) + 0.5) / W
    v = (np.arange(H) + 0.5) / H
    U, V = np.meshgrid(u, v)
    return (U >= margin) & (U <= 1 - margin) & (V >= margin) & (V <= 1 - margin)


def _no_clamp_neighbour(uv_expect, exclude=0.05):
    """Pixels whose expected sample positions sit within `exclude` of an edge: an
    in-frame-looking position can still have only out-of-frame neighbours, so one of
    the four bilinear taps clamps and the filtered value leaves the ramp line."""
    uv = np.asarray(uv_expect)
    return (uv >= exclude) & (uv <= 1 - exclude)


# --- neutral identity -------------------------------------------------------------------

def test_neutral_lens_stage_is_identity():
    """The doc's Algorithm block at every dial neutral: k=0, ab=0, vignette factor at
    dist<=0.3 is 1 and transmission 0 keeps mix neutral, no ghost terms; the stage is
    the identity on every pixel (a stated identity, plus the doc's own neutral claim)."""
    src = rand_tex(1)
    out = lens_stage(src)
    check("neutral lens stage equals the source", float(np.abs(out - src).max()), 1e-6)


def test_neutral_chain_is_identity_through_halation():
    """halation = 0 is the identity in the halation stage (its comp channels equal the
    source at halation 0), so the whole chain at every default reproduces its input."""
    src = rand_tex(2)
    out = lens_chain(src)
    check("neutral whole chain equals the source", float(np.abs(out - src).max()), 1e-6)


# --- distortion on a ramp (ramp readback: sampled value == sample position) --------------

def _dist_uv(bug=None, distortion=0.5):
    """The doc's warp: warp_uv = (uv - 0.5) * (1 + k * r^2) + 0.5, in float64."""
    n = N
    u = (np.arange(n) + 0.5) / n
    v = (np.arange(n) + 0.5) / n
    X, Y = np.meshgrid(u, v)
    cx, cy = X - 0.5, Y - 0.5
    r2 = cx * cx + cy * cy
    k = distortion
    wx = 0.5 + cx * (1.0 + k * r2)
    wy = 0.5 + cy * (1.0 + k * r2)
    return wx, wy


def _ramp_err(uv_expect, measured, mask=None):
    m = mask if mask is not None else _inside_mask(N, N, 0.06)
    return float(np.abs(measured - uv_expect)[m].max())


def test_distortion_ramp_readback():
    """Ramp readback: with all other dials neutral the green channel equals the sampled
    position, so the mirror's green plane must equal the doc's warp formula in float64;
    a k sign flip (barrel/pincushion) or a wrong r2 form moves it."""
    src = ramp_tex()
    for k in (0.5, -0.5):
        out = lens_stage(src, distortion=k)
        wx, wy = _dist_uv(distortion=k)
        mask = _inside_mask(N, N, 0.06)
        for arr in (wx, wy):
            mask &= _no_clamp_neighbour(arr, 0.055)
            mask &= (arr >= 0.0) & (arr <= 1.0)
        expect = np.zeros_like(src)
        expect[..., 0] = wx
        expect[..., 1] = wy
        expect[..., 2] = 0.7 * wx + 0.3 * wy
        expect[..., 3] = 1.0
        err = float(np.abs(out - expect.astype(F32))[mask].max())
        note(f"distortion {k} full-plane error", err)
        check(f"distortion {k} on a ramp matches the doc warp", err, 2e-4)


def test_aberration_ramp_readback():
    """ab = aberration * dist (mod neutral): red samples at scale 1+ab, blue at 1-ab
    along the unwarped radius (distortion neutral). Expected sample positions from
    the doc's geometry in float64, read off the ramp (value == position)."""
    src = ramp_tex()
    for a in (0.4, -0.4):
        out = lens_stage(src, aberration=a)
        u = (np.arange(N) + 0.5) / N
        v = (np.arange(N) + 0.5) / N
        X, Y = np.meshgrid(u, v)
        dist = np.sqrt((X - 0.5) ** 2 + (Y - 0.5) ** 2)
        mask = _inside_mask(N, N, 0.1) & (dist > 0.12)
        # ramp encoding: ch0 == sample position x, ch1 == sample position y (readback)
        pos_r_x = 0.5 + (X - 0.5) * (1 + a * dist)
        pos_r_y = 0.5 + (Y - 0.5) * (1 + a * dist)
        pos_b_x = 0.5 + (X - 0.5) * (1 - a * dist)
        pos_b_y = 0.5 + (Y - 0.5) * (1 - a * dist)
        mask_r = mask & _no_clamp_neighbour(pos_r_x, 0.06) & _no_clamp_neighbour(pos_r_y, 0.06)
        mask_b = mask & _no_clamp_neighbour(pos_b_x, 0.06) & _no_clamp_neighbour(pos_b_y, 0.06)
        # red taps read the ramp's ch0 (== pos x); blue taps read ch2 (== 0.7x + 0.3y)
        check(f"aberration {a}: red at scale 1+ab on a ramp",
              _ramp_err(pos_r_x, out[..., 0], mask_r), 2e-4)
        check(f"aberration {a}: green stays unshifted on a ramp",
              _ramp_err(Y, out[..., 1], mask), 2e-4)
        check(f"aberration {a}: blue at scale 1-ab on a ramp",
              _ramp_err(0.7 * pos_b_x + 0.3 * pos_b_y, out[..., 2], mask_b), 2e-4)


def test_ghost_ramp_readback():
    """Ramp readback on the ghost path: gc taps at radial offsets 1 + ghost_spacing*(n+1),
    weights normalized by their sum; ghost adds (weighted mean of tap positions) on
    top of the neutral stage's output, so the test compares the DIFFERENCE from the
    ghost=0 call. The doc states the falloff (1, 0.6, 0.36 and, as corrected 2026-10-20, 0.22);
    the tap offset formula 1 + ghost_spacing*(n+1) is the codebox's (codebox-dependent), and the
    round is pinned by test_ghost_count_rounds_not_floors."""
    src = ramp_tex()
    X, Y = np.meshgrid((np.arange(N) + 0.5) / N, (np.arange(N) + 0.5) / N)
    cy = Y - 0.5
    for spacing in (0.3, -0.3):
        for gc in (1, 2, 3):
            base = lens_stage(src, ghost=0.0, ghost_count=3)
            out = lens_stage(src, ghost=1.0, ghost_spacing=spacing, ghost_count=gc)
            w = [1.0, 0.6, 0.36, 0.22][:gc]
            wsum = sum(w)
            mask = _inside_mask(N, N, 0.14)
            # expected added ghost green: the weighted mean of the tap positions
            expect = sum(w[i] * (0.5 + cy * (1.0 + spacing * (i + 1)))
                         for i in range(gc)) / wsum
            delta = out[..., 1] - base[..., 1]
            # delta = out - base equals the ghost value; base green = Y (vignette/mix neutral)
            for i in range(gc):
                pos = 0.5 + cy * (1.0 + spacing * (i + 1))
                mask &= (pos >= 0.0) & (pos <= 1.0) & _no_clamp_neighbour(pos, 0.03)
            err = _ramp_err(expect, delta, mask)
            note(f"ghost gc={gc} spacing={spacing} green error", err)
            check(f"ghost taps gc={gc} spacing={spacing} on a ramp green", err, 4e-3)
            check(f"ghost gc={gc} spacing={spacing} alpha untouched", float(np.abs(out[..., 3] - 1.0).max()), 0.0)


# --- vignette closed forms on a uniform texture ------------------------------------------

def test_vignette_closed_form_rim_and_centre():
    """Vignette: factor = 1 - smoothstep(0.3, 0.7, dist); on a uniform source the R
    plane must be vignette * 1.05 (warm shift) at transmission 0.5 (half-mix), and
    vignette is exactly 1 for dist <= 0.3 and exactly 0 for dist >= 0.7 -- the doc's
    edges, evaluated with the textbook smoothstep."""
    src = const_tex((1.0, 1.0, 1.0, 1.0))
    out1 = lens_stage(src, transmission=1.0)
    u, v, _, _ = g.grid(N, N)
    d = np.sqrt((u - F32(0.5)) ** 2 + (v - F32(0.5)) ** 2).astype(np.float64)
    vig = 1.0 - _smoothstep_64(0.3, 0.7, d)
    err = float(np.abs(out1[..., 0] - (vig * 1.05).astype(F32)).max())
    note("vignette*1.05 worst error vs textbook smoothstep", err)
    check("vignette rim factor vs 1 - smoothstep(0.3, 0.7, dist)", err, 2e-5)
    err0 = float(np.abs(out1[..., 1][d <= 0.3 - 1e-6] - 1.0).max()) if np.any(d <= 0.3) else 0.0
    check("vignette exactly 1 at dist <= 0.3", err0, 0.0)
    err1 = float(np.abs(out1[..., 1][d >= 0.7 - 1e-6]).max()) if np.any(d >= 0.7) else 0.0
    check("vignette exactly 0 at dist >= 0.7", err1, 0.0)


def _smoothstep_64(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def test_transmission_mix_is_linear():
    """The doc: effect_out = mix(warm*vig*src, src, 1 - transmission). A one-sentence
    identity (mix linearity in its third argument) relates transmission 0.5 to the
    exact midpoint of the transmission 0 and transmission 1 outputs, independent of
    how vignette itself is shaped."""
    src = const_tex((0.8, 0.8, 0.8, 1.0))
    o0 = lens_stage(src, transmission=0.0)
    o1 = lens_stage(src, transmission=1.0)
    o05 = lens_stage(src, transmission=0.5)
    check("transmission 0.5 is the midpoint of 0 and 1 (mix linearity)",
          float(np.abs(o05 - 0.5 * (o0 + o1)).max()), 1e-5)


# --- ghost count gate --------------------------------------------------------------------

def test_ghost_count_rounds_not_floors():
    """The codebox computes floor(ghost_count + 0.5), a round. (The doc used to say floor(); it was
    corrected 2026-10-20 to match the codebox.) At ghost_count 2.5 that gives 3 taps where floor()
    would give 2. Codebox-dependent: this pins the convention."""
    check("codebox ghost_count at 2.5 rounds to 3 (floor would give 2)", _gc(2.5), 3.0)


def test_ghost_weights_are_1_06_036_022():
    """The ghost weights are 1, 0.6, 0.36 and 0.22 (the doc states them as corrected 2026-10-20; it used
    to say 0.6^(n-1), i.e. 0.216 for the fourth tap, which the codebox never used). With ghost_count 4
    the ghost layer added to a ramp is the weighted mean of the four tap positions with these weights,
    in float64."""
    src = ramp_tex()
    u = (np.arange(N) + 0.5) / N
    X, Y = np.meshgrid(u, u)
    cy = Y - 0.5
    w = [1.0, 0.6, 0.36, 0.22]
    mask = _inside_mask(N, N, 0.14)
    for i in range(4):
        pos = 0.5 + cy * (1.0 + 0.3 * (i + 1))
        mask &= (pos >= 0.0) & (pos <= 1.0) & _no_clamp_neighbour(pos, 0.03)
    expect = sum(w[i] * (0.5 + cy * (1.0 + 0.3 * (i + 1))) for i in range(4)) / sum(w)
    out = lens_stage(src, ghost=1.0, ghost_count=4)
    base = lens_stage(src, ghost=0.0, ghost_count=4)
    err = float(np.abs((out[..., 1] - base[..., 1]) - expect.astype(F32))[mask].max())
    check("ghost taps follow the weights 1, 0.6, 0.36, 0.22", err, 2e-5)


def test_ghost_sum_unity_on_uniform():
    """The ghost sum is normalized by the sum of the active weights: with the source
    uniform at 1 and ghost = 1 the added ghost layer is exactly 1 in every channel
    (alpha tap stays 0), so the composite gains exactly ghost * 1 in RGB."""
    src = const_tex((1.0, 1.0, 1.0, 1.0))
    base = lens_stage(src, ghost=0.0, ghost_count=3)
    out = lens_stage(src, ghost=1.0, ghost_count=3)
    err = float(np.abs(out[...] - (base[...] + np.array([1.0, 1.0, 1.0, 0.0], F32) * F32(1.0))).max())
    check("normalized ghost taps sum to exactly 1 on a uniform texture", err, 2e-5)


# --- generic settings (aberration + distortion + vignette together, no special value) ----

def _err_generic(bug=None):
    """Every lens dial at a generic non-default value, ramp source, in float64:
    warp then aberration then vignette factor computed from the doc's statements
    (all special values avoided: k, ab, vignette all nontrivial). Excludes pixels
    whose expected positions leave the frame (clamp-to-edge changes the value).
    Codebox-dependent in one point: the vignette formula's edges (0.3, 0.7) are
    checked separately against the doc above."""
    src = ramp_tex()
    out = lens_stage(src, aberration=0.25, distortion=0.35, transmission=0.6,
                     ghost=0.4, ghost_spacing=0.21, ghost_count=3, bug=bug)
    n = N
    u = (np.arange(n) + 0.5) / n
    v = (np.arange(n) + 0.5) / n
    X, Y = np.meshgrid(u, v)
    cx, cy = X - 0.5, Y - 0.5
    dist = np.sqrt(cx * cx + cy * cy)
    r2 = cx * cx + cy * cy
    k, ab0, tr = 0.35, 0.25, 0.6
    wx = cx * (1.0 + k * r2)
    wy = cy * (1.0 + k * r2)
    ab = ab0 * dist
    r_x = 0.5 + wx * (1.0 + ab)
    r_y = 0.5 + wy * (1.0 + ab)
    g_x = 0.5 + wx
    g_y = 0.5 + wy
    b_x = 0.5 + wx * (1.0 - ab)
    b_y = 0.5 + wy * (1.0 - ab)
    # the doc's vignette; the codebox's mix with 1 - transmission keeps
    # (warm*vig*src) at weight tr
    vig = 1.0 - _smoothstep_64(0.3, 0.7, dist)
    src_r = g.sample(src, r_x.astype(F32), r_y.astype(F32)).astype(np.float64)[..., 0]
    src_g = g.sample(src, g_x.astype(F32), g_y.astype(F32)).astype(np.float64)[..., 1]
    src_b = g.sample(src, b_x.astype(F32), b_y.astype(F32)).astype(np.float64)[..., 2]
    w = [1.0, 0.6, 0.36, 0.22]
    ws = w[:3]
    wsum = sum(ws)
    gh_r = gh_g = gh_b = 0.0
    for i in range(3):
        osi = 1.0 + 0.21 * (i + 1)
        gh_r += w[i] * g.sample(src, (0.5 + wx * osi * (1.0 + ab)).astype(F32),
                                (0.5 + wy * osi * (1.0 + ab)).astype(F32)).astype(np.float64)[..., 0]
        gh_g += w[i] * g.sample(src, (0.5 + wx * osi).astype(F32),
                                (0.5 + wy * osi).astype(F32)).astype(np.float64)[..., 1]
        gh_b += w[i] * g.sample(src, (0.5 + wx * osi * (1.0 - ab)).astype(F32),
                                (0.5 + wy * osi * (1.0 - ab)).astype(F32)).astype(np.float64)[..., 2]
    gh_r /= wsum
    gh_g /= wsum
    gh_b /= wsum
    warm = [1.05, 1.0, 0.92]
    trk = 1.0 - tr
    # mix(a, b, 1 - tr) = a * tr + b * (1 - tr)
    expect_r = (warm[0] * vig * src_r) * tr + src_r * trk + gh_r * 0.4
    expect_g = (warm[1] * vig * src_g) * tr + src_g * trk + gh_g * 0.4
    expect_b = (warm[2] * vig * src_b) * tr + src_b * trk + gh_b * 0.4
    mask = _inside_mask(n, n, 0.1)
    for arr in (r_x, r_y, g_x, g_y, b_x, b_y):
        mask &= (arr >= 0.0) & (arr <= 1.0)
    # the ghost positions too
    for i in range(3):
        osi = 1.0 + 0.21 * (i + 1)
        for pos in (0.5 + wx * osi, 0.5 + wy * osi,
                    0.5 + wx * osi * (1.0 + ab), 0.5 + wy * osi * (1.0 + ab),
                    0.5 + wx * osi * (1.0 - ab), 0.5 + wy * osi * (1.0 - ab)):
            mask &= (pos >= 0.0) & (pos <= 1.0) & _no_clamp_neighbour(pos, 0.02)
    err = max(
        float(np.abs(out[..., 0] - expect_r.astype(F32))[mask].max()),
        float(np.abs(out[..., 1] - expect_g.astype(F32))[mask].max()),
        float(np.abs(out[..., 2] - expect_b.astype(F32))[mask].max()),
    )
    return err


def test_generic_settings():
    """Every lens dial generic (no special value): the doc's formula chain in float64
    with the doc vignette and codebox ghost weights; the vignette edges and ghost
    weights are themselves pinned by independent checks, so the composed expectation
    rests on the doc plus those pinned constants."""
    err = _err_generic()
    check("generic dials vs the doc formula chain, in-frame pixels", err, 2e-3)


# --- halation ------------------------------------------------------------------------------

def test_halation_zero_is_identity():
    """halation = 0 is the identity (the doc's default; comp channels equal the source
    when every gate contributes no addition)."""
    mid = lens_stage(rand_tex(4), aberration=0.3)
    out = halation_stage(mid, halation=0.0)
    check("halation 0 leaves its input unchanged", float(np.abs(out - mid).max()), 1e-6)


def test_halation_uniform_closed_form():
    """On a uniform texture every tap sees the same value: luma L, gate factor
    clamp((L - th) / (1 - th), 0, 1) = q (one value), the average of the 16 taps is
    (8 * w1 * src + 8 * w2 * src) / ((w1 + w2) * 8) = src, so comp = clamp(src +
    warm*src*halation, 0, 1) channelwise. Closed form from the doc's stated gate
    and ring weights."""
    for L in (0.5, 0.9):
        src = const_tex((L, L, L, 1.0))
        for th in (0.7, 0.2):
            o = halation_stage(src, halation=0.8, halation_threshold=th)
            q = min(max((L - th) / max(1.0 - th, 0.0001), 0.0), 1.0)
            expect = [min(s + q * s * w * 0.8, 1.0) for s, w in ((L, 1.1), (L, 1.0), (L, 0.85))]
            err = float(np.abs(o[..., :3] - np.array(expect, F32)).max())
            note(f"halation uniform L={L} th={th} error", err)
            check(f"halation on a uniform texture, L={L} th={th}", err, 2e-5)


def test_halation_ring_average_uniform():
    """On a uniform texture the halation average is exactly the source value when every
    gate saturates to 1 (the tap average is w-weighted and w-normalized): expected
    (8*w1 + 8*w2)/((w1 + w2)*8) * value = value. This pins the wsum = (w1 + w2) * 8
    normalization rather than some other divisor."""
    src = const_tex((1.0, 1.0, 1.0, 1.0))
    o = halation_stage(src, halation=0.6, halation_threshold=0.5)
    # at L=1 th=0.5 every gate is 1, glow = src (w-normalized average), comp = 1 + 1*1.1*0.6 -> clamped to 1
    check("halation comp saturates to exactly 1 at white with halation 0.6",
          float(np.abs(o[..., 0] - 1.0).max()), 0.0)


def test_halation_gate_zero_below_threshold():
    """The luma gate: pixels whose whole neighbourhood is below the threshold contribute
    nothing. A texture at luma 0.5 with threshold 0.7 gates every tap to 0, so the
    halation stage is the identity at halation 1.0 too."""
    src = const_tex((0.5, 0.5, 0.5, 1.0))
    o = halation_stage(src, halation=1.0, halation_threshold=0.7)
    check("halation adds nothing when every tap's luma is below the threshold",
          float(np.abs(o - src).max()), 1e-6)


def test_halation_alpha_passthrough():
    """The halation composite keeps the source's alpha untouched: comp alpha is mixed
    from itself, so the doc's alpha note ('preserving alpha') holds exactly."""
    src = rand_tex(5)
    src[..., 3] = F32(0.37)
    o = halation_stage(src, halation=0.9, halation_threshold=0.1)
    check("halation preserves the source alpha exactly", float(np.abs(o[..., 3] - 0.37).max()), 0.0)


def test_halation_ramp_readback():
    """Ramp readback on the halation ring: with a source whose value is its position
    scaled, a bright region's gated taps average positions on the two rings. At a
    point above the threshold, expected glow R = mean over 16 taps of
    mask(position) * clamp((L(pos) - th)/(1 - th), 0, 1) * weight, in float64. The
    ring structure (16 isotropic taps, 2 rings, weighted 1.0/0.5) is the doc's; the radii 0.015 and
    0.03 and the 0.7071 diagonal components are the codebox's (the doc does not state them), so this
    check is codebox-dependent on those constants."""
    n = 32
    src = ramp_tex(n)
    out = halation_stage(src, halation=1.0, halation_threshold=0.4)

    def ramp_at(px, py, ch):
        # bilinear sample of the ramp under clamp-to-edge: the filter never sees
        # centres past the last texel, so a coordinate beyond both edge centres
        # returns the edge texel's value
        edge = (n - 0.5) / n
        cx = np.minimum(np.maximum(px, 0.5 / n), edge)
        cy = np.minimum(np.maximum(py, 0.5 / n), edge)
        cx = np.where(px > edge, edge, cx)
        cy = np.where(py > edge, edge, cy)
        if ch == 0:
            return cx
        if ch == 1:
            return cy
        return 0.7 * cx + 0.3 * cy

    u = (np.arange(n) + 0.5) / n
    v = (np.arange(n) + 0.5) / n
    X, Y = np.meshgrid(u, v)
    dirs = [(1.0, 0.0), (0.7071, 0.7071), (0.0, 1.0), (-0.7071, 0.7071),
            (-1.0, 0.0), (-0.7071, -0.7071), (0.0, -1.0), (0.7071, -0.7071)]
    radii = [(0.015, 1.0), (0.03, 0.5)]
    acc = [np.zeros_like(X) for _ in range(3)]
    for dx, dy in dirs:
        for rad, wt in radii:
            px, py = X + dx * rad, Y + dy * rad
            vals = [ramp_at(px, py, c) for c in range(3)]
            lm = 0.2126 * vals[0] + 0.7152 * vals[1] + 0.0722 * vals[2]
            gate = np.clip((lm - 0.4) / 0.6, 0.0, 1.0)
            for c in range(3):
                acc[c] += vals[c] * gate * wt
    total_w = (1.0 + 0.5) * 8
    mask = _inside_mask(n, n, 0.05)
    err = max(float(np.abs(out[..., c] - np.clip(src[..., c] + (acc[c] / total_w) * w_h, 0.0, 1.0))[mask].max())
              for c, w_h in ((0, 1.1), (1, 1.0), (2, 0.85)))
    check("halation ring taps on a ramp vs the doc geometry in float64", err, 2e-4)


# --- range and structure -------------------------------------------------------------------

def test_unconnected_inlets_leave_neutral_chain_at_identity():
    """An unconnected modulation inlet reads (0,0,0,1) and its .x is 0, so with every
    *_mod dial up the unconnected inlets still contribute no modulation: the doc says an
    unconnected inlet "contributes no modulation regardless" at the default *_mod = 0; this test runs
    the *_mod dials at 1, so it rests on the unconnected-inlet-reads-a-constant convention (skill),
    not on the doc line alone. Same expected output as the fully neutral call."""
    src = rand_tex(3)
    a = lens_stage(src, aberration_mod=1.0, distortion_mod=1.0, transmission_mod=1.0, surface_mod=1.0)
    b = lens_stage(src)
    check("unconnected mod inlets at *_mod 1 equal the neutral stage",
          float(np.abs(a - b).max()), 1e-6)


def test_surface_emboss_shifts_the_sample_plane_on_a_flat_gradient():
    """The surface stage: warp_uv += (surf_dx, surf_dy) with surf_dx = (sample(uv+eps) -
    sample(uv)) * surface_mod -- a finite difference on the gradient inlet. On a flat
    texture the difference is 0 (identity); on a linear ramp the green plane shifts by
    the ramp's slope * eps * surface_mod inside the frame: closed form from the doc's
    finite-difference statement; the step eps = 0.002 is the codebox's."""
    n = N
    grad = g.texture(n, n)
    u, v, _, _ = g.grid(n, n)
    slope = 4.0
    grad[..., 0] = (slope * u).astype(F32)
    grad[..., 3] = 1.0
    src_r = ramp_tex(n)
    sm = 2.0
    out = lens_stage(src_r, surf_tex=grad, surface_mod=sm)
    wx_expect = (u.astype(np.float64) - 0.5 + slope * 0.002 * sm)
    wy_expect = (v.astype(np.float64) - 0.5 + 0.0)
    mask = _inside_mask(n, n, 0.06)
    measured = out[..., 1].astype(np.float64)
    err = float(np.abs(measured - (0.5 + wy_expect))[mask].max())
    # the x plane carries the shift: sign flip in the shift would show here
    err_x = float(np.abs(out[..., 0].astype(np.float64) - (0.5 + wx_expect))[mask].max())
    note("surface shift on green plane error", err)
    note("surface shift on red plane (x) error", err_x)
    check("surface emboss shifts the sample position by the ramp's finite difference", err, 2e-4)
    check("surface emboss x shift matches the finite difference (sign included)", err_x, 2e-4)


def test_bypass_returns_the_source():
    """The doc's bypass: raw texture passthrough -- out1 = mix(effect, source, bypass),
    so bypass 1 is exactly the source on both stages."""
    src = rand_tex(6)
    o1 = lens_stage(src, aberration=0.5, distortion=0.6, transmission=0.7, ghost=0.9, bypass=1.0)
    check("lens stage bypass equals the source", float(np.abs(o1 - src).max()), 1e-6)
    o2 = halation_stage(src, halation=0.8, halation_threshold=0.3, bypass=1.0)
    check("halation stage bypass equals the source", float(np.abs(o2 - src).max()), 1e-6)


def test_ghost_aberration_fringing_direction():
    """The doc: ghost taps sample R/G/B at their own aberration-scaled offset -- the
    red ghosts scale the warp by (1+ab), the blue by (1-ab). The test compares the
    ghost-added delta from the ghost=0 call (which is the primary image's own
    aberration, not the ghosts') so the sign difference is the ghosts'. Expected
    positions in float64 from the doc's sign statement; ramp channel encoding as
    in the earlier ramp tests."""
    src = ramp_tex()
    a = 0.3
    base = lens_stage(src, ghost=0.0, aberration=a, ghost_count=3)
    out = lens_stage(src, ghost=1.0, aberration=a, ghost_count=3)
    u = (np.arange(N) + 0.5) / N
    v = (np.arange(N) + 0.5) / N
    X, Y = np.meshgrid(u, v)
    cx, cy = X - 0.5, Y - 0.5
    dist = np.sqrt(cx * cx + cy * cy)
    ab = a * dist
    w = [1.0, 0.6, 0.36, 0.22][:3]
    wsum = sum(w)
    mask = _inside_mask(N, N, 0.14)
    expect_r = sum(w[i] * (0.5 + (X - 0.5) * (1.0 + 0.3 * (i + 1)) * (1.0 + ab)) for i in range(3)) / wsum
    expect_b = sum(w[i] * (0.7 * (0.5 + (X - 0.5) * (1.0 + 0.3 * (i + 1)) * (1.0 - ab))
                           + 0.3 * (0.5 + (Y - 0.5) * (1.0 + 0.3 * (i + 1)) * (1.0 - ab)))
                   for i in range(3)) / wsum
    for i in range(3):
        osi = 1.0 + 0.3 * (i + 1)
        for arr in (cx * osi * (1.0 + ab), cy * osi * (1.0 + ab),
                    cx * osi * (1.0 - ab), cy * osi * (1.0 - ab)):
            pos = 0.5 + arr
            mask &= (pos >= 0.0) & (pos <= 1.0) & _no_clamp_neighbour(pos, 0.03)
    delta_r = out[..., 0] - base[..., 0]
    delta_b = out[..., 2] - base[..., 2]
    err_r = float(np.abs(delta_r - expect_r.astype(F32))[mask].max())
    err_b = float(np.abs(delta_b - expect_b.astype(F32))[mask].max())
    note("ghost red fringing error", err_r)
    note("ghost blue fringing error", err_b)
    check("ghost red plane fringes at 1+ab on a ramp", err_r, 1e-3)
    check("ghost blue plane fringes at 1-ab on a ramp", err_b, 1e-3)
    # a y-only ramp (ch0 == y) makes the red taps' y-position visible on the red plane
    sy = ramp_tex()
    sy[..., 0] = ramp_tex()[..., 1]
    base_y = lens_stage(sy, ghost=0.0, aberration=a, ghost_count=3)
    out_y = lens_stage(sy, ghost=1.0, aberration=a, ghost_count=3)
    expect_ry = sum(w[i] * (0.5 + (Y - 0.5) * (1.0 + 0.3 * (i + 1)) * (1.0 + ab)) for i in range(3)) / wsum
    mask_y = _inside_mask(N, N, 0.14)
    for i in range(3):
        osi = 1.0 + 0.3 * (i + 1)
        for pos in (0.5 + cx * osi * (1.0 + ab), 0.5 + cy * osi * (1.0 + ab)):
            mask_y &= (pos >= 0.0) & (pos <= 1.0) & _no_clamp_neighbour(pos, 0.03)
    err_ry = float(np.abs((out_y[..., 0] - base_y[..., 0]) - expect_ry.astype(F32))[mask_y].max())
    note("ghost red y-position error on the y-ramp", err_ry)
    check("ghost red taps sample at y = centre + cy*osi*(1+ab)", err_ry, 1e-3)


# --- mutations -----------------------------------------------------------------------------

BUGS = ["pincushion", "swap_ab", "no_vignette", "no_ghost_norm",
        "ghost_w_doc", "ghost_floor_doc", "halation_no_norm", "halation_radius"]
TOLS = {"generic": (4e-3, _err_generic)}


def _err_distortion(bug=None):
    src = ramp_tex()
    out = lens_stage(src, distortion=0.5, bug=bug)
    wx, wy = _dist_uvs(distortion=0.5)
    mask = _inside_mask(N, N, 0.06)
    for arr in (wx, wy):
        mask &= (arr >= 0.0) & (arr <= 1.0) & _no_clamp_neighbour(arr, 0.055)
    return max(float(np.abs(out[..., 0] - wx.astype(F32))[mask].max()),
               float(np.abs(out[..., 1] - wy.astype(F32))[mask].max()))


def _dist_uvs(bug=None, distortion=0.5):
    return _dist_uv(bug=bug, distortion=distortion)


def _err_vignette(bug=None):
    src = const_tex((1.0, 1.0, 1.0, 1.0))
    out = lens_stage(src, transmission=1.0, bug=bug)
    u, v, _, _ = g.grid(N, N)
    d = np.sqrt((u - F32(0.5)) ** 2 + (v - F32(0.5)) ** 2).astype(np.float64)
    vig = 1.0 - _smoothstep_64(0.3, 0.7, d)
    return float(np.abs(out[..., 0] - (vig * 1.05).astype(F32)).max())


def _err_ghost_norm(bug=None):
    src = const_tex((1.0, 1.0, 1.0, 1.0))
    base = lens_stage(src, ghost=0.0, ghost_count=3, bug=bug)
    out = lens_stage(src, ghost=1.0, ghost_count=3, bug=bug)
    return float(np.abs(out - (base + np.array([1.0, 1.0, 1.0, 0.0], F32))).max())


def _err_ghost_w(bug=None):
    """The codebox's own series (1, 0.6, 0.36, 0.22) is the mirrored behavior; the
    doc-series mutant (0.216) must move off it. The weight check itself is
    test_ghost_weights_are_1_06_036_022 (the doc was corrected to the shipped weights, 2026-10-20)."""
    src = ramp_tex()
    u = (np.arange(N) + 0.5) / N
    X, Y = np.meshgrid(u, u)
    cy = Y - 0.5
    w = [1.0, 0.6, 0.36, 0.216] if bug == "ghost_w_doc" else [1.0, 0.6, 0.36, 0.22]
    mask = _inside_mask(N, N, 0.14)
    for i in range(4):
        pos = 0.5 + cy * (1.0 + 0.3 * (i + 1))
        mask &= (pos >= 0.0) & (pos <= 1.0) & _no_clamp_neighbour(pos, 0.03)
    expect = sum(w[i] * (0.5 + cy * (1.0 + 0.3 * (i + 1))) for i in range(4)) / sum(w)
    out = lens_stage(src, ghost=1.0, ghost_count=4)
    base = lens_stage(src, ghost=0.0, ghost_count=4)
    return float(np.abs((out[..., 1] - base[..., 1]) - expect.astype(F32))[mask].max())


def _err_ghost_floor(bug=None):
    src = ramp_tex()
    # the codebox reading: gc = round(2.5) = 3 taps; the doc-floor mutant gives 2
    out = lens_stage(src, ghost=1.0, ghost_count=2.5, bug=bug)
    base = lens_stage(src, ghost=0.0, ghost_count=2.5, bug=bug)
    w = [1.0, 0.6, 0.36]
    u = (np.arange(N) + 0.5) / N
    X, Y = np.meshgrid(u, u)
    cy = Y - 0.5
    mask = _inside_mask(N, N, 0.14)
    for i in range(3):
        pos = 0.5 + cy * (1.0 + 0.3 * (i + 1))
        mask &= (pos >= 0.0) & (pos <= 1.0) & _no_clamp_neighbour(pos, 0.03)
    expect = sum(w[i] * (0.5 + cy * (1.0 + 0.3 * (i + 1))) for i in range(3)) / sum(w)
    return float(np.abs((out[..., 1] - base[..., 1]) - expect.astype(F32))[mask].max())


def _err_halation_uniform(bug=None):
    # threshold 0 keeps every gate active at L=0.5; L*1.1*halation + L stays below 1,
    # so the comp clamp cannot hide a wrong divisor
    src = const_tex((0.5, 0.5, 0.5, 1.0))
    o = halation_stage(src, halation=0.4, halation_threshold=0.0, bug=bug)
    q = min(max((0.5 - 0.0) / 1.0, 0.0), 1.0)
    expect = np.array([min(s + q * s * w * 0.4, 1.0) for s, w in ((0.5, 1.1), (0.5, 1.0), (0.5, 0.85))], F32)
    return float(np.abs(o[..., :3] - expect).max())


def _err_halation_ramp(bug=None):
    """The ring geometry on an asymmetric (ramp) texture: an outer-radius shift moves
    which positions the outer taps read."""
    return float(_halation_ramp_err(bug))


def _halation_ramp_err(bug=None):
    n = 32
    src = ramp_tex(n)
    out = halation_stage(src, halation=1.0, halation_threshold=0.4, bug=bug)
    X, Y = np.meshgrid((np.arange(n) + 0.5) / n, (np.arange(n) + 0.5) / n)
    dirs = [(1.0, 0.0), (0.7071, 0.7071), (0.0, 1.0), (-0.7071, 0.7071),
            (-1.0, 0.0), (-0.7071, -0.7071), (0.0, -1.0), (0.7071, -0.7071)]
    edge = (n - 0.5) / n

    def ramp_at(px, py, ch):
        cx = np.where(px > edge, edge, np.minimum(np.maximum(px, 0.5 / n), edge))
        cy2 = np.where(py > edge, edge, np.minimum(np.maximum(py, 0.5 / n), edge))
        return [cx, cy2, 0.7 * cx + 0.3 * cy2][ch]

    acc = [np.zeros_like(X) for _ in range(3)]
    for dx, dy in dirs:
        for rad, wt in ((0.015, 1.0), (0.03, 0.5)):
            px, py = X + dx * rad, Y + dy * rad
            vals = [ramp_at(px, py, c) for c in range(3)]
            lm = 0.2126 * vals[0] + 0.7152 * vals[1] + 0.0722 * vals[2]
            gate = np.clip((lm - 0.4) / 0.6, 0.0, 1.0)
            for c in range(3):
                acc[c] += vals[c] * gate * wt
    total_w = (1.0 + 0.5) * 8
    mask = _inside_mask(n, n, 0.05)
    return max(float(np.abs(out[..., c] - np.clip(src[..., c] + (acc[c] / total_w) * w_h, 0.0, 1.0))[mask].max())
               for c, w_h in ((0, 1.1), (1, 1.0), (2, 0.85)))


def _err_swap_ab(bug=None):
    src = ramp_tex()
    a = 0.4
    out = lens_stage(src, aberration=a, bug=bug)
    u = (np.arange(N) + 0.5) / N
    X, Y = np.meshgrid(u, u)
    dist = np.sqrt((X - 0.5) ** 2 + (Y - 0.5) ** 2)
    pos_r_x = 0.5 + (X - 0.5) * (1 + a * dist)
    pos_r_y = 0.5 + (Y - 0.5) * (1 + a * dist)
    mask = _inside_mask(N, N, 0.1) & (dist > 0.12)
    mask &= _no_clamp_neighbour(pos_r_x, 0.06) & _no_clamp_neighbour(pos_r_y, 0.06)
    return _ramp_err(pos_r_x, out[..., 0], mask)


def test_mutations_are_caught():
    """Every declared bug must fail at least one independent check by a clear margin,
    and the real mirror must pass the same checks."""
    def e(err_fn, bug=None):
        with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
            v = err_fn(bug)
        return float(v) if np.isfinite(v) else 1e9

    real = {"distortion": _err_distortion(), "vignette": _err_vignette(),
            "ghost_norm": _err_ghost_norm(), "ghost_w": _err_ghost_w(),
            "ghost_floor": _err_ghost_floor(), "halation": _err_halation_uniform(),
            "halation_ramp": _err_halation_ramp(),
            "swap_ab": _err_swap_ab(), "generic": _err_generic()}
    for k, v in real.items():
        note(f"real mirror error on {k}", v)
        assert v <= TOLS.get(k, (4e-3, None))[0], f"real mirror exceeds tolerance on {k}: {v:.3e}"
    for bug in BUGS:
        errs = {"distortion": e(_err_distortion, bug), "vignette": e(_err_vignette, bug),
                "ghost_norm": e(_err_ghost_norm, bug), "ghost_w": e(_err_ghost_w, bug),
                "ghost_floor": e(_err_ghost_floor, bug), "halation": e(_err_halation_uniform, bug),
                "halation_ramp": e(_err_halation_ramp, bug),
                "swap_ab": e(_err_swap_ab, bug), "generic": e(_err_generic, bug)}
        # per-check detection floors: the tolerance each check uses on the real mirror
        # (tighter checks catch subtler mutants; the ramp float64 reference sits near 1e-7)
        det = {"halation_ramp": 1e-4, "distortion": 1e-4, "swap_ab": 1e-4,
               "ghost_w": 1e-4, "ghost_floor": 1e-4, "ghost_norm": 1e-5,
               "vignette": 1e-3, "halation": 1e-4, "generic": 4e-3}
        caught = {k: v for k, v in errs.items() if v > det[k]}
        if not caught:
            raise AssertionError(f"mutation '{bug}' survived every check")
        k = sorted(caught, key=lambda key: -caught[key])[0]
        note(f"mutation '{bug}' caught by {k}", caught[k])
    print("    ok   every declared bug is caught by an independent check")


if __name__ == "__main__":
    sys.exit(run(globals()))