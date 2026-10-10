"""
bench_caustic_codebox.py -- the f_caustic composite codebox (src/f_caustic/codebox_sheets.gen) on the GPU through
the codebox bench, diffed against the NumPy mirror (tests/scatter_mirror.py). Task T013 of
.specify/f_caustic_scatter/tasks.md. Constitution 2: a codebox is verified here BEFORE it is wired into a module.
Updated 2026-10-10: the select codeboxes (T023) are gone with soft mode -- there is nothing left to select
between, so bypass_gate now lives directly in this codebox, and `expo` (the tone-curve exponent) is a Param
instead of a fixed constant. Both are covered below in place of the old T023 select tests.

Composite (codebox_sheets.gen): in1 = source, in2 = the float32 illuminance capture (smaller, HDR), in3 = vecfield.
  tone map (`expo`), bilinear upscale, additive composite, mix_pct, the unconnected-field guard, and bypass_gate
  (mixes both outlets to the source last).

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
N = 512                       # source / output size
R = 256                       # the illuminance capture's size
K, EXPO = 2.0, 0.7            # the codebox's internal / default constants


def gpu(code, inputs, params, dim=(N, N)):
    outs, r = bc.run_pass(code, inputs, dim=dim, params=params, all_outputs=True, timeout_ms=30000)
    if r["status"] != "ok" or outs[0] is None:
        raise AssertionError(f"bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return outs, r


def light_capture():
    """A realistic HDR illuminance capture: the NumPy scatter at 3.5 d*, 4 points per pixel (peaks near 20)."""
    tex, dstar = st.field_texture(), st.first_fold_distance()
    return sm.ref_scatter(sm.white(), tex, 3.5 * dstar, 4 * R, 1.0 / 16.0, r=R)


def sheets_ref(src, light, field, gain, mix, expo=EXPO, bypass=0.0):
    L = sm.resize_bilinear(light.astype(np.float64), src.shape[0], src.shape[1])[..., :3]
    present = float(field[..., 0].sum() + field[..., 1].sum() > 0.0)      # the guard (4 points) for these test fields
    ex = sm.tone(L, lev=gain * K, expo=expo) * present
    s3 = src[..., :3].astype(np.float64)
    comp = np.clip(s3 + ex, 0.0, 1.0)
    wet = s3 * (1.0 - mix / 100.0) + comp * (mix / 100.0)
    out1 = s3 * bypass + wet * (1.0 - bypass)
    out2 = s3 * bypass + np.clip(ex, 0.0, 1.0) * (1.0 - bypass)
    return out1, out2


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


def test_T013_expo_changes_the_tone_curve():
    """`expo` was a fixed internal constant (0.7) until 2026-10-10; now a Param -- check the GPU actually reads it,
    at the default and away from it."""
    src, light, fld = sm.gradient_src(N), light_capture(), st.field_texture()
    for expo in (0.4, 0.7, 1.2):
        outs, _ = gpu(SHEETS, [src, light, fld], {"gain": 0.5, "mix_pct": 100.0, "expo": expo})
        ref1, ref2 = sheets_ref(src, light, fld, 0.5, 100.0, expo=expo)
        check(f"composite out1 max|GPU - mirror| (expo {expo})", err(outs[0], ref1), 1e-6)
        check(f"layer     out2 max|GPU - mirror| (expo {expo})", err(outs[1], ref2), 1e-6)


def test_T013_bypass_is_the_source_on_both_outlets():
    """bypass_gate used to live in the (now-deleted) select stages; it is a Param on this codebox directly now."""
    src, light, fld = sm.gradient_src(N), light_capture(), st.field_texture()
    outs, _ = gpu(SHEETS, [src, light, fld], {"gain": 0.5, "mix_pct": 100.0, "bypass_gate": 1.0})
    ref1, ref2 = sheets_ref(src, light, fld, 0.5, 100.0, bypass=1.0)
    check("bypass: out1 (composite) max|GPU - source|", err(outs[0], ref1), 1e-6)
    check("bypass: out2 (layer) max|GPU - source|", err(outs[1], ref2), 1e-6)
    check("bypass: out1 alpha is 1", abs(float(outs[0][..., 3].min()) - 1.0), 0.0)
    check("bypass: out2 alpha is 1", abs(float(outs[1][..., 3].min()) - 1.0), 0.0)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
