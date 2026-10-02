# f_

A collection of bpatchers for [Vsynth](https://www.kevinkripper.com/vsynth) in [Max](https://cycling74.com/products/max). Generators, processors, and utilities that follow Vsynth conventions and are designed to work in Vsynth signal chains.

This repo is more than the patchers themselves — it also documents the process used to design and build them, in case that's useful to other Vsynth module authors. See "Repo Structure" below.

## Installation

You need Max 9 and the Vsynth package (see Requirements below).

**To use the modules:** download `f_-<version>.zip` from this repository's GitHub Releases page and unzip it into your Max Packages folder (macOS: `~/Documents/Max 9/Packages/`, Windows: `Documents\Max 9\Packages\`). The zip contains a single `f_/` folder. Restart Max; the patches will be available in your file browser under `f_`. No release has been published yet, so until one is, use the developer install below.

**To develop, or to track the repo:** clone this repository somewhere *outside* Max's Packages folder, then symlink (or copy) its `package/` folder into Packages under the name `f_`:

- **macOS:** `ln -s /path/to/f_/package "$HOME/Documents/Max 9/Packages/f_"`
- **Windows:** link or copy `path\to\f_\package` to `Documents\Max 9\Packages\f_`

Don't clone the repo directly into Packages. The repo root is not the package (the package is the `package/` subfolder), so Max would not find the patchers or the JavaScript.

**To build a release zip:** `build/release.sh` zips the committed state of `package/` into `dist/`; `build/release.sh --working-tree` includes uncommitted edits (for test builds). The header of the script explains the naming and checks. Don't unzip a build into your Packages folder while `f_` there is a symlink to your checkout: it would write into your working tree.

Background on the package layout and the choices behind it: `docs/max-reference/packaging.md`.

## Requirements

- Max 9 (earlier versions untested)
- Vsynth -- available via Max's Package Manager

## Patches

Every patcher in `package/patchers/` is listed here, grouped by type and alphabetical within each group. Entries marked ⚠ are built but unfinished, unverified or undocumented: don't rely on them. The `f_vf_` modules work with float32 `f_vecfield` textures, produced by the `f_vf_` generators and consumed by `f_caustic`, `f_vf_warp`, `f_vf_streak` and `f_vf_seeds`.

### Generators

| Patch | Description |
|---|---|
| `f_chladni` | Chladni plate modal synthesis visualizer (Bessel modes); audio companion patch included |
| `f_masonry` | Parametric masonry texture -- courses, bond, mortar, drift, color |
| `f_ngon` | ⚠ Unfinished. Regular N-gon generator / mask with a live-modulatable vertex count. Built, but not yet confirmed or documented |
| `f_sirds` | Single Image Random Dot Stereogram -- strip-based real-time construction; depth texture drives displacement of a repeating pattern |
| `f_vf_flow` | Dual-mode uniform/texture-perturbed direction field -- designed to feed f_weave's vecfield inlet |
| `f_vf_repulse` | Texture-driven repulsion vecfield -- 16-sample ring accumulation, luma threshold; four accumulation modes (Cancel, Max, Abs Add, Turbulent) |
| `f_vf_seeds` | Discrete mark placement/orientation via f_vecfield and a shape tex -- Voronoi-style seed distribution with priority-generalized selection and multi-owner overlap (texture bombing); shape tex + mod tex inlets |
| `f_vf_vortex` | Single fixed-point vortex field -- convergence, curl, position, 4 mod inlets |
| `f_vf_vortex_multi` | Three-site additive vortex field -- per-site position/conv/curl, 4 global mod inlets |
| `f_vf_vortex_multi_version` | ⚠ Undocumented. A second, differing file shipped beside `f_vf_vortex_multi`; unclear whether it is a superseded draft or an intentional alternate |
| `f_weave` | Parametric line-mark texture -- continuous distance-field lines with per-line phase variation; optional vecfield + scalar-potential inlets |

### Generator / processor

| Patch | Description |
|---|---|
| `f_grain` | Stochastic grain field with per-grain displacement and luma gating |
| `f_stipple` | 2D hash field stipple texture |

### Processors

| Patch | Description |
|---|---|
| `f_caustic` | Optical caustic -- streamline accumulation weighted by field convergence; two outlets (composited / isolated layer) |
| `f_channel_grader` | Per-channel color grading |
| `f_droste` | Log-polar spiral transform -- Droste / Escher-style recursive zoom |
| `f_hue_processor` | Hue-selective processing |
| `f_lens` | Filmic lens -- aberration, distortion, transmission, tilt-shift, ghost images, halation, spatial modulation |
| `f_luma_processor` | Luminance-selective processing |
| `f_mobius` | Mobius transformation UV-space processor |
| `f_stereo` | Stereographic projection display layer |
| `f_tone_curve` | Tone curve adjustment |
| `f_vf_advect` | Temporal fluid advection via f_vecfield -- accumulates flow across frames; decay >1.0 gives excitable/amplifying character |
| `f_vf_chroma` | Vecfield-driven chromatic aberration -- rainbow/hue-sweep streak along field direction; two outlets (composite / isolated layer) |
| `f_vf_fieldmap` | Scalar texture to vecfield via central difference gradient -- primary source: jit.gl.bfg |
| `f_vf_fluid` | Spectral incompressible-flow velocity solver -- force f_vecfield in, persistent evolving velocity f_vecfield out; viscosity, projection and drag controls; fixed 256x256 solver at any render size. Outputs a field, not an image: feed it to f_vf_advect / f_vf_warp / f_vf_glow |
| `f_vf_glow` | Field-aligned directional blur via f_vecfield -- accumulates source samples along streamlines with exponential falloff; two outlets (composite / isolated glow layer) |
| `f_vf_optical_flow` | Real Lucas-Kanade optical flow from source texture motion -- confidence-gated masking, temporal accumulation, and directional spatial fill along the locally-ambiguous axis for the classic aperture-problem failure mode; two outlets (vecfield / confidence+axis) |
| `f_vf_potential` | Scalar potential-field integrator -- accumulates vecfield magnitude over time via feedback; feeds f_weave's scalar inlet |
| `f_vf_prism` | Vecfield-driven spectral/prism separation -- luma-gated RGB displacement along field direction; two outlets (composite / isolated layer) |
| `f_vf_streak` | Directional blur via f_vecfield -- accumulates source samples along streamlines; two outlets (composite / isolated streak layer) |
| `f_vf_vorticity` | ⚠ Unverified. Vorticity-confinement ("curl amp") processor: adds back the fine swirl a field's curl implies. Do not treat as working |
| `f_vf_warp` | UV warp via f_vecfield -- displaces source texture along field streamlines |

### Utilities

| Patch | Description |
|---|---|
| `f_modules` | Module menu -- pick a module to add it to the patch as a bpatcher; categories marked ∇ hold vecfield modules |
| `f_texrouter` | 4x4 texture routing matrix with preset system |
| `f_util_matrix_2` | Modulation routing matrix (2-source MVP) -- textures in, scalar per-param routing messages out; draft status |
| `f_util_profile` | CPU-side dual-axis luminance profiler -- outputs row/column profile textures for modulation |
| `f_vf_split` | Splits an f_vecfield's X/Y channels to two separate greyscale outlets, unipolar or bipolar |

### Audio-domain (`gen~`)

| Patch | Description |
|---|---|
| `f_a_ripple` | ⚠ Unfinished. Generator for the cross-frequency de-correlating ripple stimulus of Yukhnovich et al. (2025): a broadband harmonic carrier with a dynamic spectral ripple on one octave band. DSP confirmed by ear; the UI is still plain flonums and toggles, and there is no reference doc or helpfile yet |
| `f_chladni_audio` | ⚠ Unverified. Audio-input companion for `f_chladni`: per its spec, a pitch follower drives `note` and an amplitude follower drives `amp`. No reference doc |

## Notes

These patches are developed alongside personal Vsynth performance work and released as-is. They follow Vsynth conventions and are designed for Vsynth signal chains. If you know Max and Vsynth, you should be able to understand and modify the patches as needed.

There is no release schedule. Patches may change significantly as development continues.

## Repo Structure

This repo has six parts:

- **`package/`** — the installable Max package: `patchers/`, `help/`, `examples/`, `javascript/`, `package-info.json`, `readme.md`. This is the only folder Max needs (see Installation above).
- **`build/`** — the build system used to generate patchers from definition files, plus supporting tools (helpfile generation via Claude API, interface auditing, migrations, the release zip script `release.sh`). Meant to be forked or read if you want to build your own `f_`-style bpatcher library. See `build/spec.md`.
- **`src/`** — build-input files per module: `definition.py` (patcher definition), `codebox_*.gen` (confirmed codebox content), and per-module build scripts for modules whose build needs diverge from the general `build_patcher.py` path.
- **`tests/`** — verification that doesn't need a scratch patch, in two layers. **Math:** NumPy mirrors of codebox algorithms, checked against independent references (`test_*.py`, `tests/run.sh`, no Max needed). **Execution:** a Max test bench — one generated patch stays open in Max and is driven from Python over OSC, so a module's real `src/` codebox runs on the GPU and its output is diffed numerically, with compile errors caught and cost measured (`bench_*.py`, `tests/bench.sh`). A second bench loads *shipped* bpatchers inside Vsynth's own render context to check their contracts: that every parameter reaches the attribute it claims to, that bypass passes through, that every outlet renders. How-to in `tests/README.md`; design in `.specify/test_bench/`.
- **`ideas/`, `.specify/`, `docs/`** — planning and reference material: half-formed module ideas (`ideas/`), specs/plans/ADRs for modules (`.specify/`), and as-built reference docs plus research notes on Vsynth/Max internals (`docs/`). `docs/f-reference/module-inventory.md` and `docs/vsynth-reference/module-inventory.md` are flat one-line-per-module capability maps (f_ layer and core Vsynth layer, respectively) — the fast way to answer "does something here already do X" without reading full per-module docs. `.specify/` root holds directories for modules under active development. `.specify/stable/f_name/` and `.specify/paused/f_name/` hold modules moved into those subdirectories once shipped-and-verified-with-nothing-outstanding (`stable/`) or shelved on a real open question, not to be resumed by default (`paused/`) — a reorganization into subdirectories, not a rename of the module's own directory. Once a module reaches `stable/`, its `.specify/` content there is archival reference (the ADR/decision history), not the active source of truth — that role passes to `docs/f-reference/f_name.md`, which should have already distilled anything from `spec.md`/`plan.md`/`tasks.md` worth keeping before the move. Kept public as a reference and conversation starter, not as polished documentation — expect dead ends, superseded approaches, and in-progress modules alongside finished ones.
- **`skills/`** — [Claude](https://claude.ai) skills used to collaborate with Claude on this codebase. Eight of them, covering Max/Vsynth/audio-DSP domain knowledge: conventions for bpatcher structure (`vsynth-bpatcher`), GenExpr/`jit.gl.pix` gotchas (`jit-gen-codebox`), the audio-domain equivalent for `gen~` (`gen-tilde-codebox`), `pfft~` spectral processing (`pfft-spectral-processing`), the read-the-help-patch-first workflow for unfamiliar Max objects (`max-advanced-object-methodology`), hand-authoring `.maxpat` JSON without a live Max (`maxpat-json-authoring`), helpfile format (`f-helpfile`), and a notation system for describing patches in chat (`max-patch-notation`). The dividing line: domain knowledge lives here, generic workflow/process scaffolding does not. This directory is the single source of truth — other checkouts symlink here rather than keeping copies, after two of them silently diverged in both directions. Uploaded copies can't be symlinked, so `skills/MANIFEST.md` records the last-uploaded state and `skills/check.sh` reports drift (`check.sh stamp` after re-uploading). Copy these into your own Claude setup (e.g. `claude-scaffold`-style skills directory) if you want a similar collaboration workflow — you'll want to adjust the hardcoded paths in `vsynth-bpatcher/SKILL.md` to match your own repo location.

`tools/` also exists, holding one-off scripts from past development sessions — not part of the supported build system (see `tools/README.md`).

## Development

Modules are built from definition files (`src/` → `build/build_patcher.py` → `package/patchers/`) rather than patched by hand, so the structure stays consistent and reviewable as diffs.

Verification happens in three tiers, cheapest and most attributable first — the full rationale is in `.specify/constitution.md`:

1. **Math** — a NumPy mirror of the codebox, checked against independent ground truth. No Max.
2. **Execution** — the real codebox file run on the GPU through the test bench and diffed numerically; shipped bpatchers additionally contract-tested for parameter wiring and bypass.
3. **Judgement** — a scratch patch for what numbers can't judge: expressive tuning, parameter ranges, visual character, Vsynth integration.

The reason for the split: a scratch patch tests two things at once — whether the math is right and whether Max and the GPU run it — so a failure can't be attributed to either. Separating them turned "this doesn't look right" into specific answers, and the contract tests found real bugs in shipped modules that no amount of looking would have surfaced.
