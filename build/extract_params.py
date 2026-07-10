#!/opt/homebrew/bin/python3.13
"""
extract_params.py — extract param metadata from f_ patchers for helpfile generation.

Priority: .specify/<name>/definition.py > patcher JSON extraction

Usage:
    python3 build/extract_params.py                  # all patchers missing helpfiles
    python3 build/extract_params.py f_grain          # single patcher by name
    python3 build/extract_params.py --all            # all patchers, incl. existing helpfiles
    python3 build/extract_params.py --dry-run        # print JSON, don't write state file

Output: build/helpfile_queue.json
"""

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent
PATCHERS_DIR = REPO_ROOT / "package" / "patchers"
HELP_DIR = REPO_ROOT / "package" / "help"
DOCS_DIR = REPO_ROOT / "docs"
SPECIFY_DIR = REPO_ROOT / ".specify"
STATE_FILE = REPO_ROOT / "build" / "helpfile_queue.json"


# ---------------------------------------------------------------------------
# Source A: definition.py
# ---------------------------------------------------------------------------

def load_definition(module_name: str):
    """Import .specify/<module_name>/definition.py and return the patcher dict."""
    def_path = SPECIFY_DIR / module_name / "definition.py"
    if not def_path.exists():
        return None
    namespace = {}
    try:
        exec(def_path.read_text(), namespace)
    except Exception as e:
        print(f"  WARNING: error executing {def_path}: {e}", file=sys.stderr)
        return None
    return namespace.get("patcher")


def params_from_definition(defn: dict) -> list[dict]:
    """
    Convert definition.py params list to extractor output format.
    Skips params with type 'internal' — they are not externally addressable.
    bypass is kept but flagged as bool.
    """
    params = []
    for p in defn.get("params", []):
        ptype = p.get("type", "float")
        if ptype == "internal":
            continue

        if ptype == "bypass":
            params.append({
                "name": "bypass",
                "hint": "Bypass",
                "range": "[0 / 1]",
                "type": "bool",
            })
        elif ptype == "umenu":
            items = p.get("items", [])
            params.append({
                "name": p["name"],
                "hint": p.get("hint", f"Options: {', '.join(items)}"),
                "range": "[" + " / ".join(items) + "]",
                "type": "enum",
            })
        else:
            mmin = p.get("min", 0.0)
            mmax = p.get("max", 1.0)
            params.append({
                "name": p["name"],
                "hint": p.get("hint", ""),
                "range": f"[{mmin} \u2013 {mmax}]",
                "type": ptype,
            })
    return params


# ---------------------------------------------------------------------------
# Source B: patcher JSON fallback
# ---------------------------------------------------------------------------

def find_route_object(boxes: list) -> list[str]:
    for box_wrapper in boxes:
        box = box_wrapper.get("box", {})
        if box.get("maxclass") == "newobj":
            text = box.get("text", "")
            if text.startswith("route "):
                return text[len("route "):].split()
    return []


def extract_param_metadata(boxes: list) -> dict:
    params = {}
    for box_wrapper in boxes:
        box = box_wrapper.get("box", {})
        maxclass = box.get("maxclass", "")
        varname = box.get("varname", "")
        if not varname:
            continue

        if maxclass == "jsui" and varname == "bypass":
            params["bypass"] = {
                "name": "bypass", "type": "bool",
                "mmin": 0, "mmax": 1, "hint": "Bypass",
            }
        elif maxclass in ("live.dial", "live.numbox"):
            saved = box.get("saved_attribute_attributes", {})
            valueof = saved.get("valueof", {})
            mmin = valueof.get("parameter_mmin", 0.0)
            mmax = valueof.get("parameter_mmax", 1.0)
            param_type = valueof.get("parameter_type", 0)
            params[varname] = {
                "name": varname,
                "type": "int" if param_type == 1 else "float",
                "mmin": mmin, "mmax": mmax,
                "hint": box.get("hint", ""),
            }
        elif maxclass == "umenu":
            items_raw = box.get("items", [])
            items = [i for i in items_raw if i != ","]
            saved = box.get("saved_attribute_attributes", {})
            valueof = saved.get("valueof", {})
            longname = valueof.get("parameter_longname", varname)
            params[varname] = {
                "name": longname, "type": "enum",
                "items": items,
                "hint": f"Options: {', '.join(items)}",
            }
    return params


def format_range(meta: dict) -> str:
    if meta["type"] == "bool":
        return "[0 / 1]"
    if meta["type"] == "enum":
        return "[" + " / ".join(meta["items"]) + "]"
    mmin = meta.get("mmin", 0.0)
    mmax = meta.get("mmax", 1.0)
    return f"[{mmin} \u2013 {mmax}]"


def infer_module_type(boxes: list) -> str:
    for box_wrapper in boxes:
        if box_wrapper.get("box", {}).get("maxclass") == "inlet":
            return "processor"
    return "generator"


def params_from_patcher_json(path: Path):
    """Returns (params, module_type). Falls back gracefully on parse errors."""
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, OSError) as e:
        print(f"  ERROR reading {path.name}: {e}", file=sys.stderr)
        return [], "processor"

    patcher = data.get("patcher", {})
    boxes = patcher.get("boxes", [])
    route_params = find_route_object(boxes)
    all_meta = extract_param_metadata(boxes)
    module_type = infer_module_type(boxes)

    params = []
    for name in route_params:
        meta = all_meta.get(name)
        if meta:
            params.append({
                "name": name,
                "hint": meta.get("hint", ""),
                "range": format_range(meta),
                "type": meta.get("type", "float"),
            })
        else:
            params.append({
                "name": name, "hint": "",
                "range": "[unknown]", "type": "float",
            })
    return params, module_type


# ---------------------------------------------------------------------------
# Main extraction
# ---------------------------------------------------------------------------

def extract_patcher(path: Path):
    module_name = path.stem
    short_name = module_name.removeprefix("f_")

    # Try definition.py first
    defn = load_definition(module_name)
    if defn:
        params = params_from_definition(defn)
        module_type = "generator" if defn.get("archetype") == "source" else "processor"
        source = "definition.py"
    else:
        params, module_type = params_from_patcher_json(path)
        source = "patcher JSON"

    docs_path = DOCS_DIR / f"{module_name}.md"
    has_docs = docs_path.exists()

    return {
        "module_name": module_name,
        "short_name": short_name,
        "module_type": module_type,
        "source": source,
        "params": params,
        "has_docs": has_docs,
        "docs_path": str(docs_path) if has_docs else None,
        "helpfile_path": str(HELP_DIR / f"{module_name}.maxhelp"),
        "status": "pending",
    }


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    include_all = "--all" in args
    args = [a for a in args if not a.startswith("--")]

    patchers = sorted(PATCHERS_DIR.glob("f_*.maxpat"))

    if args:
        requested = set(a if a.startswith("f_") else f"f_{a}" for a in args)
        patchers = [p for p in patchers if p.stem in requested]
        missing = requested - {p.stem for p in patchers}
        if missing:
            print(f"WARNING: patchers not found: {missing}", file=sys.stderr)

    if not include_all and not args:
        patchers = [p for p in patchers if not (HELP_DIR / f"{p.stem}.maxhelp").exists()]

    if not patchers:
        print("No patchers to process.")
        return

    print(f"Extracting {len(patchers)} patcher(s)...\n")

    queue = []
    for path in patchers:
        print(f"  {path.stem}...")
        result = extract_patcher(path)
        if result:
            queue.append(result)
            print(f"    {len(result['params'])} params | type={result['module_type']} | source={result['source']} | docs={result['has_docs']}")

    print(f"\n{len(queue)} patcher(s) ready.")

    if dry_run:
        print("\n--- DRY RUN OUTPUT ---")
        print(json.dumps(queue, indent=2))
    else:
        with open(STATE_FILE, "w") as f:
            json.dump(queue, f, indent=2)
        print(f"Queue written to {STATE_FILE}")


if __name__ == "__main__":
    main()
