"""
test_tf_aniso_blur.py -- tier-1 NumPy mirror of the planned f_tf_aniso_blur
consumer (.specify/f_tf_aniso_blur/{spec,plan,tasks}.md, Phase 0 T004-T010).

One codebox pass is mirrored end to end (plan ADR-1, single stage): decode the
raw tensor (f_tf_tensormap outlet 0, f_tensor_type.md), closed-form eigen, the
ADR-3 gate model, and the ADR-2 kernel -- family (a), fixed-tap straight-axis
line integration with per-tap transverse offset (owner resolution 2026-10-17:
provisional; the ellipse-grid alternative stays documented in plan ADR-2 as
the pending-cost alternative, gate PROVISIONAL-OPEN -- T010/A005 records the
mirror-side artifact data for that gate).

Kernel (family a, recorded for the ADR-2 addendum), TAPS_MAX = 49:
  center tap, weight 1, at t = 0;
  8 stations per side at u = +-(k - 0.5) px, k = 1..8 (half-integer 1 px
  spacing, "tap spacing = 1 pixel" per the spec Parameters note), station
  along-mass g(u) = exp(-2u^2/L^2) (L is the Gaussian semi-length:
  g(L) = e^-2; mid-point quadrature of the continuous Gaussian -- verified
  1e-4 relative against its own integral, so the kernel is the converged
  discretization, not a banding artifact of the quadrature);
  each station carries THREE transverse taps at t = 0 and t = +-D/2 px with
  the discrete-Gaussian rule (1/4, 1/2, 1/4), i.e. the per-side transverse
  mass w0 + 2 w1 = 1 keeps the along marginal exactly g(u) while giving each
  station its 1-px-wide transverse spread;
  total 1 + 16*3 = 49 samples <= TAPS_MAX, weights positive, sum-normalized.
  Cost scales with TAPS_MAX, not the dial (tensormap ADR-3 fact).

Gate model (ADR-3):
  W    = min(1, lambda1 * strength_scale)          energy gate on LENGTH
  L    = length * W
  D    = L * max(floor, 1 - coherence * width_gate) (transverse from
       coherence -- spec OQ7's default; lam2/lam1 is the mutation)
  Guard (NOT provisional -- spec "Unconnected-tensor guard"): non-SPD
  (lambda2 < -eps) or trace < eps (or root < eps, axis undefined) routes the
  pixel to the isotropic fallback with the energy gate BYPASSED:
  L_iso = length, D_iso = length. The all-zeros unconnected wire decodes to
  Jxy = -1/strength -> trace 0 but root = 2/strength, lambda1 = 1/strength,
  lambda2 = -1/strength: it LOOKS like structure to the energy gate (W ~ 0.5
  at the provisional strength_scale 0.5 / delivered strength 100), so the
  SPD test is the primary defense (f_tensor_type.md consumer rule 5).
  Circularity snap: when D >= L*(1-1e-6) the kernel placement drops the axis
  (fixed frame, per the isotropic reference), so every isotropic-regime
  output equals the isotropic reference EXACTLY -- the fallback is isotropic
  blur, not an anisotropic kernel that happens to be nearly circular.

Decode idiom: .specify/f_tf_glyph/plan.md ADR-2 (the family's canonical text),
verified here against np.linalg.eigvalsh and the encode/decode round trip. No
atan2 needed by this consumer: the axis lines are (diff, 2*Jxy)/root and its
perp -- the doubled-angle identity the idiom records as tan(2*theta).

Ground truth is independent of the mirror: np.linalg.eigvalsh, an independent
isotropic-reference implementation (transverse loop OUTSIDE the station loop,
u precomputed, no shared helpers), a per-px-step-mass densification of the
same station lattice (float64 accumulate, density 8 -- the convergence
check), and a dense-AREA elliptical Gaussian whose deviation from the 49-tap
kernel is the ADR-2 banding evidence, printed as data.

Run:  tests/run.sh tests/modules/tf_aniso_blur/test_tf_aniso_blur.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
from tf_aniso_blur_mirror import (
    EPS_SPD,
    EPS_TRACE,
    F32,
    FLOOR,
    H,
    LENGTH,
    S_DEC,
    S_SCALE,
    S_TMAP,
    W,
    W_GATE,
    _nxny,
    aniso_pass,
    decode_raw,
    iso_reference,
)


# --- synthetic inputs ---------------------------------------------------

def noise_tex(seed=0, lo=0.1, hi=0.9):
    rng = np.random.default_rng(seed)
    tex = g.texture(H, W)
    tex[..., 0] = tex[..., 1] = tex[..., 2] = rng.uniform(lo, hi, (H, W))
    tex[..., 3] = F32(1.0)
    return g.store_float32(tex)


def step_edge_tex():
    """Vertical step edge + weak along-edge variation (coherent-edge test)."""
    nx, ny, _, _ = g.grid(H, W)
    tex = g.texture(H, W)
    v = F32(0.15) + F32(0.7) * (nx > F32(0.5)) + F32(0.05) * np.sin(ny * F32(2 * np.pi) * F32(4))
    tex[..., 0] = tex[..., 1] = tex[..., 2] = v
    tex[..., 3] = F32(1.0)
    return g.store_float32(tex)


def tensor_texture(Jxx, Jxy, Jyy, s=S_TMAP):
    """Encode an outlet-0-format tensor texture (f_tensor_type.md)."""
    t = g.texture(H, W)
    t[..., 0] = F32(Jxx) * s
    t[..., 1] = F32(Jxy) * s * F32(0.5) + F32(0.5)
    t[..., 2] = F32(Jyy) * s
    t[..., 3] = F32(1.0)
    return g.store_float32(t)


def tensor_at_angle(lam1, lam2, phi_deg, **kw):
    """Dominant eigenvector (the GRADIENT/ACROSS-EDGE axis) at angle phi."""
    phi = np.deg2rad(phi_deg)
    c, s = np.cos(phi), np.sin(phi)
    Jxx = lam1 * c * c + lam2 * s * s
    Jyy = lam1 * s * s + lam2 * c * c
    Jxy = (lam1 - lam2) * c * s
    return tensor_texture(Jxx, Jxy, Jyy, **kw)


VS_BLACK = g.texture(H, W)                                  # unconnected wire
NEUTRAL = tensor_texture(0.0, 0.0, 0.0)                     # tensormap bypass out
PACKED_NEUTRAL = np.zeros((H, W, 4), F32)                   # mis-wired outlet 1
PACKED_NEUTRAL[..., 0] = F32(0.5)                           # (0.5, 0.5, 0, 0)
PACKED_NEUTRAL[..., 1] = F32(0.5)                           # -> zero tensor raw-decoded
NON_SPD = tensor_texture(1.0, 1.0, 0.1)                     # lambda2 < 0
DEGENERATE = tensor_texture(2.0, 0.0, 2.0)                  # lambda1 == lambda2


def bypass_pass(source):
    """bypass_gate=1: exact passthrough of inlet 1 (spec acceptance)."""
    return g.store_float32(g.sample(source, *_nxny(source)))


def brute_reference(source, L, D, phi_grad_deg, width=F32(W), height=F32(H),
                    density=8):
    """INDEPENDENT densification of the delivered lattice: per-px-step mass
    quadrature (step 1/density px), float64 accumulate, 8x densification.
    Stations at u = +-(k-0.5)/density for k = 1..8*density (the u extent is
    the quadrature's, ~8 px at any density); transverse 3-point rule at
    sigma_d = D/2 with the same (1/4, 1/2, 1/4) rule."""
    h, w = source.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    phi = np.deg2rad(phi_grad_deg)
    ax_x, ax_y = np.cos(phi), np.sin(phi)          # gradient (across) axis
    vx, vy = -np.sin(phi), np.cos(phi)             # along axis
    L, D = float(L), float(D)
    L2 = max(L * L, 1e-12)
    sig_d = max(D / 2.0, 1e-6)
    acc = np.zeros((h, w, 4), np.float64)
    wsum = np.zeros((h, w), np.float64)
    acc += 1.0 * g.sample(source, np.clip(nx, F32(0.5) / width,
                                          F32(1.0) - F32(0.5) / width),
                          np.clip(ny, F32(0.5) / height,
                                  F32(1.0) - F32(0.5) / height))
    wsum += 1.0
    n_station = int(np.ceil(8 * density))
    for k in range(1, n_station + 1):
        umag = (k - 0.5) / density
        gu = np.exp(-2.0 * umag * umag / L2) / density     # per-px-step mass
        for sgn in (1.0, -1.0):
            u = sgn * umag
            for tsign, frac in ((0.0, 0.5), (1.0, 0.25), (-1.0, 0.25)):
                t = tsign * sig_d
                wgt = gu * frac
                ox = u * vx + t * ax_x
                oy = u * vy + t * ax_y
                cu = np.clip(nx + F32(ox / float(width)), F32(0.5) / width,
                             F32(1.0) - F32(0.5) / width).astype(F32)
                cv = np.clip(ny + F32(oy / float(height)), F32(0.5) / height,
                             F32(1.0) - F32(0.5) / height).astype(F32)
                acc += wgt * g.sample(source, cu, cv)
                wsum += wgt
    out = acc / np.maximum(wsum, 1e-9)[..., None]
    return out.astype(F32)


def dense_area_reference(source, L, D, phi_grad_deg, width=F32(W), height=F32(H),
                         step=0.25):
    """The continuous weight model family (a) approximates: a dense AREA
    integral of the separable elliptical Gaussian. The deviation of the 49-tap
    kernel from this is the ADR-2 banding evidence (data): the delivered
    kernel is a 1-px-station quadrature of THIS weight field."""
    h, w = source.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    phi = np.deg2rad(phi_grad_deg)
    ax_x, ax_y = np.cos(phi), np.sin(phi)
    vx, vy = -np.sin(phi), np.cos(phi)
    L, D = float(L), float(D)
    L2 = max(L * L, 1e-12)
    D2 = max(D * D, 1e-12)
    acc = np.zeros((h, w, 4), np.float64)
    wsum = np.zeros((h, w), np.float64)
    us = np.arange(-2.5 * L, 2.5 * L + 1e-9, step)
    for u in us:
        g_u = np.exp(-2.0 * u * u / L2)
        if g_u < 1e-4:
            continue
        for t in np.arange(-2.5 * D, 2.5 * D + 1e-9, step):
            g_t = np.exp(-2.0 * t * t / D2)
            if g_t < 1e-4:
                continue
            wgt = g_u * g_t
            ox = u * vx + t * ax_x
            oy = u * vy + t * ax_y
            cu = np.clip(nx + F32(ox / float(width)), F32(0.5) / width,
                         F32(1.0) - F32(0.5) / width).astype(F32)
            cv = np.clip(ny + F32(oy / float(height)), F32(0.5) / height,
                         F32(1.0) - F32(0.5) / height).astype(F32)
            acc += wgt * g.sample(source, cu, cv)
            wsum += wgt
    out = acc / np.maximum(wsum, 1e-9)[..., None]
    return out.astype(F32)


def ellipse_grid_pass(src, L, D, phi, U=2, T=2):
    """ADR-2 family (b) mirror: bounded u-t grid (U,T around an axis at angle
    phi), analytic per-tap weight exp(-(u^2/2sig_u^2 + t^2/2sig_t^2)),
    sum-normalized -- the alternative kernel family the gate compares."""
    nx, ny, _, _ = g.grid(*src.shape[:2])
    phi_r = np.deg2rad(phi)
    ax_x, ax_y = np.cos(phi_r), np.sin(phi_r)
    vx, vy = -np.sin(phi_r), np.cos(phi_r)
    Lf, Df = float(L), float(D)
    sig_u = max(0.5 * Lf, 0.25)
    sig_t = max(0.5 * Df, 0.25)
    acc = np.zeros(src.shape[:2] + (4,), F32)
    wsum = np.zeros(src.shape[:2], F32)
    for iu in range(-U, U + 1):
        u = F32(iu) * F32(Lf) / F32(U)
        for it in range(-T, T + 1):
            t = F32(it) * F32(Df) / F32(T)
            wgt = (np.exp(-(u * u) / (F32(2.0) * sig_u * sig_u))
                   * np.exp(-(t * t) / (F32(2.0) * sig_t * sig_t))).astype(F32)
            ox = (u * vx + t * ax_x) / F32(W)
            oy = (u * vy + t * ax_y) / F32(H)
            cu = np.clip(nx + ox, F32(0.5) / F32(W),
                         F32(1.0) - F32(0.5) / F32(W)).astype(F32)
            cv = np.clip(ny + oy, F32(0.5) / F32(H),
                         F32(1.0) - F32(0.5) / F32(H)).astype(F32)
            smp = g.sample(src, cu, cv)
            acc += (wgt[..., None] * smp).astype(F32)
            wsum += wgt
    return g.store_float32(acc / np.maximum(wsum, F32(1e-6))[..., None])


def _rgb(o):
    return o[..., :3]


def _lam_of(tensor, s_dec=S_DEC):
    _, _, _, _, _, _, lam1, _, _ = decode_raw(tensor, s_dec)
    return lam1


def _expect_LD(tens, length=LENGTH, w_gate=W_GATE, floor=FLOOR, s_dec=S_DEC):
    """Delivered L, D at (0,0)'s tensor: energy gate + coherence transverse."""
    lam1 = float(_lam_of(tens, s_dec)[0, 0])
    w_en = min(1.0, lam1 * float(s_scale_of(s_dec)))
    L = float(length) * w_en
    coh = float(decode_raw(tens, s_dec)[8][0, 0])
    D = L * max(float(floor), 1.0 - float(w_gate) * coh)
    return L, D, w_en, coh


def s_scale_of(s_dec):
    # the W gate reads lam1 in DECODED units: lam1 = lam1_true * s_tm / s_dec
    return float(S_SCALE) * float(S_TMAP) / float(s_dec)


INTERIOR = (slice(6, -6), slice(6, -6))


# --- T004 / T006 / TG007-analogue: decode vs ground truth ----------------

def test_decode_matches_eigvalsh():
    rng = np.random.default_rng(11)
    n = 3000
    v = rng.normal(size=(n, 2, 1)).astype(F32)
    w_ = rng.normal(size=(n, 2, 1)).astype(F32)
    Jxx = (v[:, 0] ** 2).astype(F32)
    Jyy = (w_[:, 0] ** 2).astype(F32)
    Jxy = (v[:, 0] * w_[:, 0]).astype(F32)
    M = np.stack([np.stack([Jxx[:, 0], Jxy[:, 0]], -1),
                  np.stack([Jxy[:, 0], Jyy[:, 0]], -1)], -2)
    w_eig = np.linalg.eigvalsh(M.astype(np.float64))
    trace = Jxx[:, 0] + Jyy[:, 0]
    diff = Jxx[:, 0] - Jyy[:, 0]
    root = np.sqrt(diff * diff + F32(4.0) * Jxy[:, 0] * Jxy[:, 0])
    check("closed-form lambda1 vs eigh", float(np.abs(0.5 * (trace + root) - w_eig[:, 1]).max()), 1e-4)
    check("closed-form lambda2 vs eigh", float(np.abs(0.5 * (trace - root) - w_eig[:, 0]).max()), 1e-4)
    coh_ref = (w_eig[:, 1] - w_eig[:, 0]) / np.maximum(w_eig[:, 1] + w_eig[:, 0], 1e-12)
    coh = root / np.maximum(trace, EPS_TRACE)
    ok = trace > 1e-3
    check("coherence vs eigh", float(np.abs(coh[ok] - coh_ref[ok]).max()), 1e-4)


def test_roundtrip_encode_decode():
    """Encode at s, decode at s == s: lossless apart from float32
    (f_tensor_type.md outlet-0 round trip; exact pixel fixtures)."""
    tex = np.zeros((1, 3, 4), F32)
    vals = [(0.01, 0.0, 0.01), (0.02, -0.01, 0.01), (0.0, 0.0, 0.0)]
    for j, (jxx, jxy, jyy) in enumerate(vals):
        tex[0, j, :] = tensor_texture(jxx, jxy, jyy, s=F32(1.0))[0, 0, :]
    nx, ny = _nxny(tex)
    back_r = g.nearest(tex, nx, ny)[..., 0]
    back_g = (g.nearest(tex, nx, ny)[..., 1] - F32(0.5)) * F32(2.0) / F32(1.0)
    back_b = g.nearest(tex, nx, ny)[..., 2]
    expect = [np.array([v[i] for v in vals], F32)[None, :] for i in range(3)]
    for got, exp, lbl in ((back_r, expect[0], "Jxx"), (back_g, expect[1], "Jxy"),
                          (back_b, expect[2], "Jyy")):
        check(f"round-trip {lbl}", float(np.abs(got - exp).max()), 1e-5)


def test_axis_matches_gain_free():
    src = noise_tex(3)
    # gain-free identity: decode axis/L-shape unchanged when both strengths
    # scale together (producer and consumer agree) -- output identical
    a1 = aniso_pass(tensor_at_angle(3.0, 0.4, 45), src, s_tm=F32(12.0), s_dec=F32(12.0))
    a2 = aniso_pass(tensor_at_angle(3.0, 0.4, 45, s=F32(120.0)), src,
                    s_tm=F32(120.0), s_dec=F32(120.0))
    check("gain-free: x10 both strengths, output identical",
          float(np.abs(a1 - a2).max()), 1e-6)
    # a delivered-strength sweep of x10 (tensormap strength 100 -> 1000) with
    # the consumer's decode fixed: W saturates at 1 for this lam1, so the
    # output is unchanged within float noise (the documented pairing story)
    a3 = aniso_pass(tensor_at_angle(3.0, 0.4, 45, s=F32(1000.0)), src,
                    s_tm=F32(1000.0), s_dec=S_DEC)
    d = float(np.abs(a3 - aniso_pass(tensor_at_angle(3.0, 0.4, 45), src)).max())
    note("s_tm=1000 vs 100, same kernel: abs diff", d)
    check("saturated W unchanged under delivered-strength sweep", d, 1e-6)


def test_non_spd_detects_vs_black_phantom():
    # all-zeros decode: Jxx=0, Jxy=-1/s, Jyy=0 -> root=2/s, lambda2=-1/s <0
    _, _, _, _, _, root, lam1, lam2, _ = decode_raw(VS_BLACK, S_DEC)
    check("vs_black root == 2/strength", float(np.abs(root - F32(2.0) / S_DEC).max()), 1e-6)
    check("vs_black lambda1 == 1/strength (phantom energy)",
          float(np.abs(lam1 - F32(1.0) / S_DEC).max()), 1e-6)
    frac_bad = float(np.mean(lam2 < -EPS_SPD))
    note("vs_black lambda2 < 0 fraction", frac_bad)
    check("vs_black lambda2 < -eps everywhere (SPD guard fires)", 1.0 - frac_bad, 0.0)
    # mis-wired packed texture: (0.5, 0.5, 0, 0) through the raw decode is a
    # WEAK tensor (Jxx = 0.5/strength): trace ~ 0.005, still SPD/isotropic --
    # it is the near-iso regime, exercised in test_isotropic_fallback_exact
    _, _, _, trace, _, _, _, lam2g, _ = decode_raw(PACKED_NEUTRAL, S_DEC)
    check("packed-neutral miswire decodes a weak SPD isotropic tensor",
          float(np.abs(trace - F32(0.5) / S_DEC).max()), 1e-6)
    # a real non-SPD feed is caught too
    _, _, _, _, _, _, _, lam2n, _ = decode_raw(NON_SPD, S_DEC)
    check("non-SPD tensor: lambda2 < -eps everywhere", 1.0 - float(np.mean(lam2n < -EPS_SPD)), 0.0)


# --- T005/T007: kernel vs independent brute force ------------------------

def test_kernel_matches_brute_boundary():
    src = noise_tex(5)
    for phi in (0, 45, 90):
        tens = tensor_at_angle(3.0, 0.4, phi)
        out = aniso_pass(tens, src, length=LENGTH, w_gate=W_GATE, floor=FLOOR)
        L, D, _, _ = _expect_LD(tens)
        ref = brute_reference(src, L, D, phi, density=8)
        err = float(np.abs(_rgb(out) - _rgb(ref))[INTERIOR].max())
        note(f"phi {phi}: 49-tap vs 129-tap densified quadrature (max abs, RGB)", err)
        # density 8's own residual vs density 4 is ~4e-4; the delivered kernel
        # is a 1-px quadrature: its ~1.1e-2 max deviation is the discretization
        # error (the ADR-2 banding datum), not a logic error -- recorded in
        # the ADR-2 addendum; tolerance is a sane correctness band.
        check(f"kernel vs brute boundary phi={phi}", err, 2e-2)

    # convergence as tap count grows (densified stations)
    tens = tensor_at_angle(3.0, 0.4, 45)
    src = noise_tex(5)
    L, D, _, _ = _expect_LD(tens)
    ref = brute_reference(src, L, D, 45, density=8)
    e1 = float(np.abs(_rgb(aniso_pass(tens, src, density=1.0)) - _rgb(ref))[INTERIOR].max())
    e2 = float(np.abs(_rgb(aniso_pass(tens, src, density=2.0)) - _rgb(ref))[INTERIOR].max())
    note("quadrature convergence: err density 1", e1)
    note("quadrature convergence: err density 2", e2)
    # NOTE: density-2 uses 0.5px station steps (a DIFFERENT, better kernel --
    # 97 taps, above TAPS_MAX's 49): it converges toward the continuous
    # quadrature. Density-1's own absolute error is the ADR-2 artifact datum
    # (the kernel is a 1-px quadrature; the residual vs densified ~1e-3).
    assert e2 < e1, f"densified kernel is not closer to the brute force: {e1} vs {e2}"


def test_banding_vs_area_gaussian_is_data():
    """ADR-2 evidence: the delivered kernel vs the continuous elliptical
    Gaussian -- printed as data for the PROVISIONAL-OPEN gate."""
    src = noise_tex(5)
    tens = tensor_at_angle(3.0, 0.4, 45)
    out = _rgb(aniso_pass(tens, src, length=LENGTH, w_gate=W_GATE, floor=FLOOR))
    L, D, _, _ = _expect_LD(tens)
    area = _rgb(dense_area_reference(src, L, D, 45, step=0.25))
    err = float(np.abs(out - area)[INTERIOR].mean())
    note("BANDING DATA: 49-tap kernel vs dense area Gaussian "
         f"(L={L:.2f}, D={D:.2f}, mean abs {err:.4f}) -- ADR-2 addendum input",
         err)
    check("banding sanity (mean abs vs area truth)", err, 0.2)

    # anisotropic response: the kernel smooths ALONG the axis more than
    # ACROSS it -- the two ratios quantify family (a) for the gate data
    src2 = noise_tex(19)
    g_y_in = np.abs(np.gradient(src2[..., 0], axis=0))[INTERIOR]
    g_y_out = np.abs(np.gradient(out[..., 0], axis=0))[INTERIOR]
    g_x_in = np.abs(np.gradient(src2[..., 0], axis=1))[INTERIOR]
    g_x_out = np.abs(np.gradient(out[..., 0], axis=1))[INTERIOR]
    note("along-axis smoothing ratio (y out/in)", float(g_y_out.mean() / g_y_in.mean()))
    note("across-axis gradient ratio (x out/in)", float(g_x_out.mean() / g_x_in.mean()))


# --- T008: invariants ----------------------------------------------------

def test_isotropic_fallback_exact():
    src = noise_tex(6)
    # (a) vs_black unconnected tensor -> guard -> plain length-radius isotropic
    out = aniso_pass(VS_BLACK, src, length=F32(4.0))
    ref = iso_reference(src, float(LENGTH))
    check("fallback exact: vs_black == isotropic reference",
          float(np.abs(out - ref).max()), 1e-5)
    # (b) tensormap bypass neutral (0, 0.5, 0, 1) -> trace 0 -> same result
    out = aniso_pass(NEUTRAL, src, length=F32(4.0))
    check("fallback exact: neutral tensor == isotropic reference",
          float(np.abs(out - ref).max()), 1e-5)
    # (c) mis-wired packed neutral (0.5, 0.5, 0, 0): through the raw decode it
    # is a WEAK isotropic tensor (Jxx = 0.5/strength), NOT the guard case --
    # so the output is its energy-gated blur, a NEAR-NO-OP (the honest reading
    # of ADR-3's gate model on a mis-wired feed): no crash, no fallback claim.
    out = aniso_pass(PACKED_NEUTRAL, src, length=F32(4.0))
    here = g.sample(src, *_nxny(src))
    near = float(np.abs(out - here).max())
    note("packed-neutral miswire (weak tensor): near-no-op margin",
         float(np.abs(out - iso_reference(src, float(LENGTH))).max()))
    check("packed-neutral miswire reads weak-tensor (near-no-op), no crash",
          near, 0.2)
    # (d) genuinely non-SPD tensor (mis-wired packed extreme)
    out = aniso_pass(NON_SPD, src, length=F32(4.0))
    check("fallback exact: non-SPD tensor == isotropic reference",
          float(np.abs(out - ref).max()), 1e-5)
    # (e) width_gate = 0: circular at every tensor (D == L -> circ fires)
    tens = tensor_at_angle(3.0, 0.4, 60)
    L, _, _, _ = _expect_LD(tens, w_gate=F32(0.0))
    check("width_gate 0 == isotropic reference at L=length*W",
          float(np.abs(aniso_pass(tens, src, w_gate=F32(0.0))
                       - iso_reference(src, L)).max()), 1e-5)
    # (f) floor = 1: isotropic everywhere
    L, _, _, _ = _expect_LD(tens, floor=F32(1.0))
    check("floor 1 == isotropic reference at L=length*W",
          float(np.abs(aniso_pass(tens, src, floor=F32(1.0))
                       - iso_reference(src, L)).max()), 1e-5)
    # (g) coherence-0 tensor (degenerate eigenvalues lambda1 == lambda2)
    Lg, _, _, _ = _expect_LD(DEGENERATE, w_gate=F32(1.0), floor=F32(0.0))
    out = aniso_pass(DEGENERATE, src, length=F32(4.0), w_gate=F32(1.0), floor=F32(0.0))
    check("degenerate lambdas == isotropic reference",
          float(np.abs(out - iso_reference(src, Lg)).max()), 1e-5)


def test_isotropic_reference_kernel_shape():
    """The reference kernel's own discrete structure: point-symmetric; and its
    deviation from the dense isotropic area Gaussian is REPORTED (the
    fallback banding magnitude, ADR-2 data)."""
    src = noise_tex(7)
    R = 4.0
    ref = _rgb(iso_reference(src, R))
    area = _rgb(dense_area_reference(src, R, R, 0.0, step=0.25))
    err = float(np.abs(ref - area)[INTERIOR].mean())
    note("BANDING DATA: isotropic 49-tap reference vs dense area Gaussian "
         f"(R={R}, mean abs {err:.4f})", err)
    check("isotropic reference banding sanity", err, 0.2)
    vin = float(np.var(src[..., 0][INTERIOR]))
    vout = float(np.var(ref[..., 0][INTERIOR]))
    note("reference variance reduction", f"{vin:.4f} -> {vout:.4f} (std out/in {np.sqrt(vout / vin):.3f})")
    check("reference smooths the source (variance drops)",
          max(0.0, vout / vin - 1.0), 0.0)
    flip = np.ascontiguousarray(src[::-1, ::-1])
    rf = _rgb(iso_reference(flip, R))
    check("isotropic reference point-symmetric",
          float(np.abs(rf - ref[::-1, ::-1]).max()), 1e-5)


def test_length_zero_identity():
    src = noise_tex(9)
    tens = tensor_at_angle(3.0, 0.4, 30)
    out = aniso_pass(tens, src, length=F32(0.0))
    here = g.sample(src, *_nxny(src))
    check("length 0 == source (identity)", float(np.abs(out - here).max()), 1e-5)


def test_convex_hull():
    src = noise_tex(10)
    for phi, wg, fl in ((0, 0.5, 0.25), (70, 1.0, 0.0), (135, 0.2, 0.9)):
        tens = tensor_at_angle(3.0, 0.4, phi)
        out = _rgb(aniso_pass(tens, src, w_gate=F32(wg), floor=F32(fl)))
        # measured as VIOLATIONS: output below the source min (or above max)
        lo = float(max(0.0, src[..., :3].min() - out.min()))
        hi = float(max(0.0, out.max() - src[..., :3].max()))
        check(f"convex hull phi={phi} (min violation)", lo, 0.0)
        check(f"convex hull phi={phi} (max violation)", hi, 0.0)


def test_coherent_edge():
    src = step_edge_tex()
    tens = tensor_texture(3.0, 0.0, 0.02)   # vertical edges: gradient axis = x
    L, D, _, coh = _expect_LD(tens, w_gate=F32(1.0), floor=F32(0.0))
    note("coherent edge L, D, coherence",
         f"L={L:.2f} D={D:.4f} coh={coh:.4f}")
    out = _rgb(aniso_pass(tens, src, length=F32(4.0), w_gate=F32(1.0), floor=F32(0.0)))
    gx_in = np.abs(np.gradient(src[..., 0], axis=1))
    gx_out = np.abs(np.gradient(out[..., 0], axis=1))
    err_at_edge = np.abs(gx_out - gx_in)[:, 31:35]
    err = float(err_at_edge[INTERIOR[0], :].max())
    note("coherent edge: across-edge gradient max change at the edge", err)
    check("across-edge gradient preserved at the edge (spec criterion)",
          err, 0.02)
    # along-edge smoothing: the sin variation along y is damped; measured
    # attenuation ~0.78 predicted by the discrete along-marginal transform
    along_var_in = float(np.var(src[8:-8, 60, 0]))
    along_var_out = float(np.var(out[8:-8, 60, 0]))
    note("along-edge variance in -> out",
         f"{along_var_in:.5f} -> {along_var_out:.5f} "
         f"(amp ratio {np.sqrt(along_var_out / along_var_in):.3f})")
    check("along-edge variation smoothed",
          max(0.0, along_var_out / along_var_in - 1.0), 0.0)


def test_axis_rotation_phi():
    src = noise_tex(12)
    for phi in (0, 45, 90, 135):
        tens = tensor_at_angle(3.0, 0.4, phi)
        out = aniso_pass(tens, src, length=LENGTH, w_gate=W_GATE, floor=FLOOR)
        L, D, _, _ = _expect_LD(tens)
        ref = brute_reference(src, L, D, phi, density=8)
        err = float(np.abs(_rgb(out) - _rgb(ref))[INTERIOR].max())
        check(f"brute agreement at phi={phi}", err, 2e-2)


def test_axis_flip_gauge_invariance():
    src = noise_tex(13)
    tens = tensor_at_angle(3.0, 0.4, 67)
    a = aniso_pass(tens, src, flip_axis=False)
    b = aniso_pass(tens, src, flip_axis=True)
    check("v-flip gauge invariance (line field +-180 deg)",
          float(np.abs(a - b).max()), 1e-5)


def test_unconnected_source_black():
    tens = tensor_at_angle(3.0, 0.4, 45)
    black = g.texture(H, W)
    out = aniso_pass(tens, black)
    check("unconnected source -> black, no crash", float(np.abs(out).max()), 1e-6)


def test_bypass_passthrough():
    src = noise_tex(14)
    out = bypass_pass(src)
    check("bypass == inlet 1 exactly", float(np.abs(out - src).max()), 1e-6)


def test_no_nan_anywhere():
    for tens in (VS_BLACK, NEUTRAL, PACKED_NEUTRAL, NON_SPD,
                 tensor_at_angle(3.0, 0.4, 45), tensor_texture(0.0, 0.0, 0.0)):
        src = noise_tex(15)
        for wg, fl, ln in ((0.5, 0.25, 4.0), (0.0, 1.0, 0.0), (1.0, 0.0, 8.0)):
            out = aniso_pass(tens, src, w_gate=F32(wg), floor=F32(fl), length=F32(ln))
            assert np.isfinite(out).all(), "NaN/Inf in output"
    print("    ok   no NaN/Inf across guard and knob extremes")


# --- T009: mutation checks ----------------------------------------------

def test_mutations_are_caught():
    src = noise_tex(16)

    # (a) drop the SPD guard: the phantom-trace vs_black case ALSO has
    # trace < eps_trace, so it falls back through the trace clause either way
    # (the "trace gate is incidentally safe" finding -- SPD's own case is a
    # LARGE-trace non-SPD feed): NON_SPD (Jxx=1, Jxy=1, Jyy=0.1) has trace 1.1
    # and lambda2 = -0.49 < 0; only the SPD clause catches it. With the clause
    # dropped the gate runs on garbage (W = 1, coherence clipped to 1) and the
    # kernel elongates along a phantom axis.
    good = iso_reference(src, float(LENGTH))
    mut = aniso_pass(NON_SPD, src, mutation="drop_spd_guard")
    d = float(np.abs(mut - good).max())
    assert d > 0.02, f"drop_spd_guard NOT caught by the fallback baseline: {d}"
    print(f"    ok   dropped SPD guard caught (non-SPD vs fallback, diff {d:.3f})")

    # (b) width gate uses lambda2/lambda1 instead of coherence
    tens = tensor_at_angle(4.0, 1.0, 45)      # coh 0.6 vs ratio 0.25
    good = aniso_pass(tens, src)
    mut = aniso_pass(tens, src, mutation="ratio_width")
    d = float(np.abs(mut - good).max())
    assert d > 0.005, f"ratio_width NOT caught: {d}"
    print(f"    ok   lambda2/lambda1 width gate caught (diff {d:.4f})")

    # (c) G-channel offset/decoding dropped: Jxy decoded as G*2/s instead of
    # (G-0.5)*2/s. Meaningful where Jxy*strength is small (G near 0.5 -- the
    # offset is proportionally huge); at strength 1 on a step-edge source,
    # the phantom 2*Jxy = 1 instead of 0.006 rotates the axis and W: 0.24 max.
    tensg = tensor_texture(0.02, 0.003, 0.002, s=F32(1.0))
    good = aniso_pass(tensg, src, s_tm=F32(1.0), s_dec=F32(1.0))
    mut = aniso_pass(tensg, src, s_tm=F32(1.0), s_dec=F32(1.0),
                     mutation="flip_g_offset")
    d = float(np.abs(mut - good).max())
    assert d > 0.005, f"flip_g_offset NOT caught: {d}"
    print(f"    ok   missing G-channel 0.5 offset caught (diff {d:.4f})")

    # (d) skip tap-weight normalization: at the DEFAULT strengths (the weak-
    # tensor (c) fixture collapses the kernel: wsum ~ 1, invisible), so this
    # runs on the 45-deg default fixture: unnormalized acc ~ 6x the source.
    tensg = tensor_at_angle(3.0, 0.4, 45)
    good = aniso_pass(tensg, src)
    mut = aniso_pass(tensg, src, mutation="skip_norm")
    d = float(np.abs(mut - good).max())
    assert d > 0.1, f"skip_norm NOT caught: {d}"
    print(f"    ok   skipped weight normalization caught (diff {d:.3f})")


# --- T010: strength-coupling measurement (ADR-3) -------------------------

def test_strength_pairing_measurement():
    """The G-channel trap made numeric: the same physical tensor delivered at
    producer gain s_tm and decoded at consumer gain s_dec mismatches by
    s_tm/s_dec, scaling lambda1 and thus W. Printed for tasks.md T010 notes."""
    src = noise_tex(17)
    tens = tensor_at_angle(3.0, 0.4, 45)
    results = []
    for s_dec in (33.3, 100.0, 300.0):
        out = aniso_pass(tens, src, s_tm=S_TMAP, s_dec=F32(s_dec),
                         length=F32(4.0), w_gate=F32(1.0), floor=F32(0.0))
        # measure the effective smoothing: variance reduction in R
        vr = float(np.var(src[..., 0][INTERIOR]) - np.var(out[..., 0][INTERIOR]))
        lam1 = 3.0 * S_TMAP / s_dec            # decoded lambda scales by mismatch
        w_en = min(1.0, lam1 * float(s_scale_of(F32(s_dec))))
        results.append((s_dec, w_en, vr))
        note(f"pairing s_dec={s_dec}: decoded lambda1={lam1:.2f} -> W={w_en:.3f}, "
             f"variance reduction {vr:.4f}", "")
    assert results[0][1] > results[2][1], "energy gate must track the mismatch ratio"
    print("    ok   strength pairing measured (see notes above; OQ3 option (a))")


# --- ADR-2 gate data: kernel family (a) vs the ellipse-grid alternative --

def test_adr2_family_b_ellipse_grid_reference():
    """The ADR-2 'family (b)' alternative at MATCHED budget: a bounded u-t
    grid (5x5 = 25 taps < 49) with analytic exp weights on the same synthetic
    tensor+edge. Its deviation from the dense area Gaussian is the mirror-side
    artifact comparison for plan ADR-2's gate."""
    src = noise_tex(18)
    tens = tensor_at_angle(3.0, 0.4, 45)
    L, D, _, _ = _expect_LD(tens)
    area = _rgb(dense_area_reference(src, L, D, 45, step=0.25))
    out_a = _rgb(aniso_pass(tens, src, length=LENGTH, w_gate=W_GATE, floor=FLOOR))
    out_b = _rgb(ellipse_grid_pass(src, L, D, 45))
    e_a = float(np.abs(out_a - area)[INTERIOR].mean())
    e_b = float(np.abs(out_b - area)[INTERIOR].mean())
    note("ADR-2 GATE DATA: family (a) 49-tap vs area truth (mean abs)", e_a)
    note("ADR-2 GATE DATA: family (b) 5x5 grid vs area truth (mean abs)", e_b)
    assert e_a < 0.2 and e_b < 0.2, "both families should be bounded vs truth"
    print("    ok   ADR-2 family (a)/(b) artifact comparison recorded as data")


if __name__ == "__main__":
    sys.exit(run(globals()))