"""
bench_tf_hatch.py -- Tier 2 verification for f_tf_hatch: the real stage
codeboxes (src/f_tf_hatch/codebox_*.gen) run on the GPU through the Max test
bench and are diffed against the NumPy mirror in tests/modules/tf_hatch/tf_hatch_mirror.py, one
stage per job (multi-stage modules are benched stage by stage). Tasks
T010-T017 of .specify/f_tf_hatch/tasks.md.

WRITTEN-NOT-RUN in the parallel T001 build's scope (parent constraint: no
bench execution, no live Max session); REGISTERED in tests/lib/benchdeps.DATA
via .specify/f_tf_hatch/REGISTRATION_NOTES.md, NOT added to tests/bench.sh
DEFAULT until Matt makes it a regression gate (the tensormap T021
discipline). The spike's cost model (tests/records/spike_tf_hatch_costshape.py,
plan ADR-1 amendment) is the prediction these runs resolve:
  e1 ~25 stmts / e2 ~20 / e3 ~45 -- ~6 taps/pixel, 0 loops, 3 passes
  -> model <= 2.7 ms per chain at 1080p against the ~0.9 ms/pass floor.

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/modules/tf_hatch/bench_tf_hatch.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 160

import paths as _paths
import sys
from pathlib import Path

import numpy as np

import benchclient as bc
from harness import check, note, run
import tf_hatch_mirror as m          # the tier-1 mirror

REPO = _paths.REPO
SRC = REPO / "src" / "f_tf_hatch"
F32 = np.float32
TOL = 1e-3


def code(name):
    return (SRC / f"codebox_stage_{name}.gen").read_text()


def rand_tensor_tex(h, w, seed=0, strength=100.0):
    """A random OUTLET-0-FORMAT tensor texture (glyph ADR-3: fixtures build
    outlet-0-format textures; B channel unclamped float32)."""
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


def border_err(a, b, k=2):
    """Max abs error restricted to the outermost k rows/columns."""
    d = np.abs(a - b)
    mask = np.zeros(d.shape[:2], bool)
    mask[:k] = True
    mask[-k:] = True
    mask[:, :k] = True
    mask[:, -k:] = True
    return float(d[mask].max())


def ok(r):
    check("status ok", 0 if r["status"] == "ok" else 1, 0)


# ------------------------------------------------------------- stage E1 (T011)

def test_stage_e1_compiles_and_matches():
    tex = rand_tensor_tex(64, 64, seed=1)
    # structure_floor 0 here: the mirror default, presence = 1 wherever any
    # structure exists (the floor ramp itself has its own leg below)
    params = {"strength": 100.0, "angle_offset": 0.0, "coherence_gate": 0.25,
              "structure_floor": 0.0}
    out, r = bc.run_pass(code("e1"), [tex], params=params)
    ok(r)
    ref = m.stage_e1(tex, 100.0, 0.25, 0.0)
    check("E1 ca", float(np.abs(out[..., 0] - ref[..., 0]).max()), 1e-4)
    check("E1 sa", float(np.abs(out[..., 1] - ref[..., 1]).max()), 1e-4)
    check("E1 commit", float(np.abs(out[..., 2] - ref[..., 2]).max()), 1e-4)
    check("E1 pres", float(np.abs(out[..., 3] - ref[..., 3]).max()), 1e-5)
    # borders: the read is at norm (in-bounds on both GPU and sim), so the
    # border rows must match the interior-quality tolerance
    check("E1 borders", border_err(out, ref), 1e-4)
    # eps-guard boundary: an exactly-zero tensor draws nothing (pres = 0) and
    # leaves the axis unset (no atan2 artifact)
    zero = np.zeros((8, 8, 4), F32)
    outz, r = bc.run_pass(code("e1"), [zero], params=params)
    ok(r)
    check("E1 zero tensor pres=0", float(np.abs(outz[..., 3]).max()), 1e-6)
    check("E1 zero tensor axis unset", float(np.abs(outz[..., :2]).max()), 1e-6)


def test_stage_e1_structure_floor():
    """The presence ramp on the GPU vs the mirror: the new dial, 2026-10-28.
    Floors 0.1 (the shipped default), 0.5 and 0.9 on a random tensor field
    whose encoded traces span the ramps; commit/axis must be unaffected."""
    tex = rand_tensor_tex(64, 64, seed=7)
    for fl in (0.1, 0.5, 0.9):
        params = {"strength": 100.0, "angle_offset": 0.0,
                  "coherence_gate": 0.25, "structure_floor": fl}
        out, r = bc.run_pass(code("e1"), [tex], params=params)
        ok(r)
        ref = m.stage_e1(tex, 100.0, 0.25, 0.0, fl)
        note(f"floor {fl}: mean presence (GPU)", float(out[..., 3].mean()))
        check(f"E1 floor {fl} pres", float(np.abs(out[..., 3] - ref[..., 3]).max()), 1e-4)
        check(f"E1 floor {fl} commit unaffected",
              float(np.abs(out[..., 2] - ref[..., 2]).max()), 1e-4)


def test_stage_e1_offset_and_gate():
    tex = rand_tensor_tex(64, 64, seed=2)
    for off, gate in ((1.0, 0.25), (-1.0, 0.6)):
        params = {"strength": 100.0, "angle_offset": off, "coherence_gate": gate}
        out, r = bc.run_pass(code("e1"), [tex], params=params)
        ok(r)
        ref = m.stage_e1(tex, 100.0, gate, off)
        check(f"E1 offset {off} gate {gate} ca", float(np.abs(out[..., 0] - ref[..., 0]).max()), 1e-4)
        check(f"E1 offset {off} gate {gate} commit", float(np.abs(out[..., 2] - ref[..., 2]).max()), 1e-4)


# ------------------------------------------------------------- stage E2 (T013)

def test_stage_e2_compiles_and_matches():
    tex = rand_tensor_tex(64, 64, seed=3)
    aux = m.stage_e1(tex)
    out, r = bc.run_pass(code("e2_T"), [aux], params={})
    ok(r)
    ref = m.stage_e2(aux)
    check("E2 u", float(np.abs(out[..., 0] - ref[..., 0]).max()), 1e-5)
    check("E2 v", float(np.abs(out[..., 1] - ref[..., 1]).max()), 1e-5)
    check("E2 passthrough", float(np.abs(out[..., 2:] - aux[..., 2:]).max()), 1e-6)
    check("E2 borders", border_err(out, ref), 1e-5)


# ------------------------------------------------------------- stage E3 (T015)

def test_stage_e3_matches_both_outlets():
    tex = rand_tensor_tex(64, 64, seed=4)
    aux2 = m.stage_e2(m.stage_e1(tex))
    params = {"density": 0.5, "weight": 0.1, "softness": 0.05,
              "elongation": 3.0, "phase": 0.0, "regularity": 0.5,
              "bypass_gate": 0.0}
    outs, r = bc.run_pass(code("e3"), [aux2], params=params, all_outputs=True)
    ok(r)
    ref0, ref1 = m.stage_e3(aux2)
    # reg 0.5: the line-hash is active — GPU/NumPy sine argument-reduction
    # differ in the last bits at hash arguments ~1e9 (see the sweep test's
    # tolerance note); sub-hairline edge shifts only.
    check("E3 outlet0 marks", float(np.abs(outs[0][..., 0] - ref0[..., 0]).max()), 1e-2)
    check("E3 outlet1 marks", float(np.abs(outs[1][..., 0] - ref1[..., 0]).max()), 1e-2)
    check("E3 borders", border_err(outs[0][..., 0], ref0[..., 0]), 1e-2)
    # commit -> dot endpoint: commit 0 renders nothing on the GPU
    auxz = aux2.copy()
    auxz[..., 2] = F32(0.0)
    outz, r = bc.run_pass(code("e3"), [auxz], params=params, all_outputs=True)
    ok(r)
    check("E3 commit 0 black", float(np.abs(outz[0][..., :3]).max()), 1e-6)
    # bypass: both outlets black (bypass_mode "param"; the codebox-side mix)
    params_b = dict(params, bypass_gate=1.0)
    outb, r = bc.run_pass(code("e3"), [aux2], params=params_b, all_outputs=True)
    ok(r)
    check("E3 bypass outlet0 black", float(np.abs(outb[0][..., :3]).max()), 1e-6)
    check("E3 bypass outlet1 black", float(np.abs(outb[1][..., :3]).max()), 1e-6)


def test_stage_e3_param_sweeps_match_mirror():
    tex = rand_tensor_tex(48, 64, seed=5)
    aux2 = m.stage_e2(m.stage_e1(tex))
    for den, ph, reg, soft in ((0.3, 0.0, 1.0, 0.0), (0.7, 0.25, 0.0, 0.2)):
        params = {"density": den, "weight": 0.1, "softness": soft,
                  "elongation": 3.0, "phase": ph, "regularity": reg,
                  "bypass_gate": 0.0}
        outs, r = bc.run_pass(code("e3"), [aux2], params=params, all_outputs=True)
        ok(r)
        ref0, _ = m.stage_e3(aux2, density=den, phase=ph, regularity=reg,
                             softness=soft)
        check(f"E3 den {den} ph {ph} reg {reg} soft {soft}",
              float(np.abs(outs[0][..., 0] - ref0[..., 0]).max()),
              # at regularity 0 the line-hash runs on sin(line_idx*127.1*43758)
              # — argument ~1e9, where GPU and NumPy sine argument-reduction
              # legitimately differ in the last bits (weave's idiom is a
              # LOOK; exact cross-impl match is not achievable). Sub-hairline
              # edge shifts only; the reg-1.0 case (hash zeroed) stays at
              # 3.5e-6 and proves the geometry itself.
              1e-2)


# ------------------------------------------------------------- cost (T016)
# The T001 gate's resolver: measured per-stage and chain cost vs the spike's
# model. M3 Max numbers; the M1 is unmeasured (spec OQ7).

def test_cost_per_stage_and_chain():
    tex = rand_tensor_tex(1080, 1920, seed=6)
    aux = m.stage_e1(tex)
    for label, c, args, params in (
            ("E1", code("e1"), [tex],
             {"strength": 100.0, "angle_offset": 0.0, "coherence_gate": 0.25}),
            ("E2", code("e2_T"), [aux], {}),
            ("E3", code("e3"), [m.stage_e2(aux)],
             {"density": 0.5, "weight": 0.1, "softness": 0.05,
              "elongation": 3.0, "phase": 0.0, "regularity": 0.5,
              "bypass_gate": 0.0})):
        r = bc.measure(c, args, chain=32, params=params)
        if "ms_per_pass" in r:
            note(f"{label} 1080p ms/pass (gpu_bound)", r["ms_per_pass"])
        else:
            note(f"{label} 1080p ms/pass (upper bound)", r["ms_per_pass_upper_bound"])
    # model: <= 2.7 ms per chain at 1080p (3 x 0.9 ms/pass floor)
    # NOTE the chain here runs stages 32x INDEPENDENTLY (not fed forward);
    # the sum of the three per-stage numbers is the chain-cost model check.


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))