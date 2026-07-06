# f_vf_flow

**Type:** Generator (f_vecfield producer), dual-mode
**Status:** Working — **not yet listed in README.md's patch table; found undocumented during a docs audit (2026-07-05)**

---

## What it does

Dual-mode vecfield generator, designed as an input for `f_weave`'s vecfield inlet. Takes an optional scalar texture on inlet 0:

- **Unconnected:** uniform direction field — every pixel outputs the same vector, oriented by `angle`.
- **Connected:** direction varies spatially, perturbed by the input texture's luminance scaled by `spread` — a spatially-varying flow direction rather than a single global angle.

Mode is auto-detected via `vs_inState`, driving the internal `src_mode` param (not user-facing), the same convention used by f_stipple/f_masonry.

Bypass outputs a neutral vecfield (0.5, 0.5) — not a passthrough of the input scalar texture.

---

## Signal Flow

```
in0 (optional scalar texture + control) → vs_inState → vfflow_pix in0   [render trigger + src_mode]
routepass unmatched → route angle spread → live.dials → prepend param <name> → vfflow_pix in0

vfflow_pix (@type float32) out0 → out0 (f_vecfield)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `angle` | 0–1 | 0.0 | Base flow direction (0–1 = full circle) |
| `spread` | 0–1 | 0.5 | How much the input texture perturbs direction — 0=uniform, 1=full rotation |
| `src_mode` | internal | — | Driven by `vs_inState`; not user-facing |
| `bypass` | 0/1 | 0 | Outputs neutral vecfield (0.5, 0.5) |

**Prefix:** `vfflow` — **Object name:** `vfflow_pix`

---

## Typical Use

```
[optional scalar texture] → f_vf_flow → f_weave (vecfield inlet)
```

`f_weave`'s codebox decodes an incoming vecfield's raw (undecoded, 0–1) X/Y samples directly as an orientation perturbation added to its own `cos(angle*π)`/`sin(angle*π)` basis — see `docs/f-reference/f_weave.md`.

## Notes

- No `.specify/f_vf_flow/spec.md` exists — this doc is derived from `definition.py`'s header comment and param list plus `codebox_flow.gen`.
- Not in `README.md`'s patch table — added as a finding of this documentation pass, not yet cross-checked into README.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract — note `f_vf_flow` is one of the few f_vecfield producers with a `"dual"` archetype (source when unconnected, processor-like when a texture is patched in), same category as `f_stipple`.

## Source File

`patchers/f_vf_flow.maxpat`
