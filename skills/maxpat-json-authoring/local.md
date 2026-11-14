# maxpat-json-authoring: f_ notes

Project-specific additions to `SKILL.md`. Not part of the shared skill.

## Context

Most `f_a_` scratch and production work happens without a live Max connection:
patches are built and edited as raw JSON, then handed to Matt to open in Max and
report back. Shipped modules are not hand-authored at all: they are generated
from `src/<module>/definition.py` by `build/build_patcher.py` (see CLAUDE.md,
"Build system rules"). Hand-authored JSON is for scratch and bpatcher-composition
patches only.

## Provenance

- The `numbox` finding: `f_a_ripple` v1 production build, 2026-09-16 (controls
  `band`, `hearing_profile`).
- The `code`-vs-`text` codebox key: `f_a_purr`, 2026-07-27. `_build_purr_scratch.py`
  had it wrong and was flagged stale rather than re-fixed.
- The validation script was first run against the `f_a_ripple` patches (found
  nothing).
- The `param_connect` collisions: `f_formconstants` (`depth`) and `f_wc`
  (`texture`).

## Conventions

- `flonum` is the project default for scratch-patch numeric controls, including
  integer-valued ones.
- For the exact `live.*` box shapes, see `build/build_patcher.py`'s `dial_box` /
  `numbox_box` / `menu_box`.
- Check control tokens against jit.gl.pix's attribute list before the first
  build of a definition, not only before the first open in Max.
