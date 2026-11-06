# f_vf_potential — tasks

_Created by the 2026-10-12 maintenance pass: the module shipped and
graduated to docs/, but the audit found two gaps — an unasserted bypass
behavior and a tensor-consumer fact that closes a filed open question.
Ids start at T001._

- [x] T001 (2026-11-06: the module was on native `@bypass`, so the neutral below never ran; moved to `bypass_gate`, entry added, live bench 2/2, log `tests/logs/20261106-081412-bench.log`; live by Matt 2026-11-06: black when bypassed): Add a BYPASS_EXPECT entry (or NEUTRAL_BYPASS_BY_DESIGN
  listing) for f_vf_potential in tests/contracts/bench_modules.py. The module
  declares archetype "processor" but its bypass outputs the neutral
  (0,0,0,1), not input passthrough — the implicit out1==in1 check
  shouldn't silently pass or silently skip; one line makes the
  behavior asserted. First live run validates it (the same pattern
  f_chladni's generator-neutral entries use).
- [x] T002 (2026-11-06, Claude: superseded, no edit. `ideas/f_tensorfield.md` already lists potential as sign-sensitive and excluded, confirmed 2026-10-16, and that is right: the increment is magnitude-only but the backward-advect lookup depends on direction, so "axis-blind" below is wrong): Fold the OQ11 answer into ideas/f_tensorfield.md's
  consumer audit table: f_vf_potential integrates field *magnitude*
  (codebox_potential.gen:20 — `field_mag = sqrt(fx*fx + fy*fy)`, line
  27 accumulates it), so it is axis-blind: a 180°-flipped field
  produces identical output. The table's current "assumed excluded"
  framing is wrong; it belongs on the affected list. (Code read
  settles the open question; only the doc row needs updating.)

- [x] T003 **Tier-1 NumPy mirror (omp run mirror-build-3, landed 2026-10-20).** `tests/modules/vf_potential/{vf_potential_mirror,test_vf_potential}.py`, 16/16 offline. Checks: the geometric series and fixed point for a uniform field, zero-field decay, bypass, clamp, advection, the strength/tint feedback closed form, and the direction of `decay` from the doc's own words (added 2026-10-20 after the planted-doc control for this module was missed by the author and the verifier). See `HANDOFF.md` 2026-10-20.

- [x] T004 Stable preflight (2026-11-06, offline by Claude), record below.
- [x] T005 Matt's helpfile look PASSED 2026-11-06 ("Look passes, move it"): the new demo chain at defaults, the digest, the two notes. Moved to `.specify/stable/`. He did not say whether bypass clears the trail, so that stays in `plan.md` Owed to Matt.

## Stable preflight (2026-11-06)

Part 1 offline by Claude: drift ok, no baseline entry; menu and launcher `--check` up to date; README row 110 chars or under, no ⚠; menu entry under Adapters, no recipe; bypass is `bypass_gate` (`bypass_mode: "param"`, black in `BYPASS_EXPECT`; `bench_modules.py` 2/2 in `tests/logs/20261106-081412-bench.log`, before these edits, which touch no module code); helpfile box 207.5x110 against a footprint of 190x100. The route is `dt decay strength`, no `bypass` selector, and the helpfile has no `bypass [0 / 1]` line, which is right. No gate row holds Potential. Tests: mirror in `tests/modules/vf_potential/`, 17 test functions counted (T003 says 16/16; not run). No `bench_*` file of its own, only the contract bench. There is no `spec.md` or `plan.md` for this module, only this file, so no `Spec:` path applies.

Fixed: the docs had the inlets wrong. The patcher has three: 0 texture / control, 1 vecfield, 2 color. The codebox never reads `in1`, so inlet 0 only triggers the frame, and the reference doc, `module-inventory.md` and the chains all read as if the vecfield went to inlet 0, where it would be ignored (wiring and codebox read; the behavior is inferred, not run). The helpfile's References said axis-blind, which T002 had already corrected. `strength` was documented as output scale only, and the color inlet as not affecting the accumulation; the loop reads the scaled, tinted output (mirror's closed form), so `strength` above about 1/`decay` runs to the clamp and red tint shortens the memory (worked from the recurrence, not run). Also: bypass row, a uniform field gives no isolines, stale status text and source path.

Chains in `library-characteristics.md`: every field into Potential is a vecfield (`f_vf_vortex`, `f_vf_vortex_multi`, `f_vf_fluid`, `f_vf_lbm`, `f_vf_repulse`, `f_vf_advect` out 2), and every consumer takes a texture (`f_weave` across, `f_sirds` depth, `f_stipple`, `f_lens` mod), from the docs, not run. All of them need the inlet wiring above, so the section now says so. The `f_modules` pattern claimed that chain is pre-wired by the menu; `menu.py` has no such recipe. Fixed.

Helpfile: nothing was wired upstream, so the demo showed nothing. Added `vs_sources_main` -> `f_vf_repulse` -> Potential inlets 0 and 1 -> preview, the doc's own typical chain, and moved the module and preview down. Expected at defaults (from the codebox, not seen): steady level is about half the field magnitude. `vs_sources_main` opens on the Movie tab. The note is rewritten beside the module, with a second beside the preview. Neither overlaps the preview (rects: preview 338-574 x 411-660; notes 560-780 x 281-353 and 590-780 x 411-509). The digest now says what the module is for. `test_generate_menu.py` 17/17 after the edit (`tests/logs/20261106-093622-offline.log`). Live by Matt: T005.

Left alone: `definition.py`'s docstring calls the previous frame `in3` (it is `in4`) and says the vecfield is read from `in2` without naming the inlet; changing it may mark the bench stale, as with Axis Flow. `skills/vsynth-bpatcher/SKILL.md` lists Potential among modules that re-emit a vecfield (needs Matt's re-upload). `docs/f-reference/f_weave.md` still says `src_potential` is shipped; `src/f_weave/definition.py` has no such name, and that is Weave's record.

## Moved to stable/ (2026-11-06)

Matt's helpfile look passed, so the module moved. The folder holds only this file: no scripts, no `parents[N]` or `../` paths, and `definition.py` has no `Spec:` line, so nothing needed changing. Drift still ok. `tests/build/test_gates.py` not run: it needs Matt's go. Decision, Matt 2026-11-06: "vecfields don't go in on 0, they go in on 1", so the inlets stay as they are.
