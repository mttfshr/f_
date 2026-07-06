# f_vf_potential

**Type:** Processor (f_vecfield consumer), temporal / has memory
**Status:** Working — **not yet listed in README.md's patch table; found undocumented during a docs audit (2026-07-05)**

---

## What it does

Scalar potential-field integrator. Takes a vecfield and accumulates its magnitude over time via ping-pong feedback (same two-`jit.gl.pix`-in-one-bpatcher pattern as `f_vf_advect`: an identity `pass` stage holds the previous frame, a `state` stage accumulates). Output is a 0–1 scalar (greyscale) whose level sets (isolines) trace integrated flow — designed to feed directly into `f_weave`'s scalar inlet to produce curved, field-informed isoline texture in place of `f_weave`'s straight-line default.

Typical chain: `f_vf_repulse → f_vf_potential → f_weave` (scalar inlet).

---

## Signal Flow

```
in0 (vecfield, required) → vs_inState → potential_pix in2   [src_vecfield gate]
in1 (color texture, optional) → vs_inState → potential_pix   [src_color gate]

pass_pix out0 → potential_pix in3   [previous frame, feedback]
potential_pix out0 → pass_pix in0   [feedback]
potential_pix out0 → out0 (scalar potential)
```

---

## Parameters

| Param | Range | Default | Description |
|---|---|---|---|
| `dt` | 0–0.05 | 0.01 | Accumulation step size per frame — larger = faster tracking |
| `decay` | 0.8–1.0 | 0.98 | Frame decay — lower = faster fade, higher = longer memory |
| `strength` | 0–2.0 | 1.0 | Output scale |
| `src_vecfield`, `src_color` | internal | — | vs_inState connection gates; not user-facing |
| `bypass` | 0/1 | 0 | Standard bypass |

**Prefix:** `vfpotential` — **Object names:** `#0_potential_pix` (accumulator), `#0_potential_pass` (identity feedback-hold stage)

---

## Notes

- Temporal module — has memory across frames, same architectural family as `f_vf_advect` (ping-pong `pass`/`state` pix pair, `@adapt` on both stages).
- No `.specify/f_vf_potential/spec.md` exists — this doc is derived entirely from `definition.py`'s header comment, `pix_chain`, and param list. `codebox_potential.gen` was not independently reviewed for this doc — read it directly before relying on exact algorithm details.
- The `color` mod inlet (`src_color`) suggests the accumulator can be informed by or tint against a color texture in addition to the vecfield, but the exact mechanism isn't documented anywhere outside the codebox itself — worth clarifying with Matt or reading `codebox_potential.gen` if this module comes back into active use.
- Not in `README.md`'s patch table — added as a finding of this documentation pass, not yet cross-checked into README.

## Source File

`patchers/f_vf_potential.maxpat`
