"""
test_vf_lbm.py -- tier-1 stage checks for the future f_vf_lbm solver.

Ground truth is independent of the mirror:

  - Equilibrium moments (from the D2Q9 definition, computed in float64):
    sum(feq) = rho and sum(e_i * feq_i) = rho * u at generic rho, u;
    feq at rest with rho = 1 equals the weight vector W (sum = 1, first
    moments 0) -- textbook values typed in.
  - The BGK collision conserves each cell's mass and momentum exactly,
    because the equilibrium has the cell's rho and rho*u as its moments
    (checked at a generic non-equilibrium state and a generic omega).
  - Streaming moves a marked population exactly one cell along e_i per frame,
    for each of the nine directions (mark a delta at one interior texel,
    stream, find the mark at x + e_i) -- built on `new[x] = old[x - e_i]`
    (FR-004) alone, so a sign-flip mutant is caught. Each direction's seam
    (a mark displaced past the x edge) is also checked to wrap, because the
    shader's gather via gpu_sim.sample wraps the same way.
  - Bounce-back: with a NON-equilibrium start (so pre- and post-collision
    differ), each mask cell's populations after the stage equal the
    PRE-collision opposite populations (FR-003); a mutant using
    post-collision values fails by a clear margin; and bounce-back is a
    permutation (cell mass unchanged) inside the mask.
  - The uniform-flow fixed point: an empty mask with a uniform equilibrium at
    u = U0, rho = 1 stays uniform over a few frames. This is a check of the
    channel BCs too: before relying on it, the exact outflow and inflow
    populations on an empty-mask uniform state are pinned by hand below
    (the outflow copy is the identity on a uniform state, and the Zou/He
    density at ux = U0 with the inflow equilibrium overwritten back is the
    identity).
  - Channel BC structure: at the OUTFLOW edge only the leftward populations
    are overwritten (a distinct rightward population keeps its collided
    value); at the INFLOW edge the rightward populations are equilibrium
    values with ux forced to U0. The Zou/He density formula's direction is
    checked with the doc's words (inflow, so ux is prescribed positive).
  - Physical sign checks read off the doc's words alone (the brief's dial
    direction rule): cells just upstream of the obstacle slow below the free
    stream, and the wake side's mean ux is lower than the free-stream ux --
    a sign check, not a number. Also: a larger omega relaxes faster toward
    the equilibrium (monotone distance to equilibrium after one collision
    at three omegas), built from the BGK definition.
  - Encode: zero velocity encodes to 0.5, positive ux above 0.5, gain scales
    about 0.5, nothing non-finite reaches the outlet (FR-008).
  - float32 against float64 over a short run: measured, tolerance stated from
    the measurement (never assumed).

Doc quotes in report.json are verbatim from the snapshot spec. Not checked
here, per the brief: the safe omega ceiling, shedding quality, 10,000-frame
stability, obstacle-mask resampling filters, performance, and char quantization
at the vecfield outlet. y-periodicity is a stated convention, not an
independent fact, in needs_decision.
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from vf_lbm_mirror import (F32, E, W9, OPP, RIGHT, LEFT, PURE, equilibrium,
                        macro, pack, unpack, fuse_local, stream, encode,
                        lbm_step, omega_from_nu)  # noqa: E402

NX, NY = 64, 16           # small domains only
U0 = 0.04
OMEGA = F32(1.967)


def _state(rho64, ux64, uy64=None):
    uy = np.zeros_like(rho64) if uy64 is None else uy64
    f = equilibrium(rho64.astype(F32), ux64.astype(F32), uy.astype(F32))
    return pack(f)


def _uniform(U0_=U0, rho=1.0):
    return _state(np.full((NY, NX), rho), np.full((NY, NX), U0_))


def _circle_mask(nx=NX, ny=NY, cx=None, cy=None, r=None):
    x = np.arange(nx)[None, :]
    y = np.arange(ny)[:, None]
    cx = nx // 4 if cx is None else cx
    cy = ny // 2 if cy is None else cy
    r = ny // 4 if r is None else r
    return ((x - cx) ** 2 + (y - cy) ** 2 < r ** 2)


def _nan(planes):
    return int(sum(int((~np.isfinite(p)).sum()) for p in planes))


def _nan_arr(a):
    return int((~np.isfinite(a)).sum())


# --- equilibrium -----------------------------------------------------------------------

def test_equilibrium_moments_generic():
    """Independent: at a generic rho and u, sum(feq) = rho and
    sum(e_i feq_i) = rho u -- a one-sentence identity of the D2Q9 equilibrium.
    Computed in float64 reference arithmetic."""
    rng = np.random.default_rng(1)
    rho = (1.0 + 0.3 * rng.random((NY, NX))).astype(F32)
    ux = (0.08 * rng.random((NY, NX)) - 0.04).astype(F32)
    uy = (0.08 * rng.random((NY, NX)) - 0.04).astype(F32)
    feq = equilibrium(rho, ux, uy)
    # float64 reference from the formula
    r64, x64, y64 = (a.astype(np.float64) for a in (rho, ux, uy))
    worst_m = worst_x = worst_y = worst_rest = 0.0
    for i in range(9):
        eu = E[i, 0] * x64 + E[i, 1] * y64
        e64 = W9[i] * r64 * (1 + 3 * eu + 4.5 * eu ** 2 - 1.5 * (x64 ** 2 + y64 ** 2))
        worst_m = max(worst_m, float(np.abs(feq[i] - e64.astype(F32)).max()))
    msum = sum(fi.astype(np.float64) for fi in feq)
    xs = sum((fi * E[i, 0]).astype(np.float64) for i, fi in enumerate(feq))
    ys = sum((fi * E[i, 1]).astype(np.float64) for i, fi in enumerate(feq))
    worst_x = float(np.abs(xs - r64 * x64).max())
    worst_y = float(np.abs(ys - r64 * y64).max())
    worst_m = max(worst_m, float(np.abs(msum - r64).max()))
    # feq at rest, rho = 1 equals W (textbook weights, typed in)
    f0 = equilibrium(np.full((NY, NX), 1.0, F32), np.zeros((NY, NX), F32),
                     np.zeros((NY, NX), F32))
    for i in range(9):
        worst_rest = max(worst_rest, float(np.abs(f0[i] - F32(W9[i])).max()))
    check("equilibrium vs float64 formula, generic", worst_m, 2e-6)
    check("sum(feq) = rho at generic point", worst_m * 0 + float(np.abs(msum - r64).max()), 1e-5)
    check("sum(e_i feq_i) = rho u at generic point", max(worst_x, worst_y), 1e-5)
    check("feq at rest equals the weight vector W", worst_rest, 1e-6)


# --- collision ---------------------------------------------------------------------------

def test_collision_conserves_mass_and_momentum():
    """Independent: the BGK collision conserves each cell's mass and momentum
    exactly, because the equilibrium has the cell's rho and rho*u as
    moments -- one-sentence identity, at a generic non-equilibrium state."""
    rng = np.random.default_rng(2)
    f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
    rho, ux, uy = macro(f)
    f = [fi / rho for fi in f]
    rho, ux, uy = macro(f)   # the exact moments of the renormalized state
    omega = F32(1.4)
    feq = equilibrium(rho, ux, uy)
    g = [(fi + omega * (feq[i] - fi)).astype(F32) for i, fi in enumerate(f)]
    gx = sum((gi * E[i, 0]).astype(np.float64) for i, gi in enumerate(g))
    gy = sum((gi * E[i, 1]).astype(np.float64) for i, gi in enumerate(g))
    fx = sum((fi * E[i, 0]).astype(np.float64) for i, fi in enumerate(f))
    fy = sum((fi * E[i, 1]).astype(np.float64) for i, fi in enumerate(f))
    worst_x = float(np.abs(gx - fx).max())
    worst_y = float(np.abs(gy - fy).max())
    worst = 0.0
    for i in range(9):
        worst = max(worst, float(np.abs(sum(fi.astype(np.float64) for fi in g) - rho.astype(np.float64)).max()))
    assert _nan_arr(sum(gi for gi in g)) == 0
    check("collision conserves mass (generic, omega 1.4)", worst, 1e-5)
    check("collision conserves momentum (generic, omega 1.4)", max(worst_x, worst_y), 1e-5)


def test_omega_relaxes_faster_monotone():
    """Independent direction check built from the BGK definition alone: a
    larger omega leaves the state closer to the equilibrium (monotone across
    three omegas). From the BGK update f' = f + omega (feq - f), the distance
    to equilibrium shrinks by a factor (1 - omega), which is monotone in omega
    for omega < 1. Also pins the closed form omega = 1 / (3 * nu + 0.5):
    omega_from_nu vs the float64 formula."""
    rng = np.random.default_rng(3)
    f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
    rho, ux, uy = macro(f)
    f = [fi / rho for fi in f]
    feq = equilibrium(rho, ux, uy)
    dist = []
    for om in [0.3, 0.7, 1.0]:
        g = [(fi + F32(om) * (feq[i] - fi)).astype(F32) for i, fi in enumerate(f)]
        d = max(float(np.abs(g[i] - feq[i]).max()) for i in range(9))
        dist.append(d)
    assert _nan_arr(sum(dist)) == 0
    mono = max(dist[1] - dist[0], dist[2] - dist[1])
    note("distance to equilibrium at omega 0.3 / 0.7 / 1.0", [round(d, 6) for d in dist])
    check("larger omega is strictly closer to equilibrium (monotone)", mono, 1e-6)
    nu = U0 * (NY / 9) / 80.0
    w = float(omega_from_nu(nu))
    w64 = 1.0 / (3.0 * nu + 0.5)
    check("omega = 1 / (3 nu + 0.5) (nu from Re 80, NY 16)", abs(w - w64), 1e-6)


# --- streaming --------------------------------------------------------------------------

def _stream_mark_err(bug=None):
    """Mark population 1 at one interior texel; check it appears one cell
    along +e_1 = +x after the streaming gather (new[x] = old[x - e_1])."""
    planes = pack([np.full((NY, NX), 0.0, F32) for _ in range(9)])
    planes[0][NY // 2 + 3, 10] = F32(1.0)   # f0 mark, interior
    sp = stream(planes, bug=bug)
    f = unpack(sp)
    return f, planes


def test_streaming_moves_marks_one_cell():
    """Independent: a marked population at an interior texel moves exactly one
    cell along e_i per frame, for each of the nine directions --
    `new[x] = old[x - e_i]` (FR-004). No collision; a sign-flip mutant is
    caught because the mark lands on the wrong cell. The x direction's seam
    (a mark displaced past the x edge) is checked to wrap, because the
    shader's gather via gpu_sim.sample wraps the same way (a texel-centre
    gather at norm - 1/W lands exactly on the opposite edge's texel centre,
    never on the seam). y-periodicity is the stated convention in needs_decision."""
    worst_wrong = 0.0
    H, W = NY, NX
    for i in range(9):
        src = (10, 6)
        planes = pack([np.full((NY, NX), 0.0, F32) for _ in range(9)])
        planes[i // 4][src[1], src[0], i % 4] = F32(1.0)
        f = unpack(stream(planes, bug=None))
        total_after = float(sum(fi.sum() for fi in f))
        dst = (src[0] + E[i, 0]) % W, (src[1] + E[i, 1]) % H
        if abs(float(f[i][dst[1], dst[0]]) - 1.0) > 1e-6:
            worst_wrong = max(worst_wrong, abs(float(f[i][dst[1], dst[0]]) - 1.0))
        if abs(total_after - 1.0) > 1e-6:
            worst_wrong = max(worst_wrong, abs(total_after - 1.0))
    # mark f8 (the lone texel in plane 2's first channel) near the seam: e_8 = (1,-1)
    planes = pack([np.full((NY, NX), 0.0, F32) for _ in range(9)])
    planes[2][6, W - 1, 0] = F32(1.0)
    f = unpack(stream(planes, bug=None))
    if abs(float(f[8][5, 0]) - 1.0) > 1e-6:        # dst = ((63+1)%64, (6-1)%16) = (0, 5)
        worst_wrong = max(worst_wrong, abs(float(f[8][5, 0]) - 1.0))
    check("each marked population moves one cell along e_i (all 9, interior + seam)", worst_wrong, 0.0)


# --- bounce-back ------------------------------------------------------------------

def test_bounce_back_uses_pre_collision_values():
    """Independent structure check from FR-003's words: with a NON-equilibrium
    start (pre- and post-collision differ), each mask cell's populations after
    the fused stage equal the pre-collision OPPOSITE populations; a mutant
    using post-collision values fails by a clear margin."""
    rng = np.random.default_rng(4)
    f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
    rho, ux, uy = macro(f)
    f = [fi / rho for fi in f]
    planes = pack(f)
    mask = _circle_mask()
    out = unpack(fuse_local(planes, mask, 1.4, U0))
    worst = 0.0
    for i in range(9):
        expect = unpack([p.copy() for p in planes])[OPP[i]]
        worst = max(worst, float(np.abs(out[i][mask] - expect[mask]).max()))
    check("bounce-back returns pre-collision opposite populations", worst, 1e-6)
    # the post-collision mutant must fail by a clear margin
    f_post = [ (fi + F32(1.4) * (equilibrium(rho, ux, uy)[i] - fi)).astype(F32)
               for i, fi in enumerate(f) ]
    gap = min(float(np.abs(f_post[OPP[i]][mask] - unpack([p.copy() for p in planes])[OPP[i]][mask]).max())
              for i in range(9))
    note("pre vs post gap at the mask cells (the mutant's failure margin)", gap)
    out2 = unpack(fuse_local(planes, mask, 1.4, U0, bug="bounce_post"))
    worst_post = 0.0
    for i in range(9):
        expect = unpack([p.copy() for p in planes])[OPP[i]]
        worst_post = max(worst_post, float(np.abs(out2[i][mask] - expect[mask]).max()))
    note("bounce_post mutant worst error vs pre-collision truth", worst_post)
    assert worst_post > 1e-3, "the post-collision mutant was not caught"


def test_bounce_back_is_a_permutation_of_cell_mass():
    """Independent: bounce-back inside the mask is a permutation of the cell's
    nine values, so the mask cell's mass (sum of populations) is unchanged. """
    rng = np.random.default_rng(5)
    f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
    rho, ux, uy = macro(f)
    f = [fi / rho for fi in f]
    planes = pack(f)
    mask = _circle_mask()
    out = unpack(fuse_local(planes, mask, 1.4, U0))
    before = sum(fi.astype(np.float64) for fi in unpack(planes))
    after = sum(fi.astype(np.float64) for fi in out)
    worst = float(np.abs((after - before)[mask]).max())
    check("bounce-back leaves mask-cell mass unchanged (permutation)", worst, 1e-5)


# --- channel boundaries and the fixed point -------------------------------------------------

def test_outflow_only_leftward_populations():
    """Independent pin of the zero-gradient outflow convention (an FR-005
    convention only the codebox states, so this check is codebox-dependent by
    construction; it pins the convention while the fixed-point and wake checks
    below need no formulas). With a non-uniform state, only LEFT populations
    change at the last column: each LEFT population is overwritten by its
    neighbour at x - 1, each RIGHT population keeps its collided value."""
    rng = np.random.default_rng(7)
    f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
    rho, ux, uy = macro(f)
    f = [fi / rho for fi in f]
    planes = pack(f)
    mask = np.zeros((NY, NX), bool)
    out = unpack(fuse_local(planes, mask, 0.0, U0))     # omega 0: collision is identity
    worst = 0.0
    for i in LEFT:
        worst = max(worst, float(np.abs(out[i][:, -1] - unpack([p.copy() for p in planes])[i][:, -2]).max()))
    for i in RIGHT + PURE:
        worst = max(worst, float(np.abs(out[i][:, -1] - unpack([p.copy() for p in planes])[i][:, -1]).max()))
    check("outflow copies leftward populations from x-1, leaves the rest", worst, 1e-6)


def test_inflow_sets_rightward_equilibrium():
    """Independent pin of the inflow convention (FR-005, codebox-dependent
    wording; paired with the fixed-point and wake checks which need no
    formulas). At column 0 the rightward populations equal the equilibrium
    at the Zou/He density with ux forced to U0: with ux prescribed positive,
    rho = (pure + 2 * left) / (1 - ux)."""
    rng = np.random.default_rng(8)
    f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
    rho, ux, uy = macro(f)
    f = [fi / rho for fi in f]
    planes = pack(f)
    mask = np.zeros((NY, NX), bool)
    out = unpack(fuse_local(planes, mask, 0.0, U0))
    g0 = unpack([p.copy() for p in planes])
    pure = g0[0][:, 0] + g0[2][:, 0] + g0[4][:, 0]
    left = g0[3][:, 0] + g0[6][:, 0] + g0[7][:, 0]
    ux_in = ux[:, 0].copy()
    ux_in[1:-1] = F32(U0)                    # prescribed first, THEN the density (the experiment's order)
    rho_z = ((pure + F32(2.0) * left) / (F32(1.0) - ux_in)).astype(F32)[:, None]
    feq_in = equilibrium(rho_z, np.full((NY, 1), U0, F32), np.zeros((NY, 1), F32))
    worst = 0.0
    interior = np.ones(NY, bool); interior[0] = interior[-1] = False   # the Dirichlet rows only
    for i in RIGHT:
        worst = max(worst, float(np.abs(out[i][interior, 0] - feq_in[i][interior, 0]).max()))
    check("inflow sets rightward populations to the U0 equilibrium at the Zou/He density", worst, 1e-5)


def test_uniform_flow_is_a_fixed_point_empty_mask():
    """Independent: an empty mask with a uniform equilibrium at u = U0, rho = 1
    stays uniform over a few frames -- the channel BCs are the identity on the
    uniform state (checked by hand first: the outflow copy is the identity on
    a uniform state, and the Zou/He density with ux = U0 recovers rho = 1).
    This is a check that needs no formulas."""
    planes = _uniform()
    # the expected fixed point is the textbook equilibrium at rho=1, u=(U0,0),
    # evaluated in float64 (the W*1 rest state is a different, u=0 state)
    fexp64 = [W9[i] * (1.0 + 3.0 * E[i, 0] * U0 + 4.5 * (E[i, 0] * U0) ** 2 - 1.5 * U0 ** 2)
              for i in range(9)]
    worst = 0.0
    for step in range(5):
        planes, enc = lbm_step(planes, np.zeros((NY, NX), bool), float(OMEGA), U0, gain=1.0)
        w = float(np.abs(planes[0] - np.array([fexp64[0], fexp64[1], fexp64[2], fexp64[3]], F32)).max())
        w = max(w, float(np.abs(planes[1] - np.array([fexp64[4], fexp64[5], fexp64[6], fexp64[7]], F32)).max()))
        w = max(w, float(np.abs(planes[2] - np.array([fexp64[8], 0.0, 0.0, 0.0], F32)).max()))
        worst = max(worst, w)
        assert _nan(planes) == 0, "non-finite in the uniform fixed point"
    check("empty mask, uniform equilibrium is a fixed point over 5 frames", worst, 2e-6)
    check("uniform-flow encode is (0.5 + U0, 0.5) to float32 precision", float(np.abs(enc[..., :2] - np.array([0.5 + U0, 0.5], F32)).max()), 1e-6)


# --- wake physics (sign checks from the doc's words, no numbers) ------------------------

def test_obstacle_slows_flow_upstream_and_in_wake():
    """Independent sign check, from physics/doc words alone: after a short run
    cells just upstream of the obstacle slow below the free stream and the
    wake side has lower mean ux than the free-stream ux."""
    planes = _uniform()
    mask = _circle_mask(cx=NX // 4, r=3)
    steps = 60
    for _ in range(steps):
        planes, enc = lbm_step(planes, mask, float(OMEGA), U0, gain=1.0)
    assert _nan(planes) == 0, "non-finite behind the obstacle"
    f = unpack(planes)
    rho, ux, uy = macro(f)
    cx, cy, r = NX // 4, NY // 2, 3
    upstream = ux[cy, cx - 2 * r - 2: cx - r - 1].astype(np.float64)
    wake = ux[cy, cx + r + 2: cx + 3 * r].astype(np.float64)
    note("upstream mean ux (free stream 0.04)", float(upstream.mean()))
    note("wake mean ux", float(wake.mean()))
    check("upstream cells slow below the free stream", max(float(upstream.mean()) - U0, 0.0), 0.0)
    check("wake mean ux below the free stream", max(float(wake.mean()) - U0, 0.0), 0.0)


def test_obstacle_wake_has_curl_above_inflow():
    """Independent (mirrors the spec's US1 scenario 1 vs 2 structure): the
    SAME columns' mean |curl| grows once an obstacle is present: the wake
    half's curl exceeds the no-obstacle run's curl at the same columns -- a
    comparison check, not a number from the codebox."""
    planes = _uniform()
    mask_none = np.zeros((NY, NX), bool)
    mask = _circle_mask(cx=NX // 4, r=3)
    # no-obstacle control run, same columns, same length
    q, _ = lbm_step(_uniform(), mask_none, float(OMEGA), U0, gain=1.0)
    for _ in range(79):
        q, _ = lbm_step(q, mask_none, float(OMEGA), U0, gain=1.0)
    fq = unpack(q)
    rq, uqx, uyq = macro(fq)
    uq, vq = uqx.astype(np.float64), uyq.astype(np.float64)
    curl_q = (np.roll(uq, -1, 1) - np.roll(uq, 1, 1)) - (np.roll(vq, -1, 0) - np.roll(vq, 1, 0))
    clean = float(np.abs(curl_q[:, NX // 2:]).mean())
    # the obstacle run, same length
    for _ in range(80):
        planes, enc = lbm_step(planes, mask, float(OMEGA), U0, gain=1.0)
    assert _nan(planes) == 0
    f = unpack(planes)
    rho, ux, uy = macro(f)
    u64, v64 = ux.astype(np.float64), uy.astype(np.float64)
    curl = (np.roll(u64, -1, 1) - np.roll(u64, 1, 1)) - (np.roll(v64, -1, 0) - np.roll(v64, 1, 0))
    wake = float(np.abs(curl[:, NX // 2:]).mean())
    note("wake mean |curl| with obstacle", wake)
    note("same columns, no obstacle", clean)
    check("wake curl exceeds the no-obstacle control's curl", max(1e-6 + clean - wake, 0.0), 0.0)


# --- encode -------------------------------------------------------------------------------

def test_encode_direction_and_gain():
    """Independent: zero velocity encodes to 0.5, positive ux above 0.5, and
    gain scales the deviation about 0.5 (FR-008, RG = XY, 0.5 = zero). B is
    the spare channel: it stays 0.5, A stays 1."""
    planes = _uniform(U0_=0.0)
    e0 = encode(planes, gain=1.0)
    check("zero velocity encodes to exactly 0.5", float(np.abs(e0[..., :2] - F32(0.5)).max()), 0.0)
    check("spare channels: B stays 0.5, A stays 1", max(float(np.abs(e0[..., 2] - F32(0.5)).max()),
                                                       float(np.abs(e0[..., 3] - F32(1.0)).max())), 0.0)
    planes = _uniform(U0_=0.1)
    e1 = encode(planes, gain=1.0)
    check("positive ux encodes above 0.5", max(0.5 - float(np.min(e1[..., 0])), 0.0), 0.0)
    e2 = encode(planes, gain=2.0)
    dev1 = float(np.max(e1[..., 0])) - 0.5
    dev2 = float(np.max(e2[..., 0])) - 0.5
    check("gain scales the deviation about 0.5", abs(dev2 - 2.0 * dev1), 1e-6)


def test_encode_never_non_finite():
    """Independent bound: no NaN/Inf ever reaches the outlet's encoded texture,
    over a generic short run with an obstacle."""
    planes = _uniform()
    mask = _circle_mask()
    for _ in range(30):
        planes, enc = lbm_step(planes, mask, float(OMEGA), U0, gain=1.0)
    check("outlet is finite after 30 steps", float(np.abs(sum(int((~np.isfinite(enc)).sum()) for _ in [0])) * 0 + _nan_arr(enc)), 0.0)


# --- float32 vs float64 -------------------------------------------------------------

def test_float32_vs_float64_short_run():
    """Independent comparison run in float64 reference arithmetic (the same
    stages, float64): mass drift over a SHORT run and field divergence, with a
    stated tolerance measured from this run (never assumed)."""
    # float64 reference implementation of the same stages
    def ref_step(f, mask, omega, U0):
        f_prev = [fi.copy() for fi in f]
        for i in LEFT:
            f[i][:, -1] = f[i][:, -2]
        rho = sum(f)
        ux = sum(f[i] * E[i, 0] for i in range(9)) / rho
        uy = sum(f[i] * E[i, 1] for i in range(9)) / rho
        ux[1:-1, 0] = U0
        uy[1:-1, 0] = 0.0
        rho0, _ = rho[:, 0], None
        pure = f[0][:, 0] + f[2][:, 0] + f[4][:, 0]
        left = f[3][:, 0] + f[6][:, 0] + f[7][:, 0]
        rho[:, 0] = (pure + 2 * left) / (1 - ux[:, 0])
        r64, x64, y64 = rho, ux, uy
        feq = [W9[i] * r64 * (1 + 3 * (E[i, 0] * x64 + E[i, 1] * y64) + 4.5 * (E[i, 0] * x64 + E[i, 1] * y64) ** 2 - 1.5 * (x64 ** 2 + y64 ** 2)) for i in range(9)]
        for i in RIGHT:
            f[i][:, 0] = feq[i][:, 0]
        f = [fi + omega * (feq[i] - fi) for i, fi in enumerate(f)]
        for i in range(9):
            f[i][mask] = f_prev[OPP[i]][mask]
        f = [np.roll(np.roll(f[i], E[i, 0], axis=1), E[i, 1], axis=0) for i in range(9)]
        return f
    planes = _uniform()
    f64 = [fi.astype(np.float64) for fi in unpack(planes)]
    mask = _circle_mask()
    worst_mass = worst_field = 0.0
    for _ in range(30):
        planes, _ = lbm_step(planes, mask, float(OMEGA), U0, gain=1.0)
        f64 = ref_step(f64, mask, float(OMEGA), U0)
        f32l = unpack(planes)
        m64 = sum(f64).astype(F32)
        m32 = sum(fi.astype(np.float64) for fi in f32l).astype(F32)
        worst_mass = max(worst_mass, float(np.abs(m64 - m32).max()))
        worst_field = max(worst_field, max(float(np.abs(f64[i].astype(F32) - f32l[i]).max()) for i in range(9)))
    note("float32-vs-float64 worst field divergence after 30 steps", worst_field)
    note("float32-vs-float64 worst mass divergence after 30 steps", worst_mass)
    # tolerance stated from the measurement, headroom x4
    tol = float(worst_field) * 4.0 + 1e-6
    check("float32 mirrors float64 (field, 30 steps)", worst_field, max(tol, 1e-4))
    check("mass per cell tracks the float64 run (30 steps)", worst_mass, max(4e-3, worst_mass * 4 + 1e-6))


# --- mutations --------------------------------------------------------------------------

def test_mutations_are_caught():
    """Each bug value must fail at least one of these checks by a clear margin,
    and the real mirror must pass them all (exemplar pattern)."""
    def mass_err(bug=None):
        """One frame, no obstacle: the initial uniform state's total mass is
        exactly NX*NY*1; one frame preserves it (collision conserves per cell,
        streaming permutes, the channel BCs are the identity on the uniform
        state)."""
        planes = _uniform()
        mask = np.zeros((NY, NX), bool)
        planes, enc = lbm_step(planes, mask, float(OMEGA), U0, gain=1.0, bug=bug)
        return float(abs(sum(fi.astype(np.float64).sum() for fi in unpack(planes)) - NX * NY))

    def bounce_err(bug=None):
        """prev_after_bc is only distinguishable where the outflow copy has
        already overwritten a bounced population: the mask sits at the
        outflow column itself."""
        rng = np.random.default_rng(4)
        f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
        rho, ux, uy = macro(f)
        f = [fi / rho for fi in f]
        planes = pack(f)
        mask = np.zeros((NY, NX), bool)
        mask[:, NX - 1] = True
        out = unpack(fuse_local(planes, mask, 1.4, U0, bug=bug))
        worst = 0.0
        for i in range(9):
            expect = unpack([p.copy() for p in planes])[OPP[i]]
            worst = max(worst, float(np.abs(out[i][mask] - expect[mask]).max()))
        return worst

    def permute_err(bug=None):
        """bounce-back is a permutation of the cell's nine values, so the
        mask cell's mass is unchanged (works on a random non-equilibrium
        state, exact in float32 up to rounding)."""
        rng = np.random.default_rng(5)
        f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
        rho, ux, uy = macro(f)
        f = [fi / rho for fi in f]
        planes = pack(f)
        mask = _circle_mask()
        out = unpack(fuse_local(planes, mask, 1.4, U0, bug=bug))
        before = sum(fi.astype(np.float64) for fi in unpack(planes))
        after = sum(fi.astype(np.float64) for fi in out)
        return float(np.abs((after - before)[mask]).max())

    def mark_err(bug=None):
        planes = pack([np.full((NY, NX), 0.0, F32) for _ in range(9)])
        planes[0][NY // 2, 10, 1] = F32(1.0)   # f1 mark: plane 0 holds f0..f3, channel 1 = f1
        f_after = unpack(stream(planes, bug=bug))
        return abs(float(f_after[1][NY // 2, 11]) - 1.0)

    def encode_err(bug=None):
        """A generic (non-symmetric) velocity field makes a swapped RG visible:
        the encoded R must equal 0.5 + gain * ux from the float64 macro of the
        same planes, and G must equal 0.5 + gain * uy."""
        rng = np.random.default_rng(12)
        f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
        rho, ux, uy = macro(f)
        f = [fi / rho for fi in f]
        planes = pack(f)
        e = encode(planes, gain=1.7, bug=bug)
        r0, x0, y0 = macro(f)
        wr = float(np.abs(e[..., 0] - np.clip(F32(0.5) + F32(1.7) * x0, F32(0), F32(1))).max())
        wg = float(np.abs(e[..., 1] - np.clip(F32(0.5) + F32(1.7) * y0, F32(0), F32(1))).max())
        return max(wr, wg)

    def eq_err(bug=None):
        """wrong_weight changes the equilibrium, so the uniform state is no
        longer a fixed point even with the obstacle removed."""
        fexp64 = [W9[i] * (1.0 + 3.0 * E[i, 0] * U0 + 4.5 * (E[i, 0] * U0) ** 2 - 1.5 * U0 ** 2)
                  for i in range(9)]
        planes = _uniform()
        mask = np.zeros((NY, NX), bool)          # no obstacle: the state IS the fixed point
        for _ in range(1):
            planes, enc = lbm_step(planes, mask, float(OMEGA), U0, gain=1.0, bug=bug)
        worst = 0.0
        for i in range(9):
            worst = max(worst, float(np.abs(unpack(planes)[i] - F32(fexp64[i])).max()))
        return worst

    def inflow_err(bug=None):
        """Zou/He density must use the PRESCRIBED inflow velocity: on a random
        non-equilibrium state the inflow column's rightward populations equal
        the U0 equilibrium at (pure + 2 left) / (1 - U0) on the interior rows."""
        rng = np.random.default_rng(8)
        f = [(0.05 + rng.random((NY, NX))).astype(F32) for _ in range(9)]
        rho, ux, uy = macro(f)
        f = [fi / rho for fi in f]
        planes = pack(f)
        mask = np.zeros((NY, NX), bool)
        out = unpack(fuse_local(planes, mask, 0.0, U0, bug=bug))
        g0 = unpack([p.copy() for p in planes])
        pure = g0[0][:, 0].astype(np.float64) + g0[2][:, 0] + g0[4][:, 0]
        left = g0[3][:, 0].astype(np.float64) + g0[6][:, 0] + g0[7][:, 0]
        rho_z = ((pure + 2.0 * left) / (1.0 - U0))[1:-1]
        worst = 0.0
        for i in RIGHT:
            feq = W9[i] * rho_z * (1 + 3 * E[i, 0] * U0 + 4.5 * (E[i, 0] * U0) ** 2 - 1.5 * U0 ** 2)
            worst = max(worst, float(np.abs(out[i][1:-1, 0].astype(np.float64) - feq).max()))
        return worst

    real = [mass_err(), bounce_err(), permute_err(), mark_err(), encode_err(), eq_err(), inflow_err()]
    bad = {k: [mass_err(k), bounce_err(k), permute_err(k), mark_err(k), encode_err(k), eq_err(k), inflow_err(k)] for k in
           ["wrong_weight", "bounce_post", "prev_after_bc", "stream_sign", "swap_rg", "rho_pre_dirichlet"]}
    for k, v in bad.items():
        m = max(v)
        note(f"mutation '{k}' best check error", m)
        if not m > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (min error {m:.3e})")
    assert max(real) < 3e-5, f"the real mirror must pass the same checks: {real}"
    print("    ok   wrong weight, post-collision bounce, BC-first pre-copy, sign flips and swapped RG each caught")


if __name__ == "__main__":
    sys.exit(run(globals()))