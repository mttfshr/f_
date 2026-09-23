# Tasks: Test Bench Extensions (E3 → E1 → E2 → E4)

**Roadmap**: `.specify/test_bench/extensions.md`
**v1**: `.specify/test_bench/{spec,plan,tasks}.md` (implemented)
**Order**: E3 first (Matt, 2026-09-22), then E1, E2, E4. **All done 2026-09-22.**

---

## E3 — Module contract tests

Design (from discovery, 2026-09-22):
- **Static layer (offline):** parse each shipped `package/patchers/f_*.maxpat`,
  follow cords `route` outlet → (dial/numbox) → `attrui` → target object;
  check every `attrui` attribute is a `Param` declared in the target pix's
  codebox; map which pix objects the bypass jsui reaches.
- **Live layer:** a separate module bench, `tests/bench/bench_module.maxpat`
  (ports 7473/7474), containing Vsynth's real `vs_render` bpatcher (the
  `vsynth` context, `draw`/`dim`/`vs_black`) — separate from the codebox bench
  because it creates a global `vsynth` context (Vsynth performance patches
  must be closed while it runs). Modules are loaded per job via a generated
  wrapper patch (module as bpatcher, wired to `receive bench_minN` /
  `send bench_moutN`), swapped into a cordless slot with
  `script sendbox bench_mslot replace <wrapper>` — so no cords can be deleted
  by varying inlet/outlet counts. `bench_module.js` drives inputs with
  `messnamed`, sends control messages, reads inner pix attributes back, and
  triggers bypass both via the documented `bypass 1` control message and via
  the bypass jsui (`msg_int`).

- [x] T101 Static contract checker `tests/module_contract.py` + offline suite
  `tests/test_module_contracts.py` over every shipped module; known issues
  reported as XFAIL with a pointer, not silently skipped.
  Done: 32 modules checked, 0 unexpected. **Real bugs found:** `f_vf_fieldmap` and `f_vf_repulse` Gain dial → `attrui strength`, codebox has `Param gain` (dial does nothing — same class as the old `mix_amt` bug); `f_masonry` route `brick_seed` drives the course_seed numbox and route `course_seed` is unconnected; `f_masonry` `quantize` is a dead control (Param removed 2026-07-05, UI left). Self-check proves the checker catches the original `mix_amt` bug.
- [x] T102 Module bench patch generator + `bench_module.js` (load wrapper,
  drive inputs, capture all outlets). **Matt:** close Vsynth performance
  patches first.
  Done: `make_module_bench.py`, `bench_module.js`, `modulebench.py`. As built: `vs_render` controlled via `[r bench_vsctl]` cord (js `message()` to a bpatcher hits its patcher object, not its inlet); in js a loaded bpatcher's maxclass is `patcher` — module found by varname; slot swapped to empty first, then the wrapper a frame later (`replace` creates before it frees → fixed-`@name` pix collide: "ob3d does not allow multiple bindings"); char outputs scaled 1/255 in `jxf.read_rgba`; control messages one per frame. Added `/probe` and a localhost-only `/eval` debugging hook (`modulebench.bench_eval`).
- [x] T103 **DECISION GATE:** does `replace` via scripting work from js, and
  does it leave the bench patch dirty (→ save prompt on reopen)? Record.
  **DECIDED:** scripted `replace` works from js and leaves the bench clean — `reopen()` closes without a save prompt (verified by screenshot).
- [x] T104 Client support (ports per bench, `run_module_job`), smoke test on
  one module (loads clean, every outlet produces a frame).
  Done: `benchclient` ports per bench (`CODEBOX_PORTS` 7471/7472, `MODULE_PORTS` 7473/7474); `modulebench.run_module()`.
- [x] T105 Live param contract: every route name, sent as a control message,
  lands on its `attrui` target attribute (read back from the inner pix).
  Done. **Finding:** loading ~30 modules into one bench session scrambled other modules' dial `_parameter_range` (e.g. Streak `length` saved 0–20, ran at [-1, 1]) — nondeterministic readbacks traced to that; a fresh session per module gives exact readbacks everywhere. Mechanism NOT investigated (Matt: don't sink time into it); `range_tiers` modules suspected; could matter in a real Vsynth patch with several f_ modules. Bench now reopens per module.
- [x] T106 Live bypass contract: documented `bypass 1` control message vs
  jsui `msg_int 1`; which pix objects end up bypassed; processor out1 ==
  in1 under bypass.
  Done. **Finding:** the documented `bypass 1` control message (vsynth-bpatcher skill, Control Message Convention) works in 9 modules and does nothing in 23 — essentially every build-system module (`route` has no `bypass`). jsui bypass works everywhere; processors pass through exactly except `f_lens` (known) and `f_sirds` (new, uninvestigated). Multi-pix modules leave feedback/intermediate pix unbypassed (advect/potential pass pix, optical_flow, seeds) with correct out1 where checkable.
- [x] T107 Run across all modules; triage findings (real bugs vs test
  assumptions); record.
  Done: `tests/bench_modules.py` 2/2 (32 modules, ~77 s). Other new findings, all XFAIL with notes: `hue_range.js` bad outlet index; `autopattr @varname` invalid in Max 9 (masonry/mobius/stereo); `f_vf_fieldmap` pix declares invalid `@boundmode`. Environment noise excluded: `jpatcher: doesn't understand getattr` from modules' own `getattr presentation_rect` (whether Vsynth shows it too: unverified).

## E1 — Multiple outputs
- [x] T111 **DECISION GATE:** unwired `out N` in a gen patcher keeps the outlet?
  **ANSWERED:** yes -- an unwired `out N` compiles, keeps its outlet, and emits an all-zero texture. So bench gens carry `out 1..4` (`make_genjit(min_outputs=4)`), like inputs.

- [x] T112 `make_genjit(min_outputs=4)`, 4 capture taps, `run_pass` returns
  all outputs; self-test with a 3-output probe codebox.
  Done: 4 capture taps on slot 1 (`bench_out`, `bench_out2..4`); `run_pass(all_outputs=True)` returns `[out1..out4]`. Self-test `test_5_multiple_outputs` (3-output codebox exact; unused out4 zeros).


## E2 — char textures
- [x] T121 **DECISION GATE:** char readback lands on exact k/255?
  **ANSWERED:** char quantization is round-to-nearest with clamping to [0, 1] (exact match; floor differs by 1/255).

- [x] T122 Job `type: char`; self-test vs `gpu_sim.store_char`.
  Done: `run_pass(pix_type="char")`; char outputs read back scaled k/255. Self-test `test_6_char_quantization`.


## E4 — Temporal / feedback runs
- [x] T131 **DECISION GATE:** frame-exact stepping method.
  **ANSWERED:** counting draw bangs is frame-exact when js acts at the start of a frame (the draw bang precedes the textures): step s renders on frame S0+s-1, no skips or doubles -- exact counter `init + s/64` passes up to s=20.

- [x] T132 Feedback path (out K → identity pass → in J, one-frame delay) +
  time-series capture; self-test against a NumPy-stepped accumulator.
  Done: `switch 4` picks the feedback outlet -> `bench_fb` identity pix -> `gate 2` into slot 1 in2/in3 (non-left inlets store without rendering -> one-frame delay). `run_temporal(code, inputs, steps, feedback=(out, in))`; consecutive-step captures supported. `tests/bench_temporal.py` 4/4: step counter, closed-form decay accumulator, out2->in3 routing, char feedback re-quantizing each step.
