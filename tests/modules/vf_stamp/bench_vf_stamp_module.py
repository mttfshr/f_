"""
bench_vf_stamp_module.py -- f_vf_stamp T024: the shipped patcher in the live module bench. The codebox bench cannot see
this layer: the connected flags, the gate_button and the envelope, which drive `env` from `r draw`.

Each job is a `segments` timeline (bench_module.js): control messages one per frame, a wait in frames, a snapshot. The
textures are fed every frame. An inlet without an array stays unconnected.

Asserted:
  - no stamp on load; a held press stamps at full strength and matches the mirror; a release comes back to EXACTLY idle
  - a tap is seen (SC-005), a press cancels a pending release, `attack` and `release` shape the envelope
  - with a field connected the impulse follows it and the switch does nothing; with none, the switch picks the swirl
  - with nothing on inlet 0 the module still draws: black ink and a neutral impulse, even inverted (FR-001)

Bypass is the contract bench's (tests/contracts/bench_modules.py).

The render size is the bench's vs_render, 640 x 640 as seen 2026-10-31 (bench_modules.RENDER_DIM_SIZE); the stamp is fed at
that size so the mirror compares like for like, and each snapshot's shape is checked. Frame counts around a snapshot
are loose (opening the capture takes a frame or two), so envelope rows use ranges, never one value.

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh tests/modules/vf_stamp/bench_vf_stamp_module.py
"""
GROUP = "regression"
ORDER = 162            # integers only

import paths as _paths
import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run
from vf_stamp_mirror import F32, disc, stamp_stage

N = 640
TOL = 1e-5             # 1:1 reads at texel centres: float32 rounding only (bench_vf_stamp.py)
SETTLE = 120           # frames: past the connected flags' lag, and past the tail at `release` 8 (env under 0.001 in 60)
NEUTRAL = np.array([0.5, 0.5, 0.5, 1.0], np.float32)


def job(inputs, segments, n_in=None, warmup=30):
    """One segments job. Returns {tag: {outlet: array}}. n_in = wired inlets (at least 1: the messages use inlet 0)."""
    n_in = max(len(inputs), 1) if n_in is None else n_in
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    j, job_dir = bc.new_job("module", warmup=warmup, settle=6, timeout_ms=60000)
    j["wrapper"] = f"mjob_{j['id']}.maxpat"
    j["inputs"] = []
    for i, arr in enumerate(inputs):
        fn = f"in{i + 1}.jxf"
        jxf.write_rgba(job_dir / fn, np.asarray(arr, F32))
        j["inputs"].append(fn)
    j["segments"] = segments
    wrapper = bc.BENCH_DIR / j["wrapper"]
    wrapper.write_text(json.dumps(mb.make_wrapper("f_vf_stamp.maxpat", n_in, 2), indent=2))
    r = bc.run_job(j, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
        if old != wrapper:
            old.unlink()
    assert r["status"] != "stalled", r["errors"][-3:]
    return {tag: {k: jxf.read_rgba(job_dir / f"{tag}_out{k}.jxf") for k in ks} for tag, ks in (r.get("outputs") or {}).items()}


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def outs(frames, tag):
    assert tag in frames and 1 in frames[tag] and 2 in frames[tag], f"no {tag} snapshot: {sorted(frames)}"
    a, b = frames[tag][1], frames[tag][2]
    check(f"{tag}: both outlets at the render size", float(a.shape[:2] != (N, N) or b.shape[:2] != (N, N)), 0.0)
    return a, b


def idle(frames, tag):
    a, b = outs(frames, tag)
    check(f"{tag}: ink exactly black", mx(a[..., :3], 0.0), 0.0)
    check(f"{tag}: alpha 1", mx(a[..., 3], 1.0), 0.0)
    check(f"{tag}: impulse exactly neutral", mx(b, NEUTRAL), 0.0)


def env_of(a, stamp):
    """The envelope read back from the ink, at the stamp's fully covered centre (amount 1, white)."""
    return float(a[N // 2, N // 2, 0] / stamp[N // 2, N // 2, 0])


def matches(frames, tag, stamp, **kw):
    a, b = outs(frames, tag)
    wa, wb = stamp_stage(stamp, rim=0.015, env=1.0, **kw)
    check(f"{tag}: ink vs mirror", mx(a, wa), TOL)
    check(f"{tag}: impulse vs mirror", mx(b, wb), TOL)


STAMP = disc(N, ramp=0.02)


def field():
    t = np.zeros((N, N, 4), F32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = 0.75, 0.375, 0.5, 1
    return t


def test_press_hold_release():
    f = job([STAMP], [{"wait": SETTLE, "snap": "load"},
                      {"params": [["stamp", 1]], "wait": 6, "snap": "held"},
                      {"wait": 30, "snap": "still_held"},
                      {"params": [["stamp", 0]], "wait": SETTLE, "snap": "released"}])
    idle(f, "load")
    matches(f, "held", STAMP)
    matches(f, "still_held", STAMP)
    idle(f, "released")


def test_tap_is_seen_and_ends():
    f = job([STAMP], [{"wait": SETTLE},
                      {"params": [["stamp"]], "wait": 1, "snap": "tap"},
                      {"wait": SETTLE, "snap": "after"}])
    a, _ = outs(f, "tap")
    e = env_of(a, STAMP)
    note("envelope at the tap's snapshot", e)
    check("the tap reached the outlets (env above 0.5)", float(e < 0.5), 0.0)
    idle(f, "after")


def test_press_cancels_a_pending_release():
    f = job([STAMP], [{"wait": SETTLE},
                      {"params": [["stamp", 1], ["stamp", 0], ["stamp", 1]], "wait": 30, "snap": "cancelled"}])
    matches(f, "cancelled", STAMP)


def test_attack_and_release_shape_the_envelope():
    f = job([STAMP], [{"params": [["attack", 20], ["release", 20]], "wait": SETTLE},
                      {"params": [["stamp", 1]], "wait": 5, "snap": "rising"},
                      {"wait": SETTLE, "snap": "top"},
                      {"params": [["stamp", 0]], "wait": 12, "snap": "falling"},
                      {"params": [["attack", 0], ["release", 0]], "wait": SETTLE, "snap": "instant_off"},
                      {"params": [["stamp", 1]], "wait": 3, "snap": "instant_on"}])
    rising = env_of(outs(f, "rising")[0], STAMP)
    top = env_of(outs(f, "top")[0], STAMP)
    falling = env_of(outs(f, "falling")[0], STAMP)
    note("envelope rising / top / falling (attack and release 20)", f"{rising:.4f} / {top:.4f} / {falling:.4f}")
    check("attack 20: part way up after about 5 frames (one-pole: 0.22, 0.1 to 0.45 allows the snapshot's frames)",
          float(not 0.1 < rising < 0.45), 0.0)
    check("attack 20: at the top after the settle", abs(top - 1.0), 0.01)
    check("release 20: part way down after about 12 frames (the gate holds 2 more; one-pole: about 0.6)",
          float(not 0.4 < falling < 0.85), 0.0)
    idle(f, "instant_off")
    matches(f, "instant_on", STAMP)


def test_connected_field_and_the_switch():
    fld = field()
    f = job([STAMP, fld], [{"wait": SETTLE},
                           {"params": [["stamp", 1]], "wait": 6, "snap": "field"},
                           {"params": [["impulse", 1]], "wait": 6, "snap": "field_swirl"}])
    matches(f, "field", STAMP, in1=fld, src_vec=1.0)
    check("the switch does nothing with a field connected", mx(outs(f, "field")[1], outs(f, "field_swirl")[1]), 0.0)


def test_swirl_without_a_field():
    f = job([STAMP], [{"params": [["impulse", 1]], "wait": SETTLE},
                      {"params": [["stamp", 1]], "wait": 6, "snap": "swirl"}])
    matches(f, "swirl", STAMP, impulse=1.0)


def test_empty_inlet_still_draws_nothing():
    """FR-001. The inlet is wired for the messages and gets no texture; the flag is whatever vs_inState says then."""
    f = job([], [{"params": [["invert", 1]], "wait": SETTLE},
                 {"params": [["stamp", 1]], "wait": 12, "snap": "empty"}])
    idle(f, "empty")


if __name__ == "__main__":
    sys.exit(run(globals()))
