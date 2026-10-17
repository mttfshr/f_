"""
test_tf_tensormap.py -- tier-1 NumPy mirror of the planned f_tf_tensormap
producer (.specify/f_tf_tensormap/{spec,plan,tasks}.md, Phase 0 T003-T010).

Mirrors the 3-stage-plus-split pass chain as GenExpr shaders, sampling through
gpu_sim.nearest (clamp-to-edge) exactly as the codeboxes will:

  stage A    Rec.601 luma -> 3x3 Sobel -> (gx*gx, gx*gy, gy*gy)
  stage B    bounded-loop box smooth, compile-time R_MAX, weight
             step(abs(i), radius), normalized by actual tap count (h, then v)
  stage C    closed-form 2x2 eigen -> outlet 0 (raw tensor) and outlet 1
             (packed cos2t, sin2t, trace, coherence)

Ground truth is independent of the mirror: np.linalg.eigh on the tensor,
analytic ramp angles, invariants, and the spike's edge-pad box smooth.
A mutation check flips the sign of Jxy and confirms the ramp-angle check
actually fails.

Run:  tests/run.sh tests/test_tf_tensormap.py
"""
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

from harness import check, note, run  # noqa: E402
import gpu_sim as g  # noqa: E402
import spike_structure_tensor_range as spike  # noqa: E402

F32 = np.float32
R_MAX = 8            # provisional (T016/T017 pick the real one)
EPS_TRACE = F32(1e-6)  # provisional (T019)
STRENGTH = F32(12.0)   # provisional default
H = W = 64


# --- mirror shaders ----------------------------------------------------

def _rgba_from_luma(luma):
    tex = g.texture(*luma.shape)
    tex[..., 0] = tex[..., 1] = tex[..., 2] = luma
    tex[..., 3] = F32(1.0)
    return tex


def _luma601(tex):
    return (F32(0.299) * tex[..., 0] + F32(0.587) * tex[..., 1]
            + F32(0.114) * tex[..., 2]).astype(F32)


def stage_a(src):
    """src: RGBA texture. Returns RGBA (gx^2, gx*gy, gy^2, 1)."""
    h, w = src.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    dx, dy = F32(1.0 / w), F32(1.0 / h)

    def L(ox, oy):
        return _luma601(g.nearest(src, nx + F32(ox) * dx, ny + F32(oy) * dy))

    tl, tc, tr = L(-1, -1), L(0, -1), L(1, -1)
    ml, mr = L(-1, 0), L(1, 0)
    bl, bc, br = L(-1, 1), L(0, 1), L(1, 1)
    gx = (-tl + tr) + F32(-2) * ml + F32(2) * mr + (-bl + br)
    gy = (-tl - F32(2) * tc - tr) + (bl + F32(2) * bc + br)
    out = g.texture(h, w)
    out[..., 0] = gx * gx
    out[..., 1] = gx * gy
    out[..., 2] = gy * gy
    out[..., 3] = F32(1.0)
    return g.store_float32(out)


def stage_b(tex, radius, axis, r_max=R_MAX):
    """One separable smoothing pass. axis 0 = horizontal, 1 = vertical."""
    h, w = tex.shape[:2]
    nx, ny, _, _ = g.grid(h, w)
    acc = np.zeros((h, w, 4), F32)
    count = np.zeros((h, w), F32)
    for i in range(-r_max, r_max + 1):
        wt = F32(1.0) if abs(i) <= radius else F32(0.0)
        if axis == 0:
            s = g.nearest(tex, nx + F32(i) / F32(w), ny)
        else:
            s = g.nearest(tex, nx, ny + F32(i) / F32(h))
        acc += wt * s
        count += wt
    count = np.maximum(count, F32(1.0))
    return g.store_float32(acc / count[..., None])


def eigen_closed(Jxx, Jxy, Jyy):
    trace = Jxx + Jyy
    diff = Jxx - Jyy
    root = np.sqrt(diff * diff + F32(4) * Jxy * Jxy)
    return trace, diff, root


def stage_c(tex, strength=STRENGTH, eps=EPS_TRACE, flip_jxy=False):
    """Returns (outlet0, outlet1) RGBA textures."""
    Jxx, Jxy, Jyy = tex[..., 0], tex[..., 1], tex[..., 2]
    if flip_jxy:
        Jxy = -Jxy
    trace, diff, root = eigen_closed(Jxx, Jxy, Jyy)
    theta = F32(0.5) * np.arctan2(F32(2) * Jxy, diff)
    iso = trace < eps

    o0 = g.texture(*Jxx.shape)
    o0[..., 0] = Jxx * strength
    o0[..., 1] = Jxy * strength * F32(0.5) + F32(0.5)
    o0[..., 2] = Jyy * strength
    o0[..., 3] = F32(1.0)

    o1 = g.texture(*Jxx.shape)
    safe_trace = np.maximum(trace, eps)
    o1[..., 0] = np.cos(F32(2) * theta) * F32(0.5) + F32(0.5)
    o1[..., 1] = np.sin(F32(2) * theta) * F32(0.5) + F32(0.5)
    o1[..., 2] = np.clip(trace * strength, 0, 1)
    o1[..., 3] = np.clip(root / safe_trace, 0, 1)
    o1[root < eps, 0:2] = F32(0.5)   # direction undefined (equal eigenvalues)
    o1[iso] = np.array([0.5, 0.5, 0.0, 0.0], F32)
    return g.store_float32(o0), g.store_float32(o1)


def chain(src, radius, **kw):
    a = stage_a(src)
    b = stage_b(stage_b(a, radius, 0), radius, 1)
    return b, stage_c(b, **kw)


def tensor_stage_only(luma, radius):
    """Smoothed tensor from the mirror, unscaled."""
    b, _ = chain(_rgba_from_luma(luma), radius)
    return b[..., 0], b[..., 1], b[..., 2]


def _decode_axis(o1):
    """Orientation angle (mod pi) from outlet 1 R/G."""
    c2 = (o1[..., 0] - F32(0.5)) * F32(2)
    s2 = (o1[..., 1] - F32(0.5)) * F32(2)
    return F32(0.5) * np.arctan2(s2, c2)


def _angdiff_mod_pi(a, b):
    d = np.abs(a - b) % np.pi
    return np.minimum(d, np.pi - d)


INTERIOR = (slice(12, -12), slice(12, -12))


# --- T003 stage A ------------------------------------------------------

def test_stage_a_matches_spike_sobel():
    rng = np.random.default_rng(1)
    luma = rng.uniform(0, 1, (H, W)).astype(F32)
    a = stage_a(_rgba_from_luma(luma))
    gx, gy = spike.sobel_gradient(luma)
    check("A gx^2 max abs err", float(np.abs(a[..., 0] - gx * gx).max()), 1e-4)
    check("A gx*gy max abs err", float(np.abs(a[..., 1] - gx * gy).max()), 1e-4)
    check("A gy^2 max abs err", float(np.abs(a[..., 2] - gy * gy).max()), 1e-4)


def test_stage_a_uses_rec601_luma():
    src = g.texture(H, W)
    nx, _, _, _ = g.grid(H, W)
    src[..., 0] = nx            # red ramp only
    src[..., 3] = F32(1.0)
    a = stage_a(src)
    # pure red ramp: luma slope = 0.299 per unit x; Sobel gx = 8*0.299/W
    expect = (F32(8) * F32(0.299) / F32(W)) ** 2
    check("A Rec.601 red weight", float(a[20, 30, 0] / expect - 1), 1e-3)


# --- T004 stage B ------------------------------------------------------

def test_stage_b_matches_spike_box_smooth():
    rng = np.random.default_rng(2)
    luma = rng.uniform(0, 1, (H, W)).astype(F32)
    for r in (0, 1, 3, R_MAX):
        Jxx, Jxy, Jyy = tensor_stage_only(luma, r)
        sxx, sxy, syy = spike.structure_tensor(luma, r)
        err = max(float(np.abs(Jxx - sxx).max()),
                  float(np.abs(Jxy - sxy).max()),
                  float(np.abs(Jyy - syy).max()))
        check(f"B radius {r} vs spike (incl. edges)", err, 1e-3)


def test_stage_b_radius_above_rmax_saturates():
    rng = np.random.default_rng(3)
    luma = rng.uniform(0, 1, (H, W)).astype(F32)
    a = stage_a(_rgba_from_luma(luma))
    at_max = stage_b(a, R_MAX, 0)
    over = stage_b(a, R_MAX + 5, 0)
    check("B radius>R_MAX == R_MAX", float(np.abs(at_max - over).max()), 1e-7)


# --- T005/T006 stage C vs ground truth --------------------------------

def test_stage_c_vs_eigh():
    rng = np.random.default_rng(4)
    n = 2000
    # random PSD tensors: J = A^T A summed
    v = rng.normal(size=(n, 2, 2)).astype(F32)
    Jxx = (v[:, 0, 0] ** 2 + v[:, 0, 1] ** 2).astype(F32)
    Jyy = (v[:, 1, 0] ** 2 + v[:, 1, 1] ** 2).astype(F32)
    Jxy = (v[:, 0, 0] * v[:, 1, 0] + v[:, 0, 1] * v[:, 1, 1]).astype(F32)
    tex = np.zeros((1, n, 4), F32)
    tex[0, :, 0], tex[0, :, 1], tex[0, :, 2] = Jxx, Jxy, Jyy
    trace, diff, root = eigen_closed(Jxx, Jxy, Jyy)
    l1 = 0.5 * (trace + root)
    l2 = 0.5 * (trace - root)
    M = np.stack([np.stack([Jxx, Jxy], -1), np.stack([Jxy, Jyy], -1)], -2)
    w_ = np.linalg.eigvalsh(M.astype(np.float64))
    check("lambda1 vs eigh", float(np.abs(l1 - w_[:, 1]).max()), 1e-4)
    check("lambda2 vs eigh", float(np.abs(l2 - w_[:, 0]).max()), 1e-4)

    _, o1 = stage_c(tex)
    ev = np.linalg.eigh(M.astype(np.float64))[1][:, :, 1]   # dominant vector
    ref = np.arctan2(ev[:, 1], ev[:, 0])
    got = _decode_axis(o1)[0]
    ok = trace > 1e-3
    err = _angdiff_mod_pi(got[ok].astype(np.float64), ref[ok])
    check("theta vs eigh dominant axis (rad, max)", float(err.max()), 2e-3)
    coh_ref = (w_[:, 1] - w_[:, 0]) / np.maximum(w_[:, 1] + w_[:, 0], 1e-12)
    check("coherence vs eigh", float(np.abs(o1[0, ok, 3] - coh_ref[ok]).max()), 1e-4)


def test_outlet0_encoding():
    tex = np.zeros((1, 3, 4), F32)
    tex[0, 0, :3] = (0.01, 0.0, 0.01)
    tex[0, 1, :3] = (0.02, -0.01, 0.01)
    tex[0, 2, :3] = (0.0, 0.0, 0.0)
    o0, _ = stage_c(tex)
    check("o0 zero tensor G==0.5", float(o0[0, 2, 1] - 0.5), 1e-7)
    check("o0 zero tensor A==1", float(o0[0, 2, 3] - 1.0), 1e-7)
    check("o0 R=Jxx*s", float(o0[0, 1, 0] - 0.02 * 12), 1e-6)
    check("o0 G=Jxy*s*.5+.5", float(o0[0, 1, 1] - (-0.01 * 12 * 0.5 + 0.5)), 1e-6)


# --- T007 known-angle ramps -------------------------------------------

def _ramp(phi_deg):
    nx, ny, _, _ = g.grid(H, W)
    phi = np.deg2rad(phi_deg)
    return (F32(0.5) + F32(0.3) * (np.cos(phi) * nx + np.sin(phi) * ny)).astype(F32)


def _ramp_angle_err(flip=False):
    worst = 0.0
    for phi in (0, 20, 45, 70, 90, 110, 135, 160):
        luma = _ramp(phi)
        _, (o0, o1) = chain(_rgba_from_luma(luma), 3, flip_jxy=flip)
        got = _decode_axis(o1)[INTERIOR]
        err = _angdiff_mod_pi(got, np.deg2rad(phi))
        worst = max(worst, float(err.max()))
    return worst


def test_ramp_gradient_direction():
    worst = _ramp_angle_err()
    note("ramp worst angle error (rad)", worst)
    check("ramp angle vs analytic", worst, 1e-3)


def test_ramp_coherence_is_one():
    for phi in (0, 30, 77):
        _, (_, o1) = chain(_rgba_from_luma(_ramp(phi)), 3)
        c = o1[..., 3][INTERIOR]
        check(f"ramp {phi} deg coherence-1", float(np.abs(c - 1).max()), 1e-3)


# --- T008 invariants ---------------------------------------------------

def test_flat_is_zero_tensor():
    luma = np.full((H, W), F32(0.4))
    _, (o0, o1) = chain(_rgba_from_luma(luma), 2)
    check("flat o0 R", float(np.abs(o0[..., 0]).max()), 1e-7)
    check("flat o0 G-0.5", float(np.abs(o0[..., 1] - 0.5).max()), 1e-7)
    check("flat o0 B", float(np.abs(o0[..., 2]).max()), 1e-7)
    check("flat o1 R,G == .5", float(np.abs(o1[..., :2] - 0.5).max()), 1e-7)
    check("flat o1 A == 0", float(np.abs(o1[..., 3]).max()), 1e-7)


def test_black_input_is_zero_tensor():
    _, (o0, o1) = chain(g.texture(H, W), 2)
    check("black o0 == (0,.5,0,1)", float(np.abs(o0 - np.array([0, .5, 0, 1], F32)).max()), 1e-7)
    check("black o1 == (.5,.5,0,0)", float(np.abs(o1 - np.array([.5, .5, 0, 0], F32)).max()), 1e-7)


def test_vertical_edge_trace_and_axis():
    luma = spike.edge_content(H, W, 1.0)
    # radius 0: trace at the edge = gx^2 = 16 (Sobel of unit step = 4)
    _, (o0, _) = chain(_rgba_from_luma(luma), 0, strength=F32(1))
    tr = o0[H // 2, W // 2 - 1, 0] + o0[H // 2, W // 2 - 1, 2]
    check("edge trace at radius 0", float(tr - 16.0), 1e-4)
    _, (_, o1) = chain(_rgba_from_luma(luma), 2)
    ang = _decode_axis(o1)[H // 2, W // 2]
    check("edge gradient axis is x", float(_angdiff_mod_pi(ang, 0.0)), 1e-3)
    check("edge coherence", float(o1[H // 2, W // 2, 3] - 1.0), 1e-3)


def test_coherence_contrast_independent():
    base = spike.noise_content(H, W, coarse=6, seed=5)
    cs = []
    for k in (1.0, 0.25, 0.05):
        luma = (F32(0.5) + (base - F32(0.5)) * F32(k)).astype(F32)
        _, (_, o1) = chain(_rgba_from_luma(luma), 3)
        cs.append(o1[..., 3][INTERIOR])
    check("coherence 1.0 vs 0.25", float(np.abs(cs[0] - cs[1]).max()), 2e-3)
    check("coherence 1.0 vs 0.05", float(np.abs(cs[0] - cs[2]).max()), 2e-3)


def test_rotation_invariance_of_trace():
    base = spike.noise_content(H, W, coarse=6, seed=6)
    t_a = tensor_stage_only(base, 3)
    rot = np.ascontiguousarray(np.rot90(base))
    t_b = tensor_stage_only(rot, 3)
    tr_a = (t_a[0] + t_a[2])[INTERIOR]
    tr_b = np.rot90(t_b[0] + t_b[2], -1)[INTERIOR]
    check("trace rot90 invariance", float(np.abs(tr_a - tr_b).max()), 1e-4)


def test_line_field_axis_invariant_to_sign():
    # sin stripes: gradient flips sign every half period; outlet-1 axis must
    # be constant (x) everywhere in the interior -- the reason for doubling.
    nx, _, _, _ = g.grid(H, W)
    luma = (F32(0.5) + F32(0.3) * np.sin(nx * F32(2 * np.pi) * 3)).astype(F32)
    _, (_, o1) = chain(_rgba_from_luma(luma), 2)
    ang = _decode_axis(o1)[INTERIOR]
    ok = o1[..., 3][INTERIOR] > 0.5
    check("stripes axis constant", float(_angdiff_mod_pi(ang[ok], 0.0).max()), 2e-3)


def test_trace_scales_as_contrast_squared():
    base = spike.noise_content(H, W, coarse=6, seed=7)
    ta = tensor_stage_only(base, 3)
    tr1 = (ta[0] + ta[2])[INTERIOR]
    for k in (0.5, 0.1):
        luma = (F32(0.5) + (base - F32(0.5)) * F32(k)).astype(F32)
        tk = tensor_stage_only(luma, 3)
        trk = (tk[0] + tk[2])[INTERIOR]
        check(f"trace at contrast {k} == k^2 * trace",
              float(np.abs(trk - F32(k * k) * tr1).max()), 1e-4)


def test_rotate_pi_leaves_outlet1_unchanged():
    base = spike.noise_content(H, W, coarse=6, seed=8)
    _, (_, o1a) = chain(_rgba_from_luma(base), 3)
    rot = np.ascontiguousarray(np.rot90(base, 2))
    _, (_, o1b) = chain(_rgba_from_luma(rot), 3)
    back = np.rot90(o1b, -2)
    check("rot180 outlet1 unchanged",
          float(np.abs(o1a - back)[INTERIOR].max()), 1e-4)


def test_rotate_90_negates_cos_sin_2theta():
    base = spike.noise_content(H, W, coarse=6, seed=9)
    _, (_, o1a) = chain(_rgba_from_luma(base), 3)
    rot = np.ascontiguousarray(np.rot90(base))
    _, (_, o1b) = chain(_rgba_from_luma(rot), 3)
    back = np.rot90(o1b, -1)
    ra = (o1a[..., :2] - F32(0.5))[INTERIOR]
    rb = (back[..., :2] - F32(0.5))[INTERIOR]
    check("rot90 negates (cos2t, sin2t)", float(np.abs(ra + rb).max()), 1e-4)
    check("rot90 keeps trace and coherence",
          float(np.abs(o1a[..., 2:] - back[..., 2:])[INTERIOR].max()), 1e-4)


# --- T010 mutation check ----------------------------------------------

def test_mutation_flipped_jxy_is_detected():
    good = _ramp_angle_err(flip=False)
    bad = _ramp_angle_err(flip=True)
    note("good worst angle error", good)
    note("mutated (Jxy flipped) worst angle error", bad)
    if not (bad > 0.1 and good < 1e-3):
        raise AssertionError(
            f"mutation not detected: good={good:.3e}, flipped-Jxy={bad:.3e}")
    print("    ok   Jxy sign flip is caught by the ramp-angle check")


if __name__ == "__main__":
    sys.exit(run(globals()))
