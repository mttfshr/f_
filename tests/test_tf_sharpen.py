"""
test_tf_sharpen.py -- tier-1 NumPy mirror of f_tf_sharpen
(.specify/f_tf_sharpen/{spec,plan,tasks}.md, Phase 0 T002-T009).

Operator: decode the incoming tensor (f_tensor_type.md outlet 0 encoding),
scale the eigengap by gamma while holding trace fixed, re-encode:

    J' = gamma * J + (1 - gamma) * (trace/2) * I      (plan ADR-2, g = max(gamma, 0))

i.e. lambda1' = trace/2 + g*(lambda1 - trace/2), lambda2' = trace/2 + g*(lambda2 - trace/2),
Jxy' = g*Jxy.  NOTE: the spec's prose wrote lambda2' with a MINUS (trace/2 - gap*(lambda2 -
trace/2)); that form gives lambda1' == lambda2' for every gamma != 1 and breaks trace
invariance -- the correct trace-preserving relax form is the PLUS sign (same for both
eigenvalues), mirror T003/T005 confirm. Spec corrected in REGISTRATION_NOTES.

Jxy' = g*Jxy. The negative-gamma relax branch is the identity-mix form; a literal negative
gap would swap the eigenvalues and rotate the axis 90 degrees (spec OQ2) -- T006 guards it.

Units (plan ADR-4): the codebox operates directly on the STRENGTH-SCALED outlet-0
components (xx = R, xy = (G-0.5)*2, yy = B). The glyph-plan ADR-2 gain-free identity
(strength is a common factor on R, G-0.5, B) plus the operator's positive homogeneity
mean the producer's `strength` cancels exactly in the gap math; only the floor gate
(eps_trace, an absolute encoded-units threshold) depends on the producing tensormap's
calibration. T007 proves the scale commutation; the floor's non-commutation is
asserted too and the caveat goes to the reference doc.

Ground truth is independent of the mirror: np.linalg.eigh on the decoded output
matrix, exact coherence/axis algebra. Mutation checks (T009): dropping max(gamma, 0)
and swapping the gap sign are each caught.

Run:  tests/run.sh tests/test_tf_sharpen.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402

F32 = np.float32
EPS_TRACE = F32(1e-6)   # plan ADR-3: tensormap T019 convention, encoded units
H = W = 32

nx, ny, _, _ = g.grid(H, W)


# --- mirror -------------------------------------------------------------

def sharpen(t, sharpen=1.0, eps=EPS_TRACE, clip=True, mutate=None, bypass=False):
    """One pass of the planned codebox. t: outlet-0-format RGBA texture.

    mutate: None | "drop_max" (T009a: gamma used without max(gamma, 0))
            | "swap"    (T009b: gap sign error == swapped diagonals).
    bypass: module bypass -> exact passthrough (spec acceptance row).
    Floor gate: trace < eps -> exact passthrough of the sampled input.
    """
    s = g.nearest(t, nx, ny)
    xx = s[..., 0]
    xy = (s[..., 1] - F32(0.5)) * F32(2)
    yy = s[..., 2]
    tr = xx + yy
    gam = F32(sharpen) if mutate == "drop_max" else np.maximum(F32(sharpen), F32(0))
    iso_part = (F32(1) - gam) * F32(0.5) * tr
    if mutate == "swap":
        ox = gam * yy + iso_part
        oz = gam * xx + iso_part
    else:
        ox = gam * xx + iso_part
        oz = gam * yy + iso_part
    oy = gam * xy * F32(0.5) + F32(0.5)
    out = g.texture(H, W)
    if clip:
        out[..., 0] = np.clip(ox, 0, 1)
        out[..., 1] = np.clip(oy, 0, 1)
        out[..., 2] = np.clip(oz, 0, 1)
    else:
        out[..., 0], out[..., 1], out[..., 2] = ox, oy, oz
    out[..., 3] = F32(1)
    iso = tr < eps
    # floor/vs_black passthrough: rgb exactly the input's, but the OUTLET
    # contract is A = 1 always (f_tensor_type.md outlet 0) — the codebox's
    # vec(..., 1.0) never transmits the incoming alpha; the mirror matches
    # (2026-10-17: the first draft copied s[iso] whole, keeping the
    # vs_black block's alpha 0 — a one-per-block false diff on the bench).
    out[iso, :3] = s[iso, :3]
    out[iso, 3] = F32(1)
    if bypass:
        out[...] = s                  # exact passthrough (module bypass)
    return g.store_float32(out)


# --- helpers ------------------------------------------------------------

def tensor_tex(lam1, lam2, theta, h=H, w=W):
    """Encoded outlet-0 texture of one symmetric tensor repeated everywhere."""
    c, s_ = F32(np.cos(theta)), F32(np.sin(theta))
    xx = lam1 * c * c + lam2 * s_ * s_
    xy = (lam1 - lam2) * s_ * c
    yy = lam1 * s_ * s_ + lam2 * c * c
    tex = g.texture(h, w)
    tex[..., 0] = xx
    tex[..., 1] = xy * F32(0.5) + F32(0.5)
    tex[..., 2] = yy
    tex[..., 3] = F32(1)
    return tex


def scale_tex(t, k):
    """Encode the tensor scaled by k (common factor through all three components)."""
    out = g.texture(*t.shape[:2])
    xy = (t[..., 1] - F32(0.5)) * F32(2)
    out[..., 0] = t[..., 0] * F32(k)
    out[..., 1] = xy * F32(k) * F32(0.5) + F32(0.5)
    out[..., 2] = t[..., 2] * F32(k)
    out[..., 3] = F32(1)
    return out


def components(t):
    """Decoded components in encoded (strength-scaled) units."""
    return (t[..., 0], (t[..., 1] - F32(0.5)) * F32(2), t[..., 2])


def eigen_lo_hi(xx, xy, yy):
    """np.linalg.eigh ground truth on the decoded matrix; returns (lam_lo, lam_hi)."""
    M = np.stack([np.stack([xx, xy], -1), np.stack([xy, yy], -1)], -2)
    vals = np.linalg.eigh(M)[0]            # ascending
    return vals[..., 0], vals[..., 1]


def axis_cs(xx, xy, yy):
    """(cos 2theta, sin 2theta) from components -- exact, no angle ambiguity."""
    diff = xx - yy
    root = np.sqrt(diff * diff + F32(4) * xy * xy)
    safe = np.maximum(root, F32(1e-12))
    return diff / safe, F32(2) * xy / safe


def random_valid_tensors(n, seed):
    """Random SPD tensors with valid encodings: 0 <= lam2 <= lam1 <= 1, theta in [0, pi)."""
    rng = np.random.default_rng(seed)
    out = []
    for _ in range(n):
        lam1 = rng.uniform(0.05, 1.0)
        lam2 = rng.uniform(0.0, lam1)
        theta = rng.uniform(0.0, np.pi)
        out.append((lam1, lam2, theta))
    return out


def coh(xx, xy, yy):
    diff = xx - yy
    root = np.sqrt(diff * diff + F32(4) * xy * xy)
    tr = xx + yy
    return root / np.maximum(tr, F32(1e-12))


# --- T002: decode/eigen ground truth ------------------------------------

def test_eigen_ground_truth():
    worst_val = 0.0
    worst_ang = 0.0
    cases = random_valid_tensors(20, seed=1)
    cases += [(0.5, 0.5, 0.7),              # near-isotropic
              (0.9, 0.1, 0.0), (0.9, 0.1, np.pi / 2),   # diagonal-only
              (0.99, 0.0, 1.3)]             # near-line
    for lam1, lam2, th in cases:
        tex = tensor_tex(lam1, lam2, th)
        for gam in (0.7, 1.9):
            out = sharpen(tex, sharpen=gam, clip=False)   # pre-encode-clamp math
            xx, xy, yy = components(out)
            lo, hi = eigen_lo_hi(xx, xy, yy)
            tr = lam1 + lam2
            exp_hi = tr / 2 + gam * (lam1 - tr / 2)
            exp_lo = tr / 2 + gam * (lam2 - tr / 2)
            worst_val = max(worst_val,
                            float(np.abs(hi - exp_hi).max()),
                            float(np.abs(lo - exp_lo).max()))
            c_in, s_in = axis_cs(*components(tex))
            c_out, s_out = axis_cs(xx, xy, yy)
            worst_ang = max(worst_ang, float(np.abs(c_out - c_in).max()),
                            float(np.abs(s_out - s_in).max()))
    check("eigh eigenvalue agreement (worst)", worst_val, 2e-5)
    check("(cos2t, sin2t) unchanged by gap op (worst)", worst_ang, 2e-5)


# --- T003: trace invariance ----------------------------------------------

def test_trace_invariance():
    worst = 0.0
    for lam1, lam2, th in random_valid_tensors(8, seed=2):
        tex = tensor_tex(lam1, lam2, th)
        tr0 = float((components(tex)[0] + components(tex)[2]).max())
        for gam in (F32(0), F32(0.25), F32(0.5), F32(1), F32(2), F32(4)):
            xx, xy, yy = components(sharpen(tex, sharpen=gam, clip=False))
            worst = max(worst, float(np.abs(xx + yy - tr0).max()))
    check("trace(gamma) == trace, gamma 0..4", worst, 1e-5)


# --- T004: axis invariance ------------------------------------------------

def test_axis_invariance():
    worst = 0.0
    for lam1, lam2, th in random_valid_tensors(8, seed=3):
        tex = tensor_tex(lam1, lam2, th)
        c_in, s_in = axis_cs(*components(tex))
        for gam in (F32(0.25), F32(0.5), F32(1), F32(2), F32(4)):
            c_out, s_out = axis_cs(*components(sharpen(tex, sharpen=gam, clip=False)))
            worst = max(worst, float(np.abs(c_out - c_in).max()),
                        float(np.abs(s_out - s_in).max()))
    check("axis (cos2t, sin2t) unchanged pre-clamp, gamma > 0", worst, 1e-4)


def test_gamma_zero_is_isotropic_with_trace_kept():
    tex = tensor_tex(0.9, 0.1, 0.8)
    xx, xy, yy = components(sharpen(tex, sharpen=0, clip=False))
    tr = float((components(tex)[0] + components(tex)[2]).max())
    check("gamma 0: both eigenvalues == trace/2",
          float(np.abs(xx + yy - tr).max()) + float(np.abs(xx - tr / 2).max()), 2e-6)
    check("gamma 0: cross term exactly zero (G out == 0.5)",
          float(np.abs(sharpen(tex, sharpen=0)[..., 1] - F32(0.5)).max()), 0.0)


# --- T005: coherence mapping (linear in the gap) --------------------------

def test_coherence_mapping():
    tex = tensor_tex(0.45, 0.15, 0.6)        # coherence 0.5
    for gam, expect in ((F32(2), F32(1.0)), (F32(0), F32(0.0)), (F32(0.5), F32(0.25))):
        xx, xy, yy = components(sharpen(tex, sharpen=gam))
        got = float(coh(xx, xy, yy).max())
        check(f"coherence at gamma {gam} == {expect}", abs(got - float(expect)), 1e-5)


# --- T006: no eigenvalue swap on relax (ADR-2 hazard) ----------------------

def rayleigh_along_input_axes(xx, xy, yy, c2_in, s2_in):
    """Labelled eigenvalues: output energy along the input's major axis (a) and
    its perpendicular (b). eigh sorts, so it cannot detect a swap; this can.
    a = xx*(1+c2)/2 + s2*xy + yy*(1-c2)/2;  b swaps c2 -> -c2, s2 -> -s2."""
    a = xx * (F32(1) + c2_in) / F32(2) + s2_in * xy + yy * (F32(1) - c2_in) / F32(2)
    b = xx * (F32(1) - c2_in) / F32(2) - s2_in * xy + yy * (F32(1) + c2_in) / F32(2)
    return a, b


def test_no_swap_for_any_gamma():
    worst = 0.0
    for lam1, lam2, th in random_valid_tensors(12, seed=4) + [(0.5, 0.5, 1.1)]:
        tex = tensor_tex(lam1, lam2, th)
        c2_in, s2_in = axis_cs(*components(tex))
        for gam in (0.0, 0.25, 0.5, 0.75, 1.0, 2.0, 4.0):
            xx, xy, yy = components(sharpen(tex, sharpen=gam, clip=False))
            a, b = rayleigh_along_input_axes(xx, xy, yy, c2_in, s2_in)
            worst = min(worst, float((a - b).min()))  # must stay >= 0 (no swap)
    check("input-major-axis eigenvalue never drops below its perpendicular", -worst, 0.0)


# --- T007: scale commutation (ADR-4) ---------------------------------------

def test_scale_commutation():
    worst = 0.0
    tex = tensor_tex(0.6, 0.2, 0.9)
    for k in (1.0, 10.0, 1000.0):
        out_scaled = sharpen(scale_tex(tex, k), sharpen=1.7, clip=False)
        ref = scale_tex(sharpen(tex, sharpen=1.7, clip=False), k)
        xx_a, xy_a, yy_a = components(out_scaled)
        xx_b, xy_b, yy_b = components(ref)
        worst = max(worst,
                    float((np.abs(xx_a - xx_b) / np.maximum(np.abs(xx_b), 1e-9)).max()),
                    float((np.abs(yy_a - yy_b) / np.maximum(np.abs(yy_b), 1e-9)).max()),
                    float((np.abs(xy_a - xy_b) / np.maximum(np.abs(xy_b), 1e-9)).max()))
    check("sharpen(k*tensor) == k*sharpen(tensor), k in {1,10,1000}", worst, 1e-3)


def test_floor_gate_breaks_commutation_by_design():
    # ADR-4 caveat, measured: the eps_trace floor is an absolute encoded-units
    # threshold, so a below-floor tensor scaled up escapes it and gets scaled.
    # Analytic on an axis-aligned sub-floor tensor (theta = 0): out_sub is the
    # floor passthrough (trace 4e-9 -> R 4e-9), scaled ref R = 4e-6; out_up
    # escapes the floor and its R is gamma-scaled -2e-9*k = -2e-6. Delta =
    # k*|gamma-1|*trace/2 = 1000*1*2e-9 = 2.0e-6 exactly.
    sub = tensor_tex(4e-9, 0.0, 0.0)           # trace 4e-9 < eps
    gamma = 2.0
    k = 1000.0
    out_sub = sharpen(sub, sharpen=gamma, clip=False)
    out_up = sharpen(scale_tex(sub, k), sharpen=gamma, clip=False)
    d = float(np.abs(out_up[..., 0] - scale_tex(out_sub, k)[..., 0]).max())
    note("commutation delta through the floor gate (expect 2.0e-6)", d)
    if not 1.9e-6 <= d <= 2.1e-6:
        raise AssertionError(f"floor gate behavior off: {d:.3e}, expected ~2.0e-6")


# --- floor / bypass / unconnected / neutral --------------------------------

def test_floor_gate_exact_passthrough():
    sub = tensor_tex(8e-8, 0.0, 0.4)          # trace below eps
    t = g.texture(H, W)
    t[...] = sub
    t[..., 0] = sub[..., 0] * F32(2)          # nonzero components, still sub-floor
    for gam in (0.0, 1.0, 4.0):
        out = sharpen(t, sharpen=gam)
        if gam == 0.0:
            continue
        check(f"floor passthrough bitwise, gamma {gam}",
              float(np.abs(out - t).max()), 0.0)
    above = tensor_tex(0.5, 0.1, 0.5)
    out = sharpen(above, sharpen=4.0)
    if np.abs(out - above).max() == 0.0:
        raise AssertionError("floor gate swallowed an above-eps tensor")


def test_bypass_exact_passthrough():
    tex = tensor_tex(0.7, 0.3, 1.2)
    out = sharpen(tex, sharpen=3.0, bypass=True)
    check("bypass passthrough bitwise", float(np.abs(out - tex).max()), 0.0)


def test_unconnected_inlet_is_a_fixed_point():
    z = g.texture(H, W)                        # vs_black: (0, 0, 0, 0)
    rgb_want = z[..., :3]
    for gam in (0.0, 1.0, 4.0):
        out = sharpen(z, sharpen=gam)
        # the outlet contract is A = 1 always (f_tensor_type.md outlet 0);
        # rgb = the fixed point (2026-10-17 mirror edit: passthrough keeps
        # rgb but writes the contractual alpha).
        check(f"vs_black rgb fixed point at gamma {gam}",
              float(np.abs(out[..., :3] - rgb_want).max()), 0.0)
        check(f"vs_black alpha = contract 1 at gamma {gam}",
              float(np.abs(out[..., 3] - 1.0).max()), 0.0)


def test_neutral_gamma_one_bit_exact():
    tex = tensor_tex(0.8, 0.2, 2.0)
    out = sharpen(tex, sharpen=1.0)
    check("gamma 1 is bit-exact passthrough", float(np.abs(out - tex).max()), 0.0)


# --- encoding clamp (outlet-0 contract) -------------------------------------

def test_encode_clamp_beyond_linear_range():
    # gamma > 1/coherence drives lambda2' negative; the outlet-0 contract clamps
    # R/B >= 0 (tensormap encode). gamma=4 on a coherence-1/3 tensor: lambda1'=+0.5
    # (clamped to 1), lambda2'<0 -> B=0, trace lost. Recorded behavior + a note
    # that coherence cannot be trusted to land in [0,1] downstream at extreme gamma.
    tex = tensor_tex(0.9, 0.3, 0.0)            # diagonal, coherence 1/2
    out = sharpen(tex, sharpen=4.0)
    check("clamp: R at 1.0 (lambda1' 0.9 clamped up)", float(np.abs(out[..., 0] - 1).max()), 0.0)
    check("clamp: B at 0.0 (lambda2' negative)", float(np.abs(out[..., 2] - 0).max()), 0.0)


# --- T009: mutation checks ---------------------------------------------------

def test_mutation_dropped_max_is_caught():
    # T009a: without max(gamma, 0), gamma = -0.5 keeps a negative gap: the
    # eigenvalues swap (the input's minor axis becomes the output's major) and
    # T006's labelled no-swap invariant fails.
    tex = tensor_tex(0.8, 0.2, 0.7)
    c2_in, s2_in = axis_cs(*components(tex))
    xx, xy, yy = components(sharpen(tex, sharpen=-0.5, mutate="drop_max", clip=False))
    a, b = rayleigh_along_input_axes(xx, xy, yy, c2_in, s2_in)
    bad = float((b - a).max())          # minor-axis energy exceeds major: swapped
    note("drop_max mutation: b - a along the input major axis (must be > 0)", bad)
    if not bad > 0.1:
        raise AssertionError(f"drop_max mutation NOT caught: {bad:.3e}")
    good = sharpen(tex, sharpen=-0.5, clip=False)
    xx2, xy2, yy2 = components(good)
    lo2, hi2 = eigen_lo_hi(xx2, xy2, yy2)
    check("real mirror clamps negative gamma to the isotropic endpoint",
          float(np.abs(hi2 - F32(0.5)).max()) + float(np.abs(lo2 - F32(0.5)).max()), 2e-6)


def test_mutation_swapped_gap_is_caught():
    # T009b: a gap sign error (swapped diagonals) rotates the axis by 90 deg
    # -- (cos2t, sin2t) negates -- and T004's axis invariant fails (gamma > 0).
    tex = tensor_tex(0.8, 0.2, 0.7)
    c_in, s_in = axis_cs(*components(tex))
    xx, xy, yy = components(sharpen(tex, sharpen=2.0, mutate="swap"))
    c_out, s_out = axis_cs(xx, xy, yy)
    bad = float(np.abs(c_out + c_in).max())     # negated == 90-degree rotation
    note("swap mutation: |c2_out - c2_in| (must be big)", float(np.abs(c_out - c_in).max()))
    if not bad < 1e-4:
        raise AssertionError("swap mutation axis did not rotate: not the predicted bug")
    # and the correct-op axis really is unchanged (the check the mutation defeats)
    c_ok, s_ok = axis_cs(*components(sharpen(tex, sharpen=2.0)))
    check("correct op keeps the axis (control)", float(np.abs(c_ok - c_in).max())
          + float(np.abs(s_ok - s_in).max()), 1e-4)


if __name__ == "__main__":
    sys.exit(run(globals()))