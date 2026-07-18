# Implementation Plan: f_caustic

**Date**: 2026-07-11
**Spec**: `.specify/f_caustic/spec.md`

---

## Summary

Two items, discovered and resolved together: (1) a live functional bug —
`definition.py` was building from a stray, broken codebox file instead of
the correct one — and (2) the library-wide findings 1–3 naming pass
(`ideas/dry_wet_gain_and_novel_field_outlet.md`), which turned out to be
mostly already implemented here and needed renaming/capping rather than
new architecture.

---

## Architecture Decisions

### ADR 1: Bug fix — `definition.py` pointed at the wrong codebox file

**Context**: `definition.py` loaded `codebox_v3.gen`. That file's own
internal header comment reads `// f_caustic codebox v1 — scratch
validation` despite the `v3` filename, and every `sample()` call in it
references only `in1` — for both field-decode/divergence math *and*
source-color sampling — never `in2`. `codebox_v2.gen`, by contrast, has
the correct two-inlet structure (`in1`=source, `in2`=vecfield), includes
the `strength` param entirely absent from `v3`, and matches this
project's `spec.md` and `docs/f-reference/f_caustic.md` as originally
written. Filesystem mtimes show `v2` (06-06) predates `v3` (06-09), and
`definition.py` (06-20) was last touched after both — meaning this was
likely an accidental save-over or an abandoned single-texture experiment
that never got cleaned up, not a deliberate later revision superseding
v2.

**Decision**: Deleted `codebox_v3.gen`. `definition.py` now opens
`codebox_v2.gen`.

**Rationale**: `v3`'s content contradicts `definition.py`'s own
`mod_inlets` declaration (which declares a distinct vecfield inlet) and
every other document describing this module. `v2` is internally
consistent with all of them. No plausible reading makes `v3` the
intended file.

**Consequences**:
- **Whatever `f_caustic.maxpat` currently exists on disk may have been
  built from the broken file** — the vecfield inlet may not have
  actually been functioning. Rebuild and re-verify in Max before trusting
  any existing behavior; this is priority one, ahead of the findings
  1–3 work below.
- Same class of bug as the `f_vf_advect` `strength`/`mix_amt` mismatch
  (HANDOFF, 2026-07-06) — a declared param or, here, an entire wired
  codebox, silently not matching what the build actually references.
  Worth a general audit pass across other modules for the same failure
  mode (definition.py referencing a stale/wrong codebox file) at some
  point — not scoped here, but flagging the pattern.

---

### ADR 2: gain/wet naming pass (findings 1–3) — renaming, not new architecture

**Context**: Library-wide convention change. Unlike `f_vf_glow`/
`f_vf_streak`/`f_vf_prism`, this module's `codebox_v2.gen` already
implements the gain/wet shape:
```
composited = mix(source_pass, composite, strength);   // already a crossfade
```
`intensity` already scales the caustic layer before compositing (the
gain role); `strength` already blends that layer against source (the
wet role) — just not capped to a true 0–1 crossfader (currently 0–1.5,
allowing `mix()` to extrapolate past the composite for `t>1`, a
different kind of overdrive than `gain`-then-bounded-crossfade gives
elsewhere in this rollout).

**Decision** (resolved with Matt, "gain + wet"):
- Rename `intensity` → `gain`, keep its 0–2.0 range and 0.5 default —
  already fills the role, renamed to match
- Rename `strength` → `wet`, **cap range to true 0–1** (dropping the
  1.0–1.5 extrapolation zone) — matches the crossfader framing rather
  than preserving the old extrapolation-past-composite behavior
- Outlet comment: `composite` → `mix`
- Add crossfader-styled `wet` widget per `vsynth-bpatcher/SKILL.md`
  convention (check before building)

**Rationale**: Matches the audio-sidechain shape used everywhere else in
this rollout. Capping `wet` at 1.0 removes the old overdrive-via-
extrapolation character in the 1.0–1.5 range, but `gain`'s own 0–2.0
range already gives a cleaner, more predictable way to push the effect
harder — no expressive capability is actually lost, just relocated to
the param that's supposed to carry it.

**Consequences**:
- Positive: matches naming convention across the whole rollout; simpler
  mental model (gain = how strong, wet = how much blended in, no third
  hybrid behavior in between)
- Negative: `wet=1.5`-equivalent character (whatever it currently looks
  like) is not reproducible after the range cap — if that overdriven
  extrapolation look turns out to matter to Matt after seeing it removed,
  this would need revisiting. Not verified either way before this
  decision; flagged here rather than assumed away.
- Param renames (`intensity`→`gain`, `strength`→`wet`) break any saved
  patch attrui references, same cost as any rename in this library

---

## Implementation Phases

### Phase 1: Rebuild + regression check (bug fix verification)

**Work:**
- Run `tools/build_patcher.py` against the corrected `definition.py`
  (now pointing at `codebox_v2.gen`)
- JSON-validate the rebuilt `f_caustic.maxpat`
- Load in Max, connect a source texture and `f_vf_vortex` to the
  vecfield inlet
- Confirm: bright caustic ring appears at the convergence zone (this was
  the exact behavior that may have been silently broken) — compare
  against the acceptance criteria already in spec.md, unchanged by this
  reframe
- Confirm `in2` unconnected → silent passthrough (out1), black (out2) —
  still correct, no vs_inState fallback

**Checkpoint:** Vecfield inlet confirmed functioning in Max. This is a
regression check against a real bug, not a new-feature verification —
treat any failure here as higher priority than the naming pass below.

### Phase 2: gain/wet rename

**Work:**
- Rename `intensity`→`gain`, `strength`→`wet` in `definition.py`'s
  params list; cap `wet`'s range to 0–1
- Update codebox: `composited = mix(source_pass, composite, wet)`
  (variable rename only — same `mix()` call, just capped range and new
  param name)
- Rename `composite` outlet comment → `mix`
- Confirm crossfader widget convention against `vsynth-bpatcher/SKILL.md`
  before building
- Rebuild via `build_patcher.py`; JSON-validate

**Verification:**
- `wet=0` → out1 (mix) is clean source regardless of `gain`
- `wet=1` → matches pre-rename `strength=1.0` behavior exactly
- `gain` scales caustic intensity independent of `wet`
- No change to out2 (caustic, isolated layer)
- Bypass behavior unchanged

**Checkpoint:** All spec.md reframe acceptance criteria verified in Max.
Update `docs/f-reference/f_caustic.md` and HANDOFF.md.

---

## Dependency Blocks

| Block | Depends on | Produces | Gate |
|---|---|---|---|
| Phase 1: Bug fix rebuild | Nothing (definition.py already fixed) | Verified vecfield inlet behavior | Vecfield functioning before Phase 2 |
| Phase 2: gain/wet rename | Phase 1 | Renamed params, capped wet range | Reframe acceptance criteria before docs update |

Phase 1 is a hard gate on Phase 2 — no point renaming params on a module
whose core vecfield consumption might still be broken. Confirm the bug
fix actually resolves the behavior before spending time on the naming
pass.

---

## Complexity Notes

Low complexity for Phase 2 — this is almost entirely a rename plus one
range cap, not new shader logic. Phase 1 carries the real risk: it's
possible (though considered unlikely, given `v2`'s internal consistency
with every other document) that rebuilding surfaces some other issue
that `v3`'s existence was originally masking or working around. Treat
Phase 1's Max verification as non-optional even though the file-reference
fix itself looks like an obviously correct one-line change.
