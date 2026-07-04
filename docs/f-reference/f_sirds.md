# f_sirds — Bpatcher Spec

_Last updated: 2026-07-03_
_Status: Working_

## Concept

Single Image Random Dot Stereogram (SIRDS) generator. Strip-based real-time
construction per Policarpo, "Real-Time Stereograms," GPU Gems Ch. 41 (2004).
A grayscale depth texture drives horizontal pixel displacement of a
repeating pattern texture; when correctly converged, the viewer perceives
a 3D shape encoded in the depth map.

Named `sirds` rather than `stereogram` deliberately — this is one specific
construction technique (single-image, strip-based, random-dot). Stereo-pair
or anaglyph techniques would be a different, separate module if built later.

## Parameters

| Name | Type | Description |
|------|------|-------------|
| `bypass` | toggle | Bypass — shows the raw pattern texture, undisplaced (0/1) |
| `depth_factor` | float | Depth → horizontal displacement scaling — -0.3–0.3 |

Range tightened from the theoretical -1..1 to the practical -0.3..0.3 —
values beyond that mostly just distort rather than adding usable depth
(confirmed empirically). Sign flips displacement direction. This differs
from GPU Gems' `abs()` + depth-inversion convention for negative values —
not yet reconciled, see Open Questions.

`num_strips` is **not** a live parameter — fixed at build time (12,
proven working empirically). See Architecture below.

## Inlets

| Inlet | Type | Description |
|---|---|---|
| 0 | texture (required) | Pattern — the repeating visual content carrying the illusion. Stochastic, isotropic sources strongly preferred (structured/anisotropic sources disrupt the uniform-noise appearance the illusion needs). **Animate this, even subtly — see Key Findings.** |
| 1 | texture (optional, `vs_black` fallback) | Depth — luma-read, near/far. Unconnected = zero displacement everywhere, degrades gracefully to the flat tiled pattern. |

## Architecture

Forward chain of 13 `jit.gl.pix` stages — no `jit.gl.node`/`jit.gl.pass`
needed, confirmed delay-free (verified at 4 stages; not independently
re-verified at 13, though no symptom pointing at a cook-order problem has
turned up).

- **Stage 0 (reference/seed):** tiles the pattern periodically via
  `mod(uv.x, strip_width) / strip_width`. No depth involvement, no masking
  outside its own strip — the pattern tile is periodic and has no real
  edge to run out of.
- **Stages 1–12 (depth-driven):** each reads the *previous* stage's
  already-resolved output, displaced by depth within its own strip region,
  passing through everywhere else. Byte-identical codebox apart from a
  baked `stage_index` constant.
- `strip_width = 1/(num_strips+1) = 1/13 ≈ 0.0769` — baked as a literal at
  build time into every stage, not a runtime param.
- `depth_factor` and `bypass` are broadcast to **every** depth-driven
  stage, not just the final one — each stage's own `in_strip` gate is
  multiplied by `(1.0 - bypass)`, so the whole chain self-neutralizes back
  to stage 0's clean tiled output when bypassed. No separate raw-pattern
  wire into the final stage is needed for this.
- Depth-map sampling uses a remapped coordinate, not the raw output `uv.x`:
  `depth_uv_x = (uv.x - strip_width) / (1.0 - strip_width)` — linearly
  stretches everything except the reference strip to cover the full depth
  map. Sampling `uv` directly is a bug (confirmed against the GPU Gems
  primary source), not a valid simplification.

## Build

**Not built via `tools/build_patcher.py`.** That script's `pix_chain`
mechanism only wires live params to a single "primary" node — this module
needs `depth_factor`, `bypass`, and the depth texture reaching all 12
depth-driven stages. Built instead via a dedicated script, following the
`f_vf_advect` precedent (custom builder, `definition.py` stays the
documented source of truth even though it isn't literally consumed by
`build_patcher.py`):

```
.specify/f_sirds/definition.py       — documented source of truth
.specify/f_sirds/codebox_stage0.gen  — reference stage template
.specify/f_sirds/codebox_stage_n.gen — depth-driven stage template
                                        ({stage_index}/{strip_width}
                                        baked in via .format() per instance)
.specify/f_sirds/build_sirds.py      — generates patchers/f_sirds.maxpat
```

Run: `python3 .specify/f_sirds/build_sirds.py`
Validate: `python3 -c "import json; json.load(open('patchers/f_sirds.maxpat'))"`

Registered in `f_modules` under Processors — `.specify/f_modules/build_modules.py`
and `javascript/f_addmod.js`'s `SIZES` dict (`"sirds": [190, 130]`).

## Key Findings

**`num_strips` must be large (12 works) — not a small number like 4.**
Strips are repeat units tied to comfortable eye-convergence distance, not
content divisions. Fewer/wider strips means larger per-strip displacement
and far fewer repeats — not enough repeat density to fuse at all. GPU Gems
is explicit: more strips means *less* displacement needed per strip. At
`num_strips=4`, only ~2.5 visible copies of a test depth feature appeared;
at 12, a clean single-circle illusion reads correctly.

**Animating the pattern (not just the depth map) dramatically improves
fusion stability, especially under motion.** With frozen noise, the
illusion was prone to breaking into multiple overlapping copies once
anything animated — traced to spurious coincidental matches in static
noise competing with the true, shift-math-guaranteed match. Animating the
pattern washes these out: a false match is luck-based and doesn't survive
frame to frame, degrading into shimmer, while the true match regenerates
correctly every frame and stays sharp. Same principle as Julesz's original
*dynamic* random-dot stereograms. **Practical recommendation: keep the
pattern source animating, even subtly, in live use — frozen noise may be
the harder case to fuse, not the easier one.**

Depth map can also animate successfully with smooth/gradual motion
(tested: sine-driven WFG).

## Open Questions

- **Viewing mode convention.** White=near matches wall-eyed/divergent
  viewing (the common published-SIRDS convention). Not yet decided how to
  communicate/design for viewer convergence in a live-performance context
  with no instruction card.
- **`depth_factor` sign semantics differ from GPU Gems.** Their source
  uses `abs(depth_factor)` for magnitude plus depth inversion
  (`1.0 - tex.x`) when negative; ours just flips displacement direction.
  Not reconciled.
- **Strip count ceiling above 12** unexplored — this build is fixed at 12,
  a rebuild is required to test a different count (no live control).
- **13-stage cook order** confirmed delay-free only at 4 stages in earlier
  testing; not independently re-verified at 13, though extreme
  `depth_factor` stress-testing didn't surface anything looking like a
  desync artifact.
- `depth_blur` (internal depth preconditioning, mentioned in the original
  spec draft) was never built or tested this round — deferred.
- Circular screen masking is explicitly out of scope for this module —
  handled downstream.

## Source File

`patchers/f_sirds.maxpat`

## References

Algorithm based on: Policarpo, F. "Real-Time Stereograms," GPU Gems Ch. 41
(2004). https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-41-real-time-stereograms
— strip-based construction, depth-map remap formula, and shift formula
used directly (confirmed against the chapter's embedded Cg fragment shader
source).

Otuyama, J.M. "Stereogram Tutorial." https://www.ime.usp.br/~otuyama/stereogram/basic/index.html
— cross-checked the classic recursive row-construction algorithm and
depth/shift polarity convention.

Wikipedia, "Autostereogram." https://en.wikipedia.org/wiki/Autostereogram
— viewing-mode (wall-eyed/cross-eyed) background and history context
(Julesz, dynamic RDS — informed the animated-pattern fusion-stability
finding above).
