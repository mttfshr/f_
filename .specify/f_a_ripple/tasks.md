# f_a_ripple — tasks

_Created by the 2026-10-12 maintenance pass: the folder had only
spec.md + plan.md — the plan's Phase 4 "not yet done" and Phase 5
"not started" had no task-level tracking record. Ids start at T001._

- [ ] T001: Fix the modulated-band loop bounds (spec.md Primary Risk's
  "honest fix"): compute n_lo..n_hi from band edges + f0 instead of running all
  200 harmonics with gated accumulation. Measured non-blocking (DSP
  CPU% ~33% flat, 2026-09-15) — code hygiene, not a perf emergency.
- [ ] T002: Phase 4/5 leftovers per plan.md: live.dial UI grid per f_
  conventions (shipped maxpat currently uses plain flonums), and the
  Phase 5 docs/helpfile (no .maxhelp exists). Also close the one
  unchecked spec acceptance box: perceptual comparison against
  checkhearing.org at matched settings.
## Audio archetype, Phase A (added 2026-11-16)

Source: `build/spec.md` "Audio archetypes" (signed off by Matt 2026-11-16), decisions of record in
`G-audio` (`.specify/gates.md`). Phase A = the shared audio shell + the `audio_gen` archetype,
proven by rebuilding this module from `src/f_a_ripple/definition.py`. Out of scope here: `pfft~`,
fragment splicing, `f_a_purr`, menu / launcher / `f_addmod` registration (Phase D), helpfile.
**Status: Phase A BUILT 2026-11-16 (Claude), Matt's go on the task list and on Q1-Q4 as proposed; Max checks owed (T013).**
Facts below were read this session from the files named (not run).

Starting point (read, not run): the shipped `package/patchers/f_a_ripple.maxpat` is the v1 prototype:
`gen~` (`obj-300`, 3 outlets: audio, `render_count`, `f0_h`) holding one codebox with 14 `Param`s;
14 `flonum`/`toggle` controls, each into `prepend <name>` into gen~ inlet 0; a `loadbang` fan of
14 messages that sets the defaults; test rigs (`scope~`, `spectroscope~`, 2 `snapshot~`, `metro`,
`dac~ 1 2`); no panel, title, presentation rect or `autopattr`. `src/f_a_ripple/` does not exist.

- [x] T003: Extract the codebox verbatim to `src/f_a_ripple/codebox.gen` (from the gen~ subpatcher box
  inside `obj-300`) with a `README.md` in the style of `src/f_a_purr/README.md` (source, date, length,
  sha256 prefix). No DSP edits in this task. Check: the extracted text equals the shipped codebox byte
  for byte.
- [x] T004: Codebox edits for the module, kept to the minimum and listed in the README: (a) add
  `Param bypass_gate(0.0)` and a click-free mute on `out1` (the generator's bypass is silence; a short
  one-pole slew on the gate, about 5 ms, so toggling does not click: not heard, Matt's listen);
  (b) drop `out2` / `out3` (diagnostics, see Q1); (c) `output_level` default per Q2. The DSP (T001's
  loop bounds included) is NOT touched.
- [x] T005: Builder: `build_audio(defn, side_files)` as a separate branch, entered early in `build()`
  when `defn["archetype"]` starts with `audio_` (the texture path stays byte-identical: the drift
  baseline and `test_drift.py` are the check). Shell parts per the spec: `inlet~` (only when
  `audio_in`), `outlet~`, `gen~` with the codebox in a `dsp.gen` subpatcher (`in`/`out` boxes, as in the
  shipped patch), one `prepend <name>` per param into gen~ inlet 0, `live.dial` / `live.numbox` /
  `live.menu` grid reusing the existing param box makers (`dial_box`, `numbox_box`, `menu_box`,
  `label_box`), panel, title, `autopattr`, optional gain / mix / `tanh~` stage (off for
  `f_a_ripple`: its codebox already ends in `tanh`, ADR-6). Ids per the spec: `obj-1` inlet~, `obj-2`
  outlet~, `obj-3` core, shell ids from `obj-6`; each param `obj-300+n*10` as in the texture scheme.
  `check_port_order()` runs at the end. Presentation rect and per-instance-safe naming follow the
  texture modules' bpatcher convention (to be confirmed against `dial_box` when written).
- [x] T006: Defaults without a `loadbang` fan: each control carries its default (`initial` /
  `parameter_initial`), as the texture modules do, so the 14 default messages of the prototype go
  away. Check: the built gen~ receives the same 14 default values (offline test, T008).
- [x] T007: `src/f_a_ripple/definition.py`: `archetype: "audio_gen"`, `core: "gen"`, `audio_in: False`,
  `codebox` from `codebox.gen`, the 14 params with the ranges in `spec.md` (Targeting / Modulation /
  Carrier; `band` 1-7 int, `mod_type` and `hearing_profile` as menus, `carrier_phase` not added: the
  codebox has no such Param), `bypass_gate`, and a panel size chosen from the dial grid (7 columns by 2
  rows plus the title strip is the first proposal; the real numbers come out of the Edit-View Layout
  constants when built).
- [x] T008: Offline test `tests/build/test_build_audio.py`: every definition with an `audio_*`
  archetype builds; the result is valid JSON that round-trips; every param reaches the core (a
  `prepend <name>` into gen~ inlet 0, plus a matching `Param <name>(...)` in the codebox, no orphan
  either way); defaults in the controls equal the codebox's `Param` defaults; ids unique; port order
  valid; the texture-only keys (`route`, `routepass`, `jit.gl.pix`, `vs_inState`) are absent. Mutants:
  a param dropped from the wiring, a renamed Param, a duplicate id (the test must fail on each).
  Run with `-q` only after Matt's go.
- [x] T009: Build `package/patchers/f_a_ripple.maxpat` from the definition
  (`build/py.sh build/build_patcher.py src/f_a_ripple/definition.py`). The hand-built prototype is in
  git history (and the external `/Users/matt/Vsynth/patterns/f_a_ripple_v1.maxpat`); it is replaced, not
  kept beside it.
- [x] T010: Standalone test patch (outside the module): the removed rigs, wrapped around a bpatcher
  instance of `f_a_ripple` (`scope~`, `spectroscope~`, `dac~`), at `tests/rigs/f_a_ripple_rig.maxpat`
  (hand-authored bpatcher-composition JSON, allowed by the `vsynth-bpatcher` skill; location is Q3).
  Not run in Max by Claude.
- [x] T011: Drift baseline: remove the `f_a_ripple` `out_of_scope` entry from
  `tests/build/drift_baseline.json` (the module must reproduce exactly, `status: ok`; it does not join
  the `drift` list). The `f_a_decorrelate` and `f_chladni_audio` entries stay (Phase C / not ours).
  `build/drift.py`'s `build_module` must dispatch to `build_audio` (it calls `bp.build`, so the
  dispatch lives in `build()`; verify rather than assume). Run `test_drift.py -q` and the other offline
  tests that scan `src/*/definition.py` (layout, conventions, render_dim, gates) with Matt's go, to see
  whether an audio definition breaks any of their assumptions.
- [x] T012: Records: this file, `HANDOFF.md` START HERE (**In progress** line: audio archetypes, Phase
  A state, next step B), `G-audio` row (state only; the gate stays Waiting until Phase D), `spec.md`
  checkboxes for T002's UI-grid half (the helpfile and the checkhearing.org comparison stay open), and
  `build/spec.md` "Audio archetypes" status line. One commit.
- [ ] T013 (owed to Matt, Max, not claimed by Claude): open the rebuilt patcher; listen at defaults
  (ripple heard, level sane); toggle bypass while it plays and listen for clicks; confirm the dial
  grid and panel look right; drop two instances in a patch and check they do not interfere; confirm the
  save-in-Max round trip changes nothing (`drift.py`).

### Decided 2026-11-16 (Matt: "Go, as proposed")

1. **Output channels (spec.md Q1c).** Proposal: one `outlet~`, mono. The prototype's `dac~ 1 2` was a
   test rig and its gen~ has one audio signal. `out2` / `out3` (`render_count`, `f0_h`) were
   diagnostics for the retrigger check and go (T004b); stereo would be a wider claim than the DSP makes.
2. **Output level default.** The prototype ships `output_level` = 0 (silent) as a safety. A module that
   is silent when dropped in reads as broken, and the spec's "ripple sound at defaults" implies audible.
   Proposal: rename it `gain` (the library's canonical name) with default 0.1 and a tighter range, the
   `tanh` ceiling stays after it. Reverse if you want silence-by-default kept.
3. **Test-rig location.** `tests/rigs/` (new) vs `package/examples/` (ships in the package). Proposal:
   `tests/rigs/`, since a rig is not an example for users.
4. **Message inlet.** Texture modules take param messages at their one inlet. A generator with no
   `inlet~` would have no inlet at all in Phase A (dials, presets via `autopattr`, nothing scriptable by
   message). Proposal: none in Phase A; a control inlet is a Phase D / later item once the menu path is
   known. Say if you want it now.

### Phase A record (2026-11-16, Claude, offline)

- Built: `build_audio()` in `build/build_patcher.py` (dispatched from `build()` on an `audio_*` archetype); `src/f_a_ripple/{codebox.gen,README.md,definition.py}`; `package/patchers/f_a_ripple.maxpat` rebuilt (49 boxes, 31 lines); `tests/rigs/f_a_ripple_rig.maxpat`; `tests/build/test_build_audio.py`.
- Run: `test_build_audio.py` 5/5 (`tests/logs/20261116-233026-offline.log`), `test_drift.py` 16/16 after removing the `f_a_ripple` baseline entry (`20261116-233036-offline.log`), `drift.py f_a_ripple`: ok. Sweep run with Matt's go (`tests/logs/20261116-233136-offline.log`): conventions 40/40, render_dim 13/13; layout 11/12, the one failure is the known `f_vf_erode` overlap (HANDOFF, fails on a clean tree; audio definitions add none); gates failed 4/5 because of my own G-audio wording (a path beside the ids made the parser resolve T026/T028/T123 against f_a_ripple), reworded, now 5/5 (`20261116-233142-offline.log`). T011 closed.
- Deviations from the spec, all inferred-safe but unchecked in Max: (1) the edit-view layout pass (`build/layout.py`) is not used by the audio branch (its roles are texture objects); `patching_rect` is a plain row layout. (2) The ports are `inlet~` / `outlet~` newobjs (as in the shipped `f_a_decorrelate`), so `check_port_order()` does not apply. (3) Controls carry no `param_connect` (that names a `jit.gl.pix`); values travel by `prepend`. (4) `band` is an Int live.numbox (`parameter_type` 1), the other numeric controls are dials, `mod_type` / `hearing_profile` are live.menu. (5) Bypass is a live.text toggle "Bypass" in the title bar into `prepend bypass_gate`, a generator's bypass being a ~5 ms slewed mute. (6) `tmr` dial has exponent 3 (my choice, 0.1-256 Hz; change freely). (7) `T001` (loop bounds) untouched. (8) `spec.md`'s `carrier_phase` has no Param in the codebox and so no control.
- Not done / owed: T013 (Max: open, listen at defaults, bypass clicks, panel look, two instances, save round trip); the helpfile; menu / `f_addmod` size / launcher (Phase D).

### Correction 2026-11-16 (Phase D session, Matt's report: "none of the audio modules have inlets or outlets")

Phases A-C wrote the ports as `newobj` boxes with text `inlet~` / `outlet~`. **Max has no such objects**: a patcher's ports are `inlet` / `outlet` objects, which carry signals too. The three audio patchers therefore had no ports at all (they would show a missing-object box), and my tests passed because they checked for those same wrong boxes (inferred from the report and Max's object set, not opened in Max by me). Also, Phase A dropped the control-message inlet (Q4, "none in Phase A"); Matt wants control messages in. Fixed in `build_audio()`: ports are `inlet` / `outlet` objects (`check_port_order()` now applies); every module has a control inlet feeding `route bypass <params>` into each control (a generator: inlet 0; a processor: the audio inlet 0 and a control inlet 1, so a signal is never fanned out to a route or to `pfft~` as messages); the tests now fail on an `inlet~` / `outlet~` newobj, a missing route or a dropped route cord. The Phase A/B/C records above that call the ports `inlet~` / `outlet~` newobjs are superseded by this note. All three patchers rebuilt, `drift.py` ok, `test_build_audio.py` 8/8; not opened in Max.
