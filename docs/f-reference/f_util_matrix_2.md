# f_util_matrix_2

**Type:** Utility (modulation routing matrix — MVP 2-source variant)
**Status:** Draft per `.specify/f_util_matrix/spec.md` ("discovery phase required before Phase 2") — a `.maxpat` exists in `patchers/`, but design-level open questions (D001–D004 below) may not be resolved. **Not yet listed in README.md's patch table; found undocumented during a docs audit (2026-07-05).** Confirm actual build state against the spec's open questions before relying on this as finished.

---

## What it does

A modulation routing matrix — the f_ equivalent of a Eurorack CV matrix. Sits between modulation sources (textures) and a consumer f_ bpatcher: takes N texture inlets, presents a jsui grid of source rows × param columns, and outputs the same N textures pass-through plus scalar modulation messages telling the consumer which texture to sample for which param and at what depth.

**A router, not a mixer** — one source drives one destination per connection; a second assignment to the same destination column overwrites the first (no additive many-to-one).

`f_util_matrix_2` is the MVP: 2 fixed source rows (A, B), up to 16 dynamic param columns discovered from the consumer.

---

## Interface

| Port | Description |
|---|---|
| Texture inlets 0–1 | One per source (A, B). Passed through unchanged to the matching outlet. |
| Control inlet (inlet 2) | `params <name1> <name2> ...` — consumer reports its modulatable params, rebuilding UI columns. `bypass 1/0` — zero all output amounts (1) or restore (0). |
| Texture outlets 0–1 | Pass-through of each source texture, index-matched to inlets. |
| Message outlet (outlet 2) | Sequential scalar messages per active (non-zero) cell: `<param> <source_idx> <amount>`, e.g. `mortar 0 0.6`. Emitted only on cell change; zero-amount cells emit nothing. |

Amounts are bipolar, -1.0 to 1.0, one non-zero cell per column (router constraint — setting a cell clears any other non-zero cell in the same column).

---

## Consumer contract

For an f_ bpatcher to work with this matrix it must: have `autopattr`; report its param list on load (`params <names...>` to the matrix control inlet); accept `<param> <source_idx> <amount>` messages, routing on param name and storing `source_idx`/`amount`; expose one mod texture inlet per source, wired from the matrix's texture outlets; and apply modulation in its codebox as:

```
param_eff = clamp(param + sample(in[source_idx], coord).r * amount, min, max)
```

---

## Open Questions (per spec.md — not confirmed resolved)

- **D001:** Can the matrix query a consumer's `autopattr` remotely instead of requiring an explicit `params` message?
- **D002:** What form should the consumer-side contract abstraction take (sub-patcher, JS, or Max abstraction)?
- **D003:** How do native Vsynth named texture inlets combine (additive/replace/multiplicative)? — relevant to a planned sibling tool, `f_util_router`, not yet built.
- **D004:** Confirm the `<param> <source_idx> <amount>` message format routes cleanly through Max's `route` object with multiple numeric arguments.

## Notes

- Natural pairing with `f_util_profile` (row/column profile textures feeding matrix inlets A/B) and was originally speced with `f_masonry` as first consumer, per spec.md — not confirmed whether that integration was completed.
- A 4-source variant (`f_util_matrix_4`) and a texture-outlet sibling tool (`f_util_router`) are both explicitly deferred/unspecced.
- Not in `README.md`'s patch table — added as a finding of this documentation pass, not yet cross-checked into README.

## Source File

`patchers/f_util_matrix_2.maxpat`
