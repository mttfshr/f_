# Tasks: f_tf_tensormap

**Spec**: `.specify/f_tf_tensormap/spec.md`
**Plan**: `.specify/f_tf_tensormap/plan.md`
**Hub**: `ideas/f_tensorfield.md`
**Build order**: Sequential by phase. Phases 0 and 1 are BLOCKING.
**Commits**: After each phase checkpoint.
**Test discipline** (ways-of-working, stated with frustration twice): run the one affected test, `-q`, in the background with `tests/bg.sh`; never rerun the bench to re-verify your own change; **ask before any bench run**. Tier-1 (NumPy) runs are cheap and need no ask.

---

## Expected Output Layout

```
.specify/f_tf_tensormap/
  spec.md  plan.md  tasks.md      — done
  codebox_stage_a.gen             — Phase 1
  codebox_stage_b_h.gen           — Phase 1
  codebox_stage_b_v.gen           — Phase 1
  codebox_stage_c.gen             — Phase 1
  definition.py                   — Phase 3
  (final home of the codebox files follows f_vf_optical_flow's layout; see T028)

tests/
  test_tf_tensormap.py            — Phase 0, tier-1 mirror
  bench_tf_tensormap.py           — Phase 1, tier-2
  spike_tf_tensormap_cost.py      — Phase 1, only if T016 needs its own file

~/Vsynth/patterns/tf_tensormap_scratch.maxpat   — Phase 2 (not committed)

docs/f-reference/f_tf_tensormap.md, f_tensor_type.md   — Phase 5
```

---

## Phase 0: Gates + NumPy mirror (BLOCKING)

**Purpose:** Settle the math against independent ground truth before any codebox exists, and record the naming decision that gates file creation (made: T002).

⚠️ Do not begin Phase 1 until this checkpoint is confirmed.

- [ ] T001 **DECISION GATE: verification tiers (constitution).** Recorded in plan.md ADR-8: tier 1 applies (closed-form eigen + angle recovery have independent ground truth), tier 2 applies (four codeboxes, a border question, a cost question), tier 3 applies (`strength`/`radius` defaults, visual character of B/A). Confirm or amend; nothing skipped.
- [x] T002 **DECISION GATE (Matt): module name and prefix.** **Decided 2026-10-16: `f_tf_tensormap`.** `tf` is the family prefix in use (parallel to `vf`); module prefix `tensormap`, object name `tensormap_pix`, following `f_vf_fieldmap`. Recorded in spec.md Clarifications. Still to do: the constitution's naming table needs an `f_tf_` entry (T042).
- [x] T003 Create `tests/test_tf_tensormap.py`; write the stage A mirror: Rec. 601 luma, the verified 3x3 Sobel from `.specify/stable/f_vf_sobel/spec.md`, outputs `(gx*gx, gx*gy, gy*gy)`. Sample through `gpu_sim.sample`/`nearest`, not array slicing (tests/README convention).
- [x] T004 Stage B mirror: separable box sum (horizontal then vertical) written as the codebox's bounded loop would run, with weight gating `step(abs(i), radius)` and normalization by the actual tap count. Parameterized on `R_MAX` so T017 can change it.
- [x] T005 Stage C mirror: trace, closed-form eigenvalues, `coherence = root/trace` guarded below `eps_trace`, `theta = 0.5*atan2(2*Jxy, diff)`, both outlet encodings per the spec, neutral R=G=0.5 and A=0 at degenerate pixels. `eps_trace` is a named constant to be set in T019.
- [x] T006 Ground truth, eigen: on random symmetric 2x2 tensors (include diagonal-only, repeated-eigenvalue and near-zero cases) the mirror's `lambda1`, `lambda2` and recovered axis match `np.linalg.eigh` (axis compared mod pi). Print measured errors via `harness.check`.
- [x] T007 Ground truth, direction: for a synthetic linear ramp at known angles phi in [0, pi) the recovered `theta` equals phi (mod pi, taking the across-edge convention explicitly), and `(cos 2theta, sin 2theta)` matches NumPy `arctan2` to ~1e-6.
- [x] T008 **(completed 2026-10-16, 18/18 pass)** Invariants from the spec's acceptance criteria: flat input gives the exact zero tensor and neutral outlets; edge trace is 16.0 at radius 0, contrast 1.0, and scales as contrast squared; **coherence is the same at contrast 0.1 and 1.0**; rotating the input by pi leaves outlet 1 unchanged; rotating by 90 degrees negates `(cos 2theta, sin 2theta)`.
- [x] T009 Cross-check the pass mirror against the independent vectorized implementation in `tests/spike_structure_tensor_range.py` (`structure_tensor` + `eigen`): trace, Jxy and coherence agree on the spike's flat / edge / noise content at radii 0, 1, 3, 6. The two were written separately, so agreement is evidence; disagreement means find out which is wrong.
- [x] T010 Mutation-check once (tests/README): inject a plausible bug (swap Jxy sign; drop the `4*` under the root; use raw lambda1-lambda2 for A) and confirm a test fails.
- [x] T011 Run `tests/run.sh tests/test_tf_tensormap.py -q` once in the background; record the measured errors in this file's notes. **Result 2026-10-16: 15/15 pass; errors ~1e-6 (stages A/B vs spike, eigh match, ramp angle 1.4e-6 rad); Jxy sign-flip mutation caught.**

**Checkpoint:** Mirror agrees with `np.linalg.eigh`, the known-angle ramp, and the spike implementation; one injected bug is caught; name decided. → Proceed to Phase 1.

---

## Phase 1: Codeboxes on the bench (BLOCKING)

**Purpose:** Real codeboxes, one stage at a time, each diffed against its mirror on the GPU. Settle the one real unknown: what the smoothing costs.

⚠️ Do not begin Phase 2 until this checkpoint is confirmed. Multi-stage modules are benched stage by stage (tests/README); one pass per job.

- [x] T012 *[LIVE FINDING 2026-10-16 (probe patch ~/Vsynth/patterns/tf_probe.maxpat): `dim` reads 1 inside live Vsynth jit.gl.pix (dim probe blue; `cell` = norm*(dim-1) black), regardless of @type/@adapt; `norm` and UV-offset taps work. Stages A/B now take Params texel (=1/width) and aspect (=w/h) instead of 1/dim; bench file passes them; bench needs a re-run once Max has bench.maxpat open. Module must expose/derive texel. Bench passed earlier because the bench sets dim] [benched 2026-10-16: matches mirror incl. borders. FINDING: bench GPU WRAPS out-of-range coords (not clamp); codebox now clamps to texel centres in-shader, so behaviour no longer depends on texture wrap (ADR-5 outcome; spec one-liner still to add)]* Write `codebox_stage_a.gen` (`@type float32`; 8 neighbor samples, luma, outputs `gx*gx` / `gx*gy` / `gy*gy` raw, no clamp, no offset). Bench against the stage A mirror, including a signed `gx*gy` case. **Check the border rows and columns explicitly** against the mirror (plan ADR-5); if the GPU wraps instead of clamping, the mirror follows the GPU and the spec gets a one-line note.
- [x] T013 *[written, benched]* Write `codebox_stage_b_h.gen`: horizontal bounded-loop box sum of the three products, provisional `R_MAX` = 16, per-tap weight `step(abs(i), radius)`, normalized by tap count. Keep the statement count well under the ~450 capture ceiling (`skills/jit-gen-codebox`); if it compiles but every later job returns the same stale image, the bench is wedged: `benchclient.reopen()`.
- [x] T014 *[written, benched]* Write `codebox_stage_b_v.gen` (same, vertical, reads stage B_h's output).
- [x] T015 *[benched 2026-10-16 at radius 0,1,3,6,16 incl. borders; radius 0 is exact identity]* Bench B_h then B_v against the mirror at radius 0, 1, 3, 6 and `R_MAX`; check the normalization at radius 0 (must be an identity pass) and at the borders.
- [x] T016 *[DONE 2026-10-16 (M3 Max; M1 unmeasured). Per pass, R_MAX 8/16 at 1080p: under ~0.9 ms (upper bound, CPU-bound); R_MAX 32: ~1.9 ms (GPU-bound). At R_MAX 16, radius 16 (worst case), every stage incl. A and C reads ~0.86-0.91 ms at 1080p and ~3.3-3.4 ms at 4K, all upper bounds equal across stages, i.e. the bench frame floor, not real GPU cost. Chain bound: <=3.5 ms at 1080p, <=13.4 ms at 4K (sum of upper bounds, an overestimate). Real cost is below this; resolving it needs GPU-bound measurement (e.g. larger chain)]* **Cost measurement** (`bc.measure`, tests/bench_perf.py precedent): per stage and for the 4-stage chain, at 1080p and 4K, for `R_MAX` in {8, 16, 32}. Report ms per pass only where `gpu_bound`, otherwise the upper bound, and say these are **M3 Max numbers and the M1 is unmeasured**. Compare against recorded costs of comparable modules (`f_vf_glow`, `f_vf_optical_flow`) rather than inventing a budget. The bounded loop is decided (Matt, 2026-10-16); if it looks too expensive the response is a smaller `R_MAX`, not a different algorithm.
- [x] T017 **DECIDED (Matt, 2026-10-16): `R_MAX` = 16, radius in pixels (spike convention), range 0-16; cost scales with R_MAX not live radius.** **DECISION GATE: `R_MAX` and radius units (plan ADR-3).** The bounded loop is decided (Matt, 2026-10-16). From T016 pick `R_MAX`, which sets the top of the `radius` range, and decide units (pixels per the spike vs normalized UV). Record the cost fact that **cost scales with `R_MAX`, not the live `radius`**.
- [x] T018 *[written; benched. Added: R,G neutral where root<eps (GPU atan2(0,0) differs from NumPy); mirror updated. Native-@bypass hazard: codebox bypass mix is untestable on the bench, covered at module level in Phase 3]* Write `codebox_stage_c.gen`: apply `strength`, trace, `root`, coherence (guarded), `theta`, both outlet encodings, neutral at degenerate pixels, `Param bypass` neutral output on both outlets.
- [x] T019 **DECIDED (Matt, 2026-10-16): eps_trace = 1e-6** *[measured 2026-10-16 (NumPy): flat input trace is exactly 0 (float32 noise floor = 0, also for flat RGB through luma); smallest real signal, a 1-LSB step edge, peaks at trace 2.9e-5 (radius 16) to 2.5e-4 (radius 0). Recommendation: keep eps_trace = 1e-6 (29x below a 1-LSB edge at max radius). Awaiting Matt's confirm + visual seam check on noise in Phase 2]* **DECISION GATE: `eps_trace` (plan ADR-6).** Set it from the mirror's float32 noise floor on flat and low-contrast content (a flat input gives exactly 0); confirm no visible one-pixel seam on noise content at the boundary. Update the mirror constant and stage C to match.
- [x] T020 *[benched 2026-10-16: both outlets match mirror ~1e-7 incl. branch-cut pixels; strength 0 ok; iso neutral ok]* Bench stage C against the mirror on both outputs (`all_outputs=True`): outlet 0 and outlet 1 channel by channel; isotropic pixels give R=G=0.5 and A=0; a pixel exactly on the atan2 branch cut behaves (the +pi/-pi difference is benign after angle-doubling, but verify rather than argue); `strength` = 0 and bypass behave per the spec.
- [x] T021 *[bench file written + registered; 7/7 pass 2026-10-16]* Assemble `tests/bench_tf_tensormap.py` from `tests/templates/bench_module_template.py`, pointing `CODEBOX` at the real files; register it in `tests/benchdeps.DATA` (a test enforces this). Do **not** add it to `DEFAULT` in `tests/bench.sh` until Matt says it is a regression gate.

**Checkpoint:** Every stage compiles and matches its mirror on the GPU; borders confirmed; cost recorded with the M1 caveat; radius implementation and `eps_trace` decided. → Proceed to Phase 2.

---

## Phase 2: Scratch patch, judgement tier

**Purpose:** The things numbers can't judge: gain, range, and whether B and A mean what the hub doc hopes on real content.

- [x] T022 *[LIVE-VERIFIED 2026-10-16 after the texel/aspect fix: on a square wave RAW, B, A, outlet 1 and DIR all show crisp lines at the edges; DIR is cyan (x-axis, hue 0.5) as expected. Still to judge on real content: T023-T026] [built 2026-10-16 by ~/Vsynth/patterns/_build_tf_tensormap_scratch.py (re-runnable; reads the real codeboxes). Preview codeboxes compile on the bench. Patch not yet opened in Max: structure checked only (26 boxes, 18 lines, no dup/dangling ids)]* Build `~/Vsynth/patterns/tf_tensormap_scratch.maxpat`: `jit.gl.bfg` into the four stages, previews for both outlets' channels (via `f_vf_split` / simple remap taps, preview-only).
- [x] T023 **(done 2026-10-16: Matt approved strength 100 and 300 on smooth noise; measured scaling puts the useful range at 1-1000, log; default 100)** Calibrate `strength` on bfg Perlin, Voronoi and fbm. `f_vf_fieldmap` needed 4.0 for Perlin but 0.08 for fbm, so check whether the provisional 0-30 range reaches both ends; confirm the spike's ~12 default puts typical-content B into 0.5-1.0.
- [x] T024 **(2026-10-16: Matt: radius 3 is a good default; HD-vs-4K comparison not done, noted as the texel/aspect question)** Feel `radius` across its range; compare HD against 4K at the same dial value (a pixel radius means a different physical size at each resolution) and note what Matt would want: a pixel radius, or one that tracks the render size.
- [x] T025 **(closed by Matt 2026-10-16: A and B on live noise look right; use A together with B, noted for the docs)** **Coherence on real content (plan ADR-2).** Look at A and B together. Confirm A is the contrast-independent trust signal the hub's Q12 gate wants, that it is noisy where B is tiny, and that near-isotropic dark points still land on direction singularities as the spike showed.
- [x] T026 **(closed by Matt 2026-10-16: DIR hue map follows visible structure; singularities show as dark specks, as the spike predicted)** Throwaway decode preview: half-angle `atan2` on outlet 1's R/G drawn as a direction map, to confirm it follows visible structure. Preview only, not a module.
- [x] T027 **(LOCKED 2026-10-16, Matt: strength log 1-1000 default 100; radius 0-16 default 3; `texel` and `aspect` EXPOSED as parameters for now, not derived from render size)** **DECISION GATE: lock `strength` and `radius` range and default.** Update spec.md Parameters and close Open Questions 2 and 3 with the measured values.

**Checkpoint:** Defaults confirmed on real content; spec's provisional values replaced. → Proceed to Phase 3.

---

## Phase 3: definition.py and build

**Purpose:** Assemble the confirmed stages into a real `pix_chain` bpatcher.

- [x] T028 **(read 2026-10-16: used f_vf_optical_flow as the pattern; ids derived by hand and noted in definition.py)** **Read, don't assume:** `.specify/f_vf_optical_flow/definition.py` and `.specify/stable/f_lens/definition.py` for `pix_chain` / `pix_wires`, `outlet_source_override` + `raw_lines`, and how a param reaches a node that is not the primary. This module needs the source wired to stage A while both outlets come from stage C, and `radius` fanned to both blur stages. Also record where the codebox files actually live.
- [x] T029 **DECISION GATE (Matt): outlet order** (spec OQ6). **Decided 2026-10-16: raw tensor on outlet 0, packed convenience on outlet 1.** Recorded in spec Clarifications.
- [x] T030 **(DECIDED 2026-10-16 (Matt): header signal_type "tensor out" with a new amber `tensor` colour in SIGNAL_TYPE_COLORS (build_patcher.py, one line); each outlet gets its own comment, colour and hint so raw and angle-doubled never look alike)** **DECISION GATE: `signal_type` for the outlets** (spec OQ5). Check how `build_patcher.py` uses `signal_type` and whether non-vecfield outlets can carry their own tag, or stay untyped for now. Record the choice and why; the point of the rejected-alternative is that two encodings must not look identical.
- [x] T031 **(written 2026-10-16; params strength (log, exponent 4, 1-1000, 100), radius (0-16, 3), width, height (exposed, numbox), bypass; build_patcher.py gained an optional per-param `exponent` -> parameter_exponent, so no other module changes)** Write `definition.py`: `pix_chain` of stage_a / stage_b_h / stage_b_v / stage_c, `driving_inlet`, two outlets per T029/T030, params `strength` / `radius` / `bypass` per the locked values, `Param bypass` neutral on both outlets.
- [x] T032 **(built 2026-10-16: package/patchers/f_tf_tensormap.maxpat; ids/lines verified; width/height replace the earlier texel/aspect Params)** Run `python3 build/build_patcher.py src/f_tf_tensormap/definition.py` from `/Users/matt/Github/f_/`; validate the JSON: `python3 -c "import json; json.load(open('...')); print('VALID')"`.
- [x] T033 **(done 2026-10-16: tools/ scripts no longer exist; used src/f_modules/menu.py -> build/generate_menu.py; placed in Utilities, vecfield False, not in the nabla groups; README row added (⚠ Unverified); build/generate_launch.py regenerated; test_launch 8/8. Category is a taste call, easy to move)** Register in the modules menu: `tools/rebuild_modules_menu.py`, then `tools/append_nabla_menu.py`.
- [x] T034 **(2026-10-16: f_tf_tensormap reproduces from definition.py; the only drift failure is f_vf_advect, which has uncommitted hand edits of Matt's unrelated to this work)** Drift check: the new patcher reproduces from `definition.py` with no baseline additions (`tests/test_drift.py`; the baseline list only shrinks).
- [x] T035 **(done 2026-10-16: offline + bench. Bypass is bypass_mode "param" (bypass_gate on stage_c only); BYPASS_EXPECT + NEUTRAL/PARTIAL_BYPASS_BY_DESIGN entries; contract 9/9, bench_expect 10/10; tests/bench_tf_tensormap.py 8/8 on the bench (width/height + bypass_gate checks; stages declare only the Params they use); bench_modules shows f_tf_tensormap clean (bypass-leaves-active=4, by design). bench_modules overall FAILs on 4 f_a_decorrelate errors (inlet~/outlet~/expr in a non-audio bench), not from this module.)** Contract tests: offline `tests/test_module_contracts.py`; add the module to `tests/bench_modules.py`'s `BYPASS_EXPECT` table (both outlets neutral at bypass). Run in the background; **ask before the bench run**.
- [x] T036 **(2026-10-16: Matt: pass, live)** Close and reopen in Max (open patches never auto-update), load in a Vsynth session: panel visible, params addressable, unconnected inlet and bypass give the zero-tensor neutral on both outlets.

**Checkpoint:** Patcher loads, drift-clean, contract tests green, neutral behavior confirmed. → Proceed to Phase 4.

---

## Phase 4: Integration check without a consumer

**Purpose:** There is no consumer yet. Prove the outlets are usable.

- [x] T037 **(2026-10-16: Matt: pass, live. Note: the screenshot showed VF Split fed from Axis Flow, not tensormap outlet 1, so the cos2t/sin2t reading itself was not seen; the chain was verified live via axisflow, advect and split.)** Wire outlet 1 into `f_vf_split` (bipolar mode); confirm `cos(2theta)` and `sin(2theta)` appear as two scalar textures with no `atan2` involved (hub audit table, `f_vf_split` row).
- [x] T038 **(2026-10-16: Matt: pass, live)** Rotate the test input by 90 degrees; confirm the doubled components negate. Confirm outlet 0's Jxy sign flips under a mirror flip. Three-patch chain `jit.gl.bfg -> f_tf_tensormap -> f_vf_split` is the working demo.

**Checkpoint:** Both outlets confirmed meaningful on real content in a real chain. → Proceed to Phase 5.

---

## Phase 5: Docs and handoff

**Purpose:** Promote from spec to working everywhere, and unblock the first consumer.

- [x] T039 **(2026-10-16)** Write `docs/f-reference/f_tf_tensormap.md`: param table, signal chain, calibration table by input type (from T023), the A-is-coherence note and its noisy-at-low-B caveat.
- [x] T040 **(2026-10-16)** Write `docs/f-reference/f_tensor_type.md`, the encoding contract and sibling of `f_vecfield_type.md`: outlet 0 and outlet 1 channel layouts, the 0.5-zero convention for signed channels, why angle-doubled, and the decode rule consumers must follow (and which consumers must never receive outlet 1's R/G, per the hub's exclusion list).
- [~] T041 **(2026-10-16: helpfile generated, mechanical preflight green; judgment gate is Matt: open in Max)** Helpfile via the `f-helpfile` skill, then the `skills/module-preflight/` checklist and its **content judgment gate** (the sizing fix alone didn't cover content; `f_sirds`, `f_vf_vorticity`, `f_vf_glow` failed it).
- [x] T042 **(2026-10-16: constitution naming entry + Current Bpatchers rows, module-inventory rows; README row done earlier)** Update `README.md` (status table, build queue), `docs/f-reference/module-inventory.md`, and the constitution (Current Bpatchers; naming-convention entry for the family prefix if T002 settled one).
- [x] T043 **(2026-10-16: hub updated; glow Q12 tasks T039-T043 in .specify/f_vf_glow/tasks.md, with the .w channel correction)** Update `ideas/f_tensorfield.md`: producer built, Phase 2's blocker cleared. Add the `f_vf_glow` anisotropy-inlet work (hub Q12 design) as tasks in `.specify/f_vf_glow/tasks.md` so the first consumer has a place to start.
- [x] T044 **(2026-10-16)** Update `HANDOFF.md` (short; task-level detail lives here).
- [ ] T045 Commit. Suggested split: spec/plan/tasks; tests and codeboxes; patcher and registration; docs. Plain message style per the repo's recent history.

**Checkpoint:** Docs written, README updated, git clean.

---

## Dependencies & Execution Order

- Phase 0 -> 1 -> 2 -> 3 -> 4 -> 5, strictly sequential.
- T002 (name) is decided, so T012 is unblocked.
- **T017 (radius) blocks T018** only for the radius-related stage C inputs; stage C's own math doesn't depend on it, so T018 may start once T015 passes if the gate is still open.
- **T019 (`eps_trace`) blocks T020.**
- **T030 blocks T031** (T029, outlet order, is decided).
- T023-T025 inform T027; T027 blocks T031 (the locked values go in `definition.py`).
- No parallel work: each phase's output is the next phase's input, and bench time is scarce.

---

## Notes

- This is a stateless chain: no previous-frame pass pix, unlike `f_vf_optical_flow`.
- Internal textures are float32 and unbounded by design (plan ADR-4); never expose them as outlets.
- **No consumer is in this task list.** `f_vf_glow`'s anisotropy inlet (hub Q12) is blocked on this module and is added to `f_vf_glow/tasks.md` in T043, not built here.
- `radius` cost scales with `R_MAX`, not the dial value (plan ADR-3). Turning it down does not buy back frame time; say so in the docs.
- The A channel is **coherence**, not raw lambda1-lambda2 (plan ADR-2). If a later session reads the hub doc's shorthand and "fixes" it back, point them at spec Clarifications 2026-10-16.
- `f_vecfield` is not the type of either outlet. Consumers must decode; sign-sensitive consumers must not receive outlet 1's R/G (hub "Explicit exclusion list").
- Hard constraint: no script in this task list calls the Anthropic API.
- Total tasks: 45
