# f_util_compound_dial

_Extracted from scratchpad 2026-06-08. Last updated: 2026-06-09._
_Status: Concept — not yet specced. Blocked on UI density discovery phase._

## Concept

A custom `jsui` widget with two concentric interactive rings — inner ring controls one parameter, outer ring controls a second. Purely a display/interaction compaction: the two parameters are fully independent, each emitting its own named message downstream. The widget doesn't create a new signal routing concept — it lets two related params share a single UI footprint.

---

## Interaction model

**Drag:** up/down to change value, same as `live.dial`. Hit-test on mousedown determines which ring is active: click inside the inner circle → inner param; click in the outer annulus → outer param. No modifier key required.

**Output:** two distinct named messages. MIDI mapping and mod routing attach to those names, not the widget itself — transparent to downstream infrastructure.

---

## Layout (top to bottom)

- **Label** — contextual, not static
- **Dial graphic** — two concentric rings
- **Two numboxes side by side** — left = inner/primary, right = outer/secondary

**Label behavior:**
- At rest: shows primary param name (e.g. "Aberr")
- While dragging outer ring: switches to secondary name (e.g. "Mod")
- On mouseup: snaps back to primary name

**Numboxes:** always visible, always showing both current values. Accept direct text input. Typing in either activates the corresponding ring visually.

**Footprint:** same vertical space as current `live.dial` + numbox pair. Slightly wider to accommodate two numboxes, but dial graphic doesn't grow.

---

## When to use

General-purpose — not inherently amount + mod depth, though that's the obvious case. Key constraint: the two params should belong together conceptually. Overuse makes the UI harder to read, not easier.

---

## Implementation path

`jsui` + `mgraphics` for rendering, mouse handler with radial hit-test. ~200–300 lines of JS. Lives in `javascript/` as `compound_dial.js`, used in bpatchers via `jsui @filename compound_dial.js`.

---

## Open questions

- How does this compose with f_util_matrix when that gets refined? The compound dial might become a cell in a larger grid.
- Should the outer ring have narrower drag sensitivity given its smaller hit area?
- What's the `jsui` presentation_rect — does it fit in the same vertical space as a single `live.dial`?
- Does the outer ring want a narrower value range or slower response than the inner?

---

## Dependencies

Blocked on the UI density discovery phase — don't implement until the broader design question (how to represent parameter relationships densely but intelligibly) is resolved. This widget has a clear home once that closes.
