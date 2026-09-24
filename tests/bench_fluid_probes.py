"""
bench_fluid_probes.py -- Phase 0 GPU probes for f_vf_fluid (tasks.md T005-T007).
These answer OPEN QUESTIONS, so most tests print measured facts (note) and
assert only what the design already depends on; the answers are recorded in
.specify/f_vf_fluid/tasks.md "Findings". Kept as a record of the bench-verified
facts, not as a regression gate for shipped modules.

  T005 E-seam   periodic bilinear: sample()+fract() vs four wrapped nearest() taps
  T006 E-nan    can GenExpr on jit.gl.pix detect and clear NaN/Inf?
  T007 E5       does a Param loop bound compile and give the right DFT?

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/bench_fluid_probes.py
"""
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from gpu_sim import F32, grid, sample
from harness import check, note, run
from test_fft_separable import make_image, pack, pass_dft, rel_err

CB = Path(__file__).resolve().parent / "bench" / "codeboxes"


def run_code(name, tex, params=None, all_outputs=False, subst=None):
    code = (CB / name).read_text()
    for a, b in (subst or {}).items():
        code = code.replace(a, b)
    out, r = bc.run_pass(code, [tex], params=params or {}, timeout_ms=30000,
                         all_outputs=all_outputs)
    if r["status"] != "ok":
        raise AssertionError(f"{name}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def rand_tex(n, seed=0):
    return np.random.default_rng(seed).uniform(0, 1, (n, n, 4)).astype(np.float32)


def seam_reference(tex, sx=0.37, sy=0.61):
    n = tex.shape[0]
    nx, ny, _, _ = grid(n, n)
    return sample(tex, nx - F32(sx / n), ny - F32(sy / n), wrap=True)


def seam_split(err, ring=1):
    """Max error over the interior vs over the outermost `ring` rows/columns."""
    n = err.shape[0]
    mask = np.zeros((n, n), bool)
    mask[:ring, :] = mask[-ring:, :] = mask[:, :ring] = mask[:, -ring:] = True
    e = np.max(np.abs(err), axis=-1)
    return float(e[~mask].max()), float(e[mask].max())


def test_E_seam_manual_four_tap_is_periodic():
    """T005: the manual 4-tap read must match the periodic reference
    everywhere, seam included (this is what codebox_adv.gen will use unless
    the fract() variant also passes)."""
    tex = rand_tex(64, 1)
    out = run_code("seam_tap4.gen", tex)
    inner, seam = seam_split(out - seam_reference(tex))
    check("4-tap: interior max err vs periodic reference", inner, 1e-5)
    check("4-tap: seam ring max err vs periodic reference", seam, 1e-5)


def test_E_seam_fract_variant_probe():
    """T005: sample() + fract(coordinate). Bench-verified 2026-09-23: right
    away from the seam only to ~1e-3 (the GL sampler's interpolation weights
    are 8-bit), and WRONG on the wrap rows/column (error ~0.5) because the
    sampler clamps its neighbor tap. Hence the 4-tap read is used."""
    tex = rand_tex(64, 1)
    out = run_code("seam_fract.gen", tex)
    inner, seam = seam_split(out - seam_reference(tex), ring=2)
    check("fract(): interior max err (hardware bilinear, 8-bit weights)", inner, 3e-3)
    note("fract(): wrap-ring max err (large = fract() does NOT wrap the neighbor tap)", seam)
    print(f"    {'-> fract() is periodic too' if seam < 3e-3 else '-> fract() clamps at the seam: use the 4-tap read'}")


def test_E_nan_guard_probe():
    """T006: does the comparison-based guard clear NaN and Inf on the GPU?"""
    tex = rand_tex(32, 2)
    out1, out2 = run_code("nan_probe.gen", tex, all_outputs=True)[:2]
    mid = out1[out1.shape[0] // 2, out1.shape[1] // 2]
    ramp = 0.25 + 0.5 * (np.arange(32) + 0.5) / 32
    check("finite value passes the guard unchanged", np.max(np.abs(out1[..., 2][0] - ramp)), 1e-6)
    print(f"    guard(NaN) = {float(out1[..., 0].mean()):.3g}, guard(+Inf) = {float(out1[..., 1].mean()):.3g}"
          "  (expect 0, 0 if the guard works)")
    print(f"    raw: nn==nn -> {float(out2[..., 0].mean()):.3g} (IEEE 0), inf==inf -> {float(out2[..., 1].mean()):.3g} (1), "
          f"nn<1e30 -> {float(out2[..., 2].mean()):.3g} (0), inf<1e30 -> {float(out2[..., 3].mean()):.3g} (0)")
    works = (np.all(out1[..., 0] == 0) and np.all(out1[..., 1] == 0))
    print(f"    -> abs(x) < 1e30 guard {'WORKS' if works else 'DOES NOT WORK as written'}")
    same = float(out2[..., 0].mean()) == 1.0
    print(f"    -> NOTE: NaN == NaN evaluates {'TRUE' if same else 'false'} here; "
          f"{'a `x == x` guard would NOT catch NaN' if same else '`x == x` also works'}")


def test_E5_param_loop_bound():
    """T007 (optional): a Param-bounded DFT loop. Informational: records
    whether it compiles and matches np.fft at N = 128 and N = 64."""
    for n in (128, 64):
        u, v = make_image(n, n, 1), make_image(n, n, 2)
        tex = pack(u, v)
        try:
            out = run_code("dft_param_n.gen", tex, params={"inverse": 0, "nlen": n})
        except AssertionError as e:
            print(f"    N={n}: Param loop bound did NOT run: {e}")
            continue
        err = rel_err(out, pass_dft(tex, "x"))
        note(f"N={n}: Param-bounded DFT vs mirror (rel)", err)
        print(f"    -> N={n}: {'matches' if err < 1e-4 else 'MISMATCH'}")


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
