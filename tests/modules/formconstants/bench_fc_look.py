"""
bench_fc_look.py -- f_formconstants Phase 1.5 live-diagnosis instrument.

Matt's first live look after the dim fix (2026-10-24): "flashes, brief moments
of noise, then all black; the rate of flashing is directly driven by Rate".
The stage bench proves the chain math sustains 30 frames at the default corner
(7.3e-5), so this leg watches the SHIPPED PATCHER itself in the module bench:
snapshots at six times at Rate 1, then again at Rate 0.2 after a reseed.
Interpretations:
  - dies-once-to-black: std falls monotonically after frame ~10, same wall
    time at both Rates (a real dynamics collapse -> suspect the update).
  - periodic death+rerebirth (NaN zap -> self-heal cycle): std re-spikes,
    period in FRAMES constant -> period in SECONDS inversely proportional to
    fps but the ORGANIZATION time follows dt (Rate).
  - reseed-loop (`r dim` re-firing, the T013 wiring): flashing at wall-clock
    (200ms delay class), independent of Rate -- and the `dim` broadcast noise
    would also show in the job's error log.

Run (Max open, tests/bench/bench_module.maxpat loaded):
    tests/bench.sh tests/modules/formconstants/bench_fc_look.py
"""
import sys
import time
from pathlib import Path

import numpy as np

import paths as _paths
import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run

N = 128                      # module bench texture size
OUT_DIR = _paths.REPO / "tests" / "logs" / "fc_look"


def segments(fps=60):
    def s(sec):
        return int(sec * fps)
    segs = []
    segs.append({"params": [["rate", 1.0], ["reset", 1]], "wait": s(0.25), "snap": "r10_000ms"})
    for ms, sec in ((500, 0.25), (1000, 0.5), (2000, 1.0), (4000, 2.0), (8000, 4.0)):
        segs.append({"wait": s(sec), "snap": f"r10_{ms:04d}ms"})
    segs.append({"params": [["rate", 0.2], ["reset", 1]], "wait": s(0.25), "snap": "r02_000ms"})
    for ms, sec in ((500, 0.25), (1000, 0.5), (2000, 1.0), (4000, 2.0), (8000, 4.0)):
        segs.append({"wait": s(sec), "snap": f"r02_{ms:04d}ms"})
    return segs


def ppm(path, arr3):
    with open(path, "wb") as fh:
        fh.write(f"P6\n{arr3.shape[1]} {arr3.shape[0]}\n255\n".encode())
        fh.write(arr3.astype(np.uint8).tobytes())


def test_module_lifecycle_over_time():
    segs = segments()
    frames = sum((seg.get("wait", 60) + len(seg.get("params", [])) + 1) for seg in segs)
    print(f"bench_fc_look: {len(segs)} snapshots, ~{frames} frames (~{frames / 60:.0f}s)")
    OUT_DIR.mkdir(exist_ok=True)

    job, job_dir = bc.new_job("module", warmup=10, settle=6, timeout_ms=240000)
    job["wrapper"] = f"mjob_{job['id']}.maxpat"
    mod = mb.Module((_paths.REPO / "package" / "patchers" / "f_formconstants.maxpat"))
    n_in, n_out = mb.module_io(mod)
    with open(bc.BENCH_DIR / job["wrapper"], "w") as fh:
        import json
        json.dump(mb.make_wrapper("f_formconstants.maxpat", n_in, n_out), fh, indent=2)
    jxf.write_rgba(job_dir / "in1.jxf", mb.neutral(N))
    job["inputs"] = ["in1.jxf"]
    job["segments"] = segs

    t0 = time.time()
    result = bc.run_job(job, job_dir, ports=bc.MODULE_PORTS)
    # the module bench's nesting posts this for every module (bench_modules.py
    # ENV_NOISE); the job itself rendered all frames
    noise = ["jpatcher: doesn't understand getattr"]
    errs = [e for e in (result.get("errors") or []) if e not in noise]
    print(f"job: {result['status']} in {time.time() - t0:.0f}s "
          f"({result.get('frames_rendered')} frames rendered) errors={errs}")
    assert not errs, f"module job failed: {errs}"
    if errs:
        note("job errors", str(errs))

    print(f"\n{'snapshot':12s} {'mean':>6s} {'std':>6s} {'sat%':>6s}")
    rows = []
    for tag in [s["snap"] for s in segs]:
        arr = jxf.read_rgba(job_dir / f"{tag}_out1.jxf")
        e = arr[..., 0].astype(np.float64)
        std = float(e.std())
        mean = float(e.mean())
        sat = float(np.mean((e < 0.01) | (e > 0.99)))
        rows.append((tag, arr, mean, std, sat))
        print(f"{tag:12s} {mean:6.3f} {std:6.3f} {sat:6.3f}")
    # discriminating checks (numbers over labels, both printed and asserted)
    r10 = {t[0]: t for t in rows if t[0].startswith("r10")}
    r02 = {t[0]: t for t in rows if t[0].startswith("r02")}
    note("death onset (first snap below std 0.05) r10/r02",
         f"{next((t[0] for t in rows if t[0].startswith('r10') and t[3] < 0.05), 'never')}"
         f" / {next((t[0] for t in rows if t[0].startswith('r02') and t[3] < 0.05), 'never')}")
    # contact sheets
    for prefix, sheet_rows in (("r10", [r for r in rows if r[0].startswith("r10")]),
                               ("r02", [r for r in rows if r[0].startswith("r02")])):
        ims = [r[1] for r in sheet_rows]
        g0 = np.clip(np.stack([a[..., 0] for a in ims]) * 255, 0, 255).astype(np.uint8)
        sheet = np.concatenate(list(g0), axis=1)
        sheet = np.repeat(np.repeat(sheet, 3, axis=0), 3, axis=1)[..., None].repeat(3, axis=2)
        path = OUT_DIR / f"{prefix}_{time.strftime('%Y%m%d-%H%M%S')}.ppm"
        ppm(path, sheet)
        print("sheet:", path.relative_to(_paths.REPO))
    print("job dir:", Path(job_dir).relative_to(_paths.REPO))
    check("module sustains a structured field at default dials 8s in",
          0.05 - r10["r10_8000ms"][3], 0.0)


if __name__ == "__main__":
    sys.exit(run(globals()))
