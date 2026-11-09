"""
bench_ink_module.py -- f_ink T024 (module half): the shipped patcher in the live module bench. The codebox bench (bench_ink.py)
cannot see this layer: eight stages and their cords, the render size arriving by `r dim`, a dial with several stage targets, and
the Param defaults reaching the stages at load.

Each job is a `segments` timeline (bench_module.js): control messages one per frame, a wait in frames, a snapshot. The source is fed
every frame at the render size, 640 x 640 (bench_modules.RENDER_DIM_SIZE).

Asserted (thresholds written before the first run; not to be loosened to make a failure pass):
  - load, no messages at all: the output is the source (identity through eight stages)
  - spread reaches both blurs and the threshold: matches the mirror, and the result is 2-D (not one axis only)
  - bias, snap and soften reach the threshold
  - edge_pool with pool_width UNTOUCHED: matches the mirror at the definition's default (the default reaches both pool stages)
  - pool_width moves the rim
  - mottle, mottle_scale, dropout, tooth_scale and seed reach fx_b (statistics; the hash is not comparable texel by texel)

Tolerances:
  TOL  5e-4: eight stages of float32 arithmetic against the mirror, with smoothstep at soften 0.2 multiplying rounding by about 5.

Not here: bypass is the contract bench's (tests/contracts/bench_modules.py, BYPASS_EXPECT); the cost; the order of arrival at a
two-input stage (a static source hides a one-frame lag, and the harness has no per-frame input swap), which stays inferred.

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh -q tests/modules/ink/bench_ink_module.py       (ask Matt first: CLAUDE.md)
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
from ink_mirror import F32, ink

N = 640
SETTLE = 30            # frames after a control message
TOL = 5e-4
DEFAULTS = dict(spread=0.0, snap=1.0, bias=0.0, soften=0.2, edge_pool=0.0, pool_width=0.005, mottle=0.0, mottle_scale=0.15, dropout=0.0,
                tooth_scale=0.004, seed=1.0)


def source(seed=5, n=N):
    """Inside 0..1 and finite (out-of-range and non-finite values are the codebox bench's): a solid disc on 0, in R; a set of bars,
    in G; a smooth ramp, in B; random alpha."""
    rng = np.random.default_rng(seed)
    t = np.zeros((n, n, 4), F32)
    yy, xx = np.mgrid[0:n, 0:n]
    t[..., 0] = ((xx - n * 0.4) ** 2 + (yy - n * 0.6) ** 2 < (n * 0.2) ** 2).astype(F32)
    t[..., 1] = (xx // 12 % 2).astype(F32)
    t[..., 2] = ((xx + yy) / (2.0 * n - 2.0)).astype(F32)
    t[..., 3] = rng.uniform(0.2, 1, (n, n))
    return t


SRC = source()


def job(segments, warmup=30):
    """One segments job. Returns {tag: array} for the one outlet."""
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    j, job_dir = bc.new_job("module", warmup=warmup, settle=6, timeout_ms=60000)
    j["wrapper"] = f"mjob_{j['id']}.maxpat"
    j["inputs"] = ["in1.jxf"]
    jxf.write_rgba(job_dir / "in1.jxf", SRC)
    j["segments"] = segments
    wrapper = bc.BENCH_DIR / j["wrapper"]
    wrapper.write_text(json.dumps(mb.make_wrapper("f_ink.maxpat", 1, 1), indent=2))
    r = bc.run_job(j, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
        if old != wrapper:
            old.unlink()
    assert r["status"] != "stalled", r["errors"][-3:]
    return {tag: jxf.read_rgba(job_dir / f"{tag}_out1.jxf") for tag in (r.get("outputs") or {})}


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def frame(frames, tag):
    assert tag in frames, f"no {tag} snapshot: {sorted(frames)}"
    got = frames[tag]
    check(f"{tag}: at the render size", float(got.shape[:2] != (N, N)), 0.0)
    return got


def matches(got, label, tol=TOL, **deltas):
    want = ink(SRC, **{**DEFAULTS, **deltas})
    worst = mx(got[..., :3], want[..., :3])
    note(f"{label}: max rgb error", worst)
    check(f"{label}: vs mirror", worst, tol)
    check(f"{label}: alpha is the source's", mx(got[..., 3], SRC[..., 3]), 1e-6)


def step(tag, *params):
    return {"params": [list(p) for p in params], "wait": SETTLE, "snap": tag}


def test_load_is_identity():
    got = frame(job([{"wait": SETTLE, "snap": "load"}]), "load")
    check("load, nothing touched: the output is the source", mx(got, SRC), 1e-6)


def test_spread_dial():
    f = job([step("half", ("spread", 0.5)), step("full", ("spread", 1.0)), step("back", ("spread", 0.0))])
    half, full = frame(f, "half"), frame(f, "full")
    matches(half, "spread 0.5", spread=0.5)
    matches(full, "spread 1", spread=1.0)
    # The blurs are one per axis. Snap off shows the raw blur better, but the bars' G channel varies along x only, and R (a disc) along
    # both: if the vertical pass were dead the disc's top edge would stay as sharp as its source, which the mirror row above would catch.
    check("spread back to 0: the source again", mx(frame(f, "back"), SRC), 1e-6)


def test_threshold_dials():
    f = job([step("bias", ("spread", 1.0), ("bias", 0.2)),
             step("snap", ("spread", 1.0), ("bias", 0.0), ("snap", 0.0)),
             step("soften", ("spread", 1.0), ("bias", 0.0), ("snap", 1.0), ("soften", 0.7))])
    matches(frame(f, "bias"), "bias 0.2", spread=1.0, bias=0.2)
    matches(frame(f, "snap"), "snap 0", spread=1.0, snap=0.0)
    matches(frame(f, "soften"), "soften 0.7", spread=1.0, soften=0.7)


def test_edge_pool():
    f = job([step("default_width", ("edge_pool", 1.0)), step("wider", ("edge_pool", 1.0), ("pool_width", 0.01))])
    default, wider = frame(f, "default_width"), frame(f, "wider")
    matches(default, "edge_pool 1, pool_width untouched", edge_pool=1.0)
    matches(wider, "edge_pool 1, pool_width 0.01", edge_pool=1.0, pool_width=0.01)
    check("edge_pool: a rim above 1 on the disc", float(not default[..., 0].max() > 1.1), 0.0)
    check("pool_width moves the rim", float(mx(default[..., 0], wider[..., 0]) < 0.01), 0.0)


def test_fx_dials():
    f = job([step("mottle", ("mottle", 1.0)),
             step("mottle_big", ("mottle", 1.0), ("mottle_scale", 0.4)),
             step("seed2", ("mottle", 1.0), ("mottle_scale", 0.15), ("seed", 2)),
             step("dropout", ("mottle", 0.0), ("seed", 1), ("dropout", 1.0)),
             step("tooth", ("dropout", 1.0), ("tooth_scale", 0.02))])
    mottle, big, seed2, drop, tooth = (frame(f, t) for t in ("mottle", "mottle_big", "seed2", "dropout", "tooth"))
    inside = SRC[..., 0] == 1
    outside = SRC[..., 0] == 0
    check("mottle varies the disc", float(not mottle[..., 0][inside].std() > 0.02), 0.0)
    check("mottle leaves black black", float(np.abs(mottle[..., 0][outside]).max()), 1e-6)
    check("mottle_scale changes the pattern", float(mx(mottle, big) < 0.01), 0.0)
    check("seed changes the pattern", float(mx(mottle, seed2) < 0.01), 0.0)
    ramp = SRC[..., 2]
    low, high = (ramp > 0.1) & (ramp < 0.35), ramp > 0.75
    lost_low, lost_high = float((drop[..., 2][low] == 0).mean()), float((drop[..., 2][high] == 0).mean())
    note("dropout 1 on the ramp: fraction lost low, high", f"{lost_low:.4f} {lost_high:.4f}")
    check("dropout: lighter tones lose more", float(not lost_low > lost_high), 0.0)
    check("tooth_scale changes the pattern", float(mx(drop, tooth) < 0.01), 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
