import sys
sys.path.insert(0, "build")
import build_patcher as bp, layout
d = bp.load_definition("src/f_lens/definition.py")
dbg = {}
res = bp.build(d, debug=dbg)
p = res["patcher"]; roles = dbg["roles"]
a = layout.audit(p["boxes"], p["lines"], roles)
known = lambda i: i in roles
for x, y in a["overlaps"]:
    print("overlap", x, known(x), y, known(y))
print("same_origin", a["same_origin"], [[known(i) for i in g] for g in a["same_origin"]])
print("upward", [(x, known(x), y, known(y)) for x, y in a["upward"]])
