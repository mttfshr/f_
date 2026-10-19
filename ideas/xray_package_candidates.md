# XRAY package: which objects bear on the current `f_` work?

_Captured 2026-10-18 from Matt's question: are there objects in the installed XRAY package
that we should explore in relation to our current `f_` work?_

**Status:** PARKED (Matt, 2026-10-18 14:33): he has tried `water` before and found it underwhelming, so the whole note is shelved. Not scheduled; nothing waits on it. Analysis only. Nothing built, specced, or run in Max. Read for this note:
README, HANDOFF, `.specify/plan.md`, `CLAUDE.md`, `ideas/INDEX.md`, and the notes
`f_util_analysis`, `f_loop_to_cycle`, `f_texture_sampler`, `variable_framerate`,
`shared_tensor_vecfield_operators`. From the installed package
(`~/Documents/Max 9/Packages/XRAY`, v1.0.2, Wesley Smith, copyright Cycling '74): the
`package-info.json`, the comment text of all 23 helpfiles, the launcher patcher, and, for
the four objects that have no helpfile, the string tables in their binaries.
**Not read:** the upstream source (github.com/weshoke/xray.jit, linked from every
helpfile), any refpage (the package ships no `docs/` folder), and nothing was opened in
Max. Tags: **[help]** = taken from a helpfile, **[inference]** = mine, **[unchecked]** =
needs Max or a measurement. Paused and shelved modules are not used as targets (CLAUDE.md).

---

## Short answer

Yes, but few, and mostly as scratch-patch and precompute tools rather than as parts of
shipped modules. Three tie directly to questions already written down in the repo:

1. **`xray.jit.3dbuffer` + `xray.jit.timecube`** answer, at low resolution, whether a
   per-pixel time offset into stored frames looks and behaves the way `f_loop_to_cycle`
   and `f_texture_sampler` hope.
2. **`xray.jit.water`** is a ready animated height field for the `f_lumia` chain
   (height, `f_vf_fieldmap`, `f_caustic`) and a quick look at wave behavior before an
   `f_cymascope` build.
3. **`xray.jit.cumsum` and `xray.jit.colormap`** produce the 1D tables (equalization
   curve, palette) that the standing "no dependent-texture LUT in `f_`" gap needs. They
   supply ingredients only; the consumer module does not exist yet.

A second group (distance, kmeans, svd, the contour family) is plausible but needs a probe
before it earns anything. The rest is list plumbing, or duplicates what `f_` already does.

**Why the bar is high.** Every XRAY object is a CPU `jit.matrix` external. `f_` is GPU
texture chains. So any XRAY object sits at the end of a `jit.gl.asyncread` readback and,
if its result must come back, needs an upload. That is the `f_util_profile` pattern
(`jit.gl.asyncread` into `jit.dimop`, read from its patcher). Readback latency and
bandwidth are unmeasured here. A shipped module that needed XRAY would also add a second
requirement to the README (today: Max 9 and Vsynth) while packaging is still open
(plan.md, Still open 4). [unchecked: whether `package-info.json` can declare a dependency.]

---

## What is in the package

27 pieces: 23 externals, 2 abstractions (`3dbuffer`, `pinv`), 2 JS (`diagonalize`,
`dynamicexpr`). The four externals checked (blackhole, fdm, levelsetseg, median) are
universal binaries (x86_64 and arm64); every external has a `.mxe64` too. Four externals
have no helpfile: `blackhole`, `fdm`, `levelsetseg`, `median`.

| Tier | Objects | Why |
|---|---|---|
| A: ties to an open question | `3dbuffer`, `timecube`; `water`; `cumsum`, `colormap` | Sections 1-3 |
| B: needs a probe | `distance`; `kmeans`; `svd` (+ `pinv`, `diagonalize`); `contourmap` (+ `cellvalue`, `line2quad`, `grid2tri`); the four undocumented | Section 4 |
| C: no fit | `crossproduct`, `dynamicexpr`, `mean`, `quicksort`, `sift`, `keepcell`, `cellcoords`, `cellminmax`, `invertrepos` | Section 5 |

---

## 1. `3dbuffer` + `timecube`: per-pixel time

**What they do [help].** `3dbuffer` is a "multitap time delay circular buffer": a named 3D
matrix (arguments: planes, type, three dims, a name) that any 2D input writes into, and it
reports the index of the last frame written. `timecube` reads it, three modes: 0 slices a
vertical plane through the time cube (the help calls it "Vasulka mode", i.e. slit-scan),
1 slices a horizontal plane, 2 is **map mode**: a second-inlet map, 1-plane char or long,
picks the frame per pixel ("similar to jit.repos, but in time"). Map values run 0 to n-1
for n frames and are moduloed if they go past.

**The tie.** `f_loop_to_cycle` names exactly this as its central open question (per-pixel
phase offset into a loop, with `f_masonry` bricks each on their own time), and
`f_texture_sampler` option A asks for indexed reads of stored frames. Map mode is that
read, on the CPU. It can answer, cheaply and before any GPU design, whether per-pixel
time offset looks good, how many frames and what resolution it needs, and what the CPU
cost is. Modes 0 and 1 also give slit-scan, which no module in the README table does.
[inference]

**What it cannot answer.** The GPU-resident question (can a `jit.gl.pix` read an
arbitrary `textureset` slot) stays open; `f_texture_sampler` keeps `vs_frame_delay` /
`jit.gl.textureset` as the default route. A map driven by a GPU mod texture needs
readback, 8-bit quantization (char) and re-upload, so this is a concept test, not a route.
The help mentions no interpolation between frames, so the "slot i plus a fraction" lerp
from the sampler note is not covered. [inference] Memory: 160x120 RGBA char is about
77 KB per frame, so 256 frames is about 20 MB; at 720p it is the sampler note's 3.7 MB per
frame (arithmetic, not measured).

---

## 2. `water`: an animated height field, and a wave look

**What it does [help].** A finite-difference (the help also says "Finite Element Method")
water-surface simulation after the Aizu "Fast water animation" paper, which the help
links. Float matrix, run in feedback (the same named matrix on input and output is
required). Attributes: stiffness, damping, timestep, spacestep. The second inlet is a
**per-cell wavespeed** (float or matrix), so a depth map changes how ripples travel. The
help says grids below about 100x100 are very unstable. The demo drops "rocks" with a
`qmetro`, `jit.expr` and `jit.op`.

**The ties.**
- `f_lumia` needs an animated height field to feed `f_vf_fieldmap` and then `f_caustic`;
  its analytic producer `f_vf_glass` is on hold, so the source is currently unfilled.
  Rain on glass with a depth map is a different character from the analytic mode-sum
  families in that spec. Whether wave-equation heights make good caustics is a look test
  that has not been done. [inference]
- `f_cymascope` is queued as an FDTD wave module on GPU ping-pong with "no blocker left".
  `water` is the same family with a variable wave speed. It does not replace the NumPy
  mirror (tier 1 needs one regardless); its role is the tier-3 look before the build, and
  the cited paper is a named independent reference for the scheme.

**Costs.** `f_caustic` alone is about 21-23 ms/frame, so a CPU simulation plus upload
sits on top of that; the 128x128 and 256x256 budgets are unmeasured. [unchecked]

---

## 3. `cumsum`, `colormap`: the LUT ingredients

`lut_curve_and_color_controls.md` records the real gap: no dependent-texture LUT (a 1x256
texture sampled per channel) exists anywhere in `f_`, and Matt wants it pursued
(`f_tone_curve`'s real curve is parked on it, plan.md).

- **`cumsum`** [help]: running sum along a dimension of a float matrix. A histogram run
  through it is a CDF, which is the equalization curve: a content-driven tone curve, in
  the `f_util_analysis` "patch reacts to its own content" spirit. The histogram itself
  would come from core Jitter. [unchecked: that a core histogram object fits.]
- **`colormap`** [help]: takes a 4-plane char frame and outputs a 1D map sorted by
  luminance (mode 0 averages the colors in each luminance bin, mode 1 keeps the first
  color seen), for `jit.charmap`. A palette taken from any still or film frame, usable as
  a scalar-to-color table.

Both output 8-bit char or CPU float tables. The missing piece is the consumer: a pix
module that does a dependent read, and how a 1x256 table reaches it (a named texture, per
`named_mod_textures.md`, is one candidate). XRAY does not close the gap by itself. It is
fine for color and tone; it is the wrong precision for the float32 field types.

---

## 4. Tier B: plausible, needs a probe

**`distance`** [help]: L1 (city-block) distance transform of a 1-plane char or long
matrix; mode 2 does four sweeps (top-down, bottom-up, left-right, right-left). The tie is
`f_vf_repulse`, whose reach is a 16-sample ring: the distance field of a thresholded luma
fed through `f_vf_fieldmap` would give a repulsion field with unlimited reach, and the same
idea gives an obstacle-distance field for `f_vf_lbm` (Phase 0 not started). Caveats: L1
isolines are diamonds, so the gradient has a four-direction bias; the input is char, so
the field is stepped; a moving mask means readback every frame. If it earns a place it
probably belongs on the GPU as chained pix passes (the `f_vf_fluid` precedent); jump
flooding is the usual GPU method. [inference, general knowledge, unchecked here]

**`kmeans`** [help]: clusters a matrix of vectors into a chosen number of clusters
(`clusters`, `dimmode`), starting from arbitrarily chosen vectors. The tie is a dominant
palette from a frame, for the color-driving texture in `f_vf_seeds` (Evolution 3) and for
`f_hue_processor`. Caveats: the help does not say what the centroid output looks like
[unchecked], and arbitrary starts suggest the palette could flicker frame to frame.
[inference]

**`svd`** (+ `pinv`, `diagonalize`) [help]: SVD of a 1-plane 2D matrix into U, a singular
value vector, and V, float output; `pinv` is an abstraction over those three. No clear
tie. One speculative `f_util_analysis` member: the singular-value spectrum of a small
(say 32x32) luma frame as a "how regular is this texture" signal, since stripes and weave
are close to low-rank and noise is not. [inference, no precedent in the repo] It does not
help the tensor family: the per-pixel 2x2 eigenstructure is closed form and already on the
GPU, and SVD works per matrix, not per pixel.

**`contourmap`** (+ `cellvalue`, `line2quad`, `grid2tri`) [help]: isolines of a 3D surface
(up to 10 iso-levels, or evenly spaced levels), output as line geometry; `line2quad` turns
lines into quads in 2D or 3D, `grid2tri` makes a grid into explicit triangles. The
helpfile demo renders through `jit.gl.mesh`. The possible `f_` use is isolines of a scalar
field (`f_vf_potential` output, a height field, `f_chladni` nodal lines). But it yields
geometry, and the `f_` chain is texture in, texture out, so it would be a new module shape
(readback, contour, mesh, render to texture). [unchecked: whether that works inside
Vsynth's render context.] A ten-minute scratch look at contours of `f_vf_potential` is
the most it justifies for now.

**The four with no helpfile.** Names below come from attribute and error strings in the
binaries; the meanings are guesses [inference] until someone opens them in Max.

| Object | Strings seen | Guess | Possible `f_` link |
|---|---|---|---|
| `levelsetseg` | cycles, evolve, point, radius, smooth | level-set segmentation grown from a seed point | a content-derived mask; `f_` has luma gating but no segmentation |
| `blackhole` | angle, attractor, emitter, gravity, min/max distance, timestep, velocity, weight | attractor/emitter particle motion | unclear |
| `fdm` | direction, spacestep, "single plane matrices only" | finite-difference derivative | overlaps `f_vf_fieldmap`'s GPU gradient |
| `median` | dimmode, size | median filter along a dimension | despiking analysis signals or a flow field |

---

## 5. Tier C: no fit

| Object | Why not |
|---|---|
| `crossproduct` | The help itself says a `jit.gen` patch can replace it; vecfields are 2D |
| `dynamicexpr`, `diagonalize` | JS conveniences for building `jit.expr` strings and diagonal matrices; `f_` writes codeboxes |
| `mean` | Row or column mean. `f_util_profile` already gets this from core `jit.dimop` |
| `quicksort`, `sift`, `keepcell`, `cellcoords`, `cellminmax`, `cellvalue` | Matrix list plumbing (sort, filter, coordinates of nonzero cells, bounding scan). Only matters if a point-set path appears (`seed_distribution_beyond_grid.md` names precomputed point-set textures); they could help generate a set, but the hard part, the neighbor lookup behind `f_grain` and `f_vf_seeds`, is untouched |
| `invertrepos` | Inverts an integer `jit.repos` map and is lossy by the help's own account (char/long only). `f_` warps are float GPU maps |

**One thing that looks like an XRAY job and is not.** A whole-frame dominant orientation
and coherence (useful for the fabric-wrinkle idea in `wind_as_interface.md`) needs no SVD.
The raw tensor is linear (`shared_tensor_vecfield_operators.md`), so its frame mean via
`jit.dimop`, the way `f_util_profile` works, plus a closed-form angle and coherence gives
three numbers. That would be an `f_util_` candidate in its own right. [inference]

---

## Cheapest probes (scratch patches, nothing to build)

1. **`timecube` map mode.** Fill a `3dbuffer` with about 64 frames at 160x120 from a movie
   or camera; drive the map with a char gradient, then with a slowly moving one. Look, and
   read the CPU cost. Also try modes 0 and 1 for the slit-scan look.
2. **`water` into the caustic chain.** Run it at 128x128 and 256x256, push the float
   result into a texture, feed `f_vf_fieldmap` then `f_caustic`, vary the wavespeed
   matrix. Look, and read the frame cost.
3. **Open the four undocumented objects.** Send each a matrix, list its attributes, note
   what it outputs. Fills in the table above; no claim stands until then.
4. **Optional: `distance` on thresholded luma into `f_vf_fieldmap`,** next to `f_vf_repulse`.

---

## Questions for Matt

- Is XRAY allowed as a dependency of shipped modules, or scratch and precompute only?
  My lean is scratch only: every candidate is CPU-side, and the value here is answering
  design questions, which a scratch patch does without adding a requirement.
- Are `f_loop_to_cycle` (parked in plan.md), `f_lumia` and `f_cymascope` live enough to
  spend probe time on? They decide which of probes 1 and 2 matters.

## Explicitly not decided / not in scope yet

No spec, plan, build, or Max test. No decision on a dependency. Object behavior is from
helpfile comments (read in full for timecube, 3dbuffer, water, contourmap, kmeans,
colormap, invertrepos; skimmed for the rest) and string tables, not from running them.
Windows binaries were not inspected beyond the file list.
