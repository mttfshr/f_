import sys, json
sys.path.insert(0, "build")
import build_patcher as bp

def strip(n):
    if isinstance(n, dict): return {k: strip(v) for k, v in n.items() if k != "patching_rect"}
    if isinstance(n, list): return [strip(x) for x in n]
    return n

for name in ("f_caustic", "f_stipple", "f_vf_glow", "f_vf_prism", "f_vf_streak", "f_ngon"):
    d = bp.load_definition(f"src/{name}/definition.py")
    new = {b["box"]["id"]: strip(b["box"]) for b in bp.build(d)["patcher"]["boxes"]}
    old = {b["box"]["id"]: strip(b["box"]) for b in json.load(open(f"package/patchers/{name}.maxpat"))["patcher"]["boxes"]}
    for i in sorted(set(new) & set(old)):
        for k in sorted(set(new[i]) | set(old[i])):
            if new[i].get(k) != old[i].get(k):
                print(f"{name:12} {i:9} {new[i].get('maxclass',''):8} {k}: shipped={str(old[i].get(k))[:38]!r} rebuilt={str(new[i].get(k))[:38]!r}")
    print(f"{name:12} regen writes: {len(new)} boxes, shipped has {len(old)}")
