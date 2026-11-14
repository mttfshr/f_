# f_util_row_engine

_Captured 2026-11-13 in chat with Matt, after `f_util_vary` closed. Concept only: nothing built, nothing verified. Read from the docs, not from the other modules' patchers or definitions: every claim about modules other than `f_util_vary` is inferred._
_Status: Idea, parked. Not a gate. Revisit when a second row-table utility is wanted._

## The idea

`f_util_vary` found a shape that works: a **table of rows** owned by a js engine, a **view** that scripts one bpatcher per row, and the table saved through the host's presets. Several utilities already in the docs or the ideas folder are the same table with different columns. One shared engine, with each utility a thin layer that supplies its own columns, would stop each from re-solving the same problems.

## The shape (from `f_util_vary`, observed)

- **The engine is the source of truth.** Rows are views; an edit goes back as `cell <i> <field> <value>`; add and delete are table edits followed by a rebuild.
- **Storage is one plain `pattr` holding the table, saved by the patch's presets `pattrstorage`.** Observed 2026-11-13 (scratch tests, Matt live): a bpatcher does not understand an `embed` message; parameter values do not save in an unembedded host; a `pattr @parameter_enable` blob keeps only the first list item. So the table is saved with presets, not with the patch, and every helpfile should say so.
- **It works because the output is messages.** The destinations take ordinary control messages, so the row count is not fixed by a compiled shape. Vary caps at 12 rows; the message rate under slew and wobble is unmeasured.
- **Refusals live in the engine** (a duplicate outlet + param is refused and the row restored), not in the view.
- **The param menu is the names seen on inlet 0**, not a fixed list.

## Utilities that are the same table (inferred)

| Utility | Moves | Row columns |
|---|---|---|
| `f_util_vary` (built) | scalar bases to 8 outlets | outlet, param, lo, hi, amount, chance, wobble, trim, group, mode, sign |
| `f_util_matrix_2` (draft, hand-built jsui grid) | scalar modulation messages | source, param, amount (one non-zero per param column) |
| tagged-texture router (`ideas/named_mod_textures.md`) | `<param>_tex` tags on texture messages | source, tag, on/off |
| macro / remap | one input to many params | param, lo, hi, curve, invert |
| control-side modulator bank | scalar messages from internal LFOs or walks | source, param, rate, shape, depth |
| strike / trigger table (`f_wave_field` T041, `f_vf_stamp`) | event messages | event, target, message |
| cue list | preset recalls | preset, morph time, trigger |
| scoped presets (`ideas/f_util_scoped_presets.md`) | which params a recall touches | target, in scope |

## Variant: rows that output data, not messages (added 2026-11-13, inferred)

Raised with `f_vf_vortex_multi` (docs read, codebox not opened). It has three hard-coded sites and 12 per-site params plus a shared `falloff`; its own notes list no per-site modulation, no per-site falloff, no more than three sites and no Voronoi mode. A row UI over three fixed sites would only change the panel, the same limit as `f_separate`'s ink count.

What would work: the table writes its rows into a tiny texture, one texel per site (x, y, convergence, curl; later falloff or a per-site mod depth), and the codebox loops over N texels instead of hard-coding three.

- N sites without recompiling, up to a cap; per-site columns close two of the module's listed gaps; presets save the sites by the same route as `f_util_vary`; a modulator-bank layer could animate them in place of three `vsc_center_ctrl` modules.
- This widens the engine's "messages only" rule: the engine would also emit a data texture (the texel write is the new part).
- Other point-placing modules might share it (`f_vf_seeds`, `f_vf_stamp`, `f_stipple`, `f_wave_field` strike points): not checked.
- **Spike questions, none tried:** can a codebox loop over a data texture (`skills/jit-gen-codebox/SKILL.md` covers operators and the statement budget, about 250 per function); does a texel round-trip at float32 without filtering; the per-pixel cost at 1080p with a cap of about 8 sites (unmeasured, as for `f_vf_seeds`).
- `f_vf_vortex_multi` is on `G-bypass-native`; nothing here is blocked, and any change is a new module or a v2 that needs Matt's go.

## What would be shared

The engine's table and `cell` protocol, the row-bpatcher scripting, the `pattr` encoding that survives the first-list-item limit, the param-name discovery, and the rules for refusing a bad row. What each utility owns: its columns, its output logic, its panel strip.

## What it would not cover

- **Anything that changes a compiled shape, with message output only:** `f_separate`'s ink count, outlet counts, `f_masonry`'s 18 mod depths (a row table could only front a fixed Param pool). The data-output variant above is the one way past this, for point-like lists.
- **State outside presets.** The host needs a `pattrstorage`.
- **High message rates**, until measured.
- **`f_texrouter`'s 4x4 toggle grid:** a grid is not better as a list. It is confirmed not in use (Matt, 2026-10-09) and its job is done by a `prepend` if tagged textures win.

## Open questions

- Is the shared engine worth extracting from `f_util_vary`, or should a second utility be built by copying and the common part extracted afterward? Inferred lean: copy first, extract when two exist.
- `f_util_matrix_2` D003 (do sources add, replace or multiply?) is a design question a row table does not answer.
- A chain builder (rows are modules, a recall rebuilds the chain; `f_addmod.js` already scripts modules in) is the largest payoff but breaks the "messages only" assumption: it instantiates GL modules. A spike, not a utility.

## Touches

`P-mod-textures` (tagged-texture assignment), `G-masonry` (the row table as a design for the modulation-depth refactor), `G-ui-density`, `G-drift` (`f_util_matrix_2`, `f_texrouter`). None is cleared or reopened by this note.
