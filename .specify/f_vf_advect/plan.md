# Implementation Plan: f_vf_advect

**Date:** 2026-06-09
**Spec:** `.specify/f_vf_advect/spec.md`

---

## Summary

`f_vf_advect` is a temporal fluid advection processor — the first temporal synthesis module in f_. Each frame, it transports accumulated pixel values backwards along a vector field, producing genuine multi-frame flow that is categorically distinct from the single-pass streak and warp consumers already in the library.

The implementation introduces a new internal pattern to f_: **two chained jit.gl.pix inside one bpatcher** (Pattern 1 from `docs/max-reference/temporal_synthesis_architecture.md`). A `pass_pix` identity object holds the previous frame's output; an `advect_pix` reads both current inputs and the previous frame to compute the new advected state. The GL pipeline's one-frame latency makes this loop stable without any explicit buffer management.

Because `build_patcher.py` currently assumes one jit.gl.pix per bpatcher, this module will use a **per-module build script** for its initial build — the same approach that f_caustic and f_vf_streak used before the build system generalization. Extending `build_patcher.py` for multi-pix bpatchers is tracked as a follow-on build system task, not a prerequisite here.

The codebox is the only novel shader work. The feedback wiring pattern is directly derived from vs_chemical_osc (p TEMPORAL subpatcher) and vs_filter_temp.

---

## Technical Context

**Environment:** Max 9 / Vsynth package
**Primary artifact:** `patchers/f_vf_advect.maxpat`
**Build tool:** Per-module build script `.specify/f_vf_advect/build_advect.py` (see ADR 4)
**Output type:** `@type char` on both pix objects
**Pix objects:** `vfadvect_pix` (advect), `vfadvect_pass` (pass-through)

**Constraints from constitution:**
- Codebox before patcher — GLSL verified in scratch before build script is written
- One bpatcher, one concern — no scope creep; advect only, no decay curve shaping etc.
- Vsynth compatibility — routepass pattern, vs_inState, moduleSize chain, attrui wiring
- Two pix inside one bpatcher — established by vs_chemical_osc, vs_feedback, vs_filter_temp as valid Vsynth pattern

---

## Architecture Decisions

### ADR 1: Two chained pix, pass_pix + advect_pix

**Context:** Advection requires reading the previous frame's output — one-frame temporal state. Cannot be done in a single jit.gl.pix codebox alone.

**Decision:** Two jit.gl.pix inside the bpatcher:
- `pass_pix` (`@name vfadvect_pass @type char @adapt 1`): identity — `out1 = in1`. Holds the current advected frame as a stable texture reference.
- `advect_pix` (`@name vfadvect_pix @type char @adapt 1`): three-inlet — source (in1), vecfield (in2), previous frame (in3). Computes new advected state.

Feedback wiring: `advect_pix out0 → pass_pix in0`, `pass_pix out0 → advect_pix in2`. Bpatcher output: `advect_pix out0 → outlet 0`.

**Rationale:** Directly mirrors vs_chemical_osc p TEMPORAL and vs_filter_temp. The pass_pix intermediary is required (not optional) — it provides the stable one-frame-latency reference. A direct self-loop on advect_pix is untested and likely unstable.

**Alternatives considered:**
- `jit.gl.textureset` (Pattern 2): overkill for one historical frame; adds JS dependency. Reserve for f_cymascope which needs two historical frames.
- Single pix self-loop: not observed in Vsynth source; Kevin always uses the pass_pix intermediary. Do not attempt.

**Consequences:**
- bpatcher contains two jit.gl.pix — novel in f_ library, established in Vsynth
- `build_patcher.py` cannot express this yet (see ADR 4)
- Both pix need `@adapt 1` to handle arbitrary source resolution (confirmed from vs_frame_delay pattern)

---

### ADR 2: `@name` scoping — use `#0_` prefix

**Context:** Spec open question 4. If `@name vfadvect_pix` is global to the GL context, two f_vf_advect instances in one patch collide. Vsynth uses `#0` as a bpatcher-instance scope prefix.

**Decision:** Name both pix with `#0_` prefix: `@name #0_vfadvect_pix` and `@name #0_vfadvect_pass`. Confirm this scoping works correctly in scratch patch before building.

**Rationale:** Every named object in Vsynth bpatchers uses `#0_` scoping — `autopattr @varname #0_autopattr`, receive objects `r #0_enable`, etc. The `jit.gl.pix @name` attribute follows the same convention. Confirmed observable in vs_chemical_osc: `jit.gl.pix vsynth @title slide` — titles are display only; the underlying `@name` inherits `vsynth` from the context, which is already scoped.

**Consequences:**
- Patcher text becomes `jit.gl.pix vsynth @name #0_vfadvect_pix @type char @adapt 1`
- Multiple instances in one patch are safe
- Must verify in scratch: open two f_vf_advect bpatchers in one patch, confirm both advect independently

---

### ADR 3: Codebox — backward advection, additive injection, per-channel clamp

**Context:** Spec open question 3. At default `injection=0.1`, `decay=0.95`, steady-state amplitude ≈ 2.0 — above char range, clips to white in high-traffic regions.

**Decision:**
- Use backward advection: `src_uv = uv - field_xy * dt`
- Clamp final output per-channel: `out1 = clamp(advected + injected, 0.0, 1.0)`
- Default injection lowered to `0.05` so steady-state ≈ 1.0 at the clamp boundary — clean defaults, user can push into clipping for expressive effect

**Rationale:** Clamping is the right default. It prevents invisible accumulation (buffer values above 1.0 that only become visible when injection drops). The clamp ceiling is itself expressive — regions with high field convergence saturate to white, which is a legitimate visual event. Users who want additive bloom can increase injection beyond the equilibrium point deliberately.

**Alternatives considered:**
- No clamp: accumulation exceeds char range invisibly, confusing state. Rejected.
- Normalize instead of clamp: loses the saturation character. Rejected.
- float32 pix: higher dynamic range but incompatible with standard Vsynth char pipeline. Rejected.

**Codebox sketch (advect_pix, 3 inlets):**
```
Param dt(0.02);
Param decay(0.95);
Param injection(0.05);
Param mix_amt(1.0);
Param bypass(0.0);

uv = norm;

// Sample vecfield (in2), remap [0,1] → [-1,1]
fx = (sample(in2, uv).x - 0.5) * 2.0;
fy = (sample(in2, uv).y - 0.5) * 2.0;

// Backward-displaced UV
src_x = clamp(uv.x - fx * dt, 0.0, 1.0);
src_y = clamp(uv.y - fy * dt, 0.0, 1.0);
src_uv = vec(src_x, src_y);

// Sample previous frame (in3) at displaced UV, apply decay
advected = sample(in3, src_uv) * decay;

// Add source injection (in1 at current UV)
injected = sample(in1, uv) * injection;

// Combine and clamp
result = clamp(advected + injected, 0.0, 1.0);

// Wet/dry and bypass
mixed = mix(result, sample(in1, uv), 1.0 - mix_amt);
out1 = mix(mixed, sample(in1, uv), bypass);
```

**pass_pix codebox (1 inlet):**
```
out1 = in1;
```

**Consequences:**
- Steady-state at defaults: `0.05 / (1 - 0.95)` = 1.0 — exactly at clamp boundary. Clean.
- UV clamp on displaced coordinates: edge smear is expected and expressive
- `@adapt 1` means dim-awareness is automatic; no need to query `dim` in codebox

---

### ADR 4: Per-module build script, not build_patcher.py extension

**Context:** `build_patcher.py` assumes exactly one jit.gl.pix per bpatcher. Extending it for multi-pix requires designing a new schema for expressing multiple pix objects, their gen subpatchers, and the wiring between them — a non-trivial build system design task.

**Decision:** Write a per-module `build_advect.py` for this build. The build system extension is a separate tracked task, not a prerequisite.

**Rationale:** Per-module scripts were the established fallback pattern before the generalization pass (f_caustic, f_vf_streak). The build system extension is worth doing, but designing it well requires seeing the advect patcher fully working first — advect is the reference implementation that informs the schema design. Blocking the build on a perfect schema design inverts the right sequence.

**Consequences:**
- `build_advect.py` will be longer than a definition.py but follows the same pattern as build_caustic.py
- After build_patcher.py is extended, definition.py can be written and the script retired (same as caustic/streak)
- The multi-pix build system extension becomes a concrete follow-on task once advect is verified

---

### ADR 5: vs_inState on vecfield inlet, no state_param

**Context:** Spec notes that when vecfield is unconnected, `vs_black` (all zeros) remaps to field vector (-1, -1) which would advect everything toward the top-left corner. This is wrong silent behavior.

**Decision:** Use `vs_inState` on the vecfield inlet (same as other vecfield consumers). However, unlike f_vf_warp, **no `state_param` is needed** — when unconnected, `vs_black` gives a zero field vector after remap: `(0.0 - 0.5) * 2.0 = -1.0`. This IS a non-zero offset.

**Correction from spec:** The spec incorrectly stated that zero field remaps to zero vector. It remaps to (-1, -1). The suppression pattern IS required here, same as f_vf_warp.

**Revised decision:** Use `vs_inState` with `state_param: "src_vecfield"` on the vecfield inlet. `src_vecfield` in the codebox suppresses the displacement when unconnected: `mix(0.0, fx, step(0.5, src_vecfield))`.

**Consequences:**
- `src_vecfield` hidden system param added to codebox and params list (as `"type": "internal"`)
- Same suppression pattern as f_vf_warp — well-understood, verified
- Codebox sketch above updated to include this suppression (omitted for brevity; add before Phase 1)

---

### ADR 6: 3rd outlet — gradient of accumulated flow, not input-field passthrough

**Context**: `ideas/dry_wet_gain_and_novel_field_outlet.md` finding 4
originally credited this module as a clean pass based on HANDOFF's note
about the reverted vorticity-confinement fold-in. Direct read of the
current codebox (post-ADR-5, current production state) shows the actual
field consumption (`fx,fy`, gated passthrough via `connected`) is not
novel — same shape as `f_vf_warp`'s fail case. The confinement work that
would have made it novel is exactly what got reverted (see
`ideas/vorticity_confinement.md`). This ADR supersedes that original
finding-4 credit for this module.

**Decision**: Add a 3rd outlet exposing the central-difference gradient
of `result` (the accumulated color state already computed for outlet 2),
not a smoothed/enhanced version of the input field. See spec.md's
2026-07-11 reframe section for full acceptance criteria.

**Rationale**: Considered and rejected a temporally-smoothed input field
(inertia/lag on the vecfield itself) — that's generic to any vecfield
producer, not specific to advection, and would add a second feedback
loop to a module where one feedback experiment (confinement) already
failed and was reverted. The gradient-of-`result` option is
self-referential in a way nothing else in the library produces: the
shape the flow has drawn becomes a new field to flow along, patchable
back into another `f_vf_advect` or `f_vf_warp` for flow that reshapes
its own future direction. It's also the cheaper option — reuses
`f_vf_fieldmap`'s central-difference idiom on a texture the module
already holds in state (`result`, feeding `in3` next frame), no new pix
stage or feedback wiring required.

**Alternatives considered**:
- Temporally-smoothed input field — rejected, generic (not
  advect-specific), adds a second feedback loop; parked as its own idea
  in `ideas/f_vf_temporal_smooth.md`
- Leaving finding 4 out of scope for this module — considered, rejected
  because the gradient option is cheap enough and specific enough to be
  worth doing now rather than deferring

**Consequences**:
- Positive: no new pix stage, no new feedback wiring; reuses a proven
  idiom (`f_vf_fieldmap`'s gradient trick) applied to an already-held
  texture instead of a fresh input
- Negative: `result` is char/RGB, not a pre-existing scalar field like
  `f_chladni`'s `total` — needs a luma-reduction step before the
  gradient, one small piece of new codebox work `f_chladni`'s case didn't
  require
- Corrects the record: finding 4 in the ideas doc needs its `f_vf_advect`
  entry read as "originally miscredited, corrected here" rather than
  "confirmed clean pass" — done as part of this ADR (see finding 7)

---

## Implementation Phases

### Phase 1: Scratch patch — codebox verification

Write and verify both codeboxes in a scratch patch before any build work.

**Work:**
- Open scratch patch in `~/Vsynth/patterns/`
- Build the two-pix feedback chain manually: pass_pix (1 in) → advect_pix (3 in) → outlet, with advect_pix out0 → pass_pix in0 feedback wire
- Wire: source texture → advect_pix in0, f_vf_vortex → advect_pix in1 (via vs_inState), pass_pix out0 → advect_pix in2
- Add sliders for dt, decay, injection, mix_amt, bypass, src_vecfield
- Verify all acceptance criteria: flow visible, decay/injection/dt/mix controls work, no-field = decay in place, bypass = source passthrough, state preserved across bypass toggle
- Verify `#0_` scoping: duplicate bpatcher in patch, confirm independent advection state

**Checkpoint:** Both codeboxes work correctly in scratch. All parameters behave as specced. Two instances are independent. Codeboxes frozen — no changes after this point.

---

### Phase 2: Build script

Write `build_advect.py` encoding the verified two-pix patcher structure.

**Work:**
- Model on `build_caustic.py` — same boilerplate (routepass, route, autopattr, panel, title, moduleSize chain, bypass, params)
- Key differences from standard single-pix builds:
  - Two pix objects: `vfadvect_pass` (obj-50, 1 inlet) and `vfadvect_pix` (obj-5, 3 inlets)
  - Gen subpatchers: pass_pix has trivial `in1 → out1`; advect_pix has `in1, in2, in3 → codebox → out1`
  - Feedback wire: advect_pix out0 → pass_pix in0
  - Pass wire: pass_pix out0 → advect_pix in2 (gen in3)
  - vs_inState on vecfield inlet with src_vecfield state_param (obj-51 inlet, obj-52 vs_inState, obj-53 prepend)
  - Outlet: advect_pix out0 → bpatcher outlet 0
- Object ID allocation: standard IDs for shared infra (obj-1 through obj-16), obj-50+ for additional pix and inlets, obj-20+ for param UI objects
- JSON validation: `python3 -c "import json; json.load(open('patchers/f_vf_advect.maxpat'))"`

**Checkpoint:** JSON valid. Structural inspection confirms both pix objects present, correct inlet counts, feedback wire and pass wire both present.

---

### Phase 3: Vsynth integration testing

Open built patcher in live Vsynth patch and verify all acceptance criteria.

**Work:**
- Load f_vf_advect as bpatcher in Vsynth
- Connect source → in0, f_vf_vortex → in1
- Confirm: flow accumulates over time, decay/injection/dt/mix all work, vecfield unconnected = decay in place, bypass preserves accumulated state, two instances independent
- Save and reload — no crash, state resets to empty (expected; no autopattr saves feedback texture state)
- Test with f_vf_vortex_multi and f_vf_fieldmap

**Checkpoint:** All acceptance criteria from spec pass. No crashes. Parameter save/restore works for the four user params.

---

### Phase 4: Docs and registration

**Work:**
- Update `ideas/f_vf_advect.md` status to Built
- Update `README.md`: add f_vf_advect to bpatcher table
- Update `f_modules` menu: add "Advect" to Vecfield category in `build_modules.py` and `f_addmod.js`, regenerate `f_modules.maxpat`
- Note build system extension as follow-on task in `plan.md` work queue

**Checkpoint:** README updated. f_modules menu includes f_vf_advect. Committed.

---

### Phase 5: 3rd outlet — gradient of accumulated flow

**Work:**
- In scratch patch (reopen `f_vf_advect`'s scratch or build a fresh one
  against the current production codebox), add luma-reduction of
  `result` and central-difference gradient (reuse `f_vf_fieldmap`'s
  `scale`/epsilon constant as a starting point)
- Encode as f_vecfield (RG float32, `0.5 = zero vector`), wire as out3
- Verify acceptance criteria from spec.md's 2026-07-11 reframe: out3
  tracks accumulated structure (not instantaneous input), neutral when
  `result` is flat, bypass → neutral, out1/out2 unaffected
- Confirm by routing out3 → a second `f_vf_advect` or `f_vf_warp` and
  observing visibly different behavior from routing the original input
  field to the same destination

**Checkpoint:** Out3 verified in Max against all reframe acceptance
criteria. No regression to out1/out2. Update `docs/f_vf_advect.md` and
HANDOFF with the new outlet.

---

## Dependency Blocks

| Block | Depends on | Produces | Gate |
|---|---|---|---|
| Phase 1: Scratch | Nothing | Verified codeboxes, confirmed `#0_` scoping | Codeboxes frozen before Phase 2 |
| Phase 2: Build script | Phase 1 | `f_vf_advect.maxpat` | JSON valid before Phase 3 |
| Phase 3: Integration | Phase 2 + Vsynth env | Verified working patcher | All acceptance criteria before Phase 4 |
| Phase 4: Docs | Phase 3 | Updated project records | — |
| Phase 5: 3rd outlet | Phase 3 (production module stable) | Gradient-of-`result` outlet, verified | Reframe acceptance criteria before docs update |

---

## Follow-on Tasks (not blocking this build)

- **build_patcher.py multi-pix extension:** Once f_vf_advect is verified, design a `secondary_pix` or `pix_chain` key in the definition schema that can express the pass_pix + state_pix pattern generically. f_cymascope (three pix) will stress-test the design. Retire build_advect.py once the extension is complete.
- **f_cymascope:** Unblocked by this build — three chained pix, same Pattern 1, but with two historical frames. Build after advect proves the convention.

---

## Complexity Notes

Medium complexity. The codebox is straightforward (backward advection is a standard single expression). The novel elements are:

1. **Two-pix bpatcher** — pattern is understood from Vsynth source, but first time in f_. The scratch patch phase is essential to confirm `#0_` scoping before writing the build script.
2. **ADR 5 correction** — vs_black suppression is required (same as f_vf_warp), despite the spec initially stating otherwise. Confirmed in ADR 5 above.
3. **Steady-state behavior** — injection/decay equilibrium is predictable mathematically but should be verified empirically in scratch to confirm defaults feel right before freezing.

Main risk: `#0_` scoping for `jit.gl.pix @name`. If it doesn't work as expected, two instances will share feedback state (both update the same texture). This is a correctness failure, not a crash — easy to detect in Phase 1 by opening two instances and verifying independent behavior.
