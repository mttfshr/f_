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

The `r draw` bang goes to hold and enc (draw_triggers). The feedback enters hold on cold inlets, so the loop
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

        # Bypass drives the codebox Param `bypass_gate` on the encode stage, never the native @bypass: the
        # solver keeps running and the outlet passes a neutral (zero-velocity) field.
        {"name": "bypass", "type": "bypass"},

        # Driven by the bypass jsui (`prepend param bypass_gate`), never by the route
        {"name": "bypass_gate", "type": "internal"},
    ],

    # The mask inlet reaches the mrg stage only (its second inlet).
    "inlet_comment": "obstacle mask (white = obstacle)",
    "inlet_fanout": {"texture": [["mrg", 1]], "state": []},
    "draw_triggers": ["hold", "enc"],
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
