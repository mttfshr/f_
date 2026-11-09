# f_ — Focus

_Rewritten 2026-10-31, updated 2026-11-08._ Orientation only: what is Active, what is Next, what is owed to Matt. Blocked and parked things are in `.specify/gates.md`. Per-module detail is in `.specify/<module>/tasks.md` and `docs/f-reference/`. Session state is in `HANDOFF.md` (START HERE block). The previous full plan (resolved history, "Still open" 1-14, workstream prose) is in git: `git show 76c2ab8:.specify/plan.md`.

## Active

1. **Record-keeping.** HANDOFF trimmed (older entries in `HANDOFF_ARCHIVE.md`), this focus doc and `gates.md` written 2026-10-31. Next: use it for a few sessions and measure the startup read; add per-workstream blocks and a generated survey only if the gates file isn't enough.
2. **`f_modules` menu redesign** (Matt's, in progress). See `G-menu`.
3. **`f_wave_field` redesign** (Matt's, 2026-11-04): done 2026-11-05 except T041: outline strike, LFO inlet, held press (T042), docs and helpfile (T040), in the menu under ∇ Fields, README ⚠ removed; live looks passed and benches green on the four-input harness. T041 (the `f_cymascope` audio front end) is not started. Record: `.specify/f_wave_field/tasks.md`.
4. **`f_vf_stamp`** (done 2026-11-06: built, benches green, live looks passed, documented): a gated stamping tool (texture + vecfield in; ink + impulse out; radial / swirl switch). Only the menu category is provisional (`G-menu`); the helpfile still wants a look. Record: `.specify/f_vf_stamp/tasks.md`.

5. **Print-styles family** (Matt, 2026-11-07/08): print behaviours as composable `f_` modules for screens and projection (print is a vocabulary; `ideas/f_print_styles.md`). `f_separate` is BUILT and its plates show in Max (Matt, live, 2026-11-08, after `aeaf7b3`); codebox bench 5/5 (`tests/logs/20261108-222210-bench.log`). Its looks (T030-T032), module bench and docs remain. Record: `.specify/f_separate/tasks.md`. `f_ink`, `f_screen`, `f_engrave` are specified, not built; `f_misregister` and `f_paper` have no spec. Open gates: `G-print-prelim`, `G-engrave-method`.

Closed 2026-11-07: `f_poincare` (built, benched, documented, preflight passed T052), moved to `.specify/stable/f_poincare/` (record there; `ideas/f_poincare_lessons.md` for what transfers to `f_apollonian` and `f_conformal_fill`).

Closed 2026-11-01: the render-trigger check (`f_stipple` gated `r draw` plus `render_dim` size, T044/T045; `f_weave` unconnected lines and optional inlets (reworked later the same day, below), live contract bench green 2/2; `f_vf_flow` needs a texture, re-typed processor), and `f_wave_field` T030 (Matt: passes with the existing defaults, no change; no bench re-run needed).

Closed 2026-11-01 (evening): `f_weave` rework and promotion: the vecfield inlet retired (`G-weave-scope` Q1), the irregularity variants, `offset`, texture-modulated weight / marklen / irreg (tagged textures on inlet 0, via the new `mod_inlets` `tag` builder key), a compact panel with the mode controls in the title bar, `shape` removed, type dots gray. Live look, variant checks, `marklen_tex` and the live contract bench passed (Matt; bench log `tests/logs/20261101-210309-bench.log`); offline suite green (67 files). Details: `docs/f-reference/f_weave.md` "Promoted", `.specify/f_weave/tasks.md` T063-T066.

Closed 2026-10-30/31: the `render_dim` migration (all tensor modules, vorticity, quasi, grain, seeds; `f_masonry` and `f_cmap` stay exempt), its live contract bench (green 2026-10-31 after a harness input-size fix), the `f_vf_advect` Trail rework, and `f_tf_hatch` (v2 built, benched, helpfile checked; the spike-script tidy closed 2026-11-06, T064; hub Q17, NaN masking in its E1 stage, probed clean 2026-11-01).

## Next (Claude's lean; Matt decides)

0. Stable push (Matt, 2026-11-06): batch 3, `f_tf_tensormap`, `f_tf_hatch`, `f_tf_axisflow`, `f_vf_fieldmap`, `f_vf_potential`, `f_vf_flow` and `f_tone_curve` moved, so all seven are in `.specify/stable/`; batch 4 triage is done (`.specify/maintenance/batch4_triage_2026-11-06.md`), Group A (`f_vf_warp`, `f_stipple`, `f_vf_glow`, `f_vf_prism`) moved to `.specify/stable/` 2026-11-06; Group B (`f_vf_advect`, `f_vf_streak`) moved to `.specify/stable/` 2026-11-06; `f_vf_optical_flow` and `f_vf_seeds` bypass passthrough done 2026-11-06 (look and bench passed); `f_vf_vortex` moved to `.specify/stable/` 2026-11-06, batch 4 done; bar is in `HANDOFF_ARCHIVE.md`, 2026-11-06 entries.

1. Print-styles: `f_separate`: the looks owed below, then its module bench and docs (`.specify/f_separate/tasks.md` T022, T030-T041). Then review the PRELIMINARY gates and clarify `f_screen` and `f_engrave`; `f_ink` Phase 0 (T016). `f_paper` (now additive) and `f_misregister` still need specs. Nothing runs without Matt's go.
2. `f_ks`: its docs (T040) remain (name closed 2026-11-06, T010) (tuning done 2026-10-31: map, defaults and ranges unchanged).
3. Packaging (`G-packaging`): the biggest strategic gap; no tag, icon or install test yet.
4. `f_masonry` adopts tagged textures (Matt, 2026-11-01: later, not yet). Its modulation is by space (slot, brick, pixel) with a depth per appearance param in each: 6 params x 3 spaces = 18 depths, so "one tag per named `<param>_tex`" needs a decision about the spaces. It is the module on the never-regenerate list (`G-masonry`).
5. The UI design conversation toward a design skill: `ideas/ui_design_concepts.md` (gate `G-ui-density`).

## Owed to Matt

- **Runs and looks:** `f_separate`: does the preview outlet show (the plates do, Matt 2026-11-08); does a plain reopen keep a changed swatch; does a saturation dial change the swatch; does the Mode menu fit; the new `f_vf_stamp` helpfile; the regenerated `f_modules` dropdowns; the corrected helpfile (Caustic notes); `f_caustic` demo-patch chain-cost check (untouched since 2026-10-08).
- **Decisions (print-styles):** the PRELIMINARY gates in the `f_ink`, `f_screen` and `f_engrave` `tasks.md` files and the remaining ones in `f_separate` (`G-print-prelim`); which `f_separate` mode to keep or default to (Unmix, Nearest, Project); then `f_engrave`'s method, once its spike report exists (`G-engrave-method`).
- **Decisions:** Batch 4: the remaining calls are the optical_flow / seeds passthrough details and the vortex mod-inlet gating (Matt: later).
- **Optional cleanup:** `scratch/experiments/f_weave_character/` (local, gitignored) is redundant with the shipped `f_weave`; delete whenever.
- **Later, no date:** the `f_weave` name (`G-weave-scope`, question 6): revisit once the module is better known.
- **Uploads:** re-upload `skills/vsynth-bpatcher/SKILL.md` and run `skills/check.sh stamp` after the `vs_black` wording fix (also `docs/vsynth-reference/patterns.md`).

## Conventions in force

Detail is in `CLAUDE.md`, `.specify/constitution.md` and `skills/`; the ones that most often decide what a module must look like:

- `definition.py` is the source of truth; a hand edit in Max is written back; `tests/build/test_drift.py` ratchets a shrinking baseline.
- Verification tiers: math mirror, bench execution, live judgment. Pre-convention modules need tier 1 when a closed-form check exists at moderate cost, otherwise a recorded skip.
- Gain / mix split (`gain` unbounded, `mix_pct` 0-100) for additive-layer modules; processors with no dry/wet control don't get `mix_pct`.
- Bypass via a codebox `bypass_gate` Param, never native `@bypass`.
- Outputs follow the render size (`render_dim`); controls named Width / Height are gone.
- Texture modules chain through `jit.gl.pix`; audio modules use MSP cables and can't plug into them (`G-audio`).

## Where things live

- `HANDOFF.md`: START HERE and the latest entry. `HANDOFF_ARCHIVE.md`: grep for history.
- `.specify/gates.md`: blocked and parked items with deciders and tripwires.
- `.specify/<module>/{spec,plan,tasks}.md`, with `stable/`, `paused/`, `superseded/`: the module record. Unticked boxes in older build checklists are history, not status.
- `ideas/INDEX.md`: map of idea notes. `docs/f-reference/module-inventory.md`: one line per module.
- README Patches table: the module list and ⚠ markers; it generates `f_Launch`.
