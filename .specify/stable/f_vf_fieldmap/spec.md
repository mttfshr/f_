# Spec: f_vf_fieldmap

_Created: 2026-06-07_
_Status: Built. Brought up to the shipped module 2026-11-06 (stable preflight); `strength` became `gain` on 2026-07-19, and the Clarifications below keep the old name as history._

---

## What it does

A scalar-to-vecfield converter. Takes any scalar texture input and derives a vector field from its spatial structure via central difference gradient computation. Outputs an f_vecfield-encoded float32 texture — RG encodes signed XY gradient direction, 0.5 = zero vector.

**Producer in the f_vecfield family.** Primary use case: patch `jit.gl.bfg` (Perlin, Voronoi, fractal noise) into inlet 0, get a coherent vector field out. Any scalar-dominant texture works — f_grain, f_stipple, luma from a video source, etc.

**Processor archetype — requires input.** No self-generating mode. With nothing connected there is no output: the pix runs only when a texture arrives.

**Single outlet — f_vecfield texture only.** The source texture is not re-output. Debug workflow: patch outlet 0 into vs_displacement or f_caustic.

---

## Field Architecture

Gradient computed via central difference at each pixel:

```
// sample luminance at 4 neighbors
// luma = 0.299*r + 0.587*g + 0.114*b (standard Rec. 601)
// suv = norm * (1 - 2h) + h, the inset that keeps neighbors in bounds for positive h
L_right  = luma(sample(in0, suv + vec(h, 0)))
L_left   = luma(sample(in0, suv - vec(h, 0)))
L_down   = luma(sample(in0, suv + vec(0, h)))
L_up     = luma(sample(in0, suv - vec(0, h)))

grad.x = (L_right - L_left) * gain
grad.y = (L_down  - L_up)   * gain
// grad is then rotated by `rotate` degrees

// encode to f_vecfield
R = clamp(grad.x * 0.5 + 0.5, 0.0, 1.0)
G = clamp(grad.y * 0.5 + 0.5, 0.0, 1.0)
B = 0.5
A = 1.0
// pixels with center luma <= thresh become neutral; bypass_gate mixes to neutral
```

**Why central difference:** symmetric around the sample point — gradient is centered at the pixel being computed, not offset by half a step. Correct zero-crossing behavior (flat regions produce exactly 0.5 output). 4 samples is minimal cost for this quality level.

**Why luminance:** input textures are expected to be effectively monochrome (jit.gl.bfg, f_grain, f_stipple all output grayscale-dominant content). Luminance composite handles the edge case where an RGB source is used without requiring a channel selector param.

**Scale `h` (`scale` param):** expressed in normalized UV coordinates. Default ~2 pixels at 480p (`2.0 / 480.0 ≈ 0.004`). Low scale emphasizes fine gradient structure; high scale smooths over fine detail and extracts coarse structure. This is an expressive parameter — high scale with a high-frequency noise input produces a smoother, lower-frequency field than the input itself.

**No auto-normalization:** gradient magnitude scales with input contrast and step size. The `gain` param is the user-facing calibration control. This avoids the multi-pass reduce operation that frame-level normalization would require.

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | texture (required) + control | — | Source scalar texture. Control messages route to params. |

Single inlet. No mod inlets in v1 — the patch is a converter, not a modulated generator. Expressiveness comes from the input source.

No `vs_inState` or `vs_black` fallback: unconnected means no output.

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `gain` | live.dial | -10–10 | 4.0 | Scales gradient magnitude into f_vecfield range. Default 4.0 puts typical jit.gl.bfg Perlin output into useful range. Negative inverts the field. |
| `scale` | live.dial | -0.05–0.05 | 0.004 | Central difference neighbor distance in normalized UV coords. ~2px at 480p. Low = fine structure; high = coarse/smooth. |
| `rotate` | live.dial | -180–180 | 0.0 | Rotates the field vector in degrees, after the gradient. |
| `thresh` | live.dial | -2–2 | 0.0 | Pixels with center luma at or below this become neutral. |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Drives the codebox Param `bypass_gate`: outputs neutral field (0.5, 0.5, 0.5, 1). Panel toggle only; no route selector. |

**Prefix:** `fieldmap`
**Object name:** `fieldmap_pix`
**Type:** `@type float32`

---

## Signal Flow

```
in0 (source texture + control) → routepass jit_gl_texture jit_matrix
  jit_gl_texture branch → fieldmap_pix in0
  unmatched → route <params> → live.dials → attrui → fieldmap_pix in0
  bypass jsui → prepend param bypass_gate → fieldmap_pix in0

fieldmap_pix out0 → out0 (f_vecfield texture, @type float32)
```

Neutral field when bypass is active.

---

## Acceptance Criteria

- **Basic gradient:** connect jit.gl.bfg (Perlin, medium frequency) at defaults. Patch outlet into vs_displacement — should see smooth displacement following noise gradient contours. Patch into f_caustic — should see caustic bright bands accumulating along noise ridge lines.
- **Flat input:** connect a solid-color texture. Output is flat 0.5/0.5/0.5/1.0 — zero gradient, neutral field.
- **`scale` low:** fine-detail gradient structure visible. Caustic output shows tight, high-frequency banding.
- **`scale` high:** coarser, smoother gradient. Caustic output shows broader, lower-frequency banding.
- **`gain` = 0:** output is neutral field regardless of input.
- **`gain` high:** gradient saturates — clamp behavior. Output still valid f_vecfield (clamped to 0/1).
- **Unconnected inlet:** no output, no crash.
- **Bypass:** output is flat 0.5/0.5/0.5/1.0.
- **Loads in Vsynth.** Output accepted by f_caustic and vs_displacement without error.
- **jit.gl.bfg → f_vf_fieldmap → f_caustic** is a working three-patch signal chain producing visible caustic structure.

---

## Out of Scope (v1)

- Mod inlets for gain or scale — deferred to v2 if needed
- Channel selector (R/G/B vs luminance) — luminance covers expected inputs
- Auto-normalization — requires multi-pass; deferred indefinitely
- Visual passthrough outlet — single outlet only; use vs_displacement for field visualization
- Temporal smoothing / frame blending — stateless per-frame computation only

---

## Open Questions

None. Architecture decisions resolved prior to spec (see HANDOFF.md 2026-06-07 and .specify/f_vf_fieldmap/spec.md discussion).

---

## Clarifications

### Session 2026-06-07

- Q: Single outlet or dual (vecfield + visual passthrough)? → A: Single outlet, f_vecfield only. Passthrough ergonomic value insufficient to justify second outlet. Debug via vs_displacement.
- Q: Auto-normalization or scale param? → A: Scale param only (`strength`). Auto-normalization requires multi-pass reduce; out of scope.
- Q: Mod inlets? → A: None in v1. Patch is a converter; expressiveness comes from input source variety.
- Q: Which channel to read from input? → A: Luminance composite (Rec. 601). Matches perceptual intent; inputs are expected to be grayscale-dominant.
- Q: Finite difference scheme? → A: Central difference, 4 samples. Symmetric, correct zero-crossing, minimal cost.
- Q: Param label for neighbor distance — `step` vs `scale` vs `blur`? → A: `scale`. Performer-friendly; matches perceived effect (low = fine structure, high = coarse/smooth).
- Q: `strength` default — 1.0 vs 4.0 vs 2.0? → A: `4.0`. Puts typical jit.gl.bfg Perlin gradient output into useful f_vecfield range without requiring manual calibration at first use.
