# Implementation Plan: f_vf_glow

**Date**: 2026-06-16
**Spec**: .specify/f_vf_glow/spec.md

---

## Summary

A vecfield consumer + processor bpatcher built to the standard f_ / Vsynth conventions. Single jit.gl.pix with a gen subpatcher codebox. Three inlets (texture/control, vecfield, radius mod), two outlets (composited, isolated glow). Fixed 48-step accumulation loop (raised from an initial 24 during tuning, with per-step jitter added — see spec.md's 2026-07-11 correction); `radius` controls spatial extent. No temporal feedback.

---

## Technical Context

- **Runtime**: Max 9, jit.gl.pix GPU path (GLSL via GenExpr)
- **Type**: `@type char` (Vsynth processor convention)
- **GL context**: `@drawto vsynth`
- **Build tool**: `tools/build_patcher.py` from `definition.py`
- **Inlets**: 3 — all routed via `vs_inState` for graceful unconnected fallback
- **Outlets**: 2 — requires `outlets` key in definition.py with tricolor labels

---

## Architecture Decisions

### ADR-1: Fixed step loop, `radius` as range control

**Context**: GenExpr `for` loops require compile-time constant trip counts. A user-controllable step count would require multiple gen subpatchers.

**Decision**: Fix at 48 steps (raised from an initial 24 during tuning — see spec.md's 2026-07-11 correction; this plan's number updated to match `codebox_v1.gen`, not re-decided here). `radius` (UV step size) is the sole range control — small radius = tight glow, large radius = wide glow. Per-step jitter added during tuning to break up banding at low step-to-radius ratios (not part of the original ADR reasoning, but present in shipped code).

**Rationale**: 48 steps, both directions always sampled per iteration (96 samples worst case) — acceptable GPU cost at target resolutions per spec NF-004. The artist controls spatial extent, not sample density. Cleaner UX and simpler shader.

**Alternatives rejected**:
- Variable step count via separate gen subpatchers: too complex, no clear UX benefit
- range_tiers quality selector: adds UI complexity for marginal expressive gain

---

### ADR-2: vs_black suppression via pre-remap magnitude threshold

**Context**: When the vecfield inlet is unconnected, `vs_inState` provides `vs_black` (all zeros in texture space). After the standard f_vecfield remap `(raw - 0.5) * 2.0`, a zero texture value becomes `(-1, -1)` — non-zero magnitude — causing a fixed-direction glow across the entire frame on unconnected patches.

**Decision**: Test raw field value before remapping. If `raw_x < 0.02 && raw_y < 0.02` (i.e., effectively black), set `field_suppress = 0.0`; otherwise `field_suppress = 1.0`. Multiply remapped field by `field_suppress` before computing step delta.

**Rationale**: Cleanly distinguishes vs_black (raw ≈ 0) from a genuine zero-vector region (raw = 0.5). Zero-vector regions in a real field get magnitude 0 after remap — they produce no glow displacement naturally, no special case needed.

**Consequence**: A field texture that legitimately has pixels near (0,0) in texture space (extreme negative vectors) would also be suppressed. Acceptable — extreme negative vectors are rare in practice and the f_vecfield encoding puts zero at 0.5.

---

### ADR-3: Additive radius modulation

**Context**: Radius mod inlet (in2) provides a 0–1 scalar. Two design options: additive (`radius_eff = base + mod * scale`) or multiplicative (`radius_eff = base * (1 + mod)`).

**Decision**: Additive. `radius_eff = clamp(radius + sample(in3, norm).x * radius, 0.0, 0.3)`. Unconnected inlet (vs_black = 0.0) adds nothing — clean default. The modulation depth scales with `radius` so relative behavior is consistent across radius settings.

**Rationale**: Simpler shader math. Unconnected state is a true no-op. Scaling mod depth by `radius` avoids the "mod does nothing at small radius" problem.

---

### ADR-4: Direction mode via integer param + branchless shader

**Context**: Three direction modes (bidirectional=0, forward=1, backward=2) must be implemented in GenExpr without dynamic branching overhead.

**Decision**: Compute `fwd_weight` and `bwd_weight` scalars from `direction` param using `step()`:
```
fwd_weight = 1.0 - step(1.5, direction);   // 1 when dir=0 or 1, 0 when dir=2
bwd_weight = 1.0 - step(0.5, direction) + step(1.5, direction);  // 1 when dir=0 or 2, 0 when dir=1
```
Accumulate forward and backward separately, multiply each by its weight before summing.

**Rationale**: GPU-friendly branchless logic. No `if/else` on direction in the inner loop.

---

### ADR-5: color_mix implementation

**Context**: `color_mix` blends accumulated color between full-color (0) and luma-only (1). Luma must be computed from accumulated RGB.

**Decision**: After accumulation, compute `luma = dot(accum.rgb, vec(0.2126, 0.7152, 0.0722))`. Then `glow_rgb = mix(accum.rgb, vec(luma, luma, luma), color_mix)`. Apply `strength` mix over source after.

**Rationale**: Standard luminance weights. Simple linear mix is sufficient.

---

### ADR-6: Two-outlet pattern

**Context**: f_vf_glow needs composited (out0) and isolated glow (out1), matching f_caustic and f_vf_streak precedent.

**Decision**: Use `outlets` key in definition.py. out0 = `composite` (green label), out1 = `glow layer` (cyan label). Isolated outlet carries `glow_rgb` before composite; bypass zeroes it.

---

## Implementation Phases

### Phase 1 — Codebox verified in scratch patch

Write GenExpr codebox, paste into a scratch patch at `~/Vsynth/patterns/`, wire to a vortex field source, verify visually. This is the highest-risk phase — all shader logic locked here before any build infrastructure is written.

**Codebox inlet map**:
- `in1` — source texture (outer pix inlet 0)
- `in2` — vecfield (outer pix inlet 1)
- `in3` — radius mod (outer pix inlet 2)

**Params declared in codebox**:
- `Param radius(0.05)`
- `Param falloff(1.5)`
- `Param strength(0.8)`
- `Param color_mix(0.0)`
- `Param direction(0.0)`
- `Param bypass(0.0)`

**Checkpoint**: Glow visibly traces vortex field streamlines. Direction modes produce distinct results. Unconnected vecfield inlet produces no glow.

---

### Phase 2 — definition.py + build

Write `.specify/f_vf_glow/definition.py` from confirmed codebox. Run `tools/build_patcher.py`. Verify JSON is valid and patch opens in Max without errors.

**Key definition.py fields**:
- `archetype: "processor"`
- `outlets: [{"label": "composite", "color": "green"}, {"label": "glow layer", "color": "cyan"}]`
- `inlets`: vecfield inlet (float32 label, cyan), radius mod inlet
- `vs_instate` on all three inlets
- `@type char`

**Checkpoint**: Patch opens in Max. All params appear in UI. Pix compiles without errors.

---

### Phase 3 — Integration testing

Drop `f_vf_glow` into a Vsynth signal chain with `f_vf_vortex` feeding the vecfield inlet. Test all params across range. Test both outlets. Test unconnected vecfield inlet. Test bypass.

**Checkpoint**: All spec acceptance scenarios pass. Performance acceptable at target resolution.

---

### Phase 4 — Registration

- Add to `f_modules.maxpat` (Vecfield category)
- Add to `javascript/f_addmod.js` SIZES dict
- Add to `README.md` patch table
- Write `docs/f-reference/f_vf_glow.md` as-built reference
- Update `HANDOFF.md` and `.specify/plan.md` work queue

---

## Complexity Notes

The vs_black suppression (ADR-2) and direction branchless logic (ADR-4) are the two areas most likely to need iteration in Phase 1. Both should be verified explicitly in the scratch patch before writing definition.py.

The two-outlet pattern is established precedent (f_caustic, f_vf_streak) — definition.py syntax is known-good.

---

### ADR-5: gain/wet split + outlet rename (findings 1–3, 2026-07-11)

**Context**: Library-wide convention change (`ideas/dry_wet_gain_and_novel_field_outlet.md`,
findings 1–3). See spec.md's 2026-07-11 reframe for full context —
`f_vf_glow` is a founding example of the additive-layer group, its
codebox is what originally grounded finding 1's distinction between
additive layering and true crossfade.

**Decision**: Rename `strength`→`gain` (range/default unchanged: 0–1.5,
default 0.0), add `wet` (float 0–1, crossfader widget), rewrite composite
as two-stage `layer = clamp(src + glow*gain, 0, 1); comp = mix(src,
layer, wet)`. Rename `composite` outlet comment → `mix`.

**Rationale**: Matches the audio-sidechain shape — `gain` preserves
overdrive on the effect itself, `wet` is a separate bounded blend stage.
No change to finding 4 status (already assessed as not a clean pass for
this module — no 3rd outlet planned).

**Consequences**:
- Positive: consistent naming with `f_vf_advect`/`f_vf_prism` once their
  own rollouts land; crossfader UI matches convention once established
- Negative: `strength`→`gain` rename breaks any saved patch attrui
  references, same cost as any param rename in this library

---

### Phase 5 — gain/wet split + outlet rename

**Work:**
- Confirm crossfader widget convention against `vsynth-bpatcher/SKILL.md`
  before building (don't invent a one-off — same check needed for every
  module in this rollout)
- Rewrite codebox per ADR-5; rename `strength`→`gain` in definition.py
  params, add `wet` param
- Rename `composite` outlet comment → `mix`
- Rebuild via `build_patcher.py`; JSON-validate

**Verification:**
- `wet=0` → out1 (mix) is clean source regardless of `gain`
- `wet=1`, `gain=1.0` → out1 matches pre-change `strength=1.0` behavior
  exactly (regression check)
- `gain` scales intensity independent of `wet`
- out2 (glow, isolated) unaffected by gain/wet — still raw accumulation
- Bypass behavior unchanged

**Checkpoint:** All reframe acceptance criteria from spec.md verified in
Max. No regression to Phase 1–4 behavior. Update HANDOFF.md.
