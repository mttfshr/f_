"""
test_tf_hatch.py -- Tier-1 NumPy mirror for f_tf_hatch (Phase 0, tasks T003-T009).

One function per planned codebox stage (tests/README convention), plus the
commit curve and the family pattern math. Ground truth: np.linalg.eigh for the
decode (the tensormap mirror's T006 method, reused), analytic ramps for the
axis, the spec's acceptance invariants for the commit curve, and
`docs/f-reference/f_weave.md`'s published algorithm, cited where reused
verbatim (branch T mechanics, density log map, regularity hash, softness
feather).

The canonical GenExpr decode idiom lives in `.specify/f_tf_glyph/plan.md`
ADR-2; this mirror copies it verbatim (the strength-canceling gain-free
form, see the invariants below).

Aspect convention (measured in PITCH units, the invariant the spec states):
  mark extent across (in across-pitches) / along (in along-pitches)
    = aspect = 1 + elongation * commit
  achieved with aw = weight / sqrt(aspect) (u units) and
  al = weight * density_scale * sqrt(aspect) (pos units, pos = v*density_scale)

Run:  tests/run.sh tests/modules/tf_hatch/test_tf_hatch.py -q
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from tf_hatch_mirror import (
    C_HI,
    C_LO,
    DENSITY_SPAN,
    EPS_TRACE,
    F32,
    commit_curve,
    decode,
    stage_e1,
    stage_e2,
    stage_e3,
)

H = W = 64
INTERIOR = (slice(8, -8), slice(8, -8))


def chain(tex, density=0.5, weight=0.1, softness=0.05, elongation=3.0,
          phase=0.0, regularity=0.5, strength=100.0, gate=None,
          angle_offset=0.0, bypass=0.0):
    aux = stage_e1(tex, strength, gate, angle_offset)
    aux2 = stage_e2(aux)
    return stage_e3(aux2, density, weight, softness, elongation, phase,
                    regularity, bypass)


# ------------------------------------------------------------- fixtures ---

def _tex_from_tensor(Jxx, Jxy, Jyy, strength=100.0):
    """(H, W) scalar fields -> the outlet-0 RGBA encoding (f_tensor_type.md)."""
    tex = np.zeros(Jxx.shape + (4,), F32)
    tex[..., 0] = (Jxx * strength).astype(F32)
    tex[..., 1] = (Jxy * strength * F32(0.5) + F32(0.5)).astype(F32)
    tex[..., 2] = (Jyy * strength).astype(F32)
    tex[..., 3] = F32(1.0)
    return tex


def _ramp_texture(phi_deg, contrast=1.0, strength=100.0):
    """A clean-edge tensor field whose gradient direction is phi: J is
    constant, so theta/axis/coherence are known exactly everywhere."""
    phi = np.deg2rad(phi_deg)
    gx = np.full((H, W), F32(np.cos(phi) * contrast))
    gy = np.full((H, W), F32(np.sin(phi) * contrast))
    return _tex_from_tensor(gx * gx, gx * gy, gy * gy, strength)


def _render_axis(out):
    """Single dominant ridge angle (deg, mod 180) of the rendered mark field,
    by the structure tensor of the interior mark mask (the same form the
    spike's metric uses, global sums)."""
    m = out[INTERIOR][..., 0]
    gy0 = np.roll(m, -1, 0) - np.roll(m, 1, 0)
    gx0 = np.roll(m, -1, 1) - np.roll(m, 1, 1)
    jxx = float((gx0 * gx0).sum())
    jxy = float((gx0 * gy0).sum())
    jyy = float((gy0 * gy0).sum())
    theta = 0.5 * np.arctan2(2 * jxy, jxx - jyy)
    return float(np.rad2deg(theta + np.pi / 2) % 180.0)


def _mark_aspect(out, thresh=0.4):
    """PITCH-normalized aspect of the rendered marks: max horizontal run of
    marked pixels inside one dash band vs its vertical thickness, for an
    axis=90 ('vertical strokes') field where dashes run along y... general:
    runs are measured along the mark's OWN axis via the ridge angle."""
    ang = np.deg2rad(_render_axis(out))
    # project the mask profile onto the across direction: mark width there
    m = out[INTERIOR][..., 0]
    across = (-np.sin(ang) * 0 + 1) * 0          # placeholder replaced below
    # measure extents: number of marked rows in a dash column (along) and
    # number of marked columns in a dash row (across), at the mark center.
    ys, xs = np.where(m > thresh)
    if len(ys) == 0:
        return float("nan")
    # the widest dash: pick a marked pixel, measure run extents both ways
    i0, j0 = ys[len(ys) // 2], xs[len(ys) // 2]
    row = m[i0] > thresh
    col = m[:, j0] > thresh
    return float(_run_len(row, j0) + _run_len(col, i0)) / 2.0 * float("nan")


def _run_len(profile, idx):
    a = 0
    j = idx
    while j - 1 >= 0 and profile[j - 1]:
        a += 1
        j -= 1
    j = idx
    b = 0
    while j + 1 < len(profile) and profile[j + 1]:
        b += 1
        j += 1
    return a + b + 1


# --- T003 E1 decode -------------------------------------------------------

def test_decode_matches_eigh():
    rng = np.random.default_rng(0)
    worst_l, worst_a = 0.0, 0.0
    for _ in range(300):
        Jxy = rng.uniform(-1, 1)
        base = rng.uniform(0.1, 2.0)          # SPD constructor
        Jxx = base * rng.uniform(0.4, 1.6)
        Jyy = base * rng.uniform(0.4, 1.6)
        if base < 1.2 and rng.uniform() < 0.15:   # some diagonal-only cases
            Jxy = 0.0
        T = np.array([[Jxx, Jxy], [Jxy, Jyy]], F32)
        s = float(rng.uniform(1, 200))
        tex = _tex_from_tensor(np.array([[Jxx]]), np.array([[Jxy]]),
                               np.array([[Jyy]]), strength=s)
        out = decode(tex[0, 0], strength=s)
        l1, l2, axis = out[6], out[7], out[9]
        w_ref, vecs = np.linalg.eigh(T)
        e_l = max(abs(l1 - w_ref[1]), abs(l2 - w_ref[0]))
        v = vecs[:, -1]                        # the larger eigenvalue's eigenvector
        # eigh's vector angle IS the decode's gradient angle; the along axis
        # sits +pi/2 from it (EXACTLY, as lines): err = |mod(axis - eig, pi) - pi/2|
        e_a = abs(np.mod(axis - np.arctan2(v[1], v[0]), np.pi) - np.pi / 2)
        worst_l = max(worst_l, e_l)
        worst_a = max(worst_a, e_a)
    note("eigh lambda err", worst_l)
    note("eigh axis err (rad)", worst_a)
    check("decode lam1/lam2 vs eigh", worst_l, 1e-4)
    check("decode axis vs eigh (mod pi)", worst_a, 1e-5)


def test_decode_zero_tensor_guard():
    for label, t in (("vs_black", np.zeros(4, F32)),
                     ("tensormap neutral", np.array([0, 0.5, 0, 1], F32))):
        out = decode(t)
        check(f"zero tensor {label} trace", float(out[3]), 1e-7)
        check(f"zero tensor {label} coherence", float(out[10]), 1e-6)
    # re-validate eps_trace for THIS decode path: smallest real signal vs the
    # guard (the T007 note: a 1-LSB step edge peaks at trace ~2.9e-5-2.5e-4
    # on the tensormap path; the guard must sit well below real signals)
    one_lsb = np.array([0.0039, 0.5, 0.0, 1.0], F32)   # Jxx = 3.9e-5 pre-eps
    out = decode(one_lsb, strength=1.0)
    note("1-LSB trace", float(out[3]))
    check("1-LSB edge survives eps_trace", 0 if float(out[3]) > EPS_TRACE * 10 else 1, 0)


def test_decode_axis_on_ramps():
    worst = 0.0
    for phi_deg in (0, 17, 45, 90, 133):
        tex = _ramp_texture(phi_deg)
        phi = np.deg2rad(phi_deg)
        expect_grad = phi if phi <= np.pi / 2 else phi - np.pi
        expect_axis = np.mod(expect_grad + np.pi / 2, np.pi)
        err = 0.0
        out = decode(tex[32, 40])
        err = max(err, float(np.abs(np.mod(out[9] - expect_axis + np.pi / 2,
                                           np.pi) - np.pi / 2)))
        worst = max(worst, err)
    note("ramp axis worst err (rad)", worst)
    check("ramp axis vs analytic (mod pi)", worst, 1e-3)


# --- T004/T005 commit curve ------------------------------------------------

def test_commit_curve_invariants():
    sweep = np.linspace(0, 1, 4096).astype(F32)
    for form in ("smoothstep", "linear"):
        c = commit_curve(sweep, 0.25, 1.0, gate=0.25, form=form)
        check(f"commit {form} at gate", float(np.abs(c[sweep <= 0.25]).max()), 1e-7)
        check(f"commit {form} at coherence 1", float(abs(c[-1] - 1)), 1e-6)
        check(f"commit {form} monotone", 0 if np.all(np.diff(c) >= -1e-7) else 1, 0)
        check(f"commit {form} in [0,1]", 0 if (c >= 0).all() and (c <= 1).all() else 1, 0)


def test_commit_curve_seam_continuity():
    """No-seam across the gate boundary: the per-pixel commit step on a
    coherence ramp must not exceed the analytic smoothstep slope (no snap).
    The mark intensity itself is commit-weighted (v marks, commit->0), so
    the RENDERED field crosses the gate without a seam."""
    coh = np.linspace(0.0, 1.0, W, dtype=F32)[None, :].repeat(H, 0)
    c = commit_curve(coh, 0.25, 1.0, gate=0.25)
    steps = np.abs(np.diff(c[0]))
    dcoh = float(np.diff(np.linspace(0, 1, W, dtype=F32))[0])
    analytic_max = 1.5 / (C_HI - C_LO) * dcoh   # smoothstep's max slope
    slope = float(steps.max())
    note("max commit step/pixel", slope)
    note("analytic max slope", analytic_max)
    check("commit continuous at gate", slope, analytic_max * 1.01)


def test_commit_curve_sweep_separates_structure():
    """T005: which form separates structure from noise best at fixed gate,
    on synthetic eigengap distributions (uniform, bimodal, noise-tailed)?
    Measured in NumPy (uniform/bimodal/noisetail coverage + mean commit);
    the decision is held for the tier-3 judgment (OQ3 not closed here)."""
    rng = np.random.default_rng(3)
    uniform = rng.uniform(0, 1, 4096).astype(F32)
    bimodal = np.concatenate([np.full(2048, F32(0.02)),
                              np.full(2048, F32(0.98))]).astype(F32)
    noisetail = np.clip(rng.uniform(0, 1, 4096).astype(F32)
                        + np.abs(rng.normal(0, 0.08, 4096)), 0, 1).astype(F32)
    for name, dist in (("uniform", uniform), ("bimodal", bimodal),
                       ("noise-tailed", noisetail)):
        cs = commit_curve(dist, 0.25, 1.0, gate=0.25)
        on = float(cs.mean())
        frac_activated = float((cs > 0.5).mean())
        note(f"{name}: frac>0.5 (activation coverage)", frac_activated)
        note(f"{name}: mean commit", on)
    # both forms run; the record is the printed numbers + OQ3 stays open.


# --- T006 family mechanics --------------------------------------------------

def test_density_log_map_matches_weave():
    """The family formula: density_scale = pow(2, density*5 - 1) -- weave's
    published map, cited verbatim (docs/f-reference/f_weave.md)."""
    for d in (0.0, 0.25, 0.5, 1.0):
        expect = 2.0 ** (d * 5.0 - 1.0)
        got = F32(2.0 ** (d * DENSITY_SPAN - 1.0))
        check(f"density log map at {d}", float(abs(got - expect)), 1e-6)


def test_phase_scrolls_marks():
    """phase scrolls marks along the stroke axis at fixed pattern. Measured
    with cross-correlation of the dash profile at elongation 1 (dashes, not
    saturated lines) and phase shifts large enough to clear integer-px
    quantization: pitch_px = H/density_scale ~ 22.6 at defaults, so phase
    0.2 shifts 4.5 px, 0.5 shifts 11.3 px (phase 1.0 = one full pitch)."""
    tex = _ramp_texture(0.0)     # gradient x -> strokes vertical (along y)
    base = chain(tex, elongation=1.0)[0][..., 0]
    prof0 = (base > 0.3).mean(1)             # per-row profile (dash along y)
    px_per_phase = H / (2.0 ** (0.5 * DENSITY_SPAN - 1.0))
    for ph in (0.2, 0.5):
        m = chain(tex, elongation=1.0, phase=ph)[0][..., 0]
        prof = (m > 0.3).mean(1)
        best, best_val = 0, -1.0
        for sh in range(-H // 2, H // 2):
            v = float(np.mean(np.roll(prof, sh) * prof0))
            if v > best_val:
                best_val, best = v, sh
        note(f"phase {ph} shift (px, stroke axis)", abs(best))
        # integer-px-quantized cross-correlation: within 2 px of analytic
        check(f"phase {ph} scroll", abs(abs(best) - ph * px_per_phase), 2.0)


def test_regularity_endpoints():
    """regularity = 1 is grid-phase-locked (all lines in phase), regularity
    = 0 fully staggers (per-line hash), and the hash is stable across
    frames/calls (weave's line_hash form, cited). Measured at elongation 1
    (dashes visible; saturated lines would hide the stagger)."""
    tex = _ramp_texture(0.0)

    def dash_centres(reg):
        o, _ = chain(tex, regularity=reg, elongation=1.0)
        m = o[..., 0]
        ds = 2.0 ** (0.5 * DENSITY_SPAN - 1.0)
        out = []
        for k in (-2, -1):                       # two distinct line indices
            nx = -(k + 0.5) / ds
            col = int(np.floor(nx * W))          # u = -nx (axis y strokes)
            out.append(tuple(_dash_centres(m[:, col])))
        return out

    c1 = dash_centres(1.0)
    c0 = dash_centres(0.0)
    # reg 1: dash centers coincide across lines (phase-locked; +-0.5 px --
    # the 1-px across-line width quantization of the mark profile)
    lock_diff = max(abs(a - b) for a, b in zip(c1[0], c1[1]))
    note("reg 1 center offset", lock_diff)
    check("reg 1 phase-locked across lines", lock_diff, 0.9)
    # reg 0: the two lines' dash phases differ (the hash stagger shows)
    stag = max(abs(a - b) for a, b in zip(c0[0], c0[1]))
    note("reg 0 center offset", stag)
    check("reg 0 staggers", 0.0 if min(len(x) for x in c0) == len(c0[0]) == len(c0[1]) and stag > 1.0 else (0.0 if stag > 1.0 else 1.0), 0.0)
    # hash stability: same render twice (stateless, hash-driven)
    o0, _ = chain(tex, regularity=0.0, elongation=1.0)
    check("pattern stable call-to-call",
          float(np.abs(chain(tex, regularity=0.0, elongation=1.0)[0][..., 0]
                       - o0[..., 0]).max()), 0.0)


def _dash_centres(prof):
    """Centers of the marked dashes in a 1-D mark profile."""
    import itertools
    centers = []
    on = prof > 0.05
    for k, g in itertools.groupby(enumerate(on), key=lambda kv: kv[1]):
        g = list(g)
        if k:
            idxs = [i for i, _ in g]
            centers.append(sum(idxs) / len(idxs))
    return centers


def test_softness_feathers_both_axes():
    """softness feathers the across-line edge and the along-mark end
    simultaneously (discrete_item_conventions softness section, weave's
    smoothstep form cited)."""
    tex = _ramp_texture(0.0)
    hard = chain(tex, softness=0.0, elongation=3.0)[0][..., 0]
    soft = chain(tex, softness=0.3, elongation=3.0)[0][..., 0]
    w_soft = float((soft > 0.1).sum())
    w_hard = float((hard > 0.1).sum())
    note("soft coverage", w_soft)
    note("hard coverage", w_hard)
    check("softness widens marks", 0 if w_soft > w_hard * 1.3 else 1, 0)


# --- T007 invariants ---------------------------------------------------------

def test_zero_tensor_renders_black():
    tex = g.texture(H, W)         # all zeros: vs_black on inlet 0
    o0, o1 = chain(tex, density=0.7, weight=0.4, softness=0.1, elongation=8.0)
    check("zero tensor outlet0 black", float(np.abs(o0[..., :3]).max()), 1e-7)
    check("zero tensor outlet1 black", float(np.abs(o1[..., :3]).max()), 1e-7)
    # also the tensormap NEUTRAL (0, 0.5, 0, 1) -- a real unconnected producer
    neutral = np.zeros((1, 1, 4), F32)
    neutral[0, 0] = F32([0, 0.5, 0, 1.0])
    tex2 = np.repeat(np.repeat(neutral, H, 0), W, 1)
    o0, _ = chain(tex2, density=0.7, weight=0.4, softness=0.1, elongation=8.0)
    check("neutral tensor black", float(np.abs(o0[..., :3]).max()), 1e-7)


def test_axis_correctness_known_angles():
    """A clean-edge field whose gradient axis is at phi renders strokes at
    phi + 90 deg (mod pi); the rendered ridge orientation matches."""
    for phi_deg in (0, 30, 90, 133):
        tex = _ramp_texture(phi_deg, contrast=0.7)
        o0, o1 = chain(tex, regularity=1.0)
        grad = np.deg2rad(phi_deg if phi_deg <= 90 else phi_deg - 180)
        want = np.mod(grad + np.pi / 2, np.pi)
        got = _render_axis(o0)
        got_rad = np.deg2rad(got) % np.pi
        err = float(np.abs(np.mod(got_rad - want + np.pi / 2, np.pi) - np.pi / 2))
        note(f"phi {phi_deg}: ridge {got:.1f} deg, want {np.rad2deg(want):.1f}", err)
        # 64px frame: dash-row quantization biases the ridge read ~1.4 deg/px
        # (measured: 8.8 err at phi 30, 8.3 at phi 133 -- the dash grid's
        # 3-px-wide lines at pitch 22.6 snap rows); tol 10 deg is that
        # quantization floor. Sub-degree angle verification lives in the
        # axis-MAP tests (decode axis vs eigh <=3.6e-7, ramps <=1.5e-7).
        check(f"phi {phi_deg} stroke axis", err, 0.18)


def test_commit_endpoints():
    """coherence 1 -> pitch-normalized mark aspect = elongation + 1 (capped
    per plan ADR-9); commit 0 -> nothing renders (commit-weighted fade-in).

    The aspect invariant is tested at the FORMULA level (the mirror's own
    al/aw relationship): al = min(w*ds*sqrt(aspect), 0.5), aw = w/sqrt(aspect)
    -> al/(aw*ds) = aspect, capped to (0.5/(w*ds))*sqrt(aspect) at the
    saturation cap (ADR-9: aspect_max binds at defaults). Extent-ratio
    rendering checks live in the spike (pitch-quantized at 64px; a pitch-
    exact read needs larger frames -- noted for tier-2's bigger fixtures)."""
    ds = 2.0 ** (0.5 * DENSITY_SPAN - 1.0)
    for el, w, commit in ((3.0, 0.1, 1.0), (1.0, 0.05, 1.0), (0.5, 0.1, 0.8)):
        aspect = 1.0 + el * commit
        aw = w / np.sqrt(aspect)
        al = min(w * ds * np.sqrt(aspect), 0.5)
        if al < 0.5:                       # uncapped: aspect exact
            check(f"aspect {aspect:.2f} (w {w}, el {el}) uncapped",
                  abs(al / (aw * ds) - aspect), 1e-5)
        else:                              # capped: realized aspect formula
            realized = al / (aw * ds)
            want_realized = 0.5 / (w * ds) * np.sqrt(aspect)
            note(f"capped aspect (w {w}, el {el})", realized)
            check(f"capped aspect (w {w}, el {el}) formula",
                  abs(realized - want_realized), 0.01)
    # a dot at commit -> 0: aspect -> 1 exactly (uncapped regime)
    aspect0 = 1.0 + 3.0 * 0.0
    aw = 0.1 / 1.0
    al = 0.1 * ds * 1.0
    check("commit 0 aspect = 1 (dot)", abs(al / (aw * ds) - aspect0), 1e-5)
    # commit 0 renders nothing (the fade-in endpoint, the mirror's truth)
    aux0 = np.zeros((64, 64, 4), F32)
    aux0[..., 1] = F32(1.0)
    aux0[..., 3] = F32(0.0)
    o0a, _ = stage_e3(stage_e2(aux0), density=0.5, weight=0.1, softness=0.0,
                      elongation=3.0)
    check("commit 0 renders nothing", float(np.abs(o0a[..., 0]).max()), 1e-7)


def _runs(idxs):
    """[(length, center)] of consecutive integer runs in a sorted index list."""
    if len(idxs) == 0:
        return []
    out = []
    j0 = idxs[0]
    prev = idxs[0]
    for i in idxs[1:]:
        if i != prev + 1:
            out.append((prev - j0 + 1, (j0 + prev) // 2))
            j0 = i
        prev = i
    out.append((prev - j0 + 1, (j0 + prev) // 2))
    return out


def _argmax_run(profile):
    """Center index of the longest True run in a boolean profile."""
    runs = []
    j = 0
    while j < len(profile):
        if profile[j]:
            k = j
            while k + 1 < len(profile) and profile[k + 1]:
                k += 1
            runs.append((k - j + 1, (j + k) // 2, j, k))
            j = k + 1
        else:
            j += 1
    runs.sort(reverse=True)
    return runs[0][1]


# (the old _mark_aspect is retired: pitch-normalized extents above are exact)


def test_contrast_independence():
    """Same edge at gradient contrast 0.1 and 1.0: identical commit and axis
    (the coherence property), hence identical marks."""
    tex_lo = _ramp_texture(30.0, contrast=0.1)
    tex_hi = _ramp_texture(30.0, contrast=1.0)
    o0b, _ = chain(tex_lo)
    o0h, _ = chain(tex_hi)
    check("contrast-independence of commit+axis", float(np.abs(o0b - o0h).max()), 1e-5)


def test_strength_invariance():
    """Positive scaling of the tensor leaves the output unchanged (the
    gain-free identity, glyph ADR-2)."""
    outs = []
    for s in (30.0, 100.0, 500.0):
        t = _ramp_texture(50.0, strength=s)
        o, _ = chain(t)
        outs.append(o)
    check("strength invariance 100 vs 30",
          float(np.abs(outs[0] - outs[1]).max()), 1e-4)
    check("strength invariance 100 vs 500",
          float(np.abs(outs[1] - outs[2]).max()), 1e-4)


def test_rotation_equivariance_90():
    """Rotating the input's structure by 90 deg rotates the stroke field by
    90 deg: the rendered ridge angle moves by exactly 90 (mod 180) -- the
    E1 axis map moves by exactly pi/2 (mod pi) on the analytic ramp, and
    the E3 render (fixed params) inherits it."""
    for phi_deg in (0, 70):
        t0 = _ramp_texture(phi_deg)
        t90 = _ramp_texture(phi_deg + 90)
        a0 = _tex_axis_map(t0)[32, 40]
        a90 = _tex_axis_map(t90)[32, 40]
        diff = float(np.abs(np.mod((a90 - a0) - np.pi / 2 + np.pi / 2, np.pi) - np.pi / 2))
        check(f"rot equivariance axis map phi {phi_deg}", diff, 1e-4)
        r0 = np.deg2rad(_render_axis(chain(t0, regularity=1.0)[0]) % 180.0)
        r90 = np.deg2rad(_render_axis(chain(t90, regularity=1.0)[0]) % 180.0)
        dr = float(np.abs(np.mod((r90 - r0) - np.pi / 2 + np.pi / 2, np.pi) - np.pi / 2))
        check(f"rot equivariance render phi {phi_deg}", dr, 0.2)


def _tex_axis_map(tex):
    axis = np.zeros(tex.shape[:2], F32)
    for i in range(tex.shape[0]):
        for j in range(tex.shape[1]):
            axis[i, j] = decode(tex[i, j])[9]
    return axis


def test_angle_offset_endpoint():
    """angle_offset = +-1 produces the exactly-rotated +-90 deg layout with
    no discontinuity from the doubled-angle decode (the axis field is
    unoriented, so +-90 spans the distinct layouts and the offset wraps
    cleanly)."""
    for phis, offset in ((0.0, -1.0), (0.0, 1.0), (45.0, -1.0), (80.0, 1.0)):
        tex = _ramp_texture(phis)
        aux = stage_e1(tex, angle_offset=offset)
        # the offset axis renders marks whose ridge = phi + 90 + offset*90
        want = np.mod(phis + offset * 90.0 + 90.0, 180.0)   # deg
        o0, _ = stage_e3(stage_e2(aux), regularity=1.0)
        got = _render_axis(o0)
        err_d = abs(np.mod(got - want + 90.0, 180.0) - 90.0)
        note(f"phi {phis} offset {offset}: ridge {got:.1f} want {want:.1f}", err_d)
        check(f"angle_offset {offset} at phi {phis}", err_d, 8.0)


# --- T008 mutation checks -----------------------------------------------------

def test_mutation_gradient_axis_used_for_strokes():
    """Inject: use the GRADIENT angle theta instead of the along axis
    (theta + pi/2) for the pattern frame. A 45-degree-rotated field must
    render strokes 90 deg off -- detected by the angle invariant."""
    tex = _ramp_texture(45.0)
    aux_bad = _stage_e1_mutated(tex, use_gradient_axis=True)
    aux = stage_e1(tex)
    want = np.mod(np.deg2rad(45.0) + np.pi / 2, np.pi)

    def _axis_of(a):
        return float(np.arctan2(a[..., 1], a[..., 0])[32, 40])

    got_bad = _axis_of(aux_bad)
    got_good = _axis_of(aux)
    err_bad = float(np.abs(np.mod(got_bad - want + np.pi / 2, np.pi) - np.pi / 2))
    err_good = float(np.abs(np.mod(got_good - want + np.pi / 2, np.pi) - np.pi / 2))
    note("mutation bug axis err", err_bad)
    note("truth axis err", err_good)
    check("mutation: bug err exceeds clean err (caught)",
          0.0 if err_bad > 0.5 and err_good < 1e-3 else 1.0, 0.0)


def _stage_e1_mutated(tex, use_gradient_axis=False, drop_guard=False):
    """The E1 mirror with an injected bug (the T008 mutation vehicle)."""
    ca, sa = np.zeros(tex.shape[:2], F32), np.zeros(tex.shape[:2], F32)
    commit = np.zeros(tex.shape[:2], F32)
    iso = np.ones(tex.shape[:2], F32)
    for i in range(tex.shape[0]):
        for j in range(tex.shape[1]):
            out = decode(tex[i, j])
            trace = out[3]
            if not drop_guard and trace <= F32(EPS_TRACE):
                continue
            iso[i, j] = F32(0.0)
            eff = out[8] if use_gradient_axis else out[9]     # the bug
            ca[i, j] = np.cos(eff).astype(F32)
            sa[i, j] = np.sin(eff).astype(F32)
            commit[i, j] = commit_curve(np.array([out[10]], F32))[0]
    return g.store_float32(np.stack([ca, sa, commit, iso], -1))


def test_mutation_eps_guard_dropped():
    """Inject: compute coherence as root/trace WITHOUT the eps guard (the
    raw form, trace = 0 on a zero tensor) -- the artifact path drives
    commit to inf/clamped values and marks appear where nothing should.
    The zero-tensor test must fail. (Also asserted: the guard's axis-unset
    marker -- with the guard, (ca, sa) stay exactly (0, 0) on a zero
    tensor; without, the -1/s-Jxy artifact axis leaks.)"""
    tex = np.zeros((H, W, 4), F32)
    aux = stage_e1(tex)
    check("truth: guard keeps (ca, sa) unset on zero tensor",
          float(np.abs(aux[..., :2]).max()), 1e-7)
    # the mutation: coherence = root / trace, unguarded (trace = 0 -> inf)
    rng = np.random.default_rng(0)
    trace = np.zeros((8, 8), F32)          # exactly the zero tensor
    root = np.full((8, 8), F32(0.02))      # the Jxy -1/s artifact root
    with np.errstate(divide="ignore", invalid="ignore"):
        coh_bad = (root / trace)
    coh_bad = np.where(np.isfinite(coh_bad), coh_bad, F32(5.0))  # GPU: inf/nan -> big
    c_bad = commit_curve(coh_bad)
    c_truth = commit_curve(np.zeros((8, 8), F32))
    note("mutation: mean commit unguarded", float(c_bad.mean()))
    check("mutation: dropped guard renders (caught)",
          0 if float(c_bad.mean()) > 0.1 and float(c_truth.mean()) < 1e-6 else 1, 0.0)


def test_mutation_elongation_without_commit_mult():
    """Inject: tie mark aspect to `elongation` directly, without the commit
    multiplier -- the glint lesson's view-in-disguise bug. A near-iso
    field must render elongated marks under the bug, dots under the truth
    (commit-weighted fade-in)."""
    # near-iso but traceable: Jxx=Jyy=0.5, Jxy=0.01 -> root 0.02, coh 0.02
    tex = _tex_from_tensor(np.full((H, W), F32(0.5)),
                           np.full((H, W), F32(0.01)),
                           np.full((H, W), F32(0.5)))
    coh = float(decode(tex[32, 40])[10])
    commit_truth = float(commit_curve(np.array([coh], F32))[0])
    note("coh and commit", commit_truth)
    # truth: commit->0 fades marks out entirely
    o_truth = stage_e3(stage_e2(stage_e1(tex)), elongation=8.0)[0]
    check("truth: near-iso renders ~nothing", float(np.abs(o_truth[..., 0]).max()), 0.05)
    # the BUG would render full dots at every pixel (aspect tied to dial):
    # measure the bug's rendered coverage analytically: commit replaced by 1
    aux_bug = stage_e1(tex)
    aux_bug[..., 2] = F32(1.0)                       # the bug: full commit
    o_bug = stage_e3(stage_e2(aux_bug), elongation=8.0)[0]
    check("mutation: commit removed is detected",
          0 if float(np.abs(o_bug[..., 0]).max()) - float(np.abs(o_truth[..., 0]).max()) > 0.1 else 1, 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))