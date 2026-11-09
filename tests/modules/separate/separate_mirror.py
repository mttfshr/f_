"""separate_mirror.py -- tier-1 NumPy mirror of the not-yet-built f_separate module (spec:
.specify/stable/f_separate/spec.md, plan ADR-1 to ADR-5, tasks T014-T015). Float32, per pixel, stateless,
in the order a codebox would compute it.

Model (Matt, 2026-11-08): the background is black and inks are colors of light that ADD.
    pixel = sum_i c_i * k_i          k_i = ink color (RGB, 0..1), c_i = coverage in 0..1
Unmix (P1, P2): c = clamp(gain * (K^T K + lam I)^-1 K^T x, 0, 1)   (gain, then one clamp: FR-004)       K = 3 x N, N = `inks`
    lam = LAM_REL * trace(K^T K) / N + LAM_ABS    (relative ridge, so a dim ink is not biased;
    an INFERRED choice, gate G3, not measured on a bench). The N x N inverse is by cofactors, as
    the codebox must do it (N <= 3).
Nearest (P6): the winner among the N inks and black (squared RGB distance; ties go to an ink,
    lowest index) gets coverage 1 (then gain, then clamp), the others 0; black winning gives 0.
Project (P12, Matt 2026-11-08): each ink alone: c_i = clamp(gain_i * (k_i . x) / (k_i . k_i), 0, 1); a plate
    depends only on the source and its own ink (no joint solve, so no exact round trip for overlapping inks).
Outputs (P5): plates 0..2, plate i = clamp(gain_i * c_i, 0, 1) * k_i (black beyond `inks`);
    preview = clamp(sum of the plates, 0, 1). Alpha is the source's on all four. Non-finite
    input components are zapped to 0 first (FR-010). Bypass (P10): the zapped source on all four.
    in0 = None stands for nothing connected: black, alpha 0 (vs_black), on all four.

`bug` values are mutations the tests must catch: "no_clamp", "gain_after_clamp", "preview_no_clamp",
"nearest_no_black", "skip_zap", "ignore_alpha", "project_joint", "pack_rgb" (plates packed into R, G, B as before
the 2026-11-08 decision).
"""
import numpy as np

F32 = np.float32
LAM_REL = F32(1e-4)
LAM_ABS = F32(1e-8)


def zap(x):
    return np.where(np.isfinite(x), x, F32(0)).astype(F32)


def inv_cofactor(m):
    """Inverse of a 1x1, 2x2 or 3x3 float32 matrix by cofactors (what the codebox does)."""
    m = m.astype(F32)
    n = m.shape[0]
    if n == 1:
        return (F32(1) / m).astype(F32)
    if n == 2:
        a, b, c, d = m[0, 0], m[0, 1], m[1, 0], m[1, 1]
        det = a * d - b * c
        return (np.array([[d, -b], [-c, a]], dtype=F32) / det).astype(F32)
    a, b, c = m[0]
    d, e, f = m[1]
    g, h, i = m[2]
    A, B, C = e * i - f * h, f * g - d * i, d * h - e * g
    det = a * A + b * B + c * C
    cof = np.array([[A, c * h - b * i, b * f - c * e],
                    [B, a * i - c * g, c * d - a * f],
                    [C, b * g - a * h, a * e - b * d]], dtype=F32)
    return (cof / det).astype(F32)


def ridge_inverse(k):
    """(K^T K + lam I)^-1 for K of shape (3, N)."""
    n = k.shape[1]
    ktk = (k.T @ k).astype(F32)
    lam = LAM_REL * (np.trace(ktk) / F32(n)) + LAM_ABS
    return inv_cofactor(ktk + lam * np.eye(n, dtype=F32))


def separate_stage(src, inks, n_inks=3, mode="unmix", gains=(1, 1, 1), bypass=0, bug=None):
    """src: (H, W, 4) float32 or None. inks: (3, 3) rows = ink colors. Returns four (H, W, 4) arrays."""
    if src is None:
        z = np.zeros((1, 1, 4), dtype=F32)
        return z, z.copy(), z.copy(), z.copy()
    x = src.astype(F32) if bug == "skip_zap" else zap(src.astype(F32))
    alpha = x[..., 3:4] if bug != "ignore_alpha" else np.ones_like(x[..., 3:4])
    if bypass:
        return tuple(x.copy() for _ in range(4))
    rgb = x[..., 0:3]
    k = np.clip(zap(np.asarray(inks, dtype=F32)[:n_inks]), 0, 1).T.astype(F32)   # 3 x N
    g = np.asarray(gains, dtype=F32)[:n_inks]
    if mode == "nearest":
        cand = [k[:, i] for i in range(n_inks)] + ([] if bug == "nearest_no_black" else [np.zeros(3, F32)])
        d = np.stack([((rgb - c) ** 2).sum(-1) for c in cand], -1)
        win = np.argmin(d, -1)
        cov = np.stack([(win == i).astype(F32) for i in range(n_inks)], -1)
    else:
        t = np.einsum("cn,...c->...n", k, rgb).astype(F32)
        if mode == "project" and bug != "project_joint":
            kk = (k * k).sum(0).astype(F32)
            cov = (t / np.maximum(kk, F32(1e-8))).astype(F32)       # each ink on its own
        else:
            cov = np.einsum("nm,...m->...n", ridge_inverse(k), t).astype(F32)
    if bug == "gain_after_clamp":
        cov = (np.clip(cov, 0, 1) * g).astype(F32)          # clamp first, gain unbounded after
    elif bug == "no_clamp":
        cov = (cov * g).astype(F32)
    else:
        cov = np.clip(cov * g, 0, 1).astype(F32)             # FR-004: gain, then ONE clamp
    plates = []
    for i in range(3):
        p = np.zeros(rgb.shape, dtype=F32)
        if i < n_inks:
            p = (cov[..., i:i + 1] * k[:, i]).astype(F32)
        plates.append(p)
    total = (plates[0] + plates[1] + plates[2]).astype(F32)
    prev = total if bug == "preview_no_clamp" else np.clip(total, 0, 1).astype(F32)
    if bug == "pack_rgb":
        packed = np.zeros(rgb.shape, dtype=F32)
        for i in range(n_inks):
            packed[..., i] = cov[..., i]
        plates = [packed, np.zeros_like(rgb), np.zeros_like(rgb)]
    return tuple(np.concatenate([a, alpha], -1).astype(F32) for a in (plates[0], plates[1], plates[2], prev))
