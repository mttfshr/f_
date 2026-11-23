"""Inventory every user-facing param of every non-paused module from src/<m>/definition.py.

Writes inventory.json next to this file: {module: [{name, type, widget, min, max, default, label, ui}]}.
Offline and read-only apart from that one file. Run: build/py.sh .specify/ui_primary_params/inventory.py
`widget` is the explicit key if present, else the archetype default: float/int -> "dial", menu/text_button/etc. as typed.
Definitions are exec'd, not imported; a definition that fails is listed under "_errors", not skipped silently.
"""
import json, pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
PAUSED = {p.name for p in (ROOT / ".specify" / "paused").iterdir() if p.is_dir()}
SKIP_TYPES = {"internal", "bypass", "raw_ui"}   # not controls a user sets

out, errors = {}, {}
for d in sorted((ROOT / "src").glob("*/definition.py")):
    mod = d.parent.name
    if mod in PAUSED:
        continue
    ns = {"__file__": str(d), "__name__": "definition"}
    try:
        exec(compile(d.read_text(), str(d), "exec"), ns)
        params = ns["patcher"].get("params", [])
    except Exception as e:                      # noqa: BLE001 - record and move on
        errors[mod] = repr(e)
        continue
    rows = []
    for p in params:
        t = p.get("type")
        if t in SKIP_TYPES:
            continue
        rows.append({
            "name": p.get("name"), "type": t,
            "widget": p.get("widget") or ("dial" if t in ("float", "int") else t),
            "min": p.get("min"), "max": p.get("max"), "default": p.get("default"),
            "label": p.get("label"), "ui": p.get("ui", True),
        })
    out[mod] = rows

out["_errors"] = errors
(pathlib.Path(__file__).parent / "inventory.json").write_text(json.dumps(out, indent=1))
mods = {k: v for k, v in out.items() if k != "_errors"}
print(f"{len(mods)} modules, {sum(len(v) for v in mods.values())} params, {len(errors)} errors")
for k, v in sorted(mods.items(), key=lambda kv: -len(kv[1]))[:12]:
    print(f"  {k}: {len(v)}")
for k, e in errors.items():
    print("ERROR", k, e)
