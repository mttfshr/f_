#!/usr/bin/env python3
"""Merge a `bypass_mode: "param"` rebuild into the SHIPPED patcher, keeping everything else as shipped.

Usage (after `build/py.sh build/build_patcher.py src/<m>/definition.py` rewrote the patcher):
    python3 scratch/rollout_param_bypass.py <module> [--dry-run] [--accept-layout]

OLD = the committed file (git HEAD), NEW = the working-tree file the builder just wrote.
Result = OLD plus exactly two kinds of change taken from NEW:
  1. the `code` of any codebox that differs;
  2. the bypass box (jsui -> attrui @attr bypass becomes jsui -> `prepend param <gate>`).
Differences in Max-normalised keys (inlet/outlet `index`, `parameter_unitstyle`) are ignored (kept as
shipped).  ANY other difference aborts with a report, and the working-tree file is left untouched
(restore it with `git checkout -- <file>`).  Cords must be identical.

--accept-layout  also take `patching_rect` from NEW for boxes that differ in nothing else (edit-view
                 layout owned by the builder); every rect taken is printed.  Parse/dump mode only.

Two writing modes, chosen automatically:
  * builder-formatted file (json.dumps(OLD) == OLD): parse, change, dump.
  * Max-saved file (any other formatting): the codebox string and the bypass block are replaced IN THE
    TEXT, so the other ~2000 lines stay byte-identical; the result is re-parsed and must equal the
    intended merged structure exactly, or nothing is written.
"""
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
NORMALISED = {"index", "parameter_unitstyle"}


def dump(obj):
    return json.dumps(obj, indent="\t")


def walk_boxes(patcher, path=()):
    for b in patcher.get("boxes", []):
        box = b["box"]
        here = path + (box.get("id"),)
        yield here, box
        if "patcher" in box:
            yield from walk_boxes(box["patcher"], here)


def strip(v):
    if isinstance(v, dict):
        return {k: strip(x) for k, x in v.items() if k not in NORMALISED}
    if isinstance(v, list):
        return [strip(x) for x in v]
    return v


def differing_keys(a, b):
    return {k for k in set(a) | set(b) if k != "patcher" and strip(a.get(k)) != strip(b.get(k))}


def max_value(v):
    """A value in Max's save style: inline arrays `[ a, b ]`, strings raw (not \\u-escaped)."""
    if isinstance(v, list):
        return "[ " + ", ".join(max_value(x) for x in v) + " ]" if v else "[  ]"
    return json.dumps(v, ensure_ascii=False)


def max_box_lines(box, indent):
    """The inner lines of a box in Max style (keys sorted, last one without a comma)."""
    keys = sorted(box)
    out = []
    for i, k in enumerate(keys):
        out.append(f'{indent}"{k}": {max_value(box[k])}' + ("," if i < len(keys) - 1 else ""))
    return out


def textual_patch(old_text, olds, news, changes, npath):
    """Replace code strings and the bypass block inside the Max-formatted text."""
    text = old_text
    # --- codebox strings
    code_changes = [p for k, p in changes if k == "code"]
    by_old = {}
    for p in code_changes:
        by_old.setdefault(olds[p]["code"], []).append(p)
    for old_code, paths in by_old.items():
        lit_old = json.dumps(old_code, ensure_ascii=False)
        if text.count(lit_old) != len(paths):
            sys.exit(f"ABORT: the old codebox string appears {text.count(lit_old)} times in the text, "
                     f"expected {len(paths)} (its encoding differs from Max's); merge by hand.")
        new_codes = {news[npath.get(p, p)]["code"] for p in paths}
        if len(new_codes) != 1:
            sys.exit("ABORT: boxes sharing one old codebox got different new codes; merge by hand.")
        text = text.replace(lit_old, json.dumps(new_codes.pop(), ensure_ascii=False))
    # --- bypass block
    (bp,) = [p for k, p in changes if k == "bypass"]
    box_id = bp[-1]
    lines = text.split("\n")
    idx = [i for i, l in enumerate(lines) if l.strip() == f'"id": "{box_id}",']
    if len(idx) != 1:
        sys.exit(f"ABORT: bypass box id {box_id} found {len(idx)} times in the text.")
    s = idx[0]
    while lines[s].strip() != '"box": {':
        s -= 1
    e = idx[0]
    while lines[e].strip() not in ("}", "},"):
        e += 1
    indent = lines[idx[0]][: len(lines[idx[0]]) - len(lines[idx[0]].lstrip())]
    merged = dict(news[npath.get(bp, bp)])
    merged["id"] = olds[bp]["id"]                                # the shipped id: the cords refer to it
    merged["patching_rect"] = olds[bp]["patching_rect"]          # edit-view position stays as shipped
    lines[s + 1:e] = max_box_lines(merged, indent)
    return "\n".join(lines), merged


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    accept_layout = "--accept-layout" in sys.argv
    mod = args[0]
    rel = f"package/patchers/{mod}.maxpat"
    path = REPO / rel
    old_text = subprocess.run(["git", "show", f"HEAD:{rel}"], cwd=REPO, capture_output=True,
                              text=True, check=True).stdout
    new_text = path.read_text()
    old, new = json.loads(old_text), json.loads(new_text)

    builder_format = dump(old) == old_text.rstrip("\n")
    trailing = "\n" if old_text.endswith("\n") else ""
    if not builder_format and accept_layout:
        sys.exit("ABORT: --accept-layout needs a builder-formatted file (this one was saved by Max).")

    olds = dict(walk_boxes(old["patcher"]))
    news = dict(walk_boxes(new["patcher"]))
    npath = {}                          # old box path -> new box path (identity when the ids agree)
    paired = False
    if set(olds) != set(news) or old["patcher"].get("lines") != new["patcher"].get("lines"):
        if builder_format:
            sys.exit("ABORT: box ids or top-level cords differ between the shipped file and the rebuild.")
        # A Max-saved file whose ids Max renumbered: ids and cords cannot be compared.  Pair the
        # codeboxes by document order and find the bypass boxes by what they are; the end-to-end check
        # is then `build/drift.py`, which pairs boxes by content (run it afterwards, it must say ok).
        paired = True
        oc = [p for p, b in olds.items() if "code" in b]
        nc = [p for p, b in news.items() if "code" in b]
        if len(oc) != len(nc) or not oc:
            sys.exit(f"ABORT: {len(oc)} codeboxes shipped vs {len(nc)} rebuilt; merge by hand.")
        # pair by textual similarity (document order is not trustworthy with several codeboxes); every
        # old codebox must pick a different new one
        import difflib
        npath = {}
        for po in oc:
            best = max(nc, key=lambda pn: difflib.SequenceMatcher(None, olds[po]["code"], news[pn]["code"],
                                                                  autojunk=False).ratio())
            npath[po] = best
        if len(set(npath.values())) != len(oc):
            sys.exit("ABORT: could not pair the codeboxes one to one by similarity; merge by hand.")
        ob_ = [p for p, b in olds.items() if b.get("maxclass") == "attrui" and b.get("attr") == "bypass"]
        nb_ = [p for p, b in news.items() if b.get("maxclass") == "newobj"
               and b.get("text") == "prepend param bypass_gate"]
        if len(ob_) != 1 or len(nb_) != 1:
            sys.exit(f"ABORT: {len(ob_)} shipped bypass attruis, {len(nb_)} rebuilt prepend boxes; merge by hand.")
        npath[ob_[0]] = nb_[0]

    changes, problems, rects = [], [], []
    for p, ob in olds.items():
        if paired:
            if p in npath:
                if "code" in ob and ob["code"] != news[npath[p]]["code"]:
                    changes.append(("code", p))
                elif ob.get("maxclass") == "attrui":
                    changes.append(("bypass", p))
            continue
        nb = news[p]
        diff = differing_keys(ob, nb)
        if "patcher" in ob and ob["patcher"].get("lines") != nb["patcher"].get("lines"):
            problems.append(f"{'/'.join(map(str, p))}: nested cords differ")
        if "code" in diff:
            changes.append(("code", p))
            diff.discard("code")
        if ob.get("maxclass") == "attrui" and ob.get("attr") == "bypass" and \
                nb.get("maxclass") == "newobj" and str(nb.get("text", "")).startswith("prepend param "):
            changes.append(("bypass", p))
            continue
        if accept_layout and "patching_rect" in diff:
            rects.append((p, ob["patching_rect"], nb["patching_rect"]))
            diff.discard("patching_rect")
        extra = diff - NORMALISED
        if extra:
            problems.append(f"{'/'.join(map(str, p))}: unexpected differing keys {sorted(extra)}")
    if problems:
        print("ABORT, nothing written:")
        for line in problems:
            print("  ", line)
        sys.exit(1)
    n_code = sum(1 for k, _ in changes if k == "code")
    n_byp = sum(1 for k, _ in changes if k == "bypass")
    if n_byp != 1 or n_code < 1:
        sys.exit(f"ABORT: expected exactly 1 bypass box and at least 1 codebox change, got {n_byp} and {n_code}.")

    # the intended result, as a structure (also the check for the textual mode)
    expected = json.loads(old_text)
    exp_boxes = dict(walk_boxes(expected["patcher"]))
    merged_bypass = None
    for kind, p in changes:
        if kind == "code":
            exp_boxes[p]["code"] = news[npath.get(p, p)]["code"]
    for kind, p in changes:
        if kind == "bypass":
            merged_bypass = dict(news[npath.get(p, p)])
            merged_bypass["id"] = olds[p]["id"]
            if not accept_layout:
                merged_bypass["patching_rect"] = olds[p]["patching_rect"]
            exp_boxes[p].clear()
            exp_boxes[p].update(merged_bypass)
    for p, _old_r, new_r in rects:
        exp_boxes[p]["patching_rect"] = new_r

    if builder_format:
        result = dump(expected) + trailing
        mode = "parse/dump"
    else:
        result, merged = textual_patch(old_text, olds, news, changes, npath)
        merged["patching_rect"] = olds[[p for k, p in changes if k == "bypass"][0]]["patching_rect"]
        got = json.loads(result)
        if got != expected:
            sys.exit("ABORT: the textually patched file does not equal the intended structure; "
                     "nothing written (merge by hand).")
        mode = "textual, paired by content (Max-saved file; now run build/drift.py)" if paired else "textual (Max-saved file)"
    for p, o, n in rects:
        print(f"   layout {'/'.join(map(str, p))}: {o} -> {n}")
    print(f"{mod}: {n_code} codebox(es) updated, 1 bypass box replaced, {len(rects)} rect(s) taken; mode {mode}"
          f" ({'dry run, nothing written' if dry else 'written'})")
    if not dry:
        path.write_text(result)


main()
