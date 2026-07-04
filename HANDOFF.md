# HANDOFF — f_ library

Last session: 2026-07-04 (build_patcher.py driving_inlet bug — RESOLVED
and confirmed working in Max; f_vf_seeds outer bpatcher now shows the
correct 3 inlets)

## build_patcher.py driving_inlet bug — RESOLVED, f_vf_seeds confirmed in Max

The 4th layer of the driving_inlet bug (see entry below this one for full
history) is fixed. Root cause was `mod_inlet_boxes()` unconditionally
creating a dedicated outer inlet object for every mod_inlet, including
mod_inlets[0] under driving_inlet — which already shares physical inlet 0
with the always-present inlet_box(). This produced two separate inlet
objects both ultimately feeding pix inlet 0 (one raw via routepass, one
processed via vs_inState), which is what caused the visible 4-inlet bug.

**Fix, four coordinated edits in `tools/build_patcher.py`:**
- `mod_inlet_boxes(mod_inlets, driving_inlet=False)` — now skips creating
  an inlet object for mod_inlets[0] when driving_inlet=True (mirrors how
  gen_subpatcher's earlier fix omitted the redundant "in 1" object rather
  than reindexing/sharing). Its vs_inState/state_param boxes are still
  generated. Remaining mod_inlets shift down one outer-inlet index (i, not
  i+1).
- `mod_inlet_lines(mod_inlets, driving_inlet=False)` — mod_inlets[0]'s
  wiring under driving_inlet now sources from OBJ_ROUTEPASS directly
  (texture outlet) instead of a dedicated inlet object, since that object
  no longer exists.
- `build()` — the previously-unconditional `OBJ_ROUTEPASS → pix inlet 0`
  wire for archetype=="source" is now suppressed specifically when
  driving_inlet + mod_inlets are both present, since mod_inlet_lines()
  already owns that wire in that case. Without this, pix inlet 0 would
  have been double-fed (raw + vs_inState-processed) — a real routing bug,
  not just a cosmetic inlet-count issue, caught during this session's
  discussion before being applied blindly.
- `build()` call site — `mod_inlet_boxes()` now receives
  `driving_inlet=defn.get("driving_inlet", False)`.

**Verified structurally (rebuilt patchers/f_vf_seeds.maxpat):** outer
bpatcher shows exactly 3 inlets (texture/control shared with shape tex,
vecfield, mod tex); inner jit.gl.pix numinlets=3; no duplicate/conflicting
wire into pix inlet 0; vecfield and mod tex correctly land at pix inlets
1/2 with state feedback intact.

**Verified in Max (Matt confirmed, not just JSON inspection):** 3 inlets
show correctly, shape tex into inlet 0 still drives the mark footprint,
field_priority=0 output matches pre-2026-07-04 shipped behavior.

**Process note, worth carrying forward:** this session traced all call
sites of the driving_inlet mechanism before editing (per the standing
debugging practice — see f-session-start skill), which surfaced a real
routing conflict (the double-feed above) that a naive "just fix the inlet
count" pass would have missed or handled incorrectly.

**Not yet done:** the full regression checklist item "field_priority=0
output matches pre-2026-07-04 shipped behavior exactly" — Matt confirmed
this visually this session; no independent pixel-diff was run.

**Also this session — module taxonomy discussion, no action taken:**
Discussed whether f_vf_seeds' archetype:"source" + driving_inlet:True
combination is honestly named. Landed on a 3-axis rubric (content
requirement / render trigger / bypass behavior derived from signal-type
compatibility) via an audit of every module's actual bypass semantics —
surfaced that f_masonry and f_weave are labeled archetype:"processor" but
behave as self-sufficient generators (black bypass, no real content
dependency) — the mirror-image of f_vf_seeds' mislabeling. Matt's call:
low priority to formalize now, but relevant context for whenever the
f_modules menu/category system (`build_modules.py`'s CATEGORIES) gets
refined, since that's where the mislabeling would actually surface to
users. Not written up as a dedicated doc — this paragraph is the pointer
if it comes up again.

---

Last session: 2026-07-04 (f_vf_seeds priority-generalized selection built
through Phases 1-3 and shipped; build_patcher.py bug found mid-Phase-3,
partially fixed — this entry is retained for full bug history, see
resolution above)

## f_vf_seeds — priority-generalized selection (Phases 1-3 complete on the
mechanism; a build_patcher.py inlet bug is NOT yet fully fixed)

Full spec/plan: `.specify/f_vf_seeds/spec.md`, `.specify/f_vf_seeds/plan.md`
— read both at start of next session, this entry is a pointer/summary plus
the one thing that still needs fixing.

### The mechanism (confirmed working, Phases 1-2 complete)

Generalizes `f_vf_seeds`' seed selection from pure nearest-distance to a
blendable priority incorporating vecfield magnitude — traces to GPU Gems
Ch. 20 ("Texture Bombing"): Voronoi mode and texture-bombing mode are the
same reduction loop, differing only in what feeds `priority`. New params:
`field_priority` (0=distance-only, identical to pre-2026-07-04 behavior;
1=degenerate boundary, distance fully ignored, blocky wedge-collapse, not
a "high overlap" setting) and `field_gain` (live scale on the field term).

**Empirical findings, all confirmed in scratch testing across four
vecfields (gradient test field, Repulse, Vortex, Flow):**
- fps cost of the new 9-per-candidate vecfield sampling: negligible —
  1920×1080 60+fps, 3840×2160 58–60fps. ADR 2 (keep 9-candidate search,
  don't reduce to 4) confirmed by evidence, not just deferred.
- `field_gain`'s useful range varies ~7.5x by field (Flow ~±0.2, Repulse
  ~±0.1–0.8, Vortex ~±1.5) — not tuning noise, a real per-source
  difference. No single baked-in constant works for all fields.
- Fix: `field_gain` ships as a live param with `"range_tiers": [0.2, 0.8,
  1.5]` in `definition.py` — a pure UI-menu convenience (numeric labels
  per Vsynth convention, same mechanism as `f_vf_advect`'s `dt`/
  `injection`), not codebox logic. This reversed an earlier same-session
  decision (ADR 4) to bake in one scratch-only constant — worth reading
  ADR 4 in the plan for why that didn't survive contact with real data.
- Tuning technique worth reusing elsewhere: test `field_gain` at
  `jitter=0`. With no jitter, the distance term is perfectly uniform, so
  any distortion is attributable directly to the field term — much
  cleaner than testing at high jitter where the two effects compete for
  attention.

### The build_patcher.py bug — STILL BROKEN, real next step identified

Matt reported "something's wrong" after Phase 3's rebuild, then confirmed
after the first fix attempt: **module still shows 4 inlets in Max. Not
resolved. Do not assume the fix below is sufficient — it wasn't.**

**Root cause, confirmed:** `build_patcher.py`'s `mod_inlets` mechanism
means two different things depending on the module, and had no way to
distinguish them:
- **Optional secondary modulation** on an otherwise self-sufficient
  generator (`f_vf_vortex`'s cx/cy/convergence/curl mod) — no driving
  texture exists, so a dedicated control-only `in 1` (bang/render
  trigger) with modulation starting at `in 2` is correct and intentional.
- **Primary required content** (`f_vf_seeds`' shape tex/vecfield/mod
  tex) — per Vsynth convention (Matt's explicit correction this session):
  inlet 0 must carry the driving texture *and* all control messages
  combined, no separate control-only channel.

**Fix applied this session — INCOMPLETE, only 3 of 4 layers:** added an
opt-in `driving_inlet` flag, threaded through `pix_box()` (outer
`jit.gl.pix` inlet count), `mod_inlet_lines()` (outer-inlet-to-pix
wiring), and `gen_subpatcher()` (codebox `inN` wiring). Set
`"driving_inlet": True` on `f_vf_seeds`' `definition.py`. Rebuilt and
verified structurally: the inner `vfseeds_pix` `jit.gl.pix` object's own
`numinlets` dropped from 4 to 3, and its gen subpatcher now has exactly
`in1`/`in2`/`in3` (no phantom bang, no orphaned 4th). **This was real and
correct, but insufficient** — it only touched the INNER jit.gl.pix
object, never the OUTER bpatcher wrapper that Matt actually sees when the
module is placed in a Vsynth chain.

**The missed 4th layer, found just now, not yet applied:**
`build_patcher.py` has a separate `inlet_box()` function that
unconditionally creates ONE outer bpatcher inlet at `index=0` (comment:
"texture / control" — this is the pre-existing, already-correct
control+texture-combined inlet, wired via `routepass_box()` into primary
pix inlet 0). Separately, `mod_inlet_boxes(mod_inlets)` creates one
additional outer Max `"inlet"` object per mod_inlet at `index=i+1` (i.e.
1, 2, 3 for f_vf_seeds' three mod_inlets) — **this function was never
made `driving_inlet`-aware.** Total outer bpatcher inlets =
`inlet_box()`'s 1 + `mod_inlet_boxes()`'s 3 = **4, unchanged by this
session's fix.** This is almost certainly the actual cause of what Matt
is still seeing.

**Concrete next step, not yet done:** make `mod_inlet_boxes()` (and
whatever wiring depends on its `index` values — check for other readers
of `mod_inlet_obj_id(i)`) `driving_inlet`-aware the same way the other
three layers already are: when `driving_inlet=True`, `mod_inlets[0]`'s
outer inlet object should use `index=0` (not `1`) — coexisting at the
same physical inlet as the existing `inlet_box()` (Max allows multiple
`maxclass:"inlet"` objects sharing one index, same principle already
used correctly inside the gen subpatcher fix) — and `mod_inlets[1:]`
should use `index=i` (not `i+1`). This should bring the outer bpatcher
down to 3 visible inlets, matching the already-fixed inner object.
**Not yet implemented or tested — do this first next session**, then
rebuild, then get Matt to actually confirm in Max (JSON/structural
inspection is not sufficient proof, as this session demonstrated).

**Full regression checklist, none of it done yet because the inlet count
itself is still wrong:**
- [ ] Outer bpatcher shows 3 inlets, not 4, when opened/placed in Max
- [ ] Shape tex patched into inlet 0 drives the mark footprint
- [ ] Vecfield at inlet 1 drives orientation
- [ ] Mod tex at inlet 2 actually does something (was silently dead
      before any of this session's fixes — never verified working)
- [ ] `field_priority=0` output matches pre-2026-07-04 shipped behavior
      exactly (the actual regression check, still outstanding)

**Also captured this session, deferred:**
`ideas/module_taxonomy_standardization.md` (new file) — the generator/
processor/source distinction has been fluid across this library and this
bug is the concrete example of a real cost from that. Matt's explicit
call: fix this one module now, standardize generally later. Not
scheduled, no mechanism chosen.

**Git status at session end:** `tools/build_patcher.py` modified (the
3-layer `driving_inlet` fix — real, keep it, just incomplete).
`.specify/f_vf_seeds/definition.py`, `codebox_seeds.gen`, `spec.md`,
`plan.md` all modified. `patchers/f_vf_seeds.maxpat` regenerated (still
has the outer-inlet bug — don't treat this as a clean build to commit
as-is). `ideas/module_taxonomy_standardization.md` new. **Do not commit
yet** — the module doesn't actually work correctly in Max until the 4th
layer above is fixed and confirmed.

---

## Session summary — prioritization discussion, two threads touched

**ddx/ddy screen-space derivatives — tabled, not promising.** Checked
Cycling '74's documented Gen operator set (Gen Common Operators, gen~
operators, GenExpr docs, a C74 tutorial enumerating jit.gl.pix's ~130
operators by category) — no derivative operator (`ddx`/`ddy`/`fwidth`)
appears anywhere, consistent with the `jit-gen-codebox` skill's
empirically-tested operator list never having encountered them. Not yet
confirmed via a live in-Max scratch test, but strong enough to
deprioritize. Full write-up and reasoning in
`ideas/line_edge_antialiasing.md`. If revisited: quick live test first
to confirm absence, then the real next step is deriving edge width from
`density_scale`/`dim` directly rather than hardware derivatives — not
designed yet.

**f_grain/f_vf_seeds "naturalness" gap — sharpened, no mechanism chosen.**
Started from the `voronoi_vs_texture_bombing.md` overlap question, but
the real content came from talking through the felt problem in plain
language rather than starting from architecture (Matt pushed back
correctly when the discussion jumped to solutions too fast). Landed on:

- Grid-rigidity and cell-boundary clipping are facets of the *same* felt
  problem, not two separate design threads — Matt's framing, not
  something I should have unified on my own initiative.
- **Structural, not a ceiling** — maxing jitter/`size_var`/density
  doesn't fix it, because the grid itself produces the regularity. This
  is a stronger claim than the idea file's original language.
- `size_var`/irregularity and density are coupled when they shouldn't be
  — cranking irregularity necessarily changes apparent density because
  the grid is fixed-size underneath.
- Size/clipping tolerance differs by module and by use case: fine in
  `f_grain` (used at smaller sizes for textural effect, flattening reads
  as part of the irregularity), more of a problem in `f_vf_seeds` (marks
  carry individual meaning, so a cut mark reads as broken).
- **Sharpest point:** when a vecfield drives flow (as in `f_vf_seeds`),
  field convergence should be able to produce mark overlap — that's the
  field's own information, currently discarded by the placement
  substrate regardless of what the field indicates. Not clumping — overlap
  the way the field's information would predict.

Full write-up in `ideas/seed_distribution_beyond_grid.md`'s new
"Sharpened description of the itch" section. **No mechanism chosen** —
Poisson disk / density-field scatter / texture-fed point set / grid-as-
search-structure-only hybrid all remain open candidates, none newly
favored. This entry exists to record the felt problem precisely before
any design decision.

**Still on the table, untouched this session:** two known bugs
(`f_masonry` square-output-at-non-square-render, `f_hue_processor` band
drag), `f_weave` — Matt flagged "can't put my finger on it yet," treat as
a separate open naming question, not assumed related to the grain/seeds
thread until checked — `f_tone_curve` LUT curve (wanted, but explicitly
not the current focus), `f_sirds`/`f_vf_seeds` helpfiles, `f_grain`
size-mod and `f_vf_seeds` soft-mod (explicitly tabled until the
grain/seeds structural question above is worked through — Matt doesn't
want to ship those before this is resolved).

**No code touched this session.** Two `ideas/*.md` files edited
(`line_edge_antialiasing.md`, `seed_distribution_beyond_grid.md`). Matt
to commit/push manually when convenient.

---

## Ceyron simulation_scripts — notes, not yet acted on

Read (fully or headers-only) against `f_vf_advect`/vecfield family. Full
writeup: `ideas/ceyron_simulation_scripts_notes.md` — read that at start
of next session if resuming this thread.

**One significant finding worth leading with:** the "diffusion/pressure
projection too expensive (20-80 Jacobi iterations)" non-goal already
established for `f_vf_advect` (GPU Gems 1 Ch. 38) only holds *without*
FFT. `kolmogorov_turbulence.jl`/`stable_fluids_fft.jl` show both steps
collapse to single elementwise multiplies in Fourier space when FFT is
available — no iteration at all. **Checked this session: `jit.fft`
exists but is CPU-matrix-only, not GL-space** (searched the full Jitter
ref docs — no `jit.gl.fft` or equivalent anywhere). Using it would mean
a GPU→CPU→GPU round trip every frame, the first place in `f_` that would
break the "no CPU-GPU round trip" invariant. Not closed, but now a cost
question (unmeasured) rather than an availability question — next step
is a scratch-patch fps test of the round-trip alone before deciding
anything.

Two more real threads, both bigger architecture questions, neither
started: a 2D (D2Q9) Lattice Boltzmann method reopens the "no fit"
verdict already given to GPU Gems 2 Ch. 47's *3D* LBM — 2D might
actually pack into a few RGBA textures and stream via directional gather
sampling, same idiom already used in the vecfield family; and the
Kuramoto-Sivashinsky equation as a candidate for a genuinely new
self-sustaining chaotic generator module (no existing `f_` module has
this character), pending a stability check on the finite-difference
biharmonic stencil.

No code touched, nothing scheduled — captured per Matt's request.

## Addendum — GL-domain FFT discussed, cheaper alternative identified

Talked through hand-building a 2D FFT inside `jit.gl.pix` itself
(butterfly-network passes, same "N-stage chain, DRY'd codebox with a
stage-index param" shape `f_stereogram` already proved out) as an
alternative to the CPU-roundtrip `jit.fft` path above. Feasible in
principle, but ~40 sequential passes for a forward+inverse 2D FFT round
trip at a workable power-of-2 resolution, and a fixed pass structure
that doesn't fit the live-tunable philosophy the rest of the vecfield
family has. (Correction logged in the ideas file: Vsynth's render
resolution is user-configurable, not fixed at 640×640 — doesn't change
the recommendation, an FFT module could run its own internal resolution
regardless.)

**Agreed next step, not started: scratch-patch a plain Jacobi
diffusion/projection loop directly in `jit.gl.pix`, no FFT, no
CPU roundtrip, and measure fps at some iteration count.** This tests the
original "20-80 Jacobi iterations, too expensive" non-goal empirically
in this pipeline instead of relying on general GPU-literature reasoning
— and it's simpler to test than either FFT path (no power-of-2
constraint, no complex-number packing, no CPU-GPU roundtrip). If it
comes back fast enough, both FFT threads become moot. Full writeup in
`ideas/ceyron_simulation_scripts_notes.md`'s addendum.

---

Last session: 2026-07-03 (GPU Gems research sweep — GPU Gems 3, Ch 7, 13,
16, 18, 25, 27, 28, 30, 34, 37, 40 all read in one sweep. **The entire
GPU Gems research backlog (all 3 volumes) is now fully read.**)

## GPU Gems 3 — full remaining backlog read this session (Ch 7, 13, 16,
18, 25, 27, 28, 30, 34, 37, 40)

Same established pattern (see `ideas/gpu_gems_research.md`'s "How to use
this"). Four real findings, seven confirmed no-fits (three of which
corrected optimistic backlog framings — Ch 34's pairing with Ch 25, and
two "sounds relevant by name" terminology traps already seen before with
Ch 18 and Ch 7/37).

**Real findings, own `ideas/` files:**
- **Ch 13 (Volumetric Light Scattering) → `ideas/godray_radial_accumulation.md`.**
  Not a code gap — a composition. The chapter's god-ray technique (radial
  accumulation from a point, exponential decay, sampling source
  brightness) is structurally identical to what `f_vf_glow`/`f_vf_streak`
  already do. `f_vf_vortex` with `curl=0` already produces the radial
  field the technique needs. `f_vf_vortex` → `f_vf_streak`/`f_vf_glow`
  should produce a god-ray effect with **zero new code** — untested, but
  the composition should just work. Same category as GPU Gems 2 Ch 19's
  `f_vf_warp` confirmation.
- **Ch 25 (Rendering Vector Art) → addendum to `line_edge_antialiasing.md`.**
  Gives the actual formula the file's long-open blocker was waiting on:
  `sd = f(x,y) / length(ddx(f), ddy(f))`, `alpha = 0.5 - sd` — analytic
  screen-space-derivative AA for any implicit function, directly fixing
  `f_weave`'s diagnosed scale-invariance failure. **Still UNVERIFIED:**
  does GenExpr expose `ddx()`/`ddy()`? Same blocker as before, now with a
  confirmed target formula instead of a vague direction.
  **Note:** `line_edge_antialiasing.md` was referenced in this very
  HANDOFF as already existing from a prior session but was **not present
  on disk** — recreated this session from the HANDOFF summary + this
  session's addendum, and flagged as a discrepancy. Worth a quick check
  of whether other `ideas/*.md` files HANDOFF claims exist actually do.
- **Ch 28 (Practical Post-Process DOF) → addendum to `f_lens_tiltshift_split.md`.**
  Supplies the concrete algorithm for the "content-driven focus map" idea
  already tabled there: scalar CoC map (source-agnostic — doesn't need to
  be a real depth buffer) drives variable-width blur, plus a specific
  foreground-bleed fix (`D = 2*max(D0,DB) - D0`, blur the CoC map itself
  first). Ready to reach for whenever the split/build decision happens.
- **Ch 40 (Incremental Gaussian) → `ideas/incremental_gaussian_taps.md`.**
  Small, low-priority optimization: forward-differencing recurrence
  replaces per-tap `exp()` in `f_vf_glow`'s 48-tap loop and `f_vf_prism`'s
  11-tap blur with one multiply per step. UNVERIFIED whether this
  actually matters on this pipeline — not profiled, worth measuring
  before assuming the win.

**No fits (architectural mismatch or wrong problem shape), logged inline
only:** Ch 7 (Metaballs — full 3D SPH particle sim, CPU-GPU hybrid,
persistent-particle-state architecture `f_` doesn't have; one concept,
"global particle dispersion," cross-referenced into the already-open
`seed_distribution_beyond_grid.md` but not portable as-is), Ch 16
(Vegetation/Crysis — 3D vertex-shader mesh bending, no analog to
`f_weave`'s vertex-less per-pixel line math, doesn't touch the open
orientation-blend question), Ch 18 (Relaxed Cone Stepping — same
camera/tangent-space mismatch as GPU Gems 2 Ch 8, confirmed again), Ch 27
(Motion Blur — velocity-from-depth-buffer doesn't transfer, but the
blur-along-direction loop it feeds is exactly what `f_vf_streak` already
does — pure confirmation), Ch 30 (3D Fluids — heavier version of the
already-covered 3D-voxel gap from Vol 1 Ch 38/GPU Gems 2 Ch 47), Ch 34
(SDF via tetrahedra scan-conversion — generates volumetric SDFs from 3D
*meshes*, wrong problem for `f_`'s 2D analytic/procedural shapes; corrects
the backlog's optimistic pairing with Ch 25 as "the generation side" —
Ch 25 doesn't need this as a prerequisite), Ch 37 (CUDA RNG — solves
sequential Monte Carlo streams, `f_`'s hash approach is stateless
positional hashing, different problem shape entirely, same category as
the already-ruled-out Perlin noise chapters).

**GPU Gems research backlog (all 3 volumes) is now fully read.** No
further chapters queued in `ideas/gpu_gems_research.md`. The "Related
resources" section (ShaderX/GPU Pro/GPU Zen, Real-Time Rendering 4th ed.,
iquilezles.org) remains as a standing resource if a specific technique
question comes up later — not a backlog to work through systematically
the way GPU Gems was.

**No production code touched this session** — same as every GPU Gems
session, everything lives in `ideas/*.md`. New this session:
`ideas/godray_radial_accumulation.md`, `ideas/incremental_gaussian_taps.md`,
`ideas/line_edge_antialiasing.md` (recreated — see discrepancy note
above). Changed: `ideas/gpu_gems_research.md` (eleven entries marked
Read with findings), `ideas/f_lens_tiltshift_split.md` (Ch 28 addendum).
Matt to commit/push manually when convenient.

---

Last session: 2026-07-03 (GPU Gems research sweep continued — Ch 22, 24,
26, 40, 47 read, GPU Gems 2 now fully read, 25 of ~24+ backlog chapters
done across Vol 1+2, GPU Gems 3 still untouched)

## GPU Gems 2 — now fully read (Ch 22, 24, 26, 40, 47 this session)

Continuing the established per-chapter pattern (see "How to use this" in
`ideas/gpu_gems_research.md`). All five read, discussed against real
code, and logged — two real findings (one new file, one addendum to an
existing file), three confirmed no-fits (one of which corrected a wrong
backlog framing).

- **Ch 22 (Fast Prefiltered Lines) → real finding, new file
  `ideas/line_edge_antialiasing.md`.** The chapter's rasterizer/LUT
  machinery doesn't transfer (`f_weave` has no line primitives, just an
  analytic per-pixel distance to a periodic pattern). But checking
  `f_weave`'s codebox directly sharpened the vague "mark quality is
  rough" note into something precise and testable: the `smoothstep`
  edge width is fixed in UV space and doesn't scale with `density_scale`
  — this is exactly the Sampling-Theorem aliasing failure the chapter
  exists to solve, and aliasing should measurably worsen as `density`
  increases, independent of falloff shape. **UNVERIFIED, real blocker:**
  whether GenExpr exposes screen-space derivatives (`fwidth`-equivalent)
  needed to fix this properly — not checked this session. Secondary,
  smaller, independent idea logged in the same file: swap the fixed
  `smoothstep` for a Gaussian-like (`erf`-based) profile, a pure
  filter-shape change unrelated to the aliasing question. `f_masonry`'s
  mortar lines use the same `smoothstep` idiom — flagged as a likely
  secondary candidate, not checked in detail. This is a third,
  independent axis alongside `f_weave`'s two already-open threads
  (orientation A/B, sketchy/uncertainty perturbation) — none chosen,
  all three could land in one session since they touch different code.
- **Ch 24 (LUT Color Transformations) → addendum to existing
  `ideas/lut_curve_and_color_controls.md`, not a new file.** The 1D LUT
  material just reconfirms the already-tabled `f_tone_curve` curve idea
  from Vol 1 Ch 22. What's new: 3D LUTs, a strictly more powerful
  generalization that could express cross-channel ops (hue/saturation
  grades) no 1D curve can reach — via a single dependent `tex3D` read
  with required half-texel scale/offset correction. **UNVERIFIED, real
  blocker:** whether GenExpr/`jit.gl.pix` can sample a 3D texture at
  all — no existing `f_` module uses one, not checked this session.
  Treated as a further-out "maybe" behind the near-term 1D curve work.
- **Ch 26 (Improved Perlin Noise, GPU implementation) → no fit,
  confirms Vol 1 Ch 5's verdict, no new content.** Same smooth/
  correlated gradient-noise algorithm, just the GPU-texture-lookup
  implementation of it (permutation + gradient textures, 5th-order
  Hermite fade). Doesn't change the existing "delegate to `vs_noise_3`,
  not our uncorrelated per-cell hash" answer.
- **Ch 40 (Computer Vision on the GPU) → no fit, and corrected a wrong
  backlog framing.** The backlog described this as "GPU-based optical
  flow" — false. Horn & Schunck appears only in the references list,
  never implemented in the chapter body. Real content (radial
  distortion, Canny edges, CPU-readback summation for moments/VideoOrbits,
  per-feature vertex-array histograms) all depends on multi-pass
  render-to-texture with CPU readback or non-uniform vertex layouts —
  architecturally foreign to `f_`'s single forward `jit.gl.pix` chain
  with no CPU round-trip. One incidental, unchased overlap: the
  chapter's barrel-distortion formula is the same standard model
  `f_lens`'s existing `distortion` param likely already uses (param
  confirmed present via grep, formula not diffed). If a real
  `f_vf_optflow` module is ever wanted, this isn't the source to
  revisit.
- **Ch 47 (Flow Simulation with Complex Boundaries) → no fit, heavier
  version of the Vol 1 Ch 38 gap.** Full 3D Lattice Boltzmann Method
  (D3Q19, 19 packed distributions/node) with GPU depth-peel voxelization
  of arbitrary 3D obstacle geometry — real 3D voxels and multi-pass
  depth-peeling, same "no 3D data anywhere in `f_`" mismatch as Vol 1 Ch
  2/39/42, just heavier than the Navier-Stokes solver Ch 38 already
  covered. No 2D-texture-driven equivalent to borrow for
  `f_vf_repulse`, which already solves obstacle-like behavior a
  completely different (much cheaper) way.

**GPU Gems 2 is now fully read.** Next chapter to resume with, per the
backlog's own ordering: **GPU Gems 3, starting from Ch 7** (Point-Based
Metaballs, against `f_vf_seeds`) — full remaining Vol 3 list (Ch 7, 13,
16, 18, 25, 27, 28, 30, 34, 37, 40) is in `ideas/gpu_gems_research.md`,
don't reconstruct it here.

**No production code touched this session** — same as prior GPU Gems
sessions, everything lives in `ideas/*.md`. New/changed this session:
`ideas/line_edge_antialiasing.md` (new), `ideas/lut_curve_and_color_controls.md`
(addendum appended), `ideas/gpu_gems_research.md` (five entries marked
Read with findings). Matt to commit/push manually when convenient.

---

Last session: 2026-07-03 (GPU Gems research sweep — established and ran
a per-chapter reading pattern against `ideas/gpu_gems_research.md`,
20 of the backlog's ~24 flagged chapters read across all 3 volumes)

## GPU Gems research sweep — pattern established, most of Vol 1+2 done

**The pattern (documented in `ideas/gpu_gems_research.md`'s "How to use
this" section):** read the chapter for its real mechanism, then read the
actual codebox of whichever module it's flagged against (never trust the
module name/README description alone — this caught real discrepancies,
see below), discuss whether the chapter's framing genuinely matches what
the code does today, then either log a no-fit/confirmation in the
backlog directly, or spin up a dedicated `ideas/` file if something real
surfaced. Cross-reference both directions every time.

**Session started from GPU Gems 1 Ch. 20 (Texture Bombing) in a prior
session** — that read is what prompted formalizing this into a repeatable
pattern this session, then working through the rest of the backlog in
order across GPU Gems 1, 2 (stopped mid-way), per Matt's call that later
chapters might add context to earlier open threads (confirmed true —
see Ch 12 below).

**GPU Gems 1 — fully read (Ch 2, 5, 8, 20✓prior, 21, 22, 23, 38, 39, 41✓prior, 42):**
- **No fit (architectural mismatch, logged only):** Ch 2 (Water
  Caustics — analytic-wave-function technique, `f_caustic` correctly
  uses finite-difference divergence instead for arbitrary vecfields),
  Ch 5 (Perlin Noise — solves correlated/smooth noise, `f_`'s sin-hash is
  deliberately uncorrelated per-cell, real need already delegated to
  `vs_noise_3`), Ch 39 (Volume Rendering — needs real 3D voxel data/proxy
  geometry, `f_` is pure 2D), Ch 42 (Deformers — needs 3D vertex
  normals/Jacobians, `f_droste`/`f_mobius` are flat UV remaps).
- **Real findings, own `ideas/` files:**
  - Ch 20 → `ideas/voronoi_vs_texture_bombing.md` — `f_grain`/`f_vf_seeds`
    are Voronoi (nearest-seed-wins, hard-clips at cell boundary), not
    overlap-bombed. Real design fork (identity, not a toggle), tabled.
  - Ch 8 → `ideas/spectral_rainbow_colormap.md` — diffraction-grating
    physics doesn't transfer, but the rainbow-from-a-scalar color-map
    function does; `f_vf_prism` currently only does 3-tap RGB
    channel-offset, not true spectral synthesis.
  - Ch 21 → `ideas/glow_profile_and_afterimage.md` — separable-2D-conv
    trick doesn't apply (`f_vf_glow`'s 48-tap blur is already 1D along
    the field), but three secondary ideas do: dual-curve glow profile,
    alternate step-weight profiles, temporal afterimage feedback.
  - Ch 22 → `ideas/lut_curve_and_color_controls.md` — `f_channel_grader`
    fully covers Levels (checked codebox, confirmed). `f_tone_curve`,
    despite its name, is a 3-band luma lift, not a true curve — real gap.
    **Matt wants to pursue this for real.** Revisit note added to
    `.specify/f_tone_curve/definition.py`.
  - Ch 23 → `ideas/f_lens_tiltshift_split.md` — initial read wrongly
    claimed `f_lens` had no blur (missed `jit.fx.cf.tiltshift` wired
    downstream of the codebox — corrected on the record). Real finding
    was independent of the chapter: Matt isn't reaching for `f_lens`
    because tilt-shift is structurally uncoupled from the rest of the
    module. **Open architecture question: split tilt-shift into its own
    module** (naming candidates `f_tiltshift` vs. `f_focus`), possibly
    adding a content-driven focus-map blur mode alongside the existing
    position-based gradient band. Not decided.
  - Ch 38 → `ideas/vorticity_confinement.md` — confirmed `f_vf_advect`'s
    core *is* Stam's Advection step correctly implemented (not an
    approximation). Real gap (diffusion/projection) logged as a
    deliberate non-goal — too expensive (20-80 Jacobi passes) for live
    multi-module use. Portable finding: vorticity confinement, a cheap
    single-pass force term — standalone vecfield processor vs.
    `f_vf_advect` extension, undecided.
- **Small findings, logged inline (no dedicated file needed):**
  - Ch 19 → `f_vf_warp`'s core confirmed to be exactly Sousa's
    refraction technique (Listing 19-1), independently arrived at.
    Small addition noted: a refraction-mask-style spatial gate (same
    idiom as `f_lens`/`f_vf_prism` mod-tex inlets). Revisit note added
    to `.specify/f_vf_warp/definition.py`.

**GPU Gems 2 — in progress (Ch 8✗, 12, 15 read; stopped before Ch 22):**
- Ch 8 (Displacement Mapping) — no fit; resolved a terminology trap in
  the backlog itself (this chapter's "distance functions" means 3D
  ray-marched volumes, NOT the 2D SDF antialiasing that's actually
  relevant to `f_vf_seeds` — that's Vol 3 Ch 25/34, still unread, go
  straight there for the mark-AA quality question, don't re-check Ch 8).
- Ch 12 (Tile-Based Texture Mapping) — no fit for current mechanism
  (Wang tiles solve bitmap periodicity, `f_` has no tiled bitmaps), but
  added real supporting precedent to the **already-existing**
  `ideas/seed_distribution_beyond_grid.md` (precompute+lookup beat
  in-shader hashing in their case — relevant to that file's "texture-fed
  point set" candidate direction). First case of a later chapter adding
  context to an earlier open thread, as Matt predicted.
- Ch 15 (Blueprint Rendering / Sketchy Drawings) → new file
  `ideas/sketchy_uncertainty_perturbation.md` — 3D edge-extraction half
  is no fit, but the "uncertainty" (non-uniform stochastic perturbation
  for hand-drawn character) half is portable to `f_weave`'s line
  geometry. Explicitly a different axis from the already-open
  orientation A/B question in `f_weave` (not a resolution to it).
  Generalized beyond `f_weave` since the mechanism is cheap and broadly
  applicable to any line/mark-drawing module.

**Next chapter to resume with: GPU Gems 2 Ch. 22 ("Fast Prefiltered
Lines"), against `f_weave`'s mark quality question** — this is the
chapter actually queued next in `ideas/gpu_gems_research.md`. After that,
backlog still has (GPU Gems 2): Ch 24, 26, 40, 47; then GPU Gems 3: Ch 7,
13, 16, 18, 25, 27, 28, 30, 34, 37, 40 — full remaining list is in
`ideas/gpu_gems_research.md` itself, don't reconstruct it here.

**No production code touched this session** — everything above lives in
`ideas/*.md` (new files) and two `.specify/*/definition.py` revisit-note
comments (`f_tone_curve`, `f_vf_warp` — gitignored, not in git status).
`git status` shows only doc/idea files plus the untouched carryover from
last session (`f_sirds` build artifacts, already noted in the entry
below this one) — nothing to commit as code, but the new `ideas/*.md`
files and the `ideas/gpu_gems_research.md`/`ideas/seed_distribution_beyond_grid.md`
edits are new content Matt may want to commit as a "GPU Gems research
sweep" batch when convenient.

**Live threads opened this session, ready to pick up independently of
the reading sweep:**
1. `f_tone_curve` — add real LUT-based curve control (Matt confirmed
   wants this). See `ideas/lut_curve_and_color_controls.md`.
2. `f_lens` tilt-shift split — architecture/naming decision needed. See
   `ideas/f_lens_tiltshift_split.md`.
3. Vorticity confinement for the vf_ family — standalone module vs.
   `f_vf_advect` extension. See `ideas/vorticity_confinement.md`.
4. Voronoi vs. texture-bombing identity question for `f_vf_seeds`/
   `f_grain`. See `ideas/voronoi_vs_texture_bombing.md`.
5. Spectral rainbow color-map for `f_vf_prism`. See
   `ideas/spectral_rainbow_colormap.md`.
6. Glow profile shaping + afterimage for `f_vf_glow`. See
   `ideas/glow_profile_and_afterimage.md`.
7. Sketchy/uncertainty perturbation for `f_weave` (and family). See
   `ideas/sketchy_uncertainty_perturbation.md`.

None of these are started — all still at the "discuss architecture"
stage per Matt's standing preference, captured but not acted on.

---

Last session: 2026-07-03 (f_sirds built, registered, and documented —
first working release of the SIRDS module)

## f_sirds — built, registered, working. Module renamed from f_stereogram.

`patchers/f_sirds.maxpat` exists and works — Matt confirmed a clean single
circle in a still frame in the scratch rig, then confirmed the packaged
bpatcher works correctly on first real test after building it. Full
findings, formulas, architecture, and citations live in
`docs/f-reference/f_sirds.md` — **read that doc at the start of next
session**, this entry is a pointer/summary.

**Renamed `f_stereogram` → `f_sirds` mid-session.** Matt's call: SIRDS
names the specific technique (single-image, strip-based, random-dot) and
leaves room for a future stereo-pair or anaglyph module under a different
name. `docs/f-reference/f_stereogram.md` (research notes) was folded into
the new `docs/f-reference/f_sirds.md` (as-built reference) and removed —
don't look for the old file.

**Two real bugs found and fixed in the scratch rig before building, both
found by working the math against the primary GPU Gems Ch. 41 source (Cg
fragment shader in the chapter text), not just by observation:**
1. **Stage 0 seam bug** — manufacturing black outside stage 0's own strip
   was the root cause of black-bar seam artifacts. Fix: let the periodic
   pattern tile continue across the full frame, no masking on stage 0.
2. **Depth-map sampling bug** — every stage was sampling the depth map at
   its own raw `uv.x` instead of a remapped coordinate
   (`(uv.x - strip_width) / (1 - strip_width)`), meaning the first
   `strip_width` portion of the depth map was never read by anything.

**Architectural correction: `num_strips` must be large (12), not 4.**
Strips are repeat units tied to comfortable eye-convergence distance, not
content divisions — confirmed against GPU Gems' own text and figures
(viewed directly as pasted images). At 4 strips, only ~2.5 visible copies
of a test depth feature appeared — nowhere near enough repeat density to
fuse. At 12, a clean single-circle illusion reads correctly.

**Decided explicitly: `num_strips` is NOT a live parameter.** Fixed at 12,
baked into the build as a literal constant (`strip_width` too). A live
`num_strips` would need a build-time ceiling with inert padding stages —
real complexity for a use case that isn't needed yet. Re-testing a
different strip count later means rerunning the build script with a
different constant, not a live dial.

**Dynamic-noise fusion finding, worth carrying into any future live use:**
frozen pattern + animation → illusion breaks into multiple overlapping
copies (spurious coincidental matches in static noise competing with the
true match). **Animating the pattern (not just depth) fixes this** — false
matches don't survive frame-to-frame noise changes and degrade into
shimmer, while the true match regenerates correctly every frame. Same
principle as Julesz's dynamic random-dot stereograms.

**Build: custom `build_sirds.py`, not `tools/build_patcher.py`.**
`build_patcher.py`'s `pix_chain` mechanism only wires live params to a
single "primary" node — this module needs `depth_factor`, `bypass`, and
the depth texture reaching all 12 depth-driven stages. Followed the
`f_vf_advect` precedent (custom builder script, `definition.py` stays the
documented source of truth even though it isn't literally consumed by
`build_patcher.py`). `bypass` is broadcast to every stage and folded into
each stage's own `in_strip` gate (`* (1.0 - bypass)`) — the whole chain
self-neutralizes back to stage0's clean output when bypassed, no separate
raw-pattern wire into the final stage needed.

```
.specify/f_sirds/definition.py        — documented source of truth
.specify/f_sirds/codebox_stage0.gen   — reference stage template
.specify/f_sirds/codebox_stage_n.gen  — depth-driven stage template
.specify/f_sirds/build_sirds.py       — generates patchers/f_sirds.maxpat
```

**`depth_factor` range tightened to -0.3..0.3** (from an initial -1..1) —
Matt's empirical read: values beyond that mostly just distort rather than
adding usable depth. Rebuilt and reconfirmed.

**Registered in f_modules** — `SIRDS` under Processors, `190×130`.
`.specify/f_modules/build_modules.py` and `javascript/f_addmod.js`'s
`SIZES` dict both updated, `f_modules.maxpat` regenerated and validated.

**Still open (see `docs/f-reference/f_sirds.md`'s "Open Questions" for
detail):** viewing-mode convention for a no-instructions live-performance
context; negative-`depth_factor` semantics differ from GPU Gems (ours
flips direction, theirs uses `abs()` + depth inversion — not reconciled);
strip-count ceiling above 12 unexplored (needs a rebuild to test, no live
control); **13-stage cook order not independently re-verified** (only
confirmed delay-free at 4 stages) — extreme `depth_factor` stress-testing
didn't surface anything looking like a desync artifact, but this is still
an assumption, not a proof; `depth_blur` (in the original spec draft)
never built or tested.

**Not yet done:** `help/f_sirds.maxhelp` (per `f-helpfile` skill
conventions). `git status` at session end shows `HANDOFF.md`,
`javascript/f_addmod.js`, `patchers/f_modules.maxpat` modified, plus
`docs/f-reference/f_sirds.md` and `patchers/f_sirds.maxpat` untracked —
all ready to commit as one logical unit (first working f_sirds release),
Matt to commit/push manually.

**Next step:** write the helpfile, then decide whether to keep tuning the
live rig (strip ceiling, `invert_depth` reconciliation) or move to the
next module in the queue.

---

Last session: 2026-07-01 (4-stage forward-chain scratch test — TOP OPEN
QUESTION RESOLVED, plus a new displacement/valid-region constraint found)

## f_stereogram — forward-chain architecture PROVEN via 4-stage scratch test

File: `/Users/matt/Vsynth/patterns/stereogram_scratch_alt.maxpat` (new
file — do not confuse with the older `stereogram_scratch.maxpat`, which
contains the pre-correction v1/v2 attempts described further down this
document and is now superseded for this line of testing).

**The top open question from the previous session — "revisit whether the
strip algorithm can just be a straight `jit.gl.pix` chain" — is answered
YES, empirically, end to end.** Built a 4-stage fixed-N proof: `stage0_pix`
through `stage3_pix`, each a plain `jit.gl.pix` object wired in a straight
forward chain (`stage_N out0 → stage_N+1 in0`), each also fed `depth_source`
on `in1`. Each stage's codebox implements the passthrough/compute split
directly: within its own hardcoded strip range (`uv.x` quartiles), sample
the previous stage's output at a depth-displaced coordinate; outside that
range, pass the previous stage's output straight through unchanged. Stage 0
is the base case (no previous stage — pattern sampled directly, black
outside its own strip).

**Confirmed by direct observation, stage by stage:**
- `stage0_pix` alone: pattern tiled correctly into strip 0's quarter, black
  elsewhere.
- `stage1_pix`: at `depth_factor=0`, quarter 1 shows stage 0's content
  passed through undisplaced (shift cancels exactly) — proved the
  passthrough/region-split wiring before testing displacement at all. Then
  swept `depth_factor` and confirmed only quarter 1 (and downstream)
  responded — `preview_1` (pure stage-0 output) stayed completely static,
  ruling out any cross-talk between the separate `jit.gl.pix` instances.
- `stage2_pix`/`stage3_pix`: same pattern extended, full 4-strip chain
  confirmed live in a single preview window, each stage responding only to
  its own `depth_factor`.

**No `jit.gl.node`, no `jit.gl.pass`, no manual node-chaining needed for
this mechanism.** The architecture question that's been open since
2026-06-30 is closed: a plain forward chain of `jit.gl.pix` objects is
sufficient for the strip algorithm's intra-frame dependency structure.
This doesn't retroactively waste the `jit.gl.pass` research — it's a
confirmed-viable alternative and may still be worth it for other reasons —
but it's no longer required to make this algorithm work at all.

**Render-clock gotcha recurred, worth naming as a pattern now (second
occurrence):** the first attempt at viewing `stage0_pix`'s output showed
all-black across every preview. Root cause was not the shader — it was
`vs_render`'s own `ON`/`OFF` toggle defaulting to `OFF`, with the render
window's fps readout showing `0.00000`. Last session it was `jit.world`'s
`@enable` defaulting to 0; this session it was a different control with
the same failure signature. **Standing check going forward: before
debugging any shader/patch logic that's producing black output, check the
render window's fps counter first.** A `0.00000` reading means nothing
downstream can be trusted as evidence about anything else yet.

**New finding — displacement magnitude is bounded by previous-stage valid
region, not free:** swapping `pattern_source` for a noise generator
(`N0ISE 3`) surfaced black seams between strips at `depth_factor=0.2` that
were not present with the original edge-shaped test pattern. Diagnosed by
setting `depth_factor` back to `0` on both live stages — seams vanished
completely, full continuous noise texture across all four strips,
confirming this is not a wiring/compositing bug. Root cause: in this
4-stage test, each stage's "valid" content is confined to its own
strip-width quarter (stage 0 is black outside its own strip, and that
constraint propagates forward through the passthrough chain). When
`shift_x = uv.x - strip_width + depth_val * depth_factor * strip_width`
pushes the sample coordinate past the edge of the previous stage's
populated region, it samples black — visible as a seam. **This is a real
constraint the production version needs to account for, not an artifact of
the test rig**, though the test rig's per-stage confinement to exactly one
strip-width of valid content is more restrictive than a production version
would likely be. Needs resolving before the live-`num_strips` architecture
is built: either bound max displacement to stay within available valid
content, or redesign what "valid region" means per stage so it isn't
confined to that one stage's own quarter.

**Still open / not addressed this session:** the live-`num_strips`
architecture itself (fixed max chain, e.g. up to 24 stages, only the first
`num_strips` active per the live param — discussed and agreed on
2026-07-01 prior to this test, not yet built). The strip-count ceiling is
still unknown empirically (per Matt: "we don't know yet"). Circular-screen
presentation is confirmed out of scope for this module — masking happens
downstream, `f_stereogram` stays naive rectangular UV.

**Next step:** resolve the displacement/valid-region constraint (likely
needs its own small scratch test — e.g. does giving stage 0 a wider
initial valid region, or redefining "valid" more generously per stage,
eliminate the seam at higher `depth_factor` without the artificial
4-strip-test confinement?), then move to building the real fixed-max-chain
architecture per the live-`num_strips` design agreed earlier this session.

---

Last session: 2026-07-01 (`jit.gl.pass` research + scratch-test session —
key open question RESOLVED)

## jit.gl.pass — no-3D-content question RESOLVED via scratch test

Full writeup: `docs/max-reference/jit_gl_pass_architecture.md`. Started
from C74 documentation research, then confirmed empirically in
`/Users/matt/Vsynth/patterns/glpass-scratch.maxpat`.

**The single highest-priority open question is now answered: `jit.gl.pass`
renders correctly against a `jit.world` context with zero 3D geometry.**
A single subpass sourcing `TEXTURE0` (fed via `jit.gl.pass`'s own
`@texture` attribute, built at runtime by combining two dynamically-named
Vsynth module outputs — `route jit_gl_texture` → `pack s s` → `prepend
texture`) rendered a known-good C74 shader (`cf.edgedetect.jxs`) correctly
with no `jit.gl.material`/`jit.gl.gridshape`/any 3D content present.
Removing 3D content that had briefly been added as a positive control made
no difference — tested both with and without, closing/reopening the patch
between. The "geometry must have a material attached" language in C74's
docs turns out to be specific to `NORMALS`/`VELOCITY`/`ALBEDO`/
`ROUGHMETAL`/`ENVIRONMENT` sources, not a blanket requirement.

**Real bug hit and resolved along the way, worth remembering on its own:**
`jit.world`'s `@enable` attribute defaults to 0 — confirmed in the local
maxref ("Enable automatic rendering (default = 0)"). A bare `jit.world`
never renders a single frame without `@enable 1` or an external bang. This
produced identical black output across every variable tested in a long
diagnostic chain (missing `jit.gl.layer`, context ambiguity, a bad
`.genjit` reference, a known-good shader, the no-geometry test itself) —
none of those were the actual problem; the window had simply never
rendered. Same category as the stale-`.maxpat`-reload gotcha already
documented above: check the boring, easy-to-overlook setting before
trusting a "still broken" result as evidence about the real question.

**RESOLVED, same session:** the actual `PREVIOUS`/multi-subpass chaining
this whole research thread exists for. `jit_gl_pass_scratch_B_fxname.jxp`
(subpass 0 samples `TEXTURE0`, subpass 1 mixes `PREVIOUS` + `TEXTURE1` via
`mix_test.genjit`) rendered a clean 50/50 blend of the two Vsynth source
textures in `testworld` — visually confirmed, not inferred. **Both halves
of the core mechanism question are now settled: no 3D content required,
same-frame sequential dependency via `PREVIOUS` works as documented.**

**Still open, unaffected by this result:** the Vsynth-integration and
`build_patcher.py`-fit concerns from the original fit assessment (points 2
and 3 in the reference doc) — a `jit.gl.pass`-based module is still a
structurally different bpatcher shape than everything else in f_, JXP file
and all. Resolving the geometry question makes this path *viable*, not
necessarily *preferable* to the node-chain approach or the plain pix-to-
pix wire — see below, now also resolved.

## Plain pix-to-pix wire delay question — RESOLVED, no scratch test needed

The original HANDOFF item flagging this as **UNVERIFIED — first empirical
test to run** is resolved, via a different route than planned: not a
clean scratch-test result (the actual test hit real friction — `jit.world`
render isn't bang-steppable, flicker rate is too fast to eyeball, and an
early "still black with parity forced" result turned out to just be
screenshot-vs-flicker timing, confirmed after the fact) but via web
research plus reconciling against `temporal_synthesis_architecture.md`'s
already-working, already-built modules.

**Answer: a straight-line forward pix-to-pix chain (A→B→C, no loop back to
an earlier point) does not carry an inherent one-frame delay.** The
one-frame latency Vsynth's temporal modules rely on
(`pass_pix`/`slide_pix`, see `temporal_synthesis_architecture.md`) is a
property of **closing a feedback loop** specifically — both `jit.gl.pix`
and `jit.gl.slab` copy their incoming texture, which is what prevents a
feedback loop from becoming an infinite instantaneous regress, and that
copy-on-cycle behavior is what produces the settle, not texture handoff in
general. Corroborated three ways: `jit.gl.pix`'s documented default `thru`
attribute (synchronous output when input is received), the fact that
texture-delay tooling (`jit.gl.textureset`, texture-bank tricks) has to be
built deliberately rather than being free, and — most concretely — every
existing f_ processor module already chains `jit.gl.pix` objects sampling
an upstream inlet in production with no observed frame-lag artifact. If
forward chaining carried an inherent delay, it would show up as a full
frame of lag on every processor module in the library, not just in an
edge-case test.

**Practical implication for f_stereogram:** a plain forward chain of
`jit.gl.pix` objects (source → strip 1 → strip 2 → ... ) should be safe
for the strip algorithm's intra-frame dependency structure, with no need
for the node-chain architecture or `jit.gl.pass` specifically to avoid a
delay problem. This doesn't mean `jit.gl.pass` was wasted effort — it's
now a confirmed-viable, real option, and may still be worth it for other
reasons (cleaner multi-subpass expression, no `build_patcher.py` extension
for multi-pix bpatchers) — but it's no longer *the* answer to "how do we
avoid a frame delay," because there may not be one to avoid in the first
place. **Next actual step for f_stereogram: revisit whether the strip
algorithm can just be a straight `jit.gl.pix` chain**, before reaching for
node-chaining or `jit.gl.pass` complexity at all.

`temporal_synthesis_architecture.md` updated same session to sharpen its
"GL texture pipeline has one frame of inherent latency" language — that
phrasing overstated the claim; scoped now to feedback loops specifically.

**No skill files or module code touched this session.** Still deferred —
worth revisiting once the `PREVIOUS`-chain test is done and there's a
fuller picture of what a `jit.gl.pass`-based module would actually cost to
build and maintain.

---

Last session: 2026-06-30 (scratch patch + research session — RESOLVED via web research, corrected mental model)

## f_stereogram — jit.gl.node / jit.gl.pix interaction: RESOLVED (wrong mental model, not a binding bug)

Full spec at `.specify/f_stereogram/spec.md`.

**Algorithm is settled, not in question.** GPU Gems Chapter 41 ("Real-Time
Stereograms", Policarpo 2004) — strip-based, multi-pass, intra-frame texture
feedback. Single-pass `jit.gl.pix` confirmed insufficient (structural, not a
tuning problem — no cross-pixel reference means no fusible repeat structure).

**The empirical dead-end from earlier this session (Method 1 name/drawto
binding, Method 2 middle-outlet binding) was chasing the wrong mechanism
entirely.** Both methods assume `jit.gl.pix` needs to be bound *as a child
inside* a `jit.gl.node`'s sub-context, the same way a 3D scene object
(`jit.gl.plato`, `jit.gl.mesh`, `jit.gl.gridshape`, `jit.gl.videoplane`)
does. It doesn't work that way, and testing confirmed it doesn't — but the
correct conclusion isn't "which outlet/attribute is the right binding
mechanism," it's that **`jit.gl.pix`/`jit.gl.slab` are texture-domain
operators, not scene members, and were never going to bind via either
method.**

**Correct model (confirmed via Cycling '74 docs + the official jit.gl.pix
tutorial, which cites Andrew Benson's SceneWarp technique as the canonical
example):**
```
[jit.gl.node @capture 1]   <- 3D objects (mesh/plato/gridshape/videoplane)
        |                     bind here via name/drawto or middle outlet
        | left outlet = captured jit.gl.texture, output every draw
        v
[jit.gl.pix]                <- receives the captured texture as a NORMAL
                                INLET 0 INPUT, exactly like any other
                                texture source. No naming/drawto/outlet
                                trick on the pix side at all.
```
Direct doc quote: "When capture is enabled, jit.gl.node outputs a
jit.gl.texture out its left-most outlet every time it draws itself. In
this mode, jit.gl.slab and jit.gl.pix objects can be **chained to the
node**..." — "chained to" is ordinary patch-cord texture flow.

This also explains why the isolated learning-patch test (bright red
`@erase_color`, solid-green zero-input pix) necessarily failed under both
methods: that pix had zero texture inputs and neither method is a
texture-passing mechanism, so there was no path by which it could ever
have shown up in the node's capture regardless of which binding syntax
was used. The test was well-designed but tested the wrong hypothesis.

**`jit.gl.pass` researched (2026-07-01) — see
`docs/max-reference/jit_gl_pass_architecture.md`.** Confirmed via C74
canonical docs: subpasses do natively support `PREVIOUS` (prior subpass
output) and named-subpass/`SUBPASS0..N` sourcing — a real, documented
same-frame chaining mechanism. But it's architecturally a 3D-scene
post-processing system (binds to a `jit.gl.node`, documented precondition
of geometry with a material attached), a different bpatcher shape than the
rest of f_, and carries an unverified dependency on 3D scene/material
content that may or may not gate the plain-2D-texture case f_stereogram
needs. **Not established as simpler than the node-chain approach** — the
highest-priority open question (does a subpass chain work against an
empty node fed only via `@texture`, no 3D content?) is still untested.
See that doc's "Fit assessment" section before reaching for it.

**Workflow gotcha hit hard this session, worth remembering going
forward:** editing a `.maxpat` JSON file on disk while it's already open
in Max does NOT live-update the open patcher window. Several rounds of
edits appeared to have no effect because Max was still showing a stale
in-memory copy. **Always fully close and reopen a patch after any file-
level edit before treating a test result as meaningful.** This alone
explained at least one full round of false "still broken" reports.

**Files:**
- `/Users/matt/Vsynth/patterns/stereogram_scratch.maxpat` — original
  scratch test. Contains v1 single-pass (`obj-5`, confirmed insufficient,
  left untouched) and v2 2-strip multi-pass attempt (`obj-40`–`obj-48`,
  currently non-functional / black output, built on the now-corrected
  binding assumption). Do not resume debugging this file directly until
  the node→pix texture-chain pattern (or `jit.gl.pass` subpass approach)
  has been proven in the isolated learning patch first.
- Isolated learning patch — built directly in Max by Matt, not yet saved
  to a path visible to me. **Get this path at the start of next session**
  and read it via Desktop Commander before touching anything.
- `/Users/matt/Vsynth/sirds.genjit` — single-pass genjit reference,
  correct per-pixel displacement math, doesn't produce fusible results on
  its own (single-pass), useful only as a math reference for whichever
  strip codebox eventually gets built.

**Reference doc corrected (2026-06-30):**
`docs/max-reference/intraframe_multipass_architecture.md` has been updated
to retract the pix-drawto-node claim and mark several previously-confident
assertions as **UNVERIFIED** (notably: whether a plain pix-to-pix message
chain actually has a frame delay at all — that was asserted, never tested).
Read that doc's "Open questions" section at the start of next session.

**Next step, in order:**
1. Get the learning patch's file path from Matt, read it fresh.
2. **Cheapest test first, do this before anything else:** wire pix_A's
   outlet directly to pix_B's inlet (no `jit.gl.node` at all) and check
   whether there's actually a one-frame delay. If there isn't, the entire
   node-based architecture may be unnecessary for f_stereogram — worth
   knowing before investing more time in the node approach.
3. If pix-to-pix does have a delay: rework the node test instead — wire
   the node's left outlet (captured `jit.gl.texture`) into a pix's inlet 0
   as an ordinary texture input (not a binding), with the node containing
   a simple visible 3D object. Close/reopen Max fully, confirm.
4. `jit.gl.pass` researched (2026-07-01, see
   `docs/max-reference/jit_gl_pass_architecture.md`) — confirmed
   `PREVIOUS`/named-subpass chaining is real, but fit for f_stereogram is
   unresolved pending one specific test: does a subpass chain work against
   a `jit.gl.node` with no 3D scene content, using only `@texture`-fed
   inputs? If yes, worth evaluating in parallel with steps 2-3. If a 3D
   scene/material turns out to be a hard requirement, deprioritize it —
   it would be a heavier-weight, differently-shaped module than the rest
   of f_ for no clear benefit over the node-chain approach.
5. Once one of these is confirmed working in the isolated learning patch,
   port it back into `stereogram_scratch.maxpat`'s strip0/strip1
   structure — don't keep iterating on the compromised file until then.

## Discussion session — soft-mod, grain, weave

No code touched this session — pure architecture/strategy discussion across
three threads. Captured here so next session starts with full context.

**f_vf_seeds soft-mod — tabled, not decided.** Explored feather (cheap,
single-sample vignette on local-UV boundary distance — this is what f_grain's
`softness` actually does, via `shape_t`/`soft_falloff`) vs. true blur
(multi-tap neighborhood sampling, real cost, softens internal shape detail
not just silhouette edge). Conclusion: which one (or both, on different axes)
reads as the "disproportionately expressive" hard↔soft control depends
entirely on the upstream shape tex content, and isn't resolvable by reasoning
alone — needs a scratch-patch comparison across several shape sources (soft
blob, hard geometric mark, detailed/textured shape, asymmetric shape) before
committing to a mechanism. Explicitly tabled, come back to it.

**f_grain extension — resolved, see "Captured but not scheduled" section
below.** Ruled out shape-tex inlet (too disruptive to grain's core voronoi
identity) and vecfield-driven displacement-steering (displace only offsets
the *background sample* under each grain, not grain position/orientation —
no real anchor for field-steering). Landed on: a plain mod-texture inlet
blended into `cell_size`, new `size_mod` depth param. Small, scoped, additive.
Full reasoning + integration point captured below — ready to build next time.

**f_weave — open, needs a scratch-patch A/B before deciding anything.**
Started from the HANDOFF item "extend shape-tex-inlet pattern to f_grain and
f_weave" — on inspection this doesn't transfer cleanly. f_weave's marks are
procedural line/hash geometry (`dist_to_line`/`dist_to_mark` smoothstep
gates), not item-based like f_vf_seeds; there's no per-mark local-UV frame to
sample a shape tex against. Building one from scratch would be a real
architecture port, not an extension.

Separately, Matt shared a screenshot: f_weave fed a video→optical-flow
vecfield on in1 produces dense, organic, scribble/hatching-like output that
tracks scene structure — visually strong, but Matt described it as feeling
"uncontrolled," specifically in **orientation response**, not (or not only)
density/spacing.

Root cause identified in the orientation block:
```
cs = base_cs + (-vy); sn = base_sn + vx;
mag = sqrt(cs*cs+sn*sn); cs/=mag; sn/=mag;
```
This is vector addition + renormalize, not angular blending. Two problems:
(1) field contribution depth is implicit and fixed (ratio of unit base vector
to ±0.5-range field vector), not an exposed/dialable param; (2) vector-add
renormalization isn't proportional to angular difference — response isn't
linear/predictable, and near-zero (flat/no-motion) field regions still get
normalized into *some* direction rather than falling back to base angle.

Two candidate fixes discussed, not chosen:
- **A — exposed depth param, same mechanism.** Scale field term before
  adding (`field_amount` param). Minimal change, inherits non-proportional
  response behavior.
- **B — true angular blend.** Compute field angle directly (atan2 or
  equivalent — verify availability/safety in GenExpr first), circular-
  interpolate with base angle, weighted by depth and optionally by field
  magnitude (so flat regions fall back to base automatically). More correct,
  bigger change to the block.

Matt was unsure which would actually feel better — correctly identified as
an empirical question, not a reasoning-from-the-couch one. **Next step:**
scratch patch with both mechanisms wired side-by-side/switchable, same
video→flow source as the screenshot, A/B live before committing to either.
Stopped here — session ended due to fatigue, explicitly flagged by Matt.

---

## Prior session — full summary

### f_vf_seeds — shape-tex architecture (major revision) ✓

The original f_vf_seeds (internal smoothstep mark geometry, identity tex as
weight/marklen modulator) was superseded this session by a cleaner architecture:
external shape texture as the mark footprint, with f_vf_seeds reduced to a pure
placement/orientation engine.

**Architecture, current state:**
- Inlets: shape tex (in1), vecfield (in2), mod tex (in3). No source inlet —
  module is a generator (`archetype: source`), not a processor.
- Mark rendering: project pixel into seed-local (along, across) frame as before,
  but instead of computing geometry, normalize into a local UV and sample an
  external shape tex. Gate (hard clip) on UV bounds. No internal edge/profile
  logic at all.
- Outlets: mark color (out1, full RGB from shape tex), mark mask (out2, luma
  greyscale), seed coord (out3, RG seed UV per pixel).
- Passthrough convention: no shape connected → src_shape=0 → black output.
  No internal fallback shape; the module has no opinion about mark appearance.
- Shape tex canonical convention: square domain, mark centered, oriented
  rightward, any color/source (WFG, camera, gradient, jit.gl.pix generator —
  no dedicated shape-generator module family needed).

**Param simplification — `size` + `stretch` replaces `weight` + `marklen`:**
Independent per-axis scale params were fussy (dialing one threw off the other).
Replaced with a single `size` (overall scale) + `stretch` (aspect ratio) pair:
`marklen_eff = size_eff * (1+stretch)`, `weight_eff = size_eff / (1+stretch)`.
Reciprocal relationship keeps mark from collapsing/ballooning as stretch increases.

**Bipolar modulation depths:** `size_mod` and `stretch_mod` extended to -1..1
(from 0..1). Bipolar reads as substantially more expressive/alive than unipolar
for this kind of per-seed modulation — mod tex can grow or shrink the base value
around its set point rather than only adding.

**`softness` removed entirely.** Edge character now lives in the shape tex.
The footprint-boundary feather softness used to provide was a narrow effect
not worth a dedicated static dial — see "Near-term" below for a mod-tex-driven
revival of this idea.

**Both definition.py and codebox_seeds.gen synced to match current patcher.**
Findings captured in `docs/f-reference/discrete_item_conventions.md`:
- size+stretch pattern (recommended for future discrete-item modules)
- bipolar modulation depths (recommended as new default)
- shape-tex-inlet architecture (full writeup, mechanics, consequences)
- open flag: cross-module `density`/`size` semantic audit needed (not started)

**Original mark-quality refinement goals (analytical AA, taper, aspect
correction) are now moot** — taper and shape moved upstream to the shape tex
entirely, so there's no internal geometry left to refine. This is a good
outcome but worth naming explicitly: those HANDOFF items are obsolete, not
completed.

**Session also involved real Max-plumbing debugging** — inlet/outlet index
vs. patching_rect x-position ordering bugs, stale shader cache after codebox
edits, route numinlets/outlets mismatches after param count changes. None of
this was architecture-related, but it ate significant time. Worth hardening
the build/edit workflow before doing this kind of patcher surgery again on
f_grain or f_weave.

**Status: shape-tex architecture proven and working. Proof of concept succeeded.**

---

## What's next — priority order

### 1. f_vf_seeds: per-seed softness/low-pass mod
Static `softness` dial was removed (see above) since a fixed footprint feather
wasn't worth a dial. But a **mod-tex-driven** version is a stronger case — same
mechanism as `size_mod`/`stretch_mod`, modulating edge feather per-seed via the
mod tex rather than a static value. Worth adding as a third bipolar mod depth
(`soft_mod`?) once the gate logic supports a feathered (smoothstep) boundary
again, parameterized per-seed instead of globally.

### 2. f_vf_seeds helpfile
Write `help/f_vf_seeds.maxhelp` following f_droste.maxhelp conventions.
Read `skills/f-helpfile/SKILL.md` first. Deferred from prior session pending
architecture stabilization — architecture is now stable, ready to write.

### 3. Discrete-item family: cross-module semantic audit
Flagged in `docs/f-reference/discrete_item_conventions.md` (OPEN section at top): `density`
and `size` likely mean different things across f_grain/f_weave/f_masonry/
f_vf_seeds in ways that haven't been reconciled. Needs a deliberate side-by-side
pass before drawing conclusions.

### 4. Discrete-item family: extend shape-tex-inlet pattern
Candidate for f_grain and f_weave per the architecture validated in f_vf_seeds.
Own session each. Also reconsider size+stretch and bipolar-mod findings when
touching either module.

### 5. UI density pass
Section 1 (intrinsic character) / Section 2 (field response) layout for all
discrete-item modules. Blocked pending compound dial widget design.

---

## Captured but not scheduled — f_grain

- **f_grain: size mod inlet.** Decided NOT to extend f_grain with a shape-tex
  inlet (too disruptive to its core voronoi mechanism) or a vecfield inlet
  for displacement-steering (on inspection, `displace` only offsets the
  *background sample* under each grain — `uv_d` → `sample(in1, uv_d)` — it
  does not move or orient grains; grain has no position/orientation concept
  to redirect, so "field-steered displacement" doesn't have a real anchor
  here). Instead: a plain mod-texture inlet (not vecfield-typed) sampled
  per-cell at `(best_gx, best_gy)`, blended into the existing `cell_size`
  computation:
  ```
  cell_size = mix(1.0, mix(cell_size_a, cell_size_b, svf), size_var);
  ```
  New mod sample blends in here (e.g. `mix(cell_size, mod_sample, mod_depth)`),
  with a new `size_mod`/depth param controlling blend amount. `size_var` and
  its existing hash-based variation stay untouched when nothing's connected —
  this is additive, not a replacement. Small, contained: one new inlet, one
  new param, one line of codebox touched. Deliberately scoped to avoid the
  rest of grain's mechanism (displacement, era/fade, luma gate, shape).

## Captured but not scheduled — see ideas/

- **Breaking the grid entirely** (f_vf_seeds seed distribution): current 3x3
  neighborhood search assumes a roughly uniform grid with jitter. True
  non-grid placement (Poisson disk, density-field-driven scatter, or something
  else) is a different seed-distribution algorithm, not a parameter tweak.
  Captured as its own exploration in `ideas/` — see
  `ideas/seed_distribution_beyond_grid.md`.

---

## Known issues / loose threads

- f_masonry square output at non-square render dimensions — root cause unresolved
- f_hue_processor band drag still broken (do not touch without a plan)
- f_weave: mod inlets (identity tex + screen tex) — deferred
- f_grain: vecfield inlet — deferred
- `rename strength → amount` across modules — parked

---

## Module inventory (current)

**Generators:** f_masonry, f_chladni, f_stipple, f_grain, f_weave
**Processors:** f_droste, f_mobius, f_stereo, f_lens, f_caustic, f_sirds
**Color/Tone:** f_channel_grader, f_hue_processor, f_luma_processor, f_tone_curve
**Utilities:** f_texrouter, f_util_profile
**Vecfield:** f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, f_vf_warp,
  f_vf_streak, f_vf_advect, f_vf_glow, f_vf_repulse, f_vf_split, f_vf_chroma,
  f_vf_prism, f_vf_potential, f_vf_flow, f_vf_seeds
