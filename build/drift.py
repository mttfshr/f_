#!/usr/bin/env python3
"""
drift.py -- does a module's shipped patcher still equal what its definition
builds?  (definition.py is the source of truth; a hand edit in Max has to be
written back into it.  .specify/build_layout/ and HANDOFF 2026-10-04.)

Read-only: builds in memory (build_patcher.build is pure), never writes.

    build/py.sh build/drift.py                 # one line per shipped patcher
    build/py.sh build/drift.py -v f_vf_warp    # with examples of each difference
    build/py.sh build/drift.py --json          # machine-readable (tests use this)

How a module is built: its own src/<name>/build_*.py if it has one (the four
script-built modules; the script's build() returns the patcher dict), else
build_patcher.build(src/<name>/definition.py).

How it is compared.  Boxes are matched by identity, not id (ids renumber):
(maxclass, text-or-comment[:40], parameter longname or attr).  patching_rect is
ignored throughout (edit-view layout is regenerated, never hand-kept).
Counts reported per module:

  boxes_def_only / boxes_patch_only   box present on one side only
  props           (box, key) differences among matched boxes, e.g. a dial's
                  range or default changed in Max; presentation_rect excluded
  layout          matched boxes whose presentation_rect differs
  pix_io          a pix with different in/out counts, or no matching pix text
  code            pix whose gen codebox text differs
  lines_def_only / lines_patch_only
                  cords between matched boxes present on one side only

Limit: a box whose identity is not unique within its patcher is compared only
in the box counts; cords touching such a box are not compared.
"""
import importlib.util
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp  # noqa: E402

PATCHERS = ROOT / "package" / "patchers"
CATEGORIES = ["boxes_def_only", "boxes_patch_only", "props", "layout", "pix_io", "code",
              "lines_def_only", "lines_patch_only"]
IGNORED_PROPS = {"patching_rect", "id", "patcher", "presentation_rect"}
RECT_TOL = 1e-3

# "Equal modulo Max".  Evidence-based (2026-10-04 survey of 745 property
# differences); anything not listed here counts as real drift.
#  - derived: Max recomputes a newobj's ports from its text on load/save, so the
#    builder's placeholders never match.  (pix port counts are checked separately
#    as pix_io; a route's argument list is its `text`, which IS compared.)
#  - state: values Max writes at save time from runtime state, not structure.
#  - defaults: keys Max writes explicitly with their default value; a missing
#    key and the default are the same.
DERIVED_PROPS = {("newobj", "numinlets"), ("newobj", "numoutlets"), ("newobj", "outlettype")}
STATE_PROPS = {("newobj", "restore"), ("newobj", "save")}
MAX_DEFAULTS = {("attrui", "style"): "", ("attrui", "parameter_enable"): 0,
                ("jsui", "parameter_enable"): 0}


def _longname(b):
    try:
        return b["saved_attribute_attributes"]["valueof"]["parameter_longname"]
    except Exception:
        return None


def signature(b):
    label = b.get("text") or b.get("comment") or ""
    return (b.get("maxclass", "?"), str(label)[:40], _longname(b) or b.get("attr") or "")


def _fmt(sig):
    mc, label, nm = sig
    return f"{mc}:{label or nm}"


def _gen_code(b):
    p = b.get("patcher")
    return None if not p else [x["box"].get("code") for x in p.get("boxes", [])
                               if x["box"].get("maxclass") == "codebox"]


def _rect_differs(a, b):
    if not a or not b or len(a) != len(b):
        return a != b
    return any(abs(x - y) > RECT_TOL for x, y in zip(a, b))


def compare(rebuilt, shipped):
    """Both are the inner `patcher` dicts. -> (counts, examples)."""
    rb = [b["box"] for b in rebuilt["boxes"]]
    sb = [b["box"] for b in shipped["boxes"]]
    rc, sc = Counter(map(signature, rb)), Counter(map(signature, sb))
    counts = dict.fromkeys(CATEGORIES, 0)
    ex = {k: [] for k in CATEGORIES}

    def note(cat, text, n=1):
        counts[cat] += n
        if len(ex[cat]) < 6:
            ex[cat].append(text)

    for s in (rc - sc).elements():
        note("boxes_def_only", _fmt(s))
    for s in (sc - rc).elements():
        note("boxes_patch_only", _fmt(s))

    rmap = {signature(b): b for b in rb if rc[signature(b)] == 1}
    smap = {signature(b): b for b in sb if sc[signature(b)] == 1}
    for sig, r in rmap.items():
        s = smap.get(sig)
        if not s:
            continue
        mc = sig[0]
        for key in sorted((set(r) | set(s)) - IGNORED_PROPS):
            if (mc, key) in DERIVED_PROPS or (mc, key) in STATE_PROPS:
                continue
            default = MAX_DEFAULTS.get((mc, key))
            rv, sv = r.get(key, default), s.get(key, default)
            if rv != sv:
                note("props", f"{_fmt(sig)}.{key}: built={str(rv)[:30]!r} "
                              f"shipped={str(sv)[:30]!r}")
        if (r.get("presentation") or s.get("presentation")) and \
                _rect_differs(r.get("presentation_rect"), s.get("presentation_rect")):
            note("layout", f"{_fmt(sig)}: built={r.get('presentation_rect')} "
                           f"shipped={s.get('presentation_rect')}")

    rpix = [b for b in rb if str(b.get("text", "")).startswith("jit.gl.pix")]
    spix = [b for b in sb if str(b.get("text", "")).startswith("jit.gl.pix")]
    for rp in rpix:
        m = [sp for sp in spix if sp.get("text") == rp.get("text")]
        if not m:
            note("pix_io", f"no shipped pix with text {rp.get('text', '')[:40]!r}")
            continue
        if (rp["numinlets"], rp["numoutlets"]) != (m[0]["numinlets"], m[0]["numoutlets"]):
            note("pix_io", f"{rp['text'][:30]}: in/out {rp['numinlets']}/{rp['numoutlets']} "
                           f"vs {m[0]['numinlets']}/{m[0]['numoutlets']}")
        if _gen_code(rp) != _gen_code(m[0]):
            note("code", rp["text"][:50])

    def edges(patcher, boxes, count_of):
        sig_of = {b["id"]: signature(b) for b in boxes if count_of[signature(b)] == 1}
        out = set()
        for line in patcher.get("lines", []):
            (s, so), (d, di) = line["patchline"]["source"], line["patchline"]["destination"]
            if s in sig_of and d in sig_of:
                out.add((sig_of[s], so, sig_of[d], di))
        return out

    re_, se_ = edges(rebuilt, rb, rc), edges(shipped, sb, sc)
    fmt_e = lambda e: f"{_fmt(e[0])}[{e[1]}] -> {_fmt(e[2])}[{e[3]}]"
    for e in sorted(re_ - se_):
        if e[0] in smap and e[2] in smap:
            note("lines_def_only", fmt_e(e))
    for e in sorted(se_ - re_):
        if e[0] in rmap and e[2] in rmap:
            note("lines_patch_only", fmt_e(e))
    return counts, ex


def definition_path(name):
    return ROOT / "src" / name / "definition.py"


def builder_script(name):
    scripts = sorted((ROOT / "src" / name).glob("build_*.py"))
    return scripts[0] if len(scripts) == 1 else None


def build_module(name):
    """-> (patcher_json_dict, how).  how: 'script' | 'definition'."""
    script = builder_script(name)
    if script:
        spec = importlib.util.spec_from_file_location(f"_drift_{name}", script)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return json.loads(json.dumps(mod.build())), "script"
    defn = bp.load_definition(definition_path(name))
    return json.loads(json.dumps(bp.build(defn))), "definition"


def shipped_names():
    return sorted(p.stem for p in PATCHERS.glob("f_*.maxpat"))


def report(name):
    """{'module', 'status', 'how', 'counts', 'examples'}.
    status: ok | drift | no_definition | build_error"""
    if not definition_path(name).exists():
        return {"module": name, "status": "no_definition", "how": None, "counts": {}, "examples": {}}
    try:
        built, how = build_module(name)
    except Exception as e:                                   # report it, don't hide it
        return {"module": name, "status": "build_error", "how": None, "counts": {},
                "examples": {"error": [f"{type(e).__name__}: {e}"[:200]]}}
    shipped = json.load(open(PATCHERS / f"{name}.maxpat"))["patcher"]
    counts, ex = compare(built["patcher"], shipped)
    status = "ok" if not any(counts.values()) else "drift"
    return {"module": name, "status": status, "how": how, "counts": counts, "examples": ex}


def main(argv):
    verbose = "-v" in argv
    as_json = "--json" in argv
    names = [a for a in argv if not a.startswith("-")] or shipped_names()
    reports = [report(n) for n in names]
    if as_json:
        print(json.dumps(reports, indent=1))
        return 0
    for r in reports:
        if r["status"] == "ok":
            line = "ok"
        elif r["status"] == "drift":
            line = "drift  " + " ".join(f"{k}={v}" for k, v in r["counts"].items() if v)
        else:
            line = r["status"]
        print(f"{r['module']:26s} {('[' + r['how'] + ']') if r['how'] else '':13s} {line}")
        if verbose:
            for cat, items in r["examples"].items():
                for it in items:
                    print(f"      {cat}: {it}")
    drifted = [r for r in reports if r["status"] != "ok"]
    print(f"\n{len(reports) - len(drifted)} of {len(reports)} reproduce exactly")
    return 1 if drifted else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
