# f_ — Focus

_Rewritten 2026-10-31, updated 2026-11-01._ Orientation only: what is Active, what is Next, what is owed to Matt. Blocked and parked things are in `.specify/gates.md`. Per-module detail is in `.specify/<module>/tasks.md` and `docs/f-reference/`. Session state is in `HANDOFF.md` (START HERE block). The previous full plan (resolved history, "Still open" 1-14, workstream prose) is in git: `git show 76c2ab8:.specify/plan.md`.

## Active

1. **Record-keeping.** HANDOFF trimmed (older entries in `HANDOFF_ARCHIVE.md`), this focus doc and `gates.md` written 2026-10-31. Next: use it for a few sessions and measure the startup read; add per-workstream blocks and a generated survey only if the gates file isn't enough.
2. **`f_modules` menu redesign** (Matt's, in progress). See `G-menu`.

Closed 2026-10-30/31: the `render_dim` migration (all tensor modules, vorticity, quasi, grain, seeds; `f_masonry` and `f_cmap` stay exempt), its live contract bench (green 2026-10-31 after a harness input-size fix), the `f_vf_advect` Trail rework, and `f_tf_hatch` (v2 built, benched, helpfile checked; only the spike-script tidy remains, Next 2; hub Q17, NaN masking in its E1 stage, probed clean 2026-11-01).

## Next (Claude's lean; Matt decides)

1. Render-trigger check: `f_stipple` done 2026-11-01 (gated `r draw` plus `render_dim` size; Matt live; T044/T045). Left: `f_vf_flow` (same `dual` wiring), then `f_weave` (doc says generator, archetype says processor; decide first).
2. Hatch tail: fix or archive the spike scripts that still pass `strength=` (T064); everything else about Hatch is closed.
3. Tier-3 tuning of `f_wave_field` (built; its full bench re-run is owed once, after tuning). `f_ks` tuning is done 2026-10-31 (map, defaults and ranges unchanged); its name (T010) and docs (T040) remain.
4. Packaging (`G-packaging`): the biggest strategic gap; no tag, icon or install test yet.

## Owed to Matt

- **Runs and looks:** live check of the remaining render-trigger suspects (`f_vf_flow`, `f_weave`); `f_wave_field` T030 tuning look (`.specify/f_wave_field/tasks.md`); the regenerated `f_modules` dropdowns; the new and corrected helpfiles (Axis Flow, Caustic notes); `f_caustic` demo-patch chain-cost check (untouched since 2026-10-08).
- **Decisions:** cap the `f_vf_advect` Trail dial near 50-100 (one-line change), yes or no.
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
