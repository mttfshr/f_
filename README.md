# f_

A collection of visual processing utility bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in [Max](https://cycling74.com/products/max).

## Installation

Clone this repository and place the `f_` folder in your Max search path. 

## Requirements

- Max 9. Might work on earlier versions but I haven't tested it.
- Vsynth package installed. You can find it in [Max's Package Manager.](https://docs.cycling74.com/userguide/package_manager/)

## Patches

| Patch | Description | Status |
|---|---|---|
| `f_droste` | Log-polar spiral transform (Droste / Escher-style recursive zoom) | ✅ Working |
| `f_grain` | Stochastic grain field with per-grain displacement and luma gating | ✅ Working |
| `f_channel_grader` | Per-channel color grading | ✅ Working |
| `f_hue_processor` | Hue-selective processing | ✅ Working |
| `f_luma_processor` | Luminance-selective processing | ✅ Working |
| `f_tone_curve` | Tone curve adjustment | ✅ Working |
| `f_texrouter` | 4×4 texture routing matrix with preset system | ✅ Working |
| `f_chladni` | Chladni plate modal synthesis visualizer (Bessel modes) | 🔨 Signal chain in progress |
| `f_mobius` | Möbius transformation UV-space processor | ✅ Working |
| `f_stereo` | Stereographic projection display layer | ✅ Working |

## Build Queue

1. f_lens — filmic lens processor; specced (`.specify/f_lens/`)
2. f_chladni signal chain — active (`.specify/f_chladni/`)
3. f_poincare — Poincaré disk hyperbolic tiling
4. f_sharmonics — spherical harmonics visualizer
5. f_cymascope — FDTD wave propagation; feasibility check first

## Help files

To be written.

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. They follow Vsynth conventions and are designed for Vsynth signal chains.

If you know Max and Vsynth, you should be able to understand and modify the patches as needed.

There's no release schedule or roadmap for these patches and the patchers might change significantly as development continues.
