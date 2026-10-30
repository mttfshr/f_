"""
test_render_dim.py -- the `render_dim` definition key (2026-10-29) and the static guard behind it.

WHY: `dim` reads 1 inside a live Vsynth jit.gl.pix, regardless of @adapt/@type (tensormap T012, probe
2026-10-16), so a codebox that reads `dim` computes with a 1 x 1 frame (f_tf_hatch's E2 pinned every march
step to the frame centre and never followed the tensor).  Vsynth broadcasts `dim W H`; a module takes it
with `r dim` -> `route dim` -> `unpack` -> `prepend param <name>` and asks for it at load with
`loadbang -> s trig_res`.  `render_dim` generates that chain (build_patcher.build_render_dim).

  - the builder output on a small synthetic definition: boxes, cords, ids
  - every misuse is loud
  - the key changes nothing when absent
  - STATIC: a module whose codebox reads `dim` must declare render_dim, or be on the explicit exemption
    list below (known latent bug, one reason each).  An exemption that no longer applies fails too, so
    the list can only shrink.

    tests/run.sh tests/build/test_render_dim.py -q
"""
import paths as _paths
import copy
import glob
import os
import re
import sys
import tempfile
from pathlib import Path

ROOT = _paths.REPO
import build_patcher as bp          # noqa: E402

from harness import check, run      # noqa: E402

TMP = Path(tempfile.mkdtemp(prefix="f_render_dim_"))
(TMP / "g.gen").write_text("Param width(640.0);\nParam height(480.0);\nParam ow(64.0);\nParam oh(64.0);\nParam bypass_gate(0.0);\nout1 = in1;\n")


def _eq(label, got, want):
    check(label, 0 if got == want else 1, 0)


def raises(fn, needle):
    try:
        fn()
    except ValueError as e:
        return needle in str(e)
    return False


def chain_defn(**extra):
    """Three stages e1 -> e2 -> e3 (primary), the first two `@adapt 0`; width/height internal params."""
    d = {"name": "f_t", "prefix": "t", "title": "Test", "signal_type": "texture",
         "archetype": "processor", "presentation_width": 160, "presentation_height": 90,
         "_def_path": str(TMP / "definition.py"),
         "outlets": [{"comment": "out"}],
         "pix_chain": [
             {"id": "e1", "name": "#0_t_e1", "gen": "g.gen", "n_inlets": 1, "n_outlets": 1,
              "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
             {"id": "e2", "name": "#0_t_e2", "gen": "g.gen", "n_inlets": 1, "n_outlets": 1,
              "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": False},
             {"id": "e3", "name": "#0_t_e3", "gen": "g.gen", "n_inlets": 1, "n_outlets": 1,
              "pix_attrs": "@adapt 0 @dim 256 256 @type float32", "primary": True}],
         "pix_wires": [["e1", 0, "e2", 0], ["e2", 0, "e3", 0]],
         "params": [
             {"name": "width", "type": "internal"},
             {"name": "height", "type": "internal"},
             {"name": "bypass", "type": "bypass"}]}
    d.update(extra)
    return d


RD = {"width_param": "width", "height_param": "height", "param_stages": ["e2"],
      "size_stages": ["e1", "e2", "e3"]}


def top_and_cords(defn):
    p = bp.build(defn)["patcher"]
    top = {b["box"]["id"]: b["box"] for b in p["boxes"]}
    cords = {(tuple(ln["patchline"]["source"]), tuple(ln["patchline"]["destination"])) for ln in p["lines"]}
    return top, cords


def pix_id(top, name):
    return [i for i, b in top.items() if str(b.get("text", "")).startswith("jit.gl.pix") and f"@name {name}" in b["text"]][0]


def test_render_dim_generates_the_vsynth_chain():
    top, cords = top_and_cords(chain_defn(render_dim=RD))
    ids = {b.get("text"): i for i, b in top.items() if str(i).startswith("obj-rd-")}
    _eq("the generated boxes are exactly the seven of the chain",
        sorted(ids), sorted(["r dim", "route dim", "unpack i i", "prepend param width", "prepend param height",
                             "loadbang", "s trig_res"]))
    e1, e2, e3 = (pix_id(top, n) for n in ("#0_t_e1", "#0_t_e2", "#0_t_e3"))
    rd, route, unpack = ids["r dim"], ids["route dim"], ids["unpack i i"]
    pw, ph = ids["prepend param width"], ids["prepend param height"]
    _eq("r dim -> inlet 0 of every size stage (their output follows the render size)",
        all(((rd, 0), (o, 0)) in cords for o in (e1, e2, e3)), True)
    _eq("r dim -> route dim -> unpack", ((rd, 0), (route, 0)) in cords and ((route, 0), (unpack, 0)) in cords, True)
    _eq("unpack left -> width, right -> height",
        ((unpack, 0), (pw, 0)) in cords and ((unpack, 1), (ph, 0)) in cords, True)
    _eq("both prepends reach the param stage e2 only",
        [((pw, 0), (e2, 0)) in cords, ((ph, 0), (e2, 0)) in cords, ((pw, 0), (e1, 0)) in cords, ((ph, 0), (e3, 0)) in cords],
        [True, True, False, False])
    _eq("loadbang -> s trig_res (ask Vsynth for the current size at load)",
        ((ids["loadbang"], 0), (ids["s trig_res"], 0)) in cords, True)
    _eq("the unpack is integers", top[unpack].get("outlettype"), ["int", "int"])


def test_each_group_is_optional_and_primary_is_an_alias():
    top, cords = top_and_cords(chain_defn(render_dim={"size_stages": ["e1"]}))
    texts = sorted(b.get("text") for i, b in top.items() if str(i).startswith("obj-rd-"))
    _eq("size_stages alone: no route/unpack/prepend", texts, ["loadbang", "r dim", "s trig_res"])
    top, cords = top_and_cords(chain_defn(render_dim={"width_param": "width", "height_param": "height",
                                                      "param_stages": ["primary"]}))
    e3 = pix_id(top, "#0_t_e3")
    pw = [i for i, b in top.items() if b.get("text") == "prepend param width"][0]
    _eq("param_stages alone, 'primary' = the primary pix; no r dim -> pix cord",
        [((pw, 0), (e3, 0)) in cords, any(s[0] == [i for i, b in top.items() if b.get("text") == "r dim"][0] and d[0] == e3
                                          for s, d in cords)], [True, False])


def test_render_dim_is_loud():
    def mk(**rd_patch):
        d = chain_defn(render_dim=dict(RD, **rd_patch))
        return lambda: bp.build(d)
    _eq("an unknown key", raises(mk(sizes=["e1"]), "unknown key"), True)
    _eq("width without height", raises(lambda: bp.build(chain_defn(render_dim={"width_param": "width", "param_stages": ["e2"]})),
                                       "go together"), True)
    _eq("params without stages", raises(lambda: bp.build(chain_defn(render_dim={"width_param": "width", "height_param": "height"})),
                                        "need param_stages"), True)
    _eq("the same name twice", raises(mk(height_param="width"), "must differ"), True)
    _eq("empty", raises(lambda: bp.build(chain_defn(render_dim={})), "declare param_stages"), True)
    _eq("an unknown node", raises(mk(param_stages=["nope"]), "unknown node"), True)
    _eq("a repeated node", raises(mk(size_stages=["e1", "e1"]), "distinct node ids"), True)
    d = chain_defn(render_dim=RD)
    d["params"][0] = {"name": "width", "type": "float", "min": 64.0, "max": 8192.0, "default": 640.0,
                      "label": "W", "hint": "w"}
    _eq("a param that is not internal (it must not be a control)", raises(lambda: bp.build(d), "type 'internal'"), True)
    d = chain_defn(render_dim=RD)
    d["params"] = [p for p in d["params"] if p["name"] != "height"]
    _eq("a param that is not declared", raises(lambda: bp.build(d), "type 'internal'"), True)
    d = chain_defn(render_dim=RD)
    d["pix_chain"][0]["pix_attrs"] = "@adapt 1 @type float32"
    _eq("a size stage that is not @adapt 0 (the dim message would be ignored)",
        raises(lambda: bp.build(d), "must set pix_attrs with '@adapt 0'"), True)


def test_the_key_changes_nothing_when_absent():
    _eq("building twice without the key gives the same patcher", bp.build(chain_defn()), bp.build(chain_defn()))
    top, _ = top_and_cords(chain_defn())
    _eq("no obj-rd boxes without the key", [i for i in top if str(i).startswith("obj-rd-")], [])


# ---- `downsample` (2026-10-30): f_tf_hatch's texture pre-stage, a separable box downsample by an integer factor

DS = {"factor": 4, "width_param": "ow", "height_param": "oh", "h_stage": "ph", "v_stage": "pv"}


def ds_defn(ds=DS, rd=None):
    d = chain_defn(render_dim=dict(RD if rd is None else rd, downsample=ds) if ds is not None else RD)
    d["pix_chain"] += [{"id": i, "name": f"#0_t_{i}", "gen": "g.gen", "n_inlets": 1, "n_outlets": 1,
                        "pix_attrs": "@adapt 0 @dim 64 64 @type float32", "primary": False} for i in ("ph", "pv")]
    d["pix_wires"] = d["pix_wires"] + [["ph", 0, "pv", 0]]
    d["params"] = d["params"] + [{"name": "ow", "type": "internal"}, {"name": "oh", "type": "internal"}]
    return d


def test_downsample_generates_the_divide_and_the_two_stage_messages():
    top, cords = top_and_cords(ds_defn())
    ph, pv = pix_id(top, "#0_t_ph"), pix_id(top, "#0_t_pv")
    txt = lambda i: top[f"obj-rd-{i}"].get("text")
    _eq("the eight downsample boxes", [txt(i) for i in range(10, 18)],
        ["expr max(1\\, $i1/4)", "expr max(1\\, $i1/4)", "prepend param ow", "prepend param oh",
         "pack 0 0", "prepend dim", "pack 0 0", "prepend dim"])
    c = lambda a, ao, b, bi: ((a if a.startswith("obj-") else f"obj-rd-{a}", ao), (b if b.startswith("obj-") else f"obj-rd-{b}", bi)) in cords
    _eq("unpack: width (left) -> the ow expr, height (right) -> the oh expr and the H stage's pack (cold inlet)",
        [c("2", 0, "10", 0), c("2", 1, "11", 0), c("2", 1, "14", 1)], [True] * 3)
    _eq("ow feeds its Param and BOTH packs' hot left inlets; oh feeds its Param and the V stage's pack (cold inlet)",
        [c("10", 0, "12", 0), c("10", 0, "14", 0), c("10", 0, "16", 0), c("11", 0, "13", 0), c("11", 0, "16", 1)], [True] * 5)
    _eq("params: ow reaches the H stage only, oh the V stage only",
        [c("12", 0, ph, 0), c("13", 0, pv, 0), c("12", 0, pv, 0), c("13", 0, ph, 0)], [True, True, False, False])
    _eq("dim messages: H stage gets (ow, H), V stage gets (ow, oh)",
        [c("14", 0, "15", 0), c("15", 0, ph, 0), c("16", 0, "17", 0), c("17", 0, pv, 0), c("15", 0, pv, 0), c("17", 0, ph, 0)],
        [True, True, True, True, False, False])
    _eq("the downsample stages are not in size_stages: `r dim` does not size them to the full render",
        [c("0", 0, ph, 0), c("0", 0, pv, 0)], [False, False])


def test_downsample_works_alone_and_the_factor_is_in_the_expr():
    d = ds_defn()
    d["render_dim"] = {"downsample": dict(DS, factor=8)}
    top, _ = top_and_cords(d)
    _eq("downsample alone builds; its factor is the expr's divisor", top["obj-rd-10"].get("text"), "expr max(1\\, $i1/8)")
    _eq("without width_param there is no `prepend param width` / `height`",
        [b.get("text") for b in top.values() if str(b.get("text", "")) in ("prepend param width", "prepend param height")], [])


def test_downsample_is_loud():
    def bad(needle, ds=None, mutate=None):
        d = ds_defn(DS if ds is None else ds)
        if mutate:
            mutate(d)
        return raises(lambda: bp.build(d), needle)
    _eq("a missing key", bad("exactly the keys", ds={k: v for k, v in DS.items() if k != "v_stage"}), True)
    _eq("an extra key", bad("exactly the keys", ds=dict(DS, extra=1)), True)
    _eq("factor 1", bad("integer >= 2", ds=dict(DS, factor=1)), True)
    _eq("factor not an int", bad("integer >= 2", ds=dict(DS, factor=4.0)), True)
    _eq("the same param twice", bad("must differ", ds=dict(DS, height_param="ow")), True)
    _eq("a param that is not declared internal", bad("type 'internal'", mutate=lambda d: d["params"].pop(-1)), True)
    _eq("an unknown stage", bad("unknown node", ds=dict(DS, v_stage="nope")), True)
    _eq("both passes on one node", bad("different nodes", ds=dict(DS, v_stage="ph")), True)
    _eq("a stage that is not @adapt 0", bad("must set pix_attrs with '@adapt 0'",
                                            mutate=lambda d: d["pix_chain"][-1].update(pix_attrs="@adapt 1 @type float32")), True)


# ---- param_stages as a dict: each Param only to the stages that declare it (f_tf_tensormap's blur passes read one axis)

def test_param_stages_dict_targets_each_param_separately():
    d = chain_defn(render_dim=dict(RD, param_stages={"width": ["e1"], "height": ["e3"]}))
    top, cords = top_and_cords(d)
    prim, e3 = pix_id(top, "#0_t_e1"), pix_id(top, "#0_t_e3")
    c = lambda a, ao, b, bi: ((a, ao), (b, bi)) in cords
    _eq("prepend param width reaches only the width stage; height only the height stage",
        [c("obj-rd-3", 0, prim, 0), c("obj-rd-3", 0, e3, 0), c("obj-rd-4", 0, e3, 0), c("obj-rd-4", 0, prim, 0)],
        [True, False, True, False])


def test_param_stages_dict_is_loud():
    for bad, needle in (({"width": ["primary"]}, "exactly the keys"),
                        ({"width": ["primary"], "height": ["nope"]}, "unknown node"),
                        ({"width": [], "height": ["primary"]}, "non-empty list")):
        d = chain_defn(render_dim=dict(RD, param_stages=bad))
        _eq(f"param_stages {bad}", raises(lambda: bp.build(d), needle), True)


# ---- STATIC: a codebox that reads `dim` must be given the render size another way

# Modules whose code reads `dim` today and declare nothing: the latent bug (`dim` reads 1 live), found
# 2026-10-29.  Each needs a live look and then a fix; remove the line when it is fixed.  f_masonry, f_grain
# and f_vf_seeds are on the never-regenerate list (hand edit only); the others build from a definition.
EXEMPT = {
    "f_cmap": "20 reads, pixel maths (tx = ux * dim.x - 0.5): the likeliest to be visibly wrong",
    "f_grain": "aspect from dim; predates the build system, never regenerate",
    "f_masonry": "aspect from dim in every phase; never regenerate",
    "f_quasi": "aspect from dim",
    "f_vf_seeds": "aspect from dim; never regenerate",
    "f_vf_vorticity": "dim in the inline codebox",
}


def _strip(code):
    return "\n".join(re.sub(r"//.*", "", ln) for ln in code.splitlines())


def _reads_dim(mod_dir):
    texts = [open(g).read() for g in glob.glob(os.path.join(mod_dir, "*.gen"))]
    dp = os.path.join(mod_dir, "definition.py")
    declared = False
    if os.path.exists(dp):
        defn = bp.load_definition(dp)
        declared = "render_dim" in defn
        if isinstance(defn.get("codebox"), str):
            texts.append(defn["codebox"])
    return any(re.search(r"\bdim\b", _strip(t)) for t in texts), declared


def test_static_a_module_that_reads_dim_declares_render_dim():
    bad, stale, n_read = [], [], 0
    for d in sorted(glob.glob(str(ROOT / "src" / "*" / ""))):
        mod = os.path.basename(d.rstrip("/"))
        reads, declared = _reads_dim(d)
        n_read += reads
        if reads and not declared and mod not in EXEMPT:
            bad.append(mod)
        if mod in EXEMPT and not (reads and not declared):
            stale.append(mod)
    print(f"    modules reading dim: {n_read}; on the exemption list: {len(EXEMPT)}")
    _eq("no module reads `dim` without render_dim or an exemption (a new one would need render_dim)", bad, [])
    _eq("every exemption is still true (reads dim, declares nothing): a fixed module comes off the list", stale, [])


if __name__ == "__main__":
    sys.exit(run(globals()))
