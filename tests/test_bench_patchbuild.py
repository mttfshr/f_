"""
test_bench_patchbuild.py -- the shared helpers of the two bench-patch generators (tests/bench/patchbuild.py,
build_cleanup T026) and the generators' output.  Offline, stdlib + the repo's own modules.

  - Patch.obj / comment / wire write the box and cord shapes the generators always wrote, in the same key order
  - patcher_dict writes the wrapper in the order Max writes it, with its own copy of the appversion
  - regenerating both bench patches reproduces the committed files byte for byte (the proof that moving the
    helpers changed nothing), and the generators still run

    tests/run.sh tests/test_bench_patchbuild.py
"""
import json
import subprocess
import sys
from pathlib import Path

from harness import check, run

BENCH = Path(__file__).resolve().parent / "bench"
sys.path.insert(0, str(BENCH))
import patchbuild as pb          # noqa: E402


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def test_obj_comment_and_wire_shapes():
    p = pb.Patch()
    r = p.obj("a", "t b b", 1, 2, [1, 2, 3, 4], ["bang", "bang"], varname="v")
    _eq("obj returns its id", r, "a")
    _eq("key order and the float rect", list(p.boxes[0]["box"]),
        ["id", "maxclass", "text", "numinlets", "numoutlets", "patching_rect", "outlettype", "varname"])
    _eq("values (the rect compared as JSON, so an int is not mistaken for a float)",
        (json.dumps(p.boxes[0]["box"]["patching_rect"]), p.boxes[0]["box"]["outlettype"]),
        ("[1.0, 2.0, 3.0, 4.0]", ["bang", "bang"]))
    p.obj("b", "r draw", 0, 1, [0, 0, 1, 1])
    _eq("default outlettype is one empty string per outlet, and no varname key",
        (p.boxes[1]["box"]["outlettype"], "varname" in p.boxes[1]["box"]), ([""], False))
    p.obj("c", "udpsend", 1, 0, [0, 0, 1, 1])
    _eq("no outlets means no outlettype key", "outlettype" in p.boxes[2]["box"], False)
    p.obj("d", "x", 1, 1, [0, 0, 1, 1], maxclass="message")
    _eq("maxclass is settable", p.boxes[3]["box"]["maxclass"], "message")
    p.comment("e", "hi", [5, 6, 7, 8])
    _eq("comment shape", list(p.boxes[4]["box"]),
        ["id", "maxclass", "text", "numinlets", "numoutlets", "patching_rect"])
    p.wire("a", 1, "b", 0)
    _eq("wire shape", p.lines, [{"patchline": {"source": ["a", 1], "destination": ["b", 0]}}])
    q = pb.Patch()
    _eq("two Patches do not share their lists", (q.boxes, q.lines), ([], []))


def test_patcher_dict_wrapper():
    d = pb.patcher_dict([1], [2])
    inner = d["patcher"]
    _eq("keys in Max's order", list(inner), ["fileversion", "appversion", "classnamespace", "rect", "boxes", "lines"])
    _eq("default rect", inner["rect"], [100.0, 100.0, 900.0, 640.0])
    _eq("a given rect is floated (compared as JSON: 1 == 1.0 in Python, but the file differs)",
        json.dumps(pb.patcher_dict([], [], (1, 2, 3, 4))["patcher"]["rect"]), "[1.0, 2.0, 3.0, 4.0]")
    inner["appversion"]["major"] = 0
    _eq("each wrapper has its own appversion copy", pb.APPVERSION["major"], 9)


def test_regenerating_both_bench_patches_is_byte_identical():
    names = ("bench.maxpat", "bench_module.maxpat", "bench_module_empty.maxpat", "bench_default.genjit")
    before = {n: (BENCH / n).read_bytes() for n in names}
    try:
        for script in ("make_bench.py", "make_module_bench.py"):
            r = subprocess.run([sys.executable, str(BENCH / script)], capture_output=True, text=True)
            _eq(f"{script} runs", r.returncode, 0)
        for n in names:
            _eq(f"{n} is byte-identical after regenerating", (BENCH / n).read_bytes() == before[n], True)
    finally:
        for n in names:                          # the generators write in place: never leave a failure's output behind
            (BENCH / n).write_bytes(before[n])


if __name__ == "__main__":
    sys.exit(run(globals()))
