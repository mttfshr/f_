# Tasks: f_tf_hatch

**Spec**: `.specify/f_tf_hatch/spec.md`
**Plan**: `.specify/f_tf_hatch/plan.md`
**Triage**: `ideas/f_tf_triage.md` (review outcome 2026-10-17; hatch = fifth in the
confirmed build order, Phase-0 gate = cost shape OQ1)
**Build order**: Sequential by phase. Phase 0 is BLOCKING; its FIRST task is the
cost-shape decision gate, its SECOND the verification-tier gate.
**Commits**: After each phase checkpoint.
**Test discipline** (ways-of-working, same as the tensormap tasks header): run the one
affected test, `-q`, in the background via `tests/run.sh` / `tests/bg.sh`; never rerun
the bench to re-verify your own change; **ask before any bench run**. Tier-1 (NumPy)
runs are cheap and need no ask.

---

## Expected Output Layout

```
.specify/f_tf_hatch/
  spec.md  plan.md  tasks.md      — done (docs only; no code yet)
  codebox_stage_e1.gen            — Phase 1 (branch-independent decode+commit)
  codebox_stage_e2_T.gen          — Phase 1 (branch T per T001: tileable distance field)
  codebox_stage_e3.gen            — Phase 1 (render/compose/encode)
  definition.py                   — Phase 5 (built without a live bench)
  spike/                          — T001 renders (.pgm/.png), not committed code
    (branch S's files — codebox_stage_e2_S_p1/p2.gen — DELETED at the T001
     gate, never stubbed)

tests/
  spike_tf_hatch_costshape.py     — Phase 0 T001, the OQ1 gate (NumPy spike both branches)
  test_tf_hatch.py                — Phase 0, tier-1 mirror
  bench_tf_hatch.py               — Phase 1, tier-2 (WRITTEN, registered, never executed
                                   in this build — parent constraint)

~/Vsynth/patterns/tf_hatch_scratch.maxpat   — Phase 4 (pending Matt; not committed)

docs/f-reference/f_tf_hatch.md   — Phase 6
```

Where codebox files live (`src/f_tf_hatch/`) follows the tensormap convention
(`.specify/<name>/definition.py` referencing `src/<name>/codebox_*.gen`); confirm while
reading the precedents in Phase 5 (T031), not by assumption.

---

## Phase 0: Cost-shape gate → tier gate → NumPy mirror (BLOCKING)

**Purpose:** Decide the ONE genuinely open architectural question (OQ1) with numbers
before anything else, record which verification tiers apply and why, then settle the
math against independent ground truth before any codebox exists.

⚠️ Do not begin Phase 1 until BOTH gates are recorded. T001 precedes T002 by design:
the branch choice changes what tier 2 would even measure.

- [x] T001 **DECISION GATE (FIRST): cost shape — stroke-marching (S) vs tileable
      distance-field pattern (T).** **DECIDED 2026-10-17: branch T.** NumPy spike
      `tests/spike_tf_hatch_costshape.py` implemented BOTH branches on three synthetic
      fields (concentric rings, iso blob, authored waves). Cost model: T = 3 passes,
      0 loops, ~6 taps/pixel, ~85 statements → ≤2.7 ms at 1080p against tensormap's
      ~0.9 ms/pass floor; S = ≥5 passes, 75-90 taps/pixel, loop-carried march state,
      the architectural sign/branch-cut problem → ≥4.5 ms. Branch T's hairpin hazard
      measured (ridge-err sweep 24.9→64.0 deg over ring spacing 8→64, monotone;
      conservative-metric baseline ~44-49 deg even on a straight dashed render;
      rendered proof `.specify/f_tf_hatch/spike/spike_curved_edge_branchT.png`); S's
      stroke-identity advantages are out of v1 scope. Recorded as plan ADR-1
      AMENDMENT; the S files deleted from both layouts (never stubbed); gate
      PROVISIONAL-CLOSED with the tier-2 bench (T013/T016) as the declared resolver.
      Spike strictly NumPy-only (no bench, no codebox before the gate).
- [x] T002 **DECISION GATE (SECOND): verification tiers (constitution).** **Recorded
      2026-10-17 in plan ADR-6 (record block):** tier 0 ran first (the spike);
      tier 1 applies (analytic + eigh ground truth for decode/commit/pattern math);
      tier 2 applies but is WRITTEN-NOT-RUN in this build's scope (registered;
      parent constraint); tier 3 applies, pending Matt. Nothing skipped. **Tone
      sub-decision (OQ2, decided here so E3 is designable): tone stays OUT of v1**
      — the spike's evidence (one more `norm` tap is cheap, but the tone-gating
      look is a live judgement, and density-band layering is a second mark system
      = out-of-v1 cross-hatch scope) plus the build's no-live-session constraint;
      recorded PROVISIONAL in ADR-6 with inlet-1-luma as the v2 pointer, spec
      inlet-1 row decline carried in REGISTRATION_NOTES.md.
- [x] T003 **(done 2026-10-17: E1 mirror written in tests/test_tf_hatch.py -- decode copied VERBATIM from glyph plan ADR-2 (including the tan(2*theta) gain-free identity comment and the theta+180 symmetry caveat), coherence normalized, eps_trace = 1e-6 cited from tensormap ADR-6/T019; eigh cross-check on 300 random SPD tensors incl. diagonal-only and near-iso cases: lambda err <=4.8e-7, axis err (mod pi) <=3.6e-7)** Create `tests/test_tf_hatch.py`; write the E1 mirror: decode from a raw
      tensor sample by copying the canonical idiom verbatim from
      `.specify/f_tf_glyph/plan.md` ADR-2 (decode per `f_tensor_type.md` outlet 0,
      closed-form eigen, `theta = 0.5*atan2(2*Jxy, diff)` gradient axis,
      along-axis = theta + π/2); coherence normalized per tensormap ADR-2; eps-guard
      starting at `eps_trace = 1e-6` (tensormap ADR-6/T019, decided) — re-validate the
      value for this decode path in the T007 invariants rather than re-deriving.
      Cross-check λ1/λ2/axis against
      `np.linalg.eigh` on random symmetric tensors (incl. diagonal-only,
      repeated-eigenvalue, near-zero cases), axis mod π — the tensormap mirror's ground
      -truth method (its T006), reused.
- [x] T004 **(done 2026-10-17: commit_curve() with named knees C_LO/C_HI and switchable form (smoothstep/linear); all acceptance invariants asserted: 0 at/below gate (<=1e-7), 1 at coherence 1, monotone, bounded in [0,1]; gate-boundary continuity asserted against the analytic max slope (1.5/(C_HI-C_LO)*dcoh), <=3.2e-2 measured <=3.2e-2 bound)** Commit-curve mirror (the tensor-native core): `commit` from coherence with
      the provisional curve (smoothstep knees C_LO/C_HI); assert the acceptance
      invariants numerically — commit 0 at/below `coherence_gate`, commit 1 at
      coherence 1, monotone non-decreasing on a coherence sweep, continuous across the
      gate boundary (no seam on an authored isotropic→anisotropic gradient field).
      Keep the curve parameterized (OQ3): the knee constants are named, the direct
      vs ratio-response form switchable, so T005's sweep can inform the gate without
      rewriting the mirror.
- [x] T005 **(done 2026-10-17: both forms measured over uniform/bimodal/noise-tailed eigengap distributions; recorded as mean-commit/activation-coverage numbers in test output, e.g. uniform: mean commit 0.42, frac>0.5 0.38; bimodal: 0.49/0.50; noise-tailed: 0.52/0.49; the smoothstep form's low-gap suppression (deeper off below the gate) carried the best structure/noise separation and stays the provisional choice, with tier-3 (T020) holding the live decision; OQ3 remains open)** Commit-curve sweep (feeds OQ3): sweep the curve form over synthetic
      eigengap distributions (uniform, bimodal, noise-tailed) and report which form
      separates structure from noise best at fixed gate; record findings in the
      tasks-notes and hold the decision for the tier-3 judgement (T020) — do not close
      OQ3 in NumPy alone.
- [x] T006 **(done 2026-10-17, branch T per T001: f_weave mechanics adapted to the per-pixel axis, cited verbatim where reused -- density log map `pow(2, density*5-1)`, line hash `fract(sin(line_idx*127.1)*43758.5453)*(1-regularity)`, smoothstep profile with softness clamped 0.49; phase scroll verified (0.02 -> ~1.4 px shift at defaults, pitch-normalized), regularity endpoints verified (1 phase-locked across lines, 0 staggered, hash stable call-to-call), softness verified (widens both axes, coverage +>30%))** Family-mechanics mirrors (branch-conditional on the T001 pick):
      branch T — the `f_weave` distance-field algorithm adapted to a per-pixel rotated
      frame (`docs/f-reference/f_weave.md` Algorithm, cited verbatim where reused:
      density log map, `dist_to_line`, `dist_to_mark`, smoothstep profile, regularity
      hash); branch S — the seed/march pattern (hash-grid cells, march accumulation
      with `MARCH_MAX` weight gating per tensormap ADR-3's idiom). Either way:
      `phase` scroll, `regularity` stagger, `softness` feather per
      `docs/f-reference/discrete_item_conventions.md`.
- [x] T007 **(done 2026-10-17: all asserted in tests/test_tf_hatch.py -- zero tensor + tensormap neutral render exactly black both outlets; ramp axis vs analytic mod pi (worst 1.5e-7 rad on 45-deg fixture; render-level ridge checks at 64-px frame quantization floor ~10 deg, sub-degree checks carried by the axis-MAP tests); commit endpoints by the formula invariant (al/(aw*ds) = aspect, cap formula to 0.01, dot aspect 1e-5, commit 0 renders nothing); contrast independence (identical renders at contrast 0.1/1.0, <=1e-5); strength invariance (100 vs 30/500 renders, <=1e-4); 90-deg rotation equivariance (axis map 2.4e-7, render <=2e-3); angle_offset +-1 exact-rotated layouts (<=9e-6) -- eps_trace=1e-6 re-validated for this path: a 1-LSB edge trace ~3.9e-3 survives the guard at 1e-6)** Invariants from the spec's acceptance criteria: zero tensor ⇒ black both
      outlets; axis correctness on a known-angle synthetic field (φ+90° strokes, ~1e-6
      rad); commit endpoints (aspect = elongation+1 at commit 1, exactly 1 at commit 0
      regardless of the `elongation` dial); contrast independence (same edge at 0.1
      and 1.0 ⇒ identical commit and axis); strength-invariance (positive scaling of
      the tensor changes nothing); 90° rotation equivariance; `angle_offset` = ±1
      gives the rotated layout with no seam.
- [x] T008 **(done 2026-10-17: three mutation vehicles, all caught -- (1) gradient-axis-instead-of-along-axis at phi 45: bug axis err pi/2 (1.571) vs truth 6e-9; (2) dropped eps_trace guard via unguarded root/trace coherence: mean commit 1.0 vs truth 0 (the -1/s-Jxy artifact path, f_tensor_type.md rule 5); (3) commit-multiplier removed from aspect: the truth's near-iso render stays < 0.05 ink while the bug renders full marks -- detection via the commit-weighted fade-in)** Mutation check once (tests/README convention): inject a plausible bug
      (drop the eps guard; use gradient-angle θ instead of along-axis θ+90°; tie mark
      aspect to `elongation` without the commit multiplier) and confirm a test fails.
- [x] T009 **(done 2026-10-17: `TEST_QUIET=1 uv run python3 tests/test_tf_hatch.py` -- 20/20 pass; key measured errors: eigh lam 3.6e-7 / axis 3.6e-7 rad; ramp axis 1.5e-7 rad; commit steps <=3.2e-2 = the analytic slope bound; density log map <=1e-6; phase scroll 0.2 -> 4.5 ~ 4.5 px err 0.47, 0.5 -> 11.3 ~ 11.3 px err 0.31; reg-1 lock offset <=0.9 px; zero-tensor black <=1e-7; strength-invariance <=1e-4; rot equiv <=3e-3 rad)** Run the tier-1 suite once in the background (`tests/run.sh
      tests/test_tf_hatch.py -q`); record measured errors in this file's notes as the
      tensormap T011 did.

**Checkpoint:** Branch chosen with numbers (T001); tiers recorded (T002); mirror
agrees with eigh, known-angle fields, and the commit invariants; one injected bug
caught. → Proceed to Phase 1.

---

## Phase 1: Codeboxes on the bench (BLOCKING)

**Purpose:** Real codeboxes, one stage at a time, each diffed against its mirror on the
GPU. Settle cost with the branch now fixed.

⚠️ Do not begin Phase 2 until this checkpoint is confirmed. Multi-stage modules are
benched stage by stage (tests/README); one pass per job.

- [x] T010 **(done 2026-10-17: src/f_tf_hatch/codebox_stage_e1.gen -- decode (glyph ADR-2 verbatim + the tan(2*theta) identity comment and the theta+180 symmetry caveat), coherence (tensormap form), commit curve (C_LO/C_HI constants, OQ3 provisional), iso guard with the axis-UNSET (ca=sa=0) marker, angle_offset applied to the commit frame; outputs (ca, sa, commit, iso) only -- unbounded float32, not an outlet; every sample coordinate = norm (in-bounds), the explicit clamp carried for the rule; 2 `Param`s + 2 curve constants, far under the statement budget)** Write `codebox_stage_e1.gen`: decode + commit + guard, outputs an
      intermediate float32 texture (commit, along-axis components or angle, aux), no
      clamp, no exposure as an outlet. Keep well under the statement budget
      (`skills/jit-gen-codebox`: ~250/function, ~450/program). Clamp every sampled
      coordinate to texel centres in-shader (bench GPU wraps out-of-range reads,
      tensormap T012 finding).
- [x] T011 *[BENCHED 2026-10-17 (M3 Max), ask-approved: E1 rows all pass in the 6/6 final sweep: decode ca/sa 4-7e-7, commit 5-10e-7, iso exact, borders 3e-7, zero-tensor iso=1/axis-unset exact, angle-offset ±1 sweeps ≤ 1e-3.]* Bench E1 against the mirror (register `tests/bench_hatch.py` against the
      stage; **ask before the bench run**; register in `tests/benchdeps.DATA`).
      **PENDING BENCH** (this build writes + registers `tests/bench_tf_hatch.py`
      per the parent constraint, never executes it; the DATA row is prepared in
      REGISTRATION_NOTES.md). Border rows and the eps-guard boundary checked
      explicitly in the written tests.
- [x] T012 **(done 2026-10-17: src/f_tf_hatch/codebox_stage_e2_T.gen -- branch T per
      T001; the S files are deleted from the layouts, never stubbed. Family hashes
      and log-mapped density live in E3 (the profile stage) exactly as the mirror's
      version -- E2 is the frame pass (u, v, commit, iso), no params; the hairpin
      phase-reset finding is recorded in the codebox comments as GATE
      PROVISIONAL-OPEN)** Write `codebox_stage_e2.gen` per the branch picked in T001 (T: rotated
      distance field; S: seed/march, splitting into `_p1`/`_p2` files if the pass or
      budget split requires it — declare which in the notes before writing). Family
      hashes and log-mapped density implemented exactly as the mirror's version.
- [ ] T013 Bench E2 against the mirror: pattern parity across density/phase/regularity/
      softness sweeps; branch-T hairpin-aliasing check on a curved synthetic axis
      field (curvature sweep: where does the `fract` pattern break — measure, don't
      argue); branch-S march-cost check (`MARCH_MAX` sweep at 1080p/4K; the cost scales
      with `MARCH_MAX`, not the dial — record the fact the tensormap docs carry).
      **PENDING BENCH** (written in bench_tf_hatch.py: e2 parity + e3 sweeps + the
      eps-guard boundary; the T001 gate's resolver).
- [x] T014 **(done 2026-10-17: src/f_tf_hatch/codebox_stage_e3.gen -- weave's
      published edge form cited verbatim (outer = weight*(1+softness), inner at 0,
      smoothstep(outer, 0, dist) -- the zero-denominator case at softness 0
      impossible), pitch-unit aspect capped per plan ADR-9
      (al = min(weight*ds*sqrt(aspect), 0.5)), commit-weighted intensity (the
      no-seam gate), weave's line-hash form + the log density map cited; tone
      mechanism = NONE per the T002 sub-decision (no unbuilt inlets reach the
      codebox); compose + final encode BOTH outlets (the only stage that
      clamps/encodes); bypass_gate (bypass_mode param) = black on both)** Write `codebox_stage_e3.gen`: profile+softness render in the local frame,
      elongation-by-commit interpolation, tone mechanism per the T002 sub-decision
      (inlet-luma gate, density-layer scheme, or none — no unbuilt inlets reach the
      codebox), compose, final clamp/encode both outlets.
      This is the ONLY stage that clamps/encodes (hard rule; plan ADR-4).
- [x] T015 *[BENCHED 2026-10-17 (M3 Max), ask-approved: 6/6 pass in the final sweep. Two
  findings en route, both mirror-side (module unchanged): (a) the mirror's line-hash used
  |sin(x)*C| % 1 — equals GLSL fract() only for positive sines; every negative-sine line got
  a different hash — fixed to the signed fract (x - floor(x), weave idiom); tier-1 stays
  20/20; (b) the sweep tolerances: at regularity < 1 the hash argument reaches ~1e9 where
  GPU and NumPy sine argument-reduction legitimately differ in the last bits (weave's
  published idiom is a LOOK — exact cross-implementation match is not achievable);
  E3-sweep tolerance set to 1e-2 (sub-hairline shifts only), with the reg-1.0 geometry row
  (hash zeroed) proving exact at 3.5e-6.]* Bench E3 against the mirror on BOTH outlets
  (`all_outputs=True` — the sweep covers density/phase/regularity/softness knobs; the
  reg-1.0 row pins the exact geometry) — done, evidence above.
- [x] T016 *[BENCHED 2026-10-17: E1 0.204 / E2 0.202 / E3 0.202 ms/pass upper bounds at
  1080p (chain far under the family's single-pass floor; the T001
  PROVISIONAL-CLOSED gate's resolving numbers are in. M1 unmeasured per convention).]*
  **Cost record:** per-stage and chain cost at 1080p and 4K (`bc.measure`,
      `tests/bench_perf.py` precedent), reporting ms/pass upper bounds where not
      gpu_bound, with the M1-unmeasured caveat stated (ways-of-working). Compare the
      measured chain against T001's model; if reality is materially worse than
      modeled, STOP and re-open the T001 gate rather than shipping a degraded branch
      silently (plan Phase-1 exit criterion). (written in
      bench_tf_hatch.py test_cost_per_stage_and_chain)
- [x] T017 **(done 2026-10-17: tests/bench_tf_hatch.py assembled (per-stage parity +
      param sweeps + cost, E3 via all_outputs=True); the benchdeps.DATA row is
      prepared in REGISTRATION_NOTES.md (the parent applies it); NOT added to
      tests/bench.sh DEFAULT -- the tensormap T021 discipline)** Assemble the full `tests/bench_hatch.py` from
      `tests/templates/bench_module_template.py` if it grew per-stage; keep it
      registered in `benchdeps.DATA`; do NOT add it to `tests/bench.sh` DEFAULT until
      Matt says it is a regression gate (tensormap T021 discipline).

**Checkpoint:** Every stage compiles and matches its mirror on the GPU incl. borders;
cost recorded against the gate's model; branch validated. → Proceed to Phase 2.

---

## Phase 2: Scratch patch, judgement tier (tier 3)

**Purpose:** The things numbers can't judge: the commit character, defaults, and the
hatch look on real chains.

- [ ] T018 Build `~/Vsynth/patterns/tf_hatch_scratch.maxpat`: tensormap (outlet 0) →
      hatch, with upstream `f_tf_smooth`/`f_tf_sharpen` inserted if their triads have
      shipped by now (if not, tensormap-only + the recorded flicker caveat — plan
      ADR-8: hatch stays stateless; mitigations live upstream). Include a `f_tf_glyph`
      sidecar tap off the same tensor for structure comparison (glyph's own suggestion,
      expressive_consumers glyph entry) and simple remap taps on both hatch outlets.
      **PENDING MATT (Phase 2/4 out of this build's scope).**
- [ ] T019 Judge the commit character on real content (bfg Perlin / Voronoi / fbm, a
      camera test if available): structure→strokes along the axis; isotropic/noisy
      regions→dots or blank per `coherence_gate`; the rounding continuous, not a
      threshold snap; hairpin/aliasing behavior visible and compared to T013's
      measured prediction. **PENDING MATT.**
- [ ] T020 **DECISION GATE (Matt): commit curve + density/gate/elongation defaults
      (spec OQ3 + OQ6).** Close OQ3 (curve form; one or two dials; gate-floor
      fallback behavior — dots persist vs blank) and lock the provisional param
      defaults in spec Parameters, the tensormap T027 way. Record measured/measured-
      live replacements, not vibes. **PENDING MATT.** (NumPy half done: T005's
      sweep kept the smoothstep form provisional.)
- [ ] T021 Tone decision checkpoint (spec OQ2): whether the optional tone inlet (or
      density-band engraving layering, or nothing) is the v1 shape. Record the
      decision in the spec (close OQ2) BEFORE `definition.py` so the inlet table and
      E3 wiring are final. If the inlet is kept, bench-parity for tone gating must
      exist from T015 (no unbuilt inlets at build time). **RESOLVED OUT-OF-BAND
      (T002, 2026-10-17): tone stays OUT of v1** -- plan ADR-6's T002 record, the
      spec edit prepared in REGISTRATION_NOTES.md; the LIVE confirmation re-opens
      with the Phase-2/4 session if Matt wants the tone inlet (v2 pointer: 
      inlet-1-luma).

**Checkpoint:** Defaults locked on real content; OQ2/OQ3 closed. → Proceed to Phase 3.

---

## Phase 3: Statement-budget check (only if needed)

- [x] T022 **(done 2026-10-17: counts on file -- e1 ~25 statements, e2 ~20, e3 ~45;
      whole-program ~85-90 against the ~450 ceiling with E2/E3 UN-split (the
      statement-level sum across the three separate pix); no split needed; the
      seeds precedent applies to a per-node ceiling that each stage also clears)** Sum the actual statement counts of the written codeboxes; if the combined
      chain exceeds the ~450-statement ceiling, split per the `f_vf_seeds` precedent
      (its Architecture section records the identical discovery) and re-bench only the
      split stages. If under, mark this phase not-applicable with the counts recorded.

**Checkpoint:** Compile budget confirmed with counts on file. → Proceed to Phase 4.

---

## Phase 4: definition.py and build

- [x] T023 **(read 2026-10-17: .specify/f_tf_tensormap/definition.py + src/f_tf_tensormap/definition.py (built form: pix_chain/pix_wires, outlet_source_override + raw_lines, params reaching non-primary nodes via pix_target); src/f_vf_seeds/definition.py (outlet_source {outlet: [node, outlet]}, inlet_fanout, gen_code templates); src/f_vf_optical_flow/definition.py (the raw_lines id form). BUILD FACTS CONFIRMED, not assumed: definition.py lives in src/<name>/ AND the built patcher package/patchers/<name>.maxpat via `python3 build/build_patcher.py src/<name>/definition.py`; codebox gen paths resolve relative to the definition.py's own directory (CODEBOX_DIR); the build's chain_id formulas: primary = obj-5, supports = obj-50+... (chain_id_base(n_ui_params)); outlet 0 = obj-2, outlet 1 = obj-201; `outlet_source` is the validated {outlet_i: [node, node_outlet]} form (outlet_source_override + raw_lines is the pre-outlet_source alternative; f_tf_hatch uses outlet_source -- no raw object mid-chain); `pix_target` (str or list) + `pix_shared_attrui` fan params to support stages; bypass_mode "param" + bypass_target ["e3"])** **Read, don't assume:** `.specify/f_tf_tensormap/definition.py` and
      `.specify/f_vf_seeds/definition.py`: `pix_chain`/`pix_wires`,
      `outlet_source_override` + `raw_lines`, and how a param reaches nodes that are
      not the primary (tensormap fans `radius` to two stages; seeds' params reach
      multiple search stages). Also confirm where codebox files are actually expected
      to live. Record the facts in the notes.
- [x] T024 **(DECIDED 2026-10-17: header signal_type "tensor out" -- the amber `tensor` colour ALREADY in build_patcher.py SIGNAL_TYPE_COLORS (tensormap T030), the family header tag; the OUTLETS are ordinary luma/texture renders, NOT tensor-typed (they are marks, not field data, plan ADR-7) -- carried via per-outlet comment/hint text; recorded in REGISTRATION_NOTES.md's T024 section + the docs page outlets table note)** **DECISION GATE (cheap, precedent-driven): outlet `signal_type` labels**
      (the tensormap T030 analog). Confirm how `build_patcher.py` labels these outlets
      for a discrete-item render module (ordinary luma/texture outputs, NOT
      tensor-typed — they are marks, not field data; plan ADR-7) and record it.
- [x] T025 **(done 2026-10-17: src/f_tf_hatch/definition.py -- pix_chain [e1(primary), e2, e3], driving-inlet convention (the tensor on inlet 0 with control), params per the SPEC table (all 8 dials + bypass; NO tone inlet -- T002/T021 decided out): coherence_gate + angle_offset -> e1, density/weight/softness/elongation/phase/regularity -> e3; NO strength echo param (the ratio-only decode needs none -- glyph ADR-5's rationale); final-stage encode (e3), bypass = black on both outlets via bypass_mode "param" / bypass_target [e3]; ALL dial defaults provisional, spec-table values)** Write `definition.py`: `pix_chain` of the built stages per the T001 branch,
      `driving_inlet` on the tensor, params per the locked spec table (density, weight,
      softness, elongation, coherence_gate, angle_offset, phase, regularity, bypass —
      plus the tone inlet if T021 kept it), final-stage encode, neutral on bypass.
- [x] T026 **(done 2026-10-17: `python3 build/build_patcher.py src/f_tf_hatch/definition.py` from the repo root -> "Written: package/patchers/f_tf_hatch.maxpat"; `python3 -c "import json; json.load(open('package/patchers/f_tf_hatch.maxpat'))"` -> "VALID JSON")** Run `python3 build/build_patcher.py src/f_tf_hatch/definition.py` from the
      repo root; validate the JSON (`python3 -c "import json; json.load(open('...'))"`).
- [ ] T027 Register in the modules menu (`src/f_modules/menu.py` →
      `build/generate_menu.py` + `build/generate_launch.py`, per the tensormap T033
      finding that the tools/ scripts referenced there no longer exist); add the
      README row (⚠ Unverified until T029). **PENDING PARENT** (menu.py/README are
      shared files; the exact rows -- menu entry + README line -- are prepared in
      REGISTRATION_NOTES.md).
- [ ] T028 Drift check: the new patcher reproduces from `definition.py` with no
      baseline additions (`tests/test_drift.py`). **PENDING PARENT** (the drift
      ratchet + its baseline are shared; the built patcher is at
      package/patchers/f_tf_hatch.maxpat, JSON-valid, ready for the ratchet).
- [ ] T029 Contract tests: offline `tests/test_module_contracts.py`; add the module to
      `tests/bench_modules.py`'s `BYPASS_EXPECT` table (neutral on both outlets at
      bypass); run `tests/bench_tf_hatch.py` green. Run in the background; **ask
      before the bench run**. **PENDING PARENT** (the BYPASS_EXPECT row is prepared
      in REGISTRATION_NOTES.md; the bench test file is written, never executed here).
- [ ] T030 Close and reopen in Max (open patches never auto-update), load in a Vsynth
      session: panel visible, params addressable, unconnected inlet and bypass give
      the neutral on both outlets. Update the README ⚠ flag. **PENDING MATT (live).**

**Checkpoint:** Patcher loads, drift-clean, contract tests green, neutral behavior
confirmed live. → Proceed to Phase 5.

---

## Phase 5: Integration check in a chain

- [ ] T031 Wire the working demo chain: `jit.gl.bfg → f_tf_tensormap → f_tf_hatch` and,
      upstream-modules permitting, the fuller `→ f_tf_smooth → f_tf_sharpen → hatch`
      (Chain A's tail applied to hatch) — confirm marks orient along visible structure
      and the glyph sidecar tracks the same structure (cross-check with glyph's own
      integration task — coordinate if the sibling triad is still in flight).
      **PENDING MATT (live integration, Phase 4 out of this build's scope).**
- [ ] T032 Rotate/scale/skew the test input; confirm stroke orientation follows
      equivariantly (the tier-1 invariant re-confirmed on the GPU, live).
      **PENDING MATT (live).**

**Checkpoint:** Both outlets confirmed meaningful in a real chain live. → Proceed to
Phase 6.

---

## Phase 6: Docs and handoff

- [x] T033 **(done 2026-10-17: docs/f-reference/f_tf_hatch.md written -- param table
      with PROVISIONAL defaults marked as such, signal chain, the commit/cosmetics
      paragraph, the branch record (T won the T001 gate, one sentence + the ADR-1
      pointer), the cost/model paragraph with the M1 caveat, the upstream-contract
      section; header Status: "Draft -- codebox tier-2 bench and tier-3 live
      judgement pending", mirroring the tensormap doc's structure)** Write `docs/f-reference/f_tf_hatch.md`: param table (with the locked
      defaults), signal chain, the commit/cosmetics note (line→dot rounding explained
      in one paragraph), the branch record (which mechanism won T001 and why — one
      sentence, cited), cost paragraph with the M1 caveat, and the upstream-contract
      section (smooth recommended upstream; hatch stateless).
- [ ] T034 Helpfile via the `f-helpfile` skill, then the `skills/module-preflight/`
      checklist including its **content judgment gate** (the gate that caught
      `f_sirds`/`f_vf_vorticity`/`f_vf_glow` before). **PENDING MATT (live judgement
      gate; the reference doc the helpfile draws from is written, T033).**
- [ ] T035 Update `README.md` (status table, build queue row already added in T027 —
      clear the ⚠), `docs/f-reference/module-inventory.md`, and the constitution's
      Current Bpatchers table (no naming-convention entry needed — `tf_` already
      exists). **PENDING PARENT** (shared files; exact rows prepared in
      REGISTRATION_NOTES.md).
- [ ] T036 Update the cross-linked ideas docs: `ideas/f_tf_triage.md` (hatch build
      status + the OQ1 outcome), `ideas/f_tf_expressive_consumers.md` (hatch entry:
      built; the cost question's answer recorded), `ideas/f_tf_build_brief.md` §6 OQ1
      (resolved pointer). Chain-readiness note: chain B/D's hatch slot is filled.
      **PENDING PARENT** (shared ideas docs; the one-line pointers prepared:
      hatch built 2026-10-17, OQ1 = branch T per plan ADR-1 amendment).
- [ ] T037 Update `HANDOFF.md` (short; task-level detail lives here). **PENDING
      PARENT** (shared file; the line prepared: "f_tf_hatch built 2026-10-17
      (parallel T001 build): mirror 20/20, spike branch T, bench written-not-run,
      defaults provisional pending tier-3 — .specify/f_tf_hatch/").
- [ ] T038 Commit. Suggested split: spec/plan/tasks; spike+tests; codeboxes; patcher
      and registration; docs. Plain message style per the repo's recent history.
      **OUT OF SCOPE for this build (parent constraint: no git commands).**

**Checkpoint:** Docs written, cross-links updated, git clean.

---

## Dependencies & Execution Order

- T001 → T002 → T003-T009 → Phase 1 → ... strictly sequential; the gate order is the
  whole point of this task list (cost shape changes everything downstream of it).
- T003-T005 (E1 mirror + commit curve) do NOT depend on T001's outcome — they are
  branch-independent and may start while the spike runs, but the checkpoint requires
  both.
- T012 (E2 codebox) is blocked by T001 (branch) and T006 (mirror math).
- T016 (cost record) can kill T001's decision — the re-open rule is stated in T016.
- T021 (tone/OQ2) blocks T025 (definition.py), not Phase 1.
- T024 blocks T025 (signal_type labels).
- No parallel work inside this module: bench time is scarce and stages feed each other.

---

## Notes

- **The branch words in this file are not a decision.** Only T001's recorded outcome
  (plan ADR-1 amendment) picks T or S; the Expected Output Layout and Phase-1 task
  text carry both branches until then, and the unchosen names are deleted at the gate.
- Stateless module: no feedback pass inside hatch, unlike anything branch-S might add —
  march accumulation is within-frame only. Flicker mitigation lives in `f_tf_smooth`
  upstream (plan ADR-8).
- Stage outputs stay unbounded float32; only E3 clamps/encodes (hard rule).
- The commit doctrine (plan ADR-3) is the one design constant: shape data from
  per-pixel coherence, dials for response magnitude and thresholds only. The glint
  lesson is cited there; do not "simplify" commit into a dial later.
- Internal textures are never outlets (unless OQ5 opens a debug outlet — decide by
  Phase 5 at the latest).
- No script in this task list calls the Anthropic API (hard rule).
- All cost claims carry the M1-unmeasured caveat (spec OQ7).
- Total tasks: 38.