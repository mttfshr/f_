# f_vf_prism

**Type:** Processor (f_vecfield consumer; its third outlet also emits a vecfield)
**Status:** Working — listed in README.md's patch table; maintenance-audited 2026-10-12; stable preflight 2026-11-06 (offline by Claude, see `.specify/stable/f_vf_prism/tasks.md`)

---

## What it does

Field-driven spectral/prism separation. For each pixel and each channel it looks up the source at a position displaced back along the vecfield by `reach`, so what it finds lands downstream as an echo. G follows the field; R and B are rotated off it by `+spread` and `-spread` radians. Each channel is then gated by `threshold` on its own value at that position: the red gate reads red, the green gate green, the blue gate blue. There is no luma computation, so pure red passes only the red gate and casts a red echo with no split. The gates are blurred over 11 taps across the field, and `feather` sets how wide those taps sit: low gives hard RGB bands, high a smoother gradient between them.

Three outlets: composite (the prism layer times `gain`, added over the source and clipped to 0-1, then blended by `mix`), the isolated prism layer (not scaled by `gain` or `mix`), and a gate-weighted dispersion vecfield (below).

Color appears at the edges of bright regions, where the three displaced lookups disagree. Inside a region bright in all channels the three gates open together, so the layer adds white and the composite clips. Nothing below `threshold` adds anything.

Closely related to f_vf_chroma (same family of vecfield-driven chromatic effects). Chroma synthesizes a rainbow marched along the field (per its doc); Prism's color comes only from the source's own channels landing at different positions.

**Inputs.** Inlet 0 must carry a texture: it alone triggers the pix (there is no `r draw`), so no source means no output (wiring read, not run). A vecfield on inlet 1 is what moves anything. With no vecfield, or a zero field, every lookup is the pixel itself: nothing splits or moves, but pixels over `threshold` still brighten, so the output is not the source (code read, not run). Only bypass, `gain` 0 or `mix` 0 return the source.

The vecfield inlet falls back to `vs_black` through `vs_inState`. `src_vecfield` zeroes the field when unconnected, and `field_suppress` drops any pixel where R + G is below 0.02, which covers black during the `vs_inState` lag; a real full-strength (-1, -1) vector would be dropped too.

**Mod inlets.** Inlets 2 and 3 read the texture's red channel: `reach + (red - 0.5)` and `spread + (red - 0.5)`, clamped to the dial's range. Red 0.5 changes nothing; there is no depth control, so at the default `reach` of 0.05 anything below red 0.45 gives zero reach. Unconnected, they do nothing.

**Third outlet.** The three channels' displacement vectors, each weighted by that channel's own blurred gate, summed, scaled by an internal 8 and encoded with 0.5 = zero. Neutral where no gate is open, strongest where all three are open and agree, and leaning toward the open channels where they disagree. Not normalized, and clipped to 0-1: three open gates on a full-strength axis-aligned field reach the clip at a `reach` of about 0.04, below the default (worked from the code, not run). The pix is `@type char`, so this outlet is 8-bit, not the float32 the vecfield type asks for, and cannot hold 0.5 exactly (127/255 and similar; the contract bench allows 0.0042).

**Bypass.** Toggle only: there is no `bypass` selector in the route. It drives the codebox Param `bypass_gate`, not the native `@bypass`. Outlets 0 and 1 give the source; outlet 2 gives the incoming vecfield, or neutral 0.5 when nothing is connected.

---

## Signal Flow

```
inlet 0 (source texture + control) → routepass jit_gl_texture jit_matrix → vfprism_pix in1
routepass unmatched → route reach spread threshold threshold_width feather gain mix_pct
                    → live.dials / numbox → attrui → vfprism_pix
inlet 1 (f_vecfield, required) → vs_inState → vfprism_pix in2   [connected flag → src_vecfield]
inlet 2 (reach mod texture)    → vs_inState → vfprism_pix in3   [connected flag → src_length_mod]
inlet 3 (spread mod texture)   → vs_inState → vfprism_pix in4   [connected flag → src_width_mod]
bypass toggle (jsui) → prepend param bypass_gate → vfprism_pix

vfprism_pix (@type char) out1 → outlet 0: composite
vfprism_pix (@type char) out2 → outlet 1: prism layer (isolated)
vfprism_pix (@type char) out3 → outlet 2: dispersion vecfield (8-bit)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `reach` | 0–0.3 | 0.05 | Displacement distance along the field, in UV, times the field's length |
| `spread` | 0–0.5 | 0.1 | Rotation of R and B off the field, in radians. 0 = all three channels land together, no color split |
| `threshold` | 0–1 | 0.7 | Gate floor, on each channel's own value at its displaced position |
| `threshold_width` | 0–0.5 | 0.1 | Softness of the gate edge. At 0 `smoothstep` gets equal edges, undefined in GLSL (expected a hard step, inferred) |
| `feather` | 0–0.5 | 0.1 | Width of the gate blur: taps reach ±5 × `feather` × sin(`spread`) × `reach` × field length, across the field. 0 = hard RGB separation; does nothing when `spread` or `reach` is 0 |
| `gain` | 0–2.0 | 1.0 | Prism intensity in the composite, additive over source, before mix. The isolated layer ignores it |
| `mix` | 0–100% | 100% | Continuous blend toward the fully-composited (source + effect) state, not spatial masking (`mix_pct` internally). The isolated layer ignores it |
| `src_vecfield`, `src_length_mod`, `src_width_mod` | internal | — | vs_inState connection flags; not user-facing |
| `bypass` | 0/1 | 0 | Toggle only, through `bypass_gate` (see Bypass above) |

**Prefix:** `vfprism` — **Object name:** `vfprism_pix`

---

## Notes

- An earlier version of this note claimed `.specify/stable/f_vf_prism/spec.md` was a stale copy of `f_vf_chroma`'s spec.md; **corrected 2026-10-12**: the spec was rewritten 2026-07-11 against the production module (its own correction note documents the fork cleanup), and it now describes the shipped `reach`/`threshold`/`feather` design. Its bypass lines and its out3 acceptance criteria are behind the code; this doc follows the code.
- **`codebox_v17.gen` is the version currently wired into `definition.py`** — this module went through many iterations (`codebox_v1.gen` through `codebox_v17.gen` all exist in `src/f_vf_prism/`); only v17 is live, adding the out3 gate-weighted vecfield outlet (ADR1) and the `strength` → `gain` rename on top of the v15 baseline. The 11 tap weights are constants in the codebox, with no `exp()`.
- Displaced lookups clamp to 0.001 / 0.999, not 0 / 1: on the GPU an exact edge coordinate reads the opposite edge (2026-10-20).
- Listed in `README.md`'s patch table.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract.

## References

Per-channel displaced lookup with the gate values blurred across the field: derived in development, no external source (origin in `.specify/stable/f_vf_prism/continuity.md`).

## Source File

`package/patchers/f_vf_prism.maxpat`
