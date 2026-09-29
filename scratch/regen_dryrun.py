"""T004 dry run (read-only w.r.t. package/patchers): which definitions regenerate to the
shipped patcher, ignoring only patching_rect?

Classifies each src/*/definition.py:
  REGEN-OK   : rebuilt patcher == shipped patcher once patching_rect is ignored
  DRIFTED    : differs in something other than patching_rect (do not regenerate)
  NO-SHIPPED : no package/patchers/<name>.maxpat
  BUILD-FAIL : build() raised
Note: build() writes package/javascript/<prefix>_toggle.js as a side effect for
panel_toggle modules; check `git status package/javascript` afterwards.
"""
import sys, glob, json, copy, traceback
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp


def strip_rects(node):
    """Deep copy with every patching_rect removed."""
    if isinstance(node, dict):
        return {k: strip_rects(v) for k, v in node.items() if k != "patching_rect"}
    if isinstance(node, list):
        return [strip_rects(x) for x in node]
    return node


def first_diff(a, b, path=""):
    if type(a) != type(b):
        return f"{path}: type {type(a).__name__} vs {type(b).__name__}"
    if isinstance(a, dict):
        for k in sorted(set(a) | set(b)):
            if k not in a:
                return f"{path}/{k}: missing in rebuilt"
            if k not in b:
                return f"{path}/{k}: missing in shipped"
            d = first_diff(a[k], b[k], f"{path}/{k}")
            if d:
                return d
        return None
    if isinstance(a, list):
        if len(a) != len(b):
            return f"{path}: len {len(a)} vs {len(b)}"
        for i, (x, y) in enumerate(zip(a, b)):
            d = first_diff(x, y, f"{path}[{i}]")
            if d:
                return d
        return None
    return None if a == b else f"{path}: {str(a)[:50]!r} vs {str(b)[:50]!r}"


results = []
for path in sorted(glob.glob(str(ROOT / "src" / "*" / "definition.py"))):
    mod = Path(path).parent.name
    try:
        defn = bp.load_definition(path)
        name = defn["name"]
        rebuilt = json.loads(json.dumps(bp.build(defn)))
    except Exception as e:
        results.append((mod, "BUILD-FAIL", f"{type(e).__name__}: {str(e)[:60]}"))
        continue
    shipped_path = ROOT / "package" / "patchers" / f"{name}.maxpat"
    if not shipped_path.exists():
        results.append((name, "NO-SHIPPED", ""))
        continue
    shipped = json.load(open(shipped_path))
    d = first_diff(strip_rects(rebuilt), strip_rects(shipped))
    results.append((name, "REGEN-OK" if d is None else "DRIFTED", d or ""))

for name, status, note in results:
    print(f"{name:22} {status:11} {note}")
print()
for s in ("REGEN-OK", "DRIFTED", "NO-SHIPPED", "BUILD-FAIL"):
    print(f"{s:11} {sum(1 for r in results if r[1] == s)}")
