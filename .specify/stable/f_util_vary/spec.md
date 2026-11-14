# Spec: f_util_vary

_Created 2026-11-12._ Design record: `ideas/f_util_vary.md` ("Shipping design: decided"). Scratch prototype: `scratch/experiments/misregister_chain/rand_engine.js` (local; first pass live-checked 2026-11-12, see HANDOFF).

## What it is
A control-side utility: bases in by name on inlet 0, varied copies out per destination. A transparent wire until the table has rows. For misregistration (offset, rotation, spread, density per plate) and any other parameter list.

## Interface
- Inlet 0: `<param> <value>` bases. Inlet 1: settings and table lines. 4 outlets (destinations), each carrying ordinary `<param> <value>` messages.
- Every base goes out of every outlet; a row adds variation to one outlet's copy.
- Row: `row <outlet> <param> lo hi amount chance wobble group trim mode sign`; `param <name> lo hi` defaults; `group <name> <corr>`; one global seed; global amount, chance, wobble scale, slew.
- Table: three editable cellblock grids (rows, groups, knobs), the engine as the source of truth, a `pattr` keeping it; the same lines (`row`, `group`, `param`, `knob`) also work as messages on inlet 1. Four assignable knobs.

## Out of scope for v1
Per-destination bases, non-float params, a grid editor, an add-row button, `mute` lines.
