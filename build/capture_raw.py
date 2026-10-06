"""
capture_raw.py -- write the parts of a shipped patcher that the builder does not produce into
`raw_ui.json` next to the module's definition.py, for `raw_boxes` / `raw_lines` / `raw_parameters`
(build/spec.md, "Raw boxes").  The third use of the same recipe (f_droste by hand, f_grain by a
throwaway script, then the colour modules), so it is a tool now.

    build/py.sh build/capture_raw.py src/f_grain/definition.py             # write raw_ui.json
    build/py.sh build/capture_raw.py src/f_grain/definition.py --dry-run   # show, don't write
    build/py.sh build/capture_raw.py src/f_x/definition.py --shipped=/path/to/f_x.maxpat   # another patcher

How it works.  The definition is built WITHOUT its raw_* keys; each generated box is matched to
the shipped patcher's box by drift.py's identity rules (drift.match_boxes), and boxes whose
identity is not unique but exists on both sides are paired in order.  Every shipped box left over
is a raw box: copied verbatim, with a fresh id obj-901, obj-902, ... (shipped order).  Every
shipped cord with at least one raw endpoint becomes a raw line, its other end translated to the
built box's id.  Shipped `parameters` entries for raw boxes are carried over under the new ids.
Cords between two boxes the builder does generate are NOT captured: if the builder does not
write one, drift reports it as `lines_patch_only`, which is the signal to extend the builder.

The definition reads the file itself (f_grain/definition.py shows the pattern):

    _RAW = json.loads((_HERE / "raw_ui.json").read_text()) if (_HERE / "raw_ui.json").exists() else {}
    ... "raw_boxes": _RAW.get("raw_boxes", []), "raw_lines": ..., "raw_parameters": ...

The tool never edits definition.py.  Re-running it is idempotent (the build ignores the existing
raw_* keys), so it can be repeated after a hand edit of the shipped patcher.
"""
import copy
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "build"))
import build_patcher as bp   # noqa: E402
import drift                 # noqa: E402

RAW_ID_BASE = 901            # first raw id: obj-901 (the builder's own ids stay below this)
RAW_KEYS = ("raw_boxes", "raw_lines", "raw_parameters")


def plan(definition_path, shipped_path=None):
    """The raw_* content for a definition and its shipped patcher (pure: writes nothing).

    -> {"raw_boxes": [...], "raw_lines": [...], "raw_parameters": {...}}"""
    definition_path = Path(definition_path)
    defn = bp.load_definition(definition_path)
    for k in RAW_KEYS:
        defn.pop(k, None)                       # build without them, so a re-run is idempotent
    built = bp.build(defn)["patcher"]
    if shipped_path is None:
        shipped_path = ROOT / "package" / "patchers" / f"{defn['name']}.maxpat"
    shipped = json.load(open(shipped_path))["patcher"]

    rb = [b["box"] for b in built["boxes"]]
    sb = [b["box"] for b in shipped["boxes"]]
    rc, sc = Counter(map(drift.signature, rb)), Counter(map(drift.signature, sb))

    ship_to_built = {s["id"]: r["id"] for r, s, _ in drift.match_boxes(rb, sb)}
    for sig in sc:                              # non-unique identities present on both sides: in order
        if sc[sig] > 1 and rc[sig] >= 1:
            sl = [b for b in sb if drift.signature(b) == sig]
            rl = [b for b in rb if drift.signature(b) == sig]
            for s, r in zip(sl, rl):
                ship_to_built.setdefault(s["id"], r["id"])

    raw_src = [b for b in sb if b["id"] not in ship_to_built]
    built_ids = {b["id"] for b in rb}
    new_id = {b["id"]: f"obj-{RAW_ID_BASE + i}" for i, b in enumerate(raw_src)}
    clash = built_ids & set(new_id.values())
    if clash:
        raise ValueError(f"raw ids collide with generated ids: {sorted(clash)}")

    raw_boxes = []
    for b in raw_src:
        c = copy.deepcopy(b)
        c["id"] = new_id[b["id"]]
        raw_boxes.append({"box": c})

    def tr(i):
        return new_id[i] if i in new_id else ship_to_built[i]

    raw_lines = []
    for ln in shipped["lines"]:
        pl = ln["patchline"]
        s, d = pl["source"][0], pl["destination"][0]
        if s in new_id or d in new_id:
            raw_lines.append({"patchline": {"destination": [tr(d), pl["destination"][1]],
                                            "source": [tr(s), pl["source"][1]]}})

    raw_parameters = {new_id[k]: v for k, v in shipped.get("parameters", {}).items() if k in new_id}
    return {"raw_boxes": raw_boxes, "raw_lines": raw_lines, "raw_parameters": raw_parameters}


def render(content):
    return json.dumps(content, indent=1, ensure_ascii=False) + "\n"


def describe(content):
    boxes = [(b["box"]["id"], b["box"]["maxclass"],
              (b["box"].get("text") or b["box"].get("varname") or "")[:28]) for b in content["raw_boxes"]]
    return (f"{len(boxes)} raw boxes, {len(content['raw_lines'])} raw lines, "
            f"{len(content['raw_parameters'])} raw parameters", boxes)


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 1:
        print(__doc__)
        return 2
    dp = Path(args[0]).resolve()
    shipped = next((Path(a.split("=", 1)[1]) for a in argv if a.startswith("--shipped=")), None)
    content = plan(dp, shipped)
    summary, boxes = describe(content)
    print(f"{dp.parent.name}: {summary}")
    for b in boxes:
        print("  ", *b)
    out = dp.parent / "raw_ui.json"
    if "--dry-run" in argv:
        print("(dry run: nothing written)")
        return 0
    text = render(content)
    if out.exists() and out.read_text() == text:
        print(f"{out.name}: unchanged")
    else:
        out.write_text(text)
        print(f"wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
