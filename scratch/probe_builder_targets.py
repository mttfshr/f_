"""
probe_builder_targets.py -- throwaway (tasks T009, T010 of .specify/f_caustic_scatter/): can the declarative builder
express the f_caustic sheets-mode structure? Builds a THROWAWAY definition in-process (nothing is written to
package/) and reads the cords back.

Questions:
  T009  one param to several pix stages (pix_target list); bypass_gate to several stages (bypass_target)
  T010  an outlet fed by a pix_chain node (outlet_source); a mod_inlet fanning into a pix node AND a raw box;
        the texture inlet fanning (inlet_fanout) into a pix node AND a raw box

Run:  build/py.sh scratch/probe_builder_targets.py
"""
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "build"))
import build_patcher as bp  # noqa: E402

CAUSTIC = "Param bypass_gate(0);\nParam gain(0.5);\nParam mix_pct(0.0);\nout1 = in1;\nout2 = in2;\n"
SHEETS = "Param bypass_gate(0);\nParam gain(0.5);\nParam mix_pct(0.0);\nout1 = in1;\nout2 = in2;\n"
SELECT = ("Param bypass_gate(0);\nParam sheets_gate(0);\n"
          "out1 = mix(in1, in3, sheets_gate);\nout2 = mix(in2, in4, sheets_gate);\n")


def raw(oid, text, nin, nout):
    return {"box": {"id": oid, "maxclass": "newobj", "text": text, "numinlets": nin, "numoutlets": nout,
                    "outlettype": ["jit_gl_texture"] * nout, "patching_rect": [400.0, 300.0, 120.0, 22.0]}}


patcher = {
    "name": "f_probe_sheets", "prefix": "probe", "title": "Probe", "archetype": "processor",
    "signal_type": "vecfield", "bypass_mode": "param", "bypass_target": ["caustic", "select"],
    "presentation_width": 227, "presentation_height": 130,
    "outlets": [{"comment": "composite"}, {"comment": "caustic"}],
    "outlet_source": {0: ["select", 0], 1: ["select", 1]},
    "inlet_fanout": {"texture": [["caustic", 0], ["sheets", 0], ["obj-901", 0]], "state": ["caustic"],
                     "state_param": "src_mode"},
    "mod_inlets": [{"label": "vecfield", "vs_instate": False,
                    "fanout": [["caustic", 1], ["sheets", 1], ["obj-902", 0]]}],
    "pix_chain": [
        {"id": "caustic", "name": "probe_caustic", "gen_code": CAUSTIC, "n_inlets": 2, "n_outlets": 2,
         "pix_type": "float32", "primary": True},
        {"id": "sheets", "name": "probe_sheets", "gen_code": SHEETS, "n_inlets": 2, "n_outlets": 2,
         "pix_type": "float32", "primary": False},
        {"id": "select", "name": "probe_select", "gen_code": SELECT, "n_inlets": 5, "n_outlets": 2,
         "pix_type": "float32", "primary": False},
    ],
    "pix_wires": [["caustic", 0, "select", 0], ["caustic", 1, "select", 1],
                  ["sheets", 0, "select", 2], ["sheets", 1, "select", 3]],
    "params": [
        {"name": "gain", "type": "float", "min": 0.0, "max": 2.0, "default": 0.5, "label": "Gain",
         "pix_target": ["caustic", "sheets"], "pix_shared_attrui": True},
        {"name": "mix_pct", "type": "float", "min": 0.0, "max": 100.0, "default": 0.0, "label": "Mix",
         "widget": "numbox", "pix_target": ["caustic", "sheets"], "pix_shared_attrui": True},
        {"name": "bypass", "type": "bypass"},
    ],
    "raw_boxes": [raw("obj-901", "jit.gl.slab vsynth @inputs 1", 1, 2),
                  raw("obj-902", "jit.gl.slab vsynth @inputs 1", 1, 2)],
    "raw_lines": [],
}


def label(boxes, oid):
    b = boxes.get(oid, {})
    return f"{oid}[{(b.get('text') or b.get('name') or b.get('maxclass') or '?')[:34]}]"


def main():
    try:
        out = bp.build(patcher)
    except Exception as e:                                  # a loud builder error IS an answer
        print("BUILD FAILED:", type(e).__name__, e)
        return 1
    d = out["patcher"]
    boxes = {b["box"]["id"]: b["box"] for b in d["boxes"]}
    lines = [(l["patchline"]["source"], l["patchline"]["destination"]) for l in d["lines"]]
    pix = {oid: b for oid, b in boxes.items() if (b.get("text") or "").startswith("jit.gl.pix")}
    print(f"built: {len(boxes)} boxes, {len(lines)} cords; pix objects: "
          f"{[(oid, b['text'].split('@name ')[1].split()[0]) for oid, b in pix.items()]}")

    def show(title, pred):
        print(f"\n{title}")
        n = 0
        for (s, so), (t, ti) in lines:
            if pred(s, so, t, ti):
                n += 1
                print(f"   {label(boxes, s)}:{so} -> {label(boxes, t)}:{ti}")
        if not n:
            print("   (none)")

    pix_ids = set(pix)
    show("T009: cords INTO each pix inlet 0 from non-pix, non-raw boxes (bypass / params / texture):",
         lambda s, so, t, ti: t in pix_ids and ti == 0 and s not in pix_ids and "prepend" in (boxes[s].get("text") or ""))
    show("T009: every 'attrui' that feeds a pix (gain / mix_pct targets):",
         lambda s, so, t, ti: t in pix_ids and boxes[s].get("maxclass") == "attrui")
    show("T010: cords INTO the two outlets:",
         lambda s, so, t, ti: boxes[t].get("maxclass") == "outlet")
    show("T010: cords into the raw slab boxes obj-901 / obj-902:",
         lambda s, so, t, ti: t in ("obj-901", "obj-902"))
    show("T010: cords into pix inlets 1+ (the texture / vecfield fanout):",
         lambda s, so, t, ti: t in pix_ids and ti >= 1 and s not in pix_ids)
    return 0


if __name__ == "__main__":
    sys.exit(main())
