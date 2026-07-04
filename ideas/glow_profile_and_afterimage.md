# Glow profile shaping and temporal afterimage — from GPU Gems Ch. 21 (Real-Time Glow)

Sparked by reading GPU Gems Ch. 21 (James/O'Rorke) against `f_vf_glow`.
Three independently portable ideas, none requiring the chapter's headline
algorithm — richer than a one-liner, so given its own file per the
established pattern.

## The chapter's core technique (does NOT transfer)

Isolate "glow source" pixels into their own texture, then blur with a
**separable 2D Gaussian-like convolution** — decompose a 2D blur into two
1D passes (horizontal, then vertical), reducing cost from `d^2` to `2d`
texture reads. This is a cost optimization specifically for *isotropic,
radially-symmetric* halos around bright points, requiring two render
passes/render targets.

## Why it doesn't apply to f_vf_glow

`f_vf_glow` is a single-pass, 48-tap accumulation strictly along the
local vecfield direction — bidirectional samples at
`uv +/- i*(dx,dy)*jitter` for `i=1..48`, weighted by `exp(-i*i*falloff)`,
normalized. This is inherently a **1D directional streak**, not a 2D
radial blur. It never had the `d^2` cost problem the chapter's technique
solves, because the field direction *is* the one axis it blurs along —
there's nothing to separate. The chapter's headline algorithm has no
purchase here by construction, not by oversight.

## Three secondary ideas that DO transfer, independent of the above

### 1. Dual-curve glow profile (chapter S:21.2.3)
The chapter's actual "glow" look comes from summing two Gaussians of
different width — a smooth broad base plus a second, narrower curve that
produces a bright spike in the center. `f_vf_glow`'s per-step weight is
currently a single curve: `w = exp(-i*i*falloff)`. Replacing this with a
sum of two exponentials at independent falloff rates
(`w = a*exp(-i*i*falloff1) + b*exp(-i*i*falloff2)`) is a same-shape,
same-loop change — likely the single highest-value idea here, since per
the chapter this dual-curve shape is specifically *why* their result
reads as "glow" rather than generic blur.

### 2. Alternate step-weight profiles (chapter S:21.2.3)
Chapter mentions a periodic/sawtooth weighting producing "an interesting
diffraction-like multiple-image effect." Since the weight is already a
per-step scalar inside `f_vf_glow`'s `for` loop, this is a free-standing
character control — swap `exp(-i*i*falloff)` for a periodic function and
get ghosting/multi-tap-echo character instead of smooth falloff. Cheap to
prototype: same accumulation structure, different weight formula.

### 3. After-image / temporal feedback (chapter S:21.5.4)
Feed the *previous frame's* glow output back into the current frame's
source before blurring, dimmed by some decay factor. `f_vf_glow` currently
has zero frame-to-frame memory — it's a pure per-frame spatial
accumulation, reset every frame. This would add genuine cross-frame
persistence/trailing, distinct from `f_vf_advect`'s temporal accumulation
(that's general field-driven fluid advection, not a glow-specific
afterimage tap). Needs a texture-delay mechanism (per HANDOFF's resolved
finding: a feedback loop, unlike a forward chain, does carry a real
one-frame delay via the copy-on-cycle behavior of `jit.gl.pix`/
`jit.gl.slab` — this is exactly the kind of intentional feedback loop
where that delay is expected and usable, not a bug to route around).

(Variable ramping, S:21.5.5 — animating exposed params over time — isn't a
finding specific to this chapter; that's already how every Vsynth module
works via external automation/LFO.)

## Status

Tabled, not scheduled. All three ideas are small, independently testable
changes to `f_vf_glow`'s existing codebox (ideas 1-2) or a genuinely new
mechanism (idea 3, temporal feedback). None require touching the module's
architecture or param set — they're internal to the accumulation loop and
weight function.

## Open questions to resume with

- Idea 1 (dual-curve) seems like the cheapest, highest-value first
  experiment — worth a scratch-patch A/B against the current single-curve
  falloff before touching anything else?
- Idea 3 (afterimage) is the only one that changes `f_vf_glow`'s identity
  meaningfully (adds temporal state to a currently-stateless-per-frame
  module) — worth deciding whether that belongs in `f_vf_glow` itself or
  as a new sibling module, similar to the open question in
  `ideas/voronoi_vs_texture_bombing.md` about where mechanism forks should
  live (same module with a mode, vs. a related-but-distinct module).
- Does idea 3 want its own decay param exposed live, or a fixed/simple
  constant to start?
