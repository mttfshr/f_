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
import os
import sys

import numpy as np

from pathlib import Path

import benchclient as bc
import caustic_runner as cr
import modulebench as mb
import record_caustic_baseline as rb
import scatter_mirror as sm
import scatter_truth as st
from harness import check, note, run

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src" / "f_caustic"))
import scatter_scene as sc                        # noqa: E402  (the `detail` ladder: one source of truth)

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


def step_of(i):
    r, ppp = sc.DETAIL[i - 1]
    n = int(round(r * ppp ** 0.5))
    return r, ppp, n, float(f"{(r / n) ** 2:.4f}")           # the ladder's messages write the weight with 4 decimals


def test_T019_detail_steps_equal_the_explicit_messages():
    """`detail N` must set exactly what the explicit messages set (the `s11` check, promoted)."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    src = sm.gradient_src()
    for i in range(1, 6):
        r, ppp, n, w = step_of(i)
        assert sc.detail_message(r, ppp) == f"r {r}, weight {w:.4f}, n {n}", sc.detail_message(r, ppp)
        a, _, _ = go([src, tex], explicit(dstar, r, n, w))
        b, _, _ = go([src, tex], [["scale", dstar], ["detail", i]])
        diff = float(np.abs(a.astype(np.float64) - b.astype(np.float64)).max())
        note(f"step {i} ({r}^2, {ppp} pts/px, n={n}): capture {b.shape[1]}x{b.shape[0]}, max|diff|", diff)
        assert b.shape[0] == r, f"step {i} should capture {r}^2, got {b.shape}"
        check(f"step {i}: max|explicit - detail|", diff, 0.0)


# Pearson r of each step against the 16-points-per-pixel reference at 1024^2, interior mask (spec table). A floor is
# the measured value rounded DOWN just below it; step 3 (768^2) was unmeasured and is measured here.
# measured 2026-10-07 (1 d* / 3.5 d*): step 1 .9929/.9026, 2 .9981/.9579, 3 .9990/.9820, 4 .9979/.9977, 5 .9992/.9998
FLOORS = {(1, 1.0): 0.99, (1, 3.5): 0.89, (2, 1.0): 0.995, (2, 3.5): 0.95, (3, 1.0): 0.998, (3, 3.5): 0.975,
          (4, 1.0): 0.995, (4, 3.5): 0.995, (5, 1.0): 0.998, (5, 3.5): 0.998}


def release_lattice():
    """A tiny job so Max drops the large lattice (the spike's stages end the same way)."""
    go([sm.white(), st.field_texture()], explicit(0.0, 256, 64))


def test_T020_quality_of_every_step_against_the_reference():
    try:
        _quality_of_every_step()
    finally:
        release_lattice()


def _quality_of_every_step():
    tex, dstar = st.field_texture(), st.first_fold_distance()
    for frac in (1.0, 3.5):
        d = frac * dstar
        ref, _, _ = go([sm.white(), tex], explicit(d, 1024, 4096))
        ref = ref[..., 0].astype(np.float64)
        mask = np.kron(st.interior(d), np.ones((4, 4), bool))
        for i in range(1, 6):
            r, ppp, n, w = step_of(i)
            cap, _, _ = go([sm.white(), tex], [["scale", d], ["detail", i]])
            c = cap[..., 0].astype(np.float64)
            up = sm.upscale(c, 1024 // r) if 1024 % r == 0 else sm.resize_bilinear(c[..., None], 1024, 1024)[..., 0]
            rr = st.pearson(up[mask], ref[mask])
            note(f"step {i} ({r}^2, {ppp}/px) at {frac} d*: r vs the reference / IoU {st.top_iou(up[mask], ref[mask]):.3f}", rr)
            floor = FLOORS.get((i, frac))
            if floor is not None:
                check(f"step {i} at {frac} d*: floor shortfall (r >= {floor})", max(0.0, floor - rr), 0.0)


def test_T021_the_default_step_fits_the_frame_budget():
    """Step 5 (the default look) holds the bench's 60 fps pacing. Everything below the cap is invisible to the bench,
    so this is a fits / does-not-fit check, NOT a cost measurement (the cost model is spike S6's: density-driven,
    timings vary up to 2x between runs; see optics_map.md). Each step is measured, only step 5 is asserted."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    for i in range(1, 6):
        ms = cr.period_ms([sm.white(), tex], [["scale", dstar], ["detail", i]], STANDALONE, n_out=3)
        note(f"step {i}: frame period ms (the cap is {cr.CAP_MS:.1f})", ms)
        # a stalled run gave -4417 ms here and "passed" (a negative period trivially fits the budget): refuse it
        assert 5.0 < ms < 100.0, f"step {i}: invalid frame period {ms:.1f} ms (a stalled bench?): not a measurement"
        if i == 5:
            check("step 5: frame period over the budget (ms above 1.15 x the cap)", max(0.0, ms - 1.15 * cr.CAP_MS), 0.0)


# ======================================================================= the REAL module (tasks T027, T028)
MODULE = "f_caustic.maxpat"
BASELINE = Path(__file__).resolve().parent / "baselines" / "f_caustic_soft.npz"


def module(settings, warmup=60):
    """The real f_caustic through the module bench; `settings` (a string or a list) sent by the wrapper, read 'base'."""
    res, out = cr.run([sm.gradient_src(512), st.field_texture()], [], MODULE, n_out=2, settings=settings, warmup=warmup)
    errs = [e for e in (res.get("errors") or []) if "getattr" not in e]
    assert not errs, f"max errors: {errs[:3]}"
    arrs = out.get("base")
    assert arrs and 1 in arrs and 2 in arrs, f"captures missing: {sorted(arrs) if arrs else None}"
    return arrs[1], arrs[2]


def vs_baseline(name, comp, layer):
    """0.0 when the captures are bit-identical to the recorded baseline, else the max |difference| of the 128^2 copies."""
    base = np.load(BASELINE)
    worst = 0.0
    for k, a in ((1, comp), (2, layer)):
        if rb.sha(a) == str(base[f"{name}_out{k}_sha"]):
            continue
        worst = max(worst, float(np.abs(rb.block_down(a) - base[f"{name}_out{k}_128"]).max()), 1e-12)
    return worst


def test_T027_soft_mode_is_bit_identical_to_the_baseline():
    """The module before the sheets mode existed (tests/baselines/f_caustic_soft.npz, recorded first): 5 parameter sets."""
    for name, values in rb.SETS.items():
        comp, layer = module(rb.settings_of(values))
        check(f"{name}: |module - baseline| (0 = bit-identical)", vs_baseline(name, comp, layer), 0.0)


ENABLE_JS = """
var m = moduleSubpatcher(), r = {};
collect(m, function (o) { return o.maxclass === "jit.gl.pix" || o.maxclass === "jit.gl.node" || o.maxclass === "jit.gl.mesh"; }, [])
  .forEach(function (o) { var n = String(o.getattr("name") || o.varname); r[o.maxclass + " " + n] = o.getattr("enable"); });
r;
"""


def enables():
    """{'jit.gl.pix caustic_pix': 1, ...}: the enable attribute of every GL object in the module just run."""
    return mb.bench_eval(ENABLE_JS)["value"]


def enabled(state, fragment):
    hits = [v for k, v in state.items() if fragment in k]
    assert hits, f"no object matching {fragment!r} in {sorted(state)}"
    return bool(hits[0])


def test_T028_soft_mode_leaves_the_sheets_branch_disabled():
    module(rb.settings_of(rb.SETS["B_wet"]))
    st_ = enables()
    note("enable state in soft mode", len(st_))
    assert enabled(st_, "caustic_pix"), st_
    for frag in ("caustic_sheets", "jit.gl.node", "jit.gl.mesh"):
        assert not enabled(st_, frag), f"{frag} should be disabled in soft mode: {st_}"


def test_T028_sheets_mode_through_the_module_equals_the_standalone():
    """Same scatter, same composite, selected by the gate: identical to the standalone's two outlets."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    d = 1.0 * dstar
    comp, layer = module(f"scale {d}, gain 0.5, mix_pct 100, mode 1", warmup=180)
    state = enables()
    # the soft stage stays enabled in sheets mode ON PURPOSE: the select stages render on its output (a disabled stage
    # emits nothing and they would starve; found here)
    assert enabled(state, "caustic_pix"), f"the soft stage must stay enabled (it triggers the select stages): {state}"
    for frag in ("caustic_sheets", "jit.gl.node", "jit.gl.mesh"):
        assert enabled(state, frag), f"{frag} should be enabled in sheets mode: {state}"
    _, s_comp, s_layer = go([sm.gradient_src(512), tex], [["scale", d], ["gain", 0.5], ["mix_pct", 100.0], ["detail", 5]])
    note("layer max (the light is there)", float(layer[..., :3].max()))
    assert layer[..., :3].max() > 0.2, "the module's caustic layer is black in sheets mode"
    check("module composite vs standalone composite: max|diff|", float(np.abs(comp.astype(np.float64) - s_comp).max()), 0.0)
    check("module layer vs standalone layer: max|diff|", float(np.abs(layer.astype(np.float64) - s_layer).max()), 0.0)


def test_T028_switching_back_to_soft_restores_the_baseline():
    tex, dstar = st.field_texture(), st.first_fold_distance()
    values = rb.SETS["B_wet"]
    comp, layer = module(["mode 1, scale %g, gain 0.5, mix_pct 100" % dstar, rb.settings_of(values) + ", mode 0"], warmup=200)
    check("sheets then soft: |module - baseline B| (0 = bit-identical)", vs_baseline("B_wet", comp, layer), 0.0)
    state = enables()
    assert enabled(state, "caustic_pix") and not enabled(state, "caustic_sheets"), state


# ================================================================== shared behaviours (tasks T031-T035)
def module_tags(settings, inputs=None, n_in=None, warmup=180):
    """Both module-bench captures from one job: 'base' (settings applied, bypass off) and 'bypassed' (the timeline's end,
    after the bypass test)."""
    inputs = inputs if inputs is not None else [sm.gradient_src(512), st.field_texture()]
    res, out = cr.run(inputs, [], MODULE, n_out=2, n_in=n_in, settings=settings, warmup=warmup)
    errs = [e for e in (res.get("errors") or []) if "getattr" not in e]
    assert not errs, f"max errors: {errs[:3]}"
    assert out.get("base") and out.get("bypassed"), f"captures missing: {sorted(out)}"
    return out["base"], out["bypassed"]


def test_T031_bypass_is_a_passthrough_on_both_outlets_in_both_modes():
    src = sm.gradient_src(512)
    dstar = st.first_fold_distance()
    for mode in (0, 1):
        base, byp = module_tags(f"scale {dstar}, gain 0.5, mix_pct 100, mode {mode}")
        note(f"mode {mode}: the caustic layer's max with bypass off", float(base[2][..., :3].max()))
        assert base[2][..., :3].max() > 0.05, f"mode {mode}: no light with bypass off: the test would prove nothing"
        for k, name in ((1, "composite"), (2, "layer")):
            check(f"mode {mode}, bypass: {name} outlet == the source, max|diff|",
                  float(np.abs(byp[k][..., :3].astype(np.float64) - src[..., :3]).max()), 1e-6)
            check(f"mode {mode}, bypass: {name} outlet alpha is 1", abs(float(byp[k][..., 3].min()) - 1.0), 0.0)


def test_T032_an_unconnected_vecfield_is_silent_in_sheets_mode():
    """Only the source is connected: the sheets composite's guard reads the field inlet as absent (probe T008)."""
    src = sm.gradient_src(512)
    base, _ = module_tags(f"scale {st.first_fold_distance()}, gain 0.5, mix_pct 100, mode 1", inputs=[src], n_in=1)
    check("no field: composite == source, max|diff|", float(np.abs(base[1][..., :3].astype(np.float64) - src[..., :3]).max()), 1e-6)
    check("no field: max of the caustic layer", float(base[2][..., :3].max()), 1e-6)


def luma(a):
    return float((a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114).mean())


def test_T034_default_brightness_is_comparable_across_modes():
    """The same default gain and scale: the sheets layer's mean luma within 2x of the soft layer's (the sheets branch's
    internal constant, codebox_sheets.gen k_sheets, is calibrated for this)."""
    settings = "scale 0.3, gain 0.5, mix_pct 100"
    soft = luma(module_tags(settings + ", mode 0")[0][2])
    sheets = luma(module_tags(settings + ", mode 1")[0][2])
    note("soft layer mean luma", soft)
    note("sheets layer mean luma", sheets)
    ratio = sheets / soft
    note("sheets / soft", ratio)
    assert 0.5 <= ratio <= 2.0, f"brightness differs by {ratio:.2f}x between modes: recalibrate k_sheets"


def test_T035_both_modes_fit_the_frame_budget_through_the_module():
    """Fits / does-not-fit only (a cost below the 60 fps cap is invisible to the bench; the model is spike S6's)."""
    inputs = [sm.gradient_src(512), st.field_texture()]
    for label, params in (("soft", [["mix_pct", 100.0], ["mode", 0]]),
                          ("sheets, default step 5", [["mix_pct", 100.0], ["scale", 0.3], ["mode", 1]])):
        ms = cr.period_ms(inputs, params, MODULE, n_out=2)
        note(f"{label}: frame period ms (the cap is {cr.CAP_MS:.1f})", ms)
        assert 5.0 < ms < 100.0, f"{label}: invalid frame period {ms:.1f} ms (a stalled bench?)"
        check(f"{label}: ms over 1.15 x the cap", max(0.0, ms - 1.15 * cr.CAP_MS), 0.0)


if __name__ == "__main__":
    cr.ensure_bench()
    only = [t for t in os.environ.get("ONLY", "").split(",") if t]
    ns = {k: v for k, v in globals().items() if not (k.startswith("test_") and only and not any(o in k for o in only))}
    sys.exit(run(ns))
