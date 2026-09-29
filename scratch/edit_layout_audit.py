"""Read-only audit: how messy is the edit-view (patching_rect) layout of built patchers?
Reports box count, overlapping pairs, and boxes sharing an identical origin."""
import json, sys, itertools, collections, pathlib

def rect(b):
    r = b.get("patching_rect")
    return r if r and len(r) == 4 else None

def overlap(a, b):
    ax, ay, aw, ah = a; bx, by, bw, bh = b
    return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah

for path in sys.argv[1:]:
    d = json.load(open(path))
    boxes = [x["box"] for x in d["patcher"]["boxes"]]
    rs = [(b.get("id"), b.get("maxclass"), b.get("text", "")[:24], rect(b)) for b in boxes if rect(b)]
    pairs = [(p, q) for p, q in itertools.combinations(rs, 2) if overlap(p[3], q[3])]
    origins = collections.Counter(tuple(r[3][:2]) for r in rs)
    dup = sum(c - 1 for c in origins.values() if c > 1)
    pres = sum(1 for b in boxes if b.get("presentation"))
    print(f"{pathlib.Path(path).name:28} boxes={len(boxes):3} presentation={pres:3} "
          f"overlap_pairs={len(pairs):4} identical_origin_dupes={dup:3}")
