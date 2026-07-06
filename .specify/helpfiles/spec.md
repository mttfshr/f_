# Spec — f_ Helpfiles

## What it does

Every patcher in the f_ library has a corresponding `.maxhelp` file in `help/`. When a user option-clicks an f_ patcher in Max, the helpfile opens and shows:

1. **A working demo** — the patcher wired into a minimal signal chain (source → patcher → preview, plus LFO for time/scalar inlets), demonstrating what it does with default params.
2. **External control reference** — a list of all params addressable via named messages on in0, with correct ranges.
3. **References** — provenance of the math and any external sources consulted, with explicit labeling of original derivations.

## How you know it's working

- Option-clicking the patcher in Max opens the helpfile immediately
- The demo produces visible output without any user configuration
- Param ranges in the External Control Messages block match the actual codebox and live.dial ranges
- References block is accurate and honest — no uncited sources, original derivations labeled as such
- `docs/f_name.md` has a `## References` section that matches and expands on the helpfile block

## Constraints

- Use the `f-helpfile` skill for all layout, font, and structural conventions
- `f_droste.maxhelp` is the canonical template — read it before writing a new helpfile
- Single flat pane layout for all current modules (no tabs unless content genuinely requires it)
- Plain ASCII in reference text — no unicode math symbols
- Helpfiles are generated via Python JSON editing (same toolchain as patchers) — not hand-built in Max
- Ranges in the helpfile must be verified against the actual codebox and attrui, not assumed
- `docs/f_name.md` must have a `## References` section before the helpfile is considered complete
