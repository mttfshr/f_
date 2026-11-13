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
knob <n> row <outlet> <param> <field>      field: amount | chance | wobble | trim
knob <n> group <name>                      the knob sets that group's correlation
```

Row defaults: range from `param` (else 0-1), amount 10, chance 100, wobble 0, group `-`
(none), trim 0, mode `u`, sign `bi`. Use `-` for an omitted field.

- **mode:** `u` uniform re-roll, `d` drunk (bounded walk, reflects at the bounds).
- **sign:** `bi` both ways, `up` only above the base, `down` only below.
- **outlet:** 1-4. One row per outlet and param.
- **trim:** fixed bias, percent of range (a plate's personality). **wobble:** slow leaky
  drift, percent of range, scaled by the global wobble.

## Panel

Fixed strip: roll, seed, amount, chance, wobble, slew. Four assignable knobs (mapped with
`knob` lines, value `k <n> <0..1>`). A 16-bar multislider shows each row's position in its
range, with a label comment. Three `jit.cellblock` grids edit the rows (11 columns x 12),
groups (2 x 6) and knobs (4 x 4). The first grid row is a header. Typing a row in the first
empty line creates it once it has an outlet and a param; clearing the outlet or the param
deletes it. A bad outlet or a duplicate outlet + param is refused and the cell restored.
The engine is the source of truth; an engine-owned `pattr vary_table` keeps the table as
one `restore ...` list.

---

## Not done

- Per-destination bases (a shared base per param name for now).
- Non-float params (menus, toggles); no `mute` line.
- Rate: messages per frame under slew and wobble are unmeasured; plan for a few dozen rows.

## Status

- Offline engine check passes (`tests/modules/f_util_vary/`, sections 1-16; per
  `.specify/f_util_vary/tasks.md`, T001/T002b).
- Live (Matt, 2026-11-12): panel renders, grids show and edit rows; the scratch
  prototype's behaviors passed. Not yet checked live: `roll` with typed rows, the groups
  and knobs grids, row deletion, save and reopen (T003).
- Menu: `Vary` under Routing / Mod, provisional (`G-menu`).
