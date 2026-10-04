# Spec: Build, Tools and Test Cleanup

**Status**: Phase 0 done 2026-10-04 (five commits). Phase 1 is next. Task list: `.specify/build_cleanup/tasks.md`.
**Origin**: Matt's request at the end of the 2026-10-02/04 session ("look closely at the build system and the tools"), which turned into a project larger than a few tasks.

## Goal

`definition.py` is the single source of truth for every shipped module, and
`build/`, `tools/`, `tests/` and `src/` are small, supported and honest about
what they do. A patcher in `package/patchers/` is an output that can be
regenerated at any time without losing anything.

## Decisions (Matt, 2026-10-04)

1. **`definition.py` is the source of truth. A hand edit in Max must be written
   back into it**, extending the schema when it cannot yet express the edit.
2. **Layout belongs to `definition.py` too** (not formula-only). Matt:
   "the shape of definition.py is in progress and we want it to hold whatever
   it needs to hold." Max stays the visual editor; the definition records the result.
3. **The drift list is a stopgap**, a ratchet that only shrinks and is deleted
   when empty. It is not a permanent registry of "hand-edited modules".
4. Everything should eventually be generated from `definition.py`, including
   the `f_modules` menu and the four script-built modules.

## Principles

- **`build()` is pure.** Only `main()` and named generators write files.
- **Ratchets, not registries.** A known-issue list has a pointer per entry,
  fails when something new appears, and fails when an entry is fixed (so it
  gets removed). Examples: `KNOWN_ISSUES` in `tests/test_module_contracts.py`,
  `tests/drift_baseline.json`.
- **Generated artifacts are generated.** Menu, launcher (`generate_launch.py`
  is the template: parse a source of truth, validate loudly, `--check`, an
  offline test), helpfile queue.
- **A check must be able to fail.** `harness.check(label, v, tol)` passes when
  `v <= tol`, so `tol=1` also passes at 0. Detection tests assert exact counts
  and get mutation-checked once.

## Done when

- `tests/drift_baseline.json` is empty and deleted; every shipped patcher has a
  `src/<name>/definition.py` and reproduces from it (or from its declared builder).
- `tools/` is gone (menu generated), and no script other than `build_patcher.py`
  `main()` and the named generators can overwrite a shipped patcher.
- The four script-built modules build through `build_patcher.py`, or their
  scripts are documented as the supported builder and still covered by drift.
- Docs (README, `build/spec.md`, `tests/README.md`, `plan.md`, the
  `vsynth-bpatcher` skill) describe the system as it is.

## Not part of this project

New modules; the mod-texture convention decision (`ideas/f_util_mod_texture.md`,
though the five dead `f_masonry` mod cells in `KNOWN_ISSUES` resolve with it);
UI-density redesign; the packaging items in `.specify/packaging/tasks.md`.
