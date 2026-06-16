# Spec: build_patcher.py

_Last updated: 2026-05-30_

## What it does

A general-purpose Python script that reads a patcher definition file and writes a valid Max 9 `.maxpat` JSON file to `patchers/f_<name>.maxpat`. One script generates any f_ bpatcher — new patchers are defined by writing a definition file, not modifying the script.

This is a personal scaffolding tool. It generates the initial patcher correctly and convention-compliantly. After generation, Max owns the `.maxpat` — hand edits in Max are expected and fine. The definition file is a structured intermediate for the build process, not a permanent mirror of the patcher.

---

## Workflow Position

```
scratch patch (iterate codebox)
    ↓
.specify/f_<name>/definition.py   ← patcher definition: codebox + params + archetype
    ↓
tools/build_patcher.py            ← reads definition, writes .maxpat
    ↓
patchers/f_<name>.maxpat          ← distributed artifact; Max owns it from here
```

`.specify/` is gitignored — definition files are private dev workspace. `patchers/` is version controlled and is the distribution artifact.

---

## Inputs

### Definition file

A Python module at `.specify/f_<name>/definition.py` containing a single dict named `patcher`. Imported directly by the build script.

**Required keys:**

```python
patcher = {
    # Identity
    "name":               str,   # e.g. "f_stipple" — used for output filename
    "prefix":             str,   # e.g. "stipple" — param_connect prefix
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
                               # .specify/f_<name>/ for a codebox file
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

**Param ordering rules:**
- `bypass` is always last
- Internal params appear in the list for documentation but generate no UI objects
- UI layout is left-to-right in order of appearance, excluding internal and bypass

---

## Output

`patchers/f_<name>.maxpat` — a valid Max 9 JSON patcher file.

**Required objects in every output patcher:**

| Object | Notes |
|---|---|
| `inlet` (texture in) | comment "texture in", index 0 |
| `outlet` (texture out) | comment "texture out", index 0 |
| `routepass jit_gl_texture jit_matrix` | peels texture from inlet |
| `route <params...>` | dispatches named control messages; bypass absent |
| `jit.gl.pix vsynth @name <object_name>` | shader core with embedded gen subpatcher |
| `autopattr @varname <prefix>_autopattr` | state save/restore |
| `bypass_toggle.js` jsui | bypass UI; wired directly to pix, not through route |
| `live.dial` per float param | with param_connect, varname, parameter_enable |
| `live.numbox` per int param | same wiring pattern as live.dial |
| `prepend param <name>` per param | sends value to pix in0 |
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
obj-8   prepend param bypass
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
obj-(20 + n*3 + 1)   prepend param <name>
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
routepass unmatched → route → dials → prepend → pix in0
bypass_toggle → prepend param bypass → pix in0
r dim → codebox inlet 1                              [inside gen]
pix out0 → outlet
```

**Processor:**
```
inlet → routepass → pix in0                          [texture]
routepass unmatched → route → dials → prepend → pix in0
bypass_toggle → prepend param bypass → pix in0
pix out0 → outlet
```

**Dual:**
```
inlet → routepass → vs_inState → pix in0             [texture or vs_black]
vs_inState outlet 1 → prepend param src_mode → pix in0
routepass unmatched → route → dials → prepend → pix in0
bypass_toggle → prepend param bypass → pix in0
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

## Known Constraints

- Max does not pick up external file edits while a patch is open — close without saving, reopen to load build script output
- `jit.gl.pix` must not have `@dim` attribute
- `routepass` declares only `jit_gl_texture jit_matrix` — no param names
- `bypass` is not in the `route` object — handled by jsui directly
- Internal params must not appear in UI, route, or parameters block
- `vs_inState` outlet 1 fires only on connection state change, not every frame — correct behavior for a Param
