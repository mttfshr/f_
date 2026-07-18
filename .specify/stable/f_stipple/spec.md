# Spec: f_stipple

_Last updated: 2026-05-30_

## What it does

A 2D hash field rendered as stipple. Every pixel evaluates a spatially-structured noise function and compares against a threshold — no mark geometry, no course structure. Pure field operation.

**Two modes, auto-detected from inlet 0 via `vs_inState` (Vsynth convention):**

- **Source mode** (no incoming texture): generates a standalone luminance stipple texture from parameters alone. White stipple on black.
- **Processor mode** (texture present on inlet 0): uses the incoming texture to modulate the hash field. Two sub-modes via `proc_mode`:
  - **Density (proc_mode = 0):** incoming luma modulates local threshold — bright regions get dense stipple, dark regions get sparse. Natural halftone / mezzotint effect. Output color inherited from input.
  - **Displacement (proc_mode = 1):** incoming luma offsets hash field phase spatially — stipple warps around bright/dark regions. `threshold` controls displacement amount. Output color inherited from input.

`proc_mode` is inert in source mode. Color grading is downstream's job — f_stipple inherits or outputs monochrome only.

---

## Hash Field Architecture

Two orthogonal hash fields evaluated in the stipple's own coordinate frame (rotated by `angle`):

- **High anisotropy end:** sin-based hash along `along` axis — periodic, directional, tiles cleanly
- **Low anisotropy end:** arithmetic hash combining `along` and `across` — isotropic grain, no tiling requirement

`anisotropy` blends between them:

```
hash_field = mix(h_iso, h_parallel, anisotropy)
```

At `anisotropy = 1`: parallel lines, orientation readable.
At `anisotropy = 0`: isotropic grain, angle irrelevant.
In between: structured grain — the primary expressive zone.

The 2D hash (combining both axes) is expected to avoid the diagonal seam artifact seen in f_masonry's 1D rotated hash. Verify in scratch patch.

---

## Coordinate Frame and Drift

`angle` defines the `along`/`across` coordinate frame. It is load-bearing: sets hash orientation AND drift axes.

```
theta  = angle * (PI / 180.0)
along  = norm.x * cos(theta) + norm.y * sin(theta)
across = -norm.x * sin(theta) + norm.y * cos(theta)
```

Drift is world-space translation: hash evaluated at `(along + along_speed * time, across + across_speed * time)`. Field is infinite — viewport scrolls through it. UV wrapping handles edges.

`along_speed`: drift parallel to lines (high anisotropy = phase shift; mid anisotropy = crawl).
`across_speed`: drift perpendicular to lines (high anisotropy = lateral scroll — the expressive direction).

---

## Signal Chain

Dual-mode source/processor. Mode detected via `vs_inState` — a Vsynth abstraction that monitors inlet connection state using draw-callback timing (not alpha or luma).

```
in0 (texture + ctrl) → routepass jit_gl_texture jit_matrix

routepass out0 (texture) → vs_inState inlet 0
  vs_inState outlet 0 (texture or vs_black fallback) → pix in0   [render trigger]
  vs_inState outlet 1 (0/1 state int) → prepend param src_mode → pix in0

routepass unmatched → route <params> → live.dials → prepend param <name> → pix in0

bypass_toggle.js → prepend param bypass → pix in0   [direct, not through route]

pix out0 → out0 (texture out)
```

`src_mode` is patcher-driven (0 = source, 1 = processor) — not a user-facing param. The codebox reads it as a `Param` but it is never exposed as a dial or in the parameters block. Not routed through `route`.

Source bypass: outputs black.
Processor bypass: passes input texture through unchanged.

---

## Parameters

| Param | UI Object | Range | Default | Notes |
|---|---|---|---|---|
| `freq` | live.dial | 0.0–20.0 | 5.0 | Hash field spatial frequency; changes field character at every value |
| `angle` | live.dial | -360–360 | 0.0 | Orientation of along/across coordinate frame |
| `anisotropy` | live.dial | 0.0–4.0 | 0.5 | 0 = isotropic grain, 1 = parallel lines, >1 = expressive aliasing |
| `threshold` | live.dial | 0.0–2.0 | 0.5 | Dither bias (source/dither mode); displacement amount (displacement mode) |
| `softness` | live.dial | 0.0–2.0 | 0.1 | Smoothstep width at comparison boundary; >1.0 produces expressive banding |
| `zoom` | live.dial | 0.1–4.0 | 1.0 | Scales viewport into hash field — same field character, bigger or smaller |
| `along_phase` | live.dial | -1.0–1.0 | 0.0 | Hash field offset along angle axis; drive externally for drift |
| `across_phase` | live.dial | -1.0–1.0 | 0.0 | Hash field offset perpendicular to angle axis; drive externally for drift |
| `colorize` | live.dial | 0.0–1.0 | 0.0 | Processor only: 0 = monochrome dither output, 1 = inherit input color |
| `proc_mode` | live.numbox | 0–1 | 0 | Processor only: 0 = dither, 1 = displacement |
| `bypass` | jsui (bypass_toggle.js) | 0–1 | 0 | Standard bypass |
| `src_mode` | patcher-driven (vs_inState) | 0–1 | 0 | Internal only: 0 = source, 1 = processor. Not exposed in UI. |

**Prefix:** `stipple`
**Object name:** `stipple_pix`

---

## Acceptance Criteria

**Source mode:**
- At default settings, produces a visible stipple texture
- `freq` sweeps visibly from large grain to fine stipple with no discontinuity
- `angle` rotates stipple orientation continuously with no discontinuity
- `anisotropy = 1.0` produces readable parallel lines; `anisotropy = 0.0` produces isotropic grain
- `threshold = 0.0` → near-black (sparse); `threshold = 1.0` → near-white (dense)
- `softness = 0.0` → hard binary stipple; `softness = 1.0` → smooth gradient field
- `along_phase` nonzero offsets field parallel to lines (high anisotropy) or diagonal (low); drive externally for continuous drift
- `across_phase` nonzero offsets field perpendicular to lines (high anisotropy) or laterally (low); drive externally for continuous drift
- Bypass outputs black

- `zoom` scales the apparent size of the field without changing its hash character; at zoom=1 output matches unzoomed baseline

**Processor/dither mode (proc_mode=0):**
- Bright input regions produce denser stipple than dark regions — hash field acts as dither matrix
- `threshold` biases dither globally; 0.5 = neutral, higher = lighter output, lower = darker
- `colorize=0` outputs monochrome stipple; `colorize=1` gates input color through stipple mask
- Bypass passes input through unchanged

**Processor/displacement mode (proc_mode=1):**
- Hash field warps spatially according to input luma
- `threshold` scales warp amount; at 0.0 produces no displacement
- Bypass passes input through unchanged

**Both modes:**
- Switching inlet connection triggers mode change cleanly via `vs_inState`
- No param sweep causes visual discontinuity or frame flash
- No diagonal seam artifact visible at any angle

---

## Open Questions

- ~~**`freq` range and mapping:**~~ Resolved: 0.0–20.0, default 5.0. Linear mapping sufficient.
- ~~**Speed scale:**~~ Resolved: renamed to `along_phase`/`across_phase`. No internal time accumulation — jit.gen has no time built-in. Drive externally (phasor~, vs_sync_time, WFG) same pattern as f_masonry `phase` and f_grain `era_clock`.
- ~~**Processor density compositing:**~~ Resolved: multiply stipple against input color (`src_col * stipple`).
- **Source mode alpha:** output as `vec(luma, luma, luma, 1.0)` — confirm alpha handling is correct in Vsynth context. Verify in Phase 4.
- ~~**Seam test:**~~ Resolved: no diagonal seam artifact visible at tested angles. 2D hash confirmed clean.

---

## Clarifications

### Session 2026-05-30
- Q: How does source/processor auto-detect work? → A: Use `vs_inState` Vsynth abstraction — connection-event timing, not alpha/luma. Drives `src_mode` param into codebox from patcher. Discovered by reading `vs_inState.maxpat` source.
