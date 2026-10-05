"""
test_build_conventions.py -- the builder writes what Max writes (build_cleanup/T008 round-trip,
Matt 2026-10-05), so a patcher opened and saved in Max changes nothing:

  - a float-type numbox is written with parameter_unitstyle 1 (Float); Max rewrites 0 to 1
  - every inlet/outlet is written with index 0; Max rewrites every index to 0 and orders the
    ports by patching_rect x, so the x order must BE the port order (check_port_order)

    tests/run.sh tests/test_build_conventions.py
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp          # noqa: E402
import drift                        # noqa: E402

from harness import check, run      # noqa: E402


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def _defn():
    return {"name": "f_t", "prefix": "t", "object_name": "t_pix", "title": "Test", "signal_type": "texture",
            "archetype": "processor", "pix_type": "char", "presentation_width": 160, "presentation_height": 90,
            "outlets": [{"comment": "composite"}, {"comment": "aux"}, {"comment": "third"}],
            "mod_inlets": [{"label": "a mod", "state_param": "src_a"}, {"label": "b mod", "state_param": "src_b"}],
            "params": [
                {"name": "g", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "label": "G", "hint": "g"},
                {"name": "mix_pct", "type": "float", "min": 0.0, "max": 100.0, "default": 0.0, "label": "Mix",
                 "widget": "numbox", "hint": "m"},
                {"name": "n", "type": "int", "min": 0, "max": 8, "default": 1, "label": "N", "hint": "n"},
                {"name": "src_a", "type": "internal"}, {"name": "src_b", "type": "internal"},
                {"name": "bypass", "type": "bypass"},
            ],
            "codebox": "Param g(0.5);\nParam mix_pct(0.0);\nParam n(1);\nParam src_a(0);\nParam src_b(0);\n"
                       "Param bypass(0.0);\nout1 = in1 * g;"}


def _boxes():
    return [b["box"] for b in bp.build(_defn())["patcher"]["boxes"]]


def test_numbox_is_written_as_max_writes_it():
    nums = [b for b in _boxes() if b.get("maxclass") == "live.numbox"]
    _eq("the definition makes two numboxes (a float one and an int one)", len(nums), 2)
    for b in nums:
        v = b["saved_attribute_attributes"]["valueof"]
        if v["parameter_longname"] == "mix_pct":
            _eq("a float-type numbox is parameter_type 0 / unitstyle 1 (Float)",
                (v["parameter_type"], v["parameter_unitstyle"]), (0, 1))
    dials = [b for b in _boxes() if b.get("maxclass") == "live.dial"]
    _eq("a dial is unitstyle 1 too (unchanged)",
        {b["saved_attribute_attributes"]["valueof"]["parameter_unitstyle"] for b in dials}, {1})


def test_every_port_is_index_zero_and_in_x_order():
    boxes = _boxes()
    for mc, n in (("inlet", 3), ("outlet", 3)):
        ports = [b for b in boxes if b.get("maxclass") == mc]
        _eq(f"{n} {mc}s", len(ports), n)
        _eq(f"every {mc} is written with index 0 (Max rewrites it to 0)",
            {b["index"] for b in ports}, {0})
        xs = [b["patching_rect"][0] for b in ports]
        _eq(f"the {mc}s are in strictly increasing x order, so Max keeps the port order",
            xs == sorted(xs) and len(set(xs)) == len(xs), True)
        _eq(f"...and the {mc}s are labelled in the intended order",
            [b["comment"] for b in ports],
            ["texture / control", "a mod", "b mod"] if mc == "inlet" else ["composite", "aux", "third"])


def _port(bid, mc, x):
    return {"box": {"id": bid, "maxclass": mc, "patching_rect": [x, 10.0, 30.0, 30.0]}}


def test_check_port_order():
    bp.check_port_order([_port("a", "inlet", 10.0), _port("b", "inlet", 50.0), _port("c", "outlet", 5.0)])
    check("increasing x passes", 0, 0)
    for label, boxes in (("inlets out of x order", [_port("a", "inlet", 50.0), _port("b", "inlet", 10.0)]),
                         ("outlets out of x order", [_port("a", "outlet", 90.0), _port("b", "outlet", 20.0)]),
                         ("two inlets at the same x", [_port("a", "inlet", 30.0), _port("b", "inlet", 30.0)])):
        try:
            bp.check_port_order(boxes)
        except ValueError as e:
            check(label + " is refused", 0 if "x" in str(e) else 1, 0)
        else:
            check(label + " (nothing was raised)", 1, 0)
    bp.check_port_order([_port("a", "inlet", 50.0), {"box": {"id": "t", "maxclass": "comment",
                                                               "patching_rect": [1.0, 1.0, 1.0, 1.0]}}])
    check("a non-port box at a smaller x is ignored", 0, 0)


def test_build_runs_the_port_order_check():
    calls = []
    real = bp.check_port_order
    bp.check_port_order = lambda boxes: (calls.append(len(boxes)), real(boxes))[1]
    try:
        bp.build(_defn())
    finally:
        bp.check_port_order = real
    _eq("build() calls check_port_order exactly once, on the finished box list", len(calls), 1)
    _eq("...with the whole patcher's boxes", calls[0] > 20, True)


def test_every_shipped_definition_builds_with_ports_in_order():
    n = 0
    for name in drift.shipped_names():
        if drift.definition_path(name).exists() and not drift.builder_script(name):
            built, _ = drift.build_module(name)      # build() runs check_port_order itself
            n += 1
            for mc in ("inlet", "outlet"):
                idx = {b["box"]["index"] for b in built["patcher"]["boxes"] if b["box"].get("maxclass") == mc}
                _eq(f"{name}: {mc} index", idx <= {0}, True)
    print(f"    ({n} definitions built)")
    _eq("a useful number of definitions were checked", n >= 25, True)


if __name__ == "__main__":
    sys.exit(run(globals()))
