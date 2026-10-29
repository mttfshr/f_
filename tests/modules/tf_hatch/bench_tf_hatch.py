"""
bench_tf_hatch.py -- Tier 2 verification for f_tf_hatch v2 (streamline renderer): the real stage
codeboxes (src/f_tf_hatch/codebox_*.gen) run on the GPU through the Max test bench and are diffed
against the NumPy mirror (tests/modules/tf_hatch/tf_hatch_mirror.py), one stage per job. Plan Block 2.

  E1  decode + presence   exact (arithmetic + one atan2)
  E2  streamline march    statistical: the lattice hash sin(ix*127.1 + iy*311.7)*43758 is borderline-
                          sensitive (a handful of cells flip between GPU and NumPy), so the check is the
                          FRACTION of pixels that differ, not a max error; COHERENT fields only (coherence 1
                          drops the hashed random direction out of the march, whose 1e5-scale arguments
                          legitimately differ between implementations)
  E3  style + encode      exact, both outlets, bypass
  cost  per stage at 1080p; gate = whole module <= 5 ms (spec "Cost gate"); the spike (Block 1,
        tests/records/spike_tf_hatch_lic_cost.py) predicted E2 ~1.7 ms at N = 16

Param names that differ from the spec's table because GenExpr reserves them: `reach` (spec: length),
`line_hard` (spec: line).

Needs Max with tests/bench/bench.maxpat open (bench.sh asks the owner before any run).
Run:  tests/bench.sh -q tests/modules/tf_hatch/bench_tf_hatch.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 160

import paths as _paths  # noqa: F401
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
import tf_hatch_mirror as m

REPO = _paths.REPO
SRC = REPO / "src" / "f_tf_hatch"
F32 = np.float32
CHAIN = 8   # the bench has 8 slots (benchclient.measure clamps to it)


def code(name):
    return (SRC / f"codebox_stage_{name}.gen").read_text()


def rand_tensor_tex(h, w, seed=0, strength=100.0):
    """A random OUTLET-0-FORMAT tensor texture (B channel unclamped float32)."""
    rng = np.random.default_rng(seed)
    tex = np.zeros((h, w, 4), F32)
    jxx = np.abs(rng.normal(0, 0.003, (h, w)))
    jyy = np.abs(rng.normal(0, 0.003, (h, w)))
    jxy = rng.normal(0, 0.002, (h, w))
    tex[..., 0] = (jxx * strength).astype(F32)
    tex[..., 1] = (jxy * strength * F32(0.5) + F32(0.5)).astype(F32)
    tex[..., 2] = (jyy * strength).astype(F32)
    tex[..., 3] = F32(1.0)
    return tex


def field_tex(h, w, along_deg, coh, tr=0.01, strength=100.0):
    """Outlet-0-format tensor texture: constant ALONG axis, coherence `coh`."""
    a = np.deg2rad(along_deg)
    gx, gy = np.cos(a + np.pi / 2), np.sin(a + np.pi / 2)
    tex = np.zeros((h, w, 4), F32)
    tex[..., 0] = tr * ((1 - coh) / 2 + coh * gx * gx) * strength
    tex[..., 1] = tr * (coh * gx * gy) * strength * 0.5 + 0.5
    tex[..., 2] = tr * ((1 - coh) / 2 + coh * gy * gy) * strength
    tex[..., 3] = 1.0
    return tex


def ok(r):
    check("status ok", 0 if r["status"] == "ok" else 1, 0)


# The shipped E2 param map, on both sides: density -> fill, reach -> half-length (HALF_LEN_FRAC of the
# frame height), grain -> cell size. PINNED in every job (the bench keeps a Param's last value).
E2_BASE = {"reach": 0.5, "grain": 0.75, "density": 0.717}
E3_BASE = {"contrast": 0.5, "line_hard": 0.0, "bypass_gate": 0.0}
E1_BASE = {"strength": 100.0, "angle_offset": 0.0, "structure_floor": 0.0}


# ------------------------------------------------------------- stage E1

def test_stage_e1_matches():
    tex = rand_tensor_tex(64, 64, seed=1)
    out, r = bc.run_pass(code("e1"), [tex], params=dict(E1_BASE))
    ok(r)
    ref = m.stage_e1(tex, 100.0, 0.0, 0.0, "unsigned_nearest")
    check("E1 axis pair", float(np.abs(out[..., :2] - ref[..., :2]).max()), 1e-4)
    check("E1 coherence", float(np.abs(out[..., 2] - ref[..., 2]).max()), 1e-4)
    check("E1 presence", float(np.abs(out[..., 3] - ref[..., 3]).max()), 1e-5)
    # an exactly-zero tensor: axis unset, coherence 0, presence 0 (no atan2(0,0) artifact)
    zero = np.zeros((8, 8, 4), F32)
    outz, r = bc.run_pass(code("e1"), [zero], params=dict(E1_BASE))
    ok(r)
    check("E1 zero tensor: all four channels 0", float(np.abs(outz).max()), 1e-6)


def test_stage_e1_floor_and_offset():
    tex = rand_tensor_tex(64, 64, seed=7)
    for fl in (0.1, 0.5, 0.9):
        params = dict(E1_BASE, structure_floor=fl)
        out, r = bc.run_pass(code("e1"), [tex], params=params)
        ok(r)
        ref = m.stage_e1(tex, 100.0, 0.0, fl, "unsigned_nearest")
        note(f"floor {fl}: mean presence (GPU)", float(out[..., 3].mean()))
        check(f"E1 floor {fl} presence", float(np.abs(out[..., 3] - ref[..., 3]).max()), 1e-4)
        check(f"E1 floor {fl} axis unaffected", float(np.abs(out[..., :2] - ref[..., :2]).max()), 1e-4)
    for off in (1.0, -1.0):
        params = dict(E1_BASE, angle_offset=off)
        out, r = bc.run_pass(code("e1"), [tex], params=params)
        ok(r)
        ref = m.stage_e1(tex, 100.0, off, 0.0, "unsigned_nearest")
        check(f"E1 offset {off} axis pair", float(np.abs(out[..., :2] - ref[..., :2]).max()), 1e-4)


# ------------------------------------------------------------- stage E2

HASH_PROBE = """ix = nearest(in1, norm).x;
iy = nearest(in1, norm).y;
out1 = vec(fract(sin(ix * 127.1 + iy * 311.7) * 43758.5453), 0.0, 0.0, 1.0);
"""


def gpu_hash_table(n=64):
    """The E2 lattice hash evaluated BY THE GPU for cell indices 0..n-1 (table[iy, ix]). The hash
    sin(ix*127.1 + iy*311.7)*43758 is not reproducible across implementations (float32 arguments of
    ~1e4, trig precision), so E2's reference uses the GPU's own hash values and the parity test is
    about everything EXCEPT the hash: coordinates, march, sign continuity, edges, brightness. How far
    the NumPy hash agrees with the GPU's is reported separately (a look-level fact, not a defect)."""
    tex = np.zeros((n, n, 4), F32)
    tex[..., 0] = np.arange(n, dtype=F32)[None, :]
    tex[..., 1] = np.arange(n, dtype=F32)[:, None]
    tex[..., 3] = 1.0
    out, r = bc.run_pass(HASH_PROBE, [tex])
    ok(r)
    return out[..., 0].copy()


def e2_ref(aux, params, h, table):
    """Mirror E2 with the noise lookup swapped for the GPU's own hash table (restored after)."""
    fill = float(m.fill_from_density(params["density"]))

    def gpu_noise(px, py, cell_px, seed=0, fill=None):
        ix = np.floor(px / F32(cell_px)).astype(int)
        iy = np.floor(py / F32(cell_px)).astype(int)
        return (table[iy, ix] < F32(fill)).astype(F32)

    saved = m.noise_at
    m.noise_at = gpu_noise
    try:
        return m.stage_e2(aux, n_steps=16, length=params["reach"], grain=params["grain"], persist="mix",
                          persist_pow=0.5, aux_mode="unsigned_nearest", fill=fill)
    finally:
        m.noise_at = saved


def test_stage_e2_matches_on_coherent_fields():
    """GPU march vs the mirror on constant-axis, coherence-1 fields (three axes, one of them
    across the horizontal branch cut). Fraction of pixels differing by > 0.05, plus the mean."""
    table = gpu_hash_table()
    ix, iy = np.meshgrid(np.arange(64), np.arange(64))
    np_h = m._fract(np.sin(ix.astype(F32) * F32(m.HASH_A) + iy.astype(F32) * F32(m.HASH_B)) * F32(m.HASH_C))
    note("NumPy vs GPU lattice hash: fraction of cells with |dh| > 0.01 (not asserted)",
         float((np.abs(np_h - table) > 0.01).mean()))
    for along in (20.0, 100.0, 170.0):
        h = w = 64
        aux = m.stage_e1(field_tex(h, w, along, 1.0), 100.0, aux_mode="unsigned_nearest")
        out, r = bc.run_pass(code("e2"), [aux], params=dict(E2_BASE))
        ok(r)
        ref = e2_ref(aux, E2_BASE, h, table)
        frac = float((np.abs(out[..., 0] - ref[..., 0]) > 0.05).mean())
        mean_ratio = float(out[..., 0].mean()) / max(float(ref[..., 0].mean()), 1e-9)
        note(f"along {along}: fraction differing > 0.05 / mean GPU/mirror", (frac, mean_ratio))
        # 3%: cells whose position sits within float32 rounding of a lattice boundary.
        check(f"E2 along {along}: <= 3% of pixels differ", 0.0 if frac <= 0.03 else frac, 0.0)
        check(f"E2 along {along}: mean raw within 5%", abs(mean_ratio - 1.0), 0.05)
        check(f"E2 along {along}: presence channel", float(np.abs(out[..., 1] - ref[..., 1]).max()), 1e-4)
        check(f"E2 along {along}: alpha 1", float(np.abs(out[..., 3] - 1.0).max()), 1e-6)


def test_stage_e2_edges_and_unset():
    """Texel-centre convention: borders match as well as the interior. And an unset axis (zero
    tensor) must not produce NaN (the march falls back to a fixed axis; E3 multiplies by presence 0)."""
    h = w = 64
    aux = m.stage_e1(field_tex(h, w, 45.0, 1.0), 100.0, aux_mode="unsigned_nearest")
    out, r = bc.run_pass(code("e2"), [aux], params=dict(E2_BASE))
    ok(r)
    ref = e2_ref(aux, E2_BASE, h, gpu_hash_table())
    d = np.abs(out[..., 0] - ref[..., 0]) > 0.05
    band = np.zeros_like(d)
    band[:3] = band[-3:] = True
    band[:, :3] = band[:, -3:] = True
    note("E2 border band: fraction differing", float(d[band].mean()))
    check("E2 border band <= 8%", 0.0 if float(d[band].mean()) <= 0.08 else float(d[band].mean()), 0.0)
    zero_aux = np.zeros((16, 16, 4), F32)
    outz, r = bc.run_pass(code("e2"), [zero_aux], params=dict(E2_BASE))
    ok(r)
    check("E2 unset axis: finite", 0.0 if bool(np.isfinite(outz).all()) else 1.0, 0.0)
    check("E2 unset axis: presence 0", float(np.abs(outz[..., 1]).max()), 1e-6)


# ------------------------------------------------------------- stage E3

def test_stage_e3_matches_both_outlets():
    tex = rand_tensor_tex(64, 64, seed=4)
    aux = m.stage_e1(tex, 100.0, 0.0, 0.1, "unsigned_nearest")
    aux2 = m.stage_e2(aux, n_steps=16, length=0.5, grain=0.75, aux_mode="unsigned_nearest",
                      fill=float(m.fill_from_density(0.717)))
    for contrast, line in ((0.5, 0.0), (1.0, 1.0), (0.2, 0.5)):
        params = dict(E3_BASE, contrast=contrast, line_hard=line)
        outs, r = bc.run_pass(code("e3"), [aux2], params=params, all_outputs=True)
        ok(r)
        ref0, ref1 = m.stage_e3(aux2, n_steps=16, contrast=contrast, line=line, fill=0.03)
        check(f"E3 contrast {contrast} line {line}: outlet 0", float(np.abs(outs[0][..., :3] - ref0[..., :3]).max()), 1e-4)
        check(f"E3 contrast {contrast} line {line}: outlet 1", float(np.abs(outs[1][..., :3] - ref1[..., :3]).max()), 1e-4)
        check(f"E3 contrast {contrast} line {line}: alpha 1", float(np.abs(outs[0][..., 3] - 1.0).max()), 1e-6)
    # presence gates: zero-presence aux2 renders nothing
    auxz = aux2.copy()
    auxz[..., 1] = 0.0
    outz, r = bc.run_pass(code("e3"), [auxz], params=dict(E3_BASE), all_outputs=True)
    ok(r)
    check("E3 presence 0 renders black", float(np.abs(outz[0][..., :3]).max()), 1e-6)
    # bypass: both outlets black, A = 1
    outb, r = bc.run_pass(code("e3"), [aux2], params=dict(E3_BASE, bypass_gate=1.0), all_outputs=True)
    ok(r)
    check("E3 bypass outlet 0 black", float(np.abs(outb[0][..., :3]).max()), 1e-6)
    check("E3 bypass outlet 1 black", float(np.abs(outb[1][..., :3]).max()), 1e-6)
    check("E3 bypass alpha 1", float(np.abs(outb[0][..., 3] - 1.0).max()), 1e-6)


# ------------------------------------------------------------- cost

def test_cost_per_stage_1080p():
    """Per-stage ms/pass at 1080p (M3 Max); the module gate is the SUM <= 5 ms. The spike predicted
    E2 ~1.7 ms (N = 16, nearest); bench floor ~0.8 ms/pass, so E1 and E3 read as upper bounds."""
    tex = rand_tensor_tex(1080, 1920, seed=6)
    aux = m.stage_e1(tex, 100.0, 0.0, 0.1, "unsigned_nearest")
    aux2 = np.zeros_like(aux)
    aux2[..., 0] = np.random.default_rng(1).random(aux.shape[:2]).astype(F32)
    aux2[..., 1] = 1.0
    aux2[..., 3] = 1.0
    total = 0.0
    for label, c, args, params in (("E1", code("e1"), [tex], dict(E1_BASE, structure_floor=0.1)),
                                   ("E2", code("e2"), [aux], dict(E2_BASE, reach=0.5, grain=0.5)),
                                   ("E3", code("e3"), [aux2], dict(E3_BASE))):
        r = bc.measure(c, args, chain=CHAIN, params=params)
        ms = r.get("ms_per_pass", r.get("ms_per_pass_upper_bound"))
        kind = "gpu_bound" if "ms_per_pass" in r else "upper bound"
        note(f"{label} 1080p ms/pass ({kind})", ms)
        total += ms
    note("sum of the three stages, ms (module gate <= 5)", total)
    check("module cost <= 5 ms at 1080p", 0.0 if total <= 5.0 else total, 0.0)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
