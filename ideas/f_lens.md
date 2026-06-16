# f_lens — Future Directions

_Built and working. Last updated: 2026-06-09._
_As-built reference: `docs/f_lens.md` (to be written)._

## Open questions from original ideation

### Inter-reflection / ghost images
Not in v1. Light bouncing between parallel glass surfaces — a cascade of ghost copies, each offset, attenuated, and slightly color-shifted. Very distinct "looking through something" signal. Could be a param cluster within f_lens or its own bpatcher (`f_interreflect`). Additive superposition of source sampled at progressively offset and attenuated UV coordinates — straightforward in a codebox.

### Anamorphic character
Directional distortion on one axis — characteristic of widescreen cinema lenses. Oval bokeh, horizontal flare character. Whether this is worth a dedicated param or sub-mode depends on how specific the reference feels in performance use.

### f_mobius performance gap connection
f_mobius and f_lens both do UV-space transforms. The f_mobius performance gap note in scratchpad (limited expressive range in practice) may be addressable by pairing with f_lens rather than fixing f_mobius in isolation — lens distortion + Möbius UV transform may have natural compositional synergy.

### Halation
Soft additive glow around bright regions, warm/amber color-shifted. Distinct from digital bloom. Not currently in f_lens — would require a separate additive pass. Could be a thin companion bpatcher or a mode.
