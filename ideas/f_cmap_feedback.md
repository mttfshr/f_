# f_cmap — iterated complex-map feedback pull (working name)

_Status: ⏸ PAUSED 2026-10-27 (Phases 0-1 built; Matt did not get the look in Max; `.specify/plan.md` Paused section). Specced 2026-10-26 (`.specify/f_cmap/{spec,tasks}.md`).
Revised 2026-10-26 after discussion with Matt (performing with live input; no checker;
rectangular map only). Drafted 2026-10-23 from the webgpgpu mining run
(`webgpgpu-ideas-1`). Not tried in Max._

## Concept

Ping-pong a texture and, every frame, replace each pixel with the old image sampled at
its position pushed through a complex map plus an animated offset. History accumulates, so
motion winds up into filaments and spirals that a one-shot warp cannot make. Two maps in
the webgpgpu examples (source read 2026-10-26, `webgpgpu/examples/Example_9_*.html`,
`Example_10_*.html`):

- **Square** (Example 9): pixel position as a complex number on a domain of radius 1.75
  (`SCALE`), squared, plus an offset w; the pixel copies the stored value at the result.
  Out-of-domain test is on the MAPPED point (|z^2 + w| > SCALE).
- **Log** (Example 10): domain radius 1; texture coordinate
  `u = (3 atan2(y, x) / 2pi + wx, 3 ln|z| / 2pi + wy)`, sampled with REPEAT wrap.
- **w animation (both):** angle += 0.01 per frame, phase += 0.01 sqrt(2) per frame,
  radius = 0.15 + 1.5 cos(phase), so |w| sweeps from -1.35 to 1.65 (passes through zero).
  Frame-rate coupled in the source; in `f_` it should come from the patcher clock.

## Decisions (Matt, 2026-10-26)

- **Use case: performing with live input.** The loop must take the camera/source.
- **No checker.** The examples' 128-pixel black-and-white checker for out-of-domain
  pixels is dropped (not wanted, not a toggle, not a mask outlet).
- **Rectangular (Square) only for now; Log dropped from scope.** If log space keeps
  coming up across modules, the answer is a separate log-space transformer module (a
  coordinate-space adapter), not a Log mode here. Revisit then.

## What the source examples actually do (matters for the design)

- **They never inject an image.** The `seed` program is created and never called; the
  buffers start empty. The only new information entering the loop is the out-of-bounds
  checker, which the next frame pulls back in. So in the source the checker IS the
  injector, not decoration. Dropping it removes the only thing that keeps the loop fed,
  so `f_cmap` needs its own injection (below).
- **The Log seam is mostly harmless.** The angular term jumps by exactly 3 across the
  atan branch cut, an integer, so REPEAT wrap hides it. Only the origin (ln r diverges)
  remains, a tiny region; a bare `sample()` wraps in pix chains, matching REPEAT (check
  exact-edge texels against the 2026-10-20 sampling findings before trusting seams).
- **Log looks like `f_droste` with other constants.** Reading the droste formulas
  (`ideas/droste_singularity.md`): `n_arms` 3, `twist` 0, `zoom` = e^(2pi/3) ~ 8.12, with w
  as rotation plus a log-radial shift. UNVERIFIED: droste's codebox was not read, and
  `f_droste` documents rotation but no radial offset.

## What f_ and Vsynth have today

- `f_mobius` and `f_droste`: stateless one-pass UV transforms. Neither keeps history.
- Vsynth `vs_feedback`: tier 3, `mix(in1, max(in1, in2), amt)`, 8-bit path. `f_droste`
  inside it probably gives most of Log mode (with max-accumulation, not replace). Square
  (z^2 + w) has no home: `f_mobius` is Mobius, `f_droste` is log-polar.

## Proposed shape (leaning, not decided)

- A new module, `f_cmap`, rectangular (Square) map only. Consider `z^n + w` with `n` a
  dial so it is not a one-off. Log is out of scope (Matt, 2026-10-26; see Decisions).
- Signature: texture -> texture, temporal. Float32 ping-pong (the web's 8-bit sub-half-step
  decay stall is not an issue).
- **Injection (new, replaces the checker):** every frame the live source is mixed into the
  pulled history, `out = mix(pull(prev), src, inject)`. Plus a `bounds` menu for
  pulled coordinates that leave the domain: Source (the live input shows through), Black,
  Wrap. Source-in-the-hole is the natural replacement for the checker.
- Dials: power n (default 2), offset rate, offset radius, decay, inject,
  bounds. Offset animation from the patcher clock (`f_quasi` Z.rate / D.rate precedent);
  Freeze and Reset as in `f_wc`.
- Coordinates: isometric, centered, in frame-height units, so the map stays conformal
  (not independent x/y normalisation; `f_quasi` found the source aspect handling was not
  isometric).
- Smear: z^2 has |f'| = 2|z|, so it magnifies near the centre (cumulative bilinear blur)
  and minifies toward the edge (aliasing). Options: Catmull-Rom taps (as `f_wc` enc),
  and per-frame injection of high frequencies. This is probably the real "narrow useful
  region" risk.
- Speculative: z^2 + w iterated is the Julia construction, so the offset is a Julia
  parameter; a good tier-3 look.

## Tensor field? (asked 2026-10-26)

Not as the core: the complex map is global and analytic. Possible later as local
modulation: `f_tf_tensormap` on the live input -> `f_tf_axisflow` -> a vecfield that
offsets the pull per pixel, so the smear follows image edges; `f_tf_aniso_blur` could
counter smear along edges. Five `f_tf_` consumers are still unverified (README ⚠), so MVP
is texture only plus, at most, an optional vecfield offset inlet. Check first whether
`f_vf_warp` run through `vs_feedback` already gives structure-aligned feedback.

## Tier-1 checks

- Fixed points of the square map satisfy z = z^2 + w.
- No decay, no injection, nearest sampling: after n frames the image at z equals the
  original at f^n(z) (exact test of the ping-pong loop against direct composition).
- Bounds region is exactly the set where the mapped magnitude exceeds the domain radius.

## Risks and open questions

- Smeary results: the useful decay / offset / inject region may be narrow and needs
  benching.
- Whether a log-space transformer module is worth building (only if log space keeps
  recurring; Log mode was dropped from this module).
- A verifier reply on a neighbouring record (`Example_18`: a three-pass feedback chain
  with `f_mobius`) found a mislabeled state encoding (8-bit shown as float); the two
  examples above were re-read from source on 2026-10-26, but other records for this theme
  deserve a second look before numbers are quoted.

## Related

`f_mobius`, `f_droste`, `droste_singularity.md`, `vecfield_aware_uv_warps.md`,
`f_conformal_fill.md`, `f_tensorfield.md`.

## Provenance

webgpgpu at 5997061, omp run `webgpgpu-ideas-1`, 2026-10-23. Source drafts in
`f_omp_runs/webgpgpu-ideas-1/ideas_draft/`: 37, 02, 03. Verified by subagents against the
example files and the f_ inventory. Revised 2026-10-26 from the example sources
(`/Users/matt/Github/webgpgpu/examples/`).
