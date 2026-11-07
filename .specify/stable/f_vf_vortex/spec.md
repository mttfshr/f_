# Spec: f_vortex

_Created: 2026-06-06_
_Status: Draft_

---

## What it does

A single fixed-point vector field generator. Produces an f_vecfield-encoded float32 texture — RG encodes signed XY field direction, 0.5 = zero vector. The field has one fixed point whose topology is continuously variable between pure sink, spiral sink, center (pure rotation), spiral source, and pure source via two independent params: convergence and curl.

**Producer in the f_vecfield family.** Output is intended for f_vecfield consumers (f_caustic, field-inlet patches). Also compatible with vs_displacement as a dumb two-channel texture.

**Generator only — no source/processor duality.** No incoming image. Inlet 0 receives bang only.

---

## Field Architecture

At every pixel, the field vector is computed from the offset to the fixed point:

```
dx = norm.x - cx
dy = norm.y - cy
r  = sqrt(dx*dx + dy*dy)

// unit radial (away from center)
rx = dx / max(r, 0.0001)
ry = dy / max(r, 0.0001)

// unit tangential (90 deg CCW of radial)
tx = -ry
ty =  rx

// blend convergence (toward center) and curl (rotation)
fx = convergence * (-rx) + curl * tx
fy = convergence * (-ry) + curl * ty

// falloff
strength = exp(-r * falloff)
fx *= strength
fy *= strength
```

**Convergence/curl as a 2D param space:**

| convergence | curl | Topology |
|---|---|---|
| > 0 | 0 | Sink — field points inward |
| < 0 | 0 | Source — field points outward |
| 0 | ≠ 0 | Center — pure rotation, no convergence |
| > 0 | ≠ 0 | Spiral sink |
| < 0 | ≠ 0 | Spiral source |

Named topologies are landmarks in a continuous 2D space. No discrete mode selector.

**Falloff:** exponential decay with distance from fixed point. `exp(-r * falloff)`. Positive falloff = field concentrated near fixed point. At falloff = 0, field has uniform strength across frame (no decay). Negative falloff not permitted — clamp to 0 in implementation.

**Encoding (f_vecfield contract):**

```
R = clamp(fx * 0.5 + 0.5, 0.0, 1.0)
G = clamp(fy * 0.5 + 0.5, 0.0, 1.0)
B = 0.5
A = 1.0
```

---

## Inlets

| Inlet | Type | Label | Description |
|---|---|---|---|
| 0 | bang + control | — | Vsynth standard. Control messages route to params. |
| 1 | texture (optional) | cx mod | Modulates fixed point X position. vs_black = no offset. |
| 2 | texture (optional) | cy mod | Modulates fixed point Y position. vs_black = no offset. |
| 3 | texture (optional) | convergence mod | Modulates convergence. vs_black = no offset. |
| 4 | texture (optional) | curl mod | Modulates curl. vs_black = no offset. |

All modulation inlets are additive: `param_effective = param_dial + sample(inN).x * mod_amount`. Each modulation inlet has a corresponding `_amt` param that scales its influence. vs_black fallback on all modulation inlets.

Modulation decoding for all inlets: `(sample(inN, norm).x - 0.5) * 2.0 * amt`, giving offset range `[-amt, +amt]`. For cx/cy this means at `_amt = 1.0` the fixed point can be driven ±1.0 beyond the dial value — fully off-screen. This is intentional; the field computes cleanly outside 0–1 and off-screen fixed points produce expressive asymmetric fields.

---

## Parameters

| Param | UI | Range | Default | Notes |
|---|---|---|---|---|
| `cx` | live.dial | 0.0–1.0 | 0.5 | Fixed point X position in normalized screen coords |
| `cy` | live.dial | 0.0–1.0 | 0.5 | Fixed point Y position in normalized screen coords |
| `convergence` | live.dial | -1.0–1.0 | 0.5 | Inward pull strength. 0 = none, >0 = sink, <0 = source |
| `curl` | live.dial | -1.0–1.0 | 0.0 | Rotational component. 0 = none, >0 = CCW, <0 = CW |
| `falloff` | live.dial | 0.0–10.0 | 2.0 | Exponential decay rate. 0 = no falloff (uniform field) |
| `cx_amt` | live.dial | 0.0–1.0 | 0.0 | Inlet 1 modulation depth |
| `cy_amt` | live.dial | 0.0–1.0 | 0.0 | Inlet 2 modulation depth |
| `convergence_amt` | live.dial | 0.0–1.0 | 0.0 | Inlet 3 modulation depth |
| `curl_amt` | live.dial | 0.0–1.0 | 0.0 | Inlet 4 modulation depth |
| `bypass` | jsui (bypass_toggle.js) | 0/1 | 0 | Bypass — outputs neutral field (all 0.5) |

**Prefix:** `vortex`
**Object name:** `vortex_pix`
**Type:** `@type float32`

---

## Signal Flow

```
in0 (bang + control) → routepass jit_gl_texture jit_matrix
  routepass unmatched → route <params> → live.dials → prepend param <name> → vortex_pix in0

in1 (cx mod texture)         → routepass jit_gl_texture → vs_inState → vortex_pix in1
in2 (cy mod texture)         → routepass jit_gl_texture → vs_inState → vortex_pix in2
in3 (convergence mod texture) → routepass jit_gl_texture → vs_inState → vortex_pix in3
in4 (curl mod texture)       → routepass jit_gl_texture → vs_inState → vortex_pix in4

vortex_pix out0 → out0 (f_vecfield texture, @type float32)
```

vs_black fallback on all modulation inlets via vs_inState. Neutral field (all 0.5) when bypass active.

---

## Acceptance Criteria

- At defaults (cx=0.5, cy=0.5, convergence=0.5, curl=0.0, falloff=2.0): smooth radial sink centered at frame center. RG gradient visible — warm center, directional color variation toward edges.
- `convergence = 0, curl ≠ 0`: pure rotation, no inward pull. Fixed point visible as a calm eye.
- `convergence < 0`: field reverses — source topology, vectors pointing outward.
- `cx/cy` moved off-center: fixed point follows correctly. Field topology unchanged, position shifted.
- `falloff = 0`: field strength uniform across frame — no center concentration.
- `falloff` increased: field increasingly concentrated near fixed point, edges approach neutral (0.5, 0.5).
- Modulation inlets at vs_black with `_amt = 0`: no effect on output.
- Modulation inlets connected with `_amt > 0`: param offsets visibly.
- Bypass: output is flat 0.5/0.5/0.5/1.0 — neutral field, no topology.
- Loads in Vsynth, output accepted by f_vecfield consumers and vs_displacement.

---

## Open Questions

- **convergence range:** -1.0–1.0 assumes field math produces meaningful output at negative values (source topology). Verify in scratch patch that negative convergence produces clean outward field rather than artifacts.

---

## Clarifications

### Session 2026-06-06

- Q: Should cx/cy modulation be clamped to keep the fixed point on-screen, or allow full ±1.0 offset? → A: Full ±1.0 offset permitted. Off-screen fixed points produce expressive asymmetric fields and the field math is clean outside 0–1.
- Q: UI layout for 9 params + bypass? → A: Row 1: cx, cy, convergence, curl. Row 2: falloff, cx_amt, cy_amt, convergence_amt. Row 3: curl_amt, bypass.
- Q: Which channel to sample on modulation inlets? → A: `.x` (red channel — conventional scalar modulation in f_ family).
