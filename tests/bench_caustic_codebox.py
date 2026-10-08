"""
bench_caustic_codebox.py -- the f_caustic sheets-mode codeboxes (src/f_caustic/) on the GPU through the codebox
bench, diffed against the NumPy mirror (tests/scatter_mirror.py). Tasks T013 (composite) and T023 (select) of
.specify/f_caustic_scatter/tasks.md. Constitution 2: a codebox is verified here BEFORE it is wired into a module.

Select (codebox_select_comp.gen / codebox_select_layer.gen, T023): in1 = soft branch, in2 = sheets branch, in3 = source;
  sheets_gate picks a branch exactly, bypass_gate mixes to the source.
Composite (codebox_sheets.gen): in1 = source, in2 = the float32 illuminance capture (smaller, HDR), in3 = vecfield.
  tone map, bilinear upscale, additive composite, mix_pct, and the unconnected-field guard.

Needs Max with tests/bench/bench.maxpat open (codebox bench).
Run:  tests/bench.sh tests/bench_caustic_codebox.py
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
import scatter_mirror as sm
import scatter_truth as st
from harness import check, note, run

SRC = Path(__file__).resolve().parent.parent / "src" / "f_caustic"
SHEETS = (SRC / "codebox_sheets.gen").read_text()
SELECTS = {"comp": (SRC / "codebox_select_comp.gen").read_text(), "layer": (SRC / "codebox_select_layer.gen").read_text()}
N = 512                       # source / output size
R = 256                       # the illuminance capture's size
K, EXPO = 2.0, 0.7            # the codebox's internal constants


def gpu(code, inputs, params, dim=(N, N)):
    outs, r = bc.run_pass(code, inputs, dim=dim, params=params, all_outputs=True, timeout_ms=30000)
    if r["status"] != "ok" or outs[0] is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs, r


def light_capture():
    """A realistic HDR illuminance capture: the NumPy scatter at 3.5 d*, 4 points per pixel (peaks near 20)."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    return sm.ref_scatter(sm.white(), tex, 3.5 * dstar, 4 * R, 1.0 / 16.0, r=R)


def sheets_ref(src, light, field, gain, mix):
    L = sm.resize_bilinear(light.astype(np.float64), src.shape[0], src.shape[1])[..., :3]
    present = float(field[..., 0].sum() + field[..., 1].sum() > 0.0)      # the guard (4 points) for these test fields
    ex = sm.tone(L, lev=gain * K, expo=EXPO) * present
    s3 = src[..., :3].astype(np.float64)
    comp = np.clip(s3 + ex, 0.0, 1.0)
    return s3 * (1 - mix / 100.0) + comp * (mix / 100.0), np.clip(ex, 0.0, 1.0)


def err(a, b):
    return float(np.abs(a[..., :3].astype(np.float64) - b).max())


def test_T013_composite_compiles_and_runs():
    outs, r = gpu(SHEETS, [sm.gradient_src(N), light_capture(), st.field_texture()], {"gain": 0.5, "mix_pct": 100.0})
    assert not [e for e in r["errors"] if "getattr" not in e], r["errors"]
    note("max of out1 (composite)", outs[0][..., :3].max())
    note("max of out2 (caustic layer)", outs[1][..., :3].max())
    assert outs[1][..., :3].max() > 0.05, "the caustic layer is black: the stage did not render the light"


def test_T013_composite_matches_mirror():
    src, light, fld = sm.gradient_src(N), light_capture(), st.field_texture()
    for gain, mix in ((0.5, 100.0), (1.0, 60.0), (0.2, 100.0)):
        outs, _ = gpu(SHEETS, [src, light, fld], {"gain": gain, "mix_pct": mix})
        ref1, ref2 = sheets_ref(src, light, fld, gain, mix)
        check(f"composite out1 max|GPU - mirror| (gain {gain}, mix {mix})", err(outs[0], ref1), 1e-6)
        check(f"layer     out2 max|GPU - mirror| (gain {gain}, mix {mix})", err(outs[1], ref2), 1e-6)


def test_T013_mix_zero_is_the_source():
    src = sm.gradient_src(N)
    outs, _ = gpu(SHEETS, [src, light_capture(), st.field_texture()], {"gain": 0.5, "mix_pct": 0.0})
    check("mix 0: |out1 - source|", err(outs[0], src[..., :3].astype(np.float64)), 1e-5)


def test_T013_zero_gain_gives_no_light():
    outs, _ = gpu(SHEETS, [sm.gradient_src(N), light_capture(), st.field_texture()], {"gain": 0.0, "mix_pct": 100.0})
    check("gain 0: max of the caustic layer", float(outs[1][..., :3].max()), 1e-6)


def test_T013_unconnected_vecfield_is_silent():
    """An unconnected inlet reads (0, 0, 0, 1) (probe T008): composite = source, layer = black."""
    src = sm.gradient_src(N)
    absent = np.zeros((N, N, 4), np.float32)
    absent[..., 3] = 1.0
    outs, _ = gpu(SHEETS, [src, light_capture(), absent], {"gain": 0.5, "mix_pct": 100.0})
    check("no field: |out1 - source|", err(outs[0], src[..., :3].astype(np.float64)), 1e-5)
    check("no field: max of the caustic layer", float(outs[1][..., :3].max()), 1e-6)


def rand_tex(seed, n=N):
    rng = np.random.default_rng(seed)
    a = rng.random((n, n, 4)).astype(np.float32)
    a[..., 3] = 1.0
    return a


def test_T023_select_gate_picks_a_branch_exactly():
    a, b, src = rand_tex(1), rand_tex(2), rand_tex(3)
    for name, code in SELECTS.items():
        o0, _ = gpu(code, [a, b, src], {"sheets_gate": 0.0, "bypass_gate": 0.0})
        o1, _ = gpu(code, [a, b, src], {"sheets_gate": 1.0, "bypass_gate": 0.0})
        check(f"select {name}: gate 0 returns the soft input, max|diff|", err(o0[0], a[..., :3].astype(np.float64)), 0.0)
        check(f"select {name}: gate 1 returns the sheets input, max|diff|", err(o1[0], b[..., :3].astype(np.float64)), 0.0)


def test_T023_select_bypass_is_the_source_in_both_modes():
    a, b, src = rand_tex(4), rand_tex(5), rand_tex(6)
    for name, code in SELECTS.items():
        for gate in (0.0, 1.0):
            o, _ = gpu(code, [a, b, src], {"sheets_gate": gate, "bypass_gate": 1.0})
            check(f"select {name}: bypass, gate {gate:g}: max|out - source|", err(o[0], src[..., :3].astype(np.float64)), 0.0)
            check(f"select {name}: bypass, gate {gate:g}: alpha is 1", abs(float(o[0][..., 3].min()) - 1.0), 0.0)


def test_T023_select_is_linear_in_the_gate():
    a, b, src = rand_tex(7), rand_tex(8), rand_tex(9)
    o, _ = gpu(SELECTS["comp"], [a, b, src], {"sheets_gate": 0.25, "bypass_gate": 0.0})
    ref = 0.75 * a[..., :3].astype(np.float64) + 0.25 * b[..., :3].astype(np.float64)
    check("select comp: gate 0.25: max|out - (0.75 a + 0.25 b)|", err(o[0], ref), 1e-6)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
