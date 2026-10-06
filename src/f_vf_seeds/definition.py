"""
f_vf_seeds -- definition.py

The full definition of the module: build/build_patcher.py builds the shipped patcher from it
(build_cleanup T019, 2026-10-06; until then src/f_vf_seeds/build_seeds_multistage.py did, because the
generic schema could not express a six-stage chain whose params fan out to several differently named
pix objects).  The keys that made it expressible (build/spec.md, "Multi-stage keys"; each default-off
and loud, tests/test_build_seeds_keys.py): pix_chain `gen_code`, per-param `pix_shared_attrui`,
`pix_attr` and `range_menu_outlet`, native `bypass_target`, `outlet_source`, and `fanout` /
`state_nodes` on mod_inlets; earlier ones: `pix_target` lists, `inlet_fanout`, `legacy`.
This file also feeds the docs/helpfile/param-extraction tooling (build/extract_params.py) and the
bench's archetype lookup.  The shipped patcher is on the never-regenerate list: this definition exists
so drift can be checked (`build/py.sh build/drift.py -v f_vf_seeds`) and the module is recorded.

Placement and orientation engine for discrete marks. Stable seed points distributed across the frame,
each rendered by sampling an external shape texture in seed-local UV space, oriented by the vecfield
sampled at that seed's position.

Architecture (Evolution 2, 2026-07-04 -- six-stage jit.gl.pix chain):
  Stage 1a/1b -- 9-candidate search + top-2 select, one shared codebox template
                (codebox_seeds_search.gen) rendered with baked hash-salt constants that distinguish the two
                (not live params -- decorrelation would break if tunable). Stage 1b's active_blend fades
                its candidates in/out via the outer `bomb` param.
  Stage 1c    -- merge: small top-2 insertion across the two halves' already-reduced results
                (codebox_seeds_merge.gen). Also outputs a properly-formatted seed-coord (gx,gy,0,1),
                wired directly to the outer module's outlet 2, bypassing Stage 4 -- preserves the original
                single-codebox outlet contract exactly (rank 1's position only).
  Stage 2/3   -- render: full per-candidate downstream (orientation, mod-tex sample, gate, shape sample,
                luma alpha), one shared codebox (codebox_seeds_render.gen) instanced once per rank.
  Stage 4     -- composite: rank-1-over-rank-2 alpha composite using rank 1's own luma-keyed alpha as the
                blend factor (codebox_seeds_composite.gen). bypass lives here, and on Stage 1c, for the
                mark-color/mask outlets.

  A single-codebox implementation hit a hard platform ceiling (Max's GL2->GL3 shader transformer's Lua
  DSL.Parser capture-group limit) at both the render-duplication stage AND, once bombing was added, at
  Stage 1 alone -- this six-stage split is the resolution, not a simplification choice. Full history:
  .specify/stable/f_vf_seeds/ (spec.md Evolution 1.5 + 2, plan.md ADR 6-8 + addenda).

Per-pixel behavior:
  1. Finds its nearest seed(s) -- up to 2 ranks
  2. Samples vecfield at each rank's seed position -> local orientation
  3. Projects pixel into seed-local (along, across) frame
  4. Constructs local UV from along/across, samples shape tex
  5. Gates on UV bounds (hard clip); luma-keyed alpha (not hardcoded 1.0)
  6. Composites rank 1 over rank 2

Key decisions: no internal mark geometry (shape character comes from the shape tex inlet); color
passthrough from the shape tex (out 1 = full-colour mark, out 2 = luma mask); passthrough when no shape is
connected (src_shape=0 -> mark=0); `stretch` 0 = uniform+aperture, 1 = deform; taper and softness live in
the shape generator; the module is a generator, not a processor (no source inlet); field_priority /
field_gain generalise seed selection from nearest-distance to a blendable priority incorporating vecfield
magnitude (0 = pixel-identical to before 2026-07-04); out 1's alpha is the mark luma, not 1.0 (so black
shape-tex background reads as transparent); `bomb` behaves as an on/off toggle, not a graded fader (the real
priority magnitude scales with density/jitter/field_gain/field_priority, so no fixed sentinel constant
stays correctly scaled -- confirmed empirically, plan.md's toggle-behavior addendum).

Inlets:  0 shape tex + control (the driving inlet) | 1 vecfield (float32 RG, drives mark orientation per
         seed) | 2 mod tex (sampled at seed UV) | 3 colour driving texture (Evolution 3, optional)
Outlets: 0 mark colour (rank 1 over rank 2, gated by the footprint) | 1 mark mask (luma, greyscale) |
         2 seed coord (rank 1's UV position only)
Bypass:  black/transparent output (generator convention): Stage 1c and Stage 4 take the native @bypass.
"""
from pathlib import Path

_HERE = Path(__file__).parent

_SALTS_A = (127.1, 311.7, 269.5, 183.3)      # Stage 1a -- the original 9 candidates
_SALTS_B = (419.2, 371.9, 133.7, 197.3)      # Stage 1b -- the bombing 9


def _search(salts):
    """The search template with one stage's baked hash salts."""
    text = (_HERE / "codebox_seeds_search.gen").read_text()
    return text.format(salt1=salts[0], salt2=salts[1], salt3=salts[2], salt4=salts[3])


_AB = ["1a", "1b"]                           # the two search halves
_RENDER = ["render_1", "render_2"]           # the two render ranks


def _ui(name, lo, hi, default, label, hint, stages, **extra):
    p = {"name": name, "type": "float", "min": lo, "max": hi, "default": default,
         "label": label, "hint": hint, "pix_target": stages}
    if len(stages) > 1:
        p["pix_shared_attrui"] = True        # one attrui fans out to every stage (as the module ships)
    p.update(extra)
    return p


_PARAMS = [
    _ui("density", 0.0, 1.0, 0.5, "Density", "Seed spacing \u2014 log-mapped, higher = more seeds", _AB),
    _ui("jitter", 0.0, 1.0, 0.5, "Jitter", "Seed position randomness (0=regular grid, 1=fully stochastic)", _AB),
    _ui("size", 0.0, 0.5, 0.2, "Size", "Mark size \u2014 overall scale", _RENDER),
    _ui("stretch", 0.0, 1.0, 0.0, "Stretch",
        "Aspect ratio \u2014 0=circular/square, increasing elongates along field direction", _RENDER),
    _ui("strength", 0.0, 1.0, 1.0, "Strength",
        "Vecfield influence on mark orientation (0=rightward, 1=full field)", _RENDER),
    _ui("mag_weight", 0.0, 1.0, 0.0, "Mag\u2192Wt", "Field magnitude \u2192 mark weight modulation depth", _RENDER),
    _ui("field_priority", 0.0, 1.0, 0.0, "Field Pri",
        "Seed selection: 0=nearest-distance (Voronoi, original behavior), 1=field-magnitude-only "
        "(degenerate at exactly 1.0 \u2014 see docs)", _AB),
    _ui("field_gain", -1.5, 1.5, 0.0, "Field Gain",
        "Field-priority scale \u2014 useful window varies by vecfield source (Flow ~0.2, Repulse ~0.8, "
        "Vortex ~1.5).", _AB, range_tiers=[0.2, 0.8, 1.5],
        range_menu_outlet=2),                # the shipped range menu feeds its `sel` from the float outlet
    # bomb: its attrui is bound directly to active_blend on the bombing half (Stage 1b); the dial keeps
    # showing "Bomb". (An earlier `route bomb` -> `prepend active_blend` chain silently dropped the value
    # in Max -- plan.md's addendum.)
    _ui("bomb", 0.0, 1.0, 0.0, "Bomb",
        "Second-sample-per-cell toggle \u2014 behaves as on/off, not a graded fader (see spec.md Evolution 2). "
        "Its attrui is bound directly to active_blend on Stage 1b \u2014 the dial itself keeps showing "
        "\"Bomb\".", ["1b"], pix_attr="active_blend"),
    _ui("phase", -1.0, 1.0, 0.0, "Phase", "Scroll marks along field direction (connect LFO for motion)", _RENDER),
    _ui("size_mod", -1.0, 1.0, 0.0, "Size Mod", "Mod tex \u2192 size modulation depth (bipolar)", _RENDER),
    _ui("stretch_mod", -1.0, 1.0, 0.0, "Str Mod", "Mod tex \u2192 stretch modulation depth (bipolar)", _RENDER),
    _ui("color_mode", 0.0, 1.0, 0.0, "Color Mode",
        "Blend between shape tex's own color (0) and the color driving texture sampled at each seed's "
        "position (1).", _RENDER),
]

patcher = {
    "name":               "f_vf_seeds",
    "prefix":             "vfseeds",
    "title":              "Seeds",
    "archetype":          "source",         # a generator: no source inlet, bypass = black
    "render_trigger":     "inlet",          # no `r draw`: the module renders when the shape tex / vecfield arrive (as shipped)
    "signal_type":        "vecfield",
    "presentation_width":  190,
    "presentation_height": 160,
    "inlet_comment":      "shape tex / control",

    "outlets": [
        {"comment": "mark color"},
        {"comment": "mark mask"},
        {"comment": "seed coord"},
    ],
    # seed coord (outlet 2) is Stage 1c's third outlet, bypassing Stage 4 (rank 1's position only)
    "outlet_source": {2: ["1c", 2]},

    "params": _PARAMS + [
        # set by vs_inState (`prepend param ...`): 1 = that inlet is connected.  src_vecfield is tracked but
        # unused in the maths (vestigial, as it was before Evolution 2): its prepend goes nowhere.
        {"name": "src_shape", "type": "internal"},
        {"name": "src_vecfield", "type": "internal"},
        {"name": "src_mod", "type": "internal"},
        {"name": "src_color_drive", "type": "internal"},
        {"name": "bypass", "type": "bypass"},
    ],

    # inlet 0 (shape tex + control): routepass -> vs_inState -> the two render stages' inlet 1; its
    # connected flag -> `prepend param src_shape` -> both render stages
    "inlet_fanout": {"texture": [["render_1", 1], ["render_2", 1]],
                     "state": _RENDER, "state_param": "src_shape"},
    # inlets 1-3: each its own vs_inState, fanned out to the stages that read it
    "mod_inlets": [
        {"label": "vecfield", "vs_instate": True, "state_param": "src_vecfield",
         "fanout": [["1a", 0], ["1b", 0], ["render_1", 2], ["render_2", 2]], "state_nodes": []},
        {"label": "mod tex", "vs_instate": True, "state_param": "src_mod",
         "fanout": [["render_1", 3], ["render_2", 3]], "state_nodes": _RENDER},
        {"label": "color drive tex", "vs_instate": True, "state_param": "src_color_drive",
         "fanout": [["render_1", 4], ["render_2", 4]], "state_nodes": _RENDER},
    ],

    # Bypass: the native attribute on the merge and composite stages only; the search halves and the render
    # stages keep running (ADR 8: bypass gated at the composite stage).
    "bypass_target": ["1c", "4"],

    "pix_chain": [
        {"id": "1a", "name": "vfseeds_search_a", "gen_code": _search(_SALTS_A), "n_inlets": 1, "n_outlets": 3,
         "pix_type": "float32", "primary": False},
        {"id": "1b", "name": "vfseeds_search_b", "gen_code": _search(_SALTS_B), "n_inlets": 1, "n_outlets": 3,
         "pix_type": "float32", "primary": False},
        {"id": "1c", "name": "vfseeds_merge", "gen": "codebox_seeds_merge.gen", "n_inlets": 6, "n_outlets": 3,
         "pix_type": "float32", "primary": False},
        {"id": "render_1", "name": "vfseeds_render_1", "gen": "codebox_seeds_render.gen", "n_inlets": 5,
         "n_outlets": 1, "primary": False},
        {"id": "render_2", "name": "vfseeds_render_2", "gen": "codebox_seeds_render.gen", "n_inlets": 5,
         "n_outlets": 1, "primary": False},
        {"id": "4", "name": "vfseeds_composite", "gen": "codebox_seeds_composite.gen", "n_inlets": 2,
         "n_outlets": 2, "primary": True},
    ],
    "pix_wires": [
        ["1a", 0, "1c", 0], ["1a", 1, "1c", 1], ["1a", 2, "1c", 2],      # search half A -> merge
        ["1b", 0, "1c", 3], ["1b", 1, "1c", 4], ["1b", 2, "1c", 5],      # search half B -> merge
        ["1c", 0, "render_1", 0], ["1c", 1, "render_2", 0],              # rank 1 / rank 2 coord -> render
        ["render_1", 0, "4", 0], ["render_2", 0, "4", 1],                # render -> composite
    ],

    # What the script-built patch never had, kept so the shipped patch stays byte-faithful instead of being
    # regenerated: no param_connect on the dials, no `lbl_<param>` varname on the labels.  Delete when the
    # module is next regenerated.
    "legacy": {
        "control_box": {p["name"]: {"param_connect": None} for p in _PARAMS},
        "element_box": {f"{p['name']}.label": {"varname": None} for p in _PARAMS},
    },
}
