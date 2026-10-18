"""
test_tf_glyph.py -- tier-1 NumPy mirror of f_tf_glyph
(.specify/f_tf_glyph/{spec,plan,tasks}.md, Phase 0 TG001-TG010).

Mirrors the single-stage codebox (codebox_glyph.gen) exactly as GenExpr:

  cell lookup   ADR-4 uniform lattice, cell centre = (floor(norm*grid)+0.5)/grid,
                sampled with gpu_sim.sample at coords clamped to texel centres
                (tensormap ADR-5: the bench GPU wraps out-of-range reads)
  decode        plan ADR-2 idiom, gain-free form: the tensor terms are used in
                their delivered units (R, G-0.5, B share the common `strength`
                factor, which cancels in every ratio this renderer uses)
  gate          ADR-6: a cell draws only if the delivered trace >= max(gate, eps_trace)
  draw          ADR-5 ellipse: aspect = clamp(sqrt(l1/l2), 1, max_aspect) on the
                delivered-units ratio; radius = scale * cellsize / 2; closed-form
                ring distance + smoothstep cover (f_weave convention)
  tint          ADR-7 provisional: ink = mix(white, source rgb, source luma) at
                the cell centre (TG019 gate pending; source never moves geometry)
  bypass        passthrough of the source texture (glyph = passthrough, per the
                2026-10-17 build directive; NOT a neutral composite)

Ground truth is independent of the mirror: np.linalg.eigh on the decoded 2x2
tensor, analytic ramp angles, the aspect algebra, invariants. A mutation check
per TG009 confirms the ramp-angle check catches a dropped 0.5 offset on G.

NOTE on the spec acceptance criterion "eigenvalue ratio 4 gives measured aspect
4": plan ADR-5 (later document, explicit formula) applies SQRT to the ratio,
so ratio 4 measures as aspect 2. The assert here follows ADR-5; the discrepancy
is recorded in tasks.md TG007 for Matt to arbitrate.

Run:  tests/run.sh tests/modules/tf_glyph/test_tf_glyph.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402

F32 = np.float32
H = W = 64
GRID = 4                      # coarse lattice so cells are many texels wide
EPS_TRACE = F32(1e-6)         # tensormap ADR-6 convention, inherited (T019 there)
DEF = dict(scale=0.8, thickness=0.15, softness=0.1, gate=0.05, max_aspect=8.0)


# --- decode idiom, gain-free (plan ADR-2; the codebox copies this verbatim) --

def decode_cells(t_s, max_aspect):
    """t_s: sampled tensor RGBA in delivered (strength-scaled) units.
    Returns trace_s, root_s, theta, aspect (all mirrors of the codebox)."""
    r = t_s[..., 0]
    gg = t_s[..., 1]
    b = t_s[..., 2]
    jxy2_s = (gg - F32(0.5)) * F32(4.0)        # = 2*Jxy*strength  (2*Jxy_s)
    diff_s = r - b                             # = (Jxx - Jyy)*strength
    root_s = np.sqrt(diff_s * diff_s + jxy2_s * jxy2_s).astype(F32)
    trace_s = r + b
    theta = F32(0.5) * np.arctan2(jxy2_s, diff_s).astype(F32)
    # degenerate-direction guard (codebox parity, 2026-10-17): the exact-
    # diagonal tensor (|jxy2|+|diff| == 0) has an undefined direction; the
    # GPU's atan2(0,0) NaNs there. NumPy returns 0 (benign), but the mirror
    # keeps the same guard so the two stay lockstep and the test asserts it.
    theta = np.where((np.abs(jxy2_s) + np.abs(diff_s)) <= F32(1e-9),
                     F32(0.0), theta).astype(F32)
    lam2 = np.maximum(trace_s - root_s, EPS_TRACE)
    ratio = (trace_s + root_s) / lam2
    aspect = np.clip(np.sqrt(np.maximum(ratio, F32(1.0))), F32(1.0),
                     F32(max_aspect)).astype(F32)
    return trace_s, root_s, theta, aspect


# --- full pass mirror -------------------------------------------------------

def sm(e0, e1, x):
    """GLSL smoothstep edge semantics (edge0 < edge1 form, as the codebox
    writes it: 1 - smoothstep(hw, hw+soft, |d|))."""
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return (t * t * (F32(3.0) - F32(2.0) * t)).astype(F32)


def _luma601(tex):
    return (F32(0.299) * tex[..., 0] + F32(0.587) * tex[..., 1]
            + F32(0.114) * tex[..., 2]).astype(F32)


def tensor_tex(h, w, jxx, jxy, jyy, strength=F32(1.0)):
    """Outlet-0 encoding (f_tensor_type.md): R=Jxx*s, G=Jxy*s*0.5+0.5, B=Jyy*s, A=1."""
    tex = g.texture(h, w)
    tex[..., 0] = jxx * strength
    tex[..., 1] = jxy * strength * F32(0.5) + F32(0.5)
    tex[..., 2] = jyy * strength
    tex[..., 3] = F32(1.0)
    return g.store_float32(tex)


def glyph(tensor, source=None, grid=GRID, scale=DEF["scale"],
          thickness=DEF["thickness"], softness=DEF["softness"],
          gate=DEF["gate"], max_aspect=DEF["max_aspect"], bypass_gate=0.0,
          tex_w=W, tex_h=H):
    """Mirror of codebox_glyph.gen, one pass, float32 end to end."""
    h, w = tensor.shape[:2]
    nx, ny, _, _ = g.grid(h, w)

    # bypass: passthrough of the source at the current pixel
    if bypass_gate:
        src_px = g.sample(source if source is not None else tensor,
                          nx, ny)
        out = g.texture(h, w)
        out[..., 0] = np.clip(src_px[..., 0], 0.0, 1.0)
        out[..., 1] = np.clip(src_px[..., 1], 0.0, 1.0)
        out[..., 2] = np.clip(src_px[..., 2], 0.0, 1.0)
        out[..., 3] = F32(1.0)
        return g.store_float32(out)

    # ADR-4 lattice: cell centres, clamped to texel centres (tensormap ADR-5)
    cell = np.floor(nx * F32(grid)).astype(F32)
    celly = np.floor(ny * F32(grid)).astype(F32)
    cu = (cell + F32(0.5)) / F32(grid)
    cv = (celly + F32(0.5)) / F32(grid)
    tu = np.clip(cu, F32(0.5) / F32(tex_w), F32(1.0) - F32(0.5) / F32(tex_w)
                 ).astype(F32)
    tv = np.clip(cv, F32(0.5) / F32(tex_h), F32(1.0) - F32(0.5) / F32(tex_h)
                 ).astype(F32)

    t_s = g.sample(tensor, tu, tv)                       # tensor at cell centre
    trace_s, _, theta, aspect = decode_cells(t_s, max_aspect)

    # ADR-6 gate, in delivered units; eps_trace floor makes the all-zeros
    # unconnected case render empty even at gate 0 (TG007)
    visible = (trace_s >= np.maximum(F32(gate), EPS_TRACE)).astype(F32)

    # local glyph frame: rotate (pixel - cell centre) by -(theta + pi/2)
    a = theta + F32(np.pi / 2)
    ca, sa = np.cos(a).astype(F32), np.sin(a).astype(F32)
    dxp = (nx - cu).astype(F32)
    dyp = (ny - cv).astype(F32)
    along = (dxp * ca + dyp * sa).astype(F32)
    across = (-dxp * sa + dyp * ca).astype(F32)

    cellsize = F32(1.0 / grid)
    rmaj = (F32(scale) * cellsize * F32(0.5)).astype(F32)
    bmin = (rmaj / aspect).astype(F32)
    e = np.sqrt((along / rmaj) ** 2 + (across / bmin) ** 2).astype(F32)
    d = ((e - F32(1.0)) * bmin).astype(F32)
    hw = (F32(0.5) * F32(thickness) * rmaj).astype(F32)
    soft = np.maximum(F32(softness) * rmaj, F32(1e-6)).astype(F32)
    cover = (F32(1.0) - sm(hw, hw + soft, np.abs(d))).astype(F32)

    # tint (ADR-7 provisional, TG019 pending): ink from the source at the cell
    # centre; an unconnected (black) source leaves the neutral white ink.
    if source is None:
        source = np.zeros((h, w, 4), F32)
    src = g.sample(source, tu, tv)
    src_l = _luma601(src)[..., None]
    ink = (F32(1.0) + (src[..., :3] - F32(1.0)) * src_l).astype(F32)

    rgb = ink * (cover * visible)[..., None]
    out = g.texture(h, w)
    out[..., 0] = np.clip(rgb[..., 0], F32(0.0), F32(1.0))
    out[..., 1] = np.clip(rgb[..., 1], F32(0.0), F32(1.0))
    out[..., 2] = np.clip(rgb[..., 2], F32(0.0), F32(1.0))
    out[..., 3] = F32(1.0)
    return g.store_float32(out)


# --- test fixtures ----------------------------------------------------------

INTERIOR = (slice(2, -2), slice(2, -2))   # away from every cell boundary


def rand_tensor(h=H, w=W, seed=0, strength=F32(1.0)):
    """Symmetric positive-definite 2x2 tensors, outlet-0 encoded."""
    rng = np.random.default_rng(seed)
    a = rng.normal(size=(h, w)).astype(F32)
    b = rng.normal(size=(h, w)).astype(F32) * F32(0.5)
    c = rng.normal(size=(h, w)).astype(F32)
    jxx = a * a + b * b
    jxy = a * b + b * c
    jyy = b * b + c * c
    return tensor_tex(h, w, jxx, jxy, jyy, strength), jxx, jxy, jyy


def ramp_tensor(h=H, w=W, phi=F32(0.6), strength=F32(1.0)):
    """Tensor of a linear luminance ramp at gradient angle phi:
    gradient g = (cos phi, sin phi), J = g g^T."""
    gx, gy = np.cos(phi).astype(F32), np.sin(phi).astype(F32)
    return tensor_tex(h, w, gx * gx, gx * gy, gy * gy, strength)


def _angdiff_mod_pi(a, b):
    d = np.mod(a - b + F32(np.pi / 2), F32(np.pi)) - F32(np.pi / 2)
    return np.abs(d)


# --- TG006: eigen ground truth ----------------------------------------------

def cell_tensor(tex, grid=GRID):
    """Sample tex at every cell centre (H,W pixels -> per-pixel cell value)."""
    nx, ny, _, _ = g.grid(*tex.shape[:2])
    cu = (np.floor(nx * F32(grid)) + F32(0.5)) / F32(grid)
    cv = (np.floor(ny * F32(grid)) + F32(0.5)) / F32(grid)
    return g.sample(tex, cu, cv)


def test_decode_matches_eigh():
    tex, jxx, jxy, jyy = rand_tensor(seed=1)
    t_s = cell_tensor(tex)
    trace_s, root_s, theta, aspect = decode_cells(t_s, DEF["max_aspect"])
    # independent ground truth per cell: np.linalg.eigh on the DECODED tensor
    # (the tensor sampled at the same cell centre the mirror reads)
    jxx_s = cell_tensor(np.stack([jxx] * 4, -1))
    jxy_s = cell_tensor(np.stack([jxy] * 4, -1))
    jyy_s = cell_tensor(np.stack([jyy] * 4, -1))
    h, w = tex.shape[:2]
    errors = []
    for yy in range(2, h - 2, 7):
        for xx in range(2, w - 2, 7):
            J = np.array([[jxx_s[yy, xx, 0], jxy_s[yy, xx, 0]],
                          [jxy_s[yy, xx, 0], jyy_s[yy, xx, 0]]], F32)
            evals, evecs = np.linalg.eigh(J)
            l1, l2 = evals[1], evals[0]
            # np.linalg.eigh axis is the major eigenvector = gradient here;
            # mirror theta is the gradient angle too
            th_ref = np.arctan2(evecs[1, 1], evecs[0, 1]).astype(F32)
            errors.append((float(trace_s[yy, xx] + root_s[yy, xx]) * 0.5 - float(l1),
                           float(trace_s[yy, xx] - root_s[yy, xx]) * 0.5 - float(l2),
                           float(_angdiff_mod_pi(theta[yy, xx], th_ref))))
    e = np.array(errors, F32)
    note("eigh lambda1 worst err", float(np.abs(e[:, 0]).max()))
    note("eigh lambda2 worst err", float(np.abs(e[:, 1]).max()))
    note("eigh theta worst err (rad, mod pi)", float(e[:, 2].max()))
    check("lambda1 vs eigh", float(np.abs(e[:, 0]).max()), 2e-5)
    check("lambda2 vs eigh", float(np.abs(e[:, 1]).max()), 2e-5)
    check("theta vs eigh axis", float(e[:, 2].max()), 1e-3)


def test_decode_diagonal_and_repeated_cases():
    # diagonal-only, repeated-eigenvalue, near-zero-lambda2 cases
    # expect: (theta, lambda1, lambda2)
    cases = [
        ((F32(1.0), F32(0.0), F32(0.0)), (F32(0.0), F32(1.0), F32(0.0))),        # pure x gradient
        ((F32(0.0), F32(0.0), F32(1.0)), (F32(np.pi / 2), F32(1.0), F32(0.0))),  # pure y
        ((F32(1.0), F32(0.0), F32(1.0)), (F32(0.0), F32(1.0), F32(1.0))),        # repeated
        ((F32(1.0), F32(0.0), F32(1e-9)), (F32(0.0), F32(1.0), F32(1e-9))),      # near-zero l2
        ((F32(0.0), F32(0.0), F32(0.0)), None),                                  # zero tensor
    ]
    for (jxx, jxy, jyy), expect in cases:
        tex = tensor_tex(1, 1, jxx, jxy, jyy)
        t_s = g.sample(tex, F32(0.5), F32(0.5))
        trace_s, root_s, theta, aspect = decode_cells(t_s, 8.0)
        if expect is None:
            check(f"zero tensor invisible (trace_s={float(trace_s)})",
                  0.0 if float(trace_s) < EPS_TRACE else 1.0, 0)
            continue
        l1 = float(trace_s[()] + root_s[()]) * 0.5
        l2 = float(trace_s[()] - root_s[()]) * 0.5
        tag = f"({float(jxx)},{float(jxy)},{float(jyy)})"
        check(f"case {tag} theta", float(abs(theta[()] - expect[0])), 1e-6)
        check(f"case {tag} lambda1", abs(l1 - float(expect[1])), 2e-5)
        check(f"case {tag} lambda2", abs(l2 - float(expect[2])), 2e-4)


# --- TG007: direction, aspect, gain-free identity, zero-tensor --------------

def test_ramp_known_angle():
    errs = []
    for phi in (0.0, 0.3, 1.1, 2.0, 2.9):
        tex = ramp_tensor(phi=F32(phi))
        out = glyph(tex)
        # measure the drawn mark's major-axis angle per cell: pixels with
        # cover > 0.5 must satisfy |along| ~ ring band along the ellipse --
        # instead, check the mirror's own theta against phi (the gradient
        # angle) and rely on the along-frame construction.
        h, w = tex.shape[:2]
        nx, ny, _, _ = g.grid(h, w)
        cu = (np.floor(nx * F32(GRID)) + F32(0.5)) / F32(GRID)
        cv = (np.floor(ny * F32(GRID)) + F32(0.5)) / F32(GRID)
        t_s = g.sample(tex, cu, cv)
        _, _, theta, _ = decode_cells(t_s, 8.0)
        err = float(_angdiff_mod_pi(theta[INTERIOR], F32(phi)).max())
        errs.append(err)
        check(f"ramp phi={phi} mirror theta == phi (mod pi)", err, 1e-5)
        # drawn major axis is at phi + pi/2: verify via the rendered mask's
        # principal direction inside one cell, against an independent calc.
        cell0 = (slice(1, H // GRID - 1), slice(1, W // GRID - 1))
        m = out[..., 0][cell0] > 0.5
        if m.sum() > 8:
            ys, xs = np.nonzero(m)
            cov = np.cov(np.stack([xs - xs.mean(), ys - ys.mean()]))
            evals, evecs = np.linalg.eigh(cov)
            major = evecs[:, 1]
            ang_major = np.arctan2(major[1], major[0])
            want = (phi + np.pi / 2) % np.pi
            d = abs(float(np.mod(ang_major - want + np.pi / 2, np.pi) - np.pi / 2))
            check(f"ramp phi={phi} drawn ring major axis == phi+pi/2 (mod pi)", d, 0.15)


def test_aspect_ratio_and_clamp():
    # ADR-5: aspect = clamp(sqrt(l1/l2), 1, max_aspect); ratio 4 -> aspect 2.
    # ratio < 1 is a non-SPD/ill-decoded tensor: the max(ratio,1) floor keeps
    # aspect 1 (same neutral as isotropic), matching plan ADR-5's guard.
    # jxx/jxy/jyy chosen so the EIGEN-value ratio is the target: diagonal
    # tensors J = diag(jxx, jyy) give l1=max, l2=min.
    for ratio, ma, want in ((4.0, 8.0, 2.0), (4.0, 1.5, 1.5),
                            (1.0 / 4.0, 8.0, 2.0), (100.0, 8.0, 8.0),
                            (1.0, 8.0, 1.0)):
        # ratio >= 1 -> diag(ratio, 1); ratio < 1 -> diag(1, 1/ratio)
        # (a swapped diagonal flips the axis, not the aspect)
        pair = (ratio, 1.0) if ratio >= 1.0 else (1.0, 1.0 / ratio)
        tex = tensor_tex(4, 4, F32(pair[0]), F32(0.0), F32(pair[1]))
        t_s = g.sample(tex, F32(0.5), F32(0.5))
        _, _, _, aspect = decode_cells(t_s, ma)
        got = float(aspect[()])
        note(f"ratio {ratio} max_aspect {ma} -> aspect", got)
        check(f"aspect ratio {ratio} clamp {ma}", abs(got - want), 2e-4)


def test_gain_free_identity():
    tex1 = ramp_tensor(phi=F32(0.7), strength=F32(1.0))
    tex2 = ramp_tensor(phi=F32(0.7), strength=F32(10.0))
    o1 = glyph(tex1)
    o2 = glyph(tex2)
    # with the same tint (no source), the renderings must be identical:
    # axis and aspect are strength-blind (ADR-5)
    err = float(np.abs(o1 - o2)[INTERIOR].max())
    note("gain x10 render delta", err)
    check("gain-free identity (x10 strength)", err, 1e-5)


def test_zero_tensor_renders_empty():
    tex = tensor_tex(H, W, F32(0.0), F32(0.0), F32(0.0))   # unconnected-wire contents
    out = glyph(tex)
    check("all-zeros tensor renders empty (gate catches phantom)",
          float(np.abs(out[..., :3]).max()), 0.0)
    # even at gate 0 the eps_trace floor holds
    out0 = glyph(tex, gate=0.0)
    check("all-zeros tensor empty at gate 0", float(np.abs(out0[..., :3]).max()), 0.0)


def test_gate_floor():
    tex, _, _, _ = rand_tensor(seed=2)
    on = glyph(tex, gate=0.05)
    off = glyph(tex, gate=1e9)
    check("huge gate kills all marks", float(np.abs(off[..., :3]).max()), 0.0)
    check("default gate draws something", 0.0 if (on[..., 0] > 0.5).any() else 1.0, 0)


def test_isotropic_draws_aspect_one():
    tex = tensor_tex(4, 4, F32(0.5), F32(0.0), F32(0.5))
    t_s = g.sample(tex, F32(0.5), F32(0.5))
    _, _, theta, aspect = decode_cells(t_s, 8.0)
    note("isotropic cell aspect", float(aspect[()]))
    check("isotropic-but-traceable cell aspect == 1", float(abs(aspect[()] - 1.0)), 1e-5)
    # the rendered circle is rotation-invariant, so the undefined theta
    # cannot leak into the picture: any theta must give the same cover
    cell = (slice(1, 15), slice(1, 15))
    out = glyph(tensor_tex(H, W, F32(0.5), F32(0.0), F32(0.5)), scale=0.8)
    check("isotropic cell draws a mark", 0.0 if (out[cell][..., 0] > 0.5).any() else 1.0, 0)


def test_line_field_pi_invariance():
    # a line at theta and theta+pi are the same structure: rotate the source
    # texture by pi (rot180) and rotate the output back -- identical.
    tex, _, _, _ = rand_tensor(seed=3)
    out_a = glyph(tex)
    rot = np.ascontiguousarray(np.rot90(tex, 2))
    out_b = np.rot90(glyph(rot), -2)
    err = float(np.abs(out_a - out_b)[INTERIOR].max())
    note("rot180 glyph field delta", err)
    check("line-field pi invariance", err, 1e-4)


def test_lattice_cell_centres():
    nx, ny, _, _ = g.grid(H, W)
    cu = (np.floor(nx * F32(GRID)) + F32(0.5)) / F32(GRID)
    expect_u = np.floor(nx * F32(GRID)) * F32(1.0 / GRID) + F32(0.5 / GRID)
    err = float(np.abs(cu - expect_u).max())
    check("cell centre formula", err, 0.0)
    # every drawn pixel lies within scale*cellsize/2 (+ 1.5px falloff) of its
    # own cell centre -- marks never bleed into neighbouring cells
    tex, _, _, _ = rand_tensor(seed=4)
    out = glyph(tex)
    cw = W // GRID
    ys, xs = np.nonzero(out[..., 0] > 0.5)
    cell_x = xs // cw
    cell_y = ys // cw
    cx = (cell_x.astype(F32) + F32(0.5)) * F32(cw) - F32(0.5)
    cy = (cell_y.astype(F32) + F32(0.5)) * F32(cw) - F32(0.5)
    rad = F32(DEF['scale'] * cw / 2 + 2.0)
    dmax = float(np.hypot(xs - cx, ys - cy).max())
    check("marks confined to their cells", dmax, float(rad))
    # and the mark is centred: per-cell drawn-pixel centroid near the centre
    cent = out[..., 0] > 0.5
    worst = 0.0
    for iy in range(GRID):
        for ix in range(GRID):
            block = cent[iy * cw:(iy + 1) * cw, ix * cw:(ix + 1) * cw]
            if block.sum() > 4:
                ys, xs = np.nonzero(block)
                d = np.hypot(ys.mean() - (cw - 1) / 2, xs.mean() - (cw - 1) / 2)
                worst = max(worst, float(d))
    note("worst per-cell centroid offset (px, ellipse ring bias ok)", worst)
    check("marks centred in cells", worst, cw / 4)


def test_cover_reference_values():
    rmaj = F32(0.8 * (1.0 / GRID) * 0.5)
    hw = F32(0.5 * 0.15) * rmaj
    soft = F32(0.1) * rmaj
    cov_on = F32(1.0) - sm(hw, hw + soft, F32(hw))          # at the band edge
    cov_out = F32(1.0) - sm(hw, hw + soft, F32(hw + soft))  # faded out
    cov_mid = F32(1.0) - sm(hw, hw + soft, F32(hw + soft / 2))
    check("cover 1 inside band", float(abs(cov_on - 1.0)), 1e-6)
    check("cover 0 past falloff", float(abs(cov_out - 0.0)), 1e-6)
    note("cover mid-falloff", float(cov_mid))
    check("cover mid-falloff ~0.5", float(abs(cov_mid - 0.5)), 1e-3)


def test_unconnected_source_neutral_ink():
    tex, _, _, _ = rand_tensor(seed=5)
    out = glyph(tex, source=np.zeros((H, W, 4), F32))
    lit = (out[..., 0] > 0.5) & (out[..., 1] > 0.5) & (out[..., 2] > 0.5)
    check("unconnected source -> untinted (white ink) glyphs",
          0.0 if lit.any() else 1.0, 0)


def test_bypass_passthrough():
    tex, _, _, _ = rand_tensor(seed=6)
    src = np.random.default_rng(9).uniform(0, 1, (H, W, 4)).astype(F32)
    src[..., 3] = 1.0
    out = glyph(tex, source=src, bypass_gate=1.0)
    check("bypass passthrough == source", float(np.abs(out[..., :3] - src[..., :3]).max()), 1e-6)


# --- TG009: mutation check ---------------------------------------------------

def test_mutation_dropped_g_offset_is_detected():
    """Plausible bug: decode G without the 0.5 offset (jxy2_s = G*4).
    The ramp-angle check must fail."""
    tex = ramp_tensor(phi=F32(0.6))
    h, w = tex.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    cu = (np.floor(nx * F32(GRID)) + F32(0.5)) / F32(GRID)
    cv = (np.floor(ny * F32(GRID)) + F32(0.5)) / F32(GRID)
    t_s = g.sample(tex, cu, cv)
    r, gg, b = t_s[..., 0], t_s[..., 1], t_s[..., 2]
    good = F32(0.5) * np.arctan2((gg - F32(0.5)) * F32(4.0), r - b)
    bad = F32(0.5) * np.arctan2(gg * F32(4.0), r - b)
    e_good = float(_angdiff_mod_pi(good[INTERIOR], F32(0.6)).max())
    e_bad = float(_angdiff_mod_pi(bad[INTERIOR], F32(0.6)).max())
    note("good worst angle error", e_good)
    note("mutated (no 0.5 offset on G) worst angle error", e_bad)
    if not (e_bad > 0.1 and e_good < 1e-4):
        raise AssertionError(f"mutation not detected: good={e_good:.3e}, bad={e_bad:.3e}")
    print("    ok   dropped 0.5 offset on G is caught by the ramp-angle check")


if __name__ == "__main__":
    sys.exit(run(globals()))