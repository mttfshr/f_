# f_vecfield — Vector Field Type Contract

_Created: 2026-06-06_
_Status: Draft — f_vortex and f_vortex_multi complete; consumer contracts (f_caustic, f_lens field inlet) pending_

---

## What this document is

A type contract for the f_vecfield texture format. Any patch that produces or consumes a vector field texture must conform to this contract. The contract is independent of which patch produced the field — consumers do not need to know the source.

This is analogous to Vsynth's own texture type conventions. The f_vecfield format is an extension of those conventions for a specific two-channel semantic.

---

## Definition

A vector field texture is a **jointly-computed two-channel (RG = XY) float32 texture** where both channels are derived from the same underlying mathematical structure. This joint computation is what gives the field coherent spatial properties: divergence, curl, streamlines, and predictable fixed-point topology.

This is categorically different from patching two independent textures into the x mod and y mod inlets of vs_displacement. Those are two unrelated scalars that happen to be read together. A vector field texture encodes a single geometric quantity at every pixel — a vector — and the relationship between neighboring vectors is meaningful.

---

## Encoding

| Property | Value |
|---|---|
| Max type | `float32` |
| Channels used | R (X component), G (Y component) |
| Range | 0.0 – 1.0 |
| Zero vector | R = 0.5, G = 0.5 |
| Full positive | R = 1.0, G = 1.0 |
| Full negative | R = 0.0, G = 0.0 |
| B and A channels | Unused by convention — set to 0.5 and 1.0 respectively |

**Encoding formula (producer):** to encode a signed vector component `v` in range -1.0 to +1.0:

```
encoded = v * 0.5 + 0.5
```

**Decoding formula (consumer):** to recover a signed component from an encoded pixel value `p`:

```
v = (p - 0.5) * 2.0
```

This is the same encoding convention used by Vsynth's displacement modulation inlets, confirmed against `vs_displacement` and `vs_xyz_disp` source. Both remap 0–1 texture input to -1–1 internally via `scale 0. 1. -1. 1.`.

---

## Coordinate frame

Vector components are expressed in **normalized screen coordinates**: the frame width and height are both 1.0. A vector of (R=1.0, G=0.5) decodes to (X=+1.0, Y=0.0) — a full-frame-width displacement to the right.

Coordinate axes follow jit.gl convention: X increases right, Y increases down.

---

## Magnitude semantics

Producers output **relative field strength** — magnitude is not in absolute pixel units. Each consumer applies its own amount or strength parameter to scale the field's effect. This follows Vsynth's modulation convention: the source produces a normalized signal, the consumer controls how much it matters.

A producer should use the full 0–1 range meaningfully. A field that never exceeds ±0.1 normalized (encoded as 0.4–0.6) wastes dynamic range and gives consumers less to work with.

---

## Derived quantities — what is and isn't stored

The vector field texture stores only the XY vector at each pixel. The following quantities are **not stored** — they are computed by consumers from the texture via finite differences:

- **Divergence** — spatial derivative of the field: ∂Fx/∂x + ∂Fy/∂y. Negative divergence = convergence zone (where caustic bright bands accumulate). Positive = divergence zone.
- **Curl** — rotational component: ∂Fy/∂x - ∂Fx/∂y. Non-zero curl indicates rotational field character.
- **Streamlines** — paths that follow field vectors across the image plane. Computed by iterative integration (stepping along field direction per pixel).

Finite difference quality scales with texture resolution. At low resolutions, derived quantities become coarse. This is a known constraint — stated here so consumers can document their resolution sensitivity.

---

## Producer conventions

Any patch in the f_vecfield family must:

1. Output `@type float32` texture
2. Encode XY components in 0–1 range with 0.5 = zero
3. Set B channel to 0.5, A channel to 1.0
4. Use `vs_black` as the fallback for unconnected modulation inlets (produces 0.5 = zero modulation, consistent with the neutral field)
5. Accept a texture inlet for structural modulation (what the inlet modulates is mode-specific — documented per patch)

---

## Consumer conventions

Any patch with a vector field inlet must:

1. Accept a float32 texture on the vector field inlet
2. Label the inlet clearly as accepting a vector field (e.g. `vec field` or `f_vecfield`)
3. Decode via `(sample - 0.5) * 2.0` before any field computation
4. Apply its own amount/strength parameter to scale the decoded field — do not assume producer magnitude is calibrated to the consumer's needs
5. Use `vs_black` (all 0.5) as the fallback for an unconnected vector field inlet, producing zero field effect

---

## Compatibility with core Vsynth modules

`vs_displacement` and `vs_xyz_disp` will accept a vector field texture and produce displacement behavior. They remap 0–1 to -1–1 internally, so the encoding is compatible. However, these modules treat the texture as two independent scalar channels — they do not compute divergence, curl, or streamlines. Patching a vector field into vs_displacement is valid and may produce interesting results, but uses the field as a dumb two-channel texture, not as a coherent field.

---

## Family members

### Producers (f_vecfield family)

| Patch | Status | Description |
|---|---|---|
| `f_vortex` | **Complete** | Single fixed-point vortex field — position, convergence, curl; 4 mod inlets |
| `f_vortex_multi` | **Complete** | Three-site additive vortex field — per-site position/conv/curl via control inlet; 4 global mod inlets |
| `f_vortex_turbulence` | Idea | Hash-grid turbulence field — implicit infinite sites |

### Consumers

| Patch | Status | Notes |
|---|---|---|
| `f_caustic` | Idea | Streamline accumulation — requires coherent field; divergence-sensitive |
| `f_lens` | Partial | Field inlet planned for spatial aberration modulation |
| `vs_displacement` | Existing | Compatible encoding; treats as scalar pair, not coherent field |
| `vs_xyz_disp` | Existing | Same as vs_displacement |

---

## Open questions

- **f_caustic step size:** streamline integration needs a step size parameter. Should this be expressed in normalized screen coordinates (consistent with field encoding) or in pixels? Normalized is cleaner but resolution-dependent in practice.
- **f_lens field inlet:** what structural parameter does the field modulate — aberration axis, distortion center, or something else? To be resolved when f_lens field inlet is designed.
- **Multi-channel extension:** if a future patch needs a 3D field (XYZ), does this contract extend naturally to RGB, or does it require a new type document?
