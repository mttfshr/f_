# Spec: f_tf_hatch (v2 — streamline renderer)

_Rewritten: 2026-10-28. v1 (lattice of oriented marks, branch T) is archived as
`spec_v1.md` / `plan_v1.md` / `tasks_v1.md` and in git at `a24b8cd`._
_Status: SPEC ONLY. No v2 code exists. The v1 codeboxes in `src/f_tf_hatch/` are still the
shipped (broken) v1 until Phase 1 of the plan replaces them._

## Why v2 exists (the reset)

The v1 live look (2026-10-28) showed two things:

1. **The look was wrong.** Marks were laid on a per-pixel lattice rotated by the local axis.
   `u = rot(norm, axis)` is anchored at the frame origin, so any smoothly varying axis
   field produced concentric rings centered on the origin (ring size set by `density`),
   and a noisy axis (camera) produced speckle. The rings were in every source and
   swamped everything else. A lattice of isolated marks cannot show continuity.
2. **The coherence question was never answered.** `coherence_gate` only dimmed the field
   (fixed in v1 by splitting shape from presence), but with the rings in the way nobody
   could see whether coherence-driven shape is worth having.

The reset, decided with Matt 2026-10-28: **`f_tf_hatch` exists to make a tensor field's
coherence and topology visible.** Orientation along structure alone is already available
to `f_vf_seeds` through `f_tf_axisflow` (tensor → vecfield); a renderer that only does that
adds nothing. What a tensor has and a vecfield does not is the *confidence* of the
direction (coherence), and the places where that confidence vanishes (degenerate points,
λ1 = λ2). The renderer's job is to show those.

## What it does

A per-pixel **streamline renderer** (line integral convolution, LIC) of procedural noise
along the decoded axis field of a raw tensor.

For each pixel: walk a bounded number of steps in both directions along the local axis,
accumulating a procedural noise value at each step. Result:

- **Coherent, smooth field → streaks.** Neighboring pixels on the same streamline share
  most of their samples, so the output is smeared along the line.
- **Incoherent field → grain.** Paths diverge or random-walk, neighbors share nothing.
- **Degenerate points (coherence → 0 inside a coherent region) → knots**, grain where the
  streaks converge, wedges and swirls around it. These are the topology.

Hatching is the *style* of the output: a contrast/threshold stage turns the smooth LIC
into engraved-looking lines. The topology comes from the field, not from mark design.

**Coherence is visible, not a dial.** There is no coherence-to-shape mapping (v1's
`commit`/aspect is gone: equating coherence with stroke length was a mistake, because
length encodes extent not confidence, and coherence saturates near 1 on any clean edge).
Coherence enters in exactly one place: **direction persistence**, how faithfully each step
follows the axis (see E2 and OQ1).

**Presence is separate** (carried from v1's 2026-10-28 fix): `structure_floor` blanks
pixels whose tensor trace is too weak to mean anything. It gates brightness only and
never changes the streak geometry.

Tone is out of v1/v2 scope (as before). Output is luma on black.

## What carries over from v1 (unchanged)

- In-pixel decode of `f_tf_tensormap` outlet 0 (raw tensor, packed Jxx/Jxy/Jyy over
  `strength`); `coherence = (λ1−λ2)/(λ1+λ2)`; axis from the eigen decomposition.
  Spec of record: `spec_v1.md` § E1; tensor contract: `docs/f-reference/f_tensor_type.md`.
- Presence formula: `pres = smoothstep(0.5·thr, 1.5·thr + 1e-6, enc_trace)·(1−iso)` with
  `thr = structure_floor²`. Same dial, same meaning.
- Statelessness; flicker is `f_tf_smooth`'s job upstream.
- Outlet-contract conventions (A=1, bypass = black on every outlet), registration
  (`REGISTRATION_NOTES.md`), name, menu entry, signal type.
- Verification tiers: tier 1 NumPy mirror, tier 2 GPU bench vs the mirror, tier 3 live.

## What is dropped

Branch T lattice, `density`/`weight`/`softness`/`elongation`/`phase`/`regularity`, mark
aspect, the cell/hash-grid mark layout, the hairpin hazard (OQ1 of v1: it was an artifact
of the lattice), ADR-1/ADR-9 of the v1 plan. v1's cost gate is replaced by a new one (below).

## Field Architecture

Three stages again, but the roles change.

### E1 — decode + presence (reused, output layout may change)

Decodes the tensor and writes an aux texture. v1 wrote `(cos a, sin a, commit, pres)`.
v2 needs: the axis, the coherence, and presence. **Open (OQ2):** store the axis as the
unsigned `(cos a, sin a)` (nearest reads only; interpolating it flips sign at the branch
cut) or as the doubled angle `(cos 2a, sin 2a)` (continuous, bilinear-safe; the march
recovers the half angle in closed form, no atan). `angle_offset` and `strength` stay E1's.

### E2 — streamline march (the new work; this is the cost gate subject)

Closed march, bounded loop (`N` steps per direction, N fixed at build time, `length`
scales the step size), one pass.

```
p = norm
acc = 0 ; wsum = 0
for each direction s in (+1, -1):
    d_prev = s * axis(p0)          # start direction
    p = p0
    for k in 1..N:
        a  = axis(p)                           # one tap into E1's aux
        a  = sign_align(a, d_prev)             # axis has no sign: flip to agree with d_prev
        a  = persist(a, coherence(p), hash)    # OQ1: coherence -> how faithfully we follow
        p += step * a ; d_prev = a
        acc  += w(k) * noise(p) ; wsum += w(k)
out = acc / wsum
```

- **Sign continuity** is the architectural problem the v1 plan flagged. The `sign_align`
  step (dot product against the previous direction, flip if negative) is the standard LIC
  answer and is what makes the march seam-free where the axis crosses the decode's wrap
  (along-axis angle 0/180°, i.e. horizontal; the decode returns angles in (0, 180]).
- **Noise** is procedural and stateless: a hash of the position at a `grain` scale
  (value noise, no extra inlet). It lives in *world* coordinates, never in the pixel's
  rotated frame, so it cannot produce origin-anchored rings.
- **Kernel** `w(k)`: box to start; a smooth falloff (e.g. cosine) is a later refinement.
- **Persistence (OQ1).** With an exactly isotropic tensor, `atan2(0,0)=0` hands the march
  a fixed (*vertical*) axis, so the incoherent region would render as clean vertical streaks,
  the opposite of what we want. So coherence must participate. Candidate: mix the axis
  with a hashed random unit vector per step, `d = normalize(coh·a + (1−coh)·r_k)`, so
  coherent regions march ballistically (long streaks) and incoherent ones random-walk
  (short correlation = grain). This is "scatter by coherence", not "stretch by coherence".
  The tier-1 test below (isotropic field must give grain) is the gate for the exact form.
- Taps: 1 per step (E1's aux, `nearest` or bilinear per OQ2) → about `2N` taps/pixel for
  `N` = 16 → ~33. Loop is bounded and weight-gated per the f_apollonian/ADR-4 precedent.

### E3 — style + compose + encode

Normalizes contrast (the average of `N` independent noise samples has `1/√N` the
variance, so the raw LIC is gray and needs stretching), applies the `line` style
(smooth LIC → hard engraved lines), multiplies by `pres`, clamps/encodes (the only clamp in
the module, plan ADR-4 of v1), bypass → black. Outlet 0 = styled output; outlet 1 = the
unstyled normalized streak field (luma) for downstream styling. **OQ4:** is outlet 1
worth keeping.

## Inlets

| # | Type | Description |
|---|------|-------------|
| 0 | texture (driving) | Raw tensor — `f_tf_tensormap` outlet 0 (or `f_tf_smooth` output). Same as v1. |

(No tone inlet; no mod inlet in v2.)

## Outlets

| # | Description |
|---|-------------|
| 0 | Streak render (luma on black, A=1), styled per `line` |
| 1 | Normalized streak field (luma, A=1), unstyled — see OQ4 |

## Parameters

All provisional until tier 3. Count target: ≤ 8.

| Name | Type | Range | Meaning |
|------|------|-------|---------|
| `length` | float | 0–1 | Total integration length (step size; `N` is fixed in the build). Longer = longer streaks |
| `grain` | float | 0–1 | Noise feature scale, log-mapped. Smaller = finer grain, thinner streaks |
| `contrast` | float | 0–1 | Normalization gain on the raw LIC |
| `line` | float | 0–1 | 0 = smooth LIC, 1 = hard engraved lines (threshold with a soft edge) |
| `structure_floor` | float | 0–1 | Presence floor, carried from v1 (default 0.1 provisional) |
| `strength` | float | 0–1 | Tensor decode calibration, carried from v1 (match tensormap's) |
| `angle_offset` | float | −1–1 | Rotates the streak direction relative to the structure axis (v1's offset) |
| `bypass` | toggle | — | Black on both outlets |

Whether coherence persistence needs its own dial (`persist`) is OQ1.

## Cost gate (replaces v1's cost-shape gate)

The march is the one expensive thing: ~`2N` taps/pixel in one pass, loop depth 1.
Measured pass floor for a simple pass at 1080p on M3 Max is ~0.8 ms (re-measure of
2026-10-28, chain-divisor fixed); v1's lattice stages each ran under that. **Provisional
budget: whole module ≤ 5 ms at 1080p (M3 Max), ≤ N=16 per direction.** Decided by a
GPU cost spike *before* any production codebox (plan Phase 0). If the budget fails the
fallbacks are lower `N`, half-resolution march, or a two-pass march (E2a/E2b).

## Acceptance Criteria

The new centre of gravity is **tier-1 tests on synthetic tensor fields with known
coherence**; the module is only worth building if these pass in the mirror.

Tier 1 (NumPy mirror), each on a synthetic encoded-tensor field:

1. **Coherent straight field** (all axes horizontal, coherence 1): streaks horizontal.
   Autocorrelation length along the axis ≥ K× that across it.
2. **Isotropic field** (equal eigenvalues, coherence 0, trace above floor): output is
   *grain*; autocorrelation approximately isotropic (ratio ≈ 1). This is the
   `atan2(0,0)` trap and the gate for OQ1.
3. **Coherence ramp** (axes fixed, coherence 0 → 1 across the frame): streak
   (autocorrelation) length along the axis rises **monotonically** with coherence. The
   direct "coherence is readable" test.
4. **Streaks follow the field** (the v1 regression): the local streak direction matches
   the field's axis on concentric rings, on a sweep that is not rings, and on a
   low-frequency random angle field. (The first draft of this test measured large-scale
   modulation about the origin; that proved to be a bad statistic, since correct streaks
   on a ring field ARE rings and constant fields have the same slow power. Ridge-vs-axis
   error is the direct measure of what v1 got wrong.)
5. **Branch cut**: a field whose axis sweeps through the decode's wrap (along-axis angle
   0/180°, where the unsigned pair flips sign; horizontal, not vertical) shows no seam;
   streak length straddling the cut stays within 80% of away from it.
6. **Degenerate point** (a wedge or center singularity): grain at the point, streaks
   around it.
7. **Presence**: `structure_floor` blanks the weak-trace region without changing the
   streak geometry elsewhere.
8. Neutral (zero) tensor → black. Bypass → black, A=1.

Tier 2: bench diff of E1/E2/E3 against the mirror (`bench_tf_hatch.py`, rewritten).
Tier 3 (Matt, live): looks like streamlines, coherence readable on the camera and on wfg
stripes, degenerate points visible, flicker acceptable under `f_tf_smooth`.

## Out of Scope

Tone / cross-hatch layering, color, multi-layer engraving, animated flow (phase), true
stroke identity (a seed-based path). All were v1 ideas; none are needed to show coherence.
Any of them may return in a later version once the streamline field is trusted.

## Open Questions

- **OQ1 — How does coherence enter the march?** **PROVISIONALLY DECIDED (Phase 0,
  2026-10-28):** direction mixing, `d = normalize(w·a + (1−w)·r_k)` with `w = coherence^0.5`
  and `r_k` a per-pixel/per-step hashed unit vector. Tests 2 and 3 pass in the mirror
  (isotropic field: L_x/L_y = 1.04; coherence ramp: streak length 2.6 → 4.6 → 7.3 → 11.1 →
  16.0 → 14.3 px over six strips, mean of six noise seeds, rank correlation 0.94). The
  exponent matters: 1.0 stays flat until coherence ~0.5 (2.3 / 2.8 / 2.9 / 6.3 / 11.4 /
  13.3 px); 0.5 grades across the whole range. No `persist` dial until tier 3 says so.
  Still open for tier 3: whether real tensormap coherence (mostly 0.1–0.7 on natural
  content) reads well at 0.5.
- **OQ2 — Aux layout:** doubled-angle with bilinear, unsigned with bilinear, and unsigned
  with `nearest` are statistically identical on the branch-cut test (streak length near/away
  1.38 in all three: the unsigned pair's sign flip only affects a ~1 px band, a single march
  step). So the choice is cost and visual quality: **leaning `unsigned_nearest`** (one tap per
  step, no sqrt); confirm on the GPU cost spike and in stills (the axis read is texel-quantized).
- **OQ3 — Kernel and N:** box vs cosine falloff; `N` = 8 / 16 / 32. Decided by cost
  spike and look.
- **OQ4 — Outlet 1:** the unstyled streak field is plausible, but is it used? Cheap to
  keep; confirm at the helpfile.
- **OQ5 — Fallback if the whole approach fails the look:** seeds with a per-seed tensor
  read (`f_vf_seeds` `axis_mode`), see `plan.md` § Out of this plan.
