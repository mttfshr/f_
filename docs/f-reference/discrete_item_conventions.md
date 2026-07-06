# Discrete-item module conventions

Design conventions shared across f_grain, f_masonry, f_weave, and f_vf_seeds.
See `ideas/discrete_item_family.md` for the full architectural framework.

---

## OPEN: this doc's f_weave description is stale relative to the shipped module (found 2026-07-05)

**This doc's `softness` and `shape` sections both describe f_weave params that
do not exist in `.specify/f_weave/definition.py`'s shipped param list**
(`density`, `angle`, `weight`, `marklen`, `regularity`, `phase`,
`src_potential`, `bypass` — no `softness`, no `shape`). Either f_weave
shipped without these params (deferred, same as `swing`/`continuity`/
`beats` per `f_weave/spec.md`'s "What Was Dropped and Why"), or they were
removed after this doc was written, or this doc describes a planned-but-
unbuilt design rather than the current build. Whichever it is, the
`softness`/`shape` sections below should not be trusted as descriptions of
the current `f_weave.maxpat` without checking `docs/f-reference/f_weave.md`
and the codebox directly first. Not corrected inline below (would require
knowing which explanation is true) — flagged here so it isn't silently
trusted.

---

## OPEN: cross-module semantic audit needed for `density` / `size`

**Flagged 2026-06-29, not yet resolved.** `density` and `size` (and possibly
other shared names) likely mean different things across modules in ways that
haven't been reconciled:

- f_vf_seeds `density`: log-mapped seed grid spacing (this doc, below).
- f_weave `density`: not yet compared — may be closer in spirit to seeds'
  since weave is also line/grid-based, but needs verification.
- f_grain `size` and `density`: grain's underlying model (Voronoi cell-based,
  era-clock driven) is structurally different from seeds' grid+jitter search,
  so even where param names match, the felt behavior may not.

This is the same kind of naming collision already documented below for
`regularity` and `shape` — sometimes the shared name is intentional (same
concept, different mechanism) and sometimes it's accidental drift that should
be reconciled. Needs a deliberate side-by-side pass across all four modules
before drawing conclusions. Not blocking current work; noting so it doesn't
get lost.

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

**f_vf_seeds `phase`:** Scrolls marks along the field direction (`along` axis),
analogous to f_weave. Range -1–1.

---

## `size` + `stretch` — preferred over independent axis params

**Finding (f_vf_seeds, 2026-06-29):** Independent `weight`/`marklen`-style params
(separate along-axis and across-axis scale controls) are fussy in practice —
dialing one in throws off the other, since both axes interact in how the mark
reads. A single `size` (overall scale) + `stretch` (aspect ratio) pair is more
expressive and less frustrating to use:

```
stretch_factor = 1.0 + stretch;
marklen_eff = size_eff * stretch_factor;   // along axis
weight_eff  = size_eff / stretch_factor;   // across axis
```

`stretch = 0` gives a circular/square mark; increasing stretch elongates along
the field direction while narrowing across, with shape staying roughly
constant in area (squeeze, not independent scale).

This collapses what was previously two item-character params into one
size param plus one shape-character param, and — combined with bipolar
modulation depths (see below) — produces much richer per-seed variation
with fewer, more legible dials.

**Recommendation:** prefer `size` + `stretch` over independent per-axis scale
params in future discrete-item modules and when revisiting f_grain/f_masonry.
The reciprocal relationship (not independent additive) is what keeps the
mark from collapsing to a sliver or ballooning unboundedly as stretch increases.

---

## Bipolar modulation depths

**Finding (f_vf_seeds, 2026-06-29):** Modulation depth params (mod tex →
parameter) read as more expressive when bipolar (-1 to 1) rather than
unipolar (0 to 1), even when the base param they modulate is unipolar.
A bipolar depth lets the mod tex both grow and shrink the base value
around its set point, rather than only adding. Observed directly with
`size_mod` and `stretch_mod` in f_vf_seeds — the bipolar range made the
mod tex's contribution feel much more alive than the unipolar version had.

**Recommendation:** default new modulation-depth params to range -1 to 1
unless there's a specific reason the modulation should only push one direction.

---

## Shape-tex-inlet architecture (external mark footprint)

**Finding (f_vf_seeds, 2026-06-29):** Rather than computing mark geometry
internally (smoothstep edges, profile blends, taper math), a discrete-item
module can accept an external texture as the mark's visual footprint and
sample it in seed-local UV space. This was the core architectural shift in
f_vf_seeds and is a candidate pattern for other discrete-item modules.

**Mechanics:**
1. Project the pixel into the seed-local `(along, across)` frame, as usual.
2. Normalize `along`/`across` into a local UV using the item's size params:
   `local_u = along / marklen_eff * 0.5 + 0.5`, similarly for `local_v`.
3. Gate on UV bounds — pixels outside `[0,1]` in either axis contribute zero.
4. Sample the shape tex at `(local_u, local_v)`; use its color and/or luma
   directly as the mark value (no internal profile/edge logic).

**Canonical shape tex convention:** square domain, mark centered, oriented
rightward (matching the module's default/no-vecfield orientation), any
color. Any upstream texture works as a mark footprint — WFG output, a
camera frame, a gradient, a dedicated jit.gl.pix shape generator — there is
no dedicated "shape generator" module family; the inlet is a generic
texture inlet and existing Vsynth tooling fills it.

**Passthrough convention:** when nothing is connected to the shape inlet,
`src_shape` (the `vs_inState` flag) is 0 and the module outputs black —
consistent with the standard generator bypass convention, not a fallback
internal shape. The module has no opinion about mark appearance without
an external shape tex; it is purely a placement/orientation engine.

**Consequences for other params:**
- `taper`, `shape` (profile blend) params become unnecessary — that
  character moves upstream into whatever generates the shape tex.
- `softness` narrows to a footprint-boundary feather only (see above);
  f_vf_seeds dropped it because the narrow effect didn't justify a dial,
  but the option remains available if a future module wants it.
- Color is preserved through to a dedicated color outlet (mark color);
  a separate luma-only outlet (mark mask) is kept for downstream
  compositing/gating use, per the standard outlet spec.

**When this applies:** modules whose primary creative content is "what does
one item look like" rather than "where are items and how are they arranged"
are good candidates — the shape-tex-inlet pattern cleanly separates those
two concerns. f_grain and f_weave are plausible future candidates per
HANDOFF notes (adding shape/identity tex inlets is already on the radar).


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

**f_vf_seeds — exception:** has no `softness` param. The mark footprint gate
is a hard clip; any edge character (soft or hard) comes from the external
shape tex via the shape-tex-inlet architecture (see below). This was a
deliberate removal, not an oversight — softness only makes sense as a
footprint-boundary feather once shape geometry moves upstream, and that
narrow effect wasn't judged worth a dedicated dial.

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
