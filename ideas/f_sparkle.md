# f_sparkle — parametric sparkles from a brightness threshold

_Created 2026-11-14. Status: ⚪ concept only, nothing built or tested. Everything
below about cost and look is inferred, not measured._

## The idea

One module, tex in → tex out: pixels brighter than a **threshold** grow sparkles.
The kind of sparkle is a parameter (cross, star, glint, burst, disc, dust), and how
far a pixel clears the threshold (its **headroom**) sets how big and bright its
sparkle is, and optionally *which kind* it gets. So one dial gates where sparkles
appear and the image's own highlights decide their character: a dim highlight
gets a speck, a hot one gets a full star.

The look targets: camera star/cross filters, glitter and sequins, snow and frost
catching light, water glints, the "magic" twinkle of motion graphics.

## Threshold model

- `threshold` (0–1 on luma, or on max(R,G,B) as a menu option) and `knee`
  (soft edge): `h = smoothstep(threshold, threshold + knee, luma)`.
- **Headroom** `h` (0–1) scales sparkle size and gain. A `response` curve dial
  (gamma on `h`) decides whether only the hottest pixels get big sparkles or
  everything above the line does.
- **Tiers (the "different kinds by threshold" mode):** two extra cut points split
  headroom into three bands, each with its own kind. Default: low band = Dust,
  middle = Glint, top = Star. One image gets a natural mix of small and large
  sparkles without any randomness. A `Single` mode ignores tiers and uses the
  chosen kind everywhere.
- Optional threshold `mod` inlet (per-pixel threshold), so a mask or another
  module decides where sparkling is allowed.

## Sparkle kinds

| Kind | Shape | Notes |
|---|---|---|
| Cross | 4 arms (2 lines) | Classic star filter. `angle` rotates |
| Star 6 / Star 8 | 6 or 8 arms | 8 arms with alternating long/short (`ratio`) reads as a "twinkle star" |
| Glint | 1 line, thin, long | Single diagonal glint, sharp core |
| Burst | Many thin spikes, spectral color | Diffraction look; spikes colored along their length (see `spectral_rainbow_colormap.md`) |
| Disc | Round or n-gon soft disc | Bokeh-ish; the "aperture" shape in miniature |
| Dust | Small points scattered *around* the highlight | Glitter fallout; needs the Cells engine (below) |

Shared shape params, using the `discrete_item_conventions.md` vocabulary where it
fits: `size` (arm length), `stretch` (aspect / long-short ratio), `softness` (arm
falloff), `shape` (the kind menu), plus `thickness`, `angle`, `core` (center
brightness spike, the dual-curve idea from `glow_profile_and_afterimage.md`).

Color: `source` (sparkle takes the pixel's color), `white`, `tint`, `spectral`
(hue shifts along the arm). `gain`, `mix_pct`, composite + isolated outlets, same
as `f_vf_glow`.

## Two engines (the main design decision)

**1. Gather (continuous).** Each output pixel walks outward along each arm
direction, sampling the thresholded source and summing `h × falloff(dist)`. Every
pixel over the threshold sparkles, so the result looks like a real star filter:
bright edges grow dense combs of spikes. Same structure as `f_vf_glow`'s tap loop,
with fixed directions instead of a field.
- Cost is arms × taps × 2. The measured limit from `f_deflicker.md` (~256-tap
  codeboxes break the shader translator) caps this: Cross at 2 lines × 2 × 48 = 192
  fits; Star 8 needs ~32 taps per direction or less. Inferred, needs a bench.
- Arm length in pixels is fixed by taps × step; longer arms mean gappier arms
  unless pre-blurred or sampled from a lower mip.
- Can't do Dust (no discrete points to scatter around).

**2. Cells (discrete).** Divide the frame into cells (`density`). Each cell hashes
one candidate point, samples luma there, and if it clears the threshold draws one
analytic sparkle (an SDF of the chosen kind) with per-cell random rotation, size
jitter and twinkle phase. Each output pixel checks its 3×3 (or 5×5) neighbor cells.
This is the texture-bombing pattern from `voronoi_vs_texture_bombing.md` and
`f_vf_seeds`.
- Sparkles are countable and separate: glitter, not a filter.
- Cheap and independent of arm count (9 or 25 cell lookups plus math).
- Arm length is capped at about 1–2 cells by the neighbor search, so big stars
  need low density. That trade-off has to be visible in the UI.
- The candidate point could be the brightest of a few samples in the cell rather
  than a random one, so sparkles land on highlights instead of near them. Cost
  question.

Lean: build Cells first (it is the more "sparkle" of the two and the cheaper), and
offer Gather as a second `engine` mode only if the star-filter look is wanted and
the composition test below fails.

## Motion

- `twinkle`: per-sparkle brightness flicker, phase from the cell hash (Cells only).
  Needs a time source; how other temporal-but-stateless modules get frame time is
  an open question, not checked.
- `rotate`: slow spin of the arm angle.
- `follow`: optional vecfield inlet sets the arm angle per pixel (glints that
  follow a surface or a flow). Axis, not direction, so mod π for even arm counts.

## Overlaps to check before building

- **Composition first:** threshold (e.g. `f_channel_grader` or a level crush) →
  `f_vf_glow` with a constant-direction field already gives a one-axis Glint, and
  two of them crossed may give a Cross. Untested; if it looks right, Gather mode is
  not needed and this module is only the Cells engine.
- `f_tf_glint` (`f_tf_backlog.md`, deferred): oriented specular glints with width
  from the tensor. Different source of orientation (image structure, not a fixed
  angle); `follow` above is the bridge if both exist.
- `optics_map.md` lists true diffraction starbursts as Fourier-optics research on
  the existing DFT. Burst here is a stylized fake, not that.
- `f_lens` halation/ghosts: a lens-wide effect, not per-highlight sparkles.

## Open questions for Matt

1. Is "different kinds based on a threshold" the tiers idea above (headroom picks
   the kind), or one chosen kind gated by the threshold? The note assumes both, with
   tiers as a mode.
2. Glitter (Cells) or star filter (Gather) as the first target?
3. Time source for `twinkle`.
4. Name: `f_sparkle`, or a `f_vf_` name if `follow` makes a vecfield central.
