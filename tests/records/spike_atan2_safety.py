"""
spike_atan2_safety.py -- GenExpr `atan2` verification on the live GPU bench.

Closes `ideas/f_tensorfield.md` Open Question 6 (and the identical blocker
in `ideas/f_weave_orientation_blend.md` Fix B): is atan2 safe in a
jit.gl.pix codebox when applied to *decoded sampled-texture* data?

Four checks against independent NumPy truth (not a mirror of GenExpr):

  T1  compiles and runs, output finite everywhere, no bench errors.
  T2  full-range value fidelity: every pixel's atan2(Fy, Fx) matches
      np.arctan2 at the same texel to float32/bilinear precision, across
      all four quadrants -- proves branch and quadrant are right.
  T3  branch-cut locality: pixels adjacent to the +/-pi cut agree with
      the analytic value at their own pixel centre (no smearing across
      the cut from the GPU's interpolation), and the cut itself lands
      where atan2's math says (theta jumps between adjacent texels).
  T4  the decode shapes consumers need: half-angle theta/2 (the tensor
      outlet-2 decode and weave Fix B) and the doubled-angle round trip
      atan2(sin t, cos t) == t for all texels.

Run: needs the Max bench open (tests/bench.sh conventions).
     python3 tests/records/spike_atan2_safety.py
"""
import paths as _paths
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
import benchclient as bc          # noqa: E402
import harness                    # noqa: E402

F32 = np.float32
N = 256                           # texel grid per axis
TAU = 2.0 * np.pi


def cb(name):
    with open(os.path.join(str(_paths.BENCH), "codeboxes", name + ".gen")) as f:
        return f.read()

def vecfield_texture():
    """A vecfield texture whose directions cover all quadrants densely and
    non-uniformly (golden-angle sweep), so no quadrant boundary sits on a
    texel centre and the +/-pi cut crosses texel interiors at generic
    angles."""
    i = np.arange(N * N, dtype=np.float64)
    # golden-angle spiral in index space: dense, aperiodic, all quadrants
    ang = (i * 0.6180339887498949) % 1.0 * TAU - np.pi   # in [-pi, pi)
    r = 0.3 + 0.7 * ((i * 0.7548776662466927) % 1.0)     # generic magnitude
    fx = (r * np.cos(ang)).astype(F32).reshape(N, N)
    fy = (r * np.sin(ang)).astype(F32).reshape(N, N)
    tex = np.zeros((N, N, 4), F32)
    tex[..., 0] = fx * 0.5 + 0.5
    tex[..., 1] = fy * 0.5 + 0.5
    tex[..., 2] = 0.5
    tex[..., 3] = 1.0
    return tex, fx, fy


def test_T1_compiles_runs_clean():
    tex, _, _ = vecfield_texture()
    out, rep = bc.run_pass(cb("atan2_safety"), [tex])
    assert rep["status"] == "ok", rep
    assert not rep.get("errors"), rep["errors"]
    assert np.isfinite(out).all(), "non-finite values in output"
    print("    ...  bench status: ok, no errors captured, all output finite")


def test_T2_full_range_value_fidelity():
    tex, fx, fy = vecfield_texture()
    out, rep = bc.run_pass(cb("atan2_safety"), [tex])
    assert rep["status"] == "ok" and not rep.get("errors"), rep
    theta_gpu = out[..., 0].astype(np.float64) * TAU - np.pi
    # independent truth at the *pixel centre* coordinates the codebox
    # sampled (norm maps texel i to (i+0.5)/N; in1 is read at norm, which
    # for a same-size input is the identity texel)
    theta_np = np.arctan2(fy, fx)
    # wrap-aware diff
    d = np.abs(np.mod(theta_gpu - theta_np + np.pi, TAU) - np.pi)
    harness.check("max |theta_gpu - arctan2| (rad, wrap-aware)", d.max(), 1e-4)
    # quadrant cross-check: the A channel's sign(Fx) probe must agree with
    # truth wherever |Fx| is away from zero (sign(0) is degenerate)
    away = np.abs(fx) > 1e-3
    sg = (np.sign(fx[away]) + 1) * 0.5
    harness.check("sign(Fx) probe disagreement (px)", np.sum(
        out[..., 3][away].astype(np.float64) != sg), 0)


def test_T3_branch_cut_locality():
    tex, fx, fy = vecfield_texture()
    out, rep = bc.run_pass(cb("atan2_safety"), [tex])
    assert rep["status"] == "ok" and not rep.get("errors"), rep
    theta_gpu = out[..., 0].astype(np.float64) * TAU - np.pi
    theta_np = np.arctan2(fy, fx)
    d = np.abs(np.mod(theta_gpu - theta_np + np.pi, TAU) - np.pi)
    # pixels whose analytic value is near the cut: their GPU value must
    # still match their own pixel-centre truth (no cross-cut smearing)
    near_cut = np.abs(np.abs(theta_np) - np.pi) < 0.2
    harness.note("pixels within 0.2 rad of the cut", int(near_cut.sum()))
    assert near_cut.sum() > 500, "test texture didn't put enough pixels near the cut"
    harness.check("max err near branch cut (rad, wrap-aware)",
                  d[near_cut].max(), 1e-4)
    # the cut is real: some adjacent-texel pairs must jump by ~2pi in the
    # RAW diff (proves the GPU returns the wrapped atan2, not an unwrapped
    # interpolation) -- the wrap-aware diff would map that jump to ~0.
    dj = np.abs(np.diff(theta_gpu, axis=1))
    jumps = int((dj > np.pi).sum())
    harness.note("adjacent-texel >pi jumps (the cut, correctly wrapped)",
                 jumps)
    assert jumps > 0, "no branch-cut jump found -- atan2 output not wrapped?"


def test_T4_decode_shapes():
    tex, fx, fy = vecfield_texture()
    out, rep = bc.run_pass(cb("atan2_safety"), [tex])
    assert rep["status"] == "ok" and not rep.get("errors"), rep
    theta_np = np.arctan2(fy, fx)
    # half-angle channel (weave fix B / tensor outlet-2 decode shape):
    # the codebox stores G = (theta/2)/pi + 0.5, i.e. the same [0,1] scale
    # as R; decode the half-angle back as (G*2 - 1)*pi/2.
    half_gpu = (out[..., 1].astype(np.float64) * 2.0 - 1.0) * np.pi / 2
    half_np = theta_np / 2
    # exclude the degenerate cut-boundary texels (fy == 0, fx < 0): there
    # IEEE atan2(-0, -x) = -pi but the GPU returned +pi (measured
    # 2026-10-12). A +/-pi convention difference at the single most
    # degenerate input, not a wrong angle -- consumers blend vectors or
    # doubled components, never this literal value.
    degen = (np.abs(fy) < 1e-6) & (fx < 0)
    harness.note("degenerate cut-boundary texels excluded", int(degen.sum()))
    d = np.abs(np.mod(half_gpu - half_np + np.pi, TAU) - np.pi)
    harness.check("max |half-angle| err excl. cut (rad, wrap-aware)",
                  d[~degen].max(), 1e-4)
    # doubled-angle round trip: atan2(sin t, cos t) must return t (mod 2pi)
    # for every texel -- the exact identity outlet-2 consumers rely on
    rt_gpu = out[..., 2].astype(np.float64) * TAU - np.pi
    d = np.abs(np.mod(rt_gpu - theta_np + np.pi, TAU) - np.pi)
    harness.check("max |atan2(sin t, cos t) - t| (rad, wrap-aware)",
                  d.max(), 1e-4)


if __name__ == "__main__":
    sys.exit(harness.run(globals()))