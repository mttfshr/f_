# Implementation Plan: f_separate

**Date**: 2026-11-08
**Spec**: .specify/stable/f_separate/spec.md

Matt reviewed the P-list on 2026-11-08 (spec "Decided with Matt"): black background, additive overprint, coloured plates, four outlets. The remaining gate details below (ridge, solve, colour controls, linear-light) are Claude's preliminary recommendations. Derivations marked inferred are worked out, not run.

---

## Summary

A stateless, per-pixel processor in one `jit.gl.pix` stage with four outlets. It solves a small least-squares problem for the coverage of each of up to three ink colours (additive light on black), clamps to 0..1, and writes each coverage times its ink colour to its own plate outlet (0 to 2). Outlet 3 is the sum, a live preview. The colour controls are the open build question (spec G6).

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix` GPU path (GenExpr). `@type float32`.
- **Archetype**: processor, in0 the `driving_inlet`; one stage; four outlets (the build supports several outlets per stage: `f_vf_glow` has two; four is unverified). With in0 unconnected all outlets are black.
- **Limits** (`skills/jit-gen-codebox/SKILL.md`, read, not re-run): about 250 statements per function and about 450 per program. The solve below is a few dozen statements per pixel (inferred).
- **Colour controls**: a search of `src/f_vf_glow/definition.py` and `build/spec.md` (2026-11-08) found no colour-picker parameter type (`f_vf_glow`'s `color_mix` is a float dial). So colours are either three float dials each, or a raw `swatch` object per colour routed to Params. Unverified; spec G6, gate T009.
- **Build**: `src/f_separate/definition.py` → `build/build_patcher.py` → `package/patchers/f_separate.maxpat`.

---

## Constitution Check

✅ Codebox-first; one concern (colour into plates); the patcher is a thin wrapper.
✅ Numbers before eyes: reproduction of each ink, overprints, the paper, the round trip and degenerate palettes are all closed forms or invariants (spec SC-001 to SC-006), so tiers 1 and 2 come before the live look.
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

### ADR-1: Additive-light model (G2 closed; spec P2, P3)

**Decision (Matt, 2026-11-08)**: background is black, overprint is additive light. For ink colours `k_i` (RGB), coverages `c_i` in 0..1: the pixel colour is `K c` with `K` the 3×N matrix of ink colours. The unmix is the least-squares solution of `K c ≈ x`, clamped to 0..1. Linear, exact, order-independent.
**Rejected**: density (Beer-Lambert) model, undefined on black; coverage-weighted multiply, black on black; screen blend `1 - Π(1 - c_i k_i)` (never clips but no exact unmix; Matt chose add).
**Consequence**: `f_paper` (unspecced) inherits additive light: the sum of plates.

### ADR-2: Solve and constraint (G3, spec P1, P4)

**Decision (preliminary)**: `c = clamp((KᵀK + λ I)⁻¹ Kᵀ x, 0, 1)` with a small ridge `λ` (about 1e-4, tuned) for collinear palettes; `KᵀK` is N×N with N ≤ 3, inverted in closed form by cofactors. A non-negative constrained solve is the alternative if the clamp looks wrong near the gamut boundary (tier 3).
**Fewer inks** (`inks` 1 or 2): the same formula with `K` of N columns; unused plates are exactly black. With one ink the plate is the projection of the pixel onto that ink's colour.

### ADR-3: Degenerate cases (G4, spec FR-007)

**Decision (preliminary)**: a black ink has a zero column (ridge keeps the inverse finite, its plate comes out 0); duplicate or collinear inks are handled by the ridge; non-finite input is zapped to 0 first. No logarithms, so no epsilon.

### ADR-4: Four outlets (G5 closed; spec P5)

**Decision (Matt)**: outlets 0 to 2 are plates `gain_i * c_i * k_i` (RGB, ink-coloured), one per ink, black for unused inks; outlet 3 is the preview, the sum of the plates, clamped to 0..1. A single RGB channel cannot carry a spot colour such as teal, so plates are not packed into R, G and B. The gain-above-1 bound question (can a plate exceed its ink colour?) is open, with the gains (User Story 6).

### ADR-5: Nearest mode (spec P6, User Story 5)

**Decision (Matt: yes; details preliminary)**: squared RGB distance from the pixel to each ink and to black; the nearest wins; an ink winning gets coverage 1 and the others 0; black winning gives all 0.

### ADR-5b: Project mode (spec P12)

**Decision (Matt, 2026-11-08)**: a third `sep_mode`: each ink's coverage is its own projection, `clamp(gain_i * (k_i . x) / (k_i . k_i), 0, 1)`, with no matrix solve and no dependence on the other inks. The codebox adds three divisions (about six statements); the mirror adds a `project` mode and a `project_joint` mutation. A black ink gives 0 (the divisor floor is 1e-8).
**Why**: moving one swatch changed the other plates under Unmix, an inherent property of the joint least squares when inks overlap in colour (checked on the mirror: a plate moved by 0.18 to 0.25 with no or little clamping); Matt finds the independent rule easier to reason about.
**Cost**: no exact round trip for overlapping inks, bleed between inks that share colour. Unmix stays the default.

### ADR-6: Colour controls (G6)

**Decision (preliminary)**: Phase 0 first tries one `swatch` box per ink colour (three) in `raw_boxes`, outputs unpacked to the Params `ink1_r` … `ink3_b` (nine Params). The fallback is nine float dials grouped in rows. Unverified: the first build task proves the swatch route offline (JSON and route) and Matt confirms it in Max.
**Rejected**: hard-coding the palette in the codebox.

### ADR-7: Bypass, alpha, bounds (spec FR-009, FR-010, FR-012)

**Decision**: `bypass` is the codebox `bypass_gate` Param (never native `@bypass`); all four outlets pass the source through (Matt, P10). Alpha copied from the source on all outlets. Coverages and preview clamped to 0..1.

---

## Stage and wiring sketch

```
in0 (driving_inlet) -> separate -> out0..out2 (plates 1-3), out3 (preview)
swatch x3 -> unpack -> Params ink1_r .. ink3_b -> separate
inks / mode / gains / bypass -> Params -> separate
```

---

## Testing plan (constitution tiers)

- **G1 decided (preliminary)**: tiers 1, 2 and 3 all apply.
- **Tier 1**: `separate_mirror.py` / `test_separate.py`: flat patches of each ink, each overprint pair (sum), black and a grey ramp; the round trip for in-gamut and out-of-gamut colours (random palettes included); bounds; degenerate palettes (black ink, duplicate or collinear inks); one-ink monotonicity; Nearest mode; non-finite zap. Run `tests/run.sh -q tests/modules/separate`.
- **Tier 2**: `bench_separate.py` runs the real codebox against the mirror; first item is the per-pixel cost at 1080p. `bench_separate_module.py` covers bypass on both outlets, the live colour change, and the colour-control route. Read `skills/bench-test-authoring` before writing either.
- **Contracts**: register in `tests/contracts/test_module_contracts.py` and `bench_modules.py` (four outlets, `BYPASS_EXPECT`).
- **Tier 3 (Matt)**: a photo with two and three chosen inks; judge the preview and the plates on screen (no prepress comparison); a bent use (three unrelated colours, a narrow palette).

## Risks

- **Clipping:** inks that sum past 1 clip in the preview; the screen blend was offered and not chosen.
- **The swatch route is unverified**: twelve dials are the fallback, at the cost of panel density (`G-ui-density`).
- **Linear-light (G7)**: additive light is linear; applying it to encoded values may shift mid-tones. Deferred by Matt; revisit at tier 3 and add a switch if the look needs it.
- **Collinear palettes** make the solve unstable; the ridge and tests cover it, tuned live.
- **Contract with `f_paper`**: additive light, simple.

## Phasing (details in tasks.md)

- **Phase 0**: gates, the mirror, the colour-control route.
- **Phase 1**: codebox (Unmix first, then Nearest and gains), `definition.py`, patcher, benches.
- **Phase 2**: tuning with Matt, live.
- **Phase 3**: reference doc, helpfile, menu, README.
