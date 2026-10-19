# f_

A collection of bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in [Max](https://cycling74.com/products/max). Generators, processors, and utilities that follow Vsynth conventions and are designed to work in Vsynth signal chains.

This repo is more than the patchers themselves — it also documents the process used to design and build them, in case that's useful to other Vsynth module authors. See "Repo Structure" below.

## Installation

You need Max 9 and the Vsynth package (see Requirements below).

There's no release yet. It's not stable enough for that. I will eventually make this installable via Max's Package Manager, but for now you need to clone the repository and symlink or copy its `package/` folder into your Max Packages folder as described in the development instructions.

Please note that this repository is intended for development and experimentation. The modules may change, and there is no guarantee of stability or backward compatibility. I won't be posting a changelog with breaking changes until some time in the future.

## Requirements

- Max 9 (earlier versions untested)
- Vsynth -- available via Max's Package Manager

## Patches

Every patcher in `package/patchers/` is listed here, grouped by category and alphabetical within each category. The categories are the ones in the `f_modules` menu (a ∇ in a category name means every module in it takes or produces a vecfield, a T_ means the same for a tensor), plus Audio for the audio modules (`gen~`, `pfft~`, and the `f_chladni` companion); a few modules not yet in the menu are filed under the category they belong to. Entries marked ⚠ are built but unfinished, unverified or undocumented: don't rely on them. The `f_vf_` modules work with float32 `f_vecfield` textures, produced by the `f_vf_` generators and consumed by `f_caustic`, `f_vf_warp`, `f_vf_streak` and `f_vf_seeds`. The `f_tf_` modules work with `f_tensor` textures produced by `f_tf_tensormap` (`docs/f-reference/f_tensor_type.md`).

This table is also the source for the package's launcher patcher (`package/extras/f_Launch.maxpat`, opened by the Package Manager's Launch button and the Extras menu), which lists every module on one tab per group below.

### Scope

| Patch | Description |
|---|---|
| `f_chladni` | Chladni plate modal synthesis visualizer (Bessel modes); audio companion patch included |

### Discrete

| Patch | Description |
|---|---|
| `f_grain` | Stochastic grain field with per-grain displacement and luma gating |
| `f_masonry` | Parametric masonry texture -- courses, bond, mortar, drift, color |
| `f_stipple` | 2D hash field stipple texture |
| `f_vf_seeds` | Discrete mark placement and orientation from a vecfield and shape tex -- Voronoi-style seeds with overlap |
| `f_weave` | Parametric distance-field line texture with per-line phase variation; optional vecfield + scalar inlets |

### Spatial

| Patch | Description |
|---|---|
| `f_droste` | Log-polar spiral transform -- Droste / Escher-style recursive zoom |
| `f_mobius` | Mobius transformation UV-space processor |
| `f_ngon` | Regular N-gon generator / mask, live-modulatable vertex count; not yet confirmed or documented |
| `f_sirds` | Single Image Random Dot Stereogram -- real-time strips; a depth texture displaces a repeating pattern |
| `f_stereo` | Stereographic projection display layer |

### Optical

| Patch | Description |
|---|---|
| `f_lens` | Filmic lens -- aberration, distortion, transmission, ghost images, halation, spatial modulation |
| `f_vf_prism` | Vecfield-driven prism separation -- luma-gated RGB displacement along the field; composite / isolated outlets |

### Color / Tone

| Patch | Description |
|---|---|
| `f_channel_grader` | Per-channel color grading |
| `f_hue_processor` | Hue-selective processing |
| `f_luma_processor` | Luminance-selective processing |
| `f_tone_curve` | Tone curve adjustment |

### ∇ Generators

| Patch | Description |
|---|---|
| `f_vf_vortex` | Single fixed-point vortex field -- convergence, curl, position, 4 mod inlets |
| `f_vf_vortex_multi` | Three-site additive vortex field -- per-site position/conv/curl, 4 global mod inlets |

### ∇ Processors

| Patch | Description |
|---|---|
| `f_caustic` | Optical caustic -- GPU forward scatter forming folded sheets; composited / isolated outlets |
| `f_vf_advect` | Temporal fluid advection via f_vecfield -- accumulates flow across frames; decay >1.0 is excitable |
| `f_vf_chroma` | Vecfield-driven chromatic aberration -- rainbow streak along field direction; composite / isolated outlets |
| `f_vf_fieldmap` | Scalar texture to vecfield via central difference gradient -- primary source: jit.gl.bfg |
| `f_vf_flow` | Dual-mode uniform/texture-perturbed direction field -- designed to feed f_weave's vecfield inlet |
| `f_vf_fluid` | Incompressible-flow solver -- force vecfield in, evolving velocity field out; feed it to advect / warp / glow |
| `f_vf_glow` | Field-aligned directional blur via f_vecfield -- accumulates along streamlines; composite / glow-layer outlets |
| `f_vf_optical_flow` | Lucas-Kanade optical flow from source motion -- confidence-gated, with aperture-problem fill; two outlets |
| `f_vf_repulse` | Texture-driven repulsion vecfield -- 16-sample ring accumulation, luma threshold, four accumulation modes |
| `f_vf_streak` | Directional blur via f_vecfield -- accumulates along streamlines; composite / isolated streak outlets |
| `f_vf_vorticity` | Vorticity-confinement ("curl amp") processor. Do not treat as working |
| `f_vf_warp` | UV warp via f_vecfield -- displaces source texture along field streamlines |

### T_ Tensor

| Patch | Description |
|---|---|
| `f_tf_aniso_blur` | Structure-aligned smoother: blurs along the tensor axis, isotropic fallback where no direction |
| `f_tf_axisflow` | Tensor map axis to a seam-free vecfield: flow along or across image edges |
| `f_tf_glyph` | Tensor glyph view: one oriented ellipse per cell from the raw tensor (also the debug tool) |
| `f_tf_hatch` | Orientation-committed hatching: marks laid out and committed from the tensor (strokes → dots) |
| `f_tf_sharpen` | Eigengap exaggerator/relaxer: contrast dial on anisotropy; axis untouched, trace fixed |
| `f_tf_smooth` | One-pole temporal tensor smoother (inertia) — stabilizes structure-tensor fields across frames |
| `f_tf_tensormap` | Structure tensor: raw tensor (outlet 0), packed direction/trace/coherence (outlet 1) |

### Utilities

| Patch | Description |
|---|---|
| `f_modules` | Module menu -- pick a module to add it as a bpatcher; ∇ marks vecfield categories, T_ tensor ones |
| `f_texrouter` | 4x4 texture routing matrix with preset system |
| `f_util_matrix_2` | Modulation routing matrix (2-source MVP) -- textures in, scalar per-param routing messages out; draft status |
| `f_util_profile` | CPU-side dual-axis luminance profiler -- outputs row/column profile textures for modulation |
| `f_vf_potential` | Scalar potential-field integrator -- accumulates vecfield magnitude over time; feeds f_weave's scalar inlet |
| `f_vf_split` | Splits an f_vecfield's X/Y channels to two separate grayscale outlets, unipolar or bipolar |

### Audio (`gen~`)

| Patch | Description |
|---|---|
| `f_a_ripple` | ⚠ Unfinished. De-correlating ripple stimulus (Yukhnovich et al. 2025); DSP done, UI and docs pending |
| `f_a_decorrelate` | ⚠ De-correlating modulation processor (audio in → out, pfft~); shipped and documented 2026-10-12 |
| `f_chladni_audio` | ⚠ Unverified. Audio-input companion for `f_chladni`: pitch drives `note`, amplitude `amp`. No reference doc |

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. They follow Vsynth conventions and are designed for Vsynth signal chains. If you know Max and Vsynth, you should be able to understand and modify the patches as needed.

There is no release schedule. Patches may change significantly as development continues.

## Repo Structure

This repo has six parts. The map first, details below.

| Folder | What it holds |
|---|---|
| `package/` | The installable Max package. The only folder Max needs. |
| `build/` | The build system that generates patchers from definition files. |
| `src/` | Build inputs, per module. |
| `tests/` | Verification: math mirrors and a Max test bench. |
| `ideas/`, `.specify/`, `docs/` | Planning and reference material. |
| `skills/` | Claude skills used to collaborate on this codebase. |

### `package/`

The installable Max package, and the only folder Max needs (see Installation above). It holds `patchers/`, `help/`, `examples/`, `extras/`, `javascript/`, `code/`, `package-info.json`, `readme.md` and `license.md`.

### `build/`

The build system that generates patchers from definition files, plus supporting tools. Meant to be forked or read if you want to build your own `f_`-style bpatcher library. See `build/spec.md`.

- `build_patcher.py` — builds a patcher from a module's definition.
- `generate_helpfiles.py` — builds the helpfile prompt.
- `drift.py` — checks that each shipped patcher still equals what its definition builds.
- `capture.py` — writes hand-tuned presentation state from a shipped patcher back into its definition.
- `capture_raw.py` — writes the boxes and cords the builder cannot produce into a `raw_ui.json` beside the definition.
- `release.sh` — the release zip script.
- `generate_launch.py` — builds the `f_Launch` homepatcher from the Patches table above.
- `generate_menu.py` — builds the `f_modules` menu from `src/f_modules/menu.py`.

### `src/`

Build inputs, per module:

- `definition.py` — the patcher definition.
- `codebox_*.gen` — confirmed codebox content.
- Per-module build scripts, for modules whose build needs diverge from the general `build_patcher.py` path.

### `tests/`

Verification that doesn't need a scratch patch, in two layers:

- **Math** — NumPy mirrors of codebox algorithms, checked against independent references (`test_*.py`, `tests/run.sh`, no Max needed). The same offline layer statically checks every shipped patcher's wiring: every control reaches the Param it claims to, and every Param is driven and read.
- **Execution** — a Max test bench. One generated patch stays open in Max and is driven from Python over OSC, so a module's real `src/` codebox runs on the GPU and its output is diffed numerically, with compile errors caught and cost measured (`bench_*.py`, `tests/bench.sh`). A second bench loads *shipped* bpatchers inside Vsynth's own render context to check their contracts: every parameter reaches the attribute it claims to, bypass passes through, and every outlet renders.

How-to in `tests/README.md`; design in `.specify/test_bench/`.

### `ideas/`, `.specify/`, `docs/`

Planning and reference material. Kept public as a reference and conversation starter, not as polished documentation: expect dead ends, superseded approaches, and in-progress modules alongside finished ones.

- **`ideas/`** — half-formed module ideas.
- **`.specify/`** — specs, plans and ADRs for modules. The root holds modules under active development. Two subdirectories hold the rest, a reorganization rather than a rename of the module's own directory:
  - `.specify/stable/f_name/` — shipped and verified with nothing outstanding. Its content there is archival reference (the ADR and decision history); the active source of truth passes to `docs/f-reference/f_name.md`, which should already have distilled anything worth keeping from `spec.md`, `plan.md` and `tasks.md` before the move.
  - `.specify/paused/f_name/` — shelved on a real open question, not to be resumed by default.
- **`docs/`** — as-built reference docs, plus research notes on Vsynth/Max internals. `docs/f-reference/module-inventory.md` and `docs/vsynth-reference/module-inventory.md` are flat one-line-per-module capability maps (the `f_` layer and the core Vsynth layer, respectively): the fast way to answer "does something here already do X" without reading full per-module docs.

### `skills/`

[Claude](https://claude.ai) skills used to collaborate with Claude on this codebase. Ten of them, covering Max/Vsynth/audio-DSP domain knowledge:

- `vsynth-bpatcher` — conventions for bpatcher structure.
- `jit-gen-codebox` — GenExpr/`jit.gl.pix` gotchas.
- `gen-tilde-codebox` — the audio-domain equivalent for `gen~`.
- `pfft-spectral-processing` — `pfft~` spectral processing.
- `max-advanced-object-methodology` — the read-the-help-patch-first workflow for unfamiliar Max objects.
- `maxpat-json-authoring` — hand-authoring `.maxpat` JSON without a live Max.
- `f-helpfile` — helpfile format.
- `max-patch-notation` — a notation system for describing patches in chat.
- `bench-test-authoring` — conventions for writing tier-2 bench test files.
- `module-preflight` — the checklist before calling a module done or moving it to `stable/`.

The dividing line: domain knowledge lives here, generic workflow/process scaffolding does not. This directory is the single source of truth — other checkouts symlink here rather than keeping copies, after two of them silently diverged in both directions. Uploaded copies can't be symlinked, so `skills/MANIFEST.md` records the last-uploaded state and `skills/check.sh` reports drift (`check.sh stamp` after re-uploading). Copy these into your own Claude setup (e.g. `claude-scaffold`-style skills directory) if you want a similar collaboration workflow — you'll want to adjust the hardcoded paths in `vsynth-bpatcher/SKILL.md` to match your own repo location.

## Development

Modules are built from definition files (`src/` → `build/build_patcher.py` → `package/patchers/`) rather than patched by hand, so the structure stays consistent and reviewable as diffs.

Verification happens in three tiers, cheapest and most attributable first — the full rationale is in `.specify/constitution.md`:

1. **Math** — a NumPy mirror of the codebox, checked against independent ground truth. No Max.
2. **Execution** — the real codebox file run on the GPU through the test bench and diffed numerically; shipped bpatchers additionally contract-tested for parameter wiring and bypass.
3. **Judgment** — a scratch patch for what numbers can't judge: expressive tuning, parameter ranges, visual character, Vsynth integration.

The reason for the split: a scratch patch tests two things at once — whether the math is right and whether Max and the GPU run it — so a failure can't be attributed to either. Separating them turned "this doesn't look right" into specific answers, and the contract tests found real bugs in shipped modules that no amount of looking would have surfaced.

## License

The repo has two licenses. The product (the package, its source and the specs) is CC BY-NC 4.0 with an extra permission for paid professional work: use it, remix it and get paid for what you make with it, but don't sell the software. Everything else (the build system, tests, AI-aided workflow, documentation and ideas) is MIT. See [LICENSE.md](LICENSE.md). `f_` requires Vsynth, which has its own license.
