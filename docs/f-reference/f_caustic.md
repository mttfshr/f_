# f_caustic

**Type:** Processor (f_vecfield consumer)
**Status:** Working — see discrepancy note below

---

## What it does

An optical caustic processor. Takes a light-source image and a vecfield (the refracting medium) and redistributes the source's brightness according to the field's convergence/divergence structure via backward streamline accumulation: bright bands build up where the field converges (negative divergence); diverging zones contribute nothing (no subtraction, only absence of accumulation). Two outlets: composite (source + caustic, additive) and the isolated caustic layer.

Structurally requires a coherent vecfield — patching a non-field texture into the vecfield inlet will produce output but not meaningful caustic structure. Unlike most f_vf_ consumers, the vecfield inlet has **no `vs_inState` fallback**: unconnected = zero field = zero accumulation = silent passthrough on the composite outlet and black on the caustic-layer outlet, not a misleading default radial caustic.

Compatible with any f_vf_ producer — pairs naturally with f_vf_vortex (sink topology produces a bright ring at the convergence zone) and f_vf_fieldmap (noise-derived caustic bands along ridge lines).

---

## Signal Flow

```
in0 (bang + control) → routepass → route <params> → live.dials → prepend param <name> → caustic_pix in0
in1 (light source, texture) → vs_inState → caustic_pix in1
in2 (f_vecfield, texture)   → caustic_pix in2   [no vs_inState — unconnected = silent, not fallback]

caustic_pix (@type float32) out1 → composite (source + caustic, additive)
caustic_pix (@type float32) out2 → caustic layer (isolated)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `strength` | 0–1.5 | 0.0 | Present in `definition.py`'s param list; not referenced in `codebox_v3.gen` or `spec.md`'s parameter table — see discrepancy note |
| `intensity` | 0–2.0 | 0.5 | Overall caustic brightness scale |
| `scale` | 0–1.0 | 0.3 | Streamline trace distance (`step_size = scale / 8`). 0 = no trace, no caustic. |
| `softness` | 0–1.0 | 0.3 | Band sharpness via smoothstep on accumulated luma. 0 = hard bright lines. 1 = diffuse glow. |
| `color_shift` | 0–1.0 | 0.0 | Chromatic dispersion — R/B channels sampled with offset step sizes along the streamline. 0 = monochrome bands. |
| `bypass` | 0/1 | 0 | out1 passes source unmodified; out2 goes black. |

**Prefix:** `caustic` — **Object name:** `caustic_pix`

---

## Algorithm

At each pixel, 8 fixed backward steps trace opposite the field direction (step count is a compile-time constant, not a runtime param):

```
step_size = scale / 8.0
for n in 0..7:
    field_n   = (sample(field_tex, pos_n) - 0.5) * 2.0
    div_n     = central-difference divergence of the field at pos_n (h = 1/512)
    weight_n  = max(-div_n, 0.0)                      // only convergence accumulates
    src_n.r   = sample(source, pos_n + field_n * color_shift * step_size).r
    src_n.g   = sample(source, pos_n).g
    src_n.b   = sample(source, pos_n - field_n * color_shift * step_size).b
    pos_(n+1) = pos_n - field_n * step_size

caustic = (Σ weight_n * src_n) / 8 * intensity
caustic *= smoothstep(0, softness + 0.001, luma(caustic))   // softness gate
out2 = clamp(caustic, 0, 1)
out1 = clamp(source + caustic, 0, 1)                          // additive composite
```

Backward tracing (rather than forward) finds which source regions would have contributed light to the current pixel given the field — the correct per-pixel accumulation framing without needing to iterate from the source.

---

## Notes

- **Discrepancy — verify in Max before relying on this doc:** the codebox currently shipped as `codebox_v3.gen` (the file `definition.py` opens and builds from) references only a single texture inlet (`in1`) throughout — for both the field decode/divergence math *and* the source-color sampling. `spec.md`'s design and `definition.py`'s `mod_inlets` declaration both call for two distinct texture inlets (light source on `in1`, vecfield on `in2`). Either `codebox_v3.gen` is an earlier self-referential scratch step that hasn't been updated to the documented two-inlet design, or the `in1`/`in2` codebox numbering doesn't map the way this doc assumes. Confirm against the actual patched `f_caustic.maxpat` object inlets before trusting the signal-flow diagram above in detail.
- `strength` appears in `definition.py`'s params list (range 0–1.5, default 0.0) but is not read anywhere in `codebox_v3.gen`, and does not appear in `spec.md`'s parameter table at all — likely a leftover or an in-progress addition. Treat as inert until confirmed wired.
- `@type float32` overrides the processor default of `char` — accumulation benefits from float32 headroom (decided in scratch validation).
- Divergence sign convention confirmed: f_vf_vortex sink topology (positive convergence) produces negative divergence at the fixed point, which is what produces bright bands.
- No `in3` surface texture in v1 — deferred.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract.
