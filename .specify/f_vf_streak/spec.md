# Spec: f_vf_streak

_Created: 2026-06-08_
_Status: Draft_

---

## What it does

A vecfield-driven directional blur processor for Vsynth. Takes a source texture and a vector field (as a float32 RG f_vecfield texture), and at each pixel accumulates source texture samples along the local streamline — producing a smear of the source image aligned with the field geometry. Fast-moving regions streak further; slow or zero regions remain relatively sharp.

**Consumer in the f_vecfield family.** Expects a valid f_vecfield texture in the vecfield inlet. Compatible with any f_vf_ producer: f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap, etc.

**Pure Processor archetype.** Requires an upstream source texture on in0. The vecfield inlet is optional — if unconnected, output passes through unstreaked. Bypass passes the source texture through unmodified.

**Two outlets (sidechain pattern).** out0 is the source texture composited with the streak layer (wet/dry via `strength`). out1 is the isolated streak layer for external compositing.

---

## Algorithm

At each pixel, walk backward along the field streamline for N steps, accumulating weighted source texture samples:

1. Sample the vecfield at the current UV to get the local field vector
2. Remap from [0, 1] → [-1, 1] (f_vecfield convention: 0.5 = zero vector)
3. Step backward along the field by `step_size = length / N`
4. At each step position, sample the source texture and accumulate with a distance-based weight
5. Normalize the accumulated result
6. Apply `color_shift`: offset R/G/B channel sample UVs along the field direction by a small per-channel amount, producing chromatic separation aligned to the streak
7. out1 = accumulated streak layer (raw)
8. out0 = source + streak * strength (additive blend; clipping acceptable and desirable at high strength)

**Step count:** Fixed at 8 (matching caustic). Balances quality against texture sample budget.

**Weighting:** Controlled by `falloff` parameter:
- `falloff = 0.0`: uniform — all steps weighted equally, pure directional blur
- `falloff = 1.0`: linear falloff — step 0 (current pixel) weighted fully, step 7 weighted ~zero; gives a trailing smear with sharper leading edge
- Intermediate values interpolate between the two regimes

Codebox pseudocode:

```glsl
Param strength(0.3);
Param length(0.15);
Param falloff(0.0);
Param color_shift(0.0);
Param src_vecfield(0.0);  // system param
Param bypass(0.0);

uv = norm;
step_size = length / 8.0;
cs = color_shift * step_size;

// suppress when no vecfield connected
connected = step(0.5, src_vecfield);

// unroll 8 steps: walk backward along streamline, accumulate weighted samples
// at step n:
//   posNx, posNy = position after n backward steps
//   fNx, fNy = field vector at posN (decoded inline)
//   wN = falloff weight at step n = mix(1.0, 1.0 - n/7.0, falloff)
//   srcN = source sample at posN (with color_shift offset on R/B channels)

// accumulate weighted color
// normalize by sum of weights
// streak_layer = normalized accumulation

// out1: streak layer (isolated)
out2 = mix(streak_layer, black, bypass);

// out0: additive blend — streak adds light over source, scaled by strength
out1 = mix(source + streak_layer * strength, source, bypass);
```

**`src_vecfield` state param:** When vecfield inlet is unconnected, `vs_inState` delivers `vs_black` (all zeros) to pix. After the `(field - 0.5) * 2.0` remap, zero maps to `-1.0` — producing a constant diagonal offset toward the top-left, not a passthrough. Explicit suppression is required: multiply decoded field vectors by `step(0.5, src_vecfield)` before stepping, zeroing them when unconnected. Same pattern as f_vf_warp.

**Edge behavior:** Step positions outside [0,1] are clamped, smearing the edge pixels.

---

## Inlets

| Inlet | Type | Label | Required | Description |
|---|---|---|---|---|
| 0 | texture + control | texture | Yes | Source texture to streak; control messages |
| 1 | f_vecfield texture | vecfield | No | Flow field (float32, RG=XY, 0.5=zero) |

When in1 is unconnected: `vs_inState` delivers `vs_black`; decoded field vectors are suppressed via `src_vecfield` — step positions stay at current UV, accumulation degenerates to source passthrough.

When in0 is unconnected: output is black.

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `strength` | live.dial | 0.0–1.0 | 0.3 | Wet/dry mix of streak layer into out0. out1 unaffected. |
| `length` | live.dial | 0.0–20.0 | 0.15 | Streamline trace distance in UV space. Controls streak reach. |
| `falloff` | live.dial | 0.0–2.5 | 0.0 | 0 = uniform blur, 1 = linear trailing smear. >1 = negative tail weights (expressive artifact territory). |
| `color_shift` | live.dial | 0.0–20.0 | 0.0 | Chromatic separation along streak direction. 0 = none. |
| `bypass` | bypass_toggle.js | 0/1 | 0 | out0 passes source; out1 goes black. |

Hidden system params:

| Param | Source | Notes |
|---|---|---|
| `src_vecfield` | vs_inState out1 on in1 | 0 = no field, 1 = connected. Available for suppression if zero-field passthrough proves unreliable in practice. |

**Prefix:** `vfstreak`
**Object name:** `vfstreak_pix`
**Output type:** `@type char`

---

## Signal Flow

```
in0 (texture + control) → routepass jit_gl_texture jit_matrix
  jit_gl_texture branch → vfstreak_pix in0      [source texture, direct]
  unmatched → route strength length falloff color_shift
            → live.dials → attruis → vfstreak_pix in0

in1 (vecfield texture) → vs_inState in0
  vs_inState out0 (texture or vs_black) → vfstreak_pix in1   [gen in2]
  vs_inState out1 (0/1) → prepend param src_vecfield → vfstreak_pix in0

bypass_toggle.js → attrui (bypass) → vfstreak_pix in0

vfstreak_pix out0 → out0 (composited, @type char)
vfstreak_pix out1 → out1 (streak layer isolated, @type char)
```

**Gen subpatcher inlets:**
- `in 1` → source texture
- `in 2` → vecfield texture or vs_black
- Codebox `numinlets`: 2, `numoutlets`: 2

---

## Outlets

| Outlet | Label | Description |
|---|---|---|
| 0 | out | Source composited with streak layer (wet/dry via `strength`) |
| 1 | streak | Isolated streak layer for external compositing |

---

## Acceptance Criteria

- **Basic streak:** Connect a source texture to in0 and `f_vf_vortex` to in1. The source should appear smeared along vortex streamlines, with the smear character changing with `length` and `falloff`.
- **Strength control:** `strength = 0` → out0 matches source exactly. `strength = 1` → full streak composite.
- **Length control:** Increasing `length` extends streak reach along streamlines smoothly.
- **Falloff control:** `falloff = 0` gives a symmetric directional blur; `falloff = 1` gives a one-directional trailing smear.
- **Color shift:** Increasing `color_shift` from 0 produces chromatic separation aligned to streak direction.
- **Isolated layer:** out1 contains only the streak layer, usable as an alpha or additive composite source.
- **No vecfield connected:** With in1 unconnected, out0 passes source through unmodified; out1 is black.
- **No source connected:** Both outlets black.
- **Bypass:** out0 passes source; out1 is black.
- **Accepts any f_vf_ producer:** Works with f_vf_vortex, f_vf_vortex_multi, f_vf_fieldmap without artifacts.
- **Resolution independence:** Streak is consistent regardless of source and vecfield resolutions.
- **Loads in Vsynth.** Survives a save/load cycle without crashing.

---

## Out of Scope

- Forward or bidirectional streamline tracing — backward only in v1
- Magnitude-weighted step size — uniform step size; field magnitude not used to modulate per-step distance
- Variable step count — fixed at 8
- Wrap/mirror edge modes — clamp to edge sufficient for v1
- Strength modulation via texture inlet

---

## Clarifications

### Session 2026-06-08

- Q: out0 composite operator — additive blend or replace blend? → A: Additive (`source + streak * strength`)
- Q: Zero-field passthrough — does vs_black degenerate cleanly? → A: No; explicit suppression required (same `src_vecfield` pattern as f_vf_warp; vs_black → -1.0 offset without it)
- Q: Parameter ranges — length, color_shift, falloff upper bounds? → A: length 0–20, color_shift 0–20, falloff 0–2.5 (>1 enters negative tail weight territory, expressive)

---

## Open Questions

- **Two-outlet bpatcher size:** Default processor size is 78×90. Two outlets and four params may require wider presentation rect — check against moduleSize.js constraints.
