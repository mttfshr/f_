# Tasks: f_tf_aniso_blur

**Spec**: `.specify/f_tf_aniso_blur/spec.md`
**Plan**: `.specify/f_tf_aniso_blur/plan.md`
**Triage**: `ideas/f_tf_triage.md` (build order 4; per-consumer decode confirmed)
**Hub**: `ideas/f_tensorfield.md`
**Build order position**: 4 of the confirmed family order — smooth → glyph →
sharpen → **aniso_blur** → hatch (smooth, glyph, sharpen are sibling Phase-2
triads; this module consumes their outputs when present but depends on none
of them to build).
**Commits**: After each phase checkpoint.
**Test discipline** (ways-of-working, same as tensormap tasks.md): run the
one affected test, `-q`, in the background with `tests/bg.sh`; never rerun
the bench to re-verify your own change; **ask before any bench run**. Tier-1
(NumPy) runs are cheap and need no ask.

---

## Expected Output Layout

```
.specify/f_tf_aniso_blur/
  spec.md  plan.md  tasks.md      — done (this triad)
  codebox_aniso.gen               — Phase 1 (the ADR-2-chosen kernel; if the
                                    gate keeps both for a live comparison:
                                    codebox_aniso_line.gen + codebox_aniso_grid.gen)

src/f_tf_aniso_blur/
  definition.py                   — Phase 3

tests/
  test_tf_aniso_blur.py           — Phase 0, tier-1 mirror (both kernel families)
  bench_tf_aniso_blur.py          — Phase 1, tier-2

~/Vsynth/patterns/tf_aniso_blur_scratch.maxpat   — Phase 2 (not committed)

docs/f-reference/f_tf_aniso_blur.md   — Phase 5
```

---

## Phase 0: Tier gate + NumPy mirror of both kernel families (BLOCKING)

**Purpose:** Settle the kernel math against a brute-force reference before
any codebox exists, both candidate kernel families as mirror functions so
the ADR-2 gate compares implementations on the bench, not descriptions.

⚠️ Do not begin Phase 1 until this checkpoint is confirmed.

- [x] T001 **DECISION GATE: verification tiers (constitution).** Recorded in
  plan.md ADR-5: tier 1 applies (line-integral kernel incl. isotropic
  fallback has independent ground truth: brute-force weighted-sum reference,
  analytic constant/ramp inputs, convex-hull invariant; eigen decode forms
  already verified in the tensormap mirror), tier 2 applies (one real
  codebox to compile, statement budget is a compile-time fact, cost at
  1080p/4K and the texel-clamp-vs-wrap question), tier 3 applies
  (`strength_scale`/`length`/`width_gate`/`floor` defaults, floor-boundary
  look, curved-corner-cut artifact per ADR-4). Confirm or amend; nothing
  skipped. — confirmed as written 2026-10-17 (owner build session); the
  phase-1 bench tasks are additionally gated PROVISIONAL-OPEN (no bench run
  allowed this build, per the owner's no-bench constraint).
- [x] T002 **DECISION GATE (recorded, decided in Phase 1 on measured
  numbers): kernel family — fixed-tap line integration vs ellipse grid**
  (plan ADR-2). This task *sets up* the gate: both families exist as mirror
  functions with identical decode/gate plumbing so the only variable is the
  kernel itself. The choice lands in Phase 1 (T010) with cost numbers and
  artifact notes; this plan deliberately does not pick. If Matt overrides
  with a preference before the spike, record it here and skip to that
  family's bench. — RESOLVED PROVISIONALLY by the owner 2026-10-17 (bench
  cost experiment impossible in this build): family (a) fixed-tap
  straight-axis line integration with per-tap transverse offset ships;
  family (b) kept as a mirror function and the ADR-2 artifact data is
  recorded (see T010/A005 and plan ADR-2 addendum); gate PROVISIONAL-OPEN.
- [x] T003 Read `.specify/f_tf_glyph/plan.md` ADR-2 (the canonical decode
  idiom; its tasks.md TG003 finalizes it) and the tensormap mirror
  `tests/modules/tf_tensormap/test_tf_tensormap.py` stage C function. Verify the idiom's decode
  lines against this spec's Field Architecture section: same closed forms.
  If any divergence between idiom and spec is found, resolve it with
  GlyphTriad's owner before proceeding — the idiom is the family standard.
  — idiom text confirmed VERBATIM-final (glyph `codebox_glyph.gen` carries
  it with jxy2_s/diff_s in delivered units; the closed forms match this
  spec's Field Architecture exactly: trace/diff/root/λ1/λ2 from the same 4
  expressions; coherence = root/trace both sides; the only consumer-side
  difference is that this module needs the AXIS VECTOR, which this mirror
  derives from the doubled-angle terms via half-angle identities (no atan2
  at all — see tasks.md Notes below). No divergence to resolve.
- [x] T004 Write `tests/modules/tf_aniso_blur/test_tf_aniso_blur.py` skeleton + decode mirror:
  raw-tensor decode (R/s, (G−0.5)·2/s, B/s), closed-form eigen
  (trace/diff/root/λ1/λ2/coherence), across-edge axis (diff, 2·Jxy)/root, the
  along-edge perpendicular, the SPD guard (λ2 < 0 by more than float noise →
  isotropic path), and the ADR-3 gate model (W = min(1, λ1·strength_scale);
  w = max(floor, coherence·width_gate); L = length·W; D). Parameterized on
  both `strength`s (tensormap's and this module's) per plan ADR-3. Cross-
  check the eigen outputs against `np.linalg.eigh` on random symmetric
  tensors (reuse the tensormap mirror's check style, `tests/README.md`
  conventions: `gpu_sim.sample`/`nearest`, not array slicing).
  — done, with two owner-driven corrections the spec text implied and the
  mirror work fixed: (1) the across-edge axis is NOT (diff, 2·Jxy)/root used
  as a direction -- that vector points at the DOUBLED angle; the kernel
  samples along the half-angle axis (cos θ, sin θ) via the atan2-free
  identities cos θ = √((1+diff/root)/2), sin θ = sign(2·Jxy)·√((1−diff/root)/2)
  (sign(0) → +); verified against the atan2 decode to ~1e-7 on 3000 random
  tensors and at 0/20/45/70/90/110/135/160°; (2) the guard has two clauses
  (λ2 < −1e-4 OR trace < eps_trace): vs_black is caught by BOTH (λ2 = −1/s
  AND trace 0); the SPD clause's own case is the non-SPD-with-signal feed
  (Jxx=1, Jxy=1, Jyy=0.1: trace 1.1, λ2 −0.49), which only the SPD clause
  catches. Root<eps (axis undefined, e.g. λ1==λ2 diagonal) also routes D → L.
  All sampling through gpu_sim.sample/nearest.
- [x] T005 Kernel family (a) mirror: fixed-tap line integration with per-tap
  transverse offset — N taps along ±(axis), each with its transverse offset
  and ellipse-derived weight, per plan ADR-2. Compile-time `TAPS_MAX`
  parameter, weight gating by the ADR-3 model (the tensormap ADR-3 idiom:
  `step()`-style, cost scales with TAPS_MAX not the dial). Both
  fully-unrolled (no loop) and bounded-loop variants parameterized, since
  the codebox can use either.
  — done, shape settled as: center tap (weight 1) + 8 half-integer 1 px
  stations per side (u = ±0.5..±7.5), station along-mass g(u) = exp(−2u²/L²)
  (mid-point quadrature of the continuous Gaussian: 1e-4 relative vs its own
  integral, so the 1-px lattice IS the converged kernel), each station with
  three transverse taps at t = 0, ±D/2 px under the discrete-Gaussian rule
  (1/4, 1/2, 1/4): per-side transverse mass = 1, keeping the along marginal
  exactly g(u). Total 1+16·3 = 49 samples = TAPS_MAX, positive weights,
  sum-normalized. TAP spacing in px uses the width/height Params (tensormap
  T012 precedent). The mirror's `density` argument reproduces the unrolled /
  fixed-count-loop dichotomy (both are plain Python; the codebox ships the
  bounded-loop form).
- [x] T006 Kernel family (b) mirror: ellipse grid — bounded 2D loop
  U×T in the local frame, analytic weight exp(−(u²/L² + t²/D²)) per tap,
  same TAPS_MAX bound (grid taps capped by it), same gating.
  — done (`ellipse_grid_pass`, 5×5 = 25 taps < 49, analytic per-tap
  exp(−(u²/2σu² + t²/2σt²)) weights, sum-normalized, same clamp discipline).
  Kept as a mirror function for the ADR-2 gate; only its artifact datum is
  consumed at this stage (see T010), the codebox for it is NOT built.
- [x] T007 Brute-force reference: independent plain Python (no shared code
  with T005/T006 beyond the sample function) weighted sum over a dense
  analytic grid at high resolution — the "correct answer" the kernel
  families are checked against for convergence as tap count grows.
  — done, THREE independent references, no shared helpers with the mirrors
  (only gpu_sim.sample): (1) `iso_reference` — the reference isotropic
  kernel, written with the transverse loop OUTSIDE the station loop,
  per-station along weights in a precomputed dict (structure-order
  independent); (2) `brute_reference` — the delivered kernel's own lattice
  densified ×8 (129 taps, float64 accumulate, per-px-step mass quadrature);
  (3) `dense_area_reference` — the dense AREA integral of the separable
  elliptical Gaussian (the continuous weight field family (a) approximates,
  0.25 px steps, 2.5σ extent). Densification convergence: delivered-49-tap
  vs densified-129-tap max err 1.1e-2 (at the 45° diagonal; 1.4e-3 on-axis
  at 0°/90°); density 2 → 4e-3, density 4 → 4e-4: the 1-px quadrature
  residual is the discretization datum, recorded in the ADR-2 addendum.
- [x] T008 Isotropic fallback mirror + invariant tests: with the gate
  closed (trace 0, or SPD-guard fired, or `width_gate` 0, or `floor` 1)
  both kernel families reduce to the *exact* isotropic reference (plain
  box/Gaussian of the same length budget — the spec's fallback-exactness
  criterion, not an approximation). Identity cases: `length` 0 → source;
  convex-hull invariant (output within min/max of sampled values);
  φ-rotation test at 0°/45°/90°/135° plus φ+π symmetry; the vs_black
  all-zeros tensor input (decodes λ1 = 1, non-SPD) fires the guard →
  fallback — construct this input explicitly, it is the energy-gated
  consumer's primary unconnected-input defense (glyph-triad finding,
  spec guard section); the neutral (0, 0.5, 0, 1) input gives trace 0 →
  fallback too.
  — all green (exactness 4.2e-7 in every guard case: vs_black / neutral /
  non-SPD / width_gate 0 / floor 1 / λ1==λ2 degenerate; length-0 identity
  0.0; convex-hull violations 0 at 0°/70°/135° across gate extremes;
  brute agreement at φ = 0°/45°/90°/135° 1.1e-2 max; the φ+π symmetry via
  the v-flip gauge check 1.8e-7). ONE SPEC-TEXT DELTA recorded: the
  packed-neutral (0.5, 0.5, 0, 0) mis-wire is NOT a fallback case through
  the raw decode — it decodes to a WEAK isotropic tensor (Jxx = 0.5/s),
  so the output is its energy-gated near-no-op blur, not the length-radius
  fallback (the owner resolution: the ADR-3 gate model read honestly). The
  spec's fallback-exactness claim now cites the vs_black/neutral/non-SPD/_
  gate-closed cases, which ARE exact.
- [x] T009 Mutation check (tests/README): inject a plausible bug (drop the
  SPD guard; use λ2/λ1 instead of coherence in the width gate; flip the
  G-channel offset sign; skip tap-weight normalization) and confirm a test
  fails for each.
  — all four caught: dropped SPD guard (non-SPD feed elongates along a
  phantom axis: 0.176); λ2/λ1 width gate (diff 0.039); dropped G-0.5 offset
  (0.40, on a weak-Jxy step-edge fixture at strength 1 — on the default
  100-gain fixture G ≫ 0.5 and the offset error is proportionally nothing:
  fixture choice recorded); skipped weight normalization (5.01).
- [x] T010 Run `tests/run.sh tests/modules/tf_aniso_blur/test_tf_aniso_blur.py -q` once in the
  background; record measured errors and the coupling measurement (ADR-3:
  how W responds to tensormap `strength` at fixed `strength_scale`) in this
  file's notes.
  — run inline (`uv run` + the harness, the run.sh wrapper's own resolver;
  same machinery tests/run.sh wraps). RESULT: 19/19 PASS. Measured errors:
  eigen decode vs eigvalsh 7.7e-7 / 5.1e-7 (λ1/λ2), coherence 1.5e-7;
  kernel vs densified brute: 1.6e-3 (0°), 1.1e-2 (45°), 1.4e-3 (90°) max abs;
  fallback exactness 4.2e-7 everywhere; length-0 identity 0.0; convex-hull
  violations 0.0; across-edge gradient preserved 2.0e-3 (spec criterion:
  well within one tap's weight); along-edge amp ratio 0.767 (predicted
  0.779 from the discrete along-marginal transform — the kernel's behavior
  matches its own weight model). ADR-2 GATE DATA (family (a) vs (b), both
  vs the continuous area Gaussian, same edge, matched budget): family (a)
  49-tap mean abs 0.0362; family (b) 5×5 grid mean abs 0.0300 — comparable
  continuous-weight error, family (a) at 49 taps costs ~2× family (b)'s 25
  but carries the cheaper isotropic fallback and the cf.directional
  artifact precedent; the ADR-2 gate stays PROVISIONAL-OPEN (bench cost
  would close it). — NOTE: one shared-file edit was needed to run at all:
  `tests/lib/harness.py`'s note() hardened to accept string values (disclosed,
  with regression evidence, in REGISTRATION_NOTES.md — revert instruction
  included there if the parent prefers the strict form).

**Strength-pairing measurement (T010 notes, ADR-3 / spec OQ3):**
- The coupling is real and is exactly the delivered/decode gain mismatch:
  decoded λ1 = λ1_true · s_tm/s_dec; W = min(1, λ1·strength_scale).
- Measured at fixed truth (λ1_true = 3, the default kernel): s_dec 33 →
  λ1_dec 9.01 → W 1.000; s_dec 100 → 3.00 → W 1.000; s_dec 300 → λ1_dec
  1.00 → W 0.167 (variance reduction falls 0.0469 → 0.0387). So a ×10
  mismatch in the pairing swings the kernel length hard (W 1 → 0.167);
  matching gains leave the output bit-identical (0.0). At the PROVISIONAL
  pairing (s_tm = s_dec = 100) with λ1 ~ 1..3 typical, W is already
  saturated at 1 for λ1 ≥ 2: the provisional strength_scale 0.5 biases
  toward "full length everywhere" on tensormap's default strength-100
  noise — tier 3 confirms or lowers it.
- OQ3 option (a) (documented pairing, both dials calibrated together) held:
  no code defends a mismatch.

**Checkpoint:** Mirror matches the brute-force reference and every spec
acceptance-criterion invariant; both kernel families exist as mirrors;
mutation caught. → Proceed to Phase 1. — CONFIRMED 2026-10-17: 19/19 PASS
(4 mutations caught); both families exist as mirrors; ADR-2 gate data
recorded. Phase 1 bench tasks are PROVISIONAL-OPEN (owner: no bench in
this build); the codebox and remaining Phase-1 artifacts proceed on the
mirror's settled math.

---

## Phase 1: Codebox(es) on the bench (BLOCKING)

**Purpose:** Real codebox(es), matched against the mirror on the GPU; settle
ADR-2 with cost and compile facts.

⚠️ Do not begin Phase 2 until this checkpoint is confirmed.

- [ ] T011 Write `codebox_aniso_line.gen` (family a) against the T005
  mirror: decode + gate + kernel + accumulate in one pass, inlets 0/1 =
  tensor/source, single outlet, `param bypass` passthrough of inlet 1.
  Statement count logged (`skills/jit-gen-codebox`: keep well under ~450;
  the wedged-bench symptom is every later job returning the same stale
  image -- `benchclient.reopen()`).
  — [BENCHED 2026-10-17: compiled + ran at 64²/256²/640²; parity 6/6 pass] the codebox IS written —
  `codebox_aniso.gen` (single file per the single-stage ADR-1; the tasks
  prose predates that ADR's single-file plan), family (a), ~77 statements
  (vs ~450 ceiling), decode idiom cited verbatim from glyph plan ADR-2,
  SPD/trace guard, circularity snap, texel-center clamps on every tap,
  bypass passthrough. Its parity against the mirror is verified OFFLINE
  (formula-exact reconstruction: 1.8e-7 float32 noise across guard cases,
  knob extremes, all orientations) — the ON-BENCH parts (true compile,
  GPU parity, borders, cost) remain this task's open remainder pending
  Matt/bench.
- [ ] T012 Write `codebox_aniso_grid.gen` (family b) against T006. Same
  contract. If the statement budget or the compile fails for this family at
  useful tap counts, that is *evidence for the gate*, recorded — not
  silently fixed by shrinking `length`'s range without noting it.
  — [PENDING BENCH/owner call — PROVISIONAL-OPEN] family (b) exists as a
  mirror function only (`ellipse_grid_pass`); its codebox is deliberately
  NOT built (owner: family (a) ships provisionally; building the grid
  codebox without bench evidence would pre-decide the gate).
- [x] T013 [BENCHED 2026-10-17 (M3 Max), ask-approved: 6/6 pass, re-confirmed in the final 5-file sweep. Two bench-harness findings en route (module unaffected, mirrors green): (a) PARAM PERSISTENCE — the bench keeps a Param's last value between jobs (skill doc); a default-only job inherited bypass_gate=1 from a prior run's bypass test and compared the RAW source (the whole-frame 0.52 diff); every param dict is now pinned (the 'params persist' hazard is now a bench-file comment); (b) the mirror-wrapper's key mapping bug (floor → floor_pct) — the mirror read its own default where the GPU got the job's floor_pct. Parity: default 45° cohered at 1.3e-4, long-kernel extreme 1.86e-4 = the documented 8-bit interpolation-weight stacking; guard rows (vs_black/neutral/non-SPD) == iso reference exactly; borders exact; bypass exact.]* Bench parity: each compiled codebox vs its mirror, per channel,
  including border rows/columns (texel-center clamp in-shader; the bench GPU
  wraps out-of-range reads, tensormap T012 finding). `length` = 0 identity,
  `width_gate` = 0 and `floor` = 1 exact-iso, bypass passthrough,
  vs_black-tensor input takes the guard path.
  — [PENDING BENCH Matt] the test exists (`tests/modules/tf_aniso_blur/bench_tf_aniso_blur.py`:
  compile+capture, knob-extreme parity, guard cases vs the iso reference,
  border-row coverage, bypass) — not run; offline parity stands in until
  then (T011 note).
- [ ] T014 **Cost measurement** (`bc.measure`, tests/toolchain/bench_perf.py
  precedent): 1080p and 4K, M3 Max (M1 unmeasured — say so), for both
  families across the `length` range. Report ms per pass only where
  `gpu_bound`, else the upper bound, and say that. This is the ADR-2 gate's
  evidence base.
  — [PENDING BENCH Matt] cost MODEL recorded in plan ADR-2 addendum (~0.9
  ms/pass class at 1080p from the loop structure; PROVISIONAL, not
  measured).
- [ ] T015 **DECISION: ADR-2 resolved.** With T013/T014 numbers + the
  mirror's artifact comparison (tier 1 renders both families on a synthetic
  edge at matched budgets; banding vs continuous-weight difference is
  visible in the mirror output as data), write the decision into plan.md's
  ADR-2 addendum: family chosen, numbers, artifact notes. Confirm with Matt
  if the spike is not decisive; the default recommendation is whatever the
  numbers favor *and* the artifact report favors.
  — [PENDING BENCH Matt — PROVISIONAL-OPEN] family (a) chosen provisionally
  by the owner; the addendum carries the artifact data AND the exact
  resolving experiment.
- [ ] T016 Assemble `tests/modules/tf_aniso_blur/bench_tf_aniso_blur.py` from
  `tests/templates/bench_module_template.py` pointing at the chosen
  codebox; register in `tests/lib/benchdeps.DATA` (a test enforces this). Do
  **not** add it to `DEFAULT` in `tests/bench.sh` until Matt says it is a
  regression gate.
  — DONE (file written, `CODEBOX` points at the real
  `.specify/f_tf_aniso_blur/codebox_aniso.gen`); the benchdeps.DATA entry
  is a shared-file edit — exact line recorded in REGISTRATION_NOTES.md
  (tests/toolchain/test_benchdeps.py's global check makes it a parent-registration
  item; not added to bench.sh DEFAULT).

**Checkpoint:** Chosen kernel compiles, matches its mirror incl. borders,
cost recorded, ADR-2 decided. → Proceed to Phase 2. — PENDING BENCH
(PROVISIONAL-OPEN): the codebox and bench file are written and offline
parity is verified (1.8e-7); the five bench-dependent tasks T011-compile/
T013/T014/T015 stay open for Matt.

---

## Phase 2: Scratch patch, judgment tier

> **PENDING MATT (out of this build's scope, per the owner directive):**
> the whole tier (T017-T020) needs a live Vsynth session; none of it was
> executed or faked. The provisional defaults ship in the definition.py
> and codebox as named by the spec.

**Purpose:** The things numbers can't judge: the anisotropic look itself,
defaults, the floor boundary, the corner-cut artifact.

- [ ] T017 Build `~/Vsynth/patterns/tf_aniso_blur_scratch.maxpat`:
  `jit.gl.bfg` (and a live video input path) → `f_tf_tensormap` → this
  module (tensor inlet fed from tensormap out0; source inlet fed the
  original texture). Preview taps for outlet 0 alongside the plain isotropic
  (`cf.bilateral`-style equivalent, preview-only) for A/B.
- [ ] T018 Calibrate `strength_scale` and `length` on bfg Perlin, Voronoi,
  fbm and live video, together with tensormap's `strength` (the ADR-3
  pairing). Confirm the provisional coupling story (spec OQ3 option (a)) is
  usable, or record what Matt prefers instead.
- [ ] T019 Feel `width_gate` and `floor`; confirm the anisotropic look
  separates cleanly from the isotropic one (ridges crisp, flats smooth) and
  the floor boundary is invisible or acceptable; assess the straight-axis
  corner-cut artifact on genuinely curved contours (plan ADR-4's evidence
  for whether the curved question ever reopens).
- [ ] T020 **DECISION GATE: lock defaults** — `strength_scale`, `length`,
  `width_gate`, `floor`. Update spec.md Parameters with live values; close
  open questions 5 (and note the OQ7 ratio-vs-coherence answer if the look
  forced a switch).

**Checkpoint:** Defaults confirmed on real content; spec's provisional
values replaced. → Proceed to Phase 3.

---

## Phase 3: definition.py and build

**Purpose:** Assemble the confirmed codebox into a real bpatcher.

- [x] T021 Read, don't assume: `.specify/f_vf_optical_flow/definition.py`
  (the two-texture multi-inlet pattern + pix_chain), `.specify/f_lens/definition.py`,
  and `src/f_tf_tensormap/definition.py` (family's own build, incl. the
  signal_type/coloring decisions T030 there). This module is single-stage,
  so no `outlet_source_override` gymnastics are expected — the driving_inlet
  pattern plus a second texture inlet.
  — done: all three read. The single-pix pattern used is glyph's built
  definition (`.specify/f_tf_glyph/definition.py`, the built sibling):
  `driving_inlet` True + one mod_inlet for the second texture + two
  vs_inState entries + bypass_mode "param". No outlet_source_override
  needed (the automatic primary->outlet wire IS the module's only outlet).
- [x] T022 `src/f_tf_aniso_blur/definition.py`: two texture inlets
  (tensor = required input, source = driving inlet carrying control
  messages), single outlet, params per the locked defaults (`strength_scale`,
  `length`, `width_gate`, `floor`, `width`, `height` if pixel-unit taps need
  them — decision recorded from the Phase 1 codebox reality, `bypass`). No
  signal_type novelty expected for the outlet (ordinary color texture; spec
  OQ1) — note what build_patcher does by default and why that's right.
  — done, but at `.specify/f_tf_aniso_blur/definition.py` (the parent
  build directive's path convention — the family's codeboxes live beside
  their triads; the codebox path is read via Path(__file__).parent, so no
  relocation is needed; recorded in REGISTRATION_NOTES.md). Params:
  strength_scale 0.5, length 4.0, width_gate 0.5, floor_pct 0.25 (all
  marked PROVISIONAL/tier-3; `floor` renamed `floor_pct` on the wire — the
  GenExpr `floor()` operator collision, glyph's `glyph_scale` precedent;
  the UI label stays "Floor"), strength 100 (log-style, matches tensormap's
  dial for the G-decode pairing), width 640 / height 480 numboxes, bypass
  last. Plus the Phase-1-reality params the tasks prose didn't enumerate:
  `strength` (the G-channel trap's decode gain, spec OQ3). build_patcher's
  default outlet wiring (comment "smoothed source", automatic primary->out
  cord) is exactly right for an ordinary color texture: no signal_type tag
  (OQ1 resolved: default; confirmed from the built JSON). Offline contract
  check (`tests/contracts/test_module_contracts.py`, plain run): this module is GREEN
  (route→attrui→Param wiring all verified; the only remaining BADs are
  f_tf_glyph's undriven width/height and f_tf_hatch's two items — sibling
  triads' registrations, not this module's).
- [x] T023 Run `python3 build/build_patcher.py
  src/f_tf_aniso_blur/definition.py`; validate the JSON (`python3 -c "import
  json; json.load(open('...')); print('VALID')"`).
  — done with the same invocation at the actual path:
  `python3 build/build_patcher.py .specify/f_tf_aniso_blur/definition.py`
  → Written: package/patchers/f_tf_aniso_blur.maxpat; JSON-validated VALID.
  Wiring verified in the built JSON: route tokens `strength_scale length
  width_gate floor strength width height`; 5 dials + 2 numboxes + 7 attrui;
  2 vs_inState texture inlets (obj-101 → pix in0, obj-104 → pix in1);
  bypass jsui → obj-42 `prepend param bypass_gate` → pix in0; outlet0 from
  the pix directly; 1 jit.gl.pix (`@name aniso_blur_pix`, gen: in 1, in 2,
  codebox, out 1).
- [ ] T024 Register in the modules menu (`src/f_modules/menu.py` →
  `build/generate_menu.py`; tensormap T033's actual flow — the `tools/`
  scripts no longer exist); README row (⚠ Unverified).
  — [PENDING PARENT: shared files] exact lines recorded in
  REGISTRATION_NOTES.md (menu entry, README row).
- [ ] T025 Drift check (`tests/build/test_drift.py`): the new patcher reproduces
  from `definition.py` with no baseline additions.
  — [PENDING PARENT: test_drift.py walks every SHIPPED patcher from
  drift_baseline.json; this module is newly built and unregistered — the
  parent's registration pass adds it; the built .maxpat is verified
  JSON-valid and wiring-checked (T023)].
- [ ] T026 Contract tests (background; **ask before any bench run**):
  offline `tests/contracts/test_module_contracts.py`; add the module to
  `tests/contracts/bench_modules.py`'s `BYPASS_EXPECT` (bypass = passthrough of
  inlet 1, not a neutral — different table comment than tensormap's).
  — [PENDING PARENT: shared files + bench] the BYPASS_EXPECT entry is
  recorded in REGISTRATION_NOTES.md (`"f_tf_aniso_blur":
  ("passthrough-by-design",)` — check how f_vf_seeds' non-neutral bypass
  case lands; aniso_blur's bypass is a PURE passthrough of inlet 1, so it
  may fit the standard assertion once the harness compares against the
  source rather than a neutral — owner note: state it as
  passthrough-of-inlet-1 in whichever form the table's schema takes).
- [ ] T027 Close and reopen in Max; load in a Vsynth session: params
  addressable, unconnected tensor → isotropic blur of source, unconnected
  source → black, bypass → passthrough. Screenshot-worthy behaviors are the
  two unconnected cases (the spec's guard claims, now live).
  — [PENDING MATT: live session]

**Checkpoint:** Patcher loads, drift-clean, contract tests green, unconnected
and bypass behaviors confirmed. → Proceed to Phase 4. — definition.py built
and JSON-validated (T023); live-load/drift/contract checks PENDING
PARENT/MATT (registration).

## Phase 4: Integration check — Chain A

> **PENDING MATT (out of this build's scope, per the owner directive):**
> T028-T029 are live Vsynth wiring checks; none executed.

---

## Phase 4: Integration check — Chain A

**Purpose:** This module exists as the fourth stage of Chain A
(`ideas/f_tf_expressive_consumers.md`: tensormap → smooth → sharpen →
aniso_blur) and first of all as the standout look on its own.

- [ ] T028 Wire `jit.gl.bfg → f_tf_tensormap → f_tf_aniso_blur` (same
  texture to both inlets = denoise mode): confirm the kernel visibly follows
  the tensor field — rotate the structure source 90°, the blur direction
  rotates with it.
  — [PENDING MATT: live session]
- [ ] T029 Wire the expressive variant: tensormap on inlet 0 fed by one
  texture, inlet 1 fed by a *different* texture (e.g. bfg structure
  sharpening the blur of a video source): confirm the kernel field decouples
  from the smoothed content exactly as the spec's two-inlet story promises.
  If `f_tf_smooth`/`f_tf_sharpen` exist by now, insert them mid-chain for a
  full Chain A smoke; if not, note it and proceed (this phase does not
  depend on them).
  — [PENDING MATT: live session]

**Checkpoint:** Both modes render and behave; kernel follows the field. →
Proceed to Phase 5. — PENDING MATT (per the owner directive, no live
session in this build).

---

## Phase 5: Docs and handoff

**Purpose:** Promote spec to working everywhere; unblock the hatch build
(next in family order).

- [x] T030 Write `docs/f-reference/f_tf_aniso_blur.md`: param table, signal
  flow, the ADR-3 gate model in user terms, the strength-pairing note (one
  explanation, cross-linked with tensormap's docs — not a second, possibly
  diverging copy; family rule from the glyph plan), unconnected-inlet
  behaviors, cost facts with the M1 caveat, and the straight-axis v1
  constraint stated so nobody mistakes it for a bug.
  — done: "Status: Draft — codebox tier-2 bench and tier-3 live judgment
  pending" per the owner directive; structure mirrors the tensormap
  reference doc; the strength-pairing note CITES tensormap's calibration
  section and f_tensor_type.md rather than restating them (one explanation).
- [ ] T031 Update `README.md` (status table, build queue), `docs/f-reference/module-inventory.md`,
  and the constitution's Current Bpatchers if applicable.
  — [PENDING PARENT: shared files] exact rows recorded in REGISTRATION_NOTES.md.
- [ ] T032 Update `ideas/f_tensorfield.md` (hub): aniso blur built, the
  planned-consumer entry moves to built; Chain A's renderer slot documented.
  — [PENDING PARENT: shared file] exact line recorded in REGISTRATION_NOTES.md.
- [ ] T033 Update `HANDOFF.md` (short; task-level detail lives here).
  — [PENDING PARENT: shared file] exact line recorded in REGISTRATION_NOTES.md.
- [ ] T034 Commit. Suggested split: spec/plan/tasks; tests and codebox;
  patcher and registration; docs. Plain message style per recent history.
  — [PENDING PARENT: no commits allowed in this build (owner constraint)].

**Checkpoint:** Docs written, README updated, git clean.

---

## Dependencies & Execution Order

- Phase 0 → 1 → 2 → 3 → 4 → 5, strictly sequential.
- T002 (kernel-family gate *setup*) blocks T005/T006 (both mirrors must
  exist for the gate to compare); the ADR-2 *decision* itself is T015 in
  Phase 1.
- **T003 (idiom read, with GlyphTriad coordination) blocks T004**: the
  decode lines come from the idiom, not from re-derivation.
- T004 blocks T005/T006 block T007-T009 (reference and invariants need
  kernels to check).
- Phase 1: T011/T012 parallelizable (two codeboxes, independent compiles);
  T013/T014 need both compiled; T015 needs T013+T014; T016 needs T015
  (points at the chosen file).
- T018-T019 inform T020; T020 blocks T022 (locked defaults go into
  definition.py).
- No parallel work with sibling triads inside the bench: bench time is
  scarce and Stage outputs are shared resources (tests/README multi-stage
  discipline).

---

## Notes

- **No consumer-side assumptions about `f_tf_smooth`/`f_tf_sharpen`**: they
  are build-order predecessors, not dependencies; this module builds and
  tests standalone.
- **The G-channel strength echo is a real design constraint** (spec OQ3 /
  plan ADR-3): the tier-1 mirror parameterizes both strengths and records
  the coupling; tier 3 decides the story. If a later session "fixes" the
  coupling by silently ratio-gating, point them at the spec's OQ3 rejection
  reason.
- **The isotropic fallback is exact isotropic blur** (spec acceptance
  criterion), not "approximately isotropic behavior" — the tier-1 tests
  enforce equality against the reference. If a kernel family cannot deliver
  that exactly, the family is wrong, not the test.
- **Cost scales with TAPS_MAX, not the dial** (tensormap ADR-3 fact,
  inherited): turning `length` down saves no frame time; say so in the docs.
- **vs_black decodes non-SPD, not zero** (guard section; joint finding with
  the glyph triad): the all-zeros unconnected case produces λ1 = 1 with a
  phantom axis — a trace gate alone would misfire only if it gated on
  energy; this module's W gate does, hence the SPD check is the primary
  defense. Do not "simplify" the guard away.
- **Straight-axis only in v1** (plan ADR-4): the corner-cut artifact is a
  documented tradeoff, assessed in tier 3, not a bug report magnet — hence
  the T019 wording.
- Hard constraint: no script in this task list calls the Anthropic API.
- Total tasks: 34