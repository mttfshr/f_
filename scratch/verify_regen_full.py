import sys, json, subprocess
sys.path.insert(0, "build")
import layout

def flat(n, path=""):
    """leaf path -> value, patching_rect excluded."""
    out = {}
    if isinstance(n, dict):
        for k, v in n.items():
            if k == "patching_rect": continue
            out.update(flat(v, f"{path}/{k}"))
    elif isinstance(n, list):
        for i, v in enumerate(n): out.update(flat(v, f"{path}[{i}]"))
    else:
        out[path] = n
    return out

for m in sys.argv[1:]:
    path = f"package/patchers/{m}.maxpat"
    new = json.load(open(path))
    old = json.loads(subprocess.check_output(["git", "show", f"HEAD:{path}"]))
    fn, fo = flat(new), flat(old)
    diffs = sorted(k for k in set(fn) | set(fo) if fn.get(k, "<absent>") != fo.get(k, "<absent>"))
    p = new["patcher"]
    a = layout.audit(p["boxes"], p["lines"])
    print(f"\n=== {m}: valid JSON, {len(diffs)} non-rect leaf differences, overlaps={len(a['overlaps'])} same_origin={len(a['same_origin'])}")
    lbl = [k for k in diffs if k.endswith("/varname") and str(fn.get(k)).startswith("lbl_")]
    other = [k for k in diffs if k not in lbl]
    print(f"    label varnames added: {len(lbl)}")
    for k in other[:30]:
        print(f"    {k}: shipped={str(fo.get(k, '<absent>'))[:40]!r} new={str(fn.get(k, '<absent>'))[:40]!r}")
    if len(other) > 30: print(f"    ... +{len(other)-30} more")
