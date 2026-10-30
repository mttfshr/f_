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


def e2p(aux, **kw):
    """E2 params for this aux: Width / Height must equal the render size (live `dim` is unusable).
    `src_stroke` (the stroke-texture inlet's connected flag) and `coh_floor` are PINNED to 0 in every job, as
    the bench keeps a Param's last value; a texture / coherence-floor test overrides them."""
    p = dict(E2_BASE, width=float(aux.shape[1]), height=float(aux.shape[0]), src_stroke=0.0, coh_floor=0.0)
    p.update(kw)
    return p


# E2 has a second inlet (the stroke texture). Unconnected, the live module sees a black texture and
# src_stroke 0; the bench passes a small black one.
NOTEX = np.zeros((4, 4, 4), F32)


def noise_tex(h, w, seed):
    """RGBA stroke texture, R=G=B=luma, uniform white noise."""
    t = np.zeros((h, w, 4), F32)
    t[..., 0] = t[..., 1] = t[..., 2] = np.random.default_rng(seed).random((h, w)).astype(F32)
    t[..., 3] = 1.0
    return t
E3_BASE = {"contrast": 0.5, "line_hard": 0.0, "bypass_gate": 0.0}
E1_BASE = {"angle_offset": 0.0, "structure_floor": 0.0}


# ------------------------------------------------------------- stage E1

def test_stage_e1_matches():
    tex = rand_tensor_tex(64, 64, seed=1)
    out, r = bc.run_pass(code("e1"), [tex], params=dict(E1_BASE))
    ok(r)
    ref = m.stage_e1(tex, 0.0, 0.0, "unsigned_nearest")
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
        ref = m.stage_e1(tex, 0.0, fl, "unsigned_nearest")
        note(f"floor {fl}: mean presence (GPU)", float(out[..., 3].mean()))
        check(f"E1 floor {fl} presence", float(np.abs(out[..., 3] - ref[..., 3]).max()), 1e-4)
        check(f"E1 floor {fl} axis unaffected", float(np.abs(out[..., :2] - ref[..., :2]).max()), 1e-4)
    for off in (1.0, -1.0):
        params = dict(E1_BASE, angle_offset=off)
        out, r = bc.run_pass(code("e1"), [tex], params=params)
        ok(r)
        ref = m.stage_e1(tex, off, 0.0, "unsigned_nearest")
        check(f"E1 offset {off} axis pair", float(np.abs(out[..., :2] - ref[..., :2]).max()), 1e-4)


# ------------------------------------------------------------- stage E2

HASH12_SRC = """hash12(ha, hb) {
    hx = fract(ha * 0.1031);
    hy = fract(hb * 0.1031);
    hz = hx;
    hd = hx * (hy + 33.33) + hy * (hz + 33.33) + hz * (hx + 33.33);
    hx = hx + hd;
    hy = hy + hd;
    hz = hz + hd;
    return fract((hx + hy) * hz);
}
"""
# The probe evaluates the SAME hash12 text as the shipped E2 codebox (test_hash_is_the_shipped_one asserts it).
HASH_PROBE = HASH12_SRC + """
ix = nearest(in1, norm).x;
iy = nearest(in1, norm).y;
out1 = vec(hash12(ix, iy), 0.0, 0.0, 1.0);
"""


def gpu_hash_table(n=192):
    """The E2 lattice hash evaluated BY THE GPU for cell indices 0..n-1 (table[iy, ix]); 192 covers the
    lattice of a 1080p frame at the finest useful grain. (The first E2 hash, sin(ix*127.1 + iy*311.7)*
    43758, was not reproducible across implementations and, at 1080p lattice indices, lost its
    precision on the GPU: the lit-cell pattern clumped and flipped with 0.01 changes of `grain`,
    2026-10-29 live look. The hash is now sin-free and the tests below hold it to NumPy.)
    The E2 reference below still uses the GPU's own table, so the parity test stays about everything
    EXCEPT the hash: coordinates, march, sign continuity, edges, brightness."""
    tex = np.zeros((n, n, 4), F32)
    tex[..., 0] = np.arange(n, dtype=F32)[None, :]
    tex[..., 1] = np.arange(n, dtype=F32)[:, None]
    tex[..., 3] = 1.0
    out, r = bc.run_pass(HASH_PROBE, [tex])
    ok(r)
    return out[..., 0].copy()


def e2_ref(aux, params, h, table=None):
    """Mirror E2 (blob noise). The reference uses the mirror's NumPy hash12: the blob lattice is rotated
    and its indices reach ~3000 at the finest grain, beyond the GPU-hash table (the table is still
    built for the hash tests; `table` is accepted and unused). The GPU hash matches NumPy to ~0.05% of
    cells (test_hash_gpu_matches_numpy_and_is_uniform), and the quintic blend smooths what differs."""
    fill = float(m.fill_from_density(params["density"]))
    return m.stage_e2(aux, n_steps=16, length=params["reach"], grain=params["grain"], persist="mix",
                      persist_pow=0.5, aux_mode="unsigned_nearest", fill=fill, noise="blobs")


def test_hash_is_the_shipped_one():
    check("bench probe uses the shipped hash12 text", 0.0 if HASH12_SRC in code("e2") else 1.0, 0.0)


HASH13_SRC = """hash13(ha, hb, hc) {
    hx = fract(ha * 0.1031);
    hy = fract(hb * 0.1031);
    hz = fract(hc * 0.1031);
    hd = hx * (hz + 31.32) + hy * (hy + 31.32) + hz * (hx + 31.32);
    hx = hx + hd;
    hy = hy + hd;
    hz = hz + hd;
    return fract((hx + hy) * hz);
}
"""
HASH13_PROBE = HASH13_SRC + """
Param cval(1.0);
ix = nearest(in1, norm).x;
iy = nearest(in1, norm).y;
out1 = vec(hash13(ix, iy, cval), 0.0, 0.0, 1.0);
"""


def test_hash13_gpu_matches_numpy_and_is_isotropic():
    """The per-step random direction: the GPU's hash13 against NumPy at 1080p-sized pixel coordinates
    (the E2 march uses angle = 2 pi * hash13(floor x, floor y, k + 32 side)); the direction it makes
    must not be biased (a degenerate hash would drag low-coherence paths one way)."""
    check("hash13 probe is the shipped text", 0.0 if HASH13_SRC in code("e2") else 1.0, 0.0)
    n = 256
    tex = np.zeros((n, n, 4), F32)
    tex[..., 0] = (np.arange(n, dtype=F32)[None, :] * 7.0)   # x = 0..1785
    tex[..., 1] = (np.arange(n, dtype=F32)[:, None] * 4.0)   # y = 0..1020
    tex[..., 3] = 1.0
    ix, iy = tex[..., 0], tex[..., 1]
    for cval in (1.0, 9.0, 33.0, 48.0):
        out, r = bc.run_pass(HASH13_PROBE, [tex], params={"cval": cval})
        ok(r)
        ref = m.hash13(ix, iy, F32(cval))
        bad = float((np.abs(out[..., 0] - ref) > 0.01).mean())
        ang = 2 * np.pi * out[..., 0]
        mc, ms = float(np.cos(ang).mean()), float(np.sin(ang).mean())
        note(f"hash13 c={cval}: fraction differing from NumPy / mean cos, sin", (bad, mc, ms))
        check(f"hash13 c={cval}: matches NumPy (<= 1% differ)", 0.0 if bad <= 0.01 else bad, 0.0)
        check(f"hash13 c={cval}: mean cos(angle) ~ 0", abs(mc), 0.05)
        check(f"hash13 c={cval}: mean sin(angle) ~ 0", abs(ms), 0.05)


def test_hash_gpu_matches_numpy_and_is_uniform():
    """The lattice hash at 1080p-sized cell indices (0..191): the GPU agrees with NumPy, and the lit-cell
    pattern is uniform, not clumped (the 2026-10-29 failure was the previous sin-based hash)."""
    table = gpu_hash_table()
    ix, iy = np.meshgrid(np.arange(192, dtype=F32), np.arange(192, dtype=F32))
    np_h = m.hash12(ix, iy)
    bad = float((np.abs(np_h - table) > 0.01).mean())
    note("NumPy vs GPU hash: fraction of cells with |dh| > 0.01", bad)
    check("GPU hash matches NumPy (<= 1% of cells differ)", 0.0 if bad <= 0.01 else bad, 0.0)
    lit = (table < 0.04)
    note("lit fraction at fill 0.04", float(lit.mean()))
    check("lit fraction within 25% of fill", abs(float(lit.mean()) / 0.04 - 1.0), 0.25)
    blocks = lit.reshape(6, 32, 6, 32).mean(axis=(1, 3))
    note("lit fraction per 32x32 block: min / max", (float(blocks.min()), float(blocks.max())))
    check("no clumping: every block within 3x of fill", 0.0 if blocks.max() <= 0.12 else float(blocks.max()), 0.0)
    check("hash value range", 0.0 if (table.min() >= 0.0 and table.max() < 1.0) else 1.0, 0.0)


def test_stage_e2_matches_on_coherent_fields():
    """GPU march vs the mirror on constant-axis, coherence-1 fields (three axes, one of them
    across the horizontal branch cut). Fraction of pixels differing by > 0.05, plus the mean."""
    table = gpu_hash_table()
    for along in (20.0, 100.0, 170.0):
        h = w = 64
        aux = m.stage_e1(field_tex(h, w, along, 1.0), aux_mode="unsigned_nearest")
        out, r = bc.run_pass(code("e2"), [aux, NOTEX], params=e2p(aux))
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


def test_stage_e2_matches_on_incoherent_fields():
    """Same, at partial coherence: the persistence mix and the per-step random direction are on the
    GPU path now (a coherence-1 field never uses them)."""
    table = gpu_hash_table()
    for along, coh in ((30.0, 0.5), (110.0, 0.2)):
        h = w = 64
        aux = m.stage_e1(field_tex(h, w, along, coh), aux_mode="unsigned_nearest")
        out, r = bc.run_pass(code("e2"), [aux, NOTEX], params=e2p(aux))
        ok(r)
        ref = e2_ref(aux, E2_BASE, h, table)
        frac = float((np.abs(out[..., 0] - ref[..., 0]) > 0.05).mean())
        note(f"along {along} coherence {coh}: fraction differing > 0.05 / mean GPU, mirror",
             (frac, float(out[..., 0].mean()), float(ref[..., 0].mean())))
        check(f"E2 coherence {coh}: <= 3% of pixels differ", 0.0 if frac <= 0.03 else frac, 0.0)


def test_stage_e2_edges_and_unset():
    """Texel-centre convention: borders match as well as the interior. And an unset axis (zero
    tensor) must not produce NaN (the march falls back to a fixed axis; E3 multiplies by presence 0)."""
    h = w = 64
    aux = m.stage_e1(field_tex(h, w, 45.0, 1.0), aux_mode="unsigned_nearest")
    out, r = bc.run_pass(code("e2"), [aux, NOTEX], params=e2p(aux))
    ok(r)
    ref = e2_ref(aux, E2_BASE, h, gpu_hash_table())
    d = np.abs(out[..., 0] - ref[..., 0]) > 0.05
    band = np.zeros_like(d)
    band[:3] = band[-3:] = True
    band[:, :3] = band[:, -3:] = True
    note("E2 border band: fraction differing", float(d[band].mean()))
    check("E2 border band <= 8%", 0.0 if float(d[band].mean()) <= 0.08 else float(d[band].mean()), 0.0)
    zero_aux = np.zeros((16, 16, 4), F32)
    outz, r = bc.run_pass(code("e2"), [zero_aux, NOTEX], params=e2p(zero_aux))
    ok(r)
    check("E2 unset axis: finite", 0.0 if bool(np.isfinite(outz).all()) else 1.0, 0.0)
    check("E2 unset axis: presence 0", float(np.abs(outz[..., 1]).max()), 1e-6)


def test_stage_e2_stroke_texture_matches():
    """The optional stroke-texture inlet (in2, src_stroke = 1) vs the mirror: a coherent and a partial-
    coherence field, a NON-square texture (the normalized mapping), Grain zoom (2.8 tiles at 0.75) and a
    Density-0.3 soft threshold. The same pixel-fraction criterion as the blob march."""
    for along, coh in ((20.0, 1.0), (110.0, 0.5)):
        h = w = 64
        aux = m.stage_e1(field_tex(h, w, along, coh), aux_mode="unsigned_nearest")
        tex = noise_tex(40, 48, 3)
        params = e2p(aux, src_stroke=1.0, density=0.3)
        out, r = bc.run_pass(code("e2"), [aux, tex], params=params)
        ok(r)
        ref = m.stage_e2(aux, n_steps=16, length=params["reach"], grain=params["grain"], persist="mix",
                         persist_pow=0.5, aux_mode="unsigned_nearest",
                         fill=float(m.fill_from_density(0.3)), texture=tex)
        frac = float((np.abs(out[..., 0] - ref[..., 0]) > 0.05).mean())
        mean_ratio = float(out[..., 0].mean()) / max(float(ref[..., 0].mean()), 1e-9)
        note(f"stroke texture, along {along} coherence {coh}: fraction differing > 0.05 / mean GPU/mirror",
             (frac, mean_ratio))
        check(f"E2 stroke texture {along}/{coh}: <= 3% of pixels differ", 0.0 if frac <= 0.03 else frac, 0.0)
        check(f"E2 stroke texture {along}/{coh}: mean raw within 5%", abs(mean_ratio - 1.0), 0.05)
        check(f"E2 stroke texture {along}/{coh}: presence channel", float(np.abs(out[..., 1] - ref[..., 1]).max()), 1e-4)


def test_stage_e2_coherence_floor_matches():
    """Coh Floor (Terminate + black-out) vs the mirror, floor 0.5: a split field (left coherent, right isotropic:
    the right half goes black), a uniform field INSIDE the ramp (coherence 0.4 -> presence x 0.5) and the stroke-
    texture mode on that ramp field. Channel 0 by the pixel-fraction criterion, the presence channel tightly."""
    h = w = 64
    split = np.where((np.arange(w)[None, :, None] < w // 2), field_tex(h, w, 0.0, 1.0), field_tex(h, w, 0.0, 0.0)).astype(F32)
    cases = [("split", split, {}, None), ("ramp", field_tex(h, w, 20.0, 0.4), {}, None),
             ("ramp+texture", field_tex(h, w, 20.0, 0.4), dict(src_stroke=1.0, density=0.3), noise_tex(40, 48, 3))]
    for label, tex_in, extra, stroke in cases:
        aux = m.stage_e1(tex_in, aux_mode="unsigned_nearest")
        params = e2p(aux, coh_floor=0.5, **extra)
        out, r = bc.run_pass(code("e2"), [aux, stroke if stroke is not None else NOTEX], params=params)
        ok(r)
        dens = extra.get("density", None)
        ref = m.stage_e2(aux, n_steps=16, length=params["reach"], grain=params["grain"], persist="mix",
                         persist_pow=0.5, aux_mode="unsigned_nearest",
                         fill=float(m.fill_from_density(dens if dens is not None else params["density"])),
                         coh_floor=0.5, texture=stroke)
        frac = float((np.abs(out[..., 0] - ref[..., 0]) > 0.05).mean())
        pres_err = float(np.abs(out[..., 1] - ref[..., 1]).max())
        note(f"coh_floor 0.5, {label}: fraction differing > 0.05 / presence max abs err / mean pres GPU, mirror",
             (frac, pres_err, float(out[..., 1].mean()), float(ref[..., 1].mean())))
        check(f"E2 coh_floor {label}: <= 3% of pixels differ", 0.0 if frac <= 0.03 else frac, 0.0)
        check(f"E2 coh_floor {label}: presence channel", pres_err, 1e-4)


# ------------------------------------------------------------- stage E3

def test_stage_e3_matches_both_outlets():
    tex = rand_tensor_tex(64, 64, seed=4)
    aux = m.stage_e1(tex, 0.0, 0.1, "unsigned_nearest")
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
    E2 ~1.7 ms (N = 16, nearest); bench floor ~0.8 ms/pass, so E1 and E3 read as upper bounds.
    The gate is the BLOB path. The stroke-texture mode is reported, not gated: 11-13 ms for E2 with a full-size
    float32 texture at a low Grain (memory-bound; .specify/f_tf_hatch/spike/bench_cost_probe*.py), accepted as a
    heavy optional mode (Matt, 2026-10-29)."""
    tex = rand_tensor_tex(1080, 1920, seed=6)
    aux = m.stage_e1(tex, 0.0, 0.1, "unsigned_nearest")
    aux2 = np.zeros_like(aux)
    aux2[..., 0] = np.random.default_rng(1).random(aux.shape[:2]).astype(F32)
    aux2[..., 1] = 1.0
    aux2[..., 3] = 1.0
    total = 0.0
    for label, c, args, params in (("E1", code("e1"), [tex], dict(E1_BASE, structure_floor=0.1)),
                                   ("E2", code("e2"), [aux, NOTEX], e2p(aux, reach=0.5, grain=0.5)),
                                   ("E3", code("e3"), [aux2], dict(E3_BASE))):
        r = bc.measure(c, args, chain=CHAIN, params=params)
        ms = r.get("ms_per_pass", r.get("ms_per_pass_upper_bound"))
        kind = "gpu_bound" if "ms_per_pass" in r else "upper bound"
        note(f"{label} 1080p ms/pass ({kind})", ms)
        total += ms
    r = bc.measure(code("e2"), [aux, noise_tex(1080, 1920, 9)], chain=CHAIN,
                   params=e2p(aux, reach=0.5, grain=0.5, src_stroke=1.0))
    note("E2 stroke-texture mode 1080p ms/pass (not in the gate)", r.get("ms_per_pass", r.get("ms_per_pass_upper_bound")))
    r = bc.measure(code("e2"), [aux, NOTEX], chain=CHAIN, params=e2p(aux, reach=0.5, grain=0.5, coh_floor=0.5))
    note("E2 coh_floor 0.5 blob mode 1080p ms/pass (not in the gate)", r.get("ms_per_pass", r.get("ms_per_pass_upper_bound")))
    note("sum of the three stages, ms (module gate <= 5)", total)
    check("module cost <= 5 ms at 1080p", 0.0 if total <= 5.0 else total, 0.0)


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
