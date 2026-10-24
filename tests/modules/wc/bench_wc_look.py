"""
bench_wc_look.py -- f_wc Phase 2 tuning instrument (tasks.md T030/T031/T032).

Loads the shipped f_wc into the module bench and runs ONE parametric job (the
"segments" timeline branch in tests/bench/bench_module.js):

    1. SOAK: defaults (rate 1, grain 1.4, drive off), snapshots at 4s / 12s / 30s
       -- the NF-003 long-soak window for the live module (finite, no saturation).
    2. GRAIN SWEEP: sigma_I from 1.1 (fine, stripe-glass) to 3.5 (coarse labyrinth),
       reseeded and 3 s settled at each mark -- snapshots for the landmark-snap
       candidates and dial feel (T031).
    3. DRIVE INJECTION: a pattern-scale scene on the drive inlet from the start but
       inactive (drive_gain 0), then drive_gain 1.5 with snapshots at +0.25 s,
       +1 s, +4 s, then off again at +1 s -- the hallucinate -> see transition
       speed and legibility (T032).

Every snapshot lands as a jxf in the job dir; the script then prints a metric table
(contrast / saturation / dominant pattern wavelength / scene correlation) and writes
a contact-sheet PNG per phase to tests/logs/ for Matt's look.

Run (Max open, module bench loaded as bench.maxpat equivalent; reopen handled):
    tests/bench.sh tests/modules/wc/bench_wc_look.py
"""
import sys
import time
from pathlib import Path

import numpy as np

import paths as _paths
import benchclient as bc
import jxf
import modulebench as mb

N = 128                      # module bench texture size
OUT_DIR = _paths.REPO / "tests" / "logs" / "wc_look"
LOG_DIR = _paths.REPO / "tests" / "logs"


def scene(n):
    """Pattern-scale drive scene: smoothed noise in [0, 1] (the T007 style)."""
    rng = np.random.default_rng(41)
    raw = rng.random((n, n))
    ky, kx = np.meshgrid(np.fft.fftfreq(n), np.fft.fftfreq(n), indexing="ij")
    k2 = kx * kx + ky * ky
    blurred = np.real(np.fft.ifft2(np.fft.fft2(raw) * np.exp(-2 * np.pi ** 2 * 3.0 ** 2 * k2)))
    blurred = (blurred - blurred.min()) / (blurred.max() - blurred.min() + 1e-12)
    t = np.zeros((n, n, 4), np.float32)
    t[..., 0] = blurred.astype(np.float32)
    return t


def segments(fps=60):
    def s(sec):
        return int(sec * fps)
    return [
        {"params": [["rate", 1.0], ["grain", 1.4], ["drive_gain", 0.0], ["reset", 1]],
         "wait": s(4), "snap": "soak_04s"},
        {"wait": s(8), "snap": "soak_12s"},
        {"wait": s(18), "snap": "soak_30s"},
        {"params": [["grain", 1.1], ["reset", 1]], "wait": s(3), "snap": "grain_1.1"},
        {"params": [["grain", 1.4], ["reset", 1]], "wait": s(3), "snap": "grain_1.4"},
        {"params": [["grain", 1.9], ["reset", 1]], "wait": s(3), "snap": "grain_1.9"},
        {"params": [["grain", 2.6], ["reset", 1]], "wait": s(3), "snap": "grain_2.6"},
        {"params": [["grain", 3.5], ["reset", 1]], "wait": s(3), "snap": "grain_3.5"},
        {"params": [["grain", 1.4], ["reset", 1]], "wait": s(4), "snap": "drive_pre"},
        {"params": [["drive_gain", 1.5]], "wait": s(0.25), "snap": "drive_t0.25s"},
        {"wait": s(0.75), "snap": "drive_t1s"},
        {"wait": s(3), "snap": "drive_t4s"},
        {"params": [["drive_gain", 0.0]], "wait": s(1), "snap": "drive_off_1s"},
    ]


def metrics(rgba, n, ref=None):
    """Per-snapshot numbers for the tuning table."""
    e = rgba[..., 0].astype(np.float64)
    out = {"std": float(e.std()), "sat": float(np.mean((e < 0.01) | (e > 0.99)))}
    z = np.abs(np.fft.fft2(e - e.mean()))
    z[0, 0] = 0
    idx = np.unravel_index(np.argmax(z), z.shape)
    cyc = float(np.hypot(idx[0], idx[1]))
    out["lam_px"] = round(n / cyc, 1) if cyc > 0 else float("inf")
    if ref is not None:
        a, b = e.ravel() - e.mean(), ref.ravel() - ref.mean()
        out["scene_corr"] = float(a @ b / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12))
    return out


def main():
    segs = segments()
    frames = sum((seg.get("wait", 60) + len(seg.get("params", [])) + 1) for seg in segs)
    print(f"bench_wc_look: {len(segs)} segments, ~{frames} frames (~{frames / 60:.0f}s)")

    job, job_dir = bc.new_job("module", warmup=10, settle=6, timeout_ms=240000)
    job["wrapper"] = f"mjob_{job['id']}.maxpat"
    mod = mb.Module((_paths.REPO / "package" / "patchers" / "f_wc.maxpat"))
    n_in, n_out = mb.module_io(mod)
    with open(bc.BENCH_DIR / job["wrapper"], "w") as fh:
        import json
        json.dump(mb.make_wrapper("f_wc.maxpat", n_in, n_out), fh, indent=2)
    neutral = mb.neutral(N)
    jxf.write_rgba(job_dir / "in1.jxf", neutral)
    jxf.write_rgba(job_dir / "in2.jxf", scene(N))
    job["inputs"] = ["in1.jxf", "in2.jxf"]
    job["segments"] = segs

    t0 = time.time()
    result = bc.run_job(job, job_dir, ports=bc.MODULE_PORTS)
    print(f"job: {result['status']} in {time.time() - t0:.0f}s "
          f"({result.get('frames_rendered')} frames rendered) errors={result.get('errors')}")
    if result["status"] != "ok":
        for f in Path(job_dir).glob("*.gen"):
            print("  leftover:", f)
        return 1

    ref_tex = jxf.read_rgba(job_dir / "in2.jxf")[..., 0].astype(np.float64)

    OUT_DIR.mkdir(exist_ok=True)
    print(f"\n{'snapshot':16s} {'std':>6s} {'sat':>6s} {'lam_px':>8s} {'corr':>6s}")
    rows = []
    snaps = [s["snap"] for s in segs if "snap" in s]
    for tag in snaps:
        arr = jxf.read_rgba(job_dir / f"{tag}_out1.jxf")
        m = metrics(arr, N, ref=ref_tex if tag.startswith("drive") else None)
        rows.append((tag, arr, m))
        print(f"{tag:16s} {m['std']:6.3f} {m['sat']:6.3f} {m['lam_px']:>8.1f} "
              f"{m['scene_corr']:6.2f}" if "scene_corr" in m else
              f"{tag:16s} {m['std']:6.3f} {m['sat']:6.3f} {m['lam_px']:>8.1f}")
    # contact sheets: 128x128 RGBA luma -> tile per phase
    # contact sheets per phase, written as plain PPM (no pillow dependency)
    def ppm(path, arr3):
        with open(path, "wb") as fh:
            fh.write(f"P6\n{arr3.shape[1]} {arr3.shape[0]}\n255\n".encode())
            fh.write(arr3.astype(np.uint8).tobytes())
    upscaled = []
    for name, tags in (("soak", [s for s in snaps if s.startswith("soak")]),
                       ("grain", [s for s in snaps if s.startswith("grain")]),
                       ("drive", [s for s in snaps if s.startswith("drive")])):
        ims = [dict(rows)[t] for t in tags]
        g0 = np.clip(np.stack([a[..., 0] for a in ims]) * 255, 0, 255).astype(np.uint8)
        sheet = np.concatenate(list(g0), axis=1)
        sheet = np.repeat(np.repeat(sheet, 3, axis=0), 3, axis=1)[..., None].repeat(3, axis=2)
        path = OUT_DIR / f"{name}_{time.strftime('%Y%m%d-%H%M%S')}.ppm"
        ppm(path, sheet)
        upscaled.append(path)
        print("sheet:", path.relative_to(_paths.REPO))
    print("job dir:", Path(job_dir).relative_to(_paths.REPO))
    return 0


if __name__ == "__main__":
    sys.exit(main())
