# Spec: f_tf_hatch

_Created: 2026-10-17_
_Status: Draft — Phase 0 not started. The module's FIRST Phase-0 gate is the cost-shape
decision (Open Question 1, below); neither render branch is picked anywhere in this spec._

_Promoted from `ideas/f_tf_triage.md` (review outcome 2026-10-17, Matt: "build as proposed,
but its Phase 0 gate is the cost-shape question, not the shipped-look question"). Full
design lineage: `ideas/f_tf_expressive_consumers.md` §"Render / filter consumers" →
`f_tf_hatch` entry (performer touches, chains, failure modes, cost question).
Build order per triage: smooth → glyph → sharpen → aniso_blur → **hatch** → mix, so hatch
is the fifth triad in the confirmed sequence and inherits three shipped-or-specced
upstream modules. Platform audit: `ideas/f_tf_jitfx_audit.md` §2.4 (nothing ships:
no hatching, stipple, halftone, or engraving object in core Jitter or jit.fx —
`ge.lineinterp`/`ge.randlines` are line primitives from point data, not orientation-field
renderers) and §3 (hatch row: "Look is open ground"). Single-entry brief:
`ideas/f_tf_build_brief.md` (hatch = Open Question 1 in §6)._

---

## What it does

An orientation-committed hatching / engraving renderer. Discrete marks (short strokes)
are laid out across the frame, each oriented along the local structure axis decoded from
an incoming tensor — and, critically, each mark's *shape is committed per-pixel from the
eigenvalues*: where the eigengap is wide (a direction genuinely exists) the mark commits
to a line-like stroke along that direction; where the gap closes the same mark rounds off
toward a dot. One mechanism, continuous across the field: lines where structure is
line-like, dots where it is not, nothing where the gate says there is no structure at all.

**Discrete-item family member** — the fifth, after `f_grain`, `f_masonry`, `f_weave`,
`f_vf_seeds`. Mark geometry follows the family's conventions
(`docs/f-reference/discrete_item_conventions.md`,
`ideas/discrete_item_family.md`): hash-grid cell marks oriented along the decoded axis,
with `density` / `weight` / `softness` / `phase` / `regularity` carrying the family's
established meanings (see Parameters). Mark character is *internal* (smoothstep profile,
as in `f_weave`), not the external shape-tex-inlet architecture — hatching's whole point
is that mark shape is derived from field data, so the mark footprint cannot live upstream
without un-doing the tensor-native part.

**Processor archetype, `driving_inlet`.** Requires a tensor input; no self-generating
mode. Inlet 0 carries the tensor and all control messages combined.

**Per-consumer in-pixel eigen decode** (decided 2026-10-17, triage review item 3 — no
`f_tf_decode` module exists or will): hatch samples `f_tf_tensormap` **outlet 0** (raw
tensor, `docs/f-reference/f_tensor_type.md`) and decodes λ1/λ2 and the axis in-pixel,
closed-form, every frame — the same three lines C74's own `jit.fx.cf.kuwahara` runs
(`ideas/f_tf_jitfx_audit.md` §2.1). The canonical GenExpr decode idiom is recorded in
`.specify/f_tf_glyph/plan.md` (glyph is the first stage-E consumer per the triage
sequence); this module's plan **copies it verbatim** rather than re-deriving it.

---

## Tensor-native test (stated explicitly, per the brief)

The brief's test: *could this be done correctly by collapsing the tensor to a vecfield or
scalar first? If yes, it's a view, not tensor-native* (`ideas/f_tf_build_brief.md` §2).

Direction alone would be a view — `f_tf_axisflow` already supplies it to any vecfield
consumer. What makes hatch full-tensor
(`ideas/f_tf_expressive_consumers.md`, `f_tf_hatch` entry):

1. **Per-pixel commit.** Stroke density/spacing and mark *shape* vary with coherence and
   the eigengap: confident structure → clean parallel strokes; the gap closing → marks
   round off toward dots; below the gate → nothing. A vecfield carries neither λ2 (the
   gap) nor confidence; a scalar carries neither. The per-pixel commit is the
   tensor-native part of this module and its core acceptance surface.
2. **Stroke curvature follows the field.** Mark orientation tracks the axis pixel by
   pixel (and, on the stroke-marching branch, stroke layout follows it step by step),
   the way `f_tf_aniso_blur`'s spec treats curved contours.

**The glint lesson, applied deliberately.** The audit's view-in-disguise flag
(`f_tf_glint`: "a dial-width lobe is exactly what `f_lens` already offers"; build only
with per-pixel coherence width) is the reason the commit MUST be computed from the
eigenvalues per-pixel and never from a performer dial. A hatcher whose line-vs-dot
character is a slider is `f_weave` wearing a tensor costume. Performer dials here set
*response magnitude and thresholds* (gate, elongation response), never the shape data
itself (`ideas/f_tf_expressive_consumers.md`, glint entry: "legitimate as a
performer-facing response curve, not a substitute for per-pixel data").

---

## Field Architecture

Everything between the decode and the final encode is branch-independent. What the
Phase-0 gate decides is the **mark-layout mechanism** — the middle of the chain — and
this spec deliberately describes both candidates without picking one.

### Stage frame (both branches)

```
in0 (raw tensor texture + control)
  -> stage E1  eigen decode + commit  (closed-form, per-pixel, no loop)
  -> stage E2  mark layout            (THE COST-SHAPE GATE SUBJECT — branch T or S)
  -> stage E3  mark render + tone/compose, encode  (the only stage that clamps/encodes)
```

The stage split follows the constitution's codebox-before-patcher workflow and the
~450-statement program ceiling (`skills/jit-gen-codebox`: ~250 statements per function
body, ~450 whole-program). Whether E2/E3 split further is a Phase-1 decision against
that budget, exactly as `f_vf_seeds` split its Stage 1.

### E1 — decode + commit (branch-independent, fixed math)

Decode from `f_tensor_type.md` outlet 0 (`s` = the tensormap `strength` the producer
used; see the scale-invariance note):

```
Jxx = R / s;  Jxy = (G - 0.5) * 2 / s;  Jyy = B / s          // raw tensor back

t   = Jxx + Jyy                       // trace
d   = Jxx - Jyy
root  = sqrt(d*d + 4*Jxy*Jxy)
lam1  = 0.5 * (t + root)              // larger eigenvalue: gradient (across-edge) axis
lam2  = 0.5 * (t - root)
theta = 0.5 * atan2(2*Jxy, d)         // dominant GRADIENT direction (across the edge)
axis  = theta + 0.5*pi                // the ALONG-STRUCTURE direction: stroke axis

coherence = (lam1 - lam2) / t         // normalized eigengap, [0,1], guarded below eps_t
commit    = smoothstep(C_LO, C_HI, coherence)   // provisional curve; exact form is OQ3

// direction-undefined / zero-tensor guard (mirrors tensormap stage C / plan ADR-6):
// below eps_t on trace: commit = 0, axis unset -> no marks, never an arbitrary angle

ang_eff = axis + angle_offset * (pi/2)   // performer rotation of the pattern axis
```

**Scale invariance (why outlet 0, not outlet 1):** axis and coherence depend only on
eigenvalue *ratios*, so the producer's `strength` gain cancels — no strength compensation needed,
and the tensormap calibration table (`docs/f-reference/f_tf_tensormap.md`) does not
constrain hatch's look. Only the optional absolute trace floor (a "is there structure
at all" gate, OQ2) sits in strength-scaled units. The packed outlet 1 was rejected
because its angle-doubled R/G are exactly what `f_tensor_type.md` consumer rule 1
forbids feeding to anything that lays out geometry along a direction, and its B channel
is clamped (lossy) — outlet 0 is lossless.

**Commit curve properties (the tier-1 acceptance surface):** `commit` MUST be
continuous, monotone in the normalized eigengap, contrast-independent (inherited from
coherence, tensormap plan ADR-2), equal to 0 at/below `coherence_gate`, and → 1 while
`coherence → 1`. Mark shape interpolates continuously along it: full stroke at commit 1
(elongation response `elongation`), circular dot at commit 0. The exact curve shape —
direct normalized gap vs. an eigenvalue-ratio form, exponent, knee placement — is Open
Question 3, settled by the Phase-0 mirror (tier 1), not guessed here.

### E2 — mark layout: THE COST-SHAPE GATE SUBJECT

This is brief Open Question 1 / triage's hatch gate
(`ideas/f_tf_build_brief.md` §6; `ideas/f_tf_triage.md`: "stroke-marching vs
`f_weave`-style tileable distance-field pattern... decided by a NumPy spike + cost
estimate, not by this triage"). Both candidates, with their recorded observations —
**neither branch is picked in the docs**:

**Branch T — tileable distance-field pattern (f_weave-style).** Per-pixel closed form:
rotate the pixel into its local (axis, across) frame using E1's per-pixel axis, compute
`dist_to_line` and `dist_to_mark` from `fract`-based distance fields exactly as
`f_weave` does (`docs/f-reference/f_weave.md` Algorithm), with the hash-grid cell and
per-cell stagger from the family conventions. No loop, or a bounded handful of samples.
Recorded observations the gate will weigh:

- Cost class is proven: comparable single-pass stages on this bench run ≲0.9 ms at 1080p
  (upper bounds; `docs/f-reference/f_tf_tensormap.md` Cost). Fits the single-codebox
  shape and the statement budget trivially.
- The per-pixel frame *does* curve the pattern: each pixel's local axis follows the
  field, so iso-lines of the rotated coordinate bend with the structure.
- Known hazard: where the axis curves fast relative to `density`, the rotated
  `fract` field breaks/aliasing sets in — line continuity under hairpin curvature is
  the classic weakness of screen-space rotated line patterns [INFERENCE from the
  per-pixel-frame construction; must be checked in the spike, not argued].
- "Real strokes" character (a stroke that starts, travels, ends) is approximated, not
  marched — the family's `dist_to_mark` segmentation stands in for stroke identity.

**Branch S — stroke-marching.** Marks are genuine placements: march along the field
from seed cells, accumulating coverage — per-pixel bounded loop at best
(compile-time `MARCH_MAX`, live taps weight-gated per `f_tf_tensormap` plan ADR-3's
idiom), more likely multi-pass (seed pass + march pass) or point-sprite composition,
outside the single-codebox shape everything else in this family uses
(`ideas/f_tf_expressive_consumers.md`, hatch cost entry). Recorded observations:

- Statement budget is fine for one stage; the cost, pass count and feedback plumbing
  are the question. Same cost-scaling fact as tensormap `radius` applies: cost scales
  with `MARCH_MAX`, not with any dial.
- **The sign problem is architectural for this branch, not incidental:** the decoded
  axis is an *unoriented* line (`f_tensor_type.md` "Why angle-doubled"); a march needs
  a signed direction per step, and the decoded θ+90° from `0.5·atan2(...)` flips at the
  branch cut. Mitigations exist (symmetric two-sided march; step-by-step
  continuity-based sign choice, the same mechanism `f_tf_aniso_blur`'s curved-contour
  gate needs) but each adds exactly the complexity the cost gate is weighing.
- Buys: true stroke identity, tone-driven engraving layering (Praun-style), curvature
  fidelity of the Tschumperlé kind.

The Phase-0 gate task (T001 in tasks.md) runs a NumPy spike implementing both at small
scale on synthetic tensor fields, records measured/predicted per-pixel costs against the
bench's known per-pass bounds, and records the decision with reasons. The spike is NumPy
only — no bench, no codebox (tier 2 cost comes after the decision).

### E3 — mark render + tone/compose

Regardless of branch: per-mark footprint in the local frame, family profile
(`smoothstep(weight ± softness, ...)` shape per `f_weave`, softness = feather per
`discrete_item_conventions.md`), elongated along the local axis by the commit-driven
elongation, gated by tone, composed, and encoded. This is the only stage that clamps or
encodes; every internal texture stays unbounded float32 (Hard rule; tensormap plan
ADR-4). Any coordinate used to sample a texture is clamped in-shader to texel centres —
the bench GPU wraps out-of-range reads (found 2026-10-16, tensormap T012).

**Tone handling is Open Question 2, not committed:** an engraving hatch is tone-gated
(marks appear where the tone map asks for them: `ideas/f_tf_expressive_consumers.md`
hatch entry, "tone-gated by a brightness/tone-curve input"), but whether that arrives
as an optional inlet 1 (source/texture sampled for luma), or is deferred to a
density-layer scheme (cross-hatch layers per tone band), is a gate-adjacent decision
recorded in Phase 0, before E3 is designed. The tables below list inlet 1 as
**provisional pending OQ2**.

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | tensor texture (required) + control | — | `f_tf_tensormap` outlet 0 (raw tensor, `@type float32`, `f_tensor_type.md`). Per-pixel eigen decode (E1). Control messages route to params per `driving_inlet` convention. |
| 1 | texture (optional) | tone (PROVISIONAL — OQ2) | Engraving tone gate: luma of the sampled texture gates mark intensity. Not committed; if OQ2 rejects the inlet, hatch is not tone-gated in v1 and inlets stay single. |

vs_black fallback on inlet 0: the raw-tensor zeros decode to a true **zero tensor**
(unlike the packed outlet's unconnected case — the −1-axis hazard is outlet-1 only,
never fires on outlet-0 wiring; cross-confirmed with GlyphTriad/AnisoBlurTriad,
2026-10-17, `f_tensor_type.md` rule 5) → trace below eps_t → commit 0 → **no marks**.
The natural behavior is therefore safe without an in-state flag; the mirror still
asserts it (Acceptance Criteria).

---

## Outlets

| Outlet | Content | Notes |
|---|---|---|
| 0 | Hatch output — the composed mark field, final-stage clamped/encoded | Luminance marks on black, `@type float32`, color downstream's job (the `f_weave` convention, `docs/f-reference/f_weave.md`). If OQ2 keeps the tone inlet, tone modulates mark intensity here. |
| 1 | Mark mask — marks without tone/compose | Discrete-family convention (`docs/f-reference/discrete_item_conventions.md` shape-tex section; `f_vf_seeds` out1) for downstream compositing/gating. |

Whether a third auxiliary outlet carrying commit/axis (a hatch-side debug view pairing
with `f_tf_glyph`) is worth exposing is Open Question 5 — not committed.

No outlet is an `f_vecfield` and neither should be labeled as one (`f_tensor_type.md`).

---

## Parameters

Family names and semantics per `docs/f-reference/discrete_item_conventions.md` and
`docs/f-reference/f_vf_seeds.md`. **All ranges/defaults are provisional until the
Phase-0/Phase-2 gates lock them** (the tensormap precedent — its spec marked defaults
provisional until T023-T027 locked them live).

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `density` | live.dial | 0-1 | 0.5 | Line/cell spacing; log-mapped per family convention (`pow(2, density*log_span - 1)`; span chosen in Phase 0/2, weave uses 5). Applies whatever E2 branch produces spacing: line pitch (T) or seed-cell pitch (S). |
| `weight` | live.dial | 0-0.5 | 0.1 (provisional, weave default) | Mark thickness (across-axis extent). |
| `softness` | live.dial | 0-0.49 | 0.05 (provisional) | Edge feather, both axes, per the family formula (`discrete_item_conventions.md` `softness` section, weave's clamp to 0.49). |
| `elongation` | live.dial | 0-8 | 3 (provisional) | Response-magnitude dial: max along/across aspect of a mark at commit 1. NOT the shape data — shape data is per-pixel commit (glint lesson, above). commit 0 ⇒ aspect 1 (dot) regardless of this dial. Uses the family's squeeze-not-independent finding (`discrete_item_conventions.md` `size`+`stretch` section) rather than a `marklen` dial. |
| `coherence_gate` | live.dial | 0-1 | 0.25 (provisional) | Commit floor: coherence at/below this ⇒ commit 0. How far below 0 the module then falls back (dots persist vs. blank between gate and zero) is part of OQ3's curve decision. |
| `angle_offset` | live.dial | -1-1 | 0 | Rotates the pattern relative to the decoded axis: ±1 ⇒ ±90° (axis is unoriented, so ±90° spans all distinct layouts; the ±1 endpoints reach the across-structure orientation). Zero keeps strokes along structure. |
| `phase` | live.dial | -1-1 | 0 | Family-standard animation entry point: scrolls marks along the stroke axis (`discrete_item_conventions.md` `phase` section). |
| `regularity` | live.dial | 0-1 | 0.5 (provisional) | Per-cell/per-line hash stagger (`f_weave` mechanism: stable per-cell hash scaled by 1-regularity). |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Outputs the module neutral (black / no marks). |

**Name:** `f_tf_hatch`. **Prefix:** `hatch`. **Object name:** `hatch_pix`
(`f_tf_tensormap` → `tensormap_pix` convention). **Type:** `@type float32` throughout.

---

## Signal Flow (planned shape)

```
in0 (tensor + control) -> routepass jit_gl_texture jit_matrix
  jit_gl_texture branch -> vs_inState -> hatch_pix in0
  unmatched -> route <params> -> live.dials -> prepend param <name> -> hatch_pix in0

hatch_pix out0 -> outlet 0 (hatch output, @type float32)
hatch_pix out1 -> outlet 1 (mark mask, @type float32)
```

Same routing skeleton as `f_tf_tensormap`. Internal stage-to-stage wiring is the plan's
job (ADR set in plan.md against whichever branch E2 becomes); multi-stage param fan-out
follows the `f_vf_seeds` precedent for params reaching non-primary nodes.

---

## Upstream contract (Chain B / Chain D position)

Hatch is a *renderer*, placed at the end of the confirmed chains
(`ideas/f_tf_expressive_consumers.md` §Ranked chains):

- **Chain B ("Tensor engraving instrument"):** `f_tf_tensormap` ↔(mix)↔ `f_tf_authored`
  → `f_tf_mix` → `f_tf_smooth` → **hatch**.
- **Chain D ("Motion instrument"):** `f_vf_optical_flow` → `f_tf_motion` →
  `f_tf_smooth` → **hatch**.

`f_tf_smooth` upstream is **mandatory in practice**: hatching is the most
flicker-sensitive consumer in the family (a line present one frame and gone the next
reads as noise — `ideas/f_tf_expressive_consumers.md`, hatch failure modes). Hatch
itself stays **stateless** (no feedback pass inside the module); flicker mitigation
lives upstream, not here. During hatch's own tier-3 phase, the upstream must at minimum
be the already-built `f_tf_tensormap` (+ `f_tf_sharpen` when its triad lands); if
`f_tf_smooth` has not shipped by hatch's Phase 2, the scratch patch notes the
flicker caveat rather than building a smoother here.

---

## Verification Tiers & Phase-0 gates

Per the constitution (`​.specify/constitution.md` §Verification Tiers), which tiers
apply is a decision gate — but in this module the **cost-shape gate comes FIRST**
(before the tier gate), because its outcome changes what the tiers would even test: a
branch-S pick means a multi-pass/loop-heavy pipeline whose tier-2 story differs
fundamentally from branch-T's single-pass parity. Task order: T001 cost-shape gate
(spike + cost reasoning, OQ1) → T002 tier gate → tier-1 mirror (pattern math including
the commit curve) → tier-2 bench (real codeboxes, cost) → tier-3 scratch patch
(commit/density defaults on live chains).

---

## Acceptance Criteria

Numbers first. Tiers 1-2 verify these before any scratch patch
(constitution: "numbers before eyes").

- **Zero tensor ⇒ no marks:** unconnected inlet 0 / flat tensor (trace < eps_t) gives
  outlet 0 = black and outlet 1 = black, at every density/weight/softness setting. No
  invented axis anywhere (E1 guard, mirroring tensormap plan ADR-6).
- **Axis correctness:** a synthetic clean-edge tensor field whose gradient axis is at
  known angle φ produces stroke orientation φ + 90° (mod π) at `angle_offset` = 0; the
  mirror matches NumPy `arctan2`-decoded angle to ~1e-6 rad tolerance (the atan2-safety
  tolerance from `f_tf_tensormap`).
- **Commit endpoints:** coherence 1 ⇒ commit 1 ⇒ mark aspect = `elongation` + 1
  along-axis; coherence 0 (isotropic pixel, trace above eps_t) ⇒ commit 0 ⇒ mark aspect
  exactly 1 (circle/dot) regardless of `elongation`.
- **Commit monotonicity & continuity:** on a synthetic coherence sweep, commit is
  monotone non-decreasing; the field crosses the gate boundary with a continuous
  (no-seam) mark transition — checked numerically in tier 1 on an authored isotropic→
  anisotropic gradient field.
- **Contrast independence:** the same edge structure at gradient contrast 0.1 and 1.0
  yields identical commit and axis maps (coherence property; tier-1 invariant).
- **Rotation equivariance:** rotating the input's structure by 90° rotates the rendered
  stroke field by 90°; mirror-verified.
- **Family mechanics:** density log mapping matches the family formula exactly;
  `phase` scrolls marks along the decoded axis at fixed pattern; `regularity` = 1 is
  grid-phase-locked, `regularity` = 0 fully staggers (per-cell hash, stable across
  frames); all mirror-checked.
- **`angle_offset` = ±1** produces the exactly-rotated ±90° layout with no discontinuity
  in the pattern at the rotation (axis is unoriented — the doubled-angle decode must
  make the offset wrap cleanly).
- **`strength`-invariance:** multiplying the incoming tensor by any positive constant
  leaves the output unchanged (ratio invariance, E1) — tier-1 invariant.
- **Bypass** = neutral on both outlets; **unconnected inlet** = neutral, no crash, no
  stale frame.
- **Loads in Vsynth** and both outlets render in `vs_render` (shipped-bpatcher contract
  tests, per the tensormap lifecycle).
- **Judgement tier (scratch patch):** commit's line→dot rounding reads as intended on
  the smooth→sharpen→hatch chain (structure = strokes, noise/isotropic = dots or
  blank per the gate), and the provisional `density`/`coherence_gate`/`elongation`
  defaults are confirmed live or corrected in the spec — this is what the provisional
  defaults are waiting on.

---

## Out of Scope (v1)

- **Any cross-hatch second layer** (a second mark pass at an offset angle, the classic
  engraving tone mechanism). Belongs with the OQ2 tone decision, as a candidate v2 or an
  E3 variant — not committed here.
- **Temporal smoothing inside hatch.** `f_tf_smooth` owns it, upstream. Hatch is
  stateless by design (no feedback pass, cannot self-oscillate).
- **Color.** Luminance marks only; `f_channel_grader`/colorize downstream (weave
  convention).
- **`f_tf_mix`** (chain B's crossfade) — its own triad, spec'd when chain B assembles.
- **f_tf_glow anything** — merged into the parked Q12 `f_vf_glow` design per triage
  review (2026-10-17); hatch shares nothing with it.
- **Mod inlets** — none in v1; new mod depth controls run into the paused
  `ideas/mod_depth_ui_density.md` question (tensormap precedent).
- **A shared decode module** — per-consumer in-pixel decode, decided (triage review
  item 3); `f_tf_decode` as a name is retired.
- **Any Anthropic API call** anywhere in this module's tests or tooling (hard rule).

---

## Open Questions

1. **Cost shape: stroke-marching (S) vs tileable distance-field (T) — Phase-0 FIRST
   gate, T001.** Both branches described above with the recorded observations; decided
   by a NumPy spike + cost estimate (branch implementations at small scale, per-pixel
   cost vs known bench per-pass bounds), recorded as an ADR with reasons. **Neither
   branch is picked anywhere in these docs.**
2. **Tone gating mechanism.** Optional inlet 1 (source luma sampled for mark gating) vs
   density-driven engraving layers (tone → which density band draws) vs none in v1.
   Decided in Phase 0 before E3 design; the inlet table and E3 hold the provisional
   shape until then.
3. **Commit curve form.** Direct coherence smoothstep (C_LO/C_HI knees) vs an
   eigenvalue-ratio response with an exponent; whether `coherence_gate` and the knees
   collapse into one or two exposed dials; what the gate-floor fallback is (dots
   persist vs blank). Settled by the tier-1 mirror (the curve is cheap to sweep there),
   confirmed in tier 3.
4. **`angle_offset` endpoints and range.** Provisional ±1 → ±90°. Confirm the wrap and
   that ±90° is the useful limit for an unoriented axis field (a 180° offset is
   pattern-identical).
5. **Auxiliary outlets.** Outlets 0/1 per the family convention; whether a third
   (commit/axis debug, pairing with `f_tf_glyph`) earns its place or stays a scratch
   patch preview only (the `f_vf_split`-style tap, per `f_tensor_type.md` rule 3).
6. **Defaults.** All provisional values in Parameters are locked in Phase 2/3 gates
   (T-tier-3 judgement + Matt's call), with measured replacements recorded here, the
   tensormap way.
7. **M1 caveat.** All cost numbers in this triad are stated at the bench's measured
   floor (M3 Max unless noted); M1 is unmeasured per ways-of-working. Carry this into
   any Phase 0/2 cost claim.