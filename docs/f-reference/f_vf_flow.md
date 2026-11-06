# f_vf_flow

**Type:** Processor (f_vecfield producer): a scalar texture in, a vecfield out
**Status:** Working — listed in README.md's patch table; maintenance-audited 2026-10-12. Re-typed 2026-11-01 (Matt): it is a processor, not a dual (see below). Bypass moved to `bypass_gate` 2026-11-06.

---

## What it does

Vecfield generator (it was designed to feed `f_weave`'s vecfield inlet, which was retired 2026-11-01; it feeds any vecfield consumer, for example `f_vf_warp`). It needs a texture on inlet 0: the texture's red channel (its luminance, if the texture is gray) sets the flow direction at each pixel, `angle * 2pi + (red - 0.5) * spread * 2pi`, output as a unit vector. Mid gray flows along `angle`. `spread` 0 gives the uniform field at `angle`, with any texture connected.

Every pixel is a full-strength vector, so the field has direction but no variation in strength, and never reaches zero outside bypass. Reach for `f_vf_fieldmap` instead to follow a texture's slopes, with flat areas at zero.

**Decision 2026-11-01 (Matt): flow needs a texture; there is no unconnected mode** (no uniform-field mode, no render trigger). With nothing connected it renders nothing: there is no `vs_inState`, no `vs_black` fallback and no `r draw`, so the incoming texture is the only thing that triggers the pix. Before this date the module was a `dual` with a `src_mode` flag; that, its `vs_inState` and the unconnected path were removed. A uniform field would only be a second angle dial on weave.

Bypass outputs a neutral vecfield (0.5, 0.5, 0.5, 1) through the codebox Param `bypass_gate`, not the native `@bypass` — not a passthrough of the input texture. The shader still runs, so it also needs the input texture.

---

## Signal Flow

```
in0 (scalar texture + control) → routepass jit_gl_texture jit_matrix → vfflow_pix in0
routepass unmatched → route angle spread → live.dials → attrui → vfflow_pix in0
bypass toggle (jsui) → prepend param bypass_gate → vfflow_pix in0

vfflow_pix (@type float32) out0 → out0 (f_vecfield)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `angle` | 0–1 | 0.0 | Base flow direction (0–1 = full circle) |
| `spread` | 0–1 | 0.5 | How much the input texture perturbs direction — 0=uniform, 1=full rotation |
| `bypass` | 0/1 | 0 | The toggle only (the route has no `bypass` selector). Drives `bypass_gate`: outputs a neutral vecfield (0.5, 0.5) |

**Prefix:** `vfflow` — **Object name:** `vfflow_pix`

---

## Typical Use

```
[texture] → f_vf_flow → f_vf_warp inlet 1 (or another vecfield consumer)
[source]  →              f_vf_warp inlet 0
```

`f_weave` no longer takes a vecfield (retired 2026-11-01, see `docs/f-reference/f_weave.md`); whether `f_vf_warp` after weave is a drop-in for the old behaviour was not checked (`ideas/f_weave_scope_questions.md` Q2).

## Notes

- No `.specify/f_vf_flow/spec.md` exists — this doc is derived from `definition.py`'s header comment and param list, `codebox_flow.gen` and the shipped patcher.
- The codebox comment says luminance; the code reads `.x`, the red channel.
- `spread` 1 is a full turn, so black and white input point the same way.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract. Until 2026-11-01 `f_vf_flow` was one of the few f_vecfield producers with a `"dual"` archetype; it is now a plain processor.

## Source File

`package/patchers/f_vf_flow.maxpat`
