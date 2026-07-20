# f_masonry — Bpatcher Spec

_Last updated: 2026-07-05_
_Status: Working_
_Renamed from f_weave (2026-05-30). Note: a separate, later `f_weave` module now exists in the library under a new name/concept — do not conflate the two._

## Concept

A parametric masonry texture generator — courses (horizontal bands), bond (bricks per course), mortar (gap width), offset (stagger between courses), and per-course drift/animation. Ranges from crisp mechanical regularity (running bond brick, ashlar stone) to organic broken-course structure. Complex spatial deformation (fisheye, spiral, lens) is downstream's job (f_droste, f_mobius, f_lens) — f_masonry produces the clean course structure those processors work on.

**Taxonomy note (carried from HANDOFF):** despite being labeled `archetype: "processor"` in `definition.py`, f_masonry is self-sufficient — it has no real content dependency on its texture inlet (routepass-only render trigger) and bypasses to black, the behavior of a generator. Flagged for correction whenever `build_modules.py`'s CATEGORIES get refined; not yet acted on.

## Parameters

| Name | Type | Range | Default | Description |
|------|------|-------|---------|-------------|
| `courses` | float | 0.0–100.0 | 8.0 | Number of horizontal bands (rows of bricks) |
| `bond` | float | 0.0–100.0 | 8.0 | Number of bricks per course (columns) |
| `offset` | float | 0.0–1.0 | 0.0 | Per-course stagger — 0.5 = half-brick running bond |
| `angle` | float | -360–360 | 0.0 | Field rotation in degrees |
| `skip` | float | 0.0–1.0 | 1.0 | Fraction of courses that are visible (course presence gate) |
| `regularity` | float | 0.0–1.0 | 1.0 | 1=regular grid, 0=random mark positions at same density |
| `drift` | float | 0.0–4.0 | 0.0 | Per-course along-axis drift amount |
| `phase` | float | 0.0–1.0 | 0.0 | Per-course phase offset — primary animation target (drive with vs_lfo) |
| `speed_var` | float | 0.0–10.0 | 0.0 | Per-course speed variation when animated; 0 = all courses move together |
| `mortar` | float | 0.0–1.0 | 0.2 | Gap width between bricks |
| `softness` | float | 0.0–1.0 | 0.0 | Edge feathering — 0=hard, >0=smooth |
| `width` | float | -2.0–2.0 | 0.9 | Brick aspect ratio scale in across-axis |
| `roundness` | float | -2.0–2.0 | 0.0 | 0=rectangular, 1=circular/oval bricks |
| `course_color` | float | 0.0–1.0 | 0.0 | Per-course color randomization amount |
| `brick_color` | float | 0.0–1.0 | 0.0 | Per-brick color randomization amount |
| `course_seed` | float | 0.0–999.0 | 0.0 | Course hash seed — changes color/speed/skip pattern |
| `brick_seed` | float | 0.0–999.0 | 0.0 | Brick hash seed — changes presence/drift pattern |
| `src_mode` | internal | 0/1 | — | Driven by `vs_inState`; not user-facing |
| `bypass` | bypass | 0/1 | 0 | Outputs transparent black (mix to `(0,0,0,0)`) |

Three modulation inlets (A/B/C, texture in) drive per-param `_mod_amt_` deltas on many of the above params (offset, drift, speed_var, regularity, phase, quantize, skip, mortar, softness, width, roundness, course_color, brick_color) — these modulation-amount params are codebox-internal, set via the mod-inlet system rather than the named `route`, and are not independently addressable messages. See `codebox` in `.specify/f_masonry/definition.py` for the full `_eff` accumulation per param.

- **A (slot mod)** — sampled at brick identity coordinates (`in2`); one value per brick, constant within a brick footprint.
- **B (brick mod)** — sampled at intra-brick coordinates (`in3`); tiles per brick face.
- **C (pixel mod)** — sampled at screen-space coordinates (`in4`); continuous, articulated into structural variation by the brick mask.

## Signal Chain

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix

routepass out0 (texture or vs_black) → masonry_pix in0   [render trigger]
routepass unmatched → route <params> → live.dials → prepend param <name> → masonry_pix in0

in1 (slot mod texture, A)  → masonry_pix in2
in2 (brick mod texture, B) → masonry_pix in3
in3 (pixel mod texture, C) → masonry_pix in4

masonry_pix out0 (composite) → out0
masonry_pix out1 (mask)       → out1
```

## Algorithm

Coordinate frame rotates by `angle` into `along`/`across` axes (with `aspect` correction). `across` is quantized into course bands (`band_idx`); `along` is quantized into brick slots (`slot`), staggered per-course by `offset`. Per-course hashes (seeded by `course_seed`) drive `skip` (course presence), `speed_var` (per-course animation rate), and `course_color`. Per-brick hashes (seeded by `brick_seed`) drive `regularity` (regular vs. randomized spacing) and `drift` (positional jitter, via the ADR 7 candidate-search below), and `brick_color`. Brick footprint is a `mix` between a rectangular and rounded (superellipse-like) distance field, gated by `roundness`, sized by `mortar`/`width`, and anti-aliased by a per-pixel-derivative-aware `softness` floor (`aa_width`, computed from screen-space partials of `along`/`across`). `skip`-gated courses are dropped entirely (`cont` gate) before compositing.

## Loose Threads

- **Dead `quantize` control in the live `.maxpat` — confirmed 2026-07-19.** `quantize` was removed from the codebox algorithm entirely in the 2026-07-05 ADR 7 candidate-search redesign (`src/f_masonry/definition.py`'s own header comment: "quantize removed"; no `Param quantize` declared). But the live `.maxpat`'s `quantize` `live.dial`, its `route` entry, and its `prepend quantize`/message wiring are all still present and unremoved — since `f_masonry` is on the never-regenerate-via-`build_patcher.py` list, nobody's gone back to strip the dead UI after the codebox stopped using it. The dial still moves and still sends a message, it just lands on nothing. Not urgent, but a real dangling control — worth removing from the `.maxpat` by hand next time this module is opened for other reasons.
- Known bug (per HANDOFF): square-output artifact at non-square render resolutions — untouched.
- Target-list partitioning for the three modulation inlets is a working hypothesis (structural params → slot space, appearance params → brick/pixel space), not finalized — see `.specify/f_masonry/spec.md`'s Open Questions.
- Angle compensation for slot-mod sampling when `angle≠0` is deferred (sample coordinate doesn't currently correct for rotation).

## Source File

`patchers/f_masonry.maxpat`
