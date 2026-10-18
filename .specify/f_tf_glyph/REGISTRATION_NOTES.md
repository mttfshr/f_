# REGISTRATION_NOTES — f_tf_glyph

One section per shared file. These are the exact lines the parent should apply
when integrating glyph; this module owns nothing outside `.specify/f_tf_glyph/`,
`tests/modules/tf_glyph/test_tf_glyph.py`, `tests/modules/tf_glyph/bench_tf_glyph.py`,
`docs/f-reference/f_tf_glyph.md`.

## tests/lib/benchdeps.py — DATA dict

Add one entry (mirrors the tensormap/axisflow pattern). **Path updated by the
parent's layout normalization 2026-10-17** (codebox + definition moved to
`src/f_tf_glyph/`; the entry as applied):

```python
    "bench_tf_glyph": _MACHINERY + ["src/f_tf_glyph/codebox_*.gen"],
```

(The module's codebox originally sat in `.specify/f_tf_glyph/` per this
layout section; the parent normalized it to the shipped `src/<name>/`
convention after the build — see the build-path note below.)

## build/build_patcher.py

No change needed. `"signal_type": "tensor in"` works today: the color is keyed
on the first word (`SIGNAL_TYPE_COLORS.get(signal_type.split()[0], ...)`), so
`tensor in` picks up the amber tensor color tensormap T030 added. Confirmed by
reading `build/build_patcher.py:209-214`; nothing to register.

## Module menu registration (src/f_modules/menu.py → build/generate_menu.py)

**PENDING — not performed** (shared file, parent-owned). Per tensormap T033
precedent: add `f_tf_glyph` to `src/f_modules/menu.py` (category: Utilities is
where tensormap landed; `vecfield False`, not in the nabla groups), then run
`python3 build/generate_menu.py`.

## README.md / docs/f-reference/module-inventory.md / HANDOFF.md

**PENDING — not performed** (shared files). Suggested README row, mirroring the
tensormap row style:

```
| `f_tf_glyph` | tensor consumer/debug view — one glyph per grid cell from the raw tensor | ⚠ Unverified |
```

Inventory row and HANDOFF line: status "buildable, tier-1 mirror green (14/14),
tier-2 bench written but not run, tier-3 live judgment pending Matt".

## tests/contracts/bench_modules.py — BYPASS_EXPECT

**PENDING — not performed** (shared file). Once the module is registered for the
module bench, add:

```python
    "f_tf_glyph": ("passthrough-by-design",),  # bypass = source passthrough, not neutral
```

— glyph's `bypass_gate` is a source passthrough (family contract), not a neutral
frame, so it does NOT fit the standard `BYPASS_EXPECT` neutral assertion; it
needs the PARTIAL_BYPASS_BY_DESIGN-style entry the way tensormap's
bypass-leaves-active does. Exact table shape should be copied from how
`f_vf_seeds`' non-neutral bypass case is registered.

## Build-path finding (recorded for the parent; contradicts tasks.md prose)

Tasks.md says `src/f_tf_glyph/definition.py` (Phases "as planned"); the
repo-wide convention check found **shipped definitions live in `src/f_<name>/`
but the f_tf consumer modules' plan files point at `.specify/f_tf_<module>/`**.
Tensormap and axisflow are built from `src/f_tf_tensormap/definition.py`.
Per the build directive, this module's definition.py was written to
`.specify/f_tf_glyph/definition.py` and built with:

```
python3 build/build_patcher.py .specify/f_tf_glyph/definition.py
→ Written: /Users/matt/Github/f_/package/patchers/f_tf_glyph.maxpat
→ JSON-validated: VALID
```

**If the parent wants the definition in `src/f_tf_glyph/` instead** (matching
tensormap/axisflow), move `definition.py` + `codebox_glyph.gen` there and re-run
the same command with the new path; the definition reads its codebox via
`Path(__file__).parent`, so no edit is needed.

## Built artifact

- definition.py: `.specify/f_tf_glyph/definition.py`
- codebox: `.specify/f_tf_glyph/codebox_glyph.gen` (84 statements — far under
  the ~450/250 ceilings)
- built patcher: `package/patchers/f_tf_glyph.maxpat` (JSON-valid)
- Param wiring verified in the built JSON: 6 dials/numbox → `prepend param` →
  `glyph_pix`, `bypass_gate` prepend → pix, `vs_inState` for both texture
  inlets, `driving_inlet` (tensor on outer inlet 0 via routepass, source on
  outer inlet 1), route tokens: `grid glyph_scale thickness softness gate
  max_aspect`, header `signal_type` label "tensor in".