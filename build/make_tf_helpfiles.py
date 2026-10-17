"""
make_tf_helpfiles.py -- generate package/help/f_tf_tensormap.maxhelp and
f_tf_axisflow.maxhelp (module-preflight, 2026-10-16). Reuses the layout helpers
of make_missing_helpfiles.py WITHOUT running its module loop (that one rewrites
every helpfile it lists, including hand-corrected ones). No API calls.

Run:  python3 build/make_tf_helpfiles.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
_src = (ROOT / "build" / "make_missing_helpfiles.py").read_text()
ns = {"__file__": str(ROOT / "build" / "make_missing_helpfiles.py")}
exec(compile(_src.split("# ---------------------------------------------------------------- digests")[0],
             "make_missing_helpfiles_prefix", "exec"), ns)
build, extract_params, HELP = ns["build"], ns["extract_params"], ns["HELP"]

MODULES = {
    "f_tf_tensormap": dict(
        title="Tensor Map",
        digest="Structure tensor of any texture -- where edges run, how strong, how sure. Feeds Axis Flow",
        recipe="Preview shows outlet 1: hue = edge\ndirection. Wire it to Axis Flow.",
        references=("References\n\n"
                    "Structure tensor: Bigun & Granlund (1987),\n"
                    "\"Optimal orientation detection of linear\n"
                    "symmetry\"; Kass & Witkin (1987), \"Analyzing\n"
                    "oriented patterns\". Sobel gradient, box\n"
                    "window, closed-form 2x2 eigen: standard.\n\n"
                    "See docs/f-reference/f_tf_tensormap.md and\n"
                    "docs/f-reference/f_tensor_type.md. Outlet 1\n"
                    "is angle-doubled: not a vecfield."),
        n_in=1, n_out=2, preview_outlet=1, box=(154.0, 84.0)),
    "f_tf_axisflow": dict(
        title="Axis Flow",
        digest="Turns a Tensor Map into a flow field that follows image edges, with no seam. Feeds Advect, Warp",
        recipe="Input: Tensor Map outlet 1. Output goes\nto a vecfield inlet (e.g. Advect in2).",
        references=("References\n\n"
                    "Original construction: projects a reference\n"
                    "direction onto the structure axis using\n"
                    "cos 2t / sin 2t directly (standard linear\n"
                    "algebra, no external source). No atan2, no\n"
                    "sign choice.\n\n"
                    "See docs/f-reference/f_tf_axisflow.md and\n"
                    "docs/f-reference/f_vecfield_type.md."),
        n_in=1, n_out=1, preview_outlet=0, box=(154.0, 124.0)),
}

for name, spec in MODULES.items():
    params = extract_params(name)
    doc = build(name, spec["title"], spec["digest"], params, spec["recipe"],
                spec["references"], n_in=spec["n_in"])
    for l in doc["patcher"]["lines"]:
        l["patchline"]["source"] = ["d-4", spec["preview_outlet"]]
    w, h = spec["box"]
    for b in doc["patcher"]["boxes"]:
        bx = b["box"]
        if bx["id"] == "d-4":
            bx["patching_rect"] = [338.0, 24.0, w, h]
            bx["numoutlets"] = spec["n_out"]
            bx["outlettype"] = ["jit_gl_texture"] * spec["n_out"]
        elif bx["id"] == "d-5":
            bx["patching_rect"][1] = 24.0 + h + 20.0
        elif bx["id"] == "d-9":
            bx["patching_rect"][1] = 24.0 + h + 40.0
    out = HELP / f"{name}.maxhelp"
    json.dump(doc, open(out, "w"), indent=1)
    print(f"{name}: {len(params)} params -> {out.name}")
