# Implementation Plan: f_vf_seeds — Priority-Generalized Selection

**Date:** 2026-07-04
**Spec:** `.specify/f_vf_seeds/spec.md`

---

## Summary

Evolves the existing, shipped `f_vf_seeds` module in place: generalizes its
seed-selection reduction from pure nearest-distance to a blendable priority
function incorporating vecfield magnitude, enabling field-driven mark
overlap without a new module, new search structure, or changes to anything
downstream of selection. Primary risk is empirical, not structural: the
actual GPU cost of per-candidate vecfield sampling (9x instead of 1x), and
finding a workable normalization between distance and field-magnitude
scales. Phase 1 isolates and resolves both before any production file is
touched.

---

## Technical Context

**Environment:** Max 9, Vsynth package, jit.gl.pix gen subpatcher
**Build system:** `tools/build_patcher.py` + `.specify/f_vf_seeds/definition.py`
**Existing production files:** `codebox_seeds.gen`, `definition.py`,
`patchers/f_vf_seeds.maxpat` (already built and registered)
**Scratch location:** `~/Vsynth/patterns/`
**Source of truth for current behavior:** direct read of `codebox_seeds.gen`,
2026-07-04

**Constitution constraints met:**
- Codebox-before-patcher: no production file touched until Phase 1/2 confirm
  the mechanism in scratch
- Specs before building: this plan follows the spec
- Scratch patch first: Phase 1 is scratch-only
- Explicit uncertainty: normalization constant and fps cost both marked
  open, not assumed

---

## Architecture Decisions

### ADR 1: Evolve f_vf_seeds in place, not a new module

**Context:** `ideas/voronoi_vs_texture_bombing.md` had left open whether
bombing-mode/overlap work belonged in a new sibling module or as a mode on
`f_vf_seeds`.

**Decision:** Evolve `f_vf_seeds` directly.

**Rationale:** Once priority is understood as a generalized quantity feeding
the same reduction loop (not a different codebox shape), there's no distinct
identity left for a separate module to have — it would duplicate this loop
with a different name. Reasoned through directly with Matt, 2026-07-04.

**Consequences:** `ideas/voronoi_vs_texture_bombing.md`'s "where each
module's identity likely lands" section needs a status update once this plan
lands (tracked in spec Phase 4).

### ADR 2: Keep the 9-candidate (3x3) search; do not reduce to 4

**Context:** Gustavson's 2011 GPU cellular-noise optimization reduces 3x3 to
2x2 for a real GPU win, but correctness requires the true nearest jittered
point to always fall within the smaller search window — which fails at this
codebox's current jitter range (up to ±0.5 cell offset at `jitter=1.0`, which
the param already treats as a meaningful, expressive live-performance
setting, not an edge case).

**Decision:** Keep 9. Accept the cost. Revisit only if Phase 2's fps
measurement shows 9-candidate field-sampling is prohibitive.

**Rationale:** Reducing candidate count would silently change what the top
of an already-expressive, already-performed `jitter` dial means. That's a
real interface regression, not a free win — not worth taking before even
knowing whether 9-candidate cost is a real problem in practice.

**Consequences:** Phase 2's fps number is the actual arbiter here, not
assumption. If it comes back fine, ADR 2 is settled and doesn't need
revisiting. If not, the 4-cell option is not gone, just deferred until this
measurement forces the question.

### ADR 3: Priority swap is local to the selection reduction; nothing
downstream changes

**Context:** Confirmed by direct read of `codebox_seeds.gen` —
`best_gx`/`best_gy`/`best_dx`/`best_dy` are the only values the reduction
produces, and everything after (vecfield sampling for orientation, mod-tex
sampling, along/across projection, shape-tex gating) already operates on
whichever candidate is selected, with no assumption baked in about *why* it
was selected.

**Decision:** Confine all changes to the 3x3 candidate block and the
reduction chain. No changes to orientation, gating, or shape-tex logic.

**Rationale:** Minimizes risk — this is a swap, not a rewrite. Also makes
Phase 1 scratch-testable in isolation: if the selection swap works,
everything else is already proven by the shipped module.

**Consequences:** If Phase 1 reveals a downstream assumption that does break
(not currently expected), that's a scope increase to flag explicitly, not
quietly absorb.

### ADR 4 — REVERSED 2026-07-04: `field_gain` + `field_range` menu ship as
live params, not a baked-in constant

**Original context (2026-07-04, superseded same day):** Squared distance
and field magnitude have no natural common scale — a raw mix would make
`field_priority` either invisible or totally dominant depending on the
vecfield in use. Original decision: find one normalization constant
empirically, bake it into the codebox, don't expose it live.

**Why reversed:** Empirical testing across four vecfields (gradient test
field, Repulse, Vortex, Flow) found the useful scale window varies by
roughly 7.5x between fields (Flow ~±0.2, Vortex ~±1.5) — not tuning
noise, a real per-source difference. There is no single constant to
bake in; one that works for Flow does nothing on Vortex, and one that
works for Vortex immediately collapses Flow into the degenerate
wedge-collapse regime (see spec.md's Character Space table). Hiding this
as a scratch-only detail would mean re-finding a working value by hand
every time a different vecfield is patched in — worse than exposing it,
since it's not a one-time setup cost, it's a per-source cost every time.

**New decision:** Ship two live params instead of one hidden constant:
`field_gain` (a full-resolution -1..1 performable dial) and `field_range`
(a discrete menu, options labeled numerically per Vsynth convention —
`"0.2"`, `"0.8"`, `"1.5"`, not descriptive names like "Narrow/Medium/
Wide" — since this menu selects a value range) selecting which
multiplier applies to `field_gain`. The three menu tiers are the three
empirically-tested per-field windows directly, not arbitrary round
numbers.

**Rationale for a menu over a continuous nonlinear response curve:** a
continuous power-mapped dial (the `density_scale`-style
`pow(2.0, x*k-1)` idiom already used elsewhere in this module) was the
first option considered, but Matt's call was a discrete range-selector
menu instead — direct precedent already exists in this codebase:
`f_vf_repulse`'s `mode` param (`"type": "menu"`, `floor(mode)` +
`if/else if` branching on half-integer boundaries). Reusing that exact
idiom here keeps the interface language consistent with a module the
performer already knows, rather than introducing a new control shape.

**Consequences:** `field_scale` is no longer scratch-only — it's now
`field_gain * range_max`, computed live in the codebox from two shipped
params. Definition.py's param list must include both `field_gain` (float)
and `field_range` (menu, options `["0.2", "0.8", "1.5"]` — numeric labels
per Vsynth convention). No change to the priority formula itself —
`field_scale` still feeds `mix(d, -field_mag*field_scale, field_priority)`
exactly as before; only what produces `field_scale` changed.

---

### ADR 5 — `build_patcher.py` bug found and fixed: `driving_inlet` flag

**Context:** After Phase 3's rebuild, Matt reported something wrong and asked
to double-check inlets/types. Traced through three coupled layers of
`build_patcher.py` (outer `jit.gl.pix` inlet count in `pix_box()`, outer
wiring in `mod_inlet_lines()`, codebox wiring in `gen_subpatcher()`) and
found all three assumed `mod_inlets` are always *optional secondary
modulation* on a self-sufficient generator (true for `f_vf_vortex`'s cx/cy/
curl mod — no driving texture exists there, so a dedicated control-only
`in 1` is correct and intentional). `f_vf_seeds` was using the same
mechanism for its three *primary, required* content inlets (shape tex,
vecfield, mod tex), which per Vsynth convention need inlet 0 to carry the
driving texture *and* all control messages combined — no separate
control-only channel. The mismatch shifted every real texture input up by
one position and left the true last inlet (mod tex) unconnected to
anything in the codebox.

**Decision:** Added an opt-in `driving_inlet` flag, threaded through all
three layers (`pix_box()`, `mod_inlet_lines()`, `gen_subpatcher()`),
defaulting to `False` everywhere so `f_vf_vortex`/`f_vf_vortex_multi` are
completely unaffected. Set `"driving_inlet": True` on `f_vf_seeds`'s
`definition.py` only.

**Rationale:** The codebox itself (`in1`/`in2`/`in3` for shape/vecfield/
mod) was already correct — the bug was entirely in the build script, not
the codebox authoring, so no codebox changes were needed. Confirmed the
generic `mod_inlets` mechanism is genuinely two different things wearing
one name: "optional modulation" (vortex) vs. "primary content" (seeds) —
this is the concrete case underlying the broader generator/processor/
source taxonomy note logged in `ideas/module_taxonomy_standardization.md`.

**Consequences:** Rebuilt and verified structurally: outer `vfseeds_pix`
box `numinlets: 3` (was 4), codebox `numinlets: 3` (was 4), gen subpatcher
has exactly `in1`/`in2`/`in3` (no phantom bang, no orphaned 4th inlet).
Not yet confirmed live in Max — JSON validity and structural inspection
aren't proof of correct behavior at the patching level.

---

## Dependency Blocks

### Block 1: Selection-swap mechanism proven in scratch
**Dependencies:** None
**Builds:** Scratch codebox with per-candidate vecfield sampling +
`field_priority` blend
**Verification:** Field-driven overlap visually reads as
field-information-driven, not noise; jitter at mid/high settings unaffected

### Block 2: Cost and normalization resolved
**Dependencies:** Block 1
**Builds:** fps measurement (9x vs 1x sampling), normalization constant
**Verification:** fps delta documented; character space table in spec
confirmed or corrected against what's actually observed

### Block 3: Promoted to production
**Dependencies:** Blocks 1 + 2
**Builds:** `codebox_seeds.gen`, `definition.py` updated;
`patchers/f_vf_seeds.maxpat` regenerated
**Verification:** JSON valid; opens in Max; all params (existing +
`field_priority`) respond; UI correct; existing shipped behavior at
`field_priority=0` unchanged (regression check)

### Block 4: Docs + ideas-doc reconciliation
**Dependencies:** Block 3
**Builds:** `docs/f_vf_seeds.md`, helpfile, updated ideas docs
**Verification:** Attribution present per attribution practice; ideas docs
reflect landed status, not stale open-question framing

---

## Implementation Phases

### Phase 1 — Selection swap in scratch patch

Goal: prove the mechanism works visually, in isolation, before any
cost/normalization tuning.

- [ ] Copy `codebox_seeds.gen` to
      `~/Vsynth/patterns/f_vf_seeds_priority_scratch.gen` (or equivalent
      scratch patch)
- [ ] Add per-candidate vecfield sampling (`sxA/syA` through `sxI/syI`,
      before selection)
- [ ] Add `field_priority` param; implement `priority = mix(d, -field_mag,
      field_priority)` in the reduction chain (rough/placeholder scale
      constant, refine in Phase 2)
- [ ] Verify visually: at `field_priority=0`, output is pixel-identical to
      current shipped behavior
- [ ] Verify visually: at `field_priority>0`, overlap appears in
      field-convergence zones
- [ ] Verify: `jitter` at 0.5/1.0 settings still looks as expected
      (regression check)

**Checkpoint:** Mechanism confirmed working, mechanically. Cost and
correct-scale tuning not yet resolved.

### Phase 2 — Cost and normalization tuning

Goal: know the real fps cost, and find a normalization constant that makes
`field_priority` a usable 0–1 dial.

- [x] Measure fps at target performance resolution: current 1-sample
      baseline vs. 9-sample scratch version — **1920×1080: 60+fps.
      3840×2160: 58–60fps.** Cost is negligible at this resolution; the
      9-candidate field-sampling scratch codebox is effectively free.
      **ADR 2 is now confirmed by evidence, not just deferred** — no
      pressure to revisit the 4-cell search.
- [x] Document the delta plainly — no framing, just the numbers (above).
- [ ] Explore normalization constant empirically — **in progress, not yet
      closed.** Findings so far:
      - Gradient test field: `field_scale=0.266` at `field_priority=0.5`
        — clean partition warp, no artifacts.
      - Repulse: `field_scale=0.1` and `0.81` at `field_priority=0.10` —
        real, confirmed-moving seam at low `field_scale`; clean isolated
        blob (traces the field's radial falloff) at `0.81`, tested at
        `jitter=0`.
      - **Vortex and Flow still untested in the actual 0–1
        `field_priority` range** — only tested at `field_priority=1`,
        which is a degenerate case (see finding below) and doesn't
        exercise `field_scale`'s magnitude at all.
      - **Tuning technique discovered, worth adopting as standard
        practice:** test at `jitter=0`. With no jitter, the distance term
        is perfectly uniform across the frame, so any distortion visible
        is attributable directly and cleanly to the field-priority term
        — no jitter noise competing for attention. Tune `field_scale`
        this way per field, then bring jitter back up and reconfirm it
        still reads correctly combined with real jitter noise.
      - **Correction to spec.md's Character Space table:** at
        `field_priority=1.0` exactly, `mix(d, -field_mag*field_scale, 1.0)`
        discards the distance term completely — only the *sign* of
        `field_scale` can affect the outcome at that boundary value, not
        its magnitude (provable directly from the formula, confirmed
        visually — blocky wedge-collapse regions, same shape regardless
        of `field_scale`'s magnitude, across three different fields
        tested). This is a distinct degenerate regime, not a continuation
        of "high field_priority" overlap character. The graded,
        genuinely tunable behavior only exists in the open interval
        `0 < field_priority < 1`. Spec's Character Space table needs
        updating to reflect this as its own row, not folded into "high."
- [ ] Decide: is the cost acceptable given the fps number — **yes,
      settled** (see fps finding above). Remaining Phase 2 work is purely
      the normalization constant, not a cost decision anymore.

**Checkpoint:** fps question closed. Normalization constant has real data
across two fields (gradient, Repulse) plus a confirmed tuning technique
(`jitter=0` isolation), but not yet closed — Vortex and Flow still need a
data point in the actual 0–1 range before generalizing to a single
constant (or concluding one doesn't generalize and needs to scale with
something about the field itself).

### Phase 3 — Promotion to production

Goal: confirmed scratch mechanism becomes the shipped module.

- [ ] Update `codebox_seeds.gen` with confirmed mechanism and resolved
      normalization constant
- [ ] Update `.specify/f_vf_seeds/definition.py` — add `field_priority`
      param to the param list
- [ ] Run `tools/build_patcher.py .specify/f_vf_seeds/definition.py
      patchers/f_vf_seeds.maxpat`
- [ ] Validate JSON: `python3 -c "import json;
      json.load(open('patchers/f_vf_seeds.maxpat'))"`
- [ ] Open in Max; verify all params respond; verify UI layout includes new
      param sensibly
- [ ] Regression check: `field_priority=0` output matches pre-change
      behavior exactly

**Checkpoint:** Patcher opens, all params work, no regression at default.

### Phase 4 — Integration, docs, reconciliation

Goal: documented, integration-tested, ideas docs brought up to date.

- [ ] Re-verify existing integration points f_vf_seeds already participates
      in — no regression
- [ ] Update `docs/f_vf_seeds.md` — new param, GPU Gems Ch. 20 attribution
      per attribution practice (used-directly/adapted-from/inspired-by
      language)
- [ ] Update or create helpfile per `f-helpfile` skill conventions
- [ ] Update `ideas/seed_distribution_beyond_grid.md` — mark
      priority-generalization as landed, not open
- [ ] Update `ideas/voronoi_vs_texture_bombing.md` — mark "where each
      module's identity lands" section resolved, per ADR 1
- [ ] Commit: logical units per phase, descriptive milestone messages

---

## Complexity Notes

The riskiest unknown is Phase 2's fps number — everything else in this plan
is either already proven (the selection-swap mechanism is a small,
well-understood change per ADR 3) or straightforward tuning. If 9x
per-candidate sampling turns out to be too expensive at target resolution,
the honest fallback isn't a clever shader trick — it's revisiting ADR 2
(4-cell search) with its known jitter-range tradeoff, which was deferred
rather than ruled out. No principled cost estimate exists before Phase 2
actually measures it on the real hardware/resolution target.

---

## ADR 6 — Luma-keyed alpha replaces hardcoded `1.0` on mark color output

**Context:** Matt reported (2026-07-04, after Evolution 1 shipped) that
overlapping marks — the exact zones priority-generalized selection was
built to enable — read as hard black rectangles instead of respecting the
shape tex's own masked silhouette. Traced (direct read of
`codebox_seeds.gen`) to `out1`'s alpha being hardcoded to `1.0`: the mark
footprint `gate` is a rectangular UV bounding-box test with no relationship
to the shape texture's own content, so any pixel inside the gate — shape or
black background alike — reported full opacity.

**Decision:** Use `mark_luma` (shape luma × gate — already computed,
previously only fed to the separate `out2` mask) as `out1`'s alpha channel
instead of `1.0`. Bypass output changed from opaque black `(0,0,0,1)` to
fully transparent `(0,0,0,0)`, consistent with alpha now carrying real
meaning.

**Rationale:** Same luma-gating idiom `f_grain` already uses (per README),
applied here to the alpha channel specifically. Raw luma (not a hard
threshold) chosen deliberately — gives graded/soft edges for free on any
shape tex with its own AA, no new param needed; a threshold param can be
added later if scratch testing surfaces a real need for crisper cutoffs
(none has, so far). Compositing itself stays downstream — Matt confirmed
existing Vsynth compositing modules already handle alpha-aware blending;
this module's job is just to output alpha that means something.

**Consequences:** This is a **prerequisite**, not a resolution, for real
overlap — see ADR 7/8 below and spec.md's Evolution 2. Correct alpha alone
doesn't produce multi-owner overlap; it just means that whenever a second
mark *does* get composited in, its edges will read correctly instead of as
another rectangle. Shipped to production `codebox_seeds.gen`, rebuilt,
JSON-validated same session. Not yet re-confirmed live in Max per the
"structural inspection isn't proof" standing lesson — pending Matt's
confirmation.

---

## ADR 7 — Selection reduction extended to top-2 via insertion, not just top-1

**Context:** ADR 6 fixed *how* a winning mark renders, but Matt confirmed
after testing that Evolution 1 still shows zero overlap regardless of
`field_priority`/`field_gain` — correctly diagnosed as structural:
priority-based selection only warps *which single* candidate wins each
pixel; exactly one candidate is ever drawn. There is nowhere in the
existing `step`/`mix` single-best reduction for a second candidate to ever
surface.

**Decision:** Extend the reduction to retain the top 2 candidates
(`best_*`/`second_*`), not just 1, via an insertion procedure: each new
candidate is compared to current `best`; whichever loses that comparison
(the new candidate, or the demoted old best) is then compared against
current `second`. This is a small, mechanical extension of the exact
`step`/`mix` "lower wins" idiom already used throughout this codebox — not
a new selection philosophy.

**Rationale:** Minimal-diff path to real multi-owner overlap — reuses the
existing per-candidate priority computation unchanged (ADR 1–3's territory
untouched), only the reduction's bookkeeping grows. Two ranks chosen as the
starting depth (not 3+) per Matt's direction, 2026-07-04 — cheapest version
that demonstrates real overlap, extensible later if needed.

**Consequences:** Each retained rank needs the *entire* downstream
per-candidate block (orientation projection, mod-tex sample, gate, shape
sample) run independently — this roughly doubles per-pixel work compared
to Evolution 1, and unlike Evolution 1's cheap scalar-only 9x vecfield
sampling, this cost is structurally heavier (full shape render, not a
magnitude). Not yet fps-measured. See ADR 8 — this decision's first
implementation attempt (single combined codebox) hit a hard compile
ceiling before this cost could even be measured.

---

## ADR 8 — Multi-stage `jit.gl.pix` chain required; single-codebox
implementation of ADR 7 is not viable

**Context:** First implementation attempt combined ADR 7's top-2 insertion
reduction (9 candidates, ~112 `step`/`mix` calls) with two full duplicated
downstream render blocks (one per rank) in a single codebox, pasted into
Max for scratch testing. Result: `jit.gl.pix` reported `invalid message
strength` / `method getname called on invalid object`, and the Max console
showed the actual root cause — a Lua runtime error in `gl3_transformer.lua`
during GL2→GL3 shader translation: `"DSL.Parser":393: stack overflow (too
many captures)`. Max's shader transformer parses codebox source via a Lua
pattern-matching DSL, which has a hard ~32-capture-group ceiling per
pattern match. This codebox's combined size/structure overflowed that
ceiling during compilation — a hard platform limit, not a logic bug in the
insertion or compositing math (which never actually ran; the shader never
finished compiling, and the rendered output was a stale leftover frame from
before the paste, not this codebox's actual behavior).

**Decision:** Split into a 4-stage `jit.gl.pix` chain rather than one
codebox — Stage 1 (search + top-2 select, outputs two coord textures),
Stage 2 and Stage 3 (identical render codebox, one instance per rank, each
takes a coord texture + shape/vecfield/mod tex), Stage 4 (composite).
Follows the `f_sirds` precedent directly: a custom builder script, not
`tools/build_patcher.py` (which only supports single-codebox modules per
its `pix_chain` mechanism — same limitation already documented in
`f_sirds`' own build notes).

**Rationale:** Considered and set aside: (a) trimming the single codebox to
dodge the capture ceiling — rejected, since the actual trigger (total size?
one specific expression's structure?) isn't characterized, so this risks
more guess-and-check than the debugging process calls for; (b) cutting
fidelity (e.g. skip re-deriving mod-tex/gate for rank 2) — rejected, since
it trades correctness for staying single-stage without addressing the
underlying ceiling, and would likely just move the wall rather than clear
it once bombing (Evolution 2's `K=2`) adds more candidates on top. Matt's
explicit call, 2026-07-04: multi-stage split.

**Consequences:** Stage 2/3 re-sample the vecfield at their own rank's
`gx/gy` rather than Stage 1 carrying `vx/vy` through its output — keeps
Stage 1 at 2 outlets instead of 3, small simplification enabled by the
split itself. Real, unmeasured cost: 4 render passes per frame instead of
1, on top of ADR 7's already-doubled per-rank downstream work. This must be
fps-tested (spec.md Evolution 2, Phase 3) before deciding whether it's
viable at target performance resolution — same discipline as Evolution 1's
Phase 2 fps measurement, not assumed cheap by analogy to that earlier,
structurally different result.

**Confirmed, Phase 3 (2026-07-04):** 59-60fps at target resolution with
the full 4-stage chain. Cheap, not a concern — the single biggest
open risk in this ADR resolved favorably.

---

## ADR 8 addendum — Stage 1 itself hit the SAME compile ceiling once
bombing (18 candidates) was added; split further into 1a/1b/1c

**Context:** Extending Stage 1 from 9 to 18 candidates (adding the actual
bombing samples) hit the identical `DSL.Parser` capture-group ceiling
described above — confirmed via the same console error signature. This
means the ceiling is lower than ADR 8's original framing assumed: Stage 1
*alone* at 18 candidates + top-2 selection exceeds it, with zero render
logic involved at all. The duplicated-render-logic diagnosis in ADR 8
above was correct for that specific failure, but not a complete
characterization of the ceiling itself.

**Decision:** Split Stage 1 further into three: Stage 1a (9-candidate
search + top-2 select, original hash salts), Stage 1b (identical codebox
to 1a, reused via `salt1-4`/`active_blend` params rather than a second
`.gen` file — same reuse pattern as Stage 2/3), Stage 1c (small top-2
merge across the two halves' already-reduced results — 4 candidates in,
not 9 or 18, comfortably inside anything that's compiled so far).
Pipeline is now 6 stages total, not 4.

**Rationale:** Same split-until-it-compiles discipline as the original
ADR 8 decision — proven pattern, reapplied rather than re-litigated.
Parameterizing salts into the codebox (rather than writing a second
near-duplicate `.gen` file) keeps the two search halves DRY, same
motivation as Stage 2/3 already sharing one render codebox.

**Consequences:** All three pieces (1a, 1b, 1c) confirmed compiling
independently, then confirmed correctly wired end-to-end via direct file
inspection of the scratch `.maxpat` (not just visual patch inspection —
see session process note below). Not yet independently fps-remeasured at
the full 18-candidate/6-stage configuration (Phase 4, T019) — Phase 3's
59-60fps figure above is for the 9-candidate/4-stage configuration only
and should not be assumed to transfer.

**Process note:** this session's scratch `.maxpat` was edited directly
(read/verified/edited as JSON via Desktop Commander, not only through
Matt manually patching in Max) — a departure from this project's usual
"paste codebox text into Max" convention, done at Matt's explicit
request. This worked well for codebox text edits and for verifying
wiring against what Matt described, but real content (vecfield/shape/mod
tex sources) turned out to depend on `vs_modules.maxpat`'s dynamic
menu-driven module loading — live runtime state with no static
representation in the saved file — which could not be safely
pre-wired blind and had to wait for Matt to make those specific
connections live in Max before the file could be verified complete.
Worth remembering as a boundary for this technique going forward: static
structure (codeboxes, patchlines between fixed objects) is safe to
verify/edit via direct file access; anything depending on live/dynamic
module selection is not.

---

## Addendum — `active_blend`/`bomb` cannot be a smooth blend; treated as
a toggle (2026-07-04)

**Context:** `active_blend`'s fade was implemented as
`priA = mix(sentinel, priAr, active_blend)`. Matt reported the transition
behaved like a hard switch right at `active_blend≈1.0` rather than a
graded fade. First hypothesis: `sentinel=1000.0` was simply too large
relative to real priority magnitudes (typically small, e.g. `0.001`-`0.03`
squared-distance terms at moderate `density`) — linear interpolation
between a huge sentinel and a tiny real value barely leaves "always loses"
territory until very close to `active_blend=1`. Reduced `sentinel` to
`5.0` (pulled into its own `Param` for tunability, replacing the
hardcoded constant in all 18 occurrences across both search-half
codeboxes). **Result: still a near-hard switch** (Matt: "I see a
difference between .999 and 1 and 1.001" — better than before, but not
meaningfully graded).

**Root cause, confirmed:** real priority magnitude isn't a fixed range —
it scales with `density`, `jitter`, `field_gain`, and `field_priority`
together. No single fixed `sentinel` constant can stay correctly scaled
relative to that moving target: too small and it risks not reliably
losing at `active_blend=0` for some setting combinations; too large
(relative to whatever the current real range happens to be) and the
`mix()` only produces competitive values in a narrow band near
`active_blend=1`, i.e. a switch. This isn't a tuning problem solvable by
picking a better constant — it would need `sentinel` to be computed
dynamically from the current priority range, which is real added
complexity for a control most performers would use at fully 0 or fully 1
anyway.

**Decision (Matt):** Treat `active_blend`/`bomb` as an on/off toggle, not
a graded fader. **No code change** — the existing `mix()` implementation
already behaves correctly at both endpoints (confirmed: `bomb=0` matches
Phase 3 exactly, `bomb=1` produces real bombing behavior); this is a
documentation correction (spec.md's `bomb` param description updated),
not a functional fix. A hard `step()`-gated version was considered
(`mix(sentinel, priAr, step(0.5, active_blend))`, removing the "is 0.999
really off?" ambiguity) but not applied — left as a candidate if the
soft-mix version's ambiguity near the threshold ever causes a real
problem in practice.

---

## Complexity Notes — Evolution 2

The riskiest unknown is no longer normalization or a single fps number —
it's whether a 4-stage chain (each stage itself non-trivial: 18-candidate
search when bombing lands, doubled full-render blocks, a composite pass)
holds acceptable fps at target resolution at all. Unlike Evolution 1's
per-candidate cost (a cheap scalar magnitude sample), Evolution 2's
per-rank cost is a full shape render — the two are not directly comparable,
and Evolution 1's "negligible at 4K" result should not be assumed to
transfer. If the 4-stage chain proves too expensive, the honest next
question is Phase 4.5 territory (per the debugging skill): is N=2
compositing depth itself too costly regardless of bombing, in which case
the fallback is asking whether real overlap is achievable at this
resolution/hardware at all via this mechanism — not a smaller tweak to try
first.

---

## Addendum — `route`/`prepend` rename chain silently dropped `bomb`'s
value in production; fixed with a direct-attrui approach (2026-07-05)

**Context:** `build_seeds_multistage.py`'s first version renamed the
outer `bomb` param onto Stage 1b's `active_blend` attribute via a
`route bomb` → `prepend active_blend` message chain (attrui outputs
`bomb <value>`, `route bomb` strips the selector, `prepend active_blend`
re-adds it). This compiled and validated structurally (no dangling
wires, correct box graph) but **silently failed at runtime** — Matt
reported the built module always behaved as if `bomb=1` regardless of
the dial's actual position. Console was clean (no errors); the dial
itself visibly responded to input. Root cause confirmed empirically by
Matt placing a `print` object in the chain: the value never reached
`prepend active_blend` — dropped somewhere in the `route bomb` stage.
Exact Max-internal reason not diagnosed further (not needed once the
simpler fix below was found and confirmed working).

**Fix (Matt's, confirmed working live in Max before being ported back
into the builder):** skip the rename chain entirely. An `attrui`'s
*output* name comes from its own `attr` property, not from whatever fed
its inlet — so the `bomb` dial can just feed an `attrui` bound directly
to `attr="active_blend"`, no intermediate renaming needed at all. The
dial itself keeps `parameter_longname="bomb"` (so it still displays,
saves, and automates as "Bomb"); only the *attrui downstream of it* is
bound to the real internal attribute name. Ported into
`build_seeds_multistage.py` as a generalized `attr_name` field (defaults
to the param's own name, overridden only for `bomb`) rather than a
special-cased target string — removes the `1b_active_blend` special
case from the per-param wiring loop entirely, not just fixes `bomb`
specifically.

**Process note, worth remembering:** this is the second time this
session a structurally-valid, JSON-verified patch turned out to be
functionally broken at runtime (see also ADR 8's compile-ceiling
discovery, a different failure mode but the same lesson) — static
verification (no dangling wires, valid JSON, correct box graph) is
necessary but not sufficient. Confirmation in actual running Max,
including targeted diagnostics like a temporary `print` object when a
value silently doesn't arrive, remains the only real proof.
