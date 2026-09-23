"""
bench_perf.py -- spec Story 3: performance mode (.specify/test_bench/tasks.md
T027-T030). Needs Max with tests/bench/bench.maxpat open.

Frame time ~= max(CPU overhead, K * pass cost) (CPU/GPU overlap, verified
2026-09-22), so a pass's cost is only resolvable when a run is GPU-bound; see
benchclient.measure.

Run:  tests/bench.sh tests/bench_perf.py
"""
import sys

import numpy as np

import benchclient as bc
from bench_fft import codebox
from harness import check, note, run
from test_fft_separable import make_image, pack

# ~9 ms of GPU work at 512^2: far above the bench's CPU overhead (~2-3.5 ms)
HEAVY = """acc = 0;
for (i = 0; i < 8000; i += 1) {
	acc += sin(acc * 1.0001 + norm.x * i) * 0.5;
}
out1 = vec(acc, norm.y, 0, 1) + nearest(in1, norm) * 0;
"""


def rand(n, seed=0):
    return np.random.default_rng(seed).uniform(0, 1, (n, n, 4)).astype(np.float32)


def test_rate_control_lifts_and_restores():
    r = bc.measure("out1 = in1;", [rand(128)], chain=1)
    note("identity 128^2 fps under rate control", r["fps"])
    check("fps above display-synced rate (> 150)", 0 if r["fps"] > 150 else 1, 0)
    job, d = bc.new_job("stub_delay", delay_ms=1000)
    frames = bc.run_job(job, d)["frames_rendered"]
    note("frames in 1 s afterwards (display-synced)", frames)
    check("world settings restored (40..140 frames/s)", 0 if 40 <= frames <= 140 else 1, 0)


def test_gpu_bound_scaling_is_linear():
    """Validates the overlap model AND that slot 1 recomputes every frame:
    with pass cost >> overhead, K=2 must take ~2x the frame time of K=1."""
    x = rand(512)
    r1 = bc.measure(HEAVY, [x], chain=1)
    r2 = bc.measure(HEAVY, [x], chain=2)
    note("heavy K=1 frame ms", r1["frame_ms"])
    note("heavy K=2 frame ms", r2["frame_ms"])
    check("K=1 gpu-bound", 0 if r1["gpu_bound"] else 1, 0)
    check("frame(K=2)/frame(K=1) ~ 2 (|ratio-2|)", abs(r2["frame_ms"] / r1["frame_ms"] - 2), 0.2)


def test_repeatability_within_10pct():
    x = rand(512)
    a = bc.measure(HEAVY, [x], chain=1)["frame_ms"]
    b = bc.measure(HEAVY, [x], chain=1)["frame_ms"]
    note("run A frame ms", a)
    note("run B frame ms", b)
    check("|A-B| / mean", abs(a - b) / ((a + b) / 2), 0.10)


def test_T030_dft_cost_by_resolution():
    """What one DFT pass costs at the resolutions that matter. A 2D FFT round
    trip is 4 passes (x, y, inverse y, inverse x)."""
    for n in (128, 256, 512):
        tex = pack(make_image(n, n, 1), make_image(n, n, 2))
        r = bc.measure(codebox("x", n), [tex], chain=8, params={"inverse": 0})
        check(f"N={n} status ok", 0 if r["status"] == "ok" else 1, 0)
        if r["gpu_bound"]:
            note(f"N={n} ms per pass (K=8, gpu-bound)", r["ms_per_pass"])
            note(f"N={n} => 2D round trip (4 passes) ms", 4 * r["ms_per_pass"])
        else:
            note(f"N={n} ms per pass UPPER BOUND (not gpu-bound at K=8)", r["ms_per_pass_upper_bound"])
            note(f"N={n} => 2D round trip (4 passes) ms, upper bound", 4 * r["ms_per_pass_upper_bound"])


if __name__ == "__main__":
    bc.require_bench()
    sys.exit(run(globals()))
