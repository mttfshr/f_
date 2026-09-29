"""Read-only: per-definition param counts and the widest edit-view box a param column must hold."""
import sys, glob, pathlib
sys.path.insert(0, "build")
import build_patcher as bp

rows = []
for path in sorted(glob.glob("src/*/definition.py")):
    try:
        d = bp.load_definition(path)
    except Exception as e:
        rows.append((path.split("/")[1], "load-fail", str(e)[:40])); continue
    ui = [p for p in d.get("params", []) if p["type"] in ("float", "int", "menu", "text_button")]
    if not ui:
        rows.append((d.get("name", path), 0, 0, 0)); continue
    longest = max(len(p["name"]) for p in ui)
    attrui_w = max(100.0, longest * 7.0 + 80.0)
    rows.append((d["name"], len(ui), longest, attrui_w))
print(f"{'module':22} {'n_ui':>4} {'longest':>7} {'attrui_w':>8}")
for r in rows:
    print(f"{r[0]:22} {r[1]!s:>4} {r[2]!s:>7} {r[3]!s:>8}")
ws = [r[3] for r in rows if isinstance(r[3], float)]
ns = [r[1] for r in rows if isinstance(r[1], int)]
print("max attrui_w:", max(ws), " max n_ui:", max(ns))
