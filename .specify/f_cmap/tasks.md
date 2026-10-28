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
- [ ] **T006** Cost bench (Max, with Matt): single pass plus `pass` copy at 1080p and 4K;
  report a bound if under the bench's resolution floor. NF-001; M1 unmeasured.

### Gates (Matt)

- [ ] **G1** Naming (`f_cmap` or a name a performer reads).
- [ ] **G2** Bounds region: frame rectangle (proposed) or the source's disk.
- [ ] **G3** `power`: integer 2-4 or fixed at 2.
- [ ] **G4** Sampler: bilinear plus injection, or Catmull-Rom (after T004).
- [ ] **G5** No `gain` / `mix_pct` in v1 (inject is the source blend): confirm.
- [ ] **G6** Control trim (T005 done: candidate cut is the `black` bounds rule).
- [ ] **G7** (new 2026-10-27) Promote the `L` scale dial (T032) into v1.

## Phase 1 - build (T020-T023)

- [ ] **T020** Codeboxes `src/f_cmap/codebox_cmap_pass.gen` and `codebox_cmap.gen`, and
  `definition.py` modelled on `src/f_vf_advect/definition.py` (Pattern 1: pass and primary
  pix, float32, `adapt`, `pix_wires` state -> pass -> state in2). Check every control
  name against `jit.gl.pix` attributes and GLSL builtins (FR-009; the `depth`, `texture`
  and `t` traps), frame-size-change behaviour, NaN guard (NF-003).
- [ ] **T021** Patcher clock for `theta` / the sqrt(2) phase on `rate` (`f_quasi` clock
  precedent), exact freeze at rate 0; freeze and reset wiring (`f_wc` header toggle).
- [ ] **T022** `tests/modules/cmap/bench_cmap.py` (register in `tests/lib/benchdeps.py`,
  pick an unused ORDER): codebox versus mirror frame by frame, bypass, bounds modes. Give
  the first input the render's size (the `dim` finding).
- [ ] **T023** Registration: README row (Patterns, with a unverified marker until Phase 3),
  `build/py.sh build/generate_launch.py`, `NOT_IN_MENU` entry until Phase 3, drift,
  module contract bench. Offline suite once at the end.

## Phase 2 - tuning and extensions (gated)

- [ ] **T030** Tuning with live camera (Matt): defaults, ranges, `inject` / `decay` feel.
- [ ] **T031** Optional vecfield offset inlet for structure-aligned pull (tensormap ->
  axisflow). First check whether `f_vf_warp` through `vs_feedback` already gives it.
- [ ] **T032** Optional `scale` dial (the `L` constant, currently baked at 1.75).

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
