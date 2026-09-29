"""
bench_fluid_module.py -- f_vf_fluid module-level checks inside Vsynth's real
render context (tasks.md T032, T033, T033a), through the module bench.

  T033a  the solver advances EXACTLY ONCE per frame (only the `r draw` bang on
         inlet 0 may trigger a render; the force/state inlets must be cold).
         Method: a uniform force, two captures a known number of frames apart;
         the increment per frame gives the number of updates per frame (a
         doubled update would show as ~2x).
  T032   two instances in one patch run independently: no "already in use",
         the connected one is driven, the unconnected one stays EXACTLY neutral.
  T033   (part) a fresh load starts from zero state and a finite, neutral outlet.
  T038a  the force tap grid works THROUGH the shipped patcher, not just on the
         bare stage: a static 1024^2 white-noise force (4x minification into the
         256^2 grid -- the HD case) must leave measurably less high-frequency
         energy in the velocity field at taps 8 than at taps 1. The render
         context is 512^2, but the force texture size is independent of it, so
         minification is testable here; 4K (3840^2, ~236 MB over jxf) is not,
         and stays a tier-3 judgement.

Needs Max with tests/bench/bench_module.maxpat open (other patches closed).
Run:  tests/bench.sh tests/bench_fluid_module.py
"""
import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from bench_modules import ENV_NOISE
from harness import check, note, run

MODULE = "f_vf_fluid.maxpat"
SIZE = 512                                       # the module bench's render-context size
F, MU, DT = 0.02, 0.5, 0.01                      # dial defaults (definition.py)


def uniform_force(n=SIZE):
    t = np.zeros((n, n, 4), np.float32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = 1.0, 0.5, 0.5, 1.0     # decoded force (+1, 0)
    return t


def two_instance_wrapper():
    def b(id, **kw):
        return {"box": {"id": id, **kw}}

    def w(s, so, d, di):
        return {"patchline": {"source": [s, so], "destination": [d, di]}}

    boxes = [
        b("mod1", maxclass="bpatcher", name=MODULE, numinlets=1, numoutlets=1, varname="bench_module",
          patching_rect=[20.0, 60.0, 190.0, 150.0]),
        b("mod2", maxclass="bpatcher", name=MODULE, numinlets=1, numoutlets=1, varname="bench_module2",
          patching_rect=[260.0, 60.0, 190.0, 150.0]),
        b("rin1", maxclass="newobj", text="r bench_min1", numinlets=0, numoutlets=1, outlettype=[""],
          patching_rect=[20.0, 20.0, 85.0, 22.0]),
        b("sout1", maxclass="newobj", text="s bench_mout1", numinlets=1, numoutlets=0,
          patching_rect=[20.0, 280.0, 95.0, 22.0]),
        b("sout2", maxclass="newobj", text="s bench_mout2", numinlets=1, numoutlets=0,
          patching_rect=[260.0, 280.0, 95.0, 22.0]),
    ]
    lines = [w("rin1", 0, "mod1", 0), w("mod1", 0, "sout1", 0), w("mod2", 0, "sout2", 0)]
    return {"patcher": {"fileversion": 1,
                        "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64",
                                       "modernui": 1},
                        "classnamespace": "box", "rect": [100.0, 100.0, 500.0, 340.0],
                        "boxes": boxes, "lines": lines}}


def run_wrapper(wrapper, inputs, warmup, settle=6, readback=None):
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    job, job_dir = bc.new_job("module", warmup=warmup, settle=settle, timeout_ms=30000)
    job["wrapper"] = f"mjob_{job['id']}.maxpat"
    job["inputs"] = []
    for i, arr in enumerate(inputs):
        fn = f"in{i + 1}.jxf"
        jxf.write_rgba(job_dir / fn, arr)
        job["inputs"].append(fn)
    job["params"], job["readback"], job["controls"] = [], readback or {}, []
    with open(bc.BENCH_DIR / job["wrapper"], "w") as f:
        json.dump(wrapper, f, indent=2)
    try:
        result = bc.run_job(job, job_dir, ports=bc.MODULE_PORTS)
    finally:
        for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
            old.unlink()
    arrays = {k: jxf.read_rgba(job_dir / f"base_out{k}.jxf")
              for k in (result.get("outputs") or {}).get("base", [])}
    result["errors"] = [e for e in result["errors"] if not e.startswith(ENV_NOISE)]
    return result, arrays


FORCE_N = 1024          # 4x minification into the 256^2 solver grid -- the HD case
SETTINGS = "force 0.06, dt 0.02, viscosity 0., project 1., drag 0.5, gain 1., taps %d"


def smooth_force(n=FORCE_N, amp=0.6):
    """A smooth DIVERGENCE-FREE flow (Taylor-Green) -- the signal the tap grid
    must preserve. It must be divergence-free: a gradient field such as
    (sin 2pi x, sin 2pi y) is exactly what `project` removes, so the solver
    annihilates it and every measurement becomes a ratio of numerical noise
    (found the hard way 2026-09-29)."""
    y, x = np.meshgrid(np.arange(n) / n, np.arange(n) / n, indexing="ij")
    u = np.sin(2.0 * np.pi * x) * np.cos(2.0 * np.pi * y)
    v = -np.cos(2.0 * np.pi * x) * np.sin(2.0 * np.pi * y)
    t = np.zeros((n, n, 4), np.float32)
    t[..., 0] = 0.5 + 0.5 * amp * u
    t[..., 1] = 0.5 + 0.5 * amp * v
    t[..., 2], t[..., 3] = 0.5, 1.0
    return t


def noisy_force(n=FORCE_N, seed=7, sigma=0.5):
    """The same smooth flow plus per-pixel white noise -- the real case a video
    force presents. A PURE noise field is the wrong stimulus: it is all noise and
    no signal, so a correct area average drives it toward zero and any metric
    then measures amplitude, not cleanliness (found 2026-09-29, first attempt)."""
    rng = np.random.default_rng(seed)
    t = smooth_force(n)
    noise = rng.normal(0.0, sigma, (n, n, 2)).astype(np.float32)
    t[..., :2] = np.clip(t[..., :2] + 0.5 * noise, 0.0, 1.0)
    return t



def taps_wrapper(taps):
    """mb.make_wrapper plus a loadbang that applies SETTINGS. The job's own
    `params` cannot be used here: bench_module.js captures "base" at frame W+1,
    BEFORE it sends them, so a param set that way never reaches the frame we
    measure."""
    w = mb.make_wrapper(MODULE, 1, 1)
    boxes = w["patcher"]["boxes"]
    boxes.append({"box": {"id": "lb", "maxclass": "newobj", "text": "loadbang",
                          "numinlets": 1, "numoutlets": 1, "outlettype": ["bang"],
                          "patching_rect": [320.0, 20.0, 60.0, 22.0]}})
    boxes.append({"box": {"id": "setmsg", "maxclass": "message", "text": SETTINGS % taps,
                          "numinlets": 2, "numoutlets": 1, "outlettype": [""],
                          "patching_rect": [320.0, 48.0, 420.0, 22.0]}})
    w["patcher"]["lines"].append({"patchline": {"source": ["lb", 0],
                                                "destination": ["setmsg", 0]}})
    w["patcher"]["lines"].append({"patchline": {"source": ["setmsg", 0],
                                                "destination": ["mod", 0]}})
    return w


def n_from_u(u, a):
    """Updates needed to reach velocity u from rest under u <- a*(u + F)."""
    if abs(a - 1.0) < 1e-9:
        return u / F
    return float(np.log(1.0 - u * (1.0 - a) / (F * a)) / np.log(a))


def test_T033a_solver_advances_once_per_frame():
    us = {}
    for warmup in (12, 32):
        r, arrays = run_wrapper(mb.make_wrapper(MODULE, 1, 1), [uniform_force()], warmup)
        assert not r["errors"], r["errors"]
        out = arrays[1]
        assert out.shape[:2] == (SIZE, SIZE)
        c = out[SIZE // 2, SIZE // 2]
        us[warmup] = 2.0 * (float(c[0]) - 0.5)                 # gain 1: encoded R = 0.5 + 0.5*u
        note(f"warmup {warmup}: velocity u at the centre (uniform force, gain 1)", us[warmup])
    assert 0.0 < us[12] < us[32] < 1.0, f"velocity must grow and stay below the clamp: {us}"
    dframes = 32 - 12
    best = None
    for label, a in (("no drag", 1.0), ("drag 0.5", float(np.exp(-MU * DT)))):
        rate = (n_from_u(us[32], a) - n_from_u(us[12], a)) / dframes
        note(f"updates per frame assuming {label}", rate)
        if best is None or abs(rate - 1.0) < abs(best - 1.0):
            best = rate
    check("|updates per frame - 1| (a doubled update would read ~1)", abs(best - 1.0), 0.1)


def test_T032_two_instances_are_independent():
    r, arrays = run_wrapper(two_instance_wrapper(), [uniform_force()], warmup=20)
    assert not r["errors"], f"errors (an 'already in use' would show here): {r['errors']}"
    assert set(arrays) >= {1, 2}, f"both outlets must produce a frame, got {sorted(arrays)}"
    a, b = arrays[1], arrays[2]
    driven = float(np.abs(a[..., :2] - 0.5).max())
    check("instance 1 (force connected) is driven away from neutral (must be > 0.01)",
          max(0.0, 0.01 - driven), 0.0)
    neutral = np.zeros_like(b)
    neutral[..., :3], neutral[..., 3] = 0.5, 1.0
    check("instance 2 (unconnected) is EXACTLY neutral", float(np.abs(b - neutral).max()), 0.0)
    note("instance 1 max |R,G - 0.5|", driven)
    note("both outlets are render size", float(a.shape[0] == SIZE and b.shape[0] == SIZE))


def test_T033_fresh_load_is_finite_and_starts_at_zero():
    r, arrays = run_wrapper(mb.make_wrapper(MODULE, 1, 1), [], warmup=14)      # inlet UNCONNECTED
    assert not r["errors"], r["errors"]
    out = arrays.get(1)
    assert out is not None, "unconnected module produced no outlet frame (1x1 output?)"
    assert out.shape[:2] == (SIZE, SIZE), f"unconnected outlet is {out.shape[:2]}, not render size"
    assert np.isfinite(out).all()
    neutral = np.zeros_like(out)
    neutral[..., :3], neutral[..., 3] = 0.5, 1.0
    check("unconnected inlet, fresh load: outlet exactly neutral, render size",
          float(np.abs(out - neutral).max()), 0.0)


def hf_rms(u):
    """RMS of the field minus its own 3x3 box-smoothed self."""
    p = np.pad(u, ((1, 1), (1, 1), (0, 0)), mode="edge")
    s = np.zeros_like(u)
    for dy in (0, 1, 2):
        for dx in (0, 1, 2):
            s += p[dy:dy + u.shape[0], dx:dx + u.shape[1]]
    return float(np.sqrt(np.mean((u - s / 9.0) ** 2)))


def solve(force, taps, readback, warmup=48):
    """One settled velocity field, decoded, with the settings proven to have landed."""
    r, arrays = run_wrapper(taps_wrapper(taps), [force], warmup=warmup, readback=readback)
    assert not r["errors"], r["errors"]
    out = arrays[1]
    assert out.shape[:2] == (SIZE, SIZE)
    # Prove the settings landed. If the loadbang silently did nothing, every arm
    # would run at defaults and show no difference -- a false negative that looks
    # exactly like "taps does nothing" (the 2026-09-28 tier-3 result).
    rb = r.get("params_readback") or {}
    got = list((rb.get("taps") or {}).values())
    assert got and abs(got[0] - taps) < 0.5, \
        f"settings never reached the module: taps reads {got}, wanted {taps}"
    visc = list((rb.get("viscosity") or {}).values())
    assert visc and visc[0] < 1e-6, \
        f"viscosity must be 0 here or it, not taps, does the smoothing: {visc}"
    u = 2.0 * (out[..., :2].astype(np.float64) - 0.5)
    assert float(np.abs(u).max()) < 0.98, "output is clamping -- lower force or gain"
    return u


def test_T038a_tap_grid_reduces_force_noise_through_the_module():
    readback = {"taps": ["fluid_adv"], "viscosity": ["fluid_spec"]}
    clean, noisy = smooth_force(), noisy_force()

    # Reference: the noise-free flow. Run at both tap counts -- they must agree,
    # which is the "smooth forces are unchanged by taps, by design" claim,
    # verified through the shipped module rather than asserted.
    ref = {t: solve(clean, t, readback) for t in (1, 8)}
    ref_rms = float(np.sqrt(np.mean(ref[8] ** 2)))
    smooth_delta = float(np.sqrt(np.mean((ref[1] - ref[8]) ** 2))) / max(ref_rms, 1e-12)
    note("smooth force: relative difference between taps 1 and taps 8", smooth_delta)
    check("a smooth force must be near-unchanged by taps (by design)", smooth_delta, 0.1)

    err = {}
    for t in (1, 8):
        u = solve(noisy, t, readback)
        err[t] = float(np.sqrt(np.mean((u - ref[8]) ** 2))) / max(ref_rms, 1e-12)
        note(f"taps {t}: relative error of the noisy-force field vs the clean flow", err[t])
        note(f"taps {t}: residual high-frequency rms", hf_rms(u))

    assert err[1] > 0.0, "the noise had no effect at all -- is the force reaching the solver?"
    ratio = err[1] / max(err[8], 1e-12)
    note("noise rejection, taps 1 -> 8 (tier 1 predicts a large factor at 4x minification)", ratio)
    check("tap grid must cut the noise-induced error by at least 1.5x (shortfall)",
          max(0.0, 1.5 - ratio), 0.0)


if __name__ == "__main__":
    bc.require_bench(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    sys.exit(run(globals()))
