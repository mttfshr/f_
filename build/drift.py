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
  boxes_renamed   an unmatched definition box and an unmatched patch box that are
                  the same element under a different identity (a label edited in
                  Max, a pix @name, a renamed parameter): paired and reported once
                  as `definition -> patch`.  Pairing is deliberately conservative
                  (see pair_renamed); an ambiguous leftover stays def-only/patch-only.
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
import copy
import importlib.util
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp  # noqa: E402

PATCHERS = ROOT / "package" / "patchers"
CATEGORIES = ["boxes_def_only", "boxes_patch_only", "boxes_renamed", "props", "layout", "pix_io", "code",
              "lines_def_only", "lines_patch_only"]
IGNORED_PROPS = {"patching_rect", "id", "patcher", "presentation_rect"}
RECT_TOL = 1e-3
RENAME_TOL = 8.0                          # px: a renamed element stays this close to its old rect
RENAME_SKIP_PROPS = {"text", "comment"}   # the identity that changed; not drift on top of the rename

# "Equal modulo Max".  Evidence-based (2026-10-04 survey of 745 property
# differences); anything not listed here counts as real drift.
#  - derived: Max recomputes a newobj's ports from its text on load/save, so the
#    builder's placeholders never match.  (pix port counts are checked separately
#    as pix_io; a route's argument list is its `text`, which IS compared.)
#  - state: values Max writes at save time from runtime state, not structure.
#  - defaults: keys Max writes explicitly with their default value; a missing
#    key and the default are the same.
DERIVED_PROPS = {("newobj", "numinlets"), ("newobj", "numoutlets"), ("newobj", "outlettype"),
                 ("inlet", "index"), ("outlet", "index")}
STATE_PROPS = {("newobj", "restore"), ("newobj", "save"), ("newobj", "restore_extra")}
MAX_DEFAULTS = {("attrui", "style"): "", ("attrui", "parameter_enable"): 0,
                ("jsui", "parameter_enable"): 0, ("live.text", "fontsize"): 9.5}
# Explicit values nested inside a property that Max drops when they equal the default.
# (maxclass, key, ..., leaf): default.  A missing leaf and the default are the same.
NESTED_DEFAULTS = {
    ("live.dial", "saved_attribute_attributes", "valueof", "parameter_mmin"): 0.0,
    ("live.dial", "saved_attribute_attributes", "valueof", "parameter_mmax"): 127.0,
    ("live.numbox", "saved_attribute_attributes", "valueof", "parameter_mmin"): 0.0,
}
# Max re-fits a comment's size to its text on load/save; only its position is structure.
RECT_POSITION_ONLY = {"comment"}

# Evidence, build_cleanup/T008, 2026-10-05: a MAX ROUND-TRIP.  f_vf_chroma and
# f_channel_grader were built from their definitions, opened in Max 9.2.0 and saved without
# an edit; the saved file was diffed against the built one.  (The 11 modules that "reproduce
# exactly" are NOT evidence: they carry no Max-written ports or save state, so Max never
# re-saved them.)  What Max changed became the lists above:
#   index         inlet/outlet `index` rewritten to 0 on every port; ports are ordered by x.
#   mmin / mmax   a dial's parameter_mmin 0.0 and parameter_mmax 127.0 dropped (live.dial's
#                 default range is 0-127; every other max, 1.0 / 2.0 / 20.0 / 100.0, was kept),
#                 and a numbox's parameter_mmin 0.0.  (Second round-trip: f_chladni,
#                 f_caustic, f_vf_advect.)
#   unitstyle     a float-type numbox written with parameter_unitstyle 0 (Int) comes back as
#                 1 (Float).  Every numbox in a Max-saved module has 1; the 0s are on
#                 builder-made, never-saved ones.  See _canon.
#   comment size  60x18 -> 61x21 (autofit to the text); x and y untouched.
#   restore_extra written on autopattr (state).     fontsize  live.text 9.5 dropped.
# What Max did NOT change, so a difference on any of these is a real edit or a stale
# definition, and stays drift (tests/test_drift.py pins each one):
#   the autopattr `varname` (builder `x_autopattr`; shipped `u905020188`), a dial's
#   `param_connect`, a comment's `varname`.
# Seen but deliberately not encoded: Max also writes live.text theme colours
# (activebgcolor, bgoncolor, ...) explicitly.  They equal the theme default, but a manual
# recolour looks the same and the theme differs between Max builds, so they stay drift.
# Repeat the round-trip on a new Max build before trusting these lists there (build_cleanup/T030).


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


def _pairable(r, s):
    """Could unmatched definition box r and unmatched patch box s be one element
    under a different identity?  Same maxclass, and: for a newobj the same first
    token (`route`, `jit.gl.pix`); for anything else both on the presentation
    panel with rects within RENAME_TOL of each other."""
    mc = r.get("maxclass")
    if mc != s.get("maxclass"):
        return False
    if mc == "newobj":
        rt, st = str(r.get("text", "")).split(), str(s.get("text", "")).split()
        return bool(rt) and bool(st) and rt[0] == st[0]
    ra, sa = r.get("presentation_rect"), s.get("presentation_rect")
    if not (r.get("presentation") and s.get("presentation") and ra and sa and len(ra) == len(sa)):
        return False
    return max(abs(x - y) for x, y in zip(ra, sa)) <= RENAME_TOL


def pair_renamed(r_left, s_left):
    """Mutually-unique pairs [(r, s)] among the unmatched boxes.  A box with two
    possible partners, or whose partner has two possible partners, is left
    unpaired: a wrong pairing would hide real drift."""
    cands_r = {id(r): [s for s in s_left if _pairable(r, s)] for r in r_left}
    cands_s = {id(s): [r for r in r_left if _pairable(r, s)] for s in s_left}
    return [(r, cands_r[id(r)][0]) for r in r_left
            if len(cands_r[id(r)]) == 1 and len(cands_s[id(cands_r[id(r)][0])]) == 1]


def _canon(b):
    """The box with Max's nested explicit defaults removed (NESTED_DEFAULTS)."""
    todo = [(path, d) for (cls, *path), d in NESTED_DEFAULTS.items() if cls == b.get("maxclass")]
    numbox = b.get("maxclass") == "live.numbox"
    if not todo and not numbox:
        return b
    b = copy.deepcopy(b)
    if numbox:                    # Max coerces Int display on a float-type numbox to Float
        v = (b.get("saved_attribute_attributes") or {}).get("valueof")
        if isinstance(v, dict) and v.get("parameter_type") == 0 and v.get("parameter_unitstyle") == 0:
            v["parameter_unitstyle"] = 1
    for path, default in todo:
        node = b
        for k in path[:-1]:
            node = node.get(k) if isinstance(node, dict) else None
            if node is None:
                break
        else:
            if isinstance(node, dict) and path[-1] in node and node[path[-1]] == default:
                del node[path[-1]]
    return b


def _layout_rects(mc, ra, sa):
    if mc in RECT_POSITION_ONLY and ra and sa:
        return ra[:2], sa[:2]
    return ra, sa


def prop_diffs(mc, r, s, skip=()):
    """[(key, built_value, shipped_value)] between matched boxes r (built) and s (shipped),
    after Max's normalisation.  The single definition of a property difference: compare()
    counts these and build/capture.py writes them back."""
    r, s = _canon(r), _canon(s)
    out = []
    for key in sorted((set(r) | set(s)) - IGNORED_PROPS - set(skip)):
        if (mc, key) in DERIVED_PROPS or (mc, key) in STATE_PROPS:
            continue
        default = MAX_DEFAULTS.get((mc, key))
        rv, sv = r.get(key, default), s.get(key, default)
        if rv != sv:
            out.append((key, rv, sv))
    return out


def layout_differs(mc, r, s):
    ra, sa = _layout_rects(mc, r.get("presentation_rect"), s.get("presentation_rect"))
    return bool((r.get("presentation") or s.get("presentation")) and _rect_differs(ra, sa))


def match_boxes(rb, sb):
    """[(built_box, shipped_box, renamed)]: boxes matched by identity, then the mutually
    unique renamed pairs (pair_renamed).  Boxes whose identity is not unique are left out."""
    rc, sc = Counter(map(signature, rb)), Counter(map(signature, sb))
    smap = {signature(b): b for b in sb if sc[signature(b)] == 1}
    out = [(b, smap[signature(b)], False) for b in rb
           if rc[signature(b)] == 1 and signature(b) in smap]
    r_only = [b for b in rb if rc[signature(b)] == 1 and sc[signature(b)] == 0]
    s_only = [b for b in sb if sc[signature(b)] == 1 and rc[signature(b)] == 0]
    out += [(r, s, True) for r, s in pair_renamed(r_only, s_only)]
    return out


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

    # Boxes whose identity is unique on their own side and absent from the other
    # are candidates for being the same element renamed.
    r_only = [b for b in rb if rc[signature(b)] == 1 and sc[signature(b)] == 0]
    s_only = [b for b in sb if sc[signature(b)] == 1 and rc[signature(b)] == 0]
    pairs = pair_renamed(r_only, s_only)
    left_def, left_patch = rc - sc, sc - rc
    for r, s in pairs:
        note("boxes_renamed", f"{_fmt(signature(r))} -> {_fmt(signature(s))}")
        left_def[signature(r)] -= 1
        left_patch[signature(s)] -= 1
    for sig in left_def.elements():
        note("boxes_def_only", _fmt(sig))
    for sig in left_patch.elements():
        note("boxes_patch_only", _fmt(sig))

    rmap = {signature(b): b for b in rb if rc[signature(b)] == 1}
    smap = {signature(b): b for b in sb if sc[signature(b)] == 1}
    renamed = {signature(r) for r, _ in pairs}
    for r, s in pairs:                       # a pair is matched under the definition's identity
        smap[signature(r)] = s
    for sig, r in rmap.items():
        s = smap.get(sig)
        if not s:
            continue
        mc = sig[0]
        skip = RENAME_SKIP_PROPS if sig in renamed else ()
        for key, rv, sv in prop_diffs(mc, r, s, skip):
            note("props", f"{_fmt(sig)}.{key}: built={str(rv)[:30]!r} "
                          f"shipped={str(sv)[:30]!r}")
        if layout_differs(mc, r, s):
            note("layout", f"{_fmt(sig)}: built={r.get('presentation_rect')} "
                           f"shipped={s.get('presentation_rect')}")

    pair_of = {id(r): s for r, s in pairs}
    rpix = [b for b in rb if str(b.get("text", "")).startswith("jit.gl.pix")]
    spix = [b for b in sb if str(b.get("text", "")).startswith("jit.gl.pix")]
    for rp in rpix:
        m = [sp for sp in spix if sp.get("text") == rp.get("text")]
        if not m and id(rp) in pair_of:      # same pix, @name (or similar) edited
            m = [pair_of[id(rp)]]
        if not m:
            note("pix_io", f"no shipped pix with text {rp.get('text', '')[:40]!r}")
            continue
        if (rp["numinlets"], rp["numoutlets"]) != (m[0]["numinlets"], m[0]["numoutlets"]):
            note("pix_io", f"{rp['text'][:30]}: in/out {rp['numinlets']}/{rp['numoutlets']} "
                           f"vs {m[0]['numinlets']}/{m[0]['numoutlets']}")
        if _gen_code(rp) != _gen_code(m[0]):
            note("code", rp["text"][:50])

    def edges(patcher, boxes, count_of, alias=None):
        sig_of = {b["id"]: signature(b) for b in boxes if count_of[signature(b)] == 1}
        sig_of.update(alias or {})
        out = set()
        for line in patcher.get("lines", []):
            (s, so), (d, di) = line["patchline"]["source"], line["patchline"]["destination"]
            if s in sig_of and d in sig_of:
                out.add((sig_of[s], so, sig_of[d], di))
        return out

    alias = {s["id"]: signature(r) for r, s in pairs}
    re_, se_ = edges(rebuilt, rb, rc), edges(shipped, sb, sc, alias)
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
