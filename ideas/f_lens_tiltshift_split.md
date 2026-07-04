# Splitting tilt-shift out of f_lens — from GPU Gems Ch. 23 (Depth of Field)

Sparked by reading GPU Gems Ch. 23 (Demers) against `f_lens`, which
surfaced a placement question Matt had already been mulling independently
of the chapter — not reaching for `f_lens` in practice, traced to
tilt-shift being a structurally separate mechanism bolted onto the module
rather than sharing its identity.

## Correction on the record

Initial read of `f_lens` (via grepping the GenExpr codebox only) wrongly
concluded the module had zero blur capability. Full patcher read found
`obj-15`, `jit.fx.cf.tiltshift vsynth` — a native Jitter effect wired
downstream of the `lens_pix` codebox into the composite outlet. Real blur
exists; the earlier claim was wrong. Noting this so the correction is on
record, not just in chat.

## What f_lens actually has

- **In the GenExpr codebox (`lens_pix`):** aberration (chromatic R/B
  split), distortion (radial warp), transmission (vignette + warm
  shift), surface emboss — all sharing `dist`/`warp_uv` machinery, all
  genuinely center-outward/radial in character. Four mod-texture inlets
  (`in2`-`in5`) already wired into these four effects.
- **Outside the codebox, downstream:** `jit.fx.cf.tiltshift` — a native
  object providing a **position-based gradient blur** (`tilt_axis`,
  `tilt_pos`, `slope` params: band orientation, location, width/falloff).
  Blur driven by screen position, not by any per-pixel depth/focus value.
  Sensible choice for an early build in a pure-2D-texture pipeline with
  no z-buffer.

## The seam

Aberration/distortion/transmission are coupled — same codebox, shared
`dist`/`warp_uv` math, same radial-from-center character. Tilt-shift is
not coupled to any of that — different object, different mechanism
(gradient band vs. radial), only sharing a bypass toggle and a panel.
Matt's "not reaching for it" is the practical symptom of this: the module
bundles two things that don't share a mental model, even though both are
defensibly "things a lens does" by taxonomy.

## How Ch 23's content connects

The chapter's actual novel idea — derive a per-pixel blur radius from a
scalar focus/depth value, gather-blur accordingly (circle-of-confusion) —
doesn't map onto `f_lens`'s existing z-buffer-free context directly, but
it does suggest a natural growth direction for tilt-shift specifically:
a **content-driven focus map** (arbitrary mod texture, same pattern
already used for aberration/distortion/transmission/surface) driving
blur radius, instead of only a fixed screen-position band. That's a
genuinely different, additive capability from the current gradient-band
blur, not a replacement for it — complementary the way `f_vf_streak`/
`f_vf_glow` are complementary rather than one superseding the other.

Chapter is also explicit that the neighbor-aware gather technique has a
known depth-discontinuity bleeding artifact that's only partially
solvable, not something to promise as clean — worth remembering if this
is ever built, so expectations are set honestly from the start.

## Open questions (Matt's, captured verbatim in spirit)

1. **Split or don't split** — pull tilt-shift out of `f_lens` into its
   own module, given it isn't sharing code or a mental model with the
   rest of the module, and Matt isn't reaching for `f_lens` as a result.
2. **Blur engine choice, if split** — keep `jit.fx.cf.tiltshift` as the
   default/proven engine, add a GenExpr focus-map gather-blur as a second
   mode alongside it, or replace it outright. Lower-risk path is likely
   "keep tiltshift as default, add focus-map blur later" given the
   empirical-first, scratch-before-code working style, but not decided.
3. **Does f_lens keep a lightweight tilt-shift after the split**, or lose
   it entirely and point to the new module? Precedent exists in the
   library both ways (some effects single-owner, some appear in more than
   one place) — not decided.
4. **Naming** — `f_tiltshift` names the current mechanism exactly;
   something like `f_focus` leaves room to grow past the gradient-band
   character into other focus-blur approaches (e.g. the content-driven
   focus map above) without a second rename later. Same naming logic as
   the `f_stereogram` -> `f_sirds` rename (pick the name that matches
   where the module is actually going, not just what it does today).

## Status

Tabled — real open architecture question, not yet decided, not yet
scratch-tested. Surfaced independently by Matt before this chapter read;
the chapter mainly supplied one concrete direction (content-driven focus
map) for what a split-out module could grow into, plus the honest
caveat about gather-blur bleeding artifacts.

## Addendum (2026-07-03) — GPU Gems 3 Ch. 28 gives the practical algorithm

GPU Gems 3 Ch. 28 (Hammon, "Practical Post-Process Depth of Field") is
the chapter Vol 1 Ch. 23's own note pointed to for when this is actually
being built — read now, ahead of that decision, since it directly
sharpens what "content-driven focus map" (above) would actually involve.

**Core technique, directly reusable regardless of the split/naming
questions above:** a per-pixel scalar "circle of confusion" (CoC) map —
sourced from a depth buffer in the chapter, but the algorithm doesn't
care where the scalar comes from, it only needs *some* per-pixel blur-
radius value — drives a variable-width gather blur. Exactly the
"content-driven focus map" idea already tabled above, now with a
concrete recipe instead of just a direction.

**The specific, well-scoped piece worth carrying forward: the
foreground-bleed fix.** A naive CoC-driven blur lets in-focus foreground
objects bleed into blurry background halos incorrectly (or vice versa)
at depth discontinuities — the artifact Vol 1 Ch. 23 already flagged as
"known, only partially solvable." Ch. 28's fix: blur the CoC map itself
first (separately from blurring the image), then combine the blurred and
unblurred CoC via `D = 2*max(D0, DB) - D0` (D0 = unblurred CoC, DB =
blurred CoC) before using it to drive the final image blur. This gives a
continuous, discontinuity-softened blur-radius field without needing
per-pixel depth comparisons against neighbors — cheap, and directly
portable to any scalar focus-map input, not just real depth. One final
small blur pass afterward smooths residual corner artifacts (chapter's
own caveat: doesn't fully eliminate them, just dampens).

**Relevance to `f_`:** if/when a content-driven focus-map mode is built
(open question 2 above), this is the concrete algorithm to reach for —
not a novel technique to invent from scratch. The "any scalar source"
framing matters here: `f_` has no depth buffer, but a synthetic
focus-distance map (e.g. radial distance from a screen point, or an
arbitrary painted/generated mod texture — same idiom as the module's
existing mod-tex inlets) would work as the CoC source just as well as a
real depth buffer would, since the chapter's blur-radius derivation only
needs *a* scalar, not specifically a camera-space one.

## Where to resume

Architecture/naming decision (open questions 1-4 above) is the actual
next step, before any file touches production code — consistent with
"discuss architecture before writing code." No spec file created yet
for a prospective new module; this file is the holding place until that
decision is made.
