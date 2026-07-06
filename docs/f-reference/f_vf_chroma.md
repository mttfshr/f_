# f_vf_chroma

**Type:** Processor (f_vecfield consumer)
**Status:** Working — **not yet listed in README.md's patch table; found undocumented during a docs audit (2026-07-05)**

---

## What it does

Vecfield-driven chromatic aberration. At each pixel, samples the vecfield for a direction vector and offsets the R and B channel samples in opposite directions along it (G stays at the unshifted UV) — color fringing that follows field geometry rather than a fixed radial center: vortex fields produce spiral fringing, gradient fields produce directional fringing, convergent fields produce radial fringing.

The expressive, field-steered cousin of f_lens's `aberration` (which is physically grounded — always centrifugal, scaled by distance from a fixed center). f_vf_chroma's separation axis and direction vary per-pixel with whatever field is patched in.

Two outlets, matching the f_caustic/f_vf_streak/f_vf_glow convention: composite (crossfaded with source by `strength`) and the isolated chroma-split layer (black on bypass).

---

## Signal Flow

```
in1 (source texture)         → vfchroma_pix in1
in2 (f_vecfield, required)   → vs_inState → vfchroma_pix in2   [src_vecfield gate]
in3 (hue mod texture)        → vs_inState → vfchroma_pix       [src_hue_mod gate]
in4 (dispersion mod texture) → vs_inState → vfchroma_pix       [src_dispersion_mod gate]

vfchroma_pix (@type char) out0 → composite
vfchroma_pix (@type char) out1 → chroma layer (isolated)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `radius` | 0–0.3 | 0.05 | March distance — how far the streak extends |
| `hue` | 0–1 | 0.0 | Base hue — start of the rainbow sweep |
| `dispersion` | 0–1 | 0.5 | Hue sweep width — 0=monochrome, 1=full spectrum across streak |
| `saturation` | 0–1 | 1.0 | Streak color saturation |
| `falloff` | 0–0.01 | 0.002 | Decay rate along streak — higher = shorter, sharper streak |
| `threshold` | 0–1 | 0.8 | Luma gate floor — only pixels above this emit streak |
| `threshold_width` | 0–0.5 | 0.1 | Softness of the luma gate |
| `strength` | 0–2.0 | 0.8 | Streak intensity — crossfade depth on out0 |
| `direction` | menu (Fwd/Bwd/Bi) | Fwd | Forward: streak away from source; Backward: toward source; Bi: both |
| `src_vecfield`, `src_hue_mod`, `src_dispersion_mod` | internal | — | vs_inState connection gates; not user-facing |
| `bypass` | 0/1 | 0 | out0 → source; out1 → black |

**Prefix:** `vfchroma` — **Object name:** `vfchroma_pix`

---

## Algorithm (per spec.md's core mechanic — see discrepancy note)

```
field = (sample(vecfield, uv) - 0.5) * 2.0 * step(0.5, src_vecfield)   // suppressed when disconnected
dir = field * spread
R = sample(source, uv + dir).x
G = sample(source, uv).y
B = sample(source, uv - dir).z
out0 = mix(source, chroma_split, strength)      // crossfade, not additive
out1 = chroma_split                              // isolated layer, black on bypass
```

Single-sample split — no accumulation loop, sharp fringing rather than blurred.

---

## Notes — real discrepancy between spec.md and definition.py

- **`spec.md` (titled "f_vf_chroma") describes a simpler two-param module** (`spread`, `strength`, plus the `src_vecfield` gate and `bypass`) with a plain R/G/B channel-split mechanic. **The shipped `definition.py`/`codebox_v10.gen` has a substantially larger parameter set** — `radius`, `hue`, `dispersion`, `saturation`, `falloff`, `threshold`, `threshold_width`, `direction`, plus two additional modulation inlets (`hue mod`, `dispersion mod`) — describing what reads as a rainbow/hue-sweep streak effect, not a simple RGB channel split. The module evolved considerably past what `spec.md` documents (spec.md is dated 2026-06-20; `definition.py` is unstamped but references `codebox_v10.gen`, i.e. at least 10 iterations past the spec's `codebox` sketch). **This doc's parameter table follows the shipped `definition.py`** — treat `spec.md` as superseded/stale for this module and confirm actual behavior against `codebox_v10.gen` directly if precision matters.
- **`.specify/f_vf_prism/spec.md` is a byte-for-byte copy of `f_vf_chroma`'s spec.md** (same title, same content) — almost certainly a copy-paste artifact from when f_vf_prism was forked from f_vf_chroma. Neither spec accurately describes its own module's shipped `definition.py`. Worth cleaning up directly in `.specify/` when convenient.
- Not in `README.md`'s patch table — added as a finding of this documentation pass, not yet cross-checked into README.

## Source File

`patchers/f_vf_chroma.maxpat`
