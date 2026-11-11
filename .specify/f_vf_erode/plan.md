# Implementation Plan: f_vf_erode (formerly f_ink; renamed 2026-11-10, T077)

**Date**: 2026-11-10 (rewritten for the erosion model; the 2026-11-08/09 plan is at `git show 31f0c6f:.specify/f_vf_erode/plan.md`)
**Spec**: .specify/f_vf_erode/spec.md (every gate T060-T071 is confirmed by Matt, 2026-11-10; the spec has no PRELIMINARY assumption left except what this plan adds, below)

Everything about the solver's internals below is Claude's design, worked out offline from reading `f_vf_lbm` and `f_vf_ch` (their docs and `definition.py` headers) and not yet run. It is **inferred** until the mirror (T073) and the bench confirm it.

---

## Summary

A feedback module on the library's state-loop pattern (`f_vf_lbm`, `f_vf_fluid`, `f_ks`): a `hold` stage breaks the loop, and the solver state is one float32 texture, an atlas of RGBA planes at the render size. Per frame, one solver step in two stages: water moves through shared faces, then pigment is carried, lifted and dropped. A wetting loads the picture; an output stage composites the pigment over the background per Polarity. Water, suspension and paper layers are seven channels, so two planes. Verification follows the constitution: a NumPy mirror of the three layers (T073), each stage's real codebox on the bench against it, then Matt's live looks.

---

## Technical Context

- **Runtime**: Max 9, `jit.gl.pix`, GenExpr codeboxes, `@type float32` end to end (spec FR-110).
- **Archetype**: processor, in0 the `driving_inlet`. in1 terrain, in2 vecfield, in3 background (T062), each optional, through `mod_inlets` with `vs_inState` connected flags (`src_terrain`, `src_field`, `src_bg`), never recognised by value (FR-109). Four inputs is the codebox bench's limit, so no stage reads more than four.
- **Chain, stage by stage**: a `pix_chain` (`build/spec.md`), tested per stage; the constitution says whole chains are not covered by the bench.
- **Build**: `src/f_vf_erode/definition.py` → `build/build_patcher.py` → `package/patchers/f_vf_erode.maxpat`; the `src/f_vf_erode/codebox_*.gen` files of the 2026-11-09 build (`zap`, `blur`, `fx_a`, `fx_b`, `dir`, bulge, extent) are replaced; they stay in git.
- **Limits** (`skills/jit-gen-codebox/SKILL.md`): about 250 statements per function and 450 per program; about 16 reads per stage; no `noise()` on this path; a data-dependent `sample()` coordinate can jump to nearest, so every tap is an explicit texel index read with `nearest`.
- **Precedent used**: the atlas and `hold` of `f_vf_lbm` (one texture, so one hot inlet per stage and no multi-outlet ordering; its first three-texture version produced noise live), the frame-gate and `r draw` wiring of `f_vf_lbm`/`f_ks`.

## Constitution Check

✅ Codebox-first; the patcher is a thin wrapper.
✅ Numbers before eyes: conservation, bowl, field centroid, stillness and stability each have a closed form or invariant (spec SC-101 to SC-105), so tiers 1 and 2 precede the live look.
✅ One concern: ink pooling; paper, plates, screens and line work are other modules.
✅ Specs before building: this plan follows the confirmed spec.
⚠️ Cost (NF-102): the atlas at 1080p is 1920 x 2160 float32 with two or more stages per step; unmeasured. It decides whether render size holds (T065, Matt's call).
⚠️ Panel density (`G-ui-density`): nine dials; the layout is a gate, not decided here.

---

## Project Structure

```
src/f_vf_erode/
  definition.py            # source of truth (FR-114)
  codebox_hold.gen         # loop break, identity, triggered by the frame gate
  codebox_load.gen         # wetting: picture -> paper pigment, water flood; else passes the state
  codebox_flow.gen         # water through the faces (terrain, push, edge)
  codebox_pigment.gen      # suspension carried and mixed; lift and settle with the paper layer; dry
  codebox_enc.gen          # composite per Polarity, thickness, bypass gate, alpha
tests/modules/vf_erode/
  vf_erode_mirror.py            # float32 NumPy mirror, stage for stage (T073)
  test_vf_erode.py              # tier 1, SC-101..SC-105
  bench_vf_erode.py             # tier 2, each stage's codebox vs the mirror
  bench_vf_erode_module.py      # shipped patcher: flags, identity, bypass
```

The 2026-11-09 tests and codeboxes are removed in the build commit, not before.

---

## Architecture Decisions

### ADR-1: One state atlas at the render size (spec FR-101, FR-111)

**Decision**: seven channels in two RGBA planes stacked vertically in one `@type float32` texture of W x 2H, W x H the render size (`render_dim`). Plane A: water depth `w` in R, suspension `s` RGB in the rest would need four channels, so: A = (w, s_r, s_g, s_b); B = (p_r, p_g, p_b, spare). The spare channel is a "wash loaded" flag (see ADR-5).
**Why**: the `f_vf_lbm` finding, one texture and a single hot inlet per stage.
**Fallback (Matt's call, T065)**: a fixed solver grid, only if the 1080p bench cost rules render size out; outlets still follow the render size (FR-111).
**Rejected**: separate textures per layer (undocumented outlet firing order; noise live in `f_vf_lbm`'s first version).

### ADR-2: Stages (one solver step per `r draw`)

```
r draw -> hold -> load -> flow -> pigment -> (pigment -> hold: feedback, one-frame latency)
                                     pigment -> enc -> out0, out1
in0 -> load (picture, hot? no: cold) ; in0 -> enc (alpha, bypass source)
in1 terrain -> flow ; in2 vecfield -> flow ; in3 background -> enc
```

- `hold`: identity; the loop break.
- `load`: on a wetting (a Param edge, `wet`, with a counter so a held press floods once per press), writes p = the picture as pigment (per Polarity and linear light, ADR-4), s = 0, w = flood depth; otherwise passes the state unchanged. Inlets: state (hot), picture, `src` flags.
- `flow`: updates w only (ADR-3). Inlets: state (hot), terrain, vecfield.
- `pigment`: transports s with the water just moved, then lift, settle, dry (ADR-3). Inlets: new state from `flow` (hot) and the previous flows it needs, see ADR-3.
- `enc`: render-size composite (ADR-4), thickness, `bypass_gate`, alpha from in0. Inlets: state, background, picture.
Every stage has at most three inlets, so the bench drives each directly (NF-103).

### ADR-3: Conservative face-flux update, gather form (FR-102 to FR-106, P7, P8)

**Decision**: each face between two neighboring texels carries a flux `F_face` computed from the same two cells' values by the same formula, so what leaves one cell arrives in the next. Per cell the codebox gathers its four faces (explicit indices) rather than scattering. Face velocity: `flow * -grad(terrain + w)` across the face plus `push * field` sampled at the face (spec FR-102). **No momentum of its own** (T067): the velocity is recomputed every step from the slope, so nothing coasts. Flux is limited to a fraction of the donor cell's depth (at most 1/4 each, so four outgoing faces cannot take more than the cell holds), which keeps depth non-negative and kills the checkerboard (NF-101). `dry` removes depth at a rate; `w` clamps to zero below an epsilon so a dried wash is exactly still (FR-106).
**Pigment**: the flux carries suspension from the donor, `s_face = F_face * s_donor / max(w_donor, eps)` per channel; the same face value is added to the receiver and subtracted from the donor. Mixing where water stands is a diffusion term through the same faces, scaled by the smaller of the two depths. Pigment is carried per channel and never mixed between channels (T064).
**Lift and settle** (cell-local, between `p` and `s`): `lift * speedmeasure * w` moves paper pigment into suspension, limited to what the paper holds; `settle * (1 - speedmeasure)` drops it, and all of `s` drops where `w` falls to zero. The speed measure is the cell's face-flux magnitude over the donor depth, clamped to 0..1 (inferred form; tuned live).
**Frame edge (T066)**: water and its pigment leave. The cell beyond the frame has the terrain continued linearly (odd reflection) and the edge cell's own depth for the slope, the field replicated, and depth 0 as a donor, so a terrain that slopes out drains, a flat sheet does not (the first version, depth 0 on the slope side, drained a flat sheet at the edge and broke US1.3), and nothing re-enters (mirror, T073). Conservation (SC-101) is then checked as **pigment in = pigment left in the frame + pigment that left through the edge**; the mirror counts the second term. (The spec says "closed edge"; the mirror gets a closed-edge switch, test only, so the closed-edge statement of SC-101 can be tested as written.)
**Why two stages**: `flow` and `pigment` each stay under the read and statement budgets; `pigment` needs the face fluxes `flow` computed. Re-deriving them in `pigment` from the old and new depth is the conservative option (one formula, evaluated twice); passing them in a third plane would add a second texture, which ADR-1 rules out (inferred; the mirror decides).
**Speed**: one step per frame. The `speed` dial sets the step size up to the stability limit; more steps per frame would unroll the stage pair, decided only after the cost measurement (NF-102).

### ADR-4: Polarity, linear light and the composite (T060, T068, T075)

**Decision**: the picture is converted to linear light on load. **Darker**: pigment = absorbance = `-log(max(lin, eps))`, composite = `bg * exp(-(p + s))` with `bg` white when in3 is unconnected. **Lighter**: pigment = the linear color, composite = `bg + p + s` with `bg` black when unconnected. The result is converted back to display encoding in `enc`. One solver for both: only `load` and `enc` read Polarity. A switch takes effect at the next wetting; the stored layers are in the old units until then (spec Edge Cases).
**Thickness (T069)**: outlet 1 is pigment on the paper only, as luma of absorbance (Darker) or luma of the pigment (Lighter); no water outlet.
**Identity**: a wetted, flat-terrain, no-field wash returns the input, within the round-trip of log, exp and the transfer curve in float32 (SC-104). The tolerance is stated in the mirror, not assumed to be exact (inferred).

### ADR-5: Before the first wetting (T076, confirmed by Matt 2026-11-10)

The spec says an unwetted picture with in3 unconnected comes out equal to the input (US3.4) but leaves open what an unwetted frame is: `enc` has no paper layer yet. **Proposal**: the spare channel of plane B is a "wash loaded" flag; until the first wetting `enc` outputs in0 composited as if loaded (the picture over the background by the same formula), so the unwetted output is the input; after the first wetting `enc` reads the layers and in0 no longer reaches them (T074).
**Consequence**: a moving in0 is visible until the first wetting and held after it.

### ADR-6: Bypass, units, render size

**Decision**: `bypass_gate` Param in `enc` (never native `@bypass`), source passthrough, the loop keeps running (FR-113). Every length and rate is in frame heights, converted to texels at the render size; x is scaled by the aspect for any slope or push (FR-111). Non-finite input texels are zapped in `load` and in `flow`'s reads (FR-110).

---

### Amendment 2026-11-10 (T080, as built offline; inferred until the bench)

Stages as written in `src/f_vf_erode/definition.py`: `hold -> load -> transport -> react -> hold`, plus `prep -> transport, react`, `react -> enc`. `prep` (new) holds the static face velocities and the static lift drive; `transport` is ADR-3's flow and pigment transport fused; `react` is lift and settle. The load flag is 2 * loaded + the wet gate as last seen (ADR-5). `render_dim` has a new `atlas_stages` key (W x 2H). See `tasks.md` T080 and T081.

---

## Testing plan (constitution tiers)

- **Tier 1** (T073, `vf_erode_mirror.py`, `test_vf_erode.py`, float32, stage for stage): SC-101 conservation (closed-edge switch, and the open-edge count); SC-102 bowl (rim down, bottom up); SC-103 constant field moves the centroid, push 0 equals no field; SC-104 dried wash is still, flat terrain with no field returns the input; SC-105 stability at the extremes of every dial, no negative layer, no non-finite value. Plus Polarity: Darker and Lighter identity at an unconnected background; thickness zero where there is no pigment. The mirror reads `scratch/experiments/f_ink_look/vecfield_mock.py` (local) for the form of the push, not its constants.
- **Tier 2**: `bench_vf_erode.py` runs each real codebox against the mirror; the first bench task is the 1080p cost of the atlas stages (NF-102), recorded as measured or unmeasured. Read `skills/bench-test-authoring` before writing either bench file, as the repo requires. `bench_vf_erode_module.py` checks the shipped patcher: connected flags, wetting, bypass.
- **Contracts**: add the module to `tests/contracts/test_module_contracts.py` and `bench_modules.py`.
- **Tier 3 (Matt)**: SC-107, his test frame and a stroke-like source with a real terrain and a real vecfield (for example from `f_vf_fluid`); one deliberately bent use; dial ranges and defaults. Panel layout (`G-ui-density`) and menu category (`G-menu`) are decided then, not here.

## Risks

- **Cost** of the 2H atlas at 1080p (NF-102): the fallback is a fixed grid, Matt's call.
- **Re-deriving the fluxes in `pigment`** may not reproduce `flow`'s limited fluxes exactly (conservation off by rounding): the mirror's conservation test finds it; the fallback is one fused stage if the statement budget allows (inferred, 250 statements).
- **Stability at high `push`** with a strong field at the frame edge (spec Edge Cases): the flux limit is the guard; SC-105 tests it.
- **Lift and settle forms** (the speed measure) are inferred; the bowl and field tests check direction, only the live look checks whether it reads as ink.
- **Repeat wetting before dry** (spec Edge Cases): `load` overwrites the paper layer and adds to the water; whether the old suspension is kept or dropped is a build-time choice, to record.
- **Linear-light round trip** costs precision near black under Darker (log of a small value): the `eps` is set in the mirror.

## Phasing (details in tasks.md)

- **Phase 0**: mirror and tier 1 (T073), then the 1080p cost probe on the bench.
- **Phase 1**: stage codeboxes and benches in order: `flow`, `pigment`, `load`, `enc`; then `definition.py`, patcher, module bench, contracts.
- **Phase 2**: tuning with Matt (dials, ranges, defaults, SC-107).
- **Phase 3**: reference doc, helpfile, menu placement, README row.
