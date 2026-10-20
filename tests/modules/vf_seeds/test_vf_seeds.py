"""
test_vf_seeds.py -- tier-1 NumPy tests for f_vf_seeds Stage 1c (merge) and Stage 4 (composite).

Ground truth is independent of the mirror: a plain per-pixel sort of the four candidates
by priority for the merge (float64), the textbook 'over' operator
c = a1*c1 + (1-a1)*c2, alpha = a1 + a2*(1-a1) for the composite, hand-chosen closed-form
selections, and the doc's bypass statements. Tolerances are 1e-5 or 0.0 throughout (all
reads are exactly at norm, so there is no interpolation floor; sorting and the over
operator are exact in float32 on these inputs up to ~1e-7 rounding, well inside 1e-5).

Scope: Stage 1c merge (six inlets: rank1A, rank2A, priA pair, rank1B, rank2B, priB pair;
coords carry (gx, gy, dx, dy)) and Stage 4 composite only. The search stages (hash-driven
candidate grids) and the render stages are not part of this unit. char pixel-type
quantization at the module's outer outlet is not modeled.
"""
import sys

import numpy as np

from harness import check, note, run  # noqa: E402
from vf_seeds_mirror import F32, merge_stage, composite_stage  # noqa: E402

N = 32
BUGS = ["swap_step_pair", "skip_second_demote", "out3_carries_offsets",
        "composite_reversed", "no_bypass_out2"]


def coord_tex(seed, n=N):
    """Random coordinate texture: gx, gy in [0,1), dx, dy in [-0.1, 0.1)."""
    rng = np.random.default_rng(seed)
    t = np.zeros((n, n, 4), F32)
    t[..., 0] = rng.random((n, n))
    t[..., 1] = rng.random((n, n))
    t[..., 2] = (rng.random((n, n)) - 0.5) * 0.2
    t[..., 3] = (rng.random((n, n)) - 0.5) * 0.2
    return t


def pri_tex(seed, n=N, hi=1.0, lo=0.0):
    """Random priority pair texture, two distinct values per pixel in [lo, hi)."""
    rng = np.random.default_rng(seed)
    t = np.zeros((n, n, 4), F32)
    t[..., 0] = lo + rng.random((n, n)) * (hi - lo)
    t[..., 1] = lo + rng.random((n, n)) * (hi - lo)
    return t


def render_tex(seed, n=N):
    rng = np.random.default_rng(seed)
    t = np.zeros((n, n, 4), F32)
    t[..., :3] = rng.random((n, n, 3))
    t[..., 3] = rng.random((n, n)) * 0.8 + 0.1
    return t


def const_tex(rgba, n=N):
    t = np.zeros((n, n, 4), F32)
    t[...] = np.array(rgba, F32)
    return t


def _sorted_top2(pri1, pri2, pri3, pri4, c1, c2, c3, c4):
    """Independent reference: plain stable ascending sort of the four candidates by priority.

    pri_k is (H, W); c_k is (H, W, 4). Returns rank-1 and rank-2 coordinates (H, W, 4)
    in float64. Only meaningful on pixels with no tie across ranks 1 and 2.
    """
    pri = np.stack([pri1, pri2, pri3, pri4], axis=-1).astype(np.float64)   # H, W, 4
    coords = np.stack([c1, c2, c3, c4], axis=-2).astype(np.float64)        # H, W, 4c, 4
    order = np.argsort(pri, axis=-1, kind="stable")                        # H, W, 4
    # gather each of ranks 0..1 across the fourcoord channels
    ranks = []
    for r in range(2):
        sel = np.take_along_axis(coords, order[..., r, None, None], axis=-2)  # H, W, 1, 4
        ranks.append(sel[..., 0, :])
    return ranks[0], ranks[1]


def _err(a, b, mask=None):
    """Worst |a - b| with any non-finite measured value as a hard error."""
    fin = np.isfinite(a) & np.isfinite(b)
    err = np.abs(np.where(fin, a, np.inf) - np.where(fin, b, np.inf).astype(np.float64))
    if mask is not None:
        err = err[mask]
    return float(err.max())


# --- merge vs plain sort ----------------------------------------------------------------

def _merge_sort_err(bug=None, seeds=(11, 12, 13, 14, 21, 22)):
    """Error of out1/out2 against a float64 plain ascending sort of the four candidates."""
    cA1, cA2, cB1, cB2 = (coord_tex(s) for s in (seeds[0], seeds[1], seeds[2], seeds[3]))
    pA, pB = pri_tex(seeds[4]), pri_tex(seeds[5])
    out1, out2, _ = merge_stage(cA1, cA2, pA, cB1, cB2, pB, bug=bug)
    ref1, ref2 = _sorted_top2(pA[..., 0], pA[..., 1], pB[..., 0], pB[..., 1], cA1, cA2, cB1, cB2)
    pri = np.stack([pA[..., 0], pA[..., 1], pB[..., 0], pB[..., 1]], axis=-1).astype(np.float64)
    srt = np.sort(pri, axis=-1)
    no_tie = (srt[..., 0] < srt[..., 1]) & (srt[..., 1] < srt[..., 2])
    return max(_err(out1[no_tie], ref1[no_tie]), _err(out2[no_tie], ref2[no_tie]))


def test_merge_matches_plain_sort():
    """The merge keeps the best two of four candidates by lower priority value: on pixels with
    no tie across ranks 1-2 a plain float64 sort of the four (priority, coord) candidates must
    give the same ranks 1 and 2 coords."""
    worst = 0.0
    for s in [(11, 12, 13, 14, 21, 22), (31, 32, 33, 34, 41, 42)]:
        worst = max(worst, _merge_sort_err(seeds=s))
    check("merge top-2 vs plain ascending sort of four candidates", worst, 1e-5)


def test_merge_hand_chosen_selection():
    """Constant textures, priorities chosen by hand: priA1=0.3, priA2=0.4, priB1=0.1, priB2=0.9
    must give rank 1 = B1's candidate and rank 2 = A1's candidate, with B2 and A2 demoted."""
    cA1, cA2 = coord_tex(1), coord_tex(2)
    cB1, cB2 = coord_tex(3), coord_tex(4)
    pA = const_tex((0.3, 0.4, 0.0, 0.0))
    pB = const_tex((0.1, 0.9, 0.0, 0.0))
    out1, out2, _ = merge_stage(cA1, cA2, pA, cB1, cB2, pB)
    e = max(_err(out1, cB1), _err(out2, cA1))
    check("constant priorities select rank1=B1, rank2=A1", e, 0.0)


def test_merge_outputs_carry_coord_format():
    """out1/out2 carry (gx, gy, dx, dy) of the winning candidates: with constants where each
    candidate has its own distinct gx, gy, dx, dy, the winner's dx and dy must appear in
    out1's z and w."""
    cA1 = const_tex((0.10, 0.11, 0.12, 0.13))
    cA2 = const_tex((0.20, 0.21, 0.22, 0.23))
    cB1 = const_tex((0.30, 0.31, 0.32, 0.33))
    cB2 = const_tex((0.40, 0.41, 0.42, 0.43))
    out1, out2, _ = merge_stage(cA1, cA2, const_tex((0.9, 0.8, 0, 0)), cB1, cB2, const_tex((0.7, 0.6, 0, 0)))
    expect1 = const_tex((0.40, 0.41, 0.42, 0.43))
    expect2 = const_tex((0.30, 0.31, 0.32, 0.33))
    e = max(_err(out1, expect1), _err(out2, expect2))
    check("winner's (gx, gy, dx, dy) lands in out1, runner-up in out2", e, 0.0)


def test_merge_out3_seed_coord_contract():
    """The codebox comment fixes out3's format: 'out3 = vec(best_gx, best_gy, 0.0, 1.0)' --
    zero-padded seed coord, blended to (0, 0, 0, 1) by bypass."""
    cA1, cA2, cB1, cB2 = (coord_tex(s) for s in (51, 52, 53, 54))
    pA, pB = pri_tex(55), pri_tex(56)
    _, _, out3 = merge_stage(cA1, cA2, pA, cB1, cB2, pB)
    pri = np.stack([pA[..., 0], pA[..., 1], pB[..., 0], pB[..., 1]], axis=-1).astype(np.float64)
    srt = np.sort(pri, axis=-1)
    no_tie = (srt[..., 0] < srt[..., 1])
    best = np.stack([pA[..., 0], pA[..., 1], pB[..., 0], pB[..., 1]], -1).argmin(-1)
    coords = np.stack([cA1, cA2, cB1, cB2], axis=-2).astype(np.float64)
    bgx = np.take_along_axis(coords[..., 0], best[..., None], axis=-1)[..., 0]
    bgy = np.take_along_axis(coords[..., 1], best[..., None], axis=-1)[..., 0]
    expect = np.stack([bgx, bgy, np.zeros_like(bgx), np.ones_like(bgx)], axis=-1)
    e3 = _err(out3[no_tie], expect[no_tie])
    check("out3 is (best gx, best gy, 0, 1)", e3, 0.0)
    _, _, out3b = merge_stage(cA1, cA2, pA, cB1, cB2, pB, bypass=1.0)
    black = const_tex((0.0, 0.0, 0.0, 1.0))
    check("out3 on bypass is (0, 0, 0, 1)", float(np.abs(out3b - black).max()), 0.0)


def test_merge_tie_goes_by_pair_rank2():
    """Tie convention pinned to the codebox (ties follow step's >= semantics, so this check is
    codebox-dependent, paired with the tie-free sort checks above): with priA1 == priA2 the
    A-pair's rank-2 slot wins the internal best, so out1 carries A2's coord."""
    cA1, cA2 = coord_tex(61), coord_tex(62)
    cB1, cB2 = coord_tex(63), coord_tex(64)
    pA = const_tex((0.5, 0.5, 0, 0))
    pB = const_tex((0.9, 0.8, 0, 0))
    out1, out2, _ = merge_stage(cA1, cA2, pA, cB1, cB2, pB)
    check("tie within the A pair demotes A1 (out1 = A2 coord)", float(np.abs(out1 - cA2).max()), 0.0)


# --- composite vs the over operator ------------------------------------------------------

def _composite_over_err(bug=None, seed=71):
    """Error of out1/out2 against the float64 textbook over operator:
    rgb = a1*c1 + (1 - a1)*c2, alpha = a1 + a2*(1 - a1)."""
    r1, r2 = render_tex(seed), render_tex(seed + 1)
    out1, out2 = composite_stage(r1, r2, bug=bug)
    a1 = r1[..., 3].astype(np.float64)
    a2 = r2[..., 3].astype(np.float64)
    comp = a1[..., None] * r1.astype(np.float64) + (1.0 - a1)[..., None] * r2.astype(np.float64)
    comp[..., 3] = a1 + a2 * (1.0 - a1)
    e1 = _err(out1, comp.astype(F32))
    mask = np.stack([comp[..., 3]] * 3 + [np.ones_like(a1)], axis=-1).astype(F32)
    e2 = _err(out2, mask)
    return max(e1, e2)


def test_composite_matches_over_operator():
    """Rank-1-over-rank-2 composite is the textbook over operator with rank 1's own alpha as
    the blend factor; out2 is exactly that composited alpha as grayscale with alpha 1."""
    worst = max(_composite_over_err(seed=71), _composite_over_err(seed=81))
    check("composite rgb+alpha vs over operator, out2 vs alpha gray", worst, 1e-5)


def test_composite_full_and_zero_alpha_identities():
    """Over-operator identity: a1 = 1 makes the composite rank 1's render exactly (over an
    arbitrary rank 2); a1 = 0 makes it rank 2's render with rgb unchanged and alpha = a2."""
    r2 = render_tex(91)
    one = render_tex(92)
    one[..., 3] = 1.0
    out1, out2 = composite_stage(one, r2)
    check("a1=1: composite is rank 1 exactly", float(np.abs(out1 - one).max()), 0.0)
    zero = render_tex(93)
    zero[..., 3] = 0.0
    out1, _ = composite_stage(zero, r2)
    expect = np.zeros_like(r2)
    expect[..., :3] = r2[..., :3]
    expect[..., 3] = r2[..., 3]
    check("a1=0: composite rgb is rank 2's rgb, alpha = a2", float(np.abs(out1 - expect).max()), 0.0)


def test_composite_bypass():
    """The codebox comment fixes the bypass values: out1 blends to (0, 0, 0, 0) and out2 to
    (0, 0, 0, 1) as bypass rises to 1."""
    r1, r2 = render_tex(95), render_tex(96)
    out1, out2 = composite_stage(r1, r2, bypass=1.0)
    check("bypass out1 is (0, 0, 0, 0)", float(np.abs(out1).max()), 0.0)
    black = const_tex((0.0, 0.0, 0.0, 1.0))
    check("bypass out2 is (0, 0, 0, 1)", float(np.abs(out2 - black).max()), 0.0)


def test_bypass_out1_is_transparent_not_opaque_black():
    """The doc's Key Findings say bypass output is fully transparent (0,0,0,0), i.e. alpha 0,
    not opaque black: out1's alpha channel must be exactly 0 on bypass."""
    r1, r2 = render_tex(97), render_tex(98)
    out1, _ = composite_stage(r1, r2, bypass=1.0)
    check("doc: bypass alpha is 0 (transparent), not 1", float(np.abs(out1[..., 3]).max()), 0.0)


# --- generic point -----------------------------------------------------------------------

def test_generic_parameters():
    """A check at generic (arbitrary non-special) values, which no special-value check can
    replace: random coord/priority/render textures, both stages, mid bypass for the merge's
    out3 mid-blend against the linear mix of the two endpoint contracts."""
    out1, out2, out3 = merge_stage(coord_tex(101), coord_tex(102), pri_tex(103),
                                   coord_tex(104), coord_tex(105), pri_tex(106), bypass=0.25)
    ok = _merge_sort_err(seeds=(101, 102, 104, 105, 103, 106))
    _, _, out3_full = merge_stage(coord_tex(101), coord_tex(102), pri_tex(103),
                                  coord_tex(104), coord_tex(105), pri_tex(106), bypass=0.0)
    black = const_tex((0.0, 0.0, 0.0, 1.0))
    expect = 0.75 * out3_full + 0.25 * black
    e = max(_err(out3, expect), ok)
    check("generic point: merge sort error and out3 = mix(contract, black, 0.25)", e, 1e-5)
    err = _composite_over_err(seed=111)
    check("generic point: composite over-operator error", err, 1e-5)


# --- mutations ---------------------------------------------------------------------------

def test_mutations_are_caught():
    """Every declared bug must fail at least one check by a clear margin, and the real mirror
    must pass the same checks."""
    real = [_merge_sort_err(), _composite_over_err()]
    caught = {
        "swap_step_pair": max(_merge_sort_err(bug="swap_step_pair"),
                              _merge_sort_err(bug="swap_step_pair", seeds=(31, 32, 33, 34, 41, 42))),
        "skip_second_demote": _merge_sort_err(bug="skip_second_demote"),
        "out3_carries_offsets": _out3_err(bug="out3_carries_offsets"),
        "composite_reversed": max(_composite_over_err(bug="composite_reversed"),
                                  _composite_over_err(bug="composite_reversed", seed=81)),
        "no_bypass_out2": _bypass_out2_err(bug="no_bypass_out2"),
    }
    for k, v in caught.items():
        note(f"mutation '{k}' worst error", v)
        if not v > 1e-3:
            raise AssertionError(f"mutation not detected: {k} (error {v:.3e})")
    if max(real) >= 1e-5:
        raise AssertionError(f"the real mirror must pass the same checks: {real}")
    print("    ok   the five declared mutations are each caught by a clear margin")


def _out3_err(bug=None):
    cA1, cA2, cB1, cB2 = (coord_tex(s) for s in (51, 52, 53, 54))
    pA, pB = pri_tex(55), pri_tex(56)
    _, _, out3 = merge_stage(cA1, cA2, pA, cB1, cB2, pB, bug=bug)
    pri = np.stack([pA[..., 0], pA[..., 1], pB[..., 0], pB[..., 1]], axis=-1).astype(np.float64)
    srt = np.sort(pri, axis=-1)
    no_tie = (srt[..., 0] < srt[..., 1])
    best = pri.argmin(-1)
    coords = np.stack([cA1, cA2, cB1, cB2], axis=-2).astype(np.float64)
    bgx = np.take_along_axis(coords[..., 0], best[..., None], axis=-1)[..., 0]
    bgy = np.take_along_axis(coords[..., 1], best[..., None], axis=-1)[..., 0]
    expect = np.stack([bgx, bgy, np.zeros_like(bgx), np.ones_like(bgx)], axis=-1)
    return _err(out3[no_tie], expect[no_tie])


def _bypass_out2_err(bug=None):
    r1, r2 = render_tex(95), render_tex(96)
    _, out2 = composite_stage(r1, r2, bypass=1.0, bug=bug)
    black = const_tex((0.0, 0.0, 0.0, 1.0))
    return float(np.abs(out2 - black).max())


if __name__ == "__main__":
    sys.exit(run(globals()))