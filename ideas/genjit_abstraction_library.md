# genjit abstraction library

## Idea

GenExpr supports calling `.genjit` abstraction files as functions from within a codebox — the file just needs to be on the Max search path. This opens the door to a shared library of reusable Gen functions across f_ modules.

## Why it's interesting

Currently, math that's shared across modules (e.g. Bessel mode evaluation in f_chladni, polar coordinate setup, sin hash noise) is duplicated per codebox. A shared `.genjit` library would:
- Keep shared math in sync across modules
- Make codeboxes shorter and more readable
- Reduce copy-paste errors when updating math

## Concrete candidates

- **Bessel mode evaluation** — `modal_A` and `modal_B` from f_chladni; if a rectangular plate module or other Bessel-based generator gets built, this math should be shared
- **Polar coordinate setup** — `r, th, env, mask` from UV coordinates; appears in f_chladni, f_vf_vortex family, f_droste
- **Sin hash** — 1D, 2D, and seeded variants; used across grain, stipple, masonry

## Tradeoffs

- `.genjit` files must be on the Max search path to be callable — they'd need to live in the Vsynth package or f_ package structure, not just alongside a patcher
- Adds a packaging and distribution dependency — users need the library files alongside the patchers
- Breaks the current "each patcher is self-contained" model

## When to revisit

When 2-3 modules share the same underlying math and that math has diverged due to independent edits. Until then, duplication is contained enough that the packaging overhead isn't worth it.

## Reference

- GenExpr docs: https://docs.cycling74.com/userguide/gen/gen_genexpr/#abstractions-as-genexpr-functions
- Discovered while reviewing docs during f_chladni build session, 2026-06-18
