"""
bench_separate_module.py -- f_separate T022 (module half): the shipped patcher in the live module bench. The codebox bench
(bench_separate.py) cannot see this layer: the route -> numbox -> pix chain for the ink table (H, S, L and Gain per ink), the
Inks numbox, the Mode menu, the default values at load. Rewritten 2026-11-14 for the HSL ink table (the swatches, their
saturation dials and the load-timed bang are gone) and the outlet order (outlet 0 the composite, 1 to 3 the plates).

Each job is a `segments` timeline (bench_module.js): control messages one per frame, a wait in frames, a snapshot of all four
outlets. The source is fed every frame at the render size, 640 x 640 (bench_modules.RENDER_DIM_SIZE); each snapshot's shape is
checked. outs() returns the snapshot in the mirror's order (plates 1 to 3, composite).

Reading the inks back. In Project mode with gain 1, a white pixel has coverage sum(k) / sum(k*k), which is at least 1 for k in
0..1, so it clamps to 1 and the plate shows the ink color exactly. The source has a white patch for this. The rows that compare
against the mirror use the inks READ BACK, so a color error cannot pass as, or be hidden by, a solve error; the read-back inks
get their own rows, against the standard HSL model (separate_mirror.hsl_to_rgb).

Asserted (thresholds written before the first run; not to be loosened to make a failure pass):
  - load, no messages at all: all three plates and the composite are not black, and all four match the mirror
  - the default inks arrive as the definition's colors (INK_TOL)
  - Mode menu and Inks: Unmix, Nearest, Project at three inks, and one ink, match the mirror
  - `inkN_h` / `inkN_s` / `inkN_l` reach ink N only, as the commanded color (INK_TOL), and leave the other plates exactly unchanged
  - gains reach the pix

Tolerances:
  TOL      the codebox bench's (bench_separate.py); the same codebox, measured worst 4.8e-7 for non-degenerate palettes.
  INK_TOL  the module's hsl2rgb against colorsys. The same as TOL: no swatch in the path any more, so there is no
           quantisation to allow for. If the first run disagrees, the number is recorded, not the threshold widened.

Not here: bypass is the contract bench's (tests/contracts/bench_modules.py, BYPASS_EXPECT); the 1080p cost; persistence across a
plain reopen (not reachable from this harness; Matt's look). The source stays inside 0..1 and is finite: out-of-range and
non-finite texels are the codebox bench's, this file is about the wiring.

Needs Max with tests/bench/bench_module.maxpat open (Vsynth performance patches closed).
Run:  tests/bench.sh -q tests/modules/separate/bench_separate_module.py       (ask Matt first: CLAUDE.md)
"""
GROUP = "regression"
ORDER = 171            # integers only

import paths as _paths
import json
import sys

import numpy as np

import benchclient as bc
import jxf
import modulebench as mb
from harness import check, note, run
from separate_mirror import F32, hsl_to_rgb, separate_stage

N = 640
SETTLE = 60            # frames after a control message
PATCH = 32             # the white patch's side, top left of the source
TOL = 2e-3
INK_TOL = 2e-3
DEFAULTS = np.array([[1.0, 0.25, 0.0], [0.0, 0.6, 0.6], [0.45, 0.0, 1.0]], dtype=F32)   # definition.py DEFAULTS, in RGB


def photo(seed=5, n=N):
    """Random colors and alpha inside 0..1, and the white patch that reads the inks back."""
    rng = np.random.default_rng(seed)
    t = np.zeros((n, n, 4), F32)
    t[..., :3] = rng.uniform(0, 1, (n, n, 3))
    t[..., 3] = rng.uniform(0.2, 1, (n, n))
    t[:PATCH, :PATCH, :3] = 1.0
    return t


SRC = photo()


def job(segments, warmup=30):
    """One segments job. Returns {tag: {outlet: array}}, outlets 1 to 4."""
    bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    j, job_dir = bc.new_job("module", warmup=warmup, settle=6, timeout_ms=60000)
    j["wrapper"] = f"mjob_{j['id']}.maxpat"
    j["inputs"] = ["in1.jxf"]
    jxf.write_rgba(job_dir / "in1.jxf", SRC)
    j["segments"] = segments
    wrapper = bc.BENCH_DIR / j["wrapper"]
    wrapper.write_text(json.dumps(mb.make_wrapper("f_separate.maxpat", 1, 4), indent=2))
    r = bc.run_job(j, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):
        if old != wrapper:
            old.unlink()
    assert r["status"] != "stalled", r["errors"][-3:]
    return {tag: {k: jxf.read_rgba(job_dir / f"{tag}_out{k}.jxf") for k in ks} for tag, ks in (r.get("outputs") or {}).items()}


def mx(a, b):
    return float(np.max(np.abs(np.asarray(a, np.float64) - np.asarray(b, np.float64))))


def outs(frames, tag):
    """The four outlets of one snapshot, in the mirror's order (plates 1 to 3, composite). Snapshot k is module outlet k - 1:
    1 the composite, 2 to 4 the plates."""
    assert tag in frames and all(k in frames[tag] for k in (1, 2, 3, 4)), f"no complete {tag} snapshot: {sorted(frames)}"
    got = [frames[tag][k] for k in (2, 3, 4, 1)]
    check(f"{tag}: all four outlets at the render size", float(any(g_.shape[:2] != (N, N) for g_ in got)), 0.0)
    return got


def readback(got):
    """The ink colors, from the white patch of a Project snapshot taken with gain 1 and three inks."""
    return np.array([got[i][PATCH // 2, PATCH // 2, :3] for i in range(3)], dtype=F32)


def matches(got, label, inks, n_inks=3, mode="unmix", gains=(1.0, 1.0, 1.0)):
    want = separate_stage(SRC, inks, n_inks=n_inks, mode=mode, gains=gains)
    worst = max(mx(got[i][..., :3], want[i][..., :3]) for i in range(4))
    note(f"{label}: worst rgb error over the four outlets", worst)
    check(f"{label}: rgb vs mirror", worst, TOL)
    check(f"{label}: alpha is the source's", max(mx(g_[..., 3], SRC[..., 3]) for g_ in got), 1e-6)


READ = {"params": [["n_inks", 3], ["sep_mode", 2]], "wait": SETTLE, "snap": "read"}


def test_load_touching_nothing():
    """No message reaches the module before the first snapshot: the defaults alone (three inks)."""
    f = job([{"wait": SETTLE, "snap": "load"}, READ])
    load, inks = outs(f, "load"), readback(outs(f, "read"))
    note("default inks read back", inks.tolist())
    note("default inks: worst distance from the definition's colors", mx(inks, DEFAULTS))
    check("default inks arrive as the definition's colors", mx(inks, DEFAULTS), INK_TOL)
    for i, name in enumerate(("plate 1", "plate 2", "plate 3", "composite")):
        check(f"load: {name} is not black", float(load[i][..., :3].max() < 0.1), 0.0)
    matches(load, "load, defaults (three inks)", inks)


def test_mode_menu_and_ink_count():
    f = job([{"params": [["n_inks", 3]], "wait": SETTLE, "snap": "unmix3"},
             {"params": [["sep_mode", 1]], "wait": SETTLE, "snap": "nearest3"},
             {"params": [["sep_mode", 2]], "wait": SETTLE, "snap": "project3"},
             {"params": [["n_inks", 1]], "wait": SETTLE, "snap": "project1"},
             {"params": [["sep_mode", 0]], "wait": SETTLE, "snap": "unmix1"}])
    inks = readback(outs(f, "project3"))
    matches(outs(f, "unmix3"), "Unmix, three inks", inks)
    matches(outs(f, "nearest3"), "Nearest, three inks", inks, mode="nearest")
    matches(outs(f, "project3"), "Project, three inks", inks, mode="project")
    matches(outs(f, "project1"), "Project, one ink", inks, n_inks=1, mode="project")
    matches(outs(f, "unmix1"), "Unmix, one ink", inks, n_inks=1)


def test_ink_params_reach_one_ink():
    """`inkN_h` / `_s` / `_l` go route -> numbox -> pix. The second color is a pastel."""
    one, two = (255.0, 1.0, 0.4), (30.0, 0.2, 0.5)          # (0.2, 0, 0.8) and the pastel (0.6, 0.5, 0.4)
    f = job([READ,
             {"params": [["ink1_h", one[0]], ["ink1_s", one[1]], ["ink1_l", one[2]]], "wait": SETTLE, "snap": "moved1"},
             {"params": [["ink2_h", two[0]], ["ink2_s", two[1]], ["ink2_l", two[2]]], "wait": SETTLE, "snap": "moved2"}])
    before, moved1, moved2 = outs(f, "read"), outs(f, "moved1"), outs(f, "moved2")
    note("ink 1 commanded distance", mx(readback(moved1)[0], hsl_to_rgb(*one)))
    note("ink 2 (pastel) commanded distance", mx(readback(moved2)[1], hsl_to_rgb(*two)))
    check("ink 1 Params: ink 1 is the commanded color", mx(readback(moved1)[0], hsl_to_rgb(*one)), INK_TOL)
    check("ink 2 Params: ink 2 is the commanded pastel", mx(readback(moved2)[1], hsl_to_rgb(*two)), INK_TOL)
    check("ink 1 Params: plate 2 exactly unchanged (Project)", mx(moved1[1], before[1]), 0.0)
    check("ink 1 Params: plate 3 exactly unchanged (Project)", mx(moved1[2], before[2]), 0.0)
    check("ink 2 Params: plate 1 exactly unchanged (Project)", mx(moved2[0], moved1[0]), 0.0)
    matches(moved2, "Project after both inks moved", readback(moved2), mode="project")


def test_gains():
    gains = (0.5, 2.0, 0.0)
    f = job([READ,
             {"params": [["sep_mode", 0], ["gain1", gains[0]], ["gain2", gains[1]], ["gain3", gains[2]]],
              "wait": SETTLE, "snap": "gains"}])
    got = outs(f, "gains")
    matches(got, "Unmix, gains 0.5, 2, 0", readback(outs(f, "read")), gains=gains)
    check("gain 0 empties plate 3", float(np.abs(got[2][..., :3]).max()), 1e-6)


if __name__ == "__main__":
    sys.exit(run(globals()))
