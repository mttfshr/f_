"""
bench_vf_erode_module.py -- f_vf_erode T082b: the shipped patcher in the live module bench. The codebox bench cannot see this layer:
the connected flags (terrain, vecfield, background), the Wet gate_button, the dim-driven atlas size and the frame loop.

Each job is a `segments` timeline (bench_module.js): control messages one per frame, a wait in frames, a snapshot. The textures are fed every
frame. The render size is the bench's vs_render, 640 x 640 (bench_modules.RENDER_DIM_SIZE); the atlas is 640 x 1280.

Asserted (properties, not frame-exact values: frame counts around a snapshot are loose):
  - before the first wetting the module returns its input (US3.4), both Polarity settings
  - after one wetting on a flat frame with nothing patched, the picture is still returned (SC-104: flat terrain, no field, identity)
  - with a terrain and a vecfield patched, the wetted picture moves (it is no longer the input) and stays finite
  - a background on inlet 3 shows through under Darker (the unwetted picture over it is picture * background in linear light)
  - both outlets follow the render size; outlet 2 (thickness) is finite

Bypass is the contract bench's (tests/contracts/bench_modules.py). The wetting, the load flag and every stage against the mirror are
bench_vf_erode.py's.

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh tests/modules/vf_erode/bench_vf_erode_module.py
"""
GROUP = "regression"
ORDER = 163            # integers only

import paths as _paths
import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run

F32 = np.float32
N = 640
SETTLE = 60            # frames: past the connected flags' lag
TOL_ID = 1e-3          # the identity round trip: pow, log, exp in float32 (the codebox bench measured 1e-6)


def job(inputs, segments, warmup=30):
    """One segments job. Returns {tag: {outlet: array}}."""
    n_in = max(len(inputs), 1)
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    j, job_dir = bc.new_job("module", warmup=warmup, settle=6, timeout_ms=90000)
    j["wrapper"] = f"mjob_{j['id']}.maxpat"
    j["inputs"] = []
    for i, arr in enumerate(inputs):
        fn = f"in{i + 1}.jxf"
        jxf.write_rgba(job_dir / fn, np.asarray(arr, F32))
        j["inputs"].append(fn)
    j["segments"] = segments
    wrapper = bc.BENCH_DIR / j["wrapper"]
    wrapper.write_text(json.dumps(mb.make_wrapper("f_vf_erode.maxpat", n_in, 2), indent=2))
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
    check(f"{tag}: both outlets finite", float(not (np.isfinite(a).all() and np.isfinite(b).all())), 0.0)
    return a, b


def picture(seed=1):
    img = np.ones((N, N, 4), F32)
    img[..., :3] = np.random.default_rng(seed).uniform(0.1, 0.95, (N, N, 3)).astype(F32)
    return img


def terrain():
    y, x = np.mgrid[0:N, 0:N] / N
    t = np.ones((N, N, 4), F32)
    t[..., :3] = (0.5 + 0.5 * np.sin(6.0 * x) * np.cos(5.0 * y))[..., None].astype(F32)
    return t


def field():
    t = np.zeros((N, N, 4), F32)
    t[..., 0], t[..., 1], t[..., 2], t[..., 3] = 0.8, 0.4, 0.5, 1
    return t


def test_unwetted_returns_the_input():
    pic = picture()
    f = job([pic], [{"wait": SETTLE, "snap": "darker"},
                    {"params": [["polar_sw", 1]], "wait": SETTLE, "snap": "lighter"}])
    for tag in ("darker", "lighter"):
        a, _ = outs(f, tag)
        check(f"{tag}, never wetted, nothing patched: the output is the input", mx(a, pic), TOL_ID)


def test_wetting_a_flat_frame_returns_the_picture():
    pic = picture(2)
    f = job([pic], [{"wait": SETTLE},
                    {"params": [["wet"]], "wait": SETTLE, "snap": "darker"},
                    {"params": [["polar_sw", 1]], "wait": 5},
                    {"params": [["wet"]], "wait": SETTLE, "snap": "lighter"}])
    for tag in ("darker", "lighter"):
        a, _ = outs(f, tag)
        check(f"{tag}, wetted once on flat terrain with no field: still the picture (SC-104)", mx(a, pic), TOL_ID)


def test_terrain_and_field_move_the_ink():
    pic = picture(3)
    f = job([pic, terrain(), field()], [{"wait": SETTLE, "snap": "before"},
                                        {"params": [["wet"]], "wait": SETTLE, "snap": "after"}])
    before, _ = outs(f, "before")
    after, th = outs(f, "after")
    check("terrain and vecfield patched, before the wetting: the input still comes back", mx(before, pic), TOL_ID)
    d = float(np.mean(np.abs(after[..., :3].astype(np.float64) - pic[..., :3])))
    note("mean |wetted - picture| after 60 frames with a terrain and a field", f"{d:.4f}")
    check("after the wetting the picture has moved (mean change above 0.005)", float(d < 0.005), 0.0)
    check("the thickness outlet has structure (not constant)", float(np.std(th[..., 0]) < 1e-3), 0.0)


def test_feed_starts_the_solver_without_a_press():
    """Feed (US5): with no Wet press, a terrain and field and Feed above 0, the picture is fed in and moves; flat, it converges to itself.
    The harness feeds one static texture, so 'animated' is the codebox bench's chain test; this is the shipped dial and wiring."""
    pic = picture(5)
    f = job([pic, terrain(), field()], [{"wait": SETTLE, "snap": "feed0"},
                                        {"params": [["feed", 0.2]], "wait": 90, "snap": "fed"},
                                        {"params": [["feed", 0.0]], "wait": 30, "snap": "off"}])
    a0, _ = outs(f, "feed0")
    a, th = outs(f, "fed")
    check("feed 0, never wetted: the input comes back", mx(a0, pic), TOL_ID)
    d = float(np.mean(np.abs(a[..., :3].astype(np.float64) - pic[..., :3])))
    note("mean |fed - picture| after 90 frames at feed 0.2, terrain and field patched", f"{d:.4f}")
    check("fed with no press: the ink has moved (mean change above 0.005)", float(d < 0.005), 0.0)
    f2 = job([pic], [{"params": [["feed", 0.2]], "wait": 90, "snap": "flat"}])
    b, _ = outs(f2, "flat")
    check("fed on a flat frame with nothing patched: the picture (identity)", mx(b, pic), 2e-3)


def test_background_shows_through_under_darker():
    pic = picture(4)
    bg = np.ones((N, N, 4), F32)
    bg[..., :3] = 0.5
    f = job([pic, terrain(), field(), bg], [{"wait": SETTLE, "snap": "bg"}])
    a, _ = outs(f, "bg")
    want = (pic[..., :3] ** 2.2 * 0.5 ** 2.2) ** (1 / 2.2)           # Darker, unwetted, over a mid grey: picture * 0.5 in linear light
    check("Darker over a connected background, never wetted: picture times background in linear light", mx(a[..., :3], want), TOL_ID)


if __name__ == "__main__":
    sys.exit(run(globals()))
