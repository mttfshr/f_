# f_vf_repulse

**Type:** Generator (f_vecfield producer, texture-driven)
**Status:** Complete (scratch-verified 2026-06-18; audit and build sign-off still open per spec.md)

---

## What it does

Texture-driven repulsion vecfield. For each pixel, samples 16 evenly-spaced points around a ring at radius `reach` and accumulates vectors pointing away from bright (above `threshold`) regions into a single f_vecfield output. Single-pass, stateless per frame — no feedback, no multipass propagation. Supersedes an earlier sobel+dilate approach that needed edge detection and multipass spreading; this ring-sample architecture produces correct omnidirectional outward flow from arbitrary shapes directly.

Primary use case: any texture source → f_vf_repulse → f_vf_advect, producing fluid motion flowing away from bright shapes. Multiple instances produce interacting repulsion fields.

All params are meaningful with negative values (not just their nominal positive range) — negative `gain` gives attraction instead of repulsion, negative `reach` samples inside shapes instead of around them, negative `threshold` repulses from dark regions instead of bright ones. Do not clamp these externally.

---

## Signal Flow

```
in0 (texture) → repulse_pix in1

repulse_pix (@type float32) → out0 (f_vecfield)
```

Pure processor: single texture inlet, single vecfield outlet, no feedback/textureset.

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `gain` | -10–10 | 4.0 | Field magnitude. Negative = attraction instead of repulsion. (Called `strength` in spec.md — the shipped param name is `gain`.) |
| `reach` | -0.5–0.5 | 0.1 | Ring sample radius, normalized UV. Negative samples inside shapes. |
| `threshold` | -1–1 | 0.3 | Luma threshold for repulsion contribution. Negative = repulse from dark regions. |
| `mode` | menu (0–3) | 0 | Accumulation mode — Cancel / Max / Abs Add / Turbulent. |
| `bypass` | 0/1 | 0 | Passes input texture through unchanged (not a neutral field — matches source, per codebox `mix(field, sample(in1,uv), bypass)`). |

**Prefix:** `repulse` — **Object name:** `repulse_pix`

---

## Accumulation Modes

| Mode | Name | Behavior |
|---|---|---|
| 0 | Cancel | Straight vector accumulation; opposing contributions from surrounding bright regions neutralize, producing stagnation zones between blobs. |
| 1 | Max | Strongest single ring sample wins; no cancellation — nearest/brightest bright region dominates at each pixel. |
| 2 | Abs Add | Accumulates magnitudes regardless of direction, then normalizes to the direction of the (mode-0-style) cancel vector — fields reinforce rather than cancel. |
| 3 | Turbulent | Cancel behavior, plus injected curl (perpendicular to the cancel vector) scaled by how much cancellation is occurring relative to total magnitude — rotation appears specifically in stagnation zones. |

Branching is a per-pixel `if/else` on `floor(mode)` — only the active mode's math runs.

---

## Algorithm

```
for i in 0..15 (16 evenly-spaced unit directions):
    luma_i = rec601_luma(sample(source, uv + dir_i * reach))
    w_i    = max(luma_i - threshold, 0.0)

// mode 0 (Cancel): fx,fy = Σ(-dir_i * w_i)
// mode 1 (Max):     fx,fy = strongest single (-dir_i * w_i) by weight
// mode 2 (Abs Add): fx,fy = normalize(cancel_vec) * Σ(w_i)
// mode 3 (Turbulent): fx,fy = cancel_vec + perp(cancel_vec) * turb_amt
//   where turb_amt = clamp((Σw_i / |cancel_vec| - 1) * 0.2, 0, 1)

field = clamp(fx * gain * 0.5 + 0.5, 0, 1), clamp(fy * gain * 0.5 + 0.5, 0, 1)
out1 = mix(vec(field, 0.5, 1.0), sample(source, uv), bypass)
```

Luma weighting is Rec. 601 (`0.299R + 0.587G + 0.114B`).

---

## Notes

- A previously-planned `f_vf_dilate` module (sobel + dilate propagation) is not needed for this use case — deprioritized per spec.md, though it remains specced as potentially useful for spreading other vecfields (vortex, fieldmap) rather than texture-driven repulsion specifically. Confirmed still unbuilt (`patchers/` has no `f_vf_dilate.maxpat`; `.specify/f_vf_dilate/` has spec/tasks only, no definition.py).
- Bypass here passes the *source texture* through, not a neutral vecfield (all-0.5) — differs from most other f_vf_ generators' bypass convention (e.g. f_vf_vortex, f_vf_vortex_multi output neutral field on bypass). Worth confirming this divergence is intentional before assuming parity across the vecfield family.
- Per spec.md, remaining open items before full sign-off: general audit pass and final build verification in Max (both unchecked in the spec's acceptance list as of last update).
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract.
