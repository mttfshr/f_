# Plan: f_util_matrix

_Created: 2026-06-02_
_Status: Draft — D001 resolved; D002–D004 remain_

---

## Architecture decisions (locked)

**ADR-1: Router not mixer**
The matrix routes one source to one destination with a scaling amount.
It does not accumulate multiple sources into one destination. Many-to-one
is not supported — second assignment overwrites first, or is disallowed in UI.

**ADR-2: Two separate tools**
`f_util_matrix` — for f_ patches implementing the consumer contract.
`f_util_router` — for core Vsynth modules with named texture inlets.
No mode switch, no hybrid. Clean separation of concerns.

**ADR-3: Matrix is a router with scaling**
The texture flows through unchanged. The amount is a static attenuverter
per connection — a scale factor applied by the consumer, not by the matrix.
The matrix never samples textures. Dynamism comes from texture content only.

**ADR-4: Output format**
Per active connection, matrix emits: `<param> <source_idx> <amount>`
Consumer routes on param name, uses source_idx to know which texture inlet
to sample, applies amount as scale factor in shader.

**ADR-5: Fixed source count, dynamic param count**
Source inlets fixed at build time (MVP: 2). Param destinations dynamic —
discovered via pattrstorage dump (ADR-8). jsui redraws on discovery.

**ADR-6: Consumer contract**
f_ patches implement: `autopattr` + named `pattr` objects per param, mod
message handler, texture mod inlets, `_eff` vars in codebox. Encapsulated
in a shared abstraction (form TBD per D002). No explicit param reporting
needed — matrix discovers params via pattrstorage dump (ADR-8).

**ADR-7: Bypass = zero amounts**
Bypass zeroes all output amounts. Stored amounts preserved — bypass off
restores previous state. Consumer reverts to base params.

---

**ADR-8: Param enumeration via pattrstorage dump**
The matrix discovers consumer params by sending `dump` to its own top-level
`pattrstorage @greedy 1`. The dump output is a series of messages in the form
`bpatcherScriptingName::paramName value`, terminated by `dump done`.
The matrix filters for the connected consumer's scripting name prefix to get
the param list. No explicit `params` message from the consumer is needed.
Consumer contract requirement: `autopattr` + named `pattr` objects (no
pattrstorage of its own — that leaks internal objects into the dump).

---

**ADR-9: Consumer contract abstraction form**
JS file (`f_util_mod_handler.js`). One instance per consumer patch.
Inlet 0: mod assignments from matrix (`<param> <source_idx> <amount>`).
Inlet 1: base values from dials, via `prepend <paramname>` per dial.
Stores `{param: amount}` dict; source_idx ignored (amount is the scalar).
Outlet 0: `param foo_mod_amt <amount>` and `param foo <base>` → pix in0.
Codebox convention per modulatable param:
  `Param foo; Param foo_mod_amt; float foo_eff = foo + foo_mod_amt;`
`clear` message zeros all mod params. `dump` posts state to console.

---

## Open — requires discovery before Phase 2

**D001: Param querying — RESOLVED ✓**
Top-level `pattrstorage @greedy 1` + `dump` enumerates all consumer params
as `dummy_consumer::mortar 0`, `dummy_consumer::drift 0`, etc.
Consumer needs only `autopattr` + named `pattr` objects. No loadbang report.
Matrix queries by dumping its own pattrstorage and filtering by consumer prefix.
See ADR-8. Scratch patch: `d001_pattr_discovery.maxpat` / `d001_consumer.maxpat`.

**D002: Consumer contract abstraction — RESOLVED ✓**
JS file. See ADR-9. File: `code/f_util_mod_handler.js`.

**D003: f_util_router — Vsynth texture inlet convention — RESOLVED ✓**
Consistent across all WFG variants (wfg3, wfg_saw, wfg_ramp, wfg_sine, etc.)
and shape genjit files. `in 2` → `* fm`, `in 3` → `* pm`: texture inlet value
is multiplied by the corresponding param scalar. Convention: `param * tex_value`.
Implication for f_util_router: amount scaling belongs in the consumer (post-receive),
not in the router. Router passes texture through unchanged; consumer applies `* amount`.

**D004: Message format validation — RESOLVED ✓**
`route` routes on first element of a message. `mortar 0 0.6` → `route mortar`
matches and passes `0 0.6` as a two-element list. Works correctly in Max.
`mod <param> <source_idx> <amount>` alternative unnecessary — matrix outlet
is a dedicated connection, not shared with other control. ADR-4 unchanged.

---

## Phases

### Phase 1 — Discovery
Resolve D001–D004 before any build work.
Output: discovery notes added to this plan, ADRs updated or added.

### Phase 2 — jsui design
Design the matrix grid UI:
- Source rows, param columns (or transposed?)
- Cell interaction: drag to set amount, double-click to clear, visual feedback
- Row/column labels
- Active connection highlighting
- Bypass state display
Output: jsui sketch verified in a scratch patch.

### Phase 3 — Consumer contract abstraction
Build the shared consumer-side abstraction:
- Receives `<param> <source_idx> <amount>` messages
- Stores amounts as named floats
- Exposes them to codebox
Output: working abstraction verified in a scratch patch with a dummy consumer.

### Phase 4 — f_util_matrix_2 build
Build the 2-source MVP:
- 2 texture inlets/outlets
- Control inlet for param report
- jsui grid
- Message outlet
- Bypass
Output: `f_util_matrix_2.maxpat` in patchers/

### Phase 5 — f_masonry integration
Revise f_masonry to implement consumer contract.
Replace M001 chooser/`_eff` approach with contract-based approach.
Wire f_util_profile → f_util_matrix_2 → f_masonry.
Output: working signal chain, both patches updated.

### Phase 6 — f_util_router spec and build
After f_util_matrix validated, spec and build f_util_router for core
Vsynth modules. Discovery D003 must be complete first.

---

## Signal flow (f_util_matrix_2)

```
inlet 0 (source A texture) ──────────────────────────────→ outlet 0 (source A passthrough)
inlet 1 (source B texture) ──────────────────────────────→ outlet 1 (source B passthrough)
inlet 2 (control)
  → "bypass 1/0"                  → zero/restore output amounts

pattrstorage @greedy 1 (top-level, in matrix patch)
  → on load / on demand: send "dump"
  → filters output for connected consumer scripting name prefix
  → extracts param names → jsui rebuilds param columns

jsui (source rows × param columns, amounts per cell)
  → on cell change:
      → outlet 2 (message outlet):
          sequential messages per active cell:
          "mortar 0 0.6"   (param, source_idx, amount)
          "width 1 -0.3"   (param, source_idx, amount)
          ...
```

---

## Relationship to existing work

- `vs_texrouter` — routing matrix precedent; jsui grid pattern reusable
- `f_util_profile` — natural source; row/col profile textures → matrix inlets
- `f_masonry` — first consumer; M001 work to be revised per contract
- `f_util_router` — sibling tool for Vsynth modules; spec after Phase 5
