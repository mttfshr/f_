# f_vf_split

**Type:** Utility (f_vecfield consumer)
**Status:** Working — **not yet listed in README.md's patch table; found undocumented during a docs audit (2026-07-05)**

---

## What it does

Splits an f_vecfield's X and Y channels out to two separate greyscale outlets — the R channel (X component) to out0, the G channel (Y component) to out1. A small utility for feeding a vecfield's individual axes into consumers that expect plain scalar textures (e.g. `jit.gl.bfg`-style scalar-only chains, or per-axis further processing) rather than a combined RG vecfield.

`bipolar` selects the output encoding: Unipolar passes the raw 0–1 sample through unchanged (matching the field's stored encoding); Bipolar remaps to -1–1 (`x*2-1`), i.e. the field's actual decoded signed value.

---

## Signal Flow

```
in1 (f_vecfield texture) → split_pix in1

split_pix (@type float32) out0 (X channel, greyscale) → out0
split_pix (@type float32) out1 (Y channel, greyscale) → out1
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `bipolar` | menu (Unipolar/Bipolar) | Unipolar | Unipolar: passthrough 0–1 (raw stored encoding). Bipolar: remap to -1–1 (decoded signed value). |
| `bypass` | 0/1 | 0 | Both outlets pass the source vecfield texture through unchanged (not split). |

**Prefix:** `split` — **Object name:** `split_pix`

---

## Algorithm

```
r = sample(vecfield, uv).x
g = sample(vecfield, uv).y
r_out = mix(r, r*2-1, bipolar)
g_out = mix(g, g*2-1, bipolar)
out1 = mix(vec(r_out, r_out, r_out, 1), sample(vecfield, uv), bypass)
out2 = mix(vec(g_out, g_out, g_out, 1), sample(vecfield, uv), bypass)
```

## Notes

- Not in `README.md`'s patch table — added as a finding of this documentation pass, not yet cross-checked into README.
- No `.specify/f_vf_split/spec.md` exists — this doc is derived directly from `definition.py`'s inline codebox (there is no separate `.gen` file for this module).
- See `docs/f-reference/f_vecfield_type.md` for the f_vecfield type contract.

## Source File

`patchers/f_vf_split.maxpat`
