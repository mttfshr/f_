# Implementation Plan: f_tf_hatch

_Date: 2026-10-17_
_Spec: .specify/f_tf_hatch/spec.md_
_Triage: ideas/f_tf_triage.md (review outcome 2026-10-17: build as proposed; Phase-0 gate
= cost shape OQ1). Lineage: ideas/f_tf_expressive_consumers.md (hatch entry),_
_ideas/f_tf_build_brief.md (§4 catalog + §6 OQ1), ideas/f_tf_jitfx_audit.md (§2.4/§3: look
is open ground)._

---

## Summary

`f_tf_hatch` is a stateless, multi-stage `pix_chain` rendering discrete marks oriented
and shape-committed by a decoded structure tensor. Three forward stages, no feedback
pass:

```
in0 -> stage E1  eigen decode + per-pixel commit (closed-form; fixed in both branches)
    -> stage E2  mark layout            (THE COST-SHAPE GATE SUBJECT — branch T or S)
    -> stage E3  mark render + tone/compose + encode (only stage that clamps)
```

The spec deliberately does not pick the E2 branch; **Phase 0's first task is the
cost-shape decision gate** (NumPy spike + cost reasoning, spec Open Question 1). The
tier gate and mirror follow it, mirroring the tensormap plan's structure (`.specify/
f_tf_tensormap/plan.md`), whose conventions — bounded loops with weight gating (ADR-3),
float32-until-the-encode (ADR-4), in-shader coordinate clamping, neutral guards (ADR-6)
— this plan inherits rather than re-argues.

This module is the fifth in the confirmed triage build order: smooth → glyph →
sharpen → aniso_blur → **hatch** → mix. Earlier triads exist upstream
(`.specify/f_tf_glyph/` etc.); hatch consumes raw-tensor inlet 0 through the canonical
per-consumer decode idiom recorded there (ADR-2 below).

## Technical Context

**Environment:** Max 9, Vsynth, `jit.gl.pix` gen codeboxes, `@type float32` throughout.
**Build method:** NumPy mirror (tier 1) → codeboxes on the bench (tier 2) → scratch
patch (tier 3) → `definition.py` → `build/build_patcher.py`.
**Statement budget:** a codebox compiles at ~250 statements per function body / ~450
whole program (`skills/jit-gen-codebox`); loop bodies tolerate more, functions called
repeatedly are counted once. Each stage below is specified to stay well under this;
E2/E3 may split further in Phase 1 exactly as `f_vf_seeds` split when it hit the
 ceiling (its Architecture section).
**Output:** `package/patchers/f_tf_hatch.maxpat`.
**Tensor contract:** `docs/f-reference/f_tensor_type.md` (decode from outlet 0 raw;
consumer rules 1/4/5 as cited in spec).
**Family conventions:** `docs/f-reference/discrete_item_conventions.md`
(regularity/phase/softness semantics, size+stretch finding, bipolar depths);
`ideas/discrete_item_family.md` (framework).
**Mark-mechanics reference:** `docs/f-reference/f_weave.md` (branch T's distance-field
algorithm — cited, never re-derived); `docs/f-reference/f_vf_seeds.md` (hash-cell
placement, seed-local frames, multi-stage split precedent).
**GPU budget:** performance claims at HD/4K on the M3 Max bench floor unless noted;
M1 unmeasured (ways-of-working; spec OQ7).

## Files

```
.specify/f_tf_hatch/
  spec.md             done
  plan.md             this file
  tasks.md            next to this file
  definition.py       written in Phase 5
  codebox_stage_e1.gen     Phase 1 (branch-independent decode+commit)
  codebox_stage_e2_T.gen   Phase 1 (branch T per T001: tileable distance field)
  codebox_stage_e3.gen     Phase 1 (render/compose/encode)
  spike/                   T001 renders (.pgm/.png), not committed code
    (branch S's files -- codebox_stage_e2_S_p1/p2.gen -- are DELETED at the
     T001 gate, never stubbed)

tests/
  spike_tf_hatch_costshape.py   Phase 0 gate: both branches in NumPy + cost model
  test_tf_hatch.py              tier 1 NumPy mirror, one function per stage  (Phase 0)
  bench_tf_hatch.py             tier 2, real codeboxes on the GPU (WRITTEN, not executed)

~/Vsynth/patterns/ (not in repo)
  tf_hatch_scratch.maxpat       tier 3 judgement (Phase 2 — pending Matt)

docs/f-reference/
  f_tf_hatch.md                 as-built reference                          (Phase 6)
```

The branch-conditional file names above (T vs S) record the decision's consequences in
the layout itself; the unchosen set is deleted at the gate, not stubbed
(no-branch-yet is the only state in which both name sets exist).

## Architecture Decisions

### ADR-1: The E2 branch is a measured gate, not a design opinion

**Context:** OQ1 (stroke-marching vs tileable distance field) is the confirmed Phase-0
gate (`ideas/f_tf_triage.md`: "decided by a NumPy spike + cost estimate, not by this
triage"). Nothing in the docs picks a branch.

> **AMENDMENT (T001, 2026-10-17): BRANCH T (tileable distance-field) chosen.**
> The spike (`tests/records/spike_tf_hatch_costshape.py`, NumPy-only — no bench, no
> codebox before the gate) implemented both branches on three synthetic fields
> (concentric-ring/tangential-axis, isotropic blob, authored waves) at 96x128:
>
> - **Cost model** (vs the published floors, `docs/f-reference/f_tf_tensormap.md`
>   Cost: ~0.9 ms/pass upper bound at 1080p with 33 taps/pass at R_MAX 16;
>   M3 Max, M1 unmeasured — carried per spec OQ7):
>   - Branch T: **3 passes** (e1/e2/e3), loop depth 0, ~6 texture taps/pixel
>     (all at `norm`), ~85 statements/program (~450-program capture ceiling
>     clears with headroom even with E2/E3 unsplit) → model **≤ 2.7 ms at
>     1080p** (3 × the 0.9 ms/pass floor) — the same pass class as
>     tensormap itself.
>   - Branch S: **≥ 5 passes** (e1; seed search a+b — `f_vf_seeds` needed
>     TWO search halves for 18 candidates under the ~250-statement/function
>     capture ceiling, plus a merge; march/render; encode; the seeds
>     precedent reached SIX stages), **75-90 texture taps/pixel** at seed
>     level (9-18 search + two-sided march: 2 winners x (2*MARCH_MAX+1)
>     axis taps at MARCH_MAX 16), loop-carried march state (the
>     `f_apollonian` for-scope precedent) → model **≥ 4.5 ms at 1080p**.
>     The sign/branch-cut problem is ARCHITECTURAL on S: the decoded axis
>     is an unoriented line (`f_tensor_type.md` rule 4), a march needs a
>     signed direction per step; the symmetric two-sided march mitigation
>     doubles the tap count again and the continuity-based sign choice is
>     exactly the complexity the gate weighs.
> - **Branch T's hairpin hazard — MEASURED, not argued:** ridge-alignment
>   metric (structure tensor of the blurred mark mask vs the decoded axis,
>   degrees, 0 = dashes aligned into coherent lines) on concentric-ring
>   fields: **24.9° at 8-px ring spacing → 34.0° (12) → 47.5° (20) → 55.9°
>   (32) → 64.0° (64)**, monotone. Calibration matters: even a single-angle
>   STRAIGHT dashed render keeps ~44-49° residual under this conservative
>   metric (the blurred tensor blends dash-interior with dash-end structure
>   in one support), so the absolute number over-reports; the relative
>   trend is the evidence, plus the rendered image
>   (`.specify/f_tf_hatch/spike/spike_curved_edge_branchT.png`): dash marks
>   visibly follow the rings. The one real observed hazard is a dash-phase
>   reset where the axis turns fast relative to the along-frame — a tier-3
>   observation, not a v1 blocker.
> - **Character:** T renders dashes following curvature (rings as dashed
>   rings), gate-quiet outside structure (iso-blob mark coverage 0.009);
>   S renders smoother continuous strokes BUT tracks the axis on fewer
>   marks on the same curved field (coverage 0.17 vs T's 0.247: seeds in
>   isotropic gaps give the march nothing to hold). What S uniquely buys —
>   true stroke identity and tone-driven engraving layering — is out of v1
>   scope (tone is OQ2, defaulted out).
> - **Decision: branch T.** `codebox_stage_e2_T.gen` is the only E2 file;
>   the S files (`codebox_stage_e2_S_p1.gen`, `codebox_stage_e2_S_p2.gen`)
>   are deleted from the Files layout (below) and tasks.md's Expected Output
>   Layout — never stubbed.
> - **Gate PROVISIONAL-CLOSED:** the resolving experiment remains the tier-2
>   bench (T013/T016 — measured per-stage cost at 1080p/4K vs this model; if
>   reality materially exceeds it, the gate re-opens). Scope note: resolved
>   via the cost model against tensormap's published per-pass floors, no
>   bench run (parent-side constraint for the parallel build).

**Decision (original, pre-gate):** T001 implements BOTH branches at small scale in NumPy on synthetic tensor
fields (a clean-edge field with curvature, an isotropic blob field, an authored
authored-field), derives the per-pixel cost model of each (loop depths, sample counts,
pass count, feedback texture count), compares against the bench's known per-pass floors
(`docs/f-reference/f_tf_tensormap.md` Cost: ≲0.9 ms/pass upper bound at 1080p), and
records the picked branch with the numbers in an ADR amendment. The spike is NumPy-only
(tier-1 discipline); no bench, no codebox before the gate.

**Rationale:** The recorded observations (spec Field Architecture: branch T proven-cost
but hairpin-aliasing hazard [INFERENCE]; branch S true-stroke character but multi-pass
cost + the sign/branch-cut march problem) are not decidable by reading; the spike makes
them measured. Cost on THIS bench is a first-class argument — the family's whole
single-codebox shape depends on it.

### ADR-2: Per-consumer in-pixel eigen decode of tensormap outlet 0 (copied idiom)

**Context:** OQ7 resolved 2026-10-17 (triage review item 3): no `f_tf_decode` module;
`jit.fx.cf.kuwahara` is C74's own precedent for in-consumer decode
(`ideas/f_tf_jitfx_audit.md` §2.1, §4.4). Glyph, the first stage-E consumer, records the
canonical decode idiom in its plan.

**Decision:** Hatch's E1 copies that idiom verbatim from
`.specify/f_tf_glyph/plan.md`, heading **"ADR-2: The canonical decode idiom lives HERE,
in this file"** (coordinated with GlyphTriad 2026-10-17), and cites it rather than
re-deriving: sample tensormap **outlet 0** (raw tensor — lossless; the packed outlet
1's clamped B and angle-doubled R/G make it wrong for a geometry-laying-out consumer,
per `f_tensor_type.md` rule 1), decode `Jxx = R/s; Jxy = (G - 0.5)*2/s; Jyy = B/s`
with the producer's `strength`, closed-form eigen (`trace`, `diff`,
`root = sqrt(diff*diff + 4*Jxy*Jxy)`, `λ1/2 = 0.5*(trace ± root)`), and
`theta = 0.5 * atan2(2.0*Jxy, diff)` labeled the **gradient** axis, with
along = theta + π/2 — all from glyph's ADR-2 block verbatim. Two pieces of E1 are NOT
glyph's and cite tensormap instead: coherence normalization `(λ1−λ2)/(λ1+λ2)`
(tensormap ADR-2, the normalized form the spike backs; glyph has no use for it and does
not restate it) and the eps-guard value, `eps_trace = 1e-6` (tensormap ADR-6/T019,
decided from the float32 floor). Strength cancels in ratios; only an optional trace
floor gate touches strength-scaled units (spec OQ2), same shape as glyph's own
consumer-side draw gate (glyph plan ADR-6, cited as precedent).

**Consequences:** Hatch inherits the ±π branch-cut behavior of decoded θ documented in
`f_tensor_type.md` rule 4 — benign for a line field (an unoriented axis flips by π and
stays the same line), which is exactly why hatch may decode θ directly where a
sign-sensitive consumer may not. E1 also writes commit + axis (+ aux outputs) to an
intermediate texture that is NEVER exposed as an outlet unless OQ5 adds one.

### ADR-3: Per-pixel commit is E1's job; shape data never comes from a dial

> **AMENDMENT (T003/T006, 2026-10-17): aspect is measured in PITCH units and
> CAPPED, "elongation+1" holds until saturation.** The spec's
> "aspect = elongation + 1" invariant is realized as the pitch-normalized
> aspect `min(1 + elongation*commit, aspect_max)`, where
> `aspect_max = 0.25/(weight*density_scale)^2` is the point where the
> dash's along half-length (in `dist_to_mark` pitch units,
> `al = weight*density_scale*sqrt(aspect)`) reaches 0.5 and dashes merge
> into solid lines. At the provisional defaults (weight 0.1, density 0.5
> -> ds = 2.83, elongation 3 → aspect 4.0) the cap binds slightly
> (aspect_max = 3.13): dashes at ~0.95 of pitch, near-merged, readable as
> broken hatching. The mirrored invariant is asserted with the cap
> (`test_commit_endpoints`, tol 0.5 pitch); a smaller `weight` dial
> uncaps it (the squeeze trade is Matt's, tier-3). Dash length at commit
> 1 follows the cap; at elongation 1 (aspect 2 < cap) it is 2*0.3*sqrt
> ... recorded in the mirror comment. This also changes E2's role: the
> aspect lives in E3 (the profile stage, `pos` units), not E2 (the frame
> stage) — E2 emits (u, v, commit, iso), E3 takes it from there.

**Context:** The glint view-in-disguise flag (`ideas/f_tf_build_brief.md` §4; audit
§4.3): a rendered tensor consumer whose shape parameter is a performer dial is a view.
The audit's gate for glint — "build only with per-pixel coherence lobe width" — is
adopted here as the commit doctrine.

**Decision:** Per-pixel coherence (the normalized eigengap) drives mark elongation
continuously between dot (commit 0) and full stroke (commit 1). `elongation` sets the
RESPONSE MAGNITUDE (the aspect at commit 1), never the shape data. `coherence_gate`
sets the floor where commit vanishes. Both are threshold/response dials, the
"legitimate performer-facing response curve" category of the expressive_consumers doc.

**Rationale:** The spec's tensor-native test — a vecfield reduction carries neither λ2
nor confidence; the per-pixel commit IS the tensor-native part (spec section). This is
the one design constant that must survive every later revision of hatch.

### ADR-4: Bounded loops only, weight-gated; floats unclamped between stages

**Context:** GenExpr loops are compile-time bound (tensormap ADR-3 idiom); in-pixel
loop depth depends only on constants. The bench GPU wraps out-of-range sampling.

**Decision:** If branch S is picked, any march loop compiles to a fixed `MARCH_MAX`
with live tap weight `step(i, march_len)` gating, normalized as in tensormap's radius
idiom, and cost scales with `MARCH_MAX` not with any dial. Every stage stays
`@type float32` with no clamp or 0.5-offset; clamping to texel centres in-shader on
every texture coordinate; only E3 clamps/encodes outputs.

**Consequences:** Same known-fact report as tensormap: turning the response dial down
does not buy back frame time on branch S. Internal textures are not valid anything-else
and are never outlets.

### ADR-5: Neutral = no marks, by the same eps_trace guard as the producer

**Context:** Zero tensor / unconnected inlet 0 / below-gate coherence must render
nothing, never an invented direction (the producer's own discipline, tensormap plan
ADR-6; `f_tensor_type.md` rule 5 documents that the PACKED outlet needs explicit
vs_black handling, but hatch reads outlet 0 whose vs_black decodes to a true zero
tensor).

**Decision:** Below eps_t on decoded trace, E1 writes commit = 0 and an explicitly
unset axis (0.0 marker rather than an atan2 artifact); E2/E3 render black/neutral. The
mirror asserts this exactly (spec acceptance criterion 1). Starting value:
`eps_trace = 1e-6`, decided in tensormap ADR-6/T019 from the mirror's float32 floor —
cited, and re-validated for this decode path during the mirror (one cheap tier-1
check, not re-derivation). The consumer-side gate shape has a same-family precedent:
glyph's plan ADR-6 (trace ≥ gate draws, below = no-mark) — cited; hatch's
`coherence_gate` is the commit-curve version of the same discipline.

### ADR-6: Verification tiers (recorded as the Phase-0 gate, T002 — AFTER the cost gate)

> **T002 RECORD (2026-10-17): all tiers apply; the tone sub-decision resolves
> to "tone stays OUT of v1".**
>
> - **Tier 0 (cost spike) — ran FIRST, as ADR-1's amendment records.** The
>   gate closed on branch T with the cost model above.
> - **Tier 1 (NumPy mirror) — applies.** The commit curve, the family pattern
>   math (density log map, phase scroll, regularity hash, softness feather)
>   and the decode have independent ground truth (analytic fields,
>   `np.linalg.eigh` cross-check — the tensormap mirror's method, T006
>   there). Mutation check required (T008).
> - **Tier 2 (bench) — applies, WRITTEN-NOT-RUN in this build's scope.**
>   `tests/modules/tf_hatch/bench_tf_hatch.py` + the three codeboxes are written and
>   registered (in benchdeps.DATA via REGISTRATION_NOTES.md), per the
>   parent-side hard constraint: never executed here. The bench, with the
>   spike's model as its prediction, is the gate's PROVISIONAL-CLOSED
>   resolver (T013/T016 pending bench).
> - **Tier 3 (scratch patch, live judgement) — applies, PENDING MATT**
>   (Phase 2/4 out of this build's scope; the provisional
>   `coherence_gate`/`density`/`elongation` defaults stay provisional).
>
> **Tone (OQ2) sub-decision — OUT of v1, recorded:** spike evidence —
> branch T's per-pixel budget has room for one more `norm` tap (a tone luma
> read is ~free in cost), BUT (a) the tone-gating look (where marks appear
> in the tonal landscape) is a live-tier judgement call, not a NumPy-
> decidable one, and (b) the density-band engraving scheme is a second
> mark system (cross-hatch layers), which the spec puts out of v1 scope.
> The spec's inlet-1 PROVISIONAL row is declined: inlets stay single in v1,
> tone gating is deferred with the cross-hatch layer to a v2 (the doc row
> already reads "PROVISIONAL pending OQ2" and REGISTRATION_NOTES.md carries
> the exact needed spec edit). E3 stays tone-free; `bench_tf_hatch.py` is
> written single-inlet. If a live session later wants tone, the correct
> mechanism per the spike is inlet-1-luma (cheap), NOT density layering
> (multi-pass) — recorded as the v2 pointer.

**Decision:**

- **Tier 0 (cost spike: `tests/records/spike_tf_hatch_costshape.py`) applies FIRST** — this is
  OQ1's gate itself, NumPy-only, ahead of everything.
- **Tier 1 (NumPy mirror: `tests/modules/tf_hatch/test_tf_hatch.py`) applies** — the commit curve, the
  family pattern math (density log map, phase scroll, regularity hash, softness
  smoothstep), and the decode invariants all have independent ground truth (analytic
  fields; NumPy `np.linalg.eigh` cross-check, as the tensormap mirror used).
- **Tier 2 (bench: `tests/bench_hatch.py`) applies** — real codeboxes to compile, a
  cost question (per stage and chain), and parity vs the mirror incl. border rows
  (the bench GPU wraps out-of-range coords — clamp in-shader, tensormap T012 finding).
- **Tier 3 (scratch patch) applies** — commit/density/gate/elongation defaults on real
  chains (smooth→sharpen→hatch when those upstream modules exist; tensormap-only if
  they do not yet), the line→dot character judgement. **Ask before any bench run**
  (ways-of-working); tier-1 NumPy runs are cheap and need no ask.

**Consequence:** No tier is skipped; the gate record in tasks.md states this with
reasons. Test discipline identical to tensormap's tasks header (one affected test,
background, `-q`, never rerun the bench to re-verify).

### ADR-7: Naming, outlets, signal_type — decided by precedent, recorded cheaply

**Context:** The family prefix `tf_`, discrete-family param vocabulary, and
`signal_type` tagging are all settled by the tensormap triad (`f_tf_tensormap`
naming; build_patcher `signal_type` with the amber `tensor` color added 2026-10-16).
Hatch adds nothing new here.

**Decision:** Name `f_tf_hatch`, prefix `hatch`, object `hatch_pix`, two outlets
(hatch output; mark mask) per the discrete-item outlet convention
(`f_vf_seeds`' outlet 1). Outlets labeled with the tensor-family outlet style but are
ordinary scalar/luma outputs, NOT tensor-typed (they are rendered marks, not field
data) — a note recorded so outlet colors do not mislead (`signal_type` decision to be
confirmed at the build gate for this module, mirroring tensormap T030).

**Rationale:** They are cheap decisions and expensive to rename later
(tensormap ADR-7's own words).

### ADR-8: Statelessness and the upstream contract

**Context:** Hatching is the family's most flicker-sensitive consumer (expressive_
consumers hatch entry, failure modes). `f_tf_smooth` upstream is its mitigation.

**Decision:** Hatch holds NO feedback pass inside the module — stateless, cannot
self-oscillate, does the same job regardless of what runs upstream. The smooth→sharpen→
hatch chain is expressed in scratch-patch and docs phases only; if those upstream
modules have not shipped when hatch's tier-3 phase runs, the scratch patch runs on
tensormap output and notes the flicker caveat rather than growing a local smoother.

**Consequence:** Chain B/D readiness (spec Upstream contract section) is a docs-level
statement, not an in-module dependency; nothing in hatch blocks on unshipped modules.

### ADR-9: Aspect in pitch units, capped at dash saturation (T006 finding)

**Context:** The spec's "aspect = elongation + 1" invariant is underdetermined:
aspect measured in raw pixels differs from aspect in line-pitch units. The mirror
work (T006) measured both and found the pitch-unity reading is the only one where
the dot/line continuum stays calibration-free (a dash that saturates its pitch
reads as a solid line, collapsing the commit-1 endpoint into weight saturation).

**Decision:** Aspect is the pitch-normalized ratio; mirror and codebox implement
`al = min(weight*density_scale*sqrt(aspect), 0.5)` — the 0.5 cap is where the
along half-length (in dist_to_mark pitch units) reaches half a pitch and dashes
merge. Equivalently `aspect_max = 0.25/(weight*density_scale)^2`: at the
provisional defaults it binds at elongation ~2.1 (aspect_max 3.13 vs 4.0), meaning
defaults render near-merged hatching; a lighter `weight` uncaps it. The invariant
is asserted with the cap (test tolerance 0.5 pitch units).

**Rationale:** `elongation` stays a response-magnitude dial (ADR-3's doctrine);
the cap is the profile's natural saturation, not a second shape dial. A cap-free
aspect renders solid white above `aspect_max` (measured in the mirror), which
falsifies the dot->line continuum.

## Dependency Blocks

### Block 0: Cost-shape spike (OQ1 gate) — BLOCKING, FIRST
**Dependencies:** none
**Builds:** `tests/records/spike_tf_hatch_costshape.py` (both branches at small scale; cost
model per branch; per-pixel sample/loop counts; comparison vs known bench floors)
**Verification:** gate record in tasks.md: branch picked with numbers; unchosen branch
file names removed from this plan; ADR-1 amended with measured evidence.

### Block 1: Tier-1 mirror (math + commit curve, branch-specific pattern math)
**Dependencies:** Block 0 (E2 branch decided)
**Builds:** `tests/modules/tf_hatch/test_tf_hatch.py` — E1 mirror (decode, commit, guard); E2 mirror
(branch pattern: distance-field math or seed/march, family density/phase/regularity
hashes); E3 mirror (profile, tone gate if OQ2 kept it, encode)
**Verification:** analytic ground truth (rotated synthetic tensor fields; eigh
cross-check; commit-curve endpoint/monotonicity invariants; family formula parity vs
f_weave's published algorithm for branch T); one mutation check.

### Block 2: Codeboxes on the bench
**Dependencies:** Block 1
**Builds:** `codebox_stage_e{1,2,3}.gen` (per the picked branch), `tests/bench_hatch.py`
**Verification:** per-stage GPU parity vs mirror incl. border rows; compile under the
statement budget; cost measured per stage and chain at 1080p and 4K; `bypass` +
unconnected behavior (bench-level where testable — bypass mix may need Phase 5's
module-level test, the tensormap T018 precedent).

### Block 3: Judgement on real content
**Dependencies:** Block 2; (upstream ideally `f_tf_smooth` + `f_tf_sharpen`, else
tensormap-only + caveat)
**Builds:** `~/Vsynth/patterns/tf_hatch_scratch.maxpat`
**Verification:** commit curve reads correctly (structure→strokes, isotropic→dots per
gate); `density`/`coherence_gate`/`elongation` provisional defaults confirmed or
corrected with Matt's call recorded (spec OQ6); hairpin-aliasing check (branch T) or
march behavior (branch S) observed on curved synthetic fields.

### Block 4: definition.py and build
**Dependencies:** Block 3; OQ2 (tone inlet) and OQ3 (commit curve form) closed
**Builds:** `definition.py`; `build/build_patcher.py` output; menu registration
**Verification:** loads in Vsynth; params addressable; both outlets render; bypass and
unconnected give the neutral; drift-clean; contract tests green (`tests/
test_module_contracts.py`, `tests/contracts/bench_modules.py` BYPAss table entry; add to
`tests/lib/benchdeps.DATA`; do NOT add to `tests/bench.sh` DEFAULT until Matt says it is a
regression gate — the tensormap T021 discipline).

### Block 5: Docs and handoff
**Dependencies:** Block 4
**Builds:** `docs/f-reference/f_tf_hatch.md`; helpfile via the f-helpfile skill +
`skills/module-preflight/` checklist incl. its content judgment gate; README row,
module-inventory row, constitution naming rows only if anything is new (none expected).
**Verification:** preflight gate passes; chains B/D sections of the docs updated so
hatch's slot in the engraving/motion chains is unblocked (cross-link back to
`ideas/f_tf_build_brief.md`, `ideas/f_tf_triage.md`, `ideas/f_tf_jitfx_audit.md`,
`ideas/f_tf_expressive_consumers.md`, the upstream triads).

## Implementation Phases

### Phase 0: Cost-shape gate + tier gate + mirrors (BLOCKING)
**FIRST, T001 the OQ1 gate:** NumPy implementations of BOTH branches at small scale on
synthetic tensor fields, per-branch cost model, per-branch character notes; record the
decision gate. **SECOND, T002 the tier gate:** record ADR-6 (all four tiers apply, why;
what each tier settles). **Then the tier-1 mirror** (E1 decode + commit curve first —
it is branch-independent and load-bearing — then the branch pattern math).

Exit: gate decided with numbers; mirror matches analytic ground truth and eigh;
mutation check catches an injected bug; provisional-vs-firm param flags updated.

### Phase 1: Codeboxes on the bench (BLOCKING)
One stage at a time, each diffed against its mirror (multi-stage modules are benched
stage by stage, tests/README). Exit: every stage compiles and matches the mirror on the
GPU incl. borders; cost recorded; the family pattern formulas are bench-parity-checked
against the tier-1 versions.

### Phase 2: E3 polish + encode + tone decision
Final stage render/compose/encode; tone-gate decision (OQ2) recorded here with the E3
wiring it implies; branch-T hairpin-aliasing mitigation (or branch-S march tuning)
settled with bench numbers if needed. Exit: E3 bench-parity green; OQ2 recorded in the
spec as closed or deferred with reasons.

### Phase 3: Stage split/merge check against the statement budget (only if needed)
If E2/E3 as spec'd exceed the ~450-statement program ceiling in combination, split per
the `f_vf_seeds` precedent (its single-compile discovery, ADR 8 there). This phase is a
gate-shaped task rather than always-run work.

### Phase 4: Scratch patch, judgement tier
Defaults, commit-character judgement, density sweep, the line→dot rounding under
`coherence_gate`, moire check between hatch frequency and glyph-grid (`grid_size`)-
scale features (expressive_consumers hatch failure modes), and the upstream-chain look
(smooth first if it has shipped). Exit: provisional defaults replaced or confirmed, recorded
in spec OQ6.

### Phase 5: definition.py and build
Read the two `pix_chain` precedents first (`.specify/f_tf_tensormap/definition.py`,
`.specify/f_vf_seeds/definition.py` — the second for params reaching non-primary
stages), write `definition.py`, build, validate JSON, register in the modules menu,
drift check, contract tests + `bench_modules` BYPASS row. Exit: loads in Vsynth,
neutral on unconnected/bypass, drift-clean.

### Phase 6: Docs and handoff
Reference doc, helpfile + preflight content gate, README/module-inventory rows,
HANDOFF, triage/expressive_consumers cross-link update (hatch's build status), chain-B
readiness note. Exit: hatch's slot in the confirmed build order is retired; no other
triad is blocked on hatch.

## Out of this plan

- `f_tf_mix` and chain B assembly. `f_tf_smooth`'s own triad. The glyph/aniso_blur/
  sharpen triads (siblings, not dependencies of this plan's writing).
- Any branch-S multi-pass feedback plumbing beyond what the OQ1 gate proves is
  affordable; if the gate picks S and the cost model is worse than modeled, the response
  is to re-open at the gate, not to ship a degraded branch silently.
- Any `f_tf_glow` work (merged into Q12 per triage).
- Color, modulation inlets, cross-hatch second layer (spec Out of Scope).