# f_

A collection of visual processing bpatchers for [Vsynth](https://github.com/jakeot/vsynth) in Max 9.

## Installation

**Option A — symlink (recommended for development):**
```bash
ln -s ~/Github/f_ ~/Documents/Max\ 9/Packages/f_
```

**Option B — copy:**
Copy the `f_` folder into `~/Documents/Max 9/Packages/`.

Restart Max after either method. Patches will be available on Max's search path.

## Requirements

- Max 9
- Vsynth package installed

## Patches

| Patch | Description |
|---|---|
| `f_droste` | Log-polar spiral transform (Droste / Escher-style recursive zoom) |
| `f_grain` | Stochastic grain field with per-grain displacement and luma gating |
| `f_channel_grader` | Per-channel color grading |
| `f_hue_processor` | Hue-selective processing |
| `f_luma_processor` | Luminance-selective processing |
| `f_tone_curve` | Tone curve adjustment |
| `f_texrouter` | 4×4 texture routing matrix with preset system |

## Help files

Each patch has a corresponding `.maxhelp` file in the `help/` folder. Right-click any patch in Max and choose **Open Help** to open it.

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. They follow Vsynth conventions and are designed to sit naturally in a Vsynth signal chain.
