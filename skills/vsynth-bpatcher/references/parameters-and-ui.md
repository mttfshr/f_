# Parameters and UI

Wiring and naming of controls (attrui, live.dial, live.numbox, header toggles), the `gain`/`mix` convention and the dry/wet formula, signal-type labels and type dots, ranges, and which params earn a panel slot. Part of the vsynth-bpatcher skill.

## Parameter Wiring

Parameters are wired via `attrui` — the preferred convention over `prepend param <name>`. `attrui` sits between the `live.dial` (or `live.numbox`) and `jit.gl.pix in0`, with the attribute name declared on the `attrui` object. This is tidier and more readable than the older `prepend` pattern.

### attrui

```json
{
  "maxclass": "attrui",
  "attr": "<param_name>",
  "numinlets": 1,
  "numoutlets": 1,
  "outlettype": [""],
  "parameter_enable": 0,
  "patching_rect": [x, y, 150.0, 22.0]
}
```

- `attr` — the param name, matching the `Param <name>` declaration in the codebox
- `parameter_enable: 0` — attrui is not itself a Live parameter; the dial above it is
- Output wires to `jit.gl.pix in0`

### live.dial (float params)

```json
{
  "maxclass": "live.dial",
  "parameter_enable": 1,
  "varname": "<param_shortname>",
  "saved_attribute_attributes": {
    "valueof": {
      "parameter_longname": "<param_longname>",
      "parameter_shortname": "<param_shortname>",
      "parameter_mmin": 0.0,
      "parameter_mmax": 1.0,
      "parameter_initial": [0.0],
      "parameter_initial_enable": 1,
      "parameter_linknames": 1,
      "parameter_modmode": 3,
      "parameter_type": 0,
      "parameter_unitstyle": 1
    }
  }
}
```

- `parameter_type`: 0 = float, 1 = int/toggle, 2 = enum
- `parameter_modmode: 3` = relative modulation (standard for dials)
- `varname` = `parameter_shortname`
- Note: `param_connect` is **not** used on live.dial — attrui handles the connection to pix

### live.numbox (integer/seed params)

Use for integer values like seeds, counts, mode selectors. Wires identically to live.dial — through `attrui` → pix in0. In the codebox, use `floor()` to extract the integer value.

```json
{
  "maxclass": "live.numbox",
  "parameter_enable": 1,
  "varname": "<param_shortname>",
  "patching_rect": [x, y, 44.0, 15.0],
  "presentation_rect": [x, y, 34.0, 15.0],
  "saved_attribute_attributes": {
    "valueof": {
      "parameter_longname": "<param_longname>",
      "parameter_shortname": "<param_shortname>",
      "parameter_mmin": 0.0,
      "parameter_mmax": 999.0,
      "parameter_initial": [0.0],
      "parameter_initial_enable": 1,
      "parameter_linknames": 1,
      "parameter_modmode": 3,
      "parameter_type": 0,
      "parameter_unitstyle": 0
    }
  }
}
```

In codebox: `seed_int = floor(seed_param);`

### Canonical naming: `gain` vs `mix` (locked 2026-07-12)

Any module with a composite/blended outlet (source combined with an
effect via add/multiply/etc.) has **two separate, always-separately-
named controls** — never more than these two names, never a synonym:

- **`gain`** — unbounded, can overdrive past 1:1. Controls how intense
  the effect itself is, independent of blend. This is the *only* name
  used for this role anywhere in the library — never `strength`,
  `intensity`, or any other synonym, regardless of what an individual
  module's codebox variable happens to be called internally.
- **`mix`** — bounded 0–100%, `live.numbox` (see below). Controls the
  ratio of source to effect on the composite outlet. Also the *only*
  name used for this role — never `wet`, `strength`, or `blend`.

This was reaffirmed 2026-07-12 after real drift across the rollout:
`f_vf_advect` and `f_chladni` used `gain`; `f_vf_prism` used `strength`
(its own plan called for renaming to `gain` and then abandoned the
rename mid-fix); `f_caustic` used `intensity` for the same role. All of
these are being retrofitted to `gain`. There is no acceptable reason for
two modules to name the same *role* differently — a performer needs to
build one muscle memory for "the intensity knob," not five.

### live.numbox (mix — dry/wet crossfade params)

For `mix` dry/wet blend controls: `live.numbox`, deliberately, not
`live.dial` — a dedicated convention distinct from the float-param
default. Unipolar **0–100%** (not bipolar) — nothing in the additive-
layer dry/wet design (`ideas/dry_wet_gain_and_novel_field_outlet.md`
finding 1) gives a negative range meaning. Wires identically to other
`live.numbox` params — through `attrui` → pix in0.

**Naming collision warning:** `mix` is also the codebox's built-in
blend operator (`mix(a, b, t)`). Declaring `Param mix(100.0)` and then
calling `mix(src, layer, mix / 100.0)` on the same line silently
produces black output — no compile error — confirmed on `f_vf_advect`
2026-07-12 (see `jit-gen-codebox` skill's matching entry). **Always name
the internal codebox `Param` something that doesn't collide** — e.g.
`mix_pct` — while keeping the user-facing label, `attrui` `attr`,
`live.numbox` `varname`, and any external control-message keyword as
plain `mix`. Those live outside the codebox and aren't part of the
collision, so the control still reads "Mix" to the user.

In codebox (additive-layer modules — glow, prism, streak, caustic, etc.),
**final formula, confirmed correct on `f_vf_prism` after five attempts
(2026-07-12)** — see `ideas/dry_wet_gain_and_novel_field_outlet.md`
finding 1 for the full round-by-round history of what was tried first:

```
driven = clamp(src + layer * gain, 0.0, 1.0);   // the COMPLETE composited state, source included
comp   = mix(src, driven, mix_pct / 100.0);      // plain crossfade toward that complete state
```

**Why `driven` must include `src`, not be a bare effect layer**: three
earlier attempts all failed by crossfading toward a *bare, sparse*
effect layer instead:
- `driven = clamp(layer*gain, 0, 1)` with a plain crossfade → produced a
  frame-uniform double exposure at intermediate `mix` values, because
  the bare layer is mostly black/empty and blending toward it visibly
  superimposes two unrelated images.
- Coverage-based "over" compositing (using the layer's own magnitude as
  per-pixel opacity) → still double-imaged, because the soft, feather-
  blurred gate value used as "coverage" rarely reaches a clean 1.0
  across its intentionally-wide transition band, so source kept
  bleeding through even at `mix=100%`.
- Pure additive `src + layer*gain*mix` (mix as an attenuator, no
  crossfade at all) → same superimposition problem, just via a
  different mechanism.

`driven = clamp(src + layer*gain, 0, 1)` sidesteps all three failure
modes because it's a **complete, non-sparse image everywhere** (source
is baked in) — crossfading between two complete images produces a
genuine "N% of the way there" blend with no region where one side is
empty/black, so no double-exposure artifact. Matt's own framing: "an
effect applied 30% isn't the same as an effect applied to 30% of a
masked shape... it bends 30% of the way toward what it would be at
100%." Note this is the *reverse* of what earlier guidance in this
section said — that guidance was wrong, corrected 2026-07-12.

**Open, unresolved question** (flagged on `f_vf_prism`, not fixed): this
`driven` formula is "additive/screen" — light added on top of source.
Whether some effects should instead use "occlusion" (effect locally
replaces source rather than stacking with it) is a real per-module
design question — see `ideas/dry_wet_gain_and_novel_field_outlet.md`
finding 1's vocabulary section, and `f_vf_prism`'s own plan.md "Open
follow-up." `f_vf_advect` was independently unaffected by any of this —
it's replacement-shape (`driven` was already the full
standalone processed result, no separate source term to accidentally
include).

### Vecfield labeling for non-`f_vf_`-prefixed modules

Only the `f_vf_` prefix is reserved for modules whose **primary** output
is a vecfield. A module with a *mixed* outlet set — e.g. `f_chladni`
(luma + vecfield + magnitude) — keeps its plain name but still needs the
vecfield outlet surfaced to users in two places:

1. **Header label** (`definition.py`): set `"signal_type"` to the types that go
   in and out, written as marks: `"∇ in"`, `"∇ out"` or `"∇ in/out"` for a
   vecfield, `"T_ in"`, `"T_ out"` or `"T_ in/out"` for a tensor, and both
   marks for a bridge (`f_tf_axisflow` reads `"T_ in ∇ out"`). The words
   "vecfield" and "tensor" are not used in the title bar (since 2026-10-17).
   `build_patcher.py` draws it 11 pt, right-justified in a 70 px box whose
   right edge sits 4 px left of the bypass button (`button_x`: `pw - 22`, or the
   `bypass_jsui` override's x), at y 0.9 so the baseline matches the 12 pt
   title, and colors it by its first mark (∇ = advect's cyan
   `[0.35, 0.75, 0.95, 1.0]`, `T_` = the tensor amber). There is nothing to
   hand-fix, and no per-module `signal_type` override is needed (the old ones
   were removed 2026-10-17). **Every module also gets two type dots** left of the name (`dot_box`, ids `obj-19f` / `obj-19g`, element
   keys `dot_in` / `dot_out`): round 5 px panels in one column at x 4, 7 px apart. The top one is the type the
   module takes and the bottom one the type it outputs: cyan vecfield, amber tensor, dim gray `DOT_NONE` for
   neither, read from the label by `parse_signal_type`, so a module with no `signal_type` gets two gray dots.
   They must be FOREGROUND panels (`background` 0): a background-layer panel is drawn under the frame panel
   and disappears. Shapes (tensor round, vecfield triangle, none square) were tried, first as panels and then
   as one `jsui`, and read as noisy: the dots are all round. The jsui style is still in the builder
   (`TYPE_DOTS = "jsui"`) with its script parked at `ideas/type_dots.js`. "Outputs a vecfield" means ANY outlet
   that carries one, including a pass-through (f_vf_advect and f_vf_prism have a third outlet that is one:
   they are `∇ in/out`); decide a module's label from the code in the shipped patcher, not from
   `src/*/codebox_v*.gen` (historical versions) or the docs. Every module name starts at
   `TITLE_X` (10.5) to leave room for them; a definition that overrides the
   title must keep that x (and widen the box). A module whose title is hand-placed
   can pin its dots with `dot_in` / `dot_out` presentation_rect overrides
   (f_masonry and f_texrouter do). The frame border stays dark blue
   (`BORDER_BY_TYPE = False`; setting it True restores the tried-and-dropped
   border coloring). A long module title on a narrow panel can still
   run into the label; shorten the title, not the label. `tests/build/test_generate_menu.py` checks that the
   marks in every menu module's label equal that module's menu kinds, so the
   title bar and the menu cannot drift apart.
2. **`f_modules` menu**: in `src/f_modules/menu.py` give the module's entry the
   vecfield kind (`("Chladni", "chladni", V)`, with `V = ("vec",)` defined in `menu.py`), then run
   `build/py.sh build/generate_menu.py` — the kind appends `" ∇"` to its display label. A tensor
   module takes `T` (`" T_"`); a module that reads a tensor and writes a vecfield takes `VT`.

Established 2026-07-12 via `f_chladni`'s `out3`/vecfield labeling pass —
see HANDOFF.md and `.specify/f_chladni/plan.md` for the concrete example.

---

---

## header_toggle (boolean mode param in header area)

For boolean mode switches that live next to the bypass toggle in the header rather than as a dial in the param grid. Introduced in `f_stipple` for the "Displace" mode toggle. Rendered as a `live.toggle` by `build_patcher.py`.

Declared in `definition.py` with `type: "header_toggle"`. The build script positions it in the header area adjacent to bypass, wires it through `route` → `attrui` → pix in0, and registers it in the `parameters` block. In the codebox, read it as a float and threshold at 0.5:

```glsl
Param proc_mode(0.0);  // 0 = off, 1 = on
mode_active = step(0.5, proc_mode);
```

Unlike `bypass`, `header_toggle` params **do** go through `route` and **do** appear in the `parameters` block — they're user-facing params, not system params.

---

## Parameter Ranges: Vsynth Conventions

Check existing Vsynth patchers before choosing ranges:

| Type | Convention | Source |
|---|---|---|
| Angle/rotation | -360–360 degrees | vs_wfg_3, vs_offset+rot, vs_wfg_polarizer |
| 0–1 normalized | 0.0–1.0 | most params |
| Count/frequency (direct) | 0–1000, value = count at angle 0 | f_masonry courses/bond |
| Integer seeds | 0–999, live.numbox | f_masonry course_seed/brick_seed |

Angle codebox mapping: `theta = angle * (PI / 180.0)`

### Not every parameter earns a panel slot

A panel slot is for a **performable lever** — something with expressive range that
Matt reaches for mid-performance. A parameter that is a *correctness* setting fails
that bar even when it is real and measurable: internal filter quality, tap counts,
iteration bounds. The tell is that it does nothing on typical input and, on the input
where it matters, only makes the output more correct — there is no direction to push
it for effect.

Fix those in the shader at a measured default (`Param taps(8)`) and, if the trade-off
should stay reachable by message, keep the route token and drop the widget:
`"ui": False` on the param in `definition.py` (a builder key since 2026-10-05, T016: the
route outlet goes straight to an attrui carrying the param's varname, and the param is
left out of the `parameters` block).
Costs no slot, no label, no preset entry. Note the live module bench can no longer
range-scale such a param's test value (no widget to read `parameter_range` from), so
it sends a raw fraction — the wiring is still checked, the range is not.

Precedent: `f_vf_fluid`'s `taps` was briefly a panel numbox (2026-09-28) and came off
the next day. Also see `jit-gen-codebox` → "a fixed-`@dim` stage is a resampler" for
why that parameter exists at all.

---
