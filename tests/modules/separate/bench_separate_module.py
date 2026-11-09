"""
bench_separate_module.py -- f_separate T022 (module half): the shipped patcher in the live module bench. The codebox bench
(bench_separate.py) cannot see this layer: the `r draw` -> delay -> bang that sends the default colours, the route -> swatch ->
unpack -> `prepend param` chain, the saturation dials, the Mode menu. That layer is where Matt's all-black look of 2026-11-08 was.

Each job is a `segments` timeline (bench_module.js): control messages one per frame, a wait in frames, a snapshot of all four
outlets. The source is fed every frame at the render size, 640 x 640 (bench_modules.RENDER_DIM_SIZE); each snapshot's shape is
checked.

Reading the inks back. In Project mode with gain 1, a white pixel has coverage sum(k) / sum(k*k), which is at least 1 for k in
0..1, so it clamps to 1 and the plate shows the ink colour exactly. The source has a white patch for this. The rows that compare
against the mirror use the inks READ BACK, so a swatch error cannot pass as, or be hidden by, a solve error; the read-back inks
get their own rows.

Asserted (thresholds written before the first run; not to be loosened to make a failure pass):
  - load, no messages at all: plates 1 and 2 are not black, plate 3 is, all four match the mirror (the all-black regression)
  - the default inks arrive close to the definition's colours (BANG_TOL)
  - Mode menu and Inks: Unmix, Nearest, Project at three inks, and one ink, match the mirror
  - `inkN r g b` reaches ink N only, close to the commanded colour (LIST_TOL), and leaves the other plates exactly unchanged
  - gains reach the pix
  - a saturation dial changes its own ink and leaves the other plates exactly unchanged (T021's open question)

Tolerances:
  TOL       the codebox bench's (bench_separate.py); the same codebox, measured worst 4.8e-7 for non-degenerate palettes.
  LIST_TOL  a list into a swatch "sets the four RGBA color components" and outputs them (swatch.maxref). 2e-2 allows the swatch's
            own conversion; unmeasured, the first run records the real number.
  BANG_TOL  the defaults arrive by `set` then a bang, and a bang outputs "the current color at the selected (x,y) position"
            (swatch.maxref), so they may be quantised to the swatch's pixels. INFERRED from the maxref, not measured: one pixel of
            hue across about 56 pixels is about 6/56 = 0.11 in RGB, half of that from rounding, plus lightness. 0.15 catches a
            wrong colour, not a slightly different one. The real number is noted; recalibrate from it and record why.

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
from separate_mirror import F32, separate_stage

N = 640
SETTLE = 60            # frames after a control message; the load path's delay is 100 ms after the first draw
PATCH = 32             # the white patch's side, top left of the source
TOL = 2e-3
LIST_TOL = 2e-2
BANG_TOL = 0.15
DEFAULTS = np.array([[1.0, 0.25, 0.0], [0.0, 0.6, 0.6], [0.45, 0.0, 1.0]], dtype=F32)   # definition.py DEFAULTS


def photo(seed=5, n=N):
    """Random colours and alpha inside 0..1, and the white patch that reads the inks back."""
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
    """The four outlets of one snapshot, as a list (plates 1 to 3, preview)."""
    assert tag in frames and all(k in frames[tag] for k in (1, 2, 3, 4)), f"no complete {tag} snapshot: {sorted(frames)}"
    got = [frames[tag][k] for k in (1, 2, 3, 4)]
    check(f"{tag}: all four outlets at the render size", float(any(g_.shape[:2] != (N, N) for g_ in got)), 0.0)
    return got


def readback(got):
    """The ink colours, from the white patch of a Project snapshot taken with gain 1 and three inks."""
    return np.array([got[i][PATCH // 2, PATCH // 2, :3] for i in range(3)], dtype=F32)


def matches(got, label, inks, n_inks=3, mode="unmix", gains=(1.0, 1.0, 1.0)):
    want = separate_stage(SRC, inks, n_inks=n_inks, mode=mode, gains=gains)
    worst = max(mx(got[i][..., :3], want[i][..., :3]) for i in range(4))
    note(f"{label}: worst rgb error over the four outlets", worst)
    check(f"{label}: rgb vs mirror", worst, TOL)
    check(f"{label}: alpha is the source's", max(mx(g_[..., 3], SRC[..., 3]) for g_ in got), 1e-6)


READ = {"params": [["n_inks", 3], ["sep_mode", 2]], "wait": SETTLE, "snap": "read"}


def test_load_touching_nothing():
    """The all-black regression: no message reaches the module before the first snapshot."""
    f = job([{"wait": SETTLE, "snap": "load"}, READ])
    load, inks = outs(f, "load"), readback(outs(f, "read"))
    note("default inks read back", inks.tolist())
    note("default inks: worst distance from the definition's colours", mx(inks, DEFAULTS))
    check("default inks arrive near the definition's colours", mx(inks, DEFAULTS), BANG_TOL)
    check("load: plate 1 is not black", float(load[0][..., :3].max() < 0.1), 0.0)
    check("load: plate 2 is not black", float(load[1][..., :3].max() < 0.1), 0.0)
    check("load: preview is not black", float(load[3][..., :3].max() < 0.1), 0.0)
    check("load: plate 3 is black (default two inks)", float(np.abs(load[2][..., :3]).max()), 1e-6)
    matches(load, "load, defaults", inks, n_inks=2)


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


def test_ink_message_reaches_one_ink():
    """`inkN r g b` goes route -> swatch -> unpack -> `prepend param`. The second colour is a pastel, off the swatch's plane."""
    one, two = np.array([0.2, 0.0, 0.8], F32), np.array([0.6, 0.5, 0.4], F32)
    f = job([READ,
             {"params": [["ink1", *one.tolist()]], "wait": SETTLE, "snap": "moved1"},
             {"params": [["ink2", *two.tolist()]], "wait": SETTLE, "snap": "moved2"}])
    before, moved1, moved2 = outs(f, "read"), outs(f, "moved1"), outs(f, "moved2")
    note("ink 1 commanded distance", mx(readback(moved1)[0], one))
    note("ink 2 (pastel) commanded distance", mx(readback(moved2)[1], two))
    check("ink1 message: ink 1 is the commanded colour", mx(readback(moved1)[0], one), LIST_TOL)
    check("ink2 message: ink 2 is the commanded pastel", mx(readback(moved2)[1], two), LIST_TOL)
    check("ink1 message: plate 2 exactly unchanged (Project)", mx(moved1[1], before[1]), 0.0)
    check("ink1 message: plate 3 exactly unchanged (Project)", mx(moved1[2], before[2]), 0.0)
    check("ink2 message: plate 1 exactly unchanged (Project)", mx(moved2[0], moved1[0]), 0.0)
    matches(moved2, "Project after both messages", readback(moved2), mode="project")


def test_gains():
    gains = (0.5, 2.0, 0.0)
    f = job([READ,
             {"params": [["sep_mode", 0], ["gain1", gains[0]], ["gain2", gains[1]], ["gain3", gains[2]]],
              "wait": SETTLE, "snap": "gains"}])
    got = outs(f, "gains")
    matches(got, "Unmix, gains 0.5, 2, 0", readback(outs(f, "read")), gains=gains)
    check("gain 0 empties plate 3", float(np.abs(got[2][..., :3]).max()), 1e-6)


def test_saturation_dial():
    """T021's open question: dial -> expr -> [t b f] -> `saturation`, then a bang, so the swatch sends its colour again."""
    f = job([READ,
             {"params": [["sat1", 0.5]], "wait": SETTLE, "snap": "half"},
             {"params": [["sat1", 1.0]], "wait": SETTLE, "snap": "back"}])
    before, half, back = outs(f, "read"), outs(f, "half"), outs(f, "back")
    note("ink 1 at Sat 1 = 1", readback(before)[0].tolist())
    note("ink 1 at Sat 1 = 0.5", readback(half)[0].tolist())
    note("ink 1 after Sat 1 returns to 1 (noted, not asserted)", readback(back)[0].tolist())
    check("Sat 1 changes ink 1", float(mx(readback(half)[0], readback(before)[0]) < 0.05), 0.0)
    check("Sat 1: plate 2 exactly unchanged (Project)", mx(half[1], before[1]), 0.0)
    check("Sat 1: plate 3 exactly unchanged (Project)", mx(half[2], before[2]), 0.0)
    matches(half, "Project at Sat 1 = 0.5", readback(half), mode="project")


if __name__ == "__main__":
    sys.exit(run(globals()))
