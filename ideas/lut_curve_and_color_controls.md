# LUT curves and color-control coverage — from GPU Gems Ch. 22 (Color Controls)

Sparked by reading GPU Gems Ch. 22 (Bjorke) against `f_channel_grader` and
`f_tone_curve`. Checked actual codeboxes, not just module names/README
descriptions — the names turned out to be slightly misleading.

## The chapter's three techniques

1. **Levels** — per-channel `pow()` formula, black/white/gamma inputs
   (Photoshop-authored).
2. **Curves** — arbitrary artist-drawn spline, baked into a **1x256
   dependent-texture LUT**, applied per-channel by sampling the LUT at
   the source pixel's own value. Fully arbitrary shape, not limited to a
   parametric formula.
3. **Multichannel** — grayscale via weighted dot product (Rec. 709:
   `0.222, 0.707, 0.071`), general color-space conversion via 3x3 matrix,
   and a geometric framing: saturation is scale toward/away from the
   `(1,1,1)` gray diagonal, hue is rotation around that same diagonal.

## What f_ actually has — checked directly, not assumed

**`f_channel_grader`** is a proper **lift/gamma/gain** model (per-channel
+ master, applied in that order) — confirmed from the codebox. This is
the modern colorist-standard equivalent of the chapter's Levels formula,
just in current parameterization rather than Photoshop's dated
black/white/gamma framing. Full coverage, not a gap — existing practice
here is already correct and arguably more idiomatic than the chapter.

**`f_tone_curve`**, despite its name, is **not a curve** — confirmed from
the codebox: it's a 3-band (shadows/midtones/highlights) smoothstep-
weighted additive lift keyed on luma (`lum = 0.299*r + 0.587*g +
0.114*b`, Rec. 601 weights). It can shift bands relative to each other
but cannot express an arbitrary shape — no S-curves, no per-channel
divergent remaps (the chapter's cross-processing example), no
posterization. This is a real, specific, well-bounded gap.

## The finding

No module in `f_` implements a true dependent-texture LUT curve. This is
cheap given `sample()` is already the core primitive everywhere — a 1xN
texture, sampled per-channel using the source channel's own value as the
U coordinate, gives fully arbitrary per-channel remapping that the
current 3-band model structurally cannot reach.

Matt's response on reading this: agrees the `f_tone_curve` name is
misleading, wants to pursue proper curve control for real. A revisit note
has been added to `.specify/f_tone_curve/definition.py` pointing back
here.

## Minor aside, logged but not chased

Chapter uses Rec. 709 luma weights (`0.222/0.707/0.071`); `f_tone_curve`
and `f_caustic` both use Rec. 601 (`0.299/0.587/0.114`) — the older SD
standard vs. the modern HD/digital one. Not worth chasing on its own, but
an easy, low-risk correctness update if either module's luma line is
touched for other reasons anyway.

## Open questions to resume with (for f_tone_curve's LUT extension)

- Where does the LUT come from? Options: (a) a small set of built-in
  curve shapes (S-curve, inverse, posterize) exposed as presets/params,
  (b) an actual editable curve UI in Max (more work, more flexible), (c)
  accept an external texture as a LUT source (most flexible, least
  built-in control, follows the shape-tex-inlet precedent already used in
  `f_vf_seeds`).
- Does this replace the existing 3-band lift model, sit alongside it as a
  second mode, or does the 3-band model get folded into being one of
  several LUT presets? (Same "mode vs. sibling module vs. fold-in"
  question shape as the Voronoi/bombing and glow-afterimage notes — worth
  checking those for how the tradeoff was framed before deciding here.)
- Per-channel LUTs (true independent R/G/B curves, chapter's
  cross-processing use case) or one shared luma-driven curve to start?
- Worth reconciling the Rec 601 vs Rec 709 luma-weight inconsistency at
  the same time, since any touch to this module's luma line is a natural
  point to do it.

## Addendum (2026-07-03) — GPU Gems 2 Ch. 24, 3D LUTs extend this same thread

Read as part of the GPU Gems 2 sweep, flagged in the backlog against
`f_tone_curve`/`f_channel_grader`. Confirms and extends the finding
above rather than opening a separate thread.

**What's new here, not already covered above:** Ch. 24 (Selan) is
specifically about **3D LUTs** — a single dependent texture read into a
cube-indexed 3D texture (`tex3D(lut, scale * rawColor + offset)`),
where the whole RGB triple indexes the table at once. This expresses
transforms the 1D-per-channel curve idea above structurally cannot:
anything with cross-channel coupling — hue rotation, saturation
scale-toward-gray-diagonal, gamut warps, "primary grading" color-balance
looks. A 1D LUT (per-channel, independent) can only ever express
channel-independent remaps; a 3D LUT can express arbitrary
`RGB -> RGB` mappings, at the cost of a much bigger table (their
example: 32×32×32 = 32,768 entries vs. 256 for a 1D LUT) and requiring
correct half-texel scale/offset math to avoid edge clamping artifacts
(`scale = (lutSize-1)/lutSize`, `offset = 1/(2*lutSize)` — confirmed
necessary, not optional, per their Figure 24-5 discussion).

**Practical implication for `f_`:** a 3D LUT is a strictly more powerful
generalization of the 1D-curve idea already tabled above — potentially
a single mechanism that could subsume `f_tone_curve`'s per-channel
remap *and* something like a hue/saturation grade in one dependent
read, rather than three separate modules each reaching for their own
piece of "color grading." Not proposed as a replacement for
`f_channel_grader` (lift/gamma/gain is still the right *authoring*
model — someone still has to generate the LUT contents somehow; Ch.
24's own §24.2.3 punts on this entirely, treating the identity 3D LUT
as a proxy image run through *some* existing color pipeline to bake the
table) — this is about the *application* mechanism, not the authoring
UI.

**UNVERIFIED, real blocker before this is even a candidate:** whether
GenExpr / `jit.gl.pix` codeboxes can sample a 3D texture at all (a true
`sampler3D`/`tex3D` equivalent), and whether Vsynth's texture pipeline
has any convention for feeding one in (none of the existing `f_`
modules use a 3D texture inlet — everything is 2D `jit.gl.texture`).
This needs a direct check (GenExpr operator reference / a scratch test)
before it's worth discussing architecture — could easily be a hard
no if the codebox sandbox doesn't expose 3D sampling.

## Status

Tabled — real finding, module owner wants to pursue it, but no
architecture decided yet. Revisit note lives in
`.specify/f_tone_curve/definition.py`; this file is the fuller research
context behind that note. The 3D LUT addendum is a further-out,
unverified extension of the same idea, not an independent thread — take
the 1D per-channel curve as the near-term target and treat 3D LUTs as a
"maybe, later, pending a hard feasibility check" direction.
