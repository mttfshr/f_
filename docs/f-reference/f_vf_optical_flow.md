# f_vf_optical_flow

**Type:** Processor (f_vecfield generator, from source texture motion)
**Status:** Functional, with known honest limitations (see Notes)

---

## What it does

Real Lucas-Kanade optical flow: estimates per-pixel motion `(u,v)` between consecutive frames of a source texture, output as a standard f_vecfield. Unlike the cheaper frame-difference approximation this replaced, it's a genuine local least-squares solve over a small spatial window, with a real confidence signal and a spatial fill stage that addresses the classic aperture-problem failure mode rather than just documenting it.

Two outlets: the vecfield `(u,v)` and a confidence/diagnostic signal (raw determinant of the local solve, plus the locally-ambiguous flow axis, packed together — see Outlets below).

Compatible with any f_vf_ consumer: `f_vf_warp`, `f_vf_advect`, `f_vf_prism`, `f_vf_glow`, `f_vf_streak`.

---

## Signal Flow

```
in0 (source texture) → Stage A (gradients: Ix, Iy, It via central difference + 1-frame feedback)
                          ↓
                     Stage B_h, Stage B_v (5-tap separable windowed sums: Sxx, Syy, Sxy, Sxt, Syt)
                          ↓
                     Stage C (closed-form 2x2 solve + confidence + ambiguous-axis signal)
                          ↓
                     Stage E (confidence-gated directional fill along the ambiguous axis)
                          ↓
                     Stage D (temporal accumulation: decay/injection, 1-frame feedback)
                          ↓
out0 (vecfield)  ← Stage D's accumulated field
out1 (confidence) ← Stage C's raw determinant + axis signal (unaffected by E/D)
```

Spatial fill (Stage E) happens **before** temporal accumulation (Stage D), not after — so the accumulator works on an already-filled per-frame signal instead of repeatedly decaying/re-injecting from neutral in gap regions every frame.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `scale` | -0.05–0.05 | 0.004 | Central difference step size for Ix/Iy gradients (normalized UV). Negative inverts gradient axis. |
| `gain` | -10–10 | 1.0 | Output vecfield magnitude scale. Negative inverts flow direction. |
| `mask_lo` | 0–20 | 0.0 | Confidence-gate low threshold — det at or below this reads as no-flow (neutral). |
| `mask_hi` | 0–20 | 1.0 | Confidence-gate high threshold — det at or above this passes at full strength. det's real numeric range was never precisely measured; find it empirically while watching the preview. |
| `decay` | 0–1.5 | 0.9 | Per-frame persistence of the accumulated field (Stage D). Above 1.0 allows a self-reinforcing/excitable regime, same convention as `f_vf_advect`. |
| `injection` | 0–2 | 0.3 | How strongly each frame's fresh solve blends into the accumulated field. |
| `step` | -0.1–0.1 | 0.0015 | Stage B's 5-tap window spacing (normalized UV), both passes. Bipolar range lets negative values invert tap direction. |
| `reach` | 0–0.1 | 0.01 | Stage E's directional-fill tap spacing along the locally-ambiguous axis. Same naming/role as `f_vf_prism`'s Reach. |
| `mix` (`mix_pct`) | 0–100% | 100 | Stage E's dry/wet, independent of per-pixel confidence — dial the fill effect down or off entirely as a live performance control. |
| `bypass` | 0/1 | 0 | Outputs pass through neutral (out0) / zero confidence (out1). |

**Prefix:** `opticalflow` — **Object name:** `opticalflow_pix`

---

## Outlets in detail

**out0 (vecfield):** standard f_vecfield, `(u,v)` encoded 0.5-centered. Loads into any `f_vf_` consumer with no adapter.

**out1 (confidence + axis, packed):** `x` = raw determinant of the local 2x2 LK solve (unclamped, unmasked — independent of out0's own masking, so it reflects true per-pixel confidence even where out0 has already been gated to neutral). `y`/`z` = the locally-ambiguous flow axis, double-angle encoded (`cos2θ`, `sin2θ`) rather than a plain angle, specifically to avoid a wraparound discontinuity (an axis repeats every 180°, so a naive single-angle encoding would jump somewhere in frame and blend garbage under any consumer's own bilinear sampling). This outlet no longer previews as clean grayscale — `y`/`z` carry real directional information now, not a duplicate of `x`. Primarily consumed internally by Stage E; exposed as a real outlet for anyone building a custom consumer around it, not just as an internal implementation detail.

---

## The aperture problem, and how this module handles it

Any single-scale LK optical flow has a well-known failure mode: perfectly axis-aligned, single-orientation edge content (e.g. a waveform generator's stripes at exactly 0° or 90°) makes the local 2x2 solve **exactly** singular — not approximately, not due to noise. There's genuinely no 2D gradient information locally to solve for velocity along the edge. A 5° tilt away from perfectly axis-aligned already produces real, usable flow; the failure is specifically the zero-tilt case.

This module doesn't just document that limitation — it addresses it directly. Stage C derives the locally-ambiguous axis (the direction with the least gradient information, via a standard structure-tensor double-angle result) alongside the usual confidence determinant. Stage E then propagates flow from higher-confidence neighbors **along that axis** into low-confidence pixels — not an isotropic blur, since only the axis-aligned direction actually carries information a straight edge's own rigid motion could plausibly share (a straight edge's true velocity is constant along its own length, so a real answer may exist further along that same line; sampling perpendicular to it would just blend in unrelated content).

Confirmed directly against the exact failure case (a waveform generator at Angle=0°/90°): previously-flat vecfield now shows real, directionally-plausible flow.

---

## Notes

### Frame-edge handling
`sample()` always clamps at texture boundaries on this GPU path (boundmode arguments are silently ignored regardless of what's passed). Near any frame edge, one of Stage A's central-difference taps would otherwise collapse onto the center sample instead of a genuinely-offset one, producing a biased/asymmetric derivative in a band `scale` pixels wide from every border. Stage A now zeroes `Ix`/`Iy` explicitly within that margin — Stage B's windowed sums then naturally shrink toward zero wherever the window touches this zeroed border, so the existing `mask_lo`/`mask_hi` gate already treats it as "no data," with no separate masking mechanism needed. **Known remaining rough edge:** this currently produces a visibly blank/dead framing at the border rather than a graceful falloff — an honest "no data" result, but not yet a soft one. A `smoothstep`-based falloff (rather than the current hard cutoff) is the likely fix when revisited.

### Fast motion (untested)
Single-scale LK is expected to break down on large frame-to-frame displacement — this is the standard trigger for a pyramidal (multi-scale) upgrade, deliberately out of scope for this build. This has not yet been explicitly tested against genuinely fast real motion; treat it as an expected-but-unconfirmed limitation rather than a verified one.

### `det`'s real numeric range
Never precisely measured analytically — `mask_lo`/`mask_hi` are live dials specifically so the useful range can be found empirically per-scene rather than assumed from a hardcoded threshold.

### Confidence-gated masking exists because of real testing, not by original design
The initial build (per ADR-2) deliberately deferred masking — raw confidence signal only. Real-world testing showed why that wasn't enough: the determinant's divide-by-zero floor amplifies ordinary per-frame sensor noise into large erratic `(u,v)` values specifically where `det` is small but nonzero — worst exactly along real 1D edges (window blinds, silhouette outlines), the same aperture-problem geometry as the synthetic test case, just showing up as noise instead of a clean zero reading. `mask_lo`/`mask_hi` fixed this directly.

- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract

---

## Signal chain recipes

### Basic motion-reactive processing
- `f_vf_optical_flow` on live camera or played-back footage → `f_vf_advect` (temporal smoothing/momentum on top of Stage D's own accumulation) → `f_vf_prism` or `f_vf_glow` for the visible effect

### Confidence-aware compositing
- Use out1's `x` channel directly as a luma-style mask to composite the source only where real motion was detected with confidence, independent of what out0's own masking already did to the vecfield itself
