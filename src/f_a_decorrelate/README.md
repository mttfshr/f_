# src/f_a_decorrelate

Build inputs of `definition.py` (`archetype: "audio_pfft"`; audio archetype Phase C, 2026-11-16). Edit here,
rebuild with `build/py.sh build/build_patcher.py src/f_a_decorrelate/definition.py`.

- `inner.maxpat`: the `pfft~` subpatch (loaded by name; `pfft~` cannot embed it). Copied byte for byte by the builder to
  `package/patchers/f_a_decorrelate_inner.maxpat`. From the shipped v1 inner file with one change: `index~ fad_gain` /
  `index~ fad_phase` became `index~ #1fad_gain` / `index~ #1fad_phase`, so the buffer names are per instance (the
  `pfft~` box passes `args ---`; unverified in Max, see `.specify/f_a_decorrelate/tasks.md` T016).
- `fragment.json`: the hand-kept control chain (`coll` band table, `gen~` control supplier, `metro`, two `uzi` / `expr`
  sweeps, `peek~` into two `buffer~`s) with an `attach` map from `param:<name>` to [box id, inlet] targets. Extracted
  2026-11-16 from the hand-built v1 patcher; the builder splices it verbatim.

Edits to the v1 chain (2026-11-16, Claude; none touches a formula, the 44100 / 2048 constants or the geomeans):
1. Buffer names `---fad_gain` / `---fad_phase` (`buffer~` and `peek~`): per bpatcher instance.
2. The hand toggle is gone; `metro 50 @active 1` starts itself.
3. **Defects found by reading the v1 patcher (inferred, never run; v1 was only structurally validated, T011):**
   (a) every message box's text began with the word `message` (`message store 1 1000 ...`, `message 44100.`), so `coll` and the
   `expr` would have received a `message` selector; the prefix is removed and the outlettype fixed. (b) `band` went through
   `sel 1 2 ...` (which outputs bangs) into `coll`, and `coll` outlets 1-3 were wired to the three flonums, but `coll` outlet 0
   carries the stored list and outlets 1-3 are not its elements; now `band -> deferlow -> coll -> unpack f f f -> flonums`.
   (c) `deferlow` also orders the lookup after the loadbang-time `store` messages.
4. The `expr` text and `coll` geomeans bake in 44100 Hz and 2048: the module is only right at 44.1 kHz (known limit, not fixed).

Spec and tasks: `.specify/f_a_decorrelate/`. Reference: `docs/f-reference/f_a_decorrelate.md`.
