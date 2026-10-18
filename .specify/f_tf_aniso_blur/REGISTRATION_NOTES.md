# REGISTRATION_NOTES — f_tf_aniso_blur

One section per shared file. These are the exact diff-style lines the parent
should apply when integrating aniso_blur; this module owns nothing outside
`.specify/f_tf_aniso_blur/`, `tests/test_tf_aniso_blur.py`,
`tests/bench_tf_aniso_blur.py`, `docs/f-reference/f_tf_aniso_blur.md`.

## tests/harness.py — SHARED, EDITED (one change, disclosed)

`note(label, value)` hardened from `{float(value):.3e}` to `{value}` (it
now accepts numeric and string values; all prior numeric-note output keeps
its format via the callers' own formatting — regression-green: test_harness
4/4, test_tf_tensormap 18/18, test_tf_glyph 14/14, test_fft_separable 9/9
re-run after the change). Reason: the tier-1 mirror's ADR-2 gate data and
T010 pairing notes are string-typed (e.g. `"0.0529 -> 0.0045 (std 0.291)"`),
which the strict-float note crashed on. If the parent prefers the strict
form, re-format my note() calls in `tests/test_tf_aniso_blur.py` to float-
only and revert the harness line — one-file change either way.

## tests/benchdeps.py — DATA dict

Add one entry (mirrors the tensormap/axisflow pattern):

```python
    "bench_tf_aniso_blur": _MACHINERY + ["src/f_tf_aniso_blur/codebox_aniso.gen"],
```
**Path update (parent, 2026-10-17):** codebox + definition moved to
`src/f_tf_aniso_blur/` per the shipped-layout normalization; the DATA line above
reflects the applied path.

Required: `tests/test_benchdeps.py::test_every_real_bench_file_is_registered_and_its_globs_match`
currently FAILS on the first check (`every tests/bench_*.py has a DATA
entry`) until this line lands — the only shared-suite red this module's
deliverables produce. Note: there is no `bench_tf_glyph` entry in DATA
either (glyph's triad left the same gap), so the parent's registration pass
should add BOTH lines. The codebox path is `.specify/...` not `src/...`
(path convention below).

## Build-path finding (the same deviation as all three sibling triads)

Tasks.md Phase 3 prose says `src/f_tf_aniso_blur/definition.py`; the
family's built codeboxes/definitions landed in `.specify/f_tf_<module>/`
(glyph did exactly this and recorded it). This module followed the built
siblings: definition.py and codebox_aniso.gen live in
`.specify/f_tf_aniso_blur/`. If the parent wants the `src/` convention,
move `definition.py` + `codebox_aniso.gen` to `src/f_tf_aniso_blur/` — the
definition reads its codebox via `Path(__file__).parent`, so no edit is
needed; re-run the build command at the new path.

## Built artifact

- definition.py: `.specify/f_tf_aniso_blur/definition.py`
- codebox: `.specify/f_tf_aniso_blur/codebox_aniso.gen` (~77 statements —
  far under the ~450 whole-program / ~250-per-body ceilings)
- built patcher: `package/patchers/f_tf_aniso_blur.maxpat` (JSON-valid,
  `json.load` VALID)
- build invocation:
  `python3 build/build_patcher.py .specify/f_tf_aniso_blur/definition.py`
- Wiring verified in the built JSON: route tokens `strength_scale length
  width_gate floor_pct strength width height`; 5 dials + 2 numboxes + 7
  attrui; bypass jsui (obj-7) → obj-42 `prepend param bypass_gate` → pix
  in0; two vs_inState texture inlets (obj-101 → pix in0, obj-104 → pix
  in1); outlet 0 = pix out 0 direct (automatic primary→outlet wire,
  correct for an ordinary color texture, spec OQ1); 1 jit.gl.pix
  `@name aniso_blur_pix` (gen: in 1, in 2, codebox, out 1). `signal_type
  "tensor in"` picks up tensormap T030's amber colour (first-word key; no
  build_patcher change needed).
- `tests/test_module_contracts.py` (offline, no Max needed — ran it):
  **f_tf_aniso_blur is GREEN** (this module produces no BAD entries;
  the run's only BADs are f_tf_glyph's undriven width/height and
  f_tf_hatch's undriven strength / unused coherence_gate — sibling triads'
  registrations). One rename was driven BY the contract check: the param
  `floor` → `floor_pct` (the attrui's `attr` names the CODEBOX Param, so
  the wire name must match the codebox Param exactly; glyph's `glyph_scale`
  is the shipped precedent — the route token IS the param name).

## build/build_patcher.py

No change needed (same finding as glyph's REGISTRATION_NOTES:
`"signal_type": "tensor in"` works; `driving_inlet` + one mod_inlet is a
supported combination).

## Module menu registration (src/f_modules/menu.py → build/generate_menu.py)

**PENDING — not performed** (shared file, parent-owned). Per tensormap
T033's flow: add `f_tf_aniso_blur` to `src/f_modules/menu.py` (same
category placement as tensormap/glyph — Utilities; `vecfield False`, not in
the nabla groups), then run `python3 build/generate_menu.py`.

## README.md / docs/f-reference/module-inventory.md / HANDOFF.md

**PENDING — not performed** (shared files). Suggested README row, mirroring
the tensormap/glyph row style:

```
| `f_tf_aniso_blur` | tensor consumer — structure-aligned smoother (blur along the grain, isotropic fallback) | ⚠ Unverified |
```

Inventory row and HANDOFF line: status "buildable, tier-1 mirror green
(19/19), tier-2 bench written but not run, tier-3 live judgement pending
Matt; ADR-2 kernel-family gate PROVISIONAL-OPEN".

## ideas/f_tensorfield.md (hub)

**PENDING — not performed** (shared file). Move the anisotropic-blur entry
from the planned-consumers list to built (one row), cross-linking
`docs/f-reference/f_tf_aniso_blur.md`; Chain A's renderer slot documented as
shipped-but-unverified (pending bench + tier-3). NOTE: the working tree
already carries modifications to this file and to
`docs/f-reference/f_tensor_type.md` / `ideas/f_tf_tensor_strategy.md` from
the OTHER triads' coordination — apply this line alongside, don't overwrite.

## tests/bench_modules.py — BYPASS_EXPECT

**PENDING — not performed** (shared file + bench). When the module joins
the module bench, add an entry expressing that bypass = EXACT passthrough of
inlet 1 (not a neutral, not a partial mix) — this module has no encoding of
its own, so its bypass is the strongest passthrough claim in the family.
Copy the shape of whichever registration fits a pure-passthrough expectation
(f_vf_seeds' non-neutral-bypass row style).

## tests/README.md — files list

**PENDING — not performed** (shared file). Optional one-line additions to
the Files list: `test_tf_aniso_blur.py -- tier-1 mirror of f_tf_aniso_blur
(decode, gates, SPD guard, 49-tap kernel vs brute/densified/area truth)` and
`bench_tf_aniso_blur.py -- f_tf_aniso_blur on the GPU vs the mirror
(written, not run)`.

## Shared-test status (for the parent's convenience, no edits needed here)

- `tests/test_drift.py`: the new module is not in drift_baseline.json; the
  test walks baseline-registered modules, so an unregistered NEW patcher is
  invisible to it — the parent's registration pass adds it, and it must
  reproduce from `definition.py` (verified reproducible as of this build;
  the built .maxpat is a byte-child of this definition).
- `tests/test_module_contracts.py`: static route→attrui→Param
  wiring checks over the built patcher JSON; the built JSON's wiring above
  is the expected-green shape, but the RUN is the parent's (offline and
  cheap — runnable any time after registration).