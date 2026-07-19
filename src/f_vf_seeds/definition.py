"""
f_vf_seeds — definition.py

Placement and orientation engine for discrete marks. Stable seed points
distributed across the frame, each rendered by sampling an external shape
texture in seed-local UV space, oriented by the vecfield sampled at that
seed's position.

NOT CONSUMED BY tools/build_patcher.py — this module has its own builder,
.specify/f_vf_seeds/build_seeds_multistage.py, same category of reason as
f_sirds: params need to fan out to multiple differently-named internal
pix objects at once, which build_patcher.py's param_connect mechanism
can't do. This file remains the documented source of truth (params,
architecture, rationale) even though the builder hardcodes its own copy
of the param list rather than importing this dict directly — keep both
in sync by hand when either changes.

Architecture (Evolution 2, 2026-07-04 — six-stage jit.gl.pix chain):
  Stage 1a/1b — 9-candidate search + top-2 select, one shared codebox
                (codebox_seeds_search.gen) with baked hash-salt constants
                distinguishing the two (not live params — decorrelation
                would break if tunable). Stage 1b's active_blend fades
                its candidates in/out via the outer `bomb` param.
  Stage 1c    — merge: small top-2 insertion across the two halves'
                already-reduced results (codebox_seeds_merge.gen). Also
                outputs a properly-formatted seed-coord (gx,gy,0,1),
                wired directly to the outer module's outlet 2, bypassing
                Stage 4 — preserves the original single-codebox outlet
                contract exactly (rank 1's position only).
  Stage 2/3   — render: full per-candidate downstream (orientation,
                mod-tex sample, gate, shape sample, luma alpha), one
                shared codebox (codebox_seeds_render.gen) instanced once
                per rank.
  Stage 4     — composite: rank-1-over-rank-2 alpha composite using
                rank 1's own luma-keyed alpha as the blend factor
                (codebox_seeds_composite.gen). bypass lives here for the
                mark-color/mask outlets.

  A single-codebox implementation hit a hard platform ceiling (Max's
  GL2→GL3 shader transformer's Lua DSL.Parser capture-group limit) at
  both the render-duplication stage AND, once bombing was added, at
  Stage 1 alone — this six-stage split is the resolution, not a
  simplification choice. Full history: spec.md (Evolution 1.5 +
  Evolution 2), plan.md (ADR 6-8 + addenda).

Per-pixel behavior, same as always:
  1. Finds its nearest seed(s) — now up to 2 ranks, not just 1
  2. Samples vecfield at each rank's seed position → local orientation
  3. Projects pixel into seed-local (along, across) frame
  4. Constructs local UV from along/across, samples shape tex
  5. Gates on UV bounds (hard clip); luma-keyed alpha (not hardcoded 1.0)
  6. Composites rank 1 over rank 2

Key architectural decisions:
  - No internal mark geometry — shape character entirely from shape tex inlet
  - Color passthrough from shape tex (out0 = full color mark, out1 = luma mask)
  - Passthrough when no shape connected (src_shape=0 → mark=0)
  - stretch param: 0=uniform+aperture (shape preserved, weight clips across axis)
                   1=deform (shape stretches to fill weight x marklen rectangle)
  - taper and softness moved upstream to shape generator
  - Source inlet removed — module is a generator, not a processor
  - field_priority/field_gain (2026-07-04): seed selection generalizes from
    pure nearest-distance to a blendable priority incorporating vecfield
    magnitude. At field_priority=0, behavior is pixel-identical to pre-
    2026-07-04.
  - Luma-keyed alpha (2026-07-04, Evolution 1.5): out0's alpha is mark_luma,
    not a hardcoded 1.0 — black/low-luma shape-tex background now reads as
    transparent instead of stamping an opaque rectangle. Prerequisite for
    Evolution 2's overlap to render correctly.
  - Multi-owner overlap via texture bombing (2026-07-04, Evolution 2): see
    architecture note above. `bomb` behaves as an on/off toggle, not a
    graded fader — real priority magnitude scales with density/jitter/
    field_gain/field_priority, so no fixed sentinel constant stays
    correctly scaled across settings (confirmed empirically, not a bug —
    see plan.md's toggle-behavior addendum).

Inlets:
  in 0 — shape tex (mark footprint, oriented rightward, centered, any color)
  in 1 — vecfield (float32 RG, drives mark orientation per seed)
  in 2 — mod tex (sampled at seed UV, per-seed weight/marklen modulation)

Outlets:
  out 0 — mark color (composited rank1-over-rank2, gated by mark footprint)
  out 1 — mark mask (luma of composited mark, gated by mark footprint, greyscale)
  out 2 — seed coord (rank 1's UV position only — rank 2 not exposed here)

Bypass: black/transparent output (generator convention).
"""

patcher = {
    "name":               "f_vf_seeds",
    "prefix":             "vfseeds",
    "object_name":        "vfseeds_pix",
    "title":              "Seeds",
    "archetype":          "source",
    "pix_type":           "float32",
    "signal_type":        "vecfield",
    "driving_inlet":       True,

    "presentation_width":  190,
    "presentation_height": 160,

    "outlets": [
        {"comment": "mark color"},
        {"comment": "mark mask"},
        {"comment": "seed coord (rank 1 only)"},
    ],

    "mod_inlets": [
        {
            "label":       "shape tex",
            "vs_instate":  True,
            "state_param": "src_shape",
        },
        {
            "label":       "vecfield",
            "vs_instate":  True,
            "state_param": "src_vecfield",
        },
        {
            "label":       "mod tex",
            "vs_instate":  True,
            "state_param": "src_mod",
        },
    ],

    "params": [
        # ── Arrangement ───────────────────────────────────────────────────────
        {
            "name": "density", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Seed spacing — log-mapped, higher = more seeds",
            "label": "Density",
        },
        {
            "name": "jitter", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.5,
            "hint": "Seed position randomness (0=regular grid, 1=fully stochastic)",
            "label": "Jitter",
        },

        # ── Item character ────────────────────────────────────────────────────
        {
            "name": "size", "type": "float",
            "min": 0.0, "max": 0.5, "default": 0.2,
            "hint": "Mark size — overall scale",
            "label": "Size",
        },
        {
            "name": "stretch", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.0,
            "hint": "Aspect ratio — 0=circular/square, increasing elongates along field direction",
            "label": "Stretch",
        },

        # ── Field response ────────────────────────────────────────────────────
        {
            "name": "strength", "type": "float",
            "min": 0.0, "max": 1.0, "default": 1.0,
            "hint": "Vecfield influence on mark orientation (0=rightward, 1=full field)",
            "label": "Strength",
        },
        {
            "name": "mag_weight", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.0,
            "hint": "Field magnitude → mark weight modulation depth",
            "label": "Mag→Wt",
        },

        # ── Priority-generalized selection ───────────────────────────────────
        {
            "name": "field_priority", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.0,
            "hint": "Seed selection: 0=nearest-distance (Voronoi, original behavior), 1=field-magnitude-only (degenerate at exactly 1.0 — see docs)",
            "label": "Field Pri",
        },
        {
            "name": "field_gain", "type": "float",
            "min": -1.5, "max": 1.5, "default": 0.0,
            "hint": "Field-priority scale — live value used directly, no separate range param. Useful window varies by vecfield source (Flow ~0.2, Repulse ~0.8, Vortex ~1.5) — see range_tiers.",
            "label": "Field Gain",
            "range_tiers": [0.2, 0.8, 1.5],
        },

        # ── Multi-owner overlap (Evolution 2) ────────────────────────────────
        {
            "name": "bomb", "type": "float",
            "min": 0.0, "max": 1.0, "default": 0.0,
            "hint": "Second-sample-per-cell toggle — behaves as on/off, not a graded fader (real priority magnitude scales with other params, so no fixed sentinel stays correctly scaled — see plan.md). Its attrui is bound directly to active_blend on the bombing search half — the dial itself still shows/saves/automates as \"Bomb\".",
            "label": "Bomb",
        },

        # ── Animation ─────────────────────────────────────────────────────────
        {
            "name": "phase", "type": "float",
            "min": -1.0, "max": 1.0, "default": 0.0,
            "hint": "Scroll marks along field direction (connect LFO for motion)",
            "label": "Phase",
        },

        # ── Mod tex depths ────────────────────────────────────────────────────
        {
            "name": "size_mod", "type": "float",
            "min": -1.0, "max": 1.0, "default": 0.0,
            "hint": "Mod tex → size modulation depth (bipolar)",
            "label": "Size Mod",
        },
        {
            "name": "stretch_mod", "type": "float",
            "min": -1.0, "max": 1.0, "default": 0.0,
            "hint": "Mod tex → stretch modulation depth (bipolar)",
            "label": "Str Mod",
        },

        # ── Internal / system ─────────────────────────────────────────────────
        {
            "name": "src_shape", "type": "internal",
        },
        {
            "name": "src_vecfield", "type": "internal",
        },
        {
            "name": "src_mod", "type": "internal",
        },
        {
            "name": "bypass", "type": "bypass",
        },
    ],

    "codebox_search":    open("/Users/matt/Github/f_/src/f_vf_seeds/codebox_seeds_search.gen").read(),
    "codebox_merge":     open("/Users/matt/Github/f_/src/f_vf_seeds/codebox_seeds_merge.gen").read(),
    "codebox_render":    open("/Users/matt/Github/f_/src/f_vf_seeds/codebox_seeds_render.gen").read(),
    "codebox_composite": open("/Users/matt/Github/f_/src/f_vf_seeds/codebox_seeds_composite.gen").read(),
}
