# f_ — Focus

_Rewritten 2026-10-31._ Orientation only: what is Active, what is Next, what is owed to Matt. Blocked and parked things are in `.specify/gates.md`. Per-module detail is in `.specify/<module>/tasks.md` and `docs/f-reference/`. Session state is in `HANDOFF.md` (START HERE block). The previous full plan (resolved history, "Still open" 1-14, workstream prose) is in git: `git show 76c2ab8:.specify/plan.md`.

## Active

1. **Record-keeping.** HANDOFF trimmed (older entries in `HANDOFF_ARCHIVE.md`), this focus doc and `gates.md` written 2026-10-31. Next: use it for a few sessions and measure the startup read; add per-workstream blocks and a generated survey only if the gates file isn't enough.
2. **`f_modules` menu redesign** (Matt's, in progress). See `G-menu`.
3. **`f_tf_hatch` close-out.** v2 is built and benched; open: README ⚠, v1 helpfile, 8 ms gate. See `G-hatch`.

Closed 2026-10-30/31: the `render_dim` migration (all tensor modules, vorticity, quasi, grain, seeds; `f_masonry` and `f_cmap` stay exempt) and the `f_vf_advect` Trail rework.

## Next (Claude's lean; Matt decides)

1. Fix the contract-bench harness for `render_dim` modules, then re-run it. First run (2026-10-31) failed only on bypass frame shape for `f_grain`, `f_tf_aniso_blur`, `f_tf_glyph`, `f_vf_vorticity`; options A/B/C in HANDOFF.
2. Check `f_stipple`, `f_weave`, `f_vf_flow` for the `f_quasi` "draws nothing unconnected" bug.
3. Close Hatch.
4. Tier-3 tuning of `f_ks` and `f_wave_field`: both are built and benched; tuning and docs/registration remain.
5. Packaging (`G-packaging`): the biggest strategic gap; no tag, icon or install test yet.

## Owed to Matt

- **Runs and looks:** the contract bench re-run after the harness fix (Max, Vsynth paused); live check of the three render-trigger suspects; `f_ks` T030 and `f_wave_field` T030 tuning looks (`.specify/f_ks/tasks.md`, `.specify/f_wave_field/tasks.md`); the regenerated `f_modules` dropdowns; the new and corrected helpfiles (Axis Flow, Caustic notes); `f_caustic` demo-patch chain-cost check (untouched since 2026-10-08).
- **Decisions:** contract-harness fix for bypass shape under `render_dim` (HANDOFF options A/B/C); Hatch T051 and T061; cap the `f_vf_advect` Trail dial near 50-100 (one-line change), yes or no.
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
