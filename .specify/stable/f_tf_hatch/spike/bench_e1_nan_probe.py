"""
SPIKE (not shipped): does Hatch's E1 stage produce NaN on an isotropic tensor? (hub Q17, 2026-10-17)

E1 computes theta = 0.5 * atan2(2.0*jxy, diff) with no `+1e-7` bias on the denominator argument (glyph's
ADR-2 amendment made the bias the family idiom: runtime atan2(0,0) returns NaN on this GPU) and masks with
`ca = cos(eff) * (1.0 - iso)`. A `* 0` cannot clear a NaN. The shipped bench only feeds an EXACTLY zero
tensor (iso = 1); a nonzero isotropic tensor (Jxx = Jyy, Jxy = 0) has iso = 0, so nothing masks theta.

Runs the shipped E1 codebox (src/f_tf_hatch/codebox_stage_e1.gen) through the bench on:
  A  exactly-zero tensor, 8 x 8 (the existing bench case, with an explicit NaN / inf count)
  B  constant isotropic nonzero tensor, 64 x 64, at two magnitudes
  C  the same isotropic tensor at 16 x 16 and 256 x 256 (glyph's finding held "at every dim")
  D  mixed 64 x 64: left random field, a stripe of exact zero, right half isotropic nonzero (values vary
     per texel, which rules out whole-texture constant folding)
  E  one float32 ulp from isotropic, both signs
Each case counts NaN and inf per channel (check: total must be 0) and compares the finite pixels'
coherence and presence to the mirror; the axis of an isotropic pixel is undefined, so it is a note only.

Needs Max with tests/bench/bench.maxpat open.
  tests/bench.sh -q .specify/stable/f_tf_hatch/spike/bench_e1_nan_probe.py
"""
GROUP = "spike"
ORDER = 999

import paths as _paths  # noqa: F401
import sys

import numpy as np

REPO = _paths.REPO
sys.path.insert(0, str(REPO / "tests" / "modules" / "tf_hatch"))
import bench_tf_hatch as B  # noqa: E402
import benchclient as bc  # noqa: E402
import tf_hatch_mirror as m  # noqa: E402
from harness import check, note, run  # noqa: E402

F32 = np.float32


def tensor(h, w, jxx, jxy, jyy):
    """Outlet-0-format tensor texture, ENCODED units: R = Jxx, G = Jxy*0.5 + 0.5, B = Jyy."""
    t = np.zeros((h, w, 4), F32)
    t[..., 0] = F32(jxx)
    t[..., 1] = F32(jxy) * F32(0.5) + F32(0.5)
    t[..., 2] = F32(jyy)
    t[..., 3] = F32(1.0)
    return t


def run_e1(tex):
    out, r = bc.run_pass(B.code("e1"), [tex], params=dict(B.E1_BASE))
    B.ok(r)
    return out


def bad_count(label, out, region=None):
    """NaN + inf count over (optionally a column slice of) out; per-channel counts as a note."""
    o = out if region is None else out[:, region[0]:region[1]]
    nan = np.isnan(o).sum(axis=(0, 1))
    inf = np.isinf(o).sum(axis=(0, 1))
    note(f"{label}: NaN per channel (ca, sa, coh, pres)", nan.tolist())
    note(f"{label}: inf per channel", inf.tolist())
    return int(nan.sum() + inf.sum())


def vs_mirror(label, tex, out):
    ref = m.stage_e1(tex, 0.0, 0.0, "unsigned_nearest")
    fin = np.isfinite(out).all(axis=-1)
    if not fin.any():
        note(f"{label}: no finite pixels to compare", 0)
        return
    d_coh = float(np.abs(out[..., 2] - ref[..., 2])[fin].max())
    d_pres = float(np.abs(out[..., 3] - ref[..., 3])[fin].max())
    d_ax = float(np.abs(out[..., :2] - ref[..., :2])[fin].max())
    note(f"{label}: finite pixels {int(fin.sum())}/{fin.size}; max |GPU - mirror| coh {d_coh:.2e}, "
         f"presence {d_pres:.2e}, axis {d_ax:.2e} (axis undefined at isotropy: note only)", "")


def test_a_zero_tensor():
    tex = tensor(8, 8, 0.0, 0.0, 0.0)
    out = run_e1(tex)
    n = bad_count("A zero 8x8", out)
    check("A zero tensor: NaN + inf pixels-channels", n, 0)


def test_b_isotropic_nonzero():
    for mag in (0.5, 0.001):
        tex = tensor(64, 64, mag, 0.0, mag)
        out = run_e1(tex)
        vs_mirror(f"B iso {mag}", tex, out)
        n = bad_count(f"B iso {mag} 64x64", out)
        check(f"B isotropic nonzero {mag}: NaN + inf", n, 0)


def test_c_other_sizes():
    for n_ in (16, 256):
        tex = tensor(n_, n_, 0.5, 0.0, 0.5)
        out = run_e1(tex)
        n = bad_count(f"C iso {n_}x{n_}", out)
        check(f"C isotropic nonzero at {n_}x{n_}: NaN + inf", n, 0)


def test_d_mixed_texture():
    rnd = B.rand_tensor_tex(64, 64, seed=3)
    tex = rnd.copy()
    tex[:, 32:40] = tensor(64, 8, 0.0, 0.0, 0.0)
    tex[:, 40:] = tensor(64, 24, 0.5, 0.0, 0.5)
    out = run_e1(tex)
    vs_mirror("D mixed", tex, out)
    nl = bad_count("D left (random field)", out, (0, 32))
    nz = bad_count("D middle (exact zero stripe)", out, (32, 40))
    ni = bad_count("D right (isotropic nonzero)", out, (40, 64))
    check("D random-field region: NaN + inf", nl, 0)
    check("D zero stripe: NaN + inf", nz, 0)
    check("D isotropic region: NaN + inf", ni, 0)


def test_e_one_ulp_from_isotropic():
    base = F32(0.01)
    up = np.nextafter(base, F32(1.0))
    down = np.nextafter(base, F32(0.0))
    note("E one-ulp spacing at 0.01", float(up - base))
    for name, jxx, jyy in (("jyy one ulp above", base, up), ("jyy one ulp below", base, down)):
        tex = tensor(64, 64, float(jxx), 0.0, float(jyy))
        out = run_e1(tex)
        n = bad_count(f"E {name}", out)
        check(f"E {name}: NaN + inf", n, 0)


if __name__ == "__main__":
    sys.exit(run(globals()))
