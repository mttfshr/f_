# Implementation Plan: f_engrave

**Date**: 2026-11-08
**Spec**: .specify/f_engrave/spec.md

This plan is **a plan for a spike first**. The line-field method (spec G2) is unsolved, so the architecture below is conditional on which candidate passes. All gate decisions are **preliminary** (Claude's recommendations, accepted in place on Matt's instruction, 2026-11-08; Matt has not confirmed them). Everything about the candidates is **inferred or from memory of the literature and not checked**; nothing has been run.

---

## Summary

The module draws evenly spaced lines that follow a tensor's axis, with width set by tone, one plate per channel. The hard part is not the drawing but the **line field**: a pattern whose spacing is regular, whose phase is continuous along the direction field, and which is stable under motion. Phase 0 is therefore a NumPy spike that builds a metric harness (the spec's SC-001 to SC-005) and tries five candidate methods against synthetic fields, ending in a decision gate with a **stop rule**: if no candidate meets the criteria on the fields where regular spacing is geometrically possible, the module is not built and the result is recorded. If one passes, Phase 1 builds it, with the architecture decided by the winner.

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix` GPU path (GenExpr). `@type float32`. Inputs: the raw tensor on in0 (`f_tf_tensormap` outlet 0 encoding, `docs/f-reference/f_tensor_type.md`; a packed feed is a wiring error) and the tone plates on in1.
- **Spike tooling**: ad-hoc NumPy scripts via `uv run --no-project --with numpy python3 script.py` (system `python3` and `build/py.sh` have no numpy: HANDOFF.md process note, read 2026-11-07); kept under `tests/modules/engrave/spike/` and not shipped. Mirror code for the winner moves to `tests/modules/engrave/`.
- **Limits** (`skills/jit-gen-codebox/SKILL.md`, `ideas/f_deflicker.md`; read, not re-run): about 250 statements per function and about 450 per program; about 16 reads per stage; `noise()` black on this path; a bilinear tap on a texel corner once returned ONE texel, which matters a great deal for any method that interpolates a coarse solved field.
- **Reference points in the repo**: `f_tf_hatch` (streamline renderer; its reference doc, read 2026-11-08, gives the tensor decode idiom, `eps_trace` zero-tensor guard and a 16-step march; its Streamline stage costs about 5 to 12 ms, hardware not stated). `f_ks` and `f_wave_field` are 256² GPU solvers with feedback (inventory, not opened), the precedent for a stateful coarse solve. `f_tf_axisflow` is the tensor-to-vecfield bridge (not used here, spec P2).

---

## Constitution Check

✅ Specs before building, and numbers before eyes: the method is chosen by measured criteria in a NumPy mirror before any codebox is written.
✅ Codebox-first, one concern, thin patcher; the patcher shape is decided after the method.
⚠️ **The method may not exist** within the shader limits: handled by the stop rule rather than by lowering the criteria.
⚠️ **A stateful method** changes bypass, bench and the idle behaviour (spec G4); the plan asks for a stateless method first and treats statefulness as a cost to be justified.
⚠️ **Geometric caveat (inferred)**: two streamlines of a general direction field cannot stay a constant distance apart; their separation changes with the field's divergence. A perfectly regular pitch is therefore possible only on fields without divergence between lines (parallel, concentric). Engravers handle the rest by starting and ending lines. The spec's criteria are therefore evaluated on fields F1 to F3 below, and F4 and F5 are measured, not passed or failed.

---

## Project Structure

```
tests/modules/engrave/spike/
  fields.py                  # synthetic tensor fields F1..F5 (below) as raw-tensor arrays
  metrics.py                 # SC-001..SC-005 on an output image: area law, spacing CV, angle error, continuity, stability
  cand_a_lic.py  cand_b_iso.py  cand_c_dist.py  cand_d_phase.py  cand_e_gabor.py
  spike_report.md            # numbers per candidate per field, and the decision
(after the decision)
src/f_engrave/{definition.py, codebox_*.gen}      # shapes depend on the winner
tests/modules/engrave/{engrave_mirror.py, test_engrave.py, bench_engrave.py, bench_engrave_module.py}
package/patchers/f_engrave.maxpat   docs/f-reference/f_engrave.md   package/help/f_engrave.maxhelp
```

---

## Architecture Decisions

### ADR-1: Spike before architecture; stop rule (G2, spec FR-005)

**Decision**: Phase 0 builds the harness first (fields, metrics), then each candidate against it in float32 NumPy ignoring shader limits, then checks the winner's feasibility against the limits. The decision gate is Matt's. If no candidate meets SC-001 to SC-004 on F1 to F3 (thresholds fixed from the harness, spec "set in Phase 0"), the spec is parked with the spike report and no module is built.
**Rationale**: the idea file says "pick by looking, not by reasoning"; looking is cheap in NumPy and expensive in Max.

### ADR-2: Synthetic fields

- **F1** uniform axis at an angle (and at 0, 45, 90 degrees); the baseline.
- **F2** concentric rings around a point (constant spacing is geometrically possible); the continuity and alignment test.
- **F3** a gentle sinusoidal bend, small divergence.
- **F4** radial rays (spacing must grow away from the centre): measured for how the candidate inserts or lets spacing grow.
- **F5** a field with a ±½ index singularity (a wedge) and one with a saddle: measured for the neighbourhood policy (spec G5).
Each at two tone levels (flat 0.5 and a ramp) and with a small perturbation copy for the stability metric.

### ADR-3: The five candidates (G2); predictions are inferred and are what the spike tests

- **A. LIC over a stripe seed** (spec candidate a). Prediction (inferred): integrating a periodic stripe seed along the flow blurs the stripes away wherever the flow crosses them, so lines survive only where the field aligns with the seed's stripes. Expected to fail F2 and F3. Cheap to test and a useful negative result.
- **B. Iso-lines of smoothed tone** (spec candidate b). Lines follow contours automatically; the spacing is the tone gradient's, not `pitch`. Prediction (inferred): bunching where the gradient is steep, so it fails the spacing criterion unless the scalar is gradient-normalised (which breaks near extrema).
- **C. Distance from the previous line** (spec candidate c). Seed a line, then place the next at distance `pitch` perpendicular to the field, iteratively. Prediction (inferred): exact spacing near the seed, drift away from it, and the iterative placement is sequential, so on the GPU it needs a jump-flooding-style multi-pass approximation.
- **D. Global phase solve on a coarse grid**, in the style of "Stripe Patterns on Surfaces" (Knöppel, Crane, Pinkall, Schröder, 2015), recalled from memory and **not read this session**: solve for a complex field whose phase is the line coordinate, aligned to the direction field, with singularities handled by line dislocations. Prediction (inferred): the best chance on continuity and singularities; cost is an iterative solve (stateful across frames, or many passes) on a coarse grid (a 256² solver is the repo's precedent), plus interpolating the solved field at full resolution, which depends on `sample()` (spec G9).
- **E. Oriented Gabor or phasor noise**, recalled from the procedural-noise literature, **not read this session**: sum of oriented kernels so the stripe frequency and orientation follow the field. Prediction (inferred): stateless and local, but needs many taps per pixel and its phase coherence between kernels is only approximate, so lines may break (SC-004).
**Selection**: by the harness numbers, then feasibility (statements, reads, state, cost), then Matt's look.

### ADR-4: Tone to width, per-line sampling (G7, G8, spec P8, P9)

**Decision (preliminary)**: whatever the method, the line coordinate `s` (distance across the line in pitch units, in `[-0.5, 0.5]`) gives width by `inked = |s| < tone / 2`, so the area law is exact on constant tone; hairlines (width under a texel) are drawn as partial coverage by an antialiasing ramp the width of a texel (as `f_screen` ADR-3); tone 0 gives exactly 0 and tone 1 exactly 1. The tone is read at the line's centre (the pixel moved by `-s * pitch` along the line normal), one `nearest` tap, so a line's width varies along it only with the tone along its centreline. Lines thin to nothing in highlights; whether a line also *ends* is deferred (the `ends` control in the spec's User Story 6).

### ADR-5: Direction input (spec P1, P2, P6, P7)

**Decision (preliminary)**: decode the axis from the raw tensor in the stage, using the closed-form decode and `eps_trace` guard that `f_tf_hatch` documents; plate angle offsets add to it; where coherence is under `coh_floor` the direction blends to `fallback_angle` over a ramp. Smoothing is upstream (`f_tf_smooth`, `f_tf_aniso_blur`). Code sharing with `f_tf_hatch` is unverified (spec G12); copying the decode is the fallback.

### ADR-6: State and bypass (G4, spec P11, P12)

**Decision (preliminary)**: prefer a stateless method. If the winner is stateful, bypass passes in1 through and the solve keeps running underneath (as `f_vf_advect` does, per the inventory), and an idle test shows the output settles. Decided at the decision gate.

### ADR-7: Bounds, alpha, bypass, units (spec FR-008 to FR-011)

**Decision**: output clamped to 0..1; non-finite input zapped; alpha from in1; `bypass` is the codebox `bypass_gate` Param (never native `@bypass`); lengths in frame heights (shared with `f_ink` and `f_screen`).

---

## Stage and wiring sketch (conditional)

```
in0 tensor (vs_inState) ----+
                            +--> [line-field stage(s): method-dependent] --> draw stage --> out0
in1 tone plates (vs_inState)+                                                   ^
r dim -> every stage                                          tone read at line centre (ADR-4)
```

---

## Testing plan (constitution tiers)

- **G1 decided (preliminary)**: tier 1 is the spike and then the mirror of the winner (geometry metrics are numbers, so they come first); tier 2 benches the real codebox against the mirror; tier 3 is Matt's look. Nothing is skipped; the spike *is* part of tier 1.
- **Tier 1**: the harness metrics (spec SC-001 to SC-007) on F1 to F5; plate independence; determinism; stability under perturbation.
- **Tier 2**: after the decision, each stage's real codebox against the mirror (stage by stage, per the constitution); the first bench measures `sample()` (spec G9) and the cost against `f_tf_hatch`'s.
- **Contracts**: register in `tests/contracts/test_module_contracts.py` and `bench_modules.py`.
- **Tier 3 (Matt)**: a photo through `f_tf_tensormap`, smoothing, and `f_engrave`; crosshatch from a second plate; followed by `f_ink` and `f_paper`; a bent use.

## Risks

- **No method passes** (the stop rule): the expected cost of this plan is a documented negative result. Candidate D is the most likely to pass and the hardest to fit.
- **Candidate D needs interpolation** of a coarse solved field, which collides with the open `sample()` question.
- **Statefulness** (D) complicates bypass, the bench and idle behaviour.
- **Cost** is unmeasured (spec G10) and may exceed what a performance patch tolerates.
- **Singularities** (spec G5): lines converge or break near ±½ points; the policy is measured on F5.
- **Thresholds are not chosen yet:** SC limits come from the harness; picking them after seeing the numbers is a bias to guard against, so the harness reports each candidate's numbers *before* thresholds are written into the spec, and Matt sets them.

## Phasing (details in tasks.md)

- **Phase 0**: the spike: harness, five candidates, the report, the decision gate.
- **Phase 1** (only if a candidate passes): the mirror of the winner, codebox, `definition.py`, patcher, benches.
- **Phase 2**: tuning with Matt.
- **Phase 3**: reference doc, helpfile, menu, README.
