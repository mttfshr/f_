# Implementation Plan: f_vf_stamp

**Date**: 2026-11-05
**Spec**: .specify/f_vf_stamp/spec.md

---

## Summary

A stateless vecfield-and-texture processor: one per-pixel `jit.gl.pix` stage with two inputs (the stamp texture, an optional vecfield) and two outputs (ink, impulse vecfield), plus a patcher-level gate and envelope that drive two Params. No solver, no feedback, no DFT. It is a smaller cousin of `f_wave_field`'s `enc` stage: the same inlet-state handling, the same render-size output, the same Strike button pattern.

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix` GPU path (GenExpr codebox).
- **Type**: `@type float32` (the impulse is a vecfield; the ink outlet follows G2).
- **Inlets**: 2 texture inlets, each through `vs_inState` for an unconnected fallback and a connected flag (`src_stamp`, `src_vec`); control messages on in0. The pix has three inputs (ADR-9).
- **Outlets**: 2 (ink, impulse).
- **Build**: `build/build_patcher.py` from `src/f_vf_stamp/definition.py`; the gate is the `gate_button` type (T020), the envelope `raw_boxes`.
- **Test harness**: the codebox bench now passes up to four inputs (extended 2026-11-04); the stamp stage needs two, so it fits as is.

---

## Architecture Decisions

### ADR-1: One stateless stage

**Decision**: a single codebox `stamp` computes coverage, ink and impulse from in0, in1 and Params. No feedback, no state texture.

**Rationale**: the module is a gated, shaped injector; everything that persists is downstream (`f_vf_advect`, `f_vf_fluid`). A pure function of its inputs is the cheapest thing to verify (tier 1 closed forms, tier 2 one stage against its mirror) and composes with any consumer.

**Alternatives rejected**: held slots (N params, array state, duplicates the persistence downstream); a latch at the press (needs a feedback buffer).

### ADR-2: The gate button (G4)

**Context**: `f_wave_field` T042 built the press as `raw_boxes` (a `panel` face, a `ubutton`, `[sel bang 1 0]`, two `[t b b]`, a draw counter with `[sel 2]`). A plain `button` reports no release; `live.text` in button mode sends only a bang; `textbutton` sends two identical bangs; `ubutton` is the one with exact outlets.

**Decided (Matt, 2026-11-05)**: extract the pattern into a `definition.py` schema UI type (a gate button naming its Param, message and release-draw count) and rebuild `f_wave_field` from it, checked by `drift -v f_wave_field` reproducing the same patcher. `f_vf_stamp` is the second user. This fits Matt's stated taste for general tools.


### ADR-3: Envelope per draw, in the patcher (G1)

**Decided (Matt, 2026-11-05: frames)**: `[r draw]` drives a one-pole `env += (gate - env) * k`, `k` = 1 for `attack` 0 else `1 - exp(-1/attack)` (and likewise `release`), `[expr]` or a small `[zl]` / `[pak]` chain, sent as `param env`. No `line`, no timer: the envelope is in frames, consistent with the library's one-model-step-per-draw rule (`f_wave_field` G3). A tap then gives a short bump whose height depends on `attack`; with `attack` 0 the tap gives a full-strength stamp for its gate frames and the tail follows `release`. Below 0.001 `env` snaps to 0 (Claude, T022, for Matt's veto): a one-pole never reaches 0, and SC-002 wants the idle outputs exact. `[expr]` with comparisons, `[f]` holding the state.

**Not taken**: `line` in ms (simple, frame-rate dependent).

### ADR-4: Radial and swirl from the stamp's gradient (G3)

**Decided (Matt, 2026-11-05, on the T010 numbers; live look owed at T030)**: `v = -(cov(x+s,y) - cov(x-s,y), cov(x,y+s) - cov(x,y-s))` by integer texel index with periodic wrap (the `f_wave_field` outline-mask technique: neighbour texel index computed explicitly, read at its texel centre), `s = max(1, round(rim * width))` on both axes. Swirl is `(-v.y, v.x)`, counterclockwise in uv; on-screen direction against `f_vf_vortex`'s `curl` is unchecked. Four neighbour coverage reads plus the centre, no divide. Each component is within +-1, so `force` above 1 can clip a component in the encode.

**Rejected**: `-g / max(|g|, eps) * 4 * cov * (1 - cov)`, the first proposal: zero on a hard-edged stamp (`cov` is 0 or 1 at every texel centre), and at low `softness` on a soft stamp the projection keeps 0.43 of radial. Kept in the mirror as `field="unit"` for the record.

**Known leak (mirror, inferred for the live module)**: the spectral projection and this stencil disagree at high k, so about 10% of radial energy survives `project` at wider reach. Viscosity and `taps` are not modelled; T030 decides whether it shows.

### ADR-5: Coverage

`cov = smoothstep(max(threshold - softness/2, 0), threshold + softness/2, luma)`, `invert` as `1 - cov`. The clamp keeps black uncovered at the low default `threshold`: without it, `softness` 0.3 covers black at 0.26, lets a patched in1 through across the frame and cuts the rim to about 1.48 s (mirror).

**Cut (Matt, 2026-11-05, T006)**: the irregular edge (`edge`, `seed`, a noise offset on the threshold). On a hard-edged stamp it does nothing, because the noise cannot move a 0-to-1 step (T010); an irregular edge comes from upstream.

### ADR-6: Connected flags, not values

An unconnected in1 is `vs_black` (0), which would decode as -1 after the vecfield remap. The codebox uses the `src_vec` flag from `vs_inState` (as `f_wave_field`'s `src_force` / `src_lfo`) and suppresses the in1 path from the flag, not from the value. in0 has its own flag, `src_stamp`: an empty in0 is black, which `invert` would read as full coverage, so `cov` is forced to 0 without it (Matt, 2026-11-05).

### ADR-7: Periodic indices only

Every neighbour read uses explicit integer texel indices with a modulo wrap, never an out-of-range `sample()` (`G-edge-wrap`). Gradient steps are per texel in each axis so a non-square render target is handled.

### ADR-8: Bypass (G5)

**Decided (Matt, 2026-11-05: "pass the input through"; reading confirmed the same day)**: out0 passes in0, out1 passes in1 when connected, else neutral; the gate and envelope are ignored; the FR-011 non-finite zap stays active. Note the consequence: a bypassed stamp hands the whole texture downstream as ink. (The earlier proposal was neutral outputs, as `f_wave_field`.)

### ADR-9: Rendered by `r draw`, textures on cold inputs

**Decided (Matt, 2026-11-05)**: the `f_wave_field` `enc` pattern. `r draw` goes to the pix's first inlet (a trigger the codebox does not read); the stamp texture arrives on the second input through `inlet_fanout`, the vecfield on the third through `mod_inlets` `fanout`. The stage then renders once per draw whether or not anything is connected, which FR-001 needs.

**Rejected**: the texture on the first inlet, as `f_vf_glow`: with nothing on in0 the pix would never render (inferred from the builder's wiring), and adding `r draw` beside it would put two triggers on one inlet. Possible cost of the chosen way: one frame of lag from upstream, as in `f_wave_field`.

---

## Stage and wiring sketch

```
[r draw] -> stamp (first input, a trigger only)
in0 (vs_inState) -> stamp (second input)        in1 (vs_inState) -> stamp (third input)
gate_button -> PRESS / RELEASE -> draw counter -> stamp_gate -> envelope
[r draw] -> envelope one-pole -> param env -> stamp
stamp -> out0 (ink), out1 (impulse)       r dim -> stamp (render size)
```

---

## Testing plan (constitution tiers)

- **Tier 1**: NumPy mirror in `tests/modules/vf_stamp/`: coverage closed forms, idle exactness, linearity in `force` / envelope, mask zero, radial outward / swirl divergence-free and rotated 90 degrees, periodic wrap equivalence, hash noise range and determinism, non-finite zap.
- **Tier 2**: `tests/modules/vf_stamp/bench_vf_stamp.py` runs the real codebox against the mirror (two inputs); a module bench (`bench_vf_stamp_module.py`) for the patcher: connected flags, gate sequence (tap seen for at least two frames, a press cancels a pending release), bypass.
- **Contracts**: `tests/contracts/test_module_contracts.py` coverage for the new module (`#0_` scoping, bypass, outlets).
- **Tier 3 (Matt)**: stamp into `f_vf_advect` + `f_vf_fluid`; Radial versus Swirl at `project` 1; camera plus `f_vf_optical_flow` as the in0 / in1 pair; the dial set and ranges.

## Risks

- **Radial at `project` 1 stirs nothing in `f_vf_fluid`** (by the curl constraint): by design, with the swirl switch as the answer; the look test confirms or corrects this.
- **Rim width at high render sizes**: `s` grows with the render (about 29 texels at 1920), which costs nothing in taps but has not been looked at live.
- **Ink channel mismatch with `f_vf_advect`'s injection** (G2): read the consumer before fixing the encoding.
- **Dial count** against `G-ui-density`: ten controls plus the Stamp press (G6).
- **Schema extraction (ADR-2)** touches `f_wave_field`'s definition; `drift` is the guard.

## Phasing (details in tasks.md)

- **Phase 0**: gates G1-G8, the NumPy mirror, closed-form checks.
- **Phase 1**: codebox, `definition.py`, patcher with the gate and envelope; optionally the schema gate-button type first.
- **Phase 2**: tuning with Matt (dials, ranges, defaults, look).
- **Phase 3**: reference doc, helpfile, menu placement, README row.
