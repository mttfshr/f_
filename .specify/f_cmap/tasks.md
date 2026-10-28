# Tasks: f_cmap

_Created: 2026-10-26. Spec: `spec.md`. Record of each task goes under it when done._

Verification follows the three tiers (`.specify/constitution.md`): mirror first, the real
`src/` codebox on the bench second, a live look third. No scratch-patch stage.

## Phase 0 - model, mirror, measurements (offline, no Max except T006)

- [x] **T001** `tests/modules/cmap/cmap_mirror.py`: float64 NumPy mirror of one frame
  (coordinates, `z^n + w` by repeated multiplication, bounds rules, `mix`), plus a
  `run_temporal` that ping-pongs frames with a chosen sampler (nearest, bilinear,
  Catmull-Rom) and wrap rules matching `tests/lib/gpu_sim.py`.
- [x] **T002** `test_cmap.py` tier-1 checks: identity-map invariance (FR-010); Jacobian is
  a scaled rotation at aspect 1, 16:9, 9:16 (SC-002, finite difference); fixed points of
  `z = z^2 + w`; bounds region exactly the pulled-outside-frame set (SC-004); `rate` 0
  freezes `w`; mutations caught (aspect applied twice, `n` off by one, swapped x/y).
- [x] **T003** Composition test (SC-003): nearest sampling, no decay, no injection, after
  n frames the image at z equals the original at `f^n(z)` for n = 1..5.
- [x] **T004** Smear measurement (`tests/records/spike_cmap_smear.py`): impulse
  persistence and blur growth per frame, bilinear versus Catmull-Rom, centre versus edge;
  where aliasing starts. Decides gate G4.
- [x] **T005** Look stills from the mirror on synthetic input (noise, gradient, a moving
  edge; never the checker as a module feature): usable `decay` / `inject` / `radius` /
  `sweep` region, whether `sweep` is needed, trim for G6.
- [x] **T006** Cost bench (Max, with Matt): single pass plus `pass` copy at 1080p and 4K;
  report a bound if under the bench's resolution floor. NF-001; M1 unmeasured.

### Gates (Matt)

- [x] **G1** Naming: `CMAP` (Matt, 2026-10-27; module stays `f_cmap`, label CMAP).
- [x] **G2** Bounds region: frame rectangle (Matt, 2026-10-27).
- [x] **G3** `power`: integer 2-4, default 2 (Matt, 2026-10-27).
- [x] **G4** Sampler: hand 4-tap bilinear (Matt, 2026-10-27); Catmull-Rom stays a T030 option.
- [x] **G5** No `gain` / `mix_pct` in v1 (Matt concurs, 2026-10-27).
- [x] **G6** Control trim: cut the `black` bounds rule; menu is Source / Wrap (Matt, 2026-10-27).
- [x] **G7** Promote the `L` scale dial into v1: yes (Matt, 2026-10-27); T032 moves to Phase 1 as a `scale` Param.

## Phase 1 - build (T020-T023)

- [x] **T020** Codeboxes `src/f_cmap/codebox_cmap_pass.gen` and `codebox_cmap.gen`, and
  `definition.py` modelled on `src/f_vf_advect/definition.py` (Pattern 1: pass and primary
  pix, float32, `adapt`, `pix_wires` state -> pass -> state in2). Check every control
  name against `jit.gl.pix` attributes and GLSL builtins (FR-009; the `depth`, `texture`
  and `t` traps), frame-size-change behaviour, NaN guard (NF-003).
- [x] **T021** Patcher clock for `theta` / the sqrt(2) phase on `rate` (`f_quasi` clock
  precedent), exact freeze at rate 0; freeze and reset wiring (`f_wc` header toggle).
- [x] **T022** `tests/modules/cmap/bench_cmap.py` (register in `tests/lib/benchdeps.py`,
  pick an unused ORDER): codebox versus mirror frame by frame, bypass, bounds modes. Give
  the first input the render's size (the `dim` finding).
- [x] **T023** Registration: README row (Patterns, with a unverified marker until Phase 3),
  `build/py.sh build/generate_launch.py`, `NOT_IN_MENU` entry until Phase 3, drift,
  module contract bench. Offline suite once at the end.

## Phase 2 - tuning and extensions (gated)

- [ ] **T030** Tuning with live camera (Matt): defaults, ranges, `inject` / `decay` feel.
- [ ] **T031** Optional vecfield offset inlet for structure-aligned pull (tensormap ->
  axisflow). First check whether `f_vf_warp` through `vs_feedback` already gives it.
- [x] **T032** `scale` dial (the `L` constant, default 1.75): promoted into v1 by G7, built with the Phase 1 codebox (T020). Needs a mirror check that L is a Param, not a constant (extend `pull_point`).

## Phase 3 - docs and menu

- [ ] **T040** Reference doc `docs/f-reference/f_cmap.md`, inventory rows.
- [ ] **T041** Helpfile (`f-helpfile` skill), menu entry (Patterns), README row final,
  `plan.md` and `ideas/INDEX.md` updated, module-preflight, move to `.specify/stable/`.

---

## Record

### 2026-10-27: T001-T005 (offline; T006 needs Max and is still open)

**T001** `tests/modules/cmap/cmap_mirror.py`: float64 and float32 mirror of one frame and of the
ping-pong; samplers nearest / bilinear / Catmull-Rom; bounds source / black / wrap; five mutations.
Conventions decided (revisit freely): the inside test is the closed rectangle on the normalised
sample position; "wrap" taps are periodic in the mirror (on the GPU a bare `sample()` wraps the
coordinate but clamps its taps at the seam, so T020 must decide whether to fetch its own taps);
Catmull-Rom is a = 0.5, 16 taps, unclamped; `w` is per FRAME with `rate` in turns per frame (the
webgpgpu source is 0.01 / 2 pi); alpha is forced to 1; `L` = 1.75 is a constant.

**T002 / T003** `test_cmap.py` 9/9 (0.4 s), references written with scalar `math` / `cmath`:
identity map over 50 frames 3.8e-13 (float64, all samplers), float32 bilinear 2.1e-4 and Catmull-Rom
9.7e-5 (nearest exact; tolerance 5e-4, so only 2.4x headroom); Jacobian vs n z^(n-1) 1.6e-10
relative at aspect 1, 16:9, 9:16 and n = 2..4 (SC-002); fixed points 7e-16; composition after
k = 1, 3, 5 frames for wrap / black / source with n = 2 and 3: 0 mismatches (SC-003); bounds mask
and the three hole values exact (SC-004); the mix closed form exact; bilinear and nearest equal
`gpu_sim`'s (0.0); Catmull-Rom reproduces a linear ramp (5e-15) and is interpolating. Mutations
caught: aspect_not_undone 1.1, n_off 8.1, swap_xy 2.8, centre_off 0.91, w_sign 0.60 (threshold 1e-2).

**T004** `tests/records/spike_cmap_smear.py` (frame-periodic analytic image, exact composition as
ground truth, n = 2, w = (0.15, 0), 192 x 108, wrap bounds, decay 1, inject 0, float64):
- One frame (k = 1), 8 px wavelength: nearest rel err 0.30-0.36, bilinear 0.10 (amplitude 0.91),
  Catmull-Rom 0.01 (amplitude 0.99). 24 px: 0.10 / 0.01 / 0.00.
- Where the pull contracts (|q| < 0.2, mean |f'| up to 1.04) the error does NOT compound over 10
  frames (8 px: bilinear 0.12 / 0.88, Catmull-Rom 0.01 / 0.99): orbits settle toward the attracting
  fixed point and the field goes flat.
- Where it minifies (|q| > 0.2, |f'| > 2) the exact composition is past Nyquist after about 3 frames,
  so every sampler has rel err 0.4-1.4 (unavoidable aliasing). What differs is contrast: amplitude
  nearest about 1.0 (crunchy noise), Catmull-Rom 0.66-0.82, bilinear 0.40-0.77 (mush).
- float32 identity-map drift on worst-case noise (96 x 54): bilinear 3.6e-4 / 3.6e-3 / 2.1e-2 at
  50 / 500 / 3000 frames, Catmull-Rom about half. So `freeze` must hold the history without
  resampling it (a pass-through of `prev`), not run the identity pull.
- So "smear" is two things: a per-frame softening of small features by bilinear (about 9% of an 8 px
  wave per frame, which Catmull-Rom nearly removes) and, outside the contracting region, aliasing
  that no per-pixel sampler fixes.

**T005** `tests/records/spike_cmap_look.py` (synthetic smooth source: drifting gradient, orbiting
disc, sweeping bar; 192 x 108, float32, 150 frames from a reset, last frame tiled; sheets in
`tests/logs/cmap_look/`, gitignored, regenerated by the spike). A synthetic source is not a camera:
this is a first read, the real look is T030.
- **The default look is a Julia "window", not winding image.** The frame spans |z| < 1.75 and the
  filled Julia set of z^2 + 0.15 is the contracting basin: its interior goes to a nearly flat dim
  patch (decay 0.9 turns it black, decay 1.0 grey), while outside it the live image shows at full
  strength (escaping pixels read the source). The live content appears inside only as thin filaments
  along the set boundary.
- `inject` is the dial that matters: 0.02 leaves the interior dead, 0.08 gives faint ghosts, 0.30
  shows the bar's reflections winding through the interior as filaments (the best sheet). Motion
  (mean |frame 150 - 149|) 0.0039 -> 0.0166 across inject 0.02..0.30.
- `radius`: 0 and 0.15 are nearly the same filled set; 0.6 elongates and tilts it; 1.5 dissolves it to
  dust (image nearly a passthrough with scattered fragments). `sweep` 1.5 walks through all of these.
- `bounds`: Source is the only usable default. Black leaves 82% of the frame black. Wrap processes the
  whole frame as a tiled filament texture but is dim and low contrast (luma std 0.017-0.019 vs 0.044).
- Bilinear vs Catmull-Rom: indistinguishable on this smooth source (mean and std within 0.001).
- `power`: n = 1 is a translation streak (a trail); n = 3 and 4 give more lobes and about twice the
  contrast (luma std 0.094-0.096 vs 0.045 at n = 2).
- The disk-vs-rectangle question (spec experiment 3) is settled analytically: the inscribed disk of
  the source is pi/4 of a square frame, so at 16:9 it covers 44% of the frame area and the left and
  right strips would never be fed from history.

### Findings that bear on the gates (recommendations, not decisions)

- **G2**: frame rectangle (above).
- **G3**: keep `power` 2-4; the looks differ and it costs a loop count.
- **G4**: bilinear for v1; Catmull-Rom is a T030 option if a texture-rich live source looks mushy. The
  evidence is split: Catmull-Rom is clearly better per frame (T004) but not visibly better on this
  sheet; its cost (16 taps, or 4 bilinear fetches with the usual trick) is unmeasured (T006).
- **G5**: unchanged (no `gain` / `mix_pct`).
- **G6**: candidate cut: the `black` bounds rule (82% black). `angle` stays if `freeze` needs a manual pose.
- **New G7**: promote the `L` scale (T032) into v1? The frame framing decides how much is Julia
  interior versus escaping exterior, which is most of the look.

### 2026-10-27 (later): T006, cost and GPU sampler (`tests/records/spike_cmap_cost.py`, Max 9.2.0, M3 Max)

Scratch shaders (no `src/f_cmap` codebox yet): the z^2 + w pull with bounds = Source, in1 = source, in2 =
previous frame, both render-sized so `dim` is the render's; variants differ only in how the previous
frame is read. Run with `tests/bench.sh tests/records/spike_cmap_cost.py`. Not run through the regression
set (a record, not a test).

**Part 1, GPU against the float32 mirror at 256 x 144 (mean |err| per annulus of |q|: 0-0.08 / 0.08-0.20 /
0.20-0.35 / 0.35-0.50 / 0.50-0.95; smooth two-component source and previous frame):**
- hardware `sample()` vs the mirror's NEAREST: 0.046 / 0.018 / **0.0000 / 0.0000 / 0.0000**; vs the mirror's
  BILINEAR: 0.0002 / 0.026 / 0.045 / 0.028 / 0.0004, with 31% of pixels off by more than 0.01. So the hardware
  filter is bilinear only near the centre and exactly nearest wherever the pull minifies (|q| > 0.2). The
  mirror's "bilinear" is not what a bare `sample()` does here (this is the jit-gen-codebox skill's 2026-10-06
  fact, confirmed on this pull; no skill edit needed).
- 4-tap hand bilinear vs the mirror's bilinear: 0.0000 / 0.0000 / 0.0000 / 0.0002 / 0.0000, 0.1% of pixels
  above 0.01 (max 0.073: isolated pixels, probably inside/outside decisions flipping at float32 on the frame
  edge; not investigated).
- 16-tap hand Catmull-Rom vs the mirror's Catmull-Rom: the same (max 0.064, 0.1% above 0.01).

**Part 2, cost, ms per pass, chain 8, median of 3 (an upper bound, shown with `<`, means the pass fits under
the bench's per-frame floor):** copy / hw / 4-tap / 16-tap at 1080p: <0.80 / <0.81 / <0.76 / <0.77; at 4K:
<3.06 / <3.06 / <3.10 / <3.07. The floor (the empty `out = in1` pass) is about 0.8 ms per slot at 1080p and
3.0 ms at 4K with two float32 inputs, so nothing resolves.

**Part 3, each read repeated x4 per pass with offset taps (to push past the floor):** at 1080p copy <0.79,
hw x4 <0.78, 4-tap x4 <0.75, **16-tap x4 2.64 ms** (GPU bound); at 4K copy <3.00, hw x4 <2.99, 4-tap x4 <4.24
(still unresolved), **16-tap x4 9.46 ms**. Dividing by the four reads: a 16-tap Catmull-Rom costs about
0.66 ms at 1080p and 2.4 ms at 4K per pass (derived, and nearby offset taps are cache friendly, so likely a
slight underestimate). The hardware read and the 4-tap bilinear are cheaper than anything the bench resolves
here (4-tap under about 0.75 ms at 1080p). M1 not measured (NF-001).

**Consequences:**
- The codebox MUST read the history by hand from `nearest()` (new FR-011); the standard "four bilinear fetches
  make a bicubic" trick is unusable for the same reason (it relies on the hardware bilinear).
- G4: the 4-tap bilinear is the recommended v1 (matches the mirror to 0.0002 and costs under the floor); the
  16-tap Catmull-Rom is a real but affordable option (about 0.66 ms at 1080p) if the live look wants the
  contrast T004 measured. Using bare `sample()` is out unless the nearest-in-the-minifying-zone crunch is
  wanted as a look (it keeps amplitude 1.0, T004).
- The T004 numbers for "bilinear" therefore describe the 4-tap read, not `sample()`.
- A feedback module is this pass plus one `pass` copy (the `copy` row): at 1080p expect the whole module
  under about 1.6 ms with the 4-tap read (a bound), about 1.4 ms more with Catmull-Rom.

### 2026-10-27 (evening): Phase 1 built (T020-T023, T032)

- **Files:** `src/f_cmap/{definition.py, codebox_cmap.gen, codebox_cmap_pass.gen}`, `package/patchers/f_cmap.maxpat` (built with
  `build/py.sh build/build_patcher.py src/f_cmap/definition.py`), `tests/modules/cmap/{test_cmap_static.py, bench_cmap.py}`.
  Two `jit.gl.pix` (pass: guarded copy of the primary's out1; state: in1 source, in2 previous frame), float32, `adapt`.
- **Controls (token -> label):** `decay` Decay, `inject` Inject, `radius` Radius, `sweep` Sweep, `rate` Rate (clock only, no pix cord),
  `angle` Angle, `lscale` Scale (G7; `scale` is an Ob3D attribute, FR-009), `pwr` Power (int 2-4), `edge` Bounds (Source / Wrap; Black cut by G6),
  header toggle `freeze_on`, `reset` button, bypass. `bypass_gate` / `reseed` / `theta_clk` / `phase_clk` are internal.
- **Clock (T021):** `rate` is turns per frame; two raw accumulators wrapped into [0, 1) (theta at `rate`, phase at `rate` x sqrt 2),
  `rate` 0 freezes w exactly. Reset: button / route `reset` / loadbang -> `param reseed 1`, a draw-bang counter drops it after four bangs.
- **Behaviours:** reseed (= reset) and bypass output the source; freeze outputs the previous frame (reseed beats freeze). The source is
  NaN/Inf-guarded in the primary and the history in the pass stage (NF-003). The history read is the 4-tap bilinear from `nearest()` taps
  with the tap INDEX clamped (Source) or wrapped (Wrap), so no tap sits on a seam (FR-011).
- **Tier 1 static (5/5):** Param defaults equal the definition's, every internal param is declared, tokens avoid Ob3D attributes and
  operators, forbidden constructs absent (including a bare `sample(in2`), positional ids match the built patcher.
- **Tier 2 bench (`bench_cmap.py`, 9/9, Max 9.2.0):** the codeboxes against the float32 mirror over ten parameter cases (defaults, power
  3 and 4, wrap, scale 1.2 and 2.6, a clocked offset, heavy decay / inject, a large offset): mean error 2e-8 to 1e-7 in nine, 2.6e-5 in
  scale 1.2 (one pixel in ten thousand flips its inside / outside decision, max 0.62 there). Each parameter has an effect and matches its own
  mirror. Alpha is exactly 1 (source alpha 0.25, history alpha 0). `inject` 1 is the source exactly. Freeze is bit-exact on noise (also with
  cubed / wrap / offset). Reseed and bypass are the source, and reseed beats freeze. NaN / Inf source: output finite, frozen frame still exact.
  Pass stage: finite values copied exactly, non-finite channels read 0. Five ping-pong frames with a moving w: mean error 5e-8.
- **Registration (T023):** README row (Patterns, marked unverified), `NOT_IN_MENU` entry (Phase 3 places it), launcher regenerated (53 modules),
  drift ok, `bench_cmap` registered in `tests/lib/benchdeps.py` (ORDER 64), module contract bench (BENCH_MODULES=f_cmap run covered all 48
  modules: 0 unexpected issues), offline suite green (59 files).
- **Not done / owed:** cost of the module as built (the T006 numbers were for scratch shaders; the bench `measure` of the real codebox is a
  one-liner for a later look), the Matt look in Max (T030), the helpfile and reference doc (Phase 3).

### 2026-10-27 (night): Matt's first look in Max, and two offline look studies

- **Live look (Matt, camera in a dim room):** defaults and then Decay 1.0 / Inject 0.16 / Radius 0.47 / Sweep 0.81 / Rate 0.01 /
  Power 4 / Scale 1.86 both gave "just a scalloped gray shape": a flat dim interior with a faint ghost of the live image and a thin
  scalloped border; outside the window the live image. Not a bug (the bench matches the mirror), a property of the map: the basin
  contracts, so the interior collapses toward the fixed point and only the border carries detail.
- **`tests/records/spike_cmap_inverse.py` (sheets E, F):** the INVERSE map (the pixel reads prev(+/- sqrt(z - w)); principal, per-frame
  alternating, checker and per-pixel-hash branches). Result: not better. Principal is nearly the source with faint wisps (std 0.019),
  alt_frame / checker / hash are noisy salt-and-pepper streaks on top of the source; none fills the frame with structure. Dropped.
- **`tests/records/spike_cmap_room.py` (sheet G):** the shipped forward map on a low-saturation room-like synthetic (lamps, curtain stripes,
  a swaying dark head). It reproduces Matt's look: a dark / gray flat interior (the head's color smeared) inside a scalloped border. More
  structure with a larger Radius (0.8) and a smaller Scale (1.2: the frame zooms into the border, where the detail is); a faster Rate and
  Sweep only smear it flatter (Matt's Rate 0.01 turns the offset 3.6 degrees a frame). The T005 sheets looked rich because their source was
  saturated and high-contrast: the module gives back the contrast and color the source already has.
- **Status:** the look is a gate for the module (T030): a try at Scale about 1.0-1.2, Radius about 0.8, Power 2, Rate about 0.002, Sweep 0 on
  the live camera decides whether CMAP is worth keeping.
- **`tests/records/spike_cmap_motion.py` (sheet H, 2026-10-27):** the spec's goal tested directly: a bright disc crossing the Julia window
  (forward map, room source, n 2, radius 0.6, inject 0.3, decay 1, scale 1.75 and 3.0, 72 frames, bilinear). Result: there IS interaction,
  inside the window the disc is duplicated into several soft ghost copies (the map is two-to-one) that fade over some frames, with
  small bright specks along the border. There are NO filaments or spirals: the interior contracts, so wound detail is smoothed away,
  and a bilinear read loses fine detail each frame. The spec's "motion winds up into filaments and spirals" is not met on this source.
