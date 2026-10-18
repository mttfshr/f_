# Implementation Plan: f_tf_tensormap

_Date: 2026-10-16_
_Spec: .specify/f_tf_tensormap/spec.md_
_Hub: ideas/f_tensorfield.md (design history, consumer audit)_

---

## Summary

`f_tf_tensormap` is a stateless, multi-stage `pix_chain` producing a 2x2 structure tensor from a scalar-dominant texture, with two `@type float32` outlets (raw tensor; packed direction/trace/coherence). Four forward stages, no feedback pass:

```
in0 -> stage_a   (Sobel on luma; emit gx*gx, gx*gy, gy*gy)
    -> stage_b_h (horizontal box sum of the three products)
    -> stage_b_v (vertical box sum; completes the window -> Jxx, Jxy, Jyy)
    -> stage_c   (trace, closed-form eigen, theta, coherence; encode out1 + out2)
```

This is the same shape `f_vf_optical_flow` settled on (separable window sum, then a closed-form solve), minus its previous-frame pair. That module is the build precedent for the schema questions; this plan follows it rather than re-deriving them.

Most of the risk is not the math (a NumPy spike exists and `atan2` is bench-verified). It is three things the spike could not answer: what the smoothing costs on the GPU at HD/4K, how `radius` is implemented under GenExpr's fixed-loop rules, and whether the `pix_chain` schema fans params out cleanly to stages that are not the primary node.

---

## Technical Context

**Environment:** Max 9, Vsynth, `jit.gl.pix` gen codeboxes, `@type float32` throughout
**Build method:** NumPy mirror (tier 1) -> codeboxes on the bench (tier 2) -> scratch patch (tier 3) -> `definition.py` -> `tools/build_patcher.py`
**Output:** `package/patchers/f_tf_tensormap.maxpat`
**Gradient kernel:** verified Sobel, `.specify/stable/f_vf_sobel/spec.md`
**Mirror precedent:** `tests/records/spike_structure_tensor_range.py` (vectorized NumPy; reused as an independent cross-check, not as the mirror)
**GPU budget:** performance runs at HD or 4K on an M3 Max or an M1; the M1 is unmeasured (ways-of-working). Costs measured here are M3 Max numbers and say so.

---

## Files

```
.specify/f_tf_tensormap/
  spec.md             done
  plan.md             this file
  tasks.md            next to this file
  definition.py       written in Phase 3
  codebox_stage_a.gen      Phase 1
  codebox_stage_b_h.gen    Phase 1
  codebox_stage_b_v.gen    Phase 1
  codebox_stage_c.gen      Phase 1

tests/
  test_tf_tensormap.py     tier 1 NumPy mirror, one function per stage      (Phase 0)
  bench_tf_tensormap.py    tier 2, real codeboxes on the GPU                (Phase 1)
  spike_tf_tensormap_cost.py   only if the cost gate needs it               (Phase 1)

~/Vsynth/patterns/ (not in repo)
  tf_tensormap_scratch.maxpat   tier 3 judgement                             (Phase 2)

docs/f-reference/
  f_tf_tensormap.md        as-built reference                                (Phase 5)
  f_tensor_type.md         the encoding contract, sibling of f_vecfield_type.md (Phase 5)
```

Where the codeboxes live (`src/<name>/` vs `.specify/f_tf_tensormap/`) follows whatever `f_vf_optical_flow` actually does; Task T028 reads it rather than assuming. Paths above assume `src/<name>/` per the current convention, with `<name>` = `f_tf_tensormap` (ADR-7).

---

## Architecture Decisions

### ADR-1: Staged separable chain, not one brute-force codebox

**Context:** The tensor needs per-pixel gradient products averaged over a neighborhood. Done in one codebox that is (2r+1)^2 Sobel evaluations (8 samples each) per pixel, and `radius` is a live performance parameter.

**Decision:** Four stages. Stage A computes the three products once per pixel. Stages B_h and B_v do a separable box sum. Stage C does the eigen math and encoding.

**Rationale:** Same argument that made `f_vf_optical_flow` split its window sum (tasks T008/T010 there): separable is mathematically identical to the 2D box and avoids the GL2->GL3 capture-group ceiling (a codebox over ~450 statements fails to compile and can wedge the bench; see `skills/jit-gen-codebox`). It also keeps each stage independently benchable, which Verification Tiers want.

**Consequences:** Four `pix` nodes. Intermediate textures are float32 and unbounded. The final stage is the only one that clamps or encodes.

---

### ADR-2: The A channel is normalized coherence, not raw lambda1-lambda2

**Context:** The hub doc's shorthand says "A = anisotropy (lambda1-lambda2)". The spike that backs the representation choice computes `(lambda1-lambda2)/trace`, in [0,1]. The first spec draft followed the shorthand. Found and corrected 2026-10-16.

**Decision:** `A = coherence = (lambda1-lambda2)/(lambda1+lambda2)`, guarded to 0 where trace is below epsilon. `strength` applies to B (trace) and outlet 0 only.

**Rationale:** The spike's visual check ("dark near-isotropic points line up with direction singularities") was done on the normalized quantity, so it is the one with evidence. It is also the one the `f_vf_glow` confidence gate (hub doc Q12) needs: a 0-1 trust value that does not drift with image contrast. Raw lambda1-lambda2 would make a faint but cleanly oriented texture read as untrustworthy.

**Consequences:**
- A is noisy where trace is tiny (coherence of noise is spuriously high). Consumers wanting "real structure here" read A together with B. Worth a sentence in the docs.
- The epsilon on trace (ADR-6) is now load-bearing, not cosmetic.
- Confirm on real content in the scratch patch (T025).

---

### ADR-3: `radius` is implemented as a bounded loop with weight gating (decided: Matt, 2026-10-16)

**Context:** GenExpr loop bounds are fixed; `radius` is a live dial. Two ways to get a variable-width box sum: loop to a compile-time `R_MAX` and zero the weight of taps beyond `radius`, or use a fixed tap count and make `radius` the tap *spacing*.

**Decision (Matt, 2026-10-16):** bounded loop, weight `step(abs(i), radius)` per tap, normalized by the actual tap count. `R_MAX` is chosen by the cost spike (T016/T017). If cost is too high the answer is a smaller `R_MAX`, i.e. a narrower `radius` range, not a different algorithm. The strided-taps alternative is dropped.

**Resolved (Matt, 2026-10-16): `R_MAX` = 16, `radius` in pixels, range 0-16.** Bench (M3 Max, 1080p): R_MAX 8 and 16 each cost under ~0.87 ms per smoothing pass (CPU-bound upper bound); R_MAX 32 costs ~1.9 ms. 4K and full-chain cost still to measure; M1 unmeasured. Also found: the bench GPU wraps out-of-range reads, so every stage clamps coordinates to texel centres in-shader (ADR-5).

**Rationale:** The loop is an exact box blur, so it matches the spike and the mirror and the tier-1 ground truth is clean. Strided taps are cheaper but under-sample (gaps) at large radius and change the filter's meaning; they are only worth it if cost forces it.

**Consequences:**
- Cost scales with `R_MAX`, not the live `radius`: turning the dial down saves nothing. Report this to Matt as a fact, not a surprise.
- Pixel units (the spike's units). Resolution-dependence of a pixel radius at HD vs 4K is an open question for T024, noted not solved.
- Because the loop is an exact box blur, the tier-1 ground truth is the ideal box, with no approximation to qualify.

---

### ADR-4: Float32 internally; clamp only at the outlets

**Context:** Sobel products are unbounded (contrast 1.0 gives gx up to 4, so gx^2 up to 16), and Jxy is signed.

**Decision:** Stages A, B_h, B_v are `@type float32` and store raw values, no 0.5 offset, no clamp. Stage C applies `strength`, the 0.5 offsets for signed channels, and the clamps.

**Rationale:** Encoding mid-chain would clip exactly the strong-edge regime the spike says dwarfs typical content. Same reason `f_vf_optical_flow` made its accumulators float32.

**Consequences:** Internal textures are not valid anything-else; they are never exposed as outlets.

---

### ADR-5: Edge handling matches the mirror, verified rather than assumed

**Context:** The spike pads with edge-clamp. Whether Jitter's sampling at texture borders (and `gpu_sim.sample`'s model of it) agrees is a per-environment fact.

**Decision:** The mirror uses `gpu_sim.sample`/`nearest` with the clamp the bench has verified, not array slicing. T012 checks the border rows and columns explicitly against the GPU.

**Consequences:** If the GPU wraps instead of clamps, the mirror follows the GPU (it is the thing being modeled) and the spec's edge behavior gets a one-line note.

---

### ADR-6: Degenerate pixels output neutral, by an explicit epsilon on trace

**Context:** theta and coherence are undefined where the tensor is zero or near zero, and `atan2(0,0)` on the GPU returns an arbitrary angle.

**Decision:** Below `eps_trace`, stage C writes R=G=0.5 and A=0. `eps_trace` is a stage C constant in pre-gain units, set in T019 from the mirror's float32 noise floor (a flat input gives exactly 0), not guessed.

**Rationale:** A consumer must never read an invented direction out of a flat region. This is the one place the producer actively protects consumers from the branch-cut problem it otherwise only documents.

**Consequences:** A one-pixel-wide transition at the epsilon boundary. Acceptable; checked on noise content in tier 1.

---

### ADR-7: Naming and outlet order decided by Matt (2026-10-16); `signal_type` still open

**Context:** `f_tf_tensormap` and the `tf` family prefix were open (hub Q4, spec OQ1), as was outlet order (raw first vs convenience first, spec OQ6). `signal_type` tagging for non-vecfield outlets is a build-pipeline question (spec OQ5).

**Decision:** Name is `f_tf_tensormap` (prefix `tensormap`, object `tensormap_pix`, following `f_vf_fieldmap`); outlet 0 is the raw tensor and outlet 1 the packed convenience. Only `signal_type` remains a gate (T030), and it blocks `definition.py` alone.

**Rationale:** They are cheap to decide and expensive to rename later (prefix flows into object names, the modules menu, helpfiles and the constitution's naming table).

---

### ADR-8: Verification tiers

**Decision (recorded as the Phase 0 gate, T001):**
- **Tier 1 (NumPy mirror): applies.** Closed-form eigendecomposition and angle recovery have independent ground truth (`np.linalg.eigh` on 2x2 tensors; an analytic ramp at a known angle).
- **Tier 2 (bench): applies.** Four real codeboxes to compile, a border-handling question, and a cost question.
- **Tier 3 (scratch patch): applies** for the `strength` default, `radius` range, and the visual character of B/A on real content.

**Consequence:** Tests are run sparingly and in the background (ways-of-working): one affected test at a time, `tests/bg.sh`, `-q`, and ask before a bench run.

---

## Dependency Blocks

### Block 1: Math settled in NumPy
**Dependencies:** none
**Builds:** `tests/modules/tf_tensormap/test_tf_tensormap.py`, one mirror function per stage
**Verification:** matches `np.linalg.eigh` and analytic ramps; cross-checks against the spike implementation; one mutation check

### Block 2: Codeboxes on the bench
**Dependencies:** Block 1
**Builds:** four `codebox_*.gen` files, `tests/modules/tf_tensormap/bench_tf_tensormap.py`
**Verification:** each stage compiles and matches its mirror on the GPU; border rows checked; cost measured per stage and for the chain

### Block 3: Judgement on real content
**Dependencies:** Block 2
**Builds:** scratch patch only
**Verification:** `strength` and `radius` defaults feel usable on bfg Perlin / Voronoi / fbm; B/A separate structure from flat regions

### Block 4: Patcher
**Dependencies:** Block 3; signal-type gate (T030)
**Builds:** `definition.py`, generated `.maxpat`, modules-menu registration
**Verification:** loads in Vsynth; params addressable; both outlets render; unconnected and bypass give the zero-tensor neutral; drift-clean; contract tests green

### Block 5: Docs and handoff to consumers
**Dependencies:** Block 4
**Builds:** reference docs, encoding contract, helpfile, README/constitution entries
**Verification:** helpfile passes the `module-preflight` gate; hub doc updated so the `f_vf_glow` anisotropy-gate build (Q12) is unblocked

---

## Implementation Phases

### Phase 0: Gates + tier-1 math (BLOCKING)
Record the tier gate and the naming decision (made), write the NumPy mirror and its independent ground-truth checks. Exit: mirror agrees with `np.linalg.eigh`, the known-angle ramp, and the spike; one injected bug is caught.

### Phase 1: Codeboxes on the bench (BLOCKING)
Write the four stages against the mirror, one at a time. Pick `R_MAX` by measurement (ADR-3: bounded loop is decided). Exit: every stage matches its mirror on the GPU, border behavior confirmed, cost recorded.

### Phase 2: Scratch patch, judgement tier
Calibrate `strength` and `radius`, look at B/A on real content, try a throwaway decode preview. Exit: provisional values in the spec become real, or the spec says why they did not.

### Phase 3: definition.py and build
Read the two `pix_chain` precedents first, write `definition.py`, build, validate, register in the modules menu, confirm drift-clean and contract tests. Exit: loads in Vsynth with the zero-tensor neutral on unconnected and bypass.

### Phase 4: Integration check without a consumer
There is no consumer yet. Prove the outlets are usable by wiring outlet 1 into `f_vf_split` (bipolar) to see cos2theta / sin2theta as scalars. Exit: the doubled components appear and rotate correctly with a rotated test input.

### Phase 5: Docs and handoff
Reference doc, encoding contract, helpfile, README, constitution naming entry, hub doc update, HANDOFF. Exit: Phase 2 work on `f_vf_glow` (hub Q12) has a real producer to build against.

---

## Out of this plan

- Consumers (`f_vf_glow`, `f_stipple`, `f_grain`, ...). Q12's design is in the hub doc; its build gets its own tasks under `f_vf_glow/` once this ships.
- Scharr or any second gradient operator.
- A shared decode helper module.
- Mod inlets on `strength` / `radius` (also blocked behind `mod_depth_ui_density.md`).
