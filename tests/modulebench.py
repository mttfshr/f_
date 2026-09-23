"""
modulebench.py -- client side of the E3 module bench
(tests/bench/bench_module.maxpat; .specify/test_bench/tasks_extensions.md).

run_module(name) loads a shipped f_ module into the bench inside Vsynth's
real vs_render context, feeds it textures, sends each route parameter as a
control message, reads the resulting attributes back off the module's inner
jit.gl.pix objects, exercises bypass (documented control message and the
jsui), and captures every outlet before and under bypass.

Test values come from the shipped patch's own UI objects (live.dial /
live.numbox parameter_mmin/mmax), not from definition.py.
"""
import json
import re
from pathlib import Path

import numpy as np

import benchclient as bc
import jxf
from module_contract import Module, PATCHERS, PASS_THROUGH, pix_name, pix_params, _is_pix

REPO = Path(__file__).resolve().parent.parent


def module_io(mod):
    """(n_inlets, n_outlets) of the bpatcher itself."""
    ins = sum(1 for b in mod.boxes.values() if b.get("maxclass") == "inlet")
    outs = sum(1 for b in mod.boxes.values() if b.get("maxclass") == "outlet")
    return ins, outs


def archetype(name):
    d = REPO / "src" / name / "definition.py"
    if d.exists():
        m = re.search(r'"archetype"\s*:\s*"(\w+)"', d.read_text())
        if m:
            return m.group(1)
    return None


def _control_range(box):
    """(min, max, is_int) from a live.* object's saved parameter attributes."""
    v = ((box.get("saved_attribute_attributes") or {}).get("valueof") or {})
    lo, hi = v.get("parameter_mmin"), v.get("parameter_mmax")
    ptype = v.get("parameter_type")                  # 0 float, 1 int, 2 enum
    if box.get("maxclass") == "live.menu" or ptype == 2:
        n = len(v.get("parameter_enum") or []) or 2
        return 0, n - 1, True
    if lo is None or hi is None:
        return None
    return float(lo), float(hi), ptype == 1


def param_plan(mod, report):
    """For each route name that reaches an attrui: the value to send, the
    attribute(s) to read back, which pix should carry it, and whether the
    value is expected to arrive unchanged (route -> control -> attrui)."""
    attr_targets = {}
    for aid, a in mod.attruis().items():
        pixes = [pix_name(mod.boxes[t]) for t in mod.attrui_targets(aid) if _is_pix(mod.boxes[t])]
        attr_targets.setdefault(a.get("attr"), set()).update(pixes)
    plan = []
    for rid, names in mod.routes():
        for k, name in enumerate(names):
            attrs = report["route_map"].get(name)
            if not attrs:
                continue
            first = [mod.boxes[d] for d, _ in mod.out.get((rid, k), [])]
            ctrl = next((b for b in first if b.get("maxclass") in PASS_THROUGH), None)
            rng = _control_range(ctrl) if ctrl else None
            direct = False
            if ctrl is not None:
                nxt = [mod.boxes[d] for o in range(ctrl.get("numoutlets", 0))
                       for d, _ in mod.out.get((ctrl["id"], o), [])]
                direct = any(b.get("maxclass") == "attrui" for b in nxt)
            if rng is None:                      # range unknown: path check only
                value, is_int, direct = 0.37, False, False
            else:
                lo, hi, is_int = rng
                value = lo + 0.37 * (hi - lo)
                if is_int:
                    value = int(round(value)) if hi - lo >= 2 else int(hi)
            plan.append({"name": name, "value": value, "is_int": is_int, "attrs": attrs,
                         "control": ctrl.get("varname") if ctrl else None,
                         "pix": {a: sorted(attr_targets.get(a, [])) for a in attrs},
                         "value_comparable": direct and len(attrs) == 1})
    return plan


def _suffix(static_name):
    return static_name.replace("#0", "")


def test_input(n=64, seed=0):
    """Char-representable values (k/255) so char-typed modules pass through
    exactly under bypass."""
    rng = np.random.default_rng(seed)
    x = rng.integers(0, 256, (n, n, 4)).astype(np.float32) / np.float32(255)
    x[..., 3] = 1.0
    return x


def neutral(n=64):
    return np.full((n, n, 4), np.float32(128) / np.float32(255), np.float32)


def make_wrapper(module_file, n_in, n_out):
    boxes = [{"box": {"id": "mod", "maxclass": "bpatcher", "name": module_file,
                      "numinlets": n_in, "numoutlets": n_out, "varname": "bench_module",
                      "patching_rect": [20.0, 60.0, 300.0, 200.0]}}]
    lines = []
    for i in range(n_in):
        boxes.append({"box": {"id": f"rin{i + 1}", "maxclass": "newobj", "text": f"r bench_min{i + 1}",
                              "numinlets": 0, "numoutlets": 1, "outlettype": [""],
                              "patching_rect": [20.0 + 90 * i, 20.0, 85.0, 22.0]}})
        lines.append({"patchline": {"source": [f"rin{i + 1}", 0], "destination": ["mod", i]}})
    for j in range(min(n_out, 4)):
        boxes.append({"box": {"id": f"sout{j + 1}", "maxclass": "newobj", "text": f"s bench_mout{j + 1}",
                              "numinlets": 1, "numoutlets": 0,
                              "patching_rect": [20.0 + 100 * j, 280.0, 95.0, 22.0]}})
        lines.append({"patchline": {"source": ["mod", j], "destination": [f"sout{j + 1}", 0]}})
    return {"patcher": {"fileversion": 1,
                        "appversion": {"major": 9, "minor": 1, "revision": 4,
                                       "architecture": "x64", "modernui": 1},
                        "classnamespace": "box", "rect": [100.0, 100.0, 500.0, 340.0],
                        "boxes": boxes, "lines": lines}}


def run_module(name, n=64, warmup=10, settle=6, timeout_ms=15000, fresh=True):
    """Returns (result, plan, info). result carries readbacks and the list of
    captured outlets; captured arrays are in result['arrays'][tag][k].

    fresh=True reopens the module bench first. Loading many modules into one
    bench session scrambled other modules' dial ranges (_parameter_range)
    -- found 2026-09-22 during the first sweep, mechanism not investigated
    (range_tiers modules suspected). Each module gets a clean session."""
    if fresh:
        bc.reopen(ports=bc.MODULE_PORTS, patch="bench_module.maxpat")
    mod = Module(PATCHERS / f"{name}.maxpat")
    report = mod.analyze()
    n_in, n_out = module_io(mod)
    plan = param_plan(mod, report)
    readback = {}
    for p in plan:
        for a in p["attrs"]:
            readback.setdefault(a, set()).update(_suffix(x) for x in p["pix"].get(a, []))
    readback = {a: sorted(s) for a, s in readback.items() if s}

    job, job_dir = bc.new_job("module", warmup=warmup, settle=settle, timeout_ms=timeout_ms)
    job["wrapper"] = f"mjob_{job['id']}.maxpat"
    inputs = [test_input(n)] + [neutral(n) for _ in range(max(n_in - 1, 0))]
    job["inputs"] = []
    for i, arr in enumerate(inputs[:5]):
        fn = f"in{i + 1}.jxf"
        jxf.write_rgba(job_dir / fn, arr)
        job["inputs"].append(fn)
    job["params"] = [[p["name"], p["value"]] for p in plan]
    job["readback"] = readback
    job["controls"] = sorted({p["control"] for p in plan if p.get("control")})
    wrapper_path = bc.BENCH_DIR / job["wrapper"]
    with open(wrapper_path, "w") as f:
        json.dump(make_wrapper(f"{name}.maxpat", n_in, n_out), f, indent=2)

    result = bc.run_job(job, job_dir, ports=bc.MODULE_PORTS)
    for old in bc.BENCH_DIR.glob("mjob_*.maxpat"):          # keep only the loaded one
        if old != wrapper_path:
            old.unlink()
    arrays = {}
    for tag, ks in (result.get("outputs") or {}).items():
        arrays[tag] = {k: jxf.read_rgba(job_dir / f"{tag}_out{k}.jxf") for k in ks}
    result["arrays"] = arrays
    result["job_dir"] = str(job_dir)
    info = {"n_in": n_in, "n_out": n_out, "archetype": archetype(name),
            "input": inputs[0], "static": report}
    return result, plan, info


def bench_eval(js_code, timeout=5.0):
    """Run a JS snippet inside bench_module.js (debugging hook). The snippet's
    last expression is returned (JSON-serializable values only)."""
    import tempfile
    fd, path = tempfile.mkstemp(suffix=".js")
    with open(fd, "w") as f:
        f.write(js_code)
    with bc.Channel(bc.MODULE_PORTS) as ch:
        ch.send("/eval", path)
        ch.wait_for(lambda a, args: a == "/evaled", timeout)
    return json.load(open(path + ".out.json"))
