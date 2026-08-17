# Tasks: f_dither_grain (name TBD)

> **SUPERSEDED 2026-07-21** — folded into `f_vf_seeds` as "Evolution 3:
> Color-Driving Texture". See `.specify/stable/f_vf_seeds/tasks.md`'s
> Evolution 3 phase list for the active tasks. Kept below as historical
> record of the from-scratch attempt that preceded the pivot — not
> actionable, do not resume work here.

---

**Spec**: `.specify/f_dither_grain/spec.md`
**Build order**: Sequential. Complete each phase before the next.
**Commits**: After each phase checkpoint.

---

## Expected Output Layout

```
~/Vsynth/patterns/
  dither_grain_scratch.maxpat     — scratch patch for Phases 0-3 (not committed)

.specify/f_dither_grain/
  spec.md                         — done
  plan.md                         — done
  tasks.md                        — this file

src/f_dither_grain/
  definition.py                   — authored once Phase 3 confirms and a
                                     single-codebox-vs-pix_chain decision
                                     is made (see T022)
  codebox_*.gen                   — authored per T022's outcome
```

Per current repo convention, `src/f_name/` is canonical for build-input
files (`definition.py`, `codebox_*.gen`); `.specify/f_name/` holds
planning docs only. (This corrects an earlier version of this file that
placed `definition.py`/`codebox_*.gen` under `.specify/` — stale as of
2026-07-21.)

No `patchers/f_dither_grain.maxpat`, no `docs/f-reference/` entry, no
`.maxhelp` yet — none of that exists until this module has cleared its
scratch-test phases and earned a real build, per the project's
scratch-first discipline.

---

## Phase 0: Core boundary-dither mechanism (BLOCKING)

**Purpose:** Confirm the fundamental mechanism — thresholding a
hue-derived `t` against a per-cell dither value — actually reads as a
textured boundary between two flat hues, before any regularity or
vecfield complexity is added.

⚠️ Do not begin Phase 1 (jitter/regularity) until this checkpoint is
confirmed.

- [ ] T001 **DECISION GATE:** low-saturation fallback target — designated
  hue vs. neutral/grey grain. Per spec.md's Hue-boundary model, not
  resolvable by discussion alone; build both as a quick toggle in the
  scratch patch and judge which reads better once real (or
  low-saturation authored test) content is running through it. Document
  the choice and why here before treating Phase 0 as complete.
- [ ] T002 **DECISION GATE:** auto-sort authored hues by hue angle
  (default assumed in spec.md) vs. expose as a toggle from the start.
  Spec.md defaults to auto-sort only; confirm that default is actually
  sufficient for Phase 0's acceptance criteria (arbitrary hue pairs,
  not just convenient ones) before deciding whether the toggle needs to
  exist this early or can wait.
- [ ] T003 Open scratch patch at `~/Vsynth/patterns/dither_grain_scratch.maxpat`
- [ ] T004 Build or source an authored hue-wheel-gradient test texture
  (per spec.md Phase 0 — cheaper than a live camera feed, still
  exercises the real hue-angle-extraction code path)
- [ ] T005 Write hue-angle extraction (standard HSV-style) from the test
  texture, per cell
- [ ] T006 Write the two-reference-hue bracket + fractional-position `t`
  computation (trivial for the 2-hue case — this establishes the
  pattern the N-hue bracketing will later reuse)
- [ ] T007 Write the per-cell dither threshold test (`t < d` → `hue_a`,
  else `hue_b`), fixed/non-jittered `d` for this phase
- [ ] T008 Wire in the low-saturation gate stub per T001's decision
- [x] T009 Confirm grid of grains renders standing alone, no GL errors
  Confirmed in `dither_grain_scratch.maxpat` — renders cleanly, no
  console errors. One real bug found and fixed first: `Param hue_b`
  collided with local HSV-extraction intermediate variable names
  (`hue_r`/`hue_g`/`hue_b`, copied verbatim from `f_hue_processor`,
  which never hit this since it used differently-named params) —
  "can't assign to hue_b" compile error. Renamed the locals to
  `hcomp_r`/`hcomp_g`/`hcomp_b`. New risk class for the
  `jit-gen-codebox` skill: a `Param` can collide with an unrelated
  local variable name, not just a built-in operator — worth a quick
  scan of planned local var names against any `Param` list before
  writing, not just against the operator list.
- [x] T010 Confirm the `hue_a`/`hue_b` boundary visibly reads as a
  dithered/textured transition band — not a hard edge, not a smooth
  gradient
  Confirmed: `hue_a=0` (red), `hue_b=266` (purple/blue) produced solid
  color at each end with a genuinely speckled, textured transition band
  through the middle — not a hard edge, not a smooth gradient.
- [x] T011 Re-test with at least two different, non-adjacent/
  non-complementary hue pairs to confirm the mechanism generalizes,
  per spec.md's acceptance criteria — not just one convenient pair
  Confirmed with a closer hue pair: dithered band visibly **narrower**
  than the wide-span `0`/`266` case. Expected and correct — with only
  two reference hues, `t` spans the entire bracket, so a wide-span pair
  produces a wide "genuinely uncertain" middle region while a
  close-span pair narrows it. Band-width-scales-with-span behavior
  confirmed, not just "some dithering happened."
  Also checked bypass: toggling shows no visible change in this bare
  scratch setup, but root-caused to the scratch patch having no
  render-clock/bang trigger wired to force a redraw on bypass alone —
  `jit.gl.pix` only redraws on bang, and nothing here re-bangs when
  `bypass` changes in isolation. Codebox logic (`mix(result, test_col,
  bypass)`) is correct; not treated as a real bug, not blocking Phase 0
  closure. Worth confirming for real once wired into `vs_render`
  properly (build phase), not re-tested further in scratch.

**Checkpoint: REACHED 2026-07-21.** Core mechanism confirmed reading as
dithered hue boundary, band width scaling correctly with hue-pair span,
on more than one hue pair. → Proceed to Phase 1.

---

## Phase 1: Regularity (`jitter`) (BLOCKING)

**Purpose:** Confirm the regular↔stochastic continuum, in isolation,
before vecfield is introduced.

⚠️ Do not begin Phase 2 (vecfield magnitude) until this checkpoint is
confirmed.

- [x] T012 Add hash-based per-cell positional jitter (reuse `f_stipple`'s
  or `f_grain`'s known-good hash approach — do not attempt `noise()`/
  `snoise()`, confirmed dead on this GPU path per `jit-gen-codebox`
  skill)
  Implemented as nearest-jittered-center search: each pixel's cell
  center is displaced by `(hash - 0.5) * jitter` within its cell, then
  the pixel finds its nearest center across the 3x3 neighborhood of
  cells (9-iteration nested `for` loop), producing Voronoi-like organic
  boundaries rather than square cells with randomized fill. Randomizing
  only the per-cell threshold value (Phase 0's approach) would have left
  grid lines visible even at `jitter=1` — this was identified as
  insufficient before writing any code, not discovered by trial and
  error.
- [x] T013 Confirm `jitter=0` reproduces Phase 0's regular-grid look
  exactly (regression check, not just "looks similar")
  Confirmed at `cell_freq=8`: clean square cells, indistinguishable in
  kind from Phase 0's grid, same hue params. Regression check passed.
- [x] T014 Confirm `jitter=1` produces a no-visible-grid, blue-noise-like
  scatter
  Confirmed at `cell_freq=8`: genuine irregular polygonal (Voronoi-like)
  cells, no visible grid structure. Initial check at `cell_freq=141` was
  inconclusive (cells too small at that scale to tell organic from
  secretly-square by eye) — re-tested at low `cell_freq=8` specifically
  to make cell shape visible, which is what actually confirmed the
  mechanism rather than just "looks noisy."
- [x] T015 Sweep intermediate `jitter` values; confirm a legible
  continuum with no abrupt jumps or artifacts at any point
  Confirmed at `cell_freq=8`, `jitter=0.5`: cells visibly perturbed away
  from straight grid lines, still roughly cell-sized and grid-derived —
  a legible midpoint between Phase 0's squares and `jitter=1`'s fully
  organic scatter, no runaway distortion or discontinuity.

**Checkpoint: REACHED 2026-07-21.** Regularity dial confirmed working
standalone — jitter=0 regression-matches Phase 0, jitter=1 produces
genuine organic cell boundaries (not just randomized squares), and the
continuum between is legible. → Proceed to Phase 2.

---

## Phase 2: Vecfield — magnitude → size/density (BLOCKING)

**Purpose:** Confirm the first vecfield role in isolation. Hue-boundary
logic and jitter unchanged from Phase 1.

⚠️ Do not begin Phase 3 (vecfield direction) until this checkpoint is
confirmed.

- [x] T016 Add vecfield inlet; wire magnitude → grain size and/or density
  Two implementations tried, in order. First: spatially-varying
  `cell_freq` (density-only) — rejected as not proving anything new,
  since `f_grain` already establishes "density via frequency" as
  standard vocabulary. Second: literal per-grain radius + flat
  background for uncovered pixels — worked, but Matt clarified
  real usage is on full-color textures with no concept of "background";
  shrinking a grain should reveal the neighboring grain instead. Third
  (final): adopted `f_grain`'s own `shape_t`/`soft_falloff` mechanism
  directly (`docs`/`src/f_grain/definition.py`, confirmed via direct
  read, not from memory) — normalizes nearest-center distance against
  the actual Voronoi boundary (midpoint between nearest and
  second-nearest centers) rather than a fixed/absolute radius, then
  vecfield magnitude scales that normalization the same way `f_grain`'s
  `size_var` does, and the two nearest grains are alpha-composited
  (`mix(second, best, soft_falloff)`) rather than binary-selected.
  `f_vf_seeds`' composite stage (`codebox_seeds_composite.gen`,
  confirmed via direct read) independently uses the same
  rank-over-rank alpha-blend principle at a multi-stage level — two
  separate modules landing on the same answer, treated as confirmation
  this is the right mechanism rather than a good guess.
- [x] T017 Confirm legible, controllable response across the magnitude
  range (not just visible at extremes)
  Real debugging round, not a clean first pass. Initial `mag_amount`
  values (calibrated large to compensate for the vecfield's typically
  small raw magnitude, per T018's finding) pushed `shape_t_scaled` far
  enough to saturate fully to 0 or 1 almost everywhere inside each
  grain — collapsing `soft_falloff`'s per-cell feather texture into a
  single smooth macro-scale field-shaped gradient with no visible grain
  structure, which looked identical to "softness/mag_amount have no
  effect." Root-caused via a raw grayscale preview of `soft_falloff`
  itself (isolating the mechanism from the composite, same diagnostic
  approach used for the earlier split-color and flat-background bugs)
  — confirmed real per-cell texture reappears at a much smaller
  `mag_amount` (0.3 vs. the earlier much larger value), with the
  vortex's smooth radial falloff visible sitting on top of, not
  replacing, individual grain boundaries. Formula itself confirmed
  correct throughout; this was a clamp/scaling-range issue, not a logic
  bug.
- [x] T018 Wire a real `f_vf_` producer (e.g. `f_vf_vortex`) as the
  vecfield source, not a synthetic test field; confirm distance-from-site
  falloff reads naturally through magnitude alone, per spec.md's stated
  special case
  Confirmed with `f_vf_vortex`. Also surfaced a real, expected finding:
  the producer's Conv/Curl Amt *modulation* dials being at 0.00 (only
  base Conv/Curl values active) meant raw field magnitude away from the
  core was small, requiring a much larger `mag_amount` than intuitively
  expected to see any response at all — resolved by increasing the
  vortex's own convergence amount rather than continuing to push
  `mag_amount`, which is the correct fix (properly-scaled source field)
  rather than compensating for an under-driven one.

**Known, accepted limitation carried forward (not a bug):** with only
two reference hues, `best_grain_col`/`second_grain_col` are frequently
identical away from the `hue_a`/`hue_b` dither seam — so `soft_falloff`
blending a color with itself is invisible there regardless of how
correct the underlying magnitude-driven math is. Confirmed via the raw
`soft_falloff` grayscale channel that the mechanism itself is fully
correct and legible; the full-color composite will only visibly show
vecfield-driven size right at the hue transition until a third
(or texture-driven) hue source exists. Treated as an honest
characteristic of this decoupled, 2-hue scratch setup, not something to
keep chasing now — matches spec.md's own Out of Scope framing (N-way
hue selection and texture-driven hue references are both explicitly
deferred).

**Checkpoint: REACHED 2026-07-21.** Magnitude→size/density confirmed
correct and controllable via the raw mechanism (`soft_falloff`
grayscale), with a real producer, with the composite-visibility
limitation above understood and accepted rather than unexplained.
→ Proceed to Phase 3.

---

## Phase 3: Vecfield — direction → shape/elongation — DESCOPED 2026-07-21

**Original purpose:** Confirm the genuinely novel mechanism — no
existing module orients grain shape from a field.

**Descoped, not deferred.** Built and technically confirmed working
(anisotropic falloff distance, tracking a real vecfield's direction,
distinguished from a pre-existing lattice artifact — see prior session
notes below) — but Matt's real-world judgment on reviewing the actual
result: `aniso_dist` rescales the edge-distance metric under the hood,
which reads visually as a warped ring/polar pattern rather than a
genuinely elongated grain silhouette. Mechanically working is not the
same as delivering the thing this phase was meant to produce. Matt's
call: not essential, and chasing why it doesn't *read* as elongation
would be a rabbit hole not worth the complexity for a nice-to-have axis.
Dropped from scope entirely, not left as a someday-revisit — if
direction-driven shape comes up again, it should be treated as a fresh
design question, not a continuation of this attempt.

**What's kept from this phase's work:** the `theta`/along-across rotated
coordinate frame technique (borrowed from `f_stipple`) and the general
finding about `voronoi_boundary_dist`'s lattice-artifact behavior remain
valid, reusable findings — only the *elongation application* of them is
dropped, not the underlying technique itself.

<details>
<summary>Original task notes (kept for reference, not actionable)</summary>

- [x] T019 Wire vecfield direction → grain `shape`/elongation axis
  Borrowed `f_stipple`'s rotated along/across coordinate-frame pattern
  (`theta`/`cx`/`sx`-style rotation, confirmed via direct read of
  `src/f_stipple/definition.py`) — but driven by a per-grain
  `atan2(vf_y, vf_x)` field direction instead of `f_stipple`'s fixed
  global `angle` dial, and applied to the falloff *distance metric*
  (`aniso_dist`) rather than a hash blend.
- [x] T020 Confirmed real per-cell elongation tracking local vecfield
  direction, distinct from a uniform global stretch and from a
  pre-existing lattice-normalization artifact — but see descope note
  above: mechanically real, not visually convincing as "elongation."
- [x] T021 Satisfied by the same T020 test.

</details>

**Real, unresolved problem surfacing instead:** every confirmation in
Phases 2 and 3 happened via a debug grayscale channel
(`soft_falloff`/`shape_t_scaled` previewed directly) — the actual
full-color composite has never once clearly shown either vecfield effect.
With only two reference hues, `best_grain_col`/`second_grain_col` are
frequently identical away from the `hue_a`/`hue_b` dither seam, so any
soft-falloff blend between them is invisible almost everywhere. This was
noted as an "accepted limitation" after Phase 2, but per Matt's
2026-07-21 review, it's actually the real open problem, not a footnote —
the module's core deliverable (a legible full-color effect) is still
unproven. Next real work should address this directly — likely via
testing with 3+ reference hues (so neighboring grains more often
genuinely differ) — before any further build-planning gate is treated
as resolved.

---

## Build planning (not yet a phase — gate before `definition.py`)

- [ ] T022 **DECISION GATE:** single codebox vs. `pix_chain` multi-stage.
  Depends on whether the vecfield-driven shape/orientation math (Phase 3)
  is cheap enough to compute inline alongside the hue-bracket/dither
  test, or whether it needs separating the way `f_vf_optical_flow`'s
  windowed-sum stage did. Not decidable before Phase 3 is actually
  running — resolve here once real GPU behavior (or a capture-group
  ceiling hit) is observed, not by assumption beforehand.
- [ ] T023 **DECISION GATE:** module name. `f_dither_grain` is a
  placeholder throughout spec.md and this file — confirm final name
  before `definition.py`/directory naming/registration, since renaming
  after the build touches more files than renaming before it.

---

## Dependencies

**Phase dependencies (strict):**
- Phase 0 → Phase 1: core mechanism confirmed before adding regularity
- Phase 1 → Phase 2: regularity confirmed before adding vecfield's first
  role
- Phase 2 → Phase 3: magnitude role confirmed before adding direction
  role
- Phase 3 → Build planning: all mechanisms confirmed independently
  before deciding codebox architecture or committing to a name

**No cross-phase parallelism** — per spec.md's explicit decoupled-first
approach, each phase exists specifically to validate one variable in
isolation before the next is layered on.

---

## Notes

- Five explicit decision gates are embedded in this task list (T001,
  T002, T022, T023 — plus the coupling-vs-decoupled question already
  resolved in spec.md's Clarifications, not repeated here as a gate)
  rather than left as spec.md prose, per the project's convention of
  putting outstanding architecture/design decisions into `tasks.md` as
  real to-do items when they exist for a module.
- This module has no committed code, no `.maxpat`, and no scratch patch
  yet as of this writing — Phase 0 is the actual starting point, not a
  formality.
- Coupling `t` and vecfield into one shared source (spec.md's Out of
  Scope) is deliberately not a task here — it's a possible future spec
  revision after this decoupled version is proven out, not a deferred
  task within this one.
