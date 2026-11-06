# f_vf_flow — tasks

_Created by the 2026-10-12 maintenance pass: the module shipped and
graduated to docs/, but its bypass behavior is completely unasserted
(archetype "dual" means the implicit out1==in1 processor check never
applies, and no BYPASS_EXPECT entry exists — unlike sibling generator
f_chladni, which has explicit const entries for exactly this shape).
Ids start at T001._

- [x] T001 (2026-11-06: the module was on native `@bypass`, so the neutral below never ran; moved to `bypass_gate`, entry added, live bench 2/2, log `tests/logs/20261106-081412-bench.log`; live by Matt 2026-11-06: bypass gives a neutral field): Add a `1: ("const", (0.5, 0.5, 0.5, 1.0), 0.0)`-style
  BYPASS_EXPECT entry for f_vf_flow in tests/contracts/bench_modules.py,
  mirroring the f_chladni generator-neutral pattern. The module's
  bypass mixes to the neutral vecfield (correct per family convention)
  — it just has never been asserted anywhere. First live run
  validates.

- [x] T002 (decided 2026-10-19, Matt): tier 1 skipped. Angle-to-unit-vector trig, a few lines, no iteration. (Constitution rule for pre-convention modules, "Verification Tiers".)

- [x] T003 (decided 2026-11-01, Matt): f_vf_flow needs a texture; no unconnected rendering (no gated `r draw`, no size handling). Re-typed `processor` (was `dual`): `vs_inState`, `src_mode` and the unconnected codebox path removed. Render-trigger check closed for this module. Doc and descriptions updated (README, Launch, help, make_missing_helpfiles.py digest; 2026-11-01).

- [x] T004 Stable preflight (2026-11-06, offline by Claude), record below.
- [x] T005 Matt's helpfile look PASSED 2026-11-06 ("helpfile looks pass"): the new demo chain at defaults, the digest, the two notes. Moved to `.specify/stable/`.

## Stable preflight (2026-11-06)

Part 1 offline by Claude: drift ok, no baseline entry; menu and launcher `--check` up to date; README row 102 chars, no ⚠; menu entry under ∇ Fields, recipe Ngon Flow (`f_demo_ngon` wires Flow to Advect inlet 1 and Prism inlet 1, read from the patcher); bypass is `bypass_gate` (`bypass_mode: "param"`, neutral vecfield in `BYPASS_EXPECT`; `bench_modules.py` 2/2 in `tests/logs/20261106-081412-bench.log`, from before these edits, which touch no patcher or codebox); helpfile box 167.5x91 against a footprint of 150x81 (the dials reach y 81; the Angle label starts at x -7.5). The route is `angle spread`, no `bypass` selector, and the helpfile has no `bypass [0 / 1]` line, which is right. No gate row holds Flow. Tests: no mirror (T002, skip decided by Matt) and no `bench_*` file of its own, only the contract bench. No `spec.md` or `plan.md`.

Patcher against docs: one inlet (texture / control), one outlet. No `vs_inState`, no `vs_black`, no `r draw`, so only the incoming texture triggers the pix; the doc now says so. The bypass toggle goes jsui -> `prepend param bypass_gate`; dials go through attrui, not `prepend param` as the doc said.

Fixed: `module-inventory.md` still had the pre-2026-11-01 row (optional inlet, uniform field when unconnected), and `ideas/optics_map.md` used Flow unconnected. Every doc said luminance, but the codebox reads `.x`, the red channel, so a colored texture steers by red alone (code read, not run); doc, inventory, README and `definition.py`'s docstring corrected. The docstring also still fed `f_weave`'s retired vecfield inlet. Bench inputs for this module are the patcher and codebox, so that edit does not mark it stale (`tests/lib/benchdeps.py`; drift still ok). `build/make_missing_helpfiles.py` had the old digest and recipe. The doc's bypass row now says toggle only and `bypass_gate`, and the doc notes the field is full strength everywhere, which is what separates Flow from Fieldmap.

Chains in `library-characteristics.md`: `vs_wfg_3` -> Flow takes a texture, and Flow's vecfield goes to Streak and Prism inlet 1 (`vs_wfg_3`'s output range was not checked). Both chains left out the source on inlet 0; added. Chain 2 was wrong by meaning: Flow has no gate and no luma pass, it is unit length everywhere, `src_vecfield` is only Prism's connection flag, and Prism's own gate passes bright source, not mid-luma. Rewritten as a texture-steered prism. `f_vf_fluid.md`'s "uniform `f_vf_flow`" still holds at `spread` 0 with a texture connected.

Helpfile: confirmed nothing was wired upstream, so the demo drew nothing. Added `vs_sources_main` -> Flow -> preview and moved the module and preview down. Expected at defaults (from the codebox, not seen): mid gray pink (1, .5, .5), dark toward purple, bright toward green, no gray. `vs_sources_main` opens on the Movie tab, so this depends on a movie being loaded. The note no longer names a consumer; a second sits beside the preview. Neither overlaps the preview (rects: preview 338-574 x 281-530; notes 525-760 x 170-242 and 590-780 x 281-379). The digest now says what the module is for. `test_generate_menu.py` 17/17 (`tests/logs/20261106-094613-offline.log`; passed again after the JSON format was restored, `tests/logs/20261106-094623-offline.log`). Live by Matt: T005.

Left alone: `codebox_flow.gen`'s comment says luminance (changing it would touch a bench input). `build/make_missing_helpfiles.py`'s `f_weave` entry still says to feed Flow into in2; `package/help/f_weave.maxhelp` does not name Flow, and that is Weave's record. `skills/vsynth-bpatcher/SKILL.md` lists Flow as a producer, which is still true of its output.

## Moved to stable/ (2026-11-06)

Matt's helpfile look passed, so the module moved. The folder holds only this file: no scripts, no `parents[N]` or `../` paths, and `definition.py` has no `Spec:` line, so nothing needed changing there. The doc's path to this folder was updated. `tests/build/test_gates.py` not yet run after the move (needs Matt's go).
