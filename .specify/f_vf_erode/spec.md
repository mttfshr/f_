# Spec: f_vf_erode (formerly f_ink; renamed 2026-11-10)

_Created: 2026-11-08. Rewritten 2026-11-10 (the erosion model); the 2026-11-08 and 2026-11-09 versions are in git (`git show 3bdf92a:.specify/f_vf_erode/spec.md`)._
_Updated 2026-11-10 (later): T060-T065, T074, T075 decided (Matt)._
_Status: specified, not built. The module in `src/f_vf_erode/` is still the 2026-11-09 build (Extent, Bulge, Travel), which this spec replaces._
_Origin: `ideas/f_print_styles.md` (stage 3 of the print-styles family, "ink body"). Name `f_vf_erode` is a placeholder (plain `f_`, no family prefix: Matt, 2026-11-07)._

---

## What it is

f_vf_erode treats the incoming picture as ink laid on a surface, wets it, and lets the water rearrange it. Ink pooling is erosion and deposition at small scale, the process of an alluvial plain (Matt, 2026-11-10): running water draws ink away from some places and drops it in others. Where ink is drawn away, more of the background and its texture show; where it collects, less. A Polarity control picks whether collected ink makes the picture darker or lighter (below).

There are three layers over a terrain:

- **Water**: runs downhill on the terrain, is steered by a vecfield, fills low ground, and dries.
- **Pigment in suspension**: carried by the water, and mixed where water stands.
- **Pigment on the paper**: what is seen. It starts as the incoming picture.

Fast water lifts pigment off the paper. Slow water, and water that dries up, drops it. The terrain decides where ink collects; the vecfield steers how it gets there.

## Decided with Matt

- **A vocabulary, not a goal** (2026-11-07): the behaviour is to be simulated and then bent; the same operator must be usable for results that look unmistakably digital. Authentic emulation is one use, not the measure of success. Screens and projection only.
- **Any texture in, texture out** (2026-11-08). No ink color or plate logic; RGB, alpha is not a plate.
- **Drivers from anywhere** (2026-11-08), each on a dedicated inlet, not a tagged texture (clarify Q4, `P-mod-textures`).
- **Unclamped float32 output** (2026-11-08, clarify Q2).
- **The model above** (2026-11-10): after four offline mocks, "this seems like a better direction"; the wet-once looks, dried and still running, "are looking good" (`.specify/f_vf_erode/tasks.md` Record; sheets `8_alluvial.png`, `9_vecfield.png`, local).
- **A feedback module** (2026-11-10): the earlier "stateless" assumption (A3) and "static first" are dropped. Ink that travels needs iteration.
- **Two outlets** (2026-11-10): the composite over the background, and the ink thickness as a scalar.
- **Pools are large** (2026-11-10): "larger areas with one or two clean edges"; ink runs together inside a pool, so not many small areas (the first mock "looks more like mottled texture"). Where ink is drawn away, the background shows "delineated with finer and lighter ink, not darker".
- **Areas come from the land** (2026-11-10): no stage that counts or labels strokes. An area is whatever drains to the same low place.
- **The terrain is an incoming texture** (2026-11-10), whatever it represents: paper grain, a landscape, or the picture itself.
- **The vecfield pushes** (2026-11-10, "I concur"): it is added to the downhill flow. With no terrain connected, the field alone drives the water.
- **Polarity is a control** (2026-11-10, T060): "we want to be able to choose here", "a control for whether it gets lighter or darker". The library has no layers concept, and background means no light, so in3 is the background, not an underlayer. How the two settings render is the next item (T075).
- **Polarity render** (2026-11-10, T075, "Confirm T075"): one solver for both settings; only the load and the composite differ. **Darker**: pigment is absorbance (the negative log of the color) and the composite is the background times exp(-pigment), so pooled ink is deeper and drawn-away ink is thinner and lighter; this is what the mocks did. The background is the light being filtered, so with in3 unconnected it is white. **Lighter**: pigment is the color itself, as light, and the composite is background plus pigment, so pooled ink is brighter and drawn-away ink fades toward the background; with in3 unconnected it is black (no light), as in `f_separate`. In both, an unwetted picture with in3 unconnected comes out as the input. Default: Darker. A switch takes effect at the next wetting.
- **Inlets** (2026-11-10, T062, "confirm all three"): in0 picture, in1 terrain (luma is height), in2 vecfield (`f_vecfield_type.md`), in3 background. Four inputs is the codebox bench's limit.
- **Nothing connected** (2026-11-10, T063): no terrain and no field, the water has nowhere to go, the wash dries in place, and the output is the picture. No background: white under Darker, black under Lighter (T075).
- **One water layer for three channels** (2026-11-10, T064): the channels share the water and the flow; pigment is carried per channel and never mixed between channels. This replaces the old A2.
- **Wet once** (2026-11-10, T061): a held press or trigger floods the frame, loads the current picture as the paper pigment, and the wash runs and dries ("sounds good"). Between wettings a moving in0 does nothing: the wash holds until the next wetting; always-wet is not in this version (T074, "Confirm T074").
- **Render size** (2026-11-10, T065): the layers run at the render size "if at all possible". A fixed solver grid is the fallback only if a measured cost rules render size out, and that call is Matt's. After the 1080p probe (6.3 ms upper bound for one step per frame, `tasks.md` Record) Matt kept render size (2026-11-10).
- **Remaining assumptions** (2026-11-10, T066-T071, "confirm all"): **Frame edge**: water and its pigment leave at the edge, no wall (P7). **Flow**: no momentum of its own; inertia comes through the vecfield (P8). **Linear light**: the frame is converted to linear light before the log, as in the mocks (P9, `G-linear-light`). **Thickness outlet**: pigment on the paper only, as luma of absorbance, no water outlet (P10). **Dials**: the set and names in the table below, ranges from tuning; panel under `G-ui-density`, menu under `G-menu` (P11). **Verification**: tier 1 NumPy mirror (conservation and closed-form cases), tier 2 bench against the mirror, tier 3 live (P12).

- **Before the first wetting** (2026-11-10, T076, "2> confirm"): until the first wetting the output shows the picture as if loaded, so an unwetted picture comes out as the input; after it, in0 no longer reaches the layers. A moving in0 is visible until the first press.

## Assumed by Claude, not yet confirmed

None left (2026-11-10). New assumptions made at build or mirror time are added here as PRELIMINARY.

## User Stories

### US1: Wet the picture and let it run (P1)

A performer patches a picture into in0 and a terrain into in1, and wets it. Pigment is stripped from the high ground, which goes pale; it collects in the low ground as a few large, even bodies with clean edges where the water stood. When the water is gone the result holds still.

**Independent test**: tier 1 on a bowl-shaped terrain under a flat tone.

1. **Given** a flat tone on a bowl, **when** the wash has dried, **then** pigment at the rim is lower than it started and pigment at the bottom is higher.
2. **Given** a wet-once run with a closed edge, **then** the pigment total, per channel, is the same before and after, within float tolerance.
3. **Given** a flat terrain and no field, **then** the dried output equals the input.
4. **Given** the wash has dried, **then** two successive frames are identical.

### US2: Steer the wash with a vecfield (P1)

The performer patches a vecfield into in2. The drainage leans along the field and the marks follow its direction, while pooling still happens in the terrain's low ground.

1. **Given** a bowl and a constant field, **then** the pooled pigment's centroid is displaced along the field, compared with no field.
2. **Given** push at 0, or no field connected, **then** the result equals the terrain-only result exactly. The unconnected inlet is recognised from the connected flag, not from its value.

### US3: Show what is underneath (P1)

The performer patches a background into in3. Where ink has been drawn away, the background and its texture show through thin ink; where ink has pooled, it is covered (Darker) or outshone (Lighter). Outlet 1 gives the thickness for use elsewhere.

1. **Given** a region with no pigment left, **then** the composite there equals the background, in both settings.
2. **Given** more pigment at a texel, **then** every channel of the composite there is no brighter under Darker and no darker under Lighter.
4. **Given** no wetting and in3 unconnected, **then** outlet 0 equals the input in both settings.
3. **Given** any state, **then** outlet 1 is zero where there is no pigment and rises with it.

### US4: Field only (P2)

With no terrain connected, the field alone moves the water: the picture runs along the field and no pools form unless the field converges. This is a run, not a pool (seen in the fourth mock; inferred from two stand-in fields).

### US5: Feed (Matt, 2026-11-10: "feed is great"; supersedes "later" in T074)

A continuous source, so the module follows an animated or live input. A `feed` dial (0 = wet once, exactly as before). While it is above 0, each step deposits a fraction `feed` of the shortfall between the incoming picture's pigment and the paper's, and the water relaxes toward `flood`. Pigment the solver has moved away is refilled where the picture holds more; where the picture holds less the old ink stays until it moves or dries. A still picture on a flat frame converges to itself (identity). The Wet button still works alongside it. Different from a frame delay: the memory is the water and pigment state, moved by terrain and vecfield, not an old copy of the image.

**Fade (2026-11-10, Matt's report: the frame went black):** a `fade` dial returns ink above what the picture holds toward the picture, only while feeding, so a driving texture that gets lighter is followed and the frame cannot saturate (FR-116).

**Decided by Claude, not Matt (reversible; Matt said only "feed is great")**: the deposit is bounded-additive (shortfall) rather than relax-toward-frame, and the water is relaxed toward `flood` rather than floored. Mirror: `feed()` in `tests/modules/vf_erode/vf_erode_mirror.py`; tier 1 `test_feed`.

### US6: Standard f_ module behaviour (P3)

`bypass`, `#0_`-scoped names, helpfile, menu entry, README row, per the library conventions.

## Requirements

### Functional

- **FR-101**: The module MUST keep three layers between frames: water depth, pigment in suspension (RGB), pigment on the paper (RGB).
- **FR-102**: Water MUST move between neighboring texels through shared faces, so that what leaves one arrives in the next. The face velocity is the downhill slope of terrain plus water depth, scaled by Flow, plus the vecfield scaled by Push.
- **FR-103**: Pigment in suspension MUST move with the water that carries it, taken from the cell the water leaves, and MUST mix between neighbors where water stands.
- **FR-104**: Pigment MUST be lifted from the paper at a rate that rises with the water's speed and depth, and MUST be dropped where the water is slow and wherever the water runs out.
- **FR-105**: With a closed edge and no re-inking, pigment MUST be conserved per channel. No layer may go negative.
- **FR-106**: Water MUST dry at a rate set by a dial; a dried wash MUST be still.
- **FR-115**: Feed (US5): with `feed` > 0 the load stage deposits as US5 says, every step, with no press. `feed` 0 MUST be exactly wet-once. A deposit MUST never lower the paper pigment, and MUST never take it above the picture's.
- **FR-116**: Fade (US5): with `feed` > 0, paper pigment above the picture's returns toward it at rate `fade`; with `feed` 0 it MUST do nothing. A fed run on an alternating picture MUST NOT exceed the darker picture's pigment.
- **FR-107**: Wet once (T061, T074). Wetting MUST load the current in0 picture as the pigment on the paper. Between wettings, changes at in0 MUST NOT reach the layers.
- **FR-108**: Outlet 0 MUST be the composite of the pigment (on the paper and in suspension) over the background, per the Polarity control (T075). Outlet 1 MUST be the thickness, per P10.
- **FR-109**: Inlets per T062. Each optional inlet MUST be recognised as unconnected from its connected flag (`vs_inState`), not from its value. Behaviour with inlets missing per T063.
- **FR-110**: Float32, unclamped, with no NaN or Inf reaching any outlet or any stored layer (non-finite input texels are zapped to 0).
- **FR-111**: Every length and rate MUST follow the render size (`render_dim`), and the module MUST be correct for non-square frames. The layers run at the render size (Matt, T065); if a measured cost forces a fixed solver grid (Matt's call), the outlets still follow the render size.
- **FR-112**: Frame edge per P7, by explicit index math.
- **FR-113**: Bypass MUST use a codebox `bypass_gate` Param (never native `@bypass`) and pass the source through; the layers keep running.
- **FR-114**: Standard behaviour: `#0_`-scoped names, `routepass` / `route` / `autopattr` with `varname`, `definition.py` as the source of truth.

### Non-functional

- **NF-101**: The update MUST be stable at every dial setting: no checkerboard in standing water and no growth without bound. (Both were seen in the mocks before the step and the depth were limited.)
- **NF-102** *(target, pending measurement)*: cost recorded at 1080p on the bench, stated as measured or unmeasured. This is the measurement that decides whether render size holds (FR-111).
- **NF-103**: Every stage MUST fit the codebox statement and read budgets (`skills/jit-gen-codebox/SKILL.md`).
- **NF-104**: Verification per P12.

## Parameters (provisional, P11; ranges come from tuning)

| Param | Notes |
|---|---|
| `polarity` | Darker or Lighter (decided, T060; name provisional) |
| `wet` | the wetting press or trigger (T061) |
| `flow` | how strongly water runs downhill on the terrain |
| `push` | how strongly the vecfield moves the water |
| `lift` | how readily running water takes pigment off the paper |
| `settle` | how readily slow water drops it |
| `dry` | how fast the water goes |
| `speed` | solver steps per frame |
| `bypass` | passthrough |

## Success Criteria

- **SC-101**: Conservation: pigment per channel unchanged over a wet-once run with a closed edge (tier 1 and tier 2).
- **SC-102**: Bowl: pigment falls at the rim and rises at the bottom (US1.1).
- **SC-103**: Field: the pooled centroid moves along a constant field (US2.1); push 0 equals no field (US2.2).
- **SC-104**: Stillness and identity: a dried wash does not change; flat terrain with no field returns the input (US1.3, US1.4).
- **SC-105**: Stability: no checkerboard and no non-finite value at the extremes of every dial.
- **SC-106**: The patcher matches the mirror on the bench within a stated tolerance.
- **SC-107**: Tier-3 look (Matt): on his test frame and on a stroke-like source, with a real terrain texture and a real vecfield, it reads as ink pooling: large pools with clean edges, drawn-away areas with the background showing. And one deliberately bent use reads as intentionally digital.

## Edge Cases

- Input values at or below 0 (the log), above 1, and non-finite.
- A flat terrain; a terrain with one enormous basin; terrain values outside 0..1.
- A field at full strength pointing at the frame edge; a field with no convergence.
- Wetting again before the wash has dried.
- Switching Polarity while the wash runs (decided, T075: it takes effect at the next wetting, because the stored pigment was loaded for one setting; switching the render alone would re-read absorbance as light).
- Render size changes at runtime; non-square frames.
- An inlet connected but flat (all 0 or all 1).
- Alpha: passes through from the source.

## Out of Scope (This Version)

- The terrain being changed by the flow (channels cut by erosion).
- Wicking into the paper, and pigments that settle at different rates.
- Counting or labeling strokes; a region-map inlet (Matt, 2026-11-10: only if areas from the land fall short).
- Spread, snap, bias, mottle, dropout, flecks, banding, channel gains, and Extent, Bulge, Travel (the 2026-11-08 and 2026-11-09 designs).
- Ink color, paper, overprint and plate logic (`f_paper`, `f_separate`); screens and line work (`f_screen`, `f_engrave`).
- Audio analysis: audio drives f_vf_erode only through an upstream texture.
