"""
bench_fluid.py -- f_vf_fluid Phase 1 (tasks.md T015-T022): every stage codebox
under src/f_vf_fluid/ run on the GPU through the codebox bench and diffed
against the NumPy mirror in fluid_mirror.py, then the whole chain host-sequenced
over many frames (the bench drives one codebox per job; plan ADR-10), then cost.

Stage jobs (one pass per job, outputs chained from Python):
    adv  in1 = bang stand-in, in2 = force, in3 = previous state
    fx, fy, iy, ix  in1 = previous stage
    spec in1 = spectral texture
    enc  in1 = bang stand-in, in2 = force (render res), in3 = velocity

Needs Max with tests/bench/bench.maxpat open.
Run:  tests/bench.sh tests/bench_fluid.py
"""
import sys
import time
from pathlib import Path

import numpy as np

import benchclient as bc
import fluid_mirror as fm
from fluid_mirror import Params
from gpu_sim import F32
from harness import check, note, run
from test_fft_separable import make_image, pack, rel_err
from test_fluid_mirror import rand_force, rand_state, smooth_state, taylor_green

SRC = Path(__file__).resolve().parent.parent / "src" / "f_vf_fluid"
N = 256
FILES = {"adv": "codebox_adv.gen", "fx": "codebox_dft_fx.gen", "fy": "codebox_dft_fy.gen",
         "spec": "codebox_spec.gen", "iy": "codebox_dft_iy.gen", "ix": "codebox_dft_ix.gen",
         "enc": "codebox_enc.gen"}
BANG = np.zeros((4, 4, 4), np.float32)          # stand-in for the `r draw` bang inlet


def code(stage):
    return (SRC / FILES[stage]).read_text()


def gpu(stage, inputs, dim=None, params=None, timeout_ms=30000):
    out, r = bc.run_pass(code(stage), inputs, dim=dim, params=params or {}, timeout_ms=timeout_ms)
    if r["status"] != "ok" or out is None:
        raise AssertionError(f"{stage}: bench job failed: {r['status']} {r['errors']} ({r['job_dir']})")
    return out


def g_adv(state, force, p):
    return gpu("adv", [BANG, force, state], dim=(N, N),
               params={"dt": p.dt, "force": p.force, "src_vecfield": p.src_vecfield})


def g_spec(tex, p):
    return gpu("spec", [tex], params={"viscosity": p.viscosity, "project": p.project,
                                      "drag": p.drag, "dt": p.dt})


def g_step(state, force, p):
    """One solver frame from real GPU passes: adv -> fx -> fy -> spec -> iy -> ix."""
    t = g_adv(state, force, p)
    t = gpu("fx", [t])
    t = gpu("fy", [t])
    t = g_spec(t, p)
    t = gpu("iy", [t])
    return gpu("ix", [t])


def rel(a, b):
    return float(np.max(np.abs(a - b)) / max(float(np.max(np.abs(b))), 1e-30))


def amp_along(state, ref):
    num = np.sum(state[..., 0].astype(np.float64) * ref[..., 0]
                 + state[..., 2].astype(np.float64) * ref[..., 2])
    return num / np.sum(ref[..., 0].astype(np.float64) ** 2 + ref[..., 2].astype(np.float64) ** 2)


# ----------------------------------------------------------------- T015

def test_T015_every_stage_compiles_and_runs():
    st = smooth_state(N, 1)
    spectral = fm.fft2_np(st)
    force = rand_force(64, 64, 2)
    runs = {
        "adv": lambda: gpu("adv", [BANG, force, st], dim=(N, N)),
        "fx": lambda: gpu("fx", [st]), "fy": lambda: gpu("fy", [st]),
        "spec": lambda: gpu("spec", [spectral]),
        "iy": lambda: gpu("iy", [spectral]), "ix": lambda: gpu("ix", [spectral]),
        "enc": lambda: gpu("enc", [BANG, rand_force(90, 120, 3), st], dim=(120, 90)),
    }
    for name, fn in runs.items():
        out = fn()
        assert np.isfinite(out).all(), f"{name}: non-finite output"
        print(f"    ok   {name}: compiles, runs, output {out.shape[:2]} finite")


# ----------------------------------------------------------------- T016

def test_T016_spec_matches_mirror():
    tex = fm.fft2_np(rand_state(N, 6))                # white noise: Nyquist bins included
    cases = [(0.0, 0.0, 0.0, 0.01), (0.05, 0.5, 0.2, 0.01), (0.3, 1.0, 0.0, 0.003),
             (2.0, 1.0, 1.0, 0.05), (1e-5, 0.7, 0.0, 0.05), (0.0, 1.0, 0.0, 0.01)]
    for v, pr, dr, dt in cases:
        p = Params(viscosity=v, project=pr, drag=dr, dt=dt)
        err = rel(g_spec(tex, p), fm.spec(tex, v, pr, dr, dt))
        check(f"spec nu={v:g} project={pr:g} drag={dr:g} dt={dt:g}: rel err vs mirror", err, 1e-4)


# ----------------------------------------------------------------- T017

def test_T017_adv_matches_mirror():
    st = smooth_state(N, 3, amp=0.5)
    for label, fsize, src, tol in (("force 256 (1:1)", 256, 1.0, 1e-4),
                                   ("force 128 (magnified 2x)", 128, 1.0, 1e-3)):
        force = rand_force(fsize, fsize, 4)
        p = Params(dt=0.05, force=0.3, src_vecfield=src)
        err = np.max(np.abs(g_adv(st, force, p) - fm.adv(st, force, p.dt, p.force, p.src_vecfield)))
        check(f"adv {label}: max err vs mirror", err, tol)
    force = rand_force(256, 256, 5)
    p0 = Params(dt=0.05, force=0.3, src_vecfield=0.0)
    off = g_adv(st, force, p0)
    check("adv src_vecfield=0: equals the force-free mirror", np.max(np.abs(off - fm.adv(st, None, p0.dt, 0, 0))), 1e-5)
    # seam: whole-texel displacements (u in {0.25, .5, .75}, dt .25 -> 16, 32, 48 texels) are an
    # exact wrapped gather (no interpolation), so any clamping at the edge shows up at once
    ucol = np.random.default_rng(9).choice(np.array([0.25, 0.5, 0.75], F32), N)
    s2 = np.zeros((N, N, 4), F32)
    s2[..., 0] = ucol[None, :]
    got = g_adv(s2, force, Params(dt=0.25, force=0.0, src_vecfield=0.0))
    want = ucol[(np.arange(N) - np.rint(ucol * 0.25 * N).astype(int)) % N]
    check("adv periodic seam: exact wrapped gather", np.max(np.abs(got[..., 0] - want[None, :])), 1e-6)
    big = rand_force(512, 512, 6)
    pb = Params(dt=0.05, force=0.3, src_vecfield=1.0)
    e = np.max(np.abs(g_adv(st, big, pb) - fm.adv(st, big, pb.dt, pb.force, pb.src_vecfield)))
    note("adv force 512 (MINIFIED 2x): max err vs bilinear mirror (nearest-like, informational)", e)


# ----------------------------------------------------------------- T018

def test_T018_enc_matches_mirror():
    vel = smooth_state(N, 5, amp=0.5)
    for (h, w) in ((90, 120), (60, 100), (256, 256)):
        force = rand_force(h, w, 7)
        for gain, gate, src in ((1.5, 0.0, 1.0), (1.5, 1.0, 1.0), (1.5, 1.0, 0.0),
                                (30.0, 0.0, 1.0), (1.0, 0.0, 0.0)):
            out = gpu("enc", [BANG, force, vel], dim=(w, h),
                      params={"gain": gain, "bypass_gate": gate, "src_vecfield": src})
            want = fm.enc(force, vel, gain, gate, src)
            check(f"enc {h}x{w} gain={gain:g} gate={gate:g} src={src:g}: max err vs mirror",
                  np.max(np.abs(out - want)), 1e-5)
    force = rand_force(90, 120, 8)
    byp = gpu("enc", [BANG, force, vel], dim=(120, 90), params={"gain": 1.0, "bypass_gate": 1.0, "src_vecfield": 1.0})
    check("bypass, connected: force passes through", np.max(np.abs(byp - force)), 1e-6)
    neu = gpu("enc", [BANG, force, vel], dim=(120, 90), params={"gain": 1.0, "bypass_gate": 1.0, "src_vecfield": 0.0})
    check("bypass, unconnected: exactly neutral", np.max(np.abs(neu - fm.neutral(90, 120))), 0)


# ----------------------------------------------------------------- T019

def test_T019_dft_stages():
    u, v = make_image(N, N, 1), make_image(N, N, 2)
    tex = pack(u, v)
    fwd = gpu("fy", [gpu("fx", [tex])])
    for c, name, ref in ((0, "u", u), (2, "v", v)):
        z = fwd[..., c].astype(np.float64) + 1j * fwd[..., c + 1]
        check(f"forward fx->fy {name} vs np.fft.fft2 (rel)", rel_err(z, np.fft.fft2(ref.astype(np.float64))), 1e-5)
    back = gpu("ix", [gpu("iy", [fwd])])
    check("round trip fx->fy->iy->ix: |u' - u|", np.max(np.abs(back[..., 0] - u)), 1e-5)
    check("round trip fx->fy->iy->ix: |v' - v|", np.max(np.abs(back[..., 2] - v)), 1e-5)
    check("ix outputs Im = 0 exactly", np.max(np.abs(back[..., [1, 3]])), 0)
    # NaN / Inf guard: contaminate one row of the ix input; that row must come out 0, others unchanged
    clean = gpu("ix", [fwd])
    dirty = fwd.copy()
    dirty[10, 5, 0], dirty[10, 90, 2] = np.nan, np.inf
    g = gpu("ix", [dirty])
    assert np.isfinite(g).all(), "ix let a non-finite value through"
    rows = np.arange(N) != 10
    check("ix guard: contaminated row -> 0", np.max(np.abs(g[10])), 0)
    check("ix guard: other rows unchanged", np.max(np.abs(g[rows] - clean[rows])), 0)


# ----------------------------------------------------------------- T020

def test_T020_multiframe_matches_mirror_and_taylor_green():
    """SC3/SC4 on the GPU path: 100 frames of the real stage chain (Python passes
    each stage's GPU output to the next) vs the mirror, from a Taylor-Green state."""
    dt, nu = 0.003, 0.084
    p = Params(dt=dt, viscosity=nu, project=1.0, force=0.0, src_vecfield=0.0)
    st0 = taylor_green(N)
    g, m = st0, st0
    t0 = time.time()
    worst = 0.0
    for f in range(1, 101):
        g = g_step(g, BANG, p)
        m = fm.step(m, None, p)
        worst = max(worst, float(np.max(np.abs(g - m))))
        if f % 10 == 0:
            note(f"frame {f}: |GPU - mirror| (running max {worst:.2e})", np.max(np.abs(g - m)))
        if f in (10, 50, 100):
            expect = np.exp(-nu * 2 * (2 * np.pi) ** 2 * dt * f)
            got = amp_along(g, st0)
            check(f"GPU Taylor-Green frame {f}: amplitude {got:.4f} vs analytic {expect:.4f} (rel)",
                  abs(got - expect) / expect, 0.05)
    check("100 frames: max |GPU - mirror| over all frames", worst, 1e-4)
    print(f"    ...  100 frames x 6 jobs in {time.time() - t0:.0f}s")


def test_T020b_force_path_in_the_loop():
    """The force injection path on the GPU: 30 frames with a force field."""
    rng = np.random.default_rng(12)
    force = np.zeros((N, N, 4), F32)
    sm = smooth_state(N, 8, amp=1.0)
    force[..., 0], force[..., 1] = 0.5 + 0.5 * sm[..., 0], 0.5 + 0.5 * sm[..., 2]
    force[..., 2], force[..., 3] = 0.5, 1.0
    p = Params(dt=0.02, viscosity=0.02, project=0.8, drag=0.1, force=0.05, src_vecfield=1.0)
    g = m = fm.zero_state(N)
    for f in range(1, 31):
        g = g_step(g, force, p)
        m = fm.step(m, force, p)
    check("30 frames with force: max |GPU - mirror|", np.max(np.abs(g - m)), 1e-4)
    note("state magnitude after 30 frames (so the test is not vacuous)", np.max(np.abs(m)))


# ----------------------------------------------------------------- T021

def stage_cost(stage, inputs, dim, params=None):
    for chain in (8, 16, 32):
        r = bc.measure(code(stage), inputs, dim=dim, chain=chain, params=params or {})
        if r.get("gpu_bound"):
            return r["ms_per_pass"], chain, True
    return r.get("ms_per_pass_upper_bound", float("nan")), chain, False


def test_T021_cost_per_stage():
    """NF-001: solver stages at 256^2 + enc at a 1280x720 render size; the sum
    must fit the 3 ms/frame budget (else evaluate 128^2)."""
    st = smooth_state(N, 1)
    spectral = fm.fft2_np(st)
    force720 = rand_force(720, 1280, 2)
    plan = [("adv", [BANG, rand_force(N, N, 2), st], (N, N)), ("fx", [st], None), ("fy", [st], None),
            ("spec", [spectral], None), ("iy", [spectral], None), ("ix", [spectral], None),
            ("enc", [BANG, force720, st], (1280, 720))]
    total = 0.0
    for stage, inputs, dim in plan:
        ms, chain, bound = stage_cost(stage, inputs, dim)
        total += ms
        print(f"    ...  {stage:5s} {ms:7.3f} ms/pass  (chain {chain}, {'GPU bound' if bound else 'UPPER BOUND, not resolved'})")
    check("sum of stage costs (ms/frame) vs the 3 ms budget", total, 3.0)


# ----------------------------------------------------------------- T022

def test_T022_soak_at_extremes():
    """SC5 (GPU part): host-sequenced frames at parameter extremes stay finite."""
    rand = rand_force(N, N, 11)
    uniform = np.zeros((N, N, 4), F32)
    uniform[..., 0], uniform[..., 1], uniform[..., 2], uniform[..., 3] = 1.0, 0.0, 0.5, 1.0
    cases = {
        "thick honey, big dt": (Params(dt=0.05, force=0.5, viscosity=50.0, drag=5.0, project=1.0, src_vecfield=1.0), rand, 100),
        "inviscid, no drag, big dt": (Params(dt=0.05, force=0.5, viscosity=0.0, drag=0.0, project=1.0, src_vecfield=1.0), rand, 100),
        "unprojected, uniform force": (Params(dt=0.05, force=0.5, viscosity=0.0, drag=0.0, project=0.0, src_vecfield=1.0), uniform, 100),
    }
    for label, (p, force, frames) in cases.items():
        s = fm.zero_state(N)
        for f in range(frames):
            s = g_step(s, force, p)
            assert np.isfinite(s).all(), f"{label}: non-finite state at frame {f}"
        out = gpu("enc", [BANG, force, s], dim=(160, 90), params={"gain": 1.0, "bypass_gate": 0.0, "src_vecfield": 1.0})
        assert np.isfinite(out).all() and out.min() >= 0.0 and out.max() <= 1.0, f"{label}: outlet out of range"
        print(f"    ok   {label}: finite for {frames} frames, |u|max = {np.abs(s).max():.3g}, outlet in [0, 1]")


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
