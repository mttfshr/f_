# f_chladni scratch notes

_2026-06-17_

## Setup

Scratch patch: `/Users/matt/Vsynth/patterns/chladni-scratch.maxpat`
Codebox: Mode A (linear interp) and Mode B (Gaussian resonance snap) selectable via `mode` param.
Params: `note` (0–127), `amp`, `dishradius`, `reflectamt`, `linesharpness`, `ph0`, `spread`, `mode`, `bypass`.

## Observations

### General
- Both modes produce visually compelling Chladni geometry across the full note range.
- The mixed-geometry approach (blending both radial envelope and angular order simultaneously across mode transitions) works well — no obvious artifacts at crossfade zones.

### Mode A vs Mode B
- Distinction between modes is subtle at default `spread` values.
- Difference may emerge more clearly at tight `spread` (0.05–0.1), where Mode B Gaussian barely overlaps adjacent modes and should snap harder.
- Both worth retaining in the final bpatcher as a `mode` param — expressive payoff may depend on specific param combinations and source material.

### MIDI range
- Full 0–127 span is the correct convention. Useful expressive territory is concentrated in a narrower window, but scaling happens upstream (companion patch or routing), not in the bpatcher.
- No remapping of the MIDI range in the bpatcher itself.

## Decisions

- **Mode selection**: retain both Mode A and Mode B as a `mode` param (0=linear, 1=resonance snap). Decision on which to use deferred to performance context.
- **MIDI range**: full 0–127, no internal remapping.
- **`spread` param**: retain — controls Gaussian falloff width in Mode B; useful range ~0.1–0.5 (below 0.1 produces white artifacts between modes).
- **Mixed geometry**: confirmed working; no reason to change approach.

## Open questions
- Mode B `spread` below ~0.1 produces white transition areas between modes — Gaussian weights sum near zero between modes, collapsing the pattern. Accepted as a floor on useful range: expressive `spread` range is ~0.1–0.5. No fix needed.
- Does `ph0` add enough expressive value at single-mode operation to keep? (Was useful in multi-mode superposition — less clear here.)
