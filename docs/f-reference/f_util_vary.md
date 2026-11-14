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

**Outlets 0-7**: destinations 1-8. Each sends ordinary module messages (`x 0.13`), wired
straight to a module's inlet 0: no `route`, no `prepend`.

Internal outlets (8-12) feed the panel: row monitor, labels, the `pattr`, the scripted
rows and their controls.

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

### The draw

On every `roll` each row picks a **draw**: a random number from -1 to +1. It is a fraction of
the row's allowed swing, with a direction: +1 is the full swing up, -1 the full swing down,
0 no change, +0.5 half the swing up. The row then sends

    value = base + trim + draw * amount * range  (+ wobble, clamped to lo..hi)

- **Which value:** the base is the last value received on inlet 0 for the row's one param
  (`x 0.5` makes the base of `x` 0.5). A row varies one param on one outlet; every other
  param, and every other outlet, still gets the plain base.
- **Amount** is the allowed swing (percent of the range); the draw is where in that swing
  this roll lands. Example: base 0.5, range 0-1, amount 20%: draw +1 gives 0.7, 0 gives 0.5,
  -1 gives 0.3, +0.5 gives 0.6.

### Groups

A group links rows by sharing the draw. Give rows the same group number (1-4 in the row's
group box; 0 = none). On each roll the engine picks one **shared draw** per group, and each
member's draw is `corr * shared + (1 - corr) * own`, where `corr` is that group's dial
(g1-g4, 0-1; a group the engine creates itself starts at 0.5).

- **corr 1:** every member takes the same draw, so they push the same direction and the same
  fraction of their swings. Each still has its own amount, range, trim and sign, so the
  values sent differ if those differ.
- **corr 0:** the group does nothing; each row draws on its own, as if ungrouped.
- **in between:** a shared part plus an individual part: related, not identical. Mixing two
  random numbers also shrinks the draw (inferred from the formula, not measured): it is
  widest at corr 0 or 1 and narrowest at 0.5, about 70% of the typical size.
- A row with no group is always independent.
- A group shares the draw, not the param: members can sit on different outlets (the same
  param on out 1 and out 2 moving together), on different params (`x` and `y` coupled), or
  both. The group never changes which param or outlet a row varies.
- A group of one row is not useful: with corr above 0 it only replaces part of that row's
  own draw with another random one.

Worked example, five rows with made-up draws (base 0.5, amount 20%, range 0-1, g1 = 1,
g2 = 0.5): row 1 is group 0; rows 2 and 3 are group 1; rows 4 and 5 are group 2.

| Roll | Row 1 (own) | Rows 2, 3 (g1 = 1) | Row 4 | Row 5 |
|---|---|---|---|---|
| shared | none | s1 | s2 | s2 |
| 1 (s1 +0.8, s2 -0.6) | draw +0.3, sends 0.56 | +0.8, both send 0.66 | +0.15, 0.53 | -0.40, 0.42 |
| 2 (s1 -0.5, s2 +0.4) | -0.7, 0.36 | -0.5, both 0.40 | +0.25, 0.55 | +0.50, 0.60 |
| 3 (s1 +0.2, s2 +0.9) | +0.5, 0.60 | +0.2, both 0.54 | +0.05, 0.51 | +0.20, 0.54 |

Rows 2 and 3 are identical every roll; rows 4 and 5 are pulled together by s2 but their own
draws still pull them apart; row 1 is unrelated to the others.

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
- **outlet:** 1-8. One row per outlet and param.
- **trim:** fixed bias, percent of range (a plate's personality). **wobble:** slow leaky
  drift, percent of range, scaled by the global wobble.

## Panel

Fixed strip: roll, seed, amount, chance, wobble, slew. Four group dials (g1-g4) set each
group's correlation. A 16-bar multislider shows each row's position in its range, with a
label comment. The **+** button adds a row (up to 12): the engine scripts one
`f_util_vary_row` bpatcher per row. A row has: out (1-8), param (a menu of the names seen on
inlet 0), lo, hi, four dials (amount %, chance %, wobble %, trim %), mode (off uniform, on
drunk), sign (bi / up / down), group (0 none, 1-4 = g1-g4) and a **-** that deletes it. A new
row has no param and sends nothing until one is chosen; a bad outlet or a duplicate
outlet + param is refused and the row restored.

The engine is the source of truth and keeps the table in a plain `pattr vary_table`. **The table is saved with presets, not with the patch:** if the patch has a `pattrstorage` over it (the Vsynth presets module), storing a preset stores the table, and recalling the preset rebuilds the rows. A plain patch save does not keep it (an unembedded bpatcher keeps no state: scratch tests, Matt, live, 2026-11-13). The strip values each have their own plain `pattr` (`vary_amount`, `vary_chance`, `vary_wobble`, `vary_slew`, `vary_seed`) between the dial and the engine, so the same `pattrstorage` stores them and a recall moves the dials directly; the four group dials have one each too (`vary_g1`–`vary_g4`). Only the rows are in the table. A recalled seed rolls once. A row with no param yet is not saved.

---

## Not done

- Per-destination bases (a shared base per param name for now).
- Non-float params (menus, toggles); no `mute` line.
- Rate: messages per frame under slew and wobble are unmeasured; plan for a few dozen rows.

## Status

- Offline engine check passes (`tests/modules/f_util_vary/`, via `tests/build/test_vary_engine.py`).
- Live (Matt, 2026-11-13): panel, + rows, param menu, roll, delete, all 8 outlets, trim dial,
  lo/hi and mode/sign/group after a preset recall, two copies in one patch, strip and g dials
  back on a recall. Four groups are enough for now (Matt); how to use groups is not yet clear
  to Matt, so the helpfile and this doc should explain them better when revisited.
- Menu: `Vary` under Routing / Mod (Matt: right, 2026-11-13).
