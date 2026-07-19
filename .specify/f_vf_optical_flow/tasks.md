# Tasks: f_vf_optical_flow

**Spec**: `.specify/f_vf_optical_flow/spec.md`
**Plan**: `.specify/f_vf_optical_flow/plan.md`
**Build order**: Sequential. Complete each phase before the next.
**Commits**: After each phase checkpoint.

---

## Expected Output Layout

```
patchers/
  f_vf_optical_flow.maxpat        — built by build script from definition.py

.specify/f_vf_optical_flow/
  spec.md                         — done
  plan.md                         — done
  tasks.md                        — this file
  definition.py                   — authored in Phase 3
  codebox_stage_a.gen             — authored in Phase 0
  codebox_stage_b_h.gen           — authored in Phase 1 (split from planned single stage_b.gen, see T010)
  codebox_stage_b_v.gen           — authored in Phase 1
  codebox_stage_c.gen             — authored in Phase 2
  codebox_stage_d.gen             — authored in Phase 4 (temporal accumulation, T024b)
  codebox_stage_e.gen             — to be authored in Phase 5 (confidence-gated spatial fill)

docs/f-reference/
  f_vf_optical_flow.md            — as-built reference (Phase 6)

~/Vsynth/patterns/
  optical_flow_scratch.maxpat     — scratch patch for Phases 0-2 (not committed)
```

---

## Phase 0: Stage A scratch test — gradients + temporal diff (BLOCKING)

**Purpose:** De-risk the mechanical part before building the genuinely
new windowed-sum machinery. Reuses only already-confirmed techniques.

⚠️ Do not begin Phase 1 (Stage B) until this checkpoint is confirmed.

- [x] T001 Open scratch patch at `~/Vsynth/patterns/optical_flow_scratch.maxpat`
- [x] T002 Build 2-pix feedback pair: `pass_pix` (identity) + `stage_a_pix` (primary), same shape as `f_vf_advect`'s `state`/`pass` pattern
- [x] T003 **DECISION GATE:** decide `Ix`/`Iy` gradient source — current-frame-only central difference, or averaged current+previous (Horn-Schunck-style noise reduction). Per spec.md Phase 0, decide this empirically once Stage A is running and visible, not by assumption beforehand. Document the choice and why here before moving to T004.
  **Decided: current-frame-only.** Simplest first pass — spec explicitly frames averaging as a refinement, not a requirement. Documented directly in `codebox_stage_a`'s header comment. Not revisited empirically against averaged, since current-only already produced clean, legible edge detection (see T006) — no observed noise problem to justify the extra complexity yet.
- [x] T004 Write `codebox_stage_a.gen`: compute `Ix`, `Iy` (central difference, per decision in T003) and `It` (`current - previous`)
- [x] T005 Confirm Stage A renders standing alone, no GL errors
- [x] T006 Wire each of `Ix`/`Iy`/`It` individually to a preview; confirm each visibly responds to motion in a live or played-back source (not all-zero, not garbage)
  Confirmed by Matt: `Ix`/`Iy` (via `f_vf_split` off the packed vecfield outlet) show clean, sensible edge detection tracking vertical/horizontal contrast in the scene. `It` (separate outlet) was initially flat gray regardless of motion — root-caused to a real bug, not a tuning issue (see T007) — now visibly tracks motion after the fix.
- [x] T007 Confirm the previous-frame feedback loop behaves correctly via draw order (same mechanism as `f_vf_advect`, already confirmed working there — verify it holds here too, don't assume it transfers automatically)
  **Real bug found and fixed:** initial build wired `pass_pix` directly off the camera source in parallel with `stage_a_pix`, rather than off `stage_a_pix`'s own output — no cyclic dependency, so `pass_pix` had no structural reason to lag a frame and was effectively resampling the current frame every tick. This made `It = lcur - lcur = 0` everywhere (flat gray, content-independent — matched what was observed). Fix: gave `stage_a_pix` a third outlet (`out3`, plain current-frame passthrough) and closed the loop `stage_a_pix(out3) → pass_pix → stage_a_pix(in2)`, matching `f_vf_advect`'s `state`/`pass` cycle shape exactly. Confirmed working after the fix — `It` now responds to real motion.

**Checkpoint:** Stage A confirmed working standalone — gradients and temporal diff all visibly correct. → Proceed to Phase 1.

---

## Phase 1: Windowed sum — Stage B (BLOCKING)

**Purpose:** Build the one genuinely new technique in this module. Highest risk phase for the GL2→GL3 capture-group ceiling.

⚠️ Do not begin Phase 2 (Stage C) until this checkpoint is confirmed.

- [x] T008 Write `codebox_stage_b.gen`: 5×5 windowed accumulation of `Ix²`, `Iy²`, `IxIy`, `IxIt`, `IyIt` from Stage A's output
  **Revised from a single codebox into a separable two-pass design** (`stage_b_h_pix` + `stage_b_v_pix`) — see T009/T010 for why. `stage_b_h` does a 5-tap horizontal sum of the five products (decoding Stage A's vecfield-encoded `Ix`/`Iy`/`It` inline, never via a stored-then-sliced variable); `stage_b_v` does a 5-tap vertical sum over `stage_b_h`'s output, completing the window. Both use `@type float32` — required, since these sums are genuinely unbounded, unlike Stage A's clamped/display-encoded outputs.
- [x] T009 **DECISION GATE:** decide channel packing for the five accumulator outputs — how many output textures, which sums go in which channels. Not yet decided as of spec.md; resolve here before finalizing the codebox's `out1`/`out2`/etc. structure.
  **Decided:** two output textures, split by which half of Stage C's math they feed. `out1.xyz = (ΣIx², ΣIy², ΣIxIy)` — the symmetric matrix `A`. `out2.xy = (ΣIxIt, ΣIyIt)` — the vector `b`. Direct 1:1 correspondence to the 2×2 solve, no repacking needed in Stage C.
- [x] T010 Compile and render at 5×5. **If the GL2→GL3 capture-group ceiling bites** (params gray out, pix goes invalid): split into smaller sub-stages per `jit-gen-codebox` skill's documented approach — do not attempt to hand-optimize the math first. Note here which happened.
  **Proactively avoided rather than hit and split.** Before writing any code, recognized a 5×5 box sum is separable (horizontal 5-tap sum → vertical 5-tap sum, mathematically identical to a naive 25-tap 2D sum) and built it as two simpler codeboxes from the start, rather than the naive single-codebox 125-sample-op version the plan originally assumed. This revises ADR-4's stated 4-node `pix_chain` to 5 nodes (`pass_pix` + `stage_a_pix` + `stage_b_h_pix` + `stage_b_v_pix` + `stage_c_pix`) — flagged here since that's a real plan.md revision, not just an implementation detail. Confirmed by Matt: compiles and renders with no console errors.
- [x] T011 Build a simple test pattern (e.g. a hard vertical edge moving horizontally) with a predictable, manually-computable expected signature
  Built `test_edge_pix` — a static (non-moving) hard vertical edge generator at `x=0.5`, plus `stage_b_vis_pix`, a preview-only remap tap giving one grayscale preview per sum (not part of the real pipeline). Static rather than moving, since the spatial terms (`Ix²`/`Iy²`/`IxIy`) only need a fixed edge to check, and the temporal terms (`IxIt`/`IyIt`) were instead checked qualitatively against real camera motion (same approach already validated for Stage A's `It`), rather than building a second animated synthetic pattern.
- [x] T012 Spot-check the five sums against the manual expectation from T011 — confirm they're in the right ballpark and have the right dominant-term signature, not just "some nonzero values"
  Confirmed by Matt against the static edge pattern: `Ix²` shows a bright band right at the edge (dark elsewhere); `Iy²` flat dark everywhere (no horizontal edges present); `IxIy` flat mid-gray (≈0, no cross-correlation, as expected with no `Iy` signal); `IxIt`/`IyIt` flat mid-gray with the static pattern (no motion, correctly ≈0). All five sums show the expected dominant-term signature, not just arbitrary nonzero noise.

**Checkpoint:** Stage B confirmed working, ceiling risk resolved one way or the other, sums spot-checked against a known test case. → Proceed to Phase 2.

---

## Phase 2: Solve + confidence — Stage C (BLOCKING)

**Purpose:** Closed-form solve for velocity, plus the confidence signal that makes the aperture problem visible rather than silently contaminating downstream consumers.

⚠️ Do not begin Phase 3 (definition.py) until this checkpoint is confirmed.

- [x] T013 Write `codebox_stage_c.gen`: closed-form 2×2 linear solve (Cramer's rule) for `(u,v)` from Stage B's five sums
  Built as `stage_c_pix`, `@type float32`. Solves `A·[u,v]ᵀ = -b` where `A = [[Sxx,Sxy],[Sxy,Syy]]`, `b = (Sxt,Syt)` from Stage B's two output textures. `(u,v)` encoded as a standard 0.5-centered vecfield with a `gain` param, matching `f_vf_fieldmap`'s convention.
- [x] T014 Add matrix-determinant computation as a second output (confidence signal)
  `det = Sxx·Syy − Sxy²`, output raw/unclamped on `out2` — deliberately left unnormalized per T017. Guard is `max(det, 0.0001)` only (no sign handling needed — see T017 finding below for why that's mathematically justified, not just a convenient guess).
- [x] T015 Confirm `(u,v)` output loads into `f_vf_fieldmap`'s expected vecfield format with no adapter
  Encoding matches exactly (0.5=zero, same channel layout) by construction — not yet wired into a real consumer (`f_vf_warp`) to confirm end-to-end; that's Phase 4's T023.
- [x] T016 Build/reuse a flat, textureless test region and a textured/edge-rich test region; confirm confidence output is visibly near-zero in the flat region and visibly higher in the textured region
  Confirmed with live camera footage: `det` preview dark in flat/shadowed regions (walls, dark furniture), visibly bright on structured content (window blind slats, picture frame edges, textured surfaces).
- [x] T017 **DECISION GATE:** check the raw determinant value range empirically before deciding on any normalization/clamping — per spec.md Phase 2, don't remap in a way that loses the zero-crossing meaning without first knowing what range you're actually working with
  **Real finding, not just a range check:** initial live-camera test showed two vertical bands reading as fully-saturated-white (maximum) confidence, which looked suspicious against the aperture-problem theory — a pure single-direction edge should read as *low* confidence (no constraint on motion along the edge), not high. Rather than assume the live footage or the math was wrong, ran the decisive test: swapped `test_edge_pix` (Stage B's perfectly axis-aligned synthetic vertical edge, zero vertical variation by construction) into `stage_a_pix` in place of the camera. Result: `det` read flat black across the entire pattern, including directly at the edge — confirming the solve is mathematically correct (a pure 1D edge genuinely collapses `Syy`/`Sxy` to ≈0, zeroing the determinant regardless of `Sxx`'s strength) and that the earlier live-camera bright bands were real scene content (genuine 2D texture, not a pure edge), not a bug. Precise numeric range for a future normalization decision still not pinned down (would need a `jit.gl.asyncread` readback chain, not yet built) — but the qualitative zero-crossing behavior is confirmed correct, which is what this gate actually needed. No clamp/remap decision made yet on `out2` — still raw, as originally decided.

**Checkpoint:** Both outlets (vecfield + confidence) confirmed correct against real test patterns, not just "compiles." → Proceed to Phase 3.

---

## Phase 3: definition.py and Build

**Purpose:** Assemble the three confirmed stage codeboxes plus the previous-frame pass pix into a real `pix_chain` bpatcher.

- [x] T018 Write `.specify/f_vf_optical_flow/definition.py` using `pix_chain`/`pix_wires` — 5 nodes: `pass_pix`, `stage_a_pix`, `stage_b_h_pix`, `stage_b_v_pix`, `stage_c_pix` (primary). Node count revised from plan.md's original 4 — see ADR-4 revision and T010.
  **`stage_a` is primary, not `stage_c`** — corrected from this task's own wording once the actual conflict surfaced (see T019). `stage_c` still produces the module's real outlets, via `outlet_source_override` + `raw_lines`.
- [x] T019 **DECISION GATE:** check whether `build_patcher.py`'s `outlets` mechanism already supports a non-`jit_gl_texture` outlettype for the scalar confidence outlet (per plan.md Block 3), or whether this itself needs a small schema check/extension before assuming it just works
  **Resolved, and the premise was wrong in an instructive way.** `jit_gl_texture` is already the *correct* outlettype for the confidence outlet — it's a per-pixel scalar encoded in a texture (same as every other `f_` outlet), not a discrete Max float atom, so no new outlettype was ever needed. The actual schema gap found was different and more structural: `build_pix_chain()` always wires the module's source into whichever node is `"primary"`, and always wires the module's outlets *from* that same primary node — but this module needs the source to reach `stage_a` while the outlets originate from `stage_c`, three stages downstream. Read `f_lens`'s `definition.py` directly (not assumed) and confirmed the exact mechanism already exists for this: `outlet_source_override` (suppresses the automatic primary→outlet wire) + `raw_lines` (supplies the real wire explicitly) — the same technique `f_lens` uses for its own downstream-of-primary outlet (tiltshift). Applied identically here, plus once more for `bypass` (same primary-vs-real-output mismatch — bypass auto-wires to primary/`stage_a`, but "output neutral field" only makes sense at `stage_c`, so `Param bypass` is declared in both codeboxes and fanned out to both via one extra `raw_lines` wire). No `build_patcher.py` changes needed — this was entirely a matter of using an existing, precedented mechanism correctly, not building a new one.
- [x] T020 Define standard Vsynth wrapper: routepass, autopattr, bypass toggle, moduleSize.js
  Generated automatically by `build_patcher.py`'s standard path — no bespoke wrapper code needed beyond the `outlet_source_override`/`raw_lines` additions above.
- [x] T021 Run build script per current `build_patcher.py` invocation convention (check usage directly, don't assume the same invocation as older custom build scripts)
  Checked `main()` directly: despite the tool's own `Usage:` message hinting at an older `src/f_<name>/definition.py` convention, it actually just takes whatever path is passed and writes output based on `defn["name"]`, independent of source location. Ran as `python3 build/build_patcher.py .specify/f_vf_optical_flow/definition.py` — works correctly from this project's actual `.specify/` convention.
- [x] T022 Validate JSON: `python3 -c "import json; json.load(open('patchers/f_vf_optical_flow.maxpat'))"` — must pass with no errors
  Passes. Also went further than "just validate" — wrote a small Python check against the generated patchline list confirming, wire-by-wire, that: (1) the module's real source reaches `stage_a` (not `stage_c`), (2) both outlets originate from `stage_c` with no leftover automatic `stage_a`→outlet wire, (3) `gain`'s `pix_target` resolved correctly to `stage_c` with no manual intervention, (4) `bypass` correctly fans out to both nodes, (5) `scale` correctly defaults to `stage_a` with no override needed. Every hand-derived object id (`stage_c` = `obj-53`, `bypass_pre_id(2)` = `obj-27`) matched the actual generated file exactly.

**OPEN ITEM carried forward, not silently resolved:** the scratch patch's Stage B codeboxes used `Param step(0.0015)` — `step()` is a documented built-in GenExpr operator, and shadowing built-in names is a confirmed silent-failure class in this codebase (though `step` specifically isn't yet on the skill file's confirmed list). If a collision did occur, all 5 window taps would degenerate to one repeated pixel — which would still look like "bright at the edge, flat elsewhere" in every visual test run so far, indistinguishable by eye from a genuinely working window. `definition.py`'s actual `.gen` files use `tap_step` instead (fixed internal constant, not a `Param`) specifically to avoid this risk, but the original scratch patch was never re-tested with the renamed variable to confirm which behavior it actually had. Worth a real re-check once this module loads in Max — Phase 4's T024 (does the flow read as coherent motion-following) is actually a reasonable indirect test of this, since a degenerate 1-tap "window" would produce a much noisier, less coherent `(u,v)` solve than a genuine 5×5 average.

**Checkpoint:** Valid `f_vf_optical_flow.maxpat` generated. → Proceed to Phase 4.

---

## Phase 4: Real-Consumer Wiring and Expressive Verification

**Purpose:** Answer the question the whole module exists to answer — does this produce expressively useful flow, not just numerically plausible output. This is the phase most likely to reveal the module isn't done yet, even if everything above passed.

- [x] T023 Open in Vsynth; wire `(u,v)` output into `f_vf_warp` (recommended per spec.md for legibility)
- [x] T024 With a live or played-back moving source, judge by eye: does the resulting warp read as coherent motion-following, the way the ruled-out frame-diff approach explicitly did not?
  **Real finding: initial result was noisy rather than flow-like, root-caused and fixed, not shipped as-is.** First attempt showed noise concentrated in high-*contrast* regions (window blinds, picture frame edges, silhouette outline), which briefly looked like it might be the expected single-scale fast-motion limitation (T025) — but a static-scene test (zero real motion) showed the same noise tracing the same edges, ruling that out. Root cause: `det_safe`'s divide-by-zero floor (Phase 2) amplifies ordinary per-frame sensor noise into large erratic `(u,v)` values specifically where `det` is small enough for the floor to matter but gradient is still nonzero — i.e. real 1D edges, the same aperture-problem geometry Phase 2's synthetic test already proved, just showing up as amplified noise on real edges instead of a clean `det≈0` reading. This reverses part of ADR-2's original scope (masking was explicitly deferred) — added `mask_lo`/`mask_hi` as live confidence-gate dials in `stage_c` rather than a hardcoded threshold. Confirmed by Matt directly against live camera input: cleanly kills static-scene edge noise while real motion in textured regions still passes through.
- [ ] T025 Test with fast motion specifically — confirm/deny the expected single-scale LK failure mode (breaks down on large frame-to-frame displacement). Document the finding concretely either way — don't silently declare the module done if this limitation shows up as expected; that's the known trigger for the pyramid upgrade (out of scope for this build, per spec.md).
- [ ] T026 Test confidence outlet in a real (non-synthetic-test-pattern) scene — confirm it's still doing something sensible, not just correct on the synthetic test cases from Phase 2
  Partially covered by T024's masking work (confidence outlet was the mechanism used to fix the noise), but not yet explicitly re-checked as its own outlet in isolation post-masking-fix. Also needs re-checking again post-Stage-D (T024b), since Stage D sits downstream of the confidence-consuming masking logic, not the confidence outlet itself — outlet1 is unaffected by Stage D, but worth confirming that assumption holds in practice, not just on paper.

**NEW, not in original plan — T024b Add temporal accumulation (decay/injection) as a second feedback stage.**
Even after T024's masking fix resolved the noise/correctness problem, Matt found the result still didn't read as coherent flow direction — the per-frame LK solve has no temporal continuity at all, so even correct instantaneous values wobble frame-to-frame with no persistence. Added a `stage_d_pix` + `pass_d_pix` feedback pair (mirroring `f_vf_advect`'s proven decay/injection accumulation pattern) after `stage_c`, with `decay`/`injection` as two new live dials. `stage_c`'s output is now only an intermediate injection signal; the module's real vecfield outlet comes from `stage_d`. Confirmed by Matt directly: "much closer" to the intended feel. See ADR-4's Phase 4 revision in `plan.md` for full architecture details.
**Module status: NOT stable.** Matt's own assessment at session close — this is real, confirmed progress, but the module needs more work before being considered done. Not yet clear which of T025/T026 (or something not yet identified) is the remaining gap versus just needing more hands-on tuning time. Treat as an open module, not a finished one, next session.

**NEW, not in original plan — T024c Fix frame-edge banding artifact at nonzero `scale`.**
Found during this session's real-consumer testing: any nonzero `scale` produced a visible banding artifact at the frame edges in the vecfield output. Root cause: `sample()` always clamps at texture boundaries on this GPU path (boundmode args are silently ignored, per `jit-gen-codebox` skill), so near any border one of Stage A's central-difference taps collapses onto the center sample instead of a genuinely-offset one — a biased/asymmetric derivative in a band `scale` pixels wide from every edge, not noise, with width scaling directly with `|scale|`. Fix: zero `Ix`/`Iy` explicitly within that margin in `codebox_stage_a.gen` (`edge_dist`/`edge_mask` via `step(abs(scale), edge_dist)`), rather than build a separate masking mechanism — Stage B's windowed sums then naturally shrink toward zero wherever the window touches this zeroed border, so Stage C's existing `mask_lo`/`mask_hi` confidence gate already treats it as "no data" with no new machinery needed (`mask_lo` must be above `0.00` for this to actually gate anything).
**Status: IMPROVED, NOT FULLY RESOLVED — carried forward, not closed.** Confirmed by Matt: the biased banding artifact is gone, and the overall flow reads as more coherent, not just border-clean. But the hard `step()` cutoff replaces the wrong-looking band with a visibly blank/dead framing at the border — an honest "no data" result, but not yet a graceful one. Matt's call: note it and move on rather than fix now. Real next step when revisited: soften the hard cutoff into a gradient — e.g. `smoothstep`-based falloff instead of `step`'s binary on/off, so confidence (and thus Stage E's eventual fill-in, once built) tapers into the border rather than hitting a wall. Worth deciding then whether the falloff width should still be based on `scale` alone or `scale + step` combined (the open question from earlier this session, also not yet resolved).

**Checkpoint:** Real expressive verification complete, with an honest answer either way — including if the answer is "single-scale isn't enough, pyramid is the real next step."

---

## Phase 5: Confidence-gated spatial fill — Stage E (NEW, 2026-07-18)

**Purpose:** Real, permanent aperture-problem failure mode found in Phase 4
testing (not a new bug, a performance limitation of single-scale LK): any
perfectly axis-aligned, single-orientation edge content (confirmed with a
WFG at Angle=0 and Angle=90; swapping the WFG for other sources reproduced
the same result, ruling out a source-specific cause) makes `Sxy`/`Syy`
exactly zero, so `det` is exactly zero and the solve is genuinely
singular — no gradient kernel or windowing change fixes this, since the
2D information needed simply isn't present locally. A 5° tilt away from
axis-aligned already produces real, usable flow, confirming this is
specifically the zero-tilt singular case, not a general noise problem.

**DECISION (2026-07-18):** this is scoped as part of `f_vf_optical_flow`
itself — a new Stage E fixing the module's own internal limitation — not
a separate downstream module consuming its vecfield+confidence outlets.
Matt's call: the ambiguity is intrinsic to how this module solves for
flow, so the fix belongs inside it.

**Mechanism, DECIDED 2026-07-18:** going straight for propagation along
the locally-ambiguous axis, skipping the isotropic-blur first pass —
Matt's call, since the directional version is the mathematically correct
fix for this exact failure mode (a vertical stripe's ambiguity is
resolved by information to its left/right, not above/below; isotropic
blur would spread correct flow into wrong directions too, just to get
some signal into the dead zone). Ruled out entirely: better gradient
kernels alone (doesn't manufacture information that isn't locally
present).

- [x] T034 **DECISION GATE:** isotropic confidence-weighted blur vs.
  directional propagation along the locally-ambiguous axis.
  **Decided: directional, built first — no isotropic pass.** Matt's call
  2026-07-18. The ambiguous-axis direction needs deriving as a per-pixel
  quantity from Stage B's own `A` matrix (not just its determinant) —
  see T038, now folded into the main path rather than a conditional
  follow-up.
- [x] T035 Derive the ambiguous-axis direction from Stage B's `A` matrix
  (`[[Sxx,Sxy],[Sxy,Syy]]`). **Done 2026-07-18.** Implemented in
  `codebox_stage_c.gen` using the standard structure-tensor double-angle
  result: `cos2t=(Sxx-Syy)/mag`, `sin2t=2*Sxy/mag`. Stored double-angle
  rather than a plain angle specifically to avoid a wraparound
  discontinuity (an axis repeats every 180°, so a naive single-angle
  encoding would jump somewhere in frame and blend garbage under Stage
  E's own bilinear sampling near that jump). No new pix outlet needed —
  packed into `out2`'s previously-decorative `y`/`z` channels (which used
  to just duplicate `det` for raw-preview convenience, carrying no real
  information). `out2` no longer previews as clean grayscale as a result
  — flagged as a real but currently-harmless behavior change, since no
  existing consumer reads `out2` (T023's `f_vf_warp` wiring uses `out1`
  only). Rebuilt and JSON-validated; not yet visually confirmed in Max.
- [x] T036 Build Stage E: confidence-gated directional propagation —
  low-`det` pixels sample along the T035 axis direction (both signs)
  for the nearest higher-confidence value and adopt it, rather than an
  isotropic blur. **Done 2026-07-18.** Inserted between Stage C and
  Stage D (C->E->D, per Matt's decision, so temporal accumulation works
  on an already-filled signal). New `codebox_stage_e.gen`: samples 4
  taps along T035's decoded axis (`reach`, `reach*2`, both directions),
  confidence-weighted average (reusing Stage C's own `mask_lo`/`mask_hi`
  dials rather than a duplicate pair), neutral fallback when no
  confident tap exists, `mix_pct` as a global dry/wet control. Two new
  live params (`reach`, `mix_pct` — internal name `mix_pct` per the
  locked mix-naming convention even though the UI label is "Mix").
  Inserting a node mid-`pix_chain` shifted every downstream hardcoded
  obj id and the dynamic bypass id (n_ui_params 7->9); all recomputed
  and verified by direct inspection of the built patcher's actual
  patchlines, not just JSON validity — confirmed C->E->D wiring, both
  mask dials reaching both stage_c and stage_e, bypass correctly
  reaching stage_a/stage_c/stage_d but NOT stage_e (by design — see
  codebox_stage_e.gen header for why stage_c/stage_d's own bypass
  already make this safe). Rebuilt and JSON-validated; not yet tested
  in Max.
- [x] T037 Re-test the Angle=0/Angle=90 WFG case from this session
  directly against Stage E's output — confirm real, non-zero, plausible
  flow now appears in what was previously a flat vecfield (and that the
  filled-in direction is plausible given the axis, not arbitrary).
  **Done 2026-07-18, confirmed by Matt: "passes... looks great."** Also
  separately confirmed on real Vsynth kaleidoscope content (polarizer ->
  Optical Flow -> Advect/Prism) — result read as coherent and pleasing,
  not just correct in isolation. One thing worth remembering for future
  tuning sessions: with `mask_lo` near 0, most richly-textured content
  already reads high-confidence almost everywhere, so `reach`'s effect
  can look subtle in a busy scene even when working correctly — it only
  visibly dominates in the (usually small) genuinely-low-confidence
  regions. Not a bug, just a real interaction between `mask_lo`/`mask_hi`
  and how much of the frame Stage E actually gets to touch.
- [x] T038 Confirm real motion consumers (T023's `f_vf_warp` wiring)
  still look correct/undistorted with Stage E in the chain — a fill-in
  stage that's too aggressive could smear real, already-confident flow
  boundaries. **Done 2026-07-18, called by Matt on the strength of this
  session's Advect/Prism results** (T037's kaleidoscope-content test,
  not a dedicated live-camera/`f_vf_warp` re-check) — no distortion or
  smearing observed on already-confident regions in that test. Worth
  keeping in mind this wasn't the exact T023 consumer/scenario, in case
  something specific to `f_vf_warp` or live camera content surfaces
  later; not treated as a live open question right now.

**Checkpoint: REACHED 2026-07-18.** Stage E confirmed filling the
axis-aligned aperture-problem case with directionally-plausible flow,
without degrading already-confident regions. → Proceed to Phase 6.

---

## Phase 6: Docs and Registration

**Purpose:** Update permanent project records. Nothing here until Phase 5 checkpoint is confirmed.

- [x] T027 Write `docs/f-reference/f_vf_optical_flow.md` — as-built reference: params, both outlets explained (vecfield + confidence), signal chain summary, single-scale limitation and Stage E's spatial-fill mitigation noted honestly. **Done 2026-07-18.**
- [x] T028 Update `README.md` bpatcher table. **Done 2026-07-18** — as Processor (matching `definition.py`'s own `archetype`), not Generator; caught and fixed a mislabel before it shipped.
- [x] T029 Add to appropriate category (`∇ Processors`) via `tools/rebuild_modules_menu.py`. **Done 2026-07-18** — see T031 for the full story (initially attempted via the wrong/stale script, corrected).
- [x] T030 Add size entry to `SIZES` dict in `javascript/f_addmod.js`. **Done 2026-07-18** (190×130, matching `definition.py`'s presentation size).
- [x] T031 Regenerate `patchers/f_modules.maxpat`; validate JSON. **Redone correctly 2026-07-18, after an initial mistake.** First attempt ran `build/tools/f_modules/build_modules.py`, which turned out to be a *stale* generator — its `CATEGORIES` list only knew about 5 categories, but the real live file had evolved to 8 (`Scope`, `Discrete`, `Spatial`, `Optical`, `∇ Generators`, `∇ Processors`, `Color / Tone`, `Utilities`), with nabla suffixes maintained by a separate script (`tools/append_nabla_menu.py`) that edits the live file directly. Running the stale generator overwrote all of that real, evolved structure (706 deletions in the diff) — caught by Matt immediately, reverted via `git checkout` before any further damage. Root cause fully understood, not just patched around: real source of truth is `tools/rebuild_modules_menu.py` (also had its own stale hardcoded output path, same class of bug as `build_modules.py`'s — fixed; also missing the `∇` prefix on its two nabla-category labels — fixed, verified via a dry run into a scratch path and diffed field-by-field against the live file before running for real, not just assumed correct). Added the new entry to `∇ Processors` (Matt's call — matches its architecture and its actual neighbors: `Flow`, `Caustic`, `Advect`, `Warp`, `Streak`, `Glow`, `Chroma`, `Repulse`, `Fieldmap`; declined the tempting-but-wrong "Optical" category, which is coincidentally named but thematically about lens/prism effects, not vecfield tech). Ran `rebuild_modules_menu.py` then `append_nabla_menu.py` (added `vf_optical_flow` to its `VECFIELD_MODULES` set first) — final diff was exactly 8 insertions/8 deletions: the intended addition, plus an incidental side-effect fix of a pre-existing duplicate `'Chladni ∇'` entry in slot 0 that predates this session (harmless, flagged to Matt, left as fixed rather than reintroduced).
  **`build/tools/f_modules/build_modules.py` is now confirmed stale/superseded by `tools/rebuild_modules_menu.py` — should not be run again until reconciled or retired.** Its own path bug was fixed in passing but that doesn't make its `CATEGORIES` list correct; it's a separate, unresolved problem from the real one (`rebuild_modules_menu.py`'s stale path), and conflating the two nearly caused real damage.
- [x] T032 Write `.maxhelp` file per `f-helpfile` skill conventions. **Done 2026-07-18** — modeled on `f_vf_fieldmap.maxhelp` (closer structural match than the skill's own `f_droste.maxhelp` template, since this module has no separate scalar/LFO inlet). Built programmatically to get line counts/rects and real per-param object ids exact, pulling ids directly from the built `.maxpat` rather than hand-computing them. Also noticed (not fixed): the skill doc's own stated helpfile location (`help/`) is stale — actual location is `package/help/`, same class of issue as the build_modules.py bug above.
- [x] T033 Update `HANDOFF.md`. **Done 2026-07-18.**

**Checkpoint: Ready to commit.** All six phases complete. Two honest rough edges carried forward as known limitations, not blockers: T024c's edge-framing (improved, not fully graceful) and T025 (fast-motion breakdown genuinely untested, not just deferred). See `HANDOFF.md` for full session summary and suggested commit split.

---

## Dependencies

**Phase dependencies (strict):**
- Phase 0 → Phase 1: Stage A confirmed before building Stage B's windowed sum on top of it
- Phase 1 → Phase 2: Stage B's sums confirmed correct before solving from them
- Phase 2 → Phase 3: both stage-C outlets confirmed against real test patterns before assembling the full `pix_chain`
- Phase 3 → Phase 4: valid patcher before real-consumer testing
- Phase 4 → Phase 5: axis-aligned aperture-problem limitation found and scoped as an internal fix (Stage E) before building it
- Phase 5 → Phase 6: Stage E confirmed working, not degrading existing behavior, before docs/registration

**No cross-phase parallelism** — each gate exists specifically because this module has more genuinely untested territory (the windowed-sum stage, and now Stage E's spatial-fill mechanism) than most modules in this library.

---

## Notes

- Four explicit decision gates are embedded in this task list (T003, T009, T017, T019, T034) rather than left as spec.md prose, per the project's convention of putting outstanding architecture/design decisions into `tasks.md` as real to-do items when they exist for a module.
- The most likely point of real difficulty is T010 (5×5 ceiling risk) — treat a ceiling hit as an expected possible outcome with a known response (split further), not a surprise requiring re-architecture.
- T025 is the task most likely to produce an honest "not fully done" result even after everything else passes — that's expected given ADR-3's deliberate single-scale-only scope, not a sign something went wrong.
- Phase 5 (Stage E) exists because the axis-aligned aperture-problem case is a real, permanent characteristic of single-scale LK, not something more tuning of Stage A-D would fix — confirmed by testing the same WFG at multiple angles (flat vecfield at 0°/90°, real flow at 5°) and by swapping the WFG for other sources with the same result, ruling out a source-specific cause before treating it as a module-internal limitation worth fixing.
