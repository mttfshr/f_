"""test_weave_static.py -- static guard for the built f_weave patcher (what an offline run CAN verify).

Source-mode render trigger (2026-11-01): with nothing on the inlet, vs_inState does not make the jit.gl.pix draw (the
f_quasi bug, Matt live), so source mode has its own per-frame trigger: `r draw` -> [gate 1 1] -> pix inlet 0. The gate
starts open and vs_inState's connected flag closes it through [== 0], so a connected weave renders once per frame.

  1  `r draw` reaches the pix only through the gate (data inlet 1 -> outlet 0 -> pix inlet 0), never directly
  2  the gate starts open ("gate 1 1") and its control inlet 0 is fed by [== 0], fed by vs_inState outlet 1
  3  two outer inlets (across / along -> pix inlets 0 / 1), each vs_inState with its own connected flag; no vecfield inlet
  3b the three TAGGED modulation textures (mod_inlets "tag", 2026-11-01): no outer inlet, one `route weight_tex irreg_tex
     marklen_tex` fed by the scalar route's reject outlet, each tag -> its own vs_inState -> pix inlet 2 / 3 / 4, flag -> pix
  3c the codebox reads in1 .. in5 accordingly, and `offset` / the variant terms are what the docs say
  3d the params: offset (not regularity), variant a menu, mmode a Tex uni / Tex bi toggle, depth numboxes under their
     dials, no shape / regularity / field_amount / fix_blend
  3e the title bar: the Variant label hidden, no signal_type (both type dots the "neither" gray)
  4  the output follows the render size (render_dim, size_stages only): pix `@adapt 0 @dim ...`, `r dim` -> pix,
     loadbang -> `s trig_res`. Unconnected, the pix otherwise adapts to vs_black (1x1; inferred) and draws one pixel.

NOT covered offline: that a bang to an unconnected pix really draws, the unconnected output size, how the panel looks,
and that tagged textures modulate (Matt, live).

Run:  tests/run.sh -q tests/modules/weave/test_weave_static.py   (the built patcher must be current:
      build/py.sh build/build_patcher.py src/f_weave/definition.py)
"""
import json
import os
import re

from harness import check, run  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
TAGS = ("weight_tex", "irreg_tex", "marklen_tex")
FLAGS = ("src_weight", "src_irreg", "src_marklen")


def _patcher():
    d = json.load(open(os.path.join(REPO, "package", "patchers", "f_weave.maxpat")))["patcher"]
    boxes = {b["box"]["id"]: b["box"] for b in d["boxes"]}
    lines = [(tuple(l["patchline"]["source"]), tuple(l["patchline"]["destination"])) for l in d["lines"]]
    return boxes, lines


def _source():
    return open(os.path.join(REPO, "src", "f_weave", "definition.py")).read()


def _ids(boxes, text):
    return [i for i, b in boxes.items() if b.get("text", "") == text]


def _instate_for(boxes, lines, flag):
    """The vs_inState whose outlet 1 feeds `prepend param <flag>`."""
    pre = _ids(boxes, "prepend param " + flag)
    assert len(pre) == 1, (flag, pre)
    inst = [s[0] for s, d in lines if d[0] == pre[0] and s[1] == 1 and boxes[s[0]].get("text") == "vs_inState"]
    assert len(inst) == 1, (flag, inst)
    return inst[0]


def _pix(boxes):
    pix = [i for i, b in boxes.items() if b.get("text", "").startswith("jit.gl.pix")]
    assert len(pix) == 1, pix
    return pix[0]


def _control(boxes, varname):
    hit = [b for b in boxes.values() if b.get("varname") == varname and b.get("maxclass", "").startswith("live.")]
    assert len(hit) == 1, (varname, hit)
    return hit[0]


def _route_tokens(boxes):
    route = [b for b in boxes.values() if b.get("text", "").startswith("route density")]
    assert len(route) == 1, route
    return route[0]["text"].split()[1:]


def test_r_draw_reaches_the_pix_only_through_the_gate():
    boxes, lines = _patcher()
    pix, rdraw, gate = _pix(boxes), _ids(boxes, "r draw"), _ids(boxes, "gate 1 1")
    assert len(rdraw) == 1 and len(gate) == 1, (rdraw, gate)
    check("r draw -> gate data inlet 1", 0 if ((rdraw[0], 0), (gate[0], 1)) in lines else 1, 0)
    check("gate outlet 0 -> pix inlet 0", 0 if ((gate[0], 0), (pix, 0)) in lines else 1, 0)
    direct = [1 for s, d in lines if s[0] == rdraw[0] and d[0] == pix]
    check("no direct r draw -> pix cord (it would render twice when connected)", len(direct), 0)


def test_gate_starts_open_and_is_closed_by_the_connected_flag():
    boxes, lines = _patcher()
    gate, eq, inst = _ids(boxes, "gate 1 1"), _ids(boxes, "== 0"), [_instate_for(boxes, lines, "src_potential")]
    assert len(gate) == 1 and len(eq) == 1, (gate, eq)
    check("vs_inState outlet 1 -> [== 0] inlet 0", 0 if ((inst[0], 1), (eq[0], 0)) in lines else 1, 0)
    check("[== 0] -> gate control inlet 0", 0 if ((eq[0], 0), (gate[0], 0)) in lines else 1, 0)


def test_two_outer_inlets_each_with_its_own_flag():
    """Inlet 0 = across scalar, 1 = along scalar (pix inlets 0 / 1 = codebox in1 / in2); each has its own vs_inState and a
    connected flag (src_potential / src_along) back to the pix. The vecfield inlet is retired."""
    boxes, lines = _patcher()
    pix = _pix(boxes)
    for k, flag in enumerate(("src_potential", "src_along")):
        inst = _instate_for(boxes, lines, flag)
        pre = _ids(boxes, "prepend param " + flag)[0]
        check(f"vs_inState outlet 0 ({flag}) -> pix inlet {k}", 0 if ((inst, 0), (pix, k)) in lines else 1, 0)
        check(f"prepend param {flag} -> pix inlet 0", 0 if ((pre, 0), (pix, 0)) in lines else 1, 0)
    check("the old dual flag is gone (no prepend param src_mode)", len(_ids(boxes, "prepend param src_mode")), 0)
    inlets = [b.get("comment") for b in boxes.values() if b.get("maxclass") == "inlet"]
    check("two outer inlets (the tagged textures have none of their own)", len(inlets), 2)
    check("no src_field flag box (vecfield retired)", len(_ids(boxes, "prepend param src_field")), 0)


def test_tagged_modulation_textures_are_demuxed_from_the_scalar_routes_reject_outlet():
    boxes, lines = _patcher()
    pix = _pix(boxes)
    check("the pix has five inlets (control/across, along, three tagged)", boxes[pix]["numinlets"], 5)
    demux = _ids(boxes, "route " + " ".join(TAGS))
    assert len(demux) == 1, demux
    scalar = [i for i, b in boxes.items() if b.get("text", "").startswith("route density")][0]
    reject = boxes[scalar]["numoutlets"] - 1
    check("scalar route's reject outlet -> the tag demux", 0 if ((scalar, reject), (demux[0], 0)) in lines else 1, 0)
    check("the reject outlet is the one past the last token", reject, len(_route_tokens(boxes)))
    for k, (tag, flag) in enumerate(zip(TAGS, FLAGS)):
        inst = _instate_for(boxes, lines, flag)
        pre = _ids(boxes, "prepend param " + flag)[0]
        check(f"demux outlet {k} ({tag}) -> its vs_inState", 0 if ((demux[0], k), (inst, 0)) in lines else 1, 0)
        check(f"vs_inState ({tag}) -> pix inlet {k + 2}", 0 if ((inst, 0), (pix, k + 2)) in lines else 1, 0)
        check(f"connected flag {flag} -> prepend -> pix inlet 0",
              0 if ((inst, 1), (pre, 0)) in lines and ((pre, 0), (pix, 0)) in lines else 1, 0)
    y = lambda i: boxes[i]["patching_rect"][1]
    chain = [(scalar, demux[0])]
    for k, flag in enumerate(FLAGS):
        inst = _instate_for(boxes, lines, flag)
        chain += [(demux[0], inst), (inst, pix)]
    check("the tag strip's cords run downward in the edit view", len([1 for a, b in chain if y(b) < y(a)]), 0)


def test_codebox_reads_the_matching_inlets_and_terms():
    src = _source()
    for line in ("across_pot = sample(in1, norm).x;", "along = mix(along_rot, sample(in2, norm).x, src_along);",
                 "cs = cos(base_angle);", "sn = sin(base_angle);",
                 "tw = mix(sample(in3, norm).x, sample(in3, norm).x * 2.0 - 1.0, mmode);",
                 "ti = mix(sample(in4, norm).x, sample(in4, norm).x * 2.0 - 1.0, mmode);",
                 "tl = mix(sample(in5, norm).x, sample(in5, norm).x * 2.0 - 1.0, mmode);",
                 "weight_g  = clamp(weight  + src_weight  * weight_m  * tw, 0.0, 1.0);",
                 "irreg_g   = clamp(irreg   + src_irreg   * irreg_m   * ti, 0.0, 1.0);",
                 "marklen_g = clamp(marklen + src_marklen * marklen_m * tl, 0.0, 1.0);",
                 "line_hash = fract(sin(line_idx * 127.1) * 43758.5453) * clamp(offset, 0.0, 1.0);",
                 "mark = edge_across * edge_along;"):
        check("codebox has: " + line[:48], 0 if line in src else 1, 0)
    code = "\n".join(re.sub(r"//.*|#.*", "", l) for l in src.splitlines())          # the retirement is noted in comments
    for gone in ("field_amount", "fix_blend", "src_field", "Param regularity", "Param shape", "profile ="):
        check(f"no {gone} left in the definition's code", code.count(gone), 0)
    check("no src_mode left in the definition's code", code.count("src_mode"), 0)


def test_variant_terms_and_modulation_mode_do_what_the_docs_say():
    """Variant 0 must leave weight and marklen at their (modulated) dials: every irregularity term is multiplied by a
    variant weight that is 0 there. Evaluates the codebox's own lines."""
    src = _source()
    weights = {}
    for name in ("w_wob", "w_smooth", "w_hash"):
        m = re.search(rf"{name}\s*=\s*(.*);", src)
        assert m, name
        weights[name] = m.group(1)
    want = {0: (0, 0, 0), 1: (1, 0, 0), 2: (0, 1, 0), 3: (0, 0, 1), 4: (1, 1, 0)}      # Off Wobble Smooth Hashed Both
    for vi, exp in want.items():
        got = tuple(int(eval(weights[n], {"vi": vi})) for n in ("w_wob", "w_smooth", "w_hash"))
        check(f"variant {vi}: wobble / smooth / hashed weights", 0 if got == exp else 1, 0)
    check("mod_w is gated by the smooth and hashed weights",
          0 if "mod_w = sm_w * w_smooth + hs_w * w_hash;" in src else 1, 0)
    check("the wobble displacement is gated by the wobble weight",
          0 if "u = u0 + wob * irreg_g * 0.4 * w_wob;" in src else 1, 0)
    # mmode: 0 = raw 0..1, 1 = rescaled to -1..1 (mix(t, 2t-1, mmode))
    mix = lambda a, b, t: a + (b - a) * t
    for t in (0.0, 0.5, 1.0):
        check(f"mmode 0 reads t={t} raw", mix(t, t * 2 - 1, 0.0), t)
        check(f"mmode 1 reads t={t} as {t * 2 - 1}", mix(t, t * 2 - 1, 1.0), t * 2 - 1)


def test_params_and_controls():
    boxes, _ = _patcher()
    tokens = _route_tokens(boxes)
    check("route tokens are the shipped param list",
          0 if tokens == ["density", "angle", "weight", "marklen", "offset", "phase", "softness", "variant", "irreg",
                          "nscale", "weight_m", "irreg_m", "marklen_m", "mmode"] else 1, 0)
    for gone in ("regularity", "shape", "field_amount", "fix_blend"):
        check(f"no {gone} token on the route", tokens.count(gone), 0)
    menu = _control(boxes, "variant")
    check("variant is a menu of Off / Wobble / Smooth / Hashed / Both",
          0 if (menu["maxclass"] == "live.menu"
                and menu["saved_attribute_attributes"]["valueof"]["parameter_enum"]
                == ["Off", "Wobble", "Smooth", "Hashed", "Both"]) else 1, 0)
    tog = _control(boxes, "mmode")
    check("mmode is a two-state toggle reading Tex uni / Tex bi",
          0 if (tog["maxclass"] == "live.text" and (tog["text"], tog["texton"]) == ("Tex uni", "Tex bi")) else 1, 0)
    for depth, dial in (("weight_m", "weight"), ("marklen_m", "marklen"), ("irreg_m", "irreg")):
        nb, dl = _control(boxes, depth), _control(boxes, dial)
        check(f"{depth} is a numbox", 0 if nb["maxclass"] == "live.numbox" else 1, 0)
        centred = abs((nb["presentation_rect"][0] + nb["presentation_rect"][2] / 2)
                      - (dl["presentation_rect"][0] + dl["presentation_rect"][2] / 2)) < 0.01
        below = abs(nb["presentation_rect"][1] - (dl["presentation_rect"][1] + 42.0)) < 0.01
        check(f"{depth} sits directly under {dial}, centred", 0 if (centred and below) else 1, 0)


def test_title_bar_has_no_variant_label_and_no_vecfield_marker():
    boxes, _ = _patcher()
    lbl = [b for b in boxes.values() if b.get("varname") == "lbl_variant"]
    check("the Variant label is hidden", 0 if (len(lbl) == 1 and lbl[0].get("hidden") == 1) else 1, 0)
    check("no signal_type label box (the vecfield input is gone)", 0 if "obj-8" not in boxes else 1, 0)
    dots = [boxes["obj-19f"], boxes["obj-19g"]]
    check("both type dots are the same 'neither' gray", 0 if dots[0]["bgcolor"] == dots[1]["bgcolor"] else 1, 0)
    check("the dots say no vecfield or tensor",
          0 if all("no vecfield or tensor" in d["hint"] for d in dots) else 1, 0)
    for varname in ("variant", "mmode"):
        c = _control(boxes, varname)
        check(f"{varname} is in the title bar (y < 21)", 0 if c["presentation_rect"][1] < 21.0 else 1, 0)


def test_output_follows_the_render_size():
    boxes, lines = _patcher()
    pix = _pix(boxes)
    text = boxes[pix]["text"]
    check("pix is @adapt 0 (the size is set, not adapted to vs_black's 1x1)", 0 if "@adapt 0" in text else 1, 0)
    check("pix has an explicit @dim", 0 if "@dim " in text else 1, 0)
    rdim = _ids(boxes, "r dim")
    assert len(rdim) == 1, rdim
    check("r dim -> pix inlet 0", 0 if ((rdim[0], 0), (pix, 0)) in lines else 1, 0)
    trig = _ids(boxes, "s trig_res")
    check("loadbang -> s trig_res (Vsynth re-sends the size)", 0 if trig and any(d[0] == trig[0] for _, d in lines) else 1, 0)


def test_density_curve_and_mark_ranges():
    """2026-11-01: density tops out at 64 cells across (was 16) with the low end untouched; weight / marklen reach 1.0."""
    src = _source()
    m = re.search(r"density_scale = pow\(2\.0, (.*)\);", src)
    assert m, "density_scale line not found"
    curve = lambda density: 2.0 ** eval(m.group(1).replace("max(", "max(").replace("density", repr(density)))
    check("density 0.0 unchanged (0.5 cells)", curve(0.0), 0.5)
    check("density 0.5 unchanged (default, 2^1.5 cells)", curve(0.5), 2.0 ** 1.5)
    check("density 1.0 -> 64 cells", curve(1.0), 64.0)
    d = json.load(open(os.path.join(REPO, "package", "patchers", "f_weave.maxpat")))["patcher"]
    text = json.dumps(d)
    check("built patcher carries the new curve", 0 if "4.0 * max(density - 0.5, 0.0)" in text else 1, 0)


def test_softness_zero_is_crisp_one_is_the_old_softness_one():
    """2026-11-01: feather = [w*max(1-s,0), w*(1+s)], min band aa. Mirrors the codebox lines (smoothstep reversed edges).
    The mark extents are the effective weight / marklen (weight_e / marklen_e: the dials plus modulation)."""
    src = _source()
    for line in ("aa = 0.01;", "inner_across = min(weight_e * max(1.0 - softness, 0.0), outer_across - aa);",
                 "inner_along  = min(marklen_e * max(1.0 - softness, 0.0), outer_along - aa);",
                 "edge_across = smoothstep(outer_across, inner_across, dist_to_line);",
                 "edge_along  = smoothstep(outer_along,  inner_along,  dist_to_mark);"):
        check("codebox has: " + line[:40], 0 if line in src else 1, 0)

    def sm(e0, e1, x):
        t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
        return t * t * (3 - 2 * t)

    def edge(w, s, d, aa=0.01):
        outer = w + s * w
        inner = min(w * max(1.0 - s, 0.0), outer - aa)
        return sm(outer, inner, d)

    w = 0.2
    check("s=0: full inside the edge (d=0.15)", edge(w, 0.0, 0.15), 1.0)
    check("s=0: zero outside the edge (d=0.21)", edge(w, 0.0, 0.21), 0.0)
    for d in (0.0, 0.05, 0.15, 0.3, 0.39):
        old = sm(w * 2.0, 0.0, d)          # the pre-change formula at softness 1: smoothstep(w + 1*w, 0, d)
        check(f"s=1 equals the old softness-1 falloff at d={d}", edge(w, 1.0, d), old)
    for d in (0.0, 0.1, 0.3):
        check(f"s=2 equals the old softness-2 falloff at d={d}", edge(w, 2.0, d), sm(w * 3.0, 0.0, d))


if __name__ == "__main__":
    import sys
    sys.exit(run(globals()))
