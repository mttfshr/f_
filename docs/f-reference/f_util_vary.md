# f_util_vary

Control-side variation tool (draft utility). A transparent wire for control messages with
statistical variation added per destination, per parameter. It touches no textures: it
knows nothing about its targets and only moves scalars.

Written from the engine source (`package/javascript/f_util_vary.js`) and the design notes
(`ideas/f_util_vary.md`), offline, 2026-11-13 (Claude). Live status: see "Status" below.

---

## Inputs

**Inlet 0**: bases. Any `<param> <value>` message, the ordinary control message a module
takes (`x 0.1`, `hue 0.5`). A dial, a preset recall or an LFO may drive it. Non-numeric
messages pass to every outlet unchanged.

**Inlet 1**: vary's own settings and table lines (see "Settings" and "Table lines"). Kept
separate so a module param named `amount` or `seed` cannot collide. A line that arrives as
a list led by a symbol is accepted.

The `draw` message (`r draw`) drives the per-frame tick (slew and wobble).

## Outputs

**Outlets 0-3**: destinations 1-4. Each sends ordinary module messages (`x 0.13`), wired
straight to a module's inlet 0: no `route`, no `prepend`.

Internal outlets (4-9) feed the panel: row monitor, labels, the `pattr`, and the three
grids.

---

## Passthrough rule

Every base goes out of **every** outlet. A table row adds variation only to its own
outlet's copy of its own param. No row, `amount` 0 or `chance` 0 all give the plain base,
so with an empty table vary is a transparent wire.

## Effective value

```
effective = clamp(base + trim + offset * amount + wobble, lo, hi)     (in units of the range)
```

- `offset` is held between rolls. It changes on `roll`, and glides there over `slew` ms.
- `draw = corr * (group's shared draw) + (1 - corr) * (the row's own draw)`.
- One global seed; every group and row derives its own streams from it, so `seed N`
  recalls a draw.
- Rows run across outlets: a group is how plates share a draw.

---

## Settings (inlet 1)

| Message | Effect |
|---|---|
| `roll` | New draw for every row (chance-gated), then output |
| `seed <n>` | Reseed, zero offsets, roll ("roll N" recalls a draw) |
| `amount <0-4>` | Global scale on every row's amount (default 1) |
| `chance <0-1>` | Global scale on every row's chance (default 1) |
| `wobble <0-1>` | Global scale on every row's wobble (default 1) |
| `slew <ms>` | Offsets glide to a new value over this time; 0 jumps |
| `refresh` | Re-send every known base through the current table |
| `clear` | Empty the table (bases are kept) |
| `dump` | Post each row's base, offset and group to the Max console |
| `debug <0/1>` | Post outgoing values and raw `cell` lines |

## Table lines (inlet 1)

```
param <name> <lo> <hi>            default range for a param
group <name> <corr 0..1>          1 = members share one draw, 0 = independent
row <outlet> <param> [lo hi amount% chance% wobble% group trim% mode sign]
add                               a blank row (the + button)
cell <i> <field> <value>          an edit from row i's controls (out param lo hi amt chance wob trim group mode sign, or del)
```

Row defaults: range from `param` (else unset: no clamp, and amount is a percentage of the base's own size, 1 when the base is 0; the panel shows an unset side as 0), amount 10, chance 100, wobble 0, group `-`
(none), trim 0, mode `u`, sign `bi`. Use `-` for an omitted field.

- **mode:** `u` uniform re-roll, `d` drunk (bounded walk, reflects at the bounds).
- **sign:** `bi` both ways, `up` only above the base, `down` only below.
- **outlet:** 1-4. One row per outlet and param.
- **trim:** fixed bias, percent of range (a plate's personality). **wobble:** slow leaky
  drift, percent of range, scaled by the global wobble.

## Panel

Fixed strip: roll, seed, amount, chance, wobble, slew. Four group dials (g1-g4) set each
group's correlation. A 16-bar multislider shows each row's position in its range, with a
label comment. The **+** button adds a row (up to 12): the engine scripts one
`f_util_vary_row` bpatcher per row. A row has: out (1-4), param (a menu of the names seen on
inlet 0), lo, hi, four dials (amount %, chance %, wobble %, trim %), mode (off uniform, on
drunk), sign (bi / up / down), group (0 none, 1-4 = g1-g4) and a **-** that deletes it. A new
row has no param and sends nothing until one is chosen; a bad outlet or a duplicate
outlet + param is refused and the row restored.

The engine is the source of truth and keeps the table in a plain `pattr vary_table`. **The table is saved with presets, not with the patch:** if the patch has a `pattrstorage` over it (the Vsynth presets module), storing a preset stores the table, and recalling the preset rebuilds the rows. A plain patch save does not keep it (an unembedded bpatcher keeps no state: scratch tests, Matt, live, 2026-11-13). The strip values (amount, chance, wobble, slew, seed) and the group correlations travel inside the same stored table (a `globals` line), so one store carries the whole module; the engine pushes them back to the dials on a recall. A row with no param yet is not saved.

---

## Not done

- Per-destination bases (a shared base per param name for now).
- Non-float params (menus, toggles); no `mute` line.
- Rate: messages per frame under slew and wobble are unmeasured; plan for a few dozen rows.

## Status

- Offline engine check passes (`tests/modules/f_util_vary/`). The row UI (T004) is built
  offline and has NOT been opened in Max.
- Live (Matt, 2026-11-12): panel renders, grids show and edit rows; the scratch
  prototype's behaviors passed. Not yet checked live: `roll` with typed rows, the groups
  and knobs grids, row deletion, save and reopen (T003).
- Menu: `Vary` under Routing / Mod, provisional (`G-menu`).
