"""
tf_hatch_mirror.py -- NumPy mirror of the tf_hatch shader: the functions (and the constants and
fixtures they need) that tests/modules/tf_hatch/bench_tf_hatch.py imports. Extracted
from test_tf_hatch.py in Phase C, 2026-10-18; the tests stay there.
"""
import numpy as np
import gpu_sim as g  # noqa: E402

F32 = np.float32

# --- named constants (the codebox will carry the same names + comments) ---

EPS_TRACE = 1e-6      # tensormap ADR-6/T019 value, cited (re-validated in T007)
C_LO = 0.25           # PROVISIONAL knee (OQ3): = coherence_gate default
C_HI = 1.0            # PROVISIONAL knee (OQ3)
PRES_EPS = 1e-6       # presence knee width at floor 0 (a hair above the iso guard)
PRES_LO = 0.5         # presence ramp: lo = PRES_LO * thr  (thr = floor^2)
PRES_HI = 1.5         # presence ramp: hi = PRES_HI * thr + PRES_EPS
DENSITY_SPAN = 5.0    # family log map span (weave's published value)
HASH_A = 127.1        # weave's published line-hash constants
HASH_C = 43758.5453


# ------------------------------------------------------------------ E1 ---

def commit_curve(coh, c_lo=C_LO, c_hi=C_HI, gate=None, form="smoothstep"):
    """The provisional commit curve (OQ3-parameterized: named knees, the
    direct smoothstep and the linear form both implemented so T005's sweep
    can switch forms without rewriting the mirror).

    Invariants (spec Commit curve properties): continuous, monotone in the
    normalized eigengap, 0 at/below coherence_gate, -> 1 as coherence -> 1.
    `gate` (when given) is the coherence_gate dial; by default c_lo IS the
    gate (the provisional single-knee shape)."""
    if gate is None:
        gate = c_lo
    coh = np.asarray(coh, F32)
    lo = F32(gate)
    x = np.clip((coh - lo) / np.maximum(F32(c_hi) - lo, 1e-6), F32(0), F32(1))
    if form == "smoothstep":
        return (x * x * (F32(3) - F32(2) * x)).astype(F32)
    if form == "linear":
        return x.astype(F32)
    raise ValueError(form)


def presence(enc_trace, floor=0.0):
    """Presence: is there structure here AT ALL, independent of its direction.
    Decoupled from commit (shape) on 2026-10-28 after the first live look:
    when one variable carried both, the line->dot rounding faded to black and
    the coherence gate only dimmed the field.

    enc_trace = R + B of the tensormap outlet-0 texel, i.e. trace * the
    tensormap's `strength` (its calibrated scale: ~1 on strong structure).
    thr = floor^2 (finer control at the low end); smooth ramp from 0.5*thr to
    1.5*thr (+ a hair). floor 0 -> a step at the iso guard: presence 1
    wherever any structure exists. NOT strength-invariant for floor > 0
    (spec: the optional absolute trace floor is the one strength-scaled
    quantity)."""
    thr = F32(floor) * F32(floor)
    lo = F32(PRES_LO) * thr
    hi = F32(PRES_HI) * thr + F32(PRES_EPS)
    return _smoothstep(lo, hi, np.asarray(enc_trace, F32))


def decode(t, strength=100.0):
    """E1 mirror: the canonical decode idiom, copied VERBATIM from
    .specify/f_tf_glyph/plan.md ADR-2 (f_tensor_type.md outlet 0 encoding).
    `t` = one RGBA tensor sample, any float dtype. Returns
    (Jxx, Jxy, Jyy, trace, diff, root, lambda1, lambda2, theta_grad,
     axis_along, coherence)."""
    Jxx = t[0] / strength
    Jxy = (t[1] - 0.5) * 2.0 / strength
    Jyy = t[2] / strength
    trace = Jxx + Jyy
    diff = Jxx - Jyy
    root = np.sqrt(diff * diff + F32(4.0) * Jxy * Jxy)
    lambda1 = F32(0.5) * (trace + root)
    lambda2 = F32(0.5) * (trace - root)
    theta = F32(0.5) * np.arctan2(F32(2.0) * Jxy, diff)   # GRADIENT axis
    axis = theta + F32(np.pi / 2)                          # ALONG-STRUCTURE axis
    coherence = np.where(trace > EPS_TRACE,
                         (lambda1 - lambda2) / np.maximum(trace, EPS_TRACE),
                         F32(0.0))
    return (Jxx, Jxy, Jyy, trace, diff, root, lambda1, lambda2, theta, axis,
            coherence.astype(F32))


def stage_e1(tex, strength=100.0, gate=None, angle_offset=0.0, floor=0.0):
    """E1 mirror: decode + commit + presence + guard, written as the codebox
    pass runs.

    tex: (H, W, 4) outlet-0-format tensor texture, sampled at norm (texel
    centred, so the sample coordinate is trivially in-bounds -- the in-shader
    clamp is a no-op for a norm read; kept in the codebox for the rule).
    Below eps_trace: commit 0, presence 0 and axis unset-marker (ca=sa=0),
    never a decoded-angle artifact (plan ADR-5).

    aux (intermediate, NEVER an outlet): (ca, sa, commit, pres) where
    (ca, sa) = cos/sin of the COMMIT-FRAME axis
    (axis + angle_offset*pi/2); commit = SHAPE only (0 dot -> 1 stroke);
    pres = PRESENCE only (0 = draw nothing, 1 = draw), 0 below eps_trace
    (the old `iso` channel, now continuous: the structure-floor ramp).
    """
    ca, sa = np.zeros(tex.shape[:2], F32), np.zeros(tex.shape[:2], F32)
    commit = np.zeros(tex.shape[:2], F32)
    pres = np.zeros(tex.shape[:2], F32)
    for i in range(tex.shape[0]):
        for j in range(tex.shape[1]):
            (_Jxx, _Jxy, _Jyy, trace, _d, _r, _l1, _l2, _th, axis, coh) = \
                decode(tex[i, j], strength)
            if trace <= F32(EPS_TRACE):
                continue          # pres stays 0, axis unset (0,0), commit 0
            pres[i, j] = presence(F32(tex[i, j, 0]) + F32(tex[i, j, 2]), floor)
            eff = axis + F32(angle_offset * np.pi / 2.0)
            ca[i, j] = np.cos(eff).astype(F32)
            sa[i, j] = np.sin(eff).astype(F32)
            # codebox (2026-10-17 contract fix): the coherence_gate dial IS the
            # commit knee -- x renormalizes over [gate, C_HI], so crossing the
            # floor stays continuous (the no-seam guarantee).
            commit[i, j] = commit_curve(np.array([coh], F32),
                                        gate=F32(0.0) if gate is None else F32(gate))[0]
    return g.store_float32(np.stack([ca, sa, commit, pres], -1))


# ------------------------------------------------------------------ E2 ---

def stage_e2(aux):
    """E2 mirror (branch T): the tileable distance-field layout in the
    per-pixel local frame.

    aux: E1's intermediate (ca, sa, commit, pres). All frame coordinates are
    `norm` reads (sampling at the pixel itself -- no taps, the axis texture
    carries the per-pixel frame).

    aux2 (intermediate): (u, v, commit, pres) where (u, v) = the pixel
    rotated into its local (across, along) frame (already angle_offset-
    applied in E1: the frame is the committed axis).
    """
    ca, sa, commit, pres = aux[..., 0], aux[..., 1], aux[..., 2], aux[..., 3]
    nx, ny, _, _ = g.grid(aux.shape[0], aux.shape[1])
    u = (-sa * nx + ca * ny).astype(F32)       # across (normal) coordinate
    v = (ca * nx + sa * ny).astype(F32)        # along-stroke coordinate
    return g.store_float32(np.stack([u, v, commit, pres], -1))


# ------------------------------------------------------------------ E3 ---

def stage_e3(aux2, density=0.5, weight=0.1, softness=0.05, elongation=3.0,
             phase=0.0, regularity=0.5, bypass=0.0):
    """E3 mirror (branch T): mark render + compose + encode (the only stage
    that clamps/encodes). Reads aux2's (u, v) local frame + commit.

    The f_weave algorithm (docs/f-reference/f_weave.md), adapted to the
    per-pixel axis and the commit-driven aspect; cited where reused verbatim
    (density log map, line hash, smoothstep profile, softness clamp 0.49).

    Aspect is the family's squeeze mechanism (discrete_item_conventions
    'size+stretch'), PITCH-NORMALIZED (plan ADR-9): aspect = 1 +
    elongation*commit, capped where the dash saturates its pitch:
    al = min(weight*density_scale*sqrt(aspect), 0.5) with
    aw = weight/sqrt(aspect) (u units), so the mark's across/along extents
    (in their own pitch units) realise exactly sqrt(aspect_pitch = the cap)
    -- "aspect = elongation+1 until saturation" (ADR-9: aspect_max =
    0.25/(weight*density_scale)^2; at the provisional defaults it binds at
    elongation ~2.1).

    Mark INTENSITY is weighted by PRESENCE only (aux2's 4th channel, the
    structure floor), NEVER by commit. commit drives shape alone: commit 0 =
    a full-brightness dot (aspect 1), commit 1 = a stroke. (Changed
    2026-10-28 after the first live look: weighting intensity by commit as
    well made the dot state invisible -- the coherence gate only dimmed the
    field. Presence 0 = nothing: no structure at all / below the floor.)

    out0 = hatch output (luma marks on black, A=1); out1 = mark mask
    (the same luma, encode-mixed only -- the discrete-family convention).
    Bypass = black on both (plan ADR-5).
    """
    u, v, commit, pres = aux2[..., 0], aux2[..., 1], aux2[..., 2], aux2[..., 3]
    aspect = (F32(1.0) + F32(elongation) * commit).astype(F32)
    soft = F32(min(softness, 0.49))
    density_scale = F32(2.0 ** (density * DENSITY_SPAN - 1.0))
    # ADR-9 (pitch-unit aspect, capped at dash saturation):
    aw = (weight / np.sqrt(aspect)).astype(F32)
    al = np.minimum(weight * density_scale * np.sqrt(aspect),
                    F32(0.5)).astype(F32)
    dist_to_line = np.abs(np.mod(u * density_scale, F32(1.0)) - F32(0.5)).astype(F32)
    line_idx = np.floor(u * density_scale).astype(F32)
    # weave's published line-hash: fract(sin(line_idx*127.1)*43758.5453) — a
    # SIGNED fract: x - floor(x) (GLSL semantics; negative sines flip the
    # fraction). 2026-10-17 bench finding: the first draft used
    # |sin|·C % 1, which equals the GLSL fract only when the sine is
    # positive; every negative-sine line got a different hash than the GPU
    # (den 0.7 sweeps failed at 0.687).
    sh = np.sin(line_idx * F32(HASH_A)) * F32(HASH_C)
    line_hash = ((sh - np.floor(sh)) * F32(1.0 - regularity)).astype(F32)
    pos = (v * density_scale + F32(phase) + line_hash).astype(F32)
    dist_to_mark = np.abs(np.mod(pos, F32(1.0)) - F32(0.5)).astype(F32)
    # WEAVE'S PUBLISHED EDGE FORM (cited verbatim, f_weave.md / its
    # definition.py): outer = weight + softness*weight, inner = 0:
    # edge = smoothstep(outer, 0.0, dist) -- softness EXPANDS the outer
    # edge multiplicatively rather than straddling; softness 0 = the
    # hard smoothstep(weight, 0, dist) profile, no zero-denominator case.
    outer_across = (aw * (F32(1.0) + soft)).astype(F32)
    outer_along = (al * (F32(1.0) + soft)).astype(F32)
    m_line = _smoothstep(outer_across, F32(0.0), dist_to_line)
    m_mark = _smoothstep(outer_along, F32(0.0), dist_to_mark)
    marks = (m_line * m_mark * pres).astype(F32)
    out0 = np.zeros(aux2.shape[:2] + (4,), F32)
    out0[..., 0] = marks
    out0[..., 3] = F32(1.0)
    out1 = out0.copy()          # mark mask: same luma, no encode mix in v1
    # bypass = the neutral (black) with the outlet contract's A=1 preserved
    # (2026-10-17, codebox parity: the first draft multiplied the whole vec
    # by (1-bypass), dropping alpha to 0 — against the outlets-are-A=1 rule).
    out0[..., 0] = out0[..., 0] * F32(1.0 - bypass)
    out0[..., 1] = out0[..., 1] * F32(1.0 - bypass)
    out0[..., 2] = out0[..., 2] * F32(1.0 - bypass)
    out0[..., 3] = F32(1.0)
    out1[..., 0] = out1[..., 0] * F32(1.0 - bypass)
    out1[..., 1] = out1[..., 1] * F32(1.0 - bypass)
    out1[..., 2] = out1[..., 2] * F32(1.0 - bypass)
    out1[..., 3] = F32(1.0)
    return g.store_float32(out0), g.store_float32(out1)


def _smoothstep(edge0, edge1, x):
    """GLSL-semantics smoothstep = GenExpr's built-in smoothstep() op: the
    ramp runs edge0 -> edge1, so DECreasing edges (weave's mark profile:
    smoothstep(weight + softness, max(weight - softness, 0), dist)) INVERT
    correctly. Written explicitly so the mirror matches the GPU op's clamp
    (t = clamp((x - e0)/(e1 - e0), 0, 1) with the sign carried, verified
    identical to weave's published profile on both orderings)."""
    e0 = np.asarray(edge0, F32)
    e1 = np.asarray(edge1, F32)
    denom = (e1 - e0).astype(F32)
    denom = np.where(np.abs(denom) < F32(1e-7), F32(1e-7) * np.where(denom < 0, F32(-1), F32(1)), denom)
    t = np.clip((x - e0) / denom, F32(0), F32(1)).astype(F32)
    return (t * t * (F32(3) - F32(2) * t)).astype(F32)
