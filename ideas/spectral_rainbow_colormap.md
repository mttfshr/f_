# Spectral rainbow color-mapping — from GPU Gems Ch. 8 (Diffraction)

Sparked by reading GPU Gems Ch. 8 ("Simulating Diffraction," Stam) against
`f_vf_prism`. Narrower in scope than the Voronoi/bombing question — this
is a single portable technique, not an open architecture fork, but real
enough to be worth its own file rather than a backlog one-liner.

## The chapter's technique (the part that transfers)

Stam's diffraction shader is mostly not applicable to f_ — it's a
per-vertex physical model (halfway-vector-to-tangent projection, grating
spacing `d`, Ward anisotropic highlight for the pure-reflection case).
None of that maps onto a 2D vecfield-driven texture processor; it's real
3D-surface machinery.

But buried inside it is a genuinely separable, reusable primitive: a
**rainbow color-map function**. Given a single scalar phase value `u`,
sum a small fixed series (the chapter uses `n = 1..7`) where each term
computes `y = 2u/n - 1` and evaluates three overlapping triangular "bump"
functions (`blend3`) centered around `y = 0.25 / 0.5 / 0.75` to produce
R/G/B. The result is a convincing continuous spectrum — cheap, closed-form,
no lookup texture — driven by one number. This is the actual novel
contribution worth citing, independent of the diffraction-grating physics
that motivates it in the chapter.

## Why this is a real gap in f_vf_prism, not a redundant idea

`f_vf_prism` currently produces color separation by **displacing R/G/B
independently** — R's sample offset rotated by `+spread_eff` around the
vecfield direction, G unrotated, B rotated `-spread_eff` — then an 11-tap
directional blur per channel, threshold-gated. This is a **3-tap RGB
split**: chromatic aberration / fringing, structurally limited to red,
green, and blue bands from the same source pixel. It cannot produce, say,
a yellow-green-cyan band structure the way a real diffraction grating
does, because there's no spectrum synthesis anywhere in the mechanism —
just three offset+blurred copies of one image.

The chapter's bump-function rainbow map is a different kind of tool
entirely: map *any* scalar to a full spectral RGB, not "displace this
channel." `f_vf_prism` already has candidate scalars on hand that could
drive it — field magnitude, field angle, or a manufactured phase-like
value from position along the field direction — none of which are
currently used to select *hue*, only to select *displacement*.

## What this could become (not decided)

Two different directions, worth distinguishing before doing anything:

1. **A new color-mapping mode inside `f_vf_prism`** — replace or
   supplement the RGB-channel-offset mechanism with true spectral
   synthesis driven by field angle/magnitude/phase. Bigger change to an
   existing, working module.
2. **A standalone rainbow/spectral color-map utility function** —
   package the bump-function math as a `.genexpr` helper (per the
   `require()` pattern already documented in `jit-gen-codebox` skill) that
   any module could call to turn a scalar into spectral color. Smaller,
   more general, doesn't touch `f_vf_prism`'s working mechanism at all.
   Could seed a future dedicated iridescence/interference module too
   (the chapter's own suggested extension, per its "natural companion"
   framing).

(2) is lower-risk and more in keeping with "discuss architecture before
writing code" — worth scratch-testing the bump-function math in isolation
first regardless of which direction it ultimately serves.

## Status

Tabled — flagged as genuinely worth pursuing (unlike the Ch 2 / Ch 5 reads,
which were confirmed no-fits). No scratch patch yet. Revisit alongside
other `f_vf_prism`/`f_lens` work, or as a standalone small module
experiment if the rainbow-map math itself becomes interesting on its own.

## Open questions to resume with

- Which scalar (field angle, magnitude, a synthesized phase from position
  along the field direction) produces the most useful/controllable
  spectral response for a live-performance context?
- Does this want to live as a `.genexpr` shared helper from the start, or
  is it simpler to prototype inline in a scratch patch first and factor
  out later?
- Worth checking iquilezles.org for a cleaner/cheaper rainbow bump-function
  formulation before committing to Stam's exact `n=1..7` series — the
  citation practice in `gpu_gems_research.md` wants the actual source used,
  not just the one that was read first.
