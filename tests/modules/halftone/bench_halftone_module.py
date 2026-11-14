"""
bench_halftone_module.py -- f_halftone T022 (module half): the shipped patcher in the live module bench. The codebox bench
(bench_halftone.py) cannot see this layer: the control names, the Screen menu, and render_dim (the Params `width` and `height`
from the bench's render size, which the lattice and every tone read depend on).

Written 2026-11-13 (Claude, offline) and not yet run. Thresholds are the codebox bench's, written before the first run; not to
be loosened to make a failure pass.

Each job is a `segments` timeline (bench_module.js): control messages one per frame, a wait in frames, a snapshot. The source is
fed every frame at the render size, 640 x 640 (bench_modules.RENDER_DIM_SIZE); each snapshot's shape is checked.

Asserted:
  - load, no messages: the output is the render size and matches the mirror at the definition's defaults. This is the row that
    proves `width` and `height` arrive: at the codebox defaults (1920 x 1080) the lattice would be a different one.
  - the Screen menu (Line, Threshold, Bayer), pitch, softness, shape, level, jitter, seed (T023-T025, 2026-11-14), the three angles and the six phase dials each reach the pix: the frame matches the
    mirror with that value, and differs from the frame before it.
A picture is compared as a fraction of values within TOL (bench_halftone.py explains why edge pixels can flip cells).

Not here: bypass is the contract bench's (tests/contracts/bench_modules.py, f_halftone in INPUT_SIZE, the implicit inlet-0 passthrough); the
1080p cost and the exact rows are the codebox bench's.

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh -q tests/modules/halftone/bench_halftone_module.py       (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"
ORDER = 173            # integers only

import paths as _paths
import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run
from halftone_mirror import F32, halftone_stage

N = 640
SETTLE = 30            # frames after a control message
TOL = 2e-3
FRAC_BAD = 5e-3
DEFAULTS = {"screen": 0, "pitch": 0.012, "softness": 0.1, "dot_shape": 0.0, "jitter": 0.0, "seed": 1, "level": 0.5, "angle_r": 15.0, "angle_g": 75.0, "angle_b": 45.0,
            "phase_r_x": 0.0, "phase_r_y": 0.0, "phase_g_x": 0.0, "phase_g_y": 0.0, "phase_b_x": 0.0, "phase_b_y": 0.0}
SCREENS = {0: "dot", 1: "line", 2: "threshold", 3: "bayer"}


def photo(seed=6, n=N):
    """Smooth blobs inside 0..1, a different one per channel, and a flat patch."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    t = np.zeros((n, n, 4), F32)
    for c in range(3):
        acc = np.zeros((n, n), np.float32)
        for _ in range(4):
            fx, fy, ph = rng.uniform(0.5, 2.5), rng.uniform(0.5, 2.5), rng.uniform(0, 6.28)
            acc += np.sin(6.2832 * (fx * xx / n + fy * yy / n) + ph).astype(np.float32)
        t[..., c] = np.clip(0.5 + 0.12 * acc, 0.02, 0.98)
    t[n // 4:n // 2, n // 4:n // 2, :3] = 0.8
    t[..., 3] = rng.uniform(0.2, 1, (n, n))
    return t


SRC = photo()


def job(segments, warmup=30):
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    j, job_dir = bc.new_job("module", warmup=warmup, settle=6, timeout_ms=60000)
    j["wrapper"] = f"mjob_{j['id']}.maxpat"
    j["inputs"] = ["in1.jxf"]
    jxf.write_rgba(job_dir / "in1.jxf", SRC)
    j["segments"] = segments
    wrapper = bc.BENCH_DIR / j["wrapper"]
    wrapper.write_text(json.dumps(mb.make_wrapper("f_halftone.maxpat", 1, 1), indent=2))
    r = bc.run_job(j, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
        if old != wrapper:
            old.unlink()
    assert r["status"] != "stalled", r["errors"][-3:]
    return {tag: jxf.read_rgba(job_dir / f"{tag}_out1.jxf") for tag, ks in (r.get("outputs") or {}).items() if 1 in ks}


def snap(frames, tag):
    assert tag in frames, f"no {tag} snapshot: {sorted(frames)}"
    check(f"{tag}: output at the render size", float(frames[tag].shape[:2] != (N, N)), 0.0)
    return frames[tag]


def matches(got, label, **deltas):
    p = dict(DEFAULTS)
    p.update(deltas)
    want = halftone_stage(SRC, screen=SCREENS[int(p["screen"])], pitch=p["pitch"],
                          angles=(p["angle_r"], p["angle_g"], p["angle_b"]),
                          phases=((p["phase_r_x"], p["phase_r_y"]), (p["phase_g_x"], p["phase_g_y"]),
                                  (p["phase_b_x"], p["phase_b_y"])),
                          softness=p["softness"], shape=p["dot_shape"], jitter=p["jitter"],
                          seed=int(p["seed"]), level=p["level"])
    err = np.abs(got[..., :3].astype(np.float64) - want[..., :3].astype(np.float64))
    bad = float((err > TOL).mean())
    note(f"{label}: worst rgb error (edge pixels may flip cells)", float(err.max()))
    note(f"{label}: fraction of values beyond {TOL}", bad)
    check(f"{label}: fraction beyond tolerance", bad, FRAC_BAD)
    check(f"{label}: alpha is the source's", float(np.abs(got[..., 3] - SRC[..., 3]).max()), 1e-6)


def differs(a, b, label):
    check(f"{label}: the frame changed", float(np.abs(a[..., :3] - b[..., :3]).max() < 0.5), 0.0)


def test_load_touching_nothing():
    """No message reaches the module before the snapshot: the defaults, and the render size through render_dim."""
    f = job([{"wait": 60, "snap": "load"}])
    load = snap(f, "load")
    check("load: not black", float(load[..., :3].max() < 0.1), 0.0)
    matches(load, "load, defaults")


def test_screen_pitch_softness():
    f = job([{"wait": 60, "snap": "load"},
             {"params": [["screen", 1]], "wait": SETTLE, "snap": "line"},
             {"params": [["screen", 0], ["pitch", 0.03]], "wait": SETTLE, "snap": "pitch"},
             {"params": [["softness", 0.5]], "wait": SETTLE, "snap": "soft"},
             {"params": [["softness", 0.1], ["dot_shape", 1.0]], "wait": SETTLE, "snap": "shape"}])
    load, line, pitch, soft, shape = (snap(f, t) for t in ("load", "line", "pitch", "soft", "shape"))
    matches(line, "Screen menu: Line", screen=1)
    differs(line, load, "Screen menu")
    matches(pitch, "pitch 0.03", pitch=0.03)
    differs(pitch, load, "pitch")
    matches(soft, "softness 0.5", pitch=0.03, softness=0.5)
    check("softness: the frame changed", float(np.abs(soft[..., :3] - pitch[..., :3]).max() < 0.1), 0.0)
    matches(shape, "shape 1 (T023)", pitch=0.03, dot_shape=1.0)
    differs(shape, pitch, "shape")


def test_types_jitter_seed_level():
    """T024, T025 (2026-11-14): the Screen menu's Threshold and Bayer, Level, Jitter and Seed reach the pix. A jittered frame is
    compared by its mean coverage only (the hash differs a little between GPU and NumPy: bench_halftone.py)."""
    f = job([{"params": [["pitch", 0.03]], "wait": 60, "snap": "base"},
             {"params": [["screen", 2]], "wait": SETTLE, "snap": "thr"},
             {"params": [["level", 0.3]], "wait": SETTLE, "snap": "lvl"},
             {"params": [["screen", 3]], "wait": SETTLE, "snap": "bay"},
             {"params": [["screen", 0], ["jitter", 1.0]], "wait": SETTLE, "snap": "jit"},
             {"params": [["seed", 5]], "wait": SETTLE, "snap": "seed"}])
    base, thr, lvl, bay, jit, sd = (snap(f, t) for t in ("base", "thr", "lvl", "bay", "jit", "seed"))
    matches(thr, "Screen menu: Threshold", pitch=0.03, screen=2)
    differs(thr, base, "Threshold")
    matches(lvl, "Level 0.3", pitch=0.03, screen=2, level=0.3)
    differs(lvl, thr, "Level")
    matches(bay, "Screen menu: Bayer", pitch=0.03, screen=3, level=0.3)
    differs(bay, lvl, "Bayer")
    for got, label, seed in ((jit, "Jitter 1", 1), (sd, "Seed 5", 5)):
        want = halftone_stage(SRC, screen="dot", pitch=0.03,
                              angles=(DEFAULTS["angle_r"], DEFAULTS["angle_g"], DEFAULTS["angle_b"]),
                              softness=DEFAULTS["softness"], jitter=1.0, seed=seed)
        dmean = max(abs(float(got[..., c].mean()) - float(want[..., c].mean())) for c in range(3))
        note(f"{label}: worst channel mean minus the mirror's", dmean)
        check(f"{label}: mean coverage is the mirror's", dmean, 0.04)   # the seed-to-seed spread: bench_halftone.py JIT_MEAN
    differs(jit, base, "Jitter")
    differs(sd, jit, "Seed")


def test_angles_reach_their_own_plate():
    f = job([{"params": [["pitch", 0.03]], "wait": 60, "snap": "base"},
             {"params": [["angle_r", 40.0]], "wait": SETTLE, "snap": "r"},
             {"params": [["angle_g", 100.0]], "wait": SETTLE, "snap": "g"},
             {"params": [["angle_b", 5.0]], "wait": SETTLE, "snap": "b"}])
    base, r, g, b = (snap(f, t) for t in ("base", "r", "g", "b"))
    seq = [("angle_r", 0, base, r), ("angle_g", 1, r, g), ("angle_b", 2, g, b)]
    for name, c, before, after in seq:
        others = [k for k in range(3) if k != c]
        check(f"{name}: its plate changed", float(np.abs(after[..., c] - before[..., c]).max() < 0.5), 0.0)
        check(f"{name}: the other plates exactly unchanged", float(np.abs(after[..., others] - before[..., others]).max()), 0.0)
    matches(b, "all three angles moved", pitch=0.03, angle_r=40.0, angle_g=100.0, angle_b=5.0)


def test_phase_dials_reach_their_own_plate():
    moves = [("phase_r_x", 0, 0.25), ("phase_r_y", 0, 0.5), ("phase_g_x", 1, 0.25), ("phase_g_y", 1, 0.5),
             ("phase_b_x", 2, 0.25), ("phase_b_y", 2, 0.5)]
    segs = [{"params": [["pitch", 0.03]], "wait": 60, "snap": "base"}]
    segs += [{"params": [[name, val]], "wait": SETTLE, "snap": name} for name, _, val in moves]
    f = job(segs)
    before, sent = snap(f, "base"), {"pitch": 0.03}
    for name, c, val in moves:
        after = snap(f, name)
        others = [k for k in range(3) if k != c]
        check(f"{name}: its plate changed", float(np.abs(after[..., c] - before[..., c]).max() < 0.5), 0.0)
        check(f"{name}: the other plates exactly unchanged", float(np.abs(after[..., others] - before[..., others]).max()), 0.0)
        sent[name] = val
        before = after
    matches(before, "all six phases moved", **sent)


if __name__ == "__main__":
    sys.exit(run(globals()))
