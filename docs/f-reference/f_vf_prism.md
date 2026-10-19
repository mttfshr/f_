# f_vf_prism

**Type:** Processor (f_vecfield consumer)
**Status:** Working — listed in README.md's patch table (the 2026-07-05 audit note "not yet listed" is outdated); maintenance-audited 2026-10-12

---

## What it does

Field-driven spectral/prism separation: displaces R/G/B channel samples outward along the vecfield direction by `reach`, spread apart angularly by `spread`, then gates the effect by a `threshold` on each channel's own displaced value at each of its 11 blurred tap positions, so only bright source regions cast prism color. `feather` blends between hard RGB separation and a smooth spectral gradient. Two outlets, matching the f_caustic/f_vf_streak/f_vf_chroma/f_vf_glow convention: composite (additive over source on out0 via `strength`) and the isolated prism layer.

Closely related to f_vf_chroma (same family of vecfield-driven chromatic effects) but adds the luma-gated threshold/feather mechanic — prism color appears specifically where bright source content meets the field, rather than uniformly everywhere the field is nonzero.

---

## Signal Flow

```
in1 (source texture)      → vfprism_pix in1
in2 (f_vecfield, required)→ vs_inState → vfprism_pix in2   [src_vecfield gate]
in3 (reach mod texture)   → vs_inState → vfprism_pix       [src_length_mod gate]
in4 (spread mod texture)  → vs_inState → vfprism_pix       [src_width_mod gate]

vfprism_pix (@type char) out0 → composite
vfprism_pix (@type char) out1 → prism layer (isolated)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `reach` | 0–0.3 | 0.05 | Displacement distance along field — how far the prism effect reaches |
| `spread` | 0–0.5 | 0.1 | Angular spread between R/G/B channels — chromatic separation distance |
| `threshold` | 0–1 | 0.7 | Luma gate — only bright pixels at sample position cast prism color |
| `threshold_width` | 0–0.5 | 0.1 | Softness of the luma gate — blob boundary edge |
| `feather` | 0–0.5 | 0.1 | Inter-channel blend — 0=hard RGB separation, high=smooth spectral gradient |
| `gain` | 0–2.0 | 1.0 | Prism intensity — additive over source, before mix |
| `mix` | 0–100% | 100% | Continuous blend toward the fully-composited (source + effect) state, not spatial masking (`mix_pct` internally). |
| `src_vecfield`, `src_length_mod`, `src_width_mod` | internal | — | vs_inState connection gates; not user-facing |
| `bypass` | 0/1 | 0 | Standard bypass |

**Prefix:** `vfprism` — **Object name:** `vfprism_pix`

---

## Notes

- An earlier version of this note claimed `.specify/f_vf_prism/spec.md` was a stale copy of `f_vf_chroma`'s spec.md; **corrected 2026-10-12**: the spec was rewritten 2026-07-11 against the production module (its own correction note documents the fork cleanup), and it now describes the shipped `reach`/`threshold`/`feather` design.
- **`codebox_v17.gen` is the version currently wired into `definition.py`** — this module went through many iterations (`codebox_v1.gen` through `codebox_v17.gen` all exist in `src/f_vf_prism/`); only v17 is live, adding the out3 gate-weighted vecfield outlet (ADR1) and the `strength` → `gain` rename on top of the v15 baseline.
- Listed in `README.md`'s patch table.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract.

## Source File

`patchers/f_vf_prism.maxpat`
