# Optics map — the light-transport group of f_ modules

_Created: 2026-10-06._ **Status: 🔵 map / research note, not a spec. Nothing here is decided.** Built from `docs/f-reference/module-inventory.md` and the `ideas/` files, **not** from the per-module docs or live patches, so any "Have" may turn out thinner than the one-liner suggests. Check `docs/f-reference/<module>.md` before relying on one. Companion to `f_lumia.md` (the concrete effect that prompted this).

## The group as a light pipeline

The menu's "Optical" category holds only `f_lens` and `f_vf_prism`; `f_caustic`, `f_vf_chroma`, `f_vf_glow` and `f_vf_streak` sit in ∇ Processors because the menu groups by vecfield-ness. The optics concept runs across menu categories. It lines up with what light does from source to viewer:

| Stage | Question | Modules |
|---|---|---|
| Medium | Where is the light redirected? | field producers (`f_vf_fieldmap`, `f_vf_vortex`, `f_vf_repulse`...), then `f_vf_warp` (image view) and `f_caustic` (energy view) |
| Dispersion | Do wavelengths separate? | `f_vf_chroma`, `f_vf_prism` |
| Scatter | How does light spread? | `f_vf_glow`, `f_vf_streak` |
| Camera | What does the imaging system do? | `f_lens` (distortion, aberration, vignette, ghosts, halation, tilt-shift) |
| Persistence | What lingers? | `f_vf_advect`; `f_grain`'s feedback layer, loosely |

The first three are **scene optics** (what the medium does to light); `f_lens` is **camera optics** (artifacts of the imaging system). Physical order is medium, dispersion, scatter, lens, then tone/grain. Reordering still gives an image but stops reading as one physical thing (chroma before glow = coloured glow; chroma after glow = fringes on already-spread light).

Mirror/projection optics arguably also belong to the concept: `f_mobius`, `f_droste`, `f_stereo`, and the `f_poincare` / `f_ngon` kaleidoscope work sit in Spatial today.

## Compounding principle: share the field

Each field consumer reads a different property of the same field: warp reads displacement, caustic convergence, chroma/prism direction, glow/streak the streamline. One field feeding several consumers makes the effects agree on where the "glass" is, which is what makes a stack read as one object rather than several filters. Practical hooks: the composite + isolated outlets on glow, streak, chroma, prism and caustic (build from isolated layers instead of stacking composites), and the shared `gain` / `mix` convention for balancing a stack.

## Combinations that follow (all untested compositions)

- **Lumia glass:** height -> fieldmap -> caustic, + warp + chroma (`f_lumia.md`).
- **Underwater light:** one slow field warps the scene while caustic's isolated layer is added over it; one field, two jobs.
- **God rays:** radial `f_vf_vortex` -> streak or glow (`godray_radial_accumulation.md`).
- **Anamorphic flares:** `f_vf_flow` unconnected (uniform-direction field) -> streak at a horizontal angle; the field-driven half of `f_anamorph_unnamed.md` from existing modules.
- **Crystal / prism light:** field -> `f_vf_prism`, caustic layer added for bright cores.
- **Afterglow:** `f_vf_advect` after any of the above for phosphor-like trails.

## Chart by phenomenon

Status: **Have** = shipped; **Compose** = existing modules, no new code; **Build** = small new module/codebox; **Research** = feasibility unknown; **Skip** = not a single-pass problem.

**Medium**

| Phenomenon | Status | Notes |
|---|---|---|
| Field from any scalar | Have | `f_vf_fieldmap` |
| Smooth animated glass height | **Missing** | Candidates: `f_chladni` luma (only if it is plate displacement rather than a nodal-line mask: check), `jit.gl.bfg` with a time axis (unchecked), FDTD water via `f_cymascope` (idea only) |
| Structured glass (fluted, hobnail, lens arrays) | Build | Small height generators; Voronoi machinery exists in `f_grain` / `f_vf_seeds` |

**Ray optics**

| Phenomenon | Status | Notes |
|---|---|---|
| Refraction displacement | Have | `f_vf_warp` |
| Caustics | Have, fidelity unknown | See research item 1 |
| Reflection / environment lookup from a normal | Build, cheap | Gradient already is a normal; sibling lookup to warp |
| Thick glass, multi-step ray march | Research | Fixed-iteration loops safe, `break` unverified (`f_apollonian.md`) |
| Multi-bounce, total internal reflection | Skip | |

**Wave optics**

| Phenomenon | Status | Notes |
|---|---|---|
| Thin-film iridescence (oil wheel, soap film) | Build, cheap | Scalar thickness -> interference palette; feed from `f_vf_advect` or `f_vf_potential`; overlaps `spectral_rainbow_colormap.md` |
| Diffraction (starbursts, Airy, gratings) | Research | PSF = Fourier transform of the aperture; a GPU DFT is already verified (`f_vf_fluid`) |
| Laser speckle | Research | Same machinery: squared magnitude of the FFT of random phase |
| Interference / moire | Compose or Build | Two `f_weave` instances; `f_moire` is a scratchpad idea |

**Dispersion**

| Phenomenon | Status | Notes |
|---|---|---|
| RGB split along the field | Have | `f_vf_chroma`, `f_vf_prism` |
| Continuous spectral dispersion | Build / Research | N wavelength taps weighted by a spectral colormap; check how far `f_vf_prism`'s feather already goes |

**Scatter and photometric**

| Phenomenon | Status | Notes |
|---|---|---|
| Anisotropic glow / streak | Have | `f_vf_glow`, `f_vf_streak` |
| Halation, ghosts, vignette | Have | `f_lens` |
| Volumetric shafts (incl. caustic-masked) | Compose, untested | Radial field -> streak/glow |
| Dual-Gaussian glow, afterimage | Build | Specced in `glow_profile_and_afterimage.md` |
| Persistence | Have | `f_vf_advect` |

**Camera**

| Phenomenon | Status | Notes |
|---|---|---|
| Depth of field / bokeh | Build | Aperture-shaped disc taps (`f_ngon` as a possible aperture shape); needs a focus map, the open question that shelved `f_focus` |
| Coma, astigmatism, field curvature | Research | May partly exist in `f_lens`: check |
| Anamorphic | Compose / Build | `f_anamorph_unnamed.md` |

Gobos are not missing: any texture generator (`f_weave`, `f_stipple`, `f_masonry`, `f_ngon`) is already a gobo source.

## Constraints that shape what is reachable

- **GenExpr single-pass limits:** `ddx`/`ddy` equivalents, 3D texture sampling and `break` are all unconfirmed (`line_edge_antialiasing.md`, `f_apollonian.md`).
- **A fixed-resolution internal stage is a resampler:** the verified DFT runs at 256^2, so Fourier optics would be low-passed unless handled deliberately (`skills/jit-gen-codebox`).
- **Stack cost:** under Param bypass the shader keeps running (HANDOFF 2026-10-06, GPU-cost caveat, undecided), so a long optics stack may cost real frame time even when bypassed.
- **Vecfield contract:** float32, RG = XY, 0.5 = zero (`f_vecfield_type.md`). How large a displacement it handles gracefully is unchecked.

## Research priorities (proposed order, not decided)

1. **Caustic fidelity. DONE 2026-10-06 (NumPy mirror only, not run in Max): see "Findings: caustic fidelity" below.**
   **Sheets mode decided 2026-10-07: GPU scatter at a fixed internal capture size (see "Findings: scatter density, cost and detail").**
2. **Glass generator.** One scratch session: check the `jit.gl.bfg` time axis, try `f_chladni` luma as glass, write a fluted/hobnail height codebox.
3. **Thin-film palette.** Cheap and probably high payoff; the oil wheel is also a classic of the same light-show lineage as Lumia.
4. **Fourier optics on the existing DFT.** High risk, high reward. Only start with a specific target (a starburst, or a bokeh shape from an aperture texture).
5. **Bokeh / depth of field.** Biggest visual payoff on the camera side, but hinges on the focus-map decision that shelved `f_focus`.

## Findings: caustic fidelity (research item 1, 2026-10-06)

**Method.** `scratch/caustic_fidelity.py` (untracked; run with `uv run --no-project --with numpy --with matplotlib python3 scratch/caustic_fidelity.py`, `SEED=` picks the glass, `FRACS=` the distances). A NumPy mirror of `src/f_caustic/codebox_v2.gen` built on `tests/gpu_sim.sample` (the shipped patcher reproduces exactly from that codebox, `drift.py` ok), compared with an independent ground truth: a fine grid of glass points forward-splatted to `x = u + d*F(u)` and histogrammed (photon counting, 256^2). Test glass: a periodic smooth height (5 low-frequency modes), F = its gradient, peak |F| 0.9, first fold at d* (about 0.055 UV for the two seeds used). Distances are in units of d*. Also tested: the module's own first-order term (its output at `scale` 0) and a probe estimator ("det gather": 3 fixed-point steps to an approximate preimage, then 1/|det(I + d*J)| clamped at 0.05). Figures: `scratch/caustic_fidelity_seed{7,3}.png`, `..._seed7_far.png`.

**Ground truth sanity.** The truth agrees with first-order theory about as well as photon noise allows (r 0.62 against about 0.61 expected), and the independent determinant gather matches it at r 0.999 at 0.6 d*. So the reference and the sign convention are sound.

**What the module computes.** Per pixel it traces 8 steps backward along the field and sums `max(-div F, 0) * source` at each step. The weight depends on position only, never on `scale`. That is exactly the first-order term of the true intensity (1 - d*div F), the Taylor expansion of 1/|det(I + d*J)| for small d. `scale` only moves where the 8 samples are taken.

**Results (Pearson r vs truth / top-8% overlap, seed 7; seed 3 within a few points except where noted).**

| d / d* | module | first-order only | det gather |
|---|---|---|---|
| 0.3 | 0.91 / 0.81 | 0.92 / 0.77 | 0.99 / 0.85 |
| 0.6 | 0.93 / 0.72 | 0.92 / 0.62 | 1.00 / 0.96 |
| 1.0 | 0.82 / 0.52 (seed 3: 0.71) | 0.75 / 0.41 | 0.97 / 0.90 (seed 3: 0.91) |
| 1.5 | 0.55 / 0.36 | 0.45 / 0.25 | 0.72 / 0.66 |
| 2.0 | 0.63 / 0.43 | 0.50 / 0.31 | 0.65 / 0.53 |
| 3.5 | 0.51 / 0.20 | 0.56 / 0.18 | 0.06 / 0.06 |
| 5.0 | 0.16 / 0.07 | 0.22 / 0.11 | 0.17 / 0.09 |

1. **Up to the first fold the module is a decent soft approximation** (r 0.91-0.93 at 0.3-0.6 d*), but the 8-step trace buys almost nothing over its own first-order term at small d, and only a modest gain near d*.
2. **It does not focus.** Its output at 0.3 d* and at 1.0 d* correlates at 0.986 (0.983 for seed 3); the truth over the same range correlates at 0.78 (0.68). Real light sharpens from broad bands into thin fold lines as distance grows; the module gives the same soft blobs at every distance (visible in the figure). Since the weight is blind to `scale`, no `scale` setting changes that.
3. **Fold lines are absent by construction.** Divergence is the trace of J. A fold needs one eigenvalue of J to reach -1/d, and a saddle (eigenvalues of opposite sign) can have zero divergence while sitting exactly on a fold. The divergence weight sees none of that.
4. **Diverging zones cannot darken** (`max(-div, 0)`, additive over the source), whereas real light is redistributed. Minor for a pure additive layer.
5. **Past about 2 d* nothing tested at that point tracks the truth, the (single-branch) determinant gather included; a multi-start gather tested afterwards does much better (see "Findings: multi-guess gather").** The light is multi-valued there (several glass points land on one screen point) and a single-branch gather finds one preimage or none. The truth at 3.5 d* and 5 d* is no longer thin lines: it is overlapping translucent folded sheets with bright fold edges (see `scratch/caustic_fidelity_seed7_far.png`). That is the Lumia veil/ribbon look, reached from the glass-physics direction rather than the fluid-advection direction.

**Implications (not decided).**
- If the target is the focused-light network, the module as built cannot produce it at any setting in this test, and a determinant-based gather would reproduce it up to roughly 1 d*, by sample count at about 8 texture reads per pixel against the module's 64 (not measured). Its singular fold lines need a clamp/softening policy (the probe's 0.05 floor is arbitrary), and `out2` is clamped to [0, 1] today.
- If the target is the layered-sheet look beyond 2 d*, a single-guess gather cannot do it (a multi-start gather, tested later the same day, partly can; see "Findings: multi-guess gather" below). Scatter is the other route: splat each glass point to where it lands and accumulate. **Feasibility check done the same day: a GPU scatter works inside Vsynth's render context and matches the photon-counting truth (r 0.994 at 3.5 d*); see "Findings: scatter feasibility spike" below.**
- The module is not "wrong": soft convergence glows may be a good look in their own right (a Tier 3 judgement). This note only says it is not a physical caustic, so effects built on it will not behave like light through glass as distance, glass or animation change.

**Limits of this check.** One synthetic smooth periodic glass family, two seeds; NumPy only, nothing run in Max; uniform white source only (no gobo/source placement, no `color_shift`, default `softness`/`gain` gating not modelled, output clamp not modelled); the module's own `scale` default (0.3 UV) is about 5 d* for this field, but d* depends on the field's curvature, so a gentler field (e.g. a smooth vortex) puts the same `scale` in a different regime; Pearson r and top-8% overlap are crude proxies for "does it look like caustics".

**Doc discrepancy found.** `docs/f-reference/f_caustic.md` says `scale` 0 gives "no trace, no caustic". The mirror says otherwise (r 1.0000 with `max(-div, 0)`): at `scale` 0 the layer is the undisplaced divergence-weighted source at full strength (mean 3.7, max 21.7 at gain 1, before `out2`'s clamp). Corrected in the doc 2026-10-06.

## Findings: scatter feasibility spike (2026-10-06)

**Question.** Can a GPU scatter (send every glass point to where it lands, accumulate additively) run inside Vsynth's render context? It is the physical way to the folded-sheet look beyond about 2 d*, which a single-guess gather cannot form (a multi-start gather, tested afterwards, partly can; see below).

**Precedents found in shipped files on this machine** (not from memory): Vsynth's `patchers/vs_xyz_disp.maxpat` (a `jit.gl.node @capture` holding a mesh drawn with a vertex-texture-fetch shader, `code/vtfk.jxs`, GLSL 1.20, textures adapted through `jit.gl.slab @rectangle 0`); Max's `iterated.function.systems.maxpat` (a points mesh, additive blend, into a float32 node); the Jitter Tools transform-feedback examples (`tf.vecfield.2tex`: GPU-resident particles advected by vecfield textures, not used here); the `blend_mode` integers from `jit.gl.sketch.maxhelp` (`1 1` = additive, `6 1` = src_alpha, one).

**What was built** (a record, not a regression gate; nothing shipped): `tests/bench/spike_scatter.maxpat` (+ `make_spike_scatter.py`, `--chain` variant for the lag test) and `spike_scatter.jxs`, driven through the module bench by `tests/spike_scatter.py` against a NumPy emulation of the shader and the photon-counting truth. Design: `jit.gl.gridshape @matrixoutput 1` into `jit.gl.mesh @draw_mode points` drawn into a float32 `jit.gl.node @capture 1`; a GLSL 1.20 vertex program reads the vecfield in the vertex stage, lands each point at `u + d*F(u)` and passes the source colour at `u`; additive blending; a fragment tent weight from the point's exact sub-pixel position; `point_size 3`.

**Results** (capture 256^2, glass seed 7; full output in `scratch/scatter_spike_*.log`):

| Check | Result |
|---|---|
| Identity (d = 0) | Matches the NumPy emulation exactly (relative error 0.0000). |
| Orientation | Both the texture upload and the capture readback flip vertically: the image comes out upright but the field's Y is inverted. A shader `fy = -1` fixes it; the result then matches the pix-chain convention (r = 1.0000 against the emulation in matrix space). |
| Float32 accumulation | Exact, no clamp: 4096 points on one pixel sum to 4096.0 (an earlier run reached 23,814 at one pixel). HDR illuminance is feasible. |
| Real glass vs photon-counting truth (n = 1536, 36 points per pixel) | r = 0.999, 0.999, 0.994 at 0.6, 1.0, 3.5 d*; top-8% overlap 0.958, 0.982, 0.926. The module's gather scores 0.934, 0.822, 0.510. GPU against the NumPy emulation: r = 1.0000 at all three. |
| Quality vs density | Reaches the plateau by about 4 points per pixel (r 0.9985 at 1 d*, 0.9937 at 3.5 d*, against 0.9993 and 0.9940 at 36); even 1 per pixel gives 0.990 and 0.978. |
| Frame lag (pix -> node -> capture) | **Exactly 1 frame behind the upstream pix**, in all 8 captures (counter decode); a plain pix -> pix reference lags 0, as documented. |

**Facts that shape a module (each measured here):**
- `jit.gl.gridshape` has no valid `@draw_mode`, and its own `@poly_mode 2 2` draws each vertex once per adjoining triangle (multiplicity about 6). Use the matrix output into a mesh in points mode (multiplicity exactly 1).
- GL points are round, so a size-1 point deposits only where its centre is within 0.5 px of a pixel centre: it deposited pi/4 of the energy and aliased against the lattice (a perfect-looking disc, which was a moire). Energy per point is pi * (size/2)^2 (0.777, 3.126, 7.009 measured for sizes 1, 2, 3). The tent splat with `point_size 3` conserves energy and does not depend on sub-pixel phase.
- The lattice matrix is 12 planes, 48 bytes per vertex (about 200 MB at 2048^2); Max reached about 3 GB resident during the sweep. A cheaper lattice source would help.
- Cost (bench paces at 60 fps, so "at the cap" hides the headroom): realistic glass at 3.5 d* stayed at the cap up to 6.55 M points into a 1024^2 capture; the one over-budget glass case (4.19 M points into 256^2, 64 points per pixel) fits the contention pattern below. Worst case, every point on one pixel, scales linearly at about 88 ns per point (91.6 ms for 1.05 M, 372 ms for 4.19 M, 542 ms for 6.55 M). Peak illuminance in the real field was about 18x the mean, nowhere near that contention.

**Not tested:** a non-white source (gobo placement), per-channel dispersion, `f_vecfield` sources from a real producer (the spike used a texture file and a counter pix), the module inside a full Vsynth chain, headroom beyond the 60 fps cap, 1080p/4K captures, `@layer` settings as a possible cure for the 1-frame lag, wrap-around at the borders (the emulation and truth treat edges differently from the clip), and a second glass seed.

**Verdict.** Feasible, and it is the only route found that reproduces the sheet regime. The open risks are the 1-frame lag against pix-chain consumers (warp and caustic from one field would be a frame apart), the lattice memory, and untested gobo/dispersion. It is not a drop-in for `f_caustic`: a scatter module owns a GL scene (node, mesh, shader, lattice), so it is closer in kind to `vs_xyz_disp` than to the f_ pix modules.

## Findings: scatter density, cost and detail (2026-10-07)

**Decisions (Matt).** The sheets mode of `f_caustic` is built on the **GPU scatter** ("the numbers strongly suggest the gl method"); the multi-start gather stays in `tests/` as the fallback. The 1-frame lag is accepted (the library already has them elsewhere). **MVP: a fixed internal capture size**, not a scale relative to the output, so the output resolution changes sharpness and not cost (as `f_vf_fluid` fixes its internal 256^2).

**What was measured.** Records, not regression gates: `tests/spike_scatter.py` stages `s4` to `s9`, driving `tests/bench/spike_scatter.maxpat` (`make_spike_scatter.py`) and `spike_scatter.jxs`. The shader gained `h` (tent half-width), `snap` (corner snap), `jit` and `latn` (lattice jitter) and `taps` (source prefilter); the patch takes them as `h snap jit latn taps` tokens. Logs and figures: `scratch/scatter_spike_s4*.log` to `s9`, `scatter_spike_s7_*`, `s8_*`, `s9.png`. All on one M3 Max (30 GPU cores), Max 9.2.0, glass seed 7, `d = 3.5 d*` unless stated.

**1. A load multiplier did not work, so its numbers were discarded.** Drawing the lattice K times per frame (K gated meshes) to push the cost past the bench's 60 fps cap gave periods that were not linear in K: a 4 k-point lattice read 107.7 ms at K = 32 and -27 ms at K = 8, and the same 1 M-point config read 47.3 and 39.6 ms on repeat. Each mesh carries overhead that is not GPU fill. The K meshes were removed from the generator. The lesson: validate a new timing method on a known-cheap and a known-linear case first.

**2. Corner-snap with `point_size 2` is the same image as `point_size 3`, bit for bit** (n = 1536 into 256^2: max |diff| 0.0000, sum ratio 1.0000, peak 18.59 for both). The vertex shader snaps the point to its nearest pixel corner and the fragment shader keeps weighting by the unsnapped position; a size-2 round point on a corner covers exactly the four pixel centres the tent can reach (distance 0.707 < 1). Control: size 2 without the snap loses 2.5% of the energy. It is free to adopt. **A speed-up was not established**: it looked 2x faster at 16 points per pixel in one run and slower in the next.

**3. Cost is driven by points per pixel (blend contention), not by point count.** Fixed n = 4096 (16.8 M points), capture size varied, ms per frame, two runs (A / B):

| points per pixel | size-3 footprint | corner-snap, size 2 | size 1 (vertex only) |
|---|---|---|---|
| 64 | 71 / 56 | 61 / 56 | not run |
| 16 | 69 / 29 | 35 / 45 | 20 / 25 |
| 4 | 37 / 22 | 24 / 23 | not run |
| 1 | 22 / 19 | 17 / 17 | 16 / 16 |

Vertex work is cheap (16.8 M points at size 1 and 1 point per pixel sit at the 16.7 ms cap, so about 1 ms per million points or less); the rest is fill and contention. At 1.0 to 2.2 ms per million points for 1 to 4 points per pixel (this machine only), and excluding the upscale pass: 1 M points about 1 to 2.5 ms, 2 M points about 2 to 5 ms, 4 M points about 4 to 9 ms. **Run-to-run variation is up to 2x on the same config** (size-3, 1024^2, 16 points per pixel read 69, 29 and 45 ms in three runs); two reps within one run agree to a few percent. Treat all of these as an order of magnitude and compare within a run. The earlier sweep's slope fits (S4) are not trustworthy.

**4. A coarse internal capture plus a bilinear upscale keeps most of the quality.** Reference = 16 points per pixel at 1024^2; Pearson r / top-8% IoU against it at 1024^2; `s` = capture at 1/`s` of the reference; `p` = points per capture pixel:

| `s`, `p` | M points at 1080p | 1 d*: r / IoU | 3.5 d*: r / IoU |
|---|---|---|---|
| 1, 1 | 2.07 | 0.9909 / 0.910 | 0.9880 / 0.885 |
| 1, 4 | 8.29 | 0.9992 / 0.983 | 0.9998 / 0.987 |
| 2, 1 | 0.52 | 0.9953 / 0.953 | 0.9546 / 0.879 |
| 2, 2 | 1.04 | 0.9981 / 0.978 | 0.9579 / 0.899 |
| 2, 4 | 2.07 | 0.9986 / 0.989 | 0.9583 / 0.901 |
| 4, 2 | 0.26 | 0.9929 / 0.968 | 0.9026 / 0.809 |

At `s = 2` the loss is resolution, not noise: `p` barely changes r (0.955 to 0.958 at 3.5 d*) because the thin bright lines soften; density matters mainly at `s = 1`, where it is pure noise. Distance matters: 3.5 d* has thinner lines and loses more (0.958 against 0.998 at 1 d* for `s = 2, p = 2`). Viewed after a box-down to 256^2, every `s = 2` row is at about 0.996 or better. **Looking at the picture matters**: `p = 1` shows a visible lattice moire (a cross-hatch in the dim regions) that Pearson barely registers (0.9546 against 0.9583 for `p = 1` against 4 at 3.5 d*); `p = 2` at `s = 2` looked clean; `s = 4` is clean but soft.

**5. Lattice jitter (a hash offset within each point's own cell) is a net loss.** It trades the moire for grain and lowers every score: at `s = 2, p = 2` r 0.9579 to 0.9537 (3.5 d*) and 0.9981 to 0.9822 (1 d*); at `s = 1, p = 1`, 1 d*, 0.991 to 0.869. A regular lattice at 2 points per capture pixel is the better estimator. The spectral "structure score" built to measure moire (log10 of the residual power spectrum's peak over median) did not discriminate at `s >= 2`, because the upscale residual is itself structured: do not reuse it. (The 1 d* dim-region mask came out empty, so only 3.5 d* has the dim-region columns.)

**6. Source aliasing (gobo) is smaller than feared.** A zone plate and 1, 3 and 8 px checkerboards on a 1024^2 source, through the 3.5 d* glass, compared after a box-down to 256^2: at `s = 2, p = 2` (lattice n = 724, about 0.7x the source) r = 0.993 to 0.996 and the pictures look like the reference (the only visible artefact is faint streaking on the 1 px checker, which is Nyquist-level noise); `s = 4` (n = 362) loses the finest structure and shows dim speckle (r = 0.961 to 0.978). **A 4-tap box prefilter in the vertex shader changed r by under 0.001 on most sources and by 0.003 at most (zone plate, `s = 4`)**, and costs four reads per point: do not adopt it. (`texture2D` in a vertex program has no derivatives, so the source read is a single bilinear tap per point; `texture2DLod` with mipmaps was not tried.)

**Design these numbers support for the MVP:** a fixed internal capture of about 0.5 to 1 M pixels (960 x 540 is 0.52 M) with 2 points per capture pixel (about 1 M points), a regular lattice, corner-snap with `point_size 2`, one bilinear source read, and a bilinear upscale to the output. Roughly 1 to 2.5 ms plus the upscale pass at that size on this machine, softer than full resolution at long distances, and 4K costs the same as 1080p. The lattice at that size is about 50 MB (48 bytes per vertex), so the 12-byte lattice is not needed yet.

**Not established:** non-square captures and adapting to Vsynth's render size (the spike is square throughout; the sizes above are square equivalents); real video or colour sources, and a second glass seed or distance for the source test; the absolute cost on a weaker performance machine; whether `@layer` can remove the lag (moot: accepted); the `.jxs` search path inside the package; the upscale pass's own cost; and the look on real video (all numbers are against a reference or the physics). **Matt's first look in a live Vsynth chain (2026-10-07, the preset buttons of `scatter_look.maxpat`): the presets look different from each other, none looks worse, and all of the effects could be useful, so the moire, softness and grain the metrics treat as error may be wanted characters.**

## Findings: multi-guess gather (a pull method for the sheet regime) (2026-10-06, NumPy only)

**Question (Matt):** a pixel can only follow one trail back, but is there a pull-based trick that reaches the
sheet regime without the GL scene? **Answer: yes, partly; it is much better than the single-guess gather and
visibly reproduces the ribbons, but it is weaker and far more expensive than scatter.**

**Method** (`scratch/multi_guess_gather.py`, log `scratch/multi_guess_gather.log`, picture
`scratch/multi_guess_gather.png`): multi-start damped Newton. For each screen pixel, solve
`u + d*F(u) = x` for the glass points `u` that land there, from K starting guesses on a grid around `x`
(sources lie within `d*max|F|` of `x`); 8 Newton steps; keep converged roots, drop duplicates; sum
`1/|det(I + d*J)|` over the distinct roots. Uses the **analytic** field and Jacobian, so it is an upper bound
on what a shader reading textures could do. Same photon-counting truth and test glass as before (seed 7).
Validated first where the answer is known: at 0.3 d* it finds exactly 1.00 source per pixel, mean illuminance
1.0000, r 0.990 (the truth's own noise limit).

**Results** (r vs truth / top-8% overlap / mean illuminance, which should be 1.0 if no source is missed;
S = samples per pixel along each axis, a gather needs this to integrate over the pixel):

| d / d* | K=1, S=2 | K=16, S=2 | K=36, S=2 | K=16, S=1 |
|---|---|---|---|---|
| 1.0 | 0.844 / 0.957 / 0.982 | 0.984 / 0.988 / 0.997 | 0.992 / 0.988 / 1.000 | 0.939 / 0.986 / 0.998 |
| 2.0 | 0.765 / 0.614 / 0.618 | 0.942 / 0.889 / 0.932 | 0.952 / 0.936 / 0.970 | 0.855 / 0.742 / 0.932 |
| 3.5 | 0.719 / 0.394 / 0.425 | 0.926 / 0.648 / 0.903 | 0.944 / 0.763 / 0.949 | 0.847 / 0.629 / 0.902 |

For comparison, measured earlier: scatter r 0.999 at 1.0 d*, 0.994 / overlap 0.926 at 3.5 d*; the existing
`f_caustic` gather 0.82 and 0.51.

**What it shows**
- K starting guesses are what make it work: K = 1 loses 40–60% of the light at 2–3.5 d*; K = 36 loses 3–5%.
- The picture (`multi_guess_gather.png`) has the ribbons and fold structure at 2 and 3.5 d*, with speckle along
  the thin lines; S = 1 is visibly more broken than S = 2.
- Weaker than scatter in the sheet regime: overlap with the truth's brightest lines 0.76 against 0.93 at
  3.5 d*, and 3–5% of the light is missed at 2–3.5 d* (the search does not find every source).
- **Cost is the catch (arithmetic from the code, not measured on a GPU).** K = 36, 8 iterations, S = 2 is
  1152 Newton steps per output pixel, each needing the field and its slopes (about 5 texture reads with finite
  differences): roughly 5,800 reads per pixel, about 380 million per frame at a 256² output, before any
  quality tuning. The scatter spike held 60 fps with up to 6.55 M points.

**What it would buy:** it stays an ordinary pix codebox (no GL scene, no 1-frame lag, no 200 MB lattice, no
orientation flip), so it fits the project's builder and tests and a mode inside `f_caustic`.

**Follow-up, same day** (NumPy; `scratch/multi_guess_gather2.py`, log `scratch/multi_guess_gather2.log`):
central 96×96 crop of the output, S = 2, same photon-counting truth.
- **Reading a real texture costs nothing.** A 512² float32 field texture (bilinear, slopes by ±1/512 central
  differences, like a shader) gives the same answers as the analytic field: r 0.947 vs 0.945 at 2 d*, 0.961 vs
  0.957 at 3.5 d*.
- **Smarter starts cut the cost 5–10×.** "Coarse search": look at a 6×6 set of coarse points around the pixel
  and run Newton only from the M whose image lands nearest the pixel.

| starts | Newton steps | reads/px | 2 d*: r / overlap / mean | 3.5 d*: r / overlap / mean |
|---|---|---|---|---|
| grid, 36 starts (reference) | 8 | 5,760 | 0.947 / 0.880 / 0.924 | 0.961 / 0.852 / 0.869 |
| coarse 6×6, best 4 | 6 | ~600 | 0.957 / 0.845 / 0.835 | 0.945 / 0.763 / 0.809 |
| coarse 6×6, best 6 | 6 | ~860 | 0.962 / 0.845 / 0.859 | 0.947 / 0.815 / 0.833 |
| coarse 6×6, best 6 | 8 | ~1,100 | 0.974 / 0.866 / 0.885 | 0.956 / 0.843 / 0.859 |
| coarse 6×6, best 8 | 4 | ~780 | 0.911 / 0.820 / 0.814 | 0.882 / 0.647 / 0.771 |

- Too few Newton steps hurts (4 steps loses at 3.5 d*); the knee is about 6–8 steps with 6 candidates, roughly
  1,000 reads per output pixel at S = 2, against 5,760.
- Caveats: crop only (the crop's mean illuminance is not comparable to the full-frame 1.0); r differences under
  about 0.02 are inside the truth's own photon noise, so overlap and mean are the more reliable columns; the
  residual threshold never pruned anything (the search always used all M candidates), so the practical form is
  "take the M best coarse candidates", which needs only the field's peak magnitude (window = d × peak), not a
  slope bound.
- At about 1,000 reads per output pixel the load is roughly 4 billion reads per second at 256² and 60 fps, and
  4× that at 512² (arithmetic, not a measurement).

**Still not tested:** other glass seeds; a gobo source; real GPU cost in Max for a *correct* gather (see the
prototype findings below).

**GPU prototype of the gather (2026-10-06, `tests/gather_proto.py`, codebox bench; logs in `scratch/gather_*.log`).**
A jit.gl.pix codebox prototype of the coarse-search multi-start gather, generated from Python. Verified on the
bench unless marked otherwise:
- **Parser limit: a STATEMENT budget, not bytes.** Max's codebox parser fails with "lua: [string DSL.Parser]:
  stack overflow (too many captures)". Bisected on the bench (`scratch/parser_limit_probe.py`): about **250
  statements** fit in one function body or at the top level (260 fail; five statements per line changes nothing, so
  it is not lines or bytes), a for-loop body tolerates far more (680), and the **whole program is capped at about
  450 statements** (compiled: 450, 387, 378; failed: 458, 471, 563, 600). `require("file")` works (tiny helper,
  and a required function can sample `in2`) but **adds no budget**: it is a textual include, and two required files
  of 150 statements compile where four fail, exactly like the same code inline. A function body is counted once
  however often it is called, and a call is one statement, so moving repeated code into functions is what helps.
  The 1,810-line unrolled prototype and a 600-statement required file both failed for this reason. An earlier
  version of this note said the limit counts total size; that was wrong.
- **Functions lift it partway.** A GenExpr function can sample `in2`, contain loops with local variables and
  return several values, and a function-based program is **bit-identical** to the unrolled one (M = 4:
  r = 1.00000). With one Newton start as a function called M times, 8 starts compile (387 statements); 10 do
  not (471). Growth that remains per start (about 38 statements at M = 8): the slot-insertion block (10), slot
  setup (11), the call and accumulation, and the O(M²) de-duplication pairs. Estimate, not tested: putting the
  slot insertion and each de-duplication pair behind functions would cut that to about 5 + M/2 statements per
  start, enough for roughly 16–24 starts.
- **A failed compile wedges the bench**: later jobs return a stale image with no error until `reopen()`.
  `gather_proto.ensure_healthy` probes with a known-good codebox and reopens.
- **Cost of the `sample()` version (superseded: that version reads the field nearest-like, see below; corrected figures are in the next-but-one bullet) (valid bench readings; G = 6, T = 6, S = 2):** 4 starts 1.19 ms/pass at
  256² and 3.17 ms at 512²; 6 starts 1.64 and 4.35 ms; 8 starts 2.14 and 5.54 ms, roughly linear in starts. The
  empty-pass floor is about 2.1–2.5 ms per frame, so readings under that are only upper bounds. The first cost
  run was **invalid** (the oversized program never compiled; flat 330–650 fps) and was discarded.
- **RESOLVED: the GPU/NumPy gap was `sample()` going nearest-neighbour.** First reading (GPU r 0.64 / 0.68 /
  0.70 against 0.87+ for the mirror at 3.5 d*) looked like a quality gap. Bisected: not float32 arithmetic (a
  step-for-step float32 mirror is identical to float64), not 8-bit interpolation weights (emulated at 8, 7, 6 bits:
  no change), not candidate selection (same cell in 100% of pixels), not the Newton step (field, slopes and solved
  step match to float32 precision at pixel-aligned coordinates). The cause: **jit.gl.pix `sample()` is not bilinear
  when the coordinate is data-dependent and jumps between neighbouring pixels.** Filtering picks magnify or minify
  from the coordinate's screen-space derivative, and above about one texel per pixel it falls back to the nearest
  minification filter, so the field is read piecewise-constant (median error 6e-3, up to 3.9e-2, half a texel of
  variation, against 2e-5 at pixel-aligned coordinates; `scratch/` probes). Newton starts from different coarse cells
  in neighbouring pixels, so every read is jumpy. Fix: interpolate by hand from four exact `nearest()` taps
  (`gather_proto._fxy_function`, same statement count). With it the GPU equals the float32 mirror to r = 1.0000 and
  reaches, against the photon-counting truth (G6 M4 T6 S2, tol 3e-4): r 1.000 / 0.960 / 0.930 and line overlap
  0.988 / 0.905 / 0.840 at 1 / 2 / 3.5 d*. This also explains the older bench note that a source larger than the pix
  reads nearest-like, and is relevant to any module with iterative or jumpy dependent reads (ray marching, fractal
  iteration, solvers), though not to smooth warps.
- **Cost of the CORRECT gather (hand-made bilinear; G = 6, T = 6, S = 2, GPU-bound readings, ms per pass):**
  4 starts 4.39 ms at 256² and 10.99 ms at 512²; 6 starts 6.07 and 15.73 ms; 8 starts 7.79 and 19.80 ms. About 3.7×
  the `sample()` version (four exact reads replace one filtered read, and the compiler may not share the x and y
  reads). Affordable at a 256² internal size (26–47% of a 16.7 ms frame), not at 512² with 6 or more starts.
  Not tried: reading the slopes from the same four taps as the field value (one call per Newton step instead of
  five), estimated to cut the Newton-stage reads about 5×; it changes the slope definition, so it needs its own
  accuracy check.
- **A source larger than the pix is read nearest-neighbour** (already in the bench notes; same mechanism as the
  resolved item above): the field texture must equal the pix output size for 1:1 filtering. In a real chain the
  vecfield arrives at render size. Matching sizes alone did not fix the gather; the hand-made bilinear did.
- **`step` with two literal constants folds reversed** (`step(0.3, 0.5)` gives 0); with variables or Params it
  follows GLSL (`step(edge, x)`). Shipped modules use variables, so they are unaffected.

## Possible deliverables (none chosen)

A concept doc, or a "light transport" demo patch (one field feeding warp, caustic, chroma and glow with a switch per stage; `.specify/demos/spec.md` already scopes `demo_lens_effects`). A module is probably only warranted where a gap above is real.

## Related

`f_lumia.md`, `f_caustic.md`, `f_lens.md`, `f_lens_tiltshift_split.md`, `f_anamorph_unnamed.md`, `godray_radial_accumulation.md`, `glow_profile_and_afterimage.md`, `spectral_rainbow_colormap.md`, `f_vecfield.md`, `gpu_gems_research.md`, `entrainment.md` (color-organs lineage).
