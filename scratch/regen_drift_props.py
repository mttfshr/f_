"""Property-level drift inside boxes matched by identity (complements regen_drift_semantic.py)."""
import sys, json
from collections import Counter
from pathlib import Path
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp

def ln(b):
    try: return b["saved_attribute_attributes"]["valueof"]["parameter_longname"]
    except Exception: return None
def sig(b): return (b.get("maxclass", "?"), str(b.get("text") or b.get("comment") or "")[:40], ln(b) or b.get("attr") or "")

for name in sys.argv[1:]:
    d = bp.load_definition(f"src/{name}/definition.py")
    rb = [b["box"] for b in json.loads(json.dumps(bp.build(d)))["patcher"]["boxes"]]
    sb = [b["box"] for b in json.load(open(ROOT / f"package/patchers/{name}.maxpat"))["patcher"]["boxes"]]
    rc, sc = Counter(map(sig, rb)), Counter(map(sig, sb))
    rm = {sig(b): b for b in rb if rc[sig(b)] == 1}
    sm = {sig(b): b for b in sb if sc[sig(b)] == 1}
    tally = Counter(); ex = {}
    for k in rm:
        if k not in sm: continue
        for key in set(rm[k]) | set(sm[k]):
            if key in ("patching_rect", "id", "patcher"): continue
            a, b = rm[k].get(key), sm[k].get(key)
            if a != b:
                tally[(k[0], key)] += 1
                ex.setdefault((k[0], key), (str(a)[:34], str(b)[:34]))
    print(f"\n=== {name}")
    for (mc, key), n in tally.most_common(9):
        a, b = ex[(mc, key)]
        print(f"  {n:2}x {mc}.{key}: rebuilt={a!r} shipped={b!r}")
    if not tally: print("  (none)")
