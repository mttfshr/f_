# f_

A collection of bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in [Max](https://cycling74.com/products/max). Generators, processors, and utilities that follow Vsynth conventions and are designed to work in Vsynth signal chains.

This repo is more than the patchers themselves — it also documents the process used to design and build them, in case that's useful to other Vsynth module authors. See "Repo Structure" below.

## Installation

Clone this repository, then place (or symlink) the `package` folder in your Max Packages directory, renamed to `f_`:

- **macOS:** `~/Documents/Max 9/Packages/f_` → `path/to/f_/package`
- **Windows:** `Documents\Max 9\Packages\f_` → `path\to\f_\package`

Restart Max. The patches will be available in your file browser under `f_`.

## Requirements

- Max 9 (earlier versions untested)
- Vsynth -- available via Max's Package Manager

## Patches

| Patch | Type | Description |
|---|---|---|
| `f_droste` | Processor | Log-polar spiral transform -- Droste / Escher-style recursive zoom |
| `f_grain` | Generator / Processor | Stochastic grain field with per-grain displacement and luma gating |
| `f_stipple` | Generator / Processor | 2D hash field stipple texture |
| `f_masonry` | Generator | Parametric masonry texture -- courses, bond, mortar, drift, color |
| `f_chladni` | Generator | Chladni plate modal synthesis visualizer (Bessel modes); audio companion patch included |
| `f_mobius` | Processor | Mobius transformation UV-space processor |
| `f_stereo` | Processor | Stereographic projection display layer |
| `f_lens` | Processor | Filmic lens -- aberration, distortion, transmission, tilt-shift, spatial modulation |
| `f_channel_grader` | Processor | Per-channel color grading |
| `f_hue_processor` | Processor | Hue-selective processing |
| `f_luma_processor` | Processor | Luminance-selective processing |
| `f_tone_curve` | Processor | Tone curve adjustment |
| `f_texrouter` | Utility | 4x4 texture routing matrix with preset system |
| `f_util_profile` | Utility | CPU-side dual-axis luminance profiler -- outputs row/column profile textures for modulation |
| `f_util_matrix_2` | Utility | Modulation routing matrix (2-source MVP) -- textures in, scalar per-param routing messages out; draft status |
| `f_weave` | Generator | Parametric line-mark texture -- continuous distance-field lines with per-line phase variation; optional vecfield + scalar-potential inlets |
| `f_caustic` | Processor | Optical caustic -- streamline accumulation weighted by field convergence; two outlets (composited / isolated layer) |
| `f_sirds` | Generator | Single Image Random Dot Stereogram -- strip-based real-time construction; depth texture drives displacement of a repeating pattern |
| **f_vf_ family** | **vecfield producers/consumers** | **float32 f_vecfield textures -- produced by f_vf_ generators, consumed by f_caustic, f_vf_warp, f_vf_streak, f_vf_seeds, f_lens field inlet** |
| `f_vf_vortex` | Generator | Single fixed-point vortex field -- convergence, curl, position, 4 mod inlets |
| `f_vf_vortex_multi` | Generator | Three-site additive vortex field -- per-site position/conv/curl, 4 global mod inlets |
| `f_vf_flow` | Generator | Dual-mode uniform/texture-perturbed direction field -- designed to feed f_weave's vecfield inlet |
| `f_vf_fieldmap` | Processor | Scalar texture to vecfield via central difference gradient -- primary source: jit.gl.bfg |
| `f_vf_potential` | Processor | Scalar potential-field integrator -- accumulates vecfield magnitude over time via feedback; feeds f_weave's scalar inlet |
| `f_vf_warp` | Processor | UV warp via f_vecfield -- displaces source texture along field streamlines |
| `f_vf_streak` | Processor | Directional blur via f_vecfield -- accumulates source samples along streamlines; two outlets (composite / isolated streak layer) |
| `f_vf_advect` | Processor | Temporal fluid advection via f_vecfield -- accumulates flow across frames; decay >1.0 gives excitable/amplifying character |
| `f_vf_glow` | Processor | Field-aligned directional blur via f_vecfield -- accumulates source samples along streamlines with exponential falloff; two outlets (composite / isolated glow layer) |
| `f_vf_repulse` | Generator | Texture-driven repulsion vecfield -- 16-sample ring accumulation, luma threshold; four accumulation modes (Cancel, Max, Abs Add, Turbulent) |
| `f_vf_chroma` | Processor | Vecfield-driven chromatic aberration -- rainbow/hue-sweep streak along field direction; two outlets (composite / isolated layer) |
| `f_vf_prism` | Processor | Vecfield-driven spectral/prism separation -- luma-gated RGB displacement along field direction; two outlets (composite / isolated layer) |
| `f_vf_split` | Utility | Splits an f_vecfield's X/Y channels to two separate greyscale outlets, unipolar or bipolar |
| `f_vf_seeds` | Generator | Discrete mark placement/orientation via f_vecfield and a shape tex -- Voronoi-style seed distribution with priority-generalized selection and multi-owner overlap (texture bombing); shape tex + mod tex inlets |

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. They follow Vsynth conventions and are designed for Vsynth signal chains. If you know Max and Vsynth, you should be able to understand and modify the patches as needed.

There is no release schedule. Patches may change significantly as development continues.

## Repo Structure

This repo has four parts:

- **`package/`** — the installable Max package: `patchers/`, `help/`, `javascript/`, `package-info.json`. This is the only folder Max needs (see Installation above).
- **`build/`** — the build system used to generate patchers from definition files, plus supporting tools (helpfile generation via Claude API, interface auditing, migrations). Meant to be forked or read if you want to build your own `f_`-style bpatcher library. See `build/spec.md`.
- **`ideas/`, `.specify/`, `docs/`** — planning and reference material: half-formed module ideas (`ideas/`), specs/plans/ADRs for modules under active development (`.specify/`), and as-built reference docs plus research notes on Vsynth/Max internals (`docs/`). Kept public as a reference and conversation starter, not as polished documentation — expect dead ends, superseded approaches, and in-progress modules alongside finished ones.
- **`skills/`** — [Claude](https://claude.ai) skills used to collaborate with Claude on this codebase: conventions for bpatcher structure (`vsynth-bpatcher`), GenExpr/`jit.gl.pix` gotchas (`jit-gen-codebox`), helpfile format (`f-helpfile`), and a notation system for describing patches in chat (`max-patch-notation`). Copy these into your own Claude setup (e.g. `claude-scaffold`-style skills directory) if you want a similar collaboration workflow — you'll want to adjust the hardcoded paths in `vsynth-bpatcher/SKILL.md` to match your own repo location.

`tools/` also exists, holding one-off scripts from past development sessions — not part of the supported build system (see `tools/README.md`).
