# f_vf_potential

**Type:** Processor (f_vecfield consumer), temporal / has memory
**Status:** Working — listed in README.md's patch table (the 2026-07-05 audit note "not yet listed" is outdated); maintenance-audited 2026-10-12

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
- **2026-10-12 maintenance audit — codebox now read, and the review note above can be retired:** `codebox_potential.gen` integrates field **magnitude** only (`field_mag = sqrt(fx² + fy²)` accumulated with `dt`/`decay`) — it does not integrate the vector path or direction. Consequence: the module is **axis-blind** — a field and its 180° flip produce identical output. This settles `ideas/f_tensorfield.md`'s open question 11 (previously "assumed excluded" in the tensor-consumer audit table; now recorded as affected, magnitude-only). The optional color inlet tints/gates the same accumulation per its channel luma; no directional mechanism anywhere.
- **Bypass behavior (audit finding):** bypassed, the module outputs the neutral (0,0,0,1), not an input passthrough, despite declaring archetype "processor" — the implicit `out1 == in1` contract check doesn't cover this module. A BYPASS_EXPECT entry to assert it is filed as `.specify/f_vf_potential/T001`.

## Source File

`patchers/f_vf_potential.maxpat`
