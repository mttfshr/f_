#!/usr/bin/env python3
"""
capture.py -- write hand-tuned PRESENTATION state from a shipped patcher back into its
definition.py, as an `overrides` block (build/spec.md, "Overrides").

    build/py.sh build/capture.py src/f_vf_fieldmap/definition.py             # capture
    build/py.sh build/capture.py src/f_vf_fieldmap/definition.py --dry-run   # show, don't write
    build/py.sh build/capture.py src/f_vf_fieldmap/definition.py --keys      # list element keys
    build/py.sh build/build_patcher.py --capture src/f_vf_fieldmap/definition.py   # same thing

How it works.  The definition is built WITHOUT its overrides (build_patcher.build is pure);
each generated box is matched to the shipped patcher's box by drift.py's identity rules; for
every matched element the differences (drift.prop_diffs and layout_differs, so exactly what
`drift.py` reports) are split in two:

  captured      presentation properties (CAPTURE_KEYS): the presentation rect, colours, fonts,
                dial appearance.  These are written to `patcher["overrides"][<element key>]`.
  not captured  everything else, each printed with the reason: label text, hints, ranges and
                enums (the definition owns them: edit params[]), and `varname`/`param_connect`
                (the builder is ahead of the patch, or the patch was edited: regenerate,
                do not freeze it as an override).

Because it always diffs against the build WITHOUT overrides, it is idempotent, and it rewrites
only the block between the BEGIN/END markers; the rest of definition.py is never touched.  An
element that is no longer in the shipped patch keeps its existing override (reported).
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp  # noqa: E402
import drift  # noqa: E402

BEGIN = "# BEGIN overrides (build/capture.py rewrites only this block)"
END = "# END overrides"

# Presentation-only properties: what hand-tuning in Max changes and the schema does not model.
CAPTURE_KEYS = {
    "presentation_rect", "fontsize", "fontname", "textcolor", "bgcolor", "bordercolor",
    "textjustification", "linecount", "appearance", "triangle", "shownumber", "showname",
    "needlemode", "activedialcolor", "valuepopup", "valuepopuplabel", "hidden", "border",
    "background", "tricolor",
    # a live.text's own colours and corner rounding (added 2026-10-05, f_stereo's hand-built
    # `circ` toggle; theme colours Max writes explicitly once they are set by hand)
    "activebgcolor", "activebgoncolor", "activetextcolor", "activetextoncolor", "rounded",
}

WHY_NOT = {
    "text": "label text is a definition value (title, signal_type, params[].label): edit it there",
    "comment": "label text is a definition value: edit it there",
    "hint": "a hint is a definition value (params[].hint): edit it there",
    "saved_attribute_attributes": "a parameter's range/initial/enum is a definition value "
                                  "(params[].min/max/default): edit it there",
    "varname": "the builder is ahead of the patch, or the patch was edited: regenerate, "
               "do not freeze it as an override",
    "param_connect": "the builder is ahead of the patch, or the patch was edited: regenerate, "
                     "do not freeze it as an override",
}


def _why_not(prop):
    return WHY_NOT.get(prop, "not a presentation property (captured: presentation_rect, colours, "
                             "fonts, dial appearance)")


def _py(v, indent=""):
    """A deterministic Python literal for JSON-ish data: double-quoted strings, sorted keys."""
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)
    if isinstance(v, dict):
        return "{" + ", ".join(f"{_py(k)}: {_py(x)}" for k, x in sorted(v.items())) + "}"
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(_py(x) for x in v) + "]"
    return repr(v)


def render_block(overrides):
    lines = [BEGIN, 'patcher["overrides"] = {']
    for key in sorted(overrides):
        lines.append(f"    {_py(key)}: {_py(overrides[key])},")
    lines += ["}", END]
    return "\n".join(lines) + "\n"


_BLOCK_RE = re.compile(r"\n?" + re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n", re.S)


def write_block(path, overrides):
    """Replace (or add, or remove) the marked block; return True if the file changed."""
    text = Path(path).read_text()
    if overrides:
        block = render_block(overrides)
        if BEGIN in text:
            new = _BLOCK_RE.sub(lambda m: ("\n" if m.group(0).startswith("\n") else "") + block, text, count=1)
        else:
            new = text + ("" if text.endswith("\n") else "\n") + "\n" + block
    else:
        new = _BLOCK_RE.sub("", text, count=1) if BEGIN in text else text
    if new == text:
        return False
    Path(path).write_text(new)
    return True


def plan(def_path, shipped_path=None):
    """-> dict(name, captured, kept, not_captured, unmatched, unknown, keys, built)
    without writing anything."""
    defn = bp.load_definition(def_path)
    base = {k: v for k, v in defn.items() if k != "overrides"}
    dbg = {}
    built = json.loads(json.dumps(bp.build(base, debug=dbg)))
    keys = dbg["element_keys"]
    shipped = json.load(open(shipped_path or drift.PATCHERS / f"{defn['name']}.maxpat"))
    rb = [b["box"] for b in built["patcher"]["boxes"]]
    sb = [b["box"] for b in shipped["patcher"]["boxes"]]
    matched = {id(r): (s, renamed) for r, s, renamed in drift.match_boxes(rb, sb)}
    by_id = {b["id"]: b for b in rb}

    captured, not_captured, unmatched = {}, [], []
    for key, box_id in keys.items():
        r = by_id.get(box_id)
        if r is None:
            continue                                   # a role this build did not generate
        m = matched.get(id(r))
        if m is None:
            unmatched.append(key)
            continue
        s, _renamed = m
        mc = r.get("maxclass")
        props = {}
        # No rename exemption here (drift.py skips a renamed box's text only so a rename is
        # not counted twice): a label renamed in Max must be reported as not captured.
        for prop, rv, sv in drift.prop_diffs(mc, r, s):
            if prop in CAPTURE_KEYS:
                props[prop] = sv                       # None removes the property
            else:
                not_captured.append((key, prop, rv, sv))
        if drift.layout_differs(mc, r, s):
            props["presentation_rect"] = s["presentation_rect"]
        if props:
            captured[key] = props
    existing = defn.get("overrides", {}) or {}
    kept = {k: v for k, v in existing.items() if k in unmatched}
    unknown = [k for k in existing if k not in keys]
    kept.update({k: existing[k] for k in unknown})
    return {"name": defn["name"], "captured": captured, "kept": kept,
            "not_captured": not_captured, "unmatched": unmatched, "unknown": unknown,
            "keys": keys, "built": built}


def capture(def_path, shipped_path=None, dry_run=False, out=print):
    pl = plan(def_path, shipped_path)
    final = {**pl["kept"], **pl["captured"]}
    n_props = sum(len(v) for v in pl["captured"].values())
    out(f"{pl['name']}: {n_props} propert{'y' if n_props == 1 else 'ies'} on "
        f"{len(pl['captured'])} element{'' if len(pl['captured']) == 1 else 's'} captured")
    for key in sorted(pl["captured"]):
        out(f"  {key}: {', '.join(sorted(pl['captured'][key]))}")
    if pl["not_captured"]:
        out("not captured (fix in the definition, or regenerate):")
        for key, prop, rv, sv in pl["not_captured"]:
            out(f"  {key}.{prop}: built={str(rv)[:28]!r} shipped={str(sv)[:28]!r} -- {_why_not(prop)}")
    for key in pl["kept"]:
        if key in pl["unknown"]:
            out(f"WARNING override {key!r} names no element of this build; it is kept, and the "
                f"build will fail until you fix or delete it")
        else:
            out(f"kept: {key} is not in the shipped patch, so its override is left as it was")
    if dry_run:
        out("(dry run: nothing written)")
        return pl
    changed = write_block(def_path, final)
    out(f"{'wrote' if changed else 'unchanged:'} {def_path}")
    return pl


def main(argv):
    args = [a for a in argv if not a.startswith("-")]
    if len(args) != 1:
        print(__doc__)
        return 2
    path = Path(args[0]).resolve()
    if "--keys" in argv:
        defn = bp.load_definition(path)
        dbg = {}
        built = bp.build({k: v for k, v in defn.items() if k != "overrides"}, debug=dbg)
        by_id = {b["box"]["id"]: b["box"] for b in built["patcher"]["boxes"]}
        for key, box_id in dbg["element_keys"].items():
            b = by_id.get(box_id)
            if b:
                print(f"{key:28s} {b.get('maxclass', ''):12s} {str(b.get('text') or b.get('comment') or '')[:30]}")
        return 0
    capture(path, dry_run="--dry-run" in argv)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
