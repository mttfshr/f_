"""
bench_immiscible_module.py -- f_vf_immiscible module-level checks inside Vsynth's real render
context (tasks.md T021, T022), through the module bench: the SHIPPED patcher, not the bare stages.

  T022a  reset fires once on load: a fresh module with nothing connected has a seeded (not
         uniform) phi, finite, render size, and its velocity outlet is EXACTLY neutral
         (an unconnected inlet reads as zero velocity, FR-001).
  T022b  the solver advances EXACTLY ONCE per frame (FR-006): a white source on inlet 0
         deposits phi += e (1 - phi) per frame (e = inject^3, thresh below the white), so two
         captures a known number of frames apart give the number of updates per frame; a
         doubled update would read ~2. A one-frame lag of the cold velocity input (the
         inab/pass draw-order hazard, plan ADR-1 amendment) cannot show on static inputs:
         that part rests on the wiring (adv in0 is the only hot inlet) and on the live look.
  T022c  the vecfield inlets, inab and the blend work through the module: A and B uniform
         flows, out2 stays between them, Mix 0 gives exactly A, Mix 100 exactly B, and the
         phi-grey outlet does not move with Mix. Checks the `mix_pct` setting landed on adv
         and enc (read back).
  T022d  two instances run independently: no "already in use", the driven one moves, the
         unconnected one stays EXACTLY neutral on out2 (FR-013).

Bypass neutral outlets, parameter arrival and outlet frames for every module are checked by
tests/contracts/bench_modules.py (BYPASS_EXPECT carries f_vf_immiscible).

Needs Max with tests/bench/bench_module.maxpat open (other patches closed).
Run:  tests/bench.sh tests/modules/immiscible/bench_immiscible_module.py
"""
GROUP = "regression"   # tests/bench.sh runs "regression"; see tests/lib/benchdeps.py list --group
ORDER = 81

import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from bench_modules import ENV_NOISE
from harness import check, note, run

MODULE = "f_vf_immiscible.maxpat"
SIZE = 512                                       # the module bench's render-context size
INJECT, THRESH, PULL = 0.3, 0.5, 0.3             # dial defaults (definition.py)
E = INJECT ** 3                                  # per-frame deposit rate at luma 1
PULL_MAX = 0.05                                  # spec's per-frame mean pull rate at pull = 1
PE = PULL_MAX * PULL ** 3
UA, UB = 0.6, 0.2                                # decoded uniform velocities of the two flows


def solid(rgba, n=SIZE):
    t = np.zeros((n, n, 4), np.float32)
    t[...] = np.array(rgba, np.float32)
    return t


def white():
    return solid((1.0, 1.0, 1.0, 1.0))


def flow(u):
    """A uniform f_vecfield texture with decoded x velocity u (R = 0.5 + 0.5 u, B = 0.5, A = 1)."""
    return solid((0.5 + 0.5 * u, 0.5, 0.5, 1.0))


def settings_wrapper(n_in, n_out, settings):
    """mb.make_wrapper plus a loadbang that applies `settings` (a message-box string).  The job's own
    `params` cannot be used: bench_module.js captures "base" before it sends them."""
    w = mb.make_wrapper(MODULE, n_in, n_out)
    if settings:
        boxes, lines = w["patcher"]["boxes"], w["patcher"]["lines"]
        boxes.append({"box": {"id": "lb", "maxclass": "newobj", "text": "loadbang", "numinlets": 1,
                              "numoutlets": 1, "outlettype": ["bang"], "patching_rect": [420.0, 20.0, 60.0, 22.0]}})
        boxes.append({"box": {"id": "setmsg", "maxclass": "message", "text": settings, "numinlets": 2,
                              "numoutlets": 1, "outlettype": [""], "patching_rect": [420.0, 48.0, 300.0, 22.0]}})
        lines.append({"patchline": {"source": ["lb", 0], "destination": ["setmsg", 0]}})
        lines.append({"patchline": {"source": ["setmsg", 0], "destination": ["mod", 0]}})
    return w


def two_instance_wrapper():
    def b(id, **kw):
        return {"box": {"id": id, **kw}}

    def w(s, so, d, di):
        return {"patchline": {"source": [s, so], "destination": [d, di]}}

    boxes = [
        b("mod1", maxclass="bpatcher", name=MODULE, numinlets=3, numoutlets=2, varname="bench_module",
          patching_rect=[20.0, 80.0, 190.0, 172.0]),
        b("mod2", maxclass="bpatcher", name=MODULE, numinlets=3, numoutlets=2, varname="bench_module2",
          patching_rect=[300.0, 80.0, 190.0, 172.0]),
    ]
    lines = []
    for i in range(3):
        boxes.append(b(f"rin{i + 1}", maxclass="newobj", text=f"r bench_min{i + 1}", numinlets=0, numoutlets=1,
                       outlettype=[""], patching_rect=[20.0 + 90 * i, 20.0, 85.0, 22.0]))
        lines.append(w(f"rin{i + 1}", 0, "mod1", i))                      # only instance 1 is connected
    boxes += [b("sout1", maxclass="newobj", text="s bench_mout1", numinlets=1, numoutlets=0,
                patching_rect=[20.0, 300.0, 95.0, 22.0]),
              b("sout2", maxclass="newobj", text="s bench_mout2", numinlets=1, numoutlets=0,
                patching_rect=[300.0, 300.0, 95.0, 22.0])]
    lines += [w("mod1", 1, "sout1", 0), w("mod2", 1, "sout2", 0)]      # velocity outlet (out2) of each
    return {"patcher": {"fileversion": 1,
                        "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1},
                        "classnamespace": "box", "rect": [100.0, 100.0, 540.0, 340.0],
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


def grey_to_phi(out1):
    """phi from the grey outlet: w = (phi + 1) / 2."""
    return 2.0 * out1[..., 0].astype(np.float64) - 1.0


def test_T022a_fresh_load_is_seeded_finite_and_neutral_velocity():
    r, arrays = run_wrapper(mb.make_wrapper(MODULE, 3, 2), [], warmup=40)             # nothing connected
    assert not r["errors"], r["errors"]
    assert {1, 2} <= set(arrays), f"both outlets must produce a frame, got {sorted(arrays)}"
    o1, o2 = arrays[1], arrays[2]
    for k, o in ((1, o1), (2, o2)):
        assert o.shape[:2] == (SIZE, SIZE), f"out{k} is {o.shape[:2]}, not render size"
        assert np.isfinite(o).all(), f"out{k} has non-finite values"
    neutral = np.zeros_like(o2)
    neutral[..., :3], neutral[..., 3] = 0.5, 1.0
    check("unconnected inlets: velocity outlet EXACTLY neutral", float(np.abs(o2 - neutral).max()), 0.0)
    phi = grey_to_phi(o1)
    note("phi grey: min / max / std", f"{phi.min():.3f} / {phi.max():.3f} / {phi.std():.4f}")
    check("reset fired on load: phi is seeded, not the uniform zero state (std must exceed 1e-3)",
          max(0.0, 1e-3 - float(phi.std())), 0.0)
    check("phi grey stays inside the clamp", max(float(np.abs(phi).max()) - 1.25, 0.0), 0.0)
    check("phi grey: alpha 1 and R = G = B",
          float(np.abs(o1[..., 3] - 1).max() + np.abs(o1[..., 0] - o1[..., 1]).max() + np.abs(o1[..., 1] - o1[..., 2]).max()),
          1e-6)


def n_at(phi):
    x, n, last = 0.0, 0, 0.0
    while x < phi and n < 100000:
        last = x
        x = x + E * (1.0 - x)
        x = x + PE * (0.0 - x)
        n += 1
    return n - 1 + (phi - last) / max(x - last, 1e-12)


def test_T022b_solver_advances_once_per_frame():
    means = {}
    for warmup in (28, 56):
        r, arrays = run_wrapper(mb.make_wrapper(MODULE, 3, 2), [white()], warmup)
        assert not r["errors"], r["errors"]
        means[warmup] = float(grey_to_phi(arrays[1]).mean())
        note(f"warmup {warmup}: mean phi under a white source (inject {INJECT}, thresh {THRESH})", means[warmup])
    assert 0.0 < means[28] < means[56] < 1.0, f"phi must rise and stay inside the clamp: {means}"
    rate = (n_at(means[56]) - n_at(means[28])) / (56 - 28)
    note("updates per frame (model: deposit e then mean pull)", rate)
    check("|updates per frame - 1| (a doubled update would read ~1)", abs(rate - 1.0), 0.1)


def test_T022c_vecfield_inlets_blend_and_mix_through_the_module():
    readback = {"mix_pct": ["imm_adv", "imm_enc"]}
    A, B = flow(UA), flow(UB)
    res = {}
    for label, settings in (("default", ""), ("mix 0", "mix_pct 0"), ("mix 100", "mix_pct 100")):
        r, arrays = run_wrapper(settings_wrapper(3, 2, settings), [solid((0.0, 0.0, 0.0, 1.0)), A, B], 40,
                                readback=readback)
        assert not r["errors"], r["errors"]
        if settings:
            want = float(settings.split()[1])
            got = list(((r.get("params_readback") or {}).get("mix_pct") or {}).values())
            assert len(got) >= 2 and all(abs(g - want) < 0.5 for g in got), \
                f"mix_pct never reached adv and enc: reads {got}, wanted {want}"
        res[label] = arrays
    u = {k: 2.0 * (v[2][..., 0].astype(np.float64) - 0.5) for k, v in res.items()}
    lo, hi = min(UA, UB), max(UA, UB)
    check("default mix: out2 stays between the two flows (below the lower one)", max(lo - float(u["default"].min()) , 0.0), 3e-3)
    check("default mix: out2 stays between the two flows (above the higher one)", max(float(u["default"].max()) - hi, 0.0), 3e-3)
    note("default mix: out2 velocity min / mean / max", f"{u['default'].min():.3f} / {u['default'].mean():.3f} / {u['default'].max():.3f}")
    check("default mix: the blend is a mixture (mean strictly between the flows, margin 0.02)",
          max(0.02 - (float(u["default"].mean()) - lo), 0.0) + max(0.02 - (hi - float(u["default"].mean())), 0.0), 0.0)
    check("mix 0: every texel moves exactly like A", float(np.abs(u["mix 0"] - UA).max()), 3e-3)
    check("mix 100: every texel moves exactly like B", float(np.abs(u["mix 100"] - UB).max()), 3e-3)
    check("phi grey outlet never goes uniform at mix 0 (std > 1e-3)", max(1e-3 - float(grey_to_phi(res["mix 0"][1]).std()), 0.0), 0.0)
    check("phi grey outlet never goes uniform at mix 100 (std > 1e-3)", max(1e-3 - float(grey_to_phi(res["mix 100"][1]).std()), 0.0), 0.0)


def test_T022d_two_instances_are_independent():
    r, arrays = run_wrapper(two_instance_wrapper(), [solid((0.0, 0.0, 0.0, 1.0)), flow(UA), flow(UB)], warmup=30)
    assert not r["errors"], f"errors (an 'already in use' would show here): {r['errors']}"
    assert {1, 2} <= set(arrays), f"both velocity outlets must produce a frame, got {sorted(arrays)}"
    a, b = arrays[1], arrays[2]
    driven = float(np.abs(a[..., :2] - 0.5).max())
    check("instance 1 (flows connected) is driven away from neutral (must be > 0.01)", max(0.0, 0.01 - driven), 0.0)
    neutral = np.zeros_like(b)
    neutral[..., :3], neutral[..., 3] = 0.5, 1.0
    check("instance 2 (unconnected) is EXACTLY neutral", float(np.abs(b - neutral).max()), 0.0)
    note("instance 1 max |R,G - 0.5|", driven)
    note("both outlets are render size", float(a.shape[0] == SIZE and b.shape[0] == SIZE))


if __name__ == "__main__":
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    sys.exit(run(globals()))
