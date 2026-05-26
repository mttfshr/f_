# f_

A collection of visual processing utility bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in [Max](https://cycling74.com/products/max).

## Installation

Clone this repository and place the `f_` folder in your Max search path. There are two options for doing this:

**Option A — symlink (recommended for development):**
```bash
ln -s ~/Github/f_ ~/Documents/Max\ 9/Packages/f_
```

**Option B — copy:**
Copy the `f_` folder into `~/Documents/Max 9/Packages/`.

Restart Max after either method. Patches will be available on Max's search path.

## Requirements

- Max 9
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
| `f_mobius` | Möbius transformation UV-space processor | 📋 Specced |

## Build Queue

1. f_chladni signal chain — active (`.specify/f_chladni/`)
2. f_mobius — next (`.specify/f_mobius/spec.md`)
3. f_stereo — stereographic projection display layer; after f_mobius
4. f_poincare — Poincaré disk hyperbolic tiling; after f_mobius
5. f_sharmonics — spherical harmonics visualizer; after f_stereo
6. f_cymascope — FDTD wave propagation; feasibility check first

## Help files

Each patch has a corresponding `.maxhelp` file in the `help/` folder. Right-click any patch in Max and choose **Open Help** to open it.

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. They follow Vsynth conventions and are designed for Vsynth signal chains.

If you know Max and Vsynth, you should be able to understand and modify the patches as needed.
