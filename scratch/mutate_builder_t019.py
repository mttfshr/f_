#!/usr/bin/env python3
"""Mutation check of the T019 builder keys: tests/test_build_seeds_keys.py + test_build_multistage.py
against build/build_patcher.py.  Baseline must be green; every mutant must turn a test red; always restored."""
import hashlib
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TARGET = REPO / "build/build_patcher.py"
orig = TARGET.read_text()
sha = hashlib.sha256(orig.encode()).hexdigest()

M = [  # (label, old, new, expected_count)
    ("gen_code + gen allowed", "            if gen_spec:\n                raise ValueError(f\"pix_chain node '{node['id']}': give gen or gen_code",
     "            if False:\n                raise ValueError(f\"pix_chain node '{node['id']}': give gen or gen_code", 1),
    ("gen_code empty allowed", 'if not isinstance(node["gen_code"], str) or not node["gen_code"].strip():',
     'if not isinstance(node["gen_code"], str):', 1),
    ("param-bypass check ignores gen_code", 'if "gen_code" in nd:', 'if False:', 1),
    ("shared attrui still makes extras", 'return [] if p.get("pix_shared_attrui") else pix_targets_of(p)[1:]',
     'return pix_targets_of(p)[1:]', 1),
    ("shared attrui not wired to the other stages", 'if p.get("pix_shared_attrui"):          # ONE attrui',
     'if False:          # ONE attrui', 1),
    ("pix_attr ignored on the main attrui",
     'attrui_box(param_pre_id(n), p.get("pix_attr", p["name"]),\n                                    50.0 + n * 50.0',
     'attrui_box(param_pre_id(n), p["name"],\n                                    50.0 + n * 50.0', 1),
    ("pix_attr ignored on extra attruis",
     'attrui_box(aid, p.get("pix_attr", p["name"]), 400.0', 'attrui_box(aid, p["name"], 400.0', 2),
    ("range_menu_outlet ignored", 'wire(range_menu_id(n), p.get("range_menu_outlet", 0), range_sel_id(n), 0)',
     'wire(range_menu_id(n), 0, range_sel_id(n), 0)', 1),
    ("native bypass_target ignored", '            bypass_targets = node_refs(defn["bypass_target"], "bypass_target")\n    else:',
     '            pass\n    else:', 1),
    ("outlet_source wiring ignored",
     'lines.append(wire(outlet_src_wires[i][0], outlet_src_wires[i][1], outlet_obj_id(i), 0))',
     'lines.append(wire(primary_obj_id, i, outlet_obj_id(i), 0))', 1),
    ("outlet_source: any outlet index", " or not 0 <= oi_ < len(outlets):", ":", 1),
    ("outlet_source: clash allowed", "if oi_ in outlet_overrides:", "if False:", 1),
    ("outlet_source: stage outlet unchecked", "if spec_[0] in chain_n_out and spec_[1] >= chain_n_out[spec_[0]]:",
     "if False:", 1),
    ("mod fanout does not replace the default feed", 'tex_targets = f_.get("texture") or [(OBJ_PIX, i + offset)]',
     'tex_targets = [(OBJ_PIX, i + offset)]', 1),
    ("mod state_nodes ignored", 'for node_ in (f_["state"] if "state" in f_ else [OBJ_PIX]):',
     'for node_ in [OBJ_PIX]:', 1),
    ("mod_inlets unknown key allowed", "        if unknown:\n            raise ValueError(f\"{what}: unknown key(s)",
     "        if False:\n            raise ValueError(f\"{what}: unknown key(s)", 1),
    ("state_nodes without state_param allowed", 'if not mi_.get("state_param"):\n                raise ValueError(f"{what}.state_nodes needs',
     'if False:\n                raise ValueError(f"{what}.state_nodes needs', 1),
    ("state_nodes repeats allowed", "if len(set(targets_)) != len(targets_):", "if False:", 1),
    ("empty fanout allowed", "if (not isinstance(fo, list) or not fo\n", "if (not isinstance(fo, list)\n", 1),
    ("chain id base fixed at 50", "return max(50, UI_PARAM_BASE + n_ui_params * 3 + 2)", "return 50", 1),
    ("duplicate ids allowed", "        if bid in seen_ids:", "        if False:", 1),
    ("shared attrui without a list allowed",
     'if p["pix_shared_attrui"] and not (isinstance(p.get("pix_target"), list) and len(p["pix_target"]) > 1):',
     "if False:", 1),
    ("shared attrui with ui False allowed", 'if p["pix_shared_attrui"] and (p.get("ui") is False or p.get("pix_wire", True) is False):',
     "if False:", 1),
    ("pix_attr == name allowed", 'if p["pix_attr"] == p["name"]:', "if False:", 1),
    ("pix_attr invalid name allowed", 'if not isinstance(p["pix_attr"], str) or not p["pix_attr"].isidentifier():',
     "if False:", 1),
    ("pix_attr with pix_wire False allowed", 'if p.get("pix_wire", True) is False:\n                raise ValueError(f"param \'{p[\'name\']}\': pix_attr needs an attrui',
     'if False:\n                raise ValueError(f"param \'{p[\'name\']}\': pix_attr needs an attrui', 1),
    ("range_menu_outlet any value", 'if p["range_menu_outlet"] not in (0, 1, 2) or isinstance(p["range_menu_outlet"], bool):',
     "if False:", 1),
    ("range_menu_outlet without tiers allowed", 'if not p.get("range_tiers"):\n                raise ValueError(f"param \'{p[\'name\']}\': range_menu_outlet applies',
     'if False:\n                raise ValueError(f"param \'{p[\'name\']}\': range_menu_outlet applies', 1),
]
TESTS = ["tests/test_build_seeds_keys.py", "tests/test_build_multistage.py"]


def run_tests():
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1", PATH="/opt/homebrew/bin:" + os.environ["PATH"])
    for p in REPO.rglob("__pycache__"):
        if ".git" not in p.parts:
            subprocess.run(["rm", "-rf", str(p)])
    for t in TESTS:
        r = subprocess.run(["uv", "run", "--no-project", "--with", "numpy", "python3", t],
                           cwd=REPO, env=env, capture_output=True, text=True)
        if r.returncode != 0:
            return r.returncode
    return 0


try:
    if run_tests() != 0:
        sys.exit("ABORT: the baseline is red")
    print("baseline green")
    survivors = []
    for label, old, new, n in M:
        if orig.count(old) != n:
            print(f"SKIP  {label}: anchor found {orig.count(old)} times, wanted {n}")
            survivors.append(label + " (anchor)")
            continue
        TARGET.write_text(orig.replace(old, new))
        rc = run_tests()
        print(("caught    " if rc != 0 else "SURVIVED  ") + label)
        if rc == 0:
            survivors.append(label)
finally:
    TARGET.write_text(orig)
    assert hashlib.sha256(TARGET.read_text().encode()).hexdigest() == sha, "restore failed"
    for p in REPO.rglob("__pycache__"):
        if ".git" not in p.parts:
            subprocess.run(["rm", "-rf", str(p)])
print("restored; survivors:", survivors or "none")
