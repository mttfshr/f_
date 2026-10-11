# HANDOFF

_Updated 2026-10-10._

## Ideas: two vector-field spikes built and run (research, no production code changed)

Built and ran the two cheapest items flagged in `ideas/vector_field_math_concepts.md`
(#5 Lie bracket, #6/#10 Möbius vecfield correctness), both as NumPy Math-tier scratch
scripts rather than live Max patches: `tests/spike_lie_bracket.py` and
`tests/spike_mobius_vecfield_transform.py`. Neither is a regression gate (not
registered in benchdeps); both mirror shipped codebox math (`f_vf_vortex`,
`f_vf_warp`, `f_mobius`) directly from their `definition.py`.

- **Lie bracket** (#5): chained `f_vf_warp` through two different `f_vf_vortex`
  configs (a sink, a vortex) in both orders. Visibly non-commuting -- mean
  |diff| 0.51, max 1.0, concentrated around both singularities and the spiral
  arms, not noise. `scratch/lie_bracket_spike.png`.
- **Möbius vecfield correctness** (#6/#10): confirmed from source that
  `f_mobius`'s codebox (`effect_out = sample(in1, ...)`) naively resamples a
  piped-through vecfield -- no vector-aware transform exists. Characterized
  the error: the rotate+zoom path gives a constant 45 deg direction error
  everywhere (this test's params); the invert path gives up to 180 deg (full
  reversal) near the transform's singularity, with local scale `|g'(z)|`
  ranging 2x to 8192x across the tested domain. Corrected a misread along the
  way: the invert path (`inv_x = zx/mag_sq, inv_y = -zy/mag_sq`) is plain
  `1/z`, holomorphic -- not an orientation-flipping conjugate as first
  assumed. First draft of the indicatrix diagnostic drew pushed-forward
  circles directly and they landed off-canvas near the pole (a real effect of
  `1/z`'s singularity, not a plotting bug) -- replaced with a log-scale
  heatmap of local scale, which is the more correct diagnostic anyway: a
  conformal map's true Tissot indicatrix is always a circle, never an
  ellipse, so shape never distorts, only size.
  `scratch/mobius_vecfield_rotate_zoom.png`, `scratch/mobius_vecfield_invert.png`.

No production module touched, no tests registered/gating. If a corrected
vecfield-aware UV-warp mode is ever wanted (new producer, not a near-term
build), this is the starting math.

- Nothing actionable forced by this -- pure diagnostic, confirms a real gap
  in `f_mobius` (and presumably `f_droste`/future `f_poincare`) without
  deciding whether it's worth fixing.

## f_caustic: soft mode removed, sheets locked to the heaviest step, expo exposed

Matt's call: sheets mode was consistently better than soft mode, and there was no reason to run
anything but the 1024²/4px detail step. Removed the mode/detail menus entirely, fixed the scatter
at that one step, and used the simplification to expose a param that used to be a hidden constant.
Color/chromatic-shift was deliberately NOT replaced here — Matt's building a demo patch that
chains `f_caustic` into `f_vf_prism` for that look instead, so prism stays the owner of it.

- **Architecture** (`90cee74`): collapsed the two-stage `pix_chain` (composite + select) down to
  the one remaining stage, `caustic` (`codebox_sheets.gen`). Bypass — previously handled by the
  now-deleted select stages — moved onto this codebox directly via a `bypass_gate` Param, mixed in
  on both outlets. `expo` (was a fixed internal `0.7` constant) is now a Param,
  range `0.3-1.5`. Deleted `codebox_v1.gen`, `codebox_v2.gen`, `codebox_select_comp.gen`,
  `codebox_select_layer.gen`. `scatter_scene.py` rewritten: the old 5-step `select`-ladder network
  is gone, replaced by a one-time `loadbang` that sends the fixed `(1024, 4)` lattice spec into the
  control entry at load. Caught and fixed a real wiring bug during verification (not flagged by
  Matt — found by tracing the built `.maxpat`, not by trusting `definition.py`): the vecfield
  mod_inlet's fanout collided with the capture node's wire into the same codebox inlet; moved from
  `caustic` inlet 1 to inlet 2.
- **Docs/README/launcher** (`983e52e`): `docs/f-reference/f_caustic.md` rewritten for the
  single-path shape (new History entry recording the change); README's patch-table line updated;
  `f_Launch.maxpat` regenerated.
- **Test surface** (`127b1c0`): `test_scatter_scene.py`, `bench_caustic_codebox.py` (added T013
  tests for `expo` and `bypass_gate`, now Params on this codebox directly), and
  `bench_caustic_sheets.py` all reworked for the single-path shape — the per-step sweep, the
  soft-mode baseline comparison, and the per-mode enable/disable checks are gone along with the
  branches they tested. `tests/record_caustic_baseline.py` and
  `tests/baselines/f_caustic_soft.npz` deleted (nothing left to baseline against).
  `tests/bench/caustic_sheets_standalone.maxpat` regenerated.

  Two real findings surfaced while getting this green, both fixed in place with a documented
  reason rather than silently papered over:
  - A stale tolerance (`test_T016_tone_and_upscale_follow_the_source_size`): 5e-3 was calibrated
    for the old detail-3 (768²) step; the fixed 1024² step measures 5.24e-3 against this test's
    1920x1080 source. Widened to 6e-3 — same cause (hardware bilinear 8-bit-weight rounding at a
    non-integer scale), not a regression.
  - **A real, measured cost consequence, not a test bug**: `test_T021_the_fixed_step_fits_the_
    frame_budget` and `test_T035_the_module_fits_the_frame_budget` check the SAME thing that was
    already green before this change (step 5 against 1.15x the 16.7ms frame cap) — but now
    consistently measure 21-23ms, roughly 1.3x the cap, across three separate runs. This is exactly
    the risk flagged to Matt before he approved the plan: making the heaviest scatter step
    unconditional, with no cheaper fallback, has a real floor cost. Confirmed with Matt rather than
    quietly loosening the number: widened to a named `FRAME_BUDGET_MULT = 1.4` with the measurement
    recorded in a comment. **Worth remembering**: `f_caustic` alone now costs ~21-23ms/frame on
    this machine — if a live patch ever drops below 60fps with `f_caustic` in the chain, this is
    the first thing to check, not a mystery regression elsewhere.

- Verified green: `test_scatter_scene.py` 4/4, `bench_caustic_codebox.py` 7/7,
  `bench_caustic_sheets.py` 12/12.
- Decision record: `.specify/f_caustic_scatter/tasks.md`, 2026-10-10 entry.
- Reference doc: `docs/f-reference/f_caustic.md`.
- Commits: `90cee74`, `983e52e`, `127b1c0`.

## Ideas: vector field math concepts (research, no code)

Read the Wikipedia vector field article at Matt's request and wrote
`ideas/vector_field_math_concepts.md` — nine concepts from the article each
tied to a concrete `f_` opportunity: singularity index as an explicit
control (Poincaré–Hopf/hairy-ball on the circular-screen domain), central
fields as a simpler generator mode, Helmholtz gradient/curl decomposition,
the streamline/pathline/streakline distinction (reframes `f_vf_smear`'s LIC
candidate), the Lie bracket as a zero-build composition experiment,
whether UV warpers (`f_droste`/`f_mobius`/`f_poincare`) transform a
piped-through vecfield correctly or just resample it, conservative-field
path-independence as a free NumPy test, deliberate finite-time blow-up as
a design axis, and tensor fields as the next rung up.

Expanded the tensor-field section (#9) at Matt's follow-up with four
concrete phenomena a tensor field makes possible that a vector field
structurally can't: unoriented line fields (ties directly to `f_weave`'s
orientation-blend bug — `ideas/f_weave_orientation_blend.md`), anisotropic
structure-aware blur, photoelastic stress-fringe optics (new territory for
`f_lens`/`f_caustic`/`f_vf_prism`), and confidence-scaled marks for
`f_vf_seeds`/`f_grain`.

Added a pointer entry in `ideas/INDEX.md`'s Vector field family section.

No code touched, no tests run. Nothing built — this is pure ideation,
flagged research-grade/speculative throughout. Cross-reference
`ideas/f_vecfield.md` and the existing parked/open items (`f_vf_vorticity`,
`f_vf_potential`, `vorticity_confinement.md`,
`ceyron_simulation_scripts_notes.md`) before building on any of it.

- Nothing actionable yet on this thread — these are notes to revisit, not
  tasks. If any of it gets picked up, the cheapest entry points are #5
  (Lie bracket) and #6 (vecfield-through-UV-warper correctness check):
  both need zero new code, just a scratch-patch afternoon.

## Ideas: tensor field follow-up + wind-as-interface brainstorm (research, no code)

Continued the vector-field ideas thread at Matt's request: read the Wikipedia
tensor field article and added §10-13 to `ideas/vector_field_math_concepts.md`
— Tissot's indicatrix as a distortion diagnostic for `f_droste`/`f_mobius`/
`f_poincare` (the most direct way to actually settle §6's open question),
the Jacobian determinant as adaptive anti-aliasing (possible way around
`line_edge_antialiasing.md`'s GenExpr-derivatives block), the covariant
derivative as a correctness warning for `f_sharmonics`/circular-screen
gradient work, and authoring UV distortion from a metric tensor instead of
a closed-form transform (new territory, closer to `f_conformal_fill.md`'s
offline-solve flavor). Updated `ideas/INDEX.md`'s pointer entry to match.

From there the conversation turned to a physical brainstorm — a sewn,
inflatable, translucent rear-projection dome meant to move and deform
gently in wind rather than hold a fixed shape. Wrote a new file,
`ideas/wind_as_interface.md`: the reframe from correcting geometry to
picking content that degrades gracefully under uncontrolled deformation
(`f_vf_vortex`/`f_vf_fluid`/`f_caustic`/`f_grain` fit by nature), the
escalation to actually sensing live fabric deformation (wrinkles as a
structure-tensor/line-field phenomenon, same math as §9), why that needs
distributed processing (camera CV and GPU-heavy Vsynth contend for the same
resources on one machine — this came from Matt's own past experience of it
bogging down), and a comparison of sensing routes: camera+CV streaming a
small field texture over NDI vs. distributed IMU nodes (candidate part:
Adafruit LSM6DS3TR-C, 6-DoF, STEMMA QT, one ESP32 per sensor sending OSC
over WiFi) vs. a plain anemometer — plus why WiFi/OSC beats LoRa for this
(range/bandwidth mismatch, not a real distance problem to solve). Added a
pointer in `ideas/INDEX.md`'s Standalone research section.

Both still pure ideation — no code, no tests, nothing built or decided.

## Left for Matt

- Nothing on the tensor-field or wind-as-interface writing — both are
  explicitly "mull over, not a plan" per Matt. `wind_as_interface.md` ends
  with its own open-questions list (spatial vs. single-signal sensing,
  on-node smoothing, power for fabric-mounted nodes, nothing prototyped).
- Nothing outstanding on this f_caustic change — fully committed, tests green, docs/README/
  launcher updated, panel layout confirmed by Matt live in Max (no `build/capture.py` pass needed).
- `tests/spike_caustic_res_cost.py` imports `MODULE`/`gradient_wide` from `bench_caustic_sheets.py`
  and references the now-removed `DETAIL` ladder — not touched this session since it's explicitly
  a diagnostic, not a regression gate (per its own docstring), so lower priority. Worth a look
  before it's relied on again.
- The f_grain work from the previous handoff (T001-T003, live check) is fully committed
  (`e2ea2db`, `8c0f9ae`, `4dad7e9` + the presentation capture) — nothing left there; the open item
  about moving `.specify/f_grain/` to `.specify/stable/f_grain/` is still just sitting unanswered,
  carried forward in case Matt wants it done.
- Everything else from before that (the `jit-gen-codebox` skill re-upload, soft-mode `scale`>1.0 —
  moot now that soft mode is gone) is presumably still wherever it was, not touched this session.
