"""
bench_fc_look.py -- f_formconstants T047: the SHIPPED parity patcher's look over time.

Rewritten 2026-10-24 for the Revision 2 parity build (fixed 1024^2 solver, RGB out, no
dials; the steady-web version is in git 63b6129). The module is loaded in the module bench,
reset once, and its outlet snapshotted every SPACING frames for RUN frames.

Pass criteria (Matt, 2026-10-24, from the T047 pre-check in tasks.md -- the reference's own
dynamics have a ~600-frame near-uniform transient and sub-0.05 std dips after emergence, so
"E std > 0.05 throughout" would fail the reference itself):
  (a) structure emerges: max R std over frames 700-1500 > 0.05
  (b) not dead late: max R std over the last 300 frames > 0.05
  (c) mean-R pulse period 147 frames +- 10% (zero-padded FFT over frames >= 300)
  (d) the GPU mean-R curve tracks the parity mirror's encoded curve: |diff| <= 0.03 on
      >= 90% of snapshots at frames >= 300, after the best lag in [LAG_MIN, LAG_MAX]
      (the module's reset goes through a 200 ms [delay], so its frame 0 is a wall-clock
      offset after the bench's reset message; the lag is reported).
Reference curve: fc_parity_mirror at N = 256 (local dynamics; the mean-R curve at N 256
was checked against N 1024 offline before adoption -- see tasks.md T047 record).
Uniform or dead after frame 900 -> the brief's live-debug rule, not more bench legs.

Run (Max open, tests/bench/bench_module.maxpat loaded):
    tests/bench.sh -q tests/modules/formconstants/bench_fc_look.py
Not in the regression group (long run).
"""
import json
import sys
import time
from pathlib import Path

import numpy as np

import paths as _paths
import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run

sys.path.insert(0, str(Path(__file__).resolve().parent))
import fc_parity_mirror as fm  # noqa: E402

N_IN = 64                    # module bench input texture size (the module ignores its input)
RUN = 1500                   # frames after reset
SPACING = 15                 # wait frames between snapshots (each snapshot adds one frame)
MIRROR_N = 256
LAG_MIN, LAG_MAX = -5, 90
PERIOD = 500.0 / 3.4         # S5, ~147.06 frames
OUT_DIR = _paths.REPO / "tests" / "logs" / "fc_look"


def schedule():
    """Segments plus each snapshot's frame offset from the bench's reset message."""
    segs, offs = [], []
    f = 1 + SPACING                                   # reset param takes one frame, then wait
    segs.append({"params": [["reset", 1]], "wait": SPACING, "snap": "s0000"})
    offs.append(f)
    k = 1
    while f + SPACING + 1 <= RUN:
        f += SPACING + 1
        segs.append({"wait": SPACING, "snap": f"s{k:04d}"})
        offs.append(f)
        k += 1
    return segs, np.array(offs)


def mirror_curve(frames):
    """Encoded-output R mean/std of the parity mirror, one entry per frame (after step i)."""
    st = fm.seed_state(MIRROR_N, np.random.default_rng(1))
    mean, std = np.empty(frames), np.empty(frames)
    for fr in range(frames):
        st = fm.step(st, fr)
        r = fm.encode(st, 128, 128)[..., 0].astype(np.float64)
        mean[fr], std[fr] = r.mean(), r.std()
    return mean, std


def padded_period(x, dt):
    """Dominant period (frames) of a trace sampled every dt frames; zero-padded FFT."""
    x = np.asarray(x, np.float64)
    x = (x - x.mean()) * np.hanning(len(x))
    nfft = 1 << 14
    sp = np.abs(np.fft.rfft(x, nfft))
    freqs = np.fft.rfftfreq(nfft, d=dt)
    k = int(np.argmax(sp[1:]) + 1)
    return 1.0 / freqs[k]


def ppm(path, arr3):
    with open(path, "wb") as fh:
        fh.write(f"P6\n{arr3.shape[1]} {arr3.shape[0]}\n255\n".encode())
        fh.write(arr3.astype(np.uint8).tobytes())


def test_parity_module_look_over_time():
    segs, offs = schedule()
    print(f"bench_fc_look: {len(segs)} snapshots every {SPACING + 1} frames over {offs[-1]} frames")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    t0 = time.time()
    m_mean, m_std = mirror_curve(int(offs[-1]) + 10)
    print(f"mirror reference (N {MIRROR_N}): {time.time() - t0:.0f}s")

    job, job_dir = bc.new_job("module", warmup=10, settle=6, timeout_ms=600000)
    job["wrapper"] = f"mjob_{job['id']}.maxpat"
    mod = mb.Module(_paths.REPO / "package" / "patchers" / "f_formconstants.maxpat")
    n_in, n_out = mb.module_io(mod)
    with open(bc.BENCH_DIR / job["wrapper"], "w") as fh:
        json.dump(mb.make_wrapper("f_formconstants.maxpat", n_in, n_out), fh, indent=2)
    jxf.write_rgba(job_dir / "in1.jxf", mb.neutral(N_IN))
    job["inputs"] = ["in1.jxf"]
    job["segments"] = segs

    t0 = time.time()
    result = bc.run_job(job, job_dir, ports=bc.MODULE_PORTS)
    noise = ["jpatcher: doesn't understand getattr"]      # module-bench nesting (bench_modules ENV_NOISE)
    errs = [e for e in (result.get("errors") or []) if e not in noise]
    print(f"job: {result['status']} in {time.time() - t0:.0f}s "
          f"({result.get('frames_rendered')} frames rendered) errors={errs}")
    assert not errs, f"module job failed: {errs}"

    arrs, g_mean, g_std = [], [], []
    for seg in segs:
        a = jxf.read_rgba(job_dir / f"{seg['snap']}_out1.jxf")
        r = a[..., 0].astype(np.float64)
        arrs.append(a)
        g_mean.append(r.mean())
        g_std.append(r.std())
    g_mean, g_std = np.array(g_mean), np.array(g_std)
    note("output size / alpha range", f"{arrs[0].shape[1]}x{arrs[0].shape[0]} / "
         f"{float(min(a[..., 3].min() for a in arrs)):.3f}-{float(max(a[..., 3].max() for a in arrs)):.3f}")
    note("GPU R std every ~100 frames", " ".join(f"{offs[i]}:{g_std[i]:.3f}" for i in range(0, len(offs), 6)))
    note("GPU R mean every ~100 frames", " ".join(f"{offs[i]}:{g_mean[i]:.3f}" for i in range(0, len(offs), 6)))
    if not np.all(np.isfinite(g_mean)):
        raise AssertionError("non-finite values in the module output")

    # (d) alignment first, so a failure in (a)-(c) still prints the comparison
    best = None
    for lag in range(LAG_MIN, LAG_MAX + 1):
        idx = offs - lag - 1
        use = (offs - lag >= 300) & (idx >= 0) & (idx < len(m_mean))
        d = np.abs(g_mean[use] - m_mean[idx[use]])
        cand = (float(np.mean(d <= 0.03)), -float(d.mean()), lag, d)
        if best is None or cand[:2] > best[:2]:
            best = cand
    frac, _, lag, d = best
    idx = offs - lag - 1
    note("best lag (frames) / fraction within 0.03 / max |diff|",
         f"{lag} / {frac:.3f} / {float(d.max()):.3f}")
    note("mirror R std at the same frames", " ".join(
        f"{offs[i]}:{m_std[idx[i]]:.3f}" for i in range(0, len(offs), 6) if 0 <= idx[i] < len(m_std)))

    late = offs >= offs[-1] - 300
    win = (offs >= 700) & (offs <= 1500)
    period = padded_period(g_mean[offs >= 300], SPACING + 1)
    note("mean-R pulse period (frames)", f"{period:.1f} (expected {PERIOD:.1f})")

    # contact sheet: ten snapshots, RGB, half size
    pick = np.linspace(0, len(arrs) - 1, 10).astype(int)
    tiles = [np.clip(arrs[i][::2, ::2, :3] * 255, 0, 255) for i in pick]
    path = OUT_DIR / f"parity_{time.strftime('%Y%m%d-%H%M%S')}.ppm"
    ppm(path, np.concatenate(tiles, axis=1))
    print("sheet:", path.relative_to(_paths.REPO), " frames", [int(offs[i]) for i in pick])
    print("job dir:", Path(job_dir).relative_to(_paths.REPO))

    check("(a) structure emerges: 0.05 - max R std, frames 700-1500", 0.05 - g_std[win].max(), 0.0)
    check("(b) not dead late: 0.05 - max R std, last 300 frames", 0.05 - g_std[late].max(), 0.0)
    check("(c) pulse period relative error", abs(period - PERIOD) / PERIOD, 0.10)
    check("(d) fraction of snapshots off the mirror mean by > 0.03", 1.0 - frac, 0.10)


if __name__ == "__main__":
    sys.exit(run(globals()))
