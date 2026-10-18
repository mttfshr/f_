# Spec: f_tf_glyph

_Created: 2026-10-17_
_Status: Draft_

_Promoted from `ideas/f_tf_triage.md` (Phase 1 verdict: **build as proposed, second overall**,
confirmed by Matt 2026-10-17) via `ideas/f_tf_build_brief.md` §4. Inputs cited, not re-derived:
`docs/f-reference/f_tensor_type.md` (the encoding contract) and
`docs/f-reference/f_tf_tensormap.md` (the producer). Prior art: `ideas/f_tf_expressive_consumers.md`
§"`f_tf_glyph`" and the glyph precedents it surveys (Kindlmann superquadric glyphs,
Delmarcelle/Hesselink hyperstreamlines, G'MIC `-structuretensors` + `-eigen` + `-display_tensors`);
the jit.fx audit `ideas/f_tf_jitfx_audit.md` (nothing ships anywhere near this).
Origin of the idea: `ideas/vector_field_math_concepts.md` §9._

---

## What it does

**The family's first tensor consumer and its universal debug view.** Renders one
closed-form glyph (ellipse by default; cross/tick as candidate variants — see Open
Questions) per grid cell over the source, oriented along the local structure axis,
with aspect ratio from the eigenvalue ratio and presence gated on trace. A field of
oriented marks that reads immediately as "this is where structure is, which way it
runs, and how anisotropic it is" — the visual answer to "what does the tensor
actually contain".

**Why this is tensor-native (the test from `f_tf_build_brief.md` §2):** the glyph
aspect comes from the eigenvalue *ratio* λ1/λ2 — collapsing the tensor to a vecfield
gives a line segment with no sense of "how anisotropic", and to a scalar gives a dot
with no orientation. Losing λ2 collapses the glyph to a line or dot: the second
eigenvalue is load-bearing, not decoration. This is the purest full-tensor consumer
in the catalog.

**Processor archetype, `driving_inlet`** (single driving texture; same call as
`f_vf_tensormap`'s spec), with the raw tensor as the primary input and the source
texture as a second input for tint/mask only. Not a generator; no self-generating
mode. Doubles as the debug tap for the whole family: chain A sidecars it off
tensormap (`f_tf_build_brief.md` §5), and every later renderer (sharpen, aniso_blur,
hatch) will be tuned while watching a glyph view of its own output.

**Per-consumer in-pixel decode — DECIDED (`f_tf_triage.md`, review 2026-10-17, Matt):**
no `f_tf_decode` module exists or will; the name is retired. This module decodes
tensormap **outlet 0** (raw tensor) in-pixel, exactly the way C74's only shipped
tensor consumer does: `jit.fx.cf.kuwahara` decodes eigenvalues, coherence and angle
in its main pass, every frame, from its own raw tensor data (`lambda1/2 = 0.5*(l0±l1)`,
`A = (l1−l2)/(l1+l2)`, `phi = −atan(t.y,t.x)` — three lines of closed form;
`ideas/f_tf_jitfx_audit.md` §2.1 and §4 finding 4). **This spec/plan records the
canonical decode idiom for the whole family**; sharpen, aniso_blur and hatch copy it
rather than re-derive it.

**One glyph per cell, coherent per glyph, not per pixel.** Each pixel looks up its
grid cell's center by a bounded neighbor search (the `f_vf_seeds` precedent,
`ideas/f_vf_seeds.md` §"Architecture": 3×3 neighborhood search gives the nearest
seed/cell; `ideas/f_vf_seeds.md` Q4) and reads the tensor *at the cell center*
(`ideas/f_vf_seeds.md`: sample the field at the seed position — stable, identity —
not at the current pixel; per-pixel orientation shears the mark). Result: each glyph
has one orientation, one aspect, one gate decision. **No loops anywhere in the glyph
draw itself** — the per-cell math is closed-form; the only iteration is the bounded
3×3 cell lookup, and even that reduces to arithmetic for a jitter-free grid (see
plan ADR-4).

---

## Field Architecture

```
// --- canonical decode idiom (family ADR; cited, not re-derived) ---
// encoding: docs/f-reference/f_tensor_type.md, outlet 0:
//   R = Jxx*strength (>=0), G = Jxy*strength*0.5 + 0.5, B = Jyy*strength (>=0), A = 1
// sample the raw tensor at the cell center, coords clamped to texel centers in-shader
t = sample(in_tensor, cell_uv)          // bench GPU wraps out-of-range reads (tensormap ADR-5)
Jxx = t.r / strength; Jxy = (t.g - 0.5) * 2.0 / strength; Jyy = t.b / strength
trace = Jxx + Jyy;  diff = Jxx - Jyy
root  = sqrt(diff*diff + 4.0*Jxy*Jxy)
lambda1 = 0.5 * (trace + root);  lambda2 = 0.5 * (trace - root)
theta = 0.5 * atan2(2.0*Jxy, diff)      // GRADIENT direction (across the edge); along the edge = theta + pi/2

// --- the useful invariant: the axis needs no strength knowledge ---
// aspect and rotation are computed from RATIOS of the decoded terms, and `strength`
// is a common factor on R, (G-0.5) and B, so it cancels:
//   tan(2*theta) = 2*Jxy/(Jxx-Jyy) = 2*(t.g-0.5) / (t.r - t.b)     (dimensionless, gain-free)
//   aspect        = lambda1/lambda2 = (trace+root)/(trace-root)    (gain-free)
// Only ABSOLUTE lambda values would need `strength`; this renderer does not use them.
// (Same reason coherence on outlet 1 needs no gain. f_tensor_type.md's decode rule
// still holds verbatim for any consumer that does want absolute lambdas.)

// --- draw gate ---
// visible only where the tensor means something: decoded trace above a threshold
// (isotropic/flat cells draw nothing, or their neutral circle — open question);
// this inherits tensormap's eps_trace convention (tensormap plan ADR-6), NOT a new one.

// --- glyph draw, closed form, per pixel ---
// local frame: rotate (p - cell_centre) by -(theta + pi/2) into (along, across)
//   aspect = clamp(sqrt(lambda1/lambda2), 1.0, max_aspect)   // sqrt because eigenvalues are intensity^2
//   ellipse SDF: d = length(vec2(along / a_len, across / (a_len / aspect))) - r_glyph
//   cover = smoothstep(softness, 0.0, abs(d))                // f_weave smoothstep convention
// cross/tick variants swap the ellipse distance for their own closed-form distance
// composite with the source tint where gated in
```

The ellipse is drawn in the glyph's own local frame (rotation carries the axis), so
the recovered θ only needs to be symmetric to θ+180° — which the angle-doubled
encoding guarantees by construction (`f_tensor_type.md` §"Why angle-doubled"). The
benign ±pi atan2 branch-cut difference (verified in `tests/records/spike_atan2_safety.py`,
cited in the tensormap spec) is invisible here for the same reason.

**Decode honesty note (from the brief's sign/branch-cut paragraph):** θ = 0.5·atan2
confines the axis to (−π/2, π/2], so a near-vertical axis flips sign in the *decoded
vector*. A glyph does not care — an unoriented line at θ and the line's θ+180° render
identically — but the idiom text above must carry the caveat so a later consumer that
is NOT axis-symmetric does not copy the idiom blindly.

**No auto-normalization.** Glyph size comes from the eigenvalues themselves
(gain-scaled) or from ratios (gain-free) — which of these drives the ellipse radius
is a plan decision (ADR-5), not guessed here.

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | texture (required) + control | — | **Raw tensor**, `f_tf_tensormap` outlet 0 exactly per `f_tensor_type.md`. The driving input. Anything else (outlet 1's packed encoding, a vecfield) is a wiring error and must be caught at the helpfile/contract level, not silently decoded. |
| 1 | texture (required) | — | Source texture (the same one tensormap consumed, or anything else) for cell-luma tint/mask of the glyphs. Optional visual input; its absence/neutral must not affect glyph geometry. |

Inlet order and the exact neutral for an unconnected inlet 1 are a plan-level call
(ADR-7); the spec only fixes that tensor and source are separate inputs because the
glyph's *geometry* reads the tensor while its *look* may read the source.

## Outlets

| Outlet | Content | Channels |
|---|---|---|
| 0 | Glyph composite over neutral, float32 | RGB = rendered glyphs (tinted per inlet 1), A = 1 |

`@type float32`. Stage outputs are unbounded internally; only the final stage clamps
(the family hard rule, tensormap plan ADR-4). Whether a second outlet (e.g. the
`f_vf_seeds`-style identity-coordinate texture — each pixel's cell center UV) is
worth exposing is an open question, not scoped by default.

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `grid` | live.dial | 2-256 (cells across) | 24 | Cell spacing — "the real control" (`f_tf_expressive_consumers.md`). Provisional; set by Phase 2 judgment, not guessed. |
| `scale` | live.dial | 0-2 | 0.8 | Glyph radius relative to the cell: 1.0 = glyphs touch. |
| `thickness` | live.dial | 0-1 (fraction of radius) | 0.15 | Stroke weight of the ellipse ring / cross arm width. |
| `softness` | live.dial | 0-1 | 0.1 | Edge falloff, per the f_weave convention (independent of thickness). |
| `gate` | live.dial | 0-1 | 0.05 | Trace threshold for drawing a glyph at all (pre-gain units; inherits the eps_trace discussion). Provisional. |
| `max_aspect` | live.dial | 1-32 | 8 | Clamp on the ellipse aspect so near-degenerate λ2 doesn't draw infinitely thin spikes. |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Neutral output. |

Every default above is provisional and gated by a Phase 0/2 task. **The glyph
variant (ellipse/cross/tick) is deliberately NOT a param promise** — it is an open
question (below). **Debug-view modes (axis-only tint, coherence tint) are also open
questions**, not shipping params: whether the debug role is a mode of this module or
a side product of wiring it to preview taps gets settled in the scratch-patch phase.

**Name:** `f_tf_glyph` (triage-confirmed; prefix `tf`, object name `glyph_pix` per
the `<prefix>_pix` convention).
**Type:** `@type float32` throughout.

## Signal Flow

```
in0 (tensor + control) -> routepass jit_gl_texture jit_matrix  -> glyph pix
in1 (source)           -> jit_gl_texture branch                -> glyph pix
unmatched control -> route <params> -> live.dials -> prepend param <name> -> glyph pix

glyph pix out0 -> outlet 0 (composite, @type float32)
```

Single-stage `pix` (or a trivially thin chain if the tint pass wants its own node —
plan decision ADR-6). Same routing skeleton as `f_tf_tensormap`.

## Acceptance Criteria

Numbers first, per the constitution's Verification Tiers. Tier gate recorded as the
first task of Phase 0 in tasks.md.

- **Decode ground truth:** on random symmetric 2×2 tensors the in-pixel decode's λ1,
  λ2 and θ match `np.linalg.eigh` (θ mod pi) to float32 tolerance; the gain-free
  identity (axis and aspect unchanged when `strength` changes by ×10) holds to
  ~1e-6 relative.
- **Known-angle ramp:** a linear ramp at known angle phi yields glyphs whose major
  axis is at phi + pi/2 (along the edge), matching NumPy `arctan2` to ~1e-6 rad.
- **Aspect correctness:** a synthetic field with eigenvalue ratio 4 gives measured
  ellipse aspect 4 (within tolerance) at `max_aspect` ≥ 4; a ratio above `max_aspect`
  clamps.
- **Line-field invariance:** rotating the input tensor by pi leaves the rendered
  field identical (every glyph is unoriented).
- **Isotropic cells:** a cell with λ1 ≈ λ2 draws aspect-1 (circle) or nothing, never
  an arbitrary angle — the θ-undefined region inherits tensormap's neutral rule.
- **Zero-tensor / gate:** cells below `gate` draw nothing; a fully zero tensor
  (vs_black inlet decodes to c2=s2=−1 per `f_tensor_type.md` §5 — the glyph inlet is
  outlet 0 where vs_black is the exact zero tensor neutral, but the gate must still
  hold) renders an empty field, no crash.
- **Grid invariants:** `grid` = frame-width cells makes one glyph per pixel row band
  behave as expected; cell centers land where the neighbor search says they do
  (checked against the mirror).
- **Bypass and unconnected inlets:** bypass outputs the neutral; unconnected tensor
  inlet renders empty (gated), unconnected source inlet renders untinted glyphs —
  no crash, no black frame.
- **Loads in Vsynth**, outlet renders in `vs_render`, drift-clean, contract tests
  green (the shipped-bpatcher contract).
- **Judgment tier (scratch patch):** glyph field on bfg Perlin/Voronoi/fbm reads
  structure direction and anisotropy correctly at a glance; `grid`/`scale`/`thickness`
  defaults feel usable; the field remains legible when fed through
  `f_tf_smooth`/`f_tf_sharpen` (the debug-role test). This is the live confirmation
  every provisional default above waits on.

## Out of Scope (v1)

- **Downstream chains** (`f_tf_sharpen`, `f_tf_aniso_blur`, `f_tf_hatch`, chain
  assembly). This module is the validator they decode from, not their builder.
- **Any producer work.** Tensormap and axisflow are built; no producer changes here.
  A hypothetical tensormap v2 "decoded outlet" is the documented fallback if
  per-consumer decode ever fails review (`f_tf_triage.md` §architecture) — not a
  task in this folder.
- **Glyph variant menu as a shipping param.** Ellipse is the v1 shape; cross/tick
  live in Open Question 1 until the scratch patch argues for them.
- **Debug-tint modes as shipping params** (axis-only hue, coherence tint) — Open
  Question 2.
- **Per-pixel glyph rendering** (each pixel its own ellipse from its own tensor
  sample). That is a different (denser, shear-prone) look; the cell model is the
  design, per the f_vf_seeds precedent.
- **Identity-coordinate outlet, mod inlets, temporal anything.** Stateless
  per-frame; mod-density questions inherit the paused `mod_depth_ui_density.md` blocker.
- **Anthropic API anywhere** (standing family constraint).

## Open Questions

1. **Glyph variant menu: ellipse / cross / tick.** All three are closed-form shape
   swaps (`f_tf_expressive_consumers.md` lists them as "cheap shape-function swap"),
   but whether the menu earns a param on an already-dense family panel is a
   UI-density call (same paused question as `f_tf_authored`). Phase 2 decides:
   build all three in the scratch patch, ship what earns its dial. Triage
   recommendation to carry: default v1 ships ellipse only unless Matt wants the menu.
2. **Debug-view modes (axis-only tint, coherence tint) — mode of this module, or
   not at all?** The module doubles as the family debug tool (brief §4, chain A
   sidecar), but that role may be cheaper served by wiring this module's own output
   plus preview taps in a scratch patch than by adding modes here. Scratch-patch
   phase decides; nothing promised.
3. **Does the glyph radius come from absolute eigenvalues (gain-scaled, needs
   `strength` knowledge) or from the cell's own scale param with aspect-only from
   the ratio (gain-free)?** Architecturally the gain-free path is cleaner — the
   decode needs no `strength` echo param and can never disagree with tensormap's
   dial — but the absolute path makes glyph SIZE mean physical gradient energy.
   Plan ADR-5 decides with tier-2 evidence.
4. **Inlet-1 tints how?** Source luma, source color, or a modulation of glyph
   brightness only; and what exactly the neutral is when unconnected. Phase 0/2
   question, small.
5. **Cell lookup: exact-arithmetic cell index (jitter-free grid) vs 3×3 bounded
   neighbor search (jitter-tolerant).** f_vf_seeds carries the 3×3 precedent and a
   `jitter` param; this spec does not promise jitter. If jitter stays out of v1, the
   search collapses to a floor-divide and the "no loops" claim is total. Plan ADR-4.
6. **Second (identity-UV) outlet?** f_vf_seeds ships one; its utility downstream is
   unproven for the tensor family. Default: no. Revisit if chain work wants it.

## Clarifications

- Q: Decode centrally or per-consumer? -> A: **Per-consumer, in-pixel** (triage
  review, 2026-10-17, Matt). Precedent: `jit.fx.cf.kuwahara`'s main pass decodes
  every frame from raw tensor data; a central module would be an adapter-hop for a
  three-line closed form (`f_tf_jitfx_audit.md` §4.4). This plan records the idiom.
- Q: Why outlet 0 (raw) and not outlet 1 (packed)? -> A: The glyph is a
  full-tensor consumer: it needs λ2 (aspect) and the axis, and the packed outlet's
  R/G are angle-doubled convenience values (cos2θ/sin2θ) whose decode is documented
  but whose B is clamp(trace·strength) — losing headroom the gate and aspect want.
  The raw outlet is lossless apart from the common `strength` gain, which the
  axis/aspect ratios cancel (`f_tensor_type.md`). Outlet 1 remains valid for
  axis-blind consumers.
- Q: Why a grid of glyphs rather than a continuous ellipse field? -> A: Legibility
  and the seeds precedent: one coherent orientation per mark reads as structure;
  per-pixel ellipses blur into a warped continuous field with no discrete reading.
  Also the literal ancestor: G'MIC renders exactly this (an ellipse per tensor cell)
  and the survey found it "cheap and legible"
  (`f_tf_expressive_consumers.md`, prior-art §).
- Q: First consumer — why glyph and not smooth? -> A: Build order is smooth →
  glyph (triage, confirmed): smooth stabilizes flicker BEFORE anything else renders,
  but glyph is the first *consumer* and carries this canonical decode idiom for
  every later plan. Smooth's own triad is authored in parallel (its decode idiom
  cross-references this one).