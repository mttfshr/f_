"""
bench_caustic_sheets.py -- tier 2 (module bench) for the f_caustic sheets mode (.specify/f_caustic_scatter/spec.md,
Acceptance criteria 3; tasks T016 onward). Part 1 runs the STANDALONE scene
(tests/bench/caustic_sheets_standalone.maxpat, made by src/f_caustic/scatter_scene.py --standalone), so the module
is not touched until the sheets path is proven.

Outlets of the standalone: 0 the float32 capture (the light), 1 the composite, 2 the caustic layer. Inputs: the source
texture (inlet 0, with the control messages) and the vecfield (inlet 1). The bench's `bypassed` capture is taken after
the parameters (this bpatcher ignores bypass), so it is the capture to read.
Orientation: the inputs reach the GPU as matrices, so the mirror runs with the flips found in spike S0b
(up_flip, out_flip) and the shader's baked fy = -1.

Needs Max with tests/bench/bench_module.maxpat open and every Vsynth performance patch CLOSED.
Run:  tests/bench.sh tests/bench_caustic_sheets.py
"""
import sys

import numpy as np

import benchclient as bc
import caustic_runner as cr
import scatter_mirror as sm
import scatter_truth as st
from harness import check, note, run

STANDALONE = "caustic_sheets_standalone.maxpat"
F32 = np.float32
K, EXPO = 2.0, 0.7            # codebox_sheets.gen's internal constants


def go(inputs, params):
    res, out = cr.run(inputs, params, STANDALONE, n_out=3, warmup=40)
    errs = [e for e in (res.get("errors") or []) if "getattr" not in e]
    assert not errs, f"max errors: {errs[:3]}"
    arrs = out.get("bypassed")
    assert arrs and all(k in arrs for k in (1, 2, 3)), f"captures missing: {sorted(arrs) if arrs else None}"
    return arrs[1], arrs[2], arrs[3]          # light, composite, layer


def explicit(scale, r, n, weight=None, extra=()):
    """The explicit control messages (the `detail` ladder's building blocks), n LAST."""
    w = (r / n) ** 2 if weight is None else weight
    return [["scale", float(scale)], ["r", r], ["weight", float(w)], *[list(e) for e in extra], ["n", n]]


def mirror(src, fld, scale, n, r, w=None):
    w = (r / n) ** 2 if w is None else w
    return sm.ref_scatter(src, fld, scale, n, w, True, True, r=r, fy=-1.0)


def test_T016_renders_light_and_the_shader_loads():
    """A non-black capture proves the shader loaded (the bench does not report jit.gl.shader load failures)."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    light, comp, layer = go([sm.white(), tex], [["scale", dstar], ["detail", 5]])
    note("capture shape", light.shape[0])
    note("capture max", light[..., :3].max())
    note("capture mean (a uniform source of 1 has mean 1)", light[..., :3].mean())
    assert light.shape[0] == 1024, f"detail 5 should capture 1024^2, got {light.shape}"
    assert light[..., :3].max() > 2.0, "the capture is black or flat: the shader did not draw"


def test_T016_identity_at_zero_scale():
    src, fld = sm.gradient_src(), st.field_texture()
    r, n = 256, 1024
    light, _, _ = go([src, fld], explicit(0.0, r, n))
    check("scale = 0: relative error vs the mirror", sm.rel_err(light, mirror(src, fld, 0.0, n, r)), 1e-3)


def test_T016_energy_conserved():
    src, fld = sm.gradient_src(), sm.uniform_field(0.05, -0.03)
    r, n, w = 256, 300, 0.7
    light, _, _ = go([src, fld], explicit(1.0, r, n, w))
    ref = mirror(src, fld, 1.0, n, r, w)
    got, exp = float(light[..., 0].sum()), float(ref[..., 0].sum())
    note("GPU sum / mirror sum (R)", got / exp)
    check("energy: |GPU sum - mirror sum| / mirror sum", abs(got - exp) / exp, 1e-3)


def test_T016_points_on_one_pixel_sum():
    r, n = 256, 64
    light, _, _ = go([sm.white(), sm.point_field(0.5, 0.5, 1.0)], explicit(1.0, r, n, 1.0))
    total = float(light[..., 0].sum())
    c = r // 2
    block = float(light[c - 2:c + 2, c - 2:c + 2, 0].sum())
    note("sum of all points", total)
    check("N points on one pixel: |sum - N| / N", abs(total - n * n) / (n * n), 1e-3)
    check("share of the energy outside a 4 x 4 pixel block", 1.0 - block / total, 1e-3)


def test_T016_orientation_matches_the_matrix_space_mirror():
    """Spike S0b's design: an ASYMMETRIC shift (a gradient source, a uniform field (0.3, 0.5)) tells the four
    (up_flip, out_flip) conventions apart. The periodic glass cannot: its mirror images coincide, so it correlates
    at 1.000 with the wrong convention too. The shader bakes fy = -1, which goes with both flips."""
    src, fld = sm.gradient_src(), sm.uniform_field(0.3, 0.5)
    r, n, d = 256, 256, 0.25
    light, _, _ = go([src, fld], explicit(d, r, n, 1.0))
    errs = {}
    for up in (False, True):
        for out in (False, True):
            errs[(up, out)] = sm.rel_err(light, sm.ref_scatter(src, fld, d, n, 1.0, up, out, r=r, fy=-1.0 if (up and out) else 1.0))
            note(f"rel error vs the mirror, up_flip={int(up)} out_flip={int(out)}", errs[(up, out)])
    # (1, 1) with fy -1 and (0, 0) with fy +1 are the SAME physical convention (a double flip undoes itself), so both
    # sit at the residual; the runner-up is taken over the two conventions that genuinely differ. The residual
    # (2.6e-3, the same as spike S0b) is the border clipping of this shifted configuration, not an orientation error.
    best = errs[(True, True)]
    runner_up = min(errs[(False, True)], errs[(True, False)])
    check("the baked orientation: rel error vs the (up 1, out 1, fy -1) mirror", best, 4e-3)
    assert runner_up > 0.1, f"the orientations are not distinguishable here (runner-up error {runner_up:.3f})"


def test_T016_truth_agreement_at_step_5():
    tex, dstar = st.field_texture(), st.first_fold_distance()
    for frac in (1.0, 3.5):
        d = frac * dstar
        light, _, _ = go([sm.white(), tex], [["scale", d], ["detail", 5]])
        a = sm.box_down(light[..., 0].astype(np.float64), light.shape[0] // st.NB)
        mask = st.interior(d)
        rr = st.pearson(a[mask], st.truth(d, m=2048)[mask])
        note(f"r vs photon-counting truth at {frac} d*", rr)
        check(f"1 - r vs truth at {frac} d* (spec floor: r >= 0.995)", 1.0 - rr, 2e-3)


def gradient_wide(w=1920, h=1080):
    nx = (np.arange(w, dtype=F32) + 0.5) / w
    ny = (np.arange(h, dtype=F32) + 0.5) / h
    a = np.zeros((h, w, 4), F32)
    a[..., 0], a[..., 1], a[..., 2], a[..., 3] = nx[None, :], ny[:, None], 0.25, 1.0
    return a


def test_T016_tone_and_upscale_follow_the_source_size():
    """The composite stage follows the SOURCE's size (@adapt 1): a 1920 x 1080 source gives a 1920 x 1080 output;
    the (square, smaller) capture is upscaled bilinearly and tone mapped (the `s10` check, promoted)."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    src = gradient_wide()
    light, comp, layer = go([src, tex], [["scale", dstar], ["gain", 0.5], ["mix_pct", 100.0], ["detail", 3]])
    assert comp.shape[:2] == (1080, 1920), f"output should follow the source: {comp.shape}"
    ex = sm.tone(sm.resize_bilinear(light.astype(np.float64), 1080, 1920)[..., :3], lev=0.5 * K, expo=EXPO)
    s3 = src[..., :3].astype(np.float64)
    ref_comp = np.clip(s3 + ex, 0.0, 1.0)
    # tolerance: the hardware's bilinear uses 8-bit weights, visible at a NON-integer scale (768 -> 1920 x 1080); the
    # integer 2x codebox check (tests/bench_caustic_codebox.py) agrees to 1e-7, and spike S10 saw 4.1e-3 here
    check("layer: max |GPU - NumPy|", float(np.abs(layer[..., :3] - np.clip(ex, 0, 1)).max()), 5e-3)
    check("composite: max |GPU - NumPy|", float(np.abs(comp[..., :3] - ref_comp).max()), 5e-3)
    a, b = layer[..., :3].ravel().astype(np.float64), np.clip(ex, 0, 1).ravel()
    check("layer: 1 - Pearson r vs NumPy", 1.0 - float(np.corrcoef(a, b)[0, 1]), 1e-4)


if __name__ == "__main__":
    cr.ensure_bench()
    sys.exit(run(globals()))
