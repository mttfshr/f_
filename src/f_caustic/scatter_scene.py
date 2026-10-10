"""
scatter_scene.py -- generates the raw GL scene of f_caustic (.specify/f_caustic_scatter/plan.md, ADR-2: derived by
a script, not typed or captured by hand). Tasks T014, T015. Soft mode, the mode menu, the detail menu and the two
select stages were all removed 2026-10-10: this is now the module's only path, always built at the old "detail 5"
step (1024 sq, 4 points/px) -- see docs/f-reference/f_caustic.md and the decision note in
.specify/f_caustic_scatter/tasks.md.

The scene is a jit.gl.node capture holding a points jit.gl.mesh drawn with package/code/f_caustic_sheets.jxs:
  slabS / slabF   source and field -> normalised 2D float32 (as Vsynth's vs_xyz_disp does)
  route out_name  the slabs' output names -> `texture <src> <field>` on the mesh, refreshed every frame
  grid -> mesh    a plane gridshape as a MATRIX into a points mesh: every lattice point is exactly one vertex
  node            the float32 capture (the illuminance); its outlet 0 is the scene's output
  obj-920         ONE CONTROL ENTRY: `route scale weight r n`. scale / weight -> shader params, r -> the shader's
                  `res` and the node's dim, n -> the lattice size (rebuilds the matrix, n LAST so the big lattice
                  is built once and never at an intermediate size). weight/r/n are sent once, at load, by a fixed
                  message (FIXED_DETAIL below); only `scale` changes live, from the module's Scale dial.
The module's builder aims its params' attruis at obj-920 (`pix_target`), and the standalone test patch sends the
same messages into its inlet 0, so the two have the same interface.

The MODULE layer (module_layer) adds what only the module has: the cord from the builder's Scale dial into the
control entry, and the cord from the scene's capture into the composite pix's second inlet. The composite pix is
the chain's only (and so primary) stage, fixed by the builder at obj-5.

The scene is built enabled and the lattice is built once at load (a fixed message into the control entry, n
last) -- no live rebuild, no mode-gated enable/disable.

Run:
  python3 src/f_caustic/scatter_scene.py                 write src/f_caustic/raw_ui.json (the module's raw layer)
  python3 src/f_caustic/scatter_scene.py --standalone    write tests/bench/caustic_sheets_standalone.maxpat
"""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent

NODE = "#0.node"
SHADER = "#0.sc"
CAPTURE0 = 1024                      # capture size -- now fixed (was the default `detail` step's)
FIXED_DETAIL = (1024, 4)             # (capture size, points per capture pixel) -- the old ladder's step 5, now the
                                      # only setting; see docs/f-reference/f_caustic.md "Parameters"
CTRL = "obj-920"                     # the control entry (a raw box id; the builder targets it)
APPVERSION = {"major": 9, "minor": 1, "revision": 4, "architecture": "x64", "modernui": 1}


class Graph:
    def __init__(self):
        self.boxes, self.lines = [], []

    def obj(self, oid, text, nin, nout, rect, otypes=None):
        self.boxes.append({"box": {"id": oid, "maxclass": "newobj", "text": text, "numinlets": nin,
                                   "numoutlets": nout, "outlettype": otypes or [""] * nout,
                                   "patching_rect": [float(v) for v in rect]}})

    def msg(self, oid, text, rect):
        self.boxes.append({"box": {"id": oid, "maxclass": "message", "text": text, "numinlets": 2, "numoutlets": 1,
                                   "outlettype": [""], "patching_rect": [float(v) for v in rect]}})

    def port(self, oid, maxclass, rect):
        b = {"id": oid, "maxclass": maxclass, "patching_rect": [float(v) for v in rect]}
        b.update({"numinlets": 0, "numoutlets": 1, "outlettype": [""]} if maxclass == "inlet"
                 else {"numinlets": 1, "numoutlets": 0})
        self.boxes.append({"box": b})

    def wire(self, s, so, d, di):
        self.lines.append({"patchline": {"source": [s, so], "destination": [d, di]}})


def detail_message(r, ppp):
    n = int(round(r * ppp ** 0.5))
    return f"r {r}, weight {(r / n) ** 2:.4f}, n {n}"          # n LAST: the lattice is rebuilt once


def scene(g, extra_tokens=()):
    """Add the scene to Graph g. extra_tokens: more `route` tokens the standalone test patch handles (gain,
    mix_pct); their outlets follow the scene's four. Returns the ids the caller wires to."""
    tokens = ("scale", "weight", "r", "n") + tuple(extra_tokens)
    g.obj(CTRL, "route " + " ".join(tokens), 1, len(tokens) + 1, [20, 60, 60 + 60 * len(tokens), 22])

    # texture adapters: normalised 2D float32 (a vertex program wants a sampler2D)
    g.obj("obj-901", "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32", 1, 2, [20, 120, 330, 22],
          ["jit_gl_texture", ""])
    g.obj("obj-902", "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32", 1, 2, [400, 120, 330, 22],
          ["jit_gl_texture", ""])
    # the slabs' output names -> `texture <src> <field>` on the mesh (tex0 = source, tex1 = field)
    g.obj("obj-903", "route out_name", 1, 2, [20, 160, 100, 22])
    g.obj("obj-904", "route out_name", 1, 2, [400, 160, 100, 22])
    g.obj("obj-905", "join", 2, 1, [20, 200, 60, 22])
    g.obj("obj-906", "prepend texture", 1, 1, [20, 240, 110, 22])
    g.wire("obj-901", 1, "obj-903", 0)
    g.wire("obj-902", 1, "obj-904", 0)
    g.wire("obj-903", 0, "obj-905", 0)
    g.wire("obj-904", 0, "obj-905", 1)
    g.wire("obj-905", 0, "obj-906", 0)
    # ask both slabs for their output names every frame (cheap) so `texture` is always current
    g.obj("obj-907", "r draw", 0, 1, [180, 90, 50, 22])
    g.msg("obj-908", "getout_name", [180, 120, 90, 22])
    g.wire("obj-907", 0, "obj-908", 0)
    g.wire("obj-908", 0, "obj-901", 0)
    g.wire("obj-908", 0, "obj-902", 0)

    # the capture, the shader, the lattice and the mesh -- always enabled (there is no other mode to gate against)
    g.obj("obj-909", f"jit.gl.node vsynth @capture 1 @name {NODE} @type float32 @adapt 0 "
                     f"@dim {CAPTURE0} {CAPTURE0} @erase_color 0 0 0 0", 1, 3, [400, 300, 400, 22],
          ["jit_gl_texture", "", ""])
    g.obj("obj-910", f"jit.gl.shader vsynth @name {SHADER} @file f_caustic_sheets.jxs", 1, 2, [20, 300, 330, 22])
    g.obj("obj-911", "jit.gl.gridshape vsynth @shape plane @dim 2 2 @matrixoutput 1 @automatic 0", 1, 2,
          [20, 400, 400, 22], ["jit_matrix", ""])
    g.obj("obj-912", f"jit.gl.mesh {NODE} @draw_mode points @shader {SHADER} @blend_enable 1 @blend_mode 1 1 "
                     f"@depth_enable 0 @point_size 2 @color 1 1 1 1 @lighting_enable 0", 1, 2,
          [20, 440, 600, 22], ["", ""])
    g.wire("obj-911", 0, "obj-912", 0)
    g.wire("obj-906", 0, "obj-912", 0)

    # controls: scale / weight -> shader params; r -> shader res + node dim; n -> lattice dim + rebuild
    g.obj("obj-921", "prepend param scale", 1, 1, [20, 350, 130, 22])
    g.obj("obj-922", "prepend param weight", 1, 1, [160, 350, 140, 22])
    g.obj("obj-923", "prepend param res", 1, 1, [310, 350, 120, 22])
    g.msg("obj-924", "dim $1 $1", [440, 350, 70, 22])
    g.msg("obj-925", "dim $1 $1, bang", [520, 350, 110, 22])
    g.wire(CTRL, 0, "obj-921", 0)
    g.wire(CTRL, 1, "obj-922", 0)
    g.wire(CTRL, 2, "obj-923", 0)
    g.wire(CTRL, 2, "obj-924", 0)
    g.wire(CTRL, 3, "obj-925", 0)
    for src in ("obj-921", "obj-922", "obj-923"):
        g.wire(src, 0, "obj-910", 0)
    g.wire("obj-924", 0, "obj-909", 0)
    g.wire("obj-925", 0, "obj-911", 0)

    # the lattice is built once, at load: r, weight and n (n last) sent into the control entry by a loadbang.
    # There is no ladder any more -- FIXED_DETAIL is the only setting there ever was a reason to use (2026-10-10).
    g.obj("obj-935", "loadbang", 0, 1, [640, 60, 70, 22], ["bang"])
    g.msg("obj-936", detail_message(*FIXED_DETAIL), [640, 100, 330, 22])
    g.wire("obj-935", 0, "obj-936", 0)
    g.wire("obj-936", 0, CTRL, 0)
    return {"ctrl": CTRL, "source_slab": "obj-901", "field_slab": "obj-902", "node": "obj-909",
            "reject_outlet": len(tokens)}


def sheets_pix(g, oid, code, rect):
    """Standalone only: the composite stage as an inline jit.gl.pix (3 inlets, 2 outlets) from codebox_sheets.gen.
    In the module the builder makes it as a pix_chain node from the same file."""
    def sub(i, **kw):
        kw.update({"id": f"gen-obj-{i}", "patching_rect": [30.0 + 110 * (i % 3), 30.0 + 60 * (i // 3), 100.0, 22.0]})
        return {"box": kw}
    gen = {"fileversion": 1, "appversion": dict(APPVERSION), "classnamespace": "jit.gen",
           "rect": [100.0, 100.0, 560.0, 340.0],
           "boxes": [sub(1, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""], text="in 1"),
                     sub(2, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""], text="in 2"),
                     sub(3, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""], text="in 3"),
                     sub(4, maxclass="codebox", code=code, numinlets=3, numoutlets=2, outlettype=["", ""],
                         fontname="<Monospaced>", fontsize=12.0),
                     sub(5, maxclass="newobj", numinlets=1, numoutlets=0, text="out 1"),
                     sub(6, maxclass="newobj", numinlets=1, numoutlets=0, text="out 2")],
           "lines": [{"patchline": {"source": [f"gen-obj-{k}", 0], "destination": ["gen-obj-4", k - 1]}} for k in (1, 2, 3)]
                    + [{"patchline": {"source": ["gen-obj-4", j], "destination": [f"gen-obj-{5 + j}", 0]}} for j in (0, 1)]}
    g.boxes.append({"box": {"id": oid, "maxclass": "newobj", "text": "jit.gl.pix vsynth @name #0.sheets @type float32 @adapt 1",
                            "numinlets": 3, "numoutlets": 3, "outlettype": ["jit_gl_texture", "jit_gl_texture", ""],
                            "patching_rect": [float(v) for v in rect], "patcher": gen}})


def standalone():
    """tests/bench/caustic_sheets_standalone.maxpat: the scene + the composite stage as a 2-inlet bpatcher the
    module bench can load WITHOUT touching f_caustic (the spike_scatter.maxpat precedent).
      inlet 0  control messages + the source texture      inlet 1  the vecfield texture
      outlet 0 the node's float32 capture (the light)     outlet 1 composite     outlet 2 caustic layer"""
    g = Graph()
    g.port("in0", "inlet", [20, 20, 30, 22])
    g.port("in1", "inlet", [400, 20, 30, 22])
    g.port("out0", "outlet", [20, 560, 30, 22])
    g.port("out1", "outlet", [120, 560, 30, 22])
    g.port("out2", "outlet", [220, 560, 30, 22])
    ids = scene(g, extra_tokens=("gain", "mix_pct", "bypass"))
    rej = ids["reject_outlet"]
    # the texture message is the control route's reject outlet
    g.wire("in0", 0, CTRL, 0)
    g.wire(CTRL, rej, "obj-901", 0)
    g.wire("in1", 0, "obj-902", 0)
    # the composite stage: in1 = source, in2 = the capture, in3 = the field; gain / mix_pct / bypass as pix Params
    code = (HERE / "codebox_sheets.gen").read_text()
    sheets_pix(g, "obj-950", code, [20, 500, 520, 22])
    g.wire(CTRL, rej, "obj-950", 0)               # source texture (also what makes the stage render each frame)
    g.wire(ids["node"], 0, "obj-950", 1)          # the capture
    g.wire("in1", 0, "obj-950", 2)                # the field
    g.obj("obj-951", "prepend param gain", 1, 1, [560, 450, 130, 22])
    g.obj("obj-952", "prepend param mix_pct", 1, 1, [700, 450, 140, 22])
    g.obj("obj-953", "prepend param bypass_gate", 1, 1, [850, 450, 160, 22])
    g.wire(CTRL, 4, "obj-951", 0)
    g.wire(CTRL, 5, "obj-952", 0)
    g.wire(CTRL, 6, "obj-953", 0)
    g.wire("obj-951", 0, "obj-950", 0)
    g.wire("obj-952", 0, "obj-950", 0)
    g.wire("obj-953", 0, "obj-950", 0)
    g.wire(ids["node"], 0, "out0", 0)
    g.wire("obj-950", 0, "out1", 0)
    g.wire("obj-950", 1, "out2", 0)
    return {"patcher": {"fileversion": 1, "appversion": dict(APPVERSION), "classnamespace": "box",
                        "rect": [100.0, 100.0, 1040.0, 620.0], "boxes": g.boxes, "lines": g.lines}}


# id the builder assigns the chain's one (and so primary) pix stage (build/spec.md: the primary pix is always
# obj-5). tests/test_scatter_scene.py checks it against a real build of the definition.
SHEETS = "obj-5"
# the builder-made Scale dial's OUTLET, tapped directly (an attrui aimed at a non-pix box would drop the value:
# it learns its attribute from the object it is cabled to -- and `scale` here drives the scene's raw control
# entry, not a Param on the composite codebox, so it carries `pix_wire: False` in definition.py and gets no
# attrui). tests/test_scatter_scene.py checks this id in a real build.
DIAL_SCALE = "obj-26"


def module_layer(g):
    """The module-only raw boxes and cords, added to the scene (see the module docstring)."""
    # the capture is the composite stage's second inlet (in2); its first inlet (the source) and third (the field)
    # come from the builder's own fanouts (inlet_fanout / mod_inlets in definition.py)
    g.wire("obj-909", 0, SHEETS, 1)

    # the builder's Scale dial is tapped at its outlet: scale -> `scale <v>` into the control entry.
    g.obj("obj-947", "prepend scale", 1, 1, [20, 20, 100, 22])
    g.wire(DIAL_SCALE, 0, "obj-947", 0)
    g.wire("obj-947", 0, CTRL, 0)


def raw_ui():
    """The module's raw layer: the scene (always enabled -- there is no other mode to gate against) and the one
    cord module_layer adds, to the builder's pix stage."""
    g = Graph()
    scene(g)
    module_layer(g)
    return {"raw_boxes": g.boxes, "raw_lines": g.lines, "raw_parameters": {}}


def main(argv):
    if "--standalone" in argv:
        out = REPO / "tests" / "bench" / "caustic_sheets_standalone.maxpat"
        data = standalone()
        out.write_text(json.dumps(data, indent=2))
        print(f"wrote {out.relative_to(REPO)} ({len(data['patcher']['boxes'])} boxes, {len(data['patcher']['lines'])} lines)")
    else:
        out = HERE / "raw_ui.json"
        data = raw_ui()
        out.write_text(json.dumps(data, indent=2))
        print(f"wrote {out.relative_to(REPO)} ({len(data['raw_boxes'])} raw boxes, {len(data['raw_lines'])} raw lines)")


if __name__ == "__main__":
    main(sys.argv[1:])
