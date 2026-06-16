# f_caustic — Future Directions

_Built and working. Last updated: 2026-06-09._
_As-built reference: `docs/f_caustic.md` (to be written)._

## Possible extensions

### in3 surface texture
The original spec included a surface texture inlet modulating caustic intensity non-uniformly — simulating irregular water surface or textured glass. Not in v1. f_grain is the natural source. Adds a second visual texture dependency; evaluate whether the expressive value justifies the inlet count.

### Inline radial fallback
When no f_vecfield is connected, a fallback to an inline radial field would produce caustic rings around center — useful for quick patching without a producer. Not currently implemented. Question: is this useful or misleading (implying caustic works without vecfield when the full behavior requires it)?

### f_flare / f_diffraction relationship
Flare (directional scatter from a bright point source) and diffraction (interference fringe math) are related phenomena with different architectures — probably separate bpatchers, not extensions of f_caustic. Capture when there's a specific performance need.

### Color shift
Caustic bright bands in water have warm/cool banding from chromatic dispersion. A `color_shift` param on the caustic accumulation (similar to f_vf_streak's color_shift) could add this character.
