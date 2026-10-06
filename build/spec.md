# Spec: build_patcher.py

_Last updated: 2026-07-10_

## What it does

A general-purpose Python script that reads a patcher definition file and writes a valid Max 9 `.maxpat` JSON file to `package/patchers/f_<name>.maxpat`. One script generates any f_ bpatcher — new patchers are defined by writing a definition file, not modifying the script.

This is a personal scaffolding tool. It generates the initial patcher correctly and convention-compliantly. After generation, Max owns the `.maxpat` — hand edits in Max are expected and fine. The definition file is a structured intermediate for the build process, not a permanent mirror of the patcher.

---

## Workflow Position

```
scratch patch (iterate codebox)
    ↓
src/f_<name>/definition.py         ← patcher definition: codebox + params + archetype
    ↓
build/build_patcher.py            ← reads definition, writes .maxpat
    ↓
package/patchers/f_<name>.maxpat  ← distributed artifact; Max owns it from here
```

`src/` holds build-input files (`definition.py`, codebox `.gen` files, per-module build scripts) — the working source for the build system. `.specify/` holds planning/reference material only (`spec.md`/`plan.md`/`tasks.md`), version controlled and kept public. `package/patchers/` is version controlled and is the distribution artifact — the only folder Max needs, see the repo root README.

---

## Inputs

### Definition file

A Python module at `src/f_<name>/definition.py` containing a single dict named `patcher`. Imported directly by the build script.

**Required keys:**

```python
patcher = {
    # Identity
    "name":               str,   # e.g. "f_stipple" — used for output filename
    "prefix":             str,   # e.g. "stipple" — used for autopattr varname (<prefix>_autopattr) and passed into pix_box
    "object_name":        str,   # e.g. "stipple_pix" — @name on jit.gl.pix
    "title":              str,   # e.g. "Stipple" — display name in presentation

    # Archetype — determines signal flow pattern
    # "source"    — self-generating, no upstream texture used by codebox
    # "processor" — requires upstream texture, samples in1
    # "dual"      — auto-detects via vs_inState; src_mode param drives codebox branch
    "archetype":          str,

    # Presentation panel size in pixels
    "presentation_width":  int,
    "presentation_height": int,

    # Params list — ordered; determines UI layout left-to-right
    "params":             list,  # see Param schema below

    # Confirmed codebox content — verbatim from scratch patch
    "codebox":            str,
}
```

**Optional keys:**

```python
patcher = {
    # ...required keys above...

    # pix_type: @type attribute on jit.gl.pix. Default: omitted (Max default).
    # Use "float32" for vecfield producers; "char" for standard processors.
    "pix_type":           str,   # e.g. "float32", "char"

    # outlets: list of bpatcher outlet descriptors. Default: [{"comment": "texture out"}].
    # Each entry generates one bpatcher outlet, one gen `out N`, one codebox outlet.
    # Primary outlet (index 0) is always obj-2. Additional outlets are obj-201, obj-202, etc.
    # color is optional — if present, sets tricolor on the outlet box.
    "outlets": [
        {"comment": str, "color": [r, g, b, a]},  # color is optional
    ],

    # mod_inlets: list of additional texture inlets beyond inlet 0.
    # Each entry generates an inlet box and (by default) a vs_inState.
    # Inside the gen subpatcher, these become in 2, in 3, ...
    "mod_inlets": [
        {
            "label":       str,   # inlet hover text
            "vs_instate":  bool,  # default True. False = route inlet directly to pix, no vs_inState
            "state_param": str,   # optional. Requires vs_instate=True. Wires vs_inState out1
                                  # → prepend param <state_param> → pix in0. Used to suppress
                                  # vs_black artifact when inlet is unconnected.
        },
    ],
}
```

**Param schema:**

```python
# Float param — renders as live.dial
{"name": str, "type": "float", "min": float, "max": float, "default": float, "hint": str}

# Int param — renders as live.numbox
{"name": str, "type": "int", "min": int, "max": int, "default": int, "hint": str}

# Optional on a float or int param (dial / numbox): "modmode": int 0-4 -- the control's
# parameter_modmode. Default 3 (relative modulation, the dial standard); 0 turns modulation off,
# as on f_droste's n_arms (a fractional arm count does not tile). Added 2026-10-05, build_cleanup
# T014. Loud outside 0-4.

# Optional on any control param: "route_name": str -- the message the control answers to on the
# control inlet, when it is not the param's name (f_vf_advect's `mix_pct` numbox answers to `mix`,
# as it ships; most modules' `mix_pct` answers to `mix_pct`). One word, unique among the route
# tokens, not `bypass`; loud otherwise. Added 2026-10-05, T014.
#
# Optional "hint": str. A param with no "hint" key gets hint "" (long-standing output, and what the
# shipped builder-made patchers contain); `"hint": None` writes no hint key at all, for hand-made
# controls whose shipped patch has none (f_vf_advect's dials, f_stereo's toggle). Added 2026-10-05.
#
# "pix_target" (pix_chain node id) also decides the control's `param_connect`: it names that node's
# @name, not the primary pix's (f_vf_advect's `separate` / `mode` drive the pass pix). A raw-object
# pix_target keeps naming the primary pix. Fixed 2026-10-05: the builder used to name the primary pix
# for every control, so f_vf_optical_flow's support-stage dials were bound to a pix without the Param.
#
# Optional "pix_wire": False on a control param: it keeps its route outlet and its widget but gets no
# attrui and no cord to a pix; the module wires it itself via raw_boxes / raw_lines (f_grain's
# `persistence` dial feeds an era-clock chain, not a Param). Loud on a non-boolean. Added 2026-10-05.
#
# Top-level "route_first": True -- the control inlet feeds the `route`, and the route's reject
# (unmatched) outlet feeds `routepass`, the reverse of the default (inlet -> routepass -> route).
# Adds the reject outlet to the route box. f_grain ships that way; no other module does. Loud on a
# non-boolean. Added 2026-10-05.
#
# Top-level "inlet_comment": str -- the main inlet's comment (default "texture / control"; f_grain's is
# empty). An outlet dict may carry "hint": str (the outlet's tooltip; f_grain's `grain mask` has "Raw").
# Added 2026-10-05.
#
# "label": None on a control param: no label box is built for it (a shared or hand-made label is
# carried by raw_boxes instead). A param with no "label" key still gets its default label.
#
# Top-level "pix_context": "arg" (default) or "drawto" -- how the jit.gl.pix object text names its
# context: `jit.gl.pix vsynth @name X ...` or the older `jit.gl.pix @name X @drawto vsynth ...` that
# the oldest modules ship with (f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve).
# Applies to every pix of a pix_chain too. Loud on any other value.
#
# Optional "color_expression": str on a float (dial) param -- the theme expression Max saves beside the
# dial's activedialcolor ("themecolor.live_record"); "" by default. The resolved RGB is a presentation
# property (overrides); capture cannot carry this one (it lives in saved_attribute_attributes).
# `"color_expression": None` writes no `activedialcolor` entry at all (a dial Max saved without one:
# the band-editor colour modules' dials).
#
# Top-level "route_reject_to_pix": True -- the route's reject (unmatched) outlet feeds the primary pix's
# inlet 0, so messages no route token claims reach the pix; adds the reject outlet to the route box.
# The oldest modules ship that way. Cannot be combined with route_first (both use the reject outlet).
#
# Top-level "legacy": {...} -- state of objects that were re-created in Max, preserved so a patch can
# stay byte-faithful instead of being regenerated (regenerating would rename the autopattr, which could
# affect preset recall, and nothing can verify that offline). Default-off; delete an entry when the
# module is next regenerated. Keys: "pix_varname" (the pix's scripting name, e.g. "jit.gl.pix_AA";
# every control's param_connect names it, as Max wrote it; single-pix modules only), "autopattr_varname"
# (e.g. "u905020188"), "bypass_jsui_saved" (the jsui's inert saved_attribute_attributes block, verbatim),
# "control_valueof" ({param: {valueof key: value}}; None removes the key: a default shortname, a missing
# initial value), "control_box" ({param: {box property: value}}; None removes the property: e.g. a dial
# whose param_connect was removed by hand; cannot set id, maxclass, patching_rect or patcher). Loud on an
# unknown key or a wrong shape. Added 2026-10-05, T014 (the four oldest colour modules).
# "element_valueof" ({element key: {valueof key: value}}) and "element_box" ({element key: {property:
# value}}) do the same for ANY generated element by its override key ("aberration.range_menu",
# "panel_toggle"), applied after `overrides` (f_lens: range menus Max saved with an explicit mmax,
# modmode 0 and an auto scripting name; the panel toggle's default enum labels). Loud on an unknown
# element, an element with no saved valueof block, or a denied property. Added 2026-10-05, T014.
#
# Multi-stage keys (build_cleanup T016/T017, 2026-10-05; all explicit and default-off, loud on a
# mistake; tests/test_build_multistage.py).  A "node" below is a pix_chain node id or the id of a
# raw_boxes object; an unknown one raises.
#
#   Per pix_chain node "pix_attrs": str -- the node's attributes as one verbatim string, written after
#   `@name X` in place of the generated `@type` / `@adapt` ("@adapt 0 @dim 256 256 @type float32").
#   Loud if given with pix_type or adapt, if empty, or if it sets @name.
#
#   Per param "pix_target": a node id (unchanged) OR a list of node ids.  With a list the widget's
#   param_connect and its own attrui name the FIRST stage; each further stage gets an extra attrui
#   (ids obj-700+) fed from the widget.  Loud on an unknown node, a repeat, or an empty list.
#
#   Per float/int param "ui": False -- the param keeps its route token and an attrui (varname = the
#   param name) fed straight from the route, but gets no widget, no label, no panel slot and no entry in
#   the parameters block (f_vf_fluid's `taps`, a codebox setting that is not performable).
#
#   Top-level "inlet_fanout": {"texture": [[node, inlet], ...], "state": [node, ...], "state_param": name}
#   -- the module's texture inlet reaches several stages: routepass out 0 -> vs_inState (the only route
#   for the texture; the default feed of the primary pix is replaced), vs_inState out 0 -> each listed
#   (node, inlet), and vs_inState out 1 (connected flag) -> `prepend param <state_param>` (default
#   src_mode) -> inlet 0 of each node in "state".  Without "state" no prepend box is built.  Works with
#   any archetype.
#
#   Top-level "draw_triggers": node | [node, ...] -- one `r draw` box (obj-20a) feeding inlet 0 of each
#   stage, so it advances once per frame; shared with the source archetype's own render trigger (a cord
#   the archetype already makes is not doubled).
#
#   Top-level "bypass_mode": "native" (default) | "param".  "param": the bypass jsui -> `prepend param
#   <bypass_param>` -> the stage(s) in "bypass_target" (default the primary; a node or a list), instead of
#   jsui -> attrui @attr bypass.  Native jit.gl.pix bypass skips the shader and flips secondary outlets
#   (f_vf_warp finding, plan.md item 10), so a module that needs every outlet to pass the input through
#   drives a codebox Param instead.  "bypass_param" defaults to "bypass_gate" and may not be "bypass".
#   The builder checks that each target's codebox declares `Param <bypass_param>(`; the codebox must
#   itself implement the passthrough (e.g. `out1 = mix(effect, in1, bypass_gate)` on every outlet).
#   bypass_param / bypass_target without bypass_mode "param" are loud.  Convention (Matt, 2026-10-05):
#   a bypassed module is a PASSTHROUGH on every outlet.
#
# range_tiers: the `_parameter_range` message text writes each bound the way Max writes a float in a
# message box ("1." not "1.0", "-5." not "-5.0", "0." for zero; others as their shortest repr "0.2").
# The builder used to write "1.0", which Max rewrites on load. Fixed 2026-10-05 (f_lens, f_vf_vorticity).
#
# raw_boxes / raw_lines / raw_parameters for a module are best derived, not typed:
# `build/py.sh build/capture_raw.py src/f_x/definition.py` writes `raw_ui.json` next to the
# definition (see its docstring and f_grain/definition.py for the pattern).

# Menu param — renders as live.menu with labelled options, outputs integer 0-N
{"name": str, "type": "menu", "options": [str, ...], "default": int, "hint": str}

# Internal param — present in codebox, no UI object, absent from parameters block
# Driven from patcher (e.g. vs_inState outlet → prepend param src_mode → pix in0)
{"name": str, "type": "internal"}

# Bypass — always last; rendered as bypass_toggle.js jsui
{"name": "bypass", "type": "bypass"}
```

**Multi-pix chain keys** (optional — when present, replaces `object_name`, `codebox`, and `pix_type`):

```python
patcher = {
    # ...required keys above, except object_name/codebox/pix_type are omitted...

    # pix_chain: list of pix node dicts. When present, build_patcher.py generates
    # one jit.gl.pix per entry instead of the single-pix default path.
    # Exactly one entry must have "primary": True. The primary pix is the target
    # for params, bypass, mod_inlets, and bpatcher outlets. Support pix are
    # internal plumbing only.
    "pix_chain": [
        {
            "id":       str,   # symbolic ID used in pix_wires references
            "name":     str,   # literal @name string on jit.gl.pix — author decides
            "gen":      str,   # "pass" for identity gen, or filename relative to
                               # src/f_<name>/ for a codebox file
            "n_inlets": int,   # number of gen inlets (in 1, in 2, ...)
            "n_outlets":int,   # number of gen outlets (out 1, out 2, ...)
            "pix_type": str,   # optional — @type attribute (e.g. "char", "float32")
            "adapt":    bool,  # optional — adds @adapt 1 if True
            "primary":  bool,  # True for exactly one entry
        },
        # ... more nodes ...
    ],

    # pix_wires: cross-pix patchlines, referencing pix_chain "id" values.
    # Standard wiring (routepass→primary, mod_inlets→primary, primary→outlets)
    # is generated automatically. pix_wires adds only the cross-pix connections.
    # Format: [src_id, src_outlet, dst_id, dst_inlet]
    "pix_wires": [
        [str, int, str, int],
    ],
}
```

Object ID assignment for multi-pix: primary pix → `obj-5`; support pix → `obj-50`, `obj-51`, ... in chain order (excluding primary).

**`pix_target` on a param** (added 2026-07-15, for `f_lens` halation) — a
normal (non-`raw_ui`) param can target an object other than the primary
pix. Value is either a `pix_chain` node `id` (looked up automatically),
or, if not found there, treated as a **literal object id** directly —
this second form is what lets a param target a manually-declared
`raw_boxes` object (see below) without requiring the primary pix itself
to be restructured into a `pix_chain`. The param still gets full normal
dial/label/route-dispatch generation; only the final attrui wire target
changes. No effect on message format — `jit.gl.pix` attrui messages are
generic attribute-set messages, bound by name on whichever object
receives them, regardless of which pix declared the matching `Param`.

```python
{"name": "halation", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0,
 "pix_target": "obj-raw-17"}   # a raw_boxes object id, not a pix_chain node
```

**`raw_boxes` / `raw_lines` / `raw_parameters`** (added 2026-07-15, for
`f_lens`'s tilt-shift and halation) — an escape hatch for content too
bespoke to model declaratively: verbatim box/patchline/parameter dicts,
already in the exact wrapper shape used throughout this file
(`{"box": {...}}` / `{"patchline": {...}}`), appended to the build
output unmodified.

```python
"raw_boxes":      [ {"box": {...}}, ... ],
"raw_lines":       [ {"patchline": {...}}, ... ],
"raw_parameters": { "obj-id": [longname, shortname, 0], ... },
```

Author is responsible for using object IDs that don't collide with
anything the schema generates — the `obj-raw-N` namespace (any id
containing non-numeric characters after `obj-`) is guaranteed safe,
since nothing in this file's own ID generation ever produces one.
Extract-and-remap from a working reference file rather than hand-picking
IDs from scratch. See `ideas/build_patcher_schema_gaps.md` for the full
background on when this is the right tool vs. `pix_chain`/`pix_target`.

**`"type": "raw_ui"` param** (added 2026-07-15) — reserves a route
outlet (dispatched by name, appended to the route arg list after
`ui_params` + `header_toggles`) but generates **no** dial/label/attrui/
pix-wire. For params with real UI and route dispatch but bespoke
downstream wiring (e.g. `f_lens`'s `tilt_axis`/`tilt_pos`, which both
feed a custom `lens_tiltcenter.js` transform before reaching
`jit.fx.cf.tiltshift`) that doesn't fit `pix_target`'s "route straight to
one object" shape. The param's actual UI/wiring is then supplied via
`raw_boxes`/`raw_lines`.

**`render_trigger`** (added 2026-10-05; `"rdraw"` default, or `"inlet"`; `source` archetype only) —
a source module normally gets an `r draw` box wired to the pix as a per-frame render trigger (and a
free-standing `r draw` inside the gen patcher). `"inlet"` omits both, so the module renders only when
the texture arriving at its main inlet (`routepass` out 0) drives the pix. The finished `f_vf_vortex`
and `f_vf_vortex_multi` ship that way. Loud on an unknown value, on a non-`source` archetype, and on
a source without `mod_inlets` (there the gen `r draw` is wired into the codebox and omitting it is
untested). The default is unchanged, so `f_vf_fluid` and `f_vf_seeds` are unaffected.

**`route_bypass`** (added 2026-10-05; `True` or `False`, default `False`; build_cleanup/T014) —
`bypass` becomes the first token of the `route` (`route bypass cx cy ...`), its outlet 0 is wired to
the bypass jsui, and every param (and header-toggle) outlet is one higher, so a `bypass 0/1` message
sent to the module flips the toggle. The nine oldest modules route it and the skill's 2026-09-23
decision is not to retrofit it into generated ones, so the default stays off; the key exists so the
oldest modules reproduce from their definitions. Loud on a non-boolean value.

**`outlet_source_override`** (added 2026-07-15) — `{outlet_index:
anything}`; skips the schema's automatic primary-pix→outlet wire for
that outlet index. Use when one or more `raw_boxes` objects sit between
the primary pix and a bpatcher outlet (e.g. `f_lens`'s
`lens_pix → halation → tiltshift → outlet0` chain) — the full wire path
is then supplied explicitly via `raw_lines` instead. The override value
itself isn't consumed, only the key's presence matters; a short
descriptive string is conventional.

```python
"outlet_source_override": {0: "tiltshift"},
```

**`panel_toggle`** (added 2026-07-15, generalized from `f_lens`'s
hand-built `panel_toggle`/`lens_toggle.js`) — declares a front/back
panel split. Generates the toggle `live.text` button, a per-module
toggle JS file (`package/javascript/<prefix>_toggle.js`, written as a
build side-effect — **not currently gated by a dry-run flag**, so even a
build call whose `.maxpat` output goes to a scratch path will still
overwrite the live JS file; a `dry_run` guard is a known follow-up, see
`ideas/build_patcher_schema_gaps.md`), and all wiring (reuses the same
`thispatcher` object `modulesize` already wires up).

```python
"panel_toggle": {
    "front": ["param1", "param2", ...],
    "back":  ["param3", "param4", ...],
    "front_label": "lens",   # shown when back panel active; optional, default "front"
    "back_label":  "field",  # shown when front panel active; optional, default "back"
},
```

Requires `label_box()`'s `varname=f"lbl_{p['name']}"` (added the same
day as a prerequisite fix — labels previously had no `varname` at all,
so `script sendbox` couldn't target them for any toggle mechanism).

**`range_tiers` — optional dial range selector** (float params only):

```python
{
    "name": "dt", "type": "float",
    "min": 0.0, "max": 0.05, "default": 0.01,
    "label": "dt",
    "range_tiers": [0.05, 0.5, 1.0],  # unipolar form: list of upper bounds; min assumed 0.
}
```

**Bipolar form** (added 2026-07-15, for `f_lens` v2's aberration/distortion/transmission/ghost_spacing tiers) — each tier entry can also be a `(lower, upper)` 2-tuple/list, giving an explicit lower bound instead of the assumed 0.:

```python
{
    "name": "aberration", "type": "float",
    "min": -1.0, "max": 1.0, "default": 0.0,
    "label": "Aberration",
    "range_tiers": [(-1.0, 1.0), (-2.0, 2.0), (-10.0, 10.0)],  # bipolar tiers
}
```

The two forms can be mixed within one param's `range_tiers` list — each entry is checked independently (plain number → unipolar `(0., upper)`, tuple/list → explicit `(lower, upper)`). Menu labels differ correspondingly: unipolar entries display as `"1.0"`; bipolar entries display as `"-1.0..1.0"`.

When present, generates a compact `live.menu` (triangle-only, 16×15px) positioned
to the right of the param label in the header row, plus a `sel` and one
`_parameter_range <lower>. <upper>` message per tier. Selecting a tier dynamically rescales the
dial. Menu state persists via `autopattr`. Object IDs: `obj-{300 + n*10}` = menu,
`obj-{300 + n*10 + 1}` = sel, `obj-{300 + n*10 + 2+t}` = messages (n = param index
among ui_params, t = tier index).

**Param ordering rules:**
- `bypass` is always last
- Internal params appear in the list for documentation but generate no UI objects
- UI layout is left-to-right in order of appearance, excluding internal and bypass

---

## Output

`package/patchers/f_<name>.maxpat` — a valid Max 9 JSON patcher file.

**Required objects in every output patcher:**

| Object | Notes |
|---|---|
| `inlet` (texture in) | comment "texture in", index 0 |
| `outlet` (texture out) | comment "texture out", index 0 |
| `routepass jit_gl_texture jit_matrix` | peels texture from inlet |
| `route <params...>` | dispatches named control messages; bypass absent |
| `jit.gl.pix vsynth @name <object_name>` | shader core with embedded gen subpatcher |
| `autopattr` (box `varname` = `<prefix>_autopattr`; text has no `@varname`) | state save/restore |
| `bypass_toggle.js` jsui | bypass UI; wired directly to pix, not through route |
| `live.dial` per float param | with parameter_enable, varname |
| `live.numbox` per int param | same wiring pattern as live.dial |
| `attrui` per param | sits between dial/numbox and pix in0; `attr` key names the target param — replaces the older `prepend param <name>` pattern |
| label comment per param | 9.5pt Ableton Sans Light, below dial |
| title comment | 12pt Ableton Sans Light, top-left of presentation panel |
| background panel | black bg, blue border, presentation only |
| moduleSize.js chain | loadbang → getattr presentation_rect → thispatcher → zl slice 2 → prepend tam → js moduleSize.js |
| `parameters` block | registers all param objects by obj-id |

**Archetype-specific additions:**

| Archetype | Additional objects |
|---|---|
| source | `r dim` wired to codebox inlet 1 inside gen subpatcher |
| processor | none beyond base set |
| dual | `vs_inState` between routepass texture outlet and pix in0; `prepend param src_mode` from vs_inState outlet 1 to pix in0 |

---

## Object ID Scheme

Deterministic, stable, consistent between boxes and patchlines:

```
obj-1   inlet (texture in)
obj-2   outlet (texture out)
obj-3   routepass
obj-4   route
obj-5   jit.gl.pix (contains gen subpatcher)
obj-6   autopattr
obj-7   bypass_toggle.js jsui
obj-8   bypass attrui
obj-9   panel (background)
obj-10  title comment
obj-11  loadbang (moduleSize chain)
obj-12  message (getattr presentation_rect)
obj-13  thispatcher
obj-14  zl slice 2
obj-15  prepend tam
obj-16  js moduleSize.js

# Dual-mode only:
obj-17  vs_inState
obj-18  prepend param src_mode

# Per UI param (float and int, in order, excluding internal and bypass):
# n = 0-based index among UI params
obj-(20 + n*3 + 0)   live.dial or live.numbox
obj-(20 + n*3 + 1)   attrui
obj-(20 + n*3 + 2)   label comment
```

---

## Gen Subpatcher Structure

**Source:**
```
gen-obj-1   in 1      (render trigger)
gen-obj-2   r dim     (aspect correction)
gen-obj-3   codebox   (numinlets=2)
gen-obj-4   out 1
```

**Processor:**
```
gen-obj-1   in 1      (texture inlet)
gen-obj-2   codebox   (numinlets=1)
gen-obj-3   out 1
```

**Dual:**
```
gen-obj-1   in 1      (texture from vs_inState — real or vs_black fallback)
gen-obj-2   codebox   (numinlets=1)
gen-obj-3   out 1
```

---

## Signal Flow by Archetype

**Source:**
```
inlet → routepass → pix in0                          [render trigger]
routepass unmatched → route → dials → attrui → pix in0
bypass_toggle → attrui (bypass) → pix in0
r dim → codebox inlet 1                              [inside gen]
pix out0 → outlet
```

**Processor:**
```
inlet → routepass → pix in0                          [texture]
routepass unmatched → route → dials → attrui → pix in0
bypass_toggle → attrui (bypass) → pix in0
pix out0 → outlet
```

**Dual:**
```
inlet → routepass → vs_inState → pix in0             [texture or vs_black]
vs_inState outlet 1 → prepend param src_mode → pix in0
routepass unmatched → route → dials → attrui → pix in0
bypass_toggle → attrui (bypass) → pix in0
pix out0 → outlet
```

---

## UI Layout

```
x position per param:  4 + param_index * 37
dial rect:             [x, 22, 27, 43]
label rect:            [x - 2, 64, 35, 18]
panel rect:            [0, 0, presentation_width, presentation_height]
title rect:            [-1.5, 0, 54, 21]
bypass jsui rect:      [presentation_width - 22, 5, 18, 12]
```

---

## Edit-View Layout

**Implemented 2026-09-24** — `build/layout.py`, called at the end of `build()`; spec and decisions in
`.specify/build_layout/spec.md`. The pass rewrites `patching_rect` only (never `presentation_rect`,
ids, box order or lines; `assert_unchanged()` enforces it inside `build()`), placing boxes by role
from the `{id: (role, idx)}` dict returned by `assign_roles()`:

```
signal strip : left rail (x=30): inlet y=20, routepass y=70, instate/r draw y=120
               modulation band (x=260+170*i): mod inlet y=20, vs_inState y=70, state prepend y=120
param lane   : column k centre x = 60 + 72*k   (label y=180 / route y=204 / control y=250 / attrui y=310)
               route width = n_route*72 + 7 so outlet k sits over column k; attrui fixed 68 px wide
pix stack    : y=380, layered +50 per level by cross-pix wires; outlets 50 below the deepest
range tiers  : one block per range_tiers param below the outlets (msg -> dial wires go upward by design)
service      : x >= max(lane, mod band, 700) + 60: moduleSize chain, autopattr, bypass, panel toggle, title, panel
overflow     : raw_boxes (ids not in roles) moved as one block below everything
```

Definition key: `"edit_layout": False` opts a module out (default on). Verification:
`tests/run.sh tests/test_layout.py`. Manual edit-view tweaks in Max are lost on regeneration.

---

## Styling Constants

```python
FONT         = "Ableton Sans Light"
FONT_TITLE   = 12.0
FONT_LABEL   = 9.5
DIAL_COLOR   = [0.8, 0.8, 0.8, 1.0]
BG_COLOR     = [0.0, 0.0, 0.0, 1.0]
BORDER_COLOR = [0.0, 0.03529411765, 0.2274509804, 1.0]
```

---

## Acceptance Criteria

- Output file is valid JSON that Max 9 loads without errors
- All params addressable by name message on inlet 0 (e.g. `freq 5.0`)
- bypass_toggle.js functions correctly
- autopattr saves and restores state across close/reopen
- moduleSize.js chain fires on load
- Source archetype: codebox renders without upstream texture
- Processor archetype: codebox samples upstream texture correctly
- Dual archetype: `src_mode` updates correctly when inlet is connected/disconnected
- Adding a new patcher requires only writing a definition file — no changes to build_patcher.py

---

## Helpfile Generation Pipeline

_Added 2026-07-19._ This section governs `extract_params.py` +
`generate_helpfiles.py`, not `build_patcher.py` itself — kept in this file
because it's the same "build system" the repo README points to for the
whole pipeline, not just the `.maxpat` generator.

**The rule:** a module cannot get a generated `.maxhelp` until
`docs/f-reference/f_name.md` exists and reflects that module's current
stable state. This is a hard sequencing gate, not a nice-to-have.

**Why:** `docs/f-reference/f_name.md` is the one place dev-time reasoning
(`.specify/f_name/spec.md`'s resolved decisions, `plan.md`/`tasks.md`'s
empirical findings, real signal flow from the built patcher) gets
synthesized into prod-facing language. `generate_helpfiles.py` draws its
prose — descriptions, notes, References block — from that doc, not from
`spec.md`/`plan.md` directly. Skip the doc and the generator has nothing
but mechanical param ranges to work with: a `.maxhelp` that's accurate but
says nothing about why the module exists or what its honest limitations
are. `f_vf_optical_flow.md` is the worked example of what this synthesis
should look like.

**Enforcement:**
- `extract_params.py` marks a module's queue entry `"blocked_no_docs"`
  instead of `"pending"` if `docs/f-reference/f_name.md` doesn't exist —
  visibly excluded from the queue rather than silently generated with a
  placeholder References block.
- `generate_helpfiles.py` independently skips any entry without
  `has_docs=True` before calling the API, even if the queue file was
  hand-edited — reported separately from budget-skips.

**Sequencing in practice:**
```
module reaches stable
    ↓
write/update docs/f-reference/f_name.md
    (params from definition.py + real signal flow + Notes distilled
     from spec.md/plan.md/tasks.md — see f-helpfile skill's
     "Prerequisite" section for what this should contain)
    ↓
extract_params.py f_name       ← queues it (has_docs now true)
    ↓
generate_helpfiles.py f_name   ← generates .maxhelp
```

See also: `skills/f-helpfile/SKILL.md`'s "Prerequisite" section for the
how-to; this section is the why/rule.

**Staleness tracking and the review loop.** Once a module has both a doc
and a helpfile, `extract_params.py --all` compares their mtimes and reports
one of: `current` (helpfile reflects the doc), `stale` (doc edited since
the helpfile was last generated), `pending` (doc exists, no helpfile yet),
or `blocked_no_docs`.

A `stale` result is never auto-regenerated — not by `extract_params.py`
(which only reports status, never writes helpfiles), and not by
`generate_helpfiles.py` in a bulk/unfiltered run, which only picks up
`pending` entries. Regenerating a `stale` helpfile requires naming it
explicitly (`generate_helpfiles.py f_name`) — a deliberate per-module
choice, since regeneration discards any manual edits made directly in Max.

The loop this supports, once a real finding surfaces (from performance,
from opening the module in Max, from anything):
```
edit docs/f-reference/f_name.md with the finding
    ↓
next extract_params.py --all run flags it "stale"
    ↓
explicitly decide to regenerate: generate_helpfiles.py f_name
    ↓
open in Max, review, tweak as needed, save
    ↓
Max's save bumps the .maxhelp's mtime past the doc's — the next audit
run reports it "current" again, with no separate bookkeeping step
```
Conversely: cosmetic tweaks made directly in Max (wording, layout) don't
need a doc update to "settle" — saving in Max is itself what clears
staleness, since it's a plain mtime comparison. Only tweaks that represent
real findings need to be written back into the doc — otherwise that
knowledge exists only in a comment box in Max and could be silently lost
on a future regeneration.

**Full lifecycle, including the eventual `.specify/stable/` move:**
```
module reaches stable
    ↓
write/update docs/f-reference/f_name.md   ← harvest point; confirm it
                                              actually captured everything
                                              worth keeping from spec/plan/tasks
    ↓
extract_params.py f_name → generate_helpfiles.py f_name
    ↓
.specify/f_name/ moved to .specify/stable/f_name/
    (reorganized into that subdirectory, not renamed — see README.md's
     "Repo Structure" section. From this point its spec/plan/tasks content
     is archival — the ADR/decision history — not the active reference;
     docs/f-reference/f_name.md is. Resuming later means moving it back
     to .specify/ root and treating its content as a starting draft, not
     a clean slate.)
```

---

## Source of Truth and Drift

`definition.py` is the source of truth for a module. If you change a patcher by
hand in Max, write the change back into `definition.py` (extending the schema
if it can't yet express it) so that rebuilding reproduces the patcher.

`build/drift.py` checks this without writing anything: it builds each module
in memory (`build_patcher.build` is pure; files a build also generates, such
as the `panel_toggle` JS, come back in a `side_files` dict that only `main()`
writes) and compares the result with the shipped patcher. Boxes are matched by
identity (class, text, parameter name), not by id. `patching_rect` is ignored,
since the edit-view layout is always regenerated. Differences Max introduces by
itself on save (recomputed ports of a `newobj`, saved `restore`/`save` state,
default-valued keys) are normalised away; everything else is drift. A module
with its own `src/<name>/build_*.py` is built by that script's `build()`.

```
build/py.sh build/drift.py            # every shipped patcher
build/py.sh build/drift.py -v f_lens  # with examples of each difference
```

Hand-tuned presentation state has a place to go: see "Overrides" below (`build/capture.py` writes it back).

`tests/test_drift.py` enforces the rule. A module must reproduce exactly unless
it is listed in `tests/drift_baseline.json`, a list that may only shrink and is
meant to be deleted once empty.

## The builder writes what Max writes

So that opening a built patcher in Max and saving it changes nothing (decided with Matt
2026-10-05, from the build_cleanup/T008 round-trip): a float-type `live.numbox` is written with
`parameter_unitstyle` 1 (Float), as Max rewrites 0 to 1; and every inlet and outlet is written
with `index` 0, as Max rewrites every index to 0 and orders the ports by `patching_rect` x.
Because the x order is then the port order, `check_port_order()` runs at the end of every build
and raises if the generated inlets or outlets are not in strictly increasing x order, which would
silently reorder them on the first save in Max. `build/drift.py` keeps treating the old values as
equal to the new ones, since patchers built before this still ship them (and Max rewrites them on
first save). Not yet done: the script-built modules (`f_sirds`, `f_vf_advect`) still write their own
`index` values, and the shipped patchers keep the old values until each is regenerated or saved in Max.

## Overrides: hand-tuned presentation state

**Decision (ADR, 2026-10-05; generic scope approved by Matt 2026-10-04).** A definition may
carry `patcher["overrides"] = {element_key: {property: value}}`: properties applied to the
generated boxes after they are made. It is where hand-tuning done in Max (a compact dial, a
moved jsui, a recoloured label, a resized panel) is written back, so the rule "write the change
back into `definition.py`" has somewhere to put what the schema does not model.

*Why.* Closing drift by extending the schema for every layout tweak does not scale, and
leaving the tweak in the patch only loses it on the next regeneration. Scope is **generic**,
not layout-only: any property, because the next tweak is as likely a colour or a font as a
rect. What stays out is not a property list but an ownership rule (below).

*Element keys* are name-based, from `assign_roles()`: `<param>.ctl`, `<param>.label`,
`<param>.pre`, `<param>.range_menu`, `outlet.<i>`, `mod_inlet.<i>`, `pix.<i>`, and the singletons
`panel`, `title`, `signal_type`, `bypass_jsui`, `route`, `autopattr`, ... Reordering params does
not move an override (box ids, `obj-300+n*10`, do. They are not keys). `build/py.sh
build/capture.py <definition.py> --keys` lists what a module has. `raw_boxes` have no key.

*Applying* (`build_patcher.apply_overrides`, before the edit-view layout pass): any property
except `id`, `maxclass`, `patching_rect` (regenerated every build) and `patcher`; `None`
removes a property. **Loud on every mistake**: an unknown element, an element this build did
not generate, a denied property, an empty dict. Values are deep-copied.

*Capturing* (`build/capture.py`, also `build_patcher.py --capture`): builds the definition
**without** its overrides, matches each generated box to the shipped patcher's by `drift.py`'s
identity rules (so exactly what `drift.py` reports), and writes back the differences. It is
idempotent (it always diffs against the build without overrides) and rewrites only the block
between `# BEGIN overrides` and `# END overrides`; the rest of the file is never touched.

*Ownership rule: capture takes presentation state only.* Captured: the presentation rect,
colours, fonts, dial appearance (`capture.CAPTURE_KEYS`). **Refused, with the reason printed**:
label text, hints, ranges/enums (the definition owns them: edit `params[]`), and `varname` and
`param_connect` (the builder is ahead of the patch, or the patch was edited: regenerate; do
not freeze it as an override). The pilot made the need concrete: of the drift left after
Max's own normalisation, most was `lbl_*` comment varnames the builder now writes and
Max-saved patches lack, and capturing that would have made the stale side permanent.

*Limits.* Only modules built by `build_patcher.build` (not the four with their own
`build_*.py`). Nested properties (inside `saved_attribute_attributes`) are reported, not
captured. A comment's width and height are compared by nothing (Max re-fits them), so a
captured comment rect carries Max's current size.

*Pilot (build_cleanup T012).* `f_chladni` turned out to need nothing: Max's normalisation
alone made it reproduce exactly. `f_vf_fieldmap` (panel size, jsui position, label colour and
size) and `f_vf_warp` (compact dial, label colour) were captured: layout 3 -> 0 and 1 -> 0,
props 11 -> 9 and 4 -> 1; the rest is what capture refuses. Tests: `tests/test_overrides.py`
(10 tests, 14 mutants caught).

## Known Constraints

- Max does not pick up external file edits while a patch is open — close without saving, reopen to load build script output
- `jit.gl.pix` must not have `@dim` attribute
- `routepass` declares only `jit_gl_texture jit_matrix` — no param names
- `bypass` is not in the `route` object — handled by jsui directly
- Internal params must not appear in UI, route, or parameters block
- `vs_inState` outlet 1 fires only on connection state change, not every frame — correct behavior for a Param
- Stale gen code or missing objects after a rebuild: `build/clear_max_cache.sh` clears Max 9's compiled object/package cache (Max must be closed; Max rescans packages on next launch, about a minute)
