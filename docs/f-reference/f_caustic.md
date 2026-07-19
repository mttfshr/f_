# f_caustic

**Type:** Processor (f_vecfield consumer)
**Status:** Working — vecfield-inlet discrepancy resolved 2026-07-11; gain/mix rollout applied 2026-07-12 (see Notes)

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
| `mix_pct` | 0–100% | 0.0 | Wet/dry crossfade toward the fully-composited (source+caustic) state — `composited = mix(source_pass, composite, mix_pct)`. Renamed from `strength` 2026-07-12 (gain/mix rollout); range capped to true 0–100% (dropping the old 0–1.5 extrapolation zone). Rendered as `live.numbox`; internal Param named `mix_pct` to avoid colliding with the codebox's `mix()` operator. |
| `gain` | 0–2.0 | 0.5 | Caustic brightness scale. Renamed from `intensity` 2026-07-12 to match the library-wide gain/mix naming convention. |
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

caustic = (Σ weight_n * src_n) / 8 * gain
caustic *= smoothstep(0, softness + 0.001, luma(caustic))   // softness gate
composite = clamp(source + caustic, 0, 1)                     // additive layer
composited = mix(source, composite, mix_pct / 100)             // wet/dry crossfade
out2 = clamp(caustic, 0, 1)
out1 = composited
```

Backward tracing (rather than forward) finds which source regions would have contributed light to the current pixel given the field — the correct per-pixel accumulation framing without needing to iterate from the source.

---

## Notes

- **Resolved 2026-07-11 (was: discrepancy note):** `definition.py` had been pointing at `codebox_v3.gen`, which turned out to be a stray, earlier single-inlet draft — its own internal header comment reads `// f_caustic codebox v1 — scratch validation` despite the `v3` filename, and it referenced only `in1` throughout (both field decode and source-color sampling), never `in2`. Confirmed via filesystem mtimes and by directly comparing its content against `codebox_v2.gen`, which has the correct two-inlet structure, the wet/dry crossfade, and matches this doc's signal-flow/algorithm sections as originally written. `codebox_v3.gen` has been deleted; `definition.py` now points at `codebox_v2.gen`. This means **the vecfield inlet may not have been functioning in whatever patcher was last built from `definition.py`** — rebuild and re-verify in Max before relying on existing `f_caustic.maxpat` behavior matching this doc.
- **2026-07-12 gain/mix rollout:** `strength` renamed to `mix_pct` (range capped to true 0–100%, rendered as `live.numbox`) and `intensity` renamed to `gain`, matching the library-wide convention (`gain` = unbounded effect intensity, `mix` = 0–100% blend ratio). Confirmed wired in `codebox_v2.gen`.
- **2026-07-19:** `definition.py`'s `open()` call for `codebox_v2.gen` had a stale hardcoded path pointing at `.specify/f_caustic/` from before the `src/` reorg — fixed to point at `src/f_caustic/codebox_v2.gen`, where the file actually lives.
- `@type float32` overrides the processor default of `char` — accumulation benefits from float32 headroom (decided in scratch validation).
- Divergence sign convention confirmed: f_vf_vortex sink topology (positive convergence) produces negative divergence at the fixed point, which is what produces bright bands.
- No `in3` surface texture in v1 — deferred.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract.
