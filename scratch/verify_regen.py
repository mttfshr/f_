import sys, json, subprocess
sys.path.insert(0, "build")
import layout

def strip(n, drop_label_varname=False):
    if isinstance(n, dict):
        out = {}
        for k, v in n.items():
            if k == "patching_rect": continue
            if drop_label_varname and k == "varname" and str(v).startswith("lbl_") and n.get("maxclass") == "comment": continue
            out[k] = strip(v, drop_label_varname)
        return out
    if isinstance(n, list): return [strip(x, drop_label_varname) for x in n]
    return n

for m in sys.argv[1:]:
    path = f"package/patchers/{m}.maxpat"
    new = json.load(open(path))                       # also = JSON validity
    old = json.loads(subprocess.check_output(["git", "show", f"HEAD:{path}"]))
    same = strip(new, True) == strip(old, True)
    p = new["patcher"]
    a = layout.audit(p["boxes"], p["lines"])
    print(f"{m:14} valid=YES only-rect+label-varname-changed={same}  "
          f"overlaps={len(a['overlaps'])} same_origin={len(a['same_origin'])} boxes={len(p['boxes'])}")
