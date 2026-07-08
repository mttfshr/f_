# f_vf_vorticity — Bpatcher Spec

_Last updated: 2026-07-06_
_Status: UNVERIFIED — do not treat as working. See note below._

**Correction (2026-07-06, end of session):** this file originally stated
"Status: Working" and described the module's behavior as confirmed. Matt
corrected this — it is not confirmed working. That status was asserted
based on apparent chain-testing earlier in the same session that also
produced a separate module (`f_vf_advect`'s confinement fold-in) which
seemed confirmed at multiple points along the way and later turned out
not to be, after extensive debugging. Given that track record within
this same session, nothing below should be treated as settled without
independent re-verification from scratch. Re-check before building on
top of this or registering it in `f_modules.maxpat`.

## Concept

A standalone vecfield-to-vecfield processor implementing vorticity
confinement (GPU Gems 1, Ch. 38, S:38.5.1 — Harris/Stam). Consumes an
f_vecfield, computes its vorticity (curl), and adds a corrective force —
perpendicular to the gradient of vorticity magnitude — back into the
field. Restores fine-scale swirling motion without a full diffusion/
projection solve (deliberately out of scope for `f_vf_advect` — 20-80
Jacobi iterations per timestep, too expensive for live multi-module use;
see `ideas/vorticity_confinement.md`).

Fits the vf_ family's producer/consumer composability: takes any
f_vecfield in (vortex, repulse, flow, fieldmap, or another vf_
processor's output), outputs an enhanced f_vecfield. Not coupled to any
specific downstream consumer — see Key Findings for what that means in
practice.

## Parameters

| Name | Type | Range | Description |
|------|------|-------|--------------|
| `confinement` | float | 0–1 (range_tiers 0.1/1.0/10.0) | Turbulence amount. 0 = pass-through field. Effective strength depends heavily on the source field's baseline curl — see Key Findings. |
| `bypass` | toggle | — | Output = unmodified input field |

## Inlets

| Inlet | Type | Description |
|---|---|---|
| 0 | texture (required, driving) | f_vecfield in — float32 RG, this inlet IS the vecfield, not a separate scalar source (same pattern as `f_vf_fieldmap`'s in1) |

## Outlets

| Outlet | Description |
|---|---|
| 0 | Enhanced f_vecfield — input field plus the confinement force. No composite/isolated-layer split (unlike `f_vf_glow`/`f_caustic`) — this transforms the field itself, there is no separate source image to composite over. |

## Architecture

Single `jit.gl.pix` codebox — no multi-stage split needed. This was the
real open question carried from planning (curl needs 4 field samples;
the vorticity gradient needs curl evaluated at 4 neighbors, each of which
needs its own 4 field samples — ~20+ inline texture samples per pixel,
no loops, no dynamic branching). Confirmed compiling clean in scratch
testing with no console errors and no capture-ceiling failure, unlike
`f_vf_seeds`/`f_masonry`'s loop-driven searches at similar total sample
counts — this computation's fixed, linear (non-looping) shape appears to
be the reason it didn't hit the same wall.

```
field_x(u,v) / field_y(u,v)  — sample + remap one field component at an
                                arbitrary UV (single-return functions,
                                confirmed GPU-safe pattern)
curl_at(u,v,sx,sy)           — 4-sample central-difference curl, calls
                                field_x/field_y
main body                     — curl_at at center + 4 neighbors →
                                central-difference the vorticity itself →
                                normalized gradient → perpendicular force
                                → added to the input field → re-encoded
                                as f_vecfield (0.5 = zero vector)
```

Finite-difference offsets use `dim`-derived texel size (`1.0/dim.x`,
`1.0/dim.y`), same idiom as `f_vf_sobel`'s and `f_caustic`'s divergence
calc — no new offset convention introduced.

**Zero-force on unconnected/uniform input, with no explicit suppression
code.** Unlike `f_vf_glow` (which needs an explicit raw-value threshold
check to suppress its accumulation on `vs_black`'s remapped (-1,-1)
constant), this module needs nothing extra: vorticity confinement depends
on *spatial derivatives* of the field, and a spatially uniform field
(including `vs_black`'s constant fallback) has zero derivative everywhere
— curl = 0, force = 0, as a direct structural consequence of the math,
confirmed in scratch testing.

## Build

Standard single-codebox path via `tools/build_patcher.py`:

```
.specify/f_vf_vorticity/definition.py   — documented source of truth, codebox inline
```

Run: `tools/py.sh tools/build_patcher.py .specify/f_vf_vorticity/definition.py`
Validate: `python3 -c "import json; json.load(open('patchers/f_vf_vorticity.maxpat'))"`

## Key Findings

**`confinement`'s effective strength varies substantially by source
field — confirmed against vortex, repulse, and flow.** Same category of
finding as `f_vf_seeds`' `field_gain` (~7.5x range difference by source):
a source with inherently higher baseline curl shows a stronger effect at
the same `confinement` value, because the confinement force is directly
proportional to local curl magnitude. Not a bug — exposed via
`range_tiers` (0.1/1.0/10.0), same convenience mechanism as `field_gain`,
rather than picking one fixed range that would be wrong for at least one
source.

**The technique's legible effect requires a consumer with temporal
feedback — this is the central finding of this module's integration
testing.** Vorticity confinement exists to counteract energy dissipated
over *repeated iteration* in a fluid solver; it only has something
meaningful to compound against in a consumer that carries field state
across frames. `f_vf_advect` is currently the only such consumer in `f_`
(its `decay`-weighted feedback loop). Every other current consumer
(`f_caustic`, `f_vf_warp`, `f_lens` field inlet, `f_vf_glow`) samples the
field fresh each frame with no persistent state — feeding a spatially-
perturbed-but-otherwise-static field into any of them produces a
different-looking *static* field, not visible turbulence, because
turbulence is fundamentally a temporal phenomenon and these consumers
have no "over time" to show it in. Confirmed directly: chaining through
`f_vf_advect` produces a distinctly different, visibly turbulent result;
chaining through other consumers does not produce a result distinctly
different from feeding them the unmodified source field.

**This is not a reason to fold `confinement` into `f_vf_advect` as a
param instead of keeping this standalone.** The standalone architecture
decision (per `plan.md` ADR-1/ADR-3) is reinforced, not undermined, by
this finding — a param baked into `f_vf_advect` would be unusable by any
future feedback-based module, whereas the standalone processor is
already correctly positioned for that. The practical guidance is about
*where in a chain this module earns its keep*, not about whether it
should exist independently.

## Open Questions

- **Interaction with `f_vf_advect`'s `decay > 1.0` "excitable/amplifying"
  mode** — both mechanisms independently add energy/swirl to a field.
  Whether they compound controllably or fight each other at various
  `decay`/`confinement` combinations hasn't been systematically mapped,
  only confirmed to "work well" in informal testing.
- **Whether any other current or future `f_` module has temporal
  feedback** (making it a second legible pairing for this module) —
  worth checking as new vf_ family members are built.
- **NaN/stability at very high `confinement`** — no NaN or blowup
  observed in scratch testing (including near a vortex's fixed-point
  singularity), but the practical ceiling before output becomes
  chaotic-to-the-point-of-unusable (vs. genuinely broken) wasn't
  precisely mapped.

## Source File

`patchers/f_vf_vorticity.maxpat`

## References

GPU Gems 1, Ch. 38 ("Fast Fluid Dynamics Simulation on the GPU"),
S:38.5.1 — vorticity confinement as a standalone, single-pass additive
force term. Confirmed against the codebox that `f_vf_advect`'s existing
core already implements the same chapter's Advection step correctly
(see `ideas/vorticity_confinement.md`); this module adds the chapter's
confinement term as a separate, composable processor rather than folding
it into that existing module.

`docs/f_vecfield_type.md` — float32 RG, 0.5 = zero vector encoding
convention followed on both the inlet and outlet.
