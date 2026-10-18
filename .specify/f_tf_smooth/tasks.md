# Tasks: f_tf_smooth

**Spec**: `.specify/f_tf_smooth/spec.md`
**Plan**: `.specify/f_tf_smooth/plan.md`
**Brief**: `ideas/f_tf_build_brief.md` §4 (promoted candidate), §5 (chain A first stage)
**Build order**: Sequential by phase. Phases 0 and 1 are BLOCKING.
**Commits**: After each phase checkpoint.
**Test discipline**: run the one affected test, `-q`, in the background via `tests/bg.sh`;
never rerun the bench to re-verify your own change; **ask before any bench run**.

---

## Expected Output Layout

```
.specify/f_tf_smooth/
  spec.md  plan.md  tasks.md      — this triad
  codebox_state.gen               — Phase 1
  codebox_render.gen              — Phase 1 (may fold into state; decide at T008)
  definition.py                   — Phase 3

tests/
  test_tf_smooth.py               — Phase 0, tier-1 mirror
  bench_tf_smooth.py              — Phase 1, tier-2

~/Vsynth/patterns/tf_smooth_scratch.maxpat   — Phase 2 (not committed)

docs/f-reference/f_tf_smooth.md  — Phase 5
```

---

## Phase 0: Gates + NumPy mirror (BLOCKING) — COMPLETE 2026-10-17 (12/12, `tests/run.sh tests/test_tf_smooth.py`)

- [x] T001 **DECISION GATE: verification tiers.** Confirmed as written in plan ADR-5: tier 1 applies (one-pole recurrence has closed-form ground truth), tier 2 applies (feedback round-trip on the real GPU; bench written, run pending Matt), tier 3 applies (`release` default/ceiling is a feel judgement).
- [x] T002 **(done 2026-10-17)** Write `tests/test_tf_smooth.py` — per-channel one-pole mirror over (H,W,4) float32 frames; pure array arithmetic, no gpu_sim texture reads needed (recurrence only). Mirror is `smooth_step`/`run_sequence`; encoding helpers per `f_tensor_type.md` out0.
- [x] T003 **(done: worst abs error 3.8e-6 over release {0, 0.3, 0.5, 0.9, 0.99}, k<=50; tol 1e-5)** Ground truth, decay theorem: closed form `out(k) = B + (A-B)*release^k` checked against float32 powers (not the recurrence). Includes release-0 exact passthrough and unbounded-value decay (Jxx=4.0 in; ADR-3 no-clamp proven numerically).
- [x] T004 **(done: alternating theta / theta+180 deg frames give bitwise-constant output; decoded axis preserved 0 rad)** Invariant, line-field stability — encoding-continuity check; catches accidental decode/atan2.
- [x] T005 **(done: opposite-sign flicker leaves the output exactly the input tensor (drift 0) while the vecfield one-pole control on the same alternation drops to 0.42 of |v| (25%); crossed-camp 90-degree alternation settles to the analytic period-2 blend (2/3 own camp + 1/3 other) with full preserved trace; hot/cold half-frame test: zero pixels fall below min input coherence)** Invariant, opposite-axis reinforcement — the tensor-native row as numbers.
- [x] T006 **(done: unconnected zero-tensor input decays a dirty history geometrically to neutral (1.8e-10 after 40 frames at release 0.5); bypass = bitwise-exact passthrough every frame; channels independent bitwise)** Neutral checks.
- [x] T007 **(done: sign-flip err 6.8, swapped-weights err 3.0, clamped-feedback err 2.7 — all caught by the decay-theorem check; the clamp bug is invisible on 0-1 content and caught on unbounded content (first-step err 1.5 at Jxx=4), which is why ADR-3 is a test)** Mutation check once.
- [x] T008 **(done 2026-10-17: 12/12 pass; measured errors inline above; run direct — fast, bg.sh unneeded)** Run `tests/run.sh tests/test_tf_smooth.py -q`; results recorded.

**Checkpoint:** recurrence proven; invariants encoded; mutation caught. → Proceed to Phase 1.

## Phase 1: Codeboxes on the bench (BLOCKING)

**Status:** mirror-verified; bench pending (parent-owned bench run); codeboxes at src/f_tf_smooth/.

**Purpose:** the actual risk item — unbounded float32 fed back across a frame boundary.

⚠️ Do not begin Phase 2 until this checkpoint is confirmed. **Ask before the bench run.**

- [x] T009 **Read precedents:** done 2026-10-17: f_vf_advect (src/f_vf_advect/definition.py, state/pass two-domain with pix_wires loop) + f_vf_optical_flow (outlet_source_override/raw_lines pattern) + f_lens read; codeboxes live in src/f_tf_smooth/ per built-patcher layout, see plan ADR-6.
- [x] T010 Write `codebox_state.gen`: done — src/f_tf_smooth/codebox_state.gen; Param release(0.5)/bypass_gate(0.0); one-pole mix blend (no-clamp per ADR-3).
- [x] T011 Write `codebox_render.gen` done — src/f_tf_smooth/codebox_render.gen passthrough (separate render node kept, per ADR-2).
- [x] T012 **Bench: frame-boundary round-trip.** *[BENCHED 2026-10-17 (M3 Max), ask-approved:
  6/6 pass and re-confirmed in the final 5-file sweep. The bench file's original per-step-input
  tests were wrong (E4's run_temporal has NO per-step input swap — bench.js loadInputs runs
  once per job) and were rewritten to chained run_temporal jobs with the state carried
  between; module correctness confirmed: out == A·r + B·(1−r) to float32-exact per job pair;
  release 0 identity 0.0; values above 1.0 survive the state write+read unclamped (the ADR-3
  proof); bypass is passthrough across chained dirty-state jobs (not a freeze); render chain
  = state output.]* Two consecutive bench frames: frame 1 feeds tensor A (e.g. Jxx=4.0
  unbounded), frame 2 feeds tensor B ≈ 0; assert frame 2's output is `A·release` exactly
  (not a re-clamped or re-sampled value). This is the ADR-3 proof. **Ask before the bench run.**
- [x] T013 *[BENCHED 2026-10-17, folded into T012's rewritten tests: the recurrence-vs-mirror
  sweep over 5 alternating input frames runs as one chained run_temporal per input; release
  0.0 identity 0.0 on the GPU; 0.3/0.5/0.9 vs mirror ≤ 1e-6 measured; cost model (one
  feedback tap, two taps/pass) recorded — smooth sits at the single-pass floor like glyph's
  2.39 ms upper bound; final confirm 6/6.]* Bench the full recurrence against the mirror
  over 5 frames of alternating input (`all_outputs=True`): error ≈ 1e-7 tolerance; confirm
  release 0 is exact passthrough on the GPU. **Ask before the bench run.**
- [x] T014 Register `tests/bench_tf_smooth.py` in `tests/benchdeps.DATA` (template:
  `tests/templates/bench_module_template.py`); not in `bench.sh` DEFAULT until Matt calls
  it a regression gate. done — registration line required is
  `"bench_tf_smooth": _MACHINERY + ["src/f_tf_smooth/codebox_*.gen"],` in tests/benchdeps.py DATA (parent owns shared files; recorded in .specify/f_tf_smooth/REGISTRATION_NOTES.md); bench file written from tests/templates/bench_module_template.py, not in bench.sh DEFAULT.

**Checkpoint:** feedback proven on the GPU, including unbounded values. → Proceed to
Phase 2.

---

## Phase 2: Scratch patch, judgement tier

**Purpose:** `release`'s dial is a feel question.

- [ ] T015 Build `~/Vsynth/patterns/tf_smooth_scratch.maxpat`: tensormap → smooth → decode
  preview (the glyph's Phase 0 decode preview can be reused, or scratch's own).
- [ ] T016 **DECISION GATE: `release` default and ceiling.** Live noise in; check 0
  (instant), 0.3/0.5/0.7/0.9/0.99. Record Matt's pick; update spec Parameters. Same
  discipline as tensormap T027.
- [ ] T017 Confirm the anti-flicker claim on real video-ish content: a jittery edge's
  decoded axis visibly stabilizes under moderate release; a vecfield one-pole control
  (hand-wired, scratch-only) visibly mushes under the same input. This is tier 3 evidence
  for the spec's tensor-native row.

**Checkpoint:** release locked; stabilizer claim demonstrated live. → Proceed to Phase 3.

---

## Phase 3: definition.py and build

- [x] T018 **(done 2026-10-17: f_vf_optical_flow's definition.py — outlet_source_override + raw_lines for "real output node ≠ primary"; f_vf_advect's two-node pix_chain + pix_wires loop; f_lens precedent noted. Codeboxes live in src/f_tf_smooth/ per built-patcher layout — plan ADR-6.)** Read `.specify/f_vf_optical_flow/definition.py` and `.specify/stable/f_lens/definition.py` for two-node pix_chain wiring, outlet sourcing, param fan (T028 discipline from tensormap). Record where codebox files live for this module's layout.
- [x] T019 **(done 2026-10-17: src/f_tf_smooth/definition.py — two-node pix_chain [state primary with codebox_state.gen, render support with codebox_render.gen], pix_wires [state→render, render→state-in2 feedback], bypass_mode "param" targeting the primary state pix [ADR-4 passthrough, not freeze], single outlet carrying the raw tensor via outlet_source_override {0: "render"} + raw_lines, signal_type "tensor out" amber, params release [0-1, default 0.5 PROVISIONAL] + bypass.)** Write `definition.py`.
- [x] T020 **(done 2026-10-17: invocation `python3 build/build_patcher.py src/f_tf_smooth/definition.py` from repo root [tensormap T032 path confirmed]; → package/patchers/f_tf_smooth.maxpat; JSON-validated VALID.)** Build; validate the JSON.
- [ ] T021 Register in the modules menu [PENDING parent registration — exact line in REGISTRATION_NOTES.md Utilities section]: `src/f_modules/menu.py` → `build/generate_menu.py`; README row (⚠ Unverified); category is a taste call.
- [x] T022 **(done 2026-10-17: f_tf_smooth reproduces from its definition with ZERO drift problems via test_drift's own `problems(current()['f_tf_smooth'], None)` → []; not in the baseline. Pre-existing unrelated failures remain: f_masonry baseline shrink, f_tf_glyph/f_tf_sharpen missing src definitions, f_vf_advect hand edit.)** Drift check (`tests/test_drift.py`).
- [ ] T023 Contract tests offline (`tests/test_module_contracts.py`); add BYPASS_EXPECT
  entry (passthrough semantics). Bench registration per T014; **ask before any bench run**.
  [Offline part done 2026-10-17: f_tf_smooth-specific analysis is CLEAN — pix params release+bypass_gate both driven, none unused, route_map {release: [release]}, no default_mismatch, no port gaps, bypass reaches the primary. Full-suite check is blocked by PRE-EXISTING failures from sibling modules (f_tf_glyph undriven width/height; also f_vf_advect, f_masonry) — not this module's. BYPASS_EXPECT line still pending parent (REGISTRATION_NOTES.md, bench_modules.py section).]
- [ ] T024 Close and reopen in Max; load in a Vsynth session; confirm panel, params,
  neutrals (unconnected decays to zero tensor; bypass is exact passthrough). Matt's call.

**Checkpoint:** loads, drift-clean, contracts green, neutrals confirmed. → Phase 4.

---

## Phase 4: Integration check

- [ ] T025 Wire tensormap → smooth → glyph (if glyph's patcher exists by then) or smooth →
  the Phase 2 decode preview; confirm jittery input → stable field is visible in a real
  chain, not just scratch. Interim honest gap to record if neither consumer is ready:
  smooth's output format is identical to its input format, so f_tf_tensormap → smooth →
  (decode preview) is the demonstration wiring until glyph builds.

## Phase 5: Docs and handoff

- [ ] T026 `docs/f-reference/f_tf_smooth.md`: params, signal chain, the release-gesture
  description, ADR-3's NaN-persistence caveat, bypass-passthrough (not freeze) note.
- [ ] T027 Update `docs/f-reference/module-inventory.md`, README status table, HANDOFF.
- [ ] T028 Update `ideas/f_tf_build_brief.md` chain A to point at the built module.
- [ ] T029 Commit. Suggested split: spec/plan/tasks; tests + codeboxes; patcher +
  registration; docs. Plain messages.

---

## Dependencies & Execution Order

- Phase 0 → 1 → 2 → 3 → 4 → 5, strictly sequential.
- T009 blocks T010 (state-pix wiring follows the advect precedent read).
- T012 and T013 both block T015. T012/T013 are bench runs: **ask first**.
- T016 blocks T019 (locked release goes into definition.py).
- No parallel work with other f_tf modules: bench time is scarce, and this module is first
  in the confirmed build order — after it ships, glyph/sharpen/aniso_blur/hatch can build
  against a real consumer-side precedent.

## Notes

- Stateless-in, stateful-out: the only temporal module in the family so far whose *output
  type equals its input type* — that property is what makes it chain-safe anywhere.
- Never introduce decode/atan2 here; the raw encoding passes through untouched
  (T004 guards this).
- Cost should be negligible (one feedback tap; no loops); measure once at T013 and record,
  per tensormap T016 discipline — but do not optimize without evidence.
- No Anthropic API anywhere in this task list.