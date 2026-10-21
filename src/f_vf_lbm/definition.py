"""
f_vf_lbm -- definition.py

2D Lattice Boltzmann (D2Q9, BGK) channel flow around an obstacle, a vecfield producer: a mask texture goes in
(white = obstacle), a steady wind blows left to right, and the velocity vecfield of the wake comes out. Feed the
outlet to f_vf_advect / f_vf_warp / f_vf_streak / f_vf_glow like any other vecfield.
See .specify/f_vf_lbm/{spec,tasks}.md; the verified NumPy mirror is tests/modules/vf_lbm/.

Stage chain, solver stages at a fixed 192x108 (16:9, so a shape keeps its proportions) float32, three planes
(nine populations packed in RGBA, FR-001):
    hold -> collide -> stream -> mac -> enc           (stream -> hold feedback, three planes)
    hold -> mrg -> collide                            (the obstacle flag rides in plane 3, G)
  hold     the loop break: one-frame delay of the three state planes (identity), triggered by `r draw`
  mrg      box-averages the render-size mask, writes the obstacle flag next to population 8
  collide  fused macro + equilibrium + BGK collision + bounce-back (pre-collision values) + Zou/He inflow +
           zero-gradient outflow, y periodic; seeds a valid equilibrium when the state is empty or non-finite
  stream   gather: new[x] = old[x - e_i] (explicit periodic indices)
  mac      ux, uy, rho from the streamed state (solver size)
  enc      render-size bilinear upsample + gain + clamp + f_vecfield encode + bypass gate

Why mrg exists: the codebox bench drives three inlets per stage, and collide would otherwise need a draw bang,
three planes and a mask (five). With the trigger moved to `hold` and the mask folded into plane 3, every
numerics stage (collide, stream, mac, enc, mrg) is benchable. `hold` is the only four-inlet stage and is an
identity. The first outlet of `hold` is the hot cord into collide; Max fires outlets right to left, so mrg's
flag and the second plane are in place before the first plane triggers collide.

The `r draw` bang goes to enc directly and to hold through a frame gate (raw boxes at the end of this file): a
counter passes every Nth bang, N from the Speed menu, so a skipped frame leaves the whole solver loop idle and
enc re-renders the held state. Speed 1/N therefore slows the flow to 1/N (hold is obj-50, the Speed menu obj-29).
The bang to hold The feedback enters hold on cold inlets, so the loop
advances exactly once per rendered frame (the f_vf_fluid / f_ks pattern). The mask is the module's one texture
inlet; unconnected reads as no obstacle. The solver size is a literal in each codebox (W = 192, H = 108).

Defaults taken without a Matt decision (flagged in HANDOFF, revisit at tier 3): name f_vf_lbm (T010); bypass =
a neutral vecfield with the solver running underneath (T011); `omega` is the user-facing control, 1.0 to 1.98,
default 1.97, the codebox clamps it to 1.98 (T013, FR-007); `inflow` 0 to 0.1, default 0.08; the first and last
columns are never obstacle (T014); a mask value counts as obstacle above 0.5 luma (T016, no soft weight).
"""

patcher = {
    "name":               "f_vf_lbm",
    "prefix":             "vflbm",
    "title":              "LBM",
    "signal_type":        "mask in, ∇ out",

    "presentation_width":  190,
    "presentation_height": 110,

    # processor: the obstacle mask arrives on the primary inlet
    "archetype": "processor",

    "outlets": [
        {"comment": "velocity vecfield"},
    ],

    "params": [
        {"name": "omega", "type": "float", "min": 1.0, "max": 1.98, "default": 1.97,
         "label": "Omega", "pix_target": "collide",
         "hint": "BGK relaxation rate: low = thick and smooth, high = thin and turbulent. The top of the range is the stability limit"},
        {"name": "inflow", "type": "float", "min": 0.0, "max": 0.1, "default": 0.08,
         "label": "Wind", "pix_target": "collide",
         "hint": "Inflow speed in lattice units: the wake needs about 0.08 and a few thousand frames to start shedding"},
        {"name": "gain", "type": "float", "min": 0.0, "max": 10.0, "default": 3.0,
         "label": "Gain",
         "hint": "Output scale applied to the velocity before encoding (clamped to the vecfield range)"},

        # Speed: run the solver on every Nth rendered frame (the frame gate below). No pix attribute: the
        # menu's outlet feeds the counter's modulus (pix_wire False, tapped like f_caustic's Edge menu).
        {"name": "speed", "type": "menu", "options": ["Full", "1/2", "1/3", "1/4"], "default": 0,
         "label": "Speed", "pix_wire": False,
         "hint": "How fast the flow evolves: the solver advances on every frame (Full), every 2nd, 3rd or 4th. Slower = the same wake in slow motion. The output holds its last state in between"},

        # Bypass drives the codebox Param `bypass_gate` on the encode stage, never the native @bypass: the
        # solver keeps running and the outlet passes a neutral (zero-velocity) field.
        {"name": "bypass", "type": "bypass"},

        # Driven by the bypass jsui (`prepend param bypass_gate`), never by the route
        {"name": "bypass_gate", "type": "internal"},
    ],

    # The mask inlet reaches the mrg stage only (its second inlet).
    "inlet_comment": "obstacle mask (white = obstacle)",
    "inlet_fanout": {"texture": [["mrg", 1]], "state": []},
    "draw_triggers": ["enc"],            # hold gets its bang through the frame gate (raw boxes below)
    "bypass_mode": "param",             # jsui -> prepend param bypass_gate -> enc (the primary)

    "pix_chain": [
        {"id": "hold",    "name": "#0_lbm_hold",    "gen": "codebox_hold.gen",    "n_inlets": 4, "n_outlets": 3,
         "pix_attrs": "@adapt 0 @dim 192 108 @type float32", "primary": False},
        {"id": "mrg",     "name": "#0_lbm_mrg",     "gen": "codebox_mrg.gen",     "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 192 108 @type float32", "primary": False},
        {"id": "collide", "name": "#0_lbm_collide", "gen": "codebox_collide.gen", "n_inlets": 3, "n_outlets": 3,
         "pix_attrs": "@adapt 0 @dim 192 108 @type float32", "primary": False},
        {"id": "stream",  "name": "#0_lbm_stream",  "gen": "codebox_stream.gen",  "n_inlets": 3, "n_outlets": 3,
         "pix_attrs": "@adapt 0 @dim 192 108 @type float32", "primary": False},
        {"id": "mac",     "name": "#0_lbm_mac",     "gen": "codebox_mac.gen",     "n_inlets": 3, "n_outlets": 1,
         "pix_attrs": "@adapt 0 @dim 192 108 @type float32", "primary": False},
        {"id": "enc",     "name": "#0_lbm_enc",     "gen": "codebox_enc.gen",     "n_inlets": 2, "n_outlets": 1,
         "pix_attrs": "@adapt 1 @type float32", "primary": True},
    ],
    "pix_wires": [
        # hold -> collide: the first plane is the hot cord; the third plane goes through mrg first
        ["hold", 0, "collide", 0], ["hold", 1, "collide", 1],
        ["hold", 2, "mrg", 0], ["mrg", 0, "collide", 2],
        ["collide", 0, "stream", 0], ["collide", 1, "stream", 1], ["collide", 2, "stream", 2],
        # feedback edge: stream -> hold, cold inlets (the bang is the hot one)
        ["stream", 0, "hold", 1], ["stream", 1, "hold", 2], ["stream", 2, "hold", 3],
        ["stream", 0, "mac", 0], ["stream", 1, "mac", 1], ["stream", 2, "mac", 2],
        ["mac", 0, "enc", 1],       # velocity -> encode (cold)
    ],
}


# ---- frame gate (raw boxes) -----------------------------------------------------------------------------
#   [r draw] -> [i] -> [+ 1] -> [% N] -> [i] right inlet        a counter that wraps at N
#   [i] -> [sel 0] -> bang -> hold (obj-50, inlet 0)            fires on count 0: every Nth frame
#   Speed menu (obj-29, outlet 0: index 0..3) -> [+ 1] -> [% N] right inlet
# N = 1 passes every frame (the default); the counter is never reset, so a change of N takes effect within N frames.
def _box(i, cls, rect, **kw):
    b = {"id": f"obj-raw-{i}", "maxclass": cls, "patching_rect": rect}
    b.update(kw)
    return {"box": b}


def _obj(i, text, nin, nout, rect, otypes=None):
    return _box(i, "newobj", rect, text=text, numinlets=nin, numoutlets=nout,
                outlettype=otypes or [""] * nout)


def _line(src, so, dst, di):
    ref = lambda o: o if isinstance(o, str) else f"obj-raw-{o}"      # int = a raw box, str = a full id
    return {"patchline": {"source": [ref(src), so], "destination": [ref(dst), di]}}


patcher["raw_boxes"] = [
    _obj(1, "r draw", 0, 1, [330.0, 320.0, 50.0, 22.0]),
    _obj(2, "i", 2, 1, [330.0, 350.0, 30.0, 22.0], ["int"]),
    _obj(3, "+ 1", 2, 1, [380.0, 380.0, 30.0, 22.0], ["int"]),
    _obj(4, "% 1", 2, 1, [380.0, 410.0, 30.0, 22.0], ["int"]),
    _obj(5, "sel 0", 2, 2, [330.0, 380.0, 40.0, 22.0], ["bang", ""]),
    _obj(6, "+ 1", 2, 1, [430.0, 380.0, 30.0, 22.0], ["int"]),
]
patcher["raw_lines"] = [
    _line(1, 0, 2, 0),                  # draw -> counter
    _line(2, 0, 3, 0), _line(3, 0, 4, 0), _line(4, 0, 2, 1),        # count + 1, wrapped at N, stored
    _line(2, 0, 5, 0), _line(5, 0, "obj-50", 0),                    # count 0 -> bang -> hold
    _line("obj-29", 0, 6, 0), _line(6, 0, 4, 1),                    # Speed index + 1 -> N
]
