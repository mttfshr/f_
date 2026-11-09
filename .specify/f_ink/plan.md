# Implementation Plan: f_ink

**Date**: 2026-11-08
**Spec**: .specify/f_ink/spec.md

All gate decisions below are **preliminary**: Claude's recommendations, accepted in place on Matt's instruction (2026-11-08) so the plan can proceed. Matt has not confirmed them. Where a gate is a measurement, the plan says what to measure and what Claude assumes until then (marked inferred).

---

## Summary

A stateless processor built as a short chain of `jit.gl.pix` stages: two separable blur passes for spread, two more at the pool width for edge pooling, and one or two final stages for mottle, dropout, flecks, banding, channel gains and bypass. Every stage is per pixel and reads only `nearest` taps at texel centres. No feedback, no solver. The driver inlets (an amount texture, a spread-direction vecfield) are P2 and add one input and one stage. Verification follows the constitution: a NumPy mirror of every effect against closed forms, a bench of each stage's real codebox, then Matt's live looks.

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix` GPU path (GenExpr codebox). Type `@type float32` end to end (spec FR-010).
- **Archetype**: processor, in0 the `driving_inlet`; in1 and in2 optional, through `mod_inlets` with `vs_inState` connected flags (`src_amt`, `src_dir`), as `f_vf_glow` does for its radius mod texture. With in0 unconnected the output is black.
- **Multi-stage**: a `pix_chain` (`build/spec.md`), stages wired by `pix_wires`. The constitution says whole chains are not covered by the bench: **test stage by stage**.
- **Limits that shape the design** (`skills/jit-gen-codebox/SKILL.md`, `ideas/f_deflicker.md`, read this session, not re-run): about 250 statements per function body and about 450 per program; about 16 reads per stage (a 256-tap codebox breaks the translator); `noise()` outputs black in the GPU path, so use the sin hash; a bilinear tap on a texel corner returned ONE texel in one measurement, so nothing here depends on interpolation.
- **Precedent for a separable blur in this repo**: `f_tf_hatch`'s stroke-texture pre-filter is two stages, `pre_h` and `pre_v` (its reference doc, read 2026-11-08).
- **Build**: `src/f_ink/definition.py` → `build/build_patcher.py` → `package/patchers/f_ink.maxpat`; `src/f_ink/codebox_*.gen`.
- **Test harness**: the codebox bench passes up to four inputs; no stage here needs more than three.

---

## Constitution Check

✅ Codebox-first: all logic in `.gen` files; the patcher is a thin wrapper.
✅ Numbers before eyes (constraint 6): every effect has a closed form or an invariant (spec SC-001 to SC-007), so tiers 1 and 2 come before the live look.
✅ One bpatcher, one concern: ink body only; screens, colour, paper and plates are other modules.
✅ Specs before building: this plan follows the clarified spec.
⚠️ Panel density (`G-ui-density`): about 14 dials plus three channel gains; mitigated by grouping and by making flecks, banding, gains and drivers P2.
⚠️ Cost (spec NF-001): five or six stages at 1080p; unmeasured, mitigated by the stage-by-stage bench and a cap on `spread` set by measurement.

---

## Project Structure

```
src/f_ink/
  definition.py                 # source of truth (spec FR-015)
  codebox_blur.gen              # one separable pass (horizontal/vertical by a Param), used for spread and for pool
  codebox_fx_a.gen              # re-threshold (bias, soften), edge pooling
  codebox_fx_b.gen              # mottle, tooth/dropout, flecks, banding, gains, driver scale, bypass, zap
  codebox_dir.gen               # P2: directional spread along the in2 vecfield
tests/modules/ink/
  ink_mirror.py                 # float32 NumPy mirror, stage for stage
  test_ink.py                   # tier 1 (SC-001..SC-007)
  bench_ink.py                  # tier 2, each stage's real codebox vs the mirror
  bench_ink_module.py           # shipped patcher: flags, identity, bypass
package/patchers/f_ink.maxpat   # built
docs/f-reference/f_ink.md       # Phase 3
package/help/f_ink.maxhelp      # Phase 3
```

---

## Architecture Decisions

### ADR-1: Stateless, per channel, stages not a monolith (G1, spec FR-002)

**Decision**: every output channel depends only on the same channel of in0 (plus the driver and params). Stages in order (corrected 2026-11-09, eight): `zap`; `blur_h` → `blur_v` (spread); `thresh`; `pool_h` → `pool_v` (pool width, reading S); `pool`; `fx_b`.
**Rationale**: the effects' order is fixed (spec FR-008), and a blur cannot share a stage with anything that reads its result at other positions. Splitting `fx` in two keeps each codebox under the statement budget.
**Rejected**: a single codebox with a 2-D loop (over the tap and statement budget); a stateful accumulation (out of scope).

### ADR-2: Spread is two separable passes of nearest taps (G5, G4)

**Decision (preliminary)**: a 15-tap kernel per pass at the fixed offsets -7..7, one texel apart (Matt, 2026-11-08), with tent weights set by the radius and normalized (so the dial moves continuously and radius 0 is one tap), read by explicit texel index with `nearest` (never an interpolated tap), borders by index clamp (G7). The `spread` dial maps to a radius in frame heights up to a cap. **The reach is 7 texels** (the first plan allowed a stride of 2, which the mirror showed combs a 1-texel line at 1080); at 1080p that is about 0.0065 of a frame height, and above 1080p it is held at 7 texels, so it shrinks in frame heights (against FR-011, accepted with the cap). If Matt's looks want more reach, a second cascade of the same two passes doubles the reach (variances of Gaussian-like kernels add; inferred).
**Then**: `fx_a` re-thresholds the blur: `S = smoothstep(0.5 - soften/2 - bias, 0.5 + soften/2 - bias, B)` then `mix(B, S, snap * min(spread / 0.125, 1))` (Matt, 2026-11-08: `snap` keeps continuous tone at 0). At `spread` 0 the blur is one tap of weight 1, so the result is exactly the input (FR-003 in the spec).
**Alternatives rejected**: a downsample then upsample (needs interpolation, G4 unresolved); one 2-D pass (over the read budget).
**Consequence**: reach is limited by the cap, recorded as the spec's G5 answer once measured.

### ADR-3: Edge pooling from the pool-width blur (spec FR-007)

**Decision (preliminary; corrected 2026-11-08 by the mirror, see tasks.md Record)**: with `B_p` the blur of `S` at `pool_width` and `S` the spread result, `pooled = S + edge_pool * S * 2 * max(S - B_p, 0)`. The band term is 0 on any flat field and is 0.5 on a straight edge, so the rim peaks at twice S at amount 1; multiplying by `S` keeps it on the ink side. No ink is added where the input is 0. The first form, `4 * B_p * (1 - B_p)`, was 1 on a flat 0.5 field, against FR-007.
**Consequence**: the pool blur reads `S`, so it cannot reuse the spread blur. Stages are `zap`, blur, blur, threshold, blur, blur, pool, `fx_b` (eight since 2026-11-09). Non-finite input is zapped before the first blur, not in `fx_b`.

### ADR-4: Mottle, tooth, flecks, bands from the sin hash in frame-height units (G2, G3, G10)

**Decision (preliminary)**: coordinates are `(uv.x * aspect, uv.y)` so one unit is a frame height and features are square on any frame; patterns are fixed to the frame (Matt, Q3). Mottle is value noise on a lattice of size `mottle_scale` with three octaves (weights 1, 1/2, 1/4), smoothstep-interpolated, from `fract(sin(dot(p, (127.1, 311.7)) + seed) * 43758.5453)`. Mottle modulates the local gain `1 + mottle * (m - 0.5) * 2`, applied multiplicatively so a coverage of 0 stays 0 (spec FR-005). Tooth is one octave of the same hash at `tooth_scale`; dropout removes ink where `coverage < dropout * tooth`, so light tones drop first (spec FR-006). Flecks are sparse hash peaks, banding a sine of the coordinate along `band_angle`.
**Mean of mottle**: the gain is centred on 1 in the field, so the mean of the output stays near the input's (spec User Story 2, scenario 2; to be measured).
**Rejected**: `noise()` (black on this path); a texture-based noise (needs another input).

### ADR-5: Gains and drivers (spec Q4, Q5, FR-014, FR-016)

**Decision (preliminary)**: each effect amount is multiplied by `gain_c` for channel `c` and by the in1 driver's luma at the pixel (nearest read; the amount is 1 when in1 is unconnected, from the connected flag, not the value: the `vs_black` lesson in the `f_vf_stamp` spec). In P2, in2 (a vecfield, `f_vecfield_type.md`) sets a spread direction: a short directional blur along the field (the `f_vf_streak` idea, not read) replaces the H/V pair where the field's magnitude is nonzero, mixed by magnitude. The neutral field is detected by the connected flag.
**Rejected**: tagged textures (Matt, Q4).

### ADR-6: Bypass and identity (spec FR-003, FR-013)

**Decision**: bypass is the codebox `bypass_gate` Param in `fx_b` (never native `@bypass`), source passthrough; the earlier stages keep running. With every amount at 0, each stage's result equals its input exactly by construction (blend factors of 0, not a numerical near-zero), which is what SC-001 tests.

### ADR-7: Units and render size (G2)

**Decision (preliminary)**: every length in frame heights; the pix stages take the render size from `r dim` (the `render_dim` build key), as the existing modules do. Non-square frames: x is scaled by the aspect before any pattern is evaluated.

---

## Stage and wiring sketch

```
in0 -> zap -> blur_h -> blur_v -> thresh -> pool_h -> pool_v -> pool (left inlet) -> fx_b -> out0
         |                          +-------(S)----------------> pool (right inlet)    ^
         +----------------(source, for bypass and alpha)-------------------------------+ (right inlet)
in1 (vs_inState, src_amt) -> fx_b   (P2)
in2 (vs_inState, src_dir) -> dir stage ---------------> replaces blur_v result where field != 0   (P2)
r dim -> every stage (render size)
```

---

## Testing plan (constitution tiers)

- **G1 decided (preliminary)**: tiers 1, 2 and 3 all apply; nothing is skipped.
- **Tier 1**: `tests/modules/ink/ink_mirror.py` and `test_ink.py`: identity at zero; spread on a disc, a line and a gap (area, merge, thin, bias); mottle statistics (standard deviation monotone in the amount, correlation length against `mottle_scale`, zero where input is zero); dropout fraction monotone and light-first; edge-pool rim over interior; determinism and render-size scaling; channel gain independence; border behaviour; non-finite zap. Run `tests/run.sh -q`.
- **Tier 2**: `bench_ink.py` runs each stage's real codebox against the mirror; the first bench task is to measure `sample()` on this hardware (G4) and the cost of the blur stages (G5). `bench_ink_module.py` checks the shipped patcher (connected flags, identity, bypass). Read `skills/bench-test-authoring` before writing either, as the repo requires.
- **Contracts**: add the module to `tests/contracts/test_module_contracts.py` and `bench_modules.py` expectations.
- **Tier 3 (Matt)**: `f_stipple`, `f_tf_hatch` and `f_wave_field` or `f_ks` through f_ink; one deliberately bent use; the dial ranges and defaults.

## Risks

- **Spread cap too small** for the look wanted (stride limit): the cascade extension (ADR-2) is the answer; cost doubles.
- **Mottle looks like noise, not ink**: the octave weights, the scale and the way it enters (gain versus threshold) are tier-3 judgments; the field source can be swapped for a driver texture (P2).
- **Cost** of five or six stages at 1080p is unmeasured (spec NF-001).
- **Statement budget** in `fx_b` (mottle + tooth + flecks + banding + gains): the split into functions is the mitigation; the fallback is a third stage.
- **`sample()` inside functions and loops** (inferred risk from the library's earlier findings): the first bench checks it.
- **Linear-light (G9)** may change how spread reads on mid-tones: deferred by Matt; revisit at tier 3 and, if needed, add a switch.

## Phasing (details in tasks.md)

- **Phase 0**: gates and the NumPy mirror (closed forms, statistics).
- **Phase 1**: P1 build (blur stages, `fx_a`, `fx_b` with mottle and dropout), `definition.py`, patcher, benches; then P2 (flecks, banding, gains, drivers).
- **Phase 2**: tuning with Matt.
- **Phase 3**: reference doc, helpfile, menu placement, README row.
