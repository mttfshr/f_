> **Note:** This file was referenced as already existing in HANDOFF.md
> (created "2026-07-03" per a prior session's summary) but was not
> actually present on disk when this session started. Recreated here
> from the HANDOFF summary plus this session's new addendum. Flagging
> the discrepancy rather than silently reconstructing it as if nothing
> happened — worth a quick sanity check of other `ideas/*.md` files
> HANDOFF claims exist, in case this wasn't a one-off.

# Line/edge antialiasing — from GPU Gems 2 Ch. 22 (Fast Prefiltered Lines)

## The chapter's technique (does not transfer directly)

CPU edge-function rasterizer setup, conservative line rasterization, and
a 1D LUT texture for prefiltered line coverage. This is rasterizer-
pipeline machinery with no landing spot in `f_` — `f_weave` has no line
primitives to rasterize, just an analytic per-pixel distance to a
periodic pattern (`dist_to_line`/`dist_to_mark` smoothstep gates).

## The real finding underneath

Checking `f_weave`'s codebox directly against the chapter's Sampling
Theorem section reframed the vague "mark quality is rough" note into
something precise: **the module's `smoothstep` edge width is fixed in UV
space and does not scale with `density_scale`.** This is exactly the
scale-invariance failure the chapter's aliasing analysis describes —
aliasing should worsen as `density` increases, independent of falloff
shape, because the filter width doesn't track the pattern's own spatial
frequency.

Secondary, smaller, independent idea: swap the fixed `smoothstep` for a
Gaussian-like (`erf`-based) filter profile — a pure filter-shape change,
unrelated to the scale-invariance question above.

`f_masonry`'s mortar lines use the same `smoothstep` idiom — flagged as a
likely secondary candidate for the same fix, not checked in detail.

**Original open blocker (as of the prior session):** whether GenExpr
exposes screen-space derivatives (an `fwidth()`-equivalent) needed to fix
this properly. Not checked at the time.

## Addendum (2026-07-03) — GPU Gems 3 Ch. 25 gives the actual recipe

GPU Gems 3 Ch. 25 (Loop & Blinn, "Rendering Vector Art on the GPU") is
mostly Bezier-triangulation machinery that doesn't apply here (needs mesh
triangles, not a per-pixel analytic distance). But its Antialiasing
section (25.5) gives the exact, generalizable formula this file's
blocker was waiting on — and it's not specific to Bezier curves at all,
it works for **any** implicit function `f(x,y) = 0`:

```
sd = f(x, y) / length(float2(ddx(f), ddy(f)))   // signed distance, in pixels
alpha = 0.5 - sd                                 // linear ramp AA
```

`ddx()`/`ddy()` (screen-space partial derivatives) turn the raw value of
an implicit function into a properly scaled distance-to-boundary in
pixel units — this is the `fwidth()`-equivalent this file's open question
asked about, confirmed as the standard technique (not something specific
to GPU Gems 3 — this is the general "analytic derivative AA" recipe used
across the SDF-rendering literature, including Quilez's articles).

**This directly answers the scale-invariance failure diagnosed above:**
a fixed-UV-space `smoothstep` width doesn't scale with `density_scale`
because it has no access to the screen-space derivative of the pattern;
replacing it with a `ddx`/`ddy`-based distance would make the edge width
self-correcting at any density automatically, by construction — not a
tuning fix, a different (correct) mechanism.

**The blocker is still exactly what it was: does GenExpr expose
`ddx()`/`ddy()` or equivalent?** Still not checked — the single next
empirical step before any of this is actionable, now with a confirmed
target formula to test rather than a vague "maybe screen-space
derivatives would help." Same open question applies to `f_masonry`'s
mortar lines and to `f_vf_seeds`' mark-boundary AA (see that module's own
`ideas/f_vf_seeds.md`) — one shared mechanism question behind three
separate quality issues, not three separate investigations.

## Addendum (2026-07-03) — ddx/ddy blocker checked, not promising

Checked Cycling '74's documented Gen operator set before running a live
scratch test: the "Gen Common Operators" page (explicitly the operators
shared across `gen~`, `jit.gen`, `jit.pix`, and `jit.gl.pix`), the
`gen~` operators page, the GenExpr language docs, and a C74 tutorial
that walks through jit.gl.pix's ~130 Gen-only operators by category —
**none mention `ddx`/`ddy`, `dFdx`/`dFdy`, `fwidth`, or any screen-space
derivative operator.** This is also consistent with the
`jit-gen-codebox` skill's empirically-tested operator list, which has
never encountered them (not in valid operators, not in silent
failures, not in hard errors — they've simply never come up).

Plausible structural reason, not just an omission: GenExpr compiles to
both GPU (jit.gl.pix) and CPU (jit.gen) targets from the same source,
and screen-space derivatives are a GPU-fragment-hardware-specific
concept with no CPU equivalent — so it would make sense for Gen's
common operator set to exclude them entirely rather than support them
on only one target.

**Not yet confirmed via a live in-Max scratch test** — that would be
the actual empirical answer per usual practice — but three independent
documentation sources agreeing on total absence is enough to deprioritize
this path without spending a session on it right now.

## Status

**Tabled, not promising.** The `ddx`/`ddy`-based analytic AA formula from
GPU Gems 3 Ch. 25 is likely not implementable in GenExpr as specified —
no documented derivative operator exists in the Gen operator set. If
this is revisited, the first step is still a quick live scratch-patch
test to confirm absence beyond documentation (5 minutes, not a research
session). If confirmed absent, the real next step is a different
mechanism entirely: since `f_weave` already has `density_scale` as an
explicit param, the aliasing rate is knowable analytically without
hardware derivatives — an edge width derived from `density_scale` and
`dim` directly (rather than measured via `ddx`/`ddy`) is the more
promising direction. Not designed yet.

## Cross-references

- `ideas/f_vf_seeds.md` (mark-boundary AA question)
- `ideas/gpu_gems_research.md` — GPU Gems 2 Ch. 22, GPU Gems 3 Ch. 25 entries
