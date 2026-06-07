# f_

A collection of bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in [Max](https://cycling74.com/products/max). Generators, processors, and utilities that follow Vsynth conventions and are designed to work in Vsynth signal chains.

## Installation

Clone this repository and place the `f_` folder in your Max Packages directory:

- **macOS:** `~/Documents/Max 9/Packages/`
- **Windows:** `Documents\Max 9\Packages\`

Restart Max. The patches will be available in your file browser under `f_`.

## Requirements

- Max 9 (earlier versions untested)
- Vsynth — available via Max's Package Manager

## Patches

| Patch | Type | Description |
|---|---|---|
| `f_droste` | Processor | Log-polar spiral transform — Droste / Escher-style recursive zoom |
| `f_grain` | Generator / Processor | Stochastic grain field with per-grain displacement and luma gating |
| `f_stipple` | Generator / Processor | 2D hash field stipple texture |
| `f_masonry` | Generator | Parametric masonry texture — courses, bond, mortar, drift, color |
| `f_chladni` | Generator | Chladni plate modal synthesis visualizer (Bessel modes); audio companion patch included |
| `f_mobius` | Processor | Möbius transformation UV-space processor |
| `f_stereo` | Processor | Stereographic projection display layer |
| `f_lens` | Processor | Filmic lens — aberration, distortion, transmission, tilt-shift, spatial modulation |
| `f_channel_grader` | Processor | Per-channel color grading |
| `f_hue_processor` | Processor | Hue-selective processing |
| `f_luma_processor` | Processor | Luminance-selective processing |
| `f_tone_curve` | Processor | Tone curve adjustment |
| `f_texrouter` | Utility | 4×4 texture routing matrix with preset system |
| `f_vortex` | Generator | Single fixed-point vortex field — convergence, curl, position; f_vecfield producer |
| `f_caustic` | Processor | Optical caustic — streamline accumulation weighted by field convergence; two outlets (composited / isolated layer) |

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. They follow Vsynth conventions and are designed for Vsynth signal chains. If you know Max and Vsynth, you should be able to understand and modify the patches as needed.

There is no release schedule. Patches may change significantly as development continues. Help files are not yet written — the patch tables and parameter names are designed to be self-explanatory within the Vsynth context.
