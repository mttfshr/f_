# f_vf_prism — spec

_Written: 2026-06-20_
_Rewritten: 2026-07-11 — corrected against actual production module_

**Note on this rewrite**: the prior version of this file described an
architecture that no longer matches production — title said `f_vf_chroma`
(leftover from before this module forked off it), described a
non-accumulating 3-sample lookup with `length`/`width` params, and
claimed the composite was a crossfade. None of that is true of the
module as it ships today (`definition.py`, `codebox_v15.gen`). This
rewrite treats those two files, plus `continuity.md`'s version history,
as ground truth. `continuity.md` itself is stale by one version (documents
through v14; production is v15, which fixed a desaturation bug) but its
concept/origin narrative is still accurate and not repeated here.

## Concept

Prismatic spectral dispersion driven by a vecfield. Bright areas (above a
luma threshold) cast separated R/G/B color bands displaced along the
field direction — like light through a prism or crystal, wavelength-
dependent spatial separation rather than a blended rainbow tint. Forked
from `f_vf_chroma` on 2026-06-20 after a vortex-field experiment revealed
a distinct optical character (see `continuity.md` for the full origin
story).

Two distinct performance modes depending on field source (from
`continuity.md`, still accurate):
- **`f_vf_vortex`** — convergent streamlines give directional streak
  spectra, arms radiating from a center point
- **`f_vf_repulse`** — divergent field wraps spectrum around blob
  contours, giving annular/ring spectra

## Signal Chain

- **in1** — source texture (char)
- **in2** — f_vecfield (float32, RG=XY, 0.5=zero vector); vs_inState
  gated via `src_vecfield`
- **in3** — reach mod (`src_length_mod`)
- **in4** — spread mod (`src_width_mod`)
- **out1** — composite (prism layer added over source, scaled by
  `strength`)
- **out2** — isolated prism layer (`prism`; black on bypass)

## Core Mechanic

Each pixel asks, independently per channel: "is there a bright emitter at
*my* displaced position?" Three helper functions (`displaced_r/g/b`,
`channel_gate_r/g/b`) compute a per-channel sample position — the field
direction's perpendicular, rotated by `±spread_eff` per channel (`+` for
R, none for G, `-` for B) — then gate that sample by a luma threshold.
The gate values (not the raw luma) are then blurred with an 11-tap
symmetric Gaussian along the perpendicular axis, at a step size scaled to
the actual inter-channel separation (`feather * separation`, where
`separation` itself derives from `spread_eff` and field magnitude) —
this is what gives soft spectral edges without blurring the underlying
shape. Blurring gate values after thresholding, not luma before, is the
key correctness insight from the version history (v10–v12 got this
backwards and produced omnidirectional shape blur instead of directional
chromatic feathering).

```
per channel (R shown, G/B analogous with own rotation):
  displaced_uv = uv - (fx*cos_r - fy*sin_r, fx*sin_r + fy*cos_r) * reach_eff
  gate = smoothstep(threshold, threshold+threshold_width, sample(source, displaced_uv).r)
  // repeated at 11 taps along the perpendicular axis, Gaussian-weighted, summed
```

No hue synthesis — spectral color emerges purely from channel separation,
not a rainbow gradient painted on top (that's `f_vf_chroma`'s approach,
not this module's).

## Parameters

| Name              | Type     | Range    | Default | Label     | Notes |
|-------------------|----------|----------|---------|-----------|-------|
| `reach`           | float    | 0–0.3    | 0.05    | Reach     | Displacement distance along field |
| `spread`          | float    | 0–0.5    | 0.1     | Spread    | Angular separation between R/G/B channels |
| `threshold`       | float    | 0–1.0    | 0.7     | Threshold | Luma gate floor — keep high so only bright sources emit |
| `threshold_width` | float    | 0–0.5    | 0.1     | Gate Width| Softness of the luma gate edge |
| `feather`         | float    | 0–0.5    | 0.1     | Feather   | Inter-channel Gaussian blend width, scaled to separation |
| `gain`            | float    | 0–2.0    | 1.0     | Gain      | Renamed from `strength` 2026-07-12 to match the library-wide `gain`/`mix` naming convention (vsynth-bpatcher skill) — name only, no behavior change. Additive composite depth toward the 100%-effect state — **note the 2.0 ceiling is higher than most other additive-layer modules' 1.5** (`f_vf_glow`, `f_vf_streak`, `f_caustic`), not yet reconciled; confirmed correct as-is, not touched by the mix rollout below |
| `mix`             | float    | 0–100%   | 100     | Mix       | Added 2026-07-12 (dry/wet rollout). Live.numbox, internal `Param mix_pct`. Plain per-pixel linear blend toward the full `strength`-composited state — NOT spatial masking, NOT coverage/opacity. `mix=30` means every pixel is 30% of the way from source toward its own 100%-effect value. See "Composite Model" below and plan.md ADR 2 for the five-round history of what didn't work first. |
| `src_vecfield`    | internal | —        | 0.0     | —         | vs_inState gate; suppresses vs_black offset |
| `src_length_mod`  | internal | —        | 0.0     | —         | reach mod depth |
| `src_width_mod`   | internal | —        | 0.0     | —         | spread mod depth |
| `bypass`          | bypass   | —        | 0.0     | —         | out2 → black on bypass |

## Silent / Default Behavior

- **No vecfield connected**: `src_vecfield`=0 → field suppressed via
  `field_suppress`/`connected` gating → displacement collapses to zero →
  gates evaluate at the current pixel only → effectively no dispersion
- **`reach`=0 or `spread`=0**: dispersion collapses toward zero
  separation; `threshold` still gates which regions emit
- **bypass**: out1 = source, out2 = black

## Composite Model

**Updated 2026-07-12** (dry/wet rollout — see plan.md ADR 2 for the
five-round history of what was tried and rejected first; `strength`
renamed to `gain` later the same day to match the library-wide naming
convention, math unchanged). `gain`'s own composite is unchanged —
confirmed additive, not crossfade:

```
driven_r = clamp(src_r + prism_r * gain, 0.0, 1.0);
driven_g = clamp(src_g + prism_g * gain, 0.0, 1.0);
driven_b = clamp(src_b + prism_b * gain, 0.0, 1.0);
```

`mix` is a plain per-pixel linear blend *toward* that driven state — not
toward a bare effect layer, not spatial masking/coverage:

```
comp_r = mix(src_r, driven_r, mix_pct / 100.0);
comp_g = mix(src_g, driven_g, mix_pct / 100.0);
comp_b = mix(src_b, driven_b, mix_pct / 100.0);
out1 = mix(vec(comp_r, comp_g, comp_b, src_a), vec(src_r, src_g, src_b, src_a), bypass);
out2 = mix(vec(prism_r, prism_g, prism_b, 1.0), vec(0.0, 0.0, 0.0, 1.0), bypass);
```

**Open question, not resolved 2026-07-12**: `strength`'s own composite
is additive/screen (light added on top of source) — Matt's read is that
a prism's actual character (light passing through *becomes* separated
color) is closer to occlusion (effect locally replaces source, doesn't
visibly stack with it). See plan.md's "Open follow-up" for what
redefining this would need. Not blocking — `mix`/`strength` as shipped
is confirmed correct for what it does; this is a question about what
`strength`'s 100%-state itself should mean.

Same additive-layer shape as `f_vf_glow`/`f_vf_streak`/`f_caustic` —
those three should use the same `mix`-crossfades-toward-the-complete-
composited-state mechanism once picked up (not toward a bare effect
layer — see plan.md ADR 2 for why that specific distinction matters).

## Acceptance Criteria

- [x] `f_vf_vortex` into in2: fringing spirals around the vortex center
- [x] `f_vf_repulse` into in2: annular/ring spectra around blob contours
- [x] No vecfield connected: dispersion collapses, effectively clean
      source-gated-passthrough on out1
- [x] bypass: out1 = source, out2 = black
- [x] out2 is a valid isolated layer suitable for downstream compositing
- [x] Gate blur (feather) produces soft spectral edges without blurring
      underlying shape — confirmed by v14/v15 fix

(All checked — this describes shipped, working behavior as of v15, not
pending work. Retained as a record of what was verified, not a to-do
list.)

## What This Is Not

- Not hue-synthesized rainbow (that's `f_vf_chroma`)
- Not a streak/blur effect (that's `f_vf_streak`)
- Not a UV warp (that's `f_vf_warp`) — image content isn't displaced,
  only per-channel sampling positions diverge

---

## Reframe (2026-07-11): 3rd outlet — gate-weighted dispersion direction

### Correction to prior assumption

The original library-wide inventory (`ideas/dry_wet_gain_and_novel_field_outlet.md`,
finding 4) credited this module as the cleanest confirmed pass, reasoning
that each channel's own rotated perpendicular direction was novel. That's
true of the *geometry* but not sufficient on its own — the three
directions are a fixed rotation of the same input field (`R = rotate(f,
+spread_eff)`, `G = f`, `B = rotate(f, -spread_eff)`), so any unweighted
linear combination (equal-weight average, R−B difference, etc.) collapses
back to a scalar multiple of the original field direction — the
symmetric-rotation sine terms cancel exactly. That's not novel; it's
recoverable from the existing field and `spread` alone, no different in
kind from `f_vf_warp`'s fail case.

### What's actually novel

The per-channel post-blur gate weights (`gr`, `gg`, `gb` — sampled luma
at each channel's displaced position, thresholded, then Gaussian-blurred)
are independently, nonlinearly data-dependent. Two pixels with identical
field direction can have entirely different gate weights depending on
what's actually bright at each channel's displaced sample position. This
is genuinely new information the input field doesn't carry — it's a
product of this module's own luma-gated accumulation, not a property of
the field.

### Decision: gate-weighted combination

```
combined_x = gr*Rx + gg*Gx + gb*By   // (Rx, Gx, Bx are each channel's rotated unit direction * reach_eff-scaled magnitude)
combined_y = gr*Ry + gg*Gy + gb*By
```

When `gr = gg = gb` (uniform brightness, or `threshold` gating nothing
in/out differentially), this reduces to the same trivial scalar-multiple-
of-field case noted above — the addition doesn't manufacture novelty out
of nothing when there's genuinely none to find. But where gates disagree
— e.g. a bright source lights R's sample position but not B's — the
result leans toward whichever channel is actually gated "on" at that
pixel, encoding something like "which side of the dispersion is visually
active here." That only exists because of this module's luma-gated
accumulation; it's not derivable from the field or `spread` alone.

### New outlet

- Out 3: float32 f_vecfield — `combined_x, combined_y` as above, encoded
  RG float32, `0.5 = zero vector`. Magnitude will vary with how strongly
  gates agree/disagree and with `reach_eff`/`spread_eff` — not
  unit-normalized (parallel to `f_vf_vortex`'s case, finding 6 — worth
  checking at build time whether magnitude here also ends up redundant
  with something else, though there's no other existing outlet this
  module has that's vecfield-shaped to compare against, so that specific
  redundancy risk from finding 6 shouldn't apply here).
- No new param anticipated — reuses the existing per-channel gate/
  direction computation already present in the codebox for out1/out2.
- Bypass behavior: neutral vecfield (`0.5, 0.5`), consistent with
  `f_vf_flow`'s convention for vecfield-typed outlets (this isn't an
  additive color layer, so black-on-bypass doesn't apply the way it does
  for out2).

### Acceptance criteria (addition)

- Out3 differs visibly from a scaled copy of the input field — verify by
  comparing out3 against the raw input field routed through a gain-only
  module at matching magnitude; they should diverge wherever gate weights
  disagree across channels
- Out3 is near-neutral where `gr≈gg≈gb` (uniform brightness regions) and
  diverges in direction specifically at gate-disagreement boundaries
  (e.g. edges of bright/dark regions where one channel's sample position
  crosses the threshold before another's)
- No change to out1/out2 behavior — pure addition
- Bypass sets out3 to neutral, consistent with library convention for
  vecfield-typed outlets
