# Discrete-item module conventions

Design conventions shared across f_grain, f_masonry, f_weave, and f_vf_seeds.
See `ideas/discrete_item_family.md` for the full architectural framework.

---

## `regularity` — shared name, distinct semantics

Both f_weave and f_masonry have a `regularity` param. The name is intentionally
shared (both modules concern themselves with ordered vs. disordered arrangements),
but the semantics differ:

**f_weave `regularity` (0–1):**
Controls per-line phase randomness along the mark axis.
- `regularity = 1.0` — all lines in phase: marks align across lines, grid-like.
- `regularity = 0.0` — each line's marks are independently offset by a random hash,
  fully staggered. Painterly, woven texture.

Implementation: `line_hash = fract(sin(line_idx * 127.1) * 43758.5453) * (1.0 - regularity)`
The hash is stable per line index, so the stagger pattern is consistent across frames.

**f_masonry `regularity` (0–1):**
Controls whether brick presence follows a regular repeating pattern or a
per-brick hash gate.
- `regularity = 1.0` — regular bond: each brick position uses a deterministic
  mark distance (symmetric half-brick rhythm).
- `regularity = 0.0` — random bond: each brick's presence is gated by a per-slot
  hash, breaking the regular course structure.

The two params share a name because both represent the same conceptual axis
(order ↔ disorder in the arrangement), but they operate on different geometric
quantities: mark phase offset in weave, brick presence in masonry.

---

## `phase` — standard animation entry point

`phase` is the standard param name for the primary animation axis in stateless
discrete-item generators. Convention:

- Range: typically -1 to 1 or 0 to 1 depending on the module.
- Meaning: scrolls or advances the item arrangement along its natural animation
  direction without changing the underlying topology.
- Intended use: connect an LFO or signal to `phase` for continuous motion.

**f_weave `phase`:** Scrolls marks along the line direction (`along` axis).
Range -1–1. At phase=0, marks are stationary. Increasing phase scrolls all marks
in the positive along direction.

**f_masonry `phase`:** Per-course phase offset controlling brick position along
the course direction. Range 0–1. Interacts with `speed_var` for per-course
rate variation.

**f_grain:** Uses `era_clock` instead of `phase` — grain's temporal model is
fundamentally different (discrete generation with era-based hash, not smooth scroll).
`era_clock` is driven from `r draw` and advances an integer era index per-cell.
This is a named exception to the `phase` convention; the different name signals
the different temporal character.

**f_vf_seeds (planned):** Will use `phase` to scroll marks along field streamlines,
consistent with weave.

---

## `softness` — edge feather independent of size

`softness` controls the width of the smooth falloff at item edges, independently
of the item's size param (`weight`, `width`, etc.).

- `softness = 0` — hard edge (limited only by analytical AA where implemented).
- `softness > 0` — symmetric feather zone around the edge; mark appears to glow
  or bleed into surrounding space.

**f_weave:** `softness` feathers both the across-line edge (`dist_to_line`) and
the along-line mark endpoint (`dist_to_mark`) simultaneously. Clamped to 0.49
to prevent negative inner radius. The smoothstep is:
`smoothstep(weight + softness, max(weight - softness, 0), dist_to_line)`

**f_grain:** `softness` feathers the Voronoi/circle shape blend coordinate.
Unified control for both shape transition and edge falloff.

**f_masonry:** `softness` adds to an analytical AA floor derived from pixel
frequency — `soft_final = max(softness, aa_width)`. This means softness=0 is
not truly hard; the floor prevents aliasing at high brick counts.

---

## `shape` — item profile blend

`shape` blends the brightness profile across the item cross-section:
- `shape = 0` — flat-top: uniform brightness inside the mark boundary.
- `shape = 1` — raised cosine: brightness peaks at center, smoothly tapers to
  zero at the edge. Calligraphic, ink-on-paper character.

Currently implemented in f_weave only. The raised cosine is:
`cos(clamp(dist_to_line / max(weight, 0.0001), 0, 1) * pi * 0.5)`

f_grain has an analogous concept via the `shape` param (voronoi↔circle blend)
but this controls topology, not brightness profile. The naming collision is
acceptable given the different module characters; f_grain's `shape` is documented
as a topology control, f_weave's as a profile control.
