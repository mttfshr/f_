# f_vf_flow

**Type:** Processor (f_vecfield producer): a scalar texture in, a vecfield out
**Status:** Working — listed in README.md's patch table; maintenance-audited 2026-10-12. Re-typed 2026-11-01 (Matt): it is a processor, not a dual (see below).

---

## What it does

Vecfield generator (it was designed to feed `f_weave`'s vecfield inlet, which was retired 2026-11-01; it feeds any vecfield consumer, for example `f_vf_warp`). It needs a scalar texture on inlet 0: the texture's luminance sets the flow direction at each pixel, `angle * 2pi + (luminance - 0.5) * spread * 2pi`, output as a unit vector. `spread` 0 gives the uniform field at `angle`.

**Decision 2026-11-01 (Matt): flow needs a texture; there is no unconnected mode** (no uniform-field mode, no render trigger). With nothing connected it renders nothing. Before this date the module was a `dual` with a `src_mode` flag; that, its `vs_inState` and the unconnected path were removed. A uniform field would only be a second angle dial on weave.

Bypass outputs a neutral vecfield (0.5, 0.5) — not a passthrough of the input scalar texture.

---

## Signal Flow

```
in0 (scalar texture + control) → routepass jit_gl_texture jit_matrix → vfflow_pix in0
routepass unmatched → route angle spread → live.dials → prepend param <name> → vfflow_pix in0

vfflow_pix (@type float32) out0 → out0 (f_vecfield)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `angle` | 0–1 | 0.0 | Base flow direction (0–1 = full circle) |
| `spread` | 0–1 | 0.5 | How much the input texture perturbs direction — 0=uniform, 1=full rotation |
| `bypass` | 0/1 | 0 | Outputs neutral vecfield (0.5, 0.5) |

**Prefix:** `vfflow` — **Object name:** `vfflow_pix`

---

## Typical Use

```
[scalar texture] → f_vf_flow → f_vf_warp (or another vecfield consumer)
```

`f_weave` no longer takes a vecfield (retired 2026-11-01, see `docs/f-reference/f_weave.md`); whether `f_vf_warp` after weave is a drop-in for the old behaviour was not checked (`ideas/f_weave_scope_questions.md` Q2).

## Notes

- No `.specify/f_vf_flow/spec.md` exists — this doc is derived from `definition.py`'s header comment and param list plus `codebox_flow.gen`.
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract. Until 2026-11-01 `f_vf_flow` was one of the few f_vecfield producers with a `"dual"` archetype; it is now a plain processor.

## Source File

`package/patchers/f_vf_flow.maxpat`
