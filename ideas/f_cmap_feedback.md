# f_cmap — iterated complex-map feedback pull (working name)

_Status: ⚪ concept only. Drafted 2026-10-23 from the webgpgpu mining run
(`webgpgpu-ideas-1`). Not specced, not tried in Max._

## Concept

Ping-pong a texture and, every frame, replace each pixel with the old image sampled at
its position pushed through a complex map plus an animated offset. History accumulates, so
motion winds up into filaments and spirals that a one-shot warp cannot make. Two maps in
the webgpgpu examples:

- **Square** (`Example_9_quadratic_feedback`): pixel position as a complex number,
  squared, plus an animated offset w (angle, phase and radius driven over time); the pixel
  copies the stored value there. Slowly rotating w gives shifting feedback fringes.
- **Log** (`Example_10_logarithmic_feedback`): position through the complex logarithm
  (angle scaled by 1/2 pi, log of radius, each times 3), plus offset. The old image
  winds into logarithmic spirals around the origin.
- **Out-of-bounds checker**: when the pulled coordinate leaves the domain (magnitude past
  the domain radius) the pixel shows a 128-pixel black-and-white checker instead of
  sampling wrapped or undefined data. In the module this is a toggle or a mask outlet, so
  the performer can treat the out-of-domain zone as its own band.

## What f_ has today

- `f_mobius` and `f_droste`: stateless, one-pass UV transforms (Droste is the
  log-polar spiral zoom). Neither keeps history; neither can wind motion into itself.
- The checker is available as a generator (`f_masonry`-style), but not as an
  out-of-domain fill for a feedback pull.

## Proposed shape

- Either one new module (`f_cmap`: Square and Log modes, offset, decay, bounds mask) or
  a feedback mode on `f_droste` (the log mode is `f_droste`'s resampling run as a ping-pong
  pull). Decision to make: new module versus mode, given the general-tool taste and the
  fact that Square has no home in `f_droste`.
- Signature: texture -> texture (+ optional mask scalar), temporal.
- Dials: map (Square / Log), offset rate, offset radius, spiral twist, decay,
  bounds style (wrap, checker, black).
- Float32 ping-pong replaces the web's 8-bit targets (the web version's sub-half-step
  decays stall under 8-bit re-quantization; no longer an issue).
- A bare `sample()` wraps in pix chains, which matches the examples' repeat wrapping;
  check seam texels against the 2026-10-20 sampling findings in the skill before trusting
  the seam.
- Speculative (my addition): pulling an image repeatedly through z^2 + w is the
  Julia-set construction, so the offset dial is a Julia parameter; a good tier-3 look.

## Tier-1 checks

- Fixed points of the square map satisfy z = z^2 + w.
- Log mode: angular winding per iteration follows the 3/(2 pi)-scaled `atan`; spiral pitch
  matches simulated iterates.
- Bounds mask is exactly the set where the mapped magnitude exceeds the domain radius
  (the checker itself is judgment only).

## Risks and open questions

- Origin branch cut: the same seam family as `droste_singularity.md`; history can band
  along the cut.
- Smeary results: the useful decay/offset region may be narrow and needs benching.
- A verifier reply on a neighbouring record (`Example_18`: a three-pass feedback chain with
  `f_mobius`) found a mislabeled state encoding (8-bit shown as float); the idea survives,
  but source records for this theme deserve a second look before any numbers are quoted.

## Related

`f_mobius`, `f_droste`, `droste_singularity.md`, `vecfield_aware_uv_warps.md`,
`f_conformal_fill.md`.

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 37, 02, 03. Verified by subagents against the
example files and the f_ inventory.
