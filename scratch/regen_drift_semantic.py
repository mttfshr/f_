"""Semantic drift report: rebuilt-from-definition vs shipped patcher, matching boxes by identity
(maxclass + text/comment + parameter name + attr + varname) instead of by id, so renumbered ids
don't masquerade as changes. Read-only. patching_rect ignored."""
import sys, glob, json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp

SKIP = {"f_caustic", "f_stipple", "f_vf_glow", "f_vf_prism", "f_vf_streak", "f_ngon"}


def longname(b):
    try:
        return b["saved_attribute_attributes"]["valueof"]["parameter_longname"]
    except Exception:
        return None


def sig(b):
    label = b.get("text") or b.get("comment") or ""
    return (b.get("maxclass", "?"), str(label)[:40], longname(b) or b.get("attr") or "")


def fmt(s):
    mc, label, nm = s
    return f"{mc}:{label or nm}" if label else f"{mc}:{nm}"


def gen_code(b):
    p = b.get("patcher")
    if not p:
        return None
    return [x["box"].get("code") for x in p.get("boxes", []) if x["box"].get("maxclass") == "codebox"]


for path in sorted(glob.glob(str(ROOT / "src" / "*" / "definition.py"))):
    try:
        d = bp.load_definition(path)
        rebuilt = json.loads(json.dumps(bp.build(d)))["patcher"]
    except Exception:
        continue
    name = d["name"]
    if name in SKIP:
        continue
    shipped = json.load(open(ROOT / "package" / "patchers" / f"{name}.maxpat"))["patcher"]
    rb = [b["box"] for b in rebuilt["boxes"]]
    sb = [b["box"] for b in shipped["boxes"]]
    rc, sc = Counter(map(sig, rb)), Counter(map(sig, sb))
    only_r = list((rc - sc).elements())
    only_s = list((sc - rc).elements())

    # UI position drift among boxes present in both (unique signature only)
    rmap = {sig(b): b for b in rb if rc[sig(b)] == 1}
    smap = {sig(b): b for b in sb if sc[sig(b)] == 1}
    moved = [k for k in rmap if k in smap and rmap[k].get("presentation_rect") != smap[k].get("presentation_rect")
             and (rmap[k].get("presentation") or smap[k].get("presentation"))]

    # pix boxes: inlet/outlet counts + codebox text
    rpix = [b for b in rb if str(b.get("text", "")).startswith("jit.gl.pix")]
    spix = [b for b in sb if str(b.get("text", "")).startswith("jit.gl.pix")]
    io = []
    code_diff = 0
    for rp in rpix:
        m = [sp for sp in spix if sp.get("text") == rp.get("text")]
        if not m:
            io.append(f"pix text differs ({rp.get('text')[:40]})")
            continue
        sp = m[0]
        if (rp["numinlets"], rp["numoutlets"]) != (sp["numinlets"], sp["numoutlets"]):
            io.append(f"pix in/out rebuilt {rp['numinlets']}/{rp['numoutlets']} vs shipped {sp['numinlets']}/{sp['numoutlets']}")
        if gen_code(rp) != gen_code(sp):
            code_diff += 1
    print(f"\n=== {name}   (boxes rebuilt {len(rb)} / shipped {len(sb)}; lines {len(rebuilt['lines'])} / {len(shipped['lines'])})")
    if only_r:
        print("  only in definition-build :", ", ".join(fmt(s) for s in only_r[:7]) + (f" (+{len(only_r)-7} more)" if len(only_r) > 7 else ""))
    if only_s:
        print("  only in shipped patch    :", ", ".join(fmt(s) for s in only_s[:7]) + (f" (+{len(only_s)-7} more)" if len(only_s) > 7 else ""))
    if moved:
        print(f"  presentation moved       : {len(moved)} matched boxes at a different presentation_rect")
    for x in io:
        print("  " + x)
    if code_diff:
        print(f"  codebox text differs     : {code_diff} pix node(s)")
    if not (only_r or only_s or moved or io or code_diff):
        print("  (no semantic difference found by this method)")
