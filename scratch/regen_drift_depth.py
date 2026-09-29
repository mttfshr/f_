"""T004 drift depth: per definition, how far does a rebuild differ from the shipped patcher?
Boxes matched by id; patching_rect ignored. Read-only w.r.t. package/patchers."""
import sys, glob, json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp


def strip(node):
    if isinstance(node, dict):
        return {k: strip(v) for k, v in node.items() if k != "patching_rect"}
    if isinstance(node, list):
        return [strip(x) for x in node]
    return node


def boxes_by_id(p):
    return {b["box"]["id"]: strip(b["box"]) for b in p["patcher"]["boxes"]}


def line_set(p):
    out = set()
    for l in p["patcher"]["lines"]:
        pl = l["patchline"]
        out.add((pl["source"][0], pl["source"][1], pl["destination"][0], pl["destination"][1]))
    return out


print(f"{'module':20} {'boxes+':>6} {'boxes-':>6} {'changed':>7} {'lines+':>6} {'lines-':>6}   changed-key sample")
for path in sorted(glob.glob(str(ROOT / "src" / "*" / "definition.py"))):
    try:
        defn = bp.load_definition(path)
        rebuilt = json.loads(json.dumps(bp.build(defn)))
    except Exception:
        continue
    sp = ROOT / "package" / "patchers" / f"{defn['name']}.maxpat"
    if not sp.exists():
        continue
    shipped = json.load(open(sp))
    rb, sb = boxes_by_id(rebuilt), boxes_by_id(shipped)
    add = set(rb) - set(sb)
    rem = set(sb) - set(rb)
    changed = [i for i in set(rb) & set(sb) if rb[i] != sb[i]]
    keys = set()
    for i in changed:
        for k in set(rb[i]) | set(sb[i]):
            if rb[i].get(k) != sb[i].get(k):
                keys.add(k)
    rl, sl = line_set(rebuilt), line_set(shipped)
    print(f"{defn['name']:20} {len(add):>6} {len(rem):>6} {len(changed):>7} {len(rl - sl):>6} {len(sl - rl):>6}   {','.join(sorted(keys))[:60]}")
