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
| `strength` | 0–2.0 | 0.8 | Streak intensity — crossfade depth on out0. **Not renamed in the 2026-07-12 gain/mix rollout** (the module was paused; deliberate-skip status was never recorded — maintenance audit 2026-10-12). |
| `direction` | menu (Fwd/Bwd/Bi) | Fwd | Forward: streak away from source; Backward: toward source; Bi: both. **Known bug:** Bi is unreachable from the UI — `build_patcher.py` hardcodes 2-option text_button wiring (parameter_mmax=1.0, reads options[0]/options[1] only). Filed with the retool work. |
| `src_vecfield`, `src_hue_mod`, `src_dispersion_mod` | internal | — | vs_inState connection gates; not user-facing |
| `bypass` | 0/1 | 0 | out0 → source; out1 → the source per the 2026-10-05 all-outlets-passthrough rule (the doc's earlier "out1 → black" predates it). The 48-step accumulation loop runs at full cost while bypassed (heaviest unguarded loop of the vecfield-blur family — see Notes). |

**Prefix:** `vfchroma` — **Object name:** `vfchroma_pix`

---

## Algorithm (shipped v10 — the codebox below was superseded; see Notes)

```
// v10: 48-step accumulation march along the field (single march UV),
// gate = source luma at each step's UV, synthesized hue per step:
//   step_hue = wrap(hue + (i/48) * dispersion), hsl2rgb
// accumulate synthesized color * gate * falloff weight
out0 = mix(source, source + streak * strength, ...)   // crossfade
out1 = streak                                          // isolated layer
```

**The v10 result does not achieve the module's stated goal** — the
accumulation averages across all 48 steps, so a full dispersion sweep
washes the rainbow to gray ("interesting but not what we want"). The
module is **paused mid-retool** (`.specify/paused/f_vf_chroma/`): the
recorded next direction is a closest-emitter / painter-model first-hit
loop (each pixel takes the FIRST gated step's hue, no averaging) — see
`continuity.md` there, and the vortex-field observation that produced
the module's most compelling result so far.

---

## Notes — real discrepancy between spec.md and definition.py

- **`spec.md` (titled "f_vf_chroma") describes a simpler two-param module** (`spread`, `strength`, plus the `src_vecfield` gate and `bypass`) with a plain R/G/B channel-split mechanic. **The shipped `definition.py`/`codebox_v10.gen` has a substantially larger parameter set** — `radius`, `hue`, `dispersion`, `saturation`, `falloff`, `threshold`, `threshold_width`, `direction`, plus two additional modulation inlets (`hue mod`, `dispersion mod`) — describing what reads as a rainbow/hue-sweep streak effect, not a simple RGB channel split. The module evolved considerably past what `spec.md` documents (spec.md is dated 2026-06-20; `definition.py` is unstamped but references `codebox_v10.gen`, i.e. at least 10 iterations past the spec's `codebox` sketch). **This doc's parameter table follows the shipped `definition.py`** — treat `spec.md` as superseded/stale for this module and confirm actual behavior against `codebox_v10.gen` directly if precision matters.
- ~~`.specify/f_vf_prism/spec.md` is a byte-for-byte copy of `f_vf_chroma`'s spec.md~~ **Corrected 2026-10-12:** prism's spec was rewritten 2026-07-11 (its own correction note documents the fork cleanup); the two files now differ and prism's describes its shipped module.
- ~~Not in README.md's patch table~~ **Outdated:** listed since the 2026-07-12 wave (README.md line 81). Maintenance-audited 2026-10-12; tasks filed in `.specify/paused/f_vf_chroma/tasks.md` (retool direction, text_button bug, docs/strength refresh folded into the resume work).

## Source File

`patchers/f_vf_chroma.maxpat`
