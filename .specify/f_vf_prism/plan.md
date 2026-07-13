# Implementation Plan: f_vf_prism

**Date**: 2026-07-11
**Spec**: `.specify/f_vf_prism/spec.md`

---

## Summary

Two independent additions to a working, shipped module: (1) a 3rd
outlet exposing a gate-weighted per-channel dispersion direction — a
genuinely novel vecfield derived from this module's own luma-gated
accumulation, not from the input field alone (finding 4/8 correction);
and (2) the library-wide findings 1–3 rollout — splitting the current
single `strength` param into separate `gain` (effect intensity,
unbounded) and `wet` (crossfader blend) controls, and renaming the
`composite` outlet comment to `mix`. Both are additive to the existing
codebox; no change to the core dispersion/gating math.

---

## Architecture Decisions

### ADR 1: 3rd outlet — gate-weighted combination, not raw geometry average

**Context**: Finding 4 originally credited this module as a clean pass
based on each channel's rotated perpendicular direction being distinct.
Reading the actual rotation math shows any *unweighted* combination of
the three (average, difference) cancels to a scalar multiple of the
input field — not novel, same failure shape as `f_vf_warp`. See spec.md's
2026-07-11 reframe and ideas doc finding 8 for full derivation.

**Decision**: `out3 = gr*R + gg*G + gb*B` — combine the three per-channel
directions weighted by their own post-blur gate values (`gr,gg,gb`,
already computed for out1/out2), rather than an unweighted average.

**Rationale**: The gate weights are independently, nonlinearly
data-dependent (luma-thresholded at each channel's own displaced sample
position) — genuinely new information the input field doesn't carry.
Gate-weighting is the only combination that preserves that novelty;
degenerates gracefully to the (already-known-trivial) unweighted case
when gates happen to agree.

**Alternatives considered**:
- Unweighted average or R−B difference — rejected, provably collapses to
  scalar multiple of input field (sine cancellation under symmetric
  rotation)
- Expose one channel's direction only (e.g. R) — rejected, arbitrary
  choice with no principled reason to prefer one channel, and still
  degenerates to the same trivial case for that channel alone whenever
  its own gate is uniform
- Three separate outlets (one per channel) — rejected, breaks the
  three-outlet convention this whole rollout is standardizing around;
  also each channel's direction alone is *only* a rotation of the input
  field (novelty lives in the gate weighting applied jointly, not in any
  single channel's geometry)

**Consequences**:
- Positive: reuses gate values already computed for out1/out2, no new
  sampling passes
- Negative: needs its own small block of codebox math to combine three
  weighted vectors and re-encode as f_vecfield; not zero-cost the way
  `f_chladni`'s addition was
- Magnitude behavior (not unit-normalized) should be sanity-checked
  during scratch verification per finding 6's redundancy concern, though
  there's no pre-existing vecfield-shaped outlet on this module to be
  redundant *with* the way `f_vf_vortex`'s case was

---

### ADR 2: gain/wet split + outlet rename (findings 1–3)

**Context**: Library-wide convention change (`ideas/dry_wet_gain_and_novel_field_outlet.md`,
findings 1–3) — separate effect intensity from blend amount, use a
crossfader-style control for blend, rename the `composite` outlet to
`mix`. `f_vf_prism` is in the additive-layer group this applies to.

**Decision**:
- Rename existing `strength` param → `gain` (keep its current 0–2.0
  range and default of 1.0 — see note below on why this isn't
  reconciled to match other modules' 1.5 ceiling)
- Add new `wet` param, float 0–1, crossfader-styled UI widget (per
  finding 2 — check `vsynth-bpatcher/SKILL.md` for the established
  widget convention before building)
- Codebox: `mixed = mix(src, src + layer*gain, wet)`, replacing the
  current direct `strength`-scaled additive composite
- Outlet comment: `composite` → `mix`

**Rationale**: Same reasoning as the library-wide finding 1 — `gain`
preserves the ability to overdrive the effect itself, `wet` gives a
separate, bounded, performable blend control, matching the audio-
sidechain shape (send level vs. return blend are different controls).

**Note on the 2.0 vs 1.5 ceiling discrepancy** (flagged in spec.md):
choosing to *keep* `gain`'s range at 0–2.0 rather than reconcile it down
to 1.5 to match `f_vf_glow`/`f_vf_streak`/`f_caustic`. No record exists
of why 2.0 was originally chosen for this module specifically, but
absent a reason to believe it was a mistake (as opposed to a deliberate
choice for this effect's character), forcing conformity risks losing a
deliberately-tuned range on a guess. Worth a two-second check against
Matt in scratch — does 2.0 still feel right, or was it arbitrary — before
finalizing, but not blocking the plan on it.

**Alternatives considered**:
- Leave `strength` name, add `wet` alongside it — rejected, `mix_amt`/
  `strength`/`gain` naming needs to converge on one term across the
  rollout or every module ends up calling the same concept something
  different (see the `f_vf_advect` naming note from finding 1 originally)
- Cap `gain` at 1.5 to match the other additive-layer modules — rejected
  per the note above; no evidence 1.5 is the "correct" number rather than
  just what those three modules happened to land on

**Consequences**:
- Positive: consistent naming with rollout across the additive-layer
  group; crossfader UI matches the convention once established elsewhere
- Negative: renaming `strength`→`gain` changes the param name any saved
  patches reference — existing patches using `f_vf_prism` will need
  their `gain`/`strength` attrui rewired on rebuild (same cost as any
  other param rename in this library, not unique to this module)

**Real bug found and fixed, 2026-07-12** (round 1): the first build used
`driven_r = clamp(src_r + prism_r*gain, 0, 1)` — baking the source into
"driven" before the `mix` blend. That means `mix=100%` still showed
`src + effect`, not the effect alone — dry source bled through
regardless of how far toward "wet" the control was turned. Caught
empirically by Matt testing in Max ("at 100% we should have all wet
signal").

**Round 2**: fixed round 1 to a plain linear crossfade against a
*pure effect layer* (`driven = clamp(prism_r*gain,0,1); mixed = mix(src,
driven, mix_pct/100)`) — still wrong. At 50% it produced a frame-uniform
double exposure (half of source + half of the sparse, mostly-black
effect layer, everywhere) — a literal double image, visible in Matt's
screenshot testing.

**Round 3**: tried coverage-based "over" compositing — use the effect's
own magnitude as per-pixel opacity (`coverage = max(driven_r,g,b);
opacity = coverage*mix; mixed = mix(src, driven, opacity)`). Broke
differently: coverage was computed from the *soft, feather-blurred* gate
value, which rarely reaches a clean 1.0 across its intentionally-wide
transition band — so source still bled through broadly even at
`mix=100%` (a new, different-looking double image, caught in Matt's
screenshot). Diagnosis at the time: "with nonzero threshold values the
fully wet signal is not opaque... the passthrough value is fully present
even at mix=100."

**Round 4**: tried pure additive `out = src + prism*gain*mix` (mix as an
attenuator multiplying gain, no crossfade/masking at all) — rejected on
sight as "we're breaking things... gate doesn't work as expected... we
still see a superimposition of two textures." **Full revert to `v15`**
at this point (single `strength` param, no `gain`/`mix` split at all) to
get back to a known-good baseline before continuing.

**Round 5 (final, confirmed correct)**: re-added `out3` cleanly on top of
the `v15` baseline first (`codebox_v17.gen` — diff against v15 is
*only* the appended out3 block, nothing else touched). Then, working
from Matt's own description of the correct behavior — "an effect applied
30% isn't the same as an effect applied to 30% of a masked shape... it
bends 30% of the way toward what it would be at 100%" — implemented a
plain per-pixel linear interpolation toward the **full original v15
additive-composite** (not toward a bare effect layer):

```
driven_r/g/b = clamp(src_r/g/b + prism_r/g/b * strength, 0.0, 1.0);  // the original v15 composite, unchanged
comp_r/g/b   = mix(src_r/g/b, driven_r/g/b, mix_pct / 100.0);        // plain continuous blend, no masking
```

**Why this one actually works, unlike rounds 2–4**: `driven` here is
never a sparse, mostly-black layer (rounds 2–3's failure mode) — it's
the *complete* v15 composite image, which is a full, natural-looking
image everywhere by construction (source is baked in). Crossfading
between two complete images produces a genuine "bends N% of the way
there" effect with no double-exposure artifact, because there's no
region where one side of the blend is empty/black. This is a frame-
uniform crossfade (vocabulary finding's "model 3"), which the vocabulary
finding says is usually wrong for sparse effects — but it works here
specifically *because* `driven` isn't sparse; the sparsity was hiding
inside `strength`'s own definition, which brings us to the next
paragraph.

**Confirmed by Matt as correct**, with an important caveat surfaced in
the same breath: the `mix`/`strength` *mechanism* is right, but
`strength`'s own 100%-state — `src + prism*strength`, additive/screen
model (vocabulary finding's "model 1") — was flagged as the real
remaining architectural question, not fixed today. Matt's diagnosis,
verbatim: "what is still feeling wrong about this isn't the
strength/mix articulation — that's actually correct, it's that the
original implementation of strength is an additive layer in the first
place." A prism's physical metaphor (light passing through *becomes*
separated color) is arguably occlusion (model 2), not light added on
top — but redefining `strength`'s 100%-state means giving `prism_r/g/b`
a real separate meaning for "effect color" vs. "gate strength," which
today's session correctly declined to improvise live against production
after four prior wrong turns. **This is real, separately-scoped
follow-up work** — see "Open follow-up" below — not something resolved
today.

**Also resolved this session**: whether giving `out2`'s alpha channel
real per-pixel coverage meaning would unlock external "over" compositing
via existing Vsynth tooling. Checked directly — `vs_alpha_blend`,
`vs_alpha_blend_2`, and `vs_crssfade` all use a manually-supplied blend-
*amount* control (a knob), none read per-pixel texture alpha at all.
Matt's call: don't refactor around a dimension (alpha) nothing
downstream currently consumes. Full vocabulary + alpha finding now in
`ideas/dry_wet_gain_and_novel_field_outlet.md` finding 1.

**Shipped final state**: `strength` (live.dial, 0–2.0, unchanged from
v15) + `mix` (live.numbox, 0–100%, `mix_pct` internally per the naming-
collision fix) + `out3` (gate-weighted dispersion vecfield, ADR 1,
unchanged from its original design). `f_vf_glow`/`f_vf_streak`/
`f_caustic` should use this same mechanism (`mix` crossfades toward the
module's own complete, already-composited 100%-state, never toward a
bare sparse effect layer) once picked up — and should each separately
consider whether their own `strength`-equivalent has the same additive-
vs-occlusion question raised here.

**Update 2026-07-12**: `strength` renamed to `gain` after all, per the
library-wide canonical naming decision (`vsynth-bpatcher/SKILL.md`'s
"Canonical naming: `gain` vs `mix`") — this module's own earlier ADR 2
called for exactly this rename and then abandoned it mid-fix during the
five-round formula struggle above; the rename is now finished
separately from that struggle, with no change to the confirmed-correct
formula. Rebuilt via `build_patcher.py`, diff showed only the expected
param/attr/varname/label changes. Confirmed working in Max by Matt
(2026-07-12).

### Open follow-up (not resolved today): is `strength`'s composite model correct?

`comp = src + prism*strength` is additive/screen (vocabulary finding's
model 1) — light added on top of source. Matt's read: a prism's actual
character (light passing through *becomes* separated color) is closer to
occlusion (model 2) — the effect should locally replace source where
active, not visibly stack with it. Redefining this needs:
- A real, separate definition of "effect color" vs. "gate strength" —
  currently `prism_r/g/b` conflates both (it's literally the blurred
  gate magnitude, reused directly as if it were a color)
- Whatever new formula results should be scratch-tested, not iterated
  live against production — four of today's five attempts broke
  something, and the pattern each time was jumping to a plausible-
  looking formula without an actual before/after visual check in Max
  first
- Should probably be designed alongside `f_vf_glow`/`f_vf_streak`/
  `f_caustic`'s own composites, since the same additive-vs-occlusion
  question likely applies to at least some of them too

---

## Implementation Phases

### Phase 1: Scratch — 3rd outlet
- Extend prism's scratch patch (or the existing v15 scratch context) to
  compute `out3 = gr*R + gg*G + gb*B`, encode as f_vecfield
- Verify against spec.md's addition acceptance criteria: diverges from
  scaled input field wherever gates disagree, near-neutral where gates
  agree, neutral on bypass
- **Checkpoint**: out3 behavior confirmed distinct from input field in
  Max before touching `definition.py`

### Phase 2: Scratch — gain/wet split
- Confirm `gain` range (2.0 vs. 1.5 question) empirically against actual
  visual character at both ceilings
- Build crossfader-styled `wet` control per `vsynth-bpatcher/SKILL.md`
  convention (check this first — don't invent a one-off widget)
- Verify `mixed = mix(src, src+layer*gain, wet)` produces the intended
  audio-sidechain-shaped behavior: `wet=0` → clean source regardless of
  `gain`; `wet=1` → full gain-scaled effect blended in
- **Checkpoint**: both new controls behave as specced, independently of
  each other

### Phase 3: definition.py + codebox rewrite
- Add `gain`, `wet` params; remove/rename `strength`
- Add `out3` computation and outlet declaration; rename `composite` →
  `mix` outlet comment
- Rebuild via `build_patcher.py`; JSON-validate

### Phase 4: Vsynth integration verification
- Load rebuilt bpatcher in Max
- Verify all acceptance criteria from spec.md (original + 3rd-outlet
  addition) against the live module
- Confirm no regression to existing dispersion/gating behavior on
  out1/out2

### Phase 5: Docs + registration
- Update `docs/f_vf_prism.md` (if it exists) with new params/outlet
- Update HANDOFF.md
- Confirm `f_modules` menu entry doesn't need changes (outlet count
  change only, not signal_type)

---

## Dependency Blocks

| Block | Depends on | Produces | Gate |
|---|---|---|---|
| Phase 1: 3rd outlet scratch | Nothing | Verified out3 behavior | Acceptance criteria met before Phase 3 |
| Phase 2: gain/wet scratch | Nothing (parallel to Phase 1) | Verified gain/wet controls | Acceptance criteria met before Phase 3 |
| Phase 3: definition.py rewrite | Phases 1+2 | Rebuilt `f_vf_prism.maxpat` | JSON valid before Phase 4 |
| Phase 4: Integration | Phase 3 | Verified working patcher | All acceptance criteria before Phase 5 |
| Phase 5: Docs | Phase 4 | Updated project records | — |

Phases 1 and 2 are independent of each other and can be scratch-verified
in either order or in parallel; both must land before the single
`definition.py` rewrite in Phase 3 to avoid two separate rebuild passes.

---

## Complexity Notes

Two unrelated additions bundled into one plan because they touch the
same file in the same rebuild pass — worth keeping them as separately
identifiable ADRs (done above) so either could be reverted or re-scoped
independently if scratch testing reveals a problem with just one.
