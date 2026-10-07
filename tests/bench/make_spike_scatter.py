"""
make_spike_scatter.py -- generate tests/bench/spike_scatter.maxpat, the bpatcher for the scatter
feasibility spike (ideas/optics_map.md, "Findings: caustic fidelity"; ideas/f_lumia.md).

Not a shipped module and not part of the regression bench: it is loaded by tests/spike_scatter.py
through the module bench's wrapper mechanism, inside Vsynth's real vs_render context.

Structure follows Vsynth's own vs_xyz_disp.maxpat (a jit.gl.node capture holding a mesh drawn with a
vertex-texture-fetch shader, textures adapted through jit.gl.slab @rectangle 0), with three changes:
the node captures float32, the drawable is a point grid with additive blending, and the shader
(spike_scatter.jxs) lands each point at u + d*F(u).

  inlet 0   control messages + source texture   (d, weight, psize, n, bypass; jit_gl_texture)
  inlet 1   f_vecfield texture
  outlet 0  the node's captured float32 texture

Run:  python3 tests/bench/make_spike_scatter.py
"""
import json
import sys
from pathlib import Path

from patchbuild import APPVERSION, Patch, patcher_dict

HERE = Path(__file__).resolve().parent
CHAIN = "--chain" in sys.argv       # variant for the frame-lag test (spike S3b): see the end of the file
TONEV = "--tone" in sys.argv        # variant for the display-stage test (spike S10): see the end of the file
OUT = HERE / ("spike_scatter_chain.maxpat" if CHAIN else "spike_scatter_tone.maxpat" if TONEV else "spike_scatter.maxpat")

p = Patch()
obj, wire = p.obj, p.wire
boxes, lines = p.boxes, p.lines

NODE = "#0.node"
SHADER = "#0.sc"
R = 256          # capture size; the runner assumes this
N0 = 256         # initial grid size per axis; the `n` message changes it


def port(oid, maxclass, rect):
    b = {"id": oid, "maxclass": maxclass, "patching_rect": [float(v) for v in rect]}
    if maxclass == "inlet":
        b.update({"numinlets": 0, "numoutlets": 1, "outlettype": [""]})
    else:
        b.update({"numinlets": 1, "numoutlets": 0})
    boxes.append({"box": b})


def message(oid, text, rect):
    boxes.append({"box": {"id": oid, "maxclass": "message", "text": text, "numinlets": 2,
                          "numoutlets": 1, "outlettype": [""], "patching_rect": [float(v) for v in rect]}})


port("in0", "inlet", [20, 20, 30, 22])
port("in1", "inlet", [400, 20, 30, 22])
port("out0", "outlet", [620, 520, 30, 22])

# control messages out of inlet 0; the reject outlet carries everything else (the texture message)
obj("rt", "route d weight psize n fy r bypass k h snap jit latn taps", 1, 14, [20, 60, 540, 22])
wire("in0", 0, "rt", 0)

# texture adapters: normalised 2D float32, as in vs_xyz_disp (a vertex program wants sampler2D)
obj("slabS", "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32", 1, 2, [20, 110, 300, 22],
    ["jit_gl_texture", ""])
obj("slabF", "jit.gl.slab vsynth @inputs 1 @rectangle 0 @type float32", 1, 2, [400, 110, 300, 22],
    ["jit_gl_texture", ""])
wire("rt", 13, "slabS", 0)
if not CHAIN:
    wire("in1", 0, "slabF", 0)

# slab output names -> `texture <src> <field>` on the drawable (tex0 = source, tex1 = field)
obj("rtS", "route out_name", 1, 2, [20, 160, 100, 22])
obj("rtF", "route out_name", 1, 2, [400, 160, 100, 22])
obj("join", "join", 2, 1, [20, 200, 60, 22])
obj("prepTex", "prepend texture", 1, 1, [20, 240, 110, 22])
wire("slabS", 1, "rtS", 0)
wire("slabF", 1, "rtF", 0)
wire("rtS", 0, "join", 0)
wire("rtF", 0, "join", 1)
wire("join", 0, "prepTex", 0)

# ask both slabs for their names every frame (cheap) so `texture` is always current
obj("rdraw", "r draw", 0, 1, [180, 60, 50, 22])
message("getname", "getout_name", [180, 90, 90, 22])
wire("rdraw", 0, "getname", 0)
wire("getname", 0, "slabS", 0)
wire("getname", 0, "slabF", 0)

# scene: node capture + point grid + shader
obj("node", f"jit.gl.node vsynth @capture 1 @name {NODE} @type float32 @adapt 0 @dim {R} {R} "
            "@erase_color 0 0 0 0", 1, 3, [400, 300, 330, 22], ["jit_gl_texture", "", ""])
obj("shader", f"jit.gl.shader vsynth @name {SHADER} @file spike_scatter.jxs", 1, 2, [20, 300, 270, 22])
# the lattice: gridshape as a MATRIX source (as in Max's own gridshape help), drawn by a mesh in
# points mode so each cell is exactly one vertex. (gridshape's own @poly_mode 2 2 drew every vertex
# once per adjoining triangle: multiplicity ~6, not 1 -- spike S1.)
obj("grid", f"jit.gl.gridshape vsynth @shape plane @dim {N0} {N0} @matrixoutput 1 @automatic 0",
    1, 2, [20, 400, 400, 22], ["jit_matrix", ""])
obj("mesh", f"jit.gl.mesh {NODE} @draw_mode points @shader {SHADER} @blend_enable 1 @blend_mode 1 1 "
            "@depth_enable 0 @point_size 3 @color 1 1 1 1 @lighting_enable 0", 1, 2,
    [20, 440, 560, 22], ["", ""])
obj("lb", "loadbang", 0, 1, [440, 360, 60, 22], ["bang"])
message("firstbang", "bang", [440, 390, 40, 22])
wire("lb", 0, "firstbang", 0)
wire("firstbang", 0, "grid", 0)
wire("grid", 0, "mesh", 0)
wire("prepTex", 0, "mesh", 0)
wire("node", 0, "out0", 0)

# parameters: d, weight -> shader params; psize -> point_size; n -> dim n n then re-emit the matrix
obj("prepD", "prepend param d", 1, 1, [20, 350, 110, 22])
obj("prepW", "prepend param weight", 1, 1, [140, 350, 140, 22])
obj("prepP", "prepend point_size", 1, 1, [290, 350, 120, 22])
obj("prepY", "prepend param fy", 1, 1, [560, 350, 110, 22])
message("dimn", "dim $1 $1, bang", [420, 320, 110, 22])
obj("prepR", "prepend param res", 1, 1, [680, 350, 110, 22])
message("dimr", "dim $1 $1", [680, 320, 70, 22])
wire("rt", 0, "prepD", 0)
wire("rt", 1, "prepW", 0)
wire("rt", 2, "prepP", 0)
wire("rt", 3, "dimn", 0)
wire("rt", 4, "prepY", 0)
wire("rt", 5, "prepR", 0)
wire("rt", 5, "dimr", 0)
wire("prepR", 0, "shader", 0)
wire("dimr", 0, "node", 0)
wire("prepD", 0, "shader", 0)
wire("prepW", 0, "shader", 0)
wire("prepY", 0, "shader", 0)
wire("prepP", 0, "mesh", 0)
wire("dimn", 0, "grid", 0)

# h: half-width (px) of the splat's tent kernel, a shader uniform (default 1.0 = the original tent)
obj("prepH", "prepend param h", 1, 1, [800, 350, 110, 22])
wire("rt", 8, "prepH", 0)
wire("prepH", 0, "shader", 0)

# snap (spike S5): 1 = the vertex shader snaps each point to its nearest pixel CORNER (the fragment
# shader still weights by the unsnapped position), so a size-2 point covers exactly the four pixels
# the tent can reach, instead of a size-3 point's ~9. `k` (a K-meshes load multiplier, spike S4) was
# tried and removed: its period measurements were not linear in K (tests/spike_scatter.py, S4 notes).
obj("prepSn", "prepend param snap", 1, 1, [920, 350, 110, 22])
wire("rt", 9, "prepSn", 0)
wire("prepSn", 0, "shader", 0)

# jit (spike S8): lattice jitter, in cells (0 = regular lattice, 1 = a full cell); latn: the lattice size
# n, which the vertex shader needs to recover each point's index (hash input) and the cell size.
obj("prepJ", "prepend param jit", 1, 1, [1040, 350, 110, 22])
obj("prepLn", "prepend param latn", 1, 1, [1160, 350, 110, 22])
wire("rt", 10, "prepJ", 0)
wire("rt", 11, "prepLn", 0)
wire("prepJ", 0, "shader", 0)
wire("prepLn", 0, "shader", 0)

# taps (spike S9): 1 = one bilinear source read at the lattice point; 4 = a 4-tap box prefilter at
# +-1/4 cell, against source aliasing when the lattice is coarser than the source.
obj("prepTp", "prepend param taps", 1, 1, [1280, 350, 110, 22])
wire("rt", 12, "prepTp", 0)
wire("prepTp", 0, "shader", 0)

p.comment("note", "scatter spike: see tests/spike_scatter.py. d weight psize n via inlet 0; "
                  "inlet 0 texture = source, inlet 1 = f_vecfield.", [20, 460, 560, 20])


def pix_box(oid, code, rect, attrs="@type float32"):
    """An inline jit.gl.pix with a one-codebox gen patcher (the structure build_patcher.py writes)."""
    def sub_box(i, **kw):
        kw.update({"id": f"gen-obj-{i}", "patching_rect": [30.0, 30.0 + 60 * i, 200.0, 22.0]})
        return {"box": kw}
    sub = {"fileversion": 1, "appversion": dict(APPVERSION), "classnamespace": "jit.gen",
           "rect": [100.0, 100.0, 500.0, 300.0],
           "boxes": [sub_box(1, maxclass="newobj", numinlets=0, numoutlets=1, outlettype=[""], text="in 1"),
                     sub_box(2, maxclass="codebox", code=code, numinlets=1, numoutlets=1, outlettype=[""],
                             fontname="<Monospaced>", fontsize=12.0),
                     sub_box(3, maxclass="newobj", numinlets=1, numoutlets=0, text="out 1")],
           "lines": [{"patchline": {"source": ["gen-obj-1", 0], "destination": ["gen-obj-2", 0]}},
                     {"patchline": {"source": ["gen-obj-2", 0], "destination": ["gen-obj-3", 0]}}]}
    boxes.append({"box": {"id": oid, "maxclass": "newobj", "text": f"jit.gl.pix vsynth {attrs}",
                          "numinlets": 1, "numoutlets": 2, "outlettype": ["jit_gl_texture", ""],
                          "patching_rect": [float(v) for v in rect], "patcher": sub}})


if CHAIN:
    # Frame-lag test (spike S3b). An upstream pix encodes a free-running frame counter c (0..39) into a
    # uniform field, F.x = 0.0125 * c; the scatter's own output shifts by d*F.x, so its mean decodes back
    # to the counter value of the field it actually used. outlet 1 = that upstream pix, outlet 2 = a plain
    # pix -> pix reference (documented to have no lag). Comparing the three counters in ONE capture gives
    # the relative lag, in frames, of node -> mesh -> capture.
    pix_box("upix", "Param shift(0.0);\n"
                    "out1 = vec(0.5 + shift * 0.5 + in1.x * 0.0, 0.5, 0.5, 1.0);", [400, 70, 200, 22])
    pix_box("refpix", "out1 = in1;", [700, 150, 120, 22])
    port("out1", "outlet", [660, 520, 30, 22])
    port("out2", "outlet", [700, 520, 30, 22])
    obj("cnt", "counter 0 39", 4, 4, [180, 20, 90, 22], ["int", "", "", "int"])
    obj("mulc", "* 0.0125", 2, 1, [180, 45, 70, 22])
    obj("prepS", "prepend param shift", 1, 1, [260, 45, 130, 22])
    wire("rdraw", 0, "cnt", 0)
    wire("cnt", 0, "mulc", 0)
    wire("mulc", 0, "prepS", 0)
    wire("prepS", 0, "upix", 0)
    wire("in1", 0, "upix", 0)
    wire("upix", 0, "slabF", 0)
    wire("upix", 0, "out1", 0)
    wire("upix", 0, "refpix", 0)
    wire("refpix", 0, "out2", 0)

if TONEV:
    # Display-stage test (spike S10): the tone-map + upscale stage of scratch/build_scatter_look.py, fed by the
    # node's captured texture. outlet 1 = the stage with the LIVE patch's attributes (@adapt 0 @dim 1920 1080),
    # outlet 2 = the same code with default attributes. outlet 0 (the raw capture) is unchanged.
    TONE_CODE = ("tm(v, ex) {\n"                      # function definitions must PRECEDE all statements,
                 "\tt = v / (1.0 + v);\n"             # and a Param declaration is a statement
                 "\treturn pow(t, ex);\n"
                 "}\n"
                 "Param lev(1.0);\n"
                 "Param expo(0.7);\n"
                 "r = tm(sample(in1, norm).x * lev, expo);\n"
                 "g = tm(sample(in1, norm).y * lev, expo);\n"
                 "b = tm(sample(in1, norm).z * lev, expo);\n"
                 "out1 = vec(r, g, b, 1.0);\n")
    pix_box("tone", TONE_CODE, [700, 440, 300, 22], "@type float32 @adapt 0 @dim 1920 1080")
    pix_box("tone2", TONE_CODE, [700, 480, 300, 22], "@type float32")
    port("out1", "outlet", [660, 560, 30, 22])
    port("out2", "outlet", [700, 560, 30, 22])
    wire("node", 0, "tone", 0)
    wire("node", 0, "tone2", 0)
    wire("tone", 0, "out1", 0)
    wire("tone2", 0, "out2", 0)

if __name__ == "__main__":
    with open(OUT, "w") as f:
        json.dump(patcher_dict(boxes, lines, rect=(100.0, 100.0, 760.0, 560.0)), f, indent=2)
    print(f"wrote {OUT.name} ({len(boxes)} boxes, {len(lines)} lines)")
