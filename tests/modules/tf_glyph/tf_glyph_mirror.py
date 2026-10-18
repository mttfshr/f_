"""
tf_glyph_mirror.py -- NumPy mirror of the tf_glyph shader: the functions (and the constants and
fixtures they need) that tests/modules/tf_glyph/bench_tf_glyph.py imports. Extracted
from test_tf_glyph.py in Phase C, 2026-10-18; the tests stay there.
"""
import numpy as np
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
