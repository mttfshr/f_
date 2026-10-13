"""
make_missing_helpfiles.py -- one-shot generator for the 14 shipped GPU
modules with no helpfile (helpfiles T023 batch, 2026-10-12).

Follows the f_vf_vortex.maxhelp template structure exactly (title digest,
one-line digest, External Control Messages block, References block,
panel, module bpatcher + vs_preview, wiring), with the demo wiring per
.specify/helpfiles/plan.md's archetypes:
  processor/source modules: module bpatcher -> vs_preview (fed source by
    the preview chain itself for generators, or fed by the module's
    own input in the case of pure processors we keep it simple: the
    module feeds the preview; for texture-in modules the preview chain
    provides no source, matching the existing helpfiles' minimalism --
    they demonstrate the module at defaults with whatever the user
    patches in; the existing f_vf_vortex (generator) template wires
    module out -> preview in only).
  f_vf_seeds is a source with 4 inlets but its first three outlets are
    the demo surface; same single-wire demo.

Param blocks are generated from src/<name>/definition.py (AST parse),
internal/bypass params filtered: internal omitted, bypass always last
as [0 / 1]. text_button/menu params print their options.

Run:  python3 build/make_missing_helpfiles.py   (writes package/help/)
"""
import ast
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
HELP = ROOT / "package" / "help"

EN = "\u2013"  # en dash, matching the existing helpfiles


def extract_params(module):
    """Ordered [(name, range_text)] from definition.py; internal dropped,
    bypass forced last."""
    src = (SRC / module / "definition.py").read_text()
    if module == "f_vf_seeds":
        # params built via _ui() calls: (name, min, max, default, label, hint, ...)
        rows = []
        for m in re.finditer(r'_ui\("(\w+)",\s*([-\d.]+),\s*([-\d.]+),\s*[-\d.]+,\s*"([^"]*)"', src):
            rows.append((m.group(1), f"{m.group(2)} {EN} {m.group(3)}"))
        rows.append(("bypass", "0 / 1"))
        return rows
    tree = ast.parse(src)
    found = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Dict):
            d = {}
            for k, v in zip(node.keys, node.values):
                if isinstance(k, ast.Constant):
                    try:
                        d[k.value] = ast.literal_eval(v)
                    except Exception:
                        d[k.value] = None
            if "name" in d and isinstance(d.get("name"), str) \
                    and d.get("type") in ("float", "text_button", "menu", "bypass", "internal", "raw_ui"):
                found.append(d)
    seen, ordered = set(), []
    for d in found:
        n = d["name"]
        if n in seen or n.startswith("src_"):
            continue
        seen.add(n)
        t = d.get("type")
        if t == "internal":
            continue
        if t == "bypass":
            continue
        if t == "float":
            lo, hi = d.get("min"), d.get("max")
            ordered.append((n, f"{lo:g} {EN} {hi:g}"))
        elif t in ("text_button", "menu"):
            opts = d.get("options") or []
            ordered.append((n, "/".join(str(o) for o in opts)))
        elif t == "raw_ui":
            continue  # not addressable by named message
        else:
            ordered.append((n, ""))
    ordered.append(("bypass", "0 / 1"))
    return ordered


def box(id_, maxclass, rect, text=None, fontsize=12.0, fontname="Ableton Sans Light",
        linecount=None, bubble=False, extra=None):
    b = {"id": id_, "maxclass": maxclass, "numinlets": 1, "numoutlets": 0,
         "patching_rect": rect}
    if maxclass == "comment":
        b.update({"fontface": 0, "fontname": fontname,
                  "bgcolor": [0.2, 0.2, 0.2, 0.0],
                  "saved_attribute_attributes": {"textcolor": {"expression": "themecolor.live_control_fg"}}})
        if bubble:
            b["bgcolor"] = [0.0, 0.0, 0.0, 0.0]
            b["bubble"] = 1
            del b["saved_attribute_attributes"]
    if text is not None:
        b["text"] = text
    if fontsize:
        b["fontsize"] = fontsize
    if linecount:
        b["linecount"] = linecount
    if extra:
        b.update(extra)
    return {"box": b}


def bpatcher(id_, name, rect, n_in, n_out, outlettype, varname=None):
    b = {"id": id_, "maxclass": "bpatcher", "name": name,
         "numinlets": n_in, "numoutlets": n_out, "outlettype": outlettype,
         "patching_rect": rect,
         "bgmode": 1, "border": 1, "clickthrough": 0,
         "enablehscroll": 0, "enablevscroll": 0, "lockeddragscroll": 0,
         "lockedsize": 0, "offset": [0.0, 0.0], "viewvisibility": 1}
    if varname:
        b["varname"] = varname
    return {"box": b}


def n_outlets_of(module):
    src = (SRC / module / "definition.py").read_text()
    m = re.search(r'"outlets": \[(.*?)\]', src, re.S)
    if not m:
        return 1
    return len(re.findall(r'\{"comment"', m.group(1))) or 1


def build(module, title, digest, params, recipe, references, n_in=1):
    rows = [f"{n} [{r}]" if r and "/" not in r else f"{n} [{r}]" if r else n
            for n, r in params]
    ctrl = "External Control Messages\n\n" + "\n".join(rows)
    n_ctrl = len(rows) + 2
    n_out = n_outlets_of(module)
    outlettype = ["jit_gl_texture"] * n_out

    boxes = [
        box("h-1", "comment", [15.0, 15.0, 270.0, 50.0], title, fontsize=36.0,
            fontname="Ableton Sans Medium", extra={"varname": "autohelp_top_digest[4]"}),
        box("h-2", "comment", [15.0, 75.0, 270.0, 40.0], digest, fontsize=14.0,
            linecount=2, extra={"varname": "autohelp_top_digest[3]"}),
        box("d-8", "comment", [15.0, 150.0, 270.0, float(17 * n_ctrl)], ctrl,
            linecount=n_ctrl),
        box("r-1", "comment", [15.0, 150.0 + 17 * n_ctrl + 20.0, 270.0, 120.0],
            references, fontsize=12.0, linecount=references.count("\n") + 1),
        {"box": {"id": "obj-1", "maxclass": "panel", "numinlets": 1, "numoutlets": 0,
                 "patching_rect": [0.0, -2.0, 303.0, 765.0]}},
        bpatcher("d-4", f"{module}.maxpat", [338.0, 24.0, 154.0, 91.0], n_in, n_out,
                 outlettype, varname=module),
        bpatcher("d-5", "vs_preview.maxpat", [338.0, 135.0, 236.0, 249.0], 1, 1,
                 ["jit_gl_texture"]),
    ]
    if recipe:
        boxes.append(box("d-9", "comment", [500.0, 155.0, 210.0, 51.0], recipe,
                         fontsize=12.0, linecount=2, bubble=True))
    lines = [{"patchline": {"destination": ["d-5", 0], "source": ["d-4", 0]}}]
    return {"patcher": {
        "fileversion": 1,
        "appversion": {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1},
        "classnamespace": "box",
        "rect": [100.0, 99.0, 871.0, 780.0],
        "gridonopen": 2, "toolbarvisible": 0, "helpsidebarclosed": 1,
        "boxes": boxes, "lines": lines,
        "parameters": {"inherited_shortname": 1},
        "autosave": 0,
    }}


# ---------------------------------------------------------------- digests
MODULES = {
    "f_vf_advect": dict(
        title="Advect",
        digest="Advects source texture along a vecfield with temporal feedback -- persistent flow trails",
        recipe="Feed a vecfield (vortex, fluid) into in2;\nany texture into in1.",
        references="References\n\nSee docs/f-reference/f_vf_advect.md and\ndocs/f-reference/f_vecfield_type.md. Bypass keeps\nthe feedback warm by design (ADR-8 family).",
        n_in=4),
    "f_vf_chroma": dict(
        title="Chroma",
        digest="Vecfield-driven chromatic streak -- synthesized rainbow march gated by luma (v10, paused retool)",
        recipe="Feed a vecfield into in2; bright\nsource areas emit the streak.",
        references="References\n\nSee docs/f-reference/f_vf_chroma.md. Note: mid-retool --\nthe shipped v10 washes the rainbow out at high\ndispersion (accumulation averages hues); the\nclosest-emitter redesign is specced in\n.specify/paused/f_vf_chroma/. direction=Bi is\nunreachable from the UI (build bug)."),
    "f_vf_flow": dict(
        title="Flow",
        digest="Dual-mode uniform / texture-perturbed direction field -- feeds f_weave's vecfield inlet",
        recipe="Designed to feed f_weave in2 or any\nvecfield consumer.",
        references="References\n\nSee docs/f-reference/f_vf_flow.md and\ndocs/f-reference/f_vecfield_type.md."),
    "f_vf_glow": dict(
        title="Glow",
        digest="Field-aligned directional blur -- accumulates along streamlines with exponential falloff",
        recipe="Feed a vecfield into in2; any texture\ninto in1.",
        references="References\n\nSee docs/f-reference/f_vf_glow.md and\ndocs/f-reference/f_vecfield_type.md."),
    "f_vf_potential": dict(
        title="Potential",
        digest="Scalar potential-field integrator -- accumulates vecfield magnitude over time into isolines",
        recipe="Feed into f_weave's scalar inlet for\ncurved, field-informed isolines.",
        references="References\n\nSee docs/f-reference/f_vf_potential.md.\nIntegrates field magnitude only -- axis-blind\n(a 180-degree flipped field looks identical)."),
    "f_vf_prism": dict(
        title="Prism",
        digest="Vecfield-driven prism separation -- luma-gated RGB displacement along the field",
        recipe="Feed a vecfield into in2; any texture\ninto in1.",
        references="References\n\nSee docs/f-reference/f_vf_prism.md and\ndocs/f-reference/f_vecfield_type.md."),
    "f_vf_repulse": dict(
        title="Repulse",
        digest="Obstacle-style repulsion field from a source texture's luma -- divergent flow around bright areas",
        recipe="Feed any texture into in1; the field\npushes around its bright regions.",
        references="References\n\nSee docs/f-reference/f_vf_repulse.md and\ndocs/f-reference/f_vecfield_type.md."),
    "f_vf_seeds": dict(
        title="Seeds",
        digest="Discrete marks placed on a hash grid, oriented and weighted by a vecfield -- dual source/processor",
        recipe="Feed a vecfield into in2; optionally a\nshape texture into in1.",
        references="References\n\nSee docs/f-reference/f_vf_seeds.md and\ndocs/f-reference/f_vecfield_type.md.",
        n_in=5),
    "f_vf_split": dict(
        title="Vf Split",
        digest="Splits a vecfield's X/Y channels to two greyscale outlets, unipolar or bipolar",
        recipe="Utility -- inspect vecfield channels.",
        references="References\n\nSee docs/f-reference/f_vf_split.md and\ndocs/f-reference/f_vecfield_type.md.",
        n_in=2),
    "f_vf_vortex_multi": dict(
        title="Vortex Multi",
        digest="Three-site additive vortex field -- per-site position/convergence/curl, 4 global mod inlets",
        recipe="Feed into f_vf_warp, f_caustic, or\nf_vf_streak to visualize the field.",
        references="References\n\nSee docs/f-reference/f_vf_vortex_multi.md and\ndocs/f-reference/f_vecfield_type.md."),
    "f_vf_vorticity": dict(
        title="Vorticity",
        digest="Vorticity-confinement processor -- amplifies curl in a vecfield (UNVERIFIED -- do not rely on it)",
        recipe="Feed a vecfield in; output is the\nconfinement-processed field.",
        references="References\n\nSee docs/f-reference/f_vf_vorticity.md.\nREADME marks this module Unverified -- treat the\nhelpfile demo as exploratory, not a guarantee.",
        n_in=2),
    "f_weave": dict(
        title="Weave",
        digest="Parametric distance-field line texture with per-line phase variation; optional vecfield + scalar inlets",
        recipe="Feed f_vf_flow into in2 and\nf_vf_potential into in3 for field-curved lines.",
        references="References\n\nSee docs/f-reference/f_weave.md and\ndocs/f-reference/discrete_item_conventions.md.",
        n_in=4),
    "f_ngon": dict(
        title="N-gon",
        digest="Regular N-gon generator / mask, live-modulatable vertex count (UNFINISHED -- not yet confirmed)",
        recipe="Pure generator; try n_mirrors sweeps\nfor kaleidoscope masks.",
        references="References\n\nSee ideas/f_ngon.md (the pre-spec questions)\nand docs/f-reference/f_ngon.md if present.\nREADME marks this module Unfinished."),
    "f_sirds": dict(
        title="Sirds",
        digest="Single-image random-dot stereogram from a depth texture -- autostereogram depth mapping",
        recipe="Feed a luma depth texture into in1;\ndefocus your eyes to fuse the image.",
        references="References\n\nSee docs/f-reference/f_sirds.md. Depth-map\nto autostereogram displacement follows the\nclassic SIRDS technique (Thimbleby et al.);\ndivergence from the GPU Gems convention is\nrecorded in the doc's Open Questions."),
}

for name, spec in MODULES.items():
    params = extract_params(name)
    doc = build(name, spec["title"], spec["digest"], params, spec["recipe"],
                spec["references"], n_in=spec.get("n_in", 2))
    out = HELP / f"{name}.maxhelp"
    json.dump(doc, open(out, "w"), indent=1)
    print(f"{name}: {len(params)} params, written")
print("done")