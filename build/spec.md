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
| `autopattr @varname <prefix>_autopattr` | state save/restore |
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

## Known Constraints

- Max does not pick up external file edits while a patch is open — close without saving, reopen to load build script output
- `jit.gl.pix` must not have `@dim` attribute
- `routepass` declares only `jit_gl_texture jit_matrix` — no param names
- `bypass` is not in the `route` object — handled by jsui directly
- Internal params must not appear in UI, route, or parameters block
- `vs_inState` outlet 1 fires only on connection state change, not every frame — correct behavior for a Param
