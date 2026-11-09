# Implementation Plan: f_separate

**Date**: 2026-11-08
**Spec**: .specify/f_separate/spec.md

All gate decisions below are **preliminary**: Claude's recommendations, accepted in place on Matt's instruction (2026-11-08). Matt has not confirmed them, and the overprint model in particular is Claude's choice, not checked against his prepress app. Derivations marked inferred are worked out, not run.

---

## Summary

A stateless, per-pixel processor in one `jit.gl.pix` stage with two outlets. It converts each pixel to optical density relative to the paper, solves a small least-squares problem for the coverage of each of up to three inks, clamps the result to 0..1 and writes it as three plates (outlet 0). It then recomposes the plates on the paper by the same model and writes that as a live preview (outlet 1). The colour controls are the open build question (spec G6).

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix` GPU path (GenExpr). `@type float32`.
- **Archetype**: processor, in0 the `driving_inlet`; one stage; two outlets (the build supports several outlets per stage: `f_vf_glow` has two). With in0 unconnected both outlets are black.
- **Limits** (`skills/jit-gen-codebox/SKILL.md`, read, not re-run): about 250 statements per function and about 450 per program. The solve below is a few dozen statements per pixel (inferred).
- **Colour controls**: a search of `src/f_vf_glow/definition.py` and `build/spec.md` (2026-11-08) found no colour-picker parameter type (`f_vf_glow`'s `color_mix` is a float dial). So colours are either three float dials each, or a raw `swatch` object per colour routed to Params. Unverified; spec G6, gate T009.
- **Build**: `src/f_separate/definition.py` → `build/build_patcher.py` → `package/patchers/f_separate.maxpat`.

---

## Constitution Check

✅ Codebox-first; one concern (colour into plates); the patcher is a thin wrapper.
✅ Numbers before eyes: reproduction of each ink, overprints, the paper, the round trip and degenerate palettes are all closed forms or invariants (spec SC-001 to SC-006), so tiers 1 and 2 come before the live look.
⚠️ The overprint model is not a decision to settle by eye alone: it fixes the contract with `f_paper` (whose spec is not written). Mitigation: record the model in this plan and the spec, test the round trip, and hold the contract open (T008).
⚠️ A per-pixel solve costs more than a lookup; mitigated by the small size (N ≤ 3) and measured on the bench.

---

## Project Structure

```
src/f_separate/
  definition.py              # source of truth
  codebox_separate.gen       # the single stage: density, solve, plates, preview
tests/modules/separate/
  separate_mirror.py         # float32 NumPy mirror
  test_separate.py           # tier 1
  bench_separate.py          # tier 2: real codebox vs mirror
  bench_separate_module.py   # shipped patcher: bypass, flags, colour controls
package/patchers/f_separate.maxpat   docs/f-reference/f_separate.md   package/help/f_separate.maxhelp
```

---

## Architecture Decisions

### ADR-1: Density model, solved in log space (G2, spec P2)

**Decision (preliminary, inferred)**: for paper colour `P` and an ink with full-coverage colour `k_i`, the density of ink `i` per channel is `d_i = -ln(max(k_i, ε) / P)` (clamped at 0 where `k_i` exceeds `P`). A pixel with colour `x` has target density `t = -ln(max(x, ε) / P)` (clamped at 0 where `x` exceeds `P`). Coverages add: `t ≈ D c`, where `D` is 3×N with columns `d_i`. The recomposed colour is `P * exp(-D c)`.
**Rationale**: logs make the overprint linear in the coverages, so the unmix is one small least-squares solve, a few dozen operations and order-independent. It is also a reasonable first model of translucent ink layers (inferred).
**Alternative kept for comparison**: the coverage-weighted multiply `P * Π_i (1 - c_i (1 - k_i / P))`, not linear in `c`. Decide by the round trip and by comparing the preview with Matt's prepress app (T008).
**Consequence**: `f_paper` will need to apply this same model; the contract is written into this plan so the later spec can inherit it.

### ADR-2: Solve and constraint (G3, spec P1, P4)

**Decision (preliminary)**: for `N` inks, `c = clamp((DᵀD + λ I)⁻¹ Dᵀ t, 0, 1)` with a small ridge `λ` (about 1e-4, tuned) for collinear palettes. `DᵀD` is N×N with N ≤ 3, inverted in closed form by cofactors in a function. Unconstrained solve then clamp is cheap and not optimal; a constrained (non-negative) solve for three inks is the alternative if the clamp looks wrong near the gamut boundary (tier 3).
**Fewer inks than three** (`inks` 1 or 2): the same formula with `D` of N columns; the unused plate channels are written as exactly 0.

### ADR-3: Degenerate cases (G4, spec FR-007)

**Decision (preliminary)**: `ε = 1e-4` on every logarithm argument; an ink equal to the paper has zero density (its column is zero, ridge keeps the inverse finite, its plate comes out 0); a pixel brighter than the paper has `t` clamped to 0, so every plate is 0; non-finite input is zapped to 0 before anything else.

### ADR-4: Two outlets and the preview (G5, spec P5)

**Decision (preliminary)**: out1 is `P * exp(-D c)` with the gains applied to `c`, clamped to 0..1, computed in the same stage from the same `D`. The preview duplicates `f_paper`'s core, minimally. Sharing code with a future `f_paper` is unverified in this build system; if it is not possible, the duplication stays small (about five statements).
**Rejected**: no preview outlet (the live gamut preview is the point of the module, per Matt's description of the prepress app).

### ADR-5: Nearest mode (spec P6, User Story 5)

**Decision (preliminary)**: for each pixel compute the squared RGB distance to each ink colour and to the paper; the nearest wins; if an ink wins, its plate is 1 and the others 0, if the paper wins all are 0. RGB distance, not density distance, for now (inferred: simpler, and the decision is a tier-3 look).

### ADR-6: Colour controls (G6)

**Decision (preliminary)**: Phase 0 first tries one `swatch` box per colour (three inks plus paper) in `raw_boxes`, outputs unpacked to the Params `ink1_r` … `paper_b` (twelve Params). The fallback is twelve float dials grouped in rows. Unverified: the first build task proves the swatch route offline (JSON and route) and Matt confirms it in Max.
**Rejected**: hard-coding the palette in the codebox.

### ADR-7: Bypass, alpha, bounds (spec FR-009, FR-010, FR-012)

**Decision**: `bypass` is the codebox `bypass_gate` Param (never native `@bypass`); both outlets pass the source through. Alpha copied from the source on both outlets. Plates and preview clamped to 0..1.

---

## Stage and wiring sketch

```
in0 (driving_inlet) -> separate -> out0 (plates), out1 (preview)
swatch x4 -> unpack -> Params ink1_r .. paper_b -> separate
inks / mode / gains / bypass -> Params -> separate
```

---

## Testing plan (constitution tiers)

- **G1 decided (preliminary)**: tiers 1, 2 and 3 all apply.
- **Tier 1**: `separate_mirror.py` / `test_separate.py`: flat patches of each ink, each overprint pair, the paper colour and a grey ramp; the round trip for in-gamut and out-of-gamut colours (random palettes included); bounds; degenerate palettes (ink equal to paper, zero-channel ink, collinear inks); one-ink monotonicity; Nearest mode; non-finite zap. Run `tests/run.sh -q tests/modules/separate`.
- **Tier 2**: `bench_separate.py` runs the real codebox against the mirror; first item is the per-pixel cost at 1080p. `bench_separate_module.py` covers bypass on both outlets, the live colour change, and the colour-control route. Read `skills/bench-test-authoring` before writing either.
- **Contracts**: register in `tests/contracts/test_module_contracts.py` and `bench_modules.py` (two outlets, `BYPASS_EXPECT`).
- **Tier 3 (Matt)**: a photo with two and three chosen inks; compare the preview with his prepress app's; a bent use (three unrelated colours, a narrow palette).

## Risks

- **The model may not match the prepress app's preview** (it is Claude's choice): the alternative model and the Nearest mode are the fallbacks; Matt's tier-3 comparison decides.
- **The swatch route is unverified**: twelve dials are the fallback, at the cost of panel density (`G-ui-density`).
- **Linear-light (G7)**: the density model is defined on reflectance; applying it to encoded values may shift mid-tones. Deferred by Matt; revisit at tier 3 and add a switch if the look needs it.
- **Collinear palettes** make the solve unstable; the ridge and tests cover it, tuned live.
- **Contract with `f_paper`**: this plan fixes a model its spec has not seen.

## Phasing (details in tasks.md)

- **Phase 0**: gates, the mirror, the colour-control route.
- **Phase 1**: codebox (Unmix first, then Nearest and gains), `definition.py`, patcher, benches.
- **Phase 2**: tuning with Matt against the prepress app.
- **Phase 3**: reference doc, helpfile, menu, README.
