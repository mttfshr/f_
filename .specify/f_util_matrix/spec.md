# Spec: f_util_matrix

_Created: 2026-06-02_
_Status: Draft — discovery phase required before Phase 2_

---

## What it does

`f_util_matrix` is a modulation routing matrix — a standalone bpatcher that
sits between modulation sources (textures) and a consumer f_ bpatcher. It
takes N texture inlets, presents a 2D UI grid of source rows × param columns,
and outputs the same N textures (pass-through) plus scalar modulation messages
that tell the consumer which texture to sample for which param and at what
amount.

It is the f_ equivalent of a eurorack CV matrix. It owns routing topology and
amount scaling entirely. Consumers are decoupled from source selection logic.

**It is a router, not a mixer.** One source drives one destination per
connection. Many-to-one (multiple sources accumulating into one param) is not
supported — a second assignment to the same destination overwrites the first.

---

## Sibling tool

**`f_util_router`** — a related but distinct tool for core Vsynth modules
with named texture inlets. Same jsui grid concept, but outputs textures to
named outlets rather than scalar messages. No consumer contract required.
Spec to be written after f_util_matrix discovery phase.

---

## Motivation

Without a matrix, modulation routing is embedded in each consumer bpatcher:
choosers, depth params, `_eff` variables in the codebox. This approach:
- Is not reusable across patches
- Couples source selection UI to the consumer
- Scales poorly as sources and targets grow

`f_util_matrix` externalizes all of this. Consumers become simple — they
receive textures and scalar amounts and apply them. The matrix owns the UI.

---

## Signal flow

```
source textures (N inlets)
  → pass through → N texture outlets (to consumer mod inlets)

consumer param report (control inlet)
  → matrix builds UI param columns dynamically

jsui grid (source rows × param columns, one amount per cell)
  → one source per destination — routing, not mixing
  → on any cell change: emit scalar messages on message outlet
      sequential messages per active (non-zero) cell:
      "mortar 0 0.6"   ← param name, source index, amount
      "width 1 -0.3"   ← source 1 drives width at -0.3
      consumer routes on param name, samples inlet [source_index],
      applies amount as scale factor in shader
```

---

## Interface

**Texture inlets** (0 to N-1)
One per source. Any texture — profile strip, LFO texture, WFG output, camera.
Passed through unchanged to corresponding texture outlets.

**Control inlet** (inlet N)
- `params mortar drift width regularity offset speed_var phase` — consumer
  reports its modulatable param list; matrix rebuilds UI columns accordingly
- `bypass 1/0` — zero all output amounts (bypass=1) or restore (bypass=0)

**Texture outlets** (0 to N-1)
Pass-through of each source texture. Outlet index matches inlet index.
Consumer wires these to its mod texture inlets.

**Message outlet** (outlet N)
Sequential scalar messages per active cell. Format: `<param> <source_idx> <amount>`
- `mortar 0 0.6` — consumer should sample inlet 0, apply to mortar at scale 0.6
- `width 1 -0.3` — consumer should sample inlet 1, apply to width at scale -0.3
Emitted on cell change only — consumer stores the last received value.
Zero-amount cells emit nothing.

---

## UI

**jsui grid** — source rows × param columns (dynamic)
- Row labels: source names (A, B, ... fixed or user-assignable)
- Column headers: param names from consumer report
- Each cell: draggable amount, bipolar -1.0 to 1.0
  - Displayed as a filled bar (center = 0, fill direction indicates sign)
  - Double-click to reset to 0
  - Drag vertical to set amount
  - Only one non-zero cell per column (router constraint) — setting a cell
    clears any other non-zero cell in the same column
- Zero cells: visually empty
- Non-zero cells: highlighted

**Bypass toggle** — standard position, top-right
Zeros all amounts in output messages. Stored amounts preserved —
bypass off restores previous state.

---

## MVP scope (2 sources)

First build: `f_util_matrix_2` — 2 texture inlets, 2 texture outlets,
1 control inlet, 1 message outlet. 2 source rows (A and B) fixed.
Param columns dynamic up to 16 destinations.

Larger variants (`f_util_matrix_4` etc.) when concrete use case requires.

---

## Consumer contract

For an f_ bpatcher to participate with `f_util_matrix` it must:

1. **Have `autopattr`** — already true for 7 of 10 f_ patches
2. **Report params on load** — send `params <name1> <name2> ...` to matrix
   control inlet from `loadbang` (or via autopattr query — see D001)
3. **Accept mod messages** — receive `<param> <source_idx> <amount>` on
   control inlet; route on param name; store source_idx and amount
4. **Have mod texture inlets** — one per source, wired from matrix texture
   outlets; consumer samples the indexed inlet in its shader
5. **Apply modulation in codebox**:
   `param_eff = clamp(param + sample(in[source_idx], coord).r * amount, min, max)`

Items 2–5 to be encapsulated in a shared consumer-side abstraction (form
determined by D002 discovery).

---

## Open questions — discovery required

**D001: Param querying**
Can the matrix query the consumer's `autopattr` remotely to discover params,
rather than requiring an explicit `params` message? If yes, simplifies
consumer contract. Investigate Max `pattr` remote enumeration before Phase 2.

**D002: Consumer contract abstraction form**
Sub-patcher, JS file, or Max abstraction? Must handle receiving mod messages,
storing source_idx and amount per param, exposing to codebox.

**D003: f_util_router — Vsynth texture inlet convention**
Before speccing f_util_router, read WFG3 and 2–3 other core Vsynth modules.
How do named texture inlets work — additive, replace, multiplicative?
Determines whether amount scaling happens pre- or post-consumer.

**D004: Message format**
Validate `<param> <source_idx> <amount>` works cleanly with Max `route`.
Confirm routing on first symbol with additional numeric arguments.

---

## Relationship to existing work

**`f_util_profile`** — natural source. Row/col profile textures → matrix
inlets A and B. Matrix routes to consumer params with independent amounts.

**`f_masonry`** — first consumer. M001 chooser/`_eff` approach superseded
by consumer contract. Will be revised in Phase 5.

**`vs_texrouter`** — direct precedent. `f_util_matrix` is texrouter +
amount scaling + param message output. jsui grid pattern reusable.

**`f_util_router`** — sibling tool for core Vsynth modules. Same concept,
different output contract. Spec after Phase 5.

---

## Deferred

- `f_util_matrix_4` (4-source variant)
- Per-cell slew/smoothing on amount changes
- Preset recall for matrix state
- Multiple consumer broadcast
- `f_util_router` full build
